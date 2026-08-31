#!/usr/bin/env bash
# Faithful post-save hook fixture for tmux-resurrect's save.sh order:
# post-save-layout receives the exact layout path, then save.sh advances `last`,
# then post-save-all runs without arguments.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WRAPPER="$ROOT/tmux/.config/tmux/scripts/post-save-transaction.sh"
WORK="$(mktemp -d "${HOME}/.tmp/tmux-post-save-transaction.XXXXXX")"
HOME_DIR="$WORK/home"

cleanup() {
  chmod -R u+w "$WORK" >/dev/null 2>&1 || true
  rm -rf "$WORK"
}
trap cleanup EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

layout_file() {
  local path="$1" count="$2" label="${3:-main}" i
  : >"$path"
  for ((i = 0; i < count; i++)); do
    printf 'pane\t%s:%s.0\t/home/tnunamak\t1\tbash\n' "$label" "$i" >>"$path"
  done
}

assistant_file() {
  local path="$1" count="$2" label="${3:-assistant}" i
  printf '{"sessions":[' >"$path"
  for ((i = 0; i < count; i++)); do
    (( i > 0 )) && printf ',' >>"$path"
    printf '{"pane":"main:%s.0","tool":"codex","session_id":"%s-%s"}' "$i" "$label" "$i" >>"$path"
  done
  printf ']}\n' >>"$path"
}

faithful_save_fixture() {
  local layout="$1"
  "$WRAPPER" "$layout"
  if ! cmp -s "$layout" "$HOME/.tmux/resurrect/last" 2>/dev/null; then
    ln -sfn "$(basename "$layout")" "$HOME/.tmux/resurrect/last"
  else
    rm -f "$layout"
  fi
  : # post-save-all is intentionally empty in tmux.conf.
}

mkdir -p "$HOME_DIR/.tmux/resurrect" "$HOME_DIR/.tmux/plugins/tmux-assistant-resurrect/scripts" "$HOME_DIR/.config/tmux/scripts"
ln -s "$ROOT/tmux/.config/tmux/scripts/post-save-backup.sh" "$HOME_DIR/.config/tmux/scripts/post-save-backup.sh"
ln -s "$ROOT/tmux/.config/tmux/scripts/save-assistant-sessions-guarded.sh" "$HOME_DIR/.config/tmux/scripts/save-assistant-sessions-guarded.sh"
ln -s "$ROOT/tmux/.config/tmux/scripts/resurrect-transaction-bundle" "$HOME_DIR/.config/tmux/scripts/resurrect-transaction-bundle"

cat >"$HOME_DIR/.tmux/plugins/tmux-assistant-resurrect/scripts/save-assistant-sessions.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ -n "${TEST_ASSISTANT_SLEEP:-}" ]]; then
  sleep "$TEST_ASSISTANT_SLEEP"
fi
cp "$TEST_ASSISTANT_SOURCE" "$HOME/.tmux/resurrect/assistant-sessions.json"
EOF
chmod +x "$HOME_DIR/.tmux/plugins/tmux-assistant-resurrect/scripts/save-assistant-sessions.sh"

export HOME="$HOME_DIR"
export TMUX_RESURRECT_BUNDLE_NOW_ISO="2026-08-30T23:00:00Z"
export TMUX_RESURRECT_SAVE_MIN_PCT=80
# This fixture isolates count/transaction behavior. Identity evidence has its
# own deterministic process fixture in test_tmux_assistant_identity_gate.sh.
export TMUX_RESURRECT_TEST_SKIP_IDENTITY_VALIDATION=1

layout_a="$HOME/.tmux/resurrect/tmux_resurrect_A.txt"
assistant_a="$WORK/assistant-A.json"
layout_file "$layout_a" 10 A
assistant_file "$assistant_a" 5 A
export TEST_ASSISTANT_SOURCE="$assistant_a"
faithful_save_fixture "$layout_a"
[[ "$(jq -r '.id' "$HOME/.tmux/resurrect/transactions/last-good.json")" != null ]] \
  || fail 'baseline transaction did not initialize'
baseline_id="$(jq -r '.id' "$HOME/.tmux/resurrect/transactions/last-good.json")"

layout_rejected="$HOME/.tmux/resurrect/tmux_resurrect_layout_rejected.txt"
assistant_b="$WORK/assistant-B.json"
layout_file "$layout_rejected" 3 B
assistant_file "$assistant_b" 5 B
export TEST_ASSISTANT_SOURCE="$assistant_b"
faithful_save_fixture "$layout_rejected"
[[ "$(jq -r '.id' "$HOME/.tmux/resurrect/transactions/last-good.json")" == "$baseline_id" ]] \
  || fail 'layout-rejected invocation advanced last-good'
grep -q 'layout rejected .* running assistant save without bundle commit' "$HOME/.tmux/resurrect/post-save-transaction.log" \
  || fail 'layout rejection did not suppress bundle commit'

layout_ok="$HOME/.tmux/resurrect/tmux_resurrect_layout_ok.txt"
assistant_rejected="$WORK/assistant-rejected.json"
layout_file "$layout_ok" 10 C
assistant_file "$assistant_rejected" 1 rejected
export TEST_ASSISTANT_SOURCE="$assistant_rejected"
faithful_save_fixture "$layout_ok"
[[ "$(jq -r '.id' "$HOME/.tmux/resurrect/transactions/last-good.json")" == "$baseline_id" ]] \
  || fail 'assistant-rejected invocation advanced last-good'
[[ "$(jq -r '.sessions | length' "$HOME/.tmux/resurrect/assistant-sessions.json")" == 5 ]] \
  || fail 'rejected assistant sidecar was not restored/recounted'

layout_locked="$HOME/.tmux/resurrect/tmux_resurrect_locked.txt"
assistant_locked="$WORK/assistant-locked.json"
layout_file "$layout_locked" 10 locked
assistant_file "$assistant_locked" 5 locked
export TEST_ASSISTANT_SOURCE="$assistant_locked"
exec 8>"$HOME/.tmux/resurrect/post-save-transaction.lock"
flock -n 8
"$WRAPPER" "$layout_locked"
exec 8>&-
[[ "$(jq -r '.id' "$HOME/.tmux/resurrect/transactions/last-good.json")" == "$baseline_id" ]] \
  || fail 'locked duplicate transaction advanced last-good'
grep -q 'skipping duplicate concurrent post-save transaction' "$HOME/.tmux/resurrect/post-save-transaction.log" \
  || fail 'lock skip was not logged'

printf 'PASS: post-save transaction wrapper preserves save hook generation and lock semantics\n'
