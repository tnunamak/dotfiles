---
title: "The universal command-done notification pattern gates on terminal focus/visibility via preexec/precmd timing (zsh, bash-preexec) or regex triggers (iTerm2), and iTerm2's 'Alert on next mark' + triggers are the benchmark attention feature set worth porting conceptually"
date: 2026-07-16
topic: session-ux
tags: [zsh, preexec, precmd, iterm2, triggers, marks, badges, notify, focus-gating]
status: draft
sources: [zsh-hooks, bash-preexec, zsh-notify, noti, iterm-triggers, iterm-marks, iterm-badges, iterm-escape]
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation/conclusions. Skippable. No citations here.
-->

## CLAIMS

- zsh's `preexec` runs just after a command is read and about to execute (receiving the typed command line as an argument); `precmd` runs before each prompt. Multiple hooks register via `preexec_functions`/`precmd_functions` arrays. This pair is the standard mechanism for measuring command duration (start timer in preexec, fire in precmd). [zsh-hooks]
- `bash-preexec` (rcaloras/bash-preexec) provides zsh-style `preexec` and `precmd` hooks in bash 3.1+, registered via `preexec_functions`/`precmd_functions`, enabling the same notify-on-completion pattern in bash. [bash-preexec]
- `marzocchi/zsh-notify` posts a desktop notification for long-running (over a configurable `command-complete-timeout`, default 30s) or failed commands; it checks whether the terminal is focused before notifying (`check-focus` on by default, disableable), using `WINDOWID` plus `xdotool`/`wmctrl` to query the active window on Linux. [zsh-notify]
- `noti` (variadico/noti, now on Codeberg) is a command wrapper that fires a desktop notification when a monitored process finishes; invoked as `noti <cmd>` or attached to an existing process by PID via `--pwatch`. [noti]
- iTerm2 triggers are actions fired when terminal output matches a regex; the action list includes Post Notification (Notification Center), Show Alert (modal), Bounce Dock Icon, Ring Bell, Set Mark, Set Named Mark, Set Title, Set User Variable, Send Text, Capture Output, Highlight Line/Text, Run Command, Run (Silent) Coprocess, and Stop Processing Triggers. [iterm-triggers]
- iTerm2's "Alert on next mark" (Edit > Marks and Annotations > Alert on next mark, Cmd-Opt-A) shows a modal alert when the next shell-prompt mark appears — the canonical "tell me when this long command finishes" feature; shell integration auto-adds a mark at each command prompt, navigable with Cmd-Shift-Up/Down. [iterm-marks]
- iTerm2 badges are a large translucent per-session text overlay (top-right) whose value is an interpolated string that can reference iTerm2 variables/user-vars; set via Settings>Profiles>General>Badge or a proprietary escape sequence. [iterm-badges]
- iTerm2 supports proprietary escape codes: `OSC 1337;RequestAttention=[yes|once|no|fireworks] ST` (dock bounce), `OSC 9;message ST` (growl-style notification), `OSC 1337;SetUserVar=name=value ST` (base64 value), and `OSC 1337;SetMark ST`. [iterm-escape]

## SOURCES

**zsh-hooks**
URL: https://zsh.sourceforge.io/Doc/Release/Functions.html
Accessed: 2026-07-16
Quote: "preexec — Executed just after a command has been read and is about to be executed ... the string that the user typed is passed as the first argument ... precmd — Executed before each prompt."

**bash-preexec**
URL: https://github.com/rcaloras/bash-preexec
Accessed: 2026-07-16
Quote: "preexec and precmd hook functions for Bash 3.1+ in the style of Zsh. They aim to emulate the behavior as described for Zsh."

**zsh-notify**
URL: https://github.com/marzocchi/zsh-notify
Accessed: 2026-07-16
Quote: "Desktop notifications for long-running commands in ZSH." ; "Ignore checking if the terminal is focused at all: zstyle ':notify:*' check-focus no" ; "Force checking of the WINDOWID variable on every command: zstyle ':notify:*' always-check-active-window yes"

**noti**
URL: https://codeberg.org/roble/noti (archived origin: https://github.com/variadico/noti)
Accessed: 2026-07-16
Quote: "Monitor a process and trigger a notification. Never sit and wait for some long-running process to finish."

**iterm-triggers**
URL: https://iterm2.com/documentation-triggers.html
Accessed: 2026-07-16
Quote: "A trigger is an action that is performed when text matching some regular expression is received in a terminal session." ; "Post Notification: Posts a notification with Notification Center." ; "Show Alert: Shows an alert box with user-defined text." ; "Set User Variable: Assigns a value to a user-defined variable."

**iterm-marks**
URL: https://iterm2.com/documentation-shell-integration.html
Accessed: 2026-07-16
Quote: "iTerm2 can show an alert box when a mark appears. This is useful when you start a long-running command. Select Edit>Marks and Annotations>Alert on next mark (Cmd-Opt-A) after starting a command ... When the command prompt returns, a modal alert will appear, calling attention to the finished job."

**iterm-badges**
URL: https://iterm2.com/documentation-badges.html
Accessed: 2026-07-16
Quote: "A badge is a large text label that appears in the top right of a terminal session to provide dynamic status, such as the current host name or git branch ... This value is an interpolated string, which means the badge can display the value of variables."

**iterm-escape**
URL: https://iterm2.com/documentation-escape-codes.html
Accessed: 2026-07-16
Quote: "OSC 1337 ; RequestAttention=[value] ST ... yes to request attention by bouncing the dock icon indefinitely, once to bounce it a single time, or no to cancel ... If it is fireworks then fireworks explode at the cursor's location." ; "OSC 1337 ; SetUserVar=[Ps1]=[Ps2] ST"

## SYNTHESIS

The entire industry converges on one pattern for "command done": measure command duration in a shell preexec/precmd pair, then fire a notification only if the command ran longer than a threshold AND the terminal is not focused/visible. zsh has preexec/precmd natively; bash-preexec ports it. zsh-notify is the drop-in that adds the two policy gates Tim's aesthetic demands: a duration threshold and a focus check (so you're only pinged when not looking). The focus check is the interesting part — zsh-notify does it with `WINDOWID` + xdotool/wmctrl (X11-era tooling). On Tim's Wayland/Plasma box that path is unreliable, which is exactly why kitty's `notify_on_cmd_finish invisible` (see the kitty entry) is superior for bare-kitty panes: kitty knows its own OS-window visibility natively and needs no window-query tooling. For tmux panes, the shell hook still works but the "am I focused" question must be answered against tmux+kitty state, not a Wayland window query — practically, delegate the visibility judgment to kitty (`kitten @ ls` `is_focused`/`is_active`) rather than xdotool.

iTerm2 is the benchmark, and the concepts worth porting are three: (1) **Triggers** — regex-on-output → action. This is the ONE thing missing everywhere else that Tim explicitly wants: a dev server's error burst (regex like `ERROR|panic|Traceback`) firing a notification. kitty/tmux have no native trigger engine; the port is a pane-content watcher (tail the pane or a log) that matches a regex and calls `notify-send`. This is a small script, not a config flip, and it's the highest-value build. (2) **Alert on next mark** — already natively covered by kitty `notify_on_cmd_finish`, so nothing to build there. (3) **Badges + SetUserVar** — the per-session overlay driven by a user variable maps onto kitty user vars + the `{custom}` tab_bar.py hook (see kitty entry); iTerm2's `RequestAttention` maps onto kitty `window_alert_on_bell` → KWin taskbar highlight (see KDE entry). 

Design takeaway for the three window-type signals Tim named: command-done rides `notify_on_cmd_finish`/zsh-notify (free/cheap); service-error-regex rides an iTerm2-Triggers-style pane watcher → notify-send (must-build, small); agent-blocked rides an explicit signal the agent emits (a hook writing a user var + notify-send `-u critical`), NOT output-regex, because "blocked" is a state the agent knows and should assert rather than have inferred from scrollback.
