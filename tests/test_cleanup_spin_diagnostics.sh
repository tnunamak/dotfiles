#!/bin/bash
# Proves the _diag_wait_n / _diag_wait_all diagnostic wrappers added around
# the three throttled fan-out loops (find_stale_node_modules, find_stale_venvs,
# find_stale_project_artifacts) actually detect and log the busy-spin
# signature — added after two real, unexplained hangs where the process was
# confirmed CPU-bound with zero children for 9+ minutes, but run.log had no
# evidence of which loop or call was responsible. Never reproduces those
# specific hangs (which use real find/du/CODE_ROOT scanning); instead proves
# the diagnostic layer itself is sound against a synthetic, deterministic
# repro of the exact underlying mechanism (a stale/reaped pid making `wait
# -n` return instantly forever).

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/cleanup-diag-test.XXXXXX")
trap 'rm -rf "$TEST_ROOT"' EXIT

STATE_DIR="$TEST_ROOT/state"
mkdir -p "$STATE_DIR"

fail() { echo "not ok - $*" >&2; exit 1; }

# --- A normal, fast wait -n (nothing outstanding) must log nothing ---
out=$(env XDG_STATE_HOME="$STATE_DIR/fast" bash -c "
    source '$REPO_ROOT/bin/.local/bin/cleanup'
    sleep 0.05 &
    p=\$!
    _diag_wait_n fast_case \"\$p\"
    wait 2>/dev/null
")
if [[ -f "$STATE_DIR/fast/cleanup/run.log" ]]; then
    fail "a single normal wait -n logged a DIAG line when nothing was wrong: $(cat "$STATE_DIR/fast/cleanup/run.log")"
fi
echo "ok - a normal fast wait -n logs nothing"

# --- A genuinely slow wait -n (>10s) must log a DIAG line ---
env XDG_STATE_HOME="$STATE_DIR/slow" bash -c "
    source '$REPO_ROOT/bin/.local/bin/cleanup'
    sleep 12 &
    p1=\$!
    sleep 13 &
    p2=\$!
    _diag_wait_n slow_case \"\$p1\" \"\$p2\"
    wait 2>/dev/null
" >/dev/null 2>&1
if ! grep -q "DIAG slow_case.*took.*s" "$STATE_DIR/slow/cleanup/run.log" 2>/dev/null; then
    fail "a wait -n that took ~12s did not log a DIAG line: $(cat "$STATE_DIR/slow/cleanup/run.log" 2>/dev/null)"
fi
echo "ok - a slow (>10s) wait -n logs a DIAG line with its duration"

# --- The exact busy-spin mechanism (stale pid -> instant returns forever)
#     must be caught, logged, and RATE-LIMITED (not flooding run.log) ---
env XDG_STATE_HOME="$STATE_DIR/spin" timeout 8 bash -c "
    source '$REPO_ROOT/bin/.local/bin/cleanup'
    sleep 0.01 &
    dead_pid=\$!
    wait \"\$dead_pid\" 2>/dev/null
    while true; do
        _diag_wait_n spin_case \"\$dead_pid\" 99999999
    done
" >/dev/null 2>&1 || true
log_file="$STATE_DIR/spin/cleanup/run.log"
[[ -f "$log_file" ]] || fail "a real busy-spin (stale pid, tight loop) produced no diagnostic log at all"
match_count=$(grep -c "DIAG spin_case.*busy-spin signature" "$log_file" 2>/dev/null || true)
if [[ "$match_count" -lt 1 ]]; then
    fail "busy-spin signature was not detected/logged: $(cat "$log_file")"
fi
if [[ "$match_count" -gt 3 ]]; then
    fail "busy-spin diagnostic flooded run.log instead of rate-limiting ($match_count lines in ~8s of spinning): $(cat "$log_file")"
fi
echo "ok - a real busy-spin (stale pid, tight loop) is detected and logged, rate-limited to a handful of lines, not flooded"

# --- _diag_wait_all: a slow final drain must log; a fast one must not ---
env XDG_STATE_HOME="$STATE_DIR/drain-fast" bash -c "
    source '$REPO_ROOT/bin/.local/bin/cleanup'
    sleep 0.05 &
    _diag_wait_all fast_drain
"
if [[ -f "$STATE_DIR/drain-fast/cleanup/run.log" ]]; then
    fail "a fast final drain logged a DIAG line when nothing was wrong"
fi
echo "ok - a fast final drain (_diag_wait_all) logs nothing"

env XDG_STATE_HOME="$STATE_DIR/drain-slow" bash -c "
    source '$REPO_ROOT/bin/.local/bin/cleanup'
    sleep 16 &
    _diag_wait_all slow_drain
" >/dev/null 2>&1
if ! grep -q "DIAG slow_drain.*final drain wait took" "$STATE_DIR/drain-slow/cleanup/run.log" 2>/dev/null; then
    fail "a slow (>15s) final drain did not log a DIAG line: $(cat "$STATE_DIR/drain-slow/cleanup/run.log" 2>/dev/null)"
fi
echo "ok - a slow (>15s) final drain (_diag_wait_all) logs a DIAG line"

echo "ok - cleanup spin diagnostics"
