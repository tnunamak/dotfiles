#!/usr/bin/env bash
# Test script to verify devcontainer path preservation.
# Run this INSIDE the devcontainer.
set -euo pipefail

PASS=0
FAIL=0

check() {
  local desc="$1"
  shift
  if "$@" 2>/dev/null; then
    echo "  ✓ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Devcontainer Path Preservation Tests ==="
echo ""

# 1. HOST_HOME env var is set
echo "Environment:"
check "HOST_HOME is set" [ -n "${HOST_HOME:-}" ]
check "HOST_HOME is not /home/node" [ "${HOST_HOME:-}" != "/home/node" ]
check "DEVCONTAINER is set" [ "${DEVCONTAINER:-}" = "true" ]

echo ""

# 2. Host-path mount exists and has content
echo "Host-path mount (${HOST_HOME:-<unset>}/code):"
check "${HOST_HOME}/code exists" [ -d "${HOST_HOME:-/nonexistent}/code" ]
check "${HOST_HOME}/code is a mount point" mountpoint -q "${HOST_HOME:-/nonexistent}/code"
check "${HOST_HOME}/code has contents" [ "$(ls -A "${HOST_HOME:-/nonexistent}/code" 2>/dev/null | head -1)" ]

echo ""

# 3. ~/code symlink works
echo "Symlink (~/code -> ${HOST_HOME:-<unset>}/code):"
check "~/code exists" [ -e ~/code ]
check "~/code is a symlink" [ -L ~/code ]
check "~/code points to ${HOST_HOME}/code" [ "$(readlink ~/code)" = "${HOST_HOME:-}/code" ]
check "~/code has same contents as ${HOST_HOME}/code" [ "$(ls ~/code)" = "$(ls "${HOST_HOME:-/nonexistent}/code")" ]

echo ""

# 4. Workspace folder preserves host path
echo "Workspace path:"
CWD="$(pwd)"
check "CWD starts with ${HOST_HOME}" test "${CWD#${HOST_HOME:-}}" != "$CWD"
check "CWD is under ${HOST_HOME}/code" test "${CWD#${HOST_HOME:-}/code/}" != "$CWD"
check "CWD is accessible via ~/code" [ -d ~/code/"${CWD#${HOST_HOME:-}/code/}" ]

echo ""

# 5. No /projects mount (old behavior is gone)
echo "Old /projects mount removed:"
check "/projects does not exist" [ ! -d /projects ]

echo ""

# 6. Container user sanity
echo "Container user:"
check "Running as node" [ "$(whoami)" = "node" ]
check "HOME is /home/node" [ "$HOME" = "/home/node" ]

# 7. Claude Code config files
echo "Claude Code config:"
check "~/.claude exists" [ -d ~/.claude ]
check "~/.claude.json exists" [ -f ~/.claude.json ]
check "CLAUDE_CONFIG_DIR is NOT set (should use default)" [ -z "${CLAUDE_CONFIG_DIR:-}" ]
check "~/.claude.json has mcpServers" python3 -c "import json; d=json.load(open('$HOME/.claude.json')); assert 'mcpServers' in d"
MCP_COUNT=$(python3 -c "import json; d=json.load(open('$HOME/.claude.json')); print(len(d.get('mcpServers',{})))" 2>/dev/null || echo 0)
check "~/.claude.json has MCP servers ($MCP_COUNT found)" [ "$MCP_COUNT" -gt 0 ]

echo ""

# 8. Plugin path resolution
echo "Plugin paths:"
check "installed_plugins.json exists" [ -f ~/.claude/plugins/installed_plugins.json ]
check "known_marketplaces.json exists" [ -f ~/.claude/plugins/known_marketplaces.json ]
# Check that hardcoded host paths resolve (via symlink or matching home)
PLUGIN_PATH=$(python3 -c "
import json
d=json.load(open('$HOME/.claude/plugins/installed_plugins.json'))
for name, entries in d.get('plugins',{}).items():
    for e in entries:
        print(e.get('installPath','')); break
    break
" 2>/dev/null || echo "")
if [ -n "$PLUGIN_PATH" ]; then
  check "First plugin installPath resolves ($PLUGIN_PATH)" [ -d "$PLUGIN_PATH" ]
else
  check "Plugin installPath found in installed_plugins.json" false
fi
# Check host-home symlink for path resolution
if [ "${HOST_HOME:-}" != "$HOME" ] && [ -n "${HOST_HOME:-}" ]; then
  check "${HOST_HOME}/.claude symlink exists" [ -L "${HOST_HOME}/.claude" ] || [ -d "${HOST_HOME}/.claude" ]
  check "${HOST_HOME}/.claude resolves to ~/.claude" [ "$(readlink -f "${HOST_HOME}/.claude")" = "$(readlink -f ~/.claude)" ]
fi

echo ""

# 9. Playwright browser (headless in container)
echo "Playwright (headless):"
check "PLAYWRIGHT_BROWSERS_PATH is set" [ -n "${PLAYWRIGHT_BROWSERS_PATH:-}" ]
check "Chromium installed at $PLAYWRIGHT_BROWSERS_PATH" [ -d "${PLAYWRIGHT_BROWSERS_PATH:-/nonexistent}" ] && ls "${PLAYWRIGHT_BROWSERS_PATH:-/nonexistent}"/chromium-* >/dev/null 2>&1
check "npx playwright available" npx playwright --version

echo ""

# 10. Host Playwright MCP reachable (port 3100 via gateway)
echo "Host Playwright MCP (headed browser):"
HOST_GW=$(ip route | awk '/default/ {print $3}')
check "Default gateway detected ($HOST_GW)" [ -n "$HOST_GW" ]
check "Port 3100 reachable on gateway" bash -c "echo > /dev/tcp/$HOST_GW/3100"

echo ""

# 11. Git signing
echo "Git signing:"
check "user.name configured" [ -n "$(git config user.name 2>/dev/null)" ]
check "user.email configured" [ -n "$(git config user.email 2>/dev/null)" ]
check "user.signingkey configured" [ -n "$(git config user.signingkey 2>/dev/null)" ]
SIGNING_KEY=$(git config user.signingkey 2>/dev/null || echo "")
check "Signing key file exists ($SIGNING_KEY)" [ -f "${SIGNING_KEY/#\~/$HOME}" ] 2>/dev/null || [ -f "$SIGNING_KEY" ]

echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
