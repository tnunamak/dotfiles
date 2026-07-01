---
title: "The project-quality portfolio machine — the converged full-build doctrine (post-falsification)"
date: 2026-07-01
topic: code-quality
tags: [code-quality, refactoring, autonomy, portfolio, tier-mass, stopping-condition, slvpq]
status: converged (owner + 3 expert rounds + a real falsification experiment); THIS supersedes the
        codemod-centric framing in MEMO-6-IDEAL-MACHINE-EXPERT-CONVERGENCE.md
supersedes_center_of: MEMO-6-IDEAL-MACHINE-EXPERT-CONVERGENCE.md
sources: [MEMO-7-falsification-data-kills-the-mechanization-thesis, RAW-expert7-response-round3-portfolio-machine,
          MEMO-6-IDEAL-MACHINE-EXPERT-CONVERGENCE, own-rent-delete-the-attention-perimeter-objective-function,
          SLVPQ-OPERATIONALIZATION, CANONICAL-CODE-QUALITY-THEORY.phase1]
---

# The project-quality portfolio machine

This is what the code-quality machine should BE, after a real falsification experiment killed the codemod-centric
thesis (`MEMO-7`) and three expert rounds converged on a portfolio design + a reconciled stopping condition.
It KEEPS the Memo-6 principles (ceremony ∝ residual risk; `property-at-risk × transform-class × proof-strength`;
Tier-0 = certified transform not tests; router as a deterministic control component; trust accrues to
mechanisms; A behavior-preserving / B behavior-changing; falsify-before-fan-out) but REPLACES its CENTER: the
machine is NOT a codemod machine. `MEMO-6-IDEAL-MACHINE-EXPERT-CONVERGENCE.md` remains valid for those
principles; THIS file overrides its "Tier-0 codemods are the ~70-80% bulk" premise, which is measured false.

## 0. The finding that forced the re-scope (measured, not estimated)

`falsify.mjs` + `resolve-anon.mjs` (deterministic, read-only, sweep branch) over the whole owned core (1,139
flagged fns / 167 files / 8,406 excess-cc points) measured tier MASS (Σ excess-cc, the owner-attention proxy),
not just count:

```
tier            %fns    %excess-mass
T1-seam        14.4%       26.4%
capturing-closures/anon 22.0%  23.6%   (0 of 53 iterator-callbacks cleanly extractable — all capture scope)
T2-property    10.9%       19.4%
T0 (mechanical) 41.8%      16.3%   ← the cheap safe tier holds the LEAST mass
T2-async       10.9%       14.4%
```

**~16% of complexity mass is reachable by a certified mechanical transform; ~84% is not** (capturing closures,
security guards, awaited-ordering, concept-seams). The 41.8%-by-count T0 is inflated by marginal cc-6/7
functions worth ~1-2 points. So the 130M→5M codemod story used the wrong denominator (count, not mass).

## 1. THE OPERATING PRINCIPLE (the strongest lesson)

> **Optimize owner-attention reduction per proof dollar — NOT cognitive-complexity points per token.**
> Cheap autonomy comes from routing work to the right proof class and refusing to spend effort on low-attention
> PROXY wins — not from proving most changes are mechanical.

## 2. THE MACHINE (portfolio, not codemod)

Budget direction (numbers movable, direction not): **B 40-50% · A2 judged decomplect 30-40% · T1 seam pilot
10-15% · T0 hygiene/prevention 5-10%.**

- **B — public-contract / product-surface evaluator + proposal generator (behavior-CHANGING; human-ratified).**
  The public contract (MCP shapes, error model, grant model a caller sees, pagination/projection, OAuth-facing
  concepts) is code quality (own-rent-delete §3, an absolute purity floor) but a design CHANGE, so it is queued,
  never auto-landed. Build B-minimum NOW (not later): inventory `route | OpenAPI | MCP | error | grant-model |
  tests | docs | impl-concept-names` + a seam-hypothesis collector fed by A + public-contract mismatch
  candidates → proposal packets. B does not block A; B stops A from becoming blind internal polish.
- **A2 — better-routed judged decomplecting for HIGH-ATTENTION owned complexity.** The existing expensive
  maker≠checker loop, but aimed at high-attention hotspots, NOT blanket threshold clearance. Full paranoia only
  on the T2-property/async tail.
- **T1 — seam-extraction, subclassed (do NOT assume cheap; run a pilot).** T1 is not one thing:
  - **T1a — cheap seam clarification** (name intermediate facts, split same-scope phases, extract a pure helper
    with explicit params, make implicit local concepts explicit). Proof: local-hunk + same eval order/count +
    no capture surprise + maybe one naming/seam judgment.
  - **T1b — explicit-context extraction** (where most real opportunity likely lives): a capturing closure is not
    un-extractable — it needs its implicit environment turned into an EXPLICIT context object / parameter
    bundle, then a named pure-ish function/module. This is the canon's "hidden state → explicit" and it is the
    right answer to the 84%-is-closures finding — but it is NOT T0 (needs concept judgment + behavior proof:
    capture inventory + param/context equivalence + no mutation-order change + differential/characterization +
    §B + batch coherence).
  - **T1c — T2 in disguise** (seam crosses async ordering / security / DB-transaction / OAuth-grant-consent /
    public error / cross-file contract) → full judged proof or B-proposal.
  ANSWER to "is T1 cheaper than T2?": ONLY when the seam is local + captures can be made explicit + eval
  order/count preserved + no security/async/txn/contract invariant at risk. Otherwise it collapses into T1b/T2.
  **The load-bearing experiment is 5-10 REAL T1b explicit-context extractions, not more theorizing.**
- **T0 — a RATCHET, not the engine.** Build ≤2-3 certified transforms, and only ones that ALSO prevent future
  slop: type-only-erasure (emitted-JS equivalence), trivial local-fact-naming (eval count/order provably
  unchanged), strictly-local if-inversion (certified side conditions), and a NO-HIGH-COMPLEXITY-ANONYMOUS-
  CALLBACK ratchet (a prevention rule, not a refactor). Do NOT build 15 codemods. Do NOT run the large
  false-safe experiment.

## 3. THE UPSTREAM FIX (possibly the single highest-leverage Memo-7 outcome)

The 84% concentrated in anonymous capturing `.map`/`.on`/`transaction` callbacks is very plausibly an
AI-BUILT-CODE SMELL (agents keep local state in sight, inline "just one more case," avoid committing to named
concepts until the function is a hairball — see the AI-code-smells corpus entry). So the fix is not only
downstream refactoring — add an UPSTREAM GENERATION RULE + a smell detector:

- **Generation policy:** agents must not introduce high-complexity anonymous callbacks; a callback exceeding a
  small cc threshold OR capturing more than N nonlocal names must be named, take an explicit context object,
  keep side effects visible, and carry a local contract/test if behavior matters.
- **Discovery ratchet (the callback/closure smell detector — likely more valuable than any T0 codemod):**
  `file | parent-fn | callback-kind | cc | captured-vars | captured-MUTABLE-vars | await-count |
  security/db/public-contract keywords | recommended-class (T1a/T1b/T2/B)`.

Preventing the distribution from regenerating may reduce future complexity more than downstream codemods ever
could.

## 4. THE STOPPING CONDITION (the reconciliation of the owner's "fully optimal" note)

The owner's terminal target is the FULLY OPTIMAL SLVP-ideal codebase — NOT "good enough for the critical mass"
(this is the standing bar: SLVP-ideal is the MINIMUM). The expert's "don't chase all functions under threshold"
meant "don't confuse a PROXY with the ideal," NOT "leave the long tail mediocre." Reconciled:

- **Terminal standard:** whole-codebase SLVP ideal.
- **Execution ORDER:** attention-weighted expected leverage (highest attention / risk / concept-value / churn
  first). "Low mass" ⇒ LATER unless cheap, blocking, or currently attention-costly — NEVER "not worth doing."
- **The ideal is NOT "every function under a biome threshold"** (thresholds are NOMINATORS; a cc-6 fn can BE
  ideal, a cc-4 fn can be slop). The ideal is: **every owned subsystem is EITHER (1) internally pure by the
  canon, (2) product-surface pure, (3) rented behind a pure boundary, (4) deleted, (5) quarantined/frozen/
  generated/compatibility-bound with an EXPLICIT justification, or (6) queued with a known reason it remains
  below ideal.**

> **THE DOCTRINE: Aim for 100. Sequence by leverage. Do not worship thresholds. Do not stop at critical mass.
> Every remaining imperfection must eventually be fixed, rented, deleted, quarantined, generated, frozen, or
> justified.**

## 5. THE MACHINE'S LOOP

DISCOVER (product-surface gaps · owned-complexity hotspots · callback/closure hairballs · async/security/
property-risk clusters · storage/backend contract seams · T0 hygiene) → CLASSIFY (B-proposal · A2 judged
decomplect · T1a · T1b · T1c/T2 · T0 ratchet · ignore/justify/quarantine) → RANK (expected SLVP-Q gain ×
owner-attention reduction × confidence × churn / (risk × proof cost) + B-seam value) → EXECUTE (B proposal-only
human-ratified · A2/T1/T2 behavior-preserving judged gates · T0 certified ratchet · prevention rules/linters) →
REPORT (claim ledger · mass reduced · high-attention concepts clarified · B seam-hypotheses emitted · remaining
JUSTIFIED complexity). Cognitive complexity is a NOMINATOR, not the backlog.

## 6. IMMEDIATE NEXT STEPS (expert round 3, ordered)

1. **Promote Memo 7 into a standing discovery instrument** — tier-mass by file + by subsystem, anon-callback
   hotspots, captured-identifier counts, async/security/property clusters, top-20 high-attention candidates.
   Upgrade router v0 from regex to AST/scope enough to TRUST classifications directionally (not to prove safety).
2. **Build the callback/closure smell detector + generation ratchet** (§3) — likely higher value than any codemod.
3. **Run a T1b pilot** — 5 high-mass capturing-closure candidates via explicit-context extraction; measure token
   cost, §B REVISE rate, real cognitive-load reduction, B-seam value. If T1b lands materially cheaper than T2 →
   build the seam accelerator. If not → route those to judged A2/T2 and stop calling T1 cheap.
4. **Build B-minimum now** (§2).
5. **Keep T0 as opportunistic cleanup** — ≤2-3 transforms, only if they also prevent recurrence.

The falsification experiment did exactly its job: it saved us from building an elegant machine for the wrong mass.
