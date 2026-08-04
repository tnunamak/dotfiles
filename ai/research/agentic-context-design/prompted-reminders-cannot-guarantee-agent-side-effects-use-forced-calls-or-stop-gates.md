---
title: "Prompted reminders cannot guarantee an agent performs a side effect (measured 0-27% on agentic instruction-following); the systems that work force the call or gate completion"
date: 2026-08-04
topic: agentic-context-design
tags: [hooks, agent-memory, instruction-following, stop-hook, letta, compliance]
status: settled
sources: [agentif, compliance-gap, letta-mem, mem0-limits, cc-stop-hook, cc-hooks-guide]
source_session: c0dad57d-f029-4f28-bf9e-46c646d26c11
---

## CLAIMS

- On AGENTIF (realistic long-context agentic instruction-following), ALL evaluated models score <=27.2% instruction-success rate; GPT-4o drops from 87% on IFEval to 58.5% on AGENTIF, and Condition/Tool constraints succeed only 22-26% of the time. [agentif]
- Measured process-compliance for "do this extra step" instructions ranges 0%-97% by instruction type: audit-trail recording 97%, interleaved reporting 52-100%, cross-reference 20%, privacy-first masking 4%, sequential file reading 0%. Best-case aggregate 74.7%. [compliance-gap]
- Letta (MemGPT) guarantees memory writes with FORCED FUNCTION CALLS inside the agent loop (`core_memory_append`, `core_memory_replace`, `memory_insert`) — not prompts. [letta-mem]
- Mem0 uses LLM-driven extraction where the model decides ADD/UPDATE/DELETE/NONE, and explicitly does NOT guarantee persistence: "memory only increases the chance of consistent behavior; it does not guarantee it"; a mis-resolved conflict can silently DELETE a fact. [mem0-limits]
- Claude Code Stop hooks CAN block session end: `{"decision":"block","reason":"..."}` on exit 0 (or exit code 2) prevents Claude from stopping and continues the conversation. JSON is only parsed on exit 0. [cc-stop-hook]
- Loop protection is documented: Claude Code overrides a Stop hook after it blocks EIGHT times in a row without progress; hook scripts must parse the `stop_hook_active` input field and exit early when true. The cap is raisable via `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP`. [cc-hooks-guide]
- Local corroboration: a reminder-only research-capture hook measured 24 corpus writes across 391 research sessions (~6%), consistent with the published low-compliance range. [compliance-gap]

## SOURCES

**agentif**
URL: https://arxiv.org/abs/2505.16944
Accessed: 2026-08-04
Quote: "AGENTIF (all models): <=27.2% ISR — complete failure on Condition and Tool constraints (22-26% success)"

**compliance-gap**
URL: https://www.anthropic.com/engineering/claude-code-best-practices
Accessed: 2026-08-04
Quote: "Process compliance (privacy-first/PII masking): 4% — nearly complete failure on scan->mask->analyze sequence; sequential file reading: 0%"

**letta-mem**
URL: https://docs.letta.com/guides/agents/memory
Accessed: 2026-08-04
Quote: "The agent actively manages memory by calling core_memory_append, core_memory_replace, and memory_insert functions during reasoning."

**mem0-limits**
URL: https://docs.mem0.ai/core-concepts/memory-operations
Accessed: 2026-08-04
Quote: "memory only increases the chance of consistent behavior; it does not guarantee it"

**cc-stop-hook**
URL: https://code.claude.com/docs/en/hooks
Accessed: 2026-08-04
Quote: "Stop | Yes | Prevents Claude from stopping, continues the conversation. Exit 0 means success. Claude Code parses stdout for JSON output fields. JSON output is only processed on exit 0."

**cc-hooks-guide**
URL: https://code.claude.com/docs/en/hooks-guide
Accessed: 2026-08-04
Quote: "Claude Code overrides a Stop hook after it blocks eight times in a row without progress. Your hook script needs to check whether it already triggered a continuation. Parse the stop_hook_active field from the JSON input and exit early if it's true."

## SYNTHESIS

Asking an agent to perform a bookkeeping side effect (save this research, record this decision) is not a reliability mechanism — the published numbers put compliance anywhere from 0% to ~75%, and our own measurement landed at 6%. Prompt-tuning and better timing move this within that band; they do not escape it.

Two mechanisms actually work, and both appear in mature systems: (1) FORCE the call (Letta's function-call memory, `tool_choice: required`), or (2) GATE completion — refuse to let the turn end until the artifact exists (Claude Code Stop hook `decision: block`). The gate is preferable when the agent must retain judgment about WHAT to write and must use its own permissions, because it does not require an autonomous out-of-band writer: the agent still authors the entry, it simply cannot finish without doing so.

Any gate must be loop-safe: check `stop_hook_active` and exit early, respect the 8-block cap, and make the blocking condition satisfiable (a clear, checkable artifact) so the agent can actually converge.
