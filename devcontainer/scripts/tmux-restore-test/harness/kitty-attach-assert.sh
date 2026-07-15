#!/usr/bin/env bash
# Runs INSIDE the container as the test user AFTER kitty-attach-test.sh.
# Validates the expected post-state for each scenario.
set -uo pipefail

SCENARIO="${ATTACH_SCENARIO:-kitty-attach-clean-boot}"
PASS=0; FAIL=0
fail() { echo "FAIL: $*"; FAIL=$((FAIL+1)); }
pass() { echo "PASS: $*"; PASS=$((PASS+1)); }

NEW_SESSION="$(cat /tmp/kitty-attach-new-session 2>/dev/null || echo)"

# Common assertions
assert_new_session_exists() {
  if [[ -z "$NEW_SESSION" ]]; then
    fail "no new session was created by tmux-local-attach-main"
    return 1
  fi
  if ! tmux has-session -t "=$NEW_SESSION" 2>/dev/null; then
    fail "new session '$NEW_SESSION' was reported but doesn't exist"
    return 1
  fi
  pass "new session '$NEW_SESSION' exists"
  return 0
}

# Returns the group of the new session.
new_session_group() {
  tmux list-sessions -F '#{session_name}|#{session_group}' 2>/dev/null \
    | awk -F'|' -v s="$NEW_SESSION" '$1==s {print $2}'
}

# Returns the window index the new session is currently viewing.
new_session_window() {
  tmux list-sessions -F '#{session_name}|#{window_index}' 2>/dev/null \
    | awk -F'|' -v s="$NEW_SESSION" '$1==s {print $2}'
}

# Returns # windows in the new session's group.
new_session_window_count() {
  tmux list-windows -t "=$NEW_SESSION" -F '#{window_index}' 2>/dev/null | wc -l
}

# Render the exact production status-left format. Do not strip style directives:
# tmux must parse the complete configured format before it can render a status
# line, so stripping would hide parser regressions in the production value.
new_session_status_left() {
  local format
  format=$(tmux show-options -gv status-left 2>/dev/null)
  tmux display-message -p -t "$NEW_SESSION" "$format" 2>/dev/null
}

assert_grouped_status_label() {
  local group status
  group=$(new_session_group)
  status=$(new_session_status_left)
  if [[ "$status" == "#[fg=#7aa2f7]#[bold][${group} group · view ${NEW_SESSION}] " ]]; then
    pass "status labels shared group '$group' and view '$NEW_SESSION'"
  else
    fail "status does not label group/view identity (status=${status@Q}, group=${group@Q}, view=${NEW_SESSION@Q})"
  fi
}

# Returns the set of window indices viewed by sessions in the new session's
# group OTHER than the new session itself, that are attached.
other_attached_windows() {
  local grp; grp=$(new_session_group)
  tmux list-sessions -F '#{session_group}|#{session_name}|#{session_attached}|#{window_index}' 2>/dev/null \
    | awk -F'|' -v g="$grp" -v me="$NEW_SESSION" '$1==g && $2!=me && $3!="0" {print $4}' \
    | sort -u
}

assert_new_session_in_populated_group() {
  local expected_min_windows="$1"
  local count; count=$(new_session_window_count)
  if (( count >= expected_min_windows )); then
    pass "new session sees $count windows (>= $expected_min_windows)"
  else
    fail "new session only sees $count windows (< $expected_min_windows) — joined wrong group?"
  fi
}

assert_new_session_views_unviewed_window() {
  local target_win; target_win=$(new_session_window)
  local viewed; viewed=$(other_attached_windows)
  if echo "$viewed" | grep -Fxq -- "$target_win"; then
    fail "new session views window $target_win, which is also viewed by another attached session (viewed=$viewed)"
  else
    pass "new session views window $target_win, not viewed by other attached sessions"
  fi
}

assert_new_session_created_new_window() {
  local pre_count="$1"
  local count; count=$(new_session_window_count)
  if (( count > pre_count )); then
    pass "new session group has $count windows (> $pre_count) — new window was created"
  else
    fail "new session group has $count windows (expected > $pre_count) — no new window created"
  fi
}

# --- per-scenario assertions ---
case "$SCENARIO" in
  kitty-attach-clean-boot)
    assert_new_session_exists || exit 1
    grp=$(new_session_group)
    if [[ "$grp" == "main" ]]; then pass "joined group 'main'"; else fail "joined group '$grp', expected 'main'"; fi
    assert_grouped_status_label
    assert_new_session_in_populated_group 5
    assert_new_session_views_unviewed_window
    ;;

  kitty-attach-no-session-named-main)
    assert_new_session_exists || exit 1
    grp=$(new_session_group)
    # Group name should still be `main` (it was named at group creation, no
    # rename of the group itself).
    if [[ "$grp" == "main" ]]; then pass "joined group 'main' (despite no session literally named 'main')"; else fail "joined group '$grp', expected 'main'"; fi
    assert_grouped_status_label
    assert_new_session_in_populated_group 5
    assert_new_session_views_unviewed_window
    ;;

  kitty-attach-group-name-drift)
    assert_new_session_exists || exit 1
    grp=$(new_session_group)
    if [[ "$grp" == "main-10" ]]; then pass "joined drifted group 'main-10'"; else fail "joined group '$grp', expected 'main-10'"; fi
    assert_grouped_status_label
    assert_new_session_in_populated_group 5
    assert_new_session_views_unviewed_window
    ;;

  kitty-attach-multiple-groups)
    assert_new_session_exists || exit 1
    grp=$(new_session_group)
    if [[ "$grp" == "main-10" ]]; then pass "joined populated group 'main-10' (not the empty 'main' group)"; else fail "joined group '$grp', expected 'main-10' (populated)"; fi
    assert_grouped_status_label
    assert_new_session_in_populated_group 11
    assert_new_session_views_unviewed_window
    ;;

  kitty-attach-all-windows-viewed)
    assert_new_session_exists || exit 1
    grp=$(new_session_group)
    if [[ "$grp" == "main" ]]; then pass "joined group 'main'"; else fail "joined group '$grp', expected 'main'"; fi
    assert_grouped_status_label
    # 3 windows pre, expect 4 post
    assert_new_session_created_new_window 3
    assert_new_session_views_unviewed_window
    ;;

  *)
    fail "unknown scenario: $SCENARIO"
    ;;
esac

echo ""
echo "===================="
echo "PASS=$PASS FAIL=$FAIL"
echo "===================="
[[ "$FAIL" == "0" ]] && exit 0 || exit 1
