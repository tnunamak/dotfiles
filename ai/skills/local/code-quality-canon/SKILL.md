---
name: code-quality-canon
description: "The canonical, source-grounded theory of what makes code high quality — a constitutional spec for coding agents. Use this skill for ANY non-trivial design, refactoring, decomposition, code-review, or 'is this good code / is this the right abstraction' decision, and whenever resolving a code-quality tradeoff (extraction vs locality, DRY vs decoupling, clever vs boring, FP vs pragmatic, elegance vs ship-and-survive, deep vs shallow modules, where to put a boundary). It indexes the full theory + primary sources on disk. The spine is PARADIGM-INDEPENDENT (simplicity + verification + explicit state — NOT 'use functional programming'). Triggers: 'is this high quality', 'should I extract/abstract this', 'refactor', 'decompose this god-file', 'is this the right boundary', 'review this design', 'reduce complexity', 'SLVP-Q', 'make this cleaner'."
---

# Code Quality Canon

The durable theory of code quality, source-grounded and de-biased (two research passes + an adversarial
counter-pass). Use it instead of reaching for personal taste, "Clean Code rules," or "it looks cleaner."

## How to use this skill

1. **For any non-trivial quality/design/refactor decision, READ the theory first:**
   `~/code/dotfiles/ai/research/code-quality/CANONICAL-CODE-QUALITY-THEORY.phase1.md`
   It is structured as a constitution — §1 Invariants (what quality IS), §2 Anti-goals (what it is NOT),
   §3 Operational protocol (the agent rules), §4 resolved tensions. Don't skim; the tensions are the point.
2. **Ground claims in the primary sources** (don't paraphrase from memory):
   `~/code/dotfiles/ai/research/code-quality/sources-collected/` — verbatim quotes from Carmack, King
   (parse-don't-validate), Knuth, Pike, Parnas, Ousterhout, Hughes, ISO standards, + the worse-is-better /
   DOD / decenter inputs.
3. **Apply the §3 hard rules** to your own work (these prevent the failure modes we've actually hit):
   - R1: verify the semantic DEFECT before refactoring a metric (don't churn code to move a number).
   - R2: behavior-preservation is a GATE — a refactor that changes observable behavior is a rewrite;
     prove preservation against the REAL system (incl. the right backend/integration, not just unit tests).
   - R3: the maker is not the judge — deterministic oracle + a DIFFERENT model for judged calls.
   - R4: prove the diff, don't narrate it. R5: decomplecting ≠ relocation (moving a blob ≠ abstraction).

## The spine (what to optimize — paradigm-independent)

> Verified behavior first. Reduce incidental complexity (decomplect — separate braided concerns: state⟂
> value, time⟂identity, policy⟂mechanism, domain⟂I/O, parsing⟂execution, unrelated reasons-for-change).
> Make state/effects explicit. Deep modules (small stable interface hiding real depth; shallow wrappers
> ADD complexity). Local reasoning. Honest names (a name is a compressed invariant — it must predict
> behavior). Fit code to the real DATA, not to a pretty abstraction (data-oriented). Prefer simple-that-
> ships-and-is-proven over elegant-that's-hard. **Simple (un-braided) is OBJECTIVE; easy (familiar) is
> taste — optimize the former.**

NOT the answer: "use FP," "make functions tiny," "maximize DRY," "fewer lines," "more design patterns."
FP/immutability is ONE tactic for explicit-state, not the essence. The paragons who write the most-admired
real code (SQLite, djb, Bellard, redis) are overwhelmingly imperative-C/pragmatic; what they share is
simplicity + verification + explicit state, not a paradigm.

## When NOT to over-apply
Quality is contextual (Invariant 11): weight the invariants by the actual constraints (a one-off script, a
hot path, a security boundary, a rules engine each pull different ways). Don't over-refactor; don't
manufacture abstractions; don't impose size thresholds. The metrics (LOC/cycles/complexity/coverage) GUIDE,
they don't GATE — the judged axes (right boundary? deep or shallow? decomplected or relocated?) gate.

## Related
- `cognitive-load` skill (the ~4-chunk working-memory basis for "leverage per cognitive load").
- `refactor-loop` / `engineering-loop` skills (the gated maker/checker loop that ENFORCES §3 in practice).
- `ai/research/code-quality/BOOK-LIST-FOR-TIM.md` (the deeper primary sources, when needed).

## Status
phase1 (theory). Promotes to CANONICAL-CODE-QUALITY-CANON.md once the last video/book quotes close (§7).
The THEORY is stable; only citation strength is pending. Phase 3 (operationalizing into an SLVP-Q metric +
design gate) is separate — see ai/research/code-quality/ for that work.
