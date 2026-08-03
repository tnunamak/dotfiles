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
# retries against a 20s elapsed-time deadline instead of a fixed count.
#
# This test executes the actual secrets block from shell/.shell_config against
# a fake `infisical` that simulates a configurable-depth crash cascade:
#   1. Recovers from a cascade matching the real 2026-07-28 incident (3
#      crashes, succeeds on the 4th attempt).
#   2. Does not let a final 5s attempt overrun a nearly-expired 20s budget.
#   3. Adds no latency when the first attempt succeeds (the common case).
#   4. Recovers from a cascade 5x deeper than anything ever observed live,
#      proving the fix scales to unknown depth rather than a tuned number.
#   5. Does not depend on wall-clock `date`, which can jump during boot.
#   6. Rate-limits fast permanent failures instead of spawning
#      timeout/infisical processes without a floor from every boot shell.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHELL_CONFIG="$ROOT/shell/.shell_config"
WORK="$(mktemp -d "$HOME/.tmp/infisical-retry-test.XXXXXX")"
FIXTURE_BIN="$WORK/bin"
COUNTER_FILE="$WORK/counter"
TIMEOUT_LOG="$WORK/timeout-args"
DATE_LOG="$WORK/date-calls"
mkdir -p "$FIXTURE_BIN"
trap 'rm -rf "$WORK"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

# Execute the production block rather than a hand-maintained copy that could
# stay green after the real loop changed.
SECRETS_BLOCK="$(sed -n '/^# Secrets — hydrate/,/^# Machine-specific config/p' "$SHELL_CONFIG")"
grep -qF '_inf_deadline=$(( $(_inf_now_seconds) + 20 ))' <<<"$SECRETS_BLOCK" ||
  fail "could not extract the current Infisical retry block"
grep -qF 'machine-identity.env' <<<"$SECRETS_BLOCK" ||
  fail "machine-identity path not present in extracted block — did the fast-path get removed?"

# The retry loop is the fallback; the machine-identity path is preferred.
# The MI-absent tests below rely on HOME pointing at a scratch dir with no
# ~/.config/infisical/machine-identity.env so the block falls through.
MI_TEST_HOME="$WORK/home-no-mi"
mkdir -p "$MI_TEST_HOME"

# Fake infisical: fails the first N calls (tracked via a counter file),
# succeeds after that. slow-boundary mode deliberately consumes about 18
# seconds, including the production retry throttle, then hangs so the loop
# must cap its final timeout to at most 3 seconds. The 1-3s range avoids
# coupling the test to uptime's fractional second at process start.
cat >"$FIXTURE_BIN/infisical" <<'EOF'
#!/usr/bin/env bash
COUNTER_FILE="__COUNTER_FILE__"
FAIL_COUNT="${INFISICAL_TEST_FAIL_COUNT:-0}"
MODE="${INFISICAL_TEST_MODE:-cascade}"
count=0
[[ -f "$COUNTER_FILE" ]] && count="$(cat "$COUNTER_FILE")"
count=$((count + 1))
echo "$count" >"$COUNTER_FILE"
if [[ "$MODE" == slow-boundary ]]; then
  case "$count" in
    1|2|3) exec sleep 30 ;;
    4) sleep 2; exit 1 ;;
    *) exec sleep 30 ;;
  esac
fi
[[ "$MODE" == permanent ]] && exit 1
(( count <= FAIL_COUNT )) && exit 1
echo "export INFISICAL_TEST_VAR=success_after_${count}_attempts"
EOF
sed -i "s#__COUNTER_FILE__#$COUNTER_FILE#" "$FIXTURE_BIN/infisical"
chmod +x "$FIXTURE_BIN/infisical"

# Record the actual per-attempt timeout while delegating to the system binary.
cat >"$FIXTURE_BIN/timeout" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$1" >>"__TIMEOUT_LOG__"
exec /usr/bin/timeout "$@"
EOF
sed -i "s#__TIMEOUT_LOG__#$TIMEOUT_LOG#" "$FIXTURE_BIN/timeout"
chmod +x "$FIXTURE_BIN/timeout"

# A frozen wall clock made the old `date +%s` deadline unbounded. Any call to
# this stub is a regression; Linux uptime or shell-relative SECONDS must drive
# the production loop instead.
cat >"$FIXTURE_BIN/date" <<'EOF'
#!/usr/bin/env bash
printf 'called\n' >>"__DATE_LOG__"
printf '0\n'
EOF
sed -i "s#__DATE_LOG__#$DATE_LOG#" "$FIXTURE_BIN/date"
chmod +x "$FIXTURE_BIN/date"

run_case() {
  local fail_count="$1" mode="${2:-cascade}" outer_timeout="${3:-30}"
  rm -f "$COUNTER_FILE" "$TIMEOUT_LOG"
  # Point HOME at a scratch dir with no machine-identity.env so the block
  # falls through to the retry loop — that's what these cases are testing.
  PATH="$FIXTURE_BIN:/usr/bin:/bin" \
    HOME="$MI_TEST_HOME" \
    INFISICAL_TEST_FAIL_COUNT="$fail_count" \
    INFISICAL_TEST_MODE="$mode" \
    /usr/bin/timeout "$outer_timeout" bash -c "$SECRETS_BLOCK
printf 'var=%s deadline=%s remaining=%s attempt_timeout=%s helper=%s\n' \
  \"\${INFISICAL_TEST_VAR-}\" \"\${_inf_deadline-unset}\" \
  \"\${_inf_remaining-unset}\" \"\${_inf_attempt_timeout-unset}\" \
  \"\$(type -t _inf_now_seconds 2>/dev/null || printf unset)\""
}

out="$(run_case 3)"
grep -q '^var=success_after_4_attempts ' <<<"$out" ||
  fail "did not recover from a 3-crash cascade (the real 2026-07-28 incident depth): $out"

start_ts=$(date +%s)
out="$(run_case 999999 slow-boundary)"
elapsed=$(( $(date +%s) - start_ts ))
grep -q '^var= ' <<<"$out" || fail "deadline failure unexpectedly exported a secret: $out"
(( elapsed >= 18 && elapsed <= 21 )) ||
  fail "near-deadline case took ${elapsed}s, expected a hard ~20s budget"
final_timeout="$(tail -n 1 "$TIMEOUT_LOG")"
(( final_timeout >= 1 && final_timeout <= 3 )) ||
  fail "final attempt was not capped to its 1-3s remaining budget: $(tr '\n' ' ' <"$TIMEOUT_LOG")"

start_ts=$(date +%s)
out="$(run_case 0)"
elapsed=$(( $(date +%s) - start_ts ))
grep -q '^var=success_after_1_attempts ' <<<"$out" || fail "happy path did not succeed: $out"
(( elapsed <= 2 )) || fail "happy path took ${elapsed}s — retry loop is adding latency to the common case"

out="$(run_case 15)"
grep -q '^var=success_after_16_attempts ' <<<"$out" ||
  fail "did not recover from a 15-crash cascade (5x worse than anything observed) within the time budget: $out"

grep -q 'deadline=unset remaining=unset attempt_timeout=unset helper=unset' <<<"$out" ||
  fail "Infisical retry internals leaked into the interactive shell: $out"
[[ ! -e "$DATE_LOG" ]] ||
  fail 'retry loop consulted wall-clock date instead of a relative/monotonic clock'

set +e
run_case 999999 permanent 2 >/dev/null
permanent_rc=$?
set -e
permanent_attempts="$(<"$COUNTER_FILE")"
[[ "$permanent_rc" -eq 124 ]] ||
  fail "permanent-failure throttle fixture exited unexpectedly (rc=$permanent_rc)"
(( permanent_attempts >= 3 && permanent_attempts <= 12 )) ||
  fail "permanent failure launched $permanent_attempts attempts in 2s; retry throttle is missing or excessive"

# ---- Machine-identity path (2026-08-02) ----
# The MI path is a single subshell login+export call. On success, retry-loop
# internals must not run. On failure, the block must fall through to the
# existing retry logic. Both properties are load-bearing: if MI silently
# succeeded with empty output, shells would appear healthy while getting no
# secrets; if MI failure crashed the block, the keyring fallback would be
# lost.
MI_HOME="$WORK/home-with-mi"
mkdir -p "$MI_HOME/.config/infisical"

# Fake infisical that behaves like the real one for both `login` (returns a
# JWT-shaped string) and `export --token=...` (returns dotenv). Counts calls
# so we can distinguish MI-path success (2 calls total: login + export) from
# retry-loop invocations (which don't use --token).
cat >"$FIXTURE_BIN/infisical-mi" <<'EOF'
#!/usr/bin/env bash
COUNTER="__MI_COUNTER__"
MODE="${INFISICAL_MI_TEST_MODE:-success}"
count=0
[[ -f "$COUNTER" ]] && count="$(cat "$COUNTER")"
count=$((count + 1))
echo "$count" >"$COUNTER"
# `login --method=universal-auth` returns a JWT-shaped token on stdout
if [[ "$1" == "login" ]]; then
  [[ "$MODE" == "login-fail" ]] && exit 1
  echo "fake.jwt.token"
  exit 0
fi
if [[ "$1" == "export" ]]; then
  [[ "$MODE" == "export-fail" ]] && exit 1
  echo "export INFISICAL_TEST_VAR=success_from_mi"
  exit 0
fi
exit 2
EOF
MI_COUNTER="$WORK/mi-counter"
sed -i "s#__MI_COUNTER__#$MI_COUNTER#" "$FIXTURE_BIN/infisical-mi"
chmod +x "$FIXTURE_BIN/infisical-mi"

run_mi_case() {
  local mi_mode="$1" retry_fail="${2:-0}" outer_timeout="${3:-10}"
  rm -f "$COUNTER_FILE" "$TIMEOUT_LOG" "$MI_COUNTER"
  # Write a valid-shape MI env file. Content doesn't need to be real — the
  # infisical binary we hand the block is our stub, which ignores creds.
  cat >"$MI_HOME/.config/infisical/machine-identity.env" <<MIENV
INFISICAL_UNIVERSAL_AUTH_CLIENT_ID=test-client-id
INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET=test-client-secret
MIENV
  chmod 600 "$MI_HOME/.config/infisical/machine-identity.env"
  # Replace `infisical` on PATH with our MI-aware stub for this run only.
  # The block calls `infisical` with `login ...` first, then `export ...`.
  # When it falls through to the retry loop it calls `infisical export`
  # WITHOUT --token — the original crash-cascade fixture handles that call.
  cp "$FIXTURE_BIN/infisical-mi" "$FIXTURE_BIN/infisical"
  # But the retry-loop's `infisical export` (no --token) still needs to
  # come from the crash-cascade fixture if we want to test fallback.
  # Solution: wrapper that dispatches based on args.
  cat >"$FIXTURE_BIN/infisical" <<EOF2
#!/usr/bin/env bash
# If args contain --token, this is the MI path's export call; otherwise
# it's the retry loop's export call.
for a in "\$@"; do
  if [[ "\$a" == --token=* ]]; then
    exec "$FIXTURE_BIN/infisical-mi" "\$@"
  fi
done
if [[ "\$1" == "login" ]]; then
  exec "$FIXTURE_BIN/infisical-mi" "\$@"
fi
exec "$FIXTURE_BIN/infisical-cascade" "\$@"
EOF2
  chmod +x "$FIXTURE_BIN/infisical"
  # Preserve the retry-loop fixture under its own name so the wrapper can find it.
  [[ ! -x "$FIXTURE_BIN/infisical-cascade" ]] && {
    # Re-generate the cascade binary at a distinct path so the wrapper can dispatch.
    cat >"$FIXTURE_BIN/infisical-cascade" <<'CEOF'
#!/usr/bin/env bash
COUNTER_FILE="__COUNTER_FILE__"
FAIL_COUNT="${INFISICAL_TEST_FAIL_COUNT:-0}"
count=0
[[ -f "$COUNTER_FILE" ]] && count="$(cat "$COUNTER_FILE")"
count=$((count + 1))
echo "$count" >"$COUNTER_FILE"
(( count <= FAIL_COUNT )) && exit 1
echo "export INFISICAL_TEST_VAR=success_after_retry_${count}_attempts"
CEOF
    sed -i "s#__COUNTER_FILE__#$COUNTER_FILE#" "$FIXTURE_BIN/infisical-cascade"
    chmod +x "$FIXTURE_BIN/infisical-cascade"
  }

  PATH="$FIXTURE_BIN:/usr/bin:/bin" \
    HOME="$MI_HOME" \
    INFISICAL_MI_TEST_MODE="$mi_mode" \
    INFISICAL_TEST_FAIL_COUNT="$retry_fail" \
    INFISICAL_TEST_MODE=cascade \
    /usr/bin/timeout "$outer_timeout" bash -c "$SECRETS_BLOCK
printf 'var=%s mi_calls=%s retry_calls=%s\n' \
  \"\${INFISICAL_TEST_VAR-}\" \
  \"\$(cat '$MI_COUNTER' 2>/dev/null || echo 0)\" \
  \"\$(cat '$COUNTER_FILE' 2>/dev/null || echo 0)\""
}

# Case A: MI success — retry loop must NOT run.
start_ts=$(date +%s)
out="$(run_mi_case success 0)"
elapsed=$(( $(date +%s) - start_ts ))
grep -q '^var=success_from_mi ' <<<"$out" || fail "MI success did not export the expected variable: $out"
grep -q 'retry_calls=0' <<<"$out" || fail "MI succeeded but retry loop still ran: $out"
(( elapsed <= 3 )) || fail "MI happy path took ${elapsed}s — should be sub-second"

# Case B: MI login fails — retry loop must run and succeed.
out="$(run_mi_case login-fail 0)"
grep -qE '^var=success_after_retry_[0-9]+_attempts ' <<<"$out" ||
  fail "MI-login failure did not fall through to retry loop: $out"

# Case C: MI export fails after login succeeds — same fallthrough.
out="$(run_mi_case export-fail 0)"
grep -qE '^var=success_after_retry_[0-9]+_attempts ' <<<"$out" ||
  fail "MI-export failure did not fall through to retry loop: $out"

# Restore infisical binary for any subsequent tests
cp "$FIXTURE_BIN/infisical-cascade" "$FIXTURE_BIN/infisical" 2>/dev/null || true

echo 'PASS: actual Infisical config block recovers from deep crash cascades, caps its 20s budget, ignores wall-clock jumps, cleans helpers, throttles permanent failures, adds no happy-path latency, prefers machine identity when configured (sub-second, no retry loop), and falls back to keyring retry when MI fails at either login or export'
