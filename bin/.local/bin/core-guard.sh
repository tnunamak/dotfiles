#!/usr/bin/env bash
# Keep kernel core dumps from filling the disk.
#
# Why this exists: on 2026-08-05 `core_pattern` was plain `core`, so every crash
# wrote a raw full-RSS dump into the crashing process's CWD with no size cap. A
# crash-looping Next.js dev server produced ~9.6G per crash, every ~2 minutes:
# 440 dumps / 120G on Aug 5, another 11 dumps / 72G by Aug 7.
#
# core_pattern is a HOST-WIDE kernel setting that containers share, so a
# container flipping it affects the host. It had been restored to the
# systemd-coredump pipe by Aug 7 without a reboot, i.e. it drifts at runtime.
# A static sysctl file alone would not have prevented either incident, so this
# also re-asserts the setting and sweeps whatever landed while it was wrong.
#
# Two jobs:
#   1. If core_pattern drifted off systemd-coredump, put it back (needs root).
#   2. Delete stray core.* ELF dumps left by the drift window.
#
# systemd-coredump itself caps dumps (ProcessSizeMax/ExternalSizeMax 2G) and
# stores them compressed under /var/lib/systemd/coredump, so dumps captured the
# correct way are already bounded and are NOT touched here.
#
# ~/code is swept as well as ~/.tmp: tmp-reaper.sh only removes whole 7-day-cold
# subdirs under ~/.tmp, so a multi-GB dump inside an active dir (or anywhere in
# ~/code) survives it indefinitely. All 12.5G found on 2026-08-10 was in ~/code.
set -uo pipefail

WANT_PREFIX='|/usr/lib/systemd/systemd-coredump'
MIN_SIZE="${CORE_GUARD_MIN_SIZE:-+100M}"   # only sweep real dumps, not source files
SWEEP_ROOTS=("$HOME/.tmp" "$HOME/code")
DRY="${1:-}"                                # pass --dry-run to preview

current=$(cat /proc/sys/kernel/core_pattern 2>/dev/null || echo "")

# ---- 1. re-assert core_pattern -------------------------------------------
if [[ "$current" != "$WANT_PREFIX"* ]]; then
    echo "core-guard: core_pattern drifted -> '$current'"
    if [[ "$DRY" == "--dry-run" ]]; then
        echo "core-guard: would restore systemd-coredump pattern"
    elif [[ -w /proc/sys/kernel/core_pattern ]]; then
        echo "$WANT_PREFIX %P %u %g %s %t %c %h %d %F" > /proc/sys/kernel/core_pattern \
            && echo "core-guard: restored core_pattern"
    else
        echo "core-guard: cannot restore (needs root); run as root or via the system unit" >&2
    fi
fi

# ---- 2. sweep stray dumps -------------------------------------------------
# Match core.<pid> only, and confirm ELF so we never touch files like
# core.env.example or vendored source under node_modules/zod/v4/core/.
swept=0 freed=0
while IFS= read -r -d '' f; do
    head -c 4 "$f" 2>/dev/null | grep -q $'\x7fELF' || continue
    sz=$(stat -c %s "$f" 2>/dev/null || echo 0)
    if [[ "$DRY" == "--dry-run" ]]; then
        printf 'core-guard: would sweep %6.2f GB  %s\n' "$(awk -v b="$sz" 'BEGIN{print b/1e9}')" "$f"
    else
        rm -f -- "$f" && { swept=$((swept+1)); freed=$((freed+sz)); }
    fi
done < <(find "${SWEEP_ROOTS[@]}" -type f -name 'core.[0-9]*' -size "$MIN_SIZE" -print0 2>/dev/null)

if [[ "$DRY" == "--dry-run" ]]; then
    echo "core-guard: (dry-run; MIN_SIZE=$MIN_SIZE)"
else
    awk -v n="$swept" -v b="$freed" \
        'BEGIN{printf "core-guard: swept %d dump(s), freed %.1f GB\n", n, b/1e9}'
fi
