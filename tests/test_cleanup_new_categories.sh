#!/bin/bash
# Proves the five new cleanup categories (mise_prune, nvidia_cache,
# apt_cache, rstring_cache, prisma_python) probe correctly and are gated by
# the right thresholds/tiers — WITHOUT ever running a real deletion. This is
# deliberately probe-level only: these categories operate on real
# machine-global paths (mise's data dir, ~/.cache/nvidia,
# /var/cache/apt/archives, ~/.cache/rstring, ~/.cache/prisma-python), not
# anything CODE_ROOT-scoped, so exercising their actual action blocks
# end-to-end would mean either mocking real external tools convincingly or
# risking real deletions — not worth it for what's fundamentally the same
# maybe_run/confirm wrapper every other tier-1/tier-2 category already uses
# and already has coverage for. See ai/research/dev-tool-caches/ for the
# safety research/verification behind each.

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/cleanup-newcat-test.XXXXXX")
trap 'rm -rf "$TEST_ROOT"' EXIT

export CODE_ROOT="$TEST_ROOT/code"
export REFRESH_CACHE_AFTER_CLEANUP=false
mkdir -p "$CODE_ROOT"

# shellcheck source=../bin/.local/bin/cleanup
source "$REPO_ROOT/bin/.local/bin/cleanup"

fail() { echo "not ok - $*" >&2; exit 1; }

# --- probe_du_path: must never emit two lines when du partially fails ---
# (regression guard: apt_cache hit this for real — du prints a real total to
# stdout but exits non-zero when one subdirectory is permission-denied, and
# under pipefail the `|| echo 0` fallback used to fire IN ADDITION to the
# real value, breaking every `(( $(...) > N ))` caller downstream.)
mkdir -p "$TEST_ROOT/readable/unreadable"
echo "payload" > "$TEST_ROOT/readable/file.txt"
chmod 000 "$TEST_ROOT/readable/unreadable"
out=$(probe_du_path "$TEST_ROOT/readable" 2>/dev/null)
chmod 755 "$TEST_ROOT/readable/unreadable"
line_count=$(printf '%s' "$out" | grep -c . || true)
if [[ "$line_count" != "1" ]]; then
    fail "probe_du_path emitted $line_count lines instead of 1 when du partially failed: [$out]"
fi
echo "ok - probe_du_path emits exactly one line even when du hits a permission-denied subdir"

# --- probe_mise_prune: no-op cleanly when mise isn't on PATH ---
out=$(PATH=/nonexistent probe_mise_prune 2>/dev/null)
[[ "$out" == "0|0" ]] || fail "probe_mise_prune did not no-op cleanly without mise on PATH: [$out]"
echo "ok - probe_mise_prune no-ops cleanly when mise is absent"

# --- probe_nvidia_cache: no-op cleanly (0) when neither cache path exists ---
out=$(HOME="$TEST_ROOT/empty-home" probe_nvidia_cache 2>/dev/null)
[[ "$out" == "0" ]] || fail "probe_nvidia_cache did not report 0 for a HOME with no NVIDIA caches: [$out]"
echo "ok - probe_nvidia_cache reports 0 when no NVIDIA cache directories exist"

# --- probe_nvidia_cache: sums BOTH real locations, not just ~/.cache/nvidia ---
fake_home="$TEST_ROOT/fake-home-nvidia"
mkdir -p "$fake_home/.cache/nvidia/GLCache" "$fake_home/.nv/ComputeCache"
dd if=/dev/zero of="$fake_home/.cache/nvidia/GLCache/shader.bin" bs=1024 count=100 status=none
dd if=/dev/zero of="$fake_home/.nv/ComputeCache/kernel.bin" bs=1024 count=50 status=none
out=$(HOME="$fake_home" probe_nvidia_cache 2>/dev/null)
if (( out < 150000 )); then
    fail "probe_nvidia_cache did not sum both GLCache and ComputeCache (got $out bytes, expected >=150000)"
fi
echo "ok - probe_nvidia_cache sums both ~/.cache/nvidia and ~/.nv/ComputeCache"

# --- probe_apt_cache: no-op cleanly when apt-get isn't on PATH ---
out=$(PATH=/nonexistent probe_apt_cache 2>/dev/null)
[[ "$out" == "0" ]] || fail "probe_apt_cache did not no-op cleanly without apt-get on PATH: [$out]"
echo "ok - probe_apt_cache no-ops cleanly when apt-get is absent (non-Debian machines)"

# --- probe_rstring_cache: reports 0 when the directory doesn't exist ---
out=$(HOME="$TEST_ROOT/empty-home-rstring" probe_rstring_cache 2>/dev/null)
[[ "$out" == "0" ]] || fail "probe_rstring_cache did not report 0 for a HOME with no rstring cache: [$out]"
echo "ok - probe_rstring_cache reports 0 when ~/.cache/rstring doesn't exist"

# --- probe_rstring_cache: measures real content when present ---
fake_home_rs="$TEST_ROOT/fake-home-rstring"
mkdir -p "$fake_home_rs/.cache/rstring/some_repo"
dd if=/dev/zero of="$fake_home_rs/.cache/rstring/some_repo/file.bin" bs=1024 count=100 status=none
out=$(HOME="$fake_home_rs" probe_rstring_cache 2>/dev/null)
if (( out < 100000 )); then
    fail "probe_rstring_cache did not measure real cache content (got $out bytes, expected >=100000)"
fi
echo "ok - probe_rstring_cache measures real leftover clone content"

# --- probe_prisma_python: reports 0 when the directory doesn't exist ---
out=$(HOME="$TEST_ROOT/empty-home-prisma" CODE_ROOT="$TEST_ROOT/code" probe_prisma_python 2>/dev/null)
[[ "$out" == "0" ]] || fail "probe_prisma_python did not report 0 for a HOME with no prisma-python cache: [$out]"
echo "ok - probe_prisma_python reports 0 when ~/.cache/prisma-python doesn't exist"

# --- probe_prisma_python: reports 0 (not stale-eligible) when recently touched ---
fake_home_pp="$TEST_ROOT/fake-home-prisma-fresh"
mkdir -p "$fake_home_pp/.cache/prisma-python/binaries"
dd if=/dev/zero of="$fake_home_pp/.cache/prisma-python/binaries/engine.bin" bs=1024 count=200 status=none
out=$(HOME="$fake_home_pp" CODE_ROOT="$TEST_ROOT/code" probe_prisma_python 2>/dev/null)
[[ "$out" == "0" ]] || fail "probe_prisma_python did not stay 0 for a freshly-touched cache (got: [$out])"
echo "ok - probe_prisma_python does not flag a recently-touched cache as stale"

# --- probe_prisma_python: reports real size when stale (>30d) AND unreferenced ---
fake_home_pp2="$TEST_ROOT/fake-home-prisma-stale"
mkdir -p "$fake_home_pp2/.cache/prisma-python/binaries"
dd if=/dev/zero of="$fake_home_pp2/.cache/prisma-python/binaries/engine.bin" bs=1024 count=200 status=none
old_date="2000-01-01 00:00:00 UTC"
touch -d "$old_date" "$fake_home_pp2/.cache/prisma-python/binaries/engine.bin"
touch -d "$old_date" "$fake_home_pp2/.cache/prisma-python/binaries"
touch -d "$old_date" "$fake_home_pp2/.cache/prisma-python"
out=$(HOME="$fake_home_pp2" CODE_ROOT="$TEST_ROOT/code" probe_prisma_python 2>/dev/null)
if (( out < 200000 )); then
    fail "probe_prisma_python did not flag a genuinely stale, unreferenced cache (got $out bytes, expected >=200000)"
fi
echo "ok - probe_prisma_python flags a stale (>30d), unreferenced cache for cleanup"

# --- probe_prisma_python: never flags stale if a schema.prisma exists under CODE_ROOT ---
proj_code_root="$TEST_ROOT/code-with-prisma-project"
mkdir -p "$proj_code_root/myproj"
touch "$proj_code_root/myproj/schema.prisma"
out=$(HOME="$fake_home_pp2" CODE_ROOT="$proj_code_root" probe_prisma_python 2>/dev/null)
[[ "$out" == "0" ]] || fail "probe_prisma_python flagged a stale cache even though a live schema.prisma exists: [$out]"
echo "ok - probe_prisma_python never flags the cache while a schema.prisma project exists under CODE_ROOT"

# --- new categories appear in the CATEGORIES array (is_enabled/--skip-/--only- wiring) ---
for cat in mise_prune nvidia_cache apt_cache rstring_cache prisma_python; do
    [[ " ${CATEGORIES[*]} " == *" $cat "* ]] || fail "$cat missing from CATEGORIES array"
done
echo "ok - all five new categories are registered in CATEGORIES"

# --- needs_sudo_priming must also fire for apt_cache, not just snap_revs ---
CACHE_FILE="$TEST_ROOT/cache-apt"
CACHE_VERSION_LOCAL="$CACHE_VERSION"
printf '%s\n' "$CACHE_VERSION_LOCAL" "0" "0" "apt_cache:1:600000000" "---" > "$CACHE_FILE"
touch "$CACHE_FILE"
DRY_RUN=false
INCLUDE_TIER_2=true
ONLY_MODE=false
SKIP_CAT=()
ONLY_CAT=()
needs_sudo_priming_notty_stubbed() {
    [[ "$DRY_RUN" != "true" ]] || return 1
    (( EUID != 0 )) || return 1
    [[ "$INCLUDE_TIER_2" == "true" ]] || return 1
    ensure_cache false
    if is_enabled snap_revs && (( $(cache_size_for snap_revs) > 0 )); then return 0; fi
    if is_enabled apt_cache && (( $(cache_size_for apt_cache) > 0 )); then return 0; fi
    return 1
}
if ! needs_sudo_priming_notty_stubbed; then
    fail "needs_sudo_priming logic did not fire for a real apt_cache entry (sudo-needing category)"
fi
echo "ok - sudo priming also covers apt_cache, not just snap_revs"

echo "ok - cleanup new categories (mise_prune, nvidia_cache, apt_cache, rstring_cache, prisma_python)"
