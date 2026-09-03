---
title: "Termux:API commands invoked over a non-interactive SSH session into Termux are documented as unreliable on Android 10+ (hang/no-op while the Termux app is backgrounded), while Tasker's built-in HTTP Server (6.2+, Jan 2024) is a durable, first-party remote-trigger channel for arbitrary phone automations"
date: 2026-08-30
topic: android-device-control
tags: [termux, termux-api, tasker, ssh, adb, automation, remote-trigger, android]
status: draft
sources: [termux-api-package-scripts, termux-api-issue-301, termux-api-issue-301-comments, termux-app-issue-573, tasker-http-request-event, joaoapps-tasker-6-2, tasker-wikipedia, autoremote-play-store, tasker-vs-macrodroid-2026]
source_session: unknown
---

## CLAIMS

- The canonical `termux-api` command set (from the `termux-api-package` scripts directory, the actual source of the `termux-api` apt package) is: `termux-audio-info`, `termux-battery-status`, `termux-brightness`, `termux-call-log`, `termux-camera-info`, `termux-camera-photo`, `termux-clipboard-get`, `termux-clipboard-set`, `termux-contact-list`, `termux-dialog`, `termux-download`, `termux-fingerprint`, `termux-infrared-frequencies`, `termux-infrared-transmit`, `termux-job-scheduler`, `termux-keystore`, `termux-location`, `termux-media-player`, `termux-media-scan`, `termux-microphone-record`, `termux-nfc`, `termux-notification` (+ `-channel`, `-list`, `-remove`), `termux-saf-*` (storage-access-framework: create/dirs/ls/managedir/mkdir/read/rm/stat/write), `termux-sensor`, `termux-share`, `termux-sms-inbox`, `termux-sms-list`, `termux-sms-send`, `termux-speech-to-text`, `termux-storage-get`, `termux-telephony-call`, `termux-telephony-cellinfo`, `termux-telephony-deviceinfo`, `termux-toast`, `termux-torch`, `termux-tts-engines`, `termux-tts-speak`, `termux-usb`, `termux-vibrate`, `termux-volume`, `termux-wallpaper`, `termux-wifi-connectioninfo`, `termux-wifi-enable`, `termux-wifi-scaninfo`. [termux-api-package-scripts]
- All of these require BOTH the `termux-api` apt package installed inside Termux AND the separate Termux:API companion Android app installed and granted the relevant Android runtime permissions (camera, location, SMS, etc.) — the two client/server halves are signed with the same key and only the main Termux app is allowed to call the API app's methods. [termux-api-package-scripts]
- Multiple independent reporters across Android 10 devices (Pixel 4, Pixel 1, Pixel 3a, Samsung Galaxy S9/S10+) confirmed the same symptom in `termux/termux-api` issue #301: `termux-api` subcommands (e.g. `termux-battery-status`, `termux-contact-list`, `termux-clipboard-set`) work fine when run from a local Termux terminal but hang or silently no-op when invoked via a non-interactive SSH session into `sshd` running inside Termux, with SELinux `avc: denied` log lines appearing for some but not all invocations. [termux-api-issue-301][termux-api-issue-301-comments]
- The issue thread shows the failure is device/OS-version-dependent and non-deterministic over time, not a fixed defect: one reporter's problem resolved after an automatic Termux app update to v0.95, another reporter saw it resolve on Android 10 then recur after upgrading to Android 11 on the same device, and `termux-clipboard-get`/`termux-open` specifically were called out as sometimes working "after 10+ tries" or working in one direction (`-set`) but not the other (`-get`) on the same device. [termux-api-issue-301-comments]
- The community-documented workaround for reliable SSH-triggered termux-api calls is to keep a `tmux` or GNU `screen` session running directly inside the local Termux app (so termux-api calls originate from a session Android considers already "belonging to" the foregrounded/backgrounded-but-alive Termux process) and have the SSH command inject keystrokes into that session (`tmux send-keys`/`screen -X stuff`) rather than spawning a fresh SSH-owned process tree that calls termux-api directly. [termux-api-issue-301-comments]
- A separate but adjacent issue (`termux/termux-app` #573) shows the underlying cause is Android's background-activity-launch restrictions, not something specific to termux-api's binder calls: `adb shell am start` invoked over SSH only succeeds while Termux is in the foreground, but `termux-open` (a termux-api-adjacent helper) was reported to work over SSH in both foreground and background states on that reporter's device — indicating the restriction is inconsistent across different termux-api commands and Android versions, not a blanket "SSH can never call termux-api" rule. [termux-app-issue-573]
- Tasker (joaomgcd) shipped a native, first-party "HTTP Server" capability in version 6.2 (announced/released January 2024): an "HTTP Request" profile-condition event that has Tasker "create an HTTP server in the specified port" on-device, paired with an "HTTP Response" action (keyed by the event's `%http_request_id` variable) that lets a task reply to the triggering request — meaning any external client on the LAN that can send an HTTP request to the phone's IP:port can fire an arbitrary Tasker task, with no separate plugin or third-party relay app required. [tasker-http-request-event][joaoapps-tasker-6-2]
- Tasker's own docs note a collision caveat: if two HTTP Request events are configured on the same port and path, only one of them is considered — multiple externally-triggerable profiles must differ by path. [tasker-http-request-event]
- Tasker remains the community-consensus "gold standard" for depth/flexibility among Android automation apps as of 2026, specifically cited as the stronger choice over MacroDroid for HTTP/webhook/self-hosted-integration use cases (Home Assistant, Node-RED, n8n) due to a roughly 10x larger plugin ecosystem and more flexible HTTP action configuration; MacroDroid is recommended instead only when ease-of-use is prioritized over flexibility, and MacroDroid itself supports installing Tasker/Locale plugins to borrow some of that power. [tasker-vs-macrodroid-2026]
- AutoRemote (joaomgcd, the same developer as Tasker), a push-notification-based remote-control plugin/app for triggering Tasker actions from external services, is still actively listed and updated on the Google Play Store as of 2026 (last listed update Apr 29, 2026, version 3.2.9) — it has not been discontinued, though a Tasker community thread records at least one long-time user reporting dropped messages across multiple devices and recommending an alternative plugin ("AirTask" by Marco Stornelli) instead. [autoremote-play-store]
- Tasker's Wikipedia entry confirms the app is under continued active development into 2026: stable release 6.6.20 (Feb 25, 2026), a 6.7.0-beta (Mar 12, 2026), Shizuku (ADB-permission-bridging) integration and BeanShell scripting support added around February 2026, and a May 2025 built-in generative-AI task/profile generator using OpenRouter/Gemini models. [tasker-wikipedia]

## SOURCES

**termux-api-package-scripts**
URL: https://github.com/termux/termux-api-package/tree/master/scripts
Accessed: 2026-08-30
Quote: directory listing of the `.in` script sources — canonical source of every `termux-*` command shipped by the `termux-api` apt package (verified via `gh api repos/termux/termux-api-package/contents/scripts`).

**termux-api-issue-301**
URL: https://github.com/termux/termux-api/issues/301
Accessed: 2026-08-30
Quote: "termux-api (for example `/data/data/com.termux/files/usr/libexec/termux-api BatteryStatus`) works well when using termux directly on the phone, but via ssh it is hanging" — reporter on Pixel 4, Android 10, all permissions granted, battery optimization disabled for Termux:API.

**termux-api-issue-301-comments**
URL: https://github.com/termux/termux-api/issues/301
Accessed: 2026-08-30
Quote: "The good news is, that the issue was resolved recently on my device, probably by an automatic update. I am now running termux Version 0.95 and there is no issue anymore." / "The issue was resolved on my Pixel 3a on Android 10, but once I upgraded to Android 11 it came back." / workaround script using `screen -S termux -p 0 -X stuff "termux-media-scan '$1'^M"`.

**termux-app-issue-573**
URL: https://github.com/termux/termux-app/issues/573
Accessed: 2026-08-30
Quote: "While Termux is in foreground, running e.g. `am start --user 0 -a android.settings.SETTINGS` through `ssh` ... works; but if Termux is in background, nothing happens. While termux-api e.g. `termux-open` through `ssh` works in both cases."

**tasker-http-request-event**
URL: https://tasker.joaoapps.com/userguide/en/help/eh_http_request.html
Accessed: 2026-08-30
Quote: "Tasker will create an HTTP server in the specified port" / "If you have 2 HTTP Request events with the same port and path, only one of them will be considered."

**joaoapps-tasker-6-2**
URL: https://joaoapps.com/tasker-6-2/
Accessed: 2026-08-30
Quote: "Tasker can now receive and react to HTTP Requests... you can do everything that Tasker can do remotely over your network... it supports any kinds of requests, complete with files, headers and anything else an HTTP Request can have."

**tasker-wikipedia**
URL: https://en.wikipedia.org/wiki/Tasker_(application)
Accessed: 2026-08-30
Quote: stable release 6.6.20 (Feb 25, 2026); 6.7.0-beta (Mar 12, 2026); May 2025 generative-AI task generator using OpenRouter/Gemini models.

**autoremote-play-store**
URL: https://play.google.com/store/apps/details?id=com.joaomgcd.autoremote&hl=en_US
Accessed: 2026-08-30
Quote: "With AutoRemote you have full control of your phone, from wherever you are by sending push notifications to your phone and reacting to them in Tasker or AutoRemote standalone apps." Listing shows latest version 3.2.9, last updated Apr 29, 2026 (per AppBrain cross-reference).

**tasker-vs-macrodroid-2026**
URL: https://www.droidrooter.com/blog/macrodroid-vs-tasker-vs-automate-2026/
Accessed: 2026-08-30
Quote: "pick Tasker if you want unlimited Android automation power and you accept a steep learning curve, and pick MacroDroid if you want most of the same automations working in five minutes" — plugin ecosystem for Tasker described as roughly 10x the size of the other two combined.

## SYNTHESIS

For an AI agent that needs to durably act on an Android phone from a home Linux/Mac box, Termux:API is the wrong primary channel if the agent connects over SSH rather than running a local script triggered by Termux itself. The failure mode is real, reproducible across multiple Android 10/11 devices in `termux-api` issue #301, and traces to Android's background-execution/activity-launch restrictions (confirmed generically, not termux-api-specific, in `termux-app` #573) rather than to any termux-api bug — which means it is not fixable by the Termux maintainers and will recur unpredictably across Android versions and OEM skins. It is not a hard "never works" wall either: several reporters saw it resolve after app updates, and some commands (`termux-open`) were reported as SSH-safe even backgrounded on some devices, which makes it worse from an agent-reliability standpoint (silent, version/OEM-dependent flakiness beats a clean failure). If Termux:API must be used, don't SSH directly into a spawned command; instead keep a local `tmux`/`screen` session alive on-device and have the remote agent inject keystrokes into it — a real workaround from the issue thread, at the cost of losing direct stdout capture.

Tasker's native HTTP Server (6.2+, since Jan 2024) is the better-fitting primitive for "trigger an arbitrary phone automation from an external agent on the LAN": it's first-party (no third-party relay app to trust or that can be discontinued), the request originates from Tasker's own always-alive process rather than routing through Termux's background-restricted context, and it composes with Tasker's decade-deep plugin ecosystem to reach anything Termux:API exposes and more (screen automation, app-specific intents, etc.) with one consistent trigger surface. The tradeoff is Tasker's steep authoring learning curve and that the HTTP server must be reachable (LAN-only unless the user accepts port-forwarding/VPN exposure — a security decision worth flagging explicitly to the user, not defaulting to). AutoRemote is a viable secondary/push-based channel (still maintained into 2026) for cases where the agent isn't on the same LAN, but has at least one credible community reliability complaint (dropped messages); Tasker's own HTTP Server should be preferred when LAN reachability is available, with AutoRemote or the community "AirTask" plugin as a fallback for off-LAN triggering.
