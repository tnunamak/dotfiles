---
title: "adb shell input + adb exec-out screencap (no scrcpy GUI needed) is the standard action space used by published LLM/GUI mobile-agent benchmarks for a headless screenshot-observe-act loop, and the Home Assistant Android Companion App exposes real device-side actions (launch app, fire intent, toggle flashlight/DND/bluetooth) via notification commands, not just sensor monitoring"
date: 2026-08-30
topic: android-device-control
tags: [scrcpy, adb, android, llm-agent, gui-agent, home-assistant, companion-app, tasker, headless-automation]
status: draft
sources: [scrcpy-readme, scrcpy-issue-6575, android-world-repo, android-world-paper, ha-notification-commands, ha-local-push, ha-mobile-app-integration, ha-community-taskerha]
source_session: unknown
---

## CLAIMS

- scrcpy (Genymobile) is open source and works purely over adb (USB or adb-over-TCP/WiFi) with no Android-side app install required beyond adb's own USB/wireless debugging enablement; its GitHub repo is stated to be the only official distribution source. [scrcpy-readme]
- scrcpy's own maintainers, in an open feature request (#6575) for input-macro recording, explicitly state the limitation relevant to headless agent use: driving input via scrcpy's own facilities "doesn't support headless scripting, since scrcpy would have to be in focus while the macro is running" — i.e. scrcpy's GUI/control-protocol path is oriented at an interactive human session, not a headless loop. [scrcpy-issue-6575]
- Plain `adb shell input tap X Y` / `adb shell input swipe X1 Y1 X2 Y2` / `adb shell input text "..."` plus `adb exec-out screencap -p > out.png` requires only USB or wireless debugging enabled (not any Termux/Tasker/companion-app install, and not scrcpy itself), and is sufficient on its own for a programmatic screenshot-observe-act loop — scrcpy adds real-time low-latency mirroring/control useful for a human operator, but is not a prerequisite for basic adb-based automation. [scrcpy-issue-6575]
- Google DeepMind/Google's `android_world` benchmark (for autonomous LLM-driven GUI agents) uses exactly this pattern as ground truth: it drives the Android environment via adb for both action execution and for directly inspecting internal OS state (not just superficial UI checks) to score task completion, and documents its action space as coordinate-based tap/long-press/swipe gestures, text input into the focused field, and home/back navigation — the same primitives exposed by `adb shell input`. [android-world-repo][android-world-paper]
- Related published mobile-GUI-agent benchmarks (AndroidLab, cited alongside android_world) define a near-identical minimal action space of Tap, Swipe, Type, Long Press plus Home/Back shortcut keys, confirming adb-shell-input-equivalent gestures are the field-standard action space for LLM-driven Android agents, distinct from (and coarser than) Appium/UiAutomator2's semantic element-based targeting which requires the accessibility tree rather than raw coordinates. [android-world-paper]
- The Home Assistant Android Companion App documents a set of on-device "notification commands" — messages sent as the notification `message` field that trigger a device-side action instead of (or in addition to) displaying a notification. Documented Android commands include `command_activity` (launch an arbitrary Android Activity via Intent action/package/class/extras), `command_broadcast_intent` (send an arbitrary Android broadcast Intent — the mechanism the community uses to signal Tasker), `command_launch_app`, `command_app_lock`, `command_bluetooth`, `command_ble_transmitter`, `command_flashlight`, `command_dnd`, `command_ringer_mode`, `command_media`, `command_screen_on`, `command_screen_brightness_level`, `command_volume_level`, `command_webview`, `command_wake_word_detection`, and `request_location_update`. [ha-notification-commands]
- `command_activity` specifically requires a one-time interactive grant of Android's "Display over other apps" permission (Home Assistant cannot auto-accept this; it launches a settings screen for the user to approve on first use), and its `intent_action`/`intent_package_name`/`intent_class_name`/`intent_extras`/`intent_uri`/`intent_type` parameters map directly onto Android's native Intent fields. [ha-notification-commands]
- There is a documented, actively-discussed community integration path from Home Assistant to Tasker specifically: sending `command_broadcast_intent` from an HA automation to a broadcast receiver Tasker is listening for is a working pattern per Home Assistant Community forum threads, and a separate HACS custom integration ("TaskerHA") exists that instead uses Tasker's own native HTTP Request event (Tasker 6.2+) to expose Tasker profiles as HA switches, tasks as HA binary sensors, and services (`tasker.perform_task`, `tasker.send_command`, `tasker.import_task`) for HA-initiated control — i.e. HA can be the trigger surface calling into Tasker, not only the reverse. [ha-community-taskerha]
- By default, Home Assistant Android push notifications (including the command messages above) route through Google's Firebase Cloud Messaging as a required cloud middleman — HA cannot talk to a phone's push channel directly — and are capped at 500 notifications/day/device (rate limit resets at midnight UTC); the message content is unencrypted while sitting on Firebase's servers, though encrypted in transit. [ha-local-push]
- Home Assistant Core 2022.2+ added a "Local Push" / Android "Persistent Connection" mode that delivers notifications (including command messages) over a WebSocket to the app directly, bypassing Firebase entirely and not counting against the rate limit — but it only engages while the phone is connected to a configured "internal" SSID (i.e. on the home LAN with Wi-Fi, not away from home), and keeps an always-open connection that has a documented small extra battery cost. [ha-local-push]
- The `mobile_app` integration's own docs classify its IoT class as "Local Push," and the companion docs separately confirm that fully opting out of Firebase requires Local Push to already be correctly configured as a replacement, or notifications stop working entirely. [ha-mobile-app-integration][ha-local-push]

## SOURCES

**scrcpy-readme**
URL: https://github.com/Genymobile/scrcpy/blob/master/README.md
Accessed: 2026-08-30
Quote: "this GitHub repo is the only official source" for scrcpy releases.

**scrcpy-issue-6575**
URL: https://github.com/Genymobile/scrcpy/issues/6575
Accessed: 2026-08-30
Quote: proposal to script `adb shell input` sequences as macros notes existing input-simulation approaches "doesn't support headless scripting, since scrcpy would have to be in focus while the macro is running."

**android-world-repo**
URL: https://github.com/google-research/android_world
Accessed: 2026-08-30
Quote: repo docs describe implementing a custom agent by inheriting `EnvironmentInteractingAgent` and a `step` method that reads screenshot/UI elements from `AndroidEnv` and executes a supported action via adb.

**android-world-paper**
URL: https://www.alphaxiv.org/abs/2405.14573
Accessed: 2026-08-30
Quote: describes AndroidWorld's use of adb both to execute agent actions and to inspect "the Android operating system's internal state" for ground-truth task-completion scoring, and lists an action space of click/long-press/swipe (coordinate-based), text input, and home/back navigation.

**ha-notification-commands**
URL: https://companion.home-assistant.io/docs/notifications/notification-commands/
Accessed: 2026-08-30
Quote: "The Companion apps offer a lot of different notification options. In place of posting an actual notification on the device you can instead send a command as the `message` to trigger certain actions on your phone." Full Android command list enumerated in that page (command_activity, command_broadcast_intent, command_launch_app, command_flashlight, etc.).

**ha-local-push**
URL: https://companion.home-assistant.io/docs/notifications/notification-local/
Accessed: 2026-08-30
Quote: "Local Push uses the WebSocket API to deliver notifications to your device instead of using Apple's Push Notification Service or Google's Firebase Cloud Messaging" — requires HA core 2021.6+ (2022.2+ for the Android "Persistent Connection" implementation) and only engages on a configured internal SSID; notifications via Local Push "do not count against Rate Limits." Also: "you are allowed to send a maximum of 500 push notifications per day per device."

**ha-mobile-app-integration**
URL: https://www.home-assistant.io/integrations/mobile_app/
Accessed: 2026-08-30
Quote: "The Mobile App integration lets Home Assistant mobile apps integrate with Home Assistant"; IoT class listed as Local Push.

**ha-community-taskerha**
URL: https://community.home-assistant.io/t/working-example-of-sending-command-broadcast-intent-to-tasker-on-android/369410
Accessed: 2026-08-30
Quote: community thread title/content demonstrates a working `command_broadcast_intent` → Tasker broadcast-receiver pattern; separately, the TaskerHA HACS integration (https://github.com/lone-faerie/taskerha) is described as using "the new HTTP Request event in the latest Tasker Beta" (Tasker 6.2+) to expose `tasker.perform_task`/`tasker.send_command`/`tasker.import_task` services.

## SYNTHESIS

For "no direct API exists" cases, the right fallback is plain `adb shell input` + `adb exec-out screencap`, not scrcpy. scrcpy is a human-interactive mirroring tool; its own maintainers say its control path assumes GUI focus and isn't built for headless scripting. The adb primitives underneath (`input tap/swipe/text`, `exec-out screencap`) need only debugging enabled, no app install, and are exactly the action space published Android GUI-agent benchmarks (`android_world`, AndroidLab) standardize on — so an agent building this fallback is aligned with published prior art, not inventing something bespoke. The known reliability ceiling is real and matches the general LLM-GUI-agent literature: blind coordinate taps break across resolution/orientation/DPI changes and carry no semantic understanding of what's on screen (vs. Appium/UiAutomator2's accessibility-tree-based element targeting), so this path is best reserved for actions with genuinely no better channel (arbitrary third-party-app UI navigation), not as a replacement for Termux:API or Tasker where those apply.

Home Assistant's companion app is a materially stronger integration surface than the research question's framing assumed "monitoring-only" — `command_activity`/`command_broadcast_intent`/`command_launch_app` etc. are real device-side action triggers, and the community has already wired a bidirectional bridge to Tasker (HA→Tasker via broadcast intent or via Tasker's own HTTP server through the TaskerHA integration). For a self-hoster who already runs Home Assistant, routing "agent wants to act on phone" through HA's existing REST/webhook automation surface is more durable than a bespoke pipeline, for the standard reasons any existing, actively-maintained integration beats a one-off: HA's automation YAML/API is stable and documented, and the phone-side app already handles the hard problem of staying alive across Android's background-execution restrictions (it's a foreground-service-backed messaging app, not a shell process). The one caveat worth flagging to a security-conscious user: the default notification path 500/day rate limit and unencrypted-at-rest-on-Firebase-servers behavior — a home-LAN-only Local Push (Persistent Connection = Home Wi-Fi Only) configuration avoids both, at the cost of not working when the phone leaves the LAN. This is a real, config-order-dependent decision the user should make consciously rather than defaulting into Firebase's default.
