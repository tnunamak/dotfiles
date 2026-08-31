#!/usr/bin/env bash
# Isolated integration test: systemd restore uses one transaction bundle and
# ignores newer raw resurrect files from another generation.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE_CLI="$ROOT/tmux/.config/tmux/scripts/resurrect-transaction-bundle"
SYSTEMD_RESTORE="$ROOT/tmux/.config/tmux/scripts/systemd-restore.sh"
REAL_TMUX="$(command -v tmux)"
SOCKET="test-systemd-restore-bundle-$$"
WORK="$(mktemp -d "${HOME}/.tmp/tmux-systemd-restore-bundle.XXXXXX")"
HOME_DIR="$WORK/home"
BIN_DIR="$WORK/bin"

cleanup() {
  "$REAL_TMUX" -L "$SOCKET" kill-session -t bootstrap >/dev/null 2>&1 || true
  chmod -R u+w "$WORK" >/dev/null 2>&1 || true
  rm -rf "$WORK"
}

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
trap cleanup EXIT

layout_file() {
  local path="$1" label="$2" count="$3" i
  : >"$path"
  for ((i = 0; i < count; i++)); do
    printf 'pane\t%s:%s.0\t/home/tnunamak\t1\tbash\n' "$label" "$i" >>"$path"
  done
}

assistant_file() {
  local path="$1" label="$2" count="$3" i
  printf '{"sessions":[' >"$path"
  for ((i = 0; i < count; i++)); do
    (( i > 0 )) && printf ',' >>"$path"
    printf '{"pane":"%s:%s.0","tool":"codex","session_id":"%s-%s"}' "$label" "$i" "$label" "$i" >>"$path"
  done
  printf ']}\n' >>"$path"
}

mkdir -p "$HOME_DIR/.tmux/resurrect" "$HOME_DIR/.tmux/plugins/tmux-resurrect/scripts" "$HOME_DIR/.config/tmux/scripts" "$BIN_DIR"
ln -s "$BUNDLE_CLI" "$HOME_DIR/.config/tmux/scripts/resurrect-transaction-bundle"

cat >"$BIN_DIR/tmux" <<'EOF'
#!/usr/bin/env bash
exec "$REAL_TMUX" -L "$TEST_TMUX_SOCKET" "$@"
EOF
chmod +x "$BIN_DIR/tmux"

cat >"$HOME_DIR/.tmux/plugins/tmux-resurrect/scripts/restore.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cp "$(readlink -f "$HOME/.tmux/resurrect/last")" "$TEST_RESTORE_LAYOUT_COPY"
cp "$HOME/.tmux/resurrect/assistant-sessions.json" "$TEST_RESTORE_ASSISTANT_COPY"
EOF
chmod +x "$HOME_DIR/.tmux/plugins/tmux-resurrect/scripts/restore.sh"

export HOME="$HOME_DIR"
export PATH="$BIN_DIR:$PATH"
export REAL_TMUX TEST_TMUX_SOCKET="$SOCKET"
export TEST_RESTORE_LAYOUT_COPY="$WORK/restored-layout.txt"
export TEST_RESTORE_ASSISTANT_COPY="$WORK/restored-assistant.json"
export TMUX_RESURRECT_DIR="$HOME_DIR/.tmux/resurrect"
export TMUX_RESURRECT_BUNDLE_NOW_ISO="2026-08-30T22:00:00Z"
export TMUX_RESURRECT_SAVE_MIN_PCT=80

layout_a="$WORK/tmux_resurrect_A.txt"
assistant_a="$WORK/assistant-sessions-A.json"
layout_b="$HOME_DIR/.tmux/resurrect/tmux_resurrect_B.txt"
assistant_b="$HOME_DIR/.tmux/resurrect/assistant-sessions.json"
layout_file "$layout_a" bundleA 5
assistant_file "$assistant_a" bundleA 3
"$BUNDLE_CLI" commit --layout "$layout_a" --assistant "$assistant_a" --provenance test --id bundle-A >/dev/null

layout_file "$layout_b" rawB 9
assistant_file "$assistant_b" rawB 7
ln -sfn "$(basename "$layout_b")" "$HOME_DIR/.tmux/resurrect/last"

"$REAL_TMUX" -L "$SOCKET" new-session -d -s bootstrap 'exec bash'
bash "$SYSTEMD_RESTORE"

grep -q 'bundleA:0.0' "$TEST_RESTORE_LAYOUT_COPY" || fail 'bundle layout was not restored'
! grep -q 'rawB' "$TEST_RESTORE_LAYOUT_COPY" || fail 'raw layout B leaked into restore'
[[ "$(jq -r '.sessions | length' "$TEST_RESTORE_ASSISTANT_COPY")" == 3 ]] || fail 'bundle assistant sidecar was not restored'
jq -e 'all(.sessions[]; .session_id | startswith("bundleA-"))' "$TEST_RESTORE_ASSISTANT_COPY" >/dev/null \
  || fail 'raw assistant B leaked into restore'
grep -q 'using transaction bundle bundle-A' "$HOME_DIR/.tmux/resurrect/systemd-restore.log" \
  || fail 'bundle restore log line missing'
! grep -q 'legacy raw' "$HOME_DIR/.tmux/resurrect/systemd-restore.log" \
  || fail 'legacy fallback was used even though a bundle existed'

rm -f "$TEST_RESTORE_LAYOUT_COPY" "$TEST_RESTORE_ASSISTANT_COPY"
chmod u+w "$HOME_DIR/.tmux/resurrect/transactions/last-good.json"
printf '{"schema":"tmux-resurrect-transaction-bundle/v1","id":"missing-bundle"}\n' \
  >"$HOME_DIR/.tmux/resurrect/transactions/last-good.json"
if bash "$SYSTEMD_RESTORE" >/dev/null 2>&1; then
  fail 'restore succeeded with corrupt initialized transaction state'
fi
grep -q 'transaction state exists but no valid last-good bundle resolved; aborting' "$HOME_DIR/.tmux/resurrect/systemd-restore.log" \
  || fail 'corrupt transaction abort was not logged'
[[ ! -e "$TEST_RESTORE_LAYOUT_COPY" && ! -e "$TEST_RESTORE_ASSISTANT_COPY" ]] \
  || fail 'corrupt transaction fell back to raw restore'

printf 'PASS: systemd restore uses bundle A and ignores newer raw B on isolated socket %s\n' "$SOCKET"
