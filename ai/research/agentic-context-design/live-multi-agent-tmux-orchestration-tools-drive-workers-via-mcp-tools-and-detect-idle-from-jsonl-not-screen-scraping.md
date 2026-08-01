---
title: "Production live multi-agent CLI orchestrators run each worker in its own interactive tmux window + git worktree, expose spawn/message/wait-idle primitives (often over MCP), and detect worker idle from JSONL session files rather than screen-scraping the prompt"
date: 2026-06-15
topic: agentic-context-design
tags: [agent-orchestration, tmux, multi-agent, mcp, claude-code, codex, prior-art]
status: draft
sources: [maniple, aws-cao, groundcrew, boris-loops, ultracode-shim, claude-cli-ref]
source_session: 6591a019-4e8b-445c-bde7-b8a31c8851a1
---

## CLAIMS

- Maniple (Martian-Engineering/maniple) is a Python MCP server the manager agent loads; the manager calls MCP tools (`spawn_workers`, `message_workers`, `wait_idle_workers`, `examine_worker`) and Maniple performs the tmux work: `tmux new-window`/new-session per worker running an interactive `claude` or `codex`; multi-line messages via `tmux load-buffer` + `paste-buffer`; `examine_worker` via `tmux capture-pane -p -S -<N>`. It detects idle by reading Claude Code / Codex JSONL session files (`~/.claude/projects/<hash>/`) for stop-hook markers rather than screen-scraping; supports `wait_mode: any|all` with timeout; recovers orphaned tmux windows on restart by re-indexing the JSONL; and is cross-provider (worker config pins `provider: claude|codex`). [maniple]
- AWS cli-agent-orchestrator runs every agent in its own tmux session (documenting `tmux attach` as the human HITL intervention path) and exposes three MCP primitives: `handoff` (sync — spawn, wait, tear down after saving scrollback to `~/.cao/logs/terminal/`), `assign` (async — spawn and return, worker calls back), and `send_message` (inbox delivery between running agents, no teardown); it is cross-provider (supervisor on one CLI, workers on another). [aws-cao]
- Groundcrew (ClipboardHealth/groundcrew) is a task-backlog dispatcher: one git worktree per task, one interactive Claude Code session per worktree in a dedicated tmux window, dispatched from a task queue. [groundcrew]
- Reliable worker-idle detection uses the JSONL stop marker (Claude Code writes a stop event such as `{"type":"assistant","stop_reason":"end_turn",...}` as the last event when a turn ends) rather than matching the `❯` prompt character in `capture-pane` output, which changes across CLI versions; process liveness can be confirmed with `kill -0 <pid>` since an interactive worker's pane exits only if the CLI crashes. [maniple]
- Claude Code supports session resume for interactive tmux control: `claude -r "<session-name-or-id>" "..."` resumes by name/ID, `claude -c` continues the most recent conversation in the current directory, and `--session-name <name>` assigns a human-readable, resumable name; `claude --print` (`-p`) plus `--no-session-persistence` produce a one-shot subprocess that is neither watchable-live-interactive nor resumable (no session file written). Codex `exec` is the non-interactive analog and has no equally-mature documented `-r` resume; its practical resume path is JSONL read + message re-injection. [claude-cli-ref] [maniple]
- "Ultracode" is an effort/API configuration, not a separate model or tool: at the API level it is `effort=xhigh` + adaptive thinking + large `max_tokens` + a system-reminder injection, as reverse-engineered by the UltraCode-Shim project; in Claude Code, `/effort` sets per-session effort (`xhigh` on Opus 4.x, `max` on any supported model for the session only) and cannot be hardcoded in agent frontmatter (a runtime session command, not a static field). [ultracode-shim] [claude-cli-ref]
- Anthropic's Boris Cherny (Claude Code creator) framed a shift from prompting to "building loops": "100% of our pull requests at Anthropic are run by Claude Code. 80–90% of code review too... I'm not prompting Claude anymore — I'm building loops." [boris-loops]

## SOURCES

**maniple**
URL: https://github.com/Martian-Engineering/maniple
Accessed: 2026-06-15

**aws-cao**
URL: https://github.com/awslabs/cli-agent-orchestrator
Accessed: 2026-06-15

**groundcrew**
URL: https://github.com/ClipboardHealth/groundcrew
Accessed: 2026-06-15

**boris-loops**
URL: https://x.com/0xMovez/status/2066225922928181644 ; https://x.com/0xCodez/status/2064374643729773029
Accessed: 2026-06-15

**ultracode-shim**
URL: https://github.com/OnlyTerp/UltraCode-Shim
Accessed: 2026-06-15

**claude-cli-ref**
URL: https://docs.anthropic.com/en/docs/claude-code/cli-reference ; https://docs.anthropic.com/en/docs/claude-code/sub-agents
Accessed: 2026-06-15

## SYNTHESIS

**2026-07-30 scope update:** For current, provenance-qualified async delivery, idle-turn control, and recovery facts, use [Eight coding-agent products have different documented async-delivery boundaries](../agent-harnesses/official-async-completion-contracts-for-seven-coding-harnesses.md). In particular, Codex App Server now provides documented thread resume and explicit `turn/start`; do not treat this older tmux-oriented observation as a claim that Codex has no programmatic resume path.

The production pattern for live, human-steerable multi-agent CLI orchestration is consistent across Maniple, AWS cli-agent-orchestrator, and Groundcrew: run each worker as an *interactive* CLI process (not one-shot `--print`) in its own tmux window/session and its own git worktree (worktree isolation is what prevents two workers racing on the same files), and expose a small set of orchestration primitives — spawn, message/send, wait-idle, examine — to a manager agent, ideally as MCP tool calls so the manager issues tool calls rather than raw tmux commands. Two mechanics are load-bearing: (1) multi-line messages are injected via `tmux load-buffer` + `paste-buffer` (not `send-keys` of raw text), and a message sent while the worker is mid-tool-call queues in the input buffer and submits on the next turn — so the sender must confirm receipt via `capture-pane`, not assume it; (2) worker-idle/completion is detected reliably from the CLI's JSONL session file (stop markers) rather than from screen-scraping the prompt character, which is fragile across CLI versions. Interactive resumption requires *not* using one-shot flags: a persisted, human-named session (`--session-name` + `claude -r`) survives worker-pane exit and manager restart, whereas `--print` + `--no-session-persistence` forecloses live watching, mid-run revision, and resume. Cross-provider parity is uneven: Claude Code has mature named-session resume; Codex has a documented App Server thread-resume and explicit-turn-start path, but an ordinary TUI is not a general external-control target; use the newer corpus entry for ordering and recovery qualifications. Other CLIs may lack any reliable idle signal and are safer used fire-and-forget. This is orchestration/tooling prior art; it is independent of any particular project the workers happen to be operating on.
