# Memo 7: we ran your falsification experiment. The measured tier-mass kills the codemod-centric thesis. Re-scope the full build.

You told us (Memo 6, round 2): **do not build the 5M machine on an optimistic estimate — build the smallest
experiment that can falsify it, and re-consult with real data.** We did. This memo is that data. The weakest
premise you flagged — "70-80% of the flagged functions are genuinely Tier-0 mechanical" — is **false on this
codebase**, and not marginally. Here is the measured distribution, how we got it, the one place our own
instrument is imperfect, and the sharp question: given the mass is NOT where a certified codemod can reach it,
what should the full build actually be?

## 0. What we built (all deterministic, read-only, no LLM, committed on the sweep branch)

- `falsify.mjs` — enumerates the flagged universe from biome's JSON reporter (maxComplexity=1 so every function
  reports its real score), draws the stratified 100-function sample you specified (40 churn×cc / 25 random / 15
  auth-security-public / 10 storage / 10 recent-agent), and runs **ROUTER v0** (deterministic; ambiguity
  escalates; the maker/orchestrator cannot influence it — your §7 control-component rule).
- `resolve-anon.mjs` — de-anonymizes the tier that router v0 first mis-handled (see §2).

Universe: **1,139 flagged functions across 167 owned files, 8,406 excess-complexity points** (cc>5, the real
gate). This is the whole owned core, not a sample.

## 1. THE FINDING: T0 is 42% of the COUNT but 16% of the MASS

Router v0, over the full 1,139-function universe, measuring both function COUNT and excess-complexity MASS
(Σ(cc−5), the thing that actually costs owner attention):

```
tier               fns    %fns    excess-mass   %mass
T1-seam            164   14.4%        2219      26.4%
T2-unresolved      251   22.0%        1982      23.6%   (decomposed in §2 → mostly capturing closures)
T2-property        124   10.9%        1630      19.4%   (grant/token/oauth/consent/DDL in the body)
T0                 476   41.8%        1366      16.3%   (candidate for a certified mechanical transform)
T2-async           124   10.9%        1209      14.4%   (≥2 awaits + branching: ordering not v0-decidable)
TOTAL             1139             8406
```

**The cheap, safe, mechanizable tier touches the LEAST complexity mass of any tier.** The whole 130M→5M story
rests on codemods clearing the bulk cheaply. But the bulk isn't in the cheap tier. And the 42%-by-count is
itself inflated: of the 16 T0 functions in our sample, **10 are cc-6-or-7 — one to two excess points each**.
The safe-and-cheap corner is real but thin, and it is mostly marginal functions whose "improvement" is a
vanity-metric move, not an attention reduction. This is your §8/§10 "95%-under-threshold is a metric mirage"
warning — now measured, not asserted.

## 2. The "unresolved" tier is real, not a bug — and it decomposes AGAINST mechanization

Router v0 first routed 22% of functions to "T2-unresolved" because biome's name-anchor didn't resolve to a
token. Our first instinct was "name-resolution bug, the real T0 rate is higher." **We were wrong, and we
checked.** `resolve-anon.mjs` walked all 251 and classified them:

```
class              fns   mass    what they are
OTHER-ANON         136    874    anonymous arrows/fn-expressions
ITERATOR-CALLBACK   53    440    .map/.sort/.forEach/.reduce((x) => {...}) — hairballs INSIDE a larger fn
API-CALLBACK        52    507    proc.on('close', async (c) => {...}), setHook(async (x) => {...})
DB-TRANSACTION      10    161    raw.transaction(() => {...}) — migration/DDL bodies
```

The decisive sub-finding: **0 of the 53 iterator-callbacks are cleanly extractable — every single one captures
enclosing scope** (`.map(s => ...)` where the body references `summaries`, `providedScope`, `conditions`,
`report` from the parent function). Closure-capture is exactly the disqualifying hazard on your §2 forbidden
list. These cannot be mechanically hoisted to a named pure function without capturing their environment —
which is the thing a certified transform must refuse to do. Re-routed honestly: **201 (mass 1,420) are
capturing closures, 50 (mass 562) are DDL/security.** None are cheap-mechanical.

## 3. The consolidated reachability verdict

Collapsing tiers into "can a certified mechanical codemod safely touch this?":

```
REACHABLE by a certified mechanical transform (T0):        ~16% of complexity mass
NOT reachable (T1-seam + property + async + capturing):    ~84% of complexity mass
```

**On this codebase, the complexity that costs attention is overwhelmingly in code a behavior-preserving
mechanical transform cannot touch: capturing closures, security guards, awaited-ordering, and genuine
concept-seams.** The codemod library isn't wrong — it's just aimed at a thin 16% corner. The 5M-vs-30M debate
is moot; the real question is whether clearing that corner is even worth doing.

## 4. Where OUR instrument is imperfect (so you can discount correctly)

We are telling you the failure modes of our own measurement, per the evidence-not-narration rule:
- **Router v0 is heuristic, not a parser.** cc/security/await/branch signals from regex over the function body,
  not an AST. `SEAM_CC=12` (the T0/T1 line) is a guess. `T2-async` (≥2 awaits + branching) may over-escalate
  simple sequential awaits.
- **Capture detection is a conservative proxy** — it flags an identifier referenced in the body that isn't a
  param or a known global. It over-counts (method names like `.map`, the callback's own locals leak in). So
  "0 of 53 extractable" is an UPPER bound on the disqualification — a real AST scope analysis might rescue a
  handful. But the mass is small (440 total across all 53) and the direction is unambiguous.
- **These are ELIGIBILITY numbers, not proof.** We did NOT run the expensive half (build 3 certified
  transforms, apply them, §B-shadow-review each for false-safe). We stopped when the routing distribution
  alone contradicted the premise hard enough that building the transforms first would be answering the wrong
  question. If you think the false-safe experiment is still worth running despite the mass distribution, say so.

Even granting every imperfection maximum benefit of the doubt, T0 does not climb from 16% of mass to anywhere
near the 70-80% the thesis needs.

## 5. The re-scope question (the real reason for this memo)

Given the measured distribution, the mechanical-codemod-centric machine is the wrong build. The candidates:

**(a) Center the machine on T1-seam (26% of mass, the single largest reachable tier).** An LLM proposes the
concept-split seam; the execution is mechanical; Tier-0's proof battery verifies behavior. One cheap call per
function, not the full paranoid loop. This is where quality-per-token is best on this codebase. **But**: a
concept-split is a bigger, riskier edit than an if-inversion, and the "execution is mechanical once the seam is
chosen" claim is unproven — extracting a capturing sub-concept still has the closure problem. Is T1-seam
actually cheap, or does it collapse back into T2 the moment the seam crosses a closure boundary?

**(b) Keep the current expensive judged machine, but route better.** Accept that 84% of the mass needs real
proof, and that the win is NOT making it cheap but making it *correctly triaged* — full paranoia only on the
T2-property/async tail, T1-seam on the concept-splits, T0 codemods as a cheap add-on that clears count but
little mass. Total cost stays closer to 20-50M. Honest, but it abandons the order-of-magnitude dream.

**(c) Question whether the whole axis is worth it.** If 84% of the internal-complexity mass is expensive to
touch AND (your §10) internal cognitive-complexity is a proxy that diverges from real owner-attention cost,
then maybe the highest-leverage move is NOT to spend 20-50M grinding this axis down, but to invest in the B
machine (public-contract quality) where the owner's attention actually gets taxed. The decomplect machine
would then run cheap-T0 opportunistically and emit seam-hypotheses for B, and we'd stop pretending we can
autonomously drive internal complexity to 95%-under-threshold.

## 6. The three questions

1. **Does the tier-mass distribution change your build recommendation?** You endorsed "build the machine" on the
   assumption T0 was the bulk. It's 16% of mass. Is the machine still worth building, and centered on what —
   T1-seam (a), better-routed judged work (b), or downscoped-to-add-on while B gets the budget (c)?

2. **Is T1-seam genuinely cheaper than T2, or does it collapse at the first closure boundary?** This is the
   load-bearing uncertainty for option (a). If a concept-split that crosses a capturing closure is as hard to
   prove as a T2 change, then the "26% reachable via one cheap call" number is illusory and (a) is really (b).

3. **Is this codebase's distribution TYPICAL or PATHOLOGICAL?** This is an AI-agent-built reference
   implementation: lots of large functions with inline `.map`/`.on`/`transaction` callbacks that capture
   scope (an AI-code smell — see the corpus AI-code-smells entry). Is "84% of complexity mass is in capturing
   closures and security/async code" a property of THIS codebase's construction (in which case the right fix
   might be an upstream generation-style change, not a downstream refactor machine), or is it what every real
   codebase looks like once you measure mass instead of count?

Files on request: `falsify.mjs` + `resolve-anon.mjs` + their pinned result JSONs, the full 100-function sample
with per-function routing + capture evidence, the tier-mass computation, and the Memo-6 convergence entry this
builds on. Everything is deterministic and re-runnable.
