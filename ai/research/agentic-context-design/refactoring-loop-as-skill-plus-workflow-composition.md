---
title: "A gated refactoring loop is built as a general engineering-loop skill + a task-profile skill + a Workflow that enforces maker/checker structurally"
date: 2026-06-26
topic: agentic-context-design
tags: [loop-engineering, refactoring, skills, workflow, maker-checker, fail-closed, evidence-contract]
status: draft
sources: [osmani-loop-engineering, anthropic-harness-design, build-decision-2026-06-26]
source_session: 31191f1e-53d2-44fa-b202-edce7889b4a4
---

## CLAIMS

- Enforcement of a high-stakes agent loop must be STRUCTURAL (separate subagents + real tool oracle + gated control flow), not prose; a skill is READ and can be ignored, so the fail-closed gate cannot live in skill text. [osmani-loop-engineering][anthropic-harness-design]
- A refactoring loop decomposes into THREE artifacts with a clean seam: (A) a general `engineering-loop` skill = task-agnostic machinery + invariants + a universal evidence contract; (B) a `refactor-loop` task-profile skill that fills A's contract slots; (C) a Workflow script that runs the loop so the maker and the DIFFERENT-MODEL checker are separate agent() calls and transitions are code, not narration. [build-decision-2026-06-26]
- The universal evidence contract (owned by Layer A, filled by Layer B) is: stop_condition (verifiable), oracle (exact commands), checker (model+role+required evidence artifact), acceptance_level, discovery (find+rank+CLASSIFY incl. no-go), memory (reject ledger shape), owner_gate, cleanup, fail_output. [build-decision-2026-06-26]
- The checker must produce an EVIDENCE ARTIFACT — read the diff (not the maker's summary), run the oracle, machine-verify specific claims (e.g. caller counts), write a verdict — because different-model-without-evidence is rubber-stamp theater. [anthropic-harness-design][build-decision-2026-06-26]
- The loop's honest outputs are: a PR + truth-cheap evidence packet, OR one sharp design question, OR a verified non-finding ("nothing safe cleared the bar"); a non-finding is first-class but only valid after real measurement + adversarial check. [build-decision-2026-06-26]
- The ambition check is a required gate: a safe-small change when the ask was "most impactful" is a FAILURE, not a win (the failure mode that motivated building the loop). [build-decision-2026-06-26]
- Build the concrete embodiment first and extract only the general machinery it proves; do not build a generic framework first, and do not multiply named surfaces (reuse collapses machinery). [osmani-loop-engineering][build-decision-2026-06-26]

## SOURCES

**osmani-loop-engineering**
URL: https://www.oreilly.com/radar/loop-engineering/
Accessed: 2026-06-26
Quote: "The most useful structural thing in a loop, by far, is splitting the one who writes from the one who checks." (and: a skill is "intent written down on the outside ... the agent reads it every run")

**anthropic-harness-design**
URL: https://www.anthropic.com/engineering/harness-design-long-running-apps
Accessed: 2026-06-26
Quote: "When asked to evaluate work they've produced, agents tend to respond by confidently praising the work—even when, to a human observer, the quality is obviously mediocre."

**build-decision-2026-06-26**
URL: (internal) tmp/workstreams/refactor-loop/PLAN.md + CODEX-CAPTURE-CHECK.md
Accessed: 2026-06-26
Quote: Plan ratified by owner + independently capture-checked by a different model (Codex gpt-5.5); the three-artifact A/B/Workflow decomposition and the nine invariants are the agreed design.

## SYNTHESIS

The artifacts: `ai/skills/local/engineering-loop/SKILL.md` (A), `ai/skills/local/refactor-loop/SKILL.md` (B), `<repo>/.claude/workflows/refactor-loop.js` (C). The seam: B references A and fills its slots; A has zero refactoring knowledge; C is the enforcement that the skills describe.

Why three pieces and not one skill: the research is unambiguous that a skill is *knowledge the agent reads*, which the agent can rationalize past — so the fail-closed maker/checker gate has to be *structural* (separate agent() calls, a different-model checker, a real oracle whose pass/fail you can't override). The Workflow is that structure. The two skills supply the knowledge those actors operate under.

Reuse path: future loops (triage, test-writing, deploy/MCP/connector/UI, waspflow lanes) reuse A unchanged, write their own task-profile skill filling the same contract slots, and write their own Workflow (or parametrize one). The general layer was EXTRACTED from the concrete refactoring build, not designed in the abstract — which is both the methodology's rule (extract deep modules from real use, don't pre-abstract) and the loop-engineering canon's ("extract only the general machinery proven by the embodiment").
