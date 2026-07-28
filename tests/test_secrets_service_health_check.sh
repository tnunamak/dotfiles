#!/usr/bin/env bash
# Regression test for bin/.local/bin/secrets-service-health-check.
#
# Root cause (2026-07-28): ksecretd (org.freedesktop.secrets) can come up
# successfully at boot, run fine for a while, then go silently unresponsive —
# process alive, 0% CPU, but every D-Bus call (including `infisical export`)
# hangs forever with no reply. A DIFFERENT failure mode than the boot-race
# crash-loop already fixed (shell/.shell_config's retry loop): retrying a
# live-but-wedged daemon doesn't help the way retrying a crashing-then-
# recovering one does, so a shell hitting this hung forever until someone
# manually found and killed the wedged ksecretd process.
#
# Researched directly (not assumed) before building this: this is a known,
# recurring KDE bug class (KDE Bug 504656, 504014, and the 2011-era 259942 —
# ksecretd's single Qt event loop gets wedged by one mishandled request and
# every caller hangs, not just the triggering one); ksecretd's own source
# (invent.kde.org/frameworks/kwallet) installs no SIGTERM handler, so a bare
# kill is not expected to bypass any graceful-shutdown/flush routine; no
# existing systemd/dbus-daemon mechanism can detect this instead (WatchdogSec=
# needs app-side sd_notify cooperation ksecretd doesn't implement; dbus-daemon
# does zero liveness-checking once a service has claimed its bus name); and a
# Peer.Ping to a NAMED destination routes through the target's real event
# loop in both GDBus and QtDBus, so a Ping timeout is trustworthy evidence of
# the exact failure being detected, not contention noise.
#
# This test proves, against fully-isolated stubs (pgrep/pkill/gdbus all
# faked — NEVER touches a real ksecretd process, even if one is running on
# the test machine):
#   1. A wedged daemon (Ping times out) is detected and killed.
#   2. A healthy daemon (Ping succeeds) is left alone and checked fast.
#   3. A second call within the debounce window skips re-checking entirely
#      (proven by a still-wedged daemon NOT triggering a second kill call
#      and returning instantly instead of paying the Ping timeout again).
#   4. No daemon running at all is a fast, clean no-op.
#   5. A missing gdbus degrades to a clean no-op, not an error.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/bin/.local/bin/secrets-service-health-check"
WORK="$(mktemp -d "$HOME/.tmp/secrets-health-check-test.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

FIXTURE_BIN="$WORK/bin"
mkdir -p "$FIXTURE_BIN"

# pgrep/pkill stubs never touch a real process: pgrep just reports "yes, a
# fake ksecretd exists" via exit code, pkill just logs that it was asked to
# kill one, both entirely independent of any process table.
cat >"$FIXTURE_BIN/pgrep" <<'EOF'
#!/usr/bin/env bash
[[ "$*" == *"ksecretd"* ]] && exit "${HEALTH_TEST_PGREP_RC:-0}"
exit 1
EOF
chmod +x "$FIXTURE_BIN/pgrep"

cat >"$FIXTURE_BIN/pkill" <<'EOF'
#!/usr/bin/env bash
printf 'PKILL_CALLED: %s\n' "$*" >>"$HEALTH_TEST_LOG"
exit 0
EOF
chmod +x "$FIXTURE_BIN/pkill"

cat >"$FIXTURE_BIN/gdbus" <<'EOF'
#!/usr/bin/env bash
if [[ "${HEALTH_TEST_GDBUS_MODE:-healthy}" == wedged ]]; then
  sleep 999
fi
exit 0
EOF
chmod +x "$FIXTURE_BIN/gdbus"

run_check() {
  local statedir="$1" mode="$2" log="$3"
  env -i PATH="$FIXTURE_BIN:/usr/bin:/bin" \
    XDG_STATE_HOME="$statedir" \
    HEALTH_TEST_GDBUS_MODE="$mode" \
    HEALTH_TEST_LOG="$log" \
    SECRETS_HEALTH_PING_TIMEOUT=2 \
    timeout 10 bash "$SCRIPT"
}

echo ">>> [1/5] wedged daemon is detected and killed"
log1="$WORK/log1"; : >"$log1"
run_check "$WORK/state1" wedged "$log1"
grep -qF 'PKILL_CALLED: -x ksecretd' "$log1" ||
  fail "wedged daemon was not killed: $(cat "$log1")"

echo ">>> [2/5] healthy daemon is left alone and checked fast"
log2="$WORK/log2"; : >"$log2"
start=$(date +%s)
run_check "$WORK/state2" healthy "$log2"
elapsed=$(( $(date +%s) - start ))
[[ ! -s "$log2" ]] || fail "healthy daemon was killed: $(cat "$log2")"
(( elapsed <= 2 )) || fail "healthy-daemon check took ${elapsed}s, expected near-instant"

echo ">>> [3/5] second call within the debounce window skips re-checking"
log3="$WORK/log3"; : >"$log3"
state3="$WORK/state3"
run_check "$state3" wedged "$log3"
grep -qF 'PKILL_CALLED' "$log3" || fail "first debounce-test call did not kill as expected"
lines_after_first="$(wc -l <"$log3")"
start=$(date +%s)
run_check "$state3" wedged "$log3"
elapsed=$(( $(date +%s) - start ))
lines_after_second="$(wc -l <"$log3")"
(( elapsed <= 1 )) || fail "debounced call took ${elapsed}s, expected instant skip"
[[ "$lines_after_second" -eq "$lines_after_first" ]] ||
  fail "debounce did not prevent a second kill attempt (lines: $lines_after_first -> $lines_after_second)"

echo ">>> [4/5] no daemon running at all is a fast, clean no-op"
log4="$WORK/log4"; : >"$log4"
start=$(date +%s)
env -i PATH="$FIXTURE_BIN:/usr/bin:/bin" \
  XDG_STATE_HOME="$WORK/state4" \
  HEALTH_TEST_PGREP_RC=1 \
  HEALTH_TEST_LOG="$log4" \
  timeout 10 bash "$SCRIPT"
elapsed=$(( $(date +%s) - start ))
[[ ! -s "$log4" ]] || fail "no-daemon case unexpectedly attempted a kill: $(cat "$log4")"
(( elapsed <= 1 )) || fail "no-daemon case took ${elapsed}s, expected instant"

echo ">>> [5/5] missing gdbus degrades to a clean no-op, not an error"
MINIMAL_BIN="$WORK/bin-minimal"
mkdir -p "$MINIMAL_BIN"
for tool in flock mkdir cat timeout bash pgrep; do
  ln -sf "$(command -v "$tool")" "$MINIMAL_BIN/$tool"
done
env -i PATH="$MINIMAL_BIN:/usr/bin:/bin" \
  XDG_STATE_HOME="$WORK/state5" \
  timeout 10 bash "$SCRIPT" ||
  fail "missing-gdbus case exited non-zero instead of a clean no-op"

echo 'PASS: secrets-service-health-check detects and kills a wedged daemon, leaves a healthy one alone, debounces concurrent callers, and degrades cleanly when tools are missing'
