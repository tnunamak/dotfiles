#!/usr/bin/env bash
# Post-save hook: keep rotated backups of resurrect save files.
# Prevents continuum from silently overwriting a full save with an empty one.
# Keeps the largest save file as a "best" backup that's never overwritten
# by a smaller save.
set -euo pipefail

RESURRECT_DIR="${HOME}/.tmux/resurrect"
BACKUP_DIR="${RESURRECT_DIR}/backups"
BEST_FILE="${BACKUP_DIR}/best.txt"
MAX_BACKUPS=10

mkdir -p "$BACKUP_DIR"

# Find the current save file (what "last" points to)
current="$(readlink -f "${RESURRECT_DIR}/last" 2>/dev/null)" || exit 0
[[ -f "$current" ]] || exit 0

current_size=$(stat -c %s "$current" 2>/dev/null) || exit 0
current_name=$(basename "$current")

# Always keep a timestamped backup
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
