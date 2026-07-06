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

count_save_panes() {
  local save_file="$1"
  local panes
  panes=$(grep -c '^pane' "$save_file" 2>/dev/null || true)
  panes="${panes%%$'\n'*}"
  [[ "$panes" =~ ^[0-9]+$ ]] || panes=0
  printf '%s\n' "$panes"
}

find_fallback_save() {
  local mtime path panes
  while IFS=$'\t' read -r mtime path; do
    [ -z "$path" ] && continue
    panes=$(count_save_panes "$path")
    if (( panes >= 3 )); then
      printf '%s\t%s\n' "$path" "$panes"
      return 0
    fi
  done < <(
    {
      find "$RESURRECT_DIR" -maxdepth 1 -type f -name 'tmux_resurrect_*.txt' -printf '%T@\t%p\n' 2>/dev/null
      find "$RESURRECT_DIR/backups" -maxdepth 1 -type f -name 'tmux_resurrect_*.txt' -printf '%T@\t%p\n' 2>/dev/null
    } | sort -rn 2>/dev/null
  )

  if [ -f "$RESURRECT_DIR/backups/best.txt" ]; then
    panes=$(count_save_panes "$RESURRECT_DIR/backups/best.txt")
    if (( panes >= 3 )); then
      printf '%s\t%s\n' "$RESURRECT_DIR/backups/best.txt" "$panes"
      return 0
    fi
  fi

  return 1
}

repoint_last_to_fallback() {
  local reason="$1"
  local fallback_save fallback_panes fallback_name
  local fallback_info

  fallback_info="$(find_fallback_save || true)"
  if [ -z "$fallback_info" ]; then
    log "$reason and no usable fallback save exists; nothing to do"
    return 1
  fi

  IFS=$'\t' read -r fallback_save fallback_panes <<<"$fallback_info"
  fallback_name="$(basename "$fallback_save")"
  if [ "$(dirname "$fallback_save")" != "$RESURRECT_DIR" ]; then
    cp "$fallback_save" "$RESURRECT_DIR/$fallback_name"
  fi
  ln -sfn "$fallback_name" "$RESURRECT_DIR/last"
  log "$reason; repointed to fallback save $fallback_name ($fallback_panes panes)"
  return 0
}

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
  # part of the search. We pick the newest save with >=3 panes; anything
  # smaller is likely the post-crash empty state we're trying to escape.
  if ! repoint_last_to_fallback "last symlink was dangling"; then
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
# Count panes defensively: pane counters must stay numeric even when grep finds
# no pane lines or a target disappears under us.
live_panes=$(tmux list-panes -a 2>/dev/null | wc -l 2>/dev/null | head -1)
[[ -z "$live_panes" ]] && live_panes=0
save_target="$(readlink -f "$RESURRECT_DIR/last" 2>/dev/null || true)"
if [[ -n "$save_target" && -f "$save_target" ]]; then
  save_panes=$(count_save_panes "$save_target")
else
  save_panes=0
fi
[[ -z "$save_panes" ]] && save_panes=0
log "state: live_panes=$live_panes save_panes=$save_panes"

if (( live_panes > 2 )); then
  log "tmux already has $live_panes panes — skipping restore to preserve live state"
  exit 0
fi

if (( save_panes < 3 )); then
  if repoint_last_to_fallback "last save had only $save_panes panes"; then
    save_target="$(readlink -f "$RESURRECT_DIR/last" 2>/dev/null || true)"
    if [[ -n "$save_target" && -f "$save_target" ]]; then
      save_panes=$(count_save_panes "$save_target")
    else
      save_panes=0
    fi
    log "state after fallback: save_panes=$save_panes"
  fi
fi

if (( save_panes < 3 )); then
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
