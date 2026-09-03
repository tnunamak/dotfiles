---
title: "Termux + openssh + Termux:Boot gives durable, standard-recipe SSH access into an unrooted Android phone's userspace, but background survival needs OEM-specific tuning and filesystem scope stops at shared storage"
date: 2026-08-30
topic: android-device-control
tags: [termux, ssh, android, sshd, termux-boot, doze, battery-optimization, scoped-storage, tailscale, remote-shell]
status: draft
sources: [termux-boot-github, termux-sshd-zicode, termux-sshd-samgalope, tailscale-gist, gh-issue-5150, gh-discussion-3470, dontkillmyapp-xiaomi, dontkillmyapp-oneplus, termux-storage-issue, termux-fs-layout-wiki, tsu-package, alternativeto-termux-ssh, termai-blog-termius-vs-termux, skeptrune-claude-mobile]
source_session: 3463e3ab-cbe6-426b-b831-a07c925c883c
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation/conclusions. Skippable. No citations here.
Filename = the claim in kebab-case (greppable), under the matching topic/ dir.
Add one line to INDEX.md when you create this.
-->

## CLAIMS

**Setup mechanics**
- The standard recipe (repeated across independent guides referencing the Termux wiki) is: `pkg update && pkg install openssh`, set a password with `passwd` (hashed into `~/.termux_authinfo`, no old-password prompt), then run `sshd` to start the daemon [termux-sshd-zicode].
- Termux's sshd listens on port 8022 by default, not 22, because Termux runs as a non-root/unprivileged Android app process and ports below 1024 are privileged; `sshd_config` explicitly documents "do not set port to 22 as it will not run" [termux-sshd-zicode].
- If `sshd` fails with a "no hostkeys available" error, the fix is `ssh-keygen -A` before retrying `sshd` [termux-sshd-zicode].
- Key-based auth is set up the normal OpenSSH way: generate a keypair on the client, then either `ssh-copy-id -p 8022 <user>@<phone-ip>` or manually append the public key to `~/.ssh/authorized_keys` on the phone [termux-sshd-zicode].
- `sshd_config` lives at `/data/data/com.termux/files/usr/etc/ssh/sshd_config` inside Termux's private app-scoped filesystem prefix [termux-sshd-zicode].
- Community guidance is to install Termux from F-Droid or GitHub, not the Google Play Store build, because the Play Store version is outdated/differently maintained and the two are signed with different keys (can't upgrade across them without uninstalling) [alternativeto-termux-ssh].

**Termux:Boot (auto-start on reboot)**
- Termux:Boot is a separate companion app that registers an Android `BOOT_COMPLETED` broadcast receiver; on boot it launches Termux and executes every executable script found in `~/.termux/boot/`, in sorted filename order [termux-boot-github].
- Termux:Boot must be launched manually (tapped) at least once after install to register as a boot receiver — it has no UI and immediately exits after that one-time registration [termux-boot-github].
- The official README documents no OEM battery-manager caveats, no Android-version-specific reliability notes, and no autostart-permission requirement — those failure modes are absent from the primary source and only surfaces in community discussion/wiki content, not the GitHub README [termux-boot-github].
- Community guidance (Termux's own GitHub Discussions, citing dontkillmyapp.com) states that on many OEM skins, both Termux and Termux:Boot need battery-optimization disabled AND an OEM-specific "autostart" permission enabled, or the boot receiver/script will not reliably fire [gh-discussion-3470].
- Xiaomi (MIUI/HyperOS) requires enabling "Autostart" per-app and, on MIUI 14+, a separate "Background autostart" toggle under App permissions; Android One variants of Xiaomi devices behave closer to stock and are less affected [dontkillmyapp-xiaomi].
- OnePlus has a distinct "App Auto-Launch" toggle plus "Deep optimization"/"Adaptive Battery" advanced battery settings that are enabled by default and are described as the main app-killer on that OEM [dontkillmyapp-oneplus].
- OEM battery/autostart settings commonly reset after system/OS updates, requiring the exemptions to be re-applied [dontkillmyapp-xiaomi].

**Background survival (screen off / not foreground)**
- `termux-wake-lock` only prevents CPU sleep (Doze-related CPU/network throttling); it does not prevent OEM low-memory killers (documented specifically for HyperOS/MIUI) from killing the Termux process outright to reclaim RAM [tailscale-gist].
- The combination reported as actually effective for keeping `sshd` alive is: `termux-wake-lock` + battery optimization set to "Unrestricted" for Termux (and any VPN/tunnel companion app) + pinning/locking the Termux card in the Android recent-apps screen so the OS won't reclaim its memory [tailscale-gist].
- Even with wake-lock, "Unrestricted" battery optimization, and app-pinning applied together, a filed Termux GitHub issue (Android 15, Motorola moto g15, Termux 0.119.0-beta.3) reports the OS still kills long-running background processes ("yt-dlp monitors, bash loops") after backgrounding; the issue was closed with no documented maintainer fix or root-cause confirmation in the visible thread [gh-issue-5150].
- Termux's own historical GitHub discussion states this is not a Termux bug: Doze mode (introduced Android 6) is designed to restrict background apps' CPU/network access, and Termux processes get no special exemption from that design [gh-issue-5150 discussion context via search].
- OEM skins (MIUI, ColorOS, HarmonyOS/EMUI, FunTouchOS) are repeatedly named as adding their own more-aggressive memory management on top of stock Android Doze, and Termux has a filed issue specifically for EMUI killing it even while holding a wakelock [dontkillmyapp-xiaomi].

**Filesystem scope without root**
- `termux-setup-storage` requests the Android shared-storage permission and creates `~/storage/{shared,downloads,dcim,music,pictures,...}` as symlinks into the appropriate shared-storage locations [termux-fs-layout-wiki].
- Without root, Termux cannot access other apps' private data directories (`/data/data/com.otherapp/`) — this requires root, full stop, and is blocked by both standard Unix file permissions (different UID) and Android's Scoped Storage model (Android 11+) [termux-storage-issue].
- Programs generally cannot be executed directly from `/sdcard`/`/storage/emulated`/`/mnt/media_rw` because those are emulated/FAT-style filesystem mounts that don't support execute permissions properly [termux-storage-issue].
- Android blocks unprivileged apps, including Termux, from writing to `/`, `/system`, `/data`, and similar system paths; without root these remain read-only or fully inaccessible [termux-storage-issue].
- Root access via `su` (using a wrapper such as the `tsu` Termux package) removes all of the above Scoped Storage / private-data restrictions, and is the documented path to closing the gap — but requires a rooted device, which the user's stated Pixel 8 Pro is not [tsu-package].
- The `tsu` package exists specifically because plain `su` resets `LD_LIBRARY_PATH` and other environment variables for security, breaking Termux's non-standard `$PREFIX`-based binary resolution unless `--preserve-environment` handling is done for you; `tsu` also has a `-p` flag to prefer `/system/bin` binaries when trying to run genuine Android system tools (e.g., `am`) as root from within Termux [tsu-package].

**Comparison to alternatives**
- Across multiple current (2026) comparison write-ups, Termux + `openssh` from F-Droid is described as "essentially the standard/only practical option" for running a persistent SSH *server* on Android; dedicated Play/F-Droid "SSH apps" (Termius, JuiceSSH, ConnectBot, TermAI) are documented as SSH *clients* for connecting outward, with no saved-host manager, key manager, or server-hosting capability of their own [termai-blog-termius-vs-termux].
- UserLAnd is cited as having effectively superseded GNURoot Debian as the go-to "install a full Linux distro (Ubuntu/Kali/Arch) on Android without root" app, but this is a heavier full-distro approach aimed at getting more packages/a GUI, not specifically a lighter path to a persistent SSH daemon [alternativeto-termux-ssh].
- The convergent pattern used by multiple independent, recent (2026) blog posts for driving remote AI coding agents (Claude Code specifically) from an Android phone is: Termux (shell + sshd) + Tailscale (stable private IP, WireGuard-encrypted, no port forwarding) + tmux (session persistence across disconnects) — the same three-part stack recurs across unrelated authors [skeptrune-claude-mobile, tailscale-gist].
- A blog-documented alternative to Tailscale for the same Termux-sshd stack is Cloudflare Tunnel, paired with Termux Services to auto-restart both `cloudflared` and `sshd` as managed daemons rather than raw boot-script invocations [alternativeto-termux-ssh source set — devctrl.blog cited in search result].
- One source describes a more invasive native alternative — running Tailscale SSH directly against the Android OS (not via Termux) to get a remote shell of the phone itself — but notes this requires deeper system-level modification (custom builds / SELinux policy changes), i.e., is not a stock-Android/unrooted-friendly approach [tailscale-gist search-context, kxxt.dev result].

## SOURCES

**termux-boot-github**
URL: https://github.com/termux/termux-boot
Accessed: 2026-08-30
Quote: "Termux:Boot is a Termux add-on app to run programs at boot." Setup requires launching the app once to register the boot receiver, then placing executable scripts under `~/.termux/boot/`, run in sorted order. No OEM battery-manager or Android-version caveats appear in the README itself.

**termux-sshd-zicode**
URL: https://www.zicode.com/en/blog/termux-openssh-sshd/
Accessed: 2026-08-30
Quote: "This is a key detail across all guides: Termux's SSH server listens on port 8022 by default, not port 22... Do not set port to 22 as it will not run."

**termux-sshd-samgalope**
URL: https://www.samgalope.dev/2024/09/07/how-to-set-up-ssh-on-termux/
Accessed: 2026-08-30
(Corroborating guide for the pkg install openssh / passwd / sshd recipe and port 8022 default, cross-checked against zicode.com and the dmotte.github.io Termux SSH guide.)

**tailscale-gist**
URL: https://gist.github.com/alpharomercoma/67c6698a0ade0c109957843be8837de9
Accessed: 2026-08-30
Quote: "Android aggressively kills background apps, which stops sshd." And: "termux-wake-lock does not stop HyperOS/MIUI from killing the app to free RAM — the recents lock and unrestricted battery settings are what actually maintain server uptime."

**gh-issue-5150**
URL: https://github.com/termux/termux-app/issues/5150
Accessed: 2026-08-30
Quote: (Android 15, Motorola moto g15, Termux 0.119.0-beta.3) "the Android 15 system consistently kills long-running processes (e.g., yt-dlp monitors, bash loops)" despite termux-wake-lock, Unrestricted battery optimization, and app pinned in recents. Issue closed with no visible maintainer-confirmed fix in the fetched content.

**gh-discussion-3470**
URL: https://github.com/termux/termux-app/discussions/3470
Accessed: 2026-08-30
Quote: "make sure auto start, etc. in your android device settings is enabled for both apps" (referencing dontkillmyapp.com for OEM-specific steps).

**dontkillmyapp-xiaomi**
URL: https://dontkillmyapp.com/xiaomi
Accessed: 2026-08-30
Quote: On MIUI 14, "there is a new permission to start from the background for each app, found in Settings > Apps > Your app > App permissions > Background autostart." Also: "Android One devices by Xiaomi work much better than MIUI-based devices."

**dontkillmyapp-oneplus**
URL: https://dontkillmyapp.com/oneplus
Accessed: 2026-08-30
Quote: "System settings > Battery > Battery optimization > (three dots) > Advanced optimization... Deep optimization or Adaptive Battery — this is the main app killer."

**termux-storage-issue**
URL: https://github.com/termux-play-store/termux-apps/issues/18
Accessed: 2026-08-30
Quote: "termux-setup-storage does not give you access to /data/data of other apps — that requires root." Also notes external storage (`/sdcard`, `/storage/emulated`, `/mnt/media_rw`) is emulated/FAT-style and generally cannot execute binaries.

**termux-fs-layout-wiki**
URL: https://github.com/termux/termux-packages/wiki/Termux-file-system-layout
Accessed: 2026-08-30
Quote: `termux-setup-storage` "ensures permission to shared storage is granted" and creates `$HOME/storage` with symlinks (`shared`, `downloads`, `dcim`, `music`, `pictures`, etc.).

**tsu-package**
URL: https://github.com/kiney/tsu
Accessed: 2026-08-30
Quote: "tsu is an su wrapper for the terminal emulator and packages for Android, Termux... Termux relies on LD_LIBRARY_PATH environment variables to find its libraries, and for security reasons some environment variables are reset by su unless a --preserve-environment flag is passed. tsu handles this for you."

**alternativeto-termux-ssh**
URL: https://alternativeto.net/software/termux/?platform=android&tag=ssh-client
Accessed: 2026-08-30
(Comparison context for UserLAnd superseding GNURoot Debian, and Termux F-Droid vs. Play Store distribution/signing-key split.)

**termai-blog-termius-vs-termux**
URL: https://termai.sh/blog/termius-vs-termux/
Accessed: 2026-08-30
Quote: "Termux isn't an SSH client at all, it's a Linux environment on the phone... it has no saved hosts, no key manager, no tap-to-connect." Framed as: use Termux for on-device Linux/server hosting, use a dedicated client (Termius/JuiceSSH) to connect *out* to remote servers.

**skeptrune-claude-mobile**
URL: https://www.skeptrune.com/posts/claude-code-on-mobile-termux-tailscale/
Accessed: 2026-08-30
Quote: "the setup uses five standard Unix tools that work together — a desktop runs Claude Code, tailscale creates a private network between devices, termux gives a real terminal on Android, SSH handles the connection, and tmux keeps sessions alive when you disconnect."

## SYNTHESIS

Termux + `openssh` + Termux:Boot is a real, well-documented, and — as of August 2026 — actively used pattern specifically for driving coding agents from a phone (the skeptrune/jquaintance/amberja blog cluster independently converges on Termux+Tailscale+tmux for exactly this use case, which is strong validation that this is the community's answer to the user's stated goal, not just a theoretical possibility). It genuinely gives real POSIX shell parity (a real OpenSSH server, real bash/coreutils, real package manager) rather than adb's push/pull/shell subset, which is the core requirement the user cares about.

But "durable, no re-authorization dances, survives reboots" is not a solved default state — it is an achieved state that requires ongoing OEM-specific maintenance:

1. **Reboot survival (Termux:Boot) is real but conditional.** The mechanism is legitimate (BOOT_COMPLETED receiver + script execution), but the Pixel 8 Pro is closer to stock Android than a Samsung/Xiaomi device, so the OEM-autostart-toggle failure mode is *less* likely to bite than on MIUI/OnePlus/EMUI — this is actually a point in the user's favor given their specific hardware, worth calling out since much of the OEM-killer research is Samsung/Xiaomi/OnePlus-specific and Pixel devices are the reference/least-aggressive Android implementation.

2. **Background survival is the weaker link, and it is NOT fully solved even with every documented mitigation applied.** The Android 15 GitHub issue (filed after this research's cutoff-adjacent window, closed without a confirmed fix) is the most important finding here: even wake-lock + unrestricted battery + recents-pinning together were reported insufficient on a stock-ish Android 15 device. This means the user should expect sshd to be "usually up," not "guaranteed up" — a monitoring/restart mechanism (e.g., Termux:Boot re-triggering, or a companion service that periodically checks and restarts sshd) is advisable rather than assuming Termux:Boot + wake-lock is a "set and forget" durable channel. This is the single biggest gap between this approach and the user's home-server SSH baseline.

3. **Filesystem parity has a real, hard ceiling without root, and it's a narrower ceiling than "SSH into a Unix box" implies.** The agent gets Termux's own private prefix (full read/write/execute, like a real Unix home) plus shared storage (`/sdcard`-equivalent, read/write but no execute) — but NOT other apps' data, NOT `/system`, NOT true root paths. This is a fundamentally different shape than SSH to a Linux server, where the SSH user typically has execute rights everywhere they have write rights. Framed honestly: this gets the agent a real shell and real file access to the *shared/user* layer of the phone, plus whatever `termux-api` exposes (notifications, clipboard, sensors, etc., not researched in depth here) — not administrative control of the OS or other apps' data. Rooting would close this gap (via `tsu`/`su`), but the user specified unrooted/stock, so that's out of scope by their own framing, and rooting a Pixel is a materially bigger commitment (bootloader unlock, warranty/Play Integrity implications) that should be a separate explicit decision, not a research-implied recommendation.

4. **No better alternative exists for "durable server" specifically.** UserLAnd/GNURoot/AnLinux are heavier, aimed at full-distro/GUI use cases, not a lighter path to persistent SSH. Dedicated "SSH apps" on F-Droid/Play are uniformly clients, not servers — there is no polished, purpose-built "SSH server for Android" app that the community prefers over Termux+openssh. Tailscale (or Cloudflare Tunnel) solves the *network reachability* half of the problem (stable address, no port-forwarding/re-auth-per-network-change) but doesn't touch the *process survival* half — the two problems are independent and both must be solved.

**Bottom line for the user's actual question:** viable, yes — with the caveat that "just works, survives reboots, no re-authorization dances" is closer to "works most of the time, needs a restart-on-failure safety net, and Termux:Boot handles reboots reliably on a Pixel specifically because Pixel isn't one of the aggressive OEM skins" than to the zero-maintenance reliability of `ssh localadmin@192.168.1.11` on a purpose-run Linux box. The Tailscale (or equivalent stable-network) layer is not optional — without it, IP changes on every network switch would itself be a recurring re-authorization-adjacent friction point.
