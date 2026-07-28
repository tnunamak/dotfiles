#!/usr/bin/env bash
# Regression test for retiring AR-Patch8.
#
# AR-Patch8 wrapped `codex resume` in `timeout 45`. That cannot time out only
# OAuth bootstrap: a healthy Codex TUI is the same foreground process and is
# expected to remain alive, so the wrapper killed every successful restore at
# 45 seconds. This test runs the real patcher against isolated plugin fixtures
# and proves:
#   1. Both exact AR-Patch8 assignment forms are rolled back.
#   2. Fresh upstream assignments remain untouched.
#   3. A healthy foreground Codex command remains alive past a short simulated
#      startup deadline instead of being killed by an inner timeout.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PATCHER="$ROOT/tmux/.config/tmux/scripts/patch-assistant-resurrect.sh"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/patch8-retirement-test.XXXXXX")"
HOME_DIR="$WORK/home"
PLUGIN_DIR="$HOME_DIR/.tmux/plugins/tmux-assistant-resurrect/scripts"
RESTORE_ASSISTANT="$PLUGIN_DIR/restore-assistant-sessions.sh"
ASSISTANT_SAVE="$PLUGIN_DIR/save-assistant-sessions.sh"
FIXTURE_BIN="$WORK/bin"
trap 'rm -rf "$WORK"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

mkdir -p "$PLUGIN_DIR" "$FIXTURE_BIN"
# The patcher intentionally exits early until the plugin's save script exists.
printf '#!/usr/bin/env bash\n' >"$ASSISTANT_SAVE"

cat >"$RESTORE_ASSISTANT" <<'EOF'
#!/usr/bin/env bash
safe_cli_args=
safe_sid=
resume_cmd="command timeout 45 codex${safe_cli_args} resume ${safe_sid}" # AR-Patch8
resume_cmd="command timeout 45 codex resume ${safe_sid}" # AR-Patch8
EOF

HOME="$HOME_DIR" bash "$PATCHER"
bash -n "$RESTORE_ASSISTANT" || fail 'Patch-8 rollback produced invalid bash'
grep -qF 'resume_cmd="command codex${safe_cli_args} resume ${safe_sid}"' "$RESTORE_ASSISTANT" ||
  fail 'did not roll back the safe_cli_args assignment'
grep -qF 'resume_cmd="command codex resume ${safe_sid}"' "$RESTORE_ASSISTANT" ||
  fail 'did not roll back the bare assignment'
if grep -qF 'AR-Patch8' "$RESTORE_ASSISTANT" ||
   grep -qF 'command timeout 45 codex' "$RESTORE_ASSISTANT"; then
  fail 'destructive Patch-8 timeout or marker survived rollback'
fi
grep -qF 'retired patch 8: removed destructive codex resume timeout' \
  "$HOME_DIR/.tmux/resurrect/patch-assistant-resurrect.log" ||
  fail 'rollback was not logged'

# A second run must be a no-op: the retired patch must not be reintroduced.
HOME="$HOME_DIR" bash "$PATCHER"
tail -n 1 "$HOME_DIR/.tmux/resurrect/patch-assistant-resurrect.log" |
  grep -qF 'ran, 0 applied' || fail 'Patch-8 retirement is not idempotent'

# A fresh upstream file has no marker and must remain byte-for-byte unchanged.
cat >"$RESTORE_ASSISTANT" <<'EOF'
#!/usr/bin/env bash
safe_cli_args=
safe_sid=
resume_cmd="command codex${safe_cli_args} resume ${safe_sid}"
resume_cmd="command codex resume ${safe_sid}"
EOF
cp "$RESTORE_ASSISTANT" "$WORK/upstream.before"
HOME="$HOME_DIR" bash "$PATCHER"
cmp -s "$WORK/upstream.before" "$RESTORE_ASSISTANT" ||
  fail 'retired patch changed a fresh upstream plugin file'

# A marker-shaped string is not an assignment. The rollback must fail closed
# and preserve it byte-for-byte rather than rewriting quoted documentation or
# logging text that happens to contain the old line.
cat >"$RESTORE_ASSISTANT" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' 'resume_cmd="command timeout 45 codex resume ${safe_sid}" # AR-Patch8'
EOF
cp "$RESTORE_ASSISTANT" "$WORK/near-miss.before"
HOME="$HOME_DIR" bash "$PATCHER"
cmp -s "$WORK/near-miss.before" "$RESTORE_ASSISTANT" ||
  fail 'Patch-8 rollback rewrote a marker-shaped string instead of an assignment'

# Healthy Codex is a foreground interactive process. Emit a readiness marker,
# then stay alive like a TUI. The outer 2s timeout is test cleanup only: rc=124
# proves the restored upstream command itself did not kill the healthy process.
cat >"$FIXTURE_BIN/codex" <<'EOF'
#!/usr/bin/env bash
printf 'READY\n'
exec sleep 30
EOF
chmod +x "$FIXTURE_BIN/codex"

# Reproduce the retired wrapper at a scaled one-second deadline: even after
# the stub reports READY, timeout kills the healthy foreground process.
set +e
historical_output="$(PATH="$FIXTURE_BIN:/usr/bin:/bin" timeout 1 codex \
  resume test-session-id 2>&1)"
historical_rc=$?
set -e
[[ "$historical_rc" -eq 124 && "$historical_output" == READY ]] ||
  fail "could not reproduce Patch 8 killing a healthy foreground Codex (rc=$historical_rc output=$historical_output)"

set +e
healthy_output="$(PATH="$FIXTURE_BIN:/usr/bin:/bin" timeout 2 bash -c \
  'command codex resume test-session-id' 2>&1)"
healthy_rc=$?
set -e
[[ "$healthy_rc" -eq 124 && "$healthy_output" == READY ]] ||
  fail "healthy foreground Codex did not survive the simulated startup deadline (rc=$healthy_rc output=$healthy_output)"

echo 'PASS: AR-Patch8 is retired idempotently, both marked forms are rolled back, fresh upstream stays untouched, and healthy Codex is not given a destructive inner timeout'
