# Expert response to Memo 6 — ROUND 1 (first pass, before the autonomy correction)

> Archived verbatim for provenance. Round 2 (the final, more supportive response) superseded the
> human-audit stance here — see MEMO-6-IDEAL-MACHINE-EXPERT-CONVERGENCE.md. This round's substance
> (Tier 0 unsoundness, property-at-risk formula, router-as-control, batch-interaction) survived intact.

My verdict: the Memo 6 reframe is directionally right, but the design currently overclaims "deterministic
proof" in exactly the place where the whole thing becomes dangerous. The order-of-magnitude savings are real
only if Tier 0 means semantics-preserving transform with machine-checkable side conditions, not "AST-safe
transform + existing tests."

Central correction: Off-limits-ness should not be file identity. But proof strength is not enough either. The
right unit is: property-at-risk × transform class × proof strength. Auth code is not sacred. Security
properties are. The machine should not ask "is this file auth?" It should ask: what security/product invariant
could this diff affect, and does the proof actually cover that invariant?

1. "Off-limits = proof strength, not file identity" is mostly right but incomplete. File identity is a risk
   PRIOR, not an absolute prohibition. But "a byte-identical guard + targeted differential test = as safe on
   auth as a pure helper" goes too far — security behavior is often a NONLOCAL invariant (what happens
   before/after the guard, side effects before rejection, fail-closed, normalization-before-authorization,
   error-path info leak, caching/logging/audit/rate-limit changes, two guards jointly enforcing one property,
   async ordering, caller-observable error/timing/partial-result). Rule: a security-adjacent refactor may
   auto-land only if the proof covers the security PROPERTY at risk, not merely the local syntax.

2. Tier 0 is unsound if existing tests are the local safety oracle. (Most important attack.) Existing tests
   are a smoke signal, not a proof — the codebase already proved this (mutation testing found ~60% reliability
   in auth; §B judge was the real oracle when green tests missed drift). Tier 0 must mean: the TRANSFORM is
   proven safe under checked side conditions; tests are secondary. Requires codemod CERTIFICATION (formal-ish
   spec: allowed AST shape, forbidden hazards, postconditions; per-application proof packet; transform-level
   property/fuzz tests with side-effect sentinels; random Tier-2 shadow review; any failure demotes the
   transform version). Do NOT put hoist-shared-predicate / dedup-isomorphic-branch / flatten-nesting /
   early-return in Tier 0 until each has a certified side-condition checker (they can change eval order/count,
   short-circuit, throw timing, closure capture, this/arguments, TDZ, module-init order).

3. Trust can accrue, but only on COST, not on PROOF. Every Tier 0 change still passes deterministic
   preconditions every time; trust only reduces LLM review frequency. Trust accrues to transform version /
   router version / checker version / module family / test-harness version / model-prompt version — never to
   "the agent" globally. Zero observed failures bounds risk, does not eliminate it. Default: first 20 apps 100%
   shadow, next 100 at 20%, after 100 clean 5%; security/public-contract touchset ≥10% forever; any failure
   resets to 100%. Zero-review-forever is the wrong attractor.

4. The router is the new Goodhart target. It decides scrutiny → it is part of the evaluation system, not the
   maker. Maker cannot choose the tier; orchestrator cannot lower it. Router deterministic-by-default,
   versioned, prompt-locked, runs before AND after the diff; ambiguity escalates; random Tier-0→Tier-2
   escalation + seeded traps; router decisions enter the claim ledger. Separate ROUTE / PROVE / LAND / AUDIT.

5. Batch review is good, but batch INTERACTION is real. "Individually safe" ≠ "safe in combination" (cut A
   extracts a helper cut B modifies; two cuts touch the same closure boundary; import-topology drift;
   module-init reorder; grab-bag helper module). Rule: commit individually, prove individually, then prove the
   aggregate (tsc/tests/biome + import graph + no-two-cuts-same-symbol-unless-declared + set-level coherence).

6. Human audit cannot be zero for the hardest tier (ROUND-1 STANCE — SOFTENED IN ROUND 2). The one-upfront
   conversation is the right steering interface; do not force the human to enumerate off-limits files. But a
   nonzero standing audit channel is needed for controlled autonomy — as a control system (random+triggered),
   not a per-file gate. human_audit_rate=0 allowed only if honestly labeled "unattended, not controlled."

7. The 5M estimate is plausible only after ONE falsification experiment. Weakest premise: 70-80% of the 1,136
   flagged functions are genuinely Tier 0 under statically-checkable side conditions. Second: the checker has
   no blind spots. Third: cognitive-complexity excess points are the right backlog unit (the canon says
   metrics guide, not gate; the dynamic-import-cycle incident is the local proof of metric-chase churn on a
   non-defect). Cheapest experiment: sample 100 functions (40 top churn×complexity / 30 random flagged / 20
   security-storage-public-adjacent / 10 previously-refactored agent hotspots), route each, run cheap-proof
   AND expensive-§B shadow, record false-safe / false-expensive / token cost / REVISE rate / real complexity
   reduction. Thresholds: T0 eligibility <50% ⇒ 5M likely false; any T0 false-safe ⇒ narrow T0. Build only the
   top 3 codemods first.

8. A should NOT optimize "95% under threshold" as the goal — that becomes a new metric chase. True target:
   reduce owned attention complexity in high-churn/high-risk/high-concept-value areas while preserving
   behavior. Some high-complexity functions are cold/essential/generated/boundary-shim/domain-table/temp-compat
   and should be classified acceptable, not churned.

9. The A→B seam is real but only as a HYPOTHESIS generator. A decomplected seam may reflect true domain
   concepts OR accidental implementation constraints / storage quirks / historical layering / perf / testability
   / framework artifacts / a deliberate facade. Emit a Seam Hypothesis Packet (extracted concept, behavior
   evidence, public-contract nouns, mismatch suspicion, alternative explanation, B recommendation). Not proof
   the contract is wrong.

10. Next build = NOT one-or-the-other. Build A-minimum (3 codemods, router v0, proof-packet schema,
    100-function falsification sample, Tier-0 shadow-reviewed by §B, batch proof on one module) AND B-minimum
    (public-contract inventory: route|OpenAPI|MCP|error|grant-model|tests|docs|impl-concept-names; seam-hypothesis
    collector from A; B judge: mismatch-candidate | implementation-only-seam | unclear; no auto-land,
    human-ratified proposals only). B does not block A; B prevents A from becoming blind internal polish.

11. Strongest case against heavy A investment: A preserves current behavior — if current behavior encodes a
    confused public contract, A makes the wrong concept model cleaner, deeper, HARDER to change. Not an argument
    to stop A; an argument against driving A to 95% before measuring B. (+ diminishing returns, proxy risk,
    contract drift, human-value mismatch, false confidence.)

Bottom line: ceremony ∝ residual risk is correct; the safe version is stricter — residual risk falls only when
the proof covers the PROPERTY at risk, not merely because a transform is common, tests pass, or prior similar
changes worked. Build it, but run the falsification experiment first; if the 100-function sample shows most
candidates are genuinely certified Tier 0 with no false-safe, 5M is credible; else the honest floor is
20-50M and the right response is to narrow Tier 0 and use A as a high-leverage seam generator, not a
threshold-clearing machine.
