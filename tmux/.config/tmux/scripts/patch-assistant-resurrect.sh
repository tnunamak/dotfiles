#!/usr/bin/env bash
# Idempotent patcher for tmux-assistant-resurrect.
# Re-applies two patches that the upstream plugin doesn't yet have, so they
# survive TPM auto-updates that wipe the file.
#
# Run from:
#   - setup.sh (initial machine setup)
#   - tmux-restore.service ExecStartPre (every boot, before any save fires)
#
# Exits 0 on success or no-op. Logs to ~/.tmux/resurrect/patch-assistant-resurrect.log
# so the next save+log audit shows whether patches were re-applied.
set -euo pipefail

ASSISTANT_SAVE="$HOME/.tmux/plugins/tmux-assistant-resurrect/scripts/save-assistant-sessions.sh"
LOG="$HOME/.tmux/resurrect/patch-assistant-resurrect.log"

log() {
  mkdir -p "$(dirname "$LOG")"
  printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >>"$LOG"
}

if [[ ! -f "$ASSISTANT_SAVE" ]]; then
  # Plugin not installed yet (first-boot, fresh setup). Nothing to patch.
  log "no plugin file at $ASSISTANT_SAVE — skipping (first run before TPM)"
  exit 0
fi

# Rotate log at 256 KiB (this script is short, log shouldn't grow much)
if [[ -f "$LOG" ]] && (( $(stat -c %s "$LOG" 2>/dev/null || echo 0) > 262144 )); then
  mv "$LOG" "${LOG}.old"
fi

applied=0

# Patch 1: bare-trailing --resume regex
# Upstream's `'s/--resume[= ] *[^ ]*//'` requires `=` or space after --resume,
# so a bare trailing `--resume` is left in place and re-issued at restore time,
# which Bun crashes on. Fix accepts both `--resume <id>` and `--resume=<id>`.
if grep -qF "'s/--resume[= ] *[^ ]*//'" "$ASSISTANT_SAVE"; then
  sed -i "s|'s/--resume\[= \] \*\[^ \]\*//'|'s/--resume(=[^ ]*)?( +[^ -][^ ]*)?//'|" "$ASSISTANT_SAVE"
  log "applied patch 1: bare-trailing --resume regex"
  applied=$((applied + 1))
fi

# Patch 2: canonicalize grouped session names at save time
# Upstream saves pane addresses under the most recent grouped session
# (e.g., main-0:N.0). At restore time only the canonical 'main' exists, so
# the addresses don't resolve and 'restored 0 of N assistant sessions' is
# logged. Fix resolves #{session_group} and uses the base name when
# non-empty.
if ! grep -qF 'session_group=$(tmux display-message -t "$session_name"' "$ASSISTANT_SAVE" &&
   grep -qF 'tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index}|#{pane_pid}|#{pane_current_path}" >"$PANE_FILE"' "$ASSISTANT_SAVE"; then
  sed -i '/tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index}|#{pane_pid}|#{pane_current_path}" >"$PANE_FILE"/c\
	>"$PANE_FILE"\
	while IFS='\''|'\'' read -r session_name window_index pane_index pane_pid pane_cwd; do\
		session_group=$(tmux display-message -t "$session_name" -p '\''#{session_group}'\'' 2>/dev/null || true)\
		if [ -n "$session_group" ]; then\
			session_name="$session_group"\
		fi\
		printf '\''%s:%s.%s|%s|%s\\n'\'' "$session_name" "$window_index" "$pane_index" "$pane_pid" "$pane_cwd" >>"$PANE_FILE"\
	done < <(tmux list-panes -a -F "#{session_name}|#{window_index}|#{pane_index}|#{pane_pid}|#{pane_current_path}")' "$ASSISTANT_SAVE"
  log "applied patch 2: canonicalize grouped session pane addresses"
  applied=$((applied + 1))
fi

if (( applied == 0 )); then
  # Nothing to do; both patches already in place. Don't spam the log.
  exit 0
fi

log "patches applied this run: $applied"
