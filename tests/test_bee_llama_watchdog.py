import errno
import importlib.util
import io
import json
import subprocess
import sys
import tempfile
import unittest
import urllib.error
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
    def __init__(self, *, threshold=6, restart_limit=2):
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary_directory.name)
        self.logger = MemoryLogger()
        self.active = True
        self.health = {"status": "ok"}
        self.slots = {"slots": []}
        self.restarts = 0
        self.restart_success = True
        self.captures = []
        self.now = 10_000.0
        self.config = watchdog_module.WatchdogConfig(
            health_url="health",
            slots_url="slots",
            unit="llama-bee.service",
            interval_seconds=1,
            threshold=threshold,
            http_timeout_seconds=1,
            restart_limit=restart_limit,
            restart_window_seconds=1800,
            state_dir=self.root,
            systemctl_bin="systemctl",
            journalctl_bin="journalctl",
            nvidia_smi_bin="nvidia-smi",
            ps_bin="ps",
        )
        self.watchdog = watchdog_module.BeeLlamaWatchdog(
            config=self.config,
            service_active=lambda: self.active,
            json_fetcher=self.fetch,
            capture=self.captures.append,
            restart=self.restart,
            restart_history=watchdog_module.RestartHistory(self.root / "history.json", restart_limit, 1800),
            logger=self.logger,
            wall_clock=lambda: self.now,
        )

    def close(self):
        self.temporary_directory.cleanup()

    def fetch(self, url, timeout):
        value = self.health if url == "health" else self.slots
        if isinstance(value, BaseException):
            raise value
        return value

    def restart(self):
        self.restarts += 1
        return self.restart_success

    def poll(self, count=1):
        for _ in range(count):
            self.watchdog.poll_once()

    @staticmethod
    def processing(task="task-1", prompt=0, decoded=0):
        return {"slots": [{"id_task": task, "is_processing": True, "n_prompt_tokens_processed": prompt, "next_token": {"n_decoded": decoded}}]}

    @staticmethod
    def processing_slot(task="task-1", prompt=0, decoded=0):
        return {"id_task": task, "is_processing": True, "n_prompt_tokens_processed": prompt, "next_token": {"n_decoded": decoded}}


class BeeLlamaWatchdogTests(unittest.TestCase):
    def setUp(self):
        self.harness = WatchdogHarness()

    def tearDown(self):
        self.harness.close()

    def test_healthy_prompt_progress_never_restarts(self):
        for prompt in range(8):
            self.harness.slots = self.harness.processing(prompt=prompt)
            self.harness.poll()
        self.assertEqual(self.harness.restarts, 0)

    def test_healthy_generation_progress_never_restarts(self):
        for decoded in range(8):
            self.harness.slots = self.harness.processing(prompt=50, decoded=decoded)
            self.harness.poll()
        self.assertEqual(self.harness.restarts, 0)

    def test_idle_resets_stagnation(self):
        self.harness.slots = self.harness.processing()
        self.harness.poll(6)
        self.harness.slots = {"slots": [{"id_task": "task-1", "is_processing": False, "n_prompt_tokens_processed": 0, "next_token": {"n_decoded": 0}}]}
        self.harness.poll()
        self.harness.slots = self.harness.processing()
        self.harness.poll(6)
        self.assertEqual(self.harness.restarts, 0)

    def test_task_change_resets_stagnation(self):
        self.harness.slots = self.harness.processing(task="first")
        self.harness.poll(6)
        self.harness.slots = self.harness.processing(task="second")
        self.harness.poll()
        self.harness.poll(5)
        self.assertEqual(self.harness.restarts, 0)

    def test_malformed_response_resets_stagnation(self):
        self.harness.slots = self.harness.processing()
        self.harness.poll(6)
        self.harness.slots = {"slots": [{"id_task": "task-1", "is_processing": True}]}
        self.harness.poll()
        self.harness.slots = self.harness.processing()
        self.harness.poll(6)
        self.assertEqual(self.harness.restarts, 0)
        self.assertIn("slots response malformed or ambiguous; liveness reset", self.harness.logger.messages)

    def test_loading_or_non_ok_health_resets_stagnation_without_restart(self):
        self.harness.slots = self.harness.processing()
        self.harness.poll(6)
        self.harness.health = {"status": "loading"}
        self.harness.poll()
        self.harness.health = {"status": "ok"}
        self.harness.poll(6)
        self.assertEqual(self.harness.restarts, 0)

    def test_six_slots_timeouts_while_healthy_restart_once(self):
        self.harness.slots = TimeoutError("deliberately not logged")
        self.harness.poll(6)
        self.assertEqual(self.harness.restarts, 1)
        self.assertEqual(self.harness.captures, ["slot-timeouts"])

    def test_errno_timeout_counts_toward_the_slots_timeout_threshold(self):
        self.harness.slots = urllib.error.URLError(OSError(errno.ETIMEDOUT, "timed out"))
        self.harness.poll(6)
        self.assertEqual(self.harness.restarts, 1)

    def test_stagnation_threshold_and_progress_recovery(self):
        self.harness.slots = self.harness.processing(prompt=5)
        self.harness.poll(6)
        self.harness.slots = self.harness.processing(prompt=6)
        self.harness.poll()
        self.harness.slots = self.harness.processing(prompt=6)
        self.harness.poll(5)
        self.assertEqual(self.harness.restarts, 0)
        self.harness.poll()
        self.assertEqual(self.harness.restarts, 1)
        self.assertEqual(self.harness.captures, ["stagnant"])

    def test_restart_rate_limit_allows_only_two_per_window(self):
        self.harness.slots = TimeoutError()
        self.harness.poll(18)
        self.assertEqual(self.harness.restarts, 2)
        self.assertEqual(self.harness.captures, ["slot-timeouts", "slot-timeouts"])
        self.assertTrue(any("rate-limited" in message for message in self.harness.logger.messages))

    def test_failed_restart_attempt_still_consumes_the_strict_restart_budget(self):
        self.harness.restart_success = False
        self.harness.slots = TimeoutError()
        self.harness.poll(18)
        self.assertEqual(self.harness.restarts, 2)
        self.assertTrue(any("rate-limited" in message for message in self.harness.logger.messages))

    def test_multiple_processing_slots_track_each_task_independently(self):
        self.harness.slots = {"slots": [self.harness.processing_slot("stuck"), self.harness.processing_slot("moving")]}
        self.harness.poll()
        for decoded in range(1, 7):
            self.harness.slots = {"slots": [self.harness.processing_slot("stuck"), self.harness.processing_slot("moving", decoded=decoded)]}
            self.harness.poll()
        self.assertEqual(self.harness.restarts, 1)
        self.assertEqual(self.harness.captures, ["stagnant"])

    def test_six_stagnant_comparisons_require_a_baseline_plus_six_repeats(self):
        self.harness.slots = self.harness.processing()
        self.harness.poll(6)
        self.assertEqual(self.harness.restarts, 0)
        self.harness.poll()
        self.assertEqual(self.harness.restarts, 1)

    def test_restart_history_persists_across_instances(self):
        history = watchdog_module.RestartHistory(self.harness.root / "persisted.json", 2, 1800)
        self.assertTrue(history.allow_and_record(1.0))
        self.assertTrue(history.allow_and_record(2.0))
        self.assertFalse(watchdog_module.RestartHistory(self.harness.root / "persisted.json", 2, 1800).allow_and_record(3.0))
        self.assertEqual(json.loads((self.harness.root / "persisted.json").read_text()), [1.0, 2.0])

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
        capture.capture("stagnant")
        evidence = self.harness.root / "evidence" / "19700101T000000Z-stagnant"
        self.assertTrue((evidence / "journal.txt").exists())
        self.assertTrue((evidence / "nvidia-smi.txt").exists())
        self.assertTrue((evidence / "process-state.txt").exists())
        self.assertEqual([command[0][0] for command in commands], ["journalctl", "nvidia-smi", "ps"])

    def test_command_line_rejects_non_localhost_endpoints(self):
        with redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
            watchdog_module.parse_arguments(["--slots-url", "http://example.test/slots"])

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
