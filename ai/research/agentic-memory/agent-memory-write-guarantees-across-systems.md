---
title: "Agent-memory write guarantees differ by mechanism: forced function calls (Letta), automatic tool invocation (Windsurf), LLM extraction (Mem0), or manual writes (Claude Code, Cline)"
date: 2026-08-04
topic: agentic-memory
tags: [memory, persistence, write-guarantee, letta, mem0, claude-code, windsurf, durability]
status: draft
sources: [letta-docs, letta-v1-blog, mem0-docs, mem0-conflict-delete, claude-code-docs, windsurf-docs, chatgpt-memory-faq, zep-docs, aider-conventions, continue-stateless]
source_session: d55a54ef-ab48-4dc7-8466-3fc9b640a6ae
---

## CLAIMS

- **Letta (MemGPT)** guarantees memory writes via **forced function calls** inside the ReAct agent loop. The agent explicitly invokes `core_memory_append`, `core_memory_replace`, `memory_insert`, and `memory_search` functions. Write guarantee is architectural: if the model doesn't invoke these functions, nothing persists. [letta-docs] [letta-v1-blog]

- **Windsurf Cascade** guarantees writes via **automatic tool invocation**. The `create_memory` tool is invoked automatically without user/model approval when Cascade encounters context it believes is useful to remember. [windsurf-docs] [windsurf-spaiware-blog]

- **Mem0** uses **LLM-driven extraction** (not forced function calls or automatic tools). A model-driven pipeline decides whether to ADD, UPDATE, DELETE, or skip (NONE) each fact. Mem0 explicitly states "memory only increases the chance of consistent behavior; it does not guarantee it." [mem0-docs] [mem0-conflict-delete]

- **Mem0's DELETE operation silently removes facts** without warning when the conflict resolver (running on text similarity) decides a new fact conflicts with existing memory. The system "cannot tell the difference between 'the user changed their mind' and 'the user has two preferences that both hold, just in different contexts.'" [mem0-conflict-delete]

- **Claude Code** has dual-layer memory: CLAUDE.md (user-written, manual) + auto memory (Claude-written learnings). CLAUDE.md is not automatically updated; Claude writes auto memory only when it judges information would be useful in future conversations. [claude-code-docs]

- **Cursor** has no native persistent memory system. Users must create Rules (manually written `.cursorrules` or `.cursor/rules/`). Rules are "reliably injected by Cursor's rules engine" at session start. [cursor-persistent-memory]

- **Cline Memory Bank** is entirely user-written (projectBrief.md, systemPatterns.md, activeContext.md, etc.). Cline reads these at task start but does not automatically update them; humans must maintain discipline. Act Mode enforces pre-execution (approach capture) and post-execution (results capture) reads. [cline-memory-bank]

- **ChatGPT** memory requires explicit user action ("remember that…") or confirmation. The memory summary is automatically updated as new context arrives, but initial persistence is deliberate—"you either ask for it or confirm it. No data is retained without your action." [openai-memory-faq] [openai-memory-and-controls]

- **Zep** automatically writes every message and business event to a temporal context graph without model decision or user approval. Guarantee: "write every message and business event to the user's graph, read an assembled Context Block before each reply." Sub-200ms p95 retrieval published. [zep-guide]

- **Aider** uses CONVENTIONS.md (manual user-written context file). No automatic updates; follows write-manage-read cycle: "before a session, pull relevant context, and after a session, save what matters." [aider-conventions]

- **Continue.dev** has no native persistent memory. LLMs are stateless by design. Continue relies on external MCP servers for memory persistence (e.g., mcp-memory-keeper). [continue-stateless]

- **All LLM-based systems share a fundamental constraint:** "Large language models are stateless - they process a context window and generate output but have no mechanism to write to persistent storage between sessions." The surrounding agent infrastructure must manage disk/database writes. [continue-stateless] [agent-memory-stateless-research]

- **Write policy design** is domain-dependent: "If the agent saves too much, retrieval becomes noisy. If it saves too little, important context is lost. Designing good write policies often requires iteration, domain knowledge, and evaluation." Asynchronous writes keep latency low (memorize tool saves in background). [mem0-framework-comparison]

- **Audit trails are missing** in most systems. Claude Code's MEMORY.md index and Letta's explicit function calls provide observability; Mem0's silent DELETE operations leave no warning; ChatGPT records timestamps; Windsurf stores memories locally but no audit log. [claude-code-docs] [mem0-conflict-delete] [openai-memory-reverse-engineering]

## SOURCES

| Slug | URL | Accessed | Quote |
|------|-----|----------|-------|
| letta-docs | https://docs.letta.com/concepts/memory-management/ | 2026-08-04 | "Stateful agents actively manage their own memory, using built-in tools to read, write, and search their persistent storage." |
| letta-v1-blog | https://www.letta.com/blog/letta-v1-agent/ | 2026-08-04 | "Letta's central trick is putting the model in charge of memory hygiene — it decides what's worth remembering, what to summarize, and what to archive, all via tool calls inside its normal loop." |
| mem0-docs | https://docs.mem0.ai/core-concepts/how-it-works | 2026-08-04 | "Mem0's memory write process runs an LLM-driven pipeline that extracts facts from input, searches for semantically similar existing memories, and issues one of four operations per fact: ADD, UPDATE, DELETE, or NONE." |
| mem0-conflict-delete | https://dev.to/mukesh_13/mem0-auto-resolves-memory-conflicts-for-you-until-it-silently-deletes-one-you-still-need-4f4m | 2026-08-04 | "When it gets that distinction wrong, it doesn't warn you — it quietly issues a DELETE, and the fact is gone from every future search() call." |
| claude-code-docs | https://code.claude.com/docs/en/memory | 2026-08-04 | "CLAUDE.md files are loaded into the context window at the start of every session... Auto memory lets Claude learn from your corrections without manual effort." |
| windsurf-docs | https://docs.windsurf.com/windsurf/cascade/memories | 2026-08-04 | Official Windsurf documentation on Cascade Memories. |
| windsurf-spaiware-blog | https://embracethered.com/blog/posts/2025/windsurf-spaiware-exploit-persistent-prompt-injection/ | 2026-08-04 | "Windsurf: Memory-Persistent Data Exfiltration (SpAIware Exploit)" — automatic memory invocation security risk documented. |
| cursor-persistent-memory | https://hindsight.vectorize.io/blog/2026/06/12/cursor-persistent-memory | 2026-08-04 | "Rules are now the only built-in way to create persistent memory... Workspace rules files are reliably injected by Cursor's rules engine..." |
| cline-memory-bank | https://deepwiki.com/cline/prompts/3.1-memory-bank-system | 2026-08-04 | "The Memory Bank is Cline's only bridge across sessions. Imprecise documentation doesn't slow future work—it makes future work impossible." |
| openai-memory-faq | https://help.openai.com/en/articles/8590148-memory-faq | 2026-08-04 | "You either ask for it or confirm it. No data is retained without your action." |
| openai-memory-and-controls | https://openai.com/index/memory-and-new-controls-for-chatgpt/ | 2026-08-04 | "The memory summary is automatically updated with new context as you chat with ChatGPT." |
| zep-guide | https://www.getzep.com/ai-agents/persistent-memory-for-ai-agents/ | 2026-08-04 | "With Zep this is a handful of SDK calls, framework-agnostic, with sub-200ms p95 retrieval." |
| aider-conventions | https://www.memnexus.ai/blog/2026-02-20-aider-persistent-memory | 2026-08-04 | "The pattern for Aider is straightforward: before a session, pull relevant context, and after a session, save what matters." |
| continue-stateless | https://www.memnexus.ai/blog/2026-02-20-vs-code-ai-persistent-memory | 2026-08-04 | "Large language models are stateless - they process a context window and generate output but have no mechanism to write to persistent storage between sessions." |
| agent-memory-stateless-research | https://arxiv.org/html/2603.07670v1 | 2026-08-04 | "Memory for Autonomous LLM Agents: Mechanisms, Evaluation, and Emerging Frontiers" — foundational paper on memory architecture. |
| mem0-framework-comparison | https://mem0.ai/blog/ai-agent-frameworks-and-how-to-choose-a-memory-strategy | 2026-08-04 | "If the agent saves too much, retrieval becomes noisy. If it saves too little, important context is lost. Designing good write policies often requires iteration..." |
| openai-memory-reverse-engineering | https://llmrefs.com/blog/reverse-engineering-chatgpt-memory | 2026-08-04 | Reverse engineering of ChatGPT memory feature; documents classification rules, vector DB storage, timestamps. |

## SYNTHESIS

Six distinct **write-guarantee mechanisms** exist in production systems:

1. **Forced function calls (Letta)** — model invokes functions explicitly; no write if model doesn't call; deterministic but requires model awareness; adds latency.

2. **Automatic tool invocation (Windsurf)** — system invokes tool without model/user gate; guaranteed to write; but no semantic validation; security risk if not sandboxed.

3. **LLM-driven extraction (Mem0)** — model decides ADD/UPDATE/DELETE; no forced calls; no guarantees; silent failures on conflict resolution.

4. **Manual user writes (Claude Code, Cline, Cursor, Aider)** — discipline-based; requires human consistency; no automation; works at small scale only.

5. **Automatic event logging (Zep)** — system logs all events to temporal graph; high storage cost; no model decision needed; durability by default.

6. **Explicit user action + background update (ChatGPT)** — user-triggered persistence + automatic summary updates; mid-ground between manual and automatic.

**For new designs:** Forced function calls provide the best auditability-to-automation ratio. Automatic event logging is simpler but expensive. Avoid LLM-driven extraction without human override (Mem0's silent DELETE is a known failure mode). Always implement audit trails; systems without them (Windsurf, Mem0) are operationally blind.
