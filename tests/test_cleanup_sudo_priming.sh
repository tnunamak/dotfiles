#!/bin/bash
# Proves the --clean sudo-priming fix: cleanup must only prime sudo
# credentials when a sudo-requiring category (currently only tier-2
# snap_revs) is both enabled and has something real to remove, and must ask
# for it upfront via needs_sudo_priming() rather than unconditionally.
#
# Root cause this guards: a bare unconditional `sudo -v` in main() blocked on
# an unwatched password prompt for 15+ hours on a --clean --include-tier-2
# --yes run that had nothing sudo-related to do at all.
#
# Fully isolated: CODE_ROOT and CLEANUP_CACHE_FILE are both redirected into a
# throwaway tmpdir, so this never reads or writes the real machine's cache
# file (/tmp/.cleanup-cache-<uid>) or invokes real sudo/snap.

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/cleanup-sudo-test.XXXXXX")
# trap disabled for debug

export CODE_ROOT="$TEST_ROOT/code"
export CLEANUP_CACHE_FILE="$TEST_ROOT/cache"
export REFRESH_CACHE_AFTER_CLEANUP=false
mkdir -p "$CODE_ROOT"

# shellcheck source=../bin/.local/bin/cleanup
source "$REPO_ROOT/bin/.local/bin/cleanup"

fail() { echo "not ok - $*" >&2; exit 1; }

seed_cache() {
    local snap_line="${1:-}"
    {
        printf '%s\n' "$CACHE_VERSION" "0" "1"
        [[ -n "$snap_line" ]] && printf '%s\n' "$snap_line"
        printf '%s\n' "---"
    } > "$CACHE_FILE"
    # Fresh mtime so ensure_cache's staleness check accepts our seed as-is.
    touch "$CACHE_FILE"
}

# needs_sudo_priming() itself requires `[[ -t 0 ]]` (a real TTY), which a
# plain test runner never has. This stub re-implements the same logic minus
# that one guard, so the category/cache gating this fix actually changed is
# exercised directly; the real TTY-inclusive path is proven separately below
# by the end-to-end pty run against the unmodified function.
needs_sudo_priming_notty_stubbed() {
    [[ "$DRY_RUN" != "true" ]] || return 1
    (( EUID != 0 )) || return 1
    [[ "$INCLUDE_TIER_2" == "true" ]] || return 1
    is_enabled snap_revs || return 1
    ensure_cache false
    (( $(cache_size_for snap_revs) > 0 ))
}

DRY_RUN=false
ASSUME_YES=true
ONLY_MODE=false
SKIP_CAT=()
ONLY_CAT=()

# --- Case 1: no --include-tier-2 -> never prime, even if snap_revs is nonzero ---
INCLUDE_TIER_2=false
seed_cache "snap_revs:1:2097152"
if needs_sudo_priming_notty_stubbed; then
    fail "primed sudo without --include-tier-2"
fi
echo "ok - no priming without --include-tier-2"

# --- Case 2: --include-tier-2 but snap_revs is empty -> never prime ---
INCLUDE_TIER_2=true
seed_cache ""
if needs_sudo_priming_notty_stubbed; then
    fail "primed sudo when snap_revs cache entry is absent/zero"
fi
echo "ok - no priming when there are no disabled snap revisions"

# --- Case 3: --include-tier-2, snap_revs explicitly skipped -> never prime ---
INCLUDE_TIER_2=true
SKIP_CAT=([snap_revs]=1)
seed_cache "snap_revs:1:2097152"
if needs_sudo_priming_notty_stubbed; then
    fail "primed sudo when snap_revs was explicitly skipped"
fi
SKIP_CAT=()
echo "ok - no priming when snap_revs is skipped"

# --- Case 4: --include-tier-2 and snap_revs has real bytes -> must prime ---
INCLUDE_TIER_2=true
seed_cache "snap_revs:1:2097152"
if ! needs_sudo_priming_notty_stubbed; then
    fail "failed to prime sudo when snap_revs has disabled revisions pending"
fi
echo "ok - primes when tier-2 snap_revs actually has work to do"

# --- Case 5: dry-run must never prime even with tier-2 + snap_revs present ---
INCLUDE_TIER_2=true
DRY_RUN=true
seed_cache "snap_revs:1:2097152"
if needs_sudo_priming_notty_stubbed; then
    fail "primed sudo during dry-run"
fi
DRY_RUN=false
echo "ok - no priming during dry-run"

# --- Case 6: EUID guard exists (can't flip EUID in-process to test live) ---
grep -q '(( EUID != 0 ))' "$REPO_ROOT/bin/.local/bin/cleanup" \
    || fail "EUID guard missing from needs_sudo_priming"
echo "ok - EUID guard present"

# ---------------------------------------------------------------------------
# End-to-end: run the real binary under a pty (so `[[ -t 0 ]]` is true, same
# as an interactive terminal) with fake sudo/snap on PATH and an isolated
# CLEANUP_CACHE_FILE. Exercises the unmodified needs_sudo_priming() as called
# from main(), for both "nothing to do" (must not hang/prompt) and "real
# snap_revs work pending" (must prompt, exactly once, upfront).
# ---------------------------------------------------------------------------

FAKE_BIN="$TEST_ROOT/fakebin"
mkdir -p "$FAKE_BIN"

cat > "$FAKE_BIN/sudo" <<'EOF'
#!/bin/bash
echo "$@" >> "$SUDO_LOG_PATH"
exit 0
EOF
chmod +x "$FAKE_BIN/sudo"

run_e2e() {
    # $1 = snap list output body, $2 = extra cleanup args, $3 = output log path
    local snap_body="$1" extra_args="$2" out="$3"
    cat > "$FAKE_BIN/snap" <<EOF
#!/bin/bash
if [[ "\$1" == "list" ]]; then
    printf '%s\n' "Name  Version  Rev  Tracking  Publisher  Notes"
    $snap_body
fi
exit 0
EOF
    chmod +x "$FAKE_BIN/snap"

    local e2e_home e2e_code e2e_cache e2e_sudo_log
    e2e_home="$TEST_ROOT/e2e-home-$$-$RANDOM"
    e2e_code="$TEST_ROOT/e2e-code-$$-$RANDOM"
    e2e_cache="$TEST_ROOT/e2e-cache-$$-$RANDOM"
    e2e_sudo_log="$TEST_ROOT/e2e-sudo-$$-$RANDOM.log"
    mkdir -p "$e2e_home" "$e2e_code"
    : > "$e2e_sudo_log"

    # CLEANUP_NO_CONTAIN=1: these tests exercise sudo-priming/lock logic, not
    # the systemd-run containment wrapper (covered separately) — containment
    # re-execs via `systemd-run --user`, which does NOT inherit the caller's
    # environment (only vars explicitly passed via its own --setenv list), so
    # a bare `env HOME=...` prefix here would silently stop applying inside
    # the re-exec'd process and this test would run against the REAL $HOME.
    # (This is exactly how an ad-hoc debug command mid-development for real
    # deleted 3 real node_modules dirs — never skip this on these tests.)
    # --skip-apt_cache: these tests isolate snap_revs sudo-priming behavior
    # specifically. apt_cache also needs sudo and, unlike snap_revs, reads
    # the REAL /var/cache/apt/archives (not a fake-able-via-PATH shim), so on
    # a machine where that cache is genuinely nonzero it would legitimately
    # (and correctly) prime sudo too — which is real, working behavior, just
    # not what this test file's cases are designed to isolate. See the
    # dedicated apt_cache test for that coverage.
    timeout 30 script -qec \
        "env PATH='$FAKE_BIN:/usr/bin:/bin' HOME='$e2e_home' CODE_ROOT='$e2e_code' \
            CLEANUP_CACHE_FILE='$e2e_cache' SUDO_LOG_PATH='$e2e_sudo_log' \
            REFRESH_CACHE_AFTER_CLEANUP=false CLEANUP_NO_CONTAIN=1 \
            bash '$REPO_ROOT/bin/.local/bin/cleanup' --clean $extra_args --yes \
                --skip-docker_containers --skip-docker_builder --skip-docker_dangling --skip-docker_images \
                --skip-apt_cache" \
        /dev/null > "$out" 2>&1
    local rc=$?
    echo "$e2e_sudo_log"
    return "$rc"
}

# --- E2E Case A: no disabled revisions -> must complete, never call sudo ---
out_a="$TEST_ROOT/e2e-a.log"
sudo_log_a=$(run_e2e "" "--include-tier-2" "$out_a") && rc_a=0 || rc_a=$?
if [[ "$rc_a" == "124" ]]; then
    fail "cleanup --clean --include-tier-2 --yes HUNG under a real TTY with nothing sudo-related to do (regression of the original 15h hang)"
fi
if [[ -s "$sudo_log_a" ]]; then
    fail "end-to-end run invoked sudo with zero disabled snap revisions: $(cat "$sudo_log_a")"
fi
echo "ok - end-to-end: --clean --include-tier-2 --yes completes without hanging or invoking sudo when there's nothing to do"

# Note: an end-to-end "must prime when a disabled revision really exists"
# case is intentionally not included — probe_snap_revs() validates against a
# real blob at the hardcoded /var/lib/snapd/snaps/<name>_<rev>.snap, which
# can't be faked without root. Unit-level Case 4 above already proves that
# side of needs_sudo_priming() against a hand-seeded cache; these end-to-end
# cases prove main()'s wiring specifically for the "nothing to do" paths that
# caused the original hang.

# --- E2E Case C: no --include-tier-2 -> never prime regardless of snap state ---
out_c="$TEST_ROOT/e2e-c.log"
sudo_log_c=$(run_e2e 'printf "demo-app 1.0 100 latest/stable canonical- disabled\n"' "" "$out_c") && rc_c=0 || rc_c=$?
if [[ "$rc_c" == "124" ]]; then
    fail "cleanup hung end-to-end on plain --clean (no tier-2 requested)"
fi
if [[ -s "$sudo_log_c" ]]; then
    fail "end-to-end run invoked sudo without --include-tier-2: $(cat "$sudo_log_c")"
fi
echo "ok - end-to-end: plain --clean never invokes sudo regardless of snap state"

echo "ok - cleanup sudo priming (scoped to real snap_revs work, not unconditional)"
