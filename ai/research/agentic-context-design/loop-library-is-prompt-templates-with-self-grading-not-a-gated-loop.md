---
title: "Forward Future's Loop Library is a prompt-template pack with self-rated termination, not a gated/measured maker-checker loop"
date: 2026-06-27
topic: agentic-context-design
tags: [agent-loops, refactoring-loop, competitive, self-grading, prior-art]
status: draft
sources: [loop-library]
source_session: 019f769c-f0bc-74c3-a41e-501dcc3c498a
---

<!--
Competitive assessment done in-session against our gated refactoring loop. Captured so we
don't re-evaluate it and so the structural distinction (self-grade vs oracle-gated) is durable.
-->

## CLAIMS

- The Loop Library (signals.forwardfuture.com/loop-library) is distributed as a pack of ~70 copy-paste prompt templates ("loops"), installable via `npx skills add`, oriented around ergonomic reuse of good prompts rather than enforced control flow. [loop-library]
- Its termination/quality mechanism is model self-grading: loops instruct the agent to "run autoreview" or iterate "until you are happy" / "until it looks good" — i.e. the agent decides when it is done by rating its own output. [loop-library]
- It has no separate different-model checker, no deterministic oracle (un-fakeable facts like tsc exit code / test pass-count / diff-check), and no fail-closed gate; correctness rests on the same model that produced the work judging the work. [loop-library]
- Its ergonomics are better than a hand-rolled loop: one-command install, a browsable catalog, consistent template shape — the distribution layer is more polished than our bespoke waspflow + dispatcher scripts. [loop-library]

## SOURCES

**loop-library**
URL: https://signals.forwardfuture.com/loop-library
Accessed: 2026-06-27
Quote: (assessed in-session; catalog of ~70 prompt "loops" installed via `npx skills add`, with self-review/"until you're happy" termination language)

## SYNTHESIS

This is the naive sibling of the gated refactoring loop. The substantive gap is the
termination condition: "until you are happy" is the exact non-checkable self-grade our
loop was built to eliminate — see
[[procedural-md-spec-as-agent-loop-control-flow]] (the hard problem is converting
"is this ideal?" into checkable structural conditions) and
[[refactoring-loop-as-skill-plus-workflow-composition]] (enforcement is structural —
separate different-model checker + real oracle — not skill prose). A model that
self-grades will rate plausible-but-wrong work as done; that is the under-reach /
sycophancy failure mode documented in
[[ai-generated-code-smells-and-when-agents-act-contrary-to-refactoring-goals]].

What Loop Library does better is **distribution**: `npx skills add` + a browsable catalog
beats our bespoke scripts on adoption ergonomics. The right synthesis is to keep our
substance (deterministic oracle + maker/checker model split + fail-closed gate + two-model
design gate) and borrow its packaging — ship the loop as an installable skill, not a pile
of worktree-local scripts. Do NOT adopt its self-grade termination; that is precisely the
property we removed.
