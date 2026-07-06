#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-tmux-agent-windows.sh
source "$SCRIPT_DIR/lib-tmux-agent-windows.sh"

if [ "${1:-}" != "--inside" ]; then
	session="$(tmux display-message -p '#{client_session}')"
	tmux display-popup -E -w 92% -h 80% -T "windows" \
		"TMUX_WINDOW_PICKER_SESSION=$(printf '%q' "$session") $(printf '%q' "$0") --inside"
	exit 0
fi

session="${TMUX_WINDOW_PICKER_SESSION:-$(tmux display-message -p '#{client_session}')}"
command -v fzf >/dev/null 2>&1 || {
	printf 'fzf is required on PATH\n' >&2
	exit 1
}

rows="$(
	while IFS= read -r index; do
		target="$session:$index"
		info="$(tmux_agent_resolved_window "$target")"
		state_rank="$(jq -r '.state_rank' <<<"$info")"
		activity="$(jq -r '.activity' <<<"$info")"
		glyph="$(jq -r '.glyph' <<<"$info")"
		label="$(jq -r '.label' <<<"$info")"
		cwd_tail="$(jq -r '.cwd_tail' <<<"$info")"
		age="$(jq -r '.age' <<<"$info")"
		printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
			"$state_rank" "-$activity" "$index" "$glyph" "$index" "$label" "$cwd_tail" "$age"
	done < <(tmux list-windows -t "$session" -F '#{window_index}' 2>/dev/null || true) |
		sort -n -k1,1 -k2,2 |
		cut -f3-
)"

[ -n "$rows" ] || exit 0

if [ "${TMUX_WINDOW_PICKER_PRINT_ROWS:-}" = "1" ]; then
	printf '%s\n' "$rows"
	exit 0
fi

if [ -n "${TMUX_WINDOW_PICKER_ACCEPT_INDEX:-}" ]; then
	tmux select-window -t "$session:$TMUX_WINDOW_PICKER_ACCEPT_INDEX"
	exit 0
fi

selection="$(
	printf '%s\n' "$rows" |
		fzf --ansi --delimiter=$'\t' --with-nth=2.. \
			--prompt='window> ' --height=100% --layout=reverse --border=none
)"

[ -n "$selection" ] || exit 0
index="${selection%%$'\t'*}"
tmux select-window -t "$session:$index"
