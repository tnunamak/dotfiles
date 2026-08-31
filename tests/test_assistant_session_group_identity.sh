#!/usr/bin/env bash
# Regression: a session and an unrelated window may share the same name.
# Assistant save must derive the group from the list-panes row, not resolve a
# bare target that tmux can bind to the unrelated window.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATCHER="$ROOT/tmux/.config/tmux/scripts/patch-assistant-resurrect.sh"
REAL_TMUX="$(command -v tmux)"
SOCKET="test-assistant-session-identity-$$"
WORK="$(mktemp -d "${HOME}/.tmp/assistant-session-identity.XXXXXX")"
TEST_HOME="$WORK/home"
PLUGIN_DIR="$TEST_HOME/.tmux/plugins/tmux-assistant-resurrect/scripts"
BIN_DIR="$WORK/bin"
OUTPUT="$WORK/panes.txt"

cleanup() {
  "$REAL_TMUX" -L "$SOCKET" kill-session -t '=main' 2>/dev/null || true
  "$REAL_TMUX" -L "$SOCKET" kill-session -t '=main-1' 2>/dev/null || true
  "$REAL_TMUX" -L "$SOCKET" kill-session -t '=waspflow' 2>/dev/null || true
  rm -rf -- "$WORK"
}
trap cleanup EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

mkdir -p "$PLUGIN_DIR" "$BIN_DIR" "$TEST_HOME/.tmux/resurrect"
cat >"$PLUGIN_DIR/save-assistant-sessions.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
PANE_FILE="$1"
	tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index}|#{pane_pid}|#{pane_current_path}|#{pane_tty}" >"$PANE_FILE"
EOF
chmod +x "$PLUGIN_DIR/save-assistant-sessions.sh"

cat >"$BIN_DIR/tmux" <<'EOF'
#!/usr/bin/env bash
exec "$REAL_TMUX" -L "$TEST_TMUX_SOCKET" "$@"
EOF
chmod +x "$BIN_DIR/tmux"

HOME="$TEST_HOME" PATH="$BIN_DIR:$PATH" REAL_TMUX="$REAL_TMUX" \
  TEST_TMUX_SOCKET="$SOCKET" bash "$PATCHER"

patched="$PLUGIN_DIR/save-assistant-sessions.sh"
grep -q '#{session_name}|#{session_group}|#{window_index}' "$patched" \
  || fail 'patch did not capture session_group in the list-panes row'
if grep -q '^[[:space:]]*session_group=$(tmux display-message -t "$session_name"' "$patched"; then
  fail 'ambiguous bare-session lookup remains executable'
fi
bash -n "$patched" || fail 'patched assistant saver is not valid bash'

"$REAL_TMUX" -L "$SOCKET" new-session -d -s main -n waspflow 'sleep 300'
"$REAL_TMUX" -L "$SOCKET" new-session -d -s main-1 -t '=main'
"$REAL_TMUX" -L "$SOCKET" new-session -d -s waspflow -n lane 'sleep 300'

PATH="$BIN_DIR:$PATH" REAL_TMUX="$REAL_TMUX" TEST_TMUX_SOCKET="$SOCKET" \
  "$patched" "$OUTPUT"

grep -q '^main:0\.0|' "$OUTPUT" || fail 'grouped main pane was not canonicalized to main'
grep -q '^waspflow:0\.0|' "$OUTPUT" || fail 'waspflow session was relabeled as main'

printf 'PASS: assistant saver keeps session identity when a window has the same name\n'
