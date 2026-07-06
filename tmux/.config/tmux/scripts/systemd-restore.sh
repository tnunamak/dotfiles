#!/usr/bin/env bash
# tmux-resurrect restore, driven by systemd (not continuum). Invoked by
# tmux-restore.service after every tmux.service start — including
# automatic recovery cycles. The script itself is state-aware: it only
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
STATUS="${RESURRECT_DIR}/.restore-status"
LOG="${RESURRECT_DIR}/systemd-restore.log"
RESTORE_SCRIPT="${HOME}/.tmux/plugins/tmux-resurrect/scripts/restore.sh"

log() { printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >>"$LOG"; }

# Rotate log at 1 MiB
if [[ -f "$LOG" ]] && (( $(stat -c %s "$LOG" 2>/dev/null || echo 0) > 1048576 )); then
  mv "$LOG" "${LOG}.old"
fi
rm -f "$SENTINEL" "$STATUS"

log "systemd-restore.sh invoked"
log "diag: RESURRECT_DIR=$RESURRECT_DIR RESTORE_SCRIPT=$RESTORE_SCRIPT"
log "diag: last symlink target=$(readlink "$RESURRECT_DIR/last" 2>/dev/null || echo '<none>')"
log "diag: last file exists=$([ -f "$RESURRECT_DIR/last" ] && echo yes || echo no)"

# Wait for tmux server to be ready (up to 10s). tmux.service is Type=forking,
# so by the time we run it should already be responsive, but be defensive.
log "diag: entering tmux wait loop"
for _ in $(seq 1 20); do
  if tmux list-sessions >/dev/null 2>&1; then break; fi
  sleep 0.5
done
log "diag: tmux wait loop done; server responsive=$(tmux list-sessions >/dev/null 2>&1 && echo yes || echo no)"

if ! tmux list-sessions >/dev/null 2>&1; then
  log "ERROR: tmux server not responsive; aborting"
  exit 1
fi

log "diag: tmux server is up"
if [ ! -x "$RESTORE_SCRIPT" ]; then
  log "ERROR: $RESTORE_SCRIPT not found/executable; aborting"
  exit 1
fi
log "diag: restore script found and executable"

if [ -L "$RESURRECT_DIR/last" ] && [ ! -f "$RESURRECT_DIR/last" ]; then
  # Hunt for the newest non-trivial save across both the live dir and backups/.
  # An unclean shutdown can leave the most recent save unsynced to disk while
  # the post-save-backup hook's copy in backups/ survives, so backups/ must be
  # part of the search. We pick the newest save with ≥3 panes — anything
  # smaller is likely the post-crash empty state we're trying to escape.
  #
  # Implementation note: pipefail + `awk ... exit` causes SIGPIPE on the
  # upstream `sort` and aborts the script under set -e, so we read the find
  # output into an array via mapfile and pick the best entry in pure bash.
  fallback_save=""
  fallback_panes=0
  while IFS=$'\t' read -r mtime path; do
    [ -z "$path" ] && continue
    panes=$(grep -c '^pane' "$path" 2>/dev/null || echo 0)
    if (( panes >= 3 )); then
      fallback_save="$path"
      fallback_panes=$panes
      break
    fi
  done < <(
    {
      find "$RESURRECT_DIR" -maxdepth 1 -type f -name 'tmux_resurrect_*.txt' -printf '%T@\t%p\n' 2>/dev/null
      find "$RESURRECT_DIR/backups" -maxdepth 1 -type f -name 'tmux_resurrect_*.txt' -printf '%T@\t%p\n' 2>/dev/null
    } | sort -rn 2>/dev/null
  )

  if [ -z "$fallback_save" ] && [ -f "$RESURRECT_DIR/backups/best.txt" ]; then
    fallback_save="$RESURRECT_DIR/backups/best.txt"
    fallback_panes=$(grep -c '^pane' "$fallback_save" 2>/dev/null || echo 0)
  fi

  if [ -n "$fallback_save" ]; then
    # Copy into the live dir so cliff guard's `${RESURRECT_DIR}/${prev_name}`
    # check finds the file on the next continuum save. Symlink at a path
    # outside RESURRECT_DIR breaks that lookup.
    fallback_name="$(basename "$fallback_save")"
    if [ "$(dirname "$fallback_save")" != "$RESURRECT_DIR" ]; then
      cp "$fallback_save" "$RESURRECT_DIR/$fallback_name"
    fi
    ln -sfn "$fallback_name" "$RESURRECT_DIR/last"
    log "last symlink was dangling; repointed to fallback save $fallback_name ($fallback_panes panes)"
  else
    log "last symlink was dangling and no usable fallback save exists; nothing to do"
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
# Count panes defensively: command substitution can produce "0\n0" when the
# inner command both prints "0" AND falls through to `|| echo 0` (e.g. grep -c
# on a dangling readlink target). Multiline values then break `(( var <= 1 ))`
# with "syntax error in expression". Pipe through head -1 + a fallback echo.
live_panes=$(tmux list-panes -a 2>/dev/null | wc -l 2>/dev/null | head -1)
[[ -z "$live_panes" ]] && live_panes=0
save_target="$(readlink -f "$RESURRECT_DIR/last" 2>/dev/null || true)"
if [[ -n "$save_target" && -f "$save_target" ]]; then
  save_panes=$(grep -c '^pane' "$save_target" 2>/dev/null | head -1)
else
  save_panes=0
fi
[[ -z "$save_panes" ]] && save_panes=0
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
tmux run-shell -b "bash '$RESTORE_SCRIPT' >>'$LOG' 2>&1; rc=\$?; printf '%s\n' \"\$rc\" >'$STATUS'; [ \"\$rc\" -eq 0 ] && touch '$SENTINEL'"

# Bounded wait for restore to finish (sentinel touched at end of run-shell).
for _ in $(seq 1 1200); do
  [ -f "$SENTINEL" ] && break
  [ -f "$STATUS" ] && break
  sleep 0.5
done

if [ -f "$SENTINEL" ]; then
  log "restore complete; sentinel written"
  exit 0
elif [ -f "$STATUS" ]; then
  restore_rc="$(tr -d '[:space:]' < "$STATUS" 2>/dev/null || echo 1)"
  [[ "$restore_rc" =~ ^[0-9]+$ ]] || restore_rc=1
  log "ERROR: restore exited rc=$restore_rc"
  exit "$restore_rc"
else
  log "WARNING: restore still running after 600s"
  exit 1
fi
