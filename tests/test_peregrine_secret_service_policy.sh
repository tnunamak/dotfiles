#!/usr/bin/env bash
# Static regression gate for the configuration that selects KWallet over
# GNOME Keyring as the Secret Service provider on peregrine.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DBUS_SERVICE="$ROOT/bin/.local/share/dbus-1/services/org.freedesktop.secrets.service"
GNOME_UNIT="$ROOT/bin/.config/systemd/user/gnome-keyring-daemon.service.d/10-pkcs11-only.conf"
GNOME_AUTOSTART="$ROOT/bin/.config/autostart/gnome-keyring-secrets.desktop"
VALIDATOR="$ROOT/bin/.local/bin/secret-service-provider"
NON_KWALLET_BUSCTL_BIN="$ROOT/tests/fixtures/non-kwallet-secret-service/bin"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_line() {
  local expected="$1"
  local file="$2"
  grep -Fqx -- "$expected" "$file" || fail "missing '$expected' in ${file#$ROOT/}"
}

assert_line 'Name=org.freedesktop.secrets' "$DBUS_SERVICE"
assert_line 'Exec=/usr/bin/ksecretd' "$DBUS_SERVICE"
assert_line '[Service]' "$GNOME_UNIT"
assert_line 'ExecStart=' "$GNOME_UNIT"
assert_line 'ExecStart=/usr/bin/gnome-keyring-daemon --foreground --components=pkcs11 --control-directory=%t/keyring' "$GNOME_UNIT"
! grep -Eq '^ExecStart=.*(^|[=,])secrets([,[:space:]]|$)' "$GNOME_UNIT" \
  || fail "GNOME Keyring unit override must not launch the secrets component"
assert_line '[Desktop Entry]' "$GNOME_AUTOSTART"
assert_line 'Hidden=true' "$GNOME_AUTOSTART"

bash -n "$VALIDATOR"

if failure_output="$(
  PATH="$NON_KWALLET_BUSCTL_BIN:$PATH" "$VALIDATOR" 2>&1
)"; then
  fail "validator accepted a non-KWallet Secret Service owner"
fi
expected_failure='expected ksecretd to own org.freedesktop.secrets'
[[ "$failure_output" == *"$expected_failure"* ]] \
  || fail "validator rejection lacked expected diagnostic: $failure_output"

echo "PASS: peregrine Secret Service policy selects KWallet and retains GNOME PKCS#11"
