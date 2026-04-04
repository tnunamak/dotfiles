#!/usr/bin/env bash
# Diagnostic wrapper around tmux-resurrect's restore.sh.
# Logs environment, tmux state, process tree, and restore output with
# timestamps so we can trace what actually happens when continuum auto-restore
# fires at systemd boot.
#
# Installed via: set -g @resurrect-restore-script-path "~/.config/tmux/scripts/boot-trace-restore.sh"
# Removed once the boot-time restore bug is diagnosed.

set -u

LOG="${HOME}/.tmux/resurrect/boot-trace.log"
REAL_RESTORE="${HOME}/.tmux/plugins/tmux-resurrect/scripts/restore.sh"

# Rotate log when it exceeds 1 MB so repeated auto-restores during debugging
# don't grow it unbounded.
if [ -f "$LOG" ] && [ "$(stat -c '%s' "$LOG" 2>/dev/null || echo 0)" -gt 1048576 ]; then
  mv "$LOG" "${LOG}.old"
fi

mkdir -p "$(dirname "$LOG")"

ts() { date '+%Y-%m-%dT%H:%M:%S.%3N%z'; }

log() {
  printf '[%s] %s\n' "$(ts)" "$*" >>"$LOG"
}

log_block() {
  local label="$1"
  shift
  {
    printf '[%s] --- BEGIN %s ---\n' "$(ts)" "$label"
    "$@" 2>&1 | sed 's/^/    /'
    printf '[%s] --- END %s ---\n' "$(ts)" "$label"
  } >>"$LOG"
}

log "============================================================"
log "boot-trace-restore.sh invoked"
log "pid=$$  ppid=$PPID  caller_args=$*"

# Environment snapshot — we want to know what $TMUX looks like here
log "TMUX=[${TMUX:-<unset>}]"
log "PATH=$PATH"
log "HOME=$HOME"
log "USER=${USER:-<unset>}"
log "DISPLAY=${DISPLAY:-<unset>}"
log "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-<unset>}"
log "XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-<unset>}"
log "TMUX_TMPDIR=${TMUX_TMPDIR:-<unset>}"

# System / process state
log "system uptime: $(uptime 2>&1)"
log "boot id: $(cat /proc/sys/kernel/random/boot_id 2>/dev/null || echo unknown)"

log_block "tmux processes" bash -c 'ps -u "$(id -u)" -o pid,ppid,stat,etime,command | grep -E "tmux|^\s*PID" | grep -v "grep\|boot-trace"'
log_block "process tree up from $$" bash -c '
  pid=$$
  while [ "$pid" != 1 ] && [ -n "$pid" ]; do
    ps -o pid,ppid,command -p "$pid" 2>/dev/null | tail -n +2
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d " ")
    [ -z "$pid" ] && break
  done
'

# Can we reach the tmux server? (Uses default socket, matching what restore.sh does internally)
log_block "tmux list-sessions (default socket)" tmux list-sessions
log_block "tmux list-clients (default socket)" tmux list-clients
log_block "tmux show-options -g @resurrect-dir @resurrect-restore-script-path @continuum-restore @continuum-boot" bash -c '
  for opt in @resurrect-dir @resurrect-restore-script-path @continuum-restore @continuum-boot @continuum-restore-max-delay; do
    printf "%s = " "$opt"
    tmux show-option -gqv "$opt" || echo "(unset)"
  done
'

# What save file will be read?
LAST_FILE="$HOME/.tmux/resurrect/last"
if [ -L "$LAST_FILE" ]; then
  log "last -> $(readlink "$LAST_FILE")"
  target="$(readlink -f "$LAST_FILE" 2>/dev/null)"
  if [ -f "$target" ]; then
    log "save file size: $(stat -c '%s' "$target") bytes"
    log "save file mtime: $(stat -c '%y' "$target")"
    log_block "save file line counts by type" bash -c '
      grep -c "^pane" "$target" | xargs -I{} echo "pane lines: {}"
      grep -c "^window" "$target" | xargs -I{} echo "window lines: {}"
      grep -c "^grouped_session" "$target" | xargs -I{} echo "grouped_session lines: {}"
      grep -c "^state" "$target" | xargs -I{} echo "state lines: {}"
    ' _
  else
    log "save file target MISSING: $target"
  fi
else
  log "$LAST_FILE is not a symlink (or missing)"
fi

log "calling real restore.sh: $REAL_RESTORE $*"
START_EPOCH=$(date +%s.%N)
"$REAL_RESTORE" "$@" >>"$LOG".stdout 2>>"$LOG".stderr
REAL_EXIT=$?
END_EPOCH=$(date +%s.%N)
DURATION=$(awk "BEGIN { printf \"%.3f\", $END_EPOCH - $START_EPOCH }")
log "real restore.sh exited with code $REAL_EXIT after ${DURATION}s"

# Merge any captured stdout/stderr from this call into the main log
if [ -s "${LOG}.stdout" ]; then
  log_block "real restore.sh stdout" cat "${LOG}.stdout"
  : > "${LOG}.stdout"
fi
if [ -s "${LOG}.stderr" ]; then
  log_block "real restore.sh stderr" cat "${LOG}.stderr"
  : > "${LOG}.stderr"
fi

log_block "tmux list-sessions AFTER restore" tmux list-sessions
log_block "tmux list-windows -a AFTER restore" tmux list-windows -a

log "boot-trace-restore.sh done (exit $REAL_EXIT)"
log ""

exit $REAL_EXIT
