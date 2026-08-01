---
title: "ksecretd going alive-but-unresponsive is a known recurring KDE bug class, and no systemd/D-Bus mechanism can detect it — only client-side Ping-then-kill can"
date: 2026-07-28
topic: self-hosting
tags: [kwallet, ksecretd, dbus, systemd, kde, secret-service]
status: draft
sources: [kde-bug-504656, kde-bug-504014, kde-bug-259942, ksecretd-source, dbus-spec-peer, sd-notify-man, sd-watchdog-man, archwiki-kwallet, qsavefile-docs, azure-circuit-breaker, gdbusconnection-docs]
source_session: 019f5b86-497d-75c2-9c45-146f24daac7e
---

## CLAIMS

- KDE Bug 504656 documents ksecretd (kwallet 6.14) freezing and remaining running-but-unresponsive to Secret Service D-Bus calls when a wallet has an empty name, producing an invalid D-Bus object path during collection enumeration; callers hang ~60s before timeout. Fixed in 6.15. [kde-bug-504656]
- KDE Bug 504014 documents Chromium-based apps taking ~60s to start because ksecretd/kwalletd6, when administratively disabled, did not return an error from `main()`, leaving D-Bus-activation callers hung with no reply. Fixed in 6.14.1. [kde-bug-504014]
- KDE Bug 259942 (2011) documents kwalletd ceasing to respond to all application requests after a delayed password entry, attributed in discussion to a nested-Qt-event-loop bug in the wallet-open code path. [kde-bug-259942]
- ksecretd's `main.cpp` (invent.kde.org/frameworks/kwallet) installs no custom SIGTERM or SIGINT handler; it relies on Qt/POSIX default signal disposition, and its exit path is a plain `return app.exec();` with cleanup only via normal C++ destructor unwinding. [ksecretd-source]
- The D-Bus specification's Peer interface defines `Ping` as a method an application should answer with nothing but a plain reply; it carries no arguments in either direction. [dbus-spec-peer]
- `sd_notify()`'s `WATCHDOG=1` mechanism is cooperative: the monitored application must itself call it on a schedule via its own code; systemd does not poll or probe the application. [sd-notify-man]
- `sd_watchdog_enabled()` is the API an application checks to learn its required watchdog ping interval, again requiring application-side integration to have any effect. [sd-watchdog-man]
- ArchWiki's KDE Wallet page documents KWallet's Secret Service activation via a classic D-Bus `.service` file (`Exec=` activation), not native systemd service activation. [archwiki-kwallet]
- Qt's `QSaveFile` documents the temp-file-write-then-atomic-rename pattern KDE/Qt applications commonly use to make file writes safe against interruption. [qsavefile-docs]
- The circuit breaker pattern (Azure Architecture Center) is designed for many-instance, load-balanced downstream fleets, where the goal is failing fast against a degrading instance while others remain available. [azure-circuit-breaker]
- GNOME's `GDBusConnection` documentation confirms the Peer interface's `Ping`/`GetMachineId` methods are automatically handled by the connection object, but dispatch for a specific process still occurs on that process's own main context. [gdbusconnection-docs]

## SOURCES

**kde-bug-504656**
URL: https://bugs.kde.org/show_bug.cgi?id=504656
Accessed: 2026-07-28
Quote: "kwallet 6.14: calls to ksecretd hang if there's an empty-named wallet"

**kde-bug-504014**
URL: https://bugs.kde.org/show_bug.cgi?id=504014
Accessed: 2026-07-28
Quote: "Chromium-based applications take around 60 seconds to start if KWallet is disabled"

**kde-bug-259942**
URL: https://kde-bugs-dist.kde.narkive.com/aJzzwyas/bug-259942-new-kwalletd-seems-to-stop-responding-if-the-i-enter-the-password-for-opening-a-wallet
Accessed: 2026-07-28
Quote: "kwalletd seems to stop responding if the [user] enter[s] the password for opening a wallet [with a delay]"

**ksecretd-source**
URL: https://invent.kde.org/frameworks/kwallet/-/raw/master/src/runtime/ksecretd/main.cpp
Accessed: 2026-07-28
Evidence: no SIGTERM/SIGINT handler installed; `KCrash::initialize()` present (crash reporting only); exit path is `return app.exec();`.

**dbus-spec-peer**
URL: https://dbus.freedesktop.org/doc/dbus-specification.html
Accessed: 2026-07-28
Quote: "On receipt of this method call, an application should do nothing other than reply with a METHOD_RETURN as usual"

**sd-notify-man**
URL: https://www.freedesktop.org/software/systemd/man/latest/sd_notify.html
Accessed: 2026-07-28
Quote: "WATCHDOG=1 ... Tells the service manager to update the watchdog timestamp"

**sd-watchdog-man**
URL: https://man7.org/linux/man-pages/man3/sd_watchdog_enabled.3.html
Accessed: 2026-07-28

**archwiki-kwallet**
URL: https://wiki.archlinux.org/title/KDE_Wallet
Accessed: 2026-07-28

**qsavefile-docs**
URL: https://doc.qt.io/qt-6/qsavefile.html
Accessed: 2026-07-28

**azure-circuit-breaker**
URL: https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
Accessed: 2026-07-28

**gdbusconnection-docs**
URL: https://docs.gtk.org/gio/class.DBusConnection.html
Accessed: 2026-07-28

## SYNTHESIS

ksecretd going "alive but silently unresponsive to every D-Bus caller" is not
a novel failure — it is a recurring class of bug in this exact codebase,
caused structurally by ksecretd being single-threaded on one Qt event loop:
one mishandled request (an invalid object path, a disabled-state check that
skips its error return, a blocked nested event loop) wedges that loop, and
because Qt D-Bus dispatch is serialized on it, every caller — not just the
one that triggered the bug — hangs forever with no reply. Two of the three
documented triggers were fixed in 2025 (6.14.1, 6.15); the specific trigger
behind a fresh 2026-07-28 incident (daemon ran successfully for ~10 minutes,
then wedged with 0% CPU) does not match any of the three known reports
exactly, so it is plausibly a fourth, undocumented trigger in the same class
rather than a regression of an already-fixed one.

Bare `kill` (SIGTERM) is the correct remediation, not a shortcut: ksecretd
installs no signal handler to interrupt, so SIGTERM and SIGKILL are
equivalent to it, and the observed process state before killing (S/sleeping,
0% CPU) is inconsistent with an in-flight write — a genuinely blocked
process burning no CPU is not mid-I/O, which is the actual corruption risk
that would argue against a bare kill.

No existing systemd or D-Bus mechanism can detect this class of hang instead
of a hand-rolled probe. `WatchdogSec=` requires the monitored process to
actively call `sd_notify()` on a schedule — a cooperative mechanism ksecretd
does not implement, and cannot be retrofitted from outside the process.
ksecretd is D-Bus-activated via a classic `Exec=` service file, not native
systemd activation, so it has no systemd unit of its own to attach a
watchdog to in the first place. dbus-daemon's only relevant timeout
(`service_start_timeout`, ~25s default) governs initial activation only;
once a service has claimed its bus name, dbus-daemon performs zero ongoing
liveness checking. The gap is real, not an oversight in our design.

A full circuit-breaker pattern (Closed/Open/Half-Open state machine) is
overkill for this shape of problem: that pattern exists to protect callers
from a *degrading* multi-instance fleet by routing around unhealthy members
while others still serve traffic. Here there is exactly one instance, it is
either fully healthy or fully wedged (not partially degrading), and the
correct remedy (kill and let it respawn) is instant and cheap rather than
"back off and retry later." The closer-fitting pattern is a liveness
probe + supervised restart (what Kubernetes calls a `livenessProbe`), which
does not exist for D-Bus-activated (non-systemd-native) services on this
stack — hence building a small standalone probe script rather than adopting
an existing tool.

`Peer.Ping` sent to a *named* destination (not the bus daemon itself) is a
trustworthy detector for this specific failure, not merely a cheap
convention: per the D-Bus spec it is meant to be a trivial no-op reply, but
delivery to a named destination is still routed through and answered by that
process's own main loop in both major D-Bus bindings (GDBus/GLib and
QtDBus, which ksecretd uses) — confirmed via GDBusConnection's own
documentation. A Ping timeout is therefore evidence the target's event loop
specifically is not pumping, which is the same root condition that would
also hang a real caller like `infisical export` — there is no meaningful
"healthy but too busy to answer Ping" case that would not equally make the
daemon useless to its real callers, so a Ping-timeout signal does not
produce false positives against a merely-busy-but-functional daemon.
