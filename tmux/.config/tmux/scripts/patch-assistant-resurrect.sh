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
# Upstream tmux-resurrect's save script (NOT owned — patched in place here rather
# than via a PR). Patch 3 makes its pane-content capture skip assistant panes.
RESURRECT_SAVE="$HOME/.tmux/plugins/tmux-resurrect/scripts/save.sh"
# Our own helper (committed in dotfiles, stowed here) defining
# assistant_subtree_pids. Patch 3 sources it into tmux-resurrect's save.sh.
SUBTREE_LIB="$HOME/.config/tmux/scripts/lib-assistant-subtree.sh"
# The fork's save script still contains the old, leaky strip function (Patch 5
# removes it). Same file 2a/2b patch.
LOG="$HOME/.tmux/resurrect/patch-assistant-resurrect.log"

log() {
  mkdir -p "$(dirname "$LOG")"
  printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >>"$LOG"
}

if [[ ! -f "$ASSISTANT_SAVE" ]]; then
  # Plugin not installed yet (first-boot, fresh setup). Nothing to patch.
  log "no plugin file at $ASSISTANT_SAVE — skipping (first run before TPM)"
  log "ran, 0 applied"
  exit 0
fi

# Rotate log at 256 KiB (this script is short, log shouldn't grow much)
if [[ -f "$LOG" ]] && (( $(stat -c %s "$LOG" 2>/dev/null || echo 0) > 262144 )); then
  mv "$LOG" "${LOG}.old"
fi

applied=0

# Patch 1 (bare-trailing --resume regex) was RETIRED 2026-05-28.
# Upstream PR #30 (commit f710f70) replaced the hardcoded resume sed with
# _discover_session_flags + _strip_long_opt, whose regex
# `s/<flag>(=[^ ]*| +[^- ][^ ]*)?//g` makes the value optional — so bare
# `--resume`, `--resume=<id>`, and `--resume <id>` are all stripped, for every
# session flag (resume|continue|session-id|fork-session|from-pr). That is the
# same fix this patch used to apply, now upstream and generalized. No local
# patch needed; the old grep guard could never match the new code anyway.

# Patch 2: canonicalize grouped session names at save time
# Upstream saves pane addresses under the most recent grouped session
# (e.g., main-0:N.0). At restore time only the canonical 'main' exists, so
# the addresses don't resolve and 'restored 0 of N assistant sessions' is
# logged. Fix resolves #{session_group} and uses the base name when
# non-empty.
# Patch 2a: canonicalize. Replaces the upstream single-line list-panes call with
# a per-pane loop that resolves #{session_group} and substitutes the base name.
if ! grep -qF 'session_group=$(tmux display-message -t "$session_name"' "$ASSISTANT_SAVE" &&
   grep -Eq 'tmux list-panes -a -F "#\{session_name\}:#\{window_index\}\.#\{pane_index\}\|#\{pane_pid\}\|#\{pane_current_path\}(\|#\{pane_tty\})?" >"\$PANE_FILE"' "$ASSISTANT_SAVE"; then
  perl -0777 -pe '
    my $replacement = q~	>"$PANE_FILE"
	while IFS='\''|'\'' read -r session_name window_index pane_index pane_pid pane_cwd pane_tty; do
		session_group=$(tmux display-message -t "$session_name" -p '\''#{session_group}'\'' 2>/dev/null || true)
		if [ -n "$session_group" ]; then
			session_name="$session_group"
		fi
		# AR-Patch2c (patch-assistant-resurrect.sh): fallback when #{session_group}
		# was empty but the name is still a grouped clone (<base>-<N>). Strip the
		# numeric suffix only if the canonical base session actually exists.
		case "$session_name" in
			*-[0-9]*)
				_ar_base="${session_name%-*}"
				if [ "$_ar_base" != "$session_name" ] && tmux has-session -t "=$_ar_base" 2>/dev/null; then
					session_name="$_ar_base"
				fi
				;;
		esac
		if [ -n "${pane_tty:-}" ]; then
			printf '\''%s:%s.%s|%s|%s|%s\n'\'' "$session_name" "$window_index" "$pane_index" "$pane_pid" "$pane_cwd" "$pane_tty" >>"$PANE_FILE"
		else
			printf '\''%s:%s.%s|%s|%s\n'\'' "$session_name" "$window_index" "$pane_index" "$pane_pid" "$pane_cwd" >>"$PANE_FILE"
		fi
	done < <(tmux list-panes -a -F "#{session_name}|#{window_index}|#{pane_index}|#{pane_pid}|#{pane_current_path}|#{pane_tty}")
	sort -u -o "$PANE_FILE" "$PANE_FILE"~;
    s~\ttmux list-panes -a -F "#\{session_name\}:#\{window_index\}\.#\{pane_index\}\|#\{pane_pid\}\|#\{pane_current_path\}(?:\|#\{pane_tty\})?" >"\$PANE_FILE"~$replacement~ or die "patch 2a list-panes line not found";
  ' "$ASSISTANT_SAVE" >"${ASSISTANT_SAVE}.artmp"
  if grep -qF 'AR-Patch2c' "${ASSISTANT_SAVE}.artmp" &&
     grep -qF 'sort -u -o "$PANE_FILE" "$PANE_FILE"' "${ASSISTANT_SAVE}.artmp" &&
     bash -n "${ASSISTANT_SAVE}.artmp" 2>/dev/null; then
    cat "${ASSISTANT_SAVE}.artmp" >"$ASSISTANT_SAVE"
    rm -f "${ASSISTANT_SAVE}.artmp"
    log "applied patch 2a: canonicalize grouped session pane addresses"
    applied=$((applied + 1))
  else
    log "warning: patch 2a NOT applied cleanly (marker/sort missing or bash -n failed) — review $ASSISTANT_SAVE"
    rm -f "${ASSISTANT_SAVE}.artmp"
  fi
fi

# Patch 2b: dedup. After canonicalization, the same physical pane appears once
# per grouped session clone (main, main-0, main-1, ...) all rewritten to
# 'main:N.0' — N copies of an identical line. Restore then attempts the
# resume command N times. Add `sort -u -o "$PANE_FILE" "$PANE_FILE"` right
# after the canonicalize loop so $PANE_FILE has at most one entry per pane.
if grep -qF 'session_group=$(tmux display-message -t "$session_name"' "$ASSISTANT_SAVE" &&
   ! grep -qF 'sort -u -o "$PANE_FILE" "$PANE_FILE"' "$ASSISTANT_SAVE"; then
  # Insert right after the `done < <(tmux list-panes -a -F "#{session_name}|...")` line
  sed -i '/done < <(tmux list-panes -a -F "#{session_name}|#{window_index}|#{pane_index}|#{pane_pid}|#{pane_current_path}")/a\
	sort -u -o "$PANE_FILE" "$PANE_FILE"' "$ASSISTANT_SAVE"
  log "applied patch 2b: dedup pane file"
  applied=$((applied + 1))
fi

# Patch 2c: harden canonicalization against a transient #{session_group} miss.
# (Incident 2026-06-08.) Upstream PR #30 upstreamed the 2a/2b logic, but its
# canonicalization is `session_group=$(... '#{session_group}'); [ -n ] && name=$group`.
# That trusts #{session_group} alone. During the autosave that became the last
# pre-crash save, the panes were listed under a grouped CLONE (main-4) while
# #{session_group} came back EMPTY for that target — either because the clone was
# being torn down mid-save (display-message errored, swallowed by `|| true`) or
# tmux hadn't populated the field yet. Result: 19 panes written as `main-4:N.0`,
# and the boot restore (only `main` exists) logged "restored 0 of 19".
#
# Fix: add a suffix-strip FALLBACK. After the upstream group resolution, if the
# name STILL looks like a grouped clone (`<base>-<N>`) AND a session with that
# bare `<base>` exists, strip the `-<N>`. This catches the empty-#{session_group}
# race without touching legitimately-named sessions (the `has-session <base>`
# guard means we only strip when the canonical base actually exists). Idempotent
# via the AR-Patch2c marker.
if grep -qF 'session_group=$(tmux display-message -t "$session_name"' "$ASSISTANT_SAVE" &&
   ! grep -qF 'AR-Patch2c' "$ASSISTANT_SAVE"; then
  # Insert the fallback immediately after the existing `fi` that closes the
  # `if [ -n "$session_group" ]; then session_name="$session_group"; fi` block,
  # i.e. right before the `printf ... >>"$PANE_FILE"` line. We anchor on the
  # printf line and prepend the fallback above it.
  perl -0777 -i -pe '
    s{(\n\t\tprintf '"'"'%s:%s\.%s\|%s\|%s\\n'"'"' "\$session_name")}{\n\t\t# AR-Patch2c (patch-assistant-resurrect.sh): fallback when #{session_group}\n\t\t# was empty but the name is still a grouped clone (<base>-<N>). Strip the\n\t\t# numeric suffix only if the canonical base session actually exists.\n\t\tcase "\$session_name" in\n\t\t\t*-[0-9]*)\n\t\t\t\t_ar_base="\${session_name%-*}"\n\t\t\t\tif [ "\$_ar_base" != "\$session_name" ] \&\& tmux has-session -t "=\$_ar_base" 2>/dev/null; then\n\t\t\t\t\tsession_name="\$_ar_base"\n\t\t\t\tfi\n\t\t\t\t;;\n\t\tesac$1}
  ' "$ASSISTANT_SAVE"
  if grep -qF 'AR-Patch2c' "$ASSISTANT_SAVE" && bash -n "$ASSISTANT_SAVE" 2>/dev/null; then
    log "applied patch 2c: suffix-strip fallback for empty #{session_group}"
    applied=$((applied + 1))
  else
    log "warning: patch 2c NOT applied cleanly (marker missing or bash -n failed) — review $ASSISTANT_SAVE"
  fi
fi

# Patch 3: skip assistant panes when tmux-resurrect captures pane contents.
# Upstream `dump_pane_contents` (in tmux-resurrect/scripts/save.sh) captures the
# scrollback of EVERY pane into pane_contents.tar.gz. Assistant (Claude/Codex/
# OpenCode) TUIs are relaunched fresh on restore, so their captured scrollback is
# useless — and capturing it bloated the archive by ~1GB and drove a /tmp tmpfs
# RAM leak (the old strip step's mktemp -d leaked GB-sized dirs when a save was
# SIGKILLed mid-strip). This patch sources our lib-assistant-subtree.sh, takes
# ONE ps snapshot, and skips capture for any pane whose process subtree contains
# an assistant (assistant_subtree_pids — fast, batched). Non-assistant scrollback
# is unaffected. Marker `# AR-Patch3` makes it idempotent across TPM updates.
if [[ -f "$RESURRECT_SAVE" ]] &&
   ! grep -qF 'AR-Patch3' "$RESURRECT_SAVE" &&
   grep -qF 'dump_pane_contents() {' "$RESURRECT_SAVE"; then
  awk -v lib="$SUBTREE_LIB" '
    /^dump_pane_contents\(\) \{$/ && !done1 {
      print
      print "\t# AR-Patch3 (patch-assistant-resurrect.sh): skip assistant panes at"
      print "\t# capture time so their scrollback never enters pane_contents.tar.gz."
      print "\t_ar_lib=\"" lib "\"; _ar_skip=\"\""
      print "\t# assistant_subtree_pids prints one pid per line; the space-glob skip"
      print "\t# check below needs them space-separated, so normalize newlines."
      print "\t[ -f \"$_ar_lib\" ] && . \"$_ar_lib\" && _ar_skip=\" $(assistant_subtree_pids 2>/dev/null | tr \"\\n\" \" \") \""
      done1=1; next
    }
    /capture_pane_contents "\$\{session_name\}/ && !done2 {
      match($0, /^[ \t]*/); ws=substr($0,1,RLENGTH)
      print ws "case \" $_ar_skip \" in *\" $pane_pid \"*) continue ;; esac"
      print
      done2=1; next
    }
    { print }
  ' "$RESURRECT_SAVE" >"${RESURRECT_SAVE}.artmp"
  # Validate the transform BEFORE replacing the live file: the marker must be
  # present AND the result must be syntactically valid bash. Only then overwrite
  # save.sh — a broken transform must never clobber a working save script.
  if grep -qF 'AR-Patch3' "${RESURRECT_SAVE}.artmp" && bash -n "${RESURRECT_SAVE}.artmp" 2>/dev/null; then
    cat "${RESURRECT_SAVE}.artmp" >"$RESURRECT_SAVE"
    rm -f "${RESURRECT_SAVE}.artmp"
    log "applied patch 3: skip assistant panes in tmux-resurrect pane-content capture"
    applied=$((applied + 1))
  else
    log "warning: patch 3 NOT applied (marker missing or bash -n failed) — save.sh left untouched"
    rm -f "${RESURRECT_SAVE}.artmp"
  fi
fi

# Patch 6: serialize tmux-resurrect saves across all callers.
# tmux-continuum can trigger save.sh from multiple status-line clients in the
# same second, and systemd ExecStop also calls the same save.sh. Concurrent
# writers share the same timestamped output path; the losing run can compare
# the file to itself, delete it as a duplicate, and leave `last` dangling. A
# non-blocking flock makes duplicate concurrent saves safely skippable while
# preserving normal future saves.
if [[ -f "$RESURRECT_SAVE" ]] &&
   ! grep -qF 'AR-Patch6' "$RESURRECT_SAVE" &&
   grep -qF 'source "$CURRENT_DIR/helpers.sh"' "$RESURRECT_SAVE"; then
  awk '
    /^source "\$CURRENT_DIR\/spinner_helpers\.sh"$/ && !done {
      print
      print ""
      print "# AR-Patch6 (patch-assistant-resurrect.sh): skip concurrent duplicate saves."
      print "# Keep fd 8 open for the process lifetime so the lock covers all writes."
      print "_ar_resurrect_dir=\"$(resurrect_dir)\""
      print "mkdir -p \"$_ar_resurrect_dir\""
      print "exec 8>\"$_ar_resurrect_dir/save.lock\""
      print "flock -n 8 || exit 0"
      done=1; next
    }
    { print }
  ' "$RESURRECT_SAVE" >"${RESURRECT_SAVE}.artmp"
  if grep -qF 'AR-Patch6' "${RESURRECT_SAVE}.artmp" && bash -n "${RESURRECT_SAVE}.artmp" 2>/dev/null; then
    cat "${RESURRECT_SAVE}.artmp" >"$RESURRECT_SAVE"
    rm -f "${RESURRECT_SAVE}.artmp"
    log "applied patch 6: non-blocking flock around tmux-resurrect save.sh"
    applied=$((applied + 1))
  else
    log "warning: patch 6 NOT applied (marker missing or bash -n failed) — save.sh left untouched"
    rm -f "${RESURRECT_SAVE}.artmp"
  fi
fi

# Patch 5: remove the now-vestigial, still-leaky strip_assistant_pane_contents()
# from the fork's save-assistant-sessions.sh. With Patch 3 active, assistant panes
# never enter pane_contents.tar.gz, so the strip finds nothing — but it still does
# a full ~1GB extract into an unguarded `mktemp -d`, retaining the exact /tmp leak
# surface this whole change exists to remove. We delete the call site (replacing
# the `if [ "$count" -gt 0 ]; then strip_assistant_pane_contents; fi` block with a
# no-op marker) and leave the function definition harmlessly unreferenced.
# Idempotent: guarded by the AR-Patch5 marker.
if [[ -f "$ASSISTANT_SAVE" ]] &&
   ! grep -qF 'AR-Patch5' "$ASSISTANT_SAVE" &&
   grep -qF 'strip_assistant_pane_contents' "$ASSISTANT_SAVE"; then
  # Replace the guarded call (3 lines) with a marker comment. The call always
  # appears as exactly:
  #     if [ "$count" -gt 0 ]; then
  #         strip_assistant_pane_contents
  #     fi
  # Transform to a temp file, validate (marker present + bash -n), then swap —
  # never edit ASSISTANT_SAVE in place, since it also carries the 2a/2b
  # boot-restore patches and must not be left corrupt.
  perl -0777 -pe '
    s/\tif \[ "\$count" -gt 0 \]; then\n\t\tstrip_assistant_pane_contents\n\tfi\n/\t# AR-Patch5: strip_assistant_pane_contents call removed — assistant panes\n\t# are now skipped at capture time (see patch-assistant-resurrect.sh Patch 3),\n\t# so the leaky extract\/strip\/repack is no longer needed.\n/;
  ' "$ASSISTANT_SAVE" >"${ASSISTANT_SAVE}.artmp"
  if grep -qF 'AR-Patch5' "${ASSISTANT_SAVE}.artmp" && bash -n "${ASSISTANT_SAVE}.artmp" 2>/dev/null; then
    cat "${ASSISTANT_SAVE}.artmp" >"$ASSISTANT_SAVE"
    rm -f "${ASSISTANT_SAVE}.artmp"
    log "applied patch 5: removed strip_assistant_pane_contents call (leak surface)"
    applied=$((applied + 1))
  else
    rm -f "${ASSISTANT_SAVE}.artmp"
    log "warning: patch 5 NOT applied (marker missing or bash -n failed) — file left untouched"
  fi
fi

log "ran, $applied applied"
