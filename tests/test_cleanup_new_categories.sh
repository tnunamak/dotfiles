#!/bin/bash
# Proves the three new cleanup categories (mise_prune, nvidia_cache,
# apt_cache) probe correctly and are gated by the right thresholds/tiers —
# WITHOUT ever running a real deletion. This is deliberately probe-level
# only: these categories operate on real machine-global paths (mise's data
# dir, ~/.cache/nvidia, /var/cache/apt/archives), not anything CODE_ROOT-
# scoped, so exercising their actual action blocks end-to-end would mean
# either mocking three different real external tools convincingly (mise,
# apt-get, and a real ~/.cache/nvidia layout) or risking real deletions —
# not worth it for what's fundamentally the same maybe_run/confirm wrapper
# every other tier-1/tier-2 category already uses and already has coverage
# for. See ai/research/dev-tool-caches/ for the safety research behind each.

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

# --- new categories appear in the CATEGORIES array (is_enabled/--skip-/--only- wiring) ---
for cat in mise_prune nvidia_cache apt_cache; do
    [[ " ${CATEGORIES[*]} " == *" $cat "* ]] || fail "$cat missing from CATEGORIES array"
done
echo "ok - mise_prune, nvidia_cache, apt_cache are registered in CATEGORIES"

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

echo "ok - cleanup new categories (mise_prune, nvidia_cache, apt_cache)"
