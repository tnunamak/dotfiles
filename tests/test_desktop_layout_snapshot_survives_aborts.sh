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
# This test proves BOTH: (a) the currently installed script survives a real
# kscreen-doctor abort and a dead-PID ps query and still writes a manifest,
# and (b) the pre-fix code (commit a0560e7~1) genuinely crashes under the
# identical fixture — so this isn't a strawman reproduction.
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

# kdotool stub: reports exactly one fake kitty window with a PID that does
# NOT correspond to any real process, so the ps-race bug (found while
# building this test) is exercised too, not just the kscreen-doctor abort.
cat >"$FIXTURE_BIN/kdotool" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  search) echo '{fake-window-1}' ;;
  getwindowpid) echo 99999 ;;
  get_desktop_for_window) echo 1 ;;
  getwindowgeometry) printf 'Window {fake-window-1}\n  Position: 0,0\n  Geometry: 100x100\n' ;;
  getwindowname) echo 'fake' ;;
  *) exit 0 ;;
esac
EOF
chmod +x "$FIXTURE_BIN/kdotool"

run_isolated() {
  local script="$1" statedir="$2"
  mkdir -p "$statedir"
  env -i \
    HOME="$HOME" \
    PATH="$FIXTURE_BIN:/usr/bin:/bin" \
    XDG_STATE_HOME="$statedir" \
    DESKTOP_LAYOUT_TMUX_CLIENTS='' \
    bash "$script"
}

set +e
run_isolated "$SNAPSHOT" "$WORK/state-current" >"$WORK/current.log" 2>&1
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
run_isolated "$OLD_SNAPSHOT" "$WORK/state-old" >"$WORK/old.log" 2>&1
old_rc=$?
set -e
old_manifest="$WORK/state-old/desktop-layout/manifest.json"
[[ "$old_rc" -ne 0 && ! -s "$old_manifest" ]] || \
  fail "pre-fix script did NOT crash under the identical fixture (rc=$old_rc) — reproduction doesn't isolate the bug"

echo 'PASS: desktop-layout-snapshot survives a kscreen-doctor abort and a dead-PID ps race; pre-fix code genuinely crashes under the same fixture'
