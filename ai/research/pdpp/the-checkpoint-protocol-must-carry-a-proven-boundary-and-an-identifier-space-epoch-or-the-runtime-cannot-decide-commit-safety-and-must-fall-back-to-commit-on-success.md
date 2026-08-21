---
title: "PDPP's runtime cannot decide whether a staged cursor is safe to commit because the protocol types it `cursor: unknown` — commit_on_success is a no-information fallback, not a safety judgment; the fix is a self-describing checkpoint carrying a proven-complete boundary, an outstanding-debt list, and an identifier-space epoch, which makes safe-at-any-instant true by construction and dissolves the drain question"
date: 2026-08-21
topic: pdpp
tags: [checkpoint, cursor, commit-protocol, interrupted-work, graceful-shutdown, coverage, connector-contract, decision]
status: settled
sources: [pdpp-code, pdpp-prod-postgres, pdpp-connector-survey, kafka-design, flink-e2e, cl85, rfc9110-range, tus-protocol, imap-rfc3501, stripe-pagination]
source_session: af82d1f3-1838-4307-a3a9-6bbf07e77c6f
---

<!--
Companion / do-not-duplicate map. Four entries written 2026-08-21 in this same session cover
adjacent ground; this entry cites and does NOT restate them:
  - pdpp/interrupted-work-needs-an-owner-fenced-terminal-state-not-a-graceful-shutdown-...md
    — THE decision doc on owner-epoch adjudication, the 121 stranded runs, the controller_id
    defect, and the anti-drain argument. This entry answers the ONE question that doc explicitly
    left open and gated (its SYNTHESIS §11): "does per-stream commit under INTERRUPTED hold for
    every connector, or only for those emitting bounded DETAIL_COVERAGE?" Read that doc first.
  - distributed-systems/when-the-shutdown-grace-window-is-shorter-than-a-unit-of-work-...md
    — grace-window budgets and worker strategies.
  - distributed-systems/a-dying-worker-never-writes-its-own-terminal-state-...md — zombie fencing.
  - distributed-systems/lease-reclamation-and-checkpoint-commit-ordering-...md — Kafka/Flink/WAL
    commit-ordering prior art. Cited here, not re-derived.

THIS entry's unique contribution: the checkpoint PROTOCOL/CONTRACT layer. The four siblings all
ask "who writes the terminal state and when." This one asks "what must a checkpoint SAY for the
runtime to reason about it at all" — and answers it with a full 43-connector/162-stream survey
that re-derives the cursor taxonomy from source rather than inheriting it.
-->

## CLAIMS

### A. The root cause is a type, not a policy

- The connector→runtime protocol types the checkpoint payload as fully opaque: `| { type: "STATE"; stream: string; cursor: unknown }` [pdpp-code `packages/polyfill-connectors/src/connector-runtime-protocol.ts:456`].
- The runtime's *complete* validation of a cursor is that it is a non-array object or null. There is no structural claim of any kind: `if (!isNullish(msg.cursor) && (typeof msg.cursor !== "object" || Array.isArray(msg.cursor))) throw` [pdpp-code `reference-implementation/runtime/index.ts:1199-1201`].
- Therefore the runtime has exactly zero information with which to distinguish a safe cursor from an unsafe one. `state_commit_intent: persistState ? "commit_on_success" : "do_not_persist"` [pdpp-code `runtime/index.ts:2642`, `:3939`] is not a risk judgment — it is the only decision derivable from no information. **`commit_on_success` is a no-information fallback.**
- The commit MECHANISM is already fully incremental and idempotent. `commitState(stream, cursor)` is a per-stream `PUT /v1/state/{connectorId}` with a single-key body `{ state: { [stream]: cursor } }`, emitting `run.state_advanced` [pdpp-code `runtime/index.ts:3451-3495`]. Only the *decision* is deferred to DONE — the plumbing to commit mid-run exists and is exercised today.
- The deferral is one branch: `if (persistState && (done.status === "succeeded" || isCertifiedStreamCollectionFailure))` [pdpp-code `runtime/index.ts:4933`]. Every staged cursor outside it is discarded while its records stay durable.
- PDPP already has a richer per-stream evidence vocabulary that the STATE message cannot reference: `DetailCoverageMessage{considered, covered, required_keys, hydrated_keys, gap_keys, state_stream}` [pdpp-code `connector-runtime-protocol.ts:192-231`] and `RuntimeContinuationFact{boundary, considered, covered, slice_start, slice_end, remaining}` [pdpp-code `:233-241`]. These describe DETAIL HYDRATION coverage, are carried on `DETAIL_COVERAGE`/`SKIP_RESULT`, and are **structurally disjoint from the cursor** — no field of either binds to a cursor position.
- `RuntimeContinuationFact.slice_start`/`slice_end` are validated as plain non-negative safe integers and `boundary` as a non-empty free-text string [pdpp-code `:252-264`]. Nothing ties a slice to an identifier space, so a slice is not comparable across runs after a provider re-seed.

### B. Measured cost of the no-information fallback (live production)

- Fleet-wide, **130,517 `run.state_staged` versus 75,513 `run.state_advanced`** — 42% of all staged checkpoint work is discarded. Only 5 `run.state_commit_failed` [pdpp-prod-postgres].
- **612 of 13,750 distinct checkpointing runs staged at least one cursor and committed none** [pdpp-prod-postgres].
- Restricting to terminal runs that staged ≥1 stream and reported `checkpoint_commit_status = not_committed`: **465 runs across 14 connectors durably ingested 897,916 records and advanced no cursor** [pdpp-prod-postgres]. Per connector, records ingested with zero cursor advance: chatgpt 362,977 (44 runs); codex 294,500 (1); gmail 203,417 (273); ynab 14,972 (95); amazon 14,163 (11); slack 3,519 (5); whatsapp 3,179 (1); reddit 545 (2); jellyfin 504 (1); github 93 (27); claude-code 44 (1); usaa 5 (1); steam 2 (2); chase 2 (1).
- This corrects the framing of the Gmail incident: Gmail is **23%** of the loss, not the whole of it. The defect is systemic to the protocol, not a Gmail bug.

### C. The 43-connector / 162-stream survey (re-derived from source, not inherited)

- The fleet is **43 connectors** (`packages/polyfill-connectors/manifests/*.json`, 43 files; `connectors/` holds 44 dirs of which `_conformance` is fixtures) declaring **162 streams**. The prior "44/45 connector" counts were off by the fixture directory.
- **`two_pointer` over one ordered space exists in exactly one connector: gmail.** `messages` carries `{all_mail:{uidvalidity, uidnext, forward_uidnext, highest_modseq}, backfill:{backfilled_through_uid, target_uid, completed_at}}` — `forward_uidnext` is the high watermark, `backfilled_through_uid`/`target_uid` the debt floor/ceiling [pdpp-code `connectors/gmail/index.ts:3424-3436`; consumed `:1442`, `:1477-1485`; regression/overshoot guard `:1489-1507`]. `attachments` is a degenerate floor-only variant [`:2276-2286`]. This confirms the prior survey's headline claim against the current tree.
- Gmail is also the only connector carrying an **identifier-space epoch**: `uidvalidity`, IMAP's re-seed detector [imap-rfc3501]. No other connector in the fleet persists any equivalent.
- **`partition_map_with_global_fallback` — the unsafe shape — exists and is LIVE in production, in slack `messages`.** `dedupWhere = "WHERE m.TS > COALESCE(t.last_ts, ?)"` binding the workspace-global `legacyLastTs` [pdpp-code `connectors/slack/index.ts:2024-2026`]. The safe sibling branch (`WHERE t.last_ts IS NULL OR m.TS > t.last_ts`) is selected only when no legacy global is present [`:2027-2029`]. Production state proves the unsafe branch is the live one: the newest `run.state_advanced` cursor for slack/messages holds `last_ts = "1787003747.530359"` (2026-08-17T21:55:47Z) alongside a `channel_last_ts` map of **569 channels** [pdpp-prod-postgres]. Any channel not among those 569 inherits the 2026-08-17 floor and its entire history below it is unreachable.
- Slack `messages` has a second, independent defect: the watermark advances over every row *iterated*, including rows never emitted. `maxMessageTs`/`recordChannelMaxTs` run before the `if (wantMessages)` guard, and the in-tree comment states it outright — "the loop still runs (rows are iterated) but emits nothing; maxMessageTs still advances so the STATE checkpoint is accurate" [pdpp-code `connectors/slack/index.ts:1558-1561`, `:1602-1607`]. A run scoped to `reactions` burns the `messages` watermark.
- **Every other partition map in the fleet fails SAFE** — an absent partition triggers a full/cold walk, never a global floor. Verified per connector: ynab `state?.[budgetId]?.server_knowledge` → `undefined` [`connectors/ynab/index.ts:484-487`]; chase `chooseActivity` returns `"all"` for an absent account [`connectors/chase/parsers.ts:794-817`]; usaa absent account widens to a fixed 17-month backfill floor, not a high watermark [`connectors/usaa/index.ts:2229`, `:2289`]; amazon `planIncrementalYears` includes newly-discovered years [`connectors/amazon/index.ts:1541-1574`]; groupme routes to a full backward walk [`connectors/groupme/index.ts:1871-1879`]; google_calendar/apple_contacts send no sync token [`connectors/google_calendar/index.ts:166-172`; `connectors/apple_contacts/index.ts:401`].
- **The dominant fleet shape is not positional at all.** A large majority of streams are `full_refresh_none` or fingerprint-map `completion_flag`s built on `openFingerprintCursor`, whose next-map is seeded by copying the prior map, so an id absent from the map always re-emits [pdpp-code `packages/polyfill-connectors/src/fingerprint-cursor.ts:86-116`]. These record position for nothing and **cannot skip data in either direction**. Genuinely positional cursors are a minority.
- **Six connectors are scaffolds emitting no STATE at all**: anthropic, loom, meta, linkedin, doordash, uber, shopify, wholefoods — each emits a single `SKIP_RESULT{*_wiring_pending}` (8 connectors; anthropic/loom/meta/linkedin/doordash/uber/shopify/wholefoods) [pdpp-code `connectors/anthropic/index.ts:41-48`, `connectors/uber/index.ts:52-57`, et al.].
- **The safety of nearly every remaining stream is an accident of emission TIMING, not of cursor shape.** Newest-first walks that would strand history if committed early — heb `orders` (`newestOrderDate` set from page 1 before the older pages are walked [`connectors/heb/index.ts:866-868`]) and groupme `group_messages` (`newestMessageId = messages[0]?.id` on the cold-start backward walk [`connectors/groupme/index.ts:1381-1383`]) — are safe **only because STATE is emitted once, after the walk returns** [`heb:1143-1147`; `groupme:2073-2079`]. Moving either emit inside its loop silently converts it into permanent data loss, and no runtime check would notice.
- The same is true of the archive connectors. apple_health, apple_photos, google_takeout, twitter_archive, netflix_export all advance a `single_watermark` as a running max over an **unordered** traversal (directory order, filename-sorted order, CSV row order — none sorts by the cursor field), so the watermark leads the emitted records at every instant *between* records [pdpp-code `connectors/apple_health/index.ts:107,127`; `connectors/apple_photos/index.ts:213`; `connectors/google_takeout/index.ts:128-130`; `connectors/twitter_archive/index.ts:87,145`; `connectors/netflix_export/index.ts:309-311`]. Only end-of-stream emission makes them safe.
- google_maps is the fleet's one connector that gates its own commit on proven completeness: `if (!summary.complete) { return; }` suppresses the STATE emission entirely, with `complete` cleared by incomplete discovery, any per-file parse failure, or a schema-invalid record [pdpp-code `connectors/google_maps/index.ts:393-396`, `:385-386`, `:180`]. This is the shape the contract below generalizes.
- Truncation ceilings that silently look like completion exist: reddit exits at `MAX_PAGES = 100` with no truncation signal while the watermark still advances over what was collected [pdpp-code `connectors/reddit/parsers.ts:26`, loop guard `connectors/reddit/index.ts:297`, `parsers.ts:234`]; google_calendar's `MAX_PAGES_PER_CALENDAR = 200` can end a walk with no SKIP_RESULT [`connectors/google_calendar/index.ts:70`, `:188`]; github `pull_requests` emits STATE unconditionally, outside the `if (capTruncatedWindows === 0)` guard that withholds the coverage claim [`connectors/github/index.ts:1046-1052`].
- Coverage honesty and cursor safety are **demonstrably different properties**. github `starred` reports itself `partial` with `covered = totalEvaluated - droppedTotal` yet still advances its watermark past the dropped entries [pdpp-code `connectors/github/index.ts:491-503`, `:581-584`]. jellyfin `items` writes `last_fetched_at` per library but nothing ever reads it, so a false claim there loses nothing [`connectors/jellyfin/index.ts:892-895`, `:794-863`]. A predicate over coverage alone therefore both over- and under-approximates cursor safety.
- chatgpt `messages` advances `last_update_time` to the max over every *listed* conversation including ones whose detail fetch failed — safe only because those become durable `DETAIL_GAP` rows recovered on a later run [pdpp-code `connectors/chatgpt/index.ts:4397-4408`]. The cursor's honesty depends on a side-channel the cursor does not mention.

### D. Run durations against the 10s bound (live, re-measured)

- `docker inspect pdpp-core-prod-drain` → `StopTimeout=<nil> StopSignal= Restart=unless-stopped`, image `pdpp-core:drain28`. Production runs on Docker's 10s default [pdpp-prod-docker].
- Terminal-run durations, last 60 days, bounded to <24h to exclude runs terminalized days later by a reconciler (`n`, p50s, p95s, %≤10s) [pdpp-prod-postgres]:
  slack 665, 281.2, 4052.8, 2.6% | venmo 7, 902.9, 1814.8, 28.6% | reddit 63, 9.4, 1812.5, 52.4% | usaa 69, 273.9, 1742.8, 5.8% | groupme 13, 216.3, 1433.0, 0.0% | ynab 1152, 586.8, 1221.6, 2.6% | chatgpt 790, 14.5, 1145.1, 25.1% | amazon 169, 103.9, 1065.9, 4.7% | heb 48, 25.2, 742.1, 0.0% | chase 34, 132.4, 627.6, 2.9% | whatsapp 7, 44.0, 339.0, 0.0% | gmail 6040, 27.9, 232.3, 21.1% | notion 10, 91.9, 164.8, 0.0% | jellyfin 11, 118.0, 160.1, 0.0% | github 2365, 8.6, 15.3, 83.1% | steam 14, 5.3, 7.4, 92.9% | apple_contacts 16, 1.3, 1.6, 100%.
- Only **2 of 17** connectors (steam, apple_contacts) finish inside 10s at p95. Slack's p95 is **405× the budget**; its p99 is 14,400s (4h). Median run for 8 of 17 connectors already exceeds the entire stop budget.
- The shipped 5s drain confirmed failing in production, verbatim from the container log: `{"drained":0,"elapsedMs":5000,"timedOut":1,"msg":"connector run drain complete"}` and a second `{"drained":1,"elapsedMs":2013,"timedOut":0}` [pdpp-prod-docker]. Confirms the sibling decision doc's measurement independently.

## SOURCES

**pdpp-code**
URL: /home/tnunamak/code/pdpp @ cf4f1a701
Accessed: 2026-08-21
Quote: `| { type: "STATE"; stream: string; cursor: unknown }` (`packages/polyfill-connectors/src/connector-runtime-protocol.ts:456`)

**pdpp-prod-postgres**
URL: live instance — `docker exec pdpp-postgres-1 psql -U pdpp -d pdpp`
Accessed: 2026-08-21
Quote: 130,517 `run.state_staged` vs 75,513 `run.state_advanced`; 465 terminal runs `not_committed` holding 897,916 durable records; slack `channel_last_ts` = 569 channels alongside global `last_ts` 1787003747.530359.

**pdpp-prod-docker**
URL: live instance — `docker inspect pdpp-core-prod-drain`, `docker logs`
Accessed: 2026-08-21
Quote: `StopTimeout=<nil>`; `{"drained":0,"elapsedMs":5000,"timedOut":1}`

**pdpp-connector-survey**
URL: /home/tnunamak/code/pdpp — 43 manifests, 162 streams, all `type: "STATE"` sites read
Accessed: 2026-08-21

**imap-rfc3501**
URL: https://www.rfc-editor.org/rfc/rfc3501
Accessed: 2026-08-21
Quote: UIDVALIDITY — if it changes, "the client MUST discard its cache" of UIDs; UIDs are only comparable within one UIDVALIDITY epoch.

**kafka-design**
URL: https://github.com/apache/kafka/blob/trunk/docs/design/design.md
Accessed: 2026-08-21
Quote: "letting the consumer store its offset in the same place as its output."

**flink-e2e**
URL: https://flink.apache.org/2018/02/28/an-overview-of-end-to-end-exactly-once-processing-in-apache-flink-with-apache-kafka-too/
Accessed: 2026-08-21
Quote: "After a successful pre-commit, the commit must be guaranteed to eventually succeed."

**cl85**
URL: https://lamport.azurewebsites.net/pubs/chandy.pdf
Accessed: 2026-08-21

**rfc9110-range**, **tus-protocol**, **stripe-pagination**
Accessed: 2026-08-21 (see sibling entry `lease-reclamation-and-checkpoint-commit-ordering-...` for full quotes; cited here for the durable-externally-meaningful-position rule.)

## SYNTHESIS

### 1. The question the owner actually asked

Not "which connectors are safe today" — that is archaeology, and it decays the moment someone edits a connector. The question is: **what must the checkpoint contract be able to EXPRESS, so the runtime can decide commit safety without knowing anything about the connector?**

The survey's job is to prove the answer is expressible by real connectors and to find the cases that break a naive contract. It does both, and it also produces the decisive negative result: **today, safety is not a property of the cursor. It is a property of when the connector happens to emit.** heb and groupme are safe only because their STATE emission sits outside the loop; move it inside and you get permanent data loss with no runtime check firing and no test failing. That is an unowned invariant held in place by nothing but code review.

### 2. The minimal self-describing checkpoint

Four fields. Each justified by a specific demonstrated failure; anything not preventing an observed failure is rejected.

```jsonc
{ "type": "STATE", "stream": "messages",
  "cursor": { /* unchanged, still connector-private */ },

  // The claim. Present ⇒ connector asserts commit-safety. Absent ⇒ stage only.
  "checkpoint_claim": {
    "space": "gmail:all_mail:uidvalidity=1637159102",  // 1. identifier-space epoch
    "complete_through": "48213",                        // 2. proven-complete boundary
    "debt": [{"from": "1", "to": "48212", "kind": "backfill"}],  // 3. outstanding debt
    "partition": "C016HTUEMHD"                          // 4. optional partition key
  }}
```

**1. `space` — the identifier-space epoch.** Prevents: a provider re-seed silently making a stale position look valid. Gmail is the only connector that already carries this (`uidvalidity`); IMAP invented it because the failure is real. Without it, `complete_through: "48213"` is a number with no meaning across a mailbox re-creation. The runtime's rule is pure equality — commit only if `space` matches the stored `space`, else discard the prior cursor and cold-start. No provider knowledge required. This is also what `RuntimeContinuationFact.slice_start/slice_end` lack today: bare integers with nothing to make them comparable across runs.

**2. `complete_through` — the proven-complete boundary.** Prevents: committing a watermark that leads the emitted records. This is the field the archive connectors need and the one slack `messages` violates. Its meaning is fixed and connector-independent: *every item in this space at or below this position has been durably ingested, deliberately suppressed, or listed in `debt`.* It is a claim about the ORDERED SPACE, not about how many things were counted — which is precisely why it succeeds where a coverage ratio fails.

**3. `debt` — the outstanding-debt list.** Prevents: the single-watermark class of loss, where there is no way to say "caught up to X, still owe you below Y." This is what makes gmail's two-pointer expressible generically, and what turns a newest-first walk from a footgun into a safe incremental commit: heb could commit `complete_through = newest, debt = [everything below]` from page 1 and be correct at every instant. An empty `debt` array is a strong claim; omitting the field entirely is not the same thing and must be rejected as malformed.

**4. `partition`** — optional, and it exists to kill exactly one bug: the global fallback. A claim scoped to a partition may only ever move that partition's position. A connector that wants a global floor for unseen partitions **cannot express it** — there is no field for it. Slack's `COALESCE(t.last_ts, ?)` becomes unrepresentable rather than merely discouraged. This is the test the owner asked for: a contract that cannot distinguish a real partition map from a global watermark wearing one is inadequate, and this one distinguishes them by construction.

Rejected fields, and why: a `covered`/`considered` ratio (measures hydration honesty, not position — §C shows github `starred` passes it while still skipping data, and jellyfin `items` fails it while losing nothing); a `safe: true` boolean (unfalsifiable self-attestation, the exact security hole the RI's manifest-vs-registry split already rejects elsewhere); a connector version or capability flag (that is an allowlist with extra steps — see §4); a timestamp of any kind (a position must be externally meaningful in the provider's own space, per the pagination/Range/tus rule).

### 3. The runtime's decision procedure, connector-agnostic

At every `handleStateMessage`, after the batch flush that already happens:

```
if (!msg.checkpoint_claim)                          -> stage only        // no claim, no commit
if (claim.space !== stored.space)                   -> stage only + reset // re-seed detected
if (records_flushed_for_this_stream_this_run == 0
    && claim advances position)                     -> stage only        // claim without evidence
if (claim.partition && claim moves a different key) -> reject (protocol violation)
otherwise                                           -> commitState(stream, cursor)  // already idempotent
```

Five rules, no connector names, no per-connector configuration. It composes with the existing `commitState` PUT unchanged — the plumbing is already per-stream and idempotent (§A).

The third rule is the one that carries weight and it is why the durable-ingest record is the right evidence rather than the connector's own word. Flink's rule applies directly: the records are already durably ingested when `run.batch_ingested` is written — that IS the pre-commit, and after a successful pre-commit the commit is an obligation, not an option [flink-e2e]. The runtime is not trusting the connector's claim; it is checking the claim against a fact it wrote itself. Chandy-Lamport licenses the rest: the committed state need never be a moment the run was actually in, only one reachable from the start from which the end is still reachable [cl85]. `complete_through` + `debt` is exactly such a state.

**On the research doc's proposed predicate.** Its §11 gate — "does the connector emit bounded `DETAIL_COVERAGE` with `covered == considered` and a non-null boundary?" — is a **proxy, and an inadequate one**. It is the right instinct (demand evidence, not a promise) aimed at the wrong property. `DETAIL_COVERAGE` describes detail hydration and is structurally disjoint from the cursor (§A); §C gives a false-negative (jellyfin `items`) and a false-positive (github `starred` — honest `partial` coverage, unsafe advancing cursor) in the shipped tree. **Coverage honesty and cursor safety are two different properties that merely correlate. Cursor safety is the one that governs commit, and it is governed by the boundary claim, not the ratio.** That answers the question the decision doc explicitly gated and defers Stage 5 no longer.

### 4. Migration falls out of the protocol — confirm, with one correction

Confirmed: a connector that says nothing gets `commit_on_success` forever, automatically, because rule 1 is "no claim ⇒ stage only." Nobody enumerates anything; the 8 scaffold connectors and every fingerprint-map stream simply never qualify and never need to. **If you find yourself writing a per-connector allowlist, the contract has failed** — the whole point is that the claim travels with the data.

The correction: "cannot make the claim" is rarer than it looks, and the reason is the survey's most useful positive result. The fleet's dominant shape is the fingerprint map, which is **not a position at all** — it cannot skip data in either direction (§C). Those streams don't need the contract; they need a one-line `{"space": ..., "complete_through": "*"}` meaning "full enumeration, no debt," or they can stay silent at zero cost. The genuinely positional cursors are a minority, and of those the ones that matter are already the ones losing records today (§B).

Sequencing, cheapest-value-first: (i) add the optional field to the protocol — inert, nothing changes; (ii) implement the five rules; (iii) claim it in gmail `messages` first, which already has all four fields including `uidvalidity` and is 203,417 of the lost records; (iv) chatgpt and codex next, together 657,477 records — the largest single win in the fleet; (v) fix slack's global fallback, which the contract makes *unrepresentable* rather than merely wrong.

### 5. Shutdown: the question dissolves, and this is the whole point

**Yes — and state it plainly: a checkpoint that is safe to commit at any instant is by construction safe to commit at the instant SIGTERM arrives.** SIGTERM is not a distinguished moment. It is an arbitrary instant, and a contract whose validity is instant-independent is indifferent to which instant it is. There is nothing for a drain to accomplish, because the last committed checkpoint is *already* correct.

The measurement removes any residual doubt about the alternative. Waiting is not merely suboptimal, it is unavailable: only 2 of 17 connectors finish inside 10s at p95, slack's p95 is 405× the budget, and `--stop-timeout` is fixed at container creation with no Docker equivalent of systemd's `EXTEND_TIMEOUT_USEC=` (§D, and the sibling entry's §C). The shipped 5s drain is measured burning its entire budget and saving nothing. **Delete it** — it makes shutdown faster and the failure honest, per the sibling decision doc's deletion list.

So the final shape is two mechanisms with a clean seam, and neither is a drain:

- **Between checkpoints** — the successor adjudicates via the owner epoch and writes `INTERRUPTED`. Exactly the sibling decision doc's design; nothing here changes it, and its `controller_id` defect remains the highest-value fix in the system.
- **At checkpoints** — the connector's own claim already committed the work, at the instant it became provably safe, with no cooperation from the dying process.

The residue is worth naming honestly, and an earlier draft of this entry understated it. It is **not** "work done since the last checkpoint." Staged cursors are discarded on interruption — `newState` is a plain in-memory object [pdpp-code `reference-implementation/runtime/index.ts:2762`, assigned at `:4237`] and `commitState` has exactly two call sites [`:5278`, `:5322`], both inside the DONE gate [`:5266`; located by content, the entry's original `:4933` having drifted]. There is no mid-run commit path, so a staged cursor has no durable effect until DONE. **The worst case for a `commit_on_success` connector is redo since the last COMMITTED cursor — the one written by the last successful run, which is effectively the run start.** The 465 terminal runs that durably ingested 897,916 records and advanced no cursor (§B) are the direct measurement of exactly this: they are whole-run losses, not since-last-checkpoint losses.

That is still at-least-once, it is what Kafka's default gives you, and it is still the correct trade for a system whose alternative failure mode is permanent unreachable data [kafka-design]. Redo work, never lose data — for the connectors that cannot make the claim, that remains the right permanent answer, not a temporary one. But the redo is a whole run, not a tail, and that makes the case for the claim contract stronger than this entry originally stated.

**Is any bounded cooperative step still worth having? No.** Not a shortened drain, not a "finish the current page" courtesy. Both re-introduce a wait whose only justification is the absence of the claim, and both consume SIGKILL budget that writing terminal state needs. This is the incidental complexity the contract exists to delete: machinery compensating for a checkpoint that could not describe itself.

### 6. Confidence and what would settle the rest

High confidence: the protocol type (`cursor: unknown`) and validator are read directly; the 42%/897,916-record measurements are live SQL; the slack global fallback is confirmed both in source and in the live cursor (569 channels + a global floor); the duration distribution is live SQL; the drain log lines are verbatim from the running container.

Medium confidence, and cheap to settle: whether every genuinely positional stream can supply `complete_through` in its provider's own ordered space. Gmail, chase, usaa, amazon, ynab, heb clearly can. The archive connectors (apple_health, google_takeout, twitter_archive, netflix_export) would need a position in *file* order rather than timestamp order, since their traversal is unordered with respect to the cursor field (§C) — this is a real design question per connector, not a blocker, and the honest fallback is that they stay silent and keep today's behavior. Settling it costs one connector's implementation, and gmail is the right first one because it needs no new evidence.

Not verified: whether any code path outside `handleStateMessage` stages a cursor.
