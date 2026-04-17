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

def run(args):
    subprocess.run(args, check=True)

def run_quiet(args):
    subprocess.run(args, check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

if shutil.which("codex"):
    for name, cfg in sorted(manifest.get("codex", {}).get("servers", {}).items()):
        run_quiet(["codex", "mcp", "remove", name])
        cmd = ["codex", "mcp", "add", name, "--url", cfg["url"]]
        bearer_token_env_var = cfg.get("bearer_token_env_var")
        if bearer_token_env_var:
            cmd.extend(["--bearer-token-env-var", bearer_token_env_var])
        run(cmd)
else:
    print("Skipping Codex MCP sync: codex not found", file=sys.stderr)

if shutil.which("claude"):
    for name, cfg in sorted(manifest.get("claude", {}).get("servers", {}).items()):
        run_quiet(["claude", "mcp", "remove", name, "-s", cfg["scope"]])
        if cfg["transport"] == "http":
            cmd = ["claude", "mcp", "add", "--scope", cfg["scope"], "--transport", "http", name, cfg["url"]]
            header_env_var = cfg.get("header_env_var")
            if header_env_var and header_env_var in os.environ:
                cmd.extend(["--header", f"Authorization: Bearer {os.environ[header_env_var]}"])
            run(cmd)
        elif cfg["transport"] == "stdio":
            run(["claude", "mcp", "add", "--scope", cfg["scope"], name, "--", cfg["command"], *cfg.get("args", [])])
        else:
            raise ValueError(f"Unsupported Claude MCP transport for {name}: {cfg['transport']}")
else:
    print("Skipping Claude MCP sync: claude not found", file=sys.stderr)

if shutil.which("gemini"):
    for name, cfg in sorted(manifest.get("gemini", {}).get("servers", {}).items()):
        run_quiet(["gemini", "mcp", "remove", name, "--scope", cfg["scope"]])
        if cfg["transport"] == "http":
            cmd = ["gemini", "mcp", "add", "--scope", cfg["scope"], "--transport", "http", name, cfg["url"]]
            header_env_var = cfg.get("header_env_var")
            if header_env_var and header_env_var in os.environ:
                cmd.extend(["--header", f"Authorization: Bearer {os.environ[header_env_var]}"])
            run(cmd)
        elif cfg["transport"] == "stdio":
            cmd = ["gemini", "mcp", "add", "--scope", cfg["scope"], "--transport", "stdio", name, cfg["command"], *cfg.get("args", [])]
            run(cmd)
        else:
            raise ValueError(f"Unsupported Gemini MCP transport for {name}: {cfg['transport']}")
else:
    print("Skipping Gemini MCP sync: gemini not found", file=sys.stderr)
PY
