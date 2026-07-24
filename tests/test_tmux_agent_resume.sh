#!/usr/bin/env bash
# Isolated integration test for lease-gated agent recovery.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="${ROOT}/bin/.local/bin/tmux-agent-resume"
POST_RESTORE="${ROOT}/tmux/.config/tmux/scripts/post-restore-grouped-focus.sh"
REAL_TMUX="$(command -v tmux)"
SOCKET="test-agent-resume-$$"
WORK="$(mktemp -d "${HOME}/.tmp/tmux-agent-resume-test.XXXXXX")"
HOME_DIR="${WORK}/home"
BIN_DIR="${WORK}/bin"
AGENT_LOG="${WORK}/agent.log"
MCP_LOG="${WORK}/mcp.log"
PLUGIN_LOG="${WORK}/plugin.log"

cleanup() {
  [[ -n "${CLIENT_PID:-}" ]] && kill "$CLIENT_PID" 2>/dev/null || true
  [[ -n "${CLIENT_INPUT_PID:-}" ]] && kill "$CLIENT_INPUT_PID" 2>/dev/null || true
  "${REAL_TMUX}" -L "$SOCKET" kill-session -t main >/dev/null 2>&1 || true
  "${REAL_TMUX}" -L "$SOCKET" kill-session -t main-9 >/dev/null 2>&1 || true
  rm -rf "$WORK"
}
trap cleanup EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
assert_json() { jq -e "$1" >/dev/null || fail "JSON assertion failed: $1"; }
wait_for_file_lines() {
  local file="$1" expected="$2" count=0
  for _ in $(seq 1 50); do
    count="$(wc -l <"$file" 2>/dev/null || echo 0)"
    (( count >= expected )) && return 0
    sleep 0.1
  done
  fail "expected $expected line(s) in $file, found $count"
}
attach_client() {
  local input_fifo="${WORK}/client-input"
  rm -f "$input_fifo"
  mkfifo "$input_fifo"
  sleep 600 >"$input_fifo" &
  CLIENT_INPUT_PID=$!
  "${REAL_TMUX}" -L "$SOCKET" -C attach-session -t main <"$input_fifo" >/dev/null 2>&1 &
  CLIENT_PID=$!
  for _ in $(seq 1 30); do
    [[ -n "$("${REAL_TMUX}" -L "$SOCKET" list-clients -t main -F '#{client_session}' 2>/dev/null || true)" ]] && return 0
    sleep 0.1
  done
  fail 'control-mode client did not attach'
}
detach_client() {
  [[ -n "${CLIENT_PID:-}" ]] && kill "$CLIENT_PID" 2>/dev/null || true
  [[ -n "${CLIENT_INPUT_PID:-}" ]] && kill "$CLIENT_INPUT_PID" 2>/dev/null || true
  wait "${CLIENT_PID:-}" 2>/dev/null || true
  wait "${CLIENT_INPUT_PID:-}" 2>/dev/null || true
  unset CLIENT_PID
  unset CLIENT_INPUT_PID
  for _ in $(seq 1 30); do
    [[ -z "$("${REAL_TMUX}" -L "$SOCKET" list-clients -t main -F '#{client_session}' 2>/dev/null || true)" ]] && return 0
    sleep 0.1
  done
  fail 'control-mode client did not detach'
}

mkdir -p "${HOME_DIR}/.tmux/resurrect" "${HOME_DIR}/.local/state" "$BIN_DIR" \
  "${HOME_DIR}/.tmux/plugins/tmux-assistant-resurrect/scripts"

cat >"${BIN_DIR}/tmux" <<'EOF'
#!/usr/bin/env bash
exec "$REAL_TMUX" -L "$TEST_TMUX_SOCKET" "$@"
EOF
cat >"${BIN_DIR}/codex" <<'EOF'
#!/usr/bin/env bash
printf 'codex %s\n' "$*" >>"$TEST_AGENT_LOG"
mcp-searxng
EOF
cat >"${BIN_DIR}/claude" <<'EOF'
#!/usr/bin/env bash
printf 'claude %s\n' "$*" >>"$TEST_AGENT_LOG"
mcp-searxng
EOF
cat >"${BIN_DIR}/mcp-searxng" <<'EOF'
#!/usr/bin/env bash
printf 'mcp\n' >>"$TEST_MCP_LOG"
EOF
cat >"${HOME_DIR}/.tmux/plugins/tmux-assistant-resurrect/scripts/restore-assistant-sessions.sh" <<'EOF'
#!/usr/bin/env bash
printf 'third-party replay invoked\n' >>"$TEST_PLUGIN_LOG"
EOF
chmod +x "${BIN_DIR}/tmux" "${BIN_DIR}/codex" "${BIN_DIR}/claude" "${BIN_DIR}/mcp-searxng" \
  "${HOME_DIR}/.tmux/plugins/tmux-assistant-resurrect/scripts/restore-assistant-sessions.sh"

export HOME="$HOME_DIR"
export XDG_STATE_HOME="${HOME_DIR}/.local/state"
export PATH="${BIN_DIR}:${PATH}"
export REAL_TMUX TEST_TMUX_SOCKET="$SOCKET" TEST_AGENT_LOG="$AGENT_LOG" TEST_MCP_LOG="$MCP_LOG" TEST_PLUGIN_LOG="$PLUGIN_LOG"
export TMUX_AGENT_RESUME_BIN="$CLI"
export TMUX_AGENT_RESUME_TMUX="${BIN_DIR}/tmux"
export TMUX_AGENT_RESUME_NOW_ISO='2026-07-13T12:00:00Z'

# Every test-side tmux command uses this unique -L socket, including cleanup.
"${REAL_TMUX}" -L "$SOCKET" new-session -d -s main 'exec bash'
"${REAL_TMUX}" -L "$SOCKET" new-window -t main:1 'exec bash'
"${REAL_TMUX}" -L "$SOCKET" new-session -d -s main-9 -t =main

cat >"${HOME_DIR}/.tmux/resurrect/assistant-sessions.json" <<'JSON'
{
  "timestamp": "2026-07-13T11:59:00Z",
  "sessions": [
    {"pane":"main:0.0","tool":"codex","session_id":"codex-session","cwd":"/tmp","cli_args":""},
    {"pane":"main:1.0","tool":"claude","session_id":"claude-session","cwd":"/tmp","cli_args":"--model test"},
    {"pane":"main:99.0","tool":"codex","session_id":"absent-session","cwd":"/tmp","cli_args":""}
  ]
}
JSON
cat >"${HOME_DIR}/.tmux/resurrect/tmux_resurrect_fixture.txt" <<'EOF'
grouped_session	main-9	main	:0	:1
EOF
ln -s tmux_resurrect_fixture.txt "${HOME_DIR}/.tmux/resurrect/last"

# Layout handling stays active, but the hook must only record the sidecar.
bash "$POST_RESTORE"
"${REAL_TMUX}" -L "$SOCKET" has-session -t =main
! "${REAL_TMUX}" -L "$SOCKET" has-session -t =main-9 >/dev/null 2>&1
[[ -s "${HOME_DIR}/.local/state/tmux-grouped-sessions/main.restore-queue" ]] || fail 'layout restore queue was not written'
[[ ! -e "$AGENT_LOG" ]] || fail 'deferred hook launched an agent'
[[ ! -e "$MCP_LOG" ]] || fail 'deferred hook launched an MCP server'
[[ ! -e "$PLUGIN_LOG" ]] || fail 'deferred hook invoked the third-party replay script'

export TMUX_AGENT_RESUME_NOW=1000
status="$($CLI status --json)"
assert_json '.entries | length == 3 and all(.[]; .state == "deferred" and .reason == "no explicit resume lease")' <<<"$status"
plan="$($CLI plan --json)"
assert_json '(.entries | all(.[]; .action == "defer")) and .orphan_candidates == []' <<<"$plan"

attach_client
# An explicit selected resume still cannot send into an absent pane. The manual
# lease is recorded for audit, but its status remains deferred rather than
# eligible and neither fake process is launched.
if $CLI resume main:99.0 >/dev/null 2>&1; then
  fail 'selected resume succeeded for an absent pane'
fi
status="$($CLI status --json)"
assert_json '.entries[] | select(.pane == "main:99.0") | .state == "deferred" and .reason == "saved pane is absent" and .lease.policy == "manual"' <<<"$status"
[[ ! -e "$AGENT_LOG" && ! -e "$MCP_LOG" ]] || fail 'absent selected resume launched a process'

# Neither attached-client nor explicit headless auto leases can bypass pane
# existence. apply must skip both and leave their lease unconsumed.
$CLI grant main:99.0 --auto --ttl 10 >/dev/null
plan="$($CLI plan --json)"
assert_json '.entries[] | select(.pane == "main:99.0") | .state == "deferred" and .reason == "saved pane is absent"' <<<"$plan"
absent_apply="$($CLI apply --execute-auto)"
assert_json '.applied == []' <<<"$absent_apply"
status="$($CLI status --json)"
assert_json '.entries[] | select(.pane == "main:99.0") | .lease.policy == "explicit-auto" and .lease.consumed_at == null' <<<"$status"
$CLI grant main:99.0 --auto --ttl 10 --allow-headless --owner waspflow >/dev/null
plan="$($CLI plan --json)"
assert_json '.entries[] | select(.pane == "main:99.0") | .state == "deferred" and .reason == "saved pane is absent" and .lease.allow_headless == true' <<<"$plan"
absent_headless_apply="$($CLI apply --execute-auto)"
assert_json '.applied == []' <<<"$absent_headless_apply"
status="$($CLI status --json)"
assert_json '.entries[] | select(.pane == "main:99.0") | .lease.consumed_at == null' <<<"$status"
[[ ! -e "$AGENT_LOG" && ! -e "$MCP_LOG" ]] || fail 'absent automatic resume launched a process'

# An automatic lease alone cannot overcome the attached-client gate.
detach_client
$CLI grant main:0.0 --auto --ttl 10 >/dev/null
plan="$($CLI plan --json)"
assert_json '.entries[] | select(.pane == "main:0.0") | .state == "deferred" and .reason == "automatic lease requires an attached client"' <<<"$plan"
attach_client
plan="$($CLI plan --json)"
assert_json '.entries[] | select(.pane == "main:0.0") | .state == "eligible" and .reason == "unexpired explicit lease and attached client"' <<<"$plan"
first_apply="$($CLI apply --execute-auto)"
assert_json '.applied | length == 1' <<<"$first_apply"
wait_for_file_lines "$AGENT_LOG" 1
wait_for_file_lines "$MCP_LOG" 1
grep -q '^codex resume codex-session$' "$AGENT_LOG" || fail 'automatic resume command was not selected correctly'
plan="$($CLI plan --json)"
assert_json '.entries[] | select(.pane == "main:0.0") | .state == "deferred" and .reason == "automatic lease already consumed"' <<<"$plan"
second_apply="$($CLI apply --execute-auto)"
assert_json '.applied == []' <<<"$second_apply"
[[ "$(wc -l <"$AGENT_LOG")" == 1 && "$(wc -l <"$MCP_LOG")" == 1 ]] || fail 'automatic lease dispatched more than once'

# Selected resume is also attachment-gated; it launches only the selected pane.
detach_client
if $CLI resume main:1.0 >/dev/null 2>&1; then
  fail 'selected resume succeeded without an attached client'
fi
[[ "$(wc -l <"$AGENT_LOG")" == 1 ]] || fail 'failed selected resume launched an agent'
attach_client
$CLI resume main:1.0 >/dev/null
wait_for_file_lines "$AGENT_LOG" 2
wait_for_file_lines "$MCP_LOG" 2
grep -q '^claude --model test --resume claude-session$' "$AGENT_LOG" || fail 'selected resume command was not selected correctly'

# Expiry is deterministic and fail-closed even if a prior lease was valid.
detach_client
export TMUX_AGENT_RESUME_NOW=2000
$CLI grant main:1.0 --auto --ttl 2 >/dev/null
export TMUX_AGENT_RESUME_NOW=2003
plan="$($CLI plan --json)"
assert_json '.entries[] | select(.pane == "main:1.0") | .state == "expired" and .reason == "lease expired"' <<<"$plan"
$CLI apply --execute-auto >/dev/null
[[ "$(wc -l <"$AGENT_LOG")" == 2 ]] || fail 'expired lease launched an agent'

# Headless operation is a separate explicit orchestration path, not an inferred fallback.
export TMUX_AGENT_RESUME_NOW=3000
$CLI grant main:1.0 --auto --ttl 10 --allow-headless --owner waspflow >/dev/null
plan="$($CLI plan --json)"
assert_json '.entries[] | select(.pane == "main:1.0") | .state == "eligible" and .lease.allow_headless == true and .lease.owner == "waspflow"' <<<"$plan"
assert_json '.mode == "report-only" and (.candidates | length == 1) and .candidates[0].pane == "main:0.0"' <<<"$($CLI orphans --json)"

# Cold boot stays inert until the first human client attaches. That attendance
# consumes a one-shot marker and uses headless boot-restore leases for every
# sidecar entry, including worker sessions without their own client.
$CLI record-deferred >/dev/null
$CLI mark-boot-restore >/dev/null
[[ -f "${HOME_DIR}/.local/state/tmux-agent-resume/boot-restore-pending.json" ]] || fail 'boot restore marker was not written'
[[ "$(wc -l <"$AGENT_LOG")" == 2 ]] || fail 'marking boot restore launched an agent'
attach_client
attended="$($CLI attend-boot-restore)"
assert_json '.mode == "attended-boot-restore" and (.grants.granted | length == 3) and (.applied.applied | length == 2)' <<<"$attended"
wait_for_file_lines "$AGENT_LOG" 4
wait_for_file_lines "$MCP_LOG" 4
[[ ! -f "${HOME_DIR}/.local/state/tmux-agent-resume/boot-restore-pending.json" ]] || fail 'attended restore marker was not consumed'
second_attended="$($CLI attend-boot-restore)"
[[ -z "$second_attended" ]] || fail 'attended restore triggered more than once'
[[ "$(wc -l <"$AGENT_LOG")" == 4 && "$(wc -l <"$MCP_LOG")" == 4 ]] || fail 'attended restore dispatched more than once'

printf 'PASS: tmux agent resume leases use deferred-by-default recovery on isolated socket %s\n' "$SOCKET"
