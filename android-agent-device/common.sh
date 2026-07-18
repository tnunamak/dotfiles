#!/usr/bin/env bash
# Shared configuration for the user-scoped Android agent device. Source only.

ANDROID_AGENT_DEVICE_NAME="agent_pixel_8_api_36"
ANDROID_AGENT_DEVICE_PORT="5556"
ANDROID_AGENT_DEVICE_ADB_PORT="5557"
ANDROID_AGENT_DEVICE_SERIAL="emulator-${ANDROID_AGENT_DEVICE_PORT}"
ANDROID_AGENT_DEVICE_SYSTEM_IMAGE="system-images;android-36;google_apis_playstore;x86_64"
ANDROID_AGENT_DEVICE_DEVICE_PROFILE="pixel_8"
ANDROID_AGENT_DEVICE_CMDLINE_TOOLS_REVISION="14742923"
ANDROID_AGENT_DEVICE_CMDLINE_TOOLS_PACKAGE_REVISION="20.0"
ANDROID_AGENT_DEVICE_CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-14742923_latest.zip"
# Google publishes this SHA-1 in repository2-1.xml for this exact artifact.
ANDROID_AGENT_DEVICE_CMDLINE_TOOLS_SHA1="48833c34b761c10cb20bcd16582129395d121b27"
ANDROID_AGENT_DEVICE_RAM_MB="3072"
ANDROID_AGENT_DEVICE_CORES="4"

android_agent_device_init_paths() {
  : "${XDG_DATA_HOME:=$HOME/.local/share}"
  : "${XDG_CACHE_HOME:=$HOME/.cache}"
  export ANDROID_SDK_ROOT="${ANDROID_AGENT_DEVICE_SDK_ROOT:-$XDG_DATA_HOME/android-agent-device/sdk}"
  export ANDROID_HOME="$ANDROID_SDK_ROOT"
  export ANDROID_AVD_HOME="${ANDROID_AGENT_DEVICE_AVD_HOME:-$XDG_DATA_HOME/android-agent-device/avd}"
  export ANDROID_USER_HOME="${ANDROID_AGENT_DEVICE_USER_HOME:-$XDG_DATA_HOME/android-agent-device/android-home}"
  export ANDROID_EMULATOR_HOME="$ANDROID_AVD_HOME"
  # ANDROID_SDK_HOME is deprecated and makes current avdmanager search for a nested SDK;
  # ANDROID_HOME/ANDROID_SDK_ROOT locate tools while ANDROID_USER_HOME owns user configuration.
  unset ANDROID_SDK_HOME
  export ANDROID_AGENT_DEVICE_STATE_DIR="${ANDROID_AGENT_DEVICE_STATE_DIR:-$XDG_DATA_HOME/android-agent-device/state}"
  export ANDROID_AGENT_DEVICE_CACHE_DIR="${ANDROID_AGENT_DEVICE_CACHE_DIR:-$XDG_CACHE_HOME/android-agent-device}"
  export ANDROID_AGENT_DEVICE_EVIDENCE_DIR="${ANDROID_AGENT_DEVICE_EVIDENCE_DIR:-$XDG_DATA_HOME/android-agent-device/evidence}"
  export ANDROID_AGENT_DEVICE_LOCK_FILE="$ANDROID_AGENT_DEVICE_STATE_DIR/device.lock"
  export ANDROID_AGENT_DEVICE_INSTALL_LOCK_FILE="$ANDROID_AGENT_DEVICE_STATE_DIR/install.lock"
  export ANDROID_EMULATOR_WAIT_TIME_BEFORE_KILL="20"
}

android_agent_device_mkdirs() {
  mkdir -p "$ANDROID_SDK_ROOT" "$ANDROID_AVD_HOME" "$ANDROID_USER_HOME" \
    "$ANDROID_AGENT_DEVICE_STATE_DIR" "$ANDROID_AGENT_DEVICE_CACHE_DIR" "$ANDROID_AGENT_DEVICE_EVIDENCE_DIR"
}

android_agent_device_sdkmanager() { printf '%s\n' "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"; }
android_agent_device_avdmanager() { printf '%s\n' "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/avdmanager"; }
android_agent_device_emulator() { printf '%s\n' "$ANDROID_SDK_ROOT/emulator/emulator"; }
android_agent_device_adb() { printf '%s\n' "$ANDROID_SDK_ROOT/platform-tools/adb"; }

android_agent_device_print_config() {
  cat <<EOF
name=$ANDROID_AGENT_DEVICE_NAME
serial=$ANDROID_AGENT_DEVICE_SERIAL
console_port=$ANDROID_AGENT_DEVICE_PORT
adb_port=$ANDROID_AGENT_DEVICE_ADB_PORT
sdk_root=$ANDROID_SDK_ROOT
avd_home=$ANDROID_AVD_HOME
state_dir=$ANDROID_AGENT_DEVICE_STATE_DIR
cache_dir=$ANDROID_AGENT_DEVICE_CACHE_DIR
evidence_dir=$ANDROID_AGENT_DEVICE_EVIDENCE_DIR
system_image=$ANDROID_AGENT_DEVICE_SYSTEM_IMAGE
device_profile=$ANDROID_AGENT_DEVICE_DEVICE_PROFILE
cmdline_tools_revision=$ANDROID_AGENT_DEVICE_CMDLINE_TOOLS_REVISION
cmdline_tools_package_revision=$ANDROID_AGENT_DEVICE_CMDLINE_TOOLS_PACKAGE_REVISION
cmdline_tools_url=$ANDROID_AGENT_DEVICE_CMDLINE_TOOLS_URL
ram_mb=$ANDROID_AGENT_DEVICE_RAM_MB
cores=$ANDROID_AGENT_DEVICE_CORES
EOF
}
