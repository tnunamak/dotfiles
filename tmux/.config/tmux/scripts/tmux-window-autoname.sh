#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-tmux-agent-windows.sh
source "$SCRIPT_DIR/lib-tmux-agent-windows.sh"

state_dir="$(tmux_agent_state_dir)"
mkdir -p -m 0700 "$state_dir"
lock="$state_dir/.autoname.lock"
exec 9>"$lock"
flock -n 9 || exit 0

targets=()
if [ -n "${TMUX_WINDOW_AUTONAME_TARGETS:-}" ]; then
	for target in $TMUX_WINDOW_AUTONAME_TARGETS; do
		if [[ "$target" == *:* ]]; then
			targets+=("$target")
		else
			while IFS= read -r index; do
				targets+=("$target:$index")
			done < <(tmux list-windows -t "$target" -F '#{window_index}' 2>/dev/null || true)
		fi
	done
elif tmux has-session -t main 2>/dev/null; then
	while IFS= read -r index; do
		targets+=("main:$index")
	done < <(tmux list-windows -t main -F '#{window_index}' 2>/dev/null || true)
fi

for target in "${targets[@]}"; do
	window_name="$(tmux display-message -p -t "$target" '#{window_name}' 2>/dev/null || true)"
	[ -n "$window_name" ] || continue
	[[ "$window_name" == =* ]] && continue

	info="$(tmux_agent_resolved_window "$target")"
	label="$(jq -r '.label // empty' <<<"$info")"
	glyph="$(jq -r '.glyph // empty' <<<"$info")"
	[ -n "$label" ] || continue

	new_name="${glyph}${label}"
	if [ "$window_name" != "$new_name" ]; then
		tmux set-window-option -q -t "$target" automatic-rename off
		tmux rename-window -t "$target" "$new_name"
	else
		tmux set-window-option -q -t "$target" automatic-rename off
	fi
done
