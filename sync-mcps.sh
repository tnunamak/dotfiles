#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
MANIFEST="$DOTFILES_DIR/ai/mcp-servers.json"

python3 - <<'PY' "$MANIFEST"
import json
import os
import shutil
import subprocess
import sys

manifest_path = sys.argv[1]

with open(manifest_path) as f:
    manifest = json.load(f)

agent_defaults = manifest.get("agents", {})
servers = manifest.get("servers", {})
legacy_server_names = manifest.get("legacyServerNames", [])
redactions = [
    os.environ[token_env]
    for token_env in {
        (cfg.get("auth") or {}).get("bearerTokenEnv")
        for cfg in servers.values()
    }
    if token_env and os.environ.get(token_env)
]


def run(args):
    result = subprocess.run(args, check=False, capture_output=True, text=True)
    stdout = result.stdout
    stderr = result.stderr
    for secret in redactions:
        stdout = stdout.replace(secret, "[redacted]")
        stderr = stderr.replace(secret, "[redacted]")
    if stdout:
        print(stdout, end="")
    if stderr:
        print(stderr, end="", file=sys.stderr)
    result.check_returncode()


def run_quiet(args):
    subprocess.run(args, check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def selected_servers(agent):
    for name, cfg in sorted(servers.items()):
        if agent in cfg.get("agents", []):
            yield name, cfg


def can_configure(agent, cfg):
    token_env = bearer_env(cfg)
    if agent in {"claude", "gemini"} and token_env and token_env not in os.environ:
        return False
    return True


def remove_all_known(agent):
    # Remove every canonical server name for this agent so moving a server out
    # of an agent's allowlist actually removes old config on the next sync.
    # Exception: Claude/Gemini store bearer token values directly, so if the
    # needed env var is missing, leave any existing config untouched.
    selected = {name for name, _ in selected_servers(agent)}
    for name in sorted(legacy_server_names):
        if agent == "codex":
            run_quiet(["codex", "mcp", "remove", name])
        elif agent == "claude":
            scope = agent_defaults.get(agent, {}).get("scope", "user")
            run_quiet(["claude", "mcp", "remove", name, "-s", scope])
        elif agent == "gemini":
            scope = agent_defaults.get(agent, {}).get("scope", "user")
            run_quiet(["gemini", "mcp", "remove", name, "--scope", scope])

    for name, cfg in sorted(servers.items()):
        if name in selected and not can_configure(agent, cfg):
            token_env = bearer_env(cfg)
            print(
                f"Skipping {agent} MCP {name}: {token_env} is not set; leaving existing config untouched",
                file=sys.stderr,
            )
            continue
        if agent == "codex":
            run_quiet(["codex", "mcp", "remove", name])
        elif agent == "claude":
            scope = agent_defaults.get(agent, {}).get("scope", "user")
            run_quiet(["claude", "mcp", "remove", name, "-s", scope])
        elif agent == "gemini":
            scope = agent_defaults.get(agent, {}).get("scope", "user")
            run_quiet(["gemini", "mcp", "remove", name, "--scope", scope])


def bearer_env(cfg):
    return (cfg.get("auth") or {}).get("bearerTokenEnv")


def require_transport(name, cfg):
    transport = cfg.get("transport")
    if transport not in {"http", "stdio"}:
        raise ValueError(f"Unsupported MCP transport for {name}: {transport}")
    return transport


def add_codex(name, cfg):
    transport = require_transport(name, cfg)
    if transport == "http":
        cmd = ["codex", "mcp", "add", name, "--url", cfg["url"]]
        token_env = bearer_env(cfg)
        if token_env:
            cmd.extend(["--bearer-token-env-var", token_env])
        run(cmd)
        return

    cmd = ["codex", "mcp", "add"]
    for k, v in (cfg.get("env") or {}).items():
        cmd.extend(["--env", f"{k}={v}"])
    cmd.extend([name, "--", cfg["command"], *cfg.get("args", [])])
    run(cmd)


def add_claude(name, cfg):
    transport = require_transport(name, cfg)
    scope = agent_defaults.get("claude", {}).get("scope", "user")
    if transport == "http":
        cmd = [
            "claude",
            "mcp",
            "add",
            "--scope",
            scope,
            "--transport",
            "http",
            name,
            cfg["url"],
        ]
        token_env = bearer_env(cfg)
        if token_env and token_env in os.environ:
            cmd.extend(["--header", f"Authorization: Bearer {os.environ[token_env]}"])
        run(cmd)
        return

    cmd = ["claude", "mcp", "add", "--scope", scope, name]
    for k, v in (cfg.get("env") or {}).items():
        cmd.extend(["-e", f"{k}={v}"])
    cmd.extend(["--", cfg["command"], *cfg.get("args", [])])
    run(cmd)


def add_gemini(name, cfg):
    transport = require_transport(name, cfg)
    scope = agent_defaults.get("gemini", {}).get("scope", "user")
    if transport == "http":
        cmd = [
            "gemini",
            "mcp",
            "add",
            "--scope",
            scope,
            "--transport",
            "http",
            name,
            cfg["url"],
        ]
        token_env = bearer_env(cfg)
        if token_env and token_env in os.environ:
            cmd.extend(["--header", f"Authorization: Bearer {os.environ[token_env]}"])
        run(cmd)
        return

    cmd = [
        "gemini",
        "mcp",
        "add",
        "--scope",
        scope,
        "--transport",
        "stdio",
        name,
    ]
    for k, v in (cfg.get("env") or {}).items():
        cmd.extend(["-e", f"{k}={v}"])
    cmd.extend([cfg["command"], *cfg.get("args", [])])
    run(cmd)


if shutil.which("codex"):
    remove_all_known("codex")
    for name, cfg in selected_servers("codex"):
        if not can_configure("codex", cfg):
            continue
        add_codex(name, cfg)
else:
    print("Skipping Codex MCP sync: codex not found", file=sys.stderr)

if shutil.which("claude"):
    remove_all_known("claude")
    for name, cfg in selected_servers("claude"):
        if not can_configure("claude", cfg):
            continue
        add_claude(name, cfg)
else:
    print("Skipping Claude MCP sync: claude not found", file=sys.stderr)

if shutil.which("gemini"):
    remove_all_known("gemini")
    for name, cfg in selected_servers("gemini"):
        if not can_configure("gemini", cfg):
            continue
        add_gemini(name, cfg)
else:
    print("Skipping Gemini MCP sync: gemini not found", file=sys.stderr)
PY
