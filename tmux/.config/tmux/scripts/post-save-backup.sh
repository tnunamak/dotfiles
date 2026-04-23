#!/usr/bin/env bash
# Post-save hook. Three responsibilities:
#
#   1. Keep a "best.txt" backup — never overwritten by a smaller save.
#   2. Keep rotated timestamped backups in backups/.
#   3. Cliff guard: if this save represents a massive session-count drop
#      from the previous `last` target, repoint `last` back to the
#      previous target. Protects against the post-crash pattern where
#      tmux comes up empty and continuum's next auto-save overwrites
#      the `last` pointer with the empty state, stranding the good save.
#
# The guard only reverts on sudden cliffs (≥80% drop between adjacent
# saves). Gradual session-count decline from closing windows is fine.
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

# Count panes (session-count proxy) in a save file. 0 on missing/unreadable.
count_panes() {
  local f="$1"
  [[ -f "$f" ]] || { echo 0; return; }
  grep -c '^pane' "$f" 2>/dev/null || echo 0
}

current="$(readlink -f "$LAST_LINK" 2>/dev/null)" || exit 0
[[ -f "$current" ]] || exit 0

current_name=$(basename "$current")
current_size=$(stat -c %s "$current" 2>/dev/null) || exit 0
current_panes=$(count_panes "$current")

# --- Cliff guard: detect and revert post-crash empty overwrites ---
if [[ -f "$PREV_LAST_FILE" ]]; then
  prev_name=$(<"$PREV_LAST_FILE")
  prev_path="${RESURRECT_DIR}/${prev_name}"
  if [[ -n "$prev_name" && "$prev_name" != "$current_name" && -f "$prev_path" ]]; then
    prev_panes=$(count_panes "$prev_path")
    # Only guard if previous had meaningful state (≥3 panes) AND current is
    # dramatically smaller. Arithmetic: current * 100 < prev * THRESHOLD.
    if (( prev_panes >= 3 )) && (( current_panes * 100 < prev_panes * CLIFF_THRESHOLD_PCT )); then
      log "CLIFF GUARD: $current_name has $current_panes panes vs $prev_name had $prev_panes — reverting 'last' symlink"
      ln -sfn "$prev_name" "$LAST_LINK"
      # Re-read current so downstream backup logic still runs against the kept save.
      current="$prev_path"
      current_name="$prev_name"
      current_size=$(stat -c %s "$current" 2>/dev/null) || exit 0
      current_panes=$prev_panes
    fi
  fi
fi

# Remember this target for the next save's cliff check
printf '%s' "$current_name" >"$PREV_LAST_FILE"

# Always keep a timestamped backup of whatever `last` ultimately points at
cp "$current" "${BACKUP_DIR}/${current_name}"

# Keep the largest save as "best" — never overwrite with something smaller
if [[ -f "$BEST_FILE" ]]; then
  best_size=$(stat -c %s "$BEST_FILE" 2>/dev/null) || best_size=0
  if (( current_size > best_size )); then
    cp "$current" "$BEST_FILE"
  fi
else
  cp "$current" "$BEST_FILE"
fi

# Rotate: keep only the last MAX_BACKUPS timestamped backups
ls -t "${BACKUP_DIR}"/tmux_resurrect_*.txt 2>/dev/null | tail -n +$((MAX_BACKUPS + 1)) | xargs rm -f 2>/dev/null || true
