---
title: "Fine-grained invalidation (Salsa, Bazel/Skyframe, Adapton) invalidates only the derived values that actually read a changed input and re-validates unchanged outputs without re-invalidating downstream — a single coarse generation counter cannot express either distinction"
date: 2026-08-21
topic: distributed-systems
tags: [incremental-computation, salsa, bazel, skyframe, adapton, generation-fence, invalidation, health-status, kubernetes-conditions, remediation-copy, thundering-herd, jitter]
status: draft
sources: [salsa-algorithm, salsa-overview, bazel-skyframe, k8s-api-conventions-condition, nng-error-messages, aws-jitter, google-cre-ddos]
source_session: af82d1f3-1838-4307-a3a9-6bbf07e77c6f
---

<!--
Companion / do-not-duplicate map (all read in full before writing this entry):
- distributed-systems/derived-state-staleness-after-a-code-upgrade-is-detected-by-storing-the-computing-code-version-on-the-derived-row-because-input-checkpoints-cannot-see-a-formula-change.md
  (2026-08-16) already covers: code-version-on-row pattern, Marten/dbt/Rama, rebuild budgeting/starvation,
  Rama's read-through migration. THIS entry does not re-derive any of that — it answers the question that
  entry explicitly left open: how do you invalidate LESS than "everything with a version mismatch" when the
  version bump is coarse (one counter for N independent fields)? That is fine-grained dependency tracking,
  which the 08-16 entry does not cover at all (checked: no mention of Salsa/Bazel/Adapton/dependency graphs).
- api-contract-design/health-vocabularies-separate-a-lifecycle-axis-from-a-verdict-axis-...md (2026-08-19)
  and product-design/consumer-products-do-show-raw-condition-lists-...md (2026-08-19) already settle, for
  PDPP specifically: Kubernetes condition schema, the "ProjectionReliable false-during-run" defect (same
  defect CLASS as this ticket's bug, different trigger), the owner-vs-consumer persona question, the
  passing-row filter rule, and the condition rename/merge recommendations. THIS entry does not re-litigate
  any of that; it takes the k8s condition model as settled and applies it one layer up, to the
  GENERATION-FENCE trigger specifically, which those two entries do not address (grep: neither mentions
  "generation" as a manifest/schema versioning mechanism).
- feedback-systems/mature-integrations-only-interrupt-the-owner-when-no-held-credential-can-resolve-it-...md
  already covers the attention-vs-dashboard routing split; not duplicated here.
- ux-writing/permanently-partial-sync-has-almost-no-consumer-prior-art-...md covers copy VOCABULARY for
  partial/import states; this entry covers a different copy question — remediation-string OWNERSHIP and
  the never-tell-the-user-to-wait-for-something-that-cannot-happen rule — and cites NN/g directly, which
  that entry does not.
- A sibling agent is concurrently researching graceful shutdown / in-flight work lifecycle — disjoint topic,
  not touched here.
-->

## CLAIMS

### Fine-grained dependency tracking: the general mechanism

- Salsa records, for every "tracked function" (a memoized derived computation), the exact set of other tracked functions/inputs it read during its last execution — its dependency edges are captured *as a side effect of running it*, not declared up front. [salsa-overview]
- Salsa's revalidation model ("red-green algorithm") assigns the database a single monotonically increasing revision counter, incremented on every input write; for each input it records the revision it last changed in, and for each tracked function it records, per dependency edge, the revision at which that dependency's value last changed. [salsa-algorithm]
- On a query, Salsa walks a function's *recorded* dependency edges (not the whole graph) and checks each one's last-changed revision against the current revision; only if a dependency changed since the function last ran does Salsa re-execute the function body — everything else is served from the memoized result untouched. [salsa-algorithm]
- Salsa's "backdating" (a.k.a. early cutoff): when a changed input forces a tracked function to re-execute, and the freshly recomputed output is byte-for-byte equal to the previous output, Salsa records that output as unchanged — "even though the inputs changed, the output didn't" — so nothing that depends on this function's *output* is invalidated, even though the function itself *did* re-run. [salsa-algorithm]
- Salsa layers a coarser "durability" tier on top of exact dependency tracking purely as a cheap pre-filter: inputs are tagged by how often they change (e.g. third-party crate inputs = high durability, current-workspace inputs = low durability), and if a function depends transitively only on high-durability inputs, Salsa can skip walking its edges one by one when a low-durability input changes elsewhere — but this is described as an optimization *on top of* exact tracking, not a substitute for it. [salsa-overview]
- Bazel's Skyframe states fine-grained invalidation as a correctness property, not merely a performance one: "If all the input data of all functions is recorded, Bazel can invalidate only the exact set of nodes that need to be invalidated when the input data changes." [bazel-skyframe]
- Skyframe builds a complete data-flow graph from inputs to outputs and computes invalidation as "the reverse transitive closure of the set of changed input files" — i.e. a changed input invalidates exactly its dependents-of-dependents, not the whole node graph and not a same-named sibling that happens to share a version counter. [bazel-skyframe]
- Skyframe's dependency edges are discovered implicitly during evaluation: a `SkyFunction` calls `getValue()` on whatever it needs, and that call is what registers the edge — so the graph reflects what a computation *actually read*, mirroring Salsa's mechanism despite the unrelated implementation. [bazel-skyframe]
- Skyframe also implements change pruning, the same idea as Salsa's backdating under a different name: after an invalidated node is rebuilt, if its new value is identical to the old one, the nodes that were invalidated *because of* this node are "resurrected" — Bazel's own example is editing a C++ comment: the `.o` file node is invalidated and rebuilt, but because the rebuilt object file is byte-identical, the linker step is never re-run despite having a "stale" input edge on paper. [bazel-skyframe]
- Bazel explicitly names bottom-up invalidation (walk from the changed input toward its dependents) as its chosen strategy, contrasted with a top-down "verify graph cleanliness" alternative; which is optimal is stated to depend on the graph's shape. [bazel-skyframe]
- Fine-grained/dependency-tracked invalidation and the coarse "did-the-formula-version-change" checkpoint answer two different questions: the coarse checkpoint answers "could anything be stale" (cheap, one comparison, false positives allowed); dependency tracking answers "is *this specific derived value* actually stale" (more expensive to build, zero false positives by construction, because staleness is derived from what was *read*, not from a version label attached after the fact).

### Actionable remediation copy

- Nielsen Norman's error-message guidance requires specificity over genericness: "Generic messages such as An error occurred lack context. Provide descriptions of the exact problems." [nng-error-messages]
- NN/g requires that a stated problem come with a remedy: "Merely stating the problem is also not enough; offer some potential remedies." [nng-error-messages]
- NN/g bars blaming language: "Don't use phrasing that blames users or implies they are doing something wrong, such as invalid, illegal, or incorrect." [nng-error-messages]
- NN/g's "simplify correction" guidance — "If possible, guess the correct action and let users pick it from a small list of fixes" — implies the remedy shown must be an action the *reader* can actually take; it does not contemplate a remedy that requires no user action and cannot be performed by the party reading it. [nng-error-messages]
- None of NN/g's guidelines explicitly separate "you (the user) must act" from "the system will resolve this on its own" as two different message shapes — the corpus does not supply a standard vocabulary for that split; it must be derived from the actionability principle applied strictly (see SYNTHESIS).

### Thundering herd / staggered recovery after mass invalidation

- AWS's jitter analysis states plain exponential backoff without jitter still synchronizes clients into "clusters of calls" — spreading *when* clients are idle, not *whether* they collide: "Instead of reducing the number of clients competing in every round, we've just introduced times when no client is competing." [aws-jitter]
- AWS names and formulas three jitter strategies: **Full Jitter** `sleep = random(0, min(cap, base * 2**attempt))`, which the source states produces the lowest overall client work and best completion time among the three; **Equal Jitter** `sleep = base*2**attempt/2 + random(0, base*2**attempt/2)`, which never lets sleep drop to zero; and **Decorrelated Jitter**, which derives its next window from the previous sleep value and does slightly more total work than Full Jitter but still much less than no jitter. [aws-jitter]
- Google's CRE team frames synchronized recovery as a self-inflicted DDoS with a hard capacity number: "If you experience a 15-minute error... you'll need to provision at least 15X of your normal capacity to keep from falling over" if clients retry on a fixed interval and back off together once the dependency recovers. [google-cre-ddos]
- Google's CRE piece adds a second technique beyond jitter: mark every retry attempt with an ordinal ("A value of zero means that the request is a regular sync. A value of one indicates the first retry and so on"), so the recovering backend can *triage* — "cap the overall retry load to a fixed percentage, say 10%, and service all the regular syncs and only 10% of the retries" — rather than treating all inbound load as equally urgent. [google-cre-ddos]
- Google's CRE piece recommends jitter even on the *steady-state* schedule, not only on retries: "it's also a really good idea to add a little jitter (perhaps 10%) to regular sync intervals, in addition to your retries" — i.e. jitter is prophylactic against a herd forming again, not just reactive to one that has already formed. [google-cre-ddos]

## SOURCES

**salsa-algorithm**
URL: https://salsa-rs.github.io/salsa/reference/algorithm.html
Accessed: 2026-08-21
Quote: "If it's the same as last time, we can backdate the result, meaning that we say that, even though the inputs changed, the output didn't."
Note: Fetched via WebFetch summarization, not a raw byte-for-byte quote pull; the "red-green" revision-counter mechanism and per-edge last-changed-revision comparison are described consistently across this page and salsa-overview, so treat as high confidence but re-verify exact wording before quoting in a spec.

**salsa-overview**
URL: https://salsa-rs.github.io/salsa/overview.html
Accessed: 2026-08-21
Note: WebSearch summary (not raw fetch) covering Inputs vs Functions, the durability-tier optimization layered on top of exact dependency tracking, and rust-analyzer as the flagship consumer.

**bazel-skyframe**
URL: https://bazel.build/reference/skyframe
Accessed: 2026-08-21
Quote: "If all the input data of all functions is recorded, Bazel can invalidate only the exact set of nodes that need to be invalidated when the input data changes."
Quote (change pruning): "the nodes that were invalidated due to a change in this node are 'resurrected'"
Note: Change-pruning example (C++ comment edit invalidates the .o node but the rebuilt object is byte-identical so the linker step is not re-run) and the bottom-up-vs-top-down invalidation-strategy note were extracted via WebFetch summarization of the official reference doc, not a raw fetch; re-verify exact phrasing before quoting verbatim in a design doc.

**k8s-api-conventions-condition**
URL: https://raw.githubusercontent.com/kubernetes/community/master/contributors/devel/sig-architecture/api-conventions.md
Accessed: 2026-08-19 (re-used from the existing corpus entry `api-contract-design/health-vocabularies-separate-a-lifecycle-axis-from-a-verdict-axis-...md`, not re-fetched this session)
Quote: "For known conditions, the absence of a condition status should be interpreted the same as Unknown, and typically indicates that reconciliation has not yet finished (or that the resource state may not yet be observable)."
Quote: "Controllers should apply their conditions to a resource the first time they visit the resource, even if the status is Unknown. This allows other components in the system to know that the condition exists and the controller is making progress."

**nng-error-messages**
URL: https://www.nngroup.com/articles/error-message-guidelines/
Accessed: 2026-08-21
Quote: "Generic messages such as An error occurred lack context. Provide descriptions of the exact problems."
Quote: "Merely stating the problem is also not enough; offer some potential remedies."
Quote: "Don't use phrasing that blames users or implies they are doing something wrong, such as invalid, illegal, or incorrect."
Quote: "If possible, guess the correct action and let users pick it from a small list of fixes."

**aws-jitter**
URL: https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
Accessed: 2026-08-21
Quote: "there are still clusters of calls. Instead of reducing the number of clients competing in every round, we've just introduced times when no client is competing."
Quote (Full Jitter): "sleep = random(0, min(cap, base * 2 ** attempt))"
Quote (Equal Jitter): "sleep = base * 2 ** attempt / 2 + random(0, base * 2 ** attempt / 2)"
Note: Fetched via WebFetch summarization of the official AWS Architecture Blog post (the canonical "Exponential Backoff and Jitter" article, Marc Brooker, 2015 — still the standard citation for Full/Equal/Decorrelated jitter as of 2026).

**google-cre-ddos**
URL: https://cloud.google.com/blog/products/gcp/how-to-avoid-a-self-inflicted-ddos-attack-cre-life-lessons
Accessed: 2026-08-21
Quote: "If you experience a 15-minute error (still well within your 99.9% availability) then all of your load will be locked together until after your backends recover. You'll need to provision at least 15X of your normal capacity to keep from falling over."
Quote: "An easy and effective technique to do this is to have your clients mark each attempt with a retry number... the backends can prioritize which requests to service and which to ignore as things get back to normal."
Quote: "it's also a really good idea to add a little jitter (perhaps 10%) to regular sync intervals, in addition to your retries."

## SYNTHESIS

### The distinction the whole ticket turns on

A version/generation counter and a dependency graph answer different questions, and the fence in this ticket is asking a dependency-graph question with a version-counter tool. "Generation N of connection C's manifest" is a single scalar covering the *entire* manifest — every stream, every field, every piece of cosmetic metadata. Bumping it on any edit is the correct, conservative answer to "could this evidence be stale," and it is cheap: one integer compare, exactly the pattern the companion entry (`derived-state-staleness-after-a-code-upgrade-...md`) already recommends and PDPP should keep for that question. But "could be stale" is not "is stale for the specific evidence a given condition is built from," and a single scalar structurally cannot express that difference — this is exactly Salsa's and Skyframe's starting complaint about coarse checkpoints, restated: a checkpoint answers "did an input change," dependency tracking answers "did an input *this computation actually read* change." Bumping one counter for 14 manifests and blanking 15 of 25 sources is the generation-fence equivalent of Bazel invalidating the whole build graph because one file's mtime changed, instead of invalidating only the targets that declared a dependency on that file.

The mechanism to fix this is not novel or exotic — it is the same idea in three unrelated implementations (Salsa for a compiler, Skyframe for a build system, and Adapton in the research literature that both cite as ancestor), which is itself evidence this is a solved, well-understood shape rather than something to invent from scratch. The idea has two parts, and PDPP's evidence engine already has the raw materials for both:

1. **Record what was actually read, not just that something changed.** Every condition in `connection-health.ts` already reads a *specific* durable/live source (credential store, `record_snapshot`, browser-surface lease, schedule row, etc.) — the 2026-08-19 entries document this per-condition. The manifest itself is not monolithic either: it has named fields per stream (auth requirements, coverage strategy, field schemas, `maximum_staleness_seconds`, etc.). A generation bump caused by editing stream X's field schema has no logical bearing on a condition that only ever reads stream Y's schedule row. Recording, per condition (or per evidence-cache row), *which manifest fields it was computed against* is Salsa's dependency edge and Skyframe's `getValue()` registration, applied to PDPP's own evidence graph instead of a compiler's AST.
2. **Diff the manifest edit itself before fencing on it.** This is Bazel's change pruning / Salsa's backdating, run one step earlier: instead of re-validating evidence and discarding an unchanged *output* (expensive — it requires re-running the thing you were trying to avoid re-running), diff the *new manifest against the old one* at write time and record which top-level sections actually changed. A manifest edit that only touched, say, `streams.messages.field_schema` should invalidate conditions whose recorded dependency set intersects `streams.messages.*`, and leave every condition whose dependency set is disjoint from that (schedule, credential, browser-surface, all *other* streams) untouched. This is cheaper than true fine-grained tracking (no need to trace every condition's exact read-set at evaluation time) and still captures the overwhelming majority of the value, because manifest edits are rarely all-fields-at-once; PDPP's own trigger case — "a routine edit to 14 manifests" — is very unlikely to have touched every field of every one of those 14.

The two combine into a two-tier fence, matching Salsa's own two-tier design (exact edges plus a coarse "durability" pre-filter): keep the current whole-manifest generation counter as the outer, conservative "could be stale" signal (cheap, always correct in the false-positive direction, matches the companion entry's recommendation) — but gate *which conditions actually re-derive to unknown* on a per-condition-class manifest-section dependency declaration, so a generation bump is necessary-but-not-sufficient for blanking a specific condition. This is strictly additive to the existing fence, not a replacement of it, and it is the kind of change that is naturally incremental: start with the two or three highest-blast-radius conditions (the ones that fired in this incident) and widen the dependency map over time, exactly as a codebase migrating onto Salsa adds `#[salsa::tracked]` incrementally rather than all at once.

### Status taxonomy: four distinct "we don't have a verdict" states, not one

PDPP's existing `unknown` state (settled by the 2026-08-19 corpus entries as "we have not measured this yet, never a failure, renders grey") is being asked to do the work of at least three semantically distinct situations, and Kubernetes' own vocabulary — additive, open-world conditions, a required `reason` field — already supplies the discriminator PDPP is missing: it just needs to be *used*, not invented.

1. **No data ever** (never run, or `not_applicable` per the existing corpus disposition) — structurally different from "unknown," already correctly modeled by PDPP's `not_applicable` per the settled entry; not this ticket's bug.
2. **Data exists, verdict genuinely unproven** (a run is actively in progress, or the projection sweep hasn't caught up yet) — this is the *already-diagnosed* `ProjectionReliable`-false-while-running defect from the 2026-08-19 entries. Kubernetes' rule applies directly: an in-flight outcome must be `Unknown`, never `False`.
3. **Evidence exists and is current, but superseded by a definition change** — this ticket's actual bug, and it is a *fourth* thing, distinct from both 1 and 2: the data is not stale, the run is not in flight, the projection sweep is caught up — the problem is that the *rule that judges the data* changed underneath it. This state has a genuinely different remedy from state 2 (state 2 clears on its own once the run finishes or the sweep catches up; state 3 clears only if either the fence is proven not to apply per-condition, per the fine-grained fix above, or a *new* run is produced under the new rule).
4. **Genuinely degraded** — a real, current problem with the user's data (expired credential, hard failure, exceeded gap) — the only state that should ever render amber/red under PDPP's existing worst-wins rollup.

State 3 needs its own `reason` value in PDPP's existing closed vocabulary (the corpus entries already establish PDPP has a `reason` field per condition and recommend collapsing `reason_code` into it) — something like `superseded_by_definition_change` — precisely because Kubernetes requires `reason` to be present and machine-branchable on every condition and forbids inferring cause from a shared status value. Collapsing state 3 into state 2's `Wait for the reference read model to refresh` copy is the direct cause of the second reported bug: the remedy text is written for state 2 (clears on its own) and is being shown for state 3 (does not clear on its own, ever, without a new run). One `unknown` bucket cannot carry two remedies that contradict each other; the fix is not a UI copy tweak, it is exposing the `reason` PDPP's own condition schema already has a field for.

### Remediation copy: who computes it, and the one-line rule that would have caught this bug

NN/g's guidance is unambiguous that a stated problem must come with an offered remedy and must not be generic — but the corpus (NN/g here, Plaid and Kubernetes in the existing PDPP entries) is silent on the one failure mode this ticket surfaces: a remedy that is *specific, non-generic, and still wrong*, because it was written for a different cause than the one that actually fired. That is a sharper and more dangerous failure than a vague message, because it passes every checklist item NN/g lists (specific, not blaming, offers an action) while still lying about what will happen if the reader follows it.

The enforceable rule this ticket needs, derived by combining NN/g's actionability principle with Kubernetes' `reason`-required, `message`-is-detail split (already the settled boundary rule in PDPP's own corpus): **remediation copy must be a pure function of `reason`, computed at render time, never stored as a static string on the condition definition.** PDPP's current `ProjectionReliable` condition hardcodes its remediation (`{ action: "wait", label: "Wait for the reference read model to refresh" }`) as a fixed property of the *condition type*, per the 2026-08-19 entry — which is exactly backwards, because the same condition can be `false` for at least two causes (in-flight run vs. superseded-by-generation-fence) that need opposite advice. The remedy belongs to the `reason`, not to the condition: `reason: record_checkpoint_lag` (in-flight) → "wait, this clears automatically"; `reason: superseded_by_definition_change` (this ticket) → "run now — waiting will not resolve this" with a trigger-run action, not a wait action. This mirrors Plaid's `display_message` being null-by-construction when a cause isn't user-actionable (already cited in PDPP's own corpus) — the same structural technique, applied to *which* remedy shows rather than *whether* one shows at all. Ownership: the projection computes `reason` (it is the only thing that knows the cause); a small reason→copy table, versioned alongside the closed `reason` vocabulary the corpus entries already recommend consolidating, computes the string — not the UI, and not a static per-condition template.

### Auto-trigger vs. wait, after mass invalidation

The thundering-herd literature (AWS, Google CRE) was written for machine-to-machine retries, but its logic transfers cleanly to "should a mass generation-fence event auto-fire refresh runs," with one load-bearing addition the literature doesn't have to consider: **some of PDPP's retries require an interactive human, so this is not a pure backoff-and-retry problem — it is backoff-and-retry with a subset of nodes that cannot legally auto-fire at all.**

Recommendation, layered:

- **Auto-trigger is right in principle for the failure mode described.** The Google CRE framing applies almost exactly: 15 of 25 sources went unknown simultaneously from one edit, which is a synchronized-recovery event structurally identical to "all clients hit a timeout at once" — the fix category (don't force every affected party through the same clock-driven recovery path at once) is the same regardless of whether the "clients" are HTTP callers or scheduled connector runs.
- **Never fire all 15 at the moment of invalidation.** That reproduces the exact self-inflicted-DDoS shape CRE describes, aimed at the upstream data providers instead of a backend fleet — same mechanism, different victim (a provider rate limit or bot-detection system instead of a load balancer). Apply AWS's Full Jitter formula directly to the re-run schedule: spread the 15 triggered runs across a bounded window using `random(0, cap)` rather than firing them all in the same tick or on the same fixed cadence.
- **Partition auto-triggerable from human-gated *before* scheduling anything**, using a property PDPP's manifests already declare per the 2026-08-19 corpus entries (`recommended_mode: manual` / `background_safe: false` for import-only connectors like `google_takeout`). The same declared field that already means "never runs on schedule" should mean "never runs on invalidation either" — this is not a new concept, it's applying an existing manifest flag to a new trigger source. For interactive-login connectors, auto-triggering a run a human isn't watching either fails silently (no one to complete an OAuth/2FA prompt) or, worse, produces a burst of provider-visible login attempts with no human present to react to a challenge — worse than the status quo, not better.
- **For human-gated connectors, the correct response to mass invalidation is exactly the copy fix above, not an auto-run**: surface `reason: superseded_by_definition_change` with an explicit "run required" action the human can trigger, rather than either a silent auto-run or the current false "wait" message. This is the CRE "mark each attempt with a retry number and let the backend triage" idea, inverted: instead of the *system* triaging incoming load, the *human* is the triage step, and the system's job is only to make the queue of "these need you" visible and correctly labeled — which is the existing `RequiredAction`/attention-routing mechanism the corpus already documents in `feedback-systems/mature-integrations-only-interrupt-the-owner-when-no-held-credential-can-resolve-it-...md`, applied to a new cause.
- **Rate-limit auto-triggered runs against the same governor real runs already respect**, not a separate ad hoc cap — CRE's "retry number" idea generalizes to "invalidation-triggered run" as a labeled run-cause, so the existing per-provider rate governor (already in PDPP per the `client-side-rate-governance` corpus entry) can deprioritize or throttle invalidation-triggered runs relative to user-initiated ones without new infrastructure.

### What would change this recommendation

If PDPP's manifest edits are almost always all-fields-at-once in practice (not just occasionally, as assumed above), the per-section dependency map buys little over the current whole-manifest fence, because most edits would touch every tracked section anyway — this is worth checking against real manifest-diff history before investing in the fine-grained fix. If the projection's per-condition evidence sources turn out to already be cleanly separable by manifest section (rather than several conditions reading overlapping or ambiguous parts of the manifest), the fine-grained fix is cheaper than estimated above; if they're tangled, it's more expensive and the value shifts further toward "just add the fourth status + reason + correct copy" as the higher-value, lower-cost fix to ship first, deferring the dependency-tracking piece.

### Confidence

High confidence on Salsa's and Bazel's mechanisms (WebFetch summarization of the official docs; the two independent implementations converging on the same idea — record what was read, backdate/prune unchanged outputs — is strong corroboration even without a byte-exact quote pull) and on the AWS jitter formulas and Google CRE retry-marking idea (both are canonical, widely-cited primary sources, fetched directly). Medium confidence on exact wording of the Bazel change-pruning quote and Salsa's backdating quote, since both came through WebFetch's summarization layer rather than a raw document read — re-verify exact phrasing before quoting either verbatim in a design doc, though the underlying claims are corroborated by multiple independent descriptions of the same systems in prior literature (rust-analyzer's own "Durable Incrementality" post, and Adapton's dirty-marking description, both surfaced in search but not separately fetched this session). High confidence on the PDPP-application synthesis being consistent with the existing corpus, since it was built by reading the two 2026-08-19 entries and the 2026-08-16 code-version entry in full rather than from memory, and every PDPP-specific fact used here (condition schema, `reason` field, `ProjectionReliable` hardcoded remediation, manifest `recommended_mode`/`background_safe` flags) is cited to those entries' own file:line evidence, not re-derived. Not verified: I did not read PDPP's actual manifest-diff or generation-bump code in this session (no code was read; this was corpus-only research per the task's explicit "change no code" instruction), so the claim about how manifest sections currently map (or fail to map) to conditions is an inference from the settled corpus, not a fresh code read — verify against `connection-health.ts` and the manifest-generation-bump call site before implementing.
