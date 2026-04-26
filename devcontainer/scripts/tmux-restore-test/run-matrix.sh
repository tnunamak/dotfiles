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
  many-old-saves-good-best
  prev-target-only-in-backups
  double-crash
)
VERSIONS=(
  fixed
  old
)

# Build once
docker build -t tmux-restore-test:latest . >/dev/null 2>&1 || {
  echo "BUILD FAILED"; exit 1;
}

declare -A RESULTS
total_runs=0
pass_runs=0

for ver in "${VERSIONS[@]}"; do
  case "$ver" in
    fixed) scripts_arg=() ;;
    old)   scripts_arg=(--scripts-dir old-scripts) ;;
  esac
  for sc in "${SCENARIOS[@]}"; do
    total_runs=$((total_runs + 1))
    printf '\n=== ver=%s scenario=%s ===\n' "$ver" "$sc"
    if bash run.sh "${scripts_arg[@]}" --scenario "$sc" >"/tmp/run-${ver}-${sc}.log" 2>&1; then
      RESULTS["${ver}/${sc}"]="PASS"
      pass_runs=$((pass_runs + 1))
      printf '  → PASS\n'
    else
      RESULTS["${ver}/${sc}"]="FAIL"
      printf '  → FAIL (log: /tmp/run-%s-%s.log)\n' "$ver" "$sc"
    fi
  done
done

echo ""
echo "============================================"
echo "MATRIX RESULTS"
echo "============================================"
printf '%-20s' "scenario"
for ver in "${VERSIONS[@]}"; do printf ' %-8s' "$ver"; done
echo ""
echo "---"
for sc in "${SCENARIOS[@]}"; do
  printf '%-20s' "$sc"
  for ver in "${VERSIONS[@]}"; do
    printf ' %-8s' "${RESULTS["${ver}/${sc}"]:-?}"
  done
  echo ""
done
echo "============================================"
echo "TOTAL: $pass_runs/$total_runs passed"
echo ""

# Discrimination check: at least one scenario where fixed PASSES and old FAILS
discriminating=0
for sc in "${SCENARIOS[@]}"; do
  if [[ "${RESULTS["fixed/${sc}"]:-?}" == "PASS" && "${RESULTS["old/${sc}"]:-?}" == "FAIL" ]]; then
    discriminating=$((discriminating + 1))
  fi
done
echo "Discriminating scenarios (fixed PASS, old FAIL): $discriminating"

# All-fixed-pass check
fixed_fail=0
for sc in "${SCENARIOS[@]}"; do
  if [[ "${RESULTS["fixed/${sc}"]:-?}" != "PASS" ]]; then
    fixed_fail=$((fixed_fail + 1))
  fi
done
echo "Fixed-script regressions: $fixed_fail"

if (( fixed_fail == 0 && discriminating > 0 )); then
  echo ""
  echo "RESULT: fix is validated — new scripts pass everything, old scripts fail at least one case."
  exit 0
else
  echo ""
  echo "RESULT: validation incomplete."
  exit 1
fi
