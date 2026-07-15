import importlib.util
import subprocess
import sys
import unittest
from importlib.machinery import SourceFileLoader
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "bin/.local/bin/bee-capacity-test"
SPEC = importlib.util.spec_from_loader("bee_capacity_test", SourceFileLoader("bee_capacity_test", str(SCRIPT)))
assert SPEC and SPEC.loader
capacity_module = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = capacity_module
SPEC.loader.exec_module(capacity_module)


def make_config(**overrides):
    arguments = capacity_module.parse_arguments([])
    for name, value in overrides.items():
        setattr(arguments, name, value)
    return capacity_module.make_config(arguments)


class ArgvAndPlanTests(unittest.TestCase):
    def test_defaults_match_the_specified_candidate(self):
        config = make_config()
        self.assertEqual(config.port, 5151)
        self.assertEqual(config.parallel, 4)
        self.assertEqual(config.ctx_size, 131072)
        self.assertTrue(config.kv_unified)

    def test_candidate_argv_includes_kv_unified_by_default(self):
        config = make_config()
        self.assertIn("--kv-unified", config.candidate_argv())

    def test_no_kv_unified_flag_omits_it(self):
        arguments = capacity_module.parse_arguments(["--no-kv-unified"])
        config = capacity_module.make_config(arguments)
        self.assertNotIn("--kv-unified", config.candidate_argv())

    def test_candidate_env_overrides_port_parallel_ctx_only(self):
        config = make_config()
        base_env = {"LLAMA_BEE_MODEL": "/models/x.gguf", "PATH": "/usr/bin"}
        env = config.candidate_env(base_env)
        self.assertEqual(env["LLAMA_BEE_PORT"], "5151")
        self.assertEqual(env["LLAMA_BEE_PARALLEL"], "4")
        self.assertEqual(env["LLAMA_BEE_CTX"], "131072")
        self.assertEqual(env["LLAMA_BEE_MODEL"], "/models/x.gguf")
        self.assertEqual(env["PATH"], "/usr/bin")

    def test_plan_mentions_kv_context_sharing_warning(self):
        config = make_config()
        plan = capacity_module.render_plan(config, {})
        self.assertIn("share one KV cache", plan)
        self.assertIn("--apply", plan)


class ValidationTests(unittest.TestCase):
    def test_rejects_nonpositive_parallel(self):
        arguments = capacity_module.parse_arguments(["--parallel", "0"])
        with self.assertRaises(ValueError):
            capacity_module.make_config(arguments)

    def test_rejects_negative_parallel(self):
        arguments = capacity_module.parse_arguments(["--parallel", "-1"])
        with self.assertRaises(ValueError):
            capacity_module.make_config(arguments)

    def test_rejects_nonpositive_ctx_size(self):
        arguments = capacity_module.parse_arguments(["--ctx-size", "0"])
        with self.assertRaises(ValueError):
            capacity_module.make_config(arguments)

    def test_rejects_nonpositive_timeout(self):
        arguments = capacity_module.parse_arguments(["--timeout-seconds", "0"])
        with self.assertRaises(ValueError):
            capacity_module.make_config(arguments)

    def test_rejects_nonpositive_poll_interval(self):
        arguments = capacity_module.parse_arguments(["--poll-interval-seconds", "0"])
        with self.assertRaises(ValueError):
            capacity_module.make_config(arguments)

    def test_rejects_negative_vram_floor(self):
        arguments = capacity_module.parse_arguments(["--vram-floor-mib", "-1"])
        with self.assertRaises(ValueError):
            capacity_module.make_config(arguments)

    def test_rejects_out_of_range_port(self):
        arguments = capacity_module.parse_arguments(["--port", "0"])
        with self.assertRaises(ValueError):
            capacity_module.make_config(arguments)
        arguments = capacity_module.parse_arguments(["--port", "70000"])
        with self.assertRaises(ValueError):
            capacity_module.make_config(arguments)

    def test_valid_overrides_accepted(self):
        config = make_config(parallel=8, ctx_size=65536, port=6000, timeout_seconds=30.0, poll_interval_seconds=1.0, vram_floor_mib=0)
        self.assertEqual(config.parallel, 8)
        self.assertEqual(config.ctx_size, 65536)


class CliSubprocessTests(unittest.TestCase):
    def run_cli(self, *args):
        return subprocess.run(
            [sys.executable, str(SCRIPT), *args],
            capture_output=True,
            text=True,
        )

    def test_default_invocation_is_dry_run_and_exits_zero(self):
        result = self.run_cli()
        self.assertEqual(result.returncode, 0)
        self.assertIn("plan (no process started, no service touched)", result.stdout)
        self.assertIn("--kv-unified", result.stdout)

    def test_invalid_parallel_exits_nonzero_before_any_apply_path(self):
        result = self.run_cli("--parallel", "0")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("--parallel must be a positive integer", result.stderr)

    def test_invalid_parallel_with_apply_still_fails_before_launch(self):
        result = self.run_cli("--parallel", "-4", "--apply")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("--parallel must be a positive integer", result.stderr)


class GateTests(unittest.TestCase):
    def test_health_gate_requires_status_ok(self):
        gate = capacity_module.make_health_gate("http://127.0.0.1:1", 0.01)
        failure = gate()
        self.assertIsNotNone(failure)
        self.assertEqual(failure.gate, "health")

    def test_props_gate_rejects_mismatched_total_slots(self):
        original = capacity_module.http_get_json
        capacity_module.http_get_json = lambda url, timeout: {"total_slots": 2, "n_ctx": 131072}
        try:
            gate = capacity_module.make_props_gate("http://x", 0.01, parallel=4, ctx_size=131072)
            failure = gate()
        finally:
            capacity_module.http_get_json = original
        self.assertIsNotNone(failure)
        self.assertEqual(failure.gate, "props")
        self.assertIn("total_slots", failure.reason)

    def test_props_gate_rejects_mismatched_context(self):
        original = capacity_module.http_get_json
        capacity_module.http_get_json = lambda url, timeout: {"total_slots": 4, "n_ctx": 4096}
        try:
            gate = capacity_module.make_props_gate("http://x", 0.01, parallel=4, ctx_size=131072)
            failure = gate()
        finally:
            capacity_module.http_get_json = original
        self.assertIsNotNone(failure)
        self.assertIn("context", failure.reason)

    def test_props_gate_passes_when_matched(self):
        original = capacity_module.http_get_json
        capacity_module.http_get_json = lambda url, timeout: {"total_slots": 4, "n_ctx": 131072}
        try:
            gate = capacity_module.make_props_gate("http://x", 0.01, parallel=4, ctx_size=131072)
            failure = gate()
        finally:
            capacity_module.http_get_json = original
        self.assertIsNone(failure)

    def test_slots_gate_rejects_wrong_count(self):
        original = capacity_module.http_get_json
        capacity_module.http_get_json = lambda url, timeout: [{}, {}]
        try:
            gate = capacity_module.make_slots_gate("http://x", 0.01, parallel=4)
            failure = gate()
        finally:
            capacity_module.http_get_json = original
        self.assertIsNotNone(failure)
        self.assertEqual(failure.gate, "slots")

    def test_slots_gate_passes_when_matched(self):
        original = capacity_module.http_get_json
        capacity_module.http_get_json = lambda url, timeout: [{}, {}, {}, {}]
        try:
            gate = capacity_module.make_slots_gate("http://x", 0.01, parallel=4)
            failure = gate()
        finally:
            capacity_module.http_get_json = original
        self.assertIsNone(failure)

    def test_vram_gate_parses_multi_gpu_min_and_enforces_floor(self):
        def fake_runner(command, timeout):
            return subprocess.CompletedProcess(command, 0, stdout=b"8000\n3000\n", stderr=b"")

        gate = capacity_module.make_vram_gate(fake_runner, "nvidia-smi", floor_mib=4096, timeout=1)
        failure = gate()
        self.assertIsNotNone(failure)
        self.assertEqual(failure.gate, "vram")
        self.assertIn("3000", failure.reason)

    def test_vram_gate_passes_above_floor(self):
        def fake_runner(command, timeout):
            return subprocess.CompletedProcess(command, 0, stdout=b"8000\n7000\n", stderr=b"")

        gate = capacity_module.make_vram_gate(fake_runner, "nvidia-smi", floor_mib=4096, timeout=1)
        self.assertIsNone(gate())

    def test_vram_gate_handles_command_failure(self):
        def fake_runner(command, timeout):
            return subprocess.CompletedProcess(command, 1, stdout=b"", stderr=b"no devices")

        gate = capacity_module.make_vram_gate(fake_runner, "nvidia-smi", floor_mib=4096, timeout=1)
        failure = gate()
        self.assertIsNotNone(failure)
        self.assertEqual(failure.gate, "vram")

    def test_vram_gate_handles_unparseable_output(self):
        def fake_runner(command, timeout):
            return subprocess.CompletedProcess(command, 0, stdout=b"not-a-number\n", stderr=b"")

        gate = capacity_module.make_vram_gate(fake_runner, "nvidia-smi", floor_mib=4096, timeout=1)
        failure = gate()
        self.assertIsNotNone(failure)
        self.assertEqual(failure.gate, "vram")


class FakeProcess:
    """Minimal Popen stand-in: alive until killed, records termination signals.

    Mirrors real subprocess.Popen's contract that poll()/wait() both set
    self.returncode as a side effect, since production code reads that
    attribute directly (as Popen callers are expected to).
    """

    def __init__(self, exits_immediately_with=None):
        self.returncode = exits_immediately_with
        self.terminated = False
        self.killed = False

    def poll(self):
        return self.returncode

    def send_signal(self, sig):
        self.terminated = True
        self.returncode = -15

    def kill(self):
        self.killed = True
        self.returncode = -9

    def wait(self, timeout=None):
        return self.returncode


class CandidateTrialTests(unittest.TestCase):
    def make_trial(self, gates, ensure_result=True, spawned_process=None, spawn_raises=None):
        events = []
        spawned_process = spawned_process or FakeProcess()

        def spawn(argv, env):
            if spawn_raises:
                raise spawn_raises
            events.append(("spawn", argv, env))
            return spawned_process

        def ensure_known_good_running():
            events.append(("ensure", None, None))
            return ensure_result

        clock = {"t": 0.0}

        def wall_clock():
            return clock["t"]

        def sleeper(seconds):
            clock["t"] += seconds

        config = make_config(timeout_seconds=10, poll_interval_seconds=1)
        trial = capacity_module.CandidateTrial(
            config=config,
            gates=gates,
            spawn=spawn,
            ensure_known_good_running=ensure_known_good_running,
            logger=lambda message: events.append(("log", message, None)),
            wall_clock=wall_clock,
            sleeper=sleeper,
        )
        return trial, events, spawned_process

    def test_all_gates_pass_terminates_candidate_and_restores_known_good(self):
        trial, events, process = self.make_trial(gates=[lambda: None, lambda: None])
        result = trial.run(base_env={})
        self.assertTrue(result.passed)
        self.assertIsNone(result.failure)
        self.assertTrue(result.restored)
        self.assertTrue(process.terminated)
        self.assertEqual([kind for kind, *_ in events if kind in ("spawn", "ensure")], ["spawn", "ensure"])

    def test_ensure_known_good_always_runs_after_persistent_gate_failure(self):
        failure = capacity_module.GateFailure("health", "unreachable")
        trial, events, process = self.make_trial(gates=[lambda: failure])
        result = trial.run(base_env={})
        self.assertFalse(result.passed)
        self.assertEqual(result.failure.gate, "timeout")
        self.assertTrue(result.restored)
        self.assertTrue(process.terminated)
        self.assertIn(("ensure", None, None), events)

    def test_gate_that_clears_before_timeout_passes_the_trial(self):
        attempts = {"count": 0}

        def flaky_health_gate():
            attempts["count"] += 1
            if attempts["count"] < 3:
                return capacity_module.GateFailure("health", "not ready yet")
            return None

        trial, events, process = self.make_trial(gates=[flaky_health_gate])
        result = trial.run(base_env={})
        self.assertTrue(result.passed)
        self.assertIsNone(result.failure)
        self.assertTrue(result.restored)
        self.assertGreaterEqual(attempts["count"], 3)

    def test_candidate_exiting_early_is_a_process_gate_failure(self):
        process = FakeProcess(exits_immediately_with=1)
        trial, events, _ = self.make_trial(gates=[lambda: None], spawned_process=process)
        result = trial.run(base_env={})
        self.assertFalse(result.passed)
        self.assertEqual(result.failure.gate, "process")
        self.assertTrue(result.restored)

    def test_timeout_without_any_gate_passing_is_a_timeout_failure(self):
        trial, events, process = self.make_trial(gates=[lambda: capacity_module.GateFailure("health", "not ready")])
        result = trial.run(base_env={})
        self.assertFalse(result.passed)
        self.assertEqual(result.failure.gate, "timeout")
        self.assertTrue(result.restored)

    def test_spawn_exception_still_triggers_rollback_ordering(self):
        trial, events, _ = self.make_trial(gates=[lambda: None], spawn_raises=OSError("no such file"))
        result = trial.run(base_env={})
        self.assertFalse(result.passed)
        self.assertEqual(result.failure.gate, "exception")
        self.assertTrue(result.restored)
        self.assertIn(("ensure", None, None), events)

    def test_ensure_known_good_failure_is_reported_but_does_not_raise(self):
        trial, events, process = self.make_trial(gates=[lambda: None], ensure_result=False)
        result = trial.run(base_env={})
        self.assertTrue(result.passed)
        self.assertFalse(result.restored)

    def test_rollback_ordering_terminate_before_ensure(self):
        order = []
        process = FakeProcess()

        def spawn(argv, env):
            return process

        real_send_signal = process.send_signal

        def tracked_send_signal(sig):
            order.append("terminate")
            real_send_signal(sig)

        process.send_signal = tracked_send_signal

        def ensure_known_good_running():
            order.append("ensure")
            return True

        config = make_config(timeout_seconds=10, poll_interval_seconds=1)
        trial = capacity_module.CandidateTrial(
            config=config,
            gates=[lambda: None],
            spawn=spawn,
            ensure_known_good_running=ensure_known_good_running,
            logger=lambda message: None,
            wall_clock=lambda: 0.0,
            sleeper=lambda seconds: None,
        )
        trial.run(base_env={})
        self.assertEqual(order, ["terminate", "ensure"])


class EnsureKnownGoodRunningTests(unittest.TestCase):
    def test_already_active_skips_restart(self):
        calls = []

        def runner(command, timeout):
            calls.append(command)
            return subprocess.CompletedProcess(command, 0, stdout=b"active\n", stderr=b"")

        ensure = capacity_module.make_ensure_known_good_running(runner, "systemctl", "llama-bee.service", 1, lambda m: None)
        self.assertTrue(ensure())
        self.assertEqual(len(calls), 1)
        self.assertIn("is-active", calls[0])

    def test_inactive_triggers_restart_and_reverifies(self):
        calls = []

        def runner(command, timeout):
            calls.append(command)
            if "is-active" in command:
                return subprocess.CompletedProcess(command, 0, stdout=b"active\n" if len(calls) > 1 else b"inactive\n", stderr=b"")
            return subprocess.CompletedProcess(command, 0, stdout=b"", stderr=b"")

        ensure = capacity_module.make_ensure_known_good_running(runner, "systemctl", "llama-bee.service", 1, lambda m: None)
        self.assertTrue(ensure())
        self.assertTrue(any("restart" in command for command in calls))

    def test_restart_command_failure_returns_false(self):
        def runner(command, timeout):
            if "is-active" in command:
                return subprocess.CompletedProcess(command, 0, stdout=b"inactive\n", stderr=b"")
            return subprocess.CompletedProcess(command, 1, stdout=b"", stderr=b"boom")

        ensure = capacity_module.make_ensure_known_good_running(runner, "systemctl", "llama-bee.service", 1, lambda m: None)
        self.assertFalse(ensure())

    def test_systemctl_exception_returns_false(self):
        def runner(command, timeout):
            raise subprocess.TimeoutExpired(command, timeout)

        ensure = capacity_module.make_ensure_known_good_running(runner, "systemctl", "llama-bee.service", 1, lambda m: None)
        self.assertFalse(ensure())


if __name__ == "__main__":
    unittest.main()
