---
title: "The ideal near-autonomous decomplecting machine — converged design after two expert rounds"
date: 2026-07-01
topic: code-quality
tags: [code-quality, refactoring, autonomy, proof-based, tiered-codemod, trust-accrual, slvpq]
status: converged (owner + 2 expert rounds); NOT YET BUILT — falsification experiment gates the build
sources: [MEMO-6-ideal-autonomous-refactor-machine, RAW-expert6-response-round1, RAW-expert6-response-round2,
          own-rent-delete-the-attention-perimeter-objective-function, SLVPQ-OPERATIONALIZATION,
          ungameable-quality-budget-and-prioritization-for-agent-pipelines,
          auditing-the-orchestrator-not-just-the-change, discovering-and-prioritizing-codebase-defects-at-scale]
source_session: unknown
---

# The ideal near-autonomous decomplecting machine (converged)

This is the design the code-quality machine should become, after Memo 6 (`MEMO-6-ideal-autonomous-refactor-machine.md`)
and two expert rounds (`RAW-expert6-response-round1.md`, `RAW-expert6-response-round2.md`). It EXTENDS
`SLVPQ-OPERATIONALIZATION.md` (the §E→§A→§B gate) and serves the `own-rent-delete` objective function
(maximize product value ∧ minimize complexity-under-owner-attention, two purity floors). **It is not built yet.
A 100-function falsification experiment gates whether the cost thesis is real before any fan-out.**

## 0. The motivating failure (why the current machine is wrong, not just slow)

The overnight machine landed ~35 behavior-preserving cuts, but at ~150k tokens/cut and ~13.6k tokens per
cognitive-complexity-point — extrapolating to the whole owned core (1,136 flagged functions, 13,899 excess cc
points) is **~130M tokens**. That cost profile says the process ARCHITECTURE is wrong: the machine has ONE
GEAR (maximum-paranoia adversarial maker≠checker+fuzz) applied to 100% of the work, including trivial
if/else inversions. A real senior team calibrates scrutiny to risk, codemods the mechanical bulk, and lets
trust accrue so scrutiny drops as evidence accumulates. Re-priced under that structure: **~5M target, ~3M
floor** — IF the cost reduction comes from stronger proof, not from trusting tests or agents.

## 1. THE GOVERNING FORMULA (the expert's core correction, both rounds)

> **Ceremony ∝ residual risk. Residual risk falls ONLY when the proof covers the PROPERTY at risk —
> not because a transform is common, tests pass, or prior similar changes worked.**
>
> The routing unit is **`property-at-risk × transform class × proof strength`** — NOT proof-strength alone
> (Memo 6's framing, too broad) and NOT file-identity (the old RED-tier rule, too coarse).

Filename is a **risk PRIOR** (raises the proof burden), never a prohibition. **No file is sacred; properties
are.** Auth code is not off-limits — but a byte-identical guard only proves safety when the security invariant
is LOCAL to that guard. Nonlocal invariants (ordering relative to effects, fail-closed, normalization-before-
authorization, error-shape, side-effects-before-rejection, two guards jointly enforcing one property, async
ordering, projection/pagination exposing a denied field by another path) require the proof packet to NAME the
invariant and cover it. This is the single sentence at the top of the design:

> **Every reduction in oversight must be paid for with stronger, more specific evidence.**

## 2. The three tiers (population EARNED by proof strength, not ASSIGNED by filename)

- **Tier 0 — certified semantics-preserving transform under statically-checked side conditions.** NOT
  "AST-safe + existing tests" (unsound — this codebase already proved it: auth mutation score ~60%, §B was the
  real oracle when green tests missed drift; `deriveSpineSource` regression was skip-masked). Each transform
  carries a CERTIFICATION PACKET (allowed AST shape; forbidden hazards: this/arguments/super/new.target/
  getters/proxies/labels/break-continue-targets/closure-capture/TDZ/side-effect-imports/init-order/await-order/
  repeated-eval/throw-timing/runtime-shape; machine-checked side conditions; emitted-JS or AST-equivalence
  proof; transform-level property/fuzz tests with side-effect sentinels proving eval count+order+output+throws+
  side-effect-logs preserved; per-application proof receipt; shadow-review policy). Tests are SMOKE; the
  transform proof is the ORACLE.
- **Tier 1 — judgment on the SEAM, mechanical on the EXECUTION (one cheap LLM call).** LLM proposes the
  concept-split seam; a codemod executes it; Tier-0's battery proves it. Risk is in the seam CHOICE (a taste
  question, self-correcting — a bad seam yields a grab-bag the set-coherence review catches), not in behavior.
- **Tier 2 — full adversarial loop + property harness (the current expensive machine, RARE).** ONLY where
  behavior-preservation is NOT mechanically decidable, or the touched code's tests are measurably thin
  (mutation/coverage gap). Property-based differential harness (fast-check, RUN not narrated) + different-model
  skeptic + claim-ledger entry. It SHOULD cost real tokens — a human team also slows here.

**Start with 3-4 certified transforms, NOT 15** (expert round 2 §3). Born-Tier-0 candidates: TYPE_ONLY_ERASURE,
EXACT_MOVE (body-hash + symbol-hash + callsite/import/export equivalence + module-init safety),
LOCAL_BOOLEAN_FACT_NAMING (pure predicate, evaluated once, no calls/getters/effects), TRIVIAL_INVERT_IF_ELSE.
NOT born Tier 0 (need certification first): hoist-shared-predicate, dedup-isomorphic-branch, flatten-nesting,
early-return conversion, cross-scope extract-duplicated-block — they can change eval order/count/throw-timing/
closure-capture/init-order.

## 3. The router is a CONTROL component, not a maker helper (maker≠judge, fractal)

The router decides scrutiny → it decides its own oversight → it is the new Adversarial-Goodhart target (same
conflict as the agent-derived budget and the orchestrator-narrative — see `ungameable-quality-budget` and
`auditing-the-orchestrator`). Hard rules: maker cannot choose the tier; orchestrator cannot lower it; router is
**deterministic by default**, versioned, prompt-locked (any LLM component advisory only), runs BEFORE and AFTER
the diff; ambiguity escalates; a **random sample of Tier-0 routes is escalated to Tier-2** as ongoing
calibration; seeded traps exist; every router decision enters the claim ledger. Separate the phases:
**ROUTE** (classify property-at-risk + proof requirement) / **PROVE** (execute the required oracle) / **LAND**
(independent done-gate accepts the proof) / **AUDIT** (sample route/proof/claim behavior over time). If ROUTE
and PROVE collapse into one path, the system games itself.

## 4. Trust accrues to MECHANISMS, not agents; it reduces COST, not PROOF

Trust accrues to transform-version / router-version / checker-version / proof-packet-schema-version /
module-family / test-harness-version / judge-prompt-model-version — **never to "the agent" globally.** Trust may
reduce LLM-shadow-review frequency, human-spot-audit frequency, batch-review cost. Trust may NOT remove the
deterministic side-condition checks, the emitted-JS/AST proof, the per-application receipt, the claim-ledger
entry, or the router classification. Tripwires (fail-loud): any §B REVISE, any post-merge regression, any
transform-code change, any router-code change → reset that mechanism's trust to 100% shadow. Touching
auth/storage/public-contract raises the sampling floor. Zero observed failures BOUNDS risk; it never proves
"safe forever."

## 5. Batch review: prove BOTH individual and aggregate

Commit individually (each independently revertable), prove individually, THEN prove the aggregate. Batch proof:
each commit has its own receipt + aggregate tsc/tests/biome + import-graph + module-init-order check + no two
cuts modify the same symbol/import/closure boundary unless declared dependent + no helper module becomes a
grab-bag + set-level coherence (the grab-bag REVISE was only ever caught by considering the set, not the atom).
Batching key = risk-tier × pattern homogeneity. It reduces FIXED review cost; it does not remove aggregate
review.

## 6. Autonomy: human audit is a MODE SETTING, not a per-change gate (the round-1→round-2 shift)

The owner's intent (verbatim): "pretty much fully autonomous outside of potentially one up-front discussion...
we shouldn't overprescribe/overspecify that." Round 1 leaned toward a mandatory nonzero standing audit; **round
2 corrected to the owner's position**: human audit is a MODE SETTING, not a routine workflow gate. Two modes:
- **Controlled** — low/very-low random sampling per tier + 100% on: disagreements, new-transform promotion,
  router change, dependency adoption, behavior-changing public-contract proposals.
- **Unattended** — `human_audit_rate: 0`, LEGITIMATE if the owner chooses speed, provided it is labeled
  honestly ("unattended, not controlled") and paired with the compensating deterministic controls (proof
  packets, seeded traps, random Tier-0→Tier-2 escalation, claim ledger, report compiler, router audit,
  post-run challenge).

**Owner's line, held:** zero standing human audit is a switch the owner owns, not a gap the system closes for
him. The steering interface is the one up-front conversation → a handful of TUNABLES with autonomous defaults
(objective weighting; risk appetite / where the proof bar sits; known test-gaps the machine can't infer;
budget/stop rule; audit mode). The machine does NOT ask the human to enumerate off-limits files — it DERIVES
the proof burden per change from property-at-risk.

## 7. Scope: BOTH purity floors are code quality; A is behavior-PRESERVING, B is behavior-CHANGING

Correcting a Memo-6 sloppiness (owner caught it): the public contract — MCP tool shapes, error model, the grant
model a caller experiences, pagination/projection semantics, OAuth-facing concepts — is part of the production
execution path, so its concept model IS the code's concept model. It is **in scope** (own-rent-delete §3: OWNED
PRODUCT SURFACE / PUBLIC CONTRACT is an absolute purity floor). Out of scope: docs (pdpp.dev / user
reading-path) and superficial sugar. The real boundary is **behavior-PRESERVING vs behavior-CHANGING**:
- **Machine A** does the `internal_purity(owned)` floor — behavior-preserving by construction (a decomplect
  leaves the public contract byte-identical). This whole memo is A.
- **Machine B** does the public-contract floor — a design CHANGE (rename a public error, restructure a
  caller-visible grant shape, fix a conflated concept), which is a behavior change BY DEFINITION, so A's
  behavior-preservation gate is built to REJECT it. B's output is a QUEUED human-ratified proposal, never an
  auto-land.

**The A→B seam (a real design lead).** When A decomplects, Tier-1 must NAME the seams — that naming is a
concept model of the contract, extracted from behavior by force, which the current machine DISCARDS. That
artifact is exactly B's input. So: decomplect exposes the seam → the seam is a HYPOTHESIS about a contract
defect → B verifies and proposes the redesign for ratification (generalizing own-rent-delete §8 rule 3,
"own-but-decomplect is the on-ramp to rent"). A can't FIX the contract; it can EXPOSE it, free, as a byproduct.
Emit a **Seam Hypothesis Packet** (extracted concept, behavior evidence, public-contract nouns, mismatch
suspicion, ALTERNATIVE explanation [may be an implementation seam a facade deliberately hides], B
recommendation). B does NOT block A; B prevents A from becoming blind internal polish.

## 8. Do NOT optimize "95% under threshold" — it's a proxy, not the goal

Target: **no high-attention owned complexity without a reason.** Cognitive-complexity excess points are
NOMINATORS, not the definition of SLVP-Q (the canon: verify the semantic defect before refactoring the metric;
the dynamic-import-cycle incident is the local proof of metric-chase churn on a non-defect). Prioritize
high-churn×complexity, security/storage/public-contract adjacency, agent-generated hotspots, known
concept-braiding, seams that feed B, code consuming owner attention. Classify as acceptable (do not churn):
cold complexity, essential domain complexity, generated code, quarantined compat shims, one-off migrations,
explicit defensive code at security boundaries, code scheduled for contract redesign.

## 9. THE GATE BEFORE THE BUILD — a 100-function falsification experiment (do this FIRST)

The 5M thesis rests on three under-proven premises, weakest first: (1) 70-80% of the 1,136 flagged functions
are genuinely Tier-0 under certified side conditions; (2) the side-condition checker has no blind spots;
(3) cognitive-complexity excess is the right backlog unit. Do NOT build the full machine on an optimistic
estimate. Build the smallest experiment that can FALSIFY it:

Sample 100 functions — **40** top churn×complexity / **25** random flagged / **15** auth-security-public-adjacent
/ **10** storage-backend adjacent / **10** recent agent-generated/refactored hotspots. For each: router
classifies (T0/T1/T2/DELETE/B-proposal); for every T0 candidate run BOTH the cheap proof AND the current
expensive §B shadow-review; track false-safe, false-expensive, proof cost, review cost, actual cognitive-load
reduction, and whether it was a real defect or a metric mirage. Build only the top 3 certified transforms for
this experiment. **Decision thresholds:** T0 eligibility <50% ⇒ 5M likely false (honest floor 20-50M); any T0
false-safe ⇒ narrow T0 before fan-out; proof receipts too expensive to generate/debug ⇒ savings shrink; many
cold/essential/quarantined candidates ⇒ the 13,899-point backlog is a metric mirage; common batch-coherence
failures ⇒ T1/T2 share is larger than estimated. Fan out ONLY after: zero T0 false-safe, cheap receipts,
router ambiguity escalates correctly, seeded traps caught, batch aggregate proof works, claim-ledger/report
prevents overclaiming.

## 10. Build order (do not skip to fan-out)

Phase 0 — patch the doctrine (this file + the loop skills) with the formula + Tier-0=certified + audit-as-mode
+ router-as-control + trust-accrues-to-mechanisms + A-emits-seam-hypotheses. Phase 1 — A-minimum (3 certified
transforms, router v0, proof-packet + trust-ledger schemas, the 100-function falsification runner,
Tier-0→Tier-2 shadow path, batch proof on one module, claim-ledger integration); NO broad fan-out. Phase 2 —
B-minimum in parallel, READ-ONLY/proposal-only (public-contract inventory: route|OpenAPI|MCP|error|grant-model|
tests|docs|impl-concept-names; seam-hypothesis collector from A; B judge: mismatch-candidate |
implementation-only-seam | unclear; human-ratified proposals only). Phase 3 — fan out aggressively ONLY after
falsification passes, inside token budget. Do NOT build: the 15-transform suite before certification, a
governance bureaucracy, a heavy continuous auditor on every tiny cut, a write-enabled B, prune/delete
automation over yellow/red candidates, or a machine whose success metric is threshold clearance. And do NOT
reintroduce timid filename-based blocking — that was the wrong failure mode.

## Final architecture (the whole machine in five lines)

```
cheap where proof is strong
expensive where proof is weak
autonomous where behavior is preserved
human-ratified where behavior/product contract changes
claim-ledgered everywhere
```
