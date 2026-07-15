import os
import shlex
import hashlib
import subprocess
import tempfile
import unittest
from pathlib import Path


REPOSITORY = Path(__file__).parents[1]
START_SCRIPT = REPOSITORY / "bin/.local/bin/llama-bee-start"
UNIT = REPOSITORY / "systemd/.config/systemd/user/llama-bee.service"
RESOURCES_DROP_IN = REPOSITORY / "systemd/.config/systemd/user/llama-bee.service.d/10-resources.conf"
PACKAGE = REPOSITORY / "llama-bee-systemd"


def clean_environment(overrides=None):
    environment = os.environ.copy()
    for name in tuple(environment):
        if name.startswith("LLAMA_BEE_") or name == "CUDA_VISIBLE_DEVICES":
            environment.pop(name)
    environment.update(overrides or {})
    return environment


def render_command(mode="--print-command", overrides=None, extra_arguments=()):
    result = subprocess.run(
        [str(START_SCRIPT), mode, *extra_arguments],
        check=True,
        text=True,
        capture_output=True,
        env=clean_environment(overrides),
    )
    return shlex.split(result.stdout)


def print_command(overrides=None, extra_arguments=()):
    return render_command(overrides=overrides, extra_arguments=extra_arguments)


class LlamaBeeRuntimeTests(unittest.TestCase):
    def assert_option(self, arguments, option, expected_value):
        self.assertIn(option, arguments)
        self.assertEqual(arguments[arguments.index(option) + 1], expected_value)

    def test_print_command_preserves_critical_operator_defaults(self):
        command = print_command()
        self.assertEqual(command[:2], ["exec", str(Path.home() / "applications/beellama/build/bin/llama-server")])
        arguments = command[2:]

        for option in ("--slots", "--metrics", "--no-host", "--mlock", "--reasoning", "--kv-unified", "--spec-type"):
            self.assertIn(option, arguments)
        self.assert_option(arguments, "--host", "127.0.0.1")
        self.assert_option(arguments, "-np", "1")
        self.assert_option(arguments, "--ctx-size", "102400")
        self.assert_option(arguments, "--ctx-checkpoints", "16")
        self.assert_option(arguments, "--checkpoint-min-step", "256")
        self.assert_option(arguments, "--cache-ram", "4096")
        self.assert_option(arguments, "--cache-type-k", "q5_0")
        self.assert_option(arguments, "--cache-type-v", "q4_1")
        self.assert_option(arguments, "--spec-draft-n-max", "3")
        self.assert_option(arguments, "--n-gpu-layers", "999")
        self.assert_option(arguments, "-b", "2048")
        self.assert_option(arguments, "-ub", "512")
        self.assert_option(arguments, "--reasoning", "on")
        self.assert_option(arguments, "--reasoning-budget", "-1")
        self.assert_option(arguments, "--chat-template-kwargs", '{"preserve_thinking":true}')
        self.assert_option(arguments, "--chat-template-file", "/media/windows/AI Models/LLMs/Chat Templates/Qwen-Fixed-Chat-Templates/23a40b0bd4d197c31d39e3c442fd2cd6100b3971/chat_template.jinja")

    def test_dry_run_is_the_same_deterministic_command_renderer(self):
        self.assertEqual(render_command(), render_command("--dry-run"))

    def test_print_command_proves_overrides_and_shell_quoting(self):
        model = "/models/Qwen with spaces.gguf"
        projector = "/models/projector with spaces.gguf"
        command = print_command(
            {
                "LLAMA_BEE_APPLICATIONS_DIR": "/applications with spaces",
                "LLAMA_BEE_MODEL": model,
                "LLAMA_BEE_MMPROJ": projector,
                "LLAMA_BEE_NO_MMPROJ_OFFLOAD": "1",
                "LLAMA_BEE_MTP": "0",
                "LLAMA_BEE_CHAT_TEMPLATE": "embedded",
                "LLAMA_BEE_CHAT_TEMPLATE_KWARGS": '{"preserve_thinking":false}',
                "LLAMA_BEE_CTX": "2048",
                "LLAMA_BEE_CTV": "q8_0",
                "LLAMA_BEE_TENSOR_SPLIT": "1,0",
            },
            ("--alias", "value with spaces"),
        )
        self.assertEqual(command[:2], ["exec", "/applications with spaces/beellama/build/bin/llama-server"])
        arguments = command[2:]
        self.assert_option(arguments, "--model", model)
        self.assert_option(arguments, "--mmproj", projector)
        self.assert_option(arguments, "--ctx-size", "2048")
        self.assert_option(arguments, "--cache-type-v", "q8_0")
        self.assert_option(arguments, "--tensor-split", "1,0")
        self.assert_option(arguments, "--chat-template-kwargs", '{"preserve_thinking":false}')
        self.assert_option(arguments, "--alias", "value with spaces")
        self.assertIn("--no-mmproj-offload", arguments)
        self.assertNotIn("--spec-type", arguments)
        self.assertNotIn("--chat-template-file", arguments)

    def test_candidate_only_tuning_renders_the_requested_allowlisted_values(self):
        command = print_command({
            "LLAMA_BEE_CANDIDATE_OVERRIDES": "1",
            "LLAMA_BEE_CANDIDATE_N_GPU_LAYERS": "61",
            "LLAMA_BEE_CANDIDATE_BATCH_SIZE": "1024",
            "LLAMA_BEE_CANDIDATE_UBATCH_SIZE": "256",
        })
        arguments = command[2:]
        self.assert_option(arguments, "--n-gpu-layers", "61")
        self.assert_option(arguments, "-b", "1024")
        self.assert_option(arguments, "-ub", "256")

    def test_candidate_typed_controls_render_the_explicit_binary_checkpoint_and_cache(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            server = home / "applications/beellama-candidate/build/bin/llama-server"
            server.parent.mkdir(parents=True)
            server.write_bytes(b"candidate-binary")
            server.chmod(0o755)
            command = print_command({
                "HOME": str(home),
                "LLAMA_BEE_CANDIDATE_OVERRIDES": "1",
                "LLAMA_BEE_CANDIDATE_N_GPU_LAYERS": "61",
                "LLAMA_BEE_CANDIDATE_BATCH_SIZE": "1024",
                "LLAMA_BEE_CANDIDATE_UBATCH_SIZE": "256",
                "LLAMA_BEE_CANDIDATE_SERVER_PATH": str(server),
                "LLAMA_BEE_CANDIDATE_SERVER_SHA256": hashlib.sha256(server.read_bytes()).hexdigest(),
                "LLAMA_BEE_CANDIDATE_CHECKPOINT_MIN_STEP": "128",
                "LLAMA_BEE_CANDIDATE_CACHE_RAM_MIB": "8",
            })
            rejected = subprocess.run([str(START_SCRIPT), "--print-command"], text=True, capture_output=True,
                                      env=clean_environment({
                                          "HOME": str(home),
                                          "LLAMA_BEE_CANDIDATE_OVERRIDES": "1",
                                          "LLAMA_BEE_CANDIDATE_N_GPU_LAYERS": "61",
                                          "LLAMA_BEE_CANDIDATE_BATCH_SIZE": "1024",
                                          "LLAMA_BEE_CANDIDATE_UBATCH_SIZE": "256",
                                          "LLAMA_BEE_CANDIDATE_SERVER_PATH": str(server),
                                          "LLAMA_BEE_CANDIDATE_SERVER_SHA256": "0" * 64,
                                      }))
            self.assertNotEqual(rejected.returncode, 0)
            self.assertIn("SHA-256 does not match", rejected.stderr)
        self.assertEqual(command[:2], ["exec", str(server)])
        arguments = command[2:]
        self.assert_option(arguments, "--checkpoint-min-step", "128")
        self.assert_option(arguments, "--cache-ram", "8")

    def test_candidate_server_rejects_ancestor_symlink_and_lexical_resolution_changes(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            applications = home / "applications"
            applications.mkdir()
            outside = home / "outside/build/bin/llama-server"
            outside.parent.mkdir(parents=True)
            outside.write_bytes(b"candidate-binary")
            outside.chmod(0o755)
            digest = hashlib.sha256(outside.read_bytes()).hexdigest()
            inside = applications / "actual/build/bin/llama-server"
            inside.parent.mkdir(parents=True)
            inside.write_bytes(b"candidate-binary")
            inside.chmod(0o755)
            linked_inside = applications / "linked-inside"
            linked_inside.symlink_to(applications / "actual", target_is_directory=True)
            linked_outside = applications / "linked-outside"
            linked_outside.symlink_to(home / "outside", target_is_directory=True)
            base = {
                "HOME": str(home),
                "LLAMA_BEE_CANDIDATE_OVERRIDES": "1",
                "LLAMA_BEE_CANDIDATE_N_GPU_LAYERS": "61",
                "LLAMA_BEE_CANDIDATE_BATCH_SIZE": "1024",
                "LLAMA_BEE_CANDIDATE_UBATCH_SIZE": "256",
                "LLAMA_BEE_CANDIDATE_SERVER_SHA256": digest,
            }
            for path in (str(linked_inside / "build/bin/llama-server"),
                         str(linked_outside / "build/bin/llama-server"),
                         f"{home}/applications/../outside/build/bin/llama-server"):
                with self.subTest(path=path):
                    result = subprocess.run([str(START_SCRIPT), "--print-command"], text=True, capture_output=True,
                                            env=clean_environment({**base, "LLAMA_BEE_CANDIDATE_SERVER_PATH": path}))
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn("ERROR: candidate server", result.stderr)

    def test_candidate_tuning_rejects_partial_invalid_and_injection_shaped_environment(self):
        for overrides in (
            {"LLAMA_BEE_CANDIDATE_N_GPU_LAYERS": "61"},
            {"LLAMA_BEE_CANDIDATE_OVERRIDES": "1", "LLAMA_BEE_CANDIDATE_N_GPU_LAYERS": "61", "LLAMA_BEE_CANDIDATE_BATCH_SIZE": "1024"},
            {"LLAMA_BEE_CANDIDATE_OVERRIDES": "1", "LLAMA_BEE_CANDIDATE_N_GPU_LAYERS": "61; touch /tmp/pwned", "LLAMA_BEE_CANDIDATE_BATCH_SIZE": "1024", "LLAMA_BEE_CANDIDATE_UBATCH_SIZE": "256"},
            {"LLAMA_BEE_CANDIDATE_OVERRIDES": "1", "LLAMA_BEE_CANDIDATE_N_GPU_LAYERS": "61", "LLAMA_BEE_CANDIDATE_BATCH_SIZE": "256", "LLAMA_BEE_CANDIDATE_UBATCH_SIZE": "512"},
            {"LLAMA_BEE_CANDIDATE_OVERRIDES": "1", "LLAMA_BEE_CANDIDATE_N_GPU_LAYERS": "61", "LLAMA_BEE_CANDIDATE_BATCH_SIZE": "1024", "LLAMA_BEE_CANDIDATE_UBATCH_SIZE": "256", "LLAMA_BEE_CANDIDATE_SERVER_PATH": "/tmp/llama-server"},
            {"LLAMA_BEE_CANDIDATE_OVERRIDES": "1", "LLAMA_BEE_CANDIDATE_N_GPU_LAYERS": "61", "LLAMA_BEE_CANDIDATE_BATCH_SIZE": "1024", "LLAMA_BEE_CANDIDATE_UBATCH_SIZE": "256", "LLAMA_BEE_CANDIDATE_CHECKPOINT_MIN_STEP": "$(touch /tmp/pwned)"},
            {"LLAMA_BEE_CANDIDATE_OVERRIDES": "1", "LLAMA_BEE_CANDIDATE_N_GPU_LAYERS": "61", "LLAMA_BEE_CANDIDATE_BATCH_SIZE": "1024", "LLAMA_BEE_CANDIDATE_UBATCH_SIZE": "256", "LLAMA_BEE_CANDIDATE_CACHE_RAM_MIB": "32769"},
        ):
            with self.subTest(overrides=overrides):
                result = subprocess.run([str(START_SCRIPT), "--print-command"], text=True, capture_output=True,
                                        env=clean_environment(overrides))
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("ERROR: candidate", result.stderr)

    def test_unit_and_memlock_drop_in_are_base_configuration_only(self):
        self.assertTrue(os.access(START_SCRIPT, os.X_OK))
        unit = UNIT.read_text()
        self.assertIn("WorkingDirectory=%h/applications/beellama", unit)
        self.assertIn("ExecStart=%h/.local/bin/llama-bee-start", unit)
        self.assertIn('Environment="LLAMA_BEE_VISIBLE_DEVICES=1"', unit)
        self.assertIn('Environment="LLAMA_BEE_CTV=q4_1"', unit)
        self.assertNotIn("/home/tnunamak", unit)
        self.assertEqual(RESOURCES_DROP_IN.read_text(), "# BeeLlama uses --mlock for a large model. The generic systemd user-manager\n# default is 8 MiB, which is too small and makes llama.cpp's mlock partial.\n[Service]\nLimitMEMLOCK=infinity\n")
        self.assertFalse(any(path.name == "20-model.conf" for path in PACKAGE.rglob("*")))

    def test_dedicated_no_fold_stow_install_links_only_bee_unit_files(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            target = Path(temporary_directory)
            subprocess.run(["stow", "-d", str(REPOSITORY), "-t", target, "--no-folding", "bin"], check=True)
            user_units = target / ".config/systemd/user"
            user_units.mkdir(parents=True)
            unrelated_unit = user_units / "unrelated.service"
            unrelated_unit.write_text("existing unit\n")

            subprocess.run(["stow", "-d", str(REPOSITORY), "-t", target, "--no-folding", "llama-bee-systemd"], check=True)

            installed_unit = user_units / "llama-bee.service"
            installed_drop_in = user_units / "llama-bee.service.d/10-resources.conf"
            self.assertTrue(installed_unit.is_symlink())
            self.assertTrue(installed_drop_in.is_symlink())
            self.assertEqual(installed_unit.resolve(), UNIT)
            self.assertEqual(installed_drop_in.resolve(), RESOURCES_DROP_IN)
            self.assertEqual(unrelated_unit.read_text(), "existing unit\n")
            self.assertFalse((user_units / "llama-bee.service.d/20-model.conf").exists())

    def test_setup_stows_the_dedicated_no_fold_package(self):
        setup = (REPOSITORY / "setup.sh").read_text()
        self.assertRegex(setup, r"PACKAGES=\([^)]*\bllama-bee-systemd\b")
        self.assertRegex(setup, r"NO_FOLD_PKGS=\([^)]*\bllama-bee-systemd\b")


if __name__ == "__main__":
    unittest.main()
