#!/usr/bin/env bash
# Offline tests for pmctl. No network access, no live Purelymail account.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PMCTL="$SCRIPT_DIR/../scripts/pmctl"

FAKE_BIN_DIR="$(mktemp -d)"
trap 'rm -rf "$FAKE_BIN_DIR"' EXIT

pass=0
fail=0

check() {
  local desc="$1"
  local status="$2"
  if [[ "$status" -eq 0 ]]; then
    echo "ok - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc"
    fail=$((fail + 1))
  fi
}

# Fake curl: captures argv and stdin config without using the network.
write_fake_curl() {
  cat > "$FAKE_BIN_DIR/curl" <<'FAKECURL'
#!/usr/bin/env bash
# Consume args but ignore them except to sanity-check no secret leaked into argv.
printf '%s\n' "$@" >"${FAKE_CURL_ARGV_FILE:?}"
cat >"${FAKE_CURL_CONFIG_FILE:?}"
for arg in "$@"; do
  case "$arg" in
    *super-secret-argv-token*)
      echo "FAKE CURL: secret leaked into argv!" >&2
      exit 99
      ;;
  esac
done

case "${FAKE_CURL_MODE:-success}" in
  success)
    printf '{"result":{"users":["a@example.com"]}}\n200'
    ;;
  http_error)
    printf 'not found\n404'
    ;;
  body_error)
    printf '{"error":{"code":"BAD","message":"nope"}}\n200'
    ;;
esac
FAKECURL
  chmod +x "$FAKE_BIN_DIR/curl"
}

write_fake_curl
export PATH="$FAKE_BIN_DIR:$PATH"
export FAKE_CURL_ARGV_FILE="$FAKE_BIN_DIR/argv"
export FAKE_CURL_CONFIG_FILE="$FAKE_BIN_DIR/config"

# 1. Missing token is rejected
unset PURELYMAIL_API_TOKEN || true
set +e
out=$(echo '{}' | "$PMCTL" listUser 2>&1)
status=$?
set -e
[[ "$status" -ne 0 && "$out" == *"PURELYMAIL_API_TOKEN"* ]]
check "missing token rejected" $?

export PURELYMAIL_API_TOKEN="test-token-do-not-use"

# 2. Missing endpoint arg shows usage
set +e
out=$("$PMCTL" 2>&1)
status=$?
set -e
[[ "$status" -ne 0 && "$out" == *"Usage"* ]]
check "missing endpoint shows usage" $?

# 3. Unknown flag rejected (argv secret-injection guard)
set +e
out=$(echo '{}' | "$PMCTL" listUser --token super-secret-argv-token 2>&1)
status=$?
set -e
[[ "$status" -ne 0 ]]
check "unknown argv flag rejected" $?

# 4. Successful pass-through (stdin body)
FAKE_CURL_MODE=success
export FAKE_CURL_MODE
out=$(echo '{}' | "$PMCTL" listUser)
status=$?
[[ "$status" -eq 0 && "$out" == *'"users"'* ]]
check "successful call returns result payload" $?

# 5. Successful call via --data-file
tmp_body="$(mktemp)"
echo '{}' > "$tmp_body"
out=$("$PMCTL" listUser --data-file "$tmp_body")
status=$?
rm -f "$tmp_body"
[[ "$status" -eq 0 && "$out" == *'"users"'* ]]
check "successful call via --data-file" $?

# 6. Non-destructive endpoint needs no confirmation env var
unset PMCTL_CONFIRM_DESTRUCTIVE || true
out=$(echo '{}' | "$PMCTL" listUser)
status=$?
[[ "$status" -eq 0 ]]
check "non-destructive endpoint runs without confirmation" $?

# 7. Destructive endpoint blocked without confirmation
unset PMCTL_CONFIRM_DESTRUCTIVE || true
set +e
out=$(echo '{"userName":"me@example.com"}' | "$PMCTL" deleteUser 2>&1)
status=$?
set -e
[[ "$status" -ne 0 && "$out" == *"destructive"* ]]
check "destructive endpoint blocked without PMCTL_CONFIRM_DESTRUCTIVE"  $?

# 8. Destructive endpoint proceeds with confirmation
PMCTL_CONFIRM_DESTRUCTIVE=yes
export PMCTL_CONFIRM_DESTRUCTIVE
out=$(echo '{"userName":"me@example.com"}' | "$PMCTL" deleteUser)
status=$?
[[ "$status" -eq 0 ]]
check "destructive endpoint proceeds with PMCTL_CONFIRM_DESTRUCTIVE=yes" $?
unset PMCTL_CONFIRM_DESTRUCTIVE || true

# 9. Another destructive endpoint (deleteDomain) also gated
set +e
out=$(echo '{"name":"example.com"}' | "$PMCTL" deleteDomain 2>&1)
status=$?
set -e
[[ "$status" -ne 0 && "$out" == *"destructive"* ]]
check "deleteDomain also blocked without confirmation" $?

# 10. HTTP-level error surfaced as failure
FAKE_CURL_MODE=http_error
export FAKE_CURL_MODE
set +e
out=$(echo '{}' | "$PMCTL" listUser 2>&1)
status=$?
set -e
[[ "$status" -ne 0 && "$out" == *"HTTP 404"* ]]
check "HTTP error surfaced as failure" $?

# 11. Body-level error (200 but no 'result' key) surfaced as failure
FAKE_CURL_MODE=body_error
export FAKE_CURL_MODE
set +e
out=$(echo '{}' | "$PMCTL" listUser 2>&1)
status=$?
set -e
[[ "$status" -ne 0 && "$out" == *"no 'result' key"* ]]
check "body-level error shape surfaced as failure" $?
FAKE_CURL_MODE=success
export FAKE_CURL_MODE

# 12. Token and request body stay out of curl argv.
export PURELYMAIL_API_TOKEN="super-secret-argv-token"
echo '{"password":"body-secret"}' | "$PMCTL" createUser >/dev/null
! grep -qE 'super-secret-argv-token|body-secret' "$FAKE_CURL_ARGV_FILE"
check "token and body stay out of curl argv" $?

# 13. Generated app password requires a protected output file and emits no payload.
export PURELYMAIL_API_TOKEN="test-token-do-not-use"
set +e
out=$(echo '{"userHandle":"me@example.com"}' | "$PMCTL" createAppPassword 2>&1)
status=$?
set -e
[[ "$status" -ne 0 && "$out" == *"--secret-output-file"* ]]
check "createAppPassword requires secret output file" $?

secret_file="$FAKE_BIN_DIR/generated.json"
stdout=$(echo '{"userHandle":"me@example.com"}' | "$PMCTL" createAppPassword --secret-output-file "$secret_file" 2>/dev/null)
[[ -z "$stdout" && -s "$secret_file" && "$(stat -c %a "$secret_file")" == 600 ]]
check "generated secret is written mode 0600 and not echoed" $?

echo
echo "pmctl tests: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
