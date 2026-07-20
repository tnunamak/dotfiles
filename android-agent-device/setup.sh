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
  # One global order, shared with cli.sh's with_lock via common.sh: the device lock (fd 9) is
  # always acquired or reused first, the install lock (fd 8) second. No path may take install
  # then device -- that ordering is exactly what let a standalone --install/--update/--uninstall
  # deadlock when invoked from inside `android-agent-device lock -- ...`'s inherited fd 9, since
  # this function used to unconditionally replace it with a fresh, contending open-file-description.
  # Reusing/validating an inherited device lock here (instead of blindly reopening fd 9) is what
  # makes that nested case work instead of self-deadlocking.
  android_agent_device_acquire_device_lock
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

# A directory name/component, or a predictable fixed-content sentinel file, is not proof of
# ownership: a user can legitimately have unrelated pre-existing data at a path this capability is
# configured to use (default or an operator override), and a fixed marker text is trivially
# copyable between roots or hosts. Ownership must instead be a record that (a) is a real regular
# file this installer wrote, never a symlink; (b) names the exact canonical path and role it lives
# in, so a marker copied to a different root or renamed cannot validate there; and (c) carries one
# install-run-scoped random ID shared identically across all six roots, so a marker manually placed
# in one root without the matching set in the other five cannot validate alone. install_impl's
# preflight (below) additionally refuses to ever write a record into a nonempty, unowned CUSTOM
# root at all -- adoption without proof is exactly the defect this replaces.
ANDROID_AGENT_DEVICE_RECORD_NAME=".android-agent-device-owned"

# role names double as the record's "role=" field and must be unique per canonical root. The third
# field is non-empty exactly when the root is a CUSTOM override rather than the un-overridden
# default path. ANDROID_AGENT_DEVICE_STATE_DIR/CACHE_DIR/EVIDENCE_DIR are self-referential defaults
# in common.sh (the override variable and the resolved variable share one name), so once
# android_agent_device_init_paths has run once in this process, that variable is always non-empty
# regardless of whether an operator actually set it -- checking it directly cannot tell override
# from default apart. Comparing the resolved path against a freshly recomputed pure default (using
# only $XDG_DATA_HOME/$XDG_CACHE_HOME, ignoring any already-exported override variable) does.
android_agent_device_roots() {
  local sdk_override='' avd_override='' home_override='' state_override='' cache_override='' evidence_override=''
  [[ -n "${ANDROID_AGENT_DEVICE_SDK_ROOT:-}" ]] && sdk_override=1
  [[ -n "${ANDROID_AGENT_DEVICE_AVD_HOME:-}" ]] && avd_override=1
  [[ -n "${ANDROID_AGENT_DEVICE_USER_HOME:-}" ]] && home_override=1
  [[ "$ANDROID_AGENT_DEVICE_STATE_DIR" != "$XDG_DATA_HOME/android-agent-device/state" ]] && state_override=1
  [[ "$ANDROID_AGENT_DEVICE_CACHE_DIR" != "$XDG_CACHE_HOME/android-agent-device" ]] && cache_override=1
  [[ "$ANDROID_AGENT_DEVICE_EVIDENCE_DIR" != "$XDG_DATA_HOME/android-agent-device/evidence" ]] && evidence_override=1
  cat <<EOF
sdk|$ANDROID_SDK_ROOT|$sdk_override
avd|$ANDROID_AVD_HOME|$avd_override
android-home|$ANDROID_USER_HOME|$home_override
state|$ANDROID_AGENT_DEVICE_STATE_DIR|$state_override
cache|$ANDROID_AGENT_DEVICE_CACHE_DIR|$cache_override
evidence|$ANDROID_AGENT_DEVICE_EVIDENCE_DIR|$evidence_override
EOF
}

record_path() { printf '%s/%s\n' "$1" "$ANDROID_AGENT_DEVICE_RECORD_NAME"; }

# A record (or its root) reached through a symlink is rejected outright: `-L` on the resolved
# record path, and comparing the resolved root against its non-canonicalized form, both catch a
# symlink component without ever following one to read/write through it.
path_is_or_is_under_symlink() {
  local probe
  probe="$1"
  while [[ "$probe" != / && -n "$probe" ]]; do
    [[ -L "$probe" ]] && return 0
    probe="$(dirname "$probe")"
  done
  return 1
}

root_has_valid_ownership_record() {
  local root="$1" role="$2" install_id="$3" record recorded_path recorded_role recorded_id
  record="$(record_path "$root")"
  [[ -f "$record" && ! -L "$record" ]] || return 1
  path_is_or_is_under_symlink "$root" && return 1
  recorded_path="$(sed -n 's/^path=//p' "$record" | head -n 1)"
  recorded_role="$(sed -n 's/^role=//p' "$record" | head -n 1)"
  recorded_id="$(sed -n 's/^install_id=//p' "$record" | head -n 1)"
  [[ "$recorded_path" == "$(realpath -m "$root")" ]] || return 1
  [[ "$recorded_role" == "$role" ]] || return 1
  [[ -n "$recorded_id" ]] || return 1
  [[ "$recorded_id" == "$install_id" ]]
}

# Any owner's record identifies the shared install-run ID it belongs to, regardless of what that
# ID is; used to discover an already-self-consistent set (all six carrying the same ID) without
# needing to know the ID in advance.
root_ownership_record_install_id() {
  local root="$1" record
  record="$(record_path "$root")"
  [[ -f "$record" && ! -L "$record" ]] || return 1
  path_is_or_is_under_symlink "$root" && return 1
  sed -n 's/^install_id=//p' "$record" | head -n 1
}

directory_empty_of_content() {
  local dir="$1" entry name
  while IFS= read -r -d '' entry; do
    name="$(basename "$entry")"
    case "$name" in
      "$ANDROID_AGENT_DEVICE_RECORD_NAME"|device.lock|install.lock) ;;
      *) return 1 ;;
    esac
  done < <(find "$dir" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)
  return 0
}

# A root is at its literal, un-overridden default location only if the corresponding
# ANDROID_AGENT_DEVICE_*_ROOT/_HOME/_DIR override was never set; legacy one-time migration is
# restricted to exactly this case; a CUSTOM override never migrates, only adopts empty/owned.
role_is_default_path() { [[ -z "$3" ]]; }

# Classifies one root before any install mutation happens anywhere. Echoes one of:
# absent | empty | owned | migratable-legacy-default | disqualified. Never writes anything.
# corroborated_id (possibly empty) must come from discover_corroborated_install_id, computed once
# across all six roots by the caller -- never from this root's own self-reported ID in isolation,
# which a single forged/copied record could satisfy on its own.
classify_root_for_install() {
  local role="$1" root="$2" override="$3" corroborated_id="$4" resolved
  resolved="$(realpath -m "$root")"
  if path_is_or_is_under_symlink "$resolved" && [[ -e "$resolved" ]]; then
    printf 'disqualified: %s is reached through a symlink; this installer never writes through one\n' "$resolved"
    return 1
  fi
  if [[ ! -e "$resolved" ]]; then
    echo absent
    return 0
  fi
  if [[ -n "$corroborated_id" ]] && root_has_valid_ownership_record "$resolved" "$role" "$corroborated_id"; then
    echo owned
    return 0
  fi
  if directory_empty_of_content "$resolved"; then
    echo empty
    return 0
  fi
  if role_is_default_path "$role" "$root" "$override" && [[ "${ANDROID_AGENT_DEVICE_MIGRATE_LEGACY:-}" == 1 ]]; then
    echo migratable-legacy-default
    return 0
  fi
  if role_is_default_path "$role" "$root" "$override"; then
    printf 'disqualified: %s (default %s path) has content but no valid ownership record and no ANDROID_AGENT_DEVICE_MIGRATE_LEGACY=1 acknowledgement for the documented one-time migration\n' "$resolved" "$role"
  else
    printf 'disqualified: %s (a custom ANDROID_AGENT_DEVICE_* override for %s) is nonempty and not already validly owned; a custom root must be absent, empty, or already this installer'"'"'s to be used -- it is never auto-adopted or migrated\n' "$resolved" "$role"
  fi
  return 1
}

# Preflights every one of the six roots before any of install_impl's other steps run (host
# packages, SDK download, AVD creation) and before any ownership record is written anywhere. A
# single disqualified root aborts the whole install; nothing is downloaded, mutated, or claimed.
preflight_install_roots() {
  local line role root override verdict failed=false corroborated_id
  corroborated_id="$(discover_corroborated_install_id 2>/dev/null || true)"
  while IFS='|' read -r role root override; do
    [[ -n "$role" ]] || continue
    if ! verdict="$(classify_root_for_install "$role" "$root" "$override" "$corroborated_id")"; then
      echo "Refusing to install: $verdict" >&2
      failed=true
      continue
    fi
  done < <(android_agent_device_roots)
  [[ "$failed" == false ]] || { echo "No root was mutated, no sentinel was written, and nothing was downloaded." >&2; return 1; }
}

# Writes all six ownership records only after preflight_install_roots has passed for all of them.
# Each write is atomic (mktemp + mv within the same root, so no reader ever observes a partial
# record) and refuses to write through a symlinked root. One shared install ID is generated once
# and used for every record, so a record copied alone to another root (a different path/role) or
# without its five siblings (a different, unmatched ID) cannot pass validation there.
write_ownership_records() {
  local install_id role root override resolved stage
  install_id="$(od -An -tx1 -N16 /dev/urandom | tr -d ' \n')"
  while IFS='|' read -r role root override; do
    [[ -n "$role" ]] || continue
    mkdir -p "$root"
    resolved="$(realpath -m "$root")"
    path_is_or_is_under_symlink "$resolved" && { echo "Refusing to write an ownership record through a symlinked root: $resolved" >&2; return 1; }
    stage="$(mktemp "$resolved/.android-agent-device-owned.XXXXXX")"
    printf 'path=%s\nrole=%s\ninstall_id=%s\n' "$resolved" "$role" "$install_id" > "$stage"
    mv -T "$stage" "$(record_path "$resolved")"
  done < <(android_agent_device_roots)
}

# Trusting a root's own self-reported install_id to validate that same root is circular: a single
# forged or copied record with an arbitrary but internally-consistent ID would always "match
# itself." A shared install identity is only meaningful if it is actually shared -- corroborated by
# every OTHER nonempty root's own independently-read record, not just asserted by the one root being
# checked. Reads every nonempty root's record's ID first; only an ID that every nonempty root agrees
# on (unanimously, not just this one) counts as the real, current install's identity.
discover_corroborated_install_id() {
  local role root override resolved id ids="" candidate count=0
  while IFS='|' read -r role root override; do
    [[ -n "$role" ]] || continue
    resolved="$(realpath -m "$root")"
    [[ -e "$resolved" ]] || continue
    directory_empty_of_content "$resolved" && continue
    id="$(root_ownership_record_install_id "$resolved" 2>/dev/null || true)"
    [[ -n "$id" ]] || return 1
    ids="$ids $id"
    count=$((count + 1))
  done < <(android_agent_device_roots)
  # write_ownership_records always writes all six roots in one atomic pass, so a genuine install
  # never leaves exactly one nonempty root with a record and the rest empty/absent. Requiring at
  # least two independently-read, agreeing roots is what makes corroboration meaningful: a single
  # root's self-report (forged or copied) can never satisfy "unanimous" on its own.
  [[ $count -ge 2 ]] || return 1
  candidate="$(awk '{print $1}' <<<"$ids")"
  for id in $ids; do [[ "$id" == "$candidate" ]] || return 1; done
  printf '%s\n' "$candidate"
}

# Canonicalizes (realpath -m, so symlinks/../traversal cannot hide the true target) every
# documented override (common.sh:21-31) and requires a valid record for the one install ID every
# nonempty root corroborates, before any deletion. A nonexistent root, or one containing nothing
# but this capability's own lock-file/record bookkeeping (mkdirs runs on every invocation, so those
# can exist even on a tree that was never installed), is safe to skip -- there is nothing there to
# lose. If even one nonempty root disagrees on the ID, is missing a record, or fails validation,
# the whole uninstall aborts -- it is never partially applied, and no root is deleted on the
# strength of its own unverified self-report alone.
any_root_has_content() {
  local role root override resolved
  while IFS='|' read -r role root override; do
    [[ -n "$role" ]] || continue
    resolved="$(realpath -m "$root")"
    [[ -e "$resolved" ]] || continue
    directory_empty_of_content "$resolved" || return 0
  done < <(android_agent_device_roots)
  return 1
}

require_ownership_of_deletion_targets() {
  local role root override resolved corroborated_id
  # A genuinely fresh tree (nothing anywhere but this invocation's own lock bookkeeping) has
  # nothing to protect or corroborate; only look for a shared install identity once there is at
  # least one nonempty root, so a never-installed uninstall stays a safe no-op instead of a refusal.
  any_root_has_content || return 0
  corroborated_id="$(discover_corroborated_install_id)" || {
    echo "Refusing to uninstall: the six capability roots do not all agree on one install identity (a root may be unowned, missing its record, or recording a different install). Nothing was deleted." >&2
    return 1
  }
  while IFS='|' read -r role root override; do
    [[ -n "$role" ]] || continue
    resolved="$(realpath -m "$root")"
    [[ -e "$resolved" ]] || continue
    directory_empty_of_content "$resolved" && continue
    root_has_valid_ownership_record "$resolved" "$role" "$corroborated_id" || {
      echo "Refusing to uninstall: $resolved (role=$role) has content but no valid android-agent-device ownership record for the corroborated install identity. It may be an unrelated directory, a copied/forged marker, or a record for a different install; only a directory this installer's --install validated and recorded can be deleted. Move/remove it yourself if you are certain, or fix the override." >&2
      return 1
    }
  done < <(android_agent_device_roots)
}

uninstall_impl() {
  local cli="$ROOT/cli.sh"
  require_ownership_of_deletion_targets
  # with_install_lock already acquired/reused fd 9 (the device lock) and exported LOCK_HELD=1, so
  # cli.sh's with_lock verifies and reuses that inherited fd here instead of opening an independent
  # flock on the same file, which would deadlock against this process.
  "$cli" stop || {
    echo "Refusing to remove SDK/AVD state while the recorded emulator could not be stopped cleanly. Inspect 'android-agent-device status --json' and retry." >&2
    return 1
  }
  rm -rf "$ANDROID_SDK_ROOT" "$ANDROID_AVD_HOME" "$ANDROID_USER_HOME" \
    "$ANDROID_AGENT_DEVICE_STATE_DIR" "$ANDROID_AGENT_DEVICE_CACHE_DIR" "$ANDROID_AGENT_DEVICE_EVIDENCE_DIR"
  # Only this capability's own namespace directories, never the shared XDG parent itself.
  rmdir --ignore-fail-on-non-empty "$XDG_DATA_HOME/android-agent-device" "$XDG_CACHE_HOME/android-agent-device" 2>/dev/null || true
  echo "Removed the user-scoped Android SDK, AVD, state, cache, and evidence directories."
  echo "kvm group membership and host packages (curl/unzip/python3/java) were left in place; remove those yourself if desired."
}

install_impl() {
  # Preflight all six roots before any host/SDK/AVD mutation, per-root, or ownership record write.
  # A disqualified root (nonempty, unowned, and not an explicitly acknowledged legacy-default
  # migration) aborts here: nothing is downloaded, nothing is mutated, no record is written
  # anywhere -- not even into the roots that would otherwise have qualified.
  preflight_install_roots
  install_host_prerequisites
  install_cmdline_tools
  install_sdk_packages
  create_avd
  write_ownership_records
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
[[ "${ANDROID_AGENT_DEVICE_LIB_ONLY:-}" == 1 ]] || main "$@"
