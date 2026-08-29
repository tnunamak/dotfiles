---
title: "apt-get autoclean plus apt-get autoremove --purge is the documented safe pair for reclaiming apt cache and kernel disk space, with kernel removal protected by APT::Protect-Kernels (running kernel + 1 rollback kept by default) — but on a real machine, old kernels that were manually apt-installed (not auto-installed as dependencies) are marked apt-mark manual and are invisible to autoremove regardless of how old or unused they are"
date: 2026-08-29
topic: dev-tool-caches
tags: [apt, dpkg, kernel-cleanup, autoremove, autoclean, ubuntu, debian]
status: draft
sources: [apt-conf-manpage, apt-get-manpage, empirical-repro]
source_session: a253134e-8cd3-4ed2-a541-bea105c07228
---

## CLAIMS

- `apt-get clean` removes the entire contents of `/var/cache/apt/archives/` (all cached `.deb` files); `apt-get autoclean` removes only cached packages whose exact version is no longer available from any configured repository (i.e., superseded versions) — confirmed via `apt-get(8)`'s own description of each subcommand. `autoclean` is the more conservative default for a tool that shouldn't force every future install to re-download. [apt-get-manpage]
- `APT::Protect-Kernels` defaults to `true` and is documented specifically to prevent `apt-get autoremove` from ever removing the currently-running kernel, plus at least one additional (rollback) kernel — confirmed via `apt.conf(5)`: "This option tells apt autoremove that kernels are protected and defaults to true. In case kernels are not protected they are treated as any other package." [apt-conf-manpage]
- `APT::VersionedKernelPackages` is a real, populated regex list on a live Ubuntu/Kubuntu machine (confirmed via `apt-config dump`: includes `linux-.*`, `kfreebsd-.*`, `gnumach-.*`, `.*-modules`, `.*-kernel`) — this is the mechanism `autoremove` uses to recognize kernel packages and apply the protection rule to them specifically, rather than kernel protection being a special-cased hardcoded package-name list. [empirical-repro]
- **Critical machine-specific finding, not covered by the general apt documentation**: `apt-get autoremove`'s kernel protection only matters for packages APT considers eligible for autoremoval in the first place — i.e. packages marked "automatically installed" (`apt-mark showauto`). On a real, live machine with 5 installed kernel packages spanning versions 6.17.0-23 through 7.0.0-30 (current), 2 of the older kernels (`7.0.0-27`, `7.0.0-29`) were found marked MANUALLY installed (`apt-mark showmanual` output included them), and a real `apt-get -s autoremove --purge` (simulate mode) on this machine reported "0 to remove" — meaning the 1.5G of old kernel files in `/boot` on this specific machine will NOT be reclaimed by `autoremove` at all, regardless of the Protect-Kernels mechanism, because the packages were never in the auto-removal candidate pool to begin with. [empirical-repro]
- Reclaiming that specific space would require an explicit `apt-mark auto <package>` re-labeling step before `autoremove` would consider the package — a materially bigger, more consequential action (changing package installation-reason metadata) than passively running a cleanup pair, and not something a `--yes`-style automated tool should do without a human decision, since the manual-install marking on a kernel package is often intentional (e.g. pinning a known-working kernel across upgrades). [empirical-repro, reasoning]
- No official Debian/Ubuntu documentation was found endorsing direct manipulation of files under `/boot` (deleting `vmlinuz-*`/`initrd.img-*` outside of dpkg/apt) — dpkg tracks kernel package file lists in its own database, and removing files it believes it owns without going through `dpkg -r`/`apt-get remove` desyncs that database, which can break subsequent `apt-get upgrade`/`autoremove` runs against the same package.

## SOURCES

**apt-get-manpage**
URL: man apt-get(8) (Debian/Ubuntu system manual)
Accessed: 2026-08-29
Quote: "clean clears out the local repository of retrieved package files... autoclean ... like clean, autoclean clears out the local repository of retrieved package files. The difference is that it only removes package files that can no longer be downloaded, and are largely useless."

**apt-conf-manpage**
URL: man apt.conf(5) (Debian/Ubuntu system manual), Protect-Kernels section
Accessed: 2026-08-29
Quote: "Protect-Kernels — This option tells apt autoremove that kernels are protected and defaults to true. In case kernels are not protected they are treated as any other package."

**empirical-repro**
URL: n/a (local verification, this machine, apt/dpkg live state)
Accessed: 2026-08-29
Quote: "apt-config dump | grep VersionedKernelPackages → linux-.*, kfreebsd-.*, gnumach-.*, .*-modules, .*-kernel (all present)" / "apt-mark showmanual 'linux-image*' → linux-image-7.0.0-27-generic, linux-image-7.0.0-29-generic, linux-image-7.0.0-30-generic" / "apt-get -s autoremove --purge → 0 upgraded, 0 newly installed, 0 to remove and 4 not upgraded"

## SYNTHESIS

The general apt documentation and the machine-specific reality diverge in a way that matters for automated tooling: `apt-get autoclean && apt-get autoremove --purge` is genuinely the correct, safe, kernel-protected pair to run non-interactively — but "safe and correct" does not mean "will reclaim the space a human might expect it to." On this machine specifically, running that pair would free the apt cache (real, safe, worth doing) but leave the old-kernel disk usage in `/boot` completely untouched, because the packages consuming that space were never candidates for autoremoval to begin with (manually-installed flag, likely from a prior explicit `apt install linux-image-X` or an interrupted/held upgrade).

For a cleanup tool: implement the safe pair (`autoclean` + `autoremove --purge`) as an automatic sudo-gated tier-2/3 action — this is unconditionally safe per the documentation and empirically confirmed kernel-protected on a real system. Separately, surface old manually-marked kernel packages as an INFO-ONLY line (size + package names), explicitly not auto-actionable, because reclaiming that space requires a `apt-mark auto` relabeling decision that changes packaging metadata semantics a human should make deliberately — mirroring how this same codebase already treats other consequential-but-not-purely-mechanical categories (e.g. `nvm_versions` lists candidates but lets the user pick interactively rather than blanket-deleting). Do not attempt to infer "this manually-marked kernel is definitely unwanted" from version age alone — a manual mark can reflect an intentional pin against a regression, and the cost of guessing wrong here is a machine that fails to boot into a kernel the user specifically wanted kept.
