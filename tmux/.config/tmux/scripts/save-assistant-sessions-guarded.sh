#!/usr/bin/env bash
# Wraps tmux-assistant-resurrect's save script with two safety guards:
#
# 1. Never-shrink: if the new save has 0 sessions but the previous save had
#    >0, refuse to overwrite. This defends against the post-crash scenario
#    where all assistant processes are gone and the save would wipe the
#    record of what was running.
#
# 2. Rotate a sidecar backup alongside each tmux-resurrect save — so if a
#    bad save slips through (e.g. a legit "no assistants running" moment
#    that's not a crash), we can still recover from the backup dir.
#
# Invoked via @resurrect-hook-post-save-all (overrides the upstream plugin's
# setting of that same hook). Chains to the upstream save script.
set -euo pipefail

RESURRECT_DIR="${HOME}/.tmux/resurrect"
OUTPUT_FILE="${RESURRECT_DIR}/assistant-sessions.json"
BACKUP_DIR="${RESURRECT_DIR}/backups"
LOG_FILE="${RESURRECT_DIR}/assistant-save.log"
UPSTREAM_SCRIPT="${HOME}/.tmux/plugins/tmux-assistant-resurrect/scripts/save-assistant-sessions.sh"

log() {
  local msg="[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [guard] $*"
  echo "$msg" >>"$LOG_FILE"
}

# Snapshot count before upstream runs
old_count=0
if [[ -f "$OUTPUT_FILE" ]]; then
  old_count=$(jq -r '.sessions | length' "$OUTPUT_FILE" 2>/dev/null || echo 0)
fi

# Stage the upstream save to a temp file so we can inspect before committing
staged=$(mktemp "${OUTPUT_FILE}.new.XXXXXX")
trap 'rm -f "$staged"' EXIT

# Temporarily redirect the upstream script's output. The upstream script
# hardcodes OUTPUT_FILE="${RESURRECT_DIR}/assistant-sessions.json". We shim
# it by copying the real file aside, letting upstream write to the real
# path, then comparing and moving.
#
# Simpler approach: let upstream write in place, then check. If the check
# fails, restore from a pre-run snapshot.
snapshot=$(mktemp "${OUTPUT_FILE}.snap.XXXXXX")
if [[ -f "$OUTPUT_FILE" ]]; then
  cp "$OUTPUT_FILE" "$snapshot"
fi

rc=0
"$UPSTREAM_SCRIPT" || rc=$?

new_count=0
if [[ -f "$OUTPUT_FILE" ]]; then
  new_count=$(jq -r '.sessions | length' "$OUTPUT_FILE" 2>/dev/null || echo 0)
fi

# Guard: refuse to overwrite >0 with 0. This is the dominant failure mode:
# after a crash/reboot, assistant processes are gone, tmux-resurrect saves
# the broken state, and the sidecar JSON gets overwritten with []. The
# post-save-backup.sh layer handles the tmux save; we do the same for JSON.
if (( old_count > 0 && new_count == 0 )); then
  log "REFUSING shrink from $old_count to 0 sessions — restoring snapshot"
  if [[ -s "$snapshot" ]]; then
    mv "$snapshot" "$OUTPUT_FILE"
  fi
else
  rm -f "$snapshot"
fi

# Rotate a timestamped sidecar backup next to tmux-resurrect backups. Only
# back up non-empty saves so we don't waste inodes on zero-session writes.
if (( new_count > 0 )) || (( old_count > 0 && new_count == 0 )); then
  mkdir -p "$BACKUP_DIR"
  # Name matches the tmux save that triggered this hook, when we can find it
  last_save="$(readlink -f "${RESURRECT_DIR}/last" 2>/dev/null || true)"
  if [[ -n "$last_save" && -f "$last_save" ]]; then
    ts="$(basename "$last_save" .txt | sed 's/^tmux_resurrect_//')"
    cp "$OUTPUT_FILE" "${BACKUP_DIR}/assistant-sessions-${ts}.json"
  fi

  # Keep the largest as "best"
  best="${BACKUP_DIR}/assistant-sessions-best.json"
  if [[ -f "$best" ]]; then
    best_count=$(jq -r '.sessions | length' "$best" 2>/dev/null || echo 0)
    if (( new_count > best_count )); then
      cp "$OUTPUT_FILE" "$best"
    fi
  else
    cp "$OUTPUT_FILE" "$best"
  fi

  # Keep only the last 10 timestamped backups
  ls -t "${BACKUP_DIR}"/assistant-sessions-2*.json 2>/dev/null | tail -n +11 | xargs -r rm -f
fi

exit "$rc"
