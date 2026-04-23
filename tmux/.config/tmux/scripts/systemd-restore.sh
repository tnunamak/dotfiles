#!/usr/bin/env bash
# Boot-time tmux-resurrect restore, driven by systemd (not continuum).
# Runs once after tmux.service is up. Bypasses continuum's status-bar-gated
# auto-restore, which races against its own auto-save and against the first
# client attach (kitty). See CLAUDE.md for the debugging history.
#
# Invoked via tmux run-shell so $TMUX is set inside restore.sh — otherwise
# restore.sh's `tmux -S "$(tmux_socket)"` calls hit an empty socket path and
# silently create nothing.
set -euo pipefail

RESURRECT_DIR="${HOME}/.tmux/resurrect"
SENTINEL="${RESURRECT_DIR}/.restore-complete"
LOG="${RESURRECT_DIR}/systemd-restore.log"
RESTORE_SCRIPT="${HOME}/.tmux/plugins/tmux-resurrect/scripts/restore.sh"

log() { printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >>"$LOG"; }

rm -f "$SENTINEL"
: >"$LOG"
log "systemd-restore.sh invoked"

# Wait for tmux server to be ready (up to 10s). tmux.service is Type=forking,
# so by the time we run it should already be responsive, but be defensive.
for _ in $(seq 1 20); do
  if tmux list-sessions >/dev/null 2>&1; then break; fi
  sleep 0.5
done

if ! tmux list-sessions >/dev/null 2>&1; then
  log "ERROR: tmux server not responsive"
  exit 1
fi

if [ ! -x "$RESTORE_SCRIPT" ]; then
  log "ERROR: $RESTORE_SCRIPT not found/executable"
  exit 1
fi

if [ ! -f "$RESURRECT_DIR/last" ]; then
  log "no resurrect save to restore ($RESURRECT_DIR/last missing)"
  touch "$SENTINEL"
  exit 0
fi

log "running restore via tmux run-shell"
# run-shell sets $TMUX in the subshell so tmux_socket() returns the real
# socket path rather than an empty string.
tmux run-shell -b "bash '$RESTORE_SCRIPT' >>'$LOG' 2>&1; touch '$SENTINEL'"

# Wait for the sentinel (restore is async inside run-shell -b).
# Bounded at 30s; the largest restores we've seen take ~3s.
for _ in $(seq 1 60); do
  [ -f "$SENTINEL" ] && break
  sleep 0.5
done

if [ -f "$SENTINEL" ]; then
  log "restore complete; sentinel written"
else
  log "WARNING: sentinel not written after 30s"
  exit 1
fi
