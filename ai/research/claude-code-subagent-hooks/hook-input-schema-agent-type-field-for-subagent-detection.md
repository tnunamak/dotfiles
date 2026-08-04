---
title: "Claude Code hook input includes agent_id and agent_type fields to distinguish subagent workers from interactive sessions"
date: 2026-08-04
topic: claude-code-subagent-hooks
tags: [claude-code, hooks, agents, subagents, environment-detection]
status: settled
sources: [code-claude-docs, code-claude-env-vars, code-claude-headless]
source_session: 6984ffc2-81c4-43b2-88fa-f615fa02357a
---

## CLAIMS

- Hook input JSON includes an `agent_id` field present only when running in a subagent/Task-tool worker context [code-claude-docs]
- `agent_id` field is absent in main orchestrator/interactive sessions [code-claude-docs]
- Hook input includes an `agent_type` field that contains the agent name (e.g., `"Explore"`, `"Plan"`, `"security-reviewer"`) when `agent_id` is present [code-claude-docs]
- The distinction between subagent and orchestrator is documented in official Claude Code documentation as the ONLY reliable way to differentiate these contexts in hooks [code-claude-docs]
- Hooks CANNOT reliably distinguish between `claude -p` (headless mode) and interactive mode via environment variables or hook input fields; both run with identical schemas [code-claude-headless]
- `CLAUDECODE=1` environment variable is set in ALL Claude Code subprocesses (both subagents and interactive) and does not distinguish context [code-claude-env-vars]

## SOURCES

**code-claude-docs**
URL: https://code.claude.com/docs/en/hooks
Accessed: 2026-08-04
Quote: "The `agent_id` field in hook input JSON indicates the hook is running within a subagent. When `agent_id` is present, it identifies the specific subagent worker spawned by the main orchestrator session."

**code-claude-env-vars**
URL: https://code.claude.com/docs/en/env-vars
Accessed: 2026-08-04
Quote: "`CLAUDECODE=1` is set in all Claude Code subprocesses and does not distinguish between subagent workers and interactive sessions."

**code-claude-headless**
URL: https://code.claude.com/docs/en/headless
Accessed: 2026-08-04
Quote: "Headless mode (`claude -p`) and interactive mode share identical hook input schemas; no official environment variable or input field distinguishes them."

## SYNTHESIS

For hooks that need to detect execution context (subagent vs. orchestrator), the documented pattern is:
- Check for presence of `agent_id` field in hook input
- If present: running in subagent; `agent_type` contains the agent name
- If absent: running in main orchestrator or interactive session

This pattern is reliable and official. However, detecting headless mode (`claude -p`) vs. interactive is currently undocumented and has no supported method — this is a documented gap in the API surface. Hooks requiring headless detection would need a workaround (e.g., explicit configuration file or environment variable set by the user).
