---
title: "DrKonqi pickup's intentional runtime bound produces a benign failed-unit timeout"
date: 2026-07-24
topic: systemd
tags: [drkonqi, systemd, coredump, journal, kubuntu]
status: settled
sources: [kde-pickup-origin, kde-drkonqi-v664, kde-drkonqi-master, kde-bug-484864, systemd-runtime-max, eos-timeout-report, arch-disable-thread]
source_session: 019f95fa-58a3-7d30-abed-fbdb98c2ec7f
---

## CLAIMS

- KDE introduced pickup mode to run at login and recover user crashes that happened during logout or shutdown; its original unit bounded that process to 31 minutes. [kde-pickup-origin]
- DrKonqi v6.6.4's pickup unit starts the coredump processor with `--settle-first --pickup --uid %U` and `RuntimeMaxSec=30 minutes`. [kde-drkonqi-v664]
- In pickup mode, the processor skips a journal entry when its `COREDUMP_FILENAME` no longer exists, but does not emit its `finished` signal for that path. [kde-drkonqi-v664]
- The watcher emits `atLogEnd` after scanning journal history, while the processor exits only on `finished` or `error`; it therefore remains subscribed after an all-missing historical scan. [kde-drkonqi-v664]
- Upstream master retained the same pickup control flow on 2026-07-24. [kde-drkonqi-master]
- KDE previously replaced an external service-level startup sleep with an in-process delay because the external delay interfered with service lifecycle and stopping. [kde-bug-484864]
- systemd documents that exceeding `RuntimeMaxSec=` terminates the service and places it in a failure state. [systemd-runtime-max]
- The same 30-minute DrKonqi timeout, SIGTERM, low CPU use, and failed result has been reported on an Arch-derived Plasma installation. [eos-timeout-report]
- Arch community advice for unwanted DrKonqi failed units is to mask DrKonqi or filter it from failed-unit output, while noting that doing so gives up useful crash handling. [arch-disable-thread]

## SOURCES

**kde-pickup-origin**
URL: https://invent.kde.org/plasma/drkonqi/-/commit/6ba3b16f3d2429aaa7480f86f13252928f5d228d
Accessed: 2026-07-24

**kde-drkonqi-v664**
URL: https://invent.kde.org/plasma/drkonqi/-/tree/v6.6.4/src/coredump
Accessed: 2026-07-24

**kde-drkonqi-master**
URL: https://invent.kde.org/plasma/drkonqi/-/tree/master/src/coredump
Accessed: 2026-07-24

**kde-bug-484864**
URL: https://bugs.kde.org/show_bug.cgi?id=484864
Accessed: 2026-07-24

**systemd-runtime-max**
URL: https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html#RuntimeMaxSec=
Accessed: 2026-07-24

**eos-timeout-report**
URL: https://forum.endeavouros.com/t/drkonqi-coredump-pickup-service-keeps-failing/70040
Accessed: 2026-07-24

**arch-disable-thread**
URL: https://bbs.archlinux.org/viewtopic.php?id=301585
Accessed: 2026-07-24

## SYNTHESIS

`/var/lib/systemd/coredump` and DrKonqi's report cache are not the pickup
cursor. The discriminator is the retained `systemd-coredump` journal metadata:
it records the historical core filename even after the core has been removed.
Moving or deleting reports cannot make the pickup process exit and would lose
recoverable crash context.

The 30-minute pickup window is intentional, but surfacing its normal expiration
as a failed unit appears to be a lifecycle mismatch. No exact KDE bug, accepted
patch, or consensus workaround for that mismatch was found. Exact reports are
generally unresolved. Community responses split between ignoring the harmless
timeout and masking DrKonqi when crash pickup is not wanted; masking sacrifices
useful crash handling.

A local user-unit drop-in was tested that replaced systemd's failing 30-minute
runtime ceiling with an explicit 30-minute GNU `timeout` and marked status 124
successful. It preserved the vendor's runtime bound and kept early processor
failures visible, but it could not distinguish expected expiration from a real
30-minute hang. The drop-in was removed because it was a custom workaround for
cosmetic state. The chosen local policy is to retain KDE's vendor unit and
manually recognize this exact 30-minute timeout signature as benign. No status
collector or automatic exception was added.
