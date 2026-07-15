# OWN / RENT / DELETE: the attention-perimeter objective function for an AI-built, human-steered codebase

**Status:** converged design (owner + two external-expert rounds, 2026-06-29). Extends the canon's
internal-purity spine with a *portfolio* layer: which complexity to keep, transfer, or remove. This is the
answer to "what should the project-quality system optimize" — a question the [[CANONICAL-CODE-QUALITY-THEORY.phase1]]
(how to make *owned* code good) does not itself answer.

Provenance: a pro-mode ChatGPT round contributed the OWN/RENT/DELETE/FREEZE/QUARANTINE classification; the
owner (Tim) specified the precise objective function and the library-selection bar; a second expert round
added two precision corrections (reclassify-don't-lower-the-floor; kill the externalize-as-work-generator
flag). See `SLVPQ-OPERATIONALIZATION.md` for the GUIDE/GATE protocol this composes with.

## 1. The objective function (owner-specified, verbatim intent)

> Maximize product value, minimize complexity **under the owner's attention**, subject to two purity floors:
> (a) RENTED complexity must encapsulate near-maximal purity **at the boundary**; (b) OWNED complexity must be
> held to near-maximal **internal** purity.

Formal: `maximize(product_value) ∧ minimize(owned_attention_complexity)` **subject to**
`boundary_purity(rented) ≈ max` ∧ `internal_purity(owned) ≈ max`.

The key reframe vs. naive "minimize total complexity": the bottleneck being optimized is **the human owner's
attention**, not global LOC or global cyclomatic complexity. A 50k-line mature dependency you never read costs
~zero attention; 200 lines of bespoke owned glue can cost a lot. So the levers are about *what falls inside the
attention perimeter*, not raw size.

## 2. The two levers — and what is NOT a lever

Attention is reduced by exactly two moves:
- **DELETE** — remove accidental complexity that has no product value (Hickey's "simple"; the canon's
  delete-over-abstract).
- **RENT** — *transfer* commodity complexity to a serious dependency behind a near-maximally pure boundary.

**Lowering owned quality is NOT a lever.** This is the load-bearing correction. RENT is a *transfer, not a
discount*: it moves complexity out of the perimeter, it does **not** buy slack on the code that stays owned. The
purity floor sits on *both* sides of the OWN/RENT line. Therefore "purity vs. attention" is a **false tradeoff** —
DELETE + RENT dissolve it. You never satisfy "minimize owned complexity" by making owned code worse.

## 3. The escape hatch is RECLASSIFICATION, not tolerance (expert correction)

The owned-core purity floor is **absolute for owned core + public-contract code**. The earlier draft said
"absolute, full stop" — too strong. There *are* owned things held to a lower bar, but they are **explicitly
labeled and isolated, not silently tolerated inside the core**:

| Class | Rule |
|---|---|
| OWNED CORE | high-purity floor (absolute) |
| OWNED PRODUCT SURFACE / PUBLIC CONTRACT | high-purity floor (absolute) |
| SPIKE / experimental | allowed lower purity **with expiry** |
| GENERATED | isolate; do **not** hand-polish the artifact |
| QUARANTINE (ambiguous external behavior) | isolate; do not expand |
| FREEZE (preserved-not-expanded behavior) | narrow; ugly-but-tested OK |
| TEMPORARY GLUE / compat shim / vendor workaround | ugly allowed **if narrow + well-tested** |

Operational consequence: an agent must **reclassify** a migration script / generated file / compat shim out of
"core" rather than over-refactor it OR rather than quietly let core slip. This is the precise version of "the
floor is absolute."

## 4. The RENT bar (owner-specified) — rare, high-conviction, human-ratified

RENT is **not** "a package exists that sort of does this." The dependency must be the **near-canonical,
objectively-best, trending-UP, sticky** choice for that exact commodity. Owner's exemplars: **libsodium**
(canonical crypto), **viem** (clear generational winner over predecessors). Most candidates fail this; RENT is a
**scalpel, not a sweep**. The adoption packet must carry a *seriousness verdict*: trend (up/flat/down),
stickiness/staying-power, "objectively-best-in-category vs. merely-popular." Popular-but-plateauing or
forking-ecosystem → fails.

**Ratification:** the owner ratifies which libraries the project hitches to — but **late/batched is fine if the
process is trustworthy** (consistently proposes the choices he'd make). So RENT decisions are
proposed-with-packet → queued → batched → human-ratified. Never auto-adopted; never pipeline-blocking. The system
earns autonomy here only via track record.

## 5. The `externalize_before_custom_build` footgun (expert correction)

A flag that *actively generates* externalize work makes agents hunt for dependencies even in a lean repo →
dependency sprawl. Replace the active generator:

```yaml
# WRONG — manufactures RENT work:
externalize_before_custom_build: true
# RIGHT — passive guards that fire only at a real build-or-own decision:
evaluate_rent_before_owning_new_commodity_complexity: true
do_not_manufacture_externalize_work: true
rent_requires_high_conviction: true
```

RENT triggers only when the question is "are we about to **build or continue owning** commodity complexity a
near-canonical dep should own?" — never "can we find a package that does this?"

## 6. Budget as GATES, not capped lanes

Owned-purity and rented-boundary-purity are **gates every subsystem must pass**, funded as need dictates — not
discretionary % lanes. (The earlier `internal_code_health_max: 20%` was a category error: it confused "low token
spend because mostly-done" with "lower standard.") Token allocations bias *order* (surface first), gates bias
*acceptance*.

```yaml
quality_budget:
  surface_minimum: 50%          # docs/API/auth/errors get order priority until the contract exists
  until_docs_score: 60
  owned_attention_reduction_minimum: 25%   # DELETE + clean-boundary RENT
  owned_internal_purity: GATE              # every owned subsystem must pass the canon bar
  rented_boundary_purity: GATE             # serious + objectively-best + narrow adapter + contract tests + exit plan
  prune_without_contract_max: 0
  red_surface_deletion: forbidden
  evaluate_rent_before_owning_new_commodity_complexity: true
  do_not_manufacture_externalize_work: true
  rent_requires_high_conviction: true
  dependency_adoption_requires_packet: true
  dependency_adoption_requires_human_ratification: true   # batched/late OK once track record earns trust
  human_ratifies_budget: true
  dimension_set: fixed_in_repo             # rubric change = human-reviewed PR (closes the bias channel)
```

Priority: `expected_SLVP_gain × owned_attention_reduction × confidence × surface_weight /
(risk × token_cost × review_cost × dependency_risk × boundary_purity_cost)`.

## 7. The Dependency Adoption Packet (required per proposed RENT)

```md
# Rented Boundary Packet
Dependency: name / version / category
Complexity rented: what we stop owning
Why commodity: not product-defining
Seriousness verdict: trend (up/flat/down) · stickiness · objectively-best-in-category? · bus factor
Supply-chain posture: OpenSSF Scorecard · deps.dev · Socket · npm/GH advisories · license · transitive load · provenance/SLSA
Owned boundary: the adapter/facade WE own
Concepts allowed to leak inward: preferably NONE (list exceptions explicitly)
Contract tests: the behavior we rely on
Upgrade policy: pinned / range / ratified
Failure & exit plan: how hard to replace
```
A great library behind a messy boundary is **not** an acceptable RENT — it relocates the mess to the seam.

## 8. Grounded application to PDPP reference-implementation (2026-06-29)

Verified manifest: **14 prod deps, 4 dev**. Commodity layers are *already* rented to serious deps — HTTP
(`fastify`/`express`), DB drivers (`pg` + `better-sqlite3`), logging (`pino`/`pino-pretty`), form/query
(`@fastify/formbody`/`qs`), embeddings (`sqlite-vec` + `@huggingface/transformers`), push (`web-push`), browser
(`patchright`), lint (`@biomejs/biome` + `ultracite` preset). So **the RENT surface is small** — narrow remaining
candidates (OpenAPI lint/validate/generate, schema-validation, CLI parsing, contract-testing utils), several
possibly already adequate. *Do not manufacture externalize work here.*

Discovery tooling is **greenfield**: no knip / ts-prune / depcheck / madge in deps or scripts → the deterministic
prefilter layer is part of the build, not a config tweak.

**Dual-backend = OWN-both (NOT prune, NOT pick-one).** Owner: postgres AND sqlite both matter. Drivers already
rented; `postgres-storage.js` is ~2864L of *owned* storage logic (15 exports); pg vs. sqlite storage modules
share zero exported names. So this is the **canonical OWN-internal-purity job**: one honest storage contract,
two serious implementations, backend differences explicit, parity tests proving the contract. Highest-priority
internal-purity item *because* it's load-bearing and attention-expensive.

**Do-not-RENT list (owner core — a dependency here would leak concepts everywhere):** PDPP protocol behavior,
consent/privacy/security policy, storage-contract semantics, public error model, OAuth/DCR/PAR consent flow
semantics, small pure functions.

**The OAuth-substrate case (a reusable OWN/RENT pattern, found 2026-06-29).** A macro audit asked "is the AS
reimplementing a commodity?" The spec disclaims token issuance ("implementation choice"), so ~30-35% of `auth.js`
is genuinely commodity OAuth+RAR substrate (PKCE/device-flow/PAR/DCR/refresh-rotation/introspection ~2,400 LOC)
braided with ~65-70% PDPP product (`authorization_details` semantics, grant→manifest validation, grant_package
lifecycle, enforcement). Verdict was **OWN-but-DECOMPLECT, not RENT**, yielding three generalizable rules:
1. **A great library that forces your domain concept into a non-standard side-channel FAILS the boundary-purity
   floor.** Here the AS *products* (Ory/Keycloak/Zitadel) only host a custom RAR type as a vendor claims-blob →
   PDPP's protocol-defining `authorization_details` would degrade to a side-channel. Only `node-oidc-provider`
   models RAR natively, and even it leaks Grant/Interaction/Koa concepts inward.
2. **Reference-implementation-as-spec INVERTS the normal rent calculus.** A normal SaaS should almost always rent
   its AS. But a reference impl whose job is to BE the readable, dependency-free definition of the protocol
   *gains* value from owning a readable substrate — IF the layering is legible. The real defect was the invisible
   seam (substrate+policy interleaved in one file), not the absence of a dependency.
3. **Decomplect-first strictly dominates jump-to-dependency.** Extracting a thin internal substrate module (ZERO
   domain nouns in its interface) whose boundary mirrors the library's adapter shape fixes the legibility defect
   now AND makes a future rent a localized adapter-map, not a rewrite. Own-but-decomplect is the on-ramp to rent.

## 9. Open research (NARROW — dependency strategy, NOT "what is code quality")

The canon (behavior-verification, decomplecting, deep modules, local reasoning, honest names, explicit effects,
data fitness, maker≠judge) is mature. The *remaining* open question is time-sensitive and package-specific:
**how should an AI-managed project decide OWN/RENT/DELETE/FREEZE/QUARANTINE, especially the supply-chain risk of
RENT?** Deliverables: (1) dependency-selection rubric (scorecard not vibes); (2) repo-specific RENT-surface table;
(3) boundary-purity patterns; (4) supply-chain policy gates (OpenSSF Scorecard, SLSA provenance, deps.dev, Socket,
npm/GH advisories — tools inform the packet, humans decide). Recent npm supply-chain attacks prove popularity ≠
safety.

## 10. Agreed next step (memo-2 point IV, expert-confirmed)

**Read-only OWN/RENT/DELETE discovery pass with dependency packets** — NOT a write-enabled externalization sprint,
NOT a harness build yet. Build the read-only discovery + the route/spec/docs/test/impl matrix; run **one manual
cycle** (surface-repair + one RENT-or-DELETE decision-with-packet + one OWN-purity decompose in parallel);
re-audit before committing to any write-enabled fan-out. Rationale: a machine was built for the wrong optimizer
once already — prove the corrected optimizer by hand before automating it.
