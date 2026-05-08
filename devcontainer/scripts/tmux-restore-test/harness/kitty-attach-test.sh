#!/usr/bin/env bash
# Runs INSIDE the container as the test user. Invokes tmux-local-attach-main
# in a way that exercises its side effects (group discovery + new-session
# creation + window selection) without requiring a real interactive PTY for
# the final `exec tmux attach-session`.
#
# tmux attach-session without a TTY exits immediately with an error — that's
# fine for our purposes because all the script's side effects (lock,
# new-session, select-window) have already happened by then.
set -uo pipefail

ATTACH_SCRIPT="${ATTACH_SCRIPT:-$HOME/.local/bin/tmux-local-attach-main}"

# Snapshot pre-state
echo "[test] PRE-state:"
tmux list-sessions -F '  #{session_group}|#{session_name}|#{session_windows}|#{session_attached}' 2>/dev/null || true
PRE_SESSIONS=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | sort -u || true)

# Run the script. Use `script` to allocate a PTY so tmux attach doesn't
# bail before doing anything (some tmux builds quit before processing the
# session-creation side effects when stdin isn't a tty). Run in background;
# we just need the side effects.
#
# Important: clear $TMUX so tmux attach doesn't refuse "session in nested
# context". Clear lock-related env. Stay in a clean PWD.
setsid -f script -qc "TMUX= XDG_RUNTIME_DIR='${XDG_RUNTIME_DIR:-/run/user/$(id -u)}' '$ATTACH_SCRIPT'" /dev/null \
  </dev/null >/tmp/attach.out 2>&1 || true

# Give it time to acquire lock, find/create the group, and create the new
# session clone. The exec-tmux-attach at the end may keep running in the
# background but its side effects are already done.
sleep 2.0

echo "[test] POST-state:"
tmux list-sessions -F '  #{session_group}|#{session_name}|#{session_windows}|#{session_attached}' 2>/dev/null || true
POST_SESSIONS=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | sort -u || true)

# Identify the new session that the script just created (added since PRE).
NEW_SESSION=$(comm -13 <(echo "$PRE_SESSIONS") <(echo "$POST_SESSIONS") | head -1)
echo "[test] NEW_SESSION=$NEW_SESSION"
echo "$NEW_SESSION" > /tmp/kitty-attach-new-session

# Capture the script output for debugging.
if [[ -s /tmp/attach.out ]]; then
  echo "[test] script output:"
  sed 's/^/  /' /tmp/attach.out
fi
