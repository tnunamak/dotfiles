#!/usr/bin/env bash
# Runs INSIDE the container as the test user AFTER restart. Verifies the
# restore actually happened. Emits PASS/FAIL lines; exit 0 only if everything
# passes.
set -uo pipefail

EXPECTED_WINDOWS="${EXPECTED_WINDOWS:-8}"
# EXPECTED_ASSISTANTS=N asserts that the assistant-sessions JSON has at least N
# sessions AND that all pane addresses use the canonical session name (no
# 'main-N:' grouped-clone names). 0 = skip the assistant-restore checks.
EXPECTED_ASSISTANTS="${EXPECTED_ASSISTANTS:-0}"
# CHECK_PATCH_PRESENT=1 asserts the assistant-resurrect plugin file contains
# both patches (canonicalize + --resume regex). Used by durability scenarios
# to confirm tmux-restore.service's ExecStartPre re-applied them.
CHECK_PATCH_PRESENT="${CHECK_PATCH_PRESENT:-0}"
# CHECK_CAPTURE_SKIP=1 asserts Patch 3 worked: the pane_contents.tar.gz produced
# by populate's pre-crash save contains NO assistant pane entries (they were
# skipped at capture time) but DOES contain plain-pane entries, and the save
# left no leaked /tmp/tmp.* dirs. The archive is staged by populate-state.sh at
# $RESURRECT_DIR/capture-test-archive.tar.gz (the live one is consumed by the
# crash simulation).
CHECK_CAPTURE_SKIP="${CHECK_CAPTURE_SKIP:-0}"
CHECK_DOUBLE_SAVE="${CHECK_DOUBLE_SAVE:-0}"
CHECK_KEEP_LAST="${CHECK_KEEP_LAST:-0}"
RESURRECT_DIR="$HOME/.tmux/resurrect"
PASS=0
FAIL=0
fail() { echo "FAIL: $*"; FAIL=$((FAIL+1)); }
pass() { echo "PASS: $*"; PASS=$((PASS+1)); }

# Wait for tmux-restore.service to settle
for _ in $(seq 1 40); do
  state="$(systemctl --user show -p ActiveState --value tmux-restore.service 2>/dev/null)"
  [[ "$state" == "active" || "$state" == "inactive" || "$state" == "failed" ]] && break
  sleep 0.5
done

# --- Check 1: tmux-restore.service didn't fail catastrophically ---
RESULT="$(systemctl --user show -p Result --value tmux-restore.service 2>/dev/null)"
EXIT_CODE="$(systemctl --user show -p ExecMainStatus --value tmux-restore.service 2>/dev/null)"
echo "tmux-restore.service: result=$RESULT exit=$EXIT_CODE"
if [[ "$RESULT" == "success" ]]; then
  pass "tmux-restore.service exited cleanly"
else
  fail "tmux-restore.service result=$RESULT exit=$EXIT_CODE"
fi

# --- Check 2: no SIGPIPE in the journal for tmux-restore.service ---
journal_out="$(journalctl --user -u tmux-restore.service --no-pager 2>/dev/null)"
if echo "$journal_out" | grep -q "Broken pipe"; then
  fail "Broken pipe in tmux-restore.service journal"
  echo "--- journal excerpt ---"
  echo "$journal_out" | grep -B2 -A2 "Broken pipe" | head -10
else
  pass "no Broken pipe in tmux-restore.service journal"
fi

# --- Check 3: systemd-restore.log shows successful run ---
LOG="$RESURRECT_DIR/systemd-restore.log"
if [[ -f "$LOG" ]]; then
  last_invocation_line=$(grep -n "systemd-restore.sh invoked" "$LOG" | tail -1 | cut -d: -f1)
  if [[ -n "$last_invocation_line" ]]; then
    tail -n +"$last_invocation_line" "$LOG" > /tmp/last-invocation.log
    if grep -q "restore complete; sentinel written" /tmp/last-invocation.log; then
      pass "systemd-restore.log shows 'restore complete'"
    elif grep -q "tmux already has .* panes — skipping" /tmp/last-invocation.log; then
      pass "systemd-restore.log shows live-state skip (acceptable)"
    elif grep -q "save has only .* panes — nothing worth restoring" /tmp/last-invocation.log; then
      fail "systemd-restore.log shows save was rejected as too small"
    elif grep -q "no usable fallback save\|no resurrect save to restore" /tmp/last-invocation.log; then
      fail "systemd-restore.log shows no save was available"
    elif grep -q "running restore via tmux run-shell" /tmp/last-invocation.log; then
      fail "systemd-restore.log shows restore started but no sentinel"
    else
      fail "systemd-restore.log has no recognizable outcome:"
      cat /tmp/last-invocation.log
    fi
  else
    fail "systemd-restore.log has no 'invoked' line"
  fi
else
  fail "systemd-restore.log missing"
fi

# --- Check 4: last symlink is valid ---
if [[ -L "$RESURRECT_DIR/last" && -f "$RESURRECT_DIR/last" ]]; then
  pass "last symlink valid"
else
  fail "last symlink missing or dangling: $(readlink "$RESURRECT_DIR/last" 2>&1)"
fi

# --- Check 5: tmux session has the expected window count ---
# Note: restore is non-destructive; if a session already exists, restore adds
# missing windows. We expect at least EXPECTED_WINDOWS.
actual=$(tmux list-windows -t main 2>/dev/null | wc -l)
echo "main session windows: $actual (expected ≥ $EXPECTED_WINDOWS)"
if (( actual >= EXPECTED_WINDOWS )); then
  pass "main has $actual windows (>= $EXPECTED_WINDOWS)"
else
  fail "main has $actual windows (< $EXPECTED_WINDOWS)"
fi

# --- Check 6 (optional): assistant sessions restored cleanly ---
# Validates two things: (a) the JSON exists with at least N entries, and
# (b) the assistant-restore.log shows ≥1 successful restore (i.e., the pane
# addresses in JSON resolved to actual panes after the restart). The classic
# bug we're catching: JSON has entries but they reference 'main-0:N.0'
# (ephemeral grouped clone names), which after reboot don't exist anymore,
# so the plugin restores 0 of N.
if (( EXPECTED_ASSISTANTS > 0 )); then
  JSON="$RESURRECT_DIR/assistant-sessions.json"
  if [[ ! -f "$JSON" ]]; then
    fail "assistant-sessions.json missing"
  else
    count=$(jq '.sessions | length' "$JSON" 2>/dev/null || echo 0)
    echo "assistant-sessions.json has $count entries (expected ≥ $EXPECTED_ASSISTANTS)"
    if (( count >= EXPECTED_ASSISTANTS )); then
      pass "assistant-sessions.json has $count entries"
    else
      fail "assistant-sessions.json has only $count entries (< $EXPECTED_ASSISTANTS)"
    fi
    # Reject pane addresses that reference grouped clones — the canonical
    # name only bug. With the patch, every pane should use 'main:' (not
    # 'main-0:', 'main-1:', etc.).
    bad=$(jq -r '.sessions[] | .pane' "$JSON" 2>/dev/null | grep -E '^main-[0-9]+:' | sort -u)
    if [[ -n "$bad" ]]; then
      fail "assistant-sessions.json contains grouped-clone pane addresses (canonicalize patch missing?):"
      echo "$bad" | sed 's/^/    /'
    else
      pass "assistant-sessions.json uses canonical session names"
    fi
    # Reject duplicate (pane, session_id) pairs. Without the dedup patch,
    # canonicalization rewrites every grouped-clone entry to the same 'main:'
    # name, producing N copies per pane. Restore then runs the resume command
    # N times — heavy load for nothing.
    total=$(jq '.sessions | length' "$JSON" 2>/dev/null || echo 0)
    unique=$(jq -r '.sessions[] | "\(.pane)|\(.session_id)"' "$JSON" 2>/dev/null | sort -u | wc -l)
    if (( total > unique )); then
      fail "assistant-sessions.json has $total entries but only $unique unique (pane, session_id) — dedup patch missing"
    else
      pass "assistant-sessions.json has no duplicate entries"
    fi
  fi

  # Check the restore log for "restored N of N" success
  AR_LOG="$RESURRECT_DIR/assistant-restore.log"
  if [[ -f "$AR_LOG" ]]; then
    last_restore=$(grep "restored .* of .* assistant session" "$AR_LOG" | tail -1)
    echo "assistant-restore last line: $last_restore"
    if echo "$last_restore" | grep -qE 'restored 0 of [1-9]'; then
      fail "assistant-restore restored 0 of N (pane addresses didn't resolve)"
    elif echo "$last_restore" | grep -qE 'restored [1-9][0-9]* of'; then
      pass "assistant-restore restored ≥1 sessions"
    elif echo "$last_restore" | grep -qE 'restored 0 of 0'; then
      fail "assistant-restore restored 0 of 0 (JSON was empty?)"
    else
      fail "assistant-restore log has no recognizable outcome"
    fi
  else
    fail "assistant-restore.log missing"
  fi
fi

# --- Check 7 (optional): patch is present in assistant-resurrect plugin ---
# Used by durability scenarios that wipe the patch pre-crash to confirm
# tmux-restore.service's ExecStartPre re-applied it on boot.
if (( CHECK_PATCH_PRESENT )); then
  PLUGIN_FILE="$HOME/.tmux/plugins/tmux-assistant-resurrect/scripts/save-assistant-sessions.sh"
  if [[ ! -f "$PLUGIN_FILE" ]]; then
    fail "plugin file missing"
  elif grep -qF 'session_group=$(tmux display-message -t "$session_name"' "$PLUGIN_FILE"; then
    pass "canonicalize patch present in plugin file"
  else
    fail "canonicalize patch MISSING from plugin file (ExecStartPre didn't re-apply it)"
  fi

  # Trigger a fresh save inside the post-restore tmux server, then verify
  # THAT save also produced canonical addresses. Otherwise we'd only know
  # the pre-crash JSON survived — not that future saves work too.
  echo "triggering post-restore save to validate patch is effective"
  bash "$HOME/.tmux/plugins/tmux-resurrect/scripts/save.sh" >/dev/null 2>&1 || true
  sleep 1
  fresh_bad=$(jq -r '.sessions[] | .pane' "$RESURRECT_DIR/assistant-sessions.json" 2>/dev/null | grep -E '^main-[0-9]+:' | sort -u)
  if [[ -n "$fresh_bad" ]]; then
    fail "post-restore save produced grouped-clone addresses (patch not effective):"
    echo "$fresh_bad" | sed 's/^/    /'
  else
    pass "post-restore save uses canonical session names"
  fi
fi

# --- Check 8 (optional): Patch 3 skips assistant panes at capture time ---
if (( CHECK_CAPTURE_SKIP )); then
  echo "--- capture-skip checks ---"
  ARC="$RESURRECT_DIR/capture-test-archive.tar.gz"
  # The patch must be present for this test to mean anything.
  SAVE_SH="$HOME/.tmux/plugins/tmux-resurrect/scripts/save.sh"
  if grep -qF 'AR-Patch3' "$SAVE_SH"; then
    pass "Patch 3 marker present in tmux-resurrect save.sh"
  else
    fail "Patch 3 marker MISSING from save.sh (patch did not apply)"
  fi

  if [[ ! -f "$ARC" ]]; then
    fail "capture-test archive missing ($ARC) — populate did not stage it"
  else
    entries="$(gzip -dc "$ARC" 2>/dev/null | tar tf - 2>/dev/null | grep 'pane-' | sed 's|.*/pane-||')"
    echo "captured pane entries:"; echo "$entries" | sed 's/^/    /'
    # Extract the actual CONTENT of the archive so we assert on text, not just
    # addresses. The claude stub prints ASSISTANT_TUI_SCROLLBACK_*_marker on
    # start, so the assistant panes have real content that MUST be skipped — a
    # silent stub would be excluded by tmux-resurrect's own empty-pane check and
    # give a false-green. The plain panes echo CAPTURE_MARKER_win_*.
    body="$(gzip -dc "$ARC" 2>/dev/null | tar xfO - 2>/dev/null)"
    # Assistant panes (windows 0,1): NO clone of their address (main:0.0, main:1.0,
    # main-N:0.0, main-N:1.0 across all grouped clones) and no marker text may
    # appear. The grouped-clone case is the one the newline bug regressed on —
    # the content (marker text) check is the robust, address-independent assertion.
    if echo "$entries" | grep -qE '(^|^main-[0-9]+):?0\.0$|(^|^main-[0-9]+):?1\.0$' \
       || echo "$entries" | grep -qE ':0\.0$|:1\.0$' \
       || echo "$body" | grep -q 'ASSISTANT_TUI_SCROLLBACK'; then
      fail "assistant pane content WAS captured (Patch 3 did not skip it)"
      echo "    assistant-addressed entries found:"; echo "$entries" | grep -E ':0\.0$|:1\.0$' | head -5 | sed 's/^/      /'
    else
      pass "assistant pane contents skipped across all grouped clones (address + marker absent)"
    fi
    # Plain panes (windows 2,3): at least one clone address present AND marker text.
    if echo "$entries" | grep -qE ':2\.0$' && echo "$entries" | grep -qE ':3\.0$' \
       && echo "$body" | grep -q 'CAPTURE_MARKER_win_'; then
      pass "non-assistant pane contents preserved (addresses + marker text present)"
    else
      fail "non-assistant pane contents missing (expected window 2 and 3 addresses + marker text)"
    fi
  fi

  # No leaked /tmp/tmp.* dirs from the capture-test save. The count was recorded
  # by populate-state.sh PRE-reboot (the simulated reboot clears /tmp, so we
  # cannot check it here directly).
  LEAK_FILE="$RESURRECT_DIR/capture-test-tmp-leak-count"
  if [[ -f "$LEAK_FILE" ]]; then
    leaked="$(cat "$LEAK_FILE")"
    if [[ "$leaked" == "0" ]]; then
      pass "no leaked /tmp/tmp.* dirs after capture-test save (recorded pre-reboot)"
    else
      fail "$leaked leaked /tmp/tmp.* dir(s) after capture-test save (recorded pre-reboot)"
    fi
  else
    fail "capture-test tmp-leak-count not recorded (populate block did not run)"
  fi
fi

# --- Check 9 (optional): concurrent save.sh invocations are serialized ---
if (( CHECK_DOUBLE_SAVE )); then
  echo "--- double-save race checks ---"
  SAVE_SH="$HOME/.tmux/plugins/tmux-resurrect/scripts/save.sh"
  if grep -qF 'AR-Patch6' "$SAVE_SH"; then
    pass "Patch 6 marker present in tmux-resurrect save.sh"
  else
    fail "Patch 6 marker MISSING from save.sh (save lock did not apply)"
  fi

  SUMMARY="$RESURRECT_DIR/concurrent-save-summary"
  if [[ ! -f "$SUMMARY" ]]; then
    fail "concurrent-save-summary missing"
  else
    cat "$SUMMARY" | sed 's/^/    /'
    # shellcheck disable=SC1090
    source "$SUMMARY"
    if [[ "${rc1:-1}" == "0" && "${rc2:-1}" == "0" ]]; then
      pass "both concurrent save.sh callers exited 0"
    else
      fail "concurrent save.sh callers returned rc1=${rc1:-missing} rc2=${rc2:-missing}"
    fi
    if [[ "${save_count:-0}" == "1" ]]; then
      pass "exactly one live save file was produced"
    else
      fail "expected exactly one live save file, got ${save_count:-missing}"
    fi
    if [[ "${last_valid:-0}" == "1" ]]; then
      pass "last symlink valid after concurrent saves"
    else
      fail "last symlink invalid after concurrent saves (target=${last_target:-missing})"
    fi
    if (( ${last_panes:-0} >= EXPECTED_WINDOWS )); then
      pass "concurrent save target has ${last_panes:-0} panes (>= $EXPECTED_WINDOWS)"
    else
      fail "concurrent save target has ${last_panes:-0} panes (< $EXPECTED_WINDOWS)"
    fi
  fi
fi

# --- Check 10 (optional): native keep-last destroys only attached clones ---
if (( CHECK_KEEP_LAST )); then
  echo "--- keep-last clone checks ---"
  SUMMARY="$RESURRECT_DIR/keep-last-summary"
  if [[ ! -f "$SUMMARY" ]]; then
    fail "keep-last-summary missing"
  else
    cat "$SUMMARY" | sed 's/^/    /'
    # shellcheck disable=SC1090
    source "$SUMMARY"
    if [[ "${clone_options_before:-}" == *keep-last* ]]; then
      pass "production attach script set destroy-unattached=keep-last on clones"
    else
      fail "clone destroy-unattached options did not include keep-last: ${clone_options_before:-missing}"
    fi
    if [[ "${storm_clones_after:-missing}" == "0" ]]; then
      pass "detach storm destroyed all clientless clones"
    else
      fail "detach storm left ${storm_clones_after:-missing} main-N clone(s)"
    fi
    if [[ "${seed_exists_after_storm:-0}" == "1" && "${seed_windows_after_storm:-0}" -ge "$EXPECTED_WINDOWS" ]]; then
      pass "seed main survived detach storm with ${seed_windows_after_storm:-0} windows"
    else
      fail "seed main did not survive intact after storm (exists=${seed_exists_after_storm:-missing}, windows=${seed_windows_after_storm:-missing})"
    fi
    if [[ "${fresh_clone:-}" =~ ^main-[0-9]+$ && "${fresh_clone_option:-}" == "keep-last" && "${fresh_clone_destroyed:-0}" == "1" ]]; then
      pass "subsequent attach created a fresh keep-last clone and it was destroyed on detach"
    else
      fail "subsequent attach result unexpected (clone=${fresh_clone:-missing}, option=${fresh_clone_option:-missing}, destroyed=${fresh_clone_destroyed:-missing})"
    fi
    if [[ "${restore_sessions_pre_hook:-0}" == "2" && "${post_hook_rc:-1}" == "0" && "${restore_sessions_post_hook:-1}" == "0" ]]; then
      pass "restore-created grouped sessions survived until post-restore hook and were killed by it"
    else
      fail "restore grouped-session flow unexpected (pre=${restore_sessions_pre_hook:-missing}, rc=${post_hook_rc:-missing}, post=${restore_sessions_post_hook:-missing})"
    fi
    if [[ "${restore_queue_lines:-0}" -ge "2" ]]; then
      pass "post-restore hook populated restore queue"
    else
      fail "restore queue had ${restore_queue_lines:-missing} entries"
    fi
    if [[ "${queue_clone:-}" =~ ^main-[0-9]+$ && "${queue_attach_window:-missing}" == "2" && "${queue_clone_destroyed:-0}" == "1" ]]; then
      pass "queue attach consumed restored window and clone was destroyed on detach"
    else
      fail "queue attach result unexpected (clone=${queue_clone:-missing}, window=${queue_attach_window:-missing}, destroyed=${queue_clone_destroyed:-missing})"
    fi
  fi
fi

echo ""
echo "===================="
echo "PASS=$PASS FAIL=$FAIL"
echo "===================="
[[ "$FAIL" == "0" ]] && exit 0 || exit 1
