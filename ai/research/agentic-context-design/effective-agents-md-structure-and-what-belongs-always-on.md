---
title: "Effective AGENTS.md: keep it under ~200 lines, critical rules first/last, reference+procedures+trials out of always-on context"
date: 2026-06-26
topic: agentic-context-design
tags: [agents-md, system-prompt, context-engineering, instruction-following, lost-in-the-middle, prompt-structure]
status: settled
sources: [cc-memory-docs, lost-in-middle, anthropic-context-eng, anthropic-steering-2026, openai-prompt-guide, anthropic-xml, ifeval, anthropic-clear-direct, windsurf-agents-md, anthropic-long-context]
source_session: 019f6667-cca5-7712-b037-e522dd6f59b8
---

## CLAIMS

- Anthropic documents a concrete adherence cliff: "Files over 200 lines consume more context and may reduce adherence" — trim or path-scope content not needed every session. [cc-memory-docs]
- "Lost in the Middle": models best use information at the very start and very end of a long context and significantly underuse the middle (U-shaped curve, shown across GPT-3.5/4, Claude, LLaMA) — so the most important behavioral rules belong in the first or last ~10 lines, not buried mid-file. [lost-in-middle]
- Anthropic: "Put your instructions at or near the beginning of the long context prompt"; recommended order is role/identity → context/documents → task instructions. [anthropic-long-context]
- Anthropic's "Steering Claude Code" (2026) names three CLAUDE.md anti-patterns by content type: a multi-line PROCEDURE belongs in a skill; "every time X always do Y" belongs in a HOOK (settings.json); "never do this" guardrails belong in hooks/permissions (deterministic), not prose. [anthropic-steering-2026]
- AGENTS.md is for FACTS true on every task (build commands, layout, conventions); procedures, reference material, and sometimes-relevant workflows belong in skills / path-scoped rules / imported files. [anthropic-steering-2026, cc-memory-docs]
- Prompt caching cuts the DOLLAR cost of a stable prefix to ~near zero after the first request, but NOT the attention cost — a cached prefix still occupies its tokens in every turn's attention computation, so signal dilution is the real reason to trim. [anthropic-steering-2026, anthropic-context-eng]
- Attention is a finite budget that degrades with total tokens (n² pairwise relationships; "context rot"), so every always-on line competes with the current task's tokens — "smallest possible set of high-signal tokens." [anthropic-context-eng]
- Instruction-following degrades as constraints compound: per-instruction compliance is high in isolation but the all-instructions-followed rate drops measurably as instruction count grows (IFEval). [ifeval]
- Contradictory rules are NOT averaged: "If two rules contradict each other, Claude may pick one arbitrarily" — dedup and audit periodically; redundancy reads as noise, not emphasis. [cc-memory-docs]
- Positive imperatives beat negatives ("Use rtk git status" > "Don't run git without rtk"); concrete beats abstract ("Run npm test before committing" > "test your changes"); a single concrete counterexample can outweigh several abstract rules. [anthropic-clear-direct, openai-prompt-guide]
- Separate scopes belong in separate files: user-scoped preferences (~/.claude/CLAUDE.md), project facts (./AGENTS.md), local/gitignored (CLAUDE.local.md); mixing personal prefs into a shared AGENTS.md injects them for every agent/teammate reading it. [cc-memory-docs]
- Use markdown headers and/or XML tags to separate INSTRUCTIONS from CONTEXT/REFERENCE so the model knows what to follow vs consult; `@`-imports modularize a monolith into focused files. [anthropic-xml, openai-prompt-guide, cc-memory-docs]
- Time-bounded/experimental instructions have no expiry in always-on files; put them where they auto-expire or delete cleanly (a hook, an @-imported file, or CLAUDE.local.md), not inline in AGENTS.md. [anthropic-steering-2026]

## SOURCES

**cc-memory-docs**
URL: https://docs.anthropic.com/en/docs/claude-code/memory
Accessed: 2026-06-26
Quote: "Files over 200 lines consume more context and may reduce adherence... If two rules contradict each other, Claude may pick one arbitrarily." Separates user/project/local scopes into different files.

**lost-in-middle**
URL: https://arxiv.org/abs/2307.03172
Accessed: 2026-06-26
Quote: U-shaped performance — models best use info at the beginning and end of long contexts; middle content is significantly underused.

**anthropic-context-eng**
URL: https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
Accessed: 2026-06-26
Quote: "As the number of tokens in the context window increases, the model's ability to accurately recall information decreases... smallest possible set of high-signal tokens." Cites Chroma context-rot (https://research.trychroma.com/context-rot).

**anthropic-steering-2026**
URL: https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more
Accessed: 2026-06-26
Quote: A 30-line procedure belongs in a skill; "every time X, always do Y" belongs in a hook; "never do this" needs a deterministic guardrail (hook/permission), not prose. Shared CLAUDE.md "grows the way any unowned config file does."

**openai-prompt-guide**
URL: https://platform.openai.com/docs/guides/prompt-engineering
Accessed: 2026-06-26
Quote: Canonical developer-message order Identity → Instructions → Examples → Context; markdown headers for sections, XML to delineate data from instructions.

**anthropic-xml**
URL: https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/use-xml-tags
Accessed: 2026-06-26
Quote: XML tags help Claude parse prompts that mix instructions, context, and examples; wrap each content type in its own tag.

**ifeval**
URL: https://arxiv.org/abs/2311.07911
Accessed: 2026-06-26
Quote: Verifiable-instruction benchmark; per-prompt (all-instructions-followed) compliance degrades as instructions compound.

**anthropic-clear-direct**
URL: https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/long-context-tips
Accessed: 2026-06-26
Quote: "Put your instructions at or near the beginning"; concrete imperatives over abstract ("Run npm test before committing" over "test your changes").

**windsurf-agents-md**
URL: https://docs.windsurf.com/windsurf/cascade/agents-md
Accessed: 2026-06-26
Quote: Root AGENTS.md = always-on; subdirectory = path-scoped; global rules capped at 6000 chars — the spec assumes a focused file, not a knowledge dump.

**anthropic-long-context**
URL: https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/long-context-tips
Accessed: 2026-06-26
Quote: Role → context → task-instructions ordering performs best.

## SYNTHESIS

Audit checklist for a long AGENTS.md, highest-leverage first:
1. Get under ~200 lines (documented adherence cliff). Ours was 213.
2. Critical behavioral rules in the first ~10 lines (Lost-in-the-Middle); reference material last or externalized.
3. By content type (Anthropic steering): PROCEDURE → skill; "always do Y after X" → hook (settings.json); "never do X" → hook/permission; REFERENCE/cheatsheet (e.g. RTK) → skill or @-imported file; FACTS-every-task → keep, compressed.
4. Split scopes: personal prefs → ~/.claude/CLAUDE.md; repo facts → ./AGENTS.md; trial/experimental → CLAUDE.local.md or a hook (auto-expire), not inline.
5. Dedup (contradictions resolve arbitrarily); positive imperatives over negatives; concrete over abstract; a counterexample over three abstract rules.
Applies directly to this repo: the RTK cheatsheet, the devspecs trial prose, and the "log to ledger after use" line are all anti-patterns by this rule (the last is already a hook now, so the prose is redundant). The durable, reusable output is a SKILL that enforces these rules whenever any agent edits AGENTS.md/system prompts — so contributions don't re-bloat the file.
