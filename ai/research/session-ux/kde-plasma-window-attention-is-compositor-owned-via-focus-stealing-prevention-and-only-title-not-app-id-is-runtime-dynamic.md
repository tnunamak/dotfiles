---
title: "KDE Plasma window attention is compositor-owned: a declined xdg-activation request becomes the 'demands attention' taskbar highlight, notify-send urgency=critical is the non-expiring signal, and only window title (not app_id) is runtime-dynamic per kitty window"
date: 2026-07-16
topic: session-ux
tags: [kde-plasma, wayland, xdg-activation, notify-send, urgency, kwin, app-id, taskbar]
status: draft
sources: [notify-send-man, freedesktop-urgency, kwin-focus-steal, kwin-window-rules, xdg-activation, xdg-shell-appid, kitty-invocation, foot-wayland-urgent]
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation/conclusions. Skippable. No citations here.
-->

## CLAIMS

- `notify-send` exposes `-u/--urgency` with three levels (`low`, `normal`, `critical`), plus `-a/--app-name`, `-i/--icon`, `-c/--category`, `-A/--action` (implies `--wait`; action NAME printed to stdout on click), `-h/--hint` (typed extra data), and `-t/--expire-time` (ms). [notify-send-man]
- Plasma ignores the expire-time for `critical`-urgency notifications, i.e. critical notifications do not auto-expire and must be dismissed. [notify-send-man]
- The freedesktop Desktop Notifications Specification defines urgency as an enum: 0 Low, 1 Normal, 2 Critical; and states critical notifications should not automatically expire and should only be closed by user dismissal. [freedesktop-urgency]
- KWin's Focus Stealing Prevention has levels None/Low/Medium/High/Extreme; windows prevented from stealing focus are marked as demanding attention, which by default highlights their taskbar entry. [kwin-focus-steal]
- KWin window rules can force a window's Focus Stealing Prevention attribute (e.g. set to None to pop it to top and give focus, or keep it from focusing so it isn't dismissed); there is no separately-named window rule literally called "urgency"/"demands attention" — the attention state is a consequence of the focus decision. [kwin-window-rules]
- On Wayland an unfocused app cannot focus itself; it requests activation via `xdg_activation_v1`'s `activate` request, and the compositor "might decide not to follow through with the activation if it's considered unwanted" (e.g. for focus-stealing prevention). The protocol XML speaks only of the compositor declining activation; the "demands attention"/"urgent" outcome is compositor (KWin) behavior, NOT protocol text. [xdg-activation]
- X11's ICCCM urgency hint / `_NET_WM_STATE_DEMANDS_ATTENTION` have no direct Wayland equivalent; the Wayland mechanism is xdg-activation. foot's tracker states X11's urgent flag "is a 'hint' X11 programs can set, but there is no corresponding protocol in Wayland" and uses XDG activation instead. [foot-wayland-urgent]
- The Plasma task manager groups/labels windows by app_id (Wayland) / WM_CLASS (X11) plus title. At the PROTOCOL level, xdg-shell's `set_app_id` may be sent after the toplevel is mapped to update the property — app_id is NOT immutable by spec. [xdg-shell-appid]
- kitty sets app_id only at startup via `--class` (aliased `--app-id`, default `kitty`) and exposes no documented runtime app_id-mutation path; only the window title is runtime-dynamic (via OSC title sequences / remote control). [kitty-invocation]
- kitty's `window_alert_on_bell` manifests on Linux as a "taskbar flash"; on Wayland this is carried by the xdg-activation attention path (issue-tracker attested), not the config-doc wording. [foot-wayland-urgent]

## SOURCES

**notify-send-man**
URL: https://man.archlinux.org/man/notify-send.1
Accessed: 2026-07-16
Quote: "-u, --urgency=LEVEL Specifies the urgency level (low, normal, critical)." ; "GNOME Shell and Notify OSD always ignore it, while Plasma ignores it for notifications with the critical urgency level." ; "-A, --action=[NAME=]Text ... Implies --wait to wait for user input."

**freedesktop-urgency**
URL: https://specifications.freedesktop.org/notification-spec/latest/urgency-levels.html
Accessed: 2026-07-16
Quote: "Type: 0 Low, 1 Normal, 2 Critical" ; "Critical notifications should not automatically expire, as they are things that the user will most likely want to know about. They should only be closed when the user dismisses them."

**kwin-focus-steal**
URL: https://docs.kde.org/stable_kf6/en/kwin/kcontrol/windowbehaviour/index.html
Accessed: 2026-07-16
Quote: "Windows that are prevented from stealing focus are marked as demanding attention, which by default means their taskbar entry will be highlighted."

**kwin-window-rules**
URL: https://docs.kde.org/stable_kf6/en/kwin/kcontrol/windowspecific/index.html
Accessed: 2026-07-16
Quote: "To pop an active window to the top, set its Focus stealing prevention attribute to None" ; "Pop the Thunderbird reminder to the top and do not give it focus so it isn't inadvertently dismissed."

**xdg-activation**
URL: https://wayland.app/protocols/xdg-activation-v1
Accessed: 2026-07-16
Quote: "Requests surface activation. It's up to the compositor to display this information as desired ... The compositor may know who requested this by checking the activation token and might decide not to follow through with the activation if it's considered unwanted."

**xdg-shell-appid**
URL: https://wayland.app/protocols/xdg-shell
Accessed: 2026-07-16
Quote: "Like other properties, a set_app_id request can be sent after the xdg_toplevel has been mapped to update the property."

**kitty-invocation**
URL: https://sw.kovidgoyal.net/kitty/invocation/
Accessed: 2026-07-16
Quote: "--class ... On Wayland set the application id. On X11 set the class part of the WM_CLASS window property. Default: kitty"

**foot-wayland-urgent**
URL: https://codeberg.org/dnkl/foot/issues/157 ; https://github.com/kovidgoyal/kitty/issues/3022
Accessed: 2026-07-16
Quote: (foot) "is a 'hint' X11 programs can set, but there is no corresponding protocol in Wayland" — foot uses XDG activation instead.

## SYNTHESIS

For Plasma-side delivery there are two clean levers and one hard constraint.

Lever 1 — `notify-send` is the free, robust cross-desktop notification path with a real urgency ladder. `-u critical` is the semantically-correct signal for "agent is blocked / needs input," because Plasma refuses to auto-expire critical notifications — they persist until dismissed, matching Tim's "event-driven truthful signals" aesthetic (a critical is a claim that persistence is warranted). `-u low`/`normal` fit service-error bursts and command-done. `-A/--action` gives clickable buttons but implies `--wait`, so it blocks — use it only from a backgrounded helper. This is the recommended sink for both the shell/kitty `command` action and the tmux `alert-*` hook path.

Lever 2 — the taskbar "demands attention" highlight is real but you don't set it directly. It is a *consequence* of KWin's Focus Stealing Prevention declining an activation request. On Wayland, a terminal bell (kitty `window_alert_on_bell`) makes an xdg-activation request; KWin declines the focus-steal and highlights the taskbar entry. So the free path to "flash this window in the taskbar" is: make the window bell (or emit a notification), and rely on KWin's default. There is no window rule literally named "urgency" to force it; a KWin window rule can only tune the focus-stealing-prevention level.

The hard constraint kills one tempting design: you CANNOT give each kitty window a distinct taskbar identity via app_id at runtime. Although the xdg-shell spec *permits* re-sending `set_app_id` after mapping, kitty fixes app_id at launch (`--class`, default `kitty`) with no runtime change, so all 18 kitty windows share app_id `kitty` and the task manager groups them together. The ONLY runtime-dynamic per-window identity kitty offers to the taskbar is the TITLE. This is why the tmux `set-titles-string` chain matters: title is the sole carrier that reaches KWin's taskbar/alt-tab per-window. Distinct per-window taskbar *icons* would require launching kitty instances with different `--class` values (startup-time, per OS window) — a heavier but viable option if per-type icon grouping is ever wanted. Net: title = dynamic and per-window; app_id/icon = fixed at launch, not per-window at runtime.
