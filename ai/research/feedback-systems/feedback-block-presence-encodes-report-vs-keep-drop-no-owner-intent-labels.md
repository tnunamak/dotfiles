---
title: "A tool's feedback-block presence is the only provenance the dogfooding system needs; owner/intent labels are incidental complexity"
date: 2026-06-25
topic: feedback-systems
tags: [dogfooding, roster, hickey, simplicity, code-review, decision]
status: settled
sources: [codex-hickey-review-2026-06-25, dogfooding-v1-decision]
---

## CLAIMS

- The behavioral distinction between trialing your own tools (report to improve them) and others' tools you just wanted to try (mainly keep/drop/tweak, sometimes feedback) collapses to ONE fact: is there a maintainer/destination to report to. [codex-hickey-review-2026-06-25]
- Encoding that fact as the PRESENCE of an optional `feedback:` block (maintainer + ledger) makes `owner` and `intent` fields redundant: a `feedback` block present => report there; absent => private keep/drop/tweak signal. [codex-hickey-review-2026-06-25]
- `owner` (mine|circle|external), `intent` (improve|evaluate), and `feedback` are not three independent axes — they are one distinction (external-reporting vs private-evaluation) wearing three names; keeping all three invites drift (e.g. intent:improve with no feedback, intent:evaluate with a maintainer). [codex-hickey-review-2026-06-25]
- The nudge message must be DESTINATION-aware, not intent-aware: branch on whether `feedback.ledger`/`feedback.maintainer` are actually present, not on a separate intent label — otherwise a missing ledger/maintainer produces a malformed "note it in <ledger> for <maintainer>". [codex-hickey-review-2026-06-25]
- Pre-adding inactive stub entries for unverified tools (waspflow/darshana/clawmeter/pdpp) is speculative complexity: the research requires per-tool empirical verification of invocation + friction shape, and empty stubs create a false sense a tool is "in the system" when it is not watchable. Add a tool only after observing one real command shape + one high-signal friction pattern. [codex-hickey-review-2026-06-25]
- Correctness fix this surfaced: the nudge's original grep/sed ledger lookup was block-unbounded (a tool with no ledger could steal the next tool's) and could not reliably read a nested `feedback.ledger`; it was replaced with a structured python+yaml read (legacy top-level `ledger` kept as fallback). [codex-hickey-review-2026-06-25]
- The detector needs NO change for any of this: friction capture is identical regardless of who built the tool; provenance only affects the SessionStart nudge text. [dogfooding-v1-decision]

## SOURCES

**codex-hickey-review-2026-06-25**
URL: local — ~/.tmp/dogfooding-review.md (Codex gpt-5.5 high review, correctness + Rich-Hickey incidental-complexity pass, 2026-06-25)
Accessed: 2026-06-25
Quote: "owner, intent, and feedback are not three independent axes in this plan. They are one behavioral distinction wearing three names: external reporting versus private evaluation. Keep the behavior-bearing data; cut the labels... The nudge branch should not be 'intent-aware'; it should be 'destination-aware'."

**dogfooding-v1-decision**
URL: ai/research/feedback-systems/dogfooding-feedback-build-simpler-v1-not-generalized-system.md
Accessed: 2026-06-25
Quote: per-tool config belongs in roster.yaml; the detector is generic; add tools only when their command/friction shape is verified.

## SYNTHESIS

Shipped roster shape: optional `feedback: {maintainer, ledger}` per tool; nothing else
for provenance. Devspecs has one (→ Brennan); a private trial tool simply omits it. The
nudge reads the block via structured YAML and branches on what's present (ledger? maintainer?).
No `owner`, no `intent`, no inactive stubs. This is the general lesson for this whole tooling
line: when a "configuration" field doesn't change behavior, it's incidental — cut it. Reach
for a reviewer's Hickey pass (essential vs incidental; is this fact derivable from another?)
before adding schema. The user explicitly didn't care about `owner` — that disinterest was
the tell that it wasn't load-bearing.
