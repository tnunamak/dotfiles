#!/usr/bin/env bash
# Diagnostic: runs via tmux.service ExecStartPost. Captures state just after
# systemd starts the tmux server, waits for continuum auto-restore to happen,
# then records whether the boot-trace-restore.sh wrapper was ever called.
#
# If boot-trace.log does not exist after the wait, continuum decided to skip
# the restore (which is what appears to have happened 2026-04-04). If it does
# exist, the wrapper tells us exactly what restore.sh did.
#
# Removed once the bug is diagnosed.

set -u

LOG="${HOME}/.tmux/resurrect/boot-trace-post-start.log"
TRACE="${HOME}/.tmux/resurrect/boot-trace.log"

mkdir -p "$(dirname "$LOG")"

ts() { date '+%Y-%m-%dT%H:%M:%S.%3N%z'; }
log() { printf '[%s] %s\n' "$(ts)" "$*" >>"$LOG"; }
log_block() {
  local label="$1"; shift
  {
    printf '[%s] --- BEGIN %s ---\n' "$(ts)" "$label"
    "$@" 2>&1 | sed 's/^/    /'
    printf '[%s] --- END %s ---\n' "$(ts)" "$label"
  } >>"$LOG"
}

# Rotate log if huge
if [ -f "$LOG" ] && [ "$(stat -c '%s' "$LOG" 2>/dev/null || echo 0)" -gt 1048576 ]; then
  mv "$LOG" "${LOG}.old"
fi

log "============================================================"
log "boot-trace-post-start.sh invoked by systemd ExecStartPost"
log "boot id: $(cat /proc/sys/kernel/random/boot_id 2>/dev/null || echo unknown)"
log "uptime: $(uptime)"

# Immediate snapshot (T+0)
log "--- T+0 immediately after ExecStart ---"
log_block "tmux processes" bash -c 'ps -u "$(id -u)" -o pid,ppid,stat,etime,command | grep -E "tmux|^\s*PID" | grep -v grep'
log_block "tmux list-sessions" tmux list-sessions
log_block "option @continuum-restore" tmux show-option -gqv @continuum-restore
log_block "option @resurrect-restore-script-path" tmux show-option -gqv @resurrect-restore-script-path
log_block "halt file exists?" ls -la "${HOME}/tmux_no_auto_restore"

# Continuum restore runs in background with a 1s sleep + up to ~15s to complete restore.
# Wait 20s total for the trace log to appear.
log "--- waiting up to 20s for boot-trace.log to appear ---"
for i in $(seq 1 20); do
  if [ -f "$TRACE" ]; then
    log "boot-trace.log appeared after ${i}s"
    break
  fi
  sleep 1
done

if [ ! -f "$TRACE" ]; then
  log "boot-trace.log DID NOT appear after 20s — continuum auto-restore never called restore.sh"
fi

# Final snapshot (T+20)
log "--- T+20 after wait ---"
log_block "tmux list-sessions" tmux list-sessions
log_block "tmux list-windows -a" tmux list-windows -a
log_block "tmux processes" bash -c 'ps -u "$(id -u)" -o pid,ppid,stat,etime,command | grep -E "tmux|^\s*PID" | grep -v grep'

log "boot-trace-post-start.sh done"
log ""
