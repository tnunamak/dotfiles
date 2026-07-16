import importlib.util
import io
import json
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stderr
from importlib.machinery import SourceFileLoader
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "bin/.local/bin/bee-llama-watchdog"
REPOSITORY = Path(__file__).parents[1]
SPEC = importlib.util.spec_from_loader("bee_llama_watchdog", SourceFileLoader("bee_llama_watchdog", str(SCRIPT)))
assert SPEC and SPEC.loader
watchdog_module = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = watchdog_module
SPEC.loader.exec_module(watchdog_module)


class MemoryLogger:
    def __init__(self):
        self.messages = []

    def write(self, message):
        self.messages.append(message)


class WatchdogHarness:
    def __init__(self, *, inactive_threshold=2, restart_limit=2):
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary_directory.name)
        self.logger = MemoryLogger()
        self.service_state = self.unit_state("active", "running", 10_000_000)
        self.restarts = 0
        self.restart_success = True
        self.captures = []
        self.now = 10_000.0
        self.config = watchdog_module.WatchdogConfig(
            unit="llama-bee.service",
            interval_seconds=30,
            inactive_threshold=inactive_threshold,
            restart_limit=restart_limit,
            restart_window_seconds=1800,
            state_dir=self.root,
            systemctl_bin="systemctl",
            journalctl_bin="journalctl",
            nvidia_smi_bin="nvidia-smi",
            ps_bin="ps",
        )
        self.watchdog = watchdog_module.LocalLlmWatchdog(
            config=self.config,
            service_state=lambda: self.service_state,
            capture=self.captures.append,
            restart=self.restart,
            restart_history=watchdog_module.RestartHistory(self.root / "history.json", restart_limit, 1800),
            logger=self.logger,
            wall_clock=lambda: self.now,
        )

    def close(self):
        self.temporary_directory.cleanup()

    def restart(self):
        self.restarts += 1
        return self.restart_success

    @staticmethod
    def unit_state(active_state, sub_state, active_enter_timestamp_monotonic):
        return watchdog_module.SystemdUnitState(active_state, sub_state, active_enter_timestamp_monotonic)

    def poll(self, count=1):
        for _ in range(count):
            self.watchdog.poll_once()


class LocalLlmWatchdogTests(unittest.TestCase):
    def setUp(self):
        self.harness = WatchdogHarness()

    def tearDown(self):
        self.harness.close()

    def test_active_service_never_restarts(self):
        self.harness.poll(10)
        self.assertEqual(self.harness.restarts, 0)

    def test_first_confirmed_inactive_observation_is_a_baseline(self):
        self.harness.service_state = self.harness.unit_state("inactive", "dead", 10_000_000)
        self.harness.poll()
        self.assertEqual(self.harness.restarts, 0)

    def test_second_confirmed_dead_observation_recovers_once(self):
        self.harness.service_state = self.harness.unit_state("failed", "failed", 10_000_000)
        self.harness.poll(2)
        self.assertEqual(self.harness.restarts, 1)
        self.assertEqual(self.harness.captures, ["unit-inactive"])

    def test_active_state_resets_inactive_evidence(self):
        self.harness.service_state = self.harness.unit_state("inactive", "dead", 10_000_000)
        self.harness.poll()
        self.harness.service_state = self.harness.unit_state("active", "running", 20_000_000)
        self.harness.poll()
        self.harness.service_state = self.harness.unit_state("inactive", "dead", 20_000_000)
        self.harness.poll()
        self.assertEqual(self.harness.restarts, 0)

    def test_new_activation_generation_discards_old_dead_evidence(self):
        self.harness.poll()
        self.harness.service_state = self.harness.unit_state("inactive", "dead", 10_000_000)
        self.harness.poll()
        # The watchdog missed a brief active/running replacement. Its larger
        # monotonic timestamp still proves this is a new service generation.
        self.harness.service_state = self.harness.unit_state("inactive", "dead", 20_000_000)
        self.harness.poll(2)
        self.assertEqual(self.harness.restarts, 0)
        self.harness.poll()
        self.assertEqual(self.harness.restarts, 1)

    def test_unknown_state_resets_inactive_evidence_and_never_restarts(self):
        self.harness.service_state = self.harness.unit_state("inactive", "dead", 10_000_000)
        self.harness.poll()
        self.harness.service_state = None
        self.harness.poll(10)
        self.assertEqual(self.harness.restarts, 0)
        self.assertIn("unit state unavailable, transitional, or not stably dead; no restart", self.harness.logger.messages)

    def test_operator_restart_and_model_loading_never_restart(self):
        self.harness.poll()
        self.harness.service_state = self.harness.unit_state("deactivating", "stop-sigkill", 10_000_000)
        self.harness.poll()
        self.harness.service_state = self.harness.unit_state("activating", "start", 10_000_000)
        self.harness.poll()
        # Type=simple becomes active before the model can accept a request.
        # Health is intentionally absent from this harness and the watchdog API.
        self.harness.service_state = self.harness.unit_state("active", "running", 20_000_000)
        self.harness.poll(10)
        self.harness.poll()
        self.assertEqual(self.harness.restarts, 0)
        self.assertEqual(self.harness.captures, [])
        self.assertEqual(self.harness.watchdog.unavailability.active_enter_timestamp_monotonic, 20_000_000)

    def test_restart_rate_limit_allows_only_two_inactive_recoveries_per_window(self):
        self.harness.service_state = self.harness.unit_state("inactive", "dead", 10_000_000)
        self.harness.poll(6)
        self.assertEqual(self.harness.restarts, 2)
        self.assertEqual(self.harness.captures, ["unit-inactive", "unit-inactive"])
        self.assertTrue(any("rate-limited" in message for message in self.harness.logger.messages))

    def test_failed_restart_attempt_still_consumes_the_strict_restart_budget(self):
        self.harness.restart_success = False
        self.harness.service_state = self.harness.unit_state("inactive", "dead", 10_000_000)
        self.harness.poll(6)
        self.assertEqual(self.harness.restarts, 2)
        self.assertTrue(any("rate-limited" in message for message in self.harness.logger.messages))

    def test_restart_history_persists_across_instances(self):
        history = watchdog_module.RestartHistory(self.harness.root / "persisted.json", 2, 1800)
        self.assertTrue(history.allow_and_record(1.0))
        self.assertTrue(history.allow_and_record(2.0))
        self.assertFalse(watchdog_module.RestartHistory(self.harness.root / "persisted.json", 2, 1800).allow_and_record(3.0))
        self.assertEqual(json.loads((self.harness.root / "persisted.json").read_text()), [1.0, 2.0])

    def test_systemd_unit_state_reads_restart_relevant_service_manager_properties(self):
        commands = []

        def runner(command, timeout):
            commands.append((command, timeout))
            return subprocess.CompletedProcess(
                command,
                0,
                b"SubState=running\nActiveEnterTimestampMonotonic=123456\nActiveState=active\n",
                b"",
            )

        self.assertEqual(
            watchdog_module.systemd_unit_state(runner, "systemctl", "llama-bee.service"),
            watchdog_module.SystemdUnitState("active", "running", 123456),
        )
        self.assertEqual(
            commands,
            [
                (
                    [
                        "systemctl",
                        "--user",
                        "show",
                        "--property=ActiveState,SubState,ActiveEnterTimestampMonotonic",
                        "llama-bee.service",
                    ],
                    watchdog_module.COMMAND_TIMEOUT_SECONDS,
                )
            ],
        )

    def test_only_stable_dead_and_failed_states_are_confirmed_unavailability(self):
        for state in (b"ActiveState=inactive\nSubState=dead\nActiveEnterTimestampMonotonic=123\n", b"ActiveState=failed\nSubState=failed\nActiveEnterTimestampMonotonic=123\n"):
            with self.subTest(state=state):
                def runner(command, timeout):
                    return subprocess.CompletedProcess(command, 0, state, b"")

                unit_state = watchdog_module.systemd_unit_state(runner, "systemctl", "llama-bee.service")
                self.assertIsNotNone(unit_state)
                self.assertEqual(unit_state.watchdog_state(), "inactive")

    def test_systemd_transitions_command_failure_and_malformed_output_do_not_confirm_unavailability(self):
        outcomes = [
            (subprocess.CompletedProcess([], 0, b"ActiveState=activating\nSubState=start\nActiveEnterTimestampMonotonic=123\n", b""), "transitional"),
            (subprocess.CompletedProcess([], 0, b"ActiveState=deactivating\nSubState=stop-sigterm\nActiveEnterTimestampMonotonic=123\n", b""), "transitional"),
            (subprocess.CompletedProcess([], 0, b"ActiveState=inactive\nSubState=stop\nActiveEnterTimestampMonotonic=123\n", b""), "unknown"),
            (subprocess.CompletedProcess([], 0, b"ActiveState=active\nSubState=running\nActiveEnterTimestampMonotonic=not-a-number\n", b""), None),
            (subprocess.CompletedProcess([], 1, b"failed\n", b""), None),
            (OSError("systemctl unavailable"), None),
            (subprocess.TimeoutExpired(["systemctl"], 5), None),
        ]
        for outcome, expected_state in outcomes:
            with self.subTest(outcome=outcome):
                def runner(command, timeout, outcome=outcome):
                    if isinstance(outcome, BaseException):
                        raise outcome
                    return outcome

                unit_state = watchdog_module.systemd_unit_state(runner, "systemctl", "llama-bee.service")
                if expected_state is None:
                    self.assertIsNone(unit_state)
                else:
                    self.assertIsNotNone(unit_state)
                    self.assertEqual(unit_state.watchdog_state(), expected_state)

    def test_watchdog_source_has_no_engine_http_or_task_observation(self):
        source = SCRIPT.read_text()
        for forbidden in ("/slots", "urlopen", "urllib", "requests", "id_task", "next_token"):
            with self.subTest(forbidden=forbidden):
                self.assertNotIn(forbidden, source)

    def test_evidence_uses_injected_commands(self):
        commands = []

        def runner(command, timeout):
            commands.append((command, timeout))
            return subprocess.CompletedProcess(command, 0, b"bounded output", b"")

        capture = watchdog_module.EvidenceCapture(
            self.harness.config,
            runner,
            self.harness.logger,
            wall_clock=lambda: 0,
        )
        capture.capture("unit-inactive")
        evidence = self.harness.root / "evidence" / "19700101T000000Z-unit-inactive"
        self.assertTrue((evidence / "journal.txt").exists())
        self.assertTrue((evidence / "nvidia-smi.txt").exists())
        self.assertTrue((evidence / "process-state.txt").exists())
        self.assertEqual([command[0][0] for command in commands], ["journalctl", "nvidia-smi", "ps"])
        ps_fields = commands[2][0][2].split(",")
        self.assertNotIn("args", ps_fields)
        self.assertNotIn("command", ps_fields)
        self.assertEqual(ps_fields, ["pid", "ppid", "stat", "etime", "pcpu", "pmem", "comm", "wchan"])

    def test_command_line_exposes_only_non_perturbing_inactive_threshold(self):
        defaults = watchdog_module.parse_arguments([])
        self.assertEqual(defaults.inactive_threshold, 2)
        arguments = watchdog_module.parse_arguments(["--inactive-threshold", "3"])
        self.assertEqual(arguments.inactive_threshold, 3)
        with redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
            watchdog_module.parse_arguments(["--inactive-threshold", "0"])
        for removed_option in ("--base-url", "--health-url", "--slots-url", "--stagnant-threshold", "--slots-unavailable-threshold", "--http-timeout-seconds"):
            with self.subTest(removed_option=removed_option), redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
                watchdog_module.parse_arguments([removed_option, "1"])

    def test_setup_stows_the_watchdog_executable_and_user_unit(self):
        setup = (REPOSITORY / "setup.sh").read_text()
        self.assertRegex(setup, r"PACKAGES=\([^)]*\bbee-watchdog-systemd\b")
        self.assertRegex(setup, r"NO_FOLD_PKGS=\([^)]*\bbee-watchdog-systemd\b")
        with tempfile.TemporaryDirectory(dir=self.harness.root) as target:
            subprocess.run(["stow", "-d", str(REPOSITORY), "-t", target, "--no-folding", "bin"], check=True)
            user_units = Path(target) / ".config/systemd/user"
            user_units.mkdir(parents=True)
            for name in ("gpu-incident-watcher.service", "tmp-reaper.service", "tmp-reaper.timer"):
                (user_units / name).write_text("existing unit\n")
            subprocess.run(
                [
                    "stow",
                    "-d",
                    str(REPOSITORY),
                    "-t",
                    target,
                    "--no-folding",
                    "bee-watchdog-systemd",
                ],
                check=True,
            )
            self.assertTrue((Path(target) / ".local/bin/bee-llama-watchdog").is_symlink())
            installed_unit = Path(target) / ".config/systemd/user/bee-llama-watchdog.service"
            self.assertTrue(installed_unit.is_symlink())
            self.assertEqual(installed_unit.resolve(), REPOSITORY / "systemd/.config/systemd/user/bee-llama-watchdog.service")
            self.assertEqual((user_units / "tmp-reaper.service").read_text(), "existing unit\n")


if __name__ == "__main__":
    unittest.main()
