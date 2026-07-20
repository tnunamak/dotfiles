#!/usr/bin/env bash
# Install a checksum-verified, user-scoped Android SDK bootstrap and shared AVD.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$ROOT/common.sh"
android_agent_device_init_paths

usage() {
  cat <<'EOF'
Usage: android-agent-device-setup [--install] [--update] [--uninstall] [--print-config] [--help]

--install       Install host prerequisites, a checksum-verified SDK bootstrap, fixed SDK package IDs, and the AVD.
--update        Explicitly update Android SDK packages after showing available updates.
--uninstall     Stop the shared device if owned, then remove the user-scoped SDK/AVD/state/cache/evidence directories.
--print-config  Print resolved user-scoped paths and fixed package IDs; no downloads.

--uninstall never touches kvm group membership or host packages (curl/unzip/python3/java);
those are host-level grants outside this capability's XDG-scoped state.
EOF
}

require_linux() {
  [[ "$(uname -s)" == Linux ]] || { echo "Android agent device currently requires Linux/KVM." >&2; exit 1; }
}

with_install_lock() {
  android_agent_device_mkdirs
  exec 8>"$ANDROID_AGENT_DEVICE_INSTALL_LOCK_FILE"
  flock -x 8
  "$@"
}

install_host_prerequisites() {
  local packages=() java_major
  command -v curl >/dev/null || packages+=(curl)
  command -v unzip >/dev/null || packages+=(unzip)
  command -v python3 >/dev/null || packages+=(python3)
  java_major="$(java -version 2>&1 | sed -n 's/.*version "\([0-9][0-9]*\).*/\1/p' | head -1 || true)"
  [[ "${java_major:-0}" -ge 17 ]] || packages+=(openjdk-21-jre-headless)
  if [[ ${#packages[@]} -gt 0 ]]; then
    command -v sudo >/dev/null || { echo "sudo is required to install missing host prerequisites: ${packages[*]}" >&2; exit 1; }
    sudo apt-get update
    sudo apt-get install -y ca-certificates "${packages[@]}"
  fi
  if [[ ! -e /dev/kvm ]]; then
    echo "KVM device /dev/kvm is absent. Enable CPU virtualization and install/enable the host KVM packages, then rerun diagnose." >&2
    exit 1
  fi
  if [[ ! -r /dev/kvm || ! -w /dev/kvm ]]; then
    if ! getent group kvm >/dev/null; then
      echo "KVM group is unavailable. Install/enable the host KVM packages, then rerun diagnose." >&2
      exit 1
    fi
    if ! id -nG "$USER" | tr ' ' '\n' | grep -qx kvm; then
      command -v sudo >/dev/null || { echo "sudo is required to add $USER to the kvm group." >&2; exit 1; }
      sudo usermod -aG kvm "$USER"
      echo "Added $USER to the kvm group. Log out and back in before using acceleration." >&2
      exit 1
    fi
    echo "This login cannot read/write /dev/kvm despite kvm membership. Log out/in, then rerun diagnose." >&2
    exit 1
  fi
}

install_cmdline_tools() {
  local sdkmanager archive actual_sha1 installed_revision stage
  sdkmanager="$(android_agent_device_sdkmanager)"
  if [[ -x "$sdkmanager" ]]; then
    installed_revision="$(sed -n 's/^Pkg.Revision=//p' "$ANDROID_SDK_ROOT/cmdline-tools/latest/source.properties" | head -n 1 || true)"
    [[ "$installed_revision" == "$ANDROID_AGENT_DEVICE_CMDLINE_TOOLS_PACKAGE_REVISION" ]] && return 0
    echo "Installed command-line tools revision ${installed_revision:-unknown} is not the required $ANDROID_AGENT_DEVICE_CMDLINE_TOOLS_PACKAGE_REVISION; repairing it." >&2
  fi
  mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools" "$ANDROID_AGENT_DEVICE_CACHE_DIR"
  archive="$ANDROID_AGENT_DEVICE_CACHE_DIR/commandlinetools-linux-${ANDROID_AGENT_DEVICE_CMDLINE_TOOLS_REVISION}.zip"
  if [[ ! -f "$archive" ]]; then
    curl --fail --location --proto '=https' --tlsv1.2 --retry 3 --output "$archive.part" "$ANDROID_AGENT_DEVICE_CMDLINE_TOOLS_URL"
    mv "$archive.part" "$archive"
  fi
  actual_sha1="$(sha1sum "$archive" | awk '{print $1}')"
  [[ "$actual_sha1" == "$ANDROID_AGENT_DEVICE_CMDLINE_TOOLS_SHA1" ]] || {
    rm -f "$archive"
    echo "Android command-line tools checksum mismatch (expected official $ANDROID_AGENT_DEVICE_CMDLINE_TOOLS_SHA1, got $actual_sha1)." >&2
    exit 1
  }
  stage="$(mktemp -d "$ANDROID_AGENT_DEVICE_CACHE_DIR/cmdline-tools.XXXXXX")"
  trap 'rm -rf "$stage"' RETURN
  unzip -q "$archive" -d "$stage"
  rm -rf "$ANDROID_SDK_ROOT/cmdline-tools/latest"
  mv "$stage/cmdline-tools" "$ANDROID_SDK_ROOT/cmdline-tools/latest"
  trap - RETURN
  rm -rf "$stage"
}

install_sdk_packages() {
  local sdkmanager license_status
  sdkmanager="$(android_agent_device_sdkmanager)"
  # sdkmanager closes stdin after the last prompt; `yes` consequently gets SIGPIPE.
  # Inspect sdkmanager's pipeline status rather than treating that expected producer exit as failure.
  set +e
  yes | "$sdkmanager" --sdk_root="$ANDROID_SDK_ROOT" --licenses >/dev/null
  license_status="${PIPESTATUS[1]}"
  set -e
  [[ "$license_status" == 0 ]] || { echo "Android SDK license acceptance failed." >&2; return "$license_status"; }
  # sdkmanager leaves a directory behind if a download is interrupted, then installs an unusable
  # `platform-tools-N` duplicate on retry. Repair only the canonical, incomplete package directory.
  if [[ -d "$ANDROID_SDK_ROOT/platform-tools" && ! -x "$ANDROID_SDK_ROOT/platform-tools/adb" ]]; then
    echo "Removing incomplete platform-tools download before retrying." >&2
    rm -rf "$ANDROID_SDK_ROOT/platform-tools"
  fi
  "$sdkmanager" --sdk_root="$ANDROID_SDK_ROOT" --channel=0 \
    "platform-tools" "emulator" "$ANDROID_AGENT_DEVICE_SYSTEM_IMAGE"
}

create_avd() {
  local avdmanager
  avdmanager="$(android_agent_device_avdmanager)"
  if [[ ! -f "$ANDROID_AVD_HOME/$ANDROID_AGENT_DEVICE_NAME.ini" ]]; then
    printf 'no\n' | "$avdmanager" --silent create avd --force --name "$ANDROID_AGENT_DEVICE_NAME" \
      --package "$ANDROID_AGENT_DEVICE_SYSTEM_IMAGE" --device "$ANDROID_AGENT_DEVICE_DEVICE_PROFILE"
  fi
  local config="$ANDROID_AVD_HOME/$ANDROID_AGENT_DEVICE_NAME.avd/config.ini"
  set_avd_property "$config" disk.dataPartition.size 8G
  set_avd_property "$config" hw.cpu.ncore "$ANDROID_AGENT_DEVICE_CORES"
  set_avd_property "$config" hw.gpu.enabled yes
  # A virtual hardware keyboard suppresses the on-screen IME, which defeats this device's purpose.
  set_avd_property "$config" hw.keyboard no
  set_avd_property "$config" hw.ramSize "$ANDROID_AGENT_DEVICE_RAM_MB"
  set_avd_property "$config" hw.sdCard no
  set_avd_property "$config" hw.sensors.orientation yes
  set_avd_property "$config" runtime.network.latency none
  set_avd_property "$config" runtime.network.speed full
  set_avd_property "$config" snapshot.present false
  set_avd_property "$config" vm.heapSize 512
}

set_avd_property() {
  local config="$1" key="$2" value="$3"
  if grep -q "^${key}=" "$config"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$config"
  else
    printf '%s=%s\n' "$key" "$value" >> "$config"
  fi
}

update_sdk_packages() {
  local sdkmanager
  sdkmanager="$(android_agent_device_sdkmanager)"
  "$sdkmanager" --sdk_root="$ANDROID_SDK_ROOT" --list --newer
  "$sdkmanager" --sdk_root="$ANDROID_SDK_ROOT" --update
}

uninstall_impl() {
  local cli="$ROOT/cli.sh"
  if [[ -f "$ANDROID_AGENT_DEVICE_STATE_DIR/emulator.state" ]]; then
    "$cli" stop || {
      echo "Refusing to remove SDK/AVD state while the recorded emulator could not be stopped cleanly. Inspect 'android-agent-device status --json' and retry." >&2
      return 1
    }
  fi
  rm -rf "$ANDROID_SDK_ROOT" "$ANDROID_AVD_HOME" "$ANDROID_USER_HOME" \
    "$ANDROID_AGENT_DEVICE_STATE_DIR" "$ANDROID_AGENT_DEVICE_CACHE_DIR" "$ANDROID_AGENT_DEVICE_EVIDENCE_DIR"
  # Only this capability's own namespace directories, never the shared XDG parent itself.
  rmdir --ignore-fail-on-non-empty "$XDG_DATA_HOME/android-agent-device" "$XDG_CACHE_HOME/android-agent-device" 2>/dev/null || true
  echo "Removed the user-scoped Android SDK, AVD, state, cache, and evidence directories."
  echo "kvm group membership and host packages (curl/unzip/python3/java) were left in place; remove those yourself if desired."
}

install_impl() {
  install_host_prerequisites
  install_cmdline_tools
  install_sdk_packages
  create_avd
  echo "Installed $ANDROID_AGENT_DEVICE_NAME. Run android-agent-device diagnose, then android-agent-device start."
}

update_impl() {
  [[ -x "$(android_agent_device_sdkmanager)" ]] || { echo "Run --install first." >&2; exit 1; }
  install_cmdline_tools
  update_sdk_packages
}

main() {
  case "${1:---help}" in
    --help|-h) usage ;;
    --print-config) android_agent_device_print_config ;;
    --install)
      require_linux
      with_install_lock install_impl
      ;;
    --update)
      require_linux
      with_install_lock update_impl
      ;;
    --uninstall)
      require_linux
      with_install_lock uninstall_impl
      ;;
    *) usage >&2; exit 2 ;;
  esac
}
main "$@"
