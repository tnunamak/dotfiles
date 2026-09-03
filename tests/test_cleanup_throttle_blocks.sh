#!/bin/bash
# Proves the fan-out throttle (_throttle_wait) actually BLOCKS when it is at
# capacity, and that fan-out width is sized from host CPUs rather than the
# cgroup CPU quota.
#
# Regression test for the 2026-08-30 hang, where `cleanup --clean
# --include-tier-2 --yes` sat at ~46% CPU making no progress. Two bugs
# compounded:
#
#   A. `nproc` honors the cgroup CPU quota, so inside cleanup's own
#      `systemd-run -p CPUQuota=50%` containment it returned 1 — collapsing
#      max_jobs from 4*24=96 to the floor of 8, making the throttle fire on
#      nearly every loop iteration instead of rarely.
#   B. `wait -n pid...` returns INSTANTLY (rc=0) for any pid bash has already
#      reaped, without blocking on the live ones. The old shape pruned only
#      AFTER waiting, so a stale pid in the list made every throttle call a
#      no-op and the enclosing loop span at 100% CPU while real children ran.
#
# The pre-fix shape is exercised inline below so the test fails loudly if
# anyone reintroduces prune-after-wait.

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

fail() { echo "not ok - $*" >&2; exit 1; }

# --- Bug A: width must come from host CPUs, not the cgroup quota ---------
host_cpus=$(bash -c "source '$REPO_ROOT/bin/.local/bin/cleanup'; _host_cpus")
[[ "$host_cpus" =~ ^[0-9]+$ ]] && (( host_cpus > 0 )) \
    || fail "_host_cpus returned a non-positive/non-numeric value: '$host_cpus'"

# Only meaningful on a multi-core box under a real quota-capable systemd.
if (( host_cpus > 1 )) && command -v systemd-run >/dev/null 2>&1; then
    quota_cpus=$(systemd-run --user --pty --quiet -p CPUQuota=50% -- \
        bash -c "source '$REPO_ROOT/bin/.local/bin/cleanup'; _host_cpus" 2>/dev/null \
        | tr -dc '0-9')
    if [[ -n "$quota_cpus" ]] && (( quota_cpus <= 1 )); then
        fail "_host_cpus collapsed to $quota_cpus inside a CPUQuota scope (host has $host_cpus) — fan-out width would fall back to the floor and over-throttle"
    fi
    echo "ok - fan-out width survives a cgroup CPU quota (host=$host_cpus, in-scope=${quota_cpus:-n/a})"
else
    echo "ok - fan-out width sizing checked (single-cpu or no systemd-run; quota case skipped)"
fi

# --- Bug B: at capacity, the throttle must actually block ----------------
# Mixed fast/slow children: the fast ones get reaped and go stale in the pid
# array while the slow ones keep it at capacity. That is precisely the state
# in which `wait -n` with a stale pid list stops blocking.
workload='
    max_jobs=8
    pids=()
    instant=0
    calls=0
    for i in $(seq 1 60); do
        if (( i % 6 == 0 )); then ( sleep 3 ) & else ( : ) & fi
        pids+=("$!")
        THROTTLE
    done
    wait
    echo "calls=$calls instant=$instant"
'

# Pre-fix shape, inlined: single wait -n, prune AFTER. Must show the
# pathology (nearly every call returning instantly = no real throttling).
old=$(bash -c "
    _prune_dead_pids() { local -n _arr=\"\$1\"; local p; local alive=(); for p in \"\${_arr[@]}\"; do kill -0 \"\$p\" 2>/dev/null && alive+=(\"\$p\"); done; _arr=(\"\${alive[@]}\"); }
    ${workload/THROTTLE/'if (( ${#pids[@]} >= max_jobs )); then s=$SECONDS; wait -n "${pids[@]}" 2>/dev/null; (( SECONDS-s == 0 )) && instant=$((instant+1)); calls=$((calls+1)); _prune_dead_pids pids; fi'}
")
old_calls=${old#calls=}; old_calls=${old_calls%% *}
old_instant=${old#*instant=}
# The pathology is "nearly every call returns instantly", not necessarily all
# of them — one genuine block is normal when a slow child happens to be the
# only thing outstanding. Require an overwhelming majority.
if (( old_calls < 5 )) || (( old_instant * 10 < old_calls * 9 )); then
    fail "the pre-fix shape did not reproduce the bug (calls=$old_calls instant=$old_instant); this test can no longer prove the fix"
fi
echo "ok - pre-fix shape reproduces the no-op throttle ($old_instant/$old_calls calls returned instantly)"

# Fixed shape: prune BEFORE waiting, loop until under capacity.
new=$(bash -c "
    run_log() { :; }
    declare -A _DIAG_INSTANT_STREAK; declare -A _DIAG_LAST_LOG_AT
    $(sed -n '/^_prune_dead_pids()/,/^}/p;/^_throttle_wait()/,/^}/p' "$REPO_ROOT/bin/.local/bin/cleanup")
    _diag_wait_n() { local l=\"\$1\"; shift; local s=\$SECONDS; wait -n \"\$@\" 2>/dev/null; local rc=\$?; (( SECONDS-s==0 )) && instant=\$((instant+1)); calls=\$((calls+1)); return \$rc; }
    ${workload/THROTTLE/'_throttle_wait testlabel "$max_jobs" pids'}
")
new_calls=${new#calls=}; new_calls=${new_calls%% *}

# The fix must call wait -n far less often than the broken shape: it only
# waits when genuinely at capacity, and each wait blocks on a live child.
if (( new_calls >= old_calls )); then
    fail "throttle still spinning: fixed shape made $new_calls wait -n calls vs $old_calls pre-fix (expected substantially fewer)"
fi
echo "ok - fixed throttle blocks instead of spinning ($new_calls calls vs $old_calls pre-fix)"

echo "ok - cleanup fan-out throttle blocks at capacity"
