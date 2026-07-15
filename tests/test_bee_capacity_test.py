import importlib.util
import hashlib
import json
import os
import subprocess
import sys
import tempfile
import threading
import unittest
from unittest import mock
from importlib.machinery import SourceFileLoader
from pathlib import Path

SCRIPT = Path(__file__).parents[1] / "bin/.local/bin/bee-capacity-test"
SPEC = importlib.util.spec_from_loader("bee_capacity_test", SourceFileLoader("bee_capacity_test", str(SCRIPT)))
m = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = m
SPEC.loader.exec_module(m)


def done(argv, code=0, stdout=b"", stderr=b""):
    return subprocess.CompletedProcess(argv, code, stdout=stdout, stderr=stderr)


ENV = {"LLAMA_BEE_MODEL": "/model.gguf", "LLAMA_BEE_MMPROJ": "/vision.gguf", "LLAMA_BEE_CTK": "q5_0", "LLAMA_BEE_CTV": "q4_1",
       "LLAMA_BEE_CACHE_RAM": "4096", "LLAMA_BEE_CHAT_TEMPLATE": "/template.jinja", "LLAMA_BEE_VISIBLE_DEVICES": "1", "LLAMA_BEE_CTX": "102400"}
FRAGMENT = "[Service]\nExecStart=/home/x/.local/bin/llama-bee-start\n"
DROP = "[Service]\nEnvironment=LLAMA_BEE_MMPROJ=/vision.gguf\n"
SHOW = ("ActiveState=active\nFragmentPath=/frag\nDropInPaths=/drop\nMainPID=42\nControlGroup=/cg\n"
        + "Environment=" + " ".join(f"{key}={value}" for key, value in ENV.items()) + "\n"
        + "ExecStart={ path=/home/x/.local/bin/llama-bee-start ; argv[]=/home/x/.local/bin/llama-bee-start ; ignore_errors=no }\n")


def approved():
    return m.ApprovedSnapshot(m.canonical_hash(FRAGMENT), {"/drop": m.canonical_hash(DROP)}, ("/home/x/.local/bin/llama-bee-start",), ENV)


def snapshot():
    return m.KnownGoodSnapshot("llama-bee.service", "/frag", m.canonical_hash(FRAGMENT), {"/drop": m.canonical_hash(DROP)}, ENV,
                               ("/home/x/.local/bin/llama-bee-start",), 42, "/cg", 5051, 1, approved().content_hash())


def candidate(**values):
    return m.CandidateSpec("/home/x/.local/bin/llama-bee-start", **values)


class PreflightTests(unittest.TestCase):
    def inspect(self, output=SHOW, files=None, health=lambda port: port == 5051, approved_snapshot=None):
        files = files or {"/frag": FRAGMENT, "/drop": DROP}
        return m.PreflightInspector(lambda command, timeout: done(command, stdout=output.encode()), "systemctl", "llama-bee.service",
                                    approved_snapshot or approved(), health, files.__getitem__, 1)

    def test_loaded_known_good_port_is_discovered_not_candidate_port(self):
        result = self.inspect().snapshot()
        self.assertIsInstance(result, m.KnownGoodSnapshot)
        self.assertEqual(result.port, 5051)

    def test_content_drift_is_refused_before_stop(self):
        result = self.inspect(files={"/frag": FRAGMENT + "# drift\n", "/drop": DROP}).snapshot()
        self.assertIn("differs", result.reason)

    def test_exec_and_environment_drift_are_refused(self):
        bad = m.ApprovedSnapshot(approved().fragment_hash, approved().drop_in_hashes, ("/other",), ENV)
        self.assertIn("differs", self.inspect(approved_snapshot=bad).snapshot().reason)

    def test_unapproved_environment_key_is_refused(self):
        output = SHOW.replace("LLAMA_BEE_CTX=102400", "LLAMA_BEE_CTX=102400 HOME=/surprise")
        self.assertIn("not allowlisted", self.inspect(output=output).snapshot().reason)

    def test_malformed_port_is_friendly_refusal(self):
        output = SHOW.replace("LLAMA_BEE_CTX=102400", "LLAMA_BEE_PORT=nope LLAMA_BEE_CTX=102400")
        self.assertIn("invalid", self.inspect(output=output).snapshot().reason)


class CandidateServiceTests(unittest.TestCase):
    def test_candidate_spec_accepts_requested_bounded_values_and_serializes_them(self):
        spec = candidate(n_gpu_layers=61, batch_size=1024, ubatch_size=256,
                         checkpoint_min_step=128, cache_ram_bytes=4 * m.MEBIBYTE)
        self.assertEqual(spec.to_json()["n_gpu_layers"], 61)
        self.assertEqual(spec.to_json()["batch_size"], 1024)
        self.assertEqual(spec.to_json()["ubatch_size"], 256)
        self.assertEqual(spec.to_json()["checkpoint_min_step"], 128)
        self.assertEqual(spec.to_json()["cache_ram_bytes"], 4 * m.MEBIBYTE)
        self.assertEqual(m.CandidateSpec.from_json(spec.to_json()), spec)

    def test_approved_snapshot_hash_commits_to_exact_candidate_values(self):
        spec = candidate(n_gpu_layers=61, batch_size=1024, ubatch_size=256)
        approved_with_candidate = m.ApprovedSnapshot(approved().fragment_hash, approved().drop_in_hashes,
                                                     approved().exec_start, approved().environment, spec)
        changed = m.ApprovedSnapshot(approved().fragment_hash, approved().drop_in_hashes,
                                     approved().exec_start, approved().environment, candidate(n_gpu_layers=62, batch_size=1024, ubatch_size=256))
        self.assertNotEqual(approved_with_candidate.content_hash(), changed.content_hash())
        self.assertEqual(m.ApprovedSnapshot.from_json({
            "fragment_hash": approved_with_candidate.fragment_hash,
            "drop_in_hashes": approved_with_candidate.drop_in_hashes,
            "exec_start": approved_with_candidate.exec_start,
            "environment": approved_with_candidate.environment,
            "candidate_spec": spec.to_json(),
        }).candidate_spec, spec)

    def test_candidate_spec_defaults_preserve_known_good_rendering_values(self):
        spec = candidate()
        self.assertEqual((spec.n_gpu_layers, spec.batch_size, spec.ubatch_size), (999, 2048, 512))
        self.assertNotIn("server_path", spec.to_json())
        self.assertNotIn("checkpoint_min_step", spec.to_json())
        self.assertNotIn("cache_ram_bytes", spec.to_json())
        legacy = spec.to_json()
        self.assertEqual(m.CandidateSpec.from_json(legacy).to_json(), legacy)

    def test_candidate_spec_rejects_invalid_or_conflicting_override_state(self):
        for values in (
            {"n_gpu_layers": -1}, {"n_gpu_layers": 1000}, {"batch_size": 0},
            {"batch_size": 2049}, {"batch_size": 256, "ubatch_size": 512},
            {"n_gpu_layers": True}, {"server_path": "/applications/beellama/build/bin/llama-server"},
            {"server_path": "relative/llama-server", "server_sha256": "a" * 64},
            {"server_path": "/applications/beellama/build/bin/not-server", "server_sha256": "a" * 64},
            {"server_path": "/applications/beellama/build/bin/llama-server", "server_sha256": "A" * 64},
            {"checkpoint_min_step": -1}, {"checkpoint_min_step": 131073},
            {"cache_ram_bytes": m.MEBIBYTE - 1}, {"cache_ram_bytes": m.MAX_CACHE_RAM_BYTES + m.MEBIBYTE},
        ):
            with self.subTest(values=values):
                with self.assertRaises(ValueError):
                    candidate(**values)
        with self.assertRaises(ValueError):
            candidate().environment({**ENV, "LLAMA_BEE_CANDIDATE_BATCH_SIZE": "$(touch /tmp/pwned)"})

    def test_explicit_server_binary_must_be_policy_bound_and_match_its_sha256(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "applications"
            binary = root / "beellama-candidate/build/bin/llama-server"
            binary.parent.mkdir(parents=True)
            binary.write_bytes(b"candidate-binary")
            binary.chmod(0o755)
            digest = hashlib.sha256(binary.read_bytes()).hexdigest()
            spec = candidate(server_path=str(binary), server_sha256=digest)
            spec.verify_server_identity(root)
            with self.assertRaisesRegex(ValueError, "SHA-256"):
                candidate(server_path=str(binary), server_sha256="0" * 64).verify_server_identity(root)
            outside = Path(directory) / "llama-server"
            outside.write_bytes(b"candidate-binary")
            outside.chmod(0o755)
            with self.assertRaisesRegex(ValueError, "~/applications"):
                candidate(server_path=str(outside), server_sha256=digest).verify_server_identity(root)

    def test_command_is_nonblocking_transient_service_never_scope(self):
        calls = []
        runner = lambda command, timeout: (calls.append(command), done(command))[1]
        self.assertTrue(m.start_transient_service(runner, "systemd-run", "candidate.service", ["/usr/bin/env", "-i"], 1,
                                                  m.CANDIDATE_SLICE))
        command = calls[0]
        self.assertIn("--user", command)
        self.assertIn("--no-block", command)
        self.assertIn("--property=Type=exec", command)
        self.assertIn("--slice=" + m.CANDIDATE_SLICE, command)
        self.assertNotIn("--scope", command)

    def test_candidate_is_exactly_bound_to_pre_recorded_slice_cgroup_and_mainpid(self):
        expected = m.CandidateIdentity("candidate.service", m.CANDIDATE_SLICE, "/candidate", None)
        runner = lambda command, timeout: done(command, stdout=(b"LoadState=loaded\nSlice=app-beecapacity.slice\n"
                                                                  b"ActiveState=active\nMainPID=123\nControlGroup=/candidate\nNTasks=2\n"))
        self.assertEqual(m.bind_running_candidate(runner, "systemctl", expected, 1),
                         m.CandidateIdentity("candidate.service", m.CANDIDATE_SLICE, "/candidate", 123))

    def test_expected_cgroup_is_deterministic_under_controlled_user_slice(self):
        identity = m.expected_candidate_identity("bee-capacity-candidate-t.service", uid=1000)
        self.assertEqual(identity.slice_name, "app-beecapacity.slice")
        self.assertEqual(identity.control_group,
                         "/user.slice/user-1000.slice/user@1000.service/app.slice/app-beecapacity.slice/bee-capacity-candidate-t.service")
        self.assertIsNone(identity.main_pid)

    def test_clean_env_replays_exact_managed_values_and_only_typed_candidate_overrides(self):
        argv = m.CandidateSpec("start", 5151, 4, 131072, 1, 61, 1024, 256).argv(ENV)
        self.assertEqual(argv[:2], ["/usr/bin/env", "-i"])
        values = dict(value.split("=", 1) for value in argv[2:-2])
        self.assertEqual(values["LLAMA_BEE_MMPROJ"], "/vision.gguf")
        self.assertEqual(values["LLAMA_BEE_CHAT_TEMPLATE"], "/template.jinja")
        self.assertEqual(values["LLAMA_BEE_CACHE_RAM"], "4096")
        self.assertEqual(values["LLAMA_BEE_PORT"], "5151")
        self.assertEqual(values["LLAMA_BEE_PARALLEL"], "4")
        self.assertEqual(values["LLAMA_BEE_CTX"], "131072")
        self.assertEqual(values["LLAMA_BEE_VISIBLE_DEVICES"], "1")
        self.assertEqual(values["LLAMA_BEE_CANDIDATE_OVERRIDES"], "1")
        self.assertEqual(values["LLAMA_BEE_CANDIDATE_N_GPU_LAYERS"], "61")
        self.assertEqual(values["LLAMA_BEE_CANDIDATE_BATCH_SIZE"], "1024")
        self.assertEqual(values["LLAMA_BEE_CANDIDATE_UBATCH_SIZE"], "256")
        self.assertEqual(values["PATH"], "/usr/bin:/bin")
        self.assertNotIn("HOME=/surprise", argv)

    def test_explicit_controls_replace_not_infer_their_managed_values(self):
        spec = candidate(server_path="/home/x/applications/beellama/build/bin/llama-server", server_sha256="a" * 64,
                         checkpoint_min_step=128, cache_ram_bytes=8 * m.MEBIBYTE)
        values = spec.environment({**ENV, "LLAMA_BEE_SERVER": "/ambient/server", "LLAMA_BEE_CHECKPOINT_MIN_STEP": "256"})
        self.assertNotIn("LLAMA_BEE_SERVER", values)
        self.assertNotIn("LLAMA_BEE_CHECKPOINT_MIN_STEP", values)
        self.assertNotIn("LLAMA_BEE_CACHE_RAM", values)
        self.assertEqual(values["LLAMA_BEE_CANDIDATE_SERVER_PATH"], spec.server_path)
        self.assertEqual(values["LLAMA_BEE_CANDIDATE_SERVER_SHA256"], "a" * 64)
        self.assertEqual(values["LLAMA_BEE_CANDIDATE_CHECKPOINT_MIN_STEP"], "128")
        self.assertEqual(values["LLAMA_BEE_CANDIDATE_CACHE_RAM_MIB"], "8")

    def test_default_wrapper_parallel_stays_one(self):
        result = subprocess.run([str(Path(__file__).parents[1] / "bin/.local/bin/llama-bee-start"), "--print-command"],
                                capture_output=True, text=True, env={key: value for key, value in os.environ.items() if key != "LLAMA_BEE_PARALLEL"})
        self.assertIn("-np 1", result.stdout)


class ReceiptAndOwnerTests(unittest.TestCase):
    def make_owner(self, receipt_mutate=None, show=b"ActiveState=inactive\nNTasks=0\n", verify=True):
        directory = tempfile.TemporaryDirectory(); self.addCleanup(directory.cleanup)
        store = m.ReceiptStore(Path(directory.name) / "custom-state")
        expected = m.expected_candidate_identity("candidate.service")
        identity = m.CandidateIdentity(expected.unit, expected.slice_name, expected.control_group, 123)
        receipt = m.TransactionReceipt("t", "llama-bee.service", "candidate.service", snapshot(), 100, 5, 0,
                                       candidate_identity=identity)
        if receipt_mutate: receipt_mutate(receipt)
        path = store.write(receipt)
        calls = []
        def runner(command, timeout):
            calls.append(command)
            if "show" in command and command[3] == "candidate.service":
                return done(command, stdout=(f"LoadState=loaded\nSlice={identity.slice_name}\nControlGroup={identity.control_group}\nMainPID=0\n".encode() + show))
            return done(command)
        inspector = type("I", (), {"snapshot": lambda self: snapshot() if verify else m.PreflightFailure("bad")})()
        owner = m.RollbackOwner(path, runner, inspector, lambda x: None, lambda: 10, lambda x: None,
                                cgroup_members=lambda path: (False, (), ()), pid_cgroup=lambda pid: None)
        return owner, store, path, calls

    def test_custom_state_dir_is_private_atomic_and_owner_derives_it_from_receipt(self):
        owner, store, path, _ = self.make_owner()
        self.assertEqual(owner.store.root, store.root)
        self.assertEqual((path.parent.stat().st_mode & 0o777), 0o700)
        self.assertEqual((path.stat().st_mode & 0o777), 0o600)

    def test_atomic_phase_updates_preserve_prior_owner_state(self):
        owner, store, path, _ = self.make_owner()
        store.update(path, lambda receipt: setattr(receipt, "owner_phase", "stopping-candidate"))
        store.update(path, lambda receipt: setattr(receipt, "controller_phase", "cleanup-requested"))
        receipt = store.read(path)
        self.assertEqual(receipt.owner_phase, "stopping-candidate")
        self.assertEqual(receipt.controller_phase, "cleanup-requested")

    def test_receipt_persists_exact_candidate_values_without_changing_legacy_owner_recovery(self):
        exact = candidate(n_gpu_layers=61, batch_size=1024, ubatch_size=256)
        directory = tempfile.TemporaryDirectory(); self.addCleanup(directory.cleanup)
        store = m.ReceiptStore(Path(directory.name))
        path = store.write(m.TransactionReceipt("t", "llama-bee.service", "candidate.service", snapshot(), 100, 5, 0,
                                                candidate_spec=exact))
        self.assertEqual(store.read(path).candidate_spec, exact)
        # Existing receipts omit candidate_spec. The rollback owner still uses
        # their unchanged known-good identity/hash semantics to recover.
        legacy = store.write(m.TransactionReceipt("legacy", "llama-bee.service", "candidate.service", snapshot(), 100, 5, 0,
                                                  candidate_identity=m.expected_candidate_identity("candidate.service")))
        self.assertIsNone(store.read(legacy).candidate_spec)

    def test_only_owner_writes_restore_ack(self):
        owner, store, path, calls = self.make_owner()
        self.assertTrue(owner.recover_with("systemctl", 1))
        self.assertTrue(store.read(path).restore_ack)
        self.assertIn(["systemctl", "--user", "start", "llama-bee.service"], calls)

    def test_failed_stop_show_or_nonzero_tasks_blocks_restore(self):
        for show in (b"", b"ActiveState=inactive\nNTasks=1\n"):
            with self.subTest(show=show):
                owner, store, path, calls = self.make_owner(show=show)
                self.assertFalse(owner.recover_with("systemctl", 1))
                self.assertFalse(store.read(path).restore_ack)
                self.assertFalse(any(command[-2:] == ["start", "llama-bee.service"] for command in calls))

    def test_failed_stop_return_code_blocks_restore(self):
        owner, store, path, calls = self.make_owner()
        original = owner.runner
        def failed_stop(command, timeout):
            if command[2] == "stop":
                return done(command, code=1)
            return original(command, timeout)
        owner.runner = failed_stop
        self.assertFalse(owner.recover_with("systemctl", 1))
        self.assertFalse(store.read(path).restore_ack)
        self.assertFalse(any(command[-2:] == ["start", "llama-bee.service"] for command in calls))

    def test_failed_show_return_code_blocks_restore(self):
        owner, store, path, calls = self.make_owner()
        original = owner.runner
        def failed_show(command, timeout):
            if command[2] == "show":
                return done(command, code=1)
            return original(command, timeout)
        owner.runner = failed_show
        self.assertFalse(owner.recover_with("systemctl", 1))
        self.assertFalse(store.read(path).restore_ack)
        self.assertFalse(any(command[-2:] == ["start", "llama-bee.service"] for command in calls))

    def test_owner_rejects_nonderived_candidate_location_before_cleanup(self):
        owner, store, path, calls = self.make_owner(
            receipt_mutate=lambda receipt: setattr(receipt, "candidate_identity",
                                                    m.CandidateIdentity("candidate.service", m.CANDIDATE_SLICE, "/wrong", 123)))
        self.assertFalse(owner.recover_with("systemctl", 1))
        self.assertEqual(store.read(path).owner_phase, "candidate-identity-invalid")
        self.assertFalse(any(command[2] in {"stop", "start"} for command in calls))

    def test_controller_exception_leaves_owner_armed(self):
        owner, store, path, _ = self.make_owner()
        self.assertFalse(store.read(path).restore_ack)
        self.assertTrue(owner.recover_with("systemctl", 1))

    def test_deadline_or_stale_heartbeat_authorizes_cleanup_not_blind_start(self):
        owner, store, path, calls = self.make_owner(receipt_mutate=lambda receipt: setattr(receipt, "deadline", 1), show=b"ActiveState=active\nNTasks=1\n")
        # Owner is at t=10, but must not start known-good while candidate lives.
        self.assertFalse(owner.recover_with("systemctl", 1))
        self.assertFalse(any(command[-2:] == ["start", "llama-bee.service"] for command in calls))

    def test_stale_heartbeat_transfers_cleanup_authority_to_owner(self):
        owner, store, path, calls = self.make_owner()
        # run() exits after one independently verified restore, driven solely
        # by receipt heartbeat state; no controller object exists.
        self.assertTrue(owner.run("systemctl", 1))
        self.assertTrue(store.read(path).restore_ack)
        self.assertIn(["systemctl", "--user", "stop", "candidate.service"], calls)


class CandidateTeardownEvidenceTests(unittest.TestCase):
    expected_identity = m.expected_candidate_identity("candidate.service")
    identity = m.CandidateIdentity(expected_identity.unit, expected_identity.slice_name, expected_identity.control_group, 123)

    @staticmethod
    def state(*, load="loaded", slice_name=m.CANDIDATE_SLICE, active="inactive", pid=0, cgroup=None, tasks=0):
        if cgroup is None:
            cgroup = CandidateTeardownEvidenceTests.identity.control_group
        return f"LoadState={load}\nSlice={slice_name}\nActiveState={active}\nMainPID={pid}\nControlGroup={cgroup}\nNTasks={tasks}\n".encode()

    def test_crashed_or_oom_unloaded_candidate_restores_after_proven_absence(self):
        calls = []
        def runner(command, timeout):
            calls.append(command)
            return done(command, stdout=self.state(load="not-found", cgroup="", tasks=0))
        proven, identity = m.stop_and_prove_candidate_absent(runner, "systemctl", "candidate.service", self.identity, 1,
                                                              lambda path: (False, (), ()), lambda pid: None)
        self.assertTrue(proven)
        self.assertEqual(identity, self.identity)
        self.assertFalse(any(command[2] == "stop" for command in calls))

    def test_owner_restores_after_crash_self_unload_with_recorded_identity(self):
        directory = tempfile.TemporaryDirectory(); self.addCleanup(directory.cleanup)
        store = m.ReceiptStore(Path(directory.name))
        path = store.write(m.TransactionReceipt("t", "llama-bee.service", "candidate.service", snapshot(), 100, 5, 0,
                                                candidate_identity=self.identity))
        starts = []
        def runner(command, timeout):
            if command[2] == "show":
                return done(command, stdout=self.state(load="not-found", cgroup="", tasks=0))
            starts.append(command)
            return done(command)
        inspector = type("I", (), {"snapshot": lambda self: snapshot()})()
        owner = m.RollbackOwner(path, runner, inspector, lambda message: None, lambda: 10, lambda seconds: None,
                                cgroup_members=lambda path: (False, (), ()), pid_cgroup=lambda pid: None)
        self.assertTrue(owner.recover_with("systemctl", 1))
        self.assertTrue(store.read(path).restore_ack)
        self.assertIn(["systemctl", "--user", "start", "llama-bee.service"], starts)

    def test_rc5_is_accepted_only_after_post_stop_not_found_and_empty_cgroup(self):
        shows = iter([self.state(), self.state(load="not-found", cgroup="", tasks=0)])
        def runner(command, timeout):
            if command[2] == "stop":
                return done(command, code=5, stderr=b"Unit not loaded")
            return done(command, stdout=next(shows))
        proven, _ = m.stop_and_prove_candidate_absent(runner, "systemctl", "candidate.service", self.identity, 1,
                                                       lambda path: (False, (), ()), lambda pid: None)
        self.assertTrue(proven)

    def test_rc5_with_nonempty_or_uninspectable_cgroup_blocks_restore(self):
        for cgroup in (lambda path: (True, (999,), (999,)), lambda path: (_ for _ in ()).throw(OSError("uninspectable"))):
            with self.subTest(cgroup=cgroup):
                shows = iter([self.state(), self.state(load="not-found", cgroup="", tasks=0)])
                def runner(command, timeout):
                    if command[2] == "stop": return done(command, code=5)
                    return done(command, stdout=next(shows))
                proven, _ = m.stop_and_prove_candidate_absent(runner, "systemctl", "candidate.service", self.identity, 1, cgroup, lambda pid: None)
                self.assertFalse(proven)

    def test_missing_cgroup_path_and_definitively_unloaded_unit_is_safe(self):
        runner = lambda command, timeout: done(command, stdout=self.state(load="not-found", cgroup="", tasks=0))
        proven, _ = m.stop_and_prove_candidate_absent(runner, "systemctl", "candidate.service", self.identity, 1,
                                                       lambda path: (False, (), ()), lambda pid: "/other.slice")
        self.assertTrue(proven)

    def test_malformed_receipt_without_expected_identity_remains_fail_closed(self):
        runner = lambda command, timeout: done(command, stdout=self.state(load="not-found", cgroup="", tasks=0))
        proven, identity = m.stop_and_prove_candidate_absent(runner, "systemctl", "candidate.service", None, 1,
                                                              lambda path: (False, (), ()), lambda pid: None)
        self.assertFalse(proven)
        self.assertIsNone(identity)

    def test_reused_pid_outside_cgroup_is_safe_but_pid_in_cgroup_blocks(self):
        self.assertTrue(m.candidate_cgroup_is_proven_empty(self.identity, lambda path: (False, (), ()), lambda pid: "/other.slice"))
        self.assertFalse(m.candidate_cgroup_is_proven_empty(self.identity, lambda path: (False, (), ()), lambda pid: self.identity.control_group))

    def test_live_unit_with_mismatched_pid_is_not_accepted(self):
        runner = lambda command, timeout: done(command, stdout=self.state(active="active", pid=999, tasks=1))
        proven, _ = m.stop_and_prove_candidate_absent(runner, "systemctl", "candidate.service", self.identity, 1,
                                                       lambda path: (False, (), ()), lambda pid: None)
        self.assertFalse(proven)

    def test_live_stop_path_still_requires_stop_then_empty_cgroup(self):
        shows = iter([self.state(active="active", pid=123, tasks=2), self.state(tasks=0)])
        calls = []
        def runner(command, timeout):
            calls.append(command)
            if command[2] == "stop": return done(command)
            return done(command, stdout=next(shows))
        proven, _ = m.stop_and_prove_candidate_absent(runner, "systemctl", "candidate.service", self.identity, 1,
                                                       lambda path: (True, (), ()), lambda pid: None)
        self.assertTrue(proven)
        self.assertIn(["systemctl", "--user", "stop", "candidate.service"], calls)

    def test_owner_retries_after_deadline_until_self_unload_is_proven(self):
        directory = tempfile.TemporaryDirectory(); self.addCleanup(directory.cleanup)
        store = m.ReceiptStore(Path(directory.name))
        path = store.write(m.TransactionReceipt("t", "llama-bee.service", "candidate.service", snapshot(), 1, 1, 0,
                                                candidate_identity=self.identity))
        attempts = {"count": 0}
        def runner(command, timeout):
            if command[2] == "show":
                return done(command, stdout=self.state(load="not-found", cgroup="", tasks=0))
            return done(command)
        def cgroup(path):
            attempts["count"] += 1
            return (True, (99,), ()) if attempts["count"] == 1 else (False, (), ())
        inspector = type("I", (), {"snapshot": lambda self: snapshot()})()
        owner = m.RollbackOwner(path, runner, inspector, lambda message: None, lambda: 10,
                                lambda seconds: None, cgroup_members=cgroup, pid_cgroup=lambda pid: None)
        self.assertTrue(owner.run("systemctl", 1))
        self.assertEqual(store.read(path).restore_attempts, 1)

    def test_controller_death_before_systemd_run_restores_from_pre_recorded_expected_cgroup(self):
        directory = tempfile.TemporaryDirectory(); self.addCleanup(directory.cleanup)
        store = m.ReceiptStore(Path(directory.name))
        identity = m.expected_candidate_identity("bee-capacity-candidate-before.service", uid=1000)
        path = store.write(m.TransactionReceipt("before", "llama-bee.service", identity.unit, snapshot(), 100, 5, 0,
                                                candidate_identity=identity))
        calls = []
        def runner(command, timeout):
            calls.append(command)
            if command[2] == "show" and command[3] == identity.unit:
                return done(command, stdout=self.state(load="not-found", slice_name="", cgroup="", tasks=0))
            return done(command)
        inspector = type("I", (), {"snapshot": lambda self: snapshot()})()
        owner = m.RollbackOwner(path, runner, inspector, lambda message: None, lambda: 10, lambda seconds: None,
                                cgroup_members=lambda path: (False, (), ()), pid_cgroup=lambda pid: None)
        self.assertTrue(owner.recover_with("systemctl", 1))
        self.assertIsNone(store.read(path).candidate_identity.main_pid)
        self.assertIn(["systemctl", "--user", "start", "llama-bee.service"], calls)

    def test_controller_death_during_launch_binds_live_expected_candidate_before_stop(self):
        directory = tempfile.TemporaryDirectory(); self.addCleanup(directory.cleanup)
        store = m.ReceiptStore(Path(directory.name))
        identity = m.expected_candidate_identity("bee-capacity-candidate-live.service", uid=1000)
        path = store.write(m.TransactionReceipt("live", "llama-bee.service", identity.unit, snapshot(), 100, 5, 0,
                                                candidate_identity=identity))
        states = iter([
            self.state(active="active", pid=432, cgroup=identity.control_group, tasks=1),
            self.state(active="inactive", pid=0, cgroup=identity.control_group, tasks=0),
        ])
        bound_at_stop = []
        def runner(command, timeout):
            if command[2] == "show" and command[3] == identity.unit:
                return done(command, stdout=next(states))
            if command[2] == "stop":
                bound_at_stop.append(store.read(path).candidate_identity.main_pid)
            return done(command)
        inspector = type("I", (), {"snapshot": lambda self: snapshot()})()
        owner = m.RollbackOwner(path, runner, inspector, lambda message: None, lambda: 10, lambda seconds: None,
                                cgroup_members=lambda path: (True, (), ()), pid_cgroup=lambda pid: None)
        self.assertTrue(owner.recover_with("systemctl", 1))
        self.assertEqual(bound_at_stop, [432])
        self.assertEqual(store.read(path).candidate_identity.main_pid, 432)

    def test_controller_death_after_self_unload_before_bind_restores_from_expected_cgroup(self):
        directory = tempfile.TemporaryDirectory(); self.addCleanup(directory.cleanup)
        store = m.ReceiptStore(Path(directory.name))
        identity = m.expected_candidate_identity("bee-capacity-candidate-crashed.service", uid=1000)
        path = store.write(m.TransactionReceipt("crashed", "llama-bee.service", identity.unit, snapshot(), 100, 5, 0,
                                                candidate_identity=identity))
        calls = []
        def runner(command, timeout):
            calls.append(command)
            if command[2] == "show" and command[3] == identity.unit:
                return done(command, stdout=self.state(load="not-found", slice_name="", cgroup="", tasks=0))
            return done(command)
        inspector = type("I", (), {"snapshot": lambda self: snapshot()})()
        owner = m.RollbackOwner(path, runner, inspector, lambda message: None, lambda: 10, lambda seconds: None,
                                cgroup_members=lambda path: (False, (), ()), pid_cgroup=lambda pid: None)
        self.assertTrue(owner.recover_with("systemctl", 1))
        self.assertTrue(store.read(path).restore_ack)
        self.assertIn(["systemctl", "--user", "start", "llama-bee.service"], calls)

    def test_pre_recorded_expected_cgroup_nonempty_or_mismatched_blocks_restore(self):
        for state, cgroup in (
            (self.state(load="not-found", slice_name="", cgroup="", tasks=0), lambda path: (True, (77,), ())),
            (self.state(active="active", pid=77, cgroup="/unexpected", tasks=1), lambda path: (False, (), ())),
        ):
            with self.subTest(state=state, cgroup=cgroup):
                identity = m.expected_candidate_identity("bee-capacity-candidate-uncertain.service", uid=1000)
                starts = []
                def runner(command, timeout):
                    if command[2] == "show":
                        return done(command, stdout=state)
                    starts.append(command)
                    return done(command)
                proven, _ = m.stop_and_prove_candidate_absent(runner, "systemctl", identity.unit, identity, 1,
                                                               cgroup, lambda pid: None)
                self.assertFalse(proven)
                self.assertFalse(any(command[2] == "start" for command in starts))


class GateTests(unittest.TestCase):
    def test_nested_props_and_extra_fields_drift_reject(self):
        fixture = {"total_slots": 1, "default_generation_settings": {"n_ctx": 1, "nested": {"a": True}}}
        original = m.http_get_json
        m.http_get_json = lambda url, timeout: {"total_slots": 4, "default_generation_settings": {"n_ctx": 131072, "nested": {"a": True, "extra": 1}}}
        try:
            failure = m.make_props_gate("http://x", fixture, 4, 131072, 1)()
        finally:
            m.http_get_json = original
        self.assertIn("key drift", failure.reason)

    def test_actual_overlap_requires_barrier_slots_and_correlated_completions(self):
        ids = {}
        entered = threading.Barrier(5)
        release = threading.Event()
        def post(url, payload, timeout):
            ids[payload["id_slot"]] = payload["request_id"]
            entered.wait(timeout=timeout)
            release.wait(timeout=timeout)
            return 200, {"request_id": payload["request_id"], "id_slot": payload["id_slot"]}
        def slots(url, timeout):
            # Block until every request has entered the mock server.  Then the
            # observation happens while all four remain in flight.
            entered.wait(timeout=timeout)
            observed = [{"id_slot": index, "request_id": request_id, "is_processing": True} for index, request_id in ids.items()]
            release.set()
            return observed
        failure = m.run_overlap_probe("http://x", 2, slots, post)
        self.assertIsNone(failure)

    def test_missing_server_observable_slot_oracle_fails_closed(self):
        failure = m.run_overlap_probe("http://x", 1, lambda url, timeout: [{"id_slot": 0}], lambda url, payload, timeout: (200, {"request_id": payload["request_id"], "id_slot": payload["id_slot"]}))
        self.assertIsNotNone(failure)


class ControllerTests(unittest.TestCase):
    def test_controller_refuses_missing_pre_recorded_identity_before_any_effect(self):
        directory = tempfile.TemporaryDirectory(); self.addCleanup(directory.cleanup)
        store = m.ReceiptStore(Path(directory.name)); path = store.write(m.TransactionReceipt("t", "llama-bee.service", "candidate.service", snapshot(), 100, 5, 0))
        calls = []
        def runner(command, timeout):
            calls.append(command)
            if "show" in command: return done(command, stdout=b"ActiveState=inactive\nNTasks=0\n")
            return done(command)
        controller = m.TransactionController(path, store, type("I", (), {})(), runner, "systemctl", "systemd-run", m.CandidateSpec("start"), {}, 1, 1, lambda x: None, lambda: 0, lambda x: None)
        self.assertFalse(controller.run())
        self.assertFalse(store.read(path).restore_ack)
        self.assertEqual(calls, [])

    def test_controller_refuses_missing_or_mismatched_candidate_spec_before_any_effect(self):
        directory = tempfile.TemporaryDirectory(); self.addCleanup(directory.cleanup)
        store = m.ReceiptStore(Path(directory.name)); candidate_unit = m.candidate_unit_name("spec")
        expected = m.expected_candidate_identity(candidate_unit)
        path = store.write(m.TransactionReceipt("spec", "llama-bee.service", candidate_unit, snapshot(), 100, 5, 0,
                                                candidate_identity=expected, candidate_spec=candidate(batch_size=1024, ubatch_size=256)))
        calls = []
        controller = m.TransactionController(path, store, type("I", (), {})(),
                                             lambda command, timeout: calls.append(command), "systemctl", "systemd-run",
                                             candidate(n_gpu_layers=61, batch_size=1024, ubatch_size=256), {}, 1, 1,
                                             lambda x: None, lambda: 0, lambda x: None)
        self.assertFalse(controller.run())
        self.assertEqual(calls, [])

    def test_controller_exception_leaves_durable_owner_armed(self):
        directory = tempfile.TemporaryDirectory(); self.addCleanup(directory.cleanup)
        store = m.ReceiptStore(Path(directory.name)); candidate_unit = m.candidate_unit_name("t")
        spec = candidate()
        path = store.write(m.TransactionReceipt("t", "llama-bee.service", candidate_unit, snapshot(), 100, 5, 0,
                                                candidate_identity=m.expected_candidate_identity(candidate_unit), candidate_spec=spec))
        def runner(command, timeout):
            if command[0] == "systemd-run":
                raise RuntimeError("controller crashed during candidate launch")
            if command[2] == "show":
                return done(command, stdout=b"ActiveState=inactive\nNTasks=0\n")
            return done(command)
        controller = m.TransactionController(path, store, type("I", (), {})(), runner, "systemctl", "systemd-run", spec, {}, 1, 1, lambda x: None, lambda: 0, lambda x: None)
        with self.assertRaises(RuntimeError):
            controller.run()
        receipt = store.read(path)
        self.assertFalse(receipt.restore_ack)
        self.assertEqual(receipt.controller_phase, "starting-candidate")

    def test_controller_atomically_binds_exact_observed_identity_after_launch(self):
        directory = tempfile.TemporaryDirectory(); self.addCleanup(directory.cleanup)
        store = m.ReceiptStore(Path(directory.name)); candidate_unit = m.candidate_unit_name("bound")
        expected = m.expected_candidate_identity(candidate_unit)
        spec = candidate()
        path = store.write(m.TransactionReceipt("bound", "llama-bee.service", candidate_unit, snapshot(), 100, 5, 0,
                                                candidate_identity=expected, candidate_spec=spec))
        calls = []
        def runner(command, timeout):
            calls.append(command)
            if command[2] != "show":
                return done(command)
            if command[3] == "llama-bee.service":
                return done(command, stdout=b"ActiveState=inactive\nNTasks=0\n")
            return done(command, stdout=(f"LoadState=loaded\nSlice={expected.slice_name}\nActiveState=active\n"
                                         f"MainPID=321\nControlGroup={expected.control_group}\nNTasks=1\n").encode())
        original = m.http_get_json
        m.http_get_json = lambda url, timeout: None  # stop at the first mocked proof gate
        try:
            controller = m.TransactionController(path, store, type("I", (), {})(), runner, "systemctl", "systemd-run",
                                                 spec, {}, 1, 1, lambda x: None, lambda: 0, lambda x: None)
            self.assertFalse(controller.run())
        finally:
            m.http_get_json = original
        self.assertEqual(store.read(path).candidate_identity,
                         m.CandidateIdentity(candidate_unit, expected.slice_name, expected.control_group, 321))
        launch = next(command for command in calls if command[0] == "systemd-run")
        self.assertIn("--slice=" + expected.slice_name, launch)


class CliTests(unittest.TestCase):
    def test_dry_run_has_no_effects(self):
        result = subprocess.run([sys.executable, str(SCRIPT)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0)
        self.assertIn("read-only plan", result.stdout)

    def test_dry_run_does_not_construct_or_call_effect_boundary(self):
        original = m.default_runner
        m.default_runner = lambda command, timeout: self.fail(f"unexpected effect: {command}")
        try:
            self.assertEqual(m.main([]), 0)
        finally:
            m.default_runner = original

    def test_dry_run_prints_requested_effective_candidate_values_without_effects(self):
        original = m.default_runner
        m.default_runner = lambda command, timeout: self.fail(f"unexpected effect: {command}")
        try:
            self.assertEqual(m.main(["--n-gpu-layers", "61", "--batch-size", "1024", "--ubatch-size", "256",
                                     "--checkpoint-min-step", "128", "--cache-ram-bytes", str(8 * m.MEBIBYTE)]), 0)
        finally:
            m.default_runner = original

    def test_apply_refuses_missing_or_mismatched_approved_candidate_before_effects(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Path(directory) / "props.json"; fixture.write_text("{}")
            missing = Path(directory) / "missing.json"
            mismatch = Path(directory) / "mismatch.json"
            base = {"fragment_hash": "x", "drop_in_hashes": {}, "exec_start": [m.DEFAULT_START_SCRIPT], "environment": ENV}
            missing.write_text(json.dumps(base))
            mismatch.write_text(json.dumps({**base, "candidate_spec": m.CandidateSpec(m.DEFAULT_START_SCRIPT, n_gpu_layers=61, batch_size=1024, ubatch_size=256).to_json()}))
            original = m.default_runner
            m.default_runner = lambda command, timeout: self.fail(f"unexpected effect: {command}")
            try:
                self.assertEqual(m.main(["--apply", "--props-fixture", str(fixture), "--approved-snapshot", str(missing)]), 2)
                self.assertEqual(m.main(["--apply", "--props-fixture", str(fixture), "--approved-snapshot", str(mismatch)]), 2)
            finally:
                m.default_runner = original

    def test_malformed_environment_is_friendly(self):
        env = {**os.environ, "BEE_CAPACITY_TEST_PHASE_TIMEOUT": "broken"}
        result = subprocess.run([sys.executable, str(SCRIPT)], capture_output=True, text=True, env=env)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must be a number", result.stderr)

    def test_conservative_deadline_validation(self):
        result = subprocess.run([sys.executable, str(SCRIPT), "--rollback-deadline-seconds", "1"], capture_output=True, text=True)
        self.assertIn("five phase budgets", result.stderr)

    def test_candidate_cli_bounds_reject_injection_shaped_or_conflicting_values(self):
        for arguments in (
            ["--n-gpu-layers", "1000"], ["--batch-size", "$(touch /tmp/pwned)"],
            ["--batch-size", "256", "--ubatch-size", "512"],
            ["--server-path", "/applications/beellama/build/bin/llama-server"],
            ["--server-path", "relative/llama-server", "--server-sha256", "a" * 64],
            ["--checkpoint-min-step", "-1"], ["--cache-ram-bytes", str(m.MEBIBYTE - 1)],
        ):
            with self.subTest(arguments=arguments):
                result = subprocess.run([sys.executable, str(SCRIPT), *arguments], capture_output=True, text=True)
                self.assertNotEqual(result.returncode, 0)

    def test_dry_plan_rejects_out_of_policy_or_hash_mismatched_server_before_output(self):
        invalid = subprocess.run([sys.executable, str(SCRIPT), "--server-path", "/tmp/llama-server",
                                  "--server-sha256", "a" * 64], capture_output=True, text=True)
        self.assertNotEqual(invalid.returncode, 0)
        self.assertIn("no effects were performed", invalid.stderr)
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            binary = home / "applications/beellama-candidate/build/bin/llama-server"
            binary.parent.mkdir(parents=True)
            binary.write_bytes(b"candidate-binary")
            binary.chmod(0o755)
            mismatched = subprocess.run([sys.executable, str(SCRIPT), "--server-path", str(binary),
                                        "--server-sha256", "0" * 64], capture_output=True, text=True,
                                       env={**os.environ, "HOME": str(home)})
        self.assertNotEqual(mismatched.returncode, 0)
        self.assertIn("SHA-256 does not match", mismatched.stderr)

    def test_apply_refuses_server_identity_failure_before_any_effect(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Path(directory) / "props.json"; fixture.write_text("{}")
            snapshot_path = Path(directory) / "approved.json"
            spec = m.CandidateSpec(m.DEFAULT_START_SCRIPT, server_path="/home/x/applications/beellama/build/bin/llama-server", server_sha256="0" * 64)
            snapshot_path.write_text(json.dumps({"fragment_hash": "x", "drop_in_hashes": {},
                                                  "exec_start": [m.DEFAULT_START_SCRIPT], "environment": ENV,
                                                  "candidate_spec": spec.to_json()}))
            original = m.default_runner
            m.default_runner = lambda command, timeout: self.fail(f"unexpected effect: {command}")
            try:
                with mock.patch.object(m.CandidateSpec, "verify_server_identity", side_effect=ValueError("server binary SHA-256 does not match server_sha256")):
                    self.assertEqual(m.main(["--apply", "--props-fixture", str(fixture),
                                             "--approved-snapshot", str(snapshot_path),
                                             "--server-path", spec.server_path, "--server-sha256", spec.server_sha256]), 2)
            finally:
                m.default_runner = original


if __name__ == "__main__":
    unittest.main()
