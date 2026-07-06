#!/usr/bin/env bash
# Run a matrix of (scripts_version × scenario) and tabulate results.
# Default: 6 scenarios × 2 script versions = 12 runs.
set -uo pipefail

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SELF_DIR"

SCENARIOS=(
  no-crash
  dangling-symlink
  dangling-no-best
  no-backups-dir
  cliff-shrink
  empty-live-dir
  empty-last-fallback
  many-old-saves-good-best
  prev-target-only-in-backups
  double-crash
  assistant-grouped-naming
  assistant-grouped-naming-unpatched
  assistant-empty-group-race
  assistant-empty-group-race-unpatched
  assistant-tpm-wipe-recovery
  second-boot-restore-failure
  kitty-attach-clean-boot
  kitty-attach-no-session-named-main
  kitty-attach-group-name-drift
  kitty-attach-multiple-groups
  kitty-attach-all-windows-viewed
)
# Scenarios dispatched via kitty-attach-run.sh (kitty-attach behavior tests),
# rest use run.sh (tmux-resurrect restore tests).
KITTY_ATTACH_SCENARIOS=(
  kitty-attach-clean-boot
  kitty-attach-no-session-named-main
  kitty-attach-group-name-drift
  kitty-attach-multiple-groups
  kitty-attach-all-windows-viewed
)
VERSIONS=(
  fixed
  old
)
# Negative scenarios: must FAIL on both versions to count as PASS.
# These prove a bug exists in upstream (independent of which fix-version is
# in play). Listed as "expected fail" — flipping their outcome would be a
# silent regression that leaves us thinking the bug was caught when it wasn't.
NEGATIVE_SCENARIOS=(
  assistant-grouped-naming-unpatched
  assistant-empty-group-race-unpatched
)

# Build once
docker build -t tmux-restore-test:latest . >/dev/null 2>&1 || {
  echo "BUILD FAILED"; exit 1;
}

declare -A RESULTS
total_runs=0
pass_runs=0

is_kitty_attach() {
  local scenario="$1"
  for s in "${KITTY_ATTACH_SCENARIOS[@]}"; do
    [[ "$s" == "$scenario" ]] && return 0
  done
  return 1
}

for ver in "${VERSIONS[@]}"; do
  case "$ver" in
    fixed)
      restore_args=()
      attach_args=()
      ;;
    old)
      restore_args=(--scripts-dir old-scripts)
      attach_args=(--attach-script old-scripts/tmux-local-attach-main)
      ;;
  esac
  for sc in "${SCENARIOS[@]}"; do
    total_runs=$((total_runs + 1))
    printf '\n=== ver=%s scenario=%s ===\n' "$ver" "$sc"
    if is_kitty_attach "$sc"; then
      cmd=(bash kitty-attach-run.sh "${attach_args[@]}" --scenario "$sc")
    else
      cmd=(bash run.sh "${restore_args[@]}" --scenario "$sc")
    fi
    if "${cmd[@]}" >"/tmp/run-${ver}-${sc}.log" 2>&1; then
      RESULTS["${ver}/${sc}"]="PASS"
      pass_runs=$((pass_runs + 1))
      printf '  → PASS\n'
    else
      RESULTS["${ver}/${sc}"]="FAIL"
      printf '  → FAIL (log: /tmp/run-%s-%s.log)\n' "$ver" "$sc"
    fi
  done
done

is_negative() {
  local scenario="$1"
  for neg in "${NEGATIVE_SCENARIOS[@]}"; do
    [[ "$neg" == "$scenario" ]] && return 0
  done
  return 1
}

echo ""
echo "============================================"
echo "MATRIX RESULTS"
echo "============================================"
printf '%-36s' "scenario"
for ver in "${VERSIONS[@]}"; do printf ' %-8s' "$ver"; done
echo ""
echo "---"
for sc in "${SCENARIOS[@]}"; do
  marker=""
  is_negative "$sc" && marker=" [neg]"
  printf '%-36s' "${sc}${marker}"
  for ver in "${VERSIONS[@]}"; do
    printf ' %-8s' "${RESULTS["${ver}/${sc}"]:-?}"
  done
  echo ""
done
echo "============================================"
echo "TOTAL raw: $pass_runs/$total_runs passed"
echo "(negative scenarios are expected to fail; raw count above is misleading for them — see analysis below)"
echo ""

# Analysis:
# - For positive scenarios: fixed must PASS. discriminator if old FAILS.
# - For negative scenarios: BOTH fixed and old must FAIL (otherwise the bug
#   the scenario is supposed to expose isn't being exposed).
discriminating=0
fixed_fail=0
negative_misbehavior=0
for sc in "${SCENARIOS[@]}"; do
  if is_negative "$sc"; then
    if [[ "${RESULTS["fixed/${sc}"]:-?}" != "FAIL" || "${RESULTS["old/${sc}"]:-?}" != "FAIL" ]]; then
      negative_misbehavior=$((negative_misbehavior + 1))
      echo "  WARN: negative scenario '$sc' should FAIL on both versions (got fixed=${RESULTS["fixed/${sc}"]:-?} old=${RESULTS["old/${sc}"]:-?})"
    fi
  else
    [[ "${RESULTS["fixed/${sc}"]:-?}" != "PASS" ]] && fixed_fail=$((fixed_fail + 1))
    if [[ "${RESULTS["fixed/${sc}"]:-?}" == "PASS" && "${RESULTS["old/${sc}"]:-?}" == "FAIL" ]]; then
      discriminating=$((discriminating + 1))
    fi
  fi
done

echo "Discriminating positive scenarios (fixed PASS, old FAIL): $discriminating"
echo "Fixed-script regressions on positive scenarios: $fixed_fail"
echo "Negative scenarios behaving correctly: $((${#NEGATIVE_SCENARIOS[@]} - negative_misbehavior))/${#NEGATIVE_SCENARIOS[@]}"

if (( fixed_fail == 0 && discriminating > 0 && negative_misbehavior == 0 )); then
  echo ""
  echo "RESULT: fix is validated — new scripts pass everything, old scripts fail at least one case, negative scenarios behave as expected."
  exit 0
else
  echo ""
  echo "RESULT: validation incomplete."
  exit 1
fi
