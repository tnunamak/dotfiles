---
title: "Persistent= only affects OnCalendar= timers, not monotonic timers like OnStartupSec= or OnBootSec="
date: 2026-08-04
topic: systemd
tags: [systemd.timer, persistent, monotonic, oncalendar]
status: settled
sources: [man-systemd-timer-5-freedesktop, man-systemd-timer-5-man7]
source_session: 438b152f-8273-4d0b-ac80-0a55cb7f37f1
---

## CLAIMS
- `Persistent=` in systemd.timer takes a boolean; when true, the service unit is triggered immediately on timer activation if it would have been triggered at least once during downtime. **This setting only has an effect on timers configured with `OnCalendar=`.** [man-systemd-timer-5-freedesktop]
- A timer configured with `OnBootSec=` or `OnStartupSec=` that is already in the past when the timer unit is activated will immediately elapse once, then has no further trigger from that directive. This is not the case for timers defined in the other directives (e.g., `OnUnitInactiveSec=` is explicitly excluded and recurs). [man-systemd-timer-5-freedesktop]
- `OnStartupSec=` is relative to when the service manager was first started and is "primarily useful in the per-user service manager"; its anchor moves on a per-user `--user` manager restart, unlike `OnBootSec=` which is anchored to system boot. [man-systemd-timer-5-freedesktop]

## SOURCES
**man-systemd-timer-5-freedesktop**
URL: https://www.freedesktop.org/software/systemd/man/latest/systemd.timer.html
Accessed: 2026-08-04
Quote: "**Persistent=** Takes a boolean argument. If true, the time when the service unit was last triggered is stored on disk. When the timer is activated, the service unit is triggered immediately if it would have been triggered at least once during the time when the timer was inactive. This is useful to catch up on missed runs of the timer when the machine was powered off. Note that this setting only has an effect on timers configured with `OnCalendar=`."

**man-systemd-timer-5-man7**
URL: https://man7.org/linux/man-pages/man5/systemd.timer.5.html
Accessed: 2026-08-04
Quote (OnBootSec/OnStartupSec past behavior): "If a timer configured with `OnBootSec=` or `OnStartupSec=` is already in the past when the timer unit is activated, it will immediately elapse."
Quote (OnStartupSec per-user note): "This is relative to when the service manager was first started. In contrast to `OnBootSec=`, this is relative to the activation of the specific service manager instance, not the system boot. Primarily useful in the per-user service manager."

## SYNTHESIS

A common mistake when designing monotonic-timer recovery patterns is to assume `Persistent=true` provides catch-up-on-restart behavior for timers using `OnBootSec=` or `OnStartupSec=`. The systemd.timer(5) spec clearly contradicts this: Persistent has **no effect** on monotonic timers.

The actual catch-up mechanism for monotonic timers is the "already in the past → fire immediately once" rule for `OnBootSec=` and `OnStartupSec=`. For `OnStartupSec=` specifically, the anchor (service manager start time) moves on each per-user manager restart, so the timer reschedules relative to the new start time, enabling restart-time recovery without Persistent.

The key distinction: `Persistent=` is for **calendar-based** timers (e.g., "run daily at 9 AM") to catch up on missed runs during downtime. Monotonic timers (startup-relative, uptime-relative) don't need it; they recover automatically via the fire-immediately-if-in-past rule. Mixing these two mechanisms or attributing Persistent behavior to monotonic timers leads to documentation errors and false-positive test assertions.

