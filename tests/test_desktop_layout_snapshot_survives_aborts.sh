#!/usr/bin/env bash
# Regression test: desktop-layout-snapshot must not let a subprocess abort or
# a nonexistent-PID `ps` query kill the whole manifest write.
#
# Root cause (2026-07-27): kscreen-doctor is a Qt/X11 binary that can abort
# outright (exit 134, DrKonqi "Service Crash") instead of failing cleanly
# when invoked from a systemd unit whose display env isn't fully populated
# (same root cause as the ksecretd boot-race in shell/.shell_config). Under
# set -euo pipefail that abort — inside a direct command-substitution
# assignment — silently killed the whole script before it ever reached the
# per-window loop or the manifest write. The manifest was stuck 5 days stale
# in production before this was found: the 2026-07-27 crash then restored
# from that stale layout, and most of its tmux window indices no longer
# matched the freshly-restored tmux session, so 18 of 19 spawned kitty
# windows failed their attach command and exited immediately.
#
# A second, related bug was found while building THIS test: `ps -o tty= -p
# "$pid"` exits non-zero (aborting the script under set -e, no pipe needed)
# if the window's process already exited by the time the per-window loop
# reaches it — a real race (window closing between kdotool enumeration and
# processing), not a test artifact. Both call sites needed `|| true`.
#
# This test proves BOTH fixes independently. The kscreen-doctor control uses
# pre-a0560e7 code plus an alive PID. The ps-race control uses a0560e7 itself
# (screen abort already guarded) plus a guaranteed-dead PID and injected
# screen JSON, so the earlier screen failure cannot hide whether ps was
# reached.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SNAPSHOT="$ROOT/bin/.local/bin/desktop-layout-snapshot"
WORK="$(mktemp -d "$HOME/.tmp/desktop-layout-snapshot-aborts.XXXXXX")"
FIXTURE_BIN="$WORK/bin"
mkdir -p "$FIXTURE_BIN"
trap 'rm -rf "$WORK"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

# kscreen-doctor stub: reproduces the real crash signature (SIGABRT / exit
# 134), matching the Qt platform-plugin-init-failure -> qFatal -> abort()
# path the real binary takes when no display is available yet.
cat >"$FIXTURE_BIN/kscreen-doctor" <<'EOF'
#!/usr/bin/env bash
kill -ABRT $$
EOF
chmod +x "$FIXTURE_BIN/kscreen-doctor"

# kdotool stub: reports exactly one fake kitty window. Tests select an alive
# or guaranteed-dead PID through DESKTOP_LAYOUT_TEST_PID.
cat >"$FIXTURE_BIN/kdotool" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  search) echo '{fake-window-1}' ;;
  getwindowpid) echo "${DESKTOP_LAYOUT_TEST_PID:?missing test PID}" ;;
  get_desktop_for_window) echo 1 ;;
  getwindowgeometry) printf 'Window {fake-window-1}\n  Position: 0,0\n  Geometry: 100x100\n' ;;
  getwindowname) echo 'fake' ;;
  *) exit 0 ;;
esac
EOF
chmod +x "$FIXTURE_BIN/kdotool"

run_isolated() {
  local script="$1" statedir="$2" test_pid="$3" screen_json="${4-}"
  local -a env_args=(
    HOME="$HOME"
    PATH="$FIXTURE_BIN:/usr/bin:/bin"
    XDG_STATE_HOME="$statedir"
    DESKTOP_LAYOUT_TMUX_CLIENTS=
    DESKTOP_LAYOUT_TEST_PID="$test_pid"
  )
  mkdir -p "$statedir"
  [[ -n "$screen_json" ]] &&
    env_args+=(DESKTOP_LAYOUT_SCREEN_JSON="$screen_json")
  env -i "${env_args[@]}" bash "$script"
}

pid_max="$(< /proc/sys/kernel/pid_max)"
dead_pid=$((pid_max + 1))
ps -p "$dead_pid" >/dev/null 2>&1 &&
  fail "chosen dead PID unexpectedly exists: $dead_pid"

set +e
run_isolated "$SNAPSHOT" "$WORK/state-current" "$dead_pid" >"$WORK/current.log" 2>&1
current_rc=$?
set -e
current_manifest="$WORK/state-current/desktop-layout/manifest.json"
[[ "$current_rc" -eq 0 && -s "$current_manifest" ]] || {
  cat "$WORK/current.log" >&2
  fail "currently installed script did not survive kscreen-doctor abort + dead-PID ps query (rc=$current_rc)"
}

OLD_SNAPSHOT="$WORK/old-snapshot"
git -C "$ROOT" show a0560e7~1:bin/.local/bin/desktop-layout-snapshot >"$OLD_SNAPSHOT" 2>/dev/null \
  || fail "could not read pre-fix desktop-layout-snapshot from git history (a0560e7~1)"
chmod +x "$OLD_SNAPSHOT"

set +e
run_isolated "$OLD_SNAPSHOT" "$WORK/state-old-screen" "$$" >"$WORK/old-screen.log" 2>&1
old_screen_rc=$?
set -e
old_screen_manifest="$WORK/state-old-screen/desktop-layout/manifest.json"
[[ "$old_screen_rc" -ne 0 && ! -s "$old_screen_manifest" ]] ||
  fail "pre-a0560e7 script did not crash on kscreen-doctor abort with an alive PID (rc=$old_screen_rc)"

PRE_PS_FIX="$WORK/pre-ps-fix-snapshot"
git -C "$ROOT" show a0560e7:bin/.local/bin/desktop-layout-snapshot >"$PRE_PS_FIX" 2>/dev/null ||
  fail "could not read pre-ps-fix desktop-layout-snapshot from git history (a0560e7)"
chmod +x "$PRE_PS_FIX"

set +e
run_isolated "$PRE_PS_FIX" "$WORK/state-old-ps" "$dead_pid" \
  '{"width":1920,"height":1080}' >"$WORK/old-ps.log" 2>&1
old_ps_rc=$?
set -e
old_ps_manifest="$WORK/state-old-ps/desktop-layout/manifest.json"
[[ "$old_ps_rc" -ne 0 && ! -s "$old_ps_manifest" ]] ||
  fail "a0560e7 script did not crash on the isolated dead-PID ps race (rc=$old_ps_rc)"

echo 'PASS: desktop-layout-snapshot survives both aborts; independent historical controls reproduce kscreen-doctor failure before a0560e7 and the ps race before 1d93cde'
