#!/usr/bin/env bash
# Keep Claude Code on the single native-install lane selected by setup.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETUP="$ROOT/setup.sh"
STATUS_REFRESH="$ROOT/bin/.local/bin/shell-status-refresh"
NPM_GLOBALS="$ROOT/npm-global-packages.txt"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

grep -qF 'curl -fsSL https://claude.ai/install.sh | bash' "$SETUP" \
  || fail 'setup.sh no longer installs Claude Code through the native installer'
grep -qF 'npm uninstall -g @anthropic-ai/claude-code' "$SETUP" \
  || fail 'setup.sh no longer removes the conflicting global npm install'
grep -qF ';claude update"' "$STATUS_REFRESH" \
  || fail 'the update picker no longer uses the native Claude updater'
! grep -Eq 'npm (install|i) -g @anthropic-ai/claude-code' "$STATUS_REFRESH" \
  || fail 'the update picker reinstalls the conflicting global npm package'
! grep -Eq '^[[:space:]]*@anthropic-ai/claude-code([[:space:]]|$)' "$NPM_GLOBALS" \
  || fail 'Claude Code must not be in the managed npm global package list'

echo 'PASS: Claude Code install and update paths use the native installer only'
