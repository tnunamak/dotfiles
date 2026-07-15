---
title: "Operationalizing the code-quality canon: SLVP-Q as a GUIDE+GATE protocol, not a scalar score (phase 3)"
date: 2026-06-28
topic: code-quality
tags: [code-quality, slvpq, operationalization, metric, gate, agents]
status: phase3-draft
sources: [canonical-code-quality-theory-phase1, ray-2014-reanalysis, ai-code-smells-corpus]
---

# Phase 3 — operationalize the canon (CANONICAL-CODE-QUALITY-THEORY.phase1.md)

## THE GOVERNING CONSTRAINT (from the theory, §6 — do not fight it)
"Very little of code quality is mechanically measurable; popular metrics are weak proxies; rigid
thresholds backfire." So SLVP-Q is NOT a scalar score you compute and optimize. Trying to make it one
recreates exactly the failure the theory warns against (metric-gaming, clean-code-theater, the Ray-2014
folklore). SLVP-Q is operationalized as a TWO-TIER PROTOCOL:
- **GUIDE tier (mechanical, cheap, advisory)** — surfaces CANDIDATE problems; never gates, never scored as
  truth. A number moving is a hypothesis to investigate, not evidence of quality (Rule R1).
- **GATE tier (judged, model/human, load-bearing)** — the actual quality verdict, anchored to the
  Invariants. This is where the design gate + different-model review live (Rule R3).

## TIER 1 — GUIDE (mechanical signals; run them, but they only point, they don't judge)
| Signal | Tool | Points at (Invariant) | Honest caveat |
|---|---|---|---|
| static import cycles (dynamic-aware) | dependency-cruiser (viaOnly dynamic-import) | entanglement (3) | a cycle may be a non-defect (R1; dynamic-import corpus) |
| dead code / unused exports | knip | incidental complexity (2) | flags, doesn't fix |
| duplication | jscpd | DRY-vs-decoupling (anti-goal) | dup may be CORRECT (different reasons-to-change) |
| cognitive complexity (per fn) | biome/sonar cognitive-cx | cognitive load (4) | proxy; NOT the real load; thresholds backfire |
| type-escape count (any/as-any) | grep/tsc | constrain state-space (10) | type-honest ≠ well-designed |
| file/fn size | wc/lint | candidate god-files (decompose?) | size is NOT the defect; DEPTH is (Ousterhout) |
| test-to-code ratio + coverage | test runner | verification culture (13) | coverage ≠ behavior-preservation |
RULE: a GUIDE signal NEVER gates a change and NEVER counts as "quality improved." It only nominates a
spot to investigate. (R1: verify the semantic defect behind the metric before acting.)

## TIER 2 — GATE (the load-bearing verdict — judged against the Invariants)
A change passes the quality gate iff ALL hold (this is the design gate, applied per change/boundary):
1. **Behavior preserved (R2)** — proven against the REAL system (right backend/integration, not just unit
   tests). Deterministic oracle: compiler + tests + the relevant integration/real-backend run + diff-check.
2. **No new lie (R4/anti-goals)** — no new any/as-any/@ts-ignore/non-null-! to satisfy types; no weakened
   tests; the diff matches the claimed intent (prove the diff, don't narrate).
3. **Decomplected, not relocated (R5)** — if it claims an extraction/abstraction: concept is first-class
   (no internals left behind, no import-back, tight interface, consumers use the facade, the concept
   contract explains why each member belongs). A shallow wrapper / blob-behind-a-filename FAILS.
4. **Deep, not shallow (Invariant 6)** — a new module hides real depth behind a small interface; extraction
   is licensed by DEPTH, not size. Tiny-method theater FAILS.
5. **Concept-correct boundary (judged)** — the boundary cuts the real concept (a domain judgment) — gated
   by the TWO-MODEL design gate (Codex+Claude agree the boundary is right BEFORE code moves; R3).
6. **Names predict behavior (Invariant 9)** — new names are compressed invariants that hold.
7. **State/effects explicit (Invariant 8), data-fit (12) where relevant** — no new hidden state; for
   hot/data-heavy paths, fits the real data.
8. **Maker ≠ judge (R3)** — the verdict comes from the deterministic oracle + a DIFFERENT model, never the
   maker's self-grade.

## GATE UPGRADE — learned from a real failure (the grant-package extraction, 2026-06-28)
A decomposition passed all the deterministic gates (tsc/tests/anti-relocation-by-facade-grep) + was
self-declared "clean" — but a different-model judge (Codex) caught it was RELOCATION-PLUS-DUPLICATION: 4
internal helpers were COPIED (present in BOTH source and new module) and a parallel write-path survived in
the source. Tests passed BECAUSE both copies worked (duplication is invisible to behavior tests). Root
cause analysis yields three upgrades, each placed at its CHEAPEST viable detection layer (do NOT push
detection up the cost ladder — most of these failures were free to detect):

### LAYER MODEL (Codex-corrected — the three layers, each preventing a DIFFERENT failure):
- **PRE-CODE concept contract (§E)** PREVENTS wrong-cut builds — the CHEAPEST place (no code written yet).
- **POST-CODE deterministic gates (§A)** PREVENT relocation/duplication execution defects — free.
- **POST-CODE concept judge (§B)** VERIFIES the result is deep/concept-correct vs the contract — one call.
The original draft had only the 2nd and 3rd. The wrong-cut was VISIBLE PRE-CODE (the 16-dep seam, the
contract's stress fractures) — finding it only at the final diff already failed the cost model (maker
budget spent building a conceptually-invalid cut). So the load-bearing addition is §E, upstream.

### E. PRE-CODE HIDDEN-CONCEPT CONTRACT (the load-bearing fix — catch the wrong cut BEFORE the maker runs)
Before a decomposition maker runs, the concept contract MUST include (and the two-model gate MUST resolve):
1. Planned facade: exported functions + why each belongs to ONE concept.
2. Owned symbols: functions/state/tables to move (classified OWN/MOVE).
3. External dependencies: deps the module will RECEIVE, grouped by reason-for-change.
4. Stay-put symbols: intentionally not moved, with line citations.
5. **Shared-path inventory:** any helper used by BOTH the target concept AND the old source path.
6. **DEPENDENCY-CLUSTER TEST (the hidden-concept detector):** if ≥3 deps form a named lifecycle of their
   own, OR are reused by another major path, the contract MUST decide: extract THAT concept first / keep it
   external / explicitly rescope. (For grant-package: the 5 pending-request-validation + 4 binding-
   normalization deps were a hidden "resolve-grant-request-for-issuance" concept — this test catches it
   pre-code.) An UNCLASSIFIED dependency cluster HARD-BLOCKS the contract.
7. **Parallel-write-path inventory:** every old write/mutation path that will REMAIN in source after
   extraction (this would have flagged the staged-approval package-write path that survived).
8. **Expected anti-relocation checks GENERATED from the table** (§A is table-driven, not hand-authored).
Valid outcomes when a hidden concept is found: "extract hidden concept first" OR "rescope as partial
extraction" — NOT "plow ahead and let the final judge catch it." This is the cheapest place to catch wrong cuts.

### A. POST-CODE DETERMINISTIC SYMBOL/BODY GATE (gates; ~zero token cost — table-driven, NOT naive grep)
GENERATED FROM the resolved ownership table (§E.8), not hand-authored after the fact (the original
facade-only grep missed the duplicated internals BECAUSE it wasn't table-driven). For each symbol classified
OWN/MOVE:
- **No-duplication:** its BODY must be GONE from the source AND must NOT exist in both files. (External-dep
  and stay-put symbols are EXCLUDED — a legit shared dep staying in source is NOT duplication. Compat
  delegators require an explicit ALLOWLIST and must contain NO body logic.)
- **No-parallel-path:** the source must no longer call the concept's OWNED write/mutation ops outside the
  new module (callsites from §E.7's inventory).
- **Real move, not copy:** each moved symbol's net source change is a deletion or an allowlisted thin delegator.
- **Fail-closed on UNCLASSIFIED symbols** (a symbol not in the table is itself a contract gap).
These are DETERMINISTIC FACTS (a moved symbol in two files IS the defect, per R1 — not a proxy), so they
GATE. CAVEAT (Codex): they catch NAME-based duplication; renamed-copy / inlined-duplicate / a parallel path
hitting a lower-level generic DB op are FALSE-NEGATIVES — which is WHY §B (the judge) is still mandatory.
The greps are necessary, not sufficient.

### B. CONCEPT-CORRECTNESS JUDGE IS MANDATORY FOR DECOMPOSITIONS (not escalation-gated)
CRITICAL CORRECTION (this is where naive token-thrift would backfire): the duplication was a SYMPTOM; the
ROOT defect was a WRONG CUT — the module needed 16 injected deps because a hidden concept
("resolve-grant-request-for-issuance") was never extracted; we cut AROUND the tangle, not THROUGH it. NO
GREP REACHES THIS. Per the research (JudgeBench: judges are the untrusted-but-necessary link for the
semantic question; APoSD: depth is JUDGED not counted), concept-correctness is irreducibly judged. So:
- For a god-file/cross-file DECOMPOSITION, the different-model judge is MANDATORY — run ONCE on the FINAL
  diff. But its job is ADVERSARIAL VERIFICATION AGAINST THE §E CONTRACT, not discovering the concept from
  scratch: (a) did implementation match the resolved ownership table? (b) did any UNCLASSIFIED dependency
  cluster emerge that §E missed? (c) is the module deep/tight/first-class? (d) duplicate ownership or
  parallel paths? It is the RESIDUAL-miss backstop, NOT the primary wrong-cut detector (that's §E, pre-code).
- DIFF-SIZE GUARD (Codex): if the final diff is too large for the judge to inspect with high confidence,
  SPLIT the extraction or give the judge a summary + targeted raw hunks. "One judge call" becomes theater
  on a huge diff.
- For CHEAP MECHANICAL changes (rename, type annotation, one-line fix), the judge IS escalation-gated
  (deterministic gate suffices). Escalation-gating is right for mechanical work, WRONG for decompositions.

### C. SEAM-WIDTH: the COUNT is a prior; an UNCLASSIFIED CLUSTER hard-blocks (Codex-corrected)
A dep-count (or any size/count metric) NEVER auto-fails by number — count thresholds backfire (Ousterhout-
Martin; the 50-line-rule finding); depth/correctness is judged. BUT "never a gate" was too soft. The sharp
rule: a high dep-count is a PRIOR (raises attention); an UNCLASSIFIED DEPENDENCY CLUSTER or a shared
lifecycle (§E.6) HARD-BLOCKS the contract. The block is NOT the count — it's failing to classify the
cluster. (16 deps is not automatically wrong; 5-pending-validation + 4-binding-normalization deps reused by
single-grant-approval, left unclassified, IS — it's a hidden concept.)

### D. EVIDENCE, NOT NARRATION (forcing function; free — the R3/R4 fix for the maker-is-the-judge failure)
The proximate failure was the PIPELINE-AUTHOR narrating "landed clean" on a grep that confirmed what they
wanted, without reading the code. Fix: a decomposition is not "done" until a COMPLETION RECORD is filled
where each line is the PASTED STDOUT of the check that proves it — un-fillable without running the check.
A checkmark or a prose summary does NOT count (agents emit plausible summaries that diverge from the diff —
our own corpus). The evidence IS the command output. "Prove the diff, don't narrate it" turned into a gate
the author cannot skip.

### THE COST PRINCIPLE (corrected — catch each failure at its cheapest PREVENTION layer, not detection)
The key correction (Codex): the cheapest place to fix a WRONG CUT is PRE-CODE (§E), before the maker spends
budget — NOT at the final-diff judge. So:
- wrong-cut / hidden-concept → §E PRE-CODE contract + dependency-cluster test (cheapest: no code yet);
- relocation/duplication/parallel-path → §A FREE table-driven deterministic gate (post-code, ~free);
- residual semantic/depth miss → §B ONE judge call on the final diff (cheap vs maker work; mandatory for
  decompositions, escalation-gated for mechanical changes), as ADVERSARIAL VERIFICATION against §E.
Net token effect is NEGATIVE vs today: §E prevents building conceptually-invalid cuts (the biggest waste —
the grant-package maker burned a full context on a wrong cut), slicing avoids full-context retries, and the
judge verifies-once rather than discovers-the-concept-from-a-huge-diff. "If the hidden concept is only found
at final diff, the system already failed the cost model even if it avoids merge."

### F. OWNERSHIP-LEDGER CLOSEOUT + OLD-PATH INVENTORY (Codex — close the loop)
After implementation, EVERY row in the §E concept contract is marked moved / delegated / stayed-put, WITH
EVIDENCE (pasted check output, §D). The §E.7 parallel-write-path inventory is re-checked: each listed old
path is confirmed still-present-by-design or removed. This is the completion record — un-fillable without
running the checks; a checkmark is not evidence.

## WHAT "SLVP-Q WENT UP" HONESTLY MEANS (no scalar)
Not "the number rose." It means: a real semantic defect (entanglement / hidden state / shallow interface /
dishonest type / wrong boundary / mispredicting name / missing verification) was REMOVED, behavior
PRESERVED (proven), and the change PASSED the gate. Report it as: defect removed + evidence + gate result —
never as a score delta.

## THE DESIGN-GATE LEDGER (already built — wire it here)
The two-model design-gate verdicts get logged to the meta-eval ledger (waspflow lib/design-gate-ledger.sh):
verdict + eventual deterministic-oracle outcome → measures whether the JUDGE (the GATE tier) is reliable.
This is the JudgeBench discipline applied to our own gate (R3). The ledger is the closest thing to a
"score," and it scores the JUDGE, not the code.

## ANTI-PATTERNS THIS OPERATIONALIZATION FORBIDS (because the theory does)
- A single SLVP-Q scalar that agents optimize → metric-gaming (R1). FORBIDDEN.
- Gating on LOC/cycles/coverage/complexity thresholds → the backfire the theory documents. GUIDE only.
- "Tests pass + tsc clean ⇒ quality improved" → misses behavior regressions the unit tests don't cover
  (we lived this: a tsc-clean SQLite-green change broke Postgres). GATE requires the REAL-system proof.
- Self-graded "this is cleaner" → R3 forbids. Different-model + oracle required.

## NEXT (when applying to PDPP): the decomposition pilot
The revised decomposition pilot (Codex's REVISE verdict) is the FIRST application of this gate to a real
god-file. It now has a definition to gate against (this protocol) + the concept-contract / ownership-table
machinery Codex specified. That is where phase 3 meets the actual SLVP-Q campaign on pdpp.
