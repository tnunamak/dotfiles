---
title: "All 3 agents (Claude/Gemini/Codex) now have hooks incl. pre-compaction, but no portable format or standard exists — use thin per-agent wiring over one shared script"
date: 2026-06-26
topic: agentic-context-design
tags: [hooks, cross-agent, claude-code, gemini, codex, precompact, abstraction, portability]
status: settled
sources: [cc-hooks-docs, gemini-hooks-docs, codex-hooks-local, context-mode-adapters, weykon-agent-hooks, dotfiles-local]
source_session: 019dd670-7005-7e83-a1c2-86e2610f04b0
---

## CLAIMS

- CORRECTION to the prior corpus claim "Codex has no hooks": Codex CLI (0.130+) DOES have a hook system, gated behind `[features].hooks = true`, configured in `~/.codex/hooks.json`, with PascalCase event names mirroring Claude (PreToolUse, PostToolUse, SessionStart, Stop, UserPromptSubmit, and PreCompact). [codex-hooks-local, context-mode-adapters]
- All three agents have a PRE-COMPACTION event: Claude `PreCompact`, Gemini `PreCompress`, Codex `PreCompact` (Codex's is runtime-gated in 0.130+ and lags the public docs). So "capture before compaction" is achievable cross-agent. [cc-hooks-docs, gemini-hooks-docs, context-mode-adapters]
- Cross-agent event mapping (verified): after-tool = PostToolUse / AfterTool / PostToolUse; before-tool = PreToolUse / BeforeTool / PreToolUse; session-start = SessionStart (all three); session-end = SessionEnd / SessionEnd / Stop; user-prompt = UserPromptSubmit / BeforeAgent / UserPromptSubmit. Config lives in ~/.claude/settings.json, ~/.gemini/settings.json, ~/.codex/hooks.json (all under a "hooks" key). [cc-hooks-docs, gemini-hooks-docs, codex-hooks-local]
- Wire format: all three deliver event data as JSON on stdin and read the hook's stdout; field names differ slightly per agent, so a shared script needs a small per-agent field-extraction shim. Gemini has the richest event set (BeforeModel/AfterModel/BeforeAgent/AfterAgent/BeforeToolSelection in addition to the shared ones). [cc-hooks-docs, gemini-hooks-docs]
- NO cross-agent hook STANDARD exists. AGENTS.md unified instructions; there is no equivalent for hooks/lifecycle events. MCP does not define lifecycle hooks (it is a tool-calling protocol). No public spec/RFC from Anthropic/OpenAI/Google. [context-mode-adapters, gemini-hooks-docs]
- Reusable abstraction LIBRARIES exist but are immature: weykon/agent-hooks (Rust ToolAdapter trait, ~2 stars, stale/incorrect event table, not on crates.io) and beam-agent (Elixir SDK, different problem: programmatic orchestration, not CLI hook wiring). The most mature cross-agent hook normalization is context-mode's embedded `adapters/` layer (`context-mode hook <agent> <event>`) — but it's part of that tool, not a standalone library. [weykon-agent-hooks, context-mode-adapters]
- The practitioner-stabilized pattern (used by context-mode and the right call here): thin per-agent wiring over one shared script — `myhook.sh <agent> <event>` reads stdin, normalizes per agent, acts; each agent's config calls it with its native event name. The "abstraction layer" is ~one script with a small per-agent shim, not a library. This is the sync-mcps.sh "one manifest, install per agent" pattern applied to hooks. [context-mode-adapters, dotfiles-local]

## SOURCES

**cc-hooks-docs**
URL: https://docs.anthropic.com/en/docs/claude-code/hooks
Accessed: 2026-06-26
Quote: Claude Code hooks (PreToolUse, PostToolUse, PreCompact, SessionStart, SessionEnd, UserPromptSubmit) in ~/.claude/settings.json; stdin JSON in, stdout/exit-code out.

**gemini-hooks-docs**
URL: https://github.com/google-gemini/gemini-cli/tree/main/docs/hooks
Accessed: 2026-06-26
Quote: Gemini CLI events include SessionStart, SessionEnd, BeforeAgent, AfterAgent, BeforeModel, AfterModel, BeforeToolSelection, BeforeTool, AfterTool, PreCompress, Notification; stdin JSON, stdout decision/systemMessage/hookSpecificOutput.

**codex-hooks-local**
URL: local — ~/.codex/hooks.json + ~/.codex/config.toml ([features].hooks=true)
Accessed: 2026-06-26
Quote: Codex hooks.json registers PreToolUse/PostToolUse/SessionStart/Stop/UserPromptSubmit/PreCompact (PascalCase, Claude-like), gated by [features].hooks=true.

**context-mode-adapters**
URL: https://github.com/mksglu/context-mode
Accessed: 2026-06-26
Quote: Per-agent adapter classes normalize hook events; exposes `context-mode hook <agent> <event>`; install docs include Codex PreCompact and note it is runtime-gated in Codex 0.130+, docs lag.

**weykon-agent-hooks**
URL: https://github.com/weykon/agent-hooks
Accessed: 2026-06-26
Quote: Rust ToolAdapter trait with per-agent modules + auto_register_all() that writes hook config into each agent; ~2 stars, event table stale, not published. Immature.

**dotfiles-local**
URL: local — this dotfiles repo (sync-mcps.sh, research-capture-* hooks)
Accessed: 2026-06-26
Quote: Repo already uses one-script-many-agents wiring for MCPs; the same pattern applies to hooks.

## SYNTHESIS

For a cross-agent hook (e.g. the research-capture nudge): don't adopt a library (none is mature)
and don't wait for a standard (none is coming soon). Use thin per-agent wiring over shared logic.
Concretely: one `research-capture-detect`/`-nudge` script taking an `<agent>` arg, with a small
per-agent stdin-field shim (tool_name / session_id extraction), wired into each agent's native
events: Claude PostToolUse+PreCompact, Gemini AfterTool+PreCompress, Codex PostToolUse+PreCompact
(needs [features].hooks=true). Per-agent config stubs are short and structurally similar; the
logic is written once. ALSO: correct the stale corpus claim — Codex has hooks now. If packaging
to share externally, the cleanest artifact is exactly this (shared script + 3 config stubs +
install step), which is what context-mode productized; a generic library is premature given no
standard.
