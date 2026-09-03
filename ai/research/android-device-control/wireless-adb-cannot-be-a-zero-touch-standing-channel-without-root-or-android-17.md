---
title: "Wireless ADB (Android Debug Bridge) cannot be a zero-touch, always-on remote-control channel on unrooted Android 11-16 — the Wireless-debugging toggle itself is reset by reboot and by Wi-Fi off/on, and only Android 17's adb Wi-Fi 2.0 (or root) closes the gap"
date: 2026-08-30
topic: android-device-control
tags: [adb, android, wireless-debugging, mdns, doze, remote-control, tasker, magisk]
status: draft
sources: [dev-docs, lineageos-adb-wifi, xda-a12-toggle-off, androidauthority-fixed, androidauthority-announce, devto-silent-disconnect, dracediax-readme, tasker-adb-wifi, xda-a13-noroot-boot, adb-quickstart, magisk-wifiadb, wadbd, wirebug, androidcentral-doze-wifi]
source_session: 3463e3ab-cbe6-426b-b831-a07c925c883c
---

## CLAIMS

- Pre-Android-11, wireless ADB required `adb tcpip <port>` issued over an existing USB (or same-boot-session) connection, and that TCP-listening mode does not survive a reboot on any Android version — the daemon reverts to USB-only until re-enabled. [lineageos-adb-wifi] [dracediax-readme]
- Android 11 added a dedicated "Wireless debugging" feature in Developer Options with `adb pair` (QR code or 6-digit pairing code) for initial trust bootstrap, distinct from the legacy `adb connect` flow used pre-11. [lineageos-adb-wifi] [dev-docs]
- The pairing relationship (the host's RSA public key stored in the device's `/data/misc/adb/adb_keys` keystore) persists across reboots once established; what does NOT persist is the "Wireless debugging" toggle state itself, which multiple independent reports describe as reset to off by (a) a device reboot and (b) turning Wi-Fi off then back on. [lineageos-adb-wifi] [xda-a12-toggle-off] [androidauthority-fixed]
- On Android 11+ with Wireless debugging re-enabled, the TLS connect port is re-randomized each session (`service.adb.tls.port` / a random port shown in the UI) — there is no fixed 5555-style port to hardcode, unlike the legacy `tcpip` mode. [lineageos-adb-wifi] [dev-docs]
- Android's wireless debugging advertises itself via mDNS using three distinct service types: `_adb._tcp` (legacy tcpip service), `_adb-tls-pairing._tcp` (active while the on-device pairing server is running), and `_adb-tls-connect._tcp` (active once the paired TLS server is listening) — `adb mdns services` / `adb mdns track-services --proto-text` on the host resolves the current IP:port dynamically from these records rather than depending on a hardcoded address. [lineageos-adb-wifi] [dev-docs]
- Because discovery is mDNS-based, a DHCP lease renewal or IP change on the phone does not by itself break reconnection — the host is expected to re-query `adb mdns services`/`track-services` and reconnect to whatever IP:port the service records currently advertise, rather than reuse a stale IP. If mDNS is filtered/unsupported on the network, `adb mdns track-services` returns empty output, and the documented fallback is the legacy USB-assisted `adb tcpip`/`adb connect` flow (which then does hardcode IP:port until it too is invalidated by reboot or IP change). [lineageos-adb-wifi] [dev-docs]
- Multiple independent user reports attribute wireless-debugging drop-offs while the screen is off / device idle on Wi-Fi to (a) system-wide Doze/App-Standby network suspension, and/or (b) a separate OEM/profile-level "Wi-Fi control" component turning Wi-Fi off entirely when the screen sleeps (one reported case: a Work Profile Setup app's "Special App Access → Wi-Fi control" governing this on a Pie device). [androidcentral-doze-wifi] [xda-a12-toggle-off]
- A developer-facing report (Wear OS 4 wireless debugging on Galaxy Watch) attributes mid-session disconnects specifically to Google Play Services' battery/system-efficiency management cutting the Wi-Fi connection, not to the ADB stack itself. [samsung-forum]
- A separate first-hand report describes a "silent disconnect" failure mode distinct from Doze: the wireless connection drops but `adb devices` continues reporting the device as connected for a period afterward, with commands returning nothing rather than an error — the author's diagnosis is that Wi-Fi ADB has no built-in liveness/heartbeat signal, unlike USB's deterministic connect/disconnect events, and the workaround is an application-level keepalive (polling `adb shell echo ok` on an interval and treating a failure as an immediate disconnect signal). [devto-silent-disconnect]
- Official Tasker documentation states there is no known way to run the ADB wireless-debugging-enable command automatically at boot using Tasker alone; community workarounds combine Termux:Boot (to run a boot-triggered script) with Tasker profiles that watch Logcat for the randomly assigned port and then issue `adb tcpip`/`adb connect`, which needs an active ADB session to begin with — i.e., these are non-root but still require either USB-assisted bootstrapping per boot or root. [tasker-adb-wifi] [fixyourandroid]
- A "no-root, Android 13" XDA project claims a fully unrooted way to auto-enable ADB WiFi in the background on boot via Tasker + the Termux plugin (no manually created scripts required in its current version), reporting success/failure via toast/notification with retry — this is the most credible fully-unrooted claim found, but its exact mechanism (how it triggers the toggle without root, since Android does not expose a public Settings.Global write permission for `adb_wifi_enabled` to third-party/Tasker apps by default) was not independently verified in this research pass. [xda-a13-noroot-boot]
- Root-based solutions are the well-established, widely used pattern for "auto re-enable on every boot": Magisk/KernelSU modules (`magisk-wifiadb`, `dracediax/wireless-adb`, `Magisk-Modules-Alt-Repo/wadbd`) run a boot-time script (`service.sh`) that calls `setprop service.adb.tcp.port <port>; stop adbd; start adbd` (legacy tcpip re-enable) or equivalently flips the wireless-debugging system properties, and explicitly document zero added battery cost because the script runs once (~1 second) at boot with no background process or wakelock. [dracediax-readme] [magisk-wifiadb] [wadbd]
- A non-root toolset (`adb-quickstart` / `adb-auto-enable`) claims persistent wireless ADB across a boot session via a Quick Settings tile plus a one-time pairing step, after which "reconnecting doesn't require re-pairing since wireless ADB stays live until the phone reboots" — i.e., it removes re-pairing friction within a boot session but does not claim to survive reboot without root. [adb-quickstart]
- `wirebug`, by its own README, explicitly requires root to write `system.adb.tcp.port` and restart the daemon — cited here as a second independent confirmation that direct property-write control of the wireless ADB state is a root-gated operation on stock Android. [wirebug]
- Android 17 (paired with ADB platform-tools 37.0.0+) introduces "adb Wi-Fi 2.0," which Google describes as replacing the original wireless-ADB implementation (built on a third-party library originally written for Chromecast, which did not handle host-side network changes like a laptop moving networks or waking from sleep) with a new ~4,000-line Rust library on the host side and Android's native `NsdManager` on the device side; the practical behavior change is that a device automatically re-enables wireless debugging and reconnects to the host when it (re)joins a wireless network the user previously marked trusted ("always allow on this network"), without a manual re-pair. [androidauthority-fixed] [androidauthority-announce] [dev-docs]
- Per Android's own developer documentation, adb Wi-Fi 2.0 support can be verified from the host by running `adb mdns track-services --proto-text` and checking for an `mdns_service_version: "2.0"` (or higher) field in the returned service record; an absent or lower version indicates the device is not on Android 17+ / the 2.0 stack. [dev-docs]
- As of the reporting found, adb Wi-Fi 2.0 was in Android Canary builds with uncertain final ship timing (potentially an Android 16 QPR3 update in March 2026 or held for the Android 17 major release), and the author of that report flagged uncertainty about how it affects third-party tools that depend on the legacy wireless-ADB behavior (e.g. Shizuku). [androidauthority-announce]

## SOURCES

**lineageos-adb-wifi**
URL: https://github.com/LineageOS/android_packages_modules_adb/blob/lineage-23.2/docs/dev/adb_wifi.md
Accessed: 2026-08-30
Quote: "Three distinct service types advertise over the network: `_adb._tcp` (Legacy TCP service from `adb tcpip <PORT>`), `_adb-tls-pairing._tcp` (Active when device pairing server runs), `_adb-tls-connect._tcp` (Active when TLS server operates)... System properties manage state across reboots: `persist.adb.tls_server.enable`, `service.adb.tls.port`, `persist.adb.wifi.guid`."
(Note: content retrieved via an AI-summarizing fetch tool rather than verbatim page text; treat structural claims as reliable but exact property names as paraphrase-level confidence, not a verbatim quote from the doc.)

**dev-docs**
URL: https://developer.android.com/tools/adb
Accessed: 2026-08-30
Quote: "Android 17 introduces ADB Wi-Fi 2.0, which provides automatic reconnection and improved usability... Device paired once remains paired until explicitly forgotten. Automatic connection on same network (no manual `adb connect` needed)... `adb mdns track-services --proto-text` ... shows `mdns_service_version: '2.0'` for Android 17+."
(Note: same caveat as above — retrieved via AI-summarizing fetch, treat as paraphrase of the official docs, not verified verbatim; the underlying claims (mDNS service types, pairing flow, mdns_service_version field) are consistent with independent sources below.)

**xda-a12-toggle-off**
URL: https://xdaforums.com/t/android-12-developer-options-adb-wireless-debugging-option-keeps-turning-off.4461375/
Accessed: 2026-08-30
Quote: "a lot of things turn the 'Wireless debugging' switch off on you — boot turns it off, and it also automatically turns off whenever Wi-Fi is turned off" (per search-result snippet; direct page fetch returned HTTP 403).

**androidauthority-fixed**
URL: https://www.androidauthority.com/android-17-adb-wi-fi-2-0-3678411/
Accessed: 2026-08-30
Quote: "Launched with Android 11, the original wireless ADB relied on... a library... initially built for Chromecast... network changes completely killed the old wireless stack... Google dropped the messy third-party dependencies in favor of its own lightweight, 4,000-line Rust library... On the device side, the phone now leverages the native Android NsdManager platform stack."

**androidauthority-announce**
URL: https://www.androidauthority.com/android-wireless-adb-auto-reconnect-3624945/
Accessed: 2026-08-30
Quote: "Android is getting a quality-of-life update that automatically turns on wireless debugging when connected to trusted Wi-Fi networks... currently active in recent Android Canary builds... could arrive as early as Android 16 QPR3 (March 2026) or be delayed until the Android 17 major release."

**devto-silent-disconnect**
URL: https://dev.to/hiyoyok/wi-fi-adb-lies-to-you-the-silent-disconnect-problem-no-one-talks-about-ii3
Accessed: 2026-08-30
Quote: "The device showed as connected. Commands returned nothing. No error, no crash — just silence... Poll this every 5 seconds in a background task. When it returns `false`, mark the device as disconnected immediately."

**dracediax-readme**
URL: https://github.com/dracediax/wireless-adb
Accessed: 2026-08-30
Quote: "setprop service.adb.tcp.port 5555 / stop adbd / start adbd... None. The module runs a single script at boot that takes ~1 second, then exits. No background process, no polling, no wake locks."

**tasker-adb-wifi**
URL: https://tasker.joaoapps.com/userguide/en/help/ah_adb_wifi.html
Accessed: 2026-08-30
Quote: "the ADB command needed for this feature has to be run every time you reboot your device, and there's no known way to run it on boot automatically" (per search-result summary of the official Tasker user guide page).

**xda-a13-noroot-boot**
URL: https://xdaforums.com/t/project-a13-no-root-automatically-enable-adb-wifi-on-boot-in-background.4646433/
Accessed: 2026-08-30
Quote: "[[DEPRECATED]] [PROJECT][A13][NO ROOT] Automatically enable ADB WiFi on boot (IN BACKGROUND)... you'll be informed with a toast and notification if ADB WiFi has been enabled successfully; if not, you can retry."

**adb-quickstart**
URL: https://github.com/Tarunswamy-Muralidharan/adb-quickstart
Accessed: 2026-08-30
Quote: "Three non-root tools for Android USB Debugging and Wireless ADB — Quick Settings tile, persistent wireless ADB on WiFi, and a one-click script for wireless ADB over phone hotspot... reconnecting doesn't require re-pairing since wireless ADB stays live until the phone reboots."

**magisk-wifiadb**
URL: https://github.com/mrh929/magisk-wifiadb
Accessed: 2026-08-30
Quote: "A magisk module to enable WiFi ADB automatically... if you accidentally reboot the device while the module switch is turned OFF, WiFi ADB will not start on boot."

**wadbd**
URL: https://github.com/Magisk-Modules-Alt-Repo/wadbd
Accessed: 2026-08-30
Quote: "Allows you to enable or disable wireless ADB for the current session or at boot... supports commands like `wadbd enable-on-boot <port>` and `wadbd disable-on-boot`."

**wirebug**
URL: https://github.com/sryze/wirebug
Accessed: 2026-08-30
Quote: "it requires root permissions, needing root to write to the system.adb.tcp.port property and restart the ADB daemon" (per search-result summary).

**androidcentral-doze-wifi**
URL: https://forums.androidcentral.com/threads/wifi-doze-when-screen-off-how-to-defeat-it.997510/
Accessed: 2026-08-30
Quote: "stop 'Work Profile Setup' from controlling the WiFi via Settings / Apps and Notifications / Special App Access / WiFi Control... switching 'Work Profile Setup' to 'Not Allowed'" (per search-result summary of the thread's reported fix).

**samsung-forum**
URL: https://forum.developer.samsung.com/t/wireless-debugging-or-why-must-samsung-break-things-via-updates/28200
Accessed: 2026-08-30
Quote: "Wear OS 4's Google Play Services, intended to improve battery and system efficiency, is what cuts the Wi-Fi connection" (per search-result summary).

**fixyourandroid**
URL: https://fixyourandroid.com/how-to/use-adb-wirelessly-with-android/
Accessed: 2026-08-30
Quote: description of a Tasker+Termux boot profile that "waits ~60 seconds post-boot... enables the global setting 'Debugging over WLAN'... checks Logcat for adb wifi entries, extracts the port... runs `adb tcpip 5555`" (per search-result summary).

## SYNTHESIS

For a coding agent that wants "always just works" shell/file access to a home-network
Android phone with zero owner attention, the honest answer as of Android 11-16 is: you
cannot get there without root, and even with root you're trading manual-toggle friction
for a different kind of fragility (Doze/Wi-Fi-off silently killing the *transport*, not
just the debugging toggle).

**The core problem is layered, not singular.** Three independent things can each break
the channel, and fixing one doesn't fix the others:
1. The "Wireless debugging" toggle resetting on reboot (fixed by root + boot script, or
   by Android 17's adb Wi-Fi 2.0 if the phone has it).
2. The TLS connect port being re-randomized every time the toggle re-enables (fixed by
   using `adb mdns services`/`track-services` for discovery instead of hardcoding a port
   — this part doesn't need root, just correct tooling on the *host* side).
3. Doze/App-Standby or an OEM power-management layer suspending Wi-Fi or network access
   while the screen is off and the phone is idle and unplugged (fixed only by exempting
   the phone from Doze's network restrictions somehow, or accepting the channel goes dark
   when idle and must be woken — e.g. by a push notification or a periodic wake — before
   an agent can talk to it).

**Practical recommendation for a home-network agent-control setup:**
- If root (Magisk/KernelSU) is acceptable: use a boot-time module (dracediax/wireless-adb,
  wadbd, or magisk-wifiadb) to restore the tcpip listener/wireless-debugging state on every
  boot. This closes gap #1 with genuinely zero ongoing owner attention and no measurable
  battery cost (single ~1s boot script, no daemon).
- Regardless of root: don't hardcode IP:port on the controller side. Use `adb mdns
  services` (or `track-services` for a live watch) and reconnect to whatever the current
  `_adb-tls-connect._tcp` record advertises. This is the only mechanism that survives DHCP
  renewal without owner intervention, and it costs nothing to implement.
- Treat "connected" as unreliable. `adb devices` can show a device as connected well after
  the underlying socket has actually died (silent-disconnect failure mode). Any standing
  control loop needs its own liveness probe (`adb shell echo ok` on an interval, e.g. every
  5-30s) and must treat a stalled probe as "reconnect now," not wait for the next real
  command to time out.
- Expect the channel to go dark when the phone is idle, screen-off, and on battery (not
  charging) — this is a real, widely reported Doze/App-Standby interaction, not a fluke.
  Two honest options: (a) keep the phone on a charger/dock, which is the most reliable
  single mitigation reported anywhere in this research, since Doze's network suspension is
  keyed off "unplugged and idle," or (b) architect the agent workflow to tolerate an
  offline phone and reconnect opportunistically rather than assuming a standing session.
- If the target phone is stock Android 17+ (or gets updated to it) and the ADB client is
  platform-tools 37.0.0+, adb Wi-Fi 2.0 may make the whole root/boot-script question moot
  for gap #1 — verify with `adb mdns track-services --proto-text` and look for
  `mdns_service_version: "2.0"`. This wasn't independently hands-on verified in this
  research pass (no device available); treat the "ships without root-level toggle-reset
  friction" claim as sourced from Android Authority's reporting on Canary builds and
  official docs, not as confirmed field behavior at GA.
- Unrooted, no-USB, fully automatic boot re-enable (the XDA "no-root Android 13" project)
  is the least-verified claim in this file — worth a follow-up hands-on test before relying
  on it, since Android does not publicly expose a `Settings.Global` write for
  `adb_wifi_enabled` to a non-privileged app, and the project's own thread title marks it
  deprecated.

**What this means for "just works" as a design goal:** on pre-Android-17 stock devices,
"zero owner attention" and "no root" are in tension. Pick one. Root removes the boot-toggle
problem entirely and at negligible cost; staying unrooted means either accepting periodic
manual re-enable, or building brittle Tasker/Termux automation that itself needs an active
ADB session to bootstrap (chicken-and-egg) — the community's own solutions for this
(Logcat-scraping Tasker profiles) are workarounds for a genuine platform gap, not a stable
production pattern.
