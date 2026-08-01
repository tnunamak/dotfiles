---
title: "kitty provides native command-done and desktop-notification primitives (notify_on_cmd_finish, OSC 99) plus a machine-readable focus/attention oracle via remote control, so most attention signaling is a config flip, not a build"
date: 2026-07-16
topic: session-ux
tags: [kitty, notifications, osc99, remote-control, notify_on_cmd_finish, shell-integration, tab-title]
status: draft
sources: [kitty-conf-bell, kitty-notify-cmd-finish, kitty-desktop-notif, kitty-multiplexer, kitty-rc, kitty-ls, kitty-tab-title, kitty-conf-alert]
source_session: f7ee6afd-af1b-412d-8865-e4d54658ef3f
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation/conclusions. Skippable. No citations here.
-->

## CLAIMS

- kitty's `notify_on_cmd_finish` fires a desktop notification when a shell command finishes; the four modes are `never`, `unfocused` (window not focused), `invisible` (window not focused AND not visible, e.g. inactive tab or inactive OS window), and `always`. It requires kitty shell integration. [kitty-notify-cmd-finish]
- `notify_on_cmd_finish` takes an optional minimum-duration threshold in seconds (default 5) as a second argument, and an optional action after that: `notify` (default), `bell`, or `command <cmdline>` — where in a custom command `%c` is replaced by the command line and `%s` by status info. Example: `notify_on_cmd_finish invisible 10.0 command notify-send job finished`. [kitty-notify-cmd-finish]
- `notify_on_cmd_finish` has a clear policy (`focus next` default): `focus` auto-clears the notification when the window regains focus (for `unfocused`/`invisible` modes); `next` clears the previous notification when the next one shows. [kitty-notify-cmd-finish]
- kitty implements OSC 99, an extensible desktop-notification escape code supporting title+body, three urgency levels via `u` (0 low, 1 normal, 2 critical), click actions via `a` (`focus` default, `report`), app-name/type filtering (`f`/`t`), icons, buttons (U+2028-separated), sound (`s`), auto-expiry (`w`), and close-reporting (`c=1`). [kitty-desktop-notif]
- kitty also supports the legacy OSC 9 notification protocol developed by iTerm2. [kitty-desktop-notif]
- kitty's OSC 99 carries an identifier field so terminal multiplexers know which window to route the query response to; multiplexers must cache icon data themselves and refresh it on detach/re-attach. An app detects support by sending an OSC 99 query then primary device attributes: getting the DA answer without a query answer means no support. [kitty-multiplexer]
- `window_alert_on_bell` (default `yes`) requests window attention on bell, making the dock icon bounce on macOS or the taskbar flash on Linux; `bell_on_tab` (default `"🔔 "`) shows text/symbol on a tab when a non-focused window in it bells; `enable_audio_bell` (default `yes`) controls the audible bell. [kitty-conf-alert]
- `allow_remote_control` (default `no`) gates kitty remote control with values `password`, `socket-only`, `socket` (socket unconditional, TTY by password), `no`, and `yes`. [kitty-rc]
- kitty remote control can set titles and per-window user variables from a script: `kitten @ set-window-title`, `kitten @ set-tab-title`, and `kitten @ set-user-vars` (all support `--match` to target windows other than the current one). [kitty-rc]
- `kitten @ ls` returns a JSON tree of OS windows → tabs → windows; each window entry includes `title`, `is_focused` (active AND in the focused OS window), `is_active` (active within its tab), `needs_attention`, `has_activity_since_last_focus`, and `user_vars`. [kitty-ls]
- kitty's `tab_title_template` supports placeholders including `{bell_symbol}` (shown when `tab.needs_attention`), `{activity_symbol}` (shown when `tab.has_activity_since_last_focus`), `{title}`, `{index}`, and `{tab.last_focused_progress_percent}`; if `{bell_symbol}`/`{activity_symbol}` are absent they are auto-prepended. [kitty-tab-title]
- The `tab_title_template` eval namespace does NOT include per-window `user_vars`; surfacing a user variable in the tab title requires the `{custom}` escape hatch calling `draw_title(data)` in a `tab_bar.py` in the kitty config dir. [kitty-tab-title]

## SOURCES

**kitty-conf-bell**
URL: https://sw.kovidgoyal.net/kitty/conf/#terminal-bell
Accessed: 2026-07-16

**kitty-notify-cmd-finish**
URL: https://sw.kovidgoyal.net/kitty/conf/#opt-kitty.notify_on_cmd_finish (mirror: https://manpages.ubuntu.com/manpages/noble/man5/kitty.conf.5.html)
Accessed: 2026-07-16
Quote: "unfocused means only notify if the window is not focused, invisible means only notify if the window is not visible ... The second argument is the minimum duration ... The default is 5 seconds ... For example: `notify_on_cmd_finish invisible 10.0 command notify-send job finished` ... `%c` is replaced by the current command line and `%s` by additional status information ... It requires shell_integration to work ... The default when no arguments are specified is: focus next."

**kitty-desktop-notif**
URL: https://sw.kovidgoyal.net/kitty/desktop-notifications/
Accessed: 2026-07-16
Quote: "kitty implements an extensible escape code (OSC 99) to show desktop notifications ... urgency levels via the `u` key—`0` (low), `1` (normal), and `2` (critical) ... kitty also supports the legacy OSC 9 protocol developed by iTerm2."

**kitty-multiplexer**
URL: https://sw.kovidgoyal.net/kitty/desktop-notifications/#querying-for-support-and-support-in-multiplexers
Accessed: 2026-07-16
Quote: "The identifier is present to support terminal multiplexers, so that they know which window to redirect the query response too ... Terminal multiplexers must cache icon data themselves and refresh it in the underlying terminal implementation when detaching and then re-attaching."

**kitty-rc**
URL: https://sw.kovidgoyal.net/kitty/remote-control/ ; https://github.com/kovidgoyal/kitty/blob/master/kitty/options/definition.py
Accessed: 2026-07-16
Quote: "The default setting of `no` prevents any form of remote control ... `socket-only` — Remote control requests received over a socket are accepted unconditionally. Requests received over the TTY are denied." ; set-user-vars: "Set user variables for the specified windows ... By default, only the window in which the command is run is affected."

**kitty-ls**
URL: https://github.com/kovidgoyal/kitty/blob/master/kitty/window.py (WindowDict) ; https://github.com/kovidgoyal/kitty/blob/master/kitty/tabs.py
Accessed: 2026-07-16
Quote: "is_focused=w.os_window_id == current_focused_os_window_id() and w is active_window" ; WindowDict fields include "is_focused: bool", "is_active: bool", "needs_attention: bool", "has_activity_since_last_focus: bool", "user_vars: dict[str, str]".

**kitty-tab-title**
URL: https://github.com/kovidgoyal/kitty/blob/master/kitty/tab_bar.py ; https://sw.kovidgoyal.net/kitty/conf/#opt-kitty.tab_title_template
Accessed: 2026-07-16
Quote: "'bell_symbol': draw_data.bell_on_tab if tab.needs_attention else ''," ; "'activity_symbol': draw_data.tab_activity_symbol if tab.has_activity_since_last_focus else ''," ; "if `{bell_symbol}` or `{activity_symbol}` are not present in the template, they are prepended to it."

**kitty-conf-alert**
URL: https://sw.kovidgoyal.net/kitty/conf/ (mirror: https://manpages.debian.org/unstable/kitty/kitty.conf.5.en.html)
Accessed: 2026-07-16
Quote: "window_alert_on_bell ... Request window attention on bell. Makes the dock icon bounce on macOS or the taskbar flash on Linux." ; "bell_on_tab ... Some text or a Unicode symbol to show on the tab if a window in the tab that does not have focus has a bell."

## SYNTHESIS

The single biggest FREE win in Tim's stack is `notify_on_cmd_finish invisible <ttl>` — it is exactly the iTerm2 "alert on next mark" feature (see the shell/iTerm2 entry) built natively into kitty, gated on kitty shell integration and, crucially, on window visibility (not just focus). For long shell commands (make/build) whose completion matters, this is a one-line config flip with a per-command duration threshold and no scripting. Its `command` action (`command notify-send ...`, with `%c`/`%s` interpolation) is the hook for anything richer — e.g. routing to ntfy or setting urgency.

The catch is the multiplexer boundary: `notify_on_cmd_finish` is driven by kitty shell integration marks, which do not survive tmux cleanly (the shell inside a tmux pane talks to tmux, not kitty). So the command-done signal is reliable for bare-kitty panes but needs the shell-hook or tmux-hook path (see the shell/iTerm2 and tmux entries) for panes inside tmux. OSC 99 is kitty's rich protocol but it is precisely what tmux swallows by default (see tmux entry) — so inside tmux the durable path is not OSC-through-tmux.

The strongest under-used primitive is kitty remote control as an attention oracle. `kitten @ ls` exposes per-window `is_focused` vs `is_active` (distinct — `is_active` is the active window in its tab even if that OS window isn't front) plus `needs_attention` and `user_vars` as machine-readable JSON. A watcher outside tmux can read this to decide "which window does Tim actually have in front of him" and drive notifications accordingly — this sidesteps the tmux OSC wall entirely. For per-window-type badges in the tab bar, `{bell_symbol}`/`{activity_symbol}` are free but tied to kitty's own bell/activity detection; anything semantic (service-error, agent-blocked) must ride the `{custom}` `tab_bar.py` hook reading a user var set via `@ set-user-vars`, because the built-in template namespace deliberately excludes `user_vars`.
