---
title: "Agents reliably retrieve stored knowledge only via an always-on instruction, not model-judgment retrieval"
date: 2026-06-25
topic: agentic-context-design
tags: [retrieval, memory, cursor, cline, claude-code, write-only-failure]
status: settled
sources: [anthropic-context-eng, windsurf-memories, cline-memory-bank, claude-code-memory, devin-knowledge, letta-memory, trigger-cursor-rules]
source_session: 019f005e-b205-77b3-9faa-01fe0eac7ed7
---

## CLAIMS

- The "write-only knowledge base" failure (knowledge gets written but never read back) is a retrieval-mechanism failure, not a knowledge-quality failure; the fix every production tool ships is making corpus-checking a standing instruction rather than a model judgment. [cline-memory-bank, windsurf-memories]
- Across Cursor, Windsurf, Cline, Continue, Devin, Aider, Claude Code, and Letta, retrieval reliability ranks: always-on injection > deterministic glob/file-pattern > "MUST read at task start" instruction > agent tool-call exploration > model-judgment description matching > auto-generated semantic memories > embeddings-over-docs. [windsurf-memories, trigger-cursor-rules, cline-memory-bank, letta-memory]
- Windsurf's own docs explicitly recommend against relying on auto-generated Memories for durable knowledge: "for knowledge you want Cascade to reliably reuse, write it as a Rule or add it to AGENTS.md." [windsurf-memories]
- Devin retrieves "Knowledge when relevant, not all at once or all at the beginning," and its docs steer users to repo-pinned (always-on) entries over floating (model-judgment) ones for reliability; every floating entry requires a hand-written trigger description. [devin-knowledge]
- Claude Code's MEMORY.md index loads at session start (first ~200 lines / 25KB) but topic files load only on model demand — Anthropic treats the always-on CLAUDE.md instruction as the reliable channel and on-demand topic files as supplementary. [claude-code-memory]
- Letta/MemGPT tiers memory deliberately: Core Memory blocks are always in context; Archival memory requires the agent to call archival_memory_search — i.e. only the always-on tier is reliable, the searchable tier requires intentional recall. [letta-memory]
- Cline's Memory Bank achieves reliable reads via a rules-layer imperative framed as identity ("my memory resets between sessions... I MUST read ALL memory bank files at the start of EVERY task - this is not optional"); its failure mode is operator negligence (forgetting to update), not retrieval failure. [cline-memory-bank]
- Cursor's "Agent Requested" rules (model reads a description and decides whether to fetch) are frequently skipped unless the description is very precise; deterministic "Auto Attached" glob rules are the community-preferred reliable type. [trigger-cursor-rules]
- Anthropic states agents should use glob/grep to retrieve files just-in-time, "effectively bypassing the issues of stale indexing," with CLAUDE.md "naively dropped into context up front." [anthropic-context-eng]
- The reliable systems orient the agent with a lightweight always-loaded INDEX/manifest (Aider repo-map, Claude Code MEMORY.md, Basic Memory link-traversal) so the agent decides WHAT to read in one pass, rather than deciding WHETHER to look. [claude-code-memory, anthropic-context-eng]

## SOURCES

**anthropic-context-eng**
URL: https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
Accessed: 2026-06-25
Quote: "CLAUDE.md files are naively dropped into context up front, while primitives like glob and grep allow it to navigate its environment and retrieve files just-in-time, effectively bypassing the issues of stale indexing and complex syntax trees."

**windsurf-memories**
URL: https://docs.windsurf.com/windsurf/cascade/memories
Accessed: 2026-06-25
Quote: "For knowledge you want Cascade to reliably reuse, write it as a Rule or add it to AGENTS.md." (Auto-generated Memories are retrieved by model judgment "when relevant.")

**cline-memory-bank**
URL: https://docs.cline.bot/prompting/cline-memory-bank
Accessed: 2026-06-25
Quote: "After each reset, I rely ENTIRELY on my Memory Bank to understand the project... I MUST read ALL memory bank files at the start of EVERY task - this is not optional."

**claude-code-memory**
URL: https://docs.anthropic.com/en/docs/claude-code/memory
Accessed: 2026-06-25
Quote: MEMORY.md loads as an index at session start; topic files are read on demand when the model judges them relevant.

**devin-knowledge**
URL: https://docs.devin.ai/product-guides/knowledge
Accessed: 2026-06-25
Quote: "Devin retrieves Knowledge when relevant, not all at once or all at the beginning. Be sure to make your retrieval trigger highly relevant to the contents."

**letta-memory**
URL: https://docs.letta.com/guides/agents/memory-blocks
Accessed: 2026-06-25
Quote: Core Memory blocks are always in the context window; archival memory is retrieved only via an explicit archival_memory_search tool call.

**trigger-cursor-rules**
URL: https://trigger.dev/blog/cursor-rules
Accessed: 2026-06-25
Quote: "Auto Attached is the most reliable type... Agent Requested requires a very precise description that the model will actually match against its current task."

## SYNTHESIS

For this dotfiles research corpus, the decisive design choice is the retrieval half, not
the storage half. Put a non-optional "check `ai/research/INDEX.md` before web-researching"
instruction in always-on AGENTS.md (reaches Claude/Codex/Gemini via the existing include +
symlink), modeled on Cline's identity-framed imperative. Back it with a described, recency-
ordered INDEX.md so the agent orients in one pass. Do NOT rely on a description-triggered
skill (Claude-only, fuzzy) or on `ctx_search` alone (agent must choose to call it) as the
primary mechanism — both reintroduce the model-judgment failure this whole body of evidence
warns against. Treat FTS5/grep as the backstop, not the trigger.
