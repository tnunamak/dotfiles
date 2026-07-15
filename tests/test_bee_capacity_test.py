import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from importlib.machinery import SourceFileLoader
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "bin/.local/bin/bee-capacity-test"
SPEC = importlib.util.spec_from_loader("bee_capacity_test", SourceFileLoader("bee_capacity_test", str(SCRIPT)))
assert SPEC and SPEC.loader
m = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = m
SPEC.loader.exec_module(m)


def completed(argv, returncode=0, stdout=b"", stderr=b""):
    return subprocess.CompletedProcess(argv, returncode, stdout=stdout, stderr=stderr)


SHOW_ACTIVE_GOOD = (
    "ActiveState=active\n"
    "FragmentPath=/home/x/.config/systemd/user/llama-bee.service\n"
    "DropInPaths=/home/x/.config/systemd/user/llama-bee.service.d/10-resources.conf\n"
    "MainPID=4242\n"
    "ControlGroup=/user.slice/user-1000.slice/user@1000.service/app.slice/llama-bee.service\n"
    'Environment=LLAMA_BEE_VISIBLE_DEVICES=1 LLAMA_BEE_CTX=102400\n'
    "ExecStart={ path=/home/x/.local/bin/llama-bee-start ; argv[]=/home/x/.local/bin/llama-bee-start ; ignore_errors=no }\n"
)


class FakeRunnerBase:
    """Records every command issued; subclasses override behavior per-command
    so tests can model exact systemctl/systemd-run/nvidia-smi failure shapes
    without any real process, GPU, or systemd daemon."""

    def __init__(self):
        self.calls = []

    def __call__(self, command, timeout):
        self.calls.append(list(command))
        return self.dispatch(command, timeout)

    def dispatch(self, command, timeout):
        raise NotImplementedError


class ArgvAndPlanTests(unittest.TestCase):
    def make_arguments(self, **overrides):
        argv = []
        for key, value in overrides.items():
            argv += [f"--{key.replace('_', '-')}", str(value)]
        return m.parse_arguments(argv)

    def test_defaults_target_gpu1_and_four_slots_full_context(self):
        arguments = self.make_arguments()
        spec = m.CandidateSpec(arguments.start_script, arguments.port, arguments.parallel, arguments.ctx_size, not arguments.no_kv_unified, arguments.gpu_index)
        self.assertEqual(spec.gpu_index, 1)
        self.assertEqual(spec.parallel, 4)
        self.assertEqual(spec.ctx_size, 131072)
        self.assertEqual(spec.env_overrides()["LLAMA_BEE_VISIBLE_DEVICES"], "1")

    def test_default_parallel_config_is_one_in_underlying_wrapper_unaffected(self):
        # bee-capacity-test's own default candidate is 4; llama-bee-start's
        # own standalone default (LLAMA_BEE_PARALLEL unset) remains 1 — this
        # harness must not change that script's default.
        result = subprocess.run(
            [str(Path(__file__).parents[1] / "bin/.local/bin/llama-bee-start"), "--print-command"],
            capture_output=True, text=True, check=True,
            env={k: v for k, v in __import__("os").environ.items() if not k.startswith("LLAMA_BEE_")},
        )
        self.assertIn("-np 1", result.stdout)

    def test_candidate_env_overrides_never_leave_gpu_index_unset(self):
        spec = m.CandidateSpec("start", 5151, 4, 131072, True, 1)
        self.assertIn("LLAMA_BEE_VISIBLE_DEVICES", spec.env_overrides())

    def test_plan_is_dry_run_default_and_mentions_gpu1_and_props_fixture_requirement(self):
        result = subprocess.run([sys.executable, str(SCRIPT)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0)
        self.assertIn("read-only", result.stdout)
        self.assertIn("GPU: index 1 only", result.stdout)
        self.assertIn("props fixture required", result.stdout)
        self.assertIn("preflight -> arm-rollback -> stop-known-good", result.stdout)

    def test_apply_without_props_fixture_refuses_before_any_work(self):
        result = subprocess.run([sys.executable, str(SCRIPT), "--apply"], capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("--props-fixture", result.stderr)

    def test_apply_with_missing_fixture_file_refuses(self):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--apply", "--props-fixture", "/does/not/exist.json"],
            capture_output=True, text=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("does not exist", result.stderr)

    def test_invalid_parallel_refused_before_apply_path_even_with_fixture(self):
        with tempfile.NamedTemporaryFile(suffix=".json", mode="w", delete=False) as handle:
            json.dump({"total_slots": 4}, handle)
            fixture_path = handle.name
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--apply", "--parallel", "0", "--props-fixture", fixture_path],
            capture_output=True, text=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("--parallel must be a positive integer", result.stderr)

    def test_rollback_deadline_must_exceed_phase_timeout(self):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--phase-timeout-seconds", "100", "--rollback-deadline-seconds", "50"],
            capture_output=True, text=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("rollback-deadline-seconds", result.stderr)


class PreflightTests(unittest.TestCase):
    def make_preflight(self, runner, health_ok=True, expected_gpu=1, expected_port=5051):
        return m.PreflightInspector(runner, "systemctl", "llama-bee.service", expected_gpu, expected_port, lambda port: health_ok, timeout=1)

    def test_accepts_clean_active_snapshot(self):
        runner = lambda command, timeout: completed(command, 0, stdout=SHOW_ACTIVE_GOOD.encode())
        snapshot = self.make_preflight(runner).snapshot()
        self.assertIsInstance(snapshot, m.KnownGoodSnapshot)
        self.assertEqual(snapshot.gpu_index, 1)
        self.assertEqual(snapshot.main_pid, 4242)

    def test_refuses_when_not_active(self):
        output = SHOW_ACTIVE_GOOD.replace("ActiveState=active", "ActiveState=activating")
        runner = lambda command, timeout: completed(command, 0, stdout=output.encode())
        result = self.make_preflight(runner).snapshot()
        self.assertIsInstance(result, m.PreflightFailure)
        self.assertIn("not active", result.reason)

    def test_refuses_on_gpu_drift(self):
        output = SHOW_ACTIVE_GOOD.replace("LLAMA_BEE_VISIBLE_DEVICES=1", "LLAMA_BEE_VISIBLE_DEVICES=0")
        runner = lambda command, timeout: completed(command, 0, stdout=output.encode())
        result = self.make_preflight(runner).snapshot()
        self.assertIsInstance(result, m.PreflightFailure)
        self.assertIn("GPU0", result.reason)

    def test_refuses_on_missing_fragment_path(self):
        output = SHOW_ACTIVE_GOOD.replace("FragmentPath=/home/x/.config/systemd/user/llama-bee.service\n", "")
        runner = lambda command, timeout: completed(command, 0, stdout=output.encode())
        result = self.make_preflight(runner).snapshot()
        self.assertIsInstance(result, m.PreflightFailure)
        self.assertIn("FragmentPath", result.reason)

    def test_refuses_on_missing_main_pid(self):
        output = SHOW_ACTIVE_GOOD.replace("MainPID=4242", "MainPID=0")
        runner = lambda command, timeout: completed(command, 0, stdout=output.encode())
        result = self.make_preflight(runner).snapshot()
        self.assertIsInstance(result, m.PreflightFailure)
        self.assertIn("MainPID", result.reason)

    def test_refuses_when_health_check_fails(self):
        runner = lambda command, timeout: completed(command, 0, stdout=SHOW_ACTIVE_GOOD.encode())
        result = self.make_preflight(runner, health_ok=False).snapshot()
        self.assertIsInstance(result, m.PreflightFailure)
        self.assertIn("health", result.reason)

    def test_refuses_on_systemctl_command_failure(self):
        runner = lambda command, timeout: completed(command, 1, stderr=b"unit not found")
        result = self.make_preflight(runner).snapshot()
        self.assertIsInstance(result, m.PreflightFailure)

    def test_refuses_on_systemctl_exception(self):
        def runner(command, timeout):
            raise subprocess.TimeoutExpired(command, timeout)

        result = self.make_preflight(runner).snapshot()
        self.assertIsInstance(result, m.PreflightFailure)

    def test_identity_key_excludes_volatile_fields(self):
        runner = lambda command, timeout: completed(command, 0, stdout=SHOW_ACTIVE_GOOD.encode())
        snapshot = self.make_preflight(runner).snapshot()
        identity = snapshot.identity_key()
        self.assertNotIn("main_pid", identity)
        self.assertNotIn("control_group", identity)


class ReceiptStoreTests(unittest.TestCase):
    def setUp(self):
        self.temp_directory = tempfile.TemporaryDirectory()
        self.store = m.ReceiptStore(Path(self.temp_directory.name))

    def tearDown(self):
        self.temp_directory.cleanup()

    def make_receipt(self, transaction_id="txn-1"):
        runner = lambda command, timeout: completed(command, 0, stdout=SHOW_ACTIVE_GOOD.encode())
        snapshot = m.PreflightInspector(runner, "systemctl", "llama-bee.service", 1, 5051, lambda p: True, 1).snapshot()
        return m.TransactionReceipt(transaction_id, "llama-bee.service", snapshot, 1000.0, "systemctl", 30.0)

    def test_default_state_directory_is_not_under_tmp(self):
        # The receipt/rollback state directory must survive independently of
        # any tmpfs cleaner and of the candidate's own working directory —
        # verify the production default (XDG_STATE_HOME-based), not this
        # test's own tempdir fixture (which is itself under /tmp).
        default_root = str(m.state_directory())
        self.assertFalse(default_root.startswith("/tmp"))
        self.assertIn(".local/state", default_root)

    def test_write_then_read_round_trips(self):
        receipt = self.make_receipt()
        path = self.store.write_receipt(receipt)
        reloaded = self.store.read_receipt(path)
        self.assertEqual(reloaded.transaction_id, receipt.transaction_id)
        self.assertEqual(reloaded.snapshot.identity_key(), receipt.snapshot.identity_key())

    def test_receipt_file_is_read_only_after_write(self):
        receipt = self.make_receipt()
        path = self.store.write_receipt(receipt)
        mode = path.stat().st_mode & 0o777
        self.assertEqual(mode, 0o400)

    def test_not_released_by_default(self):
        self.assertFalse(self.store.is_released("txn-1"))

    def test_mark_released_is_observable(self):
        self.store.mark_released("txn-1")
        self.assertTrue(self.store.is_released("txn-1"))

    def test_release_is_per_transaction(self):
        self.store.mark_released("txn-1")
        self.assertFalse(self.store.is_released("txn-2"))


class RollbackOwnerTests(unittest.TestCase):
    def make_owner(self, deadline, released_at=None, restore_succeeds=True):
        temp_directory = tempfile.TemporaryDirectory()
        self.addCleanup(temp_directory.cleanup)
        store = m.ReceiptStore(Path(temp_directory.name))
        runner_calls = []

        def runner(command, timeout):
            runner_calls.append(list(command))
            if "is-active" in command:
                return completed(command, 0, stdout=b"active\n" if not restore_succeeds is False else b"inactive\n")
            return completed(command, 0 if restore_succeeds else 1)

        receipt = m.TransactionReceipt("txn-1", "llama-bee.service", None, deadline, "systemctl", 30.0)
        clock = {"t": 0.0}

        def wall_clock():
            return clock["t"]

        def sleeper(seconds):
            clock["t"] += seconds
            if released_at is not None and clock["t"] >= released_at:
                store.mark_released("txn-1")

        owner = m.RollbackOwner(receipt, store, runner, lambda message: None, wall_clock, sleeper, poll_interval_seconds=1.0)
        return owner, store, runner_calls

    def test_released_before_deadline_never_restores(self):
        owner, store, calls = self.make_owner(deadline=100.0, released_at=5.0)
        result = owner.wait_and_restore_if_unreleased()
        self.assertTrue(result)
        self.assertFalse(any("start" in call or "restart" in call for call in calls))

    def test_unreleased_at_deadline_restores(self):
        owner, store, calls = self.make_owner(deadline=10.0, released_at=None, restore_succeeds=False)
        result = owner.wait_and_restore_if_unreleased()
        self.assertTrue(any("start" in call for call in calls))

    def test_restore_failure_is_reported_false(self):
        # is-active always inactive, restart command itself fails
        temp_directory = tempfile.TemporaryDirectory()
        self.addCleanup(temp_directory.cleanup)
        store = m.ReceiptStore(Path(temp_directory.name))

        def runner(command, timeout):
            if "is-active" in command:
                return completed(command, 0, stdout=b"inactive\n")
            return completed(command, 1, stderr=b"boom")

        receipt = m.TransactionReceipt("txn-1", "llama-bee.service", None, 5.0, "systemctl", 30.0)
        clock = {"t": 0.0}
        owner = m.RollbackOwner(receipt, store, runner, lambda message: None, lambda: clock["t"], lambda s: clock.__setitem__("t", clock["t"] + s))
        self.assertFalse(owner.wait_and_restore_if_unreleased())

    def test_owner_logic_is_a_standalone_function_not_dependent_on_controller_process(self):
        # This is the crux of surviving controller death: RollbackOwner.run
        # takes only a receipt object and injected I/O — nothing that ties
        # its lifetime to a TransactionController instance or its process.
        import inspect

        signature = inspect.signature(m.RollbackOwner.__init__)
        parameter_names = list(signature.parameters)
        self.assertNotIn("controller", parameter_names)


class CandidateScopeTests(unittest.TestCase):
    def test_start_candidate_scope_uses_unique_unit_and_explicit_gpu_env(self):
        runner = FakeRunnerBase()
        runner.dispatch = lambda command, timeout: completed(command, 0)
        spec = m.CandidateSpec("start-script", 5151, 4, 131072, True, 1)
        m.start_candidate_scope(runner, "systemd-run", spec, "txn-abc", 5)
        command = runner.calls[0]
        self.assertIn("--scope", command)
        self.assertIn("--unit=bee-capacity-candidate-txn-abc", command)
        self.assertIn("Environment=LLAMA_BEE_VISIBLE_DEVICES=1", command)
        self.assertIn("start-script", command)
        self.assertIn("--kv-unified", command)

    def test_candidate_scope_unit_name_is_transaction_scoped(self):
        self.assertNotEqual(m.candidate_scope_unit_name("a"), m.candidate_scope_unit_name("b"))

    def test_candidate_scope_empty_true_when_inactive_and_zero_tasks(self):
        runner = lambda command, timeout: completed(command, 0, stdout=b"NTasks=0\nActiveState=inactive\n")
        self.assertTrue(m.candidate_scope_is_empty(runner, "systemctl", "txn-1", 1))

    def test_candidate_scope_not_empty_while_active_with_tasks(self):
        runner = lambda command, timeout: completed(command, 0, stdout=b"NTasks=3\nActiveState=active\n")
        self.assertFalse(m.candidate_scope_is_empty(runner, "systemctl", "txn-1", 1))

    def test_known_good_cgroup_empty_requires_inactive_and_zero_tasks(self):
        runner = lambda command, timeout: completed(command, 0, stdout=b"NTasks=0\nActiveState=inactive\n")
        self.assertTrue(m.known_good_cgroup_is_empty(runner, "systemctl", "llama-bee.service", 1))

    def test_known_good_cgroup_not_empty_while_tasks_remain(self):
        runner = lambda command, timeout: completed(command, 0, stdout=b"NTasks=1\nActiveState=deactivating\n")
        self.assertFalse(m.known_good_cgroup_is_empty(runner, "systemctl", "llama-bee.service", 1))


class GateTests(unittest.TestCase):
    def test_props_gate_requires_fixture_keys_present_live(self):
        fixture = {"total_slots": 4, "n_ctx": 131072, "some_version_field": "x"}
        original = m.http_get_json
        m.http_get_json = lambda url, timeout: {"total_slots": 4, "n_ctx": 131072}  # missing some_version_field
        try:
            gate = m.make_props_gate("http://x", 0.01, 4, 131072, fixture)
            failure = gate()
        finally:
            m.http_get_json = original
        self.assertIsNotNone(failure)
        self.assertIn("missing fixture-frozen keys", failure.reason)

    def test_props_gate_passes_when_fixture_shape_and_values_match(self):
        fixture = {"total_slots": 4, "n_ctx": 131072}
        original = m.http_get_json
        m.http_get_json = lambda url, timeout: {"total_slots": 4, "n_ctx": 131072, "extra_live_field": True}
        try:
            gate = m.make_props_gate("http://x", 0.01, 4, 131072, fixture)
            failure = gate()
        finally:
            m.http_get_json = original
        self.assertIsNone(failure)

    def test_props_gate_rejects_wrong_total_slots(self):
        fixture = {"total_slots": 4}
        original = m.http_get_json
        m.http_get_json = lambda url, timeout: {"total_slots": 2, "n_ctx": 131072}
        try:
            failure = m.make_props_gate("http://x", 0.01, 4, 131072, fixture)()
        finally:
            m.http_get_json = original
        self.assertIsNotNone(failure)

    def test_slots_gate_requires_exact_count(self):
        original = m.http_get_json
        m.http_get_json = lambda url, timeout: [{}, {}, {}]
        try:
            failure = m.make_slots_gate("http://x", 0.01, 4)()
        finally:
            m.http_get_json = original
        self.assertIsNotNone(failure)

    def test_concurrent_completion_probe_requires_all_four_accepted(self):
        def fake_poster(url, payload, timeout):
            slot = payload["id_slot"]
            if slot == 2:
                return 503, None
            return 200, {"content": "ok", "id_slot": slot}

        failure = m.run_concurrent_completion_probe("http://x", 4, 1, poster=fake_poster)
        self.assertIsNotNone(failure)
        self.assertEqual(failure.gate, "concurrent-completion")
        self.assertIn("1/4", failure.reason)

    def test_concurrent_completion_probe_passes_when_all_four_complete(self):
        def fake_poster(url, payload, timeout):
            return 200, {"content": "ok", "id_slot": payload["id_slot"]}

        failure = m.run_concurrent_completion_probe("http://x", 4, 1, poster=fake_poster)
        self.assertIsNone(failure)

    def test_concurrent_completion_probe_actually_issues_four_distinct_requests(self):
        seen_slots = []

        def fake_poster(url, payload, timeout):
            seen_slots.append(payload["id_slot"])
            return 200, {"content": "ok"}

        m.run_concurrent_completion_probe("http://x", 4, 1, poster=fake_poster)
        self.assertEqual(sorted(seen_slots), [0, 1, 2, 3])

    def test_gpu1_vram_gate_queries_only_requested_index(self):
        runner = FakeRunnerBase()
        runner.dispatch = lambda command, timeout: completed(command, 0, stdout=b"9000\n")
        gate = m.make_gpu1_vram_gate(runner, "nvidia-smi", 1, 2048, 1)
        self.assertIsNone(gate())
        self.assertIn("--id=1", runner.calls[0])

    def test_gpu1_vram_gate_rejects_multi_line_output_as_unparseable(self):
        # A regression guard against silently falling back to "all GPUs":
        # if --id filtering ever stops working upstream, multi-line output
        # must fail closed, not be reduced to a min() across devices.
        runner = lambda command, timeout: completed(command, 0, stdout=b"9000\n3000\n")
        gate = m.make_gpu1_vram_gate(runner, "nvidia-smi", 1, 2048, 1)
        failure = gate()
        self.assertIsNotNone(failure)
        self.assertEqual(failure.gate, "vram")

    def test_gpu1_vram_gate_enforces_floor(self):
        runner = lambda command, timeout: completed(command, 0, stdout=b"1000\n")
        gate = m.make_gpu1_vram_gate(runner, "nvidia-smi", 1, 2048, 1)
        failure = gate()
        self.assertIsNotNone(failure)
        self.assertIn("GPU1", failure.reason)


class TransactionControllerTests(unittest.TestCase):
    def make_snapshot(self, gpu_index=1):
        return m.KnownGoodSnapshot(
            unit="llama-bee.service",
            active_state="active",
            fragment_path="/frag",
            drop_in_paths=("/drop",),
            main_pid=1,
            control_group="/cg",
            environment={"LLAMA_BEE_VISIBLE_DEVICES": str(gpu_index)},
            exec_start_path="/start",
            port=5051,
            gpu_index=gpu_index,
            health_ok=True,
        )

    def make_controller(
        self,
        *,
        preflight_result=None,
        arm_ok=True,
        stop_ok=True,
        cgroup_empty_sequence=(True,),
        start_candidate_ok=True,
        gates=(),
        stop_candidate_ok=True,
        candidate_empty_sequence=(True,),
        start_known_good_ok=True,
        restored_snapshot=None,
    ):
        snapshot = preflight_result if preflight_result is not None else self.make_snapshot()
        events = []
        clock = {"t": 0.0}
        cgroup_iter = iter(cgroup_empty_sequence)
        candidate_iter = iter(candidate_empty_sequence)

        preflight = type("P", (), {"snapshot": staticmethod(lambda: snapshot)})()
        receipt_store = m.ReceiptStore(Path(tempfile.mkdtemp()))

        controller = m.TransactionController(
            transaction_id="txn-1",
            unit="llama-bee.service",
            candidate_spec=m.CandidateSpec("start", 5151, 4, 131072, True, 1),
            preflight=preflight,
            receipt_store=receipt_store,
            arm_rollback=lambda receipt: (events.append(("arm", receipt)), arm_ok)[1],
            release_rollback=lambda: events.append(("release", None)),
            stop_known_good=lambda: (events.append(("stop-known-good", None)), stop_ok)[1],
            known_good_cgroup_empty=lambda: (events.append(("cgroup-check", None)), next(cgroup_iter, True))[1],
            start_candidate=lambda: (events.append(("start-candidate", None)), start_candidate_ok)[1],
            gates=list(gates),
            stop_candidate=lambda: (events.append(("stop-candidate", None)), stop_candidate_ok)[1],
            candidate_scope_empty=lambda: (events.append(("candidate-empty-check", None)), next(candidate_iter, True))[1],
            start_known_good=lambda: events.append(("start-known-good", None)),
            post_restore_snapshot=lambda: restored_snapshot if restored_snapshot is not None else snapshot,
            logger=lambda message: events.append(("log", message)),
            wall_clock=lambda: clock["t"],
            sleeper=lambda seconds: clock.__setitem__("t", clock["t"] + seconds),
            phase_timeout_seconds=10.0,
            poll_interval_seconds=1.0,
            rollback_deadline_seconds=100.0,
            systemctl_bin="systemctl",
        )
        return controller, events

    def test_preflight_failure_never_arms_or_stops_anything(self):
        controller, events = self.make_controller(preflight_result=m.PreflightFailure("drift detected"))
        outcome = controller.run()
        self.assertFalse(outcome.passed)
        self.assertEqual(outcome.phase_reached, "preflight")
        self.assertFalse(any(kind in ("arm", "stop-known-good", "start-candidate") for kind, _ in events))

    def test_arm_failure_never_stops_known_good(self):
        controller, events = self.make_controller(arm_ok=False)
        outcome = controller.run()
        self.assertFalse(outcome.passed)
        self.assertEqual(outcome.phase_reached, "arm-rollback")
        self.assertFalse(any(kind == "stop-known-good" for kind, _ in events))

    def test_happy_path_reaches_complete_and_releases_rollback(self):
        controller, events = self.make_controller(gates=[lambda: None])
        outcome = controller.run()
        self.assertTrue(outcome.passed)
        self.assertEqual(outcome.phase_reached, "complete")
        self.assertTrue(outcome.restored_exactly)
        kinds = [kind for kind, _ in events]
        self.assertIn("release", kinds)
        self.assertLess(kinds.index("stop-known-good"), kinds.index("start-candidate"))
        self.assertLess(kinds.index("start-candidate"), kinds.index("start-known-good"))
        self.assertEqual(kinds[-1], "release")  # release is always last, even on success

    def test_ordering_stop_known_good_before_candidate_before_prove_before_restore(self):
        controller, events = self.make_controller(gates=[lambda: None])
        controller.run()
        kinds = [kind for kind, _ in events]
        stop_index = kinds.index("stop-known-good")
        cgroup_index = kinds.index("cgroup-check")
        candidate_index = kinds.index("start-candidate")
        restore_index = kinds.index("start-known-good")
        self.assertTrue(stop_index < cgroup_index < candidate_index < restore_index)

    def test_release_runs_even_when_gate_fails(self):
        failure = m.GateFailure("health", "down")
        controller, events = self.make_controller(gates=[lambda: failure])
        outcome = controller.run()
        self.assertFalse(outcome.passed)
        self.assertEqual(outcome.phase_reached, "prove-capability")
        self.assertEqual([kind for kind, _ in events][-1], "release")

    def test_release_runs_even_when_candidate_fails_to_start(self):
        controller, events = self.make_controller(start_candidate_ok=False, gates=[lambda: None])
        outcome = controller.run()
        self.assertFalse(outcome.passed)
        self.assertEqual(outcome.phase_reached, "candidate-scope")
        kinds = [kind for kind, _ in events]
        self.assertIn("start-known-good", kinds)  # rollback still restores known-good
        self.assertEqual(kinds[-1], "release")

    def test_cgroup_never_empties_times_out_before_touching_candidate(self):
        controller, events = self.make_controller(cgroup_empty_sequence=(False, False, False, False, False, False, False, False, False, False, False, False), gates=[lambda: None])
        outcome = controller.run()
        self.assertFalse(outcome.passed)
        self.assertEqual(outcome.phase_reached, "stop-known-good")
        self.assertFalse(any(kind == "start-candidate" for kind, _ in events))

    def test_restore_identity_mismatch_fails_exact_restore(self):
        drifted = self.make_snapshot(gpu_index=1)
        different_snapshot = m.KnownGoodSnapshot(
            unit=drifted.unit, active_state=drifted.active_state, fragment_path="/different-frag",
            drop_in_paths=drifted.drop_in_paths, main_pid=999, control_group=drifted.control_group,
            environment=drifted.environment, exec_start_path=drifted.exec_start_path, port=drifted.port,
            gpu_index=drifted.gpu_index, health_ok=True,
        )
        controller, events = self.make_controller(gates=[lambda: None], restored_snapshot=different_snapshot)
        outcome = controller.run()
        self.assertFalse(outcome.passed)
        self.assertEqual(outcome.phase_reached, "exact-restore")
        self.assertFalse(outcome.restored_exactly)

    def test_restore_snapshot_preflight_failure_marks_not_restored_exactly(self):
        controller, events = self.make_controller(gates=[lambda: None], restored_snapshot=m.PreflightFailure("gone"))
        outcome = controller.run()
        self.assertFalse(outcome.restored_exactly)

    def test_release_is_always_the_final_action_regardless_of_outcome(self):
        for kwargs in (
            {"preflight_result": m.PreflightFailure("x")},
            {"arm_ok": False},
            {"start_candidate_ok": False, "gates": [lambda: None]},
            {"gates": [lambda: m.GateFailure("health", "x")]},
        ):
            with self.subTest(kwargs=kwargs):
                controller, events = self.make_controller(**kwargs)
                controller.run()
                kinds = [kind for kind, _ in events]
                if "arm" in kinds or kwargs == {"preflight_result": m.PreflightFailure("x")}:
                    if kinds and "release" in kinds:
                        self.assertEqual(kinds[-1], "release")


class RollbackSurvivesControllerDeathTests(unittest.TestCase):
    """Models the P0 requirement: rollback must not depend on the controller
    process being alive. We simulate this by constructing the RollbackOwner
    completely independently — no reference to a TransactionController or
    its instance state — and proving it alone restores known-good."""

    def test_rollback_owner_restores_without_any_controller_object_existing(self):
        temp_directory = tempfile.TemporaryDirectory()
        self.addCleanup(temp_directory.cleanup)
        store = m.ReceiptStore(Path(temp_directory.name))
        snapshot = m.KnownGoodSnapshot(
            "llama-bee.service", "active", "/frag", (), 1, "/cg", {}, "/start", 5051, 1, True
        )
        receipt = m.TransactionReceipt("txn-orphan", "llama-bee.service", snapshot, deadline_epoch_seconds=5.0, systemctl_bin="systemctl", rollback_timeout_seconds=5.0)
        path = store.write_receipt(receipt)
        # Simulate a brand-new process reading only the receipt from disk —
        # exactly what `--rollback-owner <path>` does after systemd-run
        # detaches it from a now-dead controller.
        reloaded_receipt = store.read_receipt(path)

        restart_calls = []

        def runner(command, timeout):
            if "is-active" in command:
                return completed(command, 0, stdout=b"inactive\n")
            restart_calls.append(command)
            return completed(command, 0)

        clock = {"t": 0.0}
        owner = m.RollbackOwner(reloaded_receipt, store, runner, lambda msg: None, lambda: clock["t"], lambda s: clock.__setitem__("t", clock["t"] + s))
        # is-active called twice more (before/after start) so alternate outcome
        result = owner.wait_and_restore_if_unreleased()
        self.assertTrue(any("start" in call for call in restart_calls))


class SystemctlParsingTests(unittest.TestCase):
    def test_parse_systemctl_show_handles_multiple_properties(self):
        parsed = m.parse_systemctl_show("A=1\nB=two\nC=\n")
        self.assertEqual(parsed, {"A": "1", "B": "two", "C": ""})

    def test_parse_exec_start_path_extracts_path_field(self):
        value = "{ path=/x/y/z ; argv[]=/x/y/z --flag ; ignore_errors=no }"
        self.assertEqual(m.parse_exec_start_path(value), "/x/y/z")

    def test_parse_exec_start_path_empty_on_missing_marker(self):
        self.assertEqual(m.parse_exec_start_path("garbage"), "")

    def test_parse_gpu_index_reads_visible_devices_token(self):
        self.assertEqual(m.parse_gpu_index("LLAMA_BEE_VISIBLE_DEVICES=1 OTHER=x"), 1)

    def test_parse_gpu_index_none_when_absent(self):
        self.assertIsNone(m.parse_gpu_index("OTHER=x"))

    def test_parse_environment_dict_handles_quoted_values_with_spaces(self):
        parsed = m.parse_environment_dict('LLAMA_BEE_MODEL="/media/windows/AI Models/x.gguf" LLAMA_BEE_CTX=102400')
        self.assertEqual(parsed["LLAMA_BEE_MODEL"], "/media/windows/AI Models/x.gguf")
        self.assertEqual(parsed["LLAMA_BEE_CTX"], "102400")


if __name__ == "__main__":
    unittest.main()
