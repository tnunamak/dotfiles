#!/usr/bin/env bash
set -euo pipefail

TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

export XDG_DATA_HOME="$tmp/data"
export XDG_CACHE_HOME="$tmp/cache"
config="$($TEST_ROOT/scripts/android-agent-device-setup.sh --print-config)"
grep -qx "sdk_root=$tmp/data/android-agent-device/sdk" <<<"$config"
grep -qx 'system_image=system-images;android-36;google_apis_playstore;x86_64' <<<"$config"
grep -qx 'cmdline_tools_revision=14742923' <<<"$config"
grep -qx 'cmdline_tools_package_revision=20.0' <<<"$config"

bash -n "$TEST_ROOT/android-agent-device/common.sh" "$TEST_ROOT/android-agent-device/setup.sh" \
  "$TEST_ROOT/android-agent-device/cli.sh" "$TEST_ROOT/android-agent-device/smoke-test.sh" \
  "$TEST_ROOT/scripts/android-agent-device-setup.sh" "$TEST_ROOT/bin/.local/bin/android-agent-device"

help="$($TEST_ROOT/bin/.local/bin/android-agent-device --help)"
grep -q 'lock -- COMMAND' <<<"$help"
grep -q 'recorded emulator only' <<<"$help"

# diagnose must remain machine-readable before any XDG path has been created.
fresh="$tmp/fresh"
diagnose="$(XDG_DATA_HOME="$fresh/data/absent" XDG_CACHE_HOME="$fresh/cache/absent" "$TEST_ROOT/bin/.local/bin/android-agent-device" diagnose --json)"
python3 -c 'import json, sys; value=json.load(sys.stdin); assert isinstance(value["free_kib"], int); assert "kvm_device_access" in value; assert "emulator_accel_check" in value' <<<"$diagnose"

# Source lifecycle functions with a disposable state directory; no SDK/download is required.
export ANDROID_AGENT_DEVICE_LIB_ONLY=1
# shellcheck source=../android-agent-device/cli.sh
source "$TEST_ROOT/android-agent-device/cli.sh"
android_agent_device_mkdirs
mkdir -p "$(dirname "$(emulator_path)")" "$(dirname "$(avd_ini)")"
printf '#!/usr/bin/env bash\nexit 1\n' > "$(emulator_path)"
chmod +x "$(emulator_path)"
touch "$(avd_ini)"

# --wipe is never a silent no-op when a managed process is already present.
set +e
wipe_output="$(
  {
    owned_process_valid() { return 0; }
    adb_ready() { return 0; }
    device_identity() { return 0; }
    start_impl true
  } 2>&1
)"
wipe_status=$?
set -e
[[ $wipe_status -ne 0 ]]
grep -q 'Use reset' <<<"$wipe_output"

# A live PID with the wrong command line cannot be treated as the recorded emulator or killed.
sleep 30 &
foreign_pid=$!
foreign_ticks="$(awk '{print $22}' "/proc/$foreign_pid/stat")"
printf 'pid=%s\nstart_ticks=%s\nname=%s\nconsole_port=%s\nadb_port=%s\n' \
  "$foreign_pid" "$foreign_ticks" "$ANDROID_AGENT_DEVICE_NAME" \
  "$ANDROID_AGENT_DEVICE_PORT" "$ANDROID_AGENT_DEVICE_ADB_PORT" > "$(state_file)"
! owned_process_valid
set +e
stop_output="$(stop_impl 2>&1)"
stop_status=$?
set -e
[[ $stop_status -ne 0 ]]
kill -0 "$foreign_pid"
[[ -f "$(state_file)" ]]
grep -q 'refusing to kill' <<<"$stop_output"
kill "$foreign_pid" 2>/dev/null || true
wait "$foreign_pid" 2>/dev/null || true
rm -f "$(state_file)"

# Both emulator ports are part of the ownership contract; a missing one fails closed.
(
  port_available() { return 1; }
  recorded_ports_occupied
  port_available() { [[ "$1" == "$ANDROID_AGENT_DEVICE_PORT" ]]; }
  ! recorded_ports_occupied
)

# reset is composed of stop then wipe/start; callers hold one CLI lock around this function.
lifecycle=""
stop_impl() { lifecycle+='stop '; }
start_impl() { lifecycle+="start:$1 "; }
reset_impl
[[ "$lifecycle" == 'stop start:true ' ]]
unset -f stop_impl start_impl

# Installer and smoke retain explicit single-process boundaries rather than hidden prerequisites.
grep -q 'ANDROID_AGENT_DEVICE_INSTALL_LOCK_FILE' "$TEST_ROOT/android-agent-device/setup.sh"
grep -q 'ANDROID_AGENT_DEVICE_SMOKE_LOCK_HELD' "$TEST_ROOT/android-agent-device/smoke-test.sh"
! rg -q '\bnode\b' "$TEST_ROOT/android-agent-device/smoke-test.sh"

echo 'PASS android-agent-device lifecycle/configuration contracts (no downloads)'
