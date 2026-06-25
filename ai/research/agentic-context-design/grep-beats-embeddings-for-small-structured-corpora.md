---
title: "Grep/keyword search beats embeddings for small structured text corpora; embeddings only earn their keep at scale"
date: 2026-06-25
topic: agentic-context-design
tags: [retrieval, grep, embeddings, rag, aider, cody, search]
status: settled
sources: [augment-grep, aider-repomap, cody-context, basic-memory, anthropic-context-eng]
---

## CLAIMS

- On SWE-Bench, embedding models did not significantly improve agent performance because repos were small enough for grep/find, code was structured with distinctive keywords, and agent persistence compensated for simpler tools. [augment-grep]
- Embeddings start earning their keep only when the corpus is too large for grep to scan quickly, content is natural-language-heavy with fuzzy synonyms, or cross-document conceptual queries are needed with no shared keyword; none of these hold for a corpus of dozens of structured markdown files. [augment-grep]
- Aider builds context from a tree-sitter AST + PageRank over the import/use graph, trimmed to fit the window, and sends it every request — no embeddings at all; its author chose this over RAG because code relevance is about call graphs and type dependencies, not prose similarity. [aider-repomap]
- Sourcegraph Cody uses keyword search + a structural code graph as primary retrieval signals rather than embeddings alone. [cody-context]
- Basic Memory (markdown + MCP) uses full-text search and explicit read tools with no embeddings or vector DB, confirming FTS + filename-addressable notes is the preferred architecture for structured markdown corpora. [basic-memory]
- Aider loads CONVENTIONS files unconditionally (the `read:` key) as always-on read-only context, and shorter files produce better adherence. [aider-repomap]

## SOURCES

**augment-grep**
URL: https://jxnl.co/writing/2025/09/11/why-grep-beat-embeddings-in-our-swe-bench-agent-lessons-from-augment/
Accessed: 2026-06-25
Quote: "embedding models didn't significantly improve performance because: (1) the repositories were relatively small, making grep and find sufficient; (2) the code was highly structured with distinctive keywords... (3) the agent's persistence compensated."

**aider-repomap**
URL: https://aider.chat/docs/repomap.html
Accessed: 2026-06-25
Quote: Repo map = tree-sitter symbol extraction + PageRank-style ranking over import/use edges, trimmed to fit context, sent with every request (no embeddings). Conventions via the `read:` config key load always-on.

**cody-context**
URL: https://sourcegraph.com/docs/cody/core-concepts/context
Accessed: 2026-06-25
Quote: Cody layers keyword search, the Sourcegraph structural search API, and a code graph rather than relying on embeddings alone.

**basic-memory**
URL: https://github.com/basicmachines-co/basic-memory
Accessed: 2026-06-25
Quote: Pure markdown + MCP; exposes write_note/read_note/search_notes with full-text search and no embedding pipeline.

**anthropic-context-eng**
URL: https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
Accessed: 2026-06-25
Quote: Just-in-time retrieval with glob/grep bypasses stale indexing; up-front context (CLAUDE.md) + agentic search is the hybrid.

## SYNTHESIS

This entry is the evidence base for the corpus's "no embeddings, no vector/graph DB, no
external memory engine" decision (see README.md "Deliberately NOT here"). For a dozens-of-
files markdown corpus, grep + filename-as-claim + `context-mode` FTS5 is strictly the right
tool; adopting Mem0/Letta/Zep/Cognee/Basic-Memory as a dependency would add ingestion,
embedding, or service overhead for zero measured benefit at this scale. Reassess only if the
corpus grows past ~100 entries or starts holding fuzzy natural-language content without
greppable keywords.
