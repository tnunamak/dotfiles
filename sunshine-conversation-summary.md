# Terminal Session Persistence — Conversation Summary

**From conversation:** f7ee6afd-af1b-412d-8865-e4d54658ef3f (~/applications/sunshine)
**Dates:** 2026-03-13 and 2026-03-23

## Context

KDE Plasma desktop crashed (KWin lost DRM master). Kitty terminal died with it — all open terminal sessions lost. Tim was on a TTY and asked about preventing this in the future.

## Tech Considered

| Tool | What it does | Verdict |
|------|-------------|---------|
| **Kitty `startup_session`** | Static session config file — defines a layout to open on launch | No live save/restore. Doesn't survive crashes or reboots. Not useful here. |
| **Zellij** | Modern terminal multiplexer with better defaults, floating panes, built-in session manager, no prefix key | Nice UX but smaller ecosystem than tmux |
| **tmux** | Classic multiplexer. Server process independent of any GUI. Larger ecosystem, more mature, more scriptable/composable | Chosen as the base |
| **tmuxp** | YAML-based tmux session manager — `tmuxp load` recreates predefined layouts (windows, panes, startup commands) | Useful for reproducible project layouts, but does NOT save live sessions |
| **tmux-resurrect** | tmux plugin — auto-saves session state (windows, panes, working directories, running commands) | Survives crashes AND reboots. Auto-save every 15 min. |
| **tmux-continuum** | Companion to resurrect — automates save/restore on tmux start | Paired with resurrect for full resilience |

## Key Findings

- **Kitty has NO automatic session save/restore.** Only `startup_session` which is a static config, not a live snapshot. No survive crash, no survive reboot.
- **tmux-resurrect** is strictly more resilient: auto-save every 15 min, survives desktop crashes, reboots, and works from TTY.
- **tmux runs as a server process** independent of the terminal emulator or GUI — so when KDE/kitty die, tmux sessions survive.

## Remote Access (Termius / SSH)

- tmux works perfectly over SSH — that's its original use case
- `ssh in` -> `tmux attach` picks up right where you left off
- Can detach from desk, attach from phone
- Pane/window switching via prefix key `Ctrl+b`:
  - `c` new window, `n`/`p` next/prev window
  - `%` vertical split, `"` horizontal split
  - Arrow keys to switch panes
- Works in any SSH client including Termius, though touchscreen is clunky

## Decision

**tmux + tmux-resurrect + tmux-continuum** for full terminal session resilience. Covers crashes, reboots, and remote access.

## Status: NOT YET IMPLEMENTED

Setup was about to begin but got interrupted by the reboot and then a long Sunshine debugging session. This is the next thing to set up.
