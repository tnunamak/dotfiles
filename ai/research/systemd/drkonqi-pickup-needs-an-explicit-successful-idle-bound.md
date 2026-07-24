---
title: "DrKonqi pickup needs an explicit successful idle bound when journal metadata outlives its core files"
date: 2026-07-24
topic: systemd
tags: [drkonqi, systemd, coredump, journal, kubuntu]
status: settled
sources: [kde-drkonqi-v664, kde-drkonqi-master, systemd-success-exit-status]
---

## CLAIMS

- DrKonqi v6.6.4's pickup unit starts the coredump processor with `--settle-first --pickup --uid %U` and `RuntimeMaxSec=30 minutes`. [kde-drkonqi-v664]
- In pickup mode, the processor skips a journal entry when its `COREDUMP_FILENAME` no longer exists, but does not emit its `finished` signal for that path. [kde-drkonqi-v664]
- The watcher emits `atLogEnd` after scanning journal history, while the processor exits only on `finished` or `error`; it therefore remains subscribed after an all-missing historical scan. [kde-drkonqi-v664]
- Upstream master retained the same pickup control flow on 2026-07-24. [kde-drkonqi-master]
- systemd treats a process exit status named in `SuccessExitStatus=` as successful; an isolated user-unit test confirmed GNU `timeout` exit status 124 yields `Result=success` when configured there. [systemd-success-exit-status]

## SOURCES

**kde-drkonqi-v664**
URL: https://invent.kde.org/plasma/drkonqi/-/tree/v6.6.4/src/coredump
Accessed: 2026-07-24

**kde-drkonqi-master**
URL: https://invent.kde.org/plasma/drkonqi/-/tree/master/src/coredump
Accessed: 2026-07-24

**systemd-success-exit-status**
URL: https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html#SuccessExitStatus=
Accessed: 2026-07-24

## SYNTHESIS

`/var/lib/systemd/coredump` and DrKonqi's report cache are not the pickup
cursor. The discriminator is the retained `systemd-coredump` journal metadata:
it records the historical core filename even after the core has been removed.
Moving or deleting reports cannot make the pickup process exit and would lose
recoverable crash context.

The narrow local mitigation is a user-unit drop-in that replaces systemd's
failing 30-minute runtime ceiling with an explicit 30-minute GNU `timeout`,
then marks that timeout's conventional status 124 successful. This preserves
the vendor's runtime bound; ordinary processor errors before the bound remain
failures. A hang or unusually slow pickup that reaches the bound is necessarily
classified as the expected timeout, so this workaround cannot distinguish that
case from the known idle watcher. Remove the drop-in once an upstream release
exits pickup on `atLogEnd`.
