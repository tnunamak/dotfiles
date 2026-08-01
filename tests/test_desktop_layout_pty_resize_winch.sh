#!/usr/bin/env bash
# Isolated regression test for the boot-time SIGWINCH loss bug: a Claude/Codex
# TUI resumed via tmux-agent-resume's `setsid --wait <tool> ...` never
# receives SIGWINCH when its pty is resized (by desktop-layout-restore's
# kdotool windowsize call), because setsid moves the child into a new
# session, detaching it from the pty's foreground-process-group signal
# delivery path — even though tmux and the kernel both correctly agree on
# the new size. Root-caused and reproduced (bare pty, real tmux, and the
# real `claude` binary; see investigation notes for full evidence) in
# devcontainer/scripts/sigwinch-repro/.
#
# This test extracts resend_pty_winch_for_tmux_window() LIVE from the real
# script via sed + source <(...), matching the convention in
# devcontainer/scripts/kwin-wayland-test/harness/repro-burst-fixed.sh, so
# it can never silently drift from the actual production fix.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REAL_SCRIPT="$ROOT/bin/.local/bin/desktop-layout-restore"
REAL_TMUX="$(command -v tmux)"
SOCKET="test-desktop-layout-winch-$$"
WORK="$(mktemp -d "${HOME}/.tmp/desktop-layout-pty-winch.XXXXXX")"
LOG="$WORK/winch.log"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
tmux_test() { "$REAL_TMUX" -L "$SOCKET" "$@"; }

cleanup() {
  tmux_test kill-server >/dev/null 2>&1 || true
  rm -rf "$WORK"
}
trap cleanup EXIT

grep -q '^resend_pty_winch_for_tmux_window() {' "$REAL_SCRIPT" \
  || fail "resend_pty_winch_for_tmux_window() not found in $REAL_SCRIPT"

# Import the real function, but rebind `tmux` to our isolated socket instead
# of trusting PATH — the production function calls the bare `tmux` command,
# which must resolve to our test server here, never the default socket.
tmux() { tmux_test "$@"; }
source <(sed -n '/^resend_pty_winch_for_tmux_window() {/,/^}/p' "$REAL_SCRIPT")

# A minimal stand-in for winch_probe: logs one line at start (with the pty
# size it sees) and one line per SIGWINCH received.
probe="$WORK/probe.py"
cat >"$probe" <<'PY'
import sys, os, signal, fcntl, struct, termios, time
log = sys.argv[1]
def size():
    try:
        buf = fcntl.ioctl(sys.stdin.fileno(), termios.TIOCGWINSZ, b'\0'*8)
        r, c, _, _ = struct.unpack('HHHH', buf)
        return f"{c}x{r}"
    except OSError:
        return "?"
def write(msg):
    with open(log, 'a') as f:
        f.write(msg + "\n")
count = 0
def on_winch(signum, frame):
    global count
    count += 1
    write(f"WINCH {count} {size()}")
signal.signal(signal.SIGWINCH, on_winch)
write(f"START {size()}")
for _ in range(50):
    time.sleep(0.1)
PY

command -v python3 >/dev/null || fail 'python3 is required for this test'

# Session named "main" (canonical group name — resend_pty_winch_for_tmux_window
# accepts "main" or "main-N", matching tmux-local-attach-main's discovery).
tmux_test new-session -d -s main -x 80 -y 24
tmux_test send-keys -t main "exec setsid --wait python3 '$probe' '$LOG'" Enter
for _ in $(seq 1 50); do
  [[ -f "$LOG" ]] && grep -q '^START' "$LOG" && break
  sleep 0.1
done
[[ -f "$LOG" ]] && grep -q '^START' "$LOG" || fail 'probe did not start'

# Baseline: prove the bug exists absent the fix — resize under setsid alone
# never delivers WINCH.
tmux_test resize-window -t main -x 160 -y 50
sleep 1
grep -q '^WINCH' "$LOG" && fail 'baseline unexpectedly received WINCH (bug may already be fixed elsewhere, or setsid behavior differs on this system)'

# Apply the fix and confirm it closes the gap for a real setsid-wrapped
# process, resolved purely from the tmux window index (idx=0), exactly as
# desktop-layout-restore calls it after resize_and_verify.
resend_pty_winch_for_tmux_window 0 || fail 'resend_pty_winch_for_tmux_window reported failure'
sleep 0.5
grep -q '^WINCH 1' "$LOG" || fail 'fix did not deliver SIGWINCH to the setsid-wrapped process'

# Idempotence / no-crash when there is no setsid process yet (e.g. the resume
# hook has not dispatched the agent at the time desktop-layout-restore's
# first pass runs) — the real script treats this as a soft no-op via `|| true`.
tmux_test new-window -t main -n plainshell
if resend_pty_winch_for_tmux_window 1; then
  fail 'resend_pty_winch_for_tmux_window unexpectedly succeeded against a plain shell pane'
fi

printf 'PASS: desktop-layout-restore resends SIGWINCH to setsid-wrapped resumed agents on isolated socket %s\n' "$SOCKET"
