#!/usr/bin/env bash
# Runs INSIDE the container as the test user AFTER restart. Verifies the
# restore actually happened. Emits PASS/FAIL lines; exit 0 only if everything
# passes.
set -uo pipefail

EXPECTED_WINDOWS="${EXPECTED_WINDOWS:-8}"
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

echo ""
echo "===================="
echo "PASS=$PASS FAIL=$FAIL"
echo "===================="
[[ "$FAIL" == "0" ]] && exit 0 || exit 1
