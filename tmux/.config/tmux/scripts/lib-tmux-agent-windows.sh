#!/usr/bin/env bash

tmux_agent_state_dir() {
	printf '%s\n' "${TMUX_TASK_LABEL_DIR:-$HOME/.local/state/tmux-task-labels}"
}

tmux_agent_label_limit() {
	printf '%s\n' "${TMUX_TASK_LABEL_LIMIT:-48}"
}

tmux_agent_trim() {
	printf '%s' "$1" | tr '\n\r\t' '   ' | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//'
}

tmux_agent_compact_label() {
	local label limit
	label="$(tmux_agent_trim "$1")"
	limit="$(tmux_agent_label_limit)"
	if ((${#label} > limit)); then
		label="${label:0:limit}"
		label="$(tmux_agent_trim "$label")"
	fi
	printf '%s\n' "$label"
}

tmux_agent_basename() {
	local path="${1:-}"
	if [ -z "$path" ]; then
		printf '%s\n' "?"
	else
		basename "$path"
	fi
}

tmux_agent_cwd_tail() {
	local path="${1:-}"
	if [ -z "$path" ]; then
		printf '%s\n' "?"
		return
	fi
	if [ "$path" = "$HOME" ]; then
		printf '%s\n' "~"
		return
	fi
	path="${path/#$HOME\//~/}"
	local parent base
	parent="$(basename "$(dirname "$path")")"
	base="$(basename "$path")"
	if [ "$parent" = "." ] || [ "$parent" = "/" ] || [ "$parent" = "~" ]; then
		printf '%s\n' "$base"
	else
		printf '%s/%s\n' "$parent" "$base"
	fi
}

tmux_agent_age_text() {
	local now then age
	now="$(date +%s)"
	then="${1:-0}"
	age=$((now - then))
	if ((age < 0)); then age=0; fi
	if ((age < 60)); then
		printf '%ss\n' "$age"
	elif ((age < 3600)); then
		printf '%sm\n' "$((age / 60))"
	elif ((age < 86400)); then
		printf '%sh\n' "$((age / 3600))"
	else
		printf '%sd\n' "$((age / 86400))"
	fi
}

tmux_agent_state_glyph() {
	case "${1:-}" in
		working) printf '●' ;;
		needs-input) printf '◐' ;;
		idle) printf '○' ;;
		*) printf '' ;;
	esac
}

tmux_agent_state_rank() {
	case "${1:-}" in
		needs-input) printf '0' ;;
		working) printf '1' ;;
		idle) printf '2' ;;
		*) printf '3' ;;
	esac
}

tmux_agent_sidecar_for_pane() {
	local pane="$1" state_dir
	state_dir="$(tmux_agent_state_dir)"
	if [ ! -d "$state_dir" ]; then
		printf '{}\n'
		return
	fi

	shopt -s nullglob
	local files=("$state_dir"/*.json)
	shopt -u nullglob
	if ((${#files[@]} == 0)); then
		printf '{}\n'
		return
	fi

	jq -s --arg pane "$pane" \
		'[.[] | select((.tmux_pane // "") == $pane)] | sort_by(.ts // 0) | last // {}' \
		"${files[@]}" 2>/dev/null || printf '{}\n'
}

tmux_agent_is_default_title() {
	local title="$1" command="${2:-}" host short
	title="$(tmux_agent_trim "$title")"
	host="$(hostname 2>/dev/null || true)"
	short="$(hostname -s 2>/dev/null || true)"
	[ -z "$title" ] && return 0
	[ -n "$host" ] && [ "$title" = "$host" ] && return 0
	[ -n "$short" ] && [ "$title" = "$short" ] && return 0
	[ -n "$command" ] && [ "$title" = "$command" ] && return 0
	return 1
}

tmux_agent_window_fields() {
	local target="$1"
	tmux display-message -p -t "$target" \
		'#{pane_id}	#{pane_current_command}	#{pane_current_path}	#{pane_title}	#{window_name}	#{window_activity}	#{window_index}'
}

tmux_agent_resolved_window() {
	local target="$1"
	local pane command cwd pane_title window_name activity index
	IFS=$'\t' read -r pane command cwd pane_title window_name activity index < <(tmux_agent_window_fields "$target")

	local sidecar state sidecar_label label glyph agent
	sidecar="$(tmux_agent_sidecar_for_pane "$pane")"
	state="$(jq -r '.state // empty' <<<"$sidecar")"
	sidecar_label="$(jq -r '.label // empty' <<<"$sidecar")"
	agent="$(jq -r '.agent // empty' <<<"$sidecar")"

	if [ -n "$sidecar_label" ]; then
		label="$sidecar_label"
	elif ! tmux_agent_is_default_title "$pane_title" "$command"; then
		label="$pane_title"
	else
		label="${command:-pane} $(tmux_agent_basename "$cwd")"
	fi

	label="$(tmux_agent_trim "$label")"
	glyph="$(tmux_agent_state_glyph "$state")"

	jq -cn \
		--arg pane "$pane" \
		--arg command "$command" \
		--arg cwd "$cwd" \
		--arg cwd_tail "$(tmux_agent_cwd_tail "$cwd")" \
		--arg pane_title "$pane_title" \
		--arg window_name "$window_name" \
		--argjson activity "${activity:-0}" \
		--arg index "$index" \
		--arg state "$state" \
		--arg state_rank "$(tmux_agent_state_rank "$state")" \
		--arg glyph "$glyph" \
		--arg agent "$agent" \
		--arg label "$label" \
		--arg age "$(tmux_agent_age_text "${activity:-0}")" \
		'{pane:$pane, command:$command, cwd:$cwd, cwd_tail:$cwd_tail, pane_title:$pane_title, window_name:$window_name, activity:$activity, index:$index, state:$state, state_rank:($state_rank|tonumber), glyph:$glyph, agent:$agent, label:$label, age:$age}'
}
