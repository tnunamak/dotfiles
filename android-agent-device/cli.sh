#!/usr/bin/env bash
# Locked lifecycle CLI for the one shared Android emulator.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$ROOT/common.sh"
android_agent_device_init_paths

usage() {
  cat <<'EOF'
Usage: android-agent-device <command> [options]

Commands:
  start [--wipe]       boot the named shared device and wait for Android readiness
  status [--json]      report device ownership/readiness without changing it
  lock -- COMMAND...   hold the exclusive device lock while executing COMMAND
  run -- ADB_ARGS...   execute a locked adb command against the owned shared device
  screenshot [PATH]    capture a PNG (default: timestamped evidence directory)
  logs [PATH]          capture filtered logcat (default: timestamped evidence directory)
  stop                 request a clean shutdown of this CLI's recorded emulator only
  reset                stop, wipe, and boot a fresh device under one lock
  diagnose [--json]    report KVM, SDK, AVD, disk, and browser prerequisites

This CLI serializes its own commands. Do not invoke adb/emulator directly against this AVD.
EOF
}

adb_path() { android_agent_device_adb; }
emulator_path() { android_agent_device_emulator; }
avd_ini() { printf '%s/%s.ini\n' "$ANDROID_AVD_HOME" "$ANDROID_AGENT_DEVICE_NAME"; }
state_file() { printf '%s/emulator.state\n' "$ANDROID_AGENT_DEVICE_STATE_DIR"; }
log_file() { printf '%s/emulator.log\n' "$ANDROID_AGENT_DEVICE_STATE_DIR"; }

with_lock() {
  android_agent_device_mkdirs
  if [[ "${ANDROID_AGENT_DEVICE_LOCK_HELD:-}" == 1 ]]; then
    "$@"
    return
  fi
  exec 9>"$ANDROID_AGENT_DEVICE_LOCK_FILE"
  flock -x 9
  ANDROID_AGENT_DEVICE_LOCK_HELD=1 "$@"
}

state_value() {
  local key="$1"
  [[ -f "$(state_file)" ]] || return 1
  sed -n "s/^${key}=//p" "$(state_file)" | head -n 1
}

recorded_pid() { state_value pid; }
recorded_start_ticks() { state_value start_ticks; }

process_start_ticks() {
  local pid="$1"
  [[ -r "/proc/$pid/stat" ]] || return 1
  awk '{print $22}' "/proc/$pid/stat"
}

recorded_process_alive() {
  local pid ticks actual
  pid="$(recorded_pid 2>/dev/null || true)"
  ticks="$(recorded_start_ticks 2>/dev/null || true)"
  [[ "$pid" =~ ^[0-9]+$ && "$ticks" =~ ^[0-9]+$ ]] || return 1
  actual="$(process_start_ticks "$pid" 2>/dev/null || true)"
  [[ "$actual" == "$ticks" ]]
}

process_arguments_match() {
  local pid="$1" argument next="" saw_avd=false saw_port=false
  [[ -r "/proc/$pid/cmdline" ]] || return 1
  while IFS= read -r argument; do
    if [[ "$next" == avd ]]; then
      [[ "$argument" == "$ANDROID_AGENT_DEVICE_NAME" ]] || return 1
      saw_avd=true
      next=""
      continue
    fi
    if [[ "$next" == port ]]; then
      [[ "$argument" == "$ANDROID_AGENT_DEVICE_PORT" ]] || return 1
      saw_port=true
      next=""
      continue
    fi
    case "$argument" in
      -avd) next=avd ;;
      -port) next=port ;;
    esac
  done < <(tr '\0' '\n' < "/proc/$pid/cmdline")
  [[ "$saw_avd" == true && "$saw_port" == true ]]
}

owned_process_valid() {
  local pid
  [[ -f "$(state_file)" ]] || return 1
  [[ "$(state_value name 2>/dev/null || true)" == "$ANDROID_AGENT_DEVICE_NAME" ]] || return 1
  [[ "$(state_value console_port 2>/dev/null || true)" == "$ANDROID_AGENT_DEVICE_PORT" ]] || return 1
  [[ "$(state_value adb_port 2>/dev/null || true)" == "$ANDROID_AGENT_DEVICE_ADB_PORT" ]] || return 1
  recorded_process_alive || return 1
  pid="$(recorded_pid)"
  process_arguments_match "$pid"
}

write_state() {
  local pid="$1" ticks stage owner_token="${ANDROID_AGENT_DEVICE_OWNER_TOKEN:-}"
  [[ "$owner_token" =~ ^[A-Za-z0-9._-]*$ ]] || { echo 'ANDROID_AGENT_DEVICE_OWNER_TOKEN may contain only letters, numbers, dot, underscore, and hyphen.' >&2; return 1; }
  ticks="$(process_start_ticks "$pid")"
  stage="$(mktemp "$ANDROID_AGENT_DEVICE_STATE_DIR/emulator.state.XXXXXX")"
  {
    printf 'pid=%s\n' "$pid"
    printf 'start_ticks=%s\n' "$ticks"
    printf 'name=%s\n' "$ANDROID_AGENT_DEVICE_NAME"
    printf 'console_port=%s\n' "$ANDROID_AGENT_DEVICE_PORT"
    printf 'adb_port=%s\n' "$ANDROID_AGENT_DEVICE_ADB_PORT"
    printf 'owner_token=%s\n' "$owner_token"
  } > "$stage"
  mv "$stage" "$(state_file)"
}

adb_ready() {
  local adb
  adb="$(adb_path)"
  [[ -x "$adb" ]] || return 1
  [[ "$("$adb" -s "$ANDROID_AGENT_DEVICE_SERIAL" get-state 2>/dev/null || true)" == device ]]
}

device_identity() {
  local adb value
  adb="$(adb_path)"
  adb_ready || return 1
  value="$("$adb" -s "$ANDROID_AGENT_DEVICE_SERIAL" shell getprop ro.boot.qemu.avd_name 2>/dev/null | tr -d '\r')"
  [[ -n "$value" ]] || value="$("$adb" -s "$ANDROID_AGENT_DEVICE_SERIAL" shell getprop ro.kernel.qemu.avd_name 2>/dev/null | tr -d '\r')"
  [[ "$value" == "$ANDROID_AGENT_DEVICE_NAME" ]]
}

boot_completed() {
  adb_ready && [[ "$("$(adb_path)" -s "$ANDROID_AGENT_DEVICE_SERIAL" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == 1 ]]
}

port_listening() {
  local port="$1"
  command -v ss >/dev/null 2>&1 && ss -ltnH "sport = :$port" 2>/dev/null | grep -q .
}

port_bindable() {
  local port="$1"
  python3 - "$port" >/dev/null 2>&1 <<'PY'
import socket
import sys

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
try:
    sock.bind(("127.0.0.1", int(sys.argv[1])))
finally:
    sock.close()
PY
}

port_available() {
  local port="$1"
  ! port_listening "$port" && port_bindable "$port"
}

ports_available() {
  port_available "$ANDROID_AGENT_DEVICE_PORT" && port_available "$ANDROID_AGENT_DEVICE_ADB_PORT"
}

recorded_ports_occupied() {
  ! port_available "$ANDROID_AGENT_DEVICE_PORT" && ! port_available "$ANDROID_AGENT_DEVICE_ADB_PORT"
}

require_recorded_ports_occupied() {
  recorded_ports_occupied || { echo "The recorded emulator process does not hold both expected ports ($ANDROID_AGENT_DEVICE_PORT/$ANDROID_AGENT_DEVICE_ADB_PORT); refusing to use it." >&2; return 1; }
}

require_ports_available() {
  local failed=false
  if ! port_available "$ANDROID_AGENT_DEVICE_PORT"; then
    echo "Android emulator console port $ANDROID_AGENT_DEVICE_PORT is in use." >&2
    failed=true
  fi
  if ! port_available "$ANDROID_AGENT_DEVICE_ADB_PORT"; then
    echo "Android emulator adb port $ANDROID_AGENT_DEVICE_ADB_PORT is in use." >&2
    failed=true
  fi
  [[ "$failed" == false ]] || return 1
}

browser_package() {
  local adb package
  adb="$(adb_path)"
  for package in com.android.chrome org.chromium.chrome; do
    if "$adb" -s "$ANDROID_AGENT_DEVICE_SERIAL" shell pm path "$package" 2>/dev/null | grep -q '^package:'; then
      printf '%s\n' "$package"
      return 0
    fi
  done
  return 1
}

status_impl() {
  local format="${1:-text}" state=stopped browser=missing pid="" owned=false identity=false owner_token=""
  pid="$(recorded_pid 2>/dev/null || true)"
  owner_token="$(state_value owner_token 2>/dev/null || true)"
  owned_process_valid && owned=true
  if adb_ready; then
    state=device
    device_identity && identity=true
  fi
  if [[ "$owned" == true && "$identity" == true ]] && boot_completed && recorded_ports_occupied; then
    state=ready
    browser="$(browser_package 2>/dev/null || printf missing)"
  elif adb_ready && [[ "$identity" != true || "$owned" != true ]]; then
    state=mismatch
  fi
  if [[ "$format" == json ]]; then
    printf '{"name":"%s","serial":"%s","state":"%s","pid":%s,"owned":%s,"identity":%s,"owner_token":"%s","browser":"%s"}\n' \
      "$ANDROID_AGENT_DEVICE_NAME" "$ANDROID_AGENT_DEVICE_SERIAL" "$state" "${pid:-null}" "$owned" "$identity" "$owner_token" "$browser"
  else
    printf 'name=%s\nserial=%s\nstate=%s\npid=%s\nowned=%s\nidentity=%s\nowner_token=%s\nbrowser=%s\n' \
      "$ANDROID_AGENT_DEVICE_NAME" "$ANDROID_AGENT_DEVICE_SERIAL" "$state" "${pid:-}" "$owned" "$identity" "$owner_token" "$browser"
  fi
}

wait_for_boot() {
  local adb deadline
  adb="$(adb_path)"
  timeout 180 "$adb" -s "$ANDROID_AGENT_DEVICE_SERIAL" wait-for-device
  deadline=$((SECONDS + 180))
  until boot_completed && device_identity; do
    if adb_ready && ! device_identity; then
      echo "The emulator at $ANDROID_AGENT_DEVICE_SERIAL does not identify as $ANDROID_AGENT_DEVICE_NAME; refusing to use it." >&2
      return 1
    fi
    (( SECONDS < deadline )) || { echo "Timed out waiting for Android boot. See $(log_file)." >&2; return 1; }
    sleep 2
  done
}

clear_stale_state_if_safe() {
  [[ -f "$(state_file)" ]] || return 0
  if ! recorded_process_alive && ports_available && ! adb_ready; then
    rm -f "$(state_file)"
    return 0
  fi
  return 1
}

start_impl() {
  local wipe="${1:-false}" emulator pid
  [[ -x "$(emulator_path)" ]] || { echo "Android SDK is not installed. Run android-agent-device-setup --install." >&2; return 1; }
  [[ -f "$(avd_ini)" ]] || { echo "Shared AVD is absent. Run android-agent-device-setup --install." >&2; return 1; }
  if [[ -f "$(state_file)" ]] && ! owned_process_valid; then
    clear_stale_state_if_safe || { echo "Recorded emulator ownership does not match a live process or ports. Refusing to reuse or replace it; run diagnose and inspect $(state_file)." >&2; return 1; }
  fi
  if owned_process_valid; then
    [[ "$wipe" != true ]] || { echo "start --wipe refuses an existing managed emulator. Use reset for an atomic stop/wipe/start." >&2; return 1; }
    if adb_ready && ! device_identity; then
      echo "The device at $ANDROID_AGENT_DEVICE_SERIAL has the wrong AVD identity; refusing reuse." >&2
      return 1
    fi
    echo "Shared Android device process is already recorded; waiting for readiness."
    wait_for_boot
    require_recorded_ports_occupied
    echo "Shared Android device is ready: $ANDROID_AGENT_DEVICE_SERIAL"
    return 0
  fi
  if adb_ready; then
    echo "An unrecorded Android device occupies $ANDROID_AGENT_DEVICE_SERIAL; refusing to use it." >&2
    return 1
  fi
  require_ports_available
  emulator="$(emulator_path)"
  : > "$(log_file)"
  local args=( -avd "$ANDROID_AGENT_DEVICE_NAME" -port "$ANDROID_AGENT_DEVICE_PORT" -accel on
    -no-snapshot -no-boot-anim -noaudio -no-metrics -no-window -gpu swiftshader_indirect
    -memory "$ANDROID_AGENT_DEVICE_RAM_MB" -cores "$ANDROID_AGENT_DEVICE_CORES"
    -camera-back none -camera-front none )
  [[ "$wipe" == true ]] && args+=( -wipe-data )
  # Do not let the detached emulator inherit fd 9: it is the CLI's flock and would
  # otherwise serialize every later agent action for the whole emulator lifetime.
  nohup "$emulator" "${args[@]}" 9>&- >>"$(log_file)" 2>&1 &
  pid="$!"
  sleep 1
  if ! kill -0 "$pid" 2>/dev/null; then
    echo "Emulator exited before ownership could be recorded. See $(log_file)." >&2
    return 1
  fi
  write_state "$pid"
  wait_for_boot
  require_recorded_ports_occupied
  echo "Shared Android device is ready: $ANDROID_AGENT_DEVICE_SERIAL"
}

wait_for_stop() {
  local deadline="$1"
  until ! recorded_process_alive && ports_available; do
    (( SECONDS < deadline )) || return 1
    sleep 1
  done
}

stop_impl() {
  local adb pid deadline
  if [[ ! -f "$(state_file)" ]]; then
    if adb_ready || ! ports_available; then
      echo "No recorded emulator ownership exists, but the shared serial or ports are occupied. Refusing to stop an unowned process." >&2
      return 1
    fi
    echo "Shared Android device is already stopped."
    return 0
  fi
  if ! owned_process_valid; then
    clear_stale_state_if_safe && { echo "Cleared stale stopped emulator state."; return 0; }
    echo "Recorded emulator ownership failed validation; refusing to kill a possibly unrelated process. State is preserved at $(state_file)." >&2
    return 1
  fi
  if adb_ready && ! device_identity; then
    echo "The connected emulator identity does not match $ANDROID_AGENT_DEVICE_NAME; refusing adb shutdown. State is preserved." >&2
    return 1
  fi
  adb="$(adb_path)"
  pid="$(recorded_pid)"
  if adb_ready; then
    "$adb" -s "$ANDROID_AGENT_DEVICE_SERIAL" emu kill >/dev/null 2>&1 || true
  fi
  deadline=$((SECONDS + 30))
  if ! wait_for_stop "$deadline"; then
    if recorded_process_alive && owned_process_valid; then
      kill -TERM "$pid" 2>/dev/null || true
    elif recorded_process_alive; then
      echo "Ownership changed while stopping; refusing to signal a process. State is preserved." >&2
      return 1
    fi
    deadline=$((SECONDS + 30))
    if ! wait_for_stop "$deadline"; then
      echo "Timed out waiting for the recorded emulator process and both ports to disappear. State is preserved at $(state_file)." >&2
      return 1
    fi
  fi
  rm -f "$(state_file)"
  echo "Shared Android device stopped."
}

reset_impl() {
  stop_impl
  start_impl true
}

require_owned_ready() {
  owned_process_valid || { echo "Recorded emulator ownership is invalid; refusing to target adb." >&2; return 1; }
  require_recorded_ports_occupied
  boot_completed && device_identity || { echo "The recorded shared emulator is not ready with the expected AVD identity." >&2; return 1; }
}

run_impl() {
  require_owned_ready
  "$(adb_path)" -s "$ANDROID_AGENT_DEVICE_SERIAL" "$@"
}

screenshot_impl() {
  local destination="$1"
  require_owned_ready
  [[ -n "$destination" ]] || destination="$ANDROID_AGENT_DEVICE_EVIDENCE_DIR/screen-$(date -u +%Y%m%dT%H%M%SZ).png"
  mkdir -p "$(dirname "$destination")"
  "$(adb_path)" -s "$ANDROID_AGENT_DEVICE_SERIAL" exec-out screencap -p > "$destination"
  printf '%s\n' "$destination"
}

logs_impl() {
  local destination="$1"
  require_owned_ready
  [[ -n "$destination" ]] || destination="$ANDROID_AGENT_DEVICE_EVIDENCE_DIR/logcat-$(date -u +%Y%m%dT%H%M%SZ).txt"
  mkdir -p "$(dirname "$destination")"
  "$(adb_path)" -s "$ANDROID_AGENT_DEVICE_SERIAL" logcat -d -v threadtime > "$destination"
  printf '%s\n' "$destination"
}

diagnostic_disk_kib() {
  local path="$XDG_DATA_HOME"
  while [[ ! -e "$path" && "$path" != / ]]; do path="$(dirname "$path")"; done
  df -Pk "$path" | awk 'NR==2 {print $4}'
}

diagnose_impl() {
  local format="${1:-text}" kvm_device_access=false kvm_group=false accel_check=null sdk=false avd=false browser=missing disk_kb
  [[ -r /dev/kvm && -w /dev/kvm ]] && kvm_device_access=true
  id -nG | tr ' ' '\n' | grep -qx kvm && kvm_group=true
  if [[ -x "$(emulator_path)" ]]; then
    sdk=true
    if "$(emulator_path)" -accel-check >/dev/null 2>&1; then accel_check=true; else accel_check=false; fi
  fi
  [[ -f "$(avd_ini)" ]] && avd=true
  if owned_process_valid && boot_completed && device_identity; then browser="$(browser_package 2>/dev/null || printf missing)"; fi
  disk_kb="$(diagnostic_disk_kib)"
  if [[ "$format" == json ]]; then
    printf '{"kvm_device_access":%s,"kvm_group":%s,"emulator_accel_check":%s,"sdk_installed":%s,"avd_installed":%s,"browser":"%s","free_kib":%s}\n' \
      "$kvm_device_access" "$kvm_group" "$accel_check" "$sdk" "$avd" "$browser" "$disk_kb"
  else
    printf 'kvm_device_access=%s\nkvm_group=%s\nemulator_accel_check=%s\nsdk_installed=%s\navd_installed=%s\nbrowser=%s\nfree_kib=%s\n' \
      "$kvm_device_access" "$kvm_group" "$accel_check" "$sdk" "$avd" "$browser" "$disk_kb"
    if [[ "$kvm_device_access" != true ]]; then
      echo 'KVM node access is unavailable. Ensure /dev/kvm exists, add this user to kvm, then log out/in.' >&2
    elif [[ "$accel_check" == false ]]; then
      echo 'The emulator reports that acceleration is unavailable; inspect emulator -accel-check output.' >&2
    fi
  fi
}

main() {
  local command="${1:---help}"
  shift || true
  case "$command" in
    --help|-h|help) usage ;;
    start)
      [[ $# -le 1 && ( $# -eq 0 || "$1" == --wipe ) ]] || { usage >&2; exit 2; }
      with_lock start_impl "$([[ ${1:-} == --wipe ]] && printf true || printf false)"
      ;;
    status)
      [[ $# -le 1 && ( $# -eq 0 || "$1" == --json ) ]] || { usage >&2; exit 2; }
      status_impl "$([[ ${1:-} == --json ]] && printf json || printf text)"
      ;;
    lock)
      [[ "${1:-}" == -- && $# -ge 2 ]] || { echo 'lock requires: lock -- COMMAND...' >&2; exit 2; }
      shift
      with_lock "$@"
      ;;
    run)
      [[ "${1:-}" == -- && $# -ge 2 ]] || { echo 'run requires: run -- ADB_ARGS...' >&2; exit 2; }
      shift
      with_lock run_impl "$@"
      ;;
    screenshot)
      [[ $# -le 1 ]] || { usage >&2; exit 2; }
      with_lock screenshot_impl "${1:-}"
      ;;
    logs)
      [[ $# -le 1 ]] || { usage >&2; exit 2; }
      with_lock logs_impl "${1:-}"
      ;;
    stop) [[ $# -eq 0 ]] || { usage >&2; exit 2; }; with_lock stop_impl ;;
    reset) [[ $# -eq 0 ]] || { usage >&2; exit 2; }; with_lock reset_impl ;;
    diagnose)
      [[ $# -le 1 && ( $# -eq 0 || "$1" == --json ) ]] || { usage >&2; exit 2; }
      diagnose_impl "$([[ ${1:-} == --json ]] && printf json || printf text)"
      ;;
    *) usage >&2; exit 2 ;;
  esac
}

[[ "${ANDROID_AGENT_DEVICE_LIB_ONLY:-}" == 1 ]] || main "$@"
