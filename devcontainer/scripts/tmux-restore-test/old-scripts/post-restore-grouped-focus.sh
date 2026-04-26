#!/usr/bin/env bash
# Post-restore hook:
# 1. Fix grouped-session focus headlessly with select-window.
# 2. Convert restored grouped sessions into a short-lived queue of window
#    indices for tmux-local-attach-main to consume.
# 3. Kill the detached restored grouped sessions so the attach script never
#    races on them (it always creates fresh sessions instead).
# 4. Chain to tmux-assistant-resurrect's restore hook.
set -euo pipefail

RESURRECT_DIR="${HOME}/.tmux/resurrect"
RESURRECT_FILE="${RESURRECT_DIR}/last"

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/tmux-grouped-sessions"
RESTORE_QUEUE_FILE="${STATE_DIR}/main.restore-queue"
RESTORE_STAMP_FILE="${STATE_DIR}/main.restore-stamp"

ASSISTANT_RESTORE="${HOME}/.tmux/plugins/tmux-assistant-resurrect/scripts/restore-assistant-sessions.sh"

mkdir -p "$STATE_DIR"

queue_tmp="${RESTORE_QUEUE_FILE}.tmp.$$"
stamp_tmp="${RESTORE_STAMP_FILE}.tmp.$$"
trap 'rm -f "$queue_tmp" "$stamp_tmp"' EXIT

: > "$queue_tmp"

restored_sessions=()

if [[ -f "$RESURRECT_FILE" ]]; then
  while IFS=$'\t' read -r line_type session_name original_session alt_window active_window _rest; do
    [[ "$line_type" == "grouped_session" ]] || continue
    [[ "$original_session" == "main" ]] || continue

    # Skip entries that tmux-resurrect did not actually recreate
    tmux has-session -t "=$session_name" 2>/dev/null || continue

    restored_sessions+=("$session_name")

    alt_window="${alt_window#:}"
    active_window="${active_window#:}"

    # Set focus using select-window (works headlessly, unlike switch-client)
    if [[ -n "$alt_window" ]]; then
      tmux select-window -t "=${session_name}:${alt_window}" >/dev/null 2>&1 || true
    fi
    if [[ -n "$active_window" ]]; then
      tmux select-window -t "=${session_name}:${active_window}" >/dev/null 2>&1 || true
    fi

    # Record the target window index for the queue
    # Use active_window from the save file directly (don't use display-message
    # which requires a client context to work)
    target_window="${active_window:-$alt_window}"
    if [[ "$target_window" =~ ^[0-9]+$ ]]; then
      printf '%s\n' "$target_window" >> "$queue_tmp"
    fi
  done < "$RESURRECT_FILE"
fi

# Write the queue and timestamp atomically
if [[ -s "$queue_tmp" ]]; then
  printf '%s\n' "$(date +%s)" > "$stamp_tmp"
  mv "$queue_tmp" "$RESTORE_QUEUE_FILE"
  mv "$stamp_tmp" "$RESTORE_STAMP_FILE"
else
  rm -f "$queue_tmp" "$stamp_tmp" "$RESTORE_QUEUE_FILE" "$RESTORE_STAMP_FILE"
fi

# Kill the restored grouped sessions — the attach script creates fresh ones
for session_name in "${restored_sessions[@]}"; do
  tmux kill-session -t "=$session_name" >/dev/null 2>&1 || true
done

# Chain to tmux-assistant-resurrect
if [[ -f "$ASSISTANT_RESTORE" ]]; then
  bash "$ASSISTANT_RESTORE"
fi
