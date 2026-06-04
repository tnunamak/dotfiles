#!/usr/bin/env bash
# Dotfiles-owned helper: assistant_subtree_pids
#
# Why this lives here (not in the plugin): tmux-assistant-resurrect
# (github.com/timvw/...) is NOT our repo — we have read-only access, so we can't
# add functions to its lib-detect.sh upstream. Following the same precedent as
# save-assistant-sessions-guarded.sh, we keep our own code in the dotfiles and
# extend the unowned plugin from the outside. patch-assistant-resurrect.sh
# (Patch 3) sources THIS file into tmux-resurrect's dump_pane_contents() so the
# pane-content capture loop can skip assistant panes.
#
# detect_tool (the authoritative tool-matcher, incl. its "opencode run"
# exclusion) is reused from the plugin's lib-detect.sh — single source of truth.
#
# Background: assistant (Claude/Codex/OpenCode) TUIs are relaunched fresh on
# restore, so capturing their scrollback is pointless. It also bloated
# pane_contents.tar.gz by ~1GB and drove a /tmp (tmpfs = RAM) leak via the old
# post-save strip step's unguarded `mktemp -d`. Skipping capture removes the
# whole problem.

# Source the plugin's detect_tool. Resolve the plugin dir from TPM's layout.
_AR_DETECT_LIB="${TMUX_PLUGIN_MANAGER_PATH:-$HOME/.tmux/plugins}/tmux-assistant-resurrect/scripts/lib-detect.sh"
# Fall back to the canonical path if the env var points elsewhere.
[ -f "$_AR_DETECT_LIB" ] || _AR_DETECT_LIB="$HOME/.tmux/plugins/tmux-assistant-resurrect/scripts/lib-detect.sh"
# shellcheck source=/dev/null
[ -f "$_AR_DETECT_LIB" ] && . "$_AR_DETECT_LIB"

# --- assistant_subtree_pids ---
# Prints, one per line, every PID that is an assistant OR has an assistant
# anywhere in its subtree (so a pane shell whose descendant is an assistant is
# included). Batched equivalent of the plugin's pane_has_assistant, but for every
# process at once: one ps snapshot + one awk pass (candidate flagging by argv0
# basename) + detect_tool confirmation only on candidates. On a busy server with
# grouped sessions, per-pane pane_has_assistant was ~40s (O(panes x tree) awk
# forks); this is ~0.01-0.04s. That speed matters: a slow save can be SIGKILLed
# by the next autosave mid-run, which is what leaked temp dirs in the first place.
#
# Usage: assistant_subtree_pids [ps_snapshot]
# Parent-before-child ordering assumption matches pane_has_assistant (holds on
# Linux procfs / macOS libproc).
assistant_subtree_pids() {
	# If detect_tool is unavailable (plugin missing), emit nothing — callers then
	# capture all panes, i.e. fail safe to the pre-patch behavior.
	command -v detect_tool >/dev/null 2>&1 || return 0

	local snapshot="${1:-$(ps -eo pid=,ppid=,args= 2>/dev/null)}"

	# One awk pass: a parent edge for every pid, plus a candidate line for any pid
	# whose argv0 basename is a known assistant binary (detect_tool confirms).
	local awk_out
	awk_out=$(echo "$snapshot" | awk '
		{
			pid=$1; ppid=$2; rest=substr($0, index($0,$3))
			print "P " pid " " ppid
			cmd=$3; n=split(cmd, a, "/"); base=a[n]
			if (base=="claude" || base=="codex" || base=="opencode")
				print "C " pid " " rest
		}')

	local -A _ppid=() _assist=()
	local tag pid val
	while read -r tag pid val; do
		case "$tag" in
			P) _ppid[$pid]="$val" ;;
			C) [ -n "$(detect_tool "$val")" ] && _assist[$pid]=1 ;;
		esac
	done <<< "$awk_out"

	# Mark each assistant and walk up marking every ancestor (the pane shell that
	# launched it sits above it in the tree). Never mark pid 1 (init is no pane).
	local -A _mark=()
	local ap q parent
	for ap in "${!_assist[@]}"; do
		_mark[$ap]=1
		q=$ap
		while :; do
			parent="${_ppid[$q]:-}"
			[ -z "$parent" ] && break
			[ "$parent" = 0 ] && break
			[ "$parent" = 1 ] && break
			[ "$parent" = "$q" ] && break
			_mark[$parent]=1
			q=$parent
		done
	done

	printf '%s\n' "${!_mark[@]}"
}
