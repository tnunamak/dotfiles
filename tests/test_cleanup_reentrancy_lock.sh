#!/bin/bash
# Proves the --clean re-entrancy guard: a second `cleanup --clean` invocation
# must refuse to start (fail fast, clear message, nonzero exit) while a first
# instance holds the lock, rather than running concurrently.
#
# Root cause this guards: with no lock, 7 orphaned `cleanup --clean
# --include-tier-2 --yes` instances were once found running simultaneously
# (some for 38+ hours), collectively burning 1000+ CPU-minutes before being
# noticed — nothing prevented them from piling up across repeated
# Ctrl-C'd/backgrounded attempts.
#
# Fully isolated: CODE_ROOT, CLEANUP_CACHE_FILE, and CLEANUP_LOCK_FILE are all
# redirected into a throwaway tmpdir, so this never touches the real
# machine's lock file, cache file, or code tree.

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/cleanup-lock-test.XXXXXX")
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() { echo "not ok - $*" >&2; exit 1; }

CODE_ROOT="$TEST_ROOT/code"
CACHE_FILE="$TEST_ROOT/cache"
LOCK_FILE="$TEST_ROOT/lock"
mkdir -p "$CODE_ROOT"

# Seed a fresh, valid tier-1-only cache so do_cleanup's ensure_cache doesn't
# try to rescan (which would need docker/snap on PATH — irrelevant here).
seed_cache() {
    # shellcheck disable=SC2016
    CACHE_VERSION=$(grep -m1 '^CACHE_VERSION=' "$REPO_ROOT/bin/.local/bin/cleanup" | cut -d= -f2)
    printf '%s\n' "$CACHE_VERSION" "0" "0" "---" > "$CACHE_FILE"
    touch "$CACHE_FILE"
}
seed_cache

run_clean() {
    # $1 = output log path. Runs a real subprocess (not sourced) so main()'s
    # flock acquisition is actually exercised.
    #
    # CLEANUP_NO_CONTAIN=1: this test doesn't exercise the systemd-run
    # containment wrapper (covered separately), and containment re-execs via
    # `systemd-run --user`, which does NOT inherit a plain `env VAR=...`
    # prefix — only vars its own --setenv list names. Without this,
    # $CODE_ROOT et al. would silently stop applying if containment ever
    # started triggering here (e.g. after a stdin/stdout-is-a-tty change),
    # running destructively against the REAL $HOME instead of this sandbox.
    # --only-pycache: this test exercises the flock re-entrancy guard, not
    # category behavior, and its seeded cache reporting 0 for every other
    # category was previously the ONLY thing stopping this from running
    # `mise prune -y` / `rm -rf ~/.cache/nvidia` for real against the actual
    # machine (those actions read real $HOME-relative paths, not anything
    # $CODE_ROOT-scoped) — a fragile accident of cache contents, not a real
    # guarantee. --only-pycache makes every other category excluded by
    # construction via is_enabled(), independent of what the cache reports.
    env CODE_ROOT="$CODE_ROOT" CLEANUP_CACHE_FILE="$CACHE_FILE" \
        CLEANUP_LOCK_FILE="$LOCK_FILE" REFRESH_CACHE_AFTER_CLEANUP=false \
        CLEANUP_NO_CONTAIN=1 \
        bash "$REPO_ROOT/bin/.local/bin/cleanup" --clean --yes --only-pycache \
        > "$1" 2>&1 < /dev/null
}

# --- Case 1: while the lock is held, a second invocation must fail fast ---
# Hold the lock directly (simulating an in-flight first instance) rather than
# racing a real backgrounded cleanup process against this test.
exec 210>"$LOCK_FILE"
flock 210

out_blocked="$TEST_ROOT/blocked.log"
if run_clean "$out_blocked"; then
    fail "second --clean succeeded while the lock was held: $(cat "$out_blocked")"
fi
if ! grep -qi "already running" "$out_blocked"; then
    fail "blocked invocation did not print a clear 'already running' message: $(cat "$out_blocked")"
fi
echo "ok - a second --clean refuses to start while the lock is held"

# Release the lock (close fd 210) before the next case.
exec 210>&-

# --- Case 2: once the lock is free, --clean must run normally ---
out_free="$TEST_ROOT/free.log"
if ! run_clean "$out_free"; then
    fail "cleanup --clean failed once the lock was free: $(cat "$out_free")"
fi
if grep -qi "already running" "$out_free"; then
    fail "cleanup --clean reported 'already running' even though the lock was free: $(cat "$out_free")"
fi
echo "ok - --clean runs normally once the lock is free"

# --- Case 3: the lock must not survive as a stale block after the holder exits ---
# (Kernel releases flock on fd close / process exit — this proves the
# end-to-end behavior, not just the man-page claim.)
(
    exec 211>"$LOCK_FILE"
    flock 211
    # Exit without explicitly releasing — simulates a crash/SIGKILL: the
    # kernel closes the fd on process exit regardless of how it ends.
) &
holder_pid=$!
wait "$holder_pid" 2>/dev/null || true

out_after_crash="$TEST_ROOT/after-crash.log"
if ! run_clean "$out_after_crash"; then
    fail "cleanup --clean stayed locked out after the lock holder exited (stale lock): $(cat "$out_after_crash")"
fi
echo "ok - lock does not outlive its holder (no stale-lock hang after holder exits)"

echo "ok - cleanup --clean re-entrancy guard"
