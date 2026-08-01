---
title: "An always-on 'capture research' instruction is unreliable: it only reaches sessions started after it was added, and capture-at-the-end is the weakest moment — enforce with a PreCompact/SessionEnd hook"
date: 2026-06-26
topic: agentic-context-design
tags: [research-corpus, capture, precompact, hook, instruction-reliability, mid-session-staleness]
status: settled
sources: [observed-2026-06-26, cc-prompt-caching-entry, retrieval-reliability-entry]
source_session: unknown
---

## CLAIMS

- Editing AGENTS.md/CLAUDE.md does NOT apply to an already-running session — the @-included instructions are baked into the system prompt at session start and not re-read until /clear, /compact, or restart. So a long-lived session operates on whatever the file said when it launched. [cc-prompt-caching-entry, observed-2026-06-26]
- Consequence: a research-capture rule added mid-stream reaches only sessions that START after it was committed; concurrently-running agents never see it until they restart. (Observed directly: this session predated the corpus-rule commit, so the capture instruction was never in its loaded prompt — the "missed capture" was absence-of-instruction, not instruction-ignored.) [observed-2026-06-26]
- Even when loaded, capture is the LESS reliable half of the corpus rule: retrieval ("check the corpus first") fires at session START when context is fresh and is reliable; capture ("write findings after") fires at the END when the agent is winding down / under task pressure / near compaction — the weakest moment for instruction-following. The asymmetry is structural. [retrieval-reliability-entry, observed-2026-06-26]
- For sessions run across MANY compactions, SessionEnd is the wrong primary trigger: long sessions rarely "end," and early-session research is summarized away at the first compaction before any SessionEnd fires. The risk concentrates at COMPACTION. [observed-2026-06-26]
- Claude Code exposes a PreCompact hook that can inject context before compaction; it is the correct enforcement point — it fires at each compaction (catching research throughout a long session) AND compaction re-reads CLAUDE.md, so it is also a natural instruction re-sync moment. SessionEnd/Stop is a backstop for short sessions that never compact. [observed-2026-06-26, cc-prompt-caching-entry]
- Hooks beat the instruction for reliability on BOTH failure modes: they are read fresh from settings.json (not baked into a session's prompt at launch, so they reach already-running-style behavior on next compaction) and they fire deterministically (not dependent on the model choosing to comply). [retrieval-reliability-entry]

## SOURCES

**observed-2026-06-26**
URL: local — this session (c0dad57d), 2026-06-26
Accessed: 2026-06-26
Quote: Agent did extensive research but did not capture all of it; root cause was the session predating the corpus-rule commit (bb333e1) so the capture instruction was never loaded. User asked whether other agents will reliably capture — exposing the instruction-only reliability gap.

**cc-prompt-caching-entry**
URL: ai/research/agentic-context-design/claude-code-conditional-context-injection-hook-mechanics.md
Accessed: 2026-06-26
Quote: Editing CLAUDE.md does NOT apply mid-session (baked into the cached prefix until /clear, /compact, or restart); PreCompact and SessionStart can inject context; Stop is capture-only.

**retrieval-reliability-entry**
URL: ai/research/agentic-context-design/agents-retrieve-knowledge-via-always-on-instruction-not-model-judgment.md
Accessed: 2026-06-26
Quote: Always-on instruction beats model-judgment; but model-judgment compliance is non-deterministic — the reliable channel is deterministic injection (hooks) or always-on standing procedure, not after-the-fact recall.

## SYNTHESIS

The corpus's RETRIEVAL half (check INDEX before researching) is reliable as a standing
instruction — it fires up-front. The CAPTURE half is not, for two compounding reasons:
mid-session staleness (only new sessions get the rule) and end-of-task timing (weakest
compliance moment). For a user who runs sessions across many compactions, the fix is a
PreCompact hook that nudges "capture any research to ai/research/ before this context is
compressed," plus a SessionEnd/Stop backstop. The hook is read fresh from settings.json and
fires deterministically, fixing both failure modes the instruction can't. Keep the always-on
instruction too (it's cheap and covers fresh sessions), but do not rely on it alone for
capture. This is the capture-side analogue of the dogfooding detector: instrument the moment,
don't trust after-the-fact introspection.
