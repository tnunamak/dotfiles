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

echo ""
echo "===================="
echo "PASS=$PASS FAIL=$FAIL"
echo "===================="
[[ "$FAIL" == "0" ]] && exit 0 || exit 1
