#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"

cleanup() {
  rm -rf -- "$tmp_dir"
}
trap cleanup EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_has_line() {
  local expected="$1"
  local file="$2"
  grep -Fxq -- "$expected" "$file" || fail "missing line '$expected' in $file"
}

assert_agent_lacks_server() {
  local agent="$1"
  local server="$2"
  local file="$3"
  ! grep -E "^${agent} mcp add .*${server}" "$file" >/dev/null \
    || fail "$agent unexpectedly received $server"
}

fixture="$tmp_dir/repo"
fake_home="$tmp_dir/home"
fake_bin="$tmp_dir/bin"
command_log="$tmp_dir/commands.log"
mkdir -p "$fixture/ai" "$fake_home/applications/daisy/scripts" "$fake_bin"
cp -- "$REPO_DIR/sync-mcps.sh" "$fixture/sync-mcps.sh"
chmod 755 -- "$fixture/sync-mcps.sh"

cat >"$fixture/ai/mcp-servers.json" <<'EOF'
{
  "agents": {
    "codex": {},
    "claude": {"scope": "user"},
    "gemini": {"scope": "user"},
    "daisy": {
      "reconciler": "~/applications/daisy/scripts/reconcile-pi-mcp",
      "target": "~/applications/daisy/.pi/mcp.json"
    }
  },
  "legacyServerNames": ["retired"],
  "servers": {
    "codex-only": {
      "transport": "http",
      "url": "https://codex.invalid/mcp",
      "agents": ["codex"]
    },
    "claude-only": {
      "transport": "http",
      "url": "https://claude.invalid/mcp",
      "agents": ["claude"]
    },
    "gemini-only": {
      "transport": "stdio",
      "command": "gemini-server",
      "args": ["--fixture"],
      "agents": ["gemini"]
    },
    "daisy-only": {
      "transport": "stdio",
      "command": "daisy-server",
      "agents": ["daisy"]
    },
    "shared-without-daisy": {
      "transport": "stdio",
      "command": "shared-server",
      "agents": ["codex", "claude", "gemini"]
    },
    "shared-with-daisy": {
      "transport": "stdio",
      "command": "all-server",
      "agents": ["codex", "claude", "gemini", "daisy"]
    }
  }
}
EOF

for agent in codex claude gemini; do
  cat >"$fake_bin/$agent" <<'EOF'
#!/usr/bin/env bash
printf '%s %s\n' "$(basename "$0")" "$*" >>"${SYNC_MCP_COMMAND_LOG:?}"
EOF
  chmod 755 -- "$fake_bin/$agent"
done

cat >"$fake_home/applications/daisy/scripts/reconcile-pi-mcp" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
manifest="$1"
target="$2"
mkdir -p -- "$(dirname -- "$target")"
python3 - "$manifest" "$target" <<'PY'
import json
import sys

with open(sys.argv[1]) as source:
    manifest = json.load(source)

selected = sorted(
    name
    for name, config in manifest["servers"].items()
    if "daisy" in config.get("agents", [])
)
with open(sys.argv[2], "w") as target:
    json.dump(selected, target)
    target.write("\n")
PY
printf 'daisy-reconcile %s %s\n' "$manifest" "$target" >>"${SYNC_MCP_COMMAND_LOG:?}"
EOF
chmod 755 -- "$fake_home/applications/daisy/scripts/reconcile-pi-mcp"

env \
  HOME="$fake_home" \
  PATH="$fake_bin:/usr/bin:/bin" \
  SYNC_MCP_COMMAND_LOG="$command_log" \
  "$fixture/sync-mcps.sh"

assert_has_line "codex mcp add codex-only --url https://codex.invalid/mcp" "$command_log"
assert_has_line "claude mcp add --scope user --transport http claude-only https://claude.invalid/mcp" "$command_log"
assert_has_line "gemini mcp add --scope user --transport stdio gemini-only gemini-server --fixture" "$command_log"
assert_has_line "daisy-reconcile $fixture/ai/mcp-servers.json $fake_home/applications/daisy/.pi/mcp.json" "$command_log"

assert_agent_lacks_server codex daisy-only "$command_log"
assert_agent_lacks_server claude daisy-only "$command_log"
assert_agent_lacks_server gemini daisy-only "$command_log"

python3 - "$fake_home/applications/daisy/.pi/mcp.json" <<'PY'
import json
import sys

with open(sys.argv[1]) as source:
    actual = json.load(source)
expected = ["daisy-only", "shared-with-daisy"]
if actual != expected:
    raise SystemExit(f"Daisy selection differs: expected {expected!r}, got {actual!r}")
PY

rm -f -- "$fake_home/applications/daisy/scripts/reconcile-pi-mcp"
missing_log="$tmp_dir/missing.log"
env \
  HOME="$fake_home" \
  PATH="$fake_bin:/usr/bin:/bin" \
  SYNC_MCP_COMMAND_LOG="$missing_log" \
  "$fixture/sync-mcps.sh" >"$tmp_dir/missing.out" 2>&1
grep -Fq "Skipping Daisy MCP sync: reconciler not found" "$tmp_dir/missing.out" \
  || fail "missing optional Daisy installation was not reported safely"
assert_has_line "codex mcp add codex-only --url https://codex.invalid/mcp" "$missing_log"

echo "PASS: MCP sync preserves Codex/Claude/Gemini routing and reconciles Daisy allowlists"
