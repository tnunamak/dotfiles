#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-tmux-agent-windows.sh
source "$SCRIPT_DIR/lib-tmux-agent-windows.sh"

agent="${1:-}"
state="${2:-}"
if [ -z "$agent" ] || [ -z "$state" ]; then
	exit 0
fi

input="$(cat)"
[ -n "$input" ] || input='{}'

state_dir="$(tmux_agent_state_dir)"
mkdir -p -m 0700 "$state_dir"

json_get() {
	local filter="$1"
	jq -r "$filter // empty" <<<"$input" 2>/dev/null || true
}

tmux_pane="${TMUX_PANE:-$(json_get '.tmux_pane')}"
cwd="$(json_get '.cwd // .working_dir // .workspace_root')"
event_name="$(json_get '.hook_event_name // .event_name // .hook // .event')"
session_id="$(json_get '.session_id // .sessionId // .conversation_id // .id')"
prompt="$(json_get '.prompt // .user_prompt // .message // .input')"
explicit_name="$(json_get '.name // .session_name // .sessionName // .thread_name // .title')"
name_source=""

pane_pid=""
if [ -n "$tmux_pane" ] && command -v tmux >/dev/null 2>&1; then
	pane_pid="$(tmux display-message -p -t "$tmux_pane" '#{pane_pid}' 2>/dev/null || true)"
	if [ -z "$cwd" ]; then
		cwd="$(tmux display-message -p -t "$tmux_pane" '#{pane_current_path}' 2>/dev/null || true)"
	fi
fi

if [ "$agent" = "claude" ] && [ -n "$pane_pid" ]; then
	claude_session="$HOME/.claude/sessions/$pane_pid.json"
	if [ -f "$claude_session" ]; then
		session_id="${session_id:-$(jq -r '.sessionId // .session_id // empty' "$claude_session" 2>/dev/null || true)}"
		cwd="${cwd:-$(jq -r '.cwd // empty' "$claude_session" 2>/dev/null || true)}"
		name_source="$(jq -r '.nameSource // empty' "$claude_session" 2>/dev/null || true)"
		if [ -z "$explicit_name" ] && [ "$name_source" != "derived" ]; then
			explicit_name="$(jq -r '.name // empty' "$claude_session" 2>/dev/null || true)"
		fi
	fi
fi

if [ -z "$session_id" ]; then
	session_id="${agent}-${tmux_pane:-unknown}"
fi

safe_id="$(printf '%s' "$session_id" | tr -c 'A-Za-z0-9_.=-' '_')"
sidecar="$state_dir/$safe_id.json"

previous_label=""
if [ -f "$sidecar" ]; then
	previous_label="$(jq -r '.label // empty' "$sidecar" 2>/dev/null || true)"
fi

first_prompt_line="$(printf '%s\n' "$prompt" | sed -n '1p')"
first_prompt_line="$(tmux_agent_trim "$first_prompt_line")"

label=""
if [ -n "$explicit_name" ]; then
	label="$explicit_name"
elif ((${#first_prompt_line} >= 20)); then
	label="$(tmux_agent_basename "$cwd"): $first_prompt_line"
elif [ -n "$previous_label" ]; then
	label="$previous_label"
else
	label="$(tmux_agent_basename "$cwd")"
fi
label="$(tmux_agent_compact_label "$label")"

tmp="$(mktemp "$state_dir/.${safe_id}.XXXXXX")"
jq -n \
	--arg label "$label" \
	--arg state "$state" \
	--arg tmux_pane "$tmux_pane" \
	--arg agent "$agent" \
	--arg cwd "$cwd" \
	--arg session_id "$session_id" \
	--arg hook_event_name "$event_name" \
	--argjson ts "$(date +%s)" \
	'{label:$label,state:$state,tmux_pane:$tmux_pane,agent:$agent,cwd:$cwd,ts:$ts,session_id:$session_id,hook_event_name:$hook_event_name}' \
	>"$tmp"
mv "$tmp" "$sidecar"
