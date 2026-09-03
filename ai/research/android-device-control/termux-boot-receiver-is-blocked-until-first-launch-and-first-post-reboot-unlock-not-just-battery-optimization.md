---
title: "Termux:Boot's BOOT_COMPLETED receiver is blocked by two independent Android gates — the app's own never-launched 'stopped' state, and Direct Boot/FBE holding non-aware receivers until the first post-reboot screen unlock — neither of which is fixed by battery-optimization whitelisting"
date: 2026-08-31
topic: android-device-control
tags: [termux, termux-boot, direct-boot, boot-completed, android, empirical]
status: draft
sources: [live-device-repro]
source_session: 3463e3ab-cbe6-426b-b831-a07c925c883c
---

## CLAIMS

- A freshly-installed Termux:Boot APK (sideloaded via F-Droid/adb, never opened) has `stopped=true notLaunched=true` in `dumpsys package com.termux.boot`, and in this state its `BOOT_COMPLETED` receiver does not fire at all on reboot — confirmed by a full `logcat -d` capture spanning the boot window showing dozens of other apps' `BOOT_COMPLETED` receivers firing (WorkManager RescheduleReceiver, Bluetooth, telephony, etc.) with zero log lines mentioning `com.termux.boot` anywhere in that window. [live-device-repro]
- `adb shell am start -n com.termux.boot/.BootActivity` fails with `Error type 3: Activity class ... does not exist` while the app is in this stopped state, even though `dumpsys package` correctly lists that exact activity in its `MAIN`/`LAUNCHER` resolver table — `pm grant` and explicit `am start` cannot clear "stopped" from adb; only an actual launch (a real tap on the icon, or an intent Android accepts as a genuine launch) clears `stopped=false notLaunched=false`. [live-device-repro]
- Adding both `com.termux` and `com.termux.boot` to the Doze/App-Standby whitelist via `adb shell dumpsys deviceidle whitelist +<pkg>` (confirmed present afterward via the read-back `dumpsys deviceidle whitelist` listing) did NOT, by itself, make the boot receiver fire — a full reboot afterward still showed zero termux processes and no port 8022 listener after 150+ seconds of uptime. This rules out battery/Doze whitelisting as the (or a sufficient) fix for the no-launch case. [live-device-repro]
- After launching Termux:Boot once (clearing its stopped state) and rebooting again, the `BOOT_COMPLETED` receiver still did not fire immediately at boot — `logcat` showed dozens of unrelated apps' receivers firing within the first ~2 seconds after the "Boot Completed" system broadcast window (~10:13:41–10:14:02 in the captured trace), but `com.termux.boot`'s receiver process only started at 10:14:48, and only after the device screen was unlocked with the user's credentials. `dumpsys package com.termux.boot` shows no `directBootAware` flag or FBE-allowlist entry, consistent with Android's documented Direct Boot behavior: non-direct-boot-aware `BOOT_COMPLETED` receivers are deferred by the OS until the user first unlocks the device's credential-encrypted storage after boot, not delivered at the literal "boot completed" moment. [live-device-repro]
- Once launch-state and first-unlock both occurred, the pipeline completed automatically and reliably: `ActivityManager: Start proc ...com.termux.boot/... for broadcast {com.termux.boot/com.termux.boot.BootReceiver}` at T+0s from unlock, followed ~33s later by `Start proc ...com.termux/... for started-service {com.termux/com.termux.app.TermuxService}`, and sshd was listening on port 8022 and reachable via `ssh` with key-auth within about 70 seconds of the unlock event. [live-device-repro]
- A background-activity-launch attempt by Termux itself (`android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, trying to prompt the user for the exemption dialog) was blocked by Android's background-activity-launch restrictions (`BAL_BLOCK`) during this same boot sequence — harmless in this case because the exemption had already been granted out-of-band via `dumpsys deviceidle whitelist`, but notable as a case where Termux's own self-service permission-request UI silently fails when triggered from a background/boot context, with no user-visible error. [live-device-repro]

## SOURCES

**live-device-repro**
URL: (no URL — hands-on empirical reproduction on the user's own Pixel 8 Pro, Android build with kernel 6.1.157-android14, during this session)
Accessed: 2026-08-31
Quote: "ActivityManager: Start proc 14959:com.termux.boot/u0a518 for broadcast {com.termux.boot/com.termux.boot.BootReceiver}" (logcat, captured 2026-08-31 10:14:48, ~63 seconds after the "Boot Completed" broadcast window began and immediately following a manual screen unlock)

## SYNTHESIS

The corpus's existing `termux-sshd-plus-termuxboot-gives-durable-but-imperfect-ssh-parity` entry (2026-08-30, pure research, no hands-on verification) correctly flagged OEM battery-killer behavior as the main risk to Termux:Boot durability, and noted a Pixel is less exposed to that specific risk than Samsung/Xiaomi/OnePlus. That's true, but it's not the whole story — this session found and fixed two DIFFERENT gates that have nothing to do with OEM battery-killer aggressiveness, on a Pixel 8 Pro with no custom OEM battery manager involved at all:

1. **The "never launched" gate** — any sideloaded app with a `BOOT_COMPLETED` receiver silently no-ops until it's been opened once. This is generic Android app-standby-bucket behavior (the "NEVER" bucket in `JobScheduler.JobStatus` logs), not Termux-specific, but it's easy to miss because there's no error shown to the user or in `adb shell am start` output that clearly says "this app has literally never been opened, that's why."
2. **The Direct Boot / FBE gate** — even after fixing (1), the receiver still doesn't fire at the literal boot-completed moment on a File-Based-Encryption device (standard on all modern Android). It fires only after the FIRST unlock following that boot. This means Termux:Boot is not "auto-starts on boot" in the naive sense; it's "auto-starts on the first unlock after a boot." For this user's practical purposes (a personal phone they unlock within seconds of it finishing a reboot) this is a non-issue, but it's the actual mechanism, and it matters for any unattended-reboot scenario (e.g., a stuck/crashed phone that reboots itself while the owner is asleep or away) — the SSH channel will NOT come back until someone physically unlocks the screen, and there is no unrooted way to make the receiver Direct-Boot-aware since that requires code changes Termux's maintainers haven't made (and doing so wouldn't help anyway, since the actual `sshd` binary still needs the credential-encrypted `/data` partition to be unlocked to read its host keys).

Practical fix sequence that worked, in order, each step necessary (verified by process of elimination — battery whitelisting alone was tried and failed before adding the unlock step):
1. `adb shell pm grant com.termux com.termux.permission.RUN_COMMAND` (for external-app driving, separate concern)
2. Launch Termux:Boot's icon once, by hand — `adb shell am start` cannot substitute for this while `stopped=true`.
3. `adb shell dumpsys deviceidle whitelist +com.termux.boot` and `+com.termux` (belt-and-suspenders; did not independently fix the no-fire case in this repro, but is cheap and is the officially-recommended mitigation for the OEM-killer risk the existing corpus entry already documented, so keep doing it).
4. Accept that "boots automatically" really means "starts within ~60-90s of the first post-reboot unlock," and if the phone might reboot unattended, the SSH channel has a real, unavoidable gap until someone unlocks it.
