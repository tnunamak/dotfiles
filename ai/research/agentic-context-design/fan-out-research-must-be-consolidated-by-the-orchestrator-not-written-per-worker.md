---
title: "Fan-out research fragments unless the orchestrator does the consolidation; every production multi-agent system centralizes the write, and Claude Code hooks expose agent_id so a capture gate can target the orchestrator only"
date: 2026-08-04
topic: agentic-context-design
tags: [multi-agent, fan-out, hooks, subagent, consolidation, map-reduce]
status: settled
sources: [anthropic-research, crewai-mem, langgraph-scatter, mapreduce, prod-failures, cc-subagent-hooks, cc-agent-id]
source_session: c0dad57d-f029-4f28-bf9e-46c646d26c11
---

## CLAIMS

- Every surveyed production multi-agent system centralizes consolidation in the ORCHESTRATOR, not the workers: Anthropic's LeadResearcher synthesizes subagent findings before CitationAgent; OpenAI DeepResearcher orchestrates then proofreads; Google co-scientist's Supervisor writes persistent context after collecting all intermediate outputs. [anthropic-research]
- CrewAI stores to ONE unified Memory after each task rather than per-worker writes; agents differ only in how they RECALL (planning weights importance, execution weights recency). [crewai-mem]
- LangGraph's scatter-gather runs workers in parallel then consolidates in a separate, deterministic REDUCE stage outside agent contexts. [langgraph-scatter]
- Map-reduce is the canonical consolidation shape: workers MAP their chunk, one REDUCE combines into a single final artifact — which is what prevents N conflicting summaries. [mapreduce]
- Per-worker writes without a reduce stage produce three failure modes: duplication (two workers solve the same subproblem unaware), contradiction (worker A extracts X, B extracts not-X, no reconciliation), and state desynchronization (a worker reads state another is mid-update). Coordination breakdown + spec ambiguity accounts for ~79% of production multi-agent failures, and is a system-level property rather than agent-level quality. [prod-failures]
- Anthropic's orchestrator-based research system beat a single-agent baseline by 90.2% on internal evals at ~15x token overhead, with the synthesis pass paid ONCE at the end rather than replicated per worker. [anthropic-research]
- Claude Code fires ALL hooks inside subagents (including PreToolUse/PostToolUse), but the PARENT session does not see subagent tool-call hooks directly. [cc-subagent-hooks]
- Subagent hook input carries `agent_id` and `agent_type` PLUS the parent's `session_id`; `agent_id` is present ONLY in subagent context, so a hook can distinguish worker from orchestrator. [cc-agent-id]
- `SubagentStop` is a distinct event from `Stop` (Stop hooks are auto-converted to SubagentStop inside subagent frontmatter), and SubagentStop can also block via exit 2 / decision:block. [cc-subagent-hooks]
- Headless `claude -p` sessions and interactive sessions are NOT distinguishable to hooks via documented hook input or documented env vars; `CLAUDE_CODE_ENTRYPOINT` is not in the official env-var reference. [cc-agent-id]

## SOURCES

**anthropic-research**
URL: https://www.anthropic.com/engineering/multi-agent-research-system
Accessed: 2026-08-04
Quote: "LeadResearcher synthesizes subagent findings before routing to CitationAgent"; "beats single-agent baseline by 90.2% on internal evals; cost is 15x token overhead"

**crewai-mem**
URL: https://docs.crewai.com/concepts/memory
Accessed: 2026-08-04
Quote: "after each task the crew extracts facts and stores them centrally; before each task agents recall relevant context injected into the prompt"

**langgraph-scatter**
URL: https://langchain-ai.github.io/langgraph/concepts/multi_agent/
Accessed: 2026-08-04
Quote: "parallel agents execute independently, results are consolidated in a separate REDUCE stage, not inside agent contexts"

**mapreduce**
URL: https://python.langchain.com/docs/tutorials/summarization/
Accessed: 2026-08-04
Quote: "MAP phase has workers summarize their chunk; REDUCE phase combines all summaries into one final summary"

**prod-failures**
URL: https://arxiv.org/abs/2503.13657
Accessed: 2026-08-04
Quote: "79% of failures trace to specification ambiguity + coordination breakdown"; "Inter-agent misalignment is the most common production failure mode"

**cc-subagent-hooks**
URL: https://code.claude.com/docs/en/hooks-guide
Accessed: 2026-08-04
Quote: "All hooks run inside subagents"; "Parent session does NOT see subagent tool-call hooks directly"; "Stop hooks are automatically converted to SubagentStop in subagent frontmatter"

**cc-agent-id**
URL: https://code.claude.com/docs/en/hooks
Accessed: 2026-08-04
Quote: "Hook input includes agent_id field that is present ONLY when running in a subagent context; agent_type accompanies it"

## SYNTHESIS

For a research-capture gate this settles two design questions and exposes one limit.

Settled: (1) gate the ORCHESTRATOR, never the workers — blocking each worker would produce N shallow fragments instead of one synthesized entry, which is exactly the duplication/contradiction failure mode the literature documents. (2) A hook can implement this today: skip when `agent_id` is present (subagent), act only when it is absent (top-level). Task-tool fan-out needs no extra work because subagent research already keys to the parent's `session_id`, so the parent's flag represents the whole fan-out.

The limit: independently-spawned sessions (waspflow lanes, `claude -p`) are indistinguishable from an interactive orchestrator by documented means. Each is a real session with its own flag, so a naive per-session gate would block each lane. Mitigations, in order of robustness: have the spawning tool mark its workers via an env var the hook checks (opt-in, deterministic); or gate only sessions whose research exceeds a threshold; or accept worker-level capture as low-value noise and dedupe later. The orchestrator-writes principle is the durable part; worker detection for out-of-process fan-out needs a cooperating spawner.
