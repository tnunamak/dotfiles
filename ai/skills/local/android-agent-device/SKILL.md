---
name: android-agent-device
description: Use the shared Android virtual device safely whenever a task needs a real Android browser or device journey: soft-keyboard/IME behavior, VisualViewport changes, touch, rotation, screenshots, log evidence, adb, or Android Chrome/Chromium testing. Do not substitute desktop mobile emulation for these device behaviors. Use this skill before operating the shared emulator.
compatibility: Linux host with the dotfiles Android agent device installed; `android-agent-device` on PATH.
---

# Shared Android Agent Device

This is one persistent, user-scoped Android emulator shared by concurrent coding agents.
It is a device-level test boundary, not a replacement for app-owned UI tests. The CLI lock
prevents cooperating agents from interleaving lifecycle, reset, or ADB actions.

## Preflight

Check host and device state without modifying it:

```bash
android-agent-device diagnose --json
android-agent-device status --json
```

If the SDK/AVD is missing, the host owner installs it once with:

```bash
ANDROID_AGENT_DEVICE_SETUP=1 ~/code/dotfiles/setup.sh
# or, for only this capability:
~/code/dotfiles/scripts/android-agent-device-setup.sh --install
```

To remove the capability entirely, the host owner runs
`~/code/dotfiles/scripts/android-agent-device-setup.sh --uninstall`. It stops the recorded shared
device first, then deletes only directories `--install` itself created (proven by a sentinel file
it writes into each one); a same-named or same-pathed directory `--install` never wrote into is
refused rather than deleted. It never touches `kvm` group membership or host packages.

`diagnose` reports KVM node access (`kvm_device_access`) separately from the emulator's own
`emulator_accel_check`; both must be true for the intended accelerated path.
The installer adds the user to the `kvm` group when necessary; logging out and back in is the
unavoidable one-time action. Do not run the emulator with sudo, because that creates root-owned
SDK or AVD state.

## Lifecycle and concurrency

Use only this CLI for the shared AVD. Never start its emulator process or use unscoped `adb`
directly.

```bash
android-agent-device start
android-agent-device status --json
android-agent-device run -- shell getprop sys.boot_completed
android-agent-device stop
```

For one ADB action, `run` holds the exclusive device lock:

```bash
android-agent-device run -- shell input tap 206 410
android-agent-device run -- shell settings put system user_rotation 1
```

For a multi-command critical section, hold the lock around a script or command. Nested CLI calls
inherit the lock marker, so use the CLI inside it rather than an unscoped ADB binary:

```bash
android-agent-device lock -- bash -lc '
  android-agent-device run -- shell am force-stop com.example.app
  android-agent-device run -- shell monkey -p com.example.app 1
'
```

Use `reset` only when a fresh device state is part of the test. It stops the recorded, validated device, wipes its
user-data partition, and boots it again. Normal starts use cold boot with snapshots disabled:
the AVD definition persists but hidden Quick Boot state cannot make a test pass accidentally.

## Real browser UX workflow

The selected Google Play system image supplies the Chromium baseline (`com.android.chrome` when
present). Verify it rather than assuming it:

```bash
android-agent-device start
android-agent-device status --json
```

Serve a local fixture from the host and access it from the emulator at `10.0.2.2`, then launch
the actual Android browser:

```bash
python3 -m http.server 18080 --bind 127.0.0.1 --directory ./public &
android-agent-device run -- shell am start -W -a android.intent.action.VIEW \
  -d http://10.0.2.2:18080/fixture.html
```

For CDP-only inspection, forward the Android Chrome DevTools socket after Chrome is running:

```bash
android-agent-device run -- forward tcp:9222 localabstract:chrome_devtools_remote
curl -fsS http://127.0.0.1:9222/json
```

Treat a missing DevTools socket as an unavailable optional diagnostic, not proof that the browser
test passed. Keep platform/user-visible evidence as the test oracle.

## Keyboard, VisualViewport, touch, and rotation

Desktop Playwright mobile emulation cannot prove an Android IME. For a soft-keyboard test:

1. Start the fixture in Android Chrome and tap the real input with `run -- shell input tap X Y`.
2. Capture platform state after the tap. Require an IME visibility signal from `dumpsys input_method`
   and/or `dumpsys window`; a focused DOM input or screenshot alone is insufficient.
3. Have the fixture render `window.visualViewport.width`, `.height`, and `screen.orientation.type`
   into accessible DOM text. Read it using `uiautomator dump` before and after focus/rotation.
4. Lock orientation, rotate, and verify the fixture's orientation plus a landscape screenshot:

```bash
android-agent-device run -- shell settings put system accelerometer_rotation 0
android-agent-device run -- shell settings put system user_rotation 1
android-agent-device run -- shell uiautomator dump /sdcard/window.xml
android-agent-device run -- pull /sdcard/window.xml ./window.xml
```

Use `user_rotation=0` for portrait and `1` for landscape. Coordinates are device pixels; inspect a
fresh screenshot or UI dump before sending a touch if the target layout is unknown.

## Evidence capture

Store evidence outside the checked-out app, under the user-scoped evidence directory by default:

```bash
android-agent-device screenshot
android-agent-device logs
android-agent-device screenshot ./artifacts/android-after-keyboard.png
android-agent-device logs ./artifacts/android-logcat.txt
```

For the maintained end-to-end fixture and smoke journey:

```bash
~/code/dotfiles/android-agent-device/smoke-test.sh
```

It holds one lock for a real AVD boot, browser launch, local fixture, actual soft-IME platform
evidence, VisualViewport text, rotation, screenshots, and logs. It stops only an emulator it
started (identified by its invocation token); a reused shared device remains running. Its evidence
directory is printed in the command output/configuration.

## Browser scope

Do not silently call Chrome "Brave." Brave Android's official supported distribution is Google
Play or Brave's F-Droid repository; this capability currently does not automate either because
the supported channel has no pinned, independently verifiable x86_64 release artifact suitable
for a no-login reproducible host install. Use the explicit Chromium baseline above. If a test is
Brave-specific (Shields, wallet, Brave-only UI), report that it remains unverified rather than
claiming Chromium coverage.

iOS is outside this Linux/KVM capability. Test iOS keyboard and viewport behavior on macOS with
an iOS Simulator or physical device; do not extrapolate Android Chrome results to Safari/WebKit.
