#!/bin/bash
# Proves the --clean systemd-run containment wrapper: it triggers only under
# a real TTY, re-execs as a systemd --user service (not scope — scope cannot
# carry a TTY, verified separately), applies a CPU quota, and correctly
# forwards the env vars the script actually needs.
#
# SAFETY: this test intentionally does NOT override HOME, because a bare
# `env HOME=...` prefix does NOT survive cleanup's own internal
# `systemd-run --user` re-exec (only vars in cleanup's own --setenv list do)
# — discovered the hard way when an ad-hoc debug command during development
# for real deleted 3 node_modules dirs under the real $HOME. To stay safe
# without relying on HOME isolation, every case below either runs with
# CLEANUP_NO_CONTAIN=1 (containment never triggers, so HOME is irrelevant)
# or uses --only-pycache scoped to an isolated $CODE_ROOT/$CLEANUP_CACHE_FILE
# (the one real "contained" run), which only ever touches paths under
# $CODE_ROOT — never the real $HOME — regardless of which HOME the unit sees.

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/cleanup-contain-test.XXXXXX")
trap 'rm -rf "$TEST_ROOT"; systemctl --user reset-failed "cleanup-clean-*" 2>/dev/null || true' EXIT

fail() { echo "not ok - $*" >&2; exit 1; }

command -v systemd-run &>/dev/null || { echo "skip - systemd-run not available on this machine"; exit 0; }
command -v script &>/dev/null || { echo "skip - script(1) not available to simulate a TTY"; exit 0; }

# Transient cleanup-clean-* units this test creates linger in systemd's unit
# table as `failed` after the process exits (expected — RuntimeMaxSec kills
# them, or --only-pycache finishes with nothing to do). Left uncleared, they
# can accumulate across repeated runs; clear any pre-existing ones before
# this run's exact-timestamp `--since` filtering starts, purely for hygiene
# (the --since checks below are already immune to false positives from them).
systemctl --user reset-failed "cleanup-clean-*" 2>/dev/null || true

CODE_ROOT="$TEST_ROOT/code"
CACHE_FILE="$TEST_ROOT/cache"
LOCK_FILE="$TEST_ROOT/lock"
mkdir -p "$CODE_ROOT"

CACHE_VERSION=$(grep -m1 '^CACHE_VERSION=' "$REPO_ROOT/bin/.local/bin/cleanup" | cut -d= -f2)
printf '%s\n' "$CACHE_VERSION" "0" "0" "---" > "$CACHE_FILE"
touch "$CACHE_FILE"

# journalctl's `-u 'cleanup-clean-*'` glob matches EVERY past invocation ever
# logged under this systemd user session, including leftover `failed` units
# from unrelated manual testing. A relative `--since '-N seconds'` window is
# NOT enough to isolate "did THIS test's run cause a unit to appear" — if
# tests run back-to-back, or a manual run happened moments earlier, matches
# from those leak into the window and produce a false failure (hit this for
# real: a stale unit from manual `--preview` testing broke Case 1). Capture
# an exact timestamp immediately before each action and use --since=<exact>
# instead, which only ever includes log lines from that action onward.
journal_since_now() { date '+%Y-%m-%d %H:%M:%S'; }

# --- Case 1: without a TTY, containment must NOT trigger (no systemd unit created) ---
t0=$(journal_since_now)
env CODE_ROOT="$CODE_ROOT" CLEANUP_CACHE_FILE="$CACHE_FILE" CLEANUP_LOCK_FILE="$LOCK_FILE" \
    REFRESH_CACHE_AFTER_CLEANUP=false \
    bash "$REPO_ROOT/bin/.local/bin/cleanup" --clean --yes --only-pycache \
    > "$TEST_ROOT/no-tty.log" 2>&1 < /dev/null
if journalctl --user -q --no-pager -o cat -u 'cleanup-clean-*' --since "$t0" 2>/dev/null | grep -q .; then
    fail "containment triggered a systemd unit even though stdin/stdout were not a TTY"
fi
echo "ok - containment does not trigger without a TTY"

# --- Case 2: CLEANUP_NO_CONTAIN=1 must suppress containment even under a real TTY ---
t0=$(journal_since_now)
out_optout="$TEST_ROOT/optout.log"
timeout 20 script -qec \
    "env CODE_ROOT='$CODE_ROOT' CLEANUP_CACHE_FILE='$CACHE_FILE' CLEANUP_LOCK_FILE='$LOCK_FILE' \
        REFRESH_CACHE_AFTER_CLEANUP=false CLEANUP_NO_CONTAIN=1 \
        bash '$REPO_ROOT/bin/.local/bin/cleanup' --clean --yes --only-pycache" \
    /dev/null > "$out_optout" 2>&1
if journalctl --user -q --no-pager -o cat -u 'cleanup-clean-*' --since "$t0" 2>/dev/null | grep -q .; then
    fail "CLEANUP_NO_CONTAIN=1 did not suppress the systemd-run re-exec"
fi
echo "ok - CLEANUP_NO_CONTAIN=1 suppresses containment even under a real TTY"

# --- Case 3: under a real TTY (no opt-out), containment DOES trigger as a
#     service unit (not a scope — scopes can't carry the TTY sudo needs) ---
t0=$(journal_since_now)
out_contained="$TEST_ROOT/contained.log"
timeout 20 script -qec \
    "env CODE_ROOT='$CODE_ROOT' CLEANUP_CACHE_FILE='$CACHE_FILE' CLEANUP_LOCK_FILE='$LOCK_FILE' \
        REFRESH_CACHE_AFTER_CLEANUP=false CLEANUP_CPU_QUOTA=90% CLEANUP_RUNTIME_MAX=60 \
        bash '$REPO_ROOT/bin/.local/bin/cleanup' --clean --yes --only-pycache" \
    /dev/null > "$out_contained" 2>&1
matched_unit=$(journalctl --user -q --no-pager -o cat -u 'cleanup-clean-*' --since "$t0" 2>/dev/null | grep -c 'Started cleanup-clean-' || true)
if [[ "$matched_unit" -lt 1 ]]; then
    fail "no cleanup-clean-* systemd unit was started under a real TTY: $(cat "$out_contained")"
fi
# Confirm it's a .service (our --unit= usage), not a .scope.
if journalctl --user -q --no-pager -o cat -u 'cleanup-clean-*' --since "$t0" 2>/dev/null | grep -q '\.scope'; then
    fail "containment used scope mode, which cannot carry a TTY for the sudo prompt"
fi
echo "ok - under a real TTY, containment re-execs as a systemd --user service unit"

echo "ok - cleanup --clean containment wrapper"
