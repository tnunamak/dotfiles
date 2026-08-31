#!/usr/bin/env bash
# Wraps tmux-assistant-resurrect's save script with three safety guards:
#
# 1. Identity guard: validate each saved provider/PID/session against the live
#    pane process. Any entry without PID-bound identity evidence, or with a
#    provider, PID, or session mismatch, rejects the candidate.
#
# 2. Cliff guard: refuse a zero save or a sudden drop below the configured
#    minimum percent of the previous sidecar. Normal periodic saves use 20%;
#    stop-time saves can export TMUX_RESURRECT_SAVE_MIN_PCT=80.
#
# 3. Rotate a sidecar backup alongside each accepted tmux-resurrect save — so
#    if a bad save slips through (e.g. a legit "no assistants running" moment
#    that's not a crash), we can still recover from the backup dir.
#
# Invoked by post-save-transaction.sh from @resurrect-hook-post-save-layout.
# Chains to the upstream assistant save script.
set -euo pipefail

RESURRECT_DIR="${HOME}/.tmux/resurrect"
OUTPUT_FILE="${RESURRECT_DIR}/assistant-sessions.json"
BACKUP_DIR="${RESURRECT_DIR}/backups"
LOG_FILE="${RESURRECT_DIR}/assistant-save.log"
UPSTREAM_SCRIPT="${HOME}/.tmux/plugins/tmux-assistant-resurrect/scripts/save-assistant-sessions.sh"
BUNDLE_CLI="${HOME}/.config/tmux/scripts/resurrect-transaction-bundle"
IDENTITY_VALIDATOR="${HOME}/.config/tmux/scripts/validate-assistant-session-identities.sh"
CLIFF_THRESHOLD_PCT="${TMUX_RESURRECT_SAVE_MIN_PCT:-20}"

log() {
  local msg="[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [guard] $*"
  echo "$msg" >>"$LOG_FILE"
}

# Snapshot count before upstream runs
old_count=0
if [[ -f "$OUTPUT_FILE" ]]; then
  old_count=$(jq -r '.sessions | length' "$OUTPUT_FILE" 2>/dev/null || echo 0)
fi

# Temporarily redirect the upstream script's output. The upstream script
# hardcodes OUTPUT_FILE="${RESURRECT_DIR}/assistant-sessions.json". We shim
# it by copying the real file aside, letting upstream write to the real
# path, then comparing and moving.
#
# Simpler approach: let upstream write in place, then check. If the check
# fails, restore from a pre-run snapshot.
snapshot=$(mktemp "${OUTPUT_FILE}.snap.XXXXXX")
accepted=1
if [[ -f "$OUTPUT_FILE" ]]; then
  cp "$OUTPUT_FILE" "$snapshot"
fi
trap 'rm -f "$snapshot"' EXIT

rc=0
"$UPSTREAM_SCRIPT" || rc=$?
if (( rc != 0 )); then
  accepted=0
fi

new_count=0
if [[ -f "$OUTPUT_FILE" ]]; then
  new_count=$(jq -r '.sessions | length' "$OUTPUT_FILE" 2>/dev/null || echo 0)
fi

# A count and a hash cannot prove that a sidecar describes the pane that was
# just saved. Reject a provider/PID/session mismatch or PID-unverifiable entry
# before the transaction can copy the sidecar into a new last-good bundle. A
# default Codex launch whose ID is only inferred from cwd history is never
# guessed or written as a recovery identity.
if (( accepted )) && [[ -z "${TMUX_RESURRECT_TEST_SKIP_IDENTITY_VALIDATION:-}" ]]; then
  if ! identity_result="$("$IDENTITY_VALIDATOR" "$OUTPUT_FILE" 2>&1)"; then
    log "IDENTITY GUARD: REFUSING candidate sidecar: $identity_result"
    accepted=0
    if [[ -s "$snapshot" ]]; then
      mv "$snapshot" "$OUTPUT_FILE"
      new_count=$(jq -r '.sessions | length' "$OUTPUT_FILE" 2>/dev/null || echo 0)
    else
      rm -f "$OUTPUT_FILE"
      new_count=0
    fi
  else
    log "$identity_result"
    new_count=$(jq -r '.sessions | length' "$OUTPUT_FILE" 2>/dev/null || echo 0)
  fi
fi

# Guard: reject sudden cliffs, including the original populated-to-zero case.
# Mirror post-save-backup.sh: a new sidecar below 20% of the previous count is
# not trusted, but ordinary decreases (for example 50 -> 40) remain valid.
if (( old_count > 0 && new_count * 100 < old_count * CLIFF_THRESHOLD_PCT )); then
  log "CLIFF GUARD: REFUSING shrink from $old_count to $new_count sessions (below ${CLIFF_THRESHOLD_PCT}% of previous); restoring snapshot"
  accepted=0
  if [[ -s "$snapshot" ]]; then
    mv "$snapshot" "$OUTPUT_FILE"
    new_count=$(jq -r '.sessions | length' "$OUTPUT_FILE" 2>/dev/null || echo 0)
  else
    log "CLIFF GUARD ERROR: snapshot missing; cannot restore previous sidecar"
  fi
else
  rm -f "$snapshot"
fi

# Rotate a timestamped sidecar backup next to tmux-resurrect backups. Only
# back up non-empty saves so we don't waste inodes on zero-session writes.
if (( new_count > 0 )) || (( old_count > 0 && new_count == 0 )); then
  mkdir -p "$BACKUP_DIR"
  # Name matches the exact tmux layout save that triggered this transaction.
  layout_save="${1:-}"
  if [[ -n "$layout_save" && -f "$layout_save" ]]; then
    ts="$(basename "$layout_save" .txt | sed 's/^tmux_resurrect_//')"
    cp "$OUTPUT_FILE" "${BACKUP_DIR}/assistant-sessions-${ts}.json"
  fi

  # Keep the largest as "best"
  best="${BACKUP_DIR}/assistant-sessions-best.json"
  if [[ -f "$best" ]]; then
    best_count=$(jq -r '.sessions | length' "$best" 2>/dev/null || echo 0)
    if (( new_count > best_count )); then
      cp "$OUTPUT_FILE" "$best"
    fi
  else
    cp "$OUTPUT_FILE" "$best"
  fi

  # Keep only the last 10 timestamped backups
  ls -t "${BACKUP_DIR}"/assistant-sessions-2*.json 2>/dev/null | tail -n +11 | xargs -r rm -f || true
fi

# Commit a transaction bundle only when this save invocation has both accepted
# layout and accepted assistant state. This runs after the layout hook has had
# its chance to overwrite a rejected layout cliff in-place, and after this guard
# has either accepted or restored the assistant sidecar.
if [[ -n "${TMUX_RESURRECT_SKIP_BUNDLE_COMMIT:-}" ]]; then
  log "bundle commit: skipped because layout generation was rejected"
elif (( accepted )) && [[ -x "$BUNDLE_CLI" ]]; then
  layout_save="${1:-}"
  if [[ -z "$layout_save" || ! -f "$layout_save" ]]; then
    last_save="$(readlink -f "${RESURRECT_DIR}/last" 2>/dev/null || true)"
    if [[ -n "$last_save" && -f "$last_save" ]]; then
      layout_save="$last_save"
      log "bundle commit: hook arg missing; fell back to last layout $(basename "$layout_save")"
    fi
  fi

  if [[ -n "${layout_save:-}" && -f "$layout_save" && -f "$OUTPUT_FILE" ]]; then
    if bundle_path="$("$BUNDLE_CLI" commit --layout "$layout_save" --assistant "$OUTPUT_FILE" --provenance "tmux resurrect post-save-layout transaction" 2>>"$LOG_FILE")"; then
      log "bundle commit: accepted $(basename "$bundle_path") from layout $(basename "$layout_save") and assistant sessions=$new_count"
    else
      log "bundle commit: rejected or failed for layout $(basename "$layout_save")"
    fi
  else
    log "bundle commit: skipped because accepted layout or assistant sidecar is missing"
  fi
else
  log "bundle commit: skipped because assistant generation was rejected"
fi

exit "$rc"
