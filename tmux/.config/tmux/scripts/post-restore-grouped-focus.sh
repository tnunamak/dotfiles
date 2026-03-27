#!/usr/bin/env bash
# Post-restore hook: fix grouped session window focus.
# tmux-resurrect uses switch-client to restore active windows for grouped
# sessions, but that fails during headless (no-client) restore. This script
# uses select-window instead, which works without any attached client.
# After fixing focus, it invokes tmux-assistant-resurrect's restore script.
set -euo pipefail

RESURRECT_DIR="${HOME}/.tmux/resurrect"
RESURRECT_FILE="${RESURRECT_DIR}/last"

if [[ -f "$RESURRECT_FILE" ]]; then
  while IFS=$'\t' read -r line_type session_name original_session alt_window active_window _rest; do
    [[ "$line_type" == "grouped_session" ]] || continue

    # Strip the leading ':' prefix from window indices
    alt_window="${alt_window#:}"
    active_window="${active_window#:}"

    # Skip if session wasn't actually restored
    tmux has-session -t "=$session_name" 2>/dev/null || continue

    # Set alternate window first (if present), then active window
    # This mimics the switch-client ordering in resurrect's restore
    if [[ -n "$alt_window" ]]; then
      tmux select-window -t "=${session_name}:${alt_window}" 2>/dev/null || true
    fi
    if [[ -n "$active_window" ]]; then
      tmux select-window -t "=${session_name}:${active_window}" 2>/dev/null || true
    fi
  done < "$(readlink -f "$RESURRECT_FILE")"
fi

# Chain to tmux-assistant-resurrect's restore script
ASSISTANT_RESTORE="${HOME}/.tmux/plugins/tmux-assistant-resurrect/scripts/restore-assistant-sessions.sh"
if [[ -f "$ASSISTANT_RESTORE" ]]; then
  bash "$ASSISTANT_RESTORE"
fi
