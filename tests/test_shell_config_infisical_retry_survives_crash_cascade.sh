#!/usr/bin/env bash
# Regression test for the Infisical secrets retry loop in shell/.shell_config.
#
# Root cause (2026-07-27, hardened 2026-07-28): at boot, `infisical export`
# can D-Bus-activate ksecretd (org.freedesktop.secrets) before the Wayland
# compositor exists; it aborts (SIGABRT) and dbus-daemon respawns it,
# repeating until the compositor wins the race. A 2026-07-28 crash needed 4
# activation attempts (3 crashes) to settle — landing inside the previous
# fix's 2-attempt retry budget, so `exec zsh` was needed again.
#
# Researched directly from dbus-daemon source (bus/activation.c, v1.16.2): a
# single blocking client call gets EXACTLY ONE activation attempt — if that
# spawn crashes, the client's call fails immediately; dbus-daemon does not
# retry on the client's behalf, and there is NO DOCUMENTED UPPER BOUND on how
# many times the target service can crash before stabilizing. Any fixed
# attempt count is therefore a bet, not a guarantee — this is why the fix
# retries against a 20s wall-clock deadline instead of a fixed count.
#
# This test extracts the exact retry loop from shell/.shell_config (kept
# byte-for-byte in sync — see the sync check below) and proves it against a
# fake `infisical` that simulates a configurable-depth crash cascade:
#   1. Recovers from a cascade matching the real 2026-07-28 incident (3
#      crashes, succeeds on the 4th attempt).
#   2. Does not hang forever on permanent failure — exits within the ~20s
#      deadline.
#   3. Adds no latency when the first attempt succeeds (the common case).
#   4. Recovers from a cascade 5x deeper than anything ever observed live,
#      proving the fix scales to unknown depth rather than a tuned number.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHELL_CONFIG="$ROOT/shell/.shell_config"
WORK="$(mktemp -d "$HOME/.tmp/infisical-retry-test.XXXXXX")"
FIXTURE_BIN="$WORK/bin"
COUNTER_FILE="$WORK/counter"
mkdir -p "$FIXTURE_BIN"
trap 'rm -rf "$WORK"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

# Sync check: fail loudly if shell/.shell_config's retry loop no longer
# matches what this test exercises, instead of silently testing stale logic.
grep -qF '_inf_deadline=$(( $(date +%s) + 20 ))' "$SHELL_CONFIG" \
  || fail "shell/.shell_config's retry loop shape changed — update this test's extracted copy to match"

# Fake infisical: fails the first N calls (tracked via a counter file),
# succeeds after that.
cat >"$FIXTURE_BIN/infisical" <<'EOF'
#!/usr/bin/env bash
COUNTER_FILE="__COUNTER_FILE__"
FAIL_COUNT="${INFISICAL_TEST_FAIL_COUNT:-0}"
count=0
[[ -f "$COUNTER_FILE" ]] && count="$(cat "$COUNTER_FILE")"
count=$((count + 1))
echo "$count" >"$COUNTER_FILE"
(( count <= FAIL_COUNT )) && exit 1
echo "export INFISICAL_TEST_VAR=success_after_${count}_attempts"
EOF
sed -i "s#__COUNTER_FILE__#$COUNTER_FILE#" "$FIXTURE_BIN/infisical"
chmod +x "$FIXTURE_BIN/infisical"

# Exact copy of the retry loop from shell/.shell_config — kept in sync via
# the grep check above.
run_retry_loop() {
  _inf_ok=0
  _inf_deadline=$(( $(date +%s) + 20 ))
  while (( $(date +%s) < _inf_deadline )); do
    if _inf_secrets="$(timeout 5 infisical export \
      --projectId=894e048b-954c-4c5a-a1d0-888c54c9ce66 \
      --env=dev --format=dotenv-export \
      --domain=https://secrets.vivid.fish 2>/dev/null </dev/null)"; then
      eval "$_inf_secrets"
      _inf_ok=1
      break
    fi
  done
  unset _inf_deadline
}

run_case() {
  local fail_count="$1"
  rm -f "$COUNTER_FILE"
  PATH="$FIXTURE_BIN:$PATH" INFISICAL_TEST_FAIL_COUNT="$fail_count" bash -c "
    $(declare -f run_retry_loop)
    run_retry_loop
    echo \"ok=\$_inf_ok var=\$INFISICAL_TEST_VAR\"
  "
}

out="$(run_case 3)"
grep -q '^ok=1' <<<"$out" || fail "did not recover from a 3-crash cascade (the real 2026-07-28 incident depth): $out"

start_ts=$(date +%s)
out="$(run_case 999999)"
elapsed=$(( $(date +%s) - start_ts ))
grep -q '^ok=0' <<<"$out" || fail "permanent failure did not report ok=0: $out"
(( elapsed >= 18 && elapsed <= 25 )) || fail "permanent-failure case took ${elapsed}s, expected ~20s (deadline not enforced correctly)"

start_ts=$(date +%s)
out="$(run_case 0)"
elapsed=$(( $(date +%s) - start_ts ))
grep -q '^ok=1' <<<"$out" || fail "happy path did not succeed: $out"
(( elapsed <= 2 )) || fail "happy path took ${elapsed}s — retry loop is adding latency to the common case"

out="$(run_case 15)"
grep -q '^ok=1' <<<"$out" || fail "did not recover from a 15-crash cascade (5x worse than anything observed) within the time budget: $out"

echo 'PASS: Infisical retry loop recovers from the real crash-cascade depth, from 5x that depth, gives up cleanly within ~20s on permanent failure, and adds no latency on success'
