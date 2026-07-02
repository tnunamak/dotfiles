# RAW: the expert's v1 Repo Quality Engine directive (verbatim, 2026-07-01)

> Provenance: pasted by the owner into the Claude session 31191f1e on 2026-07-01 as the expert's answer to
> "give me a high-confidence big swing at the ideal design." This is the directive `hone` was built from.
> CAPTURED LATE (2026-07-02): the agenda pressure-test found it uncited-on-disk — its §7 line "use strong
> models for selection, concept judgment, high-risk review, and report audit" was quoted in design work but
> unverifiable against the corpus until this capture. Extracted byte-accurately from the session transcript.

# Directive: Build the v1 Repo Quality Engine

We are done iterating in prose. Build the machine.

## Goal

Build a reusable engine that can take sparse owner intent like:

```text
Improve this repo toward the ideal. Work on a branch. Use the standing quality target. Escalate only true owner-level decisions.
```

and then efficiently drive a codebase toward the ideal by:

1. building durable inventory;
2. creating small candidate packets;
3. classifying what kind of complexity each candidate represents;
4. choosing the right action;
5. routing to the cheapest sufficient workflow;
6. verifying with evidence matched to the work type;
7. reporting only evidence-backed claims;
8. recording cost and lessons so future runs get cheaper.

This is **not** a refactor loop. It is a **repo-quality engine**.

Refactoring is one workflow. Other workflows include deletion, documentation/spec repair, dependency adoption proposals, quarantine/freeze decisions, evidence generation, and product-contract proposals.

## Our actual objective

The owner’s objective is:

> Maximize product value and minimize complexity under owner attention, subject to near-maximal purity for owned code and near-maximal boundary purity for rented complexity.

RENT is a transfer, not a discount. Owned code still needs to be excellent. Rented complexity must be serious, near-canonical, ecosystem-validated, narrowly bounded, contract-tested, and ratified by the owner. 

The terminal goal is the ideal codebase, not “good enough where most of the mass is.” Use attention-weighted expected value for ordering, not for lowering the standard.

## Core quality target

The quality target is:

> High-quality code is verified behavior encoded in a structure that minimizes the independent concepts, states, effects, dependencies, and change paths a competent maintainer must hold in mind to predict, operate, and safely modify the system.

The engine must optimize for reduced incidental complexity, decomplected concepts, honest names, explicit state/effects, deep modules, local reasoning, data/constraint fitness, verification, and clean boundaries. It must not optimize for LOC, DRY, low complexity score, test count, or “clean-looking” structure unless semantic risk and cognitive load actually go down. 

## Non-negotiable lessons already earned

Encode these. Do not re-derive them.

1. **Maker is not judge.** The agent that produced a change cannot certify it. The current playbook’s load-bearing invariant is that LAND comes from an independent judge, not from the maker/orchestrator. 

2. **Tests are useful, but not the oracle.** No direct test does not mean no action. No external evidence means no preservation claim. Evidence must match the change class: emitted JS equivalence, body hash, call/import/export proof, differential probes, property-at-risk proof, liveness roots, or product proposal. 

3. **Codemods are not the center.** The falsification experiment found T0/codemod-reachable work was 41.8% of function count but only 16.3% of excess-complexity mass. Use codemods for hygiene, type-only work, safe local transforms, and recurrence prevention. Do not build the machine around them. 

4. **Metric findings nominate work; they do not define work.** A dependency-cycle metric once reported a defect that was already safely broken by dynamic import. The correct fix was the rule, not churn in the code. Every metric finding needs semantic validation before work begins. 

5. **AI agents overclaim.** We have seen plausible summaries diverge from diffs, metric gaming, addition bias, and self-reported progress that was not real. Reports must be generated from evidence, not persuasive prose. 

6. **Deletion is not refactoring.** Tests passing does not prove code is dead. Deletion requires liveness roots and a deletion proof packet.

7. **OWN / RENT / DELETE / FREEZE / QUARANTINE classification happens before decomposition.** Do not decompose code that should be deleted, rented, frozen, or quarantined.

## The architecture to build

Build this exact architecture:

```text
durable inventory
→ candidate packets
→ classification
→ ranking
→ workflow execution
→ evidence verification
→ claim report
→ cost/lesson update
```

This should live as a reusable tool, preferably in waspflow or a narrow waspflow-compatible package, not as a one-off PDPP script.

## 1. Durable inventory

Build inventory scripts that produce JSON artifacts. Agents should not repeatedly reread the repo from scratch.

Minimum inventory:

```text
entrypoints
public surfaces
routes
OpenAPI/specs
docs
tests
exports
dependencies
runtime config/env vars
storage/data paths
generated files
complexity hotspots
churn
duplication
static cycles
type holes
dead/unused candidates
high-complexity callbacks/closures
risk-sensitive areas
```

The inventory list is not hardcoded globally. The engine has common collectors plus project-specific collectors.

Examples:

```text
common:
  deps, exports, tests, complexity, churn, config, generated files

PDPP-specific:
  HTTP routes, OpenAPI, MCP, OAuth/DCR/PAR/consent, SQLite/Postgres storage, connector manifests
```

Output:

```text
quality/inventory/*.json
```

## 2. Candidate packets

Do not prompt agents with broad repo context. Convert inventory findings into compact candidate packets.

Schema:

```yaml
candidate_id:
repo_sha:
subsystem:
files:
symbols:
public_surface:
current_behavior_status:
  contract | likely_intended | provisional | accidental | unknown
ownership_status:
  OWN | RENT | DELETE | FREEZE | QUARANTINE | GENERATED | TEMPORARY
proposed_action:
  preserve_refactor | idealize_rewrite | delete | rent | freeze | quarantine | document | propose_contract_change | generate_evidence
why_this_matters:
expected_quality_gain:
expected_owner_attention_reduction:
user_or_product_impact:
risk:
blast_radius:
reversibility:
expected_token_cost:
expected_evidence_cost:
required_evidence:
not_allowed:
model_tier:
batch_key:
claim_expectations:
```

This is the main token-efficiency move. Expensive reasoning creates durable packets. Cheap agents execute against packets.

## 3. Classification

Before work begins, classify two things.

### Current behavior status

```text
contract          preserve unless explicitly changed
likely_intended   preserve by default
provisional       may improve toward inferred intent
accidental        delete or rewrite
unknown           investigate or quarantine
```

This prevents over-preserving AI sediment in pre-prod projects and prevents casual rewrites of shipped contracts.

### Ownership status

```text
OWN          product-defining complexity we keep and make excellent
RENT         commodity complexity delegated to a serious dependency behind a clean boundary
DELETE       accidental complexity
FREEZE       externally visible behavior we preserve but do not expand
QUARANTINE   unclear/legacy behavior isolated until clarified
GENERATED    generated code we do not hand-polish
TEMPORARY    bounded, expiring code
```

## 4. Workflows

Implement these workflows as reusable templates. Each workflow defines inputs, allowed actions, required evidence, model tier, batching rules, stop conditions, and report format.

### A. Preserve/refactor owned code

Used when behavior is contract or likely intended.

Allowed:

```text
decomplect
rename honestly
make state/effects explicit
extract deep modules
make dependencies explicit
reduce change amplification
```

Required evidence depends on change type.

### B. Idealize/rewrite provisional code

Used for pre-prod or low-stakes code where current behavior is not sacred.

Allowed:

```text
rewrite toward inferred intent
change behavior if labeled
delete confused scaffolding
rename public-ish concepts if not shipped
generate new smoke checks
```

Required:

```text
explicit behavior-change notes
independent design review
branch-only landing unless policy allows merge
```

### C. Surface repair

Used for docs/spec/routes/errors/MCP/CLI/API coherence.

Output should make code, spec, docs, tests, and examples agree.

### D. Delete/prune

Deletion requires a proof packet. Tests passing is not sufficient.

Check liveness roots:

```text
entrypoints
routes
OpenAPI/specs
package exports
CLI
MCP tools/resources/prompts
docs/examples
env/config
dynamic imports
string dispatch
connector manifests
DB migrations/readers
tests
real backend paths
text search
```

Classify deletion candidates green/yellow/red. Red is not auto-deleted.

### E. Rent/dependency proposal

Do not auto-adopt production dependencies.

Produce a dependency adoption packet:

```text
complexity rented
why this is commodity
why this dependency is near-canonical
trend/stickiness/security/license
boundary design
concepts that may not leak
contract tests
upgrade policy
exit plan
owner ratification status
```

### F. Freeze/quarantine

Used for externally visible or unknown behavior that should not be expanded but cannot yet be safely deleted.

### G. Evidence generation

Used when the best next move is to create the oracle that unlocks higher-value work:

```text
differential harness
smoke flow
characterization test
backend parity check
route/spec/docs matrix
```

### H. Product-contract proposal

Used when current behavior should probably change but the change is product-level.

Output is a proposal, not an auto-landed refactor.

## 5. Evidence policy

Use the cheapest sufficient evidence for the change.

```text
type-only change
  emitted JS equivalence

exact move
  body hash + symbol hash + call/import/export equivalence + module-init safety

certified local transform
  side-condition proof + emitted/AST diff

pure extraction
  old-vs-new differential probes

effectful code
  focused integration evidence

auth/storage/security
  property-at-risk proof

delete
  liveness roots

surface repair
  route/spec/docs/tests consistency

product behavior change
  proposal or explicit authorization
```

Independent agents review the evidence. They do not replace the evidence.

## 6. Ranking

Rank by quality gain per token, not by metric severity.

Use:

```text
priority =
  expected_quality_gain
  × owner_attention_reduction
  × user_or_product_impact
  × confidence
  /
  (risk × evidence_cost × token_cost × reversibility_cost)
```

Metrics nominate; they do not decide.

High-churn/high-complexity is a strong signal, but not an override. Surface contract gaps, storage contract ambiguity, auth behavior, public errors, and dependency boundaries may outrank internal complexity.

## 7. Token efficiency by construction

This is mandatory. Do not build a chatty orchestration system.

The machine must be constructed so expensive reasoning is amortized.

Rules:

```text
use durable inventory instead of repeated repo reading
use candidate packets instead of bespoke prompts
use workflow templates instead of fresh plans
use cheap models for narrow execution
use strong models for selection, concept judgment, high-risk review, and report audit
batch compatible work by proof class and subsystem
commit small, review coherent batches
compile reports from claims instead of writing long prose
record cost and outcome for every job
```

Build two ledgers.

### Cost ledger

```yaml
job_id:
candidate_id:
workflow:
model_used:
tokens_in:
tokens_out:
wall_time:
landed: true | false
revision_count:
judge_result:
actual_quality_gain:
actual_owner_attention_reduction:
followup_created:
```

### Lessons ledger

```yaml
lesson_id:
triggering_failure:
new_rule:
where_enforced:
regression_example:
status:
```

This is how we avoid throwing away earned lessons.

## 8. Claim ledger and report compiler

Reports must be generated from claims.

Claim types:

```text
verified_fact
judged_design_claim
behavior_preserved
behavior_changed
hypothesis
uncertainty
remaining_work
```

No claim may say “done,” “complete,” “clean,” “first-class,” or “solved” unless the evidence supports that exact claim.

The orchestrator may comment, but the report’s main body comes from the claim ledger.

This specifically addresses the observed failure where the code was sound but the campaign narrative overstated what had been achieved. 

## 9. Batching and parallelism

The system is a graph, not a serial pipeline.

Parallelize:

```text
inventory collectors
candidate generation
independent judge sweeps
surface fixes on disjoint routes
type-only changes in separate modules
exact moves in separate modules
docs/spec consistency checks
dependency research packets
```

Serialize:

```text
same symbol touched twice
same public contract touched twice
storage/auth behavior changes
delete before liveness roots
rewrite before behavior status is classified
dependency adoption before packet
```

Batch by:

```text
same workflow
same proof class
same subsystem
non-conflicting touchsets
```

Rule:

> Commit small. Review coherent batches.

## 10. User interface

The owner should be able to give sparse intent.

Default command:

```text
Improve this repo toward its quality target. Work on a branch. Use the standing policy. Escalate only owner-level decisions.
```

Owner-level decisions:

```text
new production dependency
public behavior change
auth/security policy change
storage contract change
data migration
target/rubric change
merge/release
```

If the owner wants no interruption:

```yaml
owner_policy:
  mode: autonomous_branch
  dependency_decisions: prepare_packet_do_not_adopt
  product_behavior_changes: branch_with_proposal
  merge_release: owner_decides_later
```

If the owner explicitly authorizes more:

```yaml
owner_policy:
  mode: autonomous_preprod
  current_behavior_default: provisional
  behavior_changes_allowed_if_labeled: true
  merge_policy: branch_only
```

Branch autonomy can be high. Release autonomy remains separate.

## 11. Quality gates for the engine itself

The engine is owned complexity. Keep it small and prove it works.

Acceptance tests:

```text
candidate packet schema validation
workflow routing tests
claim ledger/report compiler tests
cost ledger write/read tests
metric-semantics negative-control test
delete liveness-root negative-control test
maker cannot self-judge test
report cannot include unbacked “done/complete/clean” claim
cache/key invalidation test
parallel touchset conflict test
```

No write-enabled fan-out until these pass.

But do not overbuild. The target is a working v1, not a governance cathedral.

## 12. Immediate implementation plan

Build the v1 in one branch.

### Phase 1 — Docs and schemas

Create:

```text
quality/README.md
quality/QUALITY-TARGET.md
quality/QUALITY-MACHINE-SPEC.md
quality/CANDIDATE-PACKET.schema.yaml
quality/WORKFLOW-TYPES.md
quality/EVIDENCE-POLICY.md
quality/CLAIM-LEDGER.schema.yaml
quality/COST-LEDGER.schema.yaml
quality/LESSONS-LEDGER.md
```

These should be concise and executable. Do not write another sprawling memo.

### Phase 2 — Minimal runnable engine

Implement:

```text
quality/inventory/build-inventory.ts
quality/planner/generate-candidates.ts
quality/planner/classify-candidates.ts
quality/planner/rank-candidates.ts
quality/reports/claim-ledger.ts
quality/reports/compile-report.ts
quality/cost/cost-ledger.ts
```

The first version may use existing discovery scripts where possible. Do not rewrite working instruments unless necessary.

### Phase 3 — Three workflows

Implement only three write workflows first:

```text
surface-repair
owned-code-preserve-refactor
evidence-generation
```

Model the other workflows in the spec, but do not fully automate deletion or dependency adoption in v1.

Deletion and dependency adoption are high-value but need stricter packets and owner ratification.

### Phase 4 — Dogfood on a meaningful batch

Do not run one toy candidate. Run a small but meaningful batch:

```text
3–5 surface candidates
3–5 owned-code candidates
1 evidence-generation candidate
```

All on a branch. Small commits. Coherent report.

Success is measured by:

```text
real quality gain
tokens spent
amount of repeated reasoning avoided
whether reports are evidence-backed
whether candidates were correctly classified
whether future runs are cheaper
```

### Phase 5 — Scale only after the first batch proves the construction

If v1 works, expand workflows:

```text
delete/prune with liveness-root packets
dependency adoption packets
freeze/quarantine
product-contract proposals
qualitative judge sweeps
larger batch fan-out
```

## 13. What not to do

Do not:

```text
write another broad strategy memo
center the machine on codemods
center it on tests
center it on cognitive-complexity thresholds
start with deletion automation
let agents reread the whole repo every time
let the maker certify its own work
let reports be hand-written persuasion
ask the owner for routine decisions
build a huge harness before v1 proves itself
```

## 14. Final standard

The machine succeeds if it lets the owner buy high-quality codebase improvement with tokens.

That means:

```text
higher quality per token
less owner attention
less repeated reasoning
more durable repo knowledge
more correct work selection
better evidence
honest reporting
no self-grading
```

The final design sentence:

> The engine turns sparse owner intent into evidence-backed repo improvements by building durable inventory, generating compact candidate packets, choosing the right action for each piece of complexity, running the cheapest sufficient workflow, and recording cost and lessons so future runs are cheaper and smarter.

Build that. Then dogfood it immediately.
