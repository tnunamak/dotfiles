#!/usr/bin/env bash
# tmux-resurrect restore, driven by systemd (not continuum). Invoked by
# tmux-restore.service after every tmux.service start — including
# Restart=on-failure cycles. The script itself is state-aware: it only
# restores when tmux is fresh-empty, so re-invocations after a legitimate
# resume (or during manual tmux restarts with live work) are no-ops.
#
# Skipping logic compares current tmux pane count against the pane count
# recorded in the resurrect save. If they already match roughly, the
# restore is redundant and is skipped.
#
# Invoked via `tmux run-shell` so $TMUX is set inside restore.sh — otherwise
# restore.sh's `tmux -S "$(tmux_socket)"` calls hit an empty socket path and
# silently create nothing.
set -euo pipefail

RESURRECT_DIR="${HOME}/.tmux/resurrect"
SENTINEL="${RESURRECT_DIR}/.restore-complete"
LOG="${RESURRECT_DIR}/systemd-restore.log"
RESTORE_SCRIPT="${HOME}/.tmux/plugins/tmux-resurrect/scripts/restore.sh"

log() { printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >>"$LOG"; }

# Rotate log at 1 MiB
if [[ -f "$LOG" ]] && (( $(stat -c %s "$LOG" 2>/dev/null || echo 0) > 1048576 )); then
  mv "$LOG" "${LOG}.old"
fi
rm -f "$SENTINEL"

log "systemd-restore.sh invoked"

# Wait for tmux server to be ready (up to 10s). tmux.service is Type=forking,
# so by the time we run it should already be responsive, but be defensive.
for _ in $(seq 1 20); do
  if tmux list-sessions >/dev/null 2>&1; then break; fi
  sleep 0.5
done

if ! tmux list-sessions >/dev/null 2>&1; then
  log "ERROR: tmux server not responsive; aborting"
  exit 1
fi

if [ ! -x "$RESTORE_SCRIPT" ]; then
  log "ERROR: $RESTORE_SCRIPT not found/executable; aborting"
  exit 1
fi

if [ -L "$RESURRECT_DIR/last" ] && [ ! -f "$RESURRECT_DIR/last" ]; then
  fallback_save=$(
    find "$RESURRECT_DIR" -maxdepth 1 -type f -name 'tmux_resurrect_*.txt' -printf '%T@ %p\n' 2>/dev/null |
      sort -nr |
      awk 'NR == 1 { sub(/^[^ ]+ /, ""); print; exit }'
  )

  if [ -z "$fallback_save" ] && [ -f "$RESURRECT_DIR/backups/best.txt" ]; then
    fallback_save="$RESURRECT_DIR/backups/best.txt"
  fi

  if [ -n "$fallback_save" ]; then
    ln -sf "$fallback_save" "$RESURRECT_DIR/last"
    log "last symlink was dangling; repointed to fallback save $fallback_save"
  else
    log "last symlink was dangling and no fallback save exists; nothing to do"
    exit 0
  fi
fi

if [ ! -f "$RESURRECT_DIR/last" ]; then
  log "no resurrect save to restore ($RESURRECT_DIR/last missing); nothing to do"
  exit 0
fi

# State-aware gate: only restore if tmux looks fresh-empty. "Fresh-empty"
# means the total live pane count across all sessions is ≤ 2 (systemd's
# default `new-session -d` plus at most one attached kitty session).
live_panes=$(tmux list-panes -a 2>/dev/null | wc -l || echo 0)
save_panes=$(grep -c '^pane' "$(readlink -f "$RESURRECT_DIR/last")" 2>/dev/null || echo 0)
log "state: live_panes=$live_panes save_panes=$save_panes"

if (( live_panes > 2 )); then
  log "tmux already has $live_panes panes — skipping restore to preserve live state"
  exit 0
fi

if (( save_panes <= 1 )); then
  log "save has only $save_panes panes — nothing worth restoring"
  exit 0
fi

log "running restore via tmux run-shell"
tmux run-shell -b "bash '$RESTORE_SCRIPT' >>'$LOG' 2>&1; touch '$SENTINEL'"

# Bounded wait for restore to finish (sentinel touched at end of run-shell).
for _ in $(seq 1 60); do
  [ -f "$SENTINEL" ] && break
  sleep 0.5
done

if [ -f "$SENTINEL" ]; then
  log "restore complete; sentinel written"
  exit 0
else
  log "WARNING: sentinel not written after 30s"
  exit 1
fi
