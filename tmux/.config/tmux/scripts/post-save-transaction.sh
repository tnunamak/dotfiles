#!/usr/bin/env bash
# Single post-save-layout transaction wrapper.
#
# tmux-resurrect calls post-save-layout with the exact layout path before it
# advances `last`, then later calls post-save-all without arguments. Keep the
# transaction here so layout acceptance and assistant sidecar acceptance belong
# to one save invocation.
set -euo pipefail

RESURRECT_DIR="${HOME}/.tmux/resurrect"
LOG="${RESURRECT_DIR}/post-save-transaction.log"
LAYOUT_GUARD="${HOME}/.config/tmux/scripts/post-save-backup.sh"
ASSISTANT_GUARD="${HOME}/.config/tmux/scripts/save-assistant-sessions-guarded.sh"
LOCK="${RESURRECT_DIR}/post-save-transaction.lock"

log() { printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >>"$LOG"; }

layout_save="${1:-}"
if [[ -z "$layout_save" || ! -f "$layout_save" ]]; then
  log "ERROR: missing layout save argument"
  exit 1
fi

mkdir -p "$RESURRECT_DIR"
exec 9>"$LOCK"
if ! flock -n 9; then
  log "skipping duplicate concurrent post-save transaction for $(basename "$layout_save")"
  exit 0
fi

status_file="$(mktemp "${RESURRECT_DIR}/.layout-accepted.XXXXXX")"
trap 'rm -f "$status_file"' EXIT

export TMUX_RESURRECT_LAYOUT_STATUS_FILE="$status_file"
"$LAYOUT_GUARD" "$layout_save"
layout_status="$(tr -d '[:space:]' <"$status_file" 2>/dev/null || true)"
unset TMUX_RESURRECT_LAYOUT_STATUS_FILE

if [[ "$layout_status" == "rejected" ]]; then
  log "layout rejected for $(basename "$layout_save"); running assistant save without bundle commit"
  TMUX_RESURRECT_SKIP_BUNDLE_COMMIT=1 "$ASSISTANT_GUARD" "$layout_save"
  exit 0
fi

if [[ "$layout_status" != "accepted" ]]; then
  log "ERROR: layout guard did not report accepted/rejected for $(basename "$layout_save")"
  exit 1
fi

"$ASSISTANT_GUARD" "$layout_save"
