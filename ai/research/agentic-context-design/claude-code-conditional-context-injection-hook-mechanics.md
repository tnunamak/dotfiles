---
title: "Claude Code can conditionally inject context via UserPromptSubmit, but skills are the idiomatic mechanism for sometimes-relevant capabilities"
date: 2026-06-25
topic: agentic-context-design
tags: [hooks, skills, claude-code, gemini, prompt-caching, conditional-context]
status: settled
sources: [cc-hooks, cc-skills-best-practices, anthropic-skills, cc-prompt-caching, gemini-config, cm-adapter-schema]
source_session: 019f118b-c78e-7651-ba62-0cda57f9b264
---

## CLAIMS

- Claude Code hook events that can inject model-visible context: PreToolUse, PostToolUse, UserPromptSubmit (via hookSpecificOutput.additionalContext), and PreCompact/SessionStart (via a context field); Stop is capture-only. [cc-hooks, cm-adapter-schema]
- The UserPromptSubmit input exposes the prompt at the root as `prompt` (NOT `tool_input.prompt` — it is not a tool call), and context is injected via the `hookSpecificOutput.additionalContext` wrapper, not a flat root-level field. [cm-adapter-schema]
- Anthropic best-practices: CLAUDE.md loads every session so it should hold only broadly-relevant content; for sometimes-relevant workflows use skills, which Claude "loads on demand without bloating every conversation." [cc-skills-best-practices]
- Skills are progressive disclosure: only name+description load at startup ("many Skills without context penalty"); the body loads only when the description matches the task. [anthropic-skills]
- Claude Code prompt-caching: the system prompt + CLAUDE.md are cached as the request prefix and billed at ~10% of input price on cached reads, so a short stable always-on block costs ~nothing per turn after the first. [cc-prompt-caching]
- Skill/plan-mode loading appends instructions as conversation messages so the cached CLAUDE.md prefix stays intact — skills/commands/agents/hooks never invalidate the cache; conversely, editing CLAUDE.md does NOT apply mid-session (baked into the cached prefix until /clear, /compact, or restart). [cc-prompt-caching]
- The residual cost of always-on content that caching does NOT fix is attention / context-rot: recall degrades as total tokens grow regardless of price, which argues for keeping always-on footprint minimal even when it is financially free. [anthropic-skills]
- Hook portability is limited: Gemini's session-start event is named differently and Codex has no hook system, so a hook is per-agent reimplementation whereas AGENTS.md/skills reach all three via the existing include+symlink. [gemini-config]

## SOURCES

**cc-hooks**
URL: https://docs.anthropic.com/en/docs/claude-code/hooks
Accessed: 2026-06-25
Quote: UserPromptSubmit runs before Claude processes the prompt and can "add additional context based on the prompt/conversation"; write injected text as factual statements, not imperative instructions.

**cc-skills-best-practices**
URL: https://www.anthropic.com/engineering/claude-code-best-practices
Accessed: 2026-06-25
Quote: "CLAUDE.md is loaded every session, so only include things that apply broadly. For domain knowledge or workflows that are only relevant sometimes, use skills instead. Claude loads them on demand without bloating every conversation."

**anthropic-skills**
URL: https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
Accessed: 2026-06-25
Quote: Metadata is "the first level of progressive disclosure"; "you can install many Skills without context penalty."

**cc-prompt-caching**
URL: https://code.claude.com/docs/en/prompt-caching
Accessed: 2026-06-25
Quote: Cached reads bill at ~10% of input price; skill loading "appends instructions as conversation messages, so the cached prefix stays intact"; hooks/skills/commands "never invalidate the cache."

**gemini-config**
URL: https://docs.gemini-cli.com (configuration / hooks)
Accessed: 2026-06-25
Quote: Gemini settings.json supports $VAR/${VAR}/${VAR:-default} expansion in any string value; its session-start hook event name differs from Claude's, and Codex has no hook system. (Env-var-in-headers verified empirically this session: linear + vana-knowledge-base MCP both connected with ${VAR} in Authorization headers.)

**cm-adapter-schema**
URL: local — node_modules/context-mode/build/adapters/claude-code-base.d.ts
Accessed: 2026-06-25
Quote: UserPromptSubmit input carries `prompt` at root; context injection is via hookSpecificOutput.additionalContext (not a flat root field). Corrects a subagent claim of `tool_input.prompt` + flat additionalContext.

## SYNTHESIS

For surfacing an optional tool to coding agents, the idiomatic, Anthropic-endorsed, cross-agent
answer is a skill (description = always-on awareness, body = lazy detail) plus a one-line
always-on pointer for recall insurance — NOT a UserPromptSubmit hook, which is Claude-only and
fuzzy. Reserve a keyword hook for deterministic/headless cases only, inject a nudge in plain
text not JSON (known first-message + injection-detection bugs), and never inject full
instructions (defeats the savings). Caching makes the dollar cost of a short always-on pointer
negligible; the real reason to stay terse is attention/context-rot. Hook-schema gotcha worth
keeping: input is `prompt` at root, output is hookSpecificOutput.additionalContext.
