---
title: "tmux routes alerts via per-window monitor flags + session-scoped bell/activity/silence actions (not to a specific client), and swallows OSC notifications unless DCS-wrapped through allow-passthrough, so grouped-session attention must be composed from these primitives"
date: 2026-07-16
topic: session-ux
tags: [tmux, monitor-activity, bell-action, allow-passthrough, osc, grouped-sessions, set-titles, alert-hooks]
status: draft
sources: [tmux-monitor, tmux-actions, tmux-visual, tmux-flags, tmux-hooks, tmux-titles, tmux-passthrough, tmux-clipboard, tmux-groups, tmux-osc-issue]
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation/conclusions. Skippable. No citations here.
-->

## CLAIMS

- tmux `monitor-activity [on|off]`, `monitor-bell [on|off]`, and `monitor-silence [interval]` are per-WINDOW options; monitored windows are highlighted in the status line; `monitor-silence` takes an interval in seconds (0 disables). [tmux-monitor]
- `activity-action`, `bell-action`, and `silence-action` are per-SESSION options with values `any|none|current|other`: `any` = an event in any window of the session causes a bell/message in the current window; `none` = ignore all; `current` = ignore events in windows other than the current; `other` = ignore events in the current window but not others. [tmux-actions]
- The tmux manual does NOT state that `bell-action` routes a bell to a specific viewing client; it filters per `any|none|current|other` and produces "a bell or message ... in the current window of that session". Whether a bell reaches the outer terminal (audible) vs a status message is governed by `visual-bell`, not `bell-action`. [tmux-actions]
- `visual-bell [on|off|both]` when `on` shows a status message instead of passing the bell through to the terminal; `off` (default) lets the bell reach the outer terminal; `both` does both. `visual-activity` and `visual-silence` behave analogously. [tmux-visual]
- The window flag characters in the status line are `#` (activity detected), `!` (bell occurred), `~` (silent for the monitor-silence interval); format variables `window_activity_flag`, `window_bell_flag`, `window_silence_flag` expand to 0/1. [tmux-flags]
- tmux has `alert-activity`, `alert-bell`, and `alert-silence` hooks that run on the same conditions that raise the corresponding window alert. [tmux-hooks]
- `set-titles [on|off]` (off by default) sets the CLIENT terminal title via terminfo `tsl`/`fsl` (for xterm-like terminals, the `\e]0;...\007` / OSC 0 sequence); `set-titles-string` is format-expanded. Because the title is set on each attached client's own terminal, each attached client of a grouped session gets its own title. [tmux-titles]
- `allow-passthrough [on|off|all]` lets programs bypass tmux via the DCS wrapper `\ePtmux;...\e\\`; `on` forwards only when the pane is visible, `all` forwards even when invisible. Upstream default is `off` (since 3.3a). [tmux-passthrough]
- tmux special-cases only a fixed set of OSC sequences natively (OSC 52 clipboard via `set-clipboard`, OSC 4/10/11 colors, OSC 7/8); OSC 9, OSC 99, and OSC 777 desktop notifications are NOT in that set and are swallowed unless DCS-wrapped with `allow-passthrough` enabled. There is no tmux option that forwards notification OSC sequences today (a `forward-osc`-style option is only a proposal). [tmux-osc-issue]
- `set-clipboard [on|external|off]` is tmux's OSC 52 forwarding knob (clipboard, not notifications). [tmux-clipboard]
- Grouped sessions created with `new-session -t` share the same windows; each new window is linked to all sessions in the group, but the current/previous window and all SESSION OPTIONS remain independent per session. [tmux-groups]

## SOURCES

**tmux-monitor**
URL: https://man.openbsd.org/tmux (OPTIONS → window options; tmux 3.6)
Accessed: 2026-07-16
Quote: "monitor-silence [interval] Monitor for silence (no activity) in the window within interval seconds ... An interval of zero disables the monitoring."

**tmux-actions**
URL: https://man.openbsd.org/tmux (OPTIONS → session options; tmux 3.6)
Accessed: 2026-07-16
Quote: "activity-action [any | none | current | other] ... any means activity in any window linked to a session causes a bell or message (depending on visual-activity) in the current window of that session, none means all activity is ignored ... current means only activity in windows other than the current window are ignored and other means activity in the current window is ignored but not those in other windows." ; "bell-action [any | none | current | other] ... The values are the same as those for activity-action."

**tmux-visual**
URL: https://man.openbsd.org/tmux (OPTIONS → session options; tmux 3.6)
Accessed: 2026-07-16
Quote: "visual-bell [on | off | both] If on, a message is shown on a bell in a window for which the monitor-bell window option is enabled instead of it being passed through to the terminal (which normally makes a sound). If set to both, a bell and a message are produced. Also see the bell-action option."

**tmux-flags**
URL: https://man.openbsd.org/tmux (STATUS LINE, FORMATS; tmux 3.6)
Accessed: 2026-07-16
Quote: "# Window activity is monitored and activity has been detected. ! Window bells are monitored and a bell has occurred in the window. ~ The window has been silent for the monitor-silence interval."

**tmux-hooks**
URL: https://man.openbsd.org/tmux (HOOKS; tmux 3.6)
Accessed: 2026-07-16
Quote: "alert-activity Run when a window has activity. See monitor-activity. alert-bell Run when a window has received a bell. See monitor-bell. alert-silence Run when a window has been silent. See monitor-silence."

**tmux-titles**
URL: https://man.openbsd.org/tmux (OPTIONS → session options, NAMES AND TITLES; tmux 3.6)
Accessed: 2026-07-16
Quote: "set-titles [on | off] Attempt to set the client terminal title using the tsl and fsl terminfo(5) entries if they exist. tmux automatically sets these to the \\e]0;...\\007 sequence if the terminal appears to be xterm(1). This option is off by default. set-titles-string string String used to set the client terminal title if set-titles is on. Formats are expanded."

**tmux-passthrough**
URL: https://man.openbsd.org/tmux (OPTIONS → window options; tmux 3.6)
Accessed: 2026-07-16
Quote: "allow-passthrough [on | off | all] Allow programs in the pane to bypass tmux using a terminal escape sequence (\\ePtmux;...\\e\\\\). If set to on, passthrough sequences will be allowed only if the pane is visible. If set to all, they will be allowed even if the pane is invisible."

**tmux-clipboard**
URL: https://man.openbsd.org/tmux (OPTIONS → server/session options; tmux 3.6)
Accessed: 2026-07-16
Quote: "set-clipboard ... If set to on, tmux will both accept the escape sequence to create a buffer and attempt to set the terminal clipboard ... If set to external, tmux will attempt to set the terminal clipboard but ignore attempts by applications to set tmux buffers."

**tmux-groups**
URL: https://man.openbsd.org/tmux (COMMANDS → new-session; tmux 3.6)
Accessed: 2026-07-16
Quote: "Sessions in the same group share the same set of windows - new windows are linked to all sessions in the group and any windows closed removed from all sessions. The current and previous window and any session options remain independent and any session in a group may be killed without affecting the others."

**tmux-osc-issue**
URL: https://github.com/tmux/tmux/issues/5237
Accessed: 2026-07-16
Quote: "tmux already special-cases a number of OSC sequences (e.g. OSC 52 clipboard via set-clipboard, OSC 4/10/11 colors, OSC 7/8) ... OSC 133 is not forwarded, and allow-passthrough defaults to off."

## SYNTHESIS

tmux's alert model is two-layered and deliberately coarse: per-WINDOW `monitor-*` flags decide *whether* an event is noticed (and paint the status flag `#`/`!`/`~`), while per-SESSION `*-action` options decide *whether it surfaces* using the `any|none|current|other` filter, and `visual-*` decides *how* (status message vs. real bell to the outer terminal). Nothing here routes to "the client I'm looking at" — the manual's routing target is "the current window of that session," and audible-bell-to-outer-terminal is an all-or-nothing `visual-bell off`. So per-window-type semantic signals (service-error, agent-blocked) cannot be expressed in tmux's native alert vocabulary; they must ride `alert-*` hooks (which fire a shell command you write) or be detected out-of-band.

The grouped-session facts are the load-bearing gotcha for Tim's setup. Windows are shared across the group, so `monitor-activity`/`monitor-bell`/`monitor-silence` (WINDOW options) are shared — every kitty clone monitors the same windows. But `bell-action`, `visual-bell`, `set-titles`, and `set-titles-string` are SESSION options and stay independent per clone. That means: (a) `set-titles` can be turned on per-clone and each kitty gets its own title expanded in its own client context — this is how you'd give alt-tab/taskbar distinct titles per kitty (today all read "zsh" because `set-titles off`); (b) a bell in a shared window is filtered/rendered per each clone's own `bell-action`/`visual-bell`, so the just-fixed `bell-action current` behavior is per-session, consistent with routing to the viewing client only in practice even though the manual frames it as "current window of that session."

The decisive negative finding: OSC 9/99/777 notifications do NOT cross tmux by default and lose pane identity when force-passed via the DCS envelope (which is off by default and forwards verbatim). tmux natively forwards only clipboard/color/cwd OSCs, not notifications, and no `forward-osc` option ships. Therefore an in-tmux program printing OSC 99 to reach Plasma is a dead end without config and even then is pane-blind. The robust attention path for tmux panes is: program → tmux `alert-*` hook or a pane-content watcher → a script that calls `notify-send` (Plasma) and/or `kitten @ set-user-vars`/`set-window-title` from OUTSIDE tmux, using tmux's own pane metadata for attribution. `set-titles-string` is the free win for making the taskbar/alt-tab title carry per-clone window identity.
