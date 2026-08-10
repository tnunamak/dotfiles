#!/usr/bin/env bash
# ExecStop wrapper for tmux.service. It must never convert a stop into a
# service failure: its job is to capture evidence, save resurrect state, then
# preserve the generated unit's kill-server behavior.
set -u

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/tmux-service"
LOG="$STATE_DIR/stop.log"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
SNAPSHOT="$STATE_DIR/stop-$STAMP-$$.log"
SAVE_SCRIPT="$HOME/.tmux/plugins/tmux-resurrect/scripts/save.sh"

mkdir -p "$STATE_DIR"

# Keep the rolling log bounded. Individual snapshots remain for postmortems.
if [[ -f "$LOG" ]] && (( $(stat -c %s "$LOG" 2>/dev/null || echo 0) > 10485760 )); then
  mv "$LOG" "$LOG.old"
fi

exec > >(tee -a "$SNAPSHOT" "$LOG") 2>&1

section() {
  printf '\n[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"
}

run() {
  section "$*"
  "$@" || printf 'command exited %s: %s\n' "$?" "$*"
}

section "tmux.service ExecStop begin"
printf 'pid=%s ppid=%s uid=%s user=%s shell=%s pwd=%s\n' \
  "$$" "$PPID" "$(id -u)" "$(id -un)" "${SHELL:-<unset>}" "$PWD"
printf 'SERVICE_RESULT=%s EXIT_CODE=%s EXIT_STATUS=%s MAINPID=%s INVOCATION_ID=%s\n' \
  "${SERVICE_RESULT:-<unset>}" "${EXIT_CODE:-<unset>}" \
  "${EXIT_STATUS:-<unset>}" "${MAINPID:-<unset>}" "${INVOCATION_ID:-<unset>}"
printf 'snapshot=%s\n' "$SNAPSHOT"
ln -sfn "$(basename "$SNAPSHOT")" "$STATE_DIR/stop.latest.log" 2>/dev/null || true

run systemctl --user show tmux.service \
  -p ActiveState -p SubState -p Result -p MainPID -p ExecMainPID \
  -p ExecMainStatus -p NRestarts -p Restart -p ExecStop -p ControlPID \
  -p FragmentPath -p DropInPaths --no-pager

section "tmux server state"
if command tmux -N display-message -p '#{pid}' >/dev/null 2>&1; then
  tmux_server_responsive=1
  command tmux -N display-message -p 'server_pid=#{pid} sessions=#{session_count} windows=#{window_count}'
  command tmux -N list-sessions -F 'session=#{session_name} group=#{session_group} attached=#{session_attached} windows=#{session_windows}' || true
  command tmux -N list-clients -F 'client=#{client_name} session=#{client_session} tty=#{client_tty} pid=#{client_pid}' || true
else
  tmux_server_responsive=0
  printf 'tmux server is not responsive before ExecStop save/kill\n'
fi

run ps -eo user:20,pid,ppid,pgid,sid,stat,lstart,etimes,comm,args --cols 320
run journalctl --user --since '3 min ago' --no-pager -o short-iso

section "tmux-resurrect save"
if (( ! tmux_server_responsive )); then
  printf 'skipping tmux-resurrect save because tmux server is not responsive; preserving previous last save\n'
elif [[ -x "$SAVE_SCRIPT" ]]; then
  timeout 300s "$SAVE_SCRIPT"
  save_rc=$?
  printf 'save_rc=%s save_script=%s\n' "$save_rc" "$SAVE_SCRIPT"
else
  printf 'save script missing or not executable: %s\n' "$SAVE_SCRIPT"
fi

section "tmux kill-server"
command tmux -N kill-server 2>/dev/null || true

section "tmux.service ExecStop end"
exit 0
