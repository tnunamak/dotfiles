---
title: "Pi exposes per-model-call context pruning, but its built-in threshold compaction waits for the agent run to end"
date: 2026-07-13
topic: llm-integration
tags: [pi, compaction, context-pruning, claude-code, codex]
status: draft
sources: [pi-compaction-issue, pi-agent-session-source, pi-pruning-discussion, pi-context-prune, claude-errors, claude-troubleshooting, claude-changelog, codex-mid-turn]
source_session: 09682362-1d47-41da-a3a3-a83e739b8760
---

## CLAIMS

- Pi's original compaction design discussion proposed checking after every assistant `message_end`, aborting an active tool loop, compacting, and resuming; it explicitly identified waiting until `agent_end` as risking tool results exhausting the remaining context. [pi-compaction-issue]
- Current Pi source documents its built-in compaction check as running after `agent_end` and before prompt submission; threshold compaction does not automatically retry, while recognized context-overflow recovery does. [pi-agent-session-source]
- Pi's maintainer changed the `context` extension event to run before every LLM call so pruning invoked during a long agent loop affects the next model call. [pi-pruning-discussion]
- `pi-context-prune` can summarize completed tool-call batches and remove their raw results from future request context while preserving the original session entries; its `every-turn` and `agentic-auto` modes can reclaim context during long runs, with latency, summary-loss, and prompt-cache tradeoffs. [pi-context-prune]
- Claude Code documentation says auto-compaction is enabled by default, and its troubleshooting guide describes repeated successful auto-compactions followed by a file or tool output immediately refilling context, with a retry circuit breaker. [claude-errors] [claude-troubleshooting]
- Claude Code's changelog includes fixes for autocompaction in sessions interrupted mid-tool-batch and for repeated autocompaction retries, but its public documentation does not specify the exact internal checkpoint cadence. [claude-changelog]
- Codex has an upstream issue and implementation discussion describing context-window recovery inside `run_turn`: compact, rebuild the request, and retry the sampling call. [codex-mid-turn]

## SOURCES

**pi-compaction-issue**
URL: https://github.com/earendil-works/pi/issues/92
Accessed: 2026-07-13

**pi-agent-session-source**
URL: https://github.com/earendil-works/pi/blob/main/packages/coding-agent/src/core/agent-session.ts
Accessed: 2026-07-13

**pi-pruning-discussion**
URL: https://github.com/earendil-works/pi/discussions/330
Accessed: 2026-07-13

**pi-context-prune**
URL: https://github.com/championswimmer/pi-context-prune
Accessed: 2026-07-13

**claude-errors**
URL: https://code.claude.com/docs/en/errors
Accessed: 2026-07-13

**claude-troubleshooting**
URL: https://code.claude.com/docs/en/troubleshooting
Accessed: 2026-07-13

**claude-changelog**
URL: https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md
Accessed: 2026-07-13

**codex-mid-turn**
URL: https://github.com/openai/codex/issues/7808
Accessed: 2026-07-13

## SYNTHESIS

Pi has two separate context-management layers. Built-in compaction creates a durable semantic checkpoint but currently waits for the low-level agent run to settle unless the provider produces a recognized overflow. Extensions can transform request context before every model call and therefore prevent a long tool loop from reaching that failure point, but pruning is not identical to full session compaction and has cache and fidelity costs. Claude Code appears to support effective mid-run compact-and-continue behavior, although its closed implementation and public docs do not establish the exact checkpoint. Codex documents explicit mid-turn recovery. For Pi, a pruning extension can provide defense in depth, but the one-token context-clamp edge still merits a narrow upstream recovery signal because configuration and pruning policy should not be required for correctness.
