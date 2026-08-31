#!/usr/bin/env bash
# tmux-resurrect restore, driven by systemd (not continuum). Invoked by
# tmux-restore.service after every tmux.service start — including
# automatic recovery cycles. The script itself is state-aware: it only
# restores when tmux is fresh-empty, so re-invocations after a legitimate
# resume (or during manual tmux restarts with live work) are no-ops.
#
# Skipping logic compares current tmux pane count against the pane count
# recorded in the resurrect save. If they already match roughly, the
# restore is redundant and is skipped.
#
# Invoked via `tmux run-shell` so $TMUX is set inside restore.sh — otherwise
# restore.sh's `tmux -S "$(tmux_socket)"` calls hit an empty socket path and
# silently create nothing.
set -euo pipefail

RESURRECT_DIR="${HOME}/.tmux/resurrect"
SENTINEL="${RESURRECT_DIR}/.restore-complete"
STATUS="${RESURRECT_DIR}/.restore-status"
LOG="${RESURRECT_DIR}/systemd-restore.log"
RESTORE_SCRIPT="${HOME}/.tmux/plugins/tmux-resurrect/scripts/restore.sh"
BUNDLE_CLI="${HOME}/.config/tmux/scripts/resurrect-transaction-bundle"
DESKTOP_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/desktop-layout"

log() { printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >>"$LOG"; }

fsync_path() {
  sync -f "$1" 2>/dev/null || return 1
}

stage_copy_to_plan() {
  local src="$1" dest="$2" plan="$3" tmp
  mkdir -p "$(dirname "$dest")"
  tmp="$(mktemp "${dest}.tmp.XXXXXX")"
  if ! cp -f "$src" "$tmp" || ! fsync_path "$tmp"; then
    rm -f "$tmp"
    return 1
  fi
  printf '%s\t%s\n' "$tmp" "$dest" >>"$plan"
}

stage_json_file() {
  local dest="$1" tmp
  mkdir -p "$(dirname "$dest")"
  tmp="$(mktemp "${dest}.tmp.XXXXXX")"
  if ! cat >"$tmp" || ! fsync_path "$tmp"; then
    rm -f "$tmp"
    return 1
  fi
  printf '%s\n' "$tmp"
}

commit_staged_file() {
  local tmp="$1" dest="$2"
  mv -f "$tmp" "$dest"
  fsync_path "$dest" || return 1
  fsync_path "$(dirname "$dest")" || return 1
}

cleanup_activation_temps() {
  local plan="${1:-}" receipt="${2:-}" symlink_tmp="${3:-}" tmp dest
  if [[ -f "$plan" ]]; then
    while IFS=$'\t' read -r tmp dest; do
      [[ -n "$tmp" ]] && rm -f "$tmp"
    done <"$plan"
  fi
  [[ -n "$receipt" ]] && rm -f "$receipt"
  [[ -n "$symlink_tmp" ]] && rm -f "$symlink_tmp"
  [[ -n "$plan" ]] && rm -f "$plan"
}

activation_plan_destination_is_safe() {
  local dest="$1" parent base
  parent="${dest%/*}"
  base="${dest##*/}"
  [[ ( "$parent" == "$RESURRECT_DIR" && ( "$base" == layout-* || "$base" == assistant-sessions.json ) ) ||
     ( "$parent" == "$DESKTOP_STATE_DIR" && "$base" == manifest.json ) ||
     "$parent" == "$DESKTOP_STATE_DIR/kitty-sessions" ]]
}

cleanup_stale_activation_artifacts() {
  local plan tmp dest
  # Plans are our only authority for a staged-file temporary path. Do not
  # glob-delete destination temps: another tool may use that naming pattern.
  while IFS= read -r -d '' plan; do
    while IFS=$'\t' read -r tmp dest; do
      [[ -n "$tmp" && -n "$dest" ]] || continue
      if activation_plan_destination_is_safe "$dest" && [[ "$tmp" == "$dest".tmp.* ]]; then
        rm -f -- "$tmp"
      fi
    done <"$plan"
    rm -f -- "$plan"
  done < <(find "$RESURRECT_DIR" -maxdepth 1 -type f -name '.bundle-activation-plan.*' -print0)
  while IFS= read -r -d '' tmp; do
    rm -f -- "$tmp"
  done < <(find "$RESURRECT_DIR" -maxdepth 1 -type l -name '.last.tmp.*' -print0)
  if [[ -d "$DESKTOP_STATE_DIR" ]]; then
    while IFS= read -r -d '' tmp; do
      rm -f -- "$tmp"
    done < <(find "$DESKTOP_STATE_DIR" -maxdepth 1 -type f \
      \( -name '.bundle-activation.json.tmp.*' -o -name '.no-desktop-receipt.json.tmp.*' \) -print0)
  fi
}

count_save_panes() {
  local save_file="$1"
  local panes
  panes=$(grep -c '^pane' "$save_file" 2>/dev/null || true)
  panes="${panes%%$'\n'*}"
  [[ "$panes" =~ ^[0-9]+$ ]] || panes=0
  printf '%s\n' "$panes"
}

find_fallback_save() {
  local mtime path panes
  while IFS=$'\t' read -r mtime path; do
    [ -z "$path" ] && continue
    panes=$(count_save_panes "$path")
    if (( panes >= 3 )); then
      printf '%s\t%s\n' "$path" "$panes"
      return 0
    fi
  done < <(
    {
      find "$RESURRECT_DIR" -maxdepth 1 -type f -name 'tmux_resurrect_*.txt' -printf '%T@\t%p\n' 2>/dev/null
      find "$RESURRECT_DIR/backups" -maxdepth 1 -type f -name 'tmux_resurrect_*.txt' -printf '%T@\t%p\n' 2>/dev/null
    } | sort -rn 2>/dev/null
  )

  if [ -f "$RESURRECT_DIR/backups/best.txt" ]; then
    panes=$(count_save_panes "$RESURRECT_DIR/backups/best.txt")
    if (( panes >= 3 )); then
      printf '%s\t%s\n' "$RESURRECT_DIR/backups/best.txt" "$panes"
      return 0
    fi
  fi

  return 1
}

resolve_bundle_for_restore() {
  [[ -x "$BUNDLE_CLI" ]] || return 1
  "$BUNDLE_CLI" resolve 2>>"$LOG" || return 1
}

transaction_state_initialized() {
  [[ -e "${RESURRECT_DIR}/transactions" ]]
}

activate_bundle_for_restore() {
  local bundle_json="$1" bundle_id bundle_path layout_name assistant_name layout_path assistant_path desktop_status desktop_file desktop_hash desktop_path native_row native_file native_hash native_path native_activation claimed_native_activation staged_plan staged_receipt receipt_path staged_last_link committed_files
  bundle_id="$(jq -r '.id' <<<"$bundle_json")"
  bundle_path="$(jq -r '.path' <<<"$bundle_json")"
  layout_name="$(jq -r '.components.layout.file' <<<"$bundle_json")"
  assistant_name="$(jq -r '.components.assistant.file // empty' <<<"$bundle_json")"
  layout_path="${bundle_path}/${layout_name}"
  [[ -f "$layout_path" ]] || return 1
  cleanup_stale_activation_artifacts
  staged_plan="$(mktemp "${RESURRECT_DIR}/.bundle-activation-plan.XXXXXX")"
  staged_receipt=""
  staged_last_link=""
  trap 'cleanup_activation_temps "$staged_plan" "$staged_receipt" "$staged_last_link"' RETURN
  stage_copy_to_plan "$layout_path" "${RESURRECT_DIR}/${layout_name}" "$staged_plan" || return 1
  if [[ -n "$assistant_name" ]]; then
    assistant_path="${bundle_path}/${assistant_name}"
    [[ -f "$assistant_path" ]] || return 1
    stage_copy_to_plan "$assistant_path" "${RESURRECT_DIR}/assistant-sessions.json" "$staged_plan" || return 1
  fi
  mkdir -p "$DESKTOP_STATE_DIR/kitty-sessions"
  desktop_status="$(jq -r '.components.desktop.status // empty' <<<"$bundle_json")"
  if [[ "$desktop_status" == "bundled" ]]; then
    desktop_file="$(jq -r '.components.desktop.file' <<<"$bundle_json")"
    desktop_hash="$(jq -r '.components.desktop.sha256' <<<"$bundle_json")"
    desktop_path="${bundle_path}/${desktop_file}"
    [[ -f "$desktop_path" ]] || return 1
    [[ "$(sha256sum "$desktop_path" | awk '{print $1}')" == "$desktop_hash" ]] || return 1
    while IFS= read -r native_row; do
      native_file="$(jq -r '.file' <<<"$native_row")"
      native_hash="$(jq -r '.sha256' <<<"$native_row")"
      claimed_native_activation="$(jq -r '.activation_path' <<<"$native_row")"
      native_path="${bundle_path}/${native_file}"
      [[ -f "$native_path" ]] || return 1
      [[ "$(sha256sum "$native_path" | awk '{print $1}')" == "$native_hash" ]] || return 1
      [[ "$native_file" =~ ^[A-Za-z0-9._-]+$ && "$native_file" != . && "$native_file" != .. ]] || return 1
      native_activation="$DESKTOP_STATE_DIR/kitty-sessions/$native_file"
      [[ "$claimed_native_activation" == "$native_activation" ]] || return 1
      stage_copy_to_plan "$native_path" "$native_activation" "$staged_plan" || return 1
    done < <(jq -c '.components.desktop.native_sessions[]?' <<<"$bundle_json")
    stage_copy_to_plan "$desktop_path" "$DESKTOP_STATE_DIR/manifest.json" "$staged_plan" || return 1
    receipt_path="$DESKTOP_STATE_DIR/.bundle-activation.json"
    staged_receipt="$(jq -n \
      --arg bundle_id "$bundle_id" \
      --arg manifest "$DESKTOP_STATE_DIR/manifest.json" \
      --arg sha256 "$desktop_hash" \
      '{schema:"tmux-resurrect-transaction-bundle/desktop-activation/v1",status:"activated",bundle_id:$bundle_id,manifest:{path:$manifest,sha256:$sha256}}' |
      stage_json_file "$receipt_path")" || return 1
  else
    receipt_path="$DESKTOP_STATE_DIR/.no-desktop-receipt.json"
    staged_receipt="$(jq -n \
      --arg bundle_id "$bundle_id" \
      --arg reason "$(jq -r '.components.desktop.reason // "desktop component absent"' <<<"$bundle_json")" \
      '{schema:"tmux-resurrect-transaction-bundle/desktop-activation/v1",status:"not-bundled",bundle_id:$bundle_id,reason:$reason}' |
      stage_json_file "$receipt_path")" || return 1
  fi

  staged_last_link="${RESURRECT_DIR}/.last.tmp.$$"
  rm -f "$staged_last_link"
  ln -s "$layout_name" "$staged_last_link" || return 1
  fsync_path "$RESURRECT_DIR" || return 1

  if [[ -n "${TMUX_RESURRECT_ACTIVATION_FAIL_AFTER_STAGE:-}" ]]; then
    log "ERROR: injected activation failure after staging bundle $bundle_id"
    return 1
  fi

  rm -f "$DESKTOP_STATE_DIR/.bundle-activation.json" "$DESKTOP_STATE_DIR/.no-desktop-receipt.json"
  fsync_path "$DESKTOP_STATE_DIR" || return 1
  # This is deliberately not a multi-directory atomic commit. The receipt is
  # the desktop commit marker: an interruption after any raw replacement leaves
  # no receipt, so desktop restore fails closed. A later activation recopies
  # every raw file from the immutable bundle and writes the receipt last.
  committed_files=0
  while IFS=$'\t' read -r tmp dest; do
    [[ -n "$tmp" && -n "$dest" ]] || continue
    commit_staged_file "$tmp" "$dest" || return 1
    committed_files=$((committed_files + 1))
    if [[ "${TMUX_RESURRECT_ACTIVATION_FAIL_AFTER_COMPONENT:-}" == "$committed_files" ]]; then
      log "ERROR: injected activation failure after component $committed_files for bundle $bundle_id"
      return 1
    fi
  done <"$staged_plan"
  mv -Tf "$staged_last_link" "$RESURRECT_DIR/last" || return 1
  staged_last_link=""
  fsync_path "$RESURRECT_DIR" || return 1
  if [[ -n "${TMUX_RESURRECT_ACTIVATION_FAIL_AFTER_LAST:-}" ]]; then
    log "ERROR: injected activation failure after last for bundle $bundle_id"
    return 1
  fi
  commit_staged_file "$staged_receipt" "$receipt_path" || return 1

  if [[ "$desktop_status" == "bundled" ]]; then
    log "activated bundled desktop manifest for bundle $bundle_id"
  else
    log "desktop restore skipped for bundle $bundle_id: $(jq -r '.components.desktop.reason // "desktop component absent"' <<<"$bundle_json")"
  fi
  log "using transaction bundle $bundle_id with layout=$layout_name assistant=${assistant_name:-<none>}"
}

repoint_last_to_fallback() {
  local reason="$1"
  local fallback_save fallback_panes fallback_name
  local fallback_info

  fallback_info="$(find_fallback_save || true)"
  if [ -z "$fallback_info" ]; then
    log "$reason and no usable fallback save exists; nothing to do"
    return 1
  fi

  IFS=$'\t' read -r fallback_save fallback_panes <<<"$fallback_info"
  fallback_name="$(basename "$fallback_save")"
  if [ "$(dirname "$fallback_save")" != "$RESURRECT_DIR" ]; then
    cp "$fallback_save" "$RESURRECT_DIR/$fallback_name"
  fi
  ln -sfn "$fallback_name" "$RESURRECT_DIR/last"
  log "$reason; repointed to fallback save $fallback_name ($fallback_panes panes)"
  return 0
}

# Rotate log at 1 MiB
if [[ -f "$LOG" ]] && (( $(stat -c %s "$LOG" 2>/dev/null || echo 0) > 1048576 )); then
  mv "$LOG" "${LOG}.old"
fi
rm -f "$SENTINEL" "$STATUS"

log "systemd-restore.sh invoked"
log "diag: RESURRECT_DIR=$RESURRECT_DIR RESTORE_SCRIPT=$RESTORE_SCRIPT"
log "diag: last symlink target=$(readlink "$RESURRECT_DIR/last" 2>/dev/null || echo '<none>')"
log "diag: last file exists=$([ -f "$RESURRECT_DIR/last" ] && echo yes || echo no)"

# Wait for tmux server to be ready (up to 10s). tmux.service is Type=forking,
# so by the time we run it should already be responsive, but be defensive.
log "diag: entering tmux wait loop"
for _ in $(seq 1 20); do
  if tmux list-sessions >/dev/null 2>&1; then break; fi
  sleep 0.5
done
log "diag: tmux wait loop done; server responsive=$(tmux list-sessions >/dev/null 2>&1 && echo yes || echo no)"

if ! tmux list-sessions >/dev/null 2>&1; then
  log "ERROR: tmux server not responsive; aborting"
  exit 1
fi

log "diag: tmux server is up"
live_panes=$(tmux list-panes -a 2>/dev/null | wc -l 2>/dev/null | head -1)
[[ -z "$live_panes" ]] && live_panes=0
log "state before activation: live_panes=$live_panes"
if (( live_panes > 2 )); then
  log "tmux already has $live_panes panes; skipping bundle activation and restore to preserve live state"
  exit 0
fi

bundle_json="$(resolve_bundle_for_restore || true)"
if [[ -n "$bundle_json" ]]; then
  if ! activate_bundle_for_restore "$bundle_json"; then
    log "ERROR: transaction bundle resolved but could not be activated; aborting rather than mixing raw files"
    exit 1
  fi
elif transaction_state_initialized; then
  log "ERROR: transaction state exists but no valid last-good bundle resolved; aborting rather than using legacy raw fallback"
  exit 1
else
  log "WARNING: no transaction bundle resolved; using legacy raw last/assistant fallback only because no valid bundle exists"
fi

if [ ! -x "$RESTORE_SCRIPT" ]; then
  log "ERROR: $RESTORE_SCRIPT not found/executable; aborting"
  exit 1
fi
log "diag: restore script found and executable"

if [[ -z "$bundle_json" ]] && [ -L "$RESURRECT_DIR/last" ] && [ ! -f "$RESURRECT_DIR/last" ]; then
  # Hunt for the newest non-trivial save across both the live dir and backups/.
  # An unclean shutdown can leave the most recent save unsynced to disk while
  # the post-save-backup hook's copy in backups/ survives, so backups/ must be
  # part of the search. We pick the newest save with >=3 panes; anything
  # smaller is likely the post-crash empty state we're trying to escape.
  if ! repoint_last_to_fallback "last symlink was dangling"; then
    exit 0
  fi
fi

if [ ! -f "$RESURRECT_DIR/last" ]; then
  log "no resurrect save to restore ($RESURRECT_DIR/last missing); nothing to do"
  exit 0
fi

# State-aware gate: only restore if tmux looks fresh-empty. "Fresh-empty"
# means the total live pane count across all sessions is ≤ 2 (systemd's
# default `new-session -d` plus at most one attached kitty session). The same
# gate ran before activation, so raw bundle files are untouched for live tmux.
save_target="$(readlink -f "$RESURRECT_DIR/last" 2>/dev/null || true)"
if [[ -n "$save_target" && -f "$save_target" ]]; then
  save_panes=$(count_save_panes "$save_target")
else
  save_panes=0
fi
[[ -z "$save_panes" ]] && save_panes=0
log "state: live_panes=$live_panes save_panes=$save_panes"

if [[ -z "$bundle_json" ]] && (( save_panes < 3 )); then
  if repoint_last_to_fallback "last save had only $save_panes panes"; then
    save_target="$(readlink -f "$RESURRECT_DIR/last" 2>/dev/null || true)"
    if [[ -n "$save_target" && -f "$save_target" ]]; then
      save_panes=$(count_save_panes "$save_target")
    else
      save_panes=0
    fi
    log "state after fallback: save_panes=$save_panes"
  fi
fi

if (( save_panes < 3 )); then
  log "save has only $save_panes panes — nothing worth restoring"
  exit 0
fi

log "running restore via tmux run-shell"
tmux run-shell -b "bash '$RESTORE_SCRIPT' >>'$LOG' 2>&1; rc=\$?; printf '%s\n' \"\$rc\" >'$STATUS'; [ \"\$rc\" -eq 0 ] && touch '$SENTINEL'"

# Bounded wait for restore to finish (sentinel touched at end of run-shell).
for _ in $(seq 1 1200); do
  [ -f "$SENTINEL" ] && break
  [ -f "$STATUS" ] && break
  sleep 0.5
done

if [ -f "$SENTINEL" ]; then
  log "restore complete; sentinel written"
  exit 0
elif [ -f "$STATUS" ]; then
  restore_rc="$(tr -d '[:space:]' < "$STATUS" 2>/dev/null || echo 1)"
  [[ "$restore_rc" =~ ^[0-9]+$ ]] || restore_rc=1
  log "ERROR: restore exited rc=$restore_rc"
  exit "$restore_rc"
else
  log "WARNING: restore still running after 600s"
  exit 1
fi
