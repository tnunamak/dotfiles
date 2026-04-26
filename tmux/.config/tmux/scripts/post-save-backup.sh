#!/usr/bin/env bash
# Post-save-layout hook for tmux-resurrect. Three responsibilities:
#
#   1. Keep a "best.txt" backup — never overwritten by a smaller save.
#   2. Keep rotated timestamped backups in backups/.
#   3. Cliff guard: if the JUST-WRITTEN save represents a massive session-count
#      drop from the previous `last` target, prevent it from becoming `last`
#      (by reverting the symlink AFTER save.sh updates it). Protects against
#      the post-crash pattern where tmux comes up empty and continuum's next
#      auto-save would otherwise bury the good save.
#
# IMPORTANT: tmux-resurrect fires this hook BEFORE updating the `last` symlink.
# At hook time, $1 is the path to the just-written save file, while
# $LAST_LINK still points at the PREVIOUS save (now "old"). save.sh updates
# the symlink to $1 immediately AFTER this hook returns. Therefore:
#   - "current" = $1 (the new save, which `last` is about to point at)
#   - "previous" = whatever $LAST_LINK points at right now
# Most of the original script confused these two, so the cliff guard was
# always one save behind. The new script consumes $1 explicitly.
#
# The guard only reverts on sudden cliffs (≥80% drop). Gradual session-count
# decline from closing windows is fine.
set -euo pipefail

RESURRECT_DIR="${HOME}/.tmux/resurrect"
BACKUP_DIR="${RESURRECT_DIR}/backups"
BEST_FILE="${BACKUP_DIR}/best.txt"
LAST_LINK="${RESURRECT_DIR}/last"
PREV_LAST_FILE="${RESURRECT_DIR}/.prev-last-target"
LOG="${RESURRECT_DIR}/post-save-backup.log"
MAX_BACKUPS=10
CLIFF_THRESHOLD_PCT=20    # new save must be ≥20% of previous to be accepted

log() { printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >>"$LOG"; }

# Rotate the log if it grows past 1 MiB
if [[ -f "$LOG" ]] && (( $(stat -c %s "$LOG" 2>/dev/null || echo 0) > 1048576 )); then
  mv "$LOG" "${LOG}.old"
fi

mkdir -p "$BACKUP_DIR"

count_panes() {
  local f="$1"
  [[ -f "$f" ]] || { echo 0; return; }
  grep -c '^pane' "$f" 2>/dev/null || echo 0
}

# --- Identify the new save (passed as $1 by tmux-resurrect's hook system) ---
new_save="${1:-}"
if [[ -z "$new_save" || ! -f "$new_save" ]]; then
  # Fallback: tmux-resurrect's `execute_hook` always passes the new path,
  # but be defensive in case a future plugin version changes the contract.
  # If the hook arg is missing, the best we can do is read what `last` will
  # become AFTER save.sh updates it — which we can approximate by finding the
  # newest tmux_resurrect_*.txt in the live dir.
  newest=$(find "$RESURRECT_DIR" -maxdepth 1 -name 'tmux_resurrect_*.txt' -printf '%T@\t%p\n' 2>/dev/null \
            | sort -rn 2>/dev/null \
            | head -1 \
            | cut -f2-)
  if [[ -n "$newest" && -f "$newest" ]]; then
    new_save="$newest"
    log "post-save-backup: hook arg missing, fell back to newest live save: $(basename "$new_save")"
  else
    log "post-save-backup: no save file to operate on (hook arg empty, no live saves found)"
    exit 0
  fi
fi

new_name=$(basename "$new_save")
new_size=$(stat -c %s "$new_save" 2>/dev/null) || { log "stat failed on $new_save"; exit 0; }
new_panes=$(count_panes "$new_save")

# --- Identify the previous save for cliff comparison ---
# Try in order: current `last` target → .prev-last-target file → backups copy → best.txt.
prev_save=""
prev_name=""
prev_panes=0
prev_resolved="$(readlink -f "$LAST_LINK" 2>/dev/null || true)"
if [[ -n "$prev_resolved" && -f "$prev_resolved" && "$(basename "$prev_resolved")" != "$new_name" ]]; then
  prev_save="$prev_resolved"
  prev_name=$(basename "$prev_save")
elif [[ -f "$PREV_LAST_FILE" ]]; then
  pn=$(<"$PREV_LAST_FILE")
  if [[ -n "$pn" && "$pn" != "$new_name" ]]; then
    if [[ -f "${RESURRECT_DIR}/${pn}" ]]; then
      prev_save="${RESURRECT_DIR}/${pn}"
      prev_name="$pn"
    elif [[ -f "${BACKUP_DIR}/${pn}" ]]; then
      prev_save="${BACKUP_DIR}/${pn}"
      prev_name="$pn"
    fi
  fi
fi
if [[ -z "$prev_save" && -f "$BEST_FILE" ]]; then
  prev_save="$BEST_FILE"
  prev_name="best.txt"
fi
[[ -n "$prev_save" ]] && prev_panes=$(count_panes "$prev_save")

# --- Cliff guard: did this save dramatically shrink? ---
revert=0
if (( prev_panes >= 3 )) && (( new_panes * 100 < prev_panes * CLIFF_THRESHOLD_PCT )); then
  revert=1
fi

if (( revert )); then
  # We need to prevent save.sh's upcoming `ln -fs $new_name $LAST_LINK` from
  # making the new (shrunken) save authoritative. We can't block it, but we
  # CAN scheduled a revert. The ordering of this hook (before symlink update)
  # makes that awkward — so what we do is:
  #
  #   1. Copy the previous save to backups/ NOW (in case it isn't already)
  #   2. Mark the new save as "rejected" by deleting it after backup, so
  #      save.sh's `files_differ` check on the next save still sees the old
  #      `last` target (the previous save).
  #
  # Wait — save.sh has ALREADY written $new_save by the time this hook fires.
  # Deleting it now would just leave save.sh updating `last` to a missing
  # file. That'd produce the EXACT bug we just fixed (dangling `last`).
  #
  # Better approach: copy the previous save over $new_save (preserving its
  # filename so save.sh's symlink update works) but with the previous save's
  # content. Then `last` ends up pointing at a file with the previous state's
  # content but the new file's name. Continuity preserved.
  log "CLIFF GUARD: new save $new_name has $new_panes panes vs prev $prev_name had $prev_panes — overwriting new save with previous content"
  cp "$prev_save" "$new_save"
  # Recompute (since $new_save now has prev's content)
  new_size=$(stat -c %s "$new_save" 2>/dev/null)
  new_panes=$prev_panes
fi

# --- Always: backup the (possibly cliff-guarded) new save into backups/ ---
cp "$new_save" "${BACKUP_DIR}/${new_name}"

# Update best.txt if this save is the largest we've seen
if [[ -f "$BEST_FILE" ]]; then
  best_size=$(stat -c %s "$BEST_FILE" 2>/dev/null) || best_size=0
  if (( new_size > best_size )); then
    cp "$new_save" "$BEST_FILE"
  fi
else
  cp "$new_save" "$BEST_FILE"
fi

# Record this save as the next run's "previous"
printf '%s' "$new_name" >"$PREV_LAST_FILE"

# Rotate: keep only the last MAX_BACKUPS timestamped backups
# (oldest beyond the limit are removed; best.txt and assistant-sessions-*.json
# are not affected since they don't match the pattern)
ls -t "${BACKUP_DIR}"/tmux_resurrect_*.txt 2>/dev/null | tail -n +$((MAX_BACKUPS + 1)) | xargs rm -f 2>/dev/null || true

log "post-save-backup: backed up $new_name (panes=$new_panes, prev=$prev_name with $prev_panes panes, cliff_guard=$revert)"
