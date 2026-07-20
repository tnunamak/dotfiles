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

# Unset before invoking any subprocess CLI below. ANDROID_AGENT_DEVICE_LIB_ONLY would otherwise
# make a subprocess skip its own main(). The derived path vars use a self-referential default
# (e.g. ANDROID_AGENT_DEVICE_STATE_DIR="${ANDROID_AGENT_DEVICE_STATE_DIR:-...}") so an operator can
# pin them directly; once this script exported them from the first XDG_DATA_HOME above, later
# subtests exporting a new XDG_DATA_HOME would otherwise inherit the stale pinned paths.
unset ANDROID_AGENT_DEVICE_LIB_ONLY ANDROID_SDK_ROOT ANDROID_HOME ANDROID_AVD_HOME \
  ANDROID_USER_HOME ANDROID_EMULATOR_HOME ANDROID_AGENT_DEVICE_STATE_DIR \
  ANDROID_AGENT_DEVICE_CACHE_DIR ANDROID_AGENT_DEVICE_EVIDENCE_DIR \
  ANDROID_AGENT_DEVICE_LOCK_FILE ANDROID_AGENT_DEVICE_INSTALL_LOCK_FILE

# Installer and smoke retain explicit single-process boundaries rather than hidden prerequisites.
grep -q 'ANDROID_AGENT_DEVICE_INSTALL_LOCK_FILE' "$TEST_ROOT/android-agent-device/setup.sh"
grep -q 'ANDROID_AGENT_DEVICE_SMOKE_LOCK_HELD' "$TEST_ROOT/android-agent-device/smoke-test.sh"
! rg -q '\bnode\b' "$TEST_ROOT/android-agent-device/smoke-test.sh"

# --uninstall is a safe no-op against a never-installed tree (no downloads, no sudo).
uninstall_fresh="$tmp/uninstall-fresh"
(
  export XDG_DATA_HOME="$uninstall_fresh/data" XDG_CACHE_HOME="$uninstall_fresh/cache"
  "$TEST_ROOT/scripts/android-agent-device-setup.sh" --uninstall
)
[[ ! -e "$uninstall_fresh/data/android-agent-device" ]]

# --uninstall removes leftover state directories when no emulator is recorded as running, for a
# root this capability actually installed into (bearing its ownership sentinel).
uninstall_tmp="$tmp/uninstall-populated"
(
  export XDG_DATA_HOME="$uninstall_tmp/data" XDG_CACHE_HOME="$uninstall_tmp/cache"
  mkdir -p "$XDG_DATA_HOME/android-agent-device/sdk" "$XDG_DATA_HOME/android-agent-device/avd"
  touch "$XDG_DATA_HOME/android-agent-device/sdk/marker"
  printf 'marker=android-agent-device-capability-root\nversion=1\n' \
    > "$XDG_DATA_HOME/android-agent-device/sdk/.android-agent-device-owned"
  "$TEST_ROOT/scripts/android-agent-device-setup.sh" --uninstall
  [[ ! -e "$XDG_DATA_HOME/android-agent-device/sdk" ]]
)

# --uninstall refuses to delete state it cannot confirm is safe to stop (a live foreign PID).
uninstall_refuse="$tmp/uninstall-refuse"
(
  export XDG_DATA_HOME="$uninstall_refuse/data" XDG_CACHE_HOME="$uninstall_refuse/cache"
  mkdir -p "$XDG_DATA_HOME/android-agent-device/state"
  sleep 30 &
  foreign_pid=$!
  foreign_ticks="$(awk '{print $22}' "/proc/$foreign_pid/stat")"
  printf 'pid=%s\nstart_ticks=%s\nname=agent_pixel_8_api_36\nconsole_port=5556\nadb_port=5557\nowner_token=test\n' \
    "$foreign_pid" "$foreign_ticks" > "$XDG_DATA_HOME/android-agent-device/state/emulator.state"
  set +e
  "$TEST_ROOT/scripts/android-agent-device-setup.sh" --uninstall
  uninstall_status=$?
  set -e
  kill "$foreign_pid" 2>/dev/null || true
  wait "$foreign_pid" 2>/dev/null || true
  [[ $uninstall_status -ne 0 ]]
  [[ -f "$XDG_DATA_HOME/android-agent-device/state/emulator.state" ]]
)

# --uninstall refuses a documented path override that resolves outside this capability's
# namespace (the exact ANDROID_AGENT_DEVICE_SDK_ROOT=$HOME example from the adversarial review),
# and leaves the forbidden path untouched. $HOME has real content and no ownership sentinel.
uninstall_forbidden="$tmp/uninstall-forbidden"
forbidden_root="$tmp/pretend-home"
(
  mkdir -p "$forbidden_root/marker-should-survive"
  export XDG_DATA_HOME="$uninstall_forbidden/data" XDG_CACHE_HOME="$uninstall_forbidden/cache"
  export ANDROID_AGENT_DEVICE_SDK_ROOT="$forbidden_root"
  set +e
  "$TEST_ROOT/scripts/android-agent-device-setup.sh" --uninstall
  uninstall_status=$?
  set -e
  [[ $uninstall_status -ne 0 ]]
)
[[ -d "$forbidden_root/marker-should-survive" ]]

# Terra's exact nested-directory reproduction: a whole-path-component name match is not ownership.
# An unrelated project directory that happens to be named "android-agent-device", containing real
# user data, must survive uninstall untouched -- it was never installer-created and has no
# ownership sentinel, no matter how its path is shaped.
uninstall_nested_unrelated="$tmp/uninstall-nested-unrelated"
nested_root="$tmp/unrelated-project/android-agent-device"
(
  mkdir -p "$nested_root/important-user-data"
  printf keep > "$nested_root/important-user-data/marker"
  export XDG_DATA_HOME="$uninstall_nested_unrelated/data" XDG_CACHE_HOME="$uninstall_nested_unrelated/cache"
  export ANDROID_AGENT_DEVICE_SDK_ROOT="$nested_root"
  set +e
  "$TEST_ROOT/scripts/android-agent-device-setup.sh" --uninstall
  uninstall_status=$?
  set -e
  [[ $uninstall_status -ne 0 ]]
)
[[ -f "$nested_root/important-user-data/marker" ]]

# A symlinked override resolving (via realpath -m) outside a sentinel-bearing root is refused, and
# the real unrelated target survives -- the same nested-unrelated case reached through a symlink.
uninstall_symlink="$tmp/uninstall-symlink"
symlink_victim="$tmp/symlink-victim/android-agent-device"
(
  mkdir -p "$symlink_victim/important-user-data"
  printf keep > "$symlink_victim/important-user-data/marker"
  mkdir -p "$tmp/symlink-parent"
  ln -s "$symlink_victim" "$tmp/symlink-parent/android-agent-device"
  export XDG_DATA_HOME="$uninstall_symlink/data" XDG_CACHE_HOME="$uninstall_symlink/cache"
  export ANDROID_AGENT_DEVICE_SDK_ROOT="$tmp/symlink-parent/android-agent-device"
  set +e
  "$TEST_ROOT/scripts/android-agent-device-setup.sh" --uninstall
  uninstall_status=$?
  set -e
  [[ $uninstall_status -ne 0 ]]
)
[[ -f "$symlink_victim/important-user-data/marker" ]]

# A ../ traversal override resolving outside the sentinel-bearing root is refused the same way.
uninstall_traversal="$tmp/uninstall-traversal"
traversal_victim="$tmp/traversal-victim"
(
  mkdir -p "$traversal_victim/important-user-data"
  printf keep > "$traversal_victim/important-user-data/marker"
  mkdir -p "$tmp/traversal-parent/android-agent-device"
  export XDG_DATA_HOME="$uninstall_traversal/data" XDG_CACHE_HOME="$uninstall_traversal/cache"
  export ANDROID_AGENT_DEVICE_SDK_ROOT="$tmp/traversal-parent/android-agent-device/../../traversal-victim"
  set +e
  "$TEST_ROOT/scripts/android-agent-device-setup.sh" --uninstall
  uninstall_status=$?
  set -e
  [[ $uninstall_status -ne 0 ]]
)
[[ -f "$traversal_victim/important-user-data/marker" ]]

# --uninstall still removes a legitimately relocated custom root: the override just has to be a
# root this installer actually created (proven by its ownership sentinel), not literally under the
# default XDG tree.
uninstall_custom="$tmp/uninstall-custom"
custom_root="$tmp/relocated/android-agent-device/sdk"
(
  mkdir -p "$custom_root/marker"
  printf 'marker=android-agent-device-capability-root\nversion=1\n' \
    > "$custom_root/.android-agent-device-owned"
  export XDG_DATA_HOME="$uninstall_custom/data" XDG_CACHE_HOME="$uninstall_custom/cache"
  export ANDROID_AGENT_DEVICE_SDK_ROOT="$custom_root"
  "$TEST_ROOT/scripts/android-agent-device-setup.sh" --uninstall
)
[[ ! -e "$custom_root" ]]

# --uninstall refuses when the state file is missing entirely but the shared ADB port is occupied
# (e.g. state was lost/corrupted while a device from an earlier interrupted lifecycle is still up):
# the missing-state branch must still fail closed on occupancy, not just on an invalid state file.
uninstall_occupied="$tmp/uninstall-occupied"
(
  export XDG_DATA_HOME="$uninstall_occupied/data" XDG_CACHE_HOME="$uninstall_occupied/cache"
  python3 -c "
import socket, time
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
sock.bind(('127.0.0.1', 5557))
sock.listen(1)
time.sleep(10)
" &
  occupier_pid=$!
  sleep 0.5
  set +e
  "$TEST_ROOT/scripts/android-agent-device-setup.sh" --uninstall
  uninstall_status=$?
  set -e
  kill "$occupier_pid" 2>/dev/null || true
  wait "$occupier_pid" 2>/dev/null || true
  [[ $uninstall_status -ne 0 ]]
  [[ -d "$XDG_DATA_HOME/android-agent-device" ]]
)

# A forged ANDROID_AGENT_DEVICE_LOCK_HELD marker without a real inherited fd 9 cannot bypass the
# device lock: a genuine external holder must still block a fresh process that only sets the
# marker. -u ANDROID_AGENT_DEVICE_LIB_ONLY is required here: it was exported above (for the
# in-process lifecycle tests) and would otherwise make the invoked CLI subprocess skip its own
# main(), producing a false pass with no relation to locking.
lock_bypass="$tmp/lock-bypass"
(
  export XDG_DATA_HOME="$lock_bypass/data" XDG_CACHE_HOME="$lock_bypass/cache"
  export ANDROID_AGENT_DEVICE_LIB_ONLY=1
  source "$TEST_ROOT/android-agent-device/cli.sh"
  android_agent_device_mkdirs
  exec 9>"$ANDROID_AGENT_DEVICE_LOCK_FILE"
  flock -x 9

  marker="$lock_bypass/child-ran"
  env -u ANDROID_AGENT_DEVICE_LIB_ONLY \
    XDG_DATA_HOME="$XDG_DATA_HOME" XDG_CACHE_HOME="$XDG_CACHE_HOME" \
    ANDROID_AGENT_DEVICE_LOCK_HELD=1 \
    bash -c "'$TEST_ROOT/bin/.local/bin/android-agent-device' stop >/dev/null 2>&1; touch '$marker'" 9>&- &
  child_pid=$!

  sleep 1.5
  [[ ! -f "$marker" ]]

  exec 9>&-
  wait "$child_pid"
  [[ -f "$marker" ]]
)

# --install/--update/--uninstall take the device lock too (fd 9), not just the separate install
# lock: a concurrent --uninstall must block while an agent (or another install/update) holds the
# device lock, and proceed once it is released. This is the coherent lock hierarchy the review
# asked for in place of two independent locks that could race SDK/AVD mutation against a live
# emulator.
lock_hierarchy="$tmp/lock-hierarchy"
(
  export XDG_DATA_HOME="$lock_hierarchy/data" XDG_CACHE_HOME="$lock_hierarchy/cache"
  export ANDROID_AGENT_DEVICE_LIB_ONLY=1
  source "$TEST_ROOT/android-agent-device/cli.sh"
  android_agent_device_mkdirs
  exec 9>"$ANDROID_AGENT_DEVICE_LOCK_FILE"
  flock -x 9

  marker="$lock_hierarchy/uninstall-ran"
  env -u ANDROID_AGENT_DEVICE_LIB_ONLY \
    XDG_DATA_HOME="$XDG_DATA_HOME" XDG_CACHE_HOME="$XDG_CACHE_HOME" \
    bash -c "'$TEST_ROOT/scripts/android-agent-device-setup.sh' --uninstall >/dev/null 2>&1; touch '$marker'" 9>&- &
  bg_pid=$!

  sleep 1.5
  [[ ! -f "$marker" ]]

  exec 9>&-
  wait "$bg_pid"
  [[ -f "$marker" ]]
)

# Terra's exact nested-lock deadlock reproduction: `android-agent-device lock -- ...` is the
# documented public way to hold the device lock for a multi-command critical section. If COMMAND
# invokes the setup script's --uninstall, it must reuse the inherited fd 9 rather than replacing it
# and blocking on itself. This must complete well within the timeout, not hang until it fires.
lock_nested_deadlock="$tmp/lock-nested-deadlock"
mkdir -p "$lock_nested_deadlock/data" "$lock_nested_deadlock/cache"
nested_status=0
timeout 8s env XDG_DATA_HOME="$lock_nested_deadlock/data" XDG_CACHE_HOME="$lock_nested_deadlock/cache" \
  "$TEST_ROOT/bin/.local/bin/android-agent-device" lock -- env \
    XDG_DATA_HOME="$lock_nested_deadlock/data" XDG_CACHE_HOME="$lock_nested_deadlock/cache" \
    "$TEST_ROOT/scripts/android-agent-device-setup.sh" --uninstall >/dev/null 2>&1 || nested_status=$?
[[ $nested_status -ne 124 ]]

# Inverse-order contention: a process holding both locks via with_install_lock (device lock fd 9
# acquired/validated first, then install lock fd 8) must make a concurrent device-lock-only caller
# (cli.sh's with_lock, the start/stop/run/reset path) block until release, and both must eventually
# complete -- proving the two entry points cannot each wait on a lock the other already holds.
lock_inverse_order="$tmp/lock-inverse-order"
(
  export XDG_DATA_HOME="$lock_inverse_order/data" XDG_CACHE_HOME="$lock_inverse_order/cache"
  marker_a="$lock_inverse_order/a-ran"
  marker_b="$lock_inverse_order/b-ran"

  env XDG_DATA_HOME="$XDG_DATA_HOME" XDG_CACHE_HOME="$XDG_CACHE_HOME" \
    ANDROID_AGENT_DEVICE_LIB_ONLY=1 \
    bash -c "
      source '$TEST_ROOT/android-agent-device/setup.sh'
      with_install_lock bash -c 'sleep 2; touch \"$marker_a\"'
    " &
  a_pid=$!

  sleep 0.5

  env XDG_DATA_HOME="$XDG_DATA_HOME" XDG_CACHE_HOME="$XDG_CACHE_HOME" \
    ANDROID_AGENT_DEVICE_LIB_ONLY=1 \
    bash -c "
      source '$TEST_ROOT/android-agent-device/cli.sh'
      with_lock bash -c 'touch \"$marker_b\"'
    " &
  b_pid=$!

  sleep 1
  [[ ! -f "$marker_b" ]]

  wait "$a_pid" "$b_pid"
  [[ -f "$marker_a" && -f "$marker_b" ]]
)

echo 'PASS android-agent-device lifecycle/configuration contracts (no downloads)'
