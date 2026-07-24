---
title: "DrKonqi pickup needs an explicit successful idle bound when journal metadata outlives its core files"
date: 2026-07-24
topic: systemd
tags: [drkonqi, systemd, coredump, journal, kubuntu]
status: settled
sources: [kde-drkonqi-v664, kde-drkonqi-master, kde-bug-484864, systemd-runtime-max, eos-timeout-report]
---

## CLAIMS

- DrKonqi v6.6.4's pickup unit starts the coredump processor with `--settle-first --pickup --uid %U` and `RuntimeMaxSec=30 minutes`. [kde-drkonqi-v664]
- In pickup mode, the processor skips a journal entry when its `COREDUMP_FILENAME` no longer exists, but does not emit its `finished` signal for that path. [kde-drkonqi-v664]
- The watcher emits `atLogEnd` after scanning journal history, while the processor exits only on `finished` or `error`; it therefore remains subscribed after an all-missing historical scan. [kde-drkonqi-v664]
- Upstream master retained the same pickup control flow on 2026-07-24. [kde-drkonqi-master]
- KDE previously replaced an external service-level startup sleep with an in-process delay because the external delay interfered with service lifecycle and stopping. [kde-bug-484864]
- systemd documents that exceeding `RuntimeMaxSec=` terminates the service and places it in a failure state. [systemd-runtime-max]
- The same 30-minute DrKonqi timeout, SIGTERM, low CPU use, and failed result has been reported on an Arch-derived Plasma installation. [eos-timeout-report]

## SOURCES

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

## SYNTHESIS

`/var/lib/systemd/coredump` and DrKonqi's report cache are not the pickup
cursor. The discriminator is the retained `systemd-coredump` journal metadata:
it records the historical core filename even after the core has been removed.
Moving or deleting reports cannot make the pickup process exit and would lose
recoverable crash context.

The proper fix belongs in DrKonqi. Pickup mode should own its lifecycle and exit
successfully when it has exhausted the historical journal without finding an
actionable core. KDE's earlier repair to this unit also moved timing behavior
into the process rather than leaving it in service orchestration.

Until upstream implements that lifecycle, the narrow local workaround is a
user-unit drop-in that replaces systemd's failing 30-minute runtime ceiling
with an explicit 30-minute GNU `timeout`, then marks that timeout's conventional
status 124 successful. This preserves the vendor's runtime bound; ordinary
processor errors before the bound remain failures. It is not an ideal fix: a
hang or unusually slow pickup that reaches the bound is necessarily classified
as the expected timeout. Remove the drop-in once an upstream release exits
pickup cleanly after journal exhaustion.
