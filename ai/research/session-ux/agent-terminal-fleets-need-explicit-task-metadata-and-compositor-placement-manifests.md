---
title: "Agent terminal fleets need explicit task metadata and compositor placement manifests, not process-name window lists"
date: 2026-07-06
topic: session-ux
tags: [tmux, kitty, kde-wayland, claude-code, codex-cli, session-restore]
status: draft
sources: [claude-statusline, claude-agent-view, codex-slash, codex-hooks, tmux-manual, tmux-fzf, sessionx, kde-session-restore, kwin-xdg-session-mr, kwin-api, kdotool, kitty-sessions, kitty-ls, quickchat-tmux-summaries, tmux-agent-status]
---

## CLAIMS

- Claude Code status lines are first-party, scriptable, receive JSON session data on stdin, and are explicitly documented as useful for distinguishing multiple sessions. [claude-statusline]
- Claude Code Agent View is first-party research preview in Claude Code v2.1.139+, showing many background sessions from one screen with state such as what is running and what needs input. [claude-agent-view]
- Codex CLI has a first-party `/title` command that configures terminal window/tab title items including project, status, thread, branch, model, and task progress, persisted to `tui.terminal_title`. [codex-slash]
- Codex CLI has first-party `/statusline` support for configuring TUI status-line fields and persisting them in config.toml. [codex-slash]
- Codex lifecycle hooks can be loaded from `~/.codex/hooks.json`, `~/.codex/config.toml`, and trusted project `.codex/` layers; project hooks depend on project trust while user hooks do not. [codex-hooks]
- tmux `automatic-rename` renames windows using `automatic-rename-format`, and tmux disables automatic rename for a window when it is named at creation, renamed later, or renamed by terminal escape sequence. [tmux-manual]
- tmux `display-popup` is a core tmux command for running a command in an overlay popup with configurable width/height/position/title. [tmux-manual]
- `sainnhe/tmux-fzf` supports fzf-powered tmux management, tmux popup mode for tmux >= 3.2, previews, and ordering across session/window/pane/command/keybinding/clipboard/process. [tmux-fzf]
- `omerxx/tmux-sessionx` provides popup fuzzy search over tmux sessions and windows with previews, and can display git branches asynchronously. [sessionx]
- KDE announced that KWin gained initial Wayland session restore protocol support landing in Plasma 6.4, with caveats: it supports sizing/positioning/virtual desktop placement only, does not restore app internal content, and requires toolkit/app opt-in. [kde-session-restore]
- KWin MR !8985 implements the xdg version of the session management protocol and references the freedesktop wayland-protocols MR. [kwin-xdg-session-mr]
- KWin's scripting API exposes workspace windows, desktops, screens, captions, and management functions as of KWin 6.0. [kwin-api]
- `kdotool` uses KWin's scripting API via D-Bus, works with KDE Plasma 6, should work on Wayland and X11, and documents that some xdotool commands are not available or possible through KWin/Wayland. [kdotool]
- kitty session files and `save_as_session` can save open OS windows, tabs, windows, running programs, and working directories into a session file. [kitty-sessions]
- kitty's `kitten @ ls` returns a JSON tree whose top level is OS windows, then tabs, then windows; window entries include title, cwd, PID, command line, and environment. [kitty-ls]
- A 2026 tmux/Claude prior-art pattern uses Claude Code hooks to summarize transcript JSONL into sidecar files and renders the result in tmux status, because many parallel `claude` panes otherwise look identical. [quickchat-tmux-summaries]
- `tmux-agent-status` is a 2026 tmux agent-session tool claiming hook-based Claude Code and Codex tracking, a persistent sidebar, compact status summary, and hierarchical fzf target switching. [tmux-agent-status]

## SOURCES

**claude-statusline**
URL: https://docs.anthropic.com/en/docs/claude-code/statusline
Accessed: 2026-07-06
Quote: "It receives JSON session data on stdin"

**claude-agent-view**
URL: https://code.claude.com/docs/en/agent-view
Accessed: 2026-07-06
Quote: "Agent view shows what every session is doing"

**codex-slash**
URL: https://developers.openai.com/codex/cli/slash-commands
Accessed: 2026-07-06
Quote: "`/title` Configure terminal window or tab title fields interactively."

**codex-hooks**
URL: https://developers.openai.com/codex/config-advanced
Accessed: 2026-07-06
Quote: "Codex can also load lifecycle hooks"

**tmux-manual**
URL: https://man7.org/linux/man-pages/man1/tmux.1.html
Accessed: 2026-07-06
Quote: "Control automatic window renaming."

**tmux-fzf**
URL: https://github.com/sainnhe/tmux-fzf
Accessed: 2026-07-06
Quote: "Use fzf to manage your tmux work environment!"

**sessionx**
URL: https://github.com/omerxx/tmux-sessionx
Accessed: 2026-07-06
Quote: "pops up an fzf-tmux \"popup\""

**kde-session-restore**
URL: https://blogs.kde.org/2025/04/12/this-week-in-plasma-the-beginnings-of-wayland-session-restore/
Accessed: 2026-07-06
Quote: "Toolkits and apps still need to opt in"

**kwin-xdg-session-mr**
URL: https://invent.kde.org/plasma/kwin/-/merge_requests/8985
Accessed: 2026-07-06
Quote: "This implements the xdg- version"

**kwin-api**
URL: https://develop.kde.org/docs/plasma/kwin/api/
Accessed: 2026-07-06
Quote: "This page describes the KWin Scripting API"

**kdotool**
URL: https://github.com/jinliu/kdotool
Accessed: 2026-07-06
Quote: "uses KWin's scripting API"

**kitty-sessions**
URL: https://sw.kovidgoyal.net/kitty/sessions/
Accessed: 2026-07-06
Quote: "save the currently open OS Windows"

**kitty-ls**
URL: https://man.archlinux.org/man/extra/kitty/kitten-%40-ls.1.en
Accessed: 2026-07-06
Quote: "returned as JSON tree"

**quickchat-tmux-summaries**
URL: https://quickchat.ai/post/tmux-session-summaries-for-parallel-ai-agents
Accessed: 2026-07-06
Quote: "every pane looks identical"

**tmux-agent-status**
URL: https://github.com/samleeney/tmux-agent-status
Accessed: 2026-07-06
Quote: "Hook-based Claude Code and Codex tracking"

## SYNTHESIS

The durable pattern is to separate semantic task metadata from terminal/window mechanics. Claude Code and Codex now have first-party metadata surfaces; tmux has strong display and switching mechanics; kitty has internal terminal-layout serialization; KWin owns Wayland placement. A robust terminal-agent fleet should therefore store task labels/state in explicit sidecars keyed by agent/tmux identity, render/search those sidecars from tmux, and restore desktop layout through stable kitty/KWin identities rather than relying on process names like `claude`/`node` or raw Wayland app restore alone.

The nearest prior-art shape is a hook-fed tmux dashboard or fzf popup. Generic tmux auto-renamers and cwd-based names help only at the repo level; they do not track live task intent. For full layout resume, the realistic near-term design is a manifest that combines kitty launch/session structure with KWin compositor placement, optionally adapting geometry to current outputs. Protocol-native Wayland session restore is improving but is not yet a complete answer for a terminal fleet with tmux windows and resumed AI-agent conversations.
