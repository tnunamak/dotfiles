---
title: "A shared Android agent device should use a verified official SDK bootstrap plus a lock-owning CLI and skill, not an Android MCP"
date: 2026-07-18
topic: android-agent-device
tags: [android, emulator, adb, cdp, appium, uiautomator, maestro, mcp, brave, visualviewport, soft-keyboard]
status: draft
sources: [android-sdkmanager, android-avdmanager, android-emulator, android-uiautomator, appium-drivers, maestro-android, chrome-remote-debugging, w3c-viewport, existing-visualviewport-research, brave-android-install, cursortouch-github-api, cursortouch-readme, tanbro-github-api, tanbro-readme]
---

## CLAIMS

- Android's official `sdkmanager` supports exact package IDs and stable channel selection; Android explicitly recommends a specific command-line-tools version for scripts rather than `latest`. [android-sdkmanager]
- The Android Studio download page and its official `repository2-1.xml` publish the exact Linux command-line-tools artifact `commandlinetools-linux-14742923_latest.zip`, size `172789259`, and checksum `48833c34b761c10cb20bcd16582129395d121b27`. [android-studio-download] [android-repository]
- `avdmanager` is the official command-line tool for creating/managing AVDs, and Android's emulator docs support named AVD startup, KVM-backed x86/x86_64 acceleration on Linux, deterministic `-port`, `-memory`, `-cores`, `-wipe-data`, and disabling Quick Boot snapshots with `-no-snapshot`. [android-avdmanager] [android-emulator]
- Android documents that an AVD's user-data partition persists between normal launches and that `-wipe-data` clears it; snapshots overwrite user-data/system/SD-card state on restore. This makes a persistent AVD definition plus cold boots and explicit reset a clearer shared-test policy than unbounded Quick Boot state. [android-emulator]
- Android UI Automator is the upstream framework for cross-process user/system UI testing and now has explicit app-state and screenshot support. Appium's UiAutomator2 driver maps WebDriver to UiAutomator2, ADB, and an SDK helper app; it is valuable for app-owned WebDriver suites but adds a server/protocol layer to a shared-device control plane. [android-uiautomator] [appium-drivers]
- Maestro controls rendered Android UI without app instrumentation and is a good project-level black-box test runner; it does not replace a host-owned lifecycle/locking boundary for a shared emulator. [maestro-android]
- Chrome's official Android remote-debugging documentation uses `adb forward tcp:9222 localabstract:chrome_devtools_remote`, so CDP is retained as an optional browser diagnostic alongside ADB and platform evidence. [chrome-remote-debugging]
- A real Android IME and `window.visualViewport` must be tested on an Android device/emulator, not desktop mobile emulation. The existing corpus establishes that `visualViewport` is the cross-browser signal and that Android/Chromium keyboard behavior depends on the `interactive-widget` mode. [existing-visualviewport-research] [w3c-viewport]
- Brave's own Android documentation names Google Play and Brave's F-Droid repositories as its supported distribution channels and labels GitHub APKs as development builds. Its support article also links Android APK downloads to GitHub. The reviewed documentation did not provide a pinned, independently-verifiable x86_64 artifact ingestion path suitable for a no-login shared emulator installer, so Chromium baseline coverage must remain explicitly separate. [brave-android-install] [brave-support]
- As sampled on 2026-07-18, CursorTouch/Android-MCP was active (741 GitHub stars; updated 2026-07-18) but auto-detects devices, prefers physical devices, and exposes a general shell tool; tanbro/uiautomator2-mcp-server was active (31 stars; pushed 2026-07-16) but exposes 70+ tools and requires a separate uiautomator2/ADB server. Neither supplies the required fixed-serial lock, reset policy, narrow privilege boundary, or first-party Claude/Codex/Gemini configuration evidence. [cursortouch-github-api] [cursortouch-readme] [tanbro-github-api] [tanbro-readme]

## SOURCES

**android-sdkmanager**
URL: https://developer.android.com/tools/sdkmanager
Accessed: 2026-07-18
Quote: "For scripts, choose a specific version instead to ensure stability."

**android-studio-download**
URL: https://developer.android.com/studio
Accessed: 2026-07-18
Quote: The Linux command-line tools row names `commandlinetools-linux-14742923_latest.zip` and publishes its checksum.

**android-repository**
URL: https://dl.google.com/android/repository/repository2-1.xml
Accessed: 2026-07-18
Quote: The `commandlinetools-linux-14742923_latest.zip` archive entry gives size `172789259` and checksum `48833c34b761c10cb20bcd16582129395d121b27`.

**android-avdmanager**
URL: https://developer.android.com/tools/avdmanager
Accessed: 2026-07-18
Quote: "The `avdmanager` tool is a command-line tool that lets you create and manage Android Virtual Devices (AVDs) from the command line."

**android-emulator**
URL: https://developer.android.com/studio/run/emulator-commandline
Accessed: 2026-07-18
Quote: "On Linux, [accelerated emulation] relies on KVM." / "`-wipe-data` ... clears this data."

**android-uiautomator**
URL: https://developer.android.com/training/testing/other-components/ui-automator
Accessed: 2026-07-18
Quote: "UI Automator lets you test an app from outside of the app's process."

**appium-drivers**
URL: https://appium.io/docs/en/latest/intro/drivers/
Accessed: 2026-07-18
Quote: UiAutomator2 uses Google UiAutomator2 plus ADB and an Android SDK helper app.

**maestro-android**
URL: https://docs.maestro.dev/get-started/supported-platform/android
Accessed: 2026-07-18
Quote: "Maestro interacts only with the rendered UI" and needs "Zero Instrumentation."

**chrome-remote-debugging**
URL: https://developer.chrome.com/docs/devtools/remote-debugging
Accessed: 2026-07-18
Quote: `adb forward tcp:9222 localabstract:chrome_devtools_remote`

**w3c-viewport**
URL: https://www.w3.org/TR/css-viewport-1/
Accessed: 2026-07-18
Quote: `resizes-visual` resizes only the visual viewport; `resizes-content` resizes both.

**existing-visualviewport-research**
URL: ../remote-browser/mobile-keyboard-overlay-requires-interactive-widget-plus-visualviewport-not-dvh-alone.md
Accessed: 2026-07-18
Quote: Corpus finding: `window.visualViewport` is the cross-engine signal for virtual-keyboard geometry changes.

**brave-android-install**
URL: https://github.com/brave/brave-browser/wiki/Installing-Brave-on-Android
Accessed: 2026-07-18
Quote: "The two officially-supported ways to install Brave on Android is through Google Play and our F-Droid repositories." / "Development builds are available as GitHub release assets."

**brave-support**
URL: https://support.brave.com/hc/en-us/articles/360025390311-How-do-I-download-and-install-Brave
Accessed: 2026-07-18
Quote: "You can also download the Android .apk file from our GitHub Repository."

**cursortouch-github-api**
URL: https://api.github.com/repos/CursorTouch/Android-MCP
Accessed: 2026-07-18
Quote: 741 stars, 102 forks, updated `2026-07-18T02:29:26Z`, pushed `2026-07-01T06:38:43Z`.

**cursortouch-readme**
URL: https://github.com/CursorTouch/Android-MCP
Accessed: 2026-07-18
Quote: It "prefers physical devices over emulators" when unspecified and lists a `Shell-Tool` that executes shell commands on the Android device.

**tanbro-github-api**
URL: https://api.github.com/repos/tanbro/uiautomator2-mcp-server
Accessed: 2026-07-18
Quote: 31 stars, 6 forks, pushed `2026-07-16T20:23:48Z`.

**tanbro-readme**
URL: https://github.com/tanbro/uiautomator2-mcp-server
Accessed: 2026-07-18
Quote: "70+ Tools" and the architecture includes `uiautomator2` and ADB.

## SYNTHESIS

Choose one purpose-built, user-scoped CLI (`android-agent-device`) with a single lock, fixed AVD
name/serial, known ports, bounded emulator resources, cold boot, explicit reset, and evidence
commands. Pair it with a local skill, which setup already distributes symmetrically to Claude,
Codex, and Gemini. This is a deep boundary: it owns the SDK paths, lifecycle, readiness, locking,
and evidence without leaking raw emulator state into every agent.

Do not add an Android MCP now. CursorTouch clears an adoption/maintenance threshold but fails the
shared-device safety test: its default device selection can target a physical phone and its shell
tool is broader than the capability needs. The smaller uiautomator2 MCP is active but lacks the
required adoption and still creates a 70-tool server around a lower-level stack. Neither improves
the test oracle for Android IME/VisualViewport/rotation; those require fixture and platform
evidence. Reconsider only if an MCP can pin this serial, participate in the same lock, omit
arbitrary shell and physical/Wi-Fi discovery, has a maintained release, and has an equally safe
configuration route for all three harnesses.
