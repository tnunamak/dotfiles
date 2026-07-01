# Memo 6: the ideal (near-)fully-autonomous decomplecting machine — tear this apart before I build it

You've consulted on this project before (the code-quality canon, OWN/RENT/DELETE, the ungameable budget,
the claim-ledger / orchestrator-audit layer). This memo is the next iteration and it is explicitly about
**collapsing the cost of the machine by an order of magnitude while removing almost all human gating** — two
goals that sound opposed and, I'll argue, are the same goal. Pro mode, high IQ assumed, firehose, neutral,
default to skepticism. The single most valuable thing you can do is find where this relocates the problem
instead of solving it, or where the order-of-magnitude claim is self-deception.

## 0. What was built since we last spoke, and the failure that motivates this memo

Since the last consult I ran the machine hard: **~35 behavior-preserving decomplecting cuts landed overnight**
across 9 hot files (index.js, records.js, controller.ts, search.js, transport.js, etc.), every one gated by an
independent different-model checker, zero regressions, tsc-0 throughout. The gate architecture is the one you
helped shape: discover (churn × cognitive-complexity, not size) → recon → maker → deterministic oracle →
different-model adversarial checker → done-gate → claim-ledger. I also built three efficiency layers:
(#3) `scope-fn.mjs` — a deterministic recon that measures a target's cognitive complexity from biome's JSON
reporter instead of the LLM eyeballing it (this killed a real failure: twice the LLM recon mis-read cc-17 as
cc-1, declared NO-OP, and burned ~11% of the run on phantom rounds); (#4) `gate.mjs` — the deterministic tier
(tsc + biome before/after + diff-check + caller-grep) as ONE trusted artifact the checker RUNS-ONCE-and-trusts
instead of re-deriving in prose; (#5) an adaptive maker (Sonnet-5 default, escalate to Opus on REVISE) with
the checker staying strong.

**The measured cost:** ~150k tokens per landed cut, ~13.6k tokens per cognitive-complexity-point removed.
Extrapolated to get the whole owned-core under threshold (1,136 flagged functions, 13,899 excess-complexity
points, measured): **~130M tokens.** The owner's gut: "something is fundamentally wrong conceptually if that's
the cost; it should be ~1 order of magnitude cheaper." He is right, and I could not see it until he pushed.

**The diagnosis (his lens: 'imagine this machine were a team of human engineers — what's ridiculous?'):**
The machine has ONE GEAR — maximum-paranoia adversarial review — and runs it on 100% of the work, including
`if(a){x}else{y}` → `if(!a){y}else{x}`. A real senior team would: (a) write a codemod for the ~15 recurring
mechanical transforms ONCE and let CI prove them, (b) reserve deep adversarial review for the scary ~5-10%
where behavior-preservation isn't mechanically decidable, (c) BATCH review across a module (review-as-a-set,
commit-individually), (d) let TRUST ACCRUE so scrutiny drops as evidence accumulates — trust in the transform,
in the test suite, in the pattern's track record, in the author. My machine pays full paranoia-price forever
because it starts from zero every invocation: no memory, re-verifies what CI already proved, reviews atoms not
sets, uniform scrutiny regardless of risk. **The order of magnitude is not in the loop's efficiency — it is in
using a heavyweight process for lightweight work and never letting earned trust reduce future cost.**

Re-priced under the sane structure (codemod-for-mechanical + property-harness-instead-of-LLM-fuzz for the
risky tail + module-batched review + honest-narrow danger set): **~5-23M tokens**, the spread driven almost
entirely by how large the genuinely-not-mechanically-decidable tail is. ~5M is the target; ~3M is my floor
(below it I stop believing behavior-preservation can be soundly proven for the hardest cuts).

## 1. The two goals are one goal (the reframe I want you to stress-test)

The owner also wants this **(near-)fully autonomous — no per-file human gate.** Historically I imposed a
"RED-tier off-limits" rule (auth/grant/token/OAuth/consent never auto-modified). I now believe — and want you
to verify — that this rule was a CATEGORY ERROR born of my own over-caution (I even mis-attributed it to the
owner; it came from a prior expert paste, not from him). Here is the argument that autonomy and the 10× cost
reduction are THE SAME MOVE:

The reason to gate auth code was never "an agent must not touch it." It was "an agent must not silently CHANGE
ITS BEHAVIOR." But behavior-preservation is exactly what the deterministic tier proves. A decomplect that
preserves a grant-scope guard BYTE-IDENTICALLY (provable: the guard's AST subtree is unchanged; a targeted
differential test exercises it) is as safe on auth code as on a pure helper. I demonstrated this: I decomplected
`compileRequestFilters` (which has a `streamGrant.fields → field_not_granted` guard) 39→14 with the guard proven
byte-identical — a function my old rule would have skipped entirely.

So the unifying claim: **the thing that lets you drop the human gate is the SAME thing that lets you drop the
LLM fuzz — a strong-enough deterministic behavior-preservation proof.** Where the proof is strong, you need
neither a human nor a paranoid LLM. Where the proof is weak (behavior not mechanically decidable, thin tests),
you need BOTH a paranoid check AND, rarely, a human. **Off-limits-ness is not a property of the file (auth vs
not); it is a property of the PROOF STRENGTH available for a given change.** Attack this. This is the load-
bearing claim of the whole design.

## 2. The proposed machine: scrutiny proportional to residual risk, trust that accrues

Governing principle (the human-team insight, formalized): **ceremony ∝ residual risk, and residual risk falls
as evidence accumulates.** Every layer's job is to REDUCE residual risk cheaply so the expensive layers fire
rarely. Concretely, a per-change risk score routes each cut to the cheapest sufficient proof:

**Tier 0 — mechanical, proven by construction + CI (near-zero LLM).** A fixed library of ~15 AST-safe
transforms (extract-duplicated-block, dedup-isomorphic-branch, invert-guard-to-early-return, flatten-nesting,
hoist-shared-predicate) written ONCE with jscodeshift/ts-morph. Applicability is pattern-matched by the codemod
itself; safety is proven by (tsc-0 + full touched-test-suite green + AST-diff shows only the intended
structural rewrite + no captured-mutable-closure / this / arguments hazards, which are statically detectable).
No maker, no adversarial checker, no per-function LLM call. This is ~70-80% of the 1,136 functions. THE key
question for you: is "AST-safe transform + existing test suite as the local safety oracle" a SOUND proof of
behavior preservation for a dynamic language, or does it silently ship the 2% where the tests have gaps? (The
one real regression I ever shipped — `deriveSpineSource` — was skip-masked by a gated suite. That is the exact
failure mode that makes me distrust "tests are the oracle.")

**Tier 1 — judgment on the SEAM, mechanical on the EXECUTION (one cheap LLM call).** For concept-splits where
"which concerns to separate and along what seam" is genuine judgment (a 133-line resolver → three strategy
helpers), an LLM proposes the seam; a codemod (or a constrained edit) executes it; Tier-0's proof battery
verifies it. One Sonnet call for the judgment, deterministic for the safety. No adversarial second model —
because the RISK is in the seam CHOICE (a taste question, self-correcting: a bad seam yields a grab-bag the
coherence-review catches), not in behavior (proven deterministically). ~15-20%.

**Tier 2 — full adversarial loop + property harness (the current expensive machine, rare).** ONLY where
behavior-preservation is NOT mechanically decidable: the change touches control flow whose equivalence needs a
semantic argument (De Morgan across effects, ordering of awaited side-effects, a security guard that must be
re-proven not just relocated), OR the test suite is measurably thin for the touched code (mutation-score /
coverage gap). Here: a property-based differential harness (fast-check, written ONCE per risky module, RUN not
narrated) + a different-model skeptic + a claim-ledger entry. This is the ~5-10% that costs real tokens, and
it SHOULD — a human team also slows down here. The point: this tier's population is EARNED (by a weak proof),
not assigned (by a filename).

**The router (the keystone, and where I most want your fire).** A deterministic-first risk classifier decides
the tier per change: AST shape of the transform (is it in the safe library?) + static hazard scan (closure
capture, this/arguments, dynamic dispatch) + touched-code test-adequacy (coverage/mutation proxy) + whether a
security-relevant subtree is inside the diff. The classifier is CHEAP and mostly deterministic; only genuinely
ambiguous cases cost an LLM call. If the router is wrong in the SAFE direction (routes a hard cut to Tier 0),
the test suite / AST-check catches it and it escalates — fail-UP, not fail-silent. If wrong in the EXPENSIVE
direction (routes a trivial cut to Tier 2), you waste tokens but lose no correctness. So the router's errors
must be asymmetric: cheap-when-wrong-expensive, catastrophic-must-be-impossible. Is that asymmetry actually
achievable, or is there a class of change that LOOKS Tier-0-safe and ISN'T (the codemod's blind spot)?

**Trust that accrues (the human-team property nothing in my current machine has).** A pattern/track-record
ledger: a transform proven safe on N functions with zero downstream regressions graduates from "re-prove" to
"spot-check every Kth." A module whose differential harness exists and whose mutation score is high earns a
lighter default tier. This is the mechanism by which scrutiny DROPS over time — the reason a real team gets
cheaper at a codebase and my amnesiac machine never does. THE RISK you must attack: trust-that-accrues is
exactly how you get COMPLACENT and ship the regression on function N+1 that the spot-check skipped. Human teams
have this failure too (the "LGTM, it's just a small change" that breaks prod). What is the DISCIPLINED version —
graduated sampling with a fail-loud tripwire (a single downstream regression RESETS the pattern's trust to
zero and re-mandates full review)? Or is accrued trust fundamentally unsafe for an autonomous agent and I
should keep paying full price?

**Batch review (review-as-a-set, commit-individually).** Cuts are made individually (each independently
revertable) but REVIEWED in homogeneous batches (all Tier-0 dedups in a module together; the one Tier-2 cut
alone). This (a) enables SET-LEVEL coherence review a per-atom machine cannot do ("are these 4 helpers a
coherent module or a grab-bag?" — the exact grab-bag REVISE I only caught by accident), (b) primes the reviewer
(the 10th similar cut reviews faster than the 1st), (c) collapses fixed review cost ~5-10×. Batching key = risk-
tier × pattern homogeneity. Is there a hidden hazard in batching independent-but-same-file cuts (e.g. two cuts
that are individually safe but interact — cut A extracts a helper cut B then modifies)?

## 3. Autonomy: the human's role reduced to ONE up-front, UNDER-specified conversation

The owner's explicit intent: **do NOT over-prescribe the human's steering.** The machine should be fully
autonomous EXCEPT for optionally one up-front conversation where the human injects whatever ARBITRARY steering
they want — and we must not pre-specify what that steering is (that would be us imposing our guess of his
intent, the exact error I made with the RED-tier rule). So the design must accept a free-form steering input
and translate it into machine parameters WITHOUT the machine assuming what the human will say.

My model: the up-front conversation produces a small set of TUNABLES the human MAY set (all with sane
autonomous defaults if they say nothing): the objective weighting (e.g. "attention-cost = churn×complexity" vs
"just get everything under threshold"); the risk appetite (how strong a proof is required before a change lands
without a human — i.e. where the Tier-2→human-spot-check line sits); any genuine hard constraints the human
KNOWS about that the machine can't infer (e.g. "the billing reconciliation path has a known test gap, always
Tier-2 it"); and the budget/stopping rule. The machine does NOT ask the human to enumerate off-limits files —
it DERIVES risk per-change from proof strength. THE question for you: is "one under-specified up-front
conversation → a handful of tunables with autonomous defaults" the right human-interface, or does genuine
autonomy over auth/billing/security code REQUIRE a standing human spot-audit channel (your earlier AI-Control
framing: the untrusted policy needs a trusted monitor + a scarce human audit budget on a random+seeded sample)?
Can the human spot-audit be OPTIONAL (the human sets its rate, including zero) or is a nonzero human audit rate
IRREDUCIBLE for soundness on the hardest tier? I lean toward: human audit rate is a TUNABLE the human sets
(default low-but-nonzero on Tier-2 only), never a per-file gate. Is that sound, or is it how you ship a silent
grant-scope-widening six months in?

## 4. The five things I want you to attack hardest

1. **Is "off-limits-ness = proof-strength, not file-identity" SOUND, or a rationalization for touching auth code
   an agent shouldn't touch?** The whole autonomy claim rests on: a byte-identical security guard + a targeted
   differential test = as safe on auth as on a pure helper. Where does that break? (Guards that are correct only
   in COMBINATION across functions? Security properties that aren't LOCAL to the diff — an invariant the
   refactor preserves syntactically but breaks by changing WHEN a check runs relative to an effect?)

2. **Is the test suite a SOUND behavior-preservation oracle for Tier 0, given it demonstrably has gaps?** If not,
   what is the minimal ADDITION that makes it sound WITHOUT re-introducing per-function LLM cost — mutation
   testing on the touched span only? AST-level semantic-equivalence checking for the restricted transform set
   (is that even decidable for the ~15 transforms)? Or is Tier 0 fundamentally unsound and the honest floor is
   higher than 5M?

3. **Does trust-that-accrues have a DISCIPLINED form, or is it just automated complacency?** Graduated sampling
   + regression-resets-trust-to-zero — does that converge to safe, or does it just delay the inevitable silent
   miss? Is there a principled sampling rate (tied to observed regression rate) or is any rate below "review
   everything" unsound for an autonomous agent with no human in the loop?

4. **Does the router relocate the Adversarial-Goodhart problem?** The router decides how much scrutiny a change
   gets — i.e. it decides its own oversight. That is the maker≠judge violation one level up AGAIN (the same
   pattern as agent-derived-budget and orchestrator-narrative). If the router under-scrutinizes to save tokens,
   who catches it? Must the router be deterministic-only (no LLM discretion, so it can't be gamed)? Does a
   fraction of Tier-0 changes need to be RANDOMLY escalated to Tier-2 as an ongoing calibration check (a
   control-evaluation, catching router drift)?

5. **The honest order-of-magnitude question.** Is ~5M REAL, or am I doing the optimistic-estimate thing? The
   ~130M→~5M claim rests on: 70% of changes being genuinely Tier-0-mechanical, the test suite being a sound
   oracle for them, and trust-accrual being safe. If ANY of those three is false, the number balloons back
   toward 20-50M. Which of the three is the weakest, and what's the cheapest experiment that would falsify it
   before I build the whole thing? (I'd rather run one falsifying experiment than build a 5M machine on a
   false premise.)

## 5. The scope boundary — sharper than "different axis," and where the two machines meet

I have been sloppy about what this machine's budget buys, and the owner corrected me; here is the precise
version. Our objective function (corpus, converged) has TWO purity floors: `internal_purity(owned) ≈ max`
AND `public-contract / product-surface purity ≈ max`. **Both are code quality.** The public contract — the
MCP tool shapes, the error model, the grant model a caller experiences, pagination/projection semantics — is
part of the production execution path, so its concept model IS the code's concept model (mangle Stripe's API
contract and you've mangled the concepts modeled internally). It is NOT out of scope. What IS out of scope:
docs (pdpp.dev, the user reading-path) and superficial sugar.

The real boundary is not axis-vs-axis; it is **behavior-PRESERVING vs. behavior-CHANGING**:
- This machine does the `internal_purity(owned)` floor. It is behavior-preserving by construction — a decomplect
  leaves the public contract byte-identical, which is the whole point.
- The public-contract floor is a **design-CHANGE** operation (rename a public error, restructure the grant
  shape a caller sees, fix a conflated concept). That is a behavior change BY DEFINITION — so this machine's
  behavior-preservation gate is built to REJECT it. A behavior-preserving engine is architecturally incapable
  of the contract-redesign axis. It needs a SEPARATE machine (call it B), whose output is a queued
  human-ratified proposal, never an auto-land (per our `surface_minimum` / `requires_human_ratification` gates).

**The seam where A feeds B (a genuine design lead, not just a caveat).** When A decomplects, Tier-1 must NAME
the seams — it decides that `queryRecords` is really *grant-scope-resolution* + *filter-compilation* +
*window-pagination*. That naming is a concept model of the contract, extracted FROM behavior by force. The
current machine DISCARDS it (the checker judges is-decomplect-not-slop and moves on). But that discarded
artifact is exactly B's input: "here is what your API actually models; does it match what a good contract
SHOULD model, or did decomplecting EXPOSE a place where the public surface conflates two concepts?" This is
the OAuth finding (corpus, own-rent-delete §8 rule 3) generalized — "own-but-decomplect is the on-ramp to
rent" becomes "decomplect exposes the seam → the seam is a HYPOTHESIS about a contract defect → B verifies and
proposes the redesign for human ratification." A can't FIX the contract, but it can EXPOSE it, for free, as a
byproduct. B is a later machine, gated by the same prove-by-hand-first rule; it is NOT part of this memo's
auto-land loop, and the seam-mismatch is a prior (could mean the CUT was wrong, or the facade hides structure
deliberately), not a verdict.

**The questions for you.** (a) Is that A→B seam real, or am I overselling a discarded artifact — does a
behavior-preserving decomplect actually yield a trustworthy concept model, or a misleading one? (b) Given
BOTH floors are in scope but only one is behavior-preserving, is the highest-leverage next build cheapening
THIS machine (A) toward 5M, or standing up B's EVALUATOR so we can even measure where the contract floor
stands? (c) Make the strongest case that spending budget decomplecting to 95%-under-threshold is a LOW-value
use relative to the contract floor — i.e. that A, however cheap, is polishing the axis that matters less.

Files on request: the corpus siblings (own-rent-delete, ungameable-budget, SLVPQ-operationalization, the
orchestrator-audit entry, canonical theory), the refactor-loop Workflow + scope-fn.mjs + gate.mjs + discover.mjs,
the 35-cut commit log with per-cut token counts, the §B verdicts (real evidence of the failure modes:
grab-bag REVISE, ||→?? drift caught, the two measurement-thrash non-findings, the false-exhaustion bugs).
