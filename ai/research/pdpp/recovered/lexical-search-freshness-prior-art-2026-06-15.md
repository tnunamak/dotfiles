# Lexical search freshness & self-healing indexing — prior art

Date: 2026-06-15
Status: captured (informative; supports making PDPP `GET /v1/search` index-lag honest and self-healing)

## Why this note

PDPP exposes a lexical full-text retrieval extension at `GET /v1/search`
(spec: `openspec/changes/add-lexical-retrieval-extension/specs/lexical-retrieval/spec.md`;
implementation: `reference-implementation/server/search.js` +
`reference-implementation/server/postgres-search.js`). The index is a separate
table (`lexical_search_index`, SQLite FTS5 / Postgres `tsvector`) maintained
two ways:

1. **Synchronous write-path hooks** — `lexicalIndexUpsert` / `lexicalIndexDelete`
   / `lexicalIndexDeleteByConnectorStream`, called from `records.js` at every
   record write/update/delete. These keep records that arrive *after* a stream
   declares `lexical_fields` in sync.
2. **Drift-detect + backfill** — `lexicalIndexBackfillForManifest`, called from
   `startServer` (native) and `registerConnector` (polyfill). It compares a
   persisted field-set fingerprint and an exact non-empty-text row count against
   the live index, and rebuilds streams that drifted.

Two SLVP-quality gaps motivate this research:

- **No freshness visibility.** The search envelope carries `meta.warnings[]`
  (`limit_clamped`, `deprecated_alias_used`, `source_skipped_not_applicable`)
  but **no `as_of` / freshness field and no staleness warning**. A caller cannot
  tell that a result reflects data as of some earlier `T` that lags live record
  ingestion. If the synchronous hook ever drops a write (e.g. an upsert throws
  and is swallowed, a record written before the manifest declared
  `lexical_fields`, or an interrupted backfill), search silently under-returns.
- **Convergence depends on a trigger, not a watermark.** Self-healing happens
  only when `lexicalIndexBackfillForManifest` is *invoked* (server start /
  connector register). Between triggers there is no continuously-advancing
  cursor that guarantees the index catches up to live writes. A long-lived
  process that never restarts and never re-registers can stay behind
  indefinitely, and nothing surfaces the lag.

This note collects prior art for (1) **index freshness visibility** and
(2) **self-healing incremental indexing**, so the design change can cite it
rather than re-deriving it. Each entry quotes only what the design relies on;
full URLs are at the bottom.

---

## Part 1 — Index freshness visibility

The question: how do mature systems expose "this search result reflects data as
of `<T>`, which may lag live writes"?

There is **no single canonical field name** across the industry, but there is a
strong canonical *shape*, and it converges on four moves:

1. State the consistency contract plainly in the docs (eventually consistent,
   bounded by `~X`).
2. Give writers a way to **wait for** their write to be visible (read-your-writes
   on demand) instead of polling.
3. Offer a **strongly-consistent escape hatch** for read-after-write
   (a different endpoint or a per-request flag).
4. When relevant, return a **freshness signal** the caller can reason about
   (an `as_of` timestamp, a lag metric, or a `forced_refresh` boolean).

### Stripe Search — eventual consistency stated as a contract

Stripe's Search API is the closest analog to PDPP `GET /v1/search`: a separate,
asynchronously-maintained index over primary objects.

- The contract is **stated in prose, in every search endpoint's docs**:
  > "Don't use search for read-after-write flows where strict consistency is
  > important. Under normal operating conditions, data is searchable in less
  > than a minute. Occasionally, propagation of new or updated data could be up
  > to an hour behind during outages."
- The **escape hatch is a different endpoint**: for read-after-write, Stripe
  tells you to use the strongly-consistent **List** endpoints
  (`stripe.customers.list`, etc.), which "aren't subject to the availability
  delays."
- Stripe also documents a **filter/result skew**: the Search API may filter on a
  *cached* version of a field but return the *latest* object, so a result can
  disagree with the query predicate it was selected by. (Direct lesson for PDPP:
  if grant/filter predicates are evaluated against the live `records` table
  while ranking comes from the index, the two can diverge — PDPP already does a
  candidate-record scan against live `records` in `buildCandidateRecordKeys`,
  which avoids the worst of this but means the index can list a record that the
  live filter rejects, i.e. over-fetch then trim, never silently include).

**Lesson for PDPP:** the *minimum bar* is Stripe's: state the consistency
contract, and give a strongly-consistent alternative. PDPP already has the
alternative — `GET /v1/streams/<s>/records` is read-from-source, so it is the
"List" analog. The cheap win is documenting that and naming the bound.

### Elasticsearch / OpenSearch — `refresh` semantics, `wait_for`, and `forced_refresh`

Elasticsearch is "near real-time": a document indexed at `T` becomes searchable
around `T + refresh_interval` (default `1s`), because a *refresh* opens a new
Lucene segment. This is the canonical model for "the index lags writes by a
bounded, tunable interval."

The freshness-visibility primitives worth stealing:

- **`?refresh=wait_for` on the write** — the write call does not return until the
  change is visible to search. This is read-your-writes *on demand*, pushed to
  write time, so the reader never has to poll. Crucially it does **not** force an
  extra refresh; it waits for the next scheduled one.
- **`"forced_refresh": true` in the write response** — a safety valve. If too
  many requests are already waiting (`index.max_refresh_listeners`, default
  1000), the request is upgraded to a real refresh and the response carries
  `forced_refresh: true`, *telling the caller* that an unusual thing happened.
  This is a precedent for **returning a boolean honesty flag in the response**
  rather than hiding the deviation.
- **"Caught up" is a checkpoint comparison.** There is no API literally named
  "is my index caught up." Operators derive it by comparing the **global
  checkpoint** to the **max sequence number** per shard (via `_cat/shards`
  `seq_no.global_checkpoint` vs `seq_no.max`). When they're equal, all committed
  ops are accounted for. This is the deep idea: *freshness is a comparison
  between an index watermark and a source watermark*, and you can expose that
  comparison. (Closing an index even *enforces* `max_seq_no == global_checkpoint`
  as a precondition.)
- **`took`** is *query latency*, not freshness — do not conflate. ES has no
  per-response "data as of" timestamp; freshness is inferred from
  `refresh_interval` and the checkpoint comparison above.

**Lesson for PDPP:** the highest-value primitive here is a **watermark
comparison** that PDPP can compute cheaply: `MAX(records.id)` /
`MAX(records.emitted_at)` over the in-scope `(connector_instance_id, stream)`
set versus the high-water mark the index has actually consumed. If they diverge,
the view is stale, and by how much.

### Algolia — async tasks, `taskID`, and `waitTask`

Algolia makes the async boundary explicit at the API level:

- Every write returns a **`taskID`**. The write request is synchronous; the
  *indexing* is asynchronous and runs on a queue.
- **`waitTask(taskID)`** polls `getTask` until status is `published`, i.e. the
  data is live and searchable. This is the same read-your-writes-on-demand idea
  as ES `wait_for`, but the freshness token is an explicit opaque id the client
  holds, rather than a flag on the write.
- For batches, the current guidance is **check all `taskID`s** (older guidance of
  "just the biggest" was downgraded as unsafe).

**Lesson for PDPP:** a per-write task id is heavier than PDPP needs, but the
*pattern* — "the write hands back a token that proves when the index caught up"
— is the strongest version of read-your-writes. The lighter PDPP analog is a
monotonic **index watermark** the search response can echo.

### Postgres FTS — generated columns / functional indexes don't lag *by construction*

PDPP's Postgres backend stores a `tsvector` (`document` column in
`lexical_search_index`). Postgres FTS prior art is directly relevant because it
shows **how to make the index unable to lag at all** within a single DB:

- **Generated column (PG12+):** `tsvector GENERATED ALWAYS AS (to_tsvector(...))
  STORED`. The index value is recomputed *inside the same transaction* as the
  row write — there is no separate maintenance step that can fall behind.
- **Functional GIN index:** `CREATE INDEX ON t USING gin (to_tsvector('...',
  body))`. Even cheaper — no stored column, "no need for triggers or other
  synchronization … the index automatically reflects any changes to the
  underlying text." This is the gold standard for "can't fall behind by design":
  the index is a *function of the row*, maintained transactionally by the engine.
- **Replication lag** (when the index lives on a replica/different system) is
  monitored via `pg_stat_replication` (`pg_wal_lsn_diff(pg_current_wal_lsn(),
  replay_lsn)` for byte lag) and, for logical replication, `pg_stat_subscription`
  on the subscriber. Canonical alerting advice: **"alert on growing lag, not
  threshold crossings"** — a standby 500MB behind for an hour is worse than a
  2GB spike during a bulk load.

**Lesson for PDPP (important):** PDPP deliberately maintains the index in
**JS, not a DB trigger or generated column**, because "index population needs to
consult the connector manifest at write time to know which fields are
searchable — triggers cannot see manifests" (`search.js` header comment). That
is a sound reason, but it means PDPP **forfeits the transactional "can't lag by
construction" guarantee** and takes on the obligation to *detect and heal* lag
itself — which is exactly Part 2. The Postgres prior art tells us what we gave
up and why; it also suggests a hybrid: keep the JS field-selection logic, but
make index maintenance part of the *same transaction* as the record write
(write-then-index atomically), so a committed record can never lack its index
rows.

### Bounded-staleness / session-consistency models — the vocabulary to expose

The distributed-systems literature gives PDPP precise words for the contract it
chooses:

- **Eventual consistency** — reads may be stale, converge over time. (Stripe
  Search, ES before refresh, Algolia before `published`.)
- **Bounded staleness** (Cosmos DB) — reads lag by at most `K` versions or `T`
  time; the system **throttles writes** when the bound is about to be exceeded
  so it can catch up. This is the model to name if PDPP wants to *promise* a
  ceiling ("search is never more than `T` behind").
- **Read-your-writes / session consistency** — within a session you always see
  your own writes. Cosmos implements this with a **session token** the client
  passes back (a version barrier, not a snapshot). DynamoDB has no token; you opt
  into a strongly-consistent read per request with `ConsistentRead=true`.
- **As-of / point-in-time read** — a consistent snapshot pinned to a specific
  timestamp (Spanner, Aurora DSQL). Distinct from a session token: an `as_of`
  pins an exact historical view; a session token is only a *floor* (never older
  than your session, but possibly newer).

**Lesson for PDPP:** PDPP's honest self-description is **"eventually consistent,
self-healing, with an exposed staleness bound."** The right response field is an
**`as_of` freshness marker plus an optional staleness warning**, not a session
token (PDPP search is read-mostly, cross-connector, and has no per-client write
session to bind).

### How responses actually carry the signal

Survey of where the signal lives in real responses:

- **A boolean honesty flag** — ES `forced_refresh: true`. Cheapest; says "this
  response deviated from the steady state."
- **A lag/freshness metric** — ES CCR status API exposes `Sync Lag (ops)` and
  `last fetch time`; Postgres replication exposes byte/time lag. The shape is
  "here is how far behind, in ops or seconds."
- **An `as_of` timestamp** — the cleanest user-facing form. Notably there is **no
  widely-published canonical pattern** for an `as_of` field in REST/GraphQL
  search responses (CircleCI has it only as an open feature request; GraphQL
  convention would put it in the spec-sanctioned `extensions` block). This is a
  small greenfield — PDPP can set a clean convention.

**Recommended PDPP shape** (synthesis, not a quote): extend the existing
`meta` block the envelope already carries:

```jsonc
"meta": {
  "as_of": "2026-06-15T18:22:04Z",        // index watermark: newest live write the index reflects
  "freshness": {
    "lagging": true,                       // index watermark < source watermark
    "lag_records": 3,                      // optional: how many committed records not yet indexed
    "source_as_of": "2026-06-15T18:22:31Z" // newest committed record in scope
  },
  "warnings": [ { "code": "search_index_stale", "message": "..." } ]
}
```

This reuses `meta.warnings[]` (so warning-free envelopes are unchanged, matching
the current "omitted when empty" rule) and adds an `as_of` that is **derivable
for free** from data PDPP already has (`records.emitted_at` / `records.id` and a
new index-watermark column).

---

## Part 2 — Self-healing incremental indexing

The question: what makes an index converge to live data *without a manual
backfill*, and "can't silently fall behind by design"?

Three families of prior art, in increasing strength of guarantee.

### A. Transactional / generated index — the strongest guarantee

If the index is a deterministic function of the row, maintained in the **same
transaction** as the row write, it **cannot** lag:

- Postgres generated `tsvector` column / functional GIN index (above): the engine
  maintains it; there is no async step to fall behind.
- The general principle: **eliminate the dual-write**. The reason an index falls
  behind is that "write the record" and "write the index" are two operations that
  can partially fail. Collapse them into one atomic unit and the failure mode
  disappears.

PDPP can't go fully transactional-in-DB *and* keep manifest-driven field
selection in JS — but it **can** wrap the record write and the JS index upsert in
one DB transaction (write-then-index atomically). Today `lexicalIndexUpsert` is
called from `records.js` but the doc comment and code path do not guarantee it
shares the record's transaction; if an upsert throws after the record commits,
the index is permanently behind until the next backfill trigger. **Making the
index write part of the record's transaction is the single highest-leverage
fix** and matches the "no dual write" principle.

### B. Outbox → CDC → idempotent indexer — the standard async pattern

When the index is genuinely a separate system (a different DB, a search cluster),
the canonical self-healing architecture is:

```
record write + outbox row  (one ACID txn)
        │
        ▼
   CDC reader (e.g. Debezium tails the WAL)
        │
        ▼
   message log (Kafka)  ──►  idempotent indexer  ──►  search index
```

Why it self-heals (the three pillars cited across the literature —
detection, isolation, recovery):

- **No dual write at the source.** The record and the "index-me" event are
  written in one transaction. *"If it's in the database, it will be in Kafka."*
  The hard distributed problem becomes a local DB transaction, which databases
  are good at.
- **Recovery is automatic via the log offset.** After a crash/outage, the CDC
  reader resumes from its last committed offset in the WAL/transaction log. No
  data is lost; nothing has to be manually re-backfilled. *"When your production
  database goes down and comes back up … you haven't lost a single event."*
- **At-least-once + idempotent consumer.** Events may be delivered more than once;
  the indexer must be idempotent. Indexing **by document id** is naturally
  idempotent (re-indexing the same doc yields the same state), which is why this
  pattern fits search especially well. The literature is explicit: prefer
  at-least-once (duplicates are fixable) over at-most-once (data loss is not).
- **Outbox is a buffer, not a store** — once consumed it is pruned
  (`DELETE FROM outbox WHERE created_at < now() - interval '3 days'`).

**Lesson for PDPP:** PDPP doesn't need Kafka/Debezium, but the *invariant* is the
one to adopt: **every committed record must leave a durable "needs indexing"
marker that an indexer drains, with the indexer resumable from a persisted
offset.** PDPP's records table already has a monotonic `id` and `emitted_at` —
that *is* a usable change-log. The watermark pattern (C) is the lightweight,
single-process realization of this.

### C. Continuously-advancing watermark/cursor — vs one-time backfill

This is the pattern PDPP should adopt, because it is single-process, needs no new
infrastructure, and directly converts the existing trigger-based backfill into a
continuous one.

The distinction the task names maps exactly onto the literature:

- **One-time backfill** = full scan that builds the index from scratch. Failure
  mode: it runs from scratch every time (wasteful) **or** it runs only at certain
  triggers and the index drifts between them (silent lag). PDPP's
  `lexicalIndexBackfillForManifest` is the second kind: it only runs at
  `startServer` / `registerConnector`.
- **Continuously-advancing watermark** = the index records the **high-water mark**
  (max `id` or `updated_at`) it has consumed, and a periodic pass indexes only
  `WHERE id > watermark` (or `updated_at > watermark`). *"It's like a bookmark,
  but the story never ends; it only becomes longer."* Because the watermark is
  persisted, the indexer **resumes after downtime** and **can't skip committed
  rows above the mark**. Monitoring is trivial: the current watermark position is
  always queryable, and `source_max - watermark` *is* the lag (this is also the
  `as_of` for Part 1 — the two designs share one number).

Two correctness caveats the watermark literature is emphatic about, both of which
apply to PDPP:

1. **Late-arriving / out-of-order rows.** If the cursor advances past a row's
   timestamp before that row is queryable, it's skipped forever. Standard
   mitigation: a **lookback window** that rewinds the cursor by a small interval
   (e.g. `watermark - 5min`) so late arrivals within the window are re-read.
   **A monotonic surrogate `id` avoids this** better than a timestamp — PDPP's
   `records.id` is monotonic and assigned at write, so cursoring on `id` (not
   `emitted_at`) sidesteps clock-skew/late-arrival skips. PDPP's existing backfill
   already pages by `id` (`afterId`/`lastId`), so the machinery exists.
2. **Deletes.** Pure timestamp/`id` watermarking catches inserts and updates but
   **misses deletes** (a deleted row no longer appears in the `WHERE id >
   watermark` scan). PDPP handles deletes on the synchronous path
   (`lexicalIndexDelete` / soft-delete), and its search JOINs `records` with
   `r.deleted = FALSE`, so a stale index row for a deleted record is **filtered at
   query time** rather than returned — a good belt-and-suspenders. But the
   watermark pass must still reconcile *tombstones* (records that went
   `deleted = TRUE` after being indexed) so the index doesn't grow unbounded.
   Cursoring on a `updated_at`/version column that bumps on delete, or periodically
   reconciling index rows whose record is now `deleted`, closes this.

**The convergence guarantee, stated plainly:** if (a) every committed record gets
a monotonic `id`, (b) the index persists the max `id` it has consumed
per `(connector_instance_id, stream)`, and (c) a bounded periodic pass indexes
`id > watermark`, then **no committed record above the last watermark can be
permanently missing from the index** — the index is "can't silently fall behind
by design," because the watermark gap is both the healing trigger *and* the
staleness signal. The only residual is the brief window between commit and the
next pass, which is exactly the bounded-staleness `T` you expose as `as_of`.

### Cross-cutting: separate index structure from content; randomized/aged maintenance

Incremental-indexing research (beyond search-specific systems) adds two design
principles PDPP already partly follows:

- **Separate the index from the content** for simpler concurrency — PDPP's index
  is a separate table keyed by `(connector_instance_id, stream, record_key,
  field)`, which is exactly this.
- **Adaptive/aged reorganization** rather than constant full rebuilds — PDPP's
  fingerprint guard already avoids needless rebuilds when the field set is
  unchanged. The watermark adds the missing "advance continuously" half.

---

## What PDPP has, and the minimal delta

**Already present (good foundations):**
- Separate index table, manifest-declared searchable fields, exact-count + field
  fingerprint drift detection, paged-by-`id` backfill, soft-delete filtered at
  query time, an envelope `meta.warnings[]` channel, and a strongly-consistent
  alternative (`GET /v1/streams/<s>/records`) that is the "Stripe List" analog.

**Missing (the two gaps this research targets):**
1. **Freshness visibility** — no `as_of` / staleness signal in the search
   envelope. *Minimal delta:* compute an index watermark and emit
   `meta.as_of` (+ a `search_index_stale` warning when `index_watermark <
   source_watermark`). Free-ish: `MAX(records.id|emitted_at)` is already
   queryable; add a persisted per-stream index watermark.
2. **Continuous convergence** — backfill only runs at start/register. *Minimal
   delta:* persist a per-`(connector_instance_id, stream)` **index watermark**
   (max `records.id` consumed) and run a **bounded periodic catch-up pass**
   indexing `id > watermark`, plus a tombstone reconcile for deletes. This turns
   the existing one-time backfill into a continuously-advancing cursor and makes
   the index *unable to silently fall behind*. Strengthen further by making the
   synchronous `lexicalIndexUpsert` share the record-write transaction (no dual
   write), so the watermark pass is a safety net rather than the primary path.

The watermark serves **both** goals with one number: it is the convergence cursor
*and* the `as_of` the response exposes. That is the SLVP-ideal shape — the
honesty signal and the self-healing mechanism are the same mechanism, so they
cannot drift apart.

---

## References

Freshness visibility:

- Stripe — Search API (eventual consistency, <1 min normal / up to 1 hr during
  outages, "don't use for read-after-write", use List endpoints, filter/result
  skew): https://docs.stripe.com/search and per-object pages, e.g.
  https://docs.stripe.com/api/customers/search
- Elasticsearch — Near real-time search:
  https://www.elastic.co/docs/manage-data/data-store/near-real-time-search
- Elasticsearch — The `refresh` parameter (`wait_for`, `forced_refresh`,
  `index.max_refresh_listeners`):
  https://www.elastic.co/docs/reference/elasticsearch/rest-apis/refresh-parameter
- Elasticsearch — `index.refresh_interval` (NRT, freshness vs throughput,
  search-idle): https://www.elastic.co/guide/en/elasticsearch/reference/8.19/near-real-time.html
- Elasticsearch — Optimistic concurrency / `_seq_no` + `_primary_term`; "caught
  up" via global checkpoint vs max seq no (`_cat/shards`):
  https://www.elastic.co/docs/reference/elasticsearch/rest-apis/optimistic-concurrency-control
- Algolia — Wait for operations (`taskID`, `waitTask`, `published`, check all
  task ids): https://www.algolia.com/doc/libraries/javascript/v5/methods/search/get-task/
- Algolia — Inside the engine: indexing vs search (async task queue):
  https://www.algolia.com/blog/engineering/inside-the-algolia-engine-part-1-indexing-vs-search
- Postgres FTS — tsvector generated columns / functional GIN indexes (no sync
  triggers needed; index is a function of the row):
  https://thoughtbot.com/blog/optimizing-full-text-search-with-postgres-tsvector-columns-and-triggers
- Postgres replication lag — `pg_stat_replication` / `pg_wal_lsn_diff`,
  subscriber-side `pg_stat_subscription`, "alert on growing lag not thresholds":
  https://www.cybertec-postgresql.com/en/monitoring-postgresql-replication/
- Consistency models — Cosmos DB consistency levels (bounded staleness throttles
  writes; session tokens = version barrier):
  https://learn.microsoft.com/en-us/azure/cosmos-db/consistency-levels
- DynamoDB read consistency (`ConsistentRead`, eventual default, no session
  token): https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.ReadConsistency.html

Self-healing incremental indexing:

- Transactional outbox + CDC to search index (Debezium → Kafka → idempotent
  indexer; "if it's in the database it'll be in Kafka"; resume from log offset;
  at-least-once + idempotency):
  https://www.lydtechconsulting.com/blog/kafka-connect-debezium-demo and
  https://thorben-janssen.com/outbox-pattern-with-cdc-and-debezium/
- Outbox pattern as self-healing (detection/isolation/recovery; outbox as buffer,
  prune after consume):
  https://www.milanjovanovic.tech/blog/implementing-the-outbox-pattern
- Watermark (data synchronization) — point-of-reference for incremental delta
  sync; resume after downtime; "above watermark" rows:
  https://en.wikipedia.org/wiki/Watermark_(data_synchronization)
- High-watermark incremental ingestion (watermark field = last-updated or
  sequential id; resume from mark):
  https://techcommunity.microsoft.com/blog/fasttrackforazureblog/robust-data-ingestion-with-high-watermarking/3707480
- Watermark lookback window for late-arriving records; timestamp watermarking
  misses deletes / append-only caveat:
  https://www.sunnydata.ai/blog/lakeflow-connect-query-based-capture-incremental-ingestion
- Incremental indexing strategy (separate structure from content; adaptive/aged
  reorganization vs full rebuild):
  https://www.emergentmind.com/topics/incremental-indexing-strategy

PDPP implementation (for grounding the delta):

- `reference-implementation/server/search.js` — write-path hooks,
  `lexicalIndexBackfillForManifest` (fingerprint + exact-count drift detection,
  paged-by-`id` backfill), `runLexicalSearch` envelope with `meta.warnings[]`.
- `reference-implementation/server/postgres-search.js` — `tsvector` index,
  `postgresLexicalSearch` (`ts_rank_cd` / `ts_headline`), watermark-able
  `postgresLexicalRecordsPageNonDeleted` (already cursors on `id`).
- `openspec/changes/add-lexical-retrieval-extension/specs/lexical-retrieval/spec.md`
  — public `lexical-retrieval` capability contract.

---

## Empirically confirmed root cause (live probe, 2026-06-15)

Verified directly against https://pdpp.vivid.fish (Vana Slack, `cin_f565a96cb0a114b0a27e9606`, stream `messages`):
- `query_records` (live): 40 messages from 2026-06-15+ exist; newest `2026-06-16T02:03`.
- lexical `search q="the"`: newest hit is **2025-11**; ZERO of the 40 recent records appear. The lexical index content ceiling is ~late-2025 (the ~April date seen earlier is the backfill *run* date, not the content date).
- semantic + hybrid `search`: return the newest (hours-old) message — fresh.

CONCLUSION (≥95%): lexical incremental write-path indexing is NOT keeping the live index current, AND the restart-time drift-detect (`search.js:537-548`) is not healing it (process not restarting, or count-coincidence skip). Semantic stays fresh because its resumable progress-row mechanism (`search-semantic.js:1352-1430`) self-heals; lexical has no equivalent. The defect is structural: **lexical convergence depends on triggers (restart/register) that aren't firing, with no continuous reconciliation** — exactly what the watermark design eliminates. This matches the design thesis: convergence must be trigger-independent, and `as_of` would have made the 2025-11 ceiling visible immediately.

---

## CORRECTED root cause via owner-token live probe (2026-06-15) — REFUTES instance-split AND global-watermark theories

Queried live pdpp.vivid.fish with the owner token, grouping lexical `search q=block&streams=messages` hits by `connector_instance_id` + date ceiling:

| connector | instance | lexical date ceiling |
|---|---|---|
| chatgpt | cin_11deac… | 2026-06-12 |
| codex | cin_ece4… | 2026-06-12 |
| gmail | cin_1339… | 2026-06-10 |
| claude-code | cin_2de5… | 2026-06-09 |
| **slack** | **cin_f565… (the REAL slack instance)** | **2026-04-21 (FROZEN)** |

**Decisive findings:**
1. **Lexical indexing WORKS for most connectors** — chatgpt/codex/gmail/claude-code are current to within days. So it is NOT a global lexical failure, NOT a missing-watermark, NOT a trigger-cadence problem.
2. **The stale Slack hits are owned by the REAL slack instance `cin_f565a96cb0a114b0a27e9606`, not an orphaned `pg_lexical_backfill_…` instance.** This REFUTES the red-team adjudicator's instance-split theory.
3. **It is Slack-stream-specific and freeze-dated:** slack/messages frozen at 2026-04-20..21; slack/files indexed to 2026-05-26; slack/canvases at 04-20. Same connector, divergent per-stream ceilings.
4. **Records are live** (slack/messages newest record emitted 2026-06-16; recent records HAVE `text` populated, e.g. a message containing "block") — so the records write path works and the data is indexable; only the lexical INDEX write is not landing for slack/messages since ~04-21.
5. **04-21 is exactly when `lexical_fields` were declared** (commit c441926c "manifests: declare lexical_fields across 12 connectors") and slack messages expansion landed (4406dc1b). The one-time declaration backfill indexed through 04-21; incremental upserts since have not landed for this stream, and the per-(instance,stream) exact-count drift guard (search.js:547) has not triggered a rebuild.

**REVISED root cause (≥90%):** Slack-messages-stream-specific incremental lexical-index failure since the ~04-21 lexical_fields declaration — the on-write `lexicalIndexUpsert` is not durably indexing recent slack/messages (throwing-and-swallowed per the deliberately-non-atomic design at records.js:262-264, OR the slack write path differs), AND the drift-detect's count guard treats the frozen index as in-sync so no rebuild fires. The earlier "whole lexical index stale" framing was WRONG — it generalized from Slack. The SLVP fix still centers on the same primitives (atomic index maintenance + drift-detect that actually heals + visible as_of), but the live remediation is narrower (this stream/connector) and the diagnosis must be confirmed by reproducing a single slack/messages write→index locally.

**STILL UNCONFIRMED (the last ~10%):** the exact mechanism by which slack/messages incremental upsert fails while chatgpt/codex succeed — needs a local repro (ingest a slack-shaped message, assert lexical row appears) or server logs showing a swallowed lexicalIndexUpsert error for slack/messages.

---

## FOUR hypotheses falsified — mechanism still unconfirmed (2026-06-15, honest status)

Pursued the root cause empirically with a local repro + live owner-token probes. RESULT: the *symptom* is rock-solid but the *mechanism* is NOT yet pinned. Four hypotheses falsified:

1. **Global lexical staleness** — FALSE. Only Slack messages frozen; chatgpt/codex/gmail/claude-code lexical current to within days (owner-token probe by connector_instance_id).
2. **Orphaned-instance / instance-split** (red-team adjudicator's theory) — FALSE. The frozen Slack rows are owned by the REAL slack instance cin_f565a96cb0a114b0a27e9606, not pg_lexical_backfill_*.
3. **Incremental upsert silently no-ops after a fingerprint/register cycle** — FALSE. Local repro `test/lexical-incremental-repro.test.js` ingests batch-1 → register (stamp fingerprint) → ingest batch-2, and batch-2 IS searchable. Passes on BOTH sqlite (`:memory:`) AND postgres (local pgvector/pg16 at 127.0.0.1:55432). The on-write hook lands incrementally.
4. **Live registered Slack manifest missing lexical_fields** (so getStreamLexicalFields→null→hook no-ops) — FALSE. Live `/v1/schema` for slack/messages advertises `search.lexical_fields: [text, subtype, metadata_event_type]`. The registered manifest HAS them.

**CONFIRMED:** Slack messages lexical frozen at 2026-04-20..21; records live to 2026-06-16; recent records have populated `text` (e.g. a message containing "block"); registered manifest declares lexical_fields; incremental indexing works in isolated repro on both backends; slack/files indexed further (to 05-26) than slack/messages.

**STILL UNKNOWN (needs live diagnostics I don't have):** the specific live condition stopping the Slack-messages incremental hook. Unruled-out candidates, each needing live server logs OR direct live-DB access:
- (a) `lexicalIndexUpsert` THROWS and is swallowed for Slack-message data at live scale (records.js:262-264 makes index maintenance non-atomic + non-fatal — a swallowed throw would freeze the index silently while records keep landing). MOST LIKELY.
- (b) Slack ingests on live via a route that does NOT call the hooked `ingestRecord` (a bulk/backfill/migration path) — but all known ingest routes (rs-mutation device-exporters, source-webhooks, ref-device-exporters) funnel through ingestRecord.
- (c) count-guard coincidence (search.js:547 `indexCount === expectedIndexRows`) holding a partial index "in sync" — but this only runs at register/restart, and would self-heal then.

**HONEST CONFIDENCE:** symptom 98%, mechanism ~50% (candidate (a) swallowed-throw is the leading but UNPROVEN explanation). The SLVP DESIGN does not actually depend on knowing (a) vs (b) vs (c): all three are fixed by the same primitives the red-team converged on — (1) atomic/observable index maintenance so a write that commits cannot silently lack its index rows AND a swallowed-throw becomes a logged/counted failure, (2) drift-detect that runs continuously (not only at restart) so any desync self-heals within a bound, (3) a visible `as_of` that would have made the 04-21 freeze SCREAM. So the fix is robust to the mechanism uncertainty — but the LIVE REMEDIATION (and a regression test that actually reproduces the freeze) requires pinning (a)/(b)/(c), which needs owner-run live diagnostics: server logs grep for swallowed lexicalIndexUpsert errors on slack/messages, OR a direct query of the live lexical_search_index vs records counts for that stream.

---

## DEFINITIVE ROOT CAUSE (live PG diagnosis, 2026-06-15) — IT IS NOT A FRESHNESS BUG

Ran the diagnostic directly against the live pdpp Postgres (pdpp-postgres-1, 127.0.0.1:55432). The "lexical search is stale" framing — the agent's report AND all of my staleness hypotheses (frozen index, instance-split, watermark, swallowed-throw) — is **WRONG**. The index is current; the results are MIS-RANKED.

**Hard numbers (slack/messages, cin_f565a96cb0a114b0a27e9606):**
- records (non-deleted): 201,333; lexical_search_index rows: 184,265 — index is populated and CURRENT.
- newest record WITH index rows: 2026-06-16T03:15 (live to minutes).
- raw FTS `document @@ plainto_tsquery('simple','block')`: **1,834 matches, newest 2026-06-16T02:12** — recent messages ARE indexed and DO match.
- **185,840 of 201,333 Slack messages share ONE emitted_at: `2026-04-20T14:23:13.467Z`** — a single bulk backfill on 04-20 (92% of the corpus stamped with one timestamp). Next biggest: 04-21 (5,852 + 4,823).

**The mechanism:** lexical search ranks results by `ts_rank_cd(document, plainto_tsquery('simple', q)) DESC` (postgres-search.js:207) with **no recency component** and a **per-source result cap (~100 hits/connector in fan-in)**. The 185k-record 04-20 bulk backfill contains the highest-`ts_rank_cd` matches (longer/denser text → higher score), so they fill Slack's ~100-result cap BEFORE any post-04-21 message is reached. Ordered by `ts_rank_cd`, every top Slack "block" hit is `2026-04-20T14:23:13.467Z` (scores 2.7, 2.1, 1.7…); ordered by `emitted_at`, the 2026-06-16/15/14 messages appear immediately. **The recent data is in the index and matches the query — it is just out-ranked and capped out of the returned page.**

**Why only Slack looked "frozen":** Slack is the connector with a massive same-timestamp bulk backfill. ChatGPT/Codex/Claude-Code/Gmail have data spread over time, so their per-source cap naturally includes recent hits. Slack's 92%-at-one-timestamp backfill is pathological for relevance-only ranking.

**Verdict on the SLVP fix — COMPLETELY REVISED:**
- The watermark/freshness/as_of/instance-split designs are ALL REJECTED — they solve a non-existent problem.
- The real issue is **search ranking quality + per-source cap behavior**: relevance-only ranking with no recency signal, plus a per-source cap that can hide an entire date range when one source has a dense bulk-load. This is a genuine SLVP search-quality gap (Stripe/Algolia search blend relevance + recency; a pure ts_rank_cd with a hard per-source cap is not SLVP-ideal).
- **P2 (fetch recovery hint) was also predicated on the freshness story — re-evaluate; the not-yet-indexed-permalink case is far rarer than believed since the index is current.**
- The agent's "P1: no freshness signal" critique partially survives but reframed: the missing signal isn't index-staleness, it's **"results truncated by per-source cap"** — search should warn when a source's results were capped (has_more per source), so a caller knows recent hits may exist beyond the page.

**Honest meta-lesson:** four rounds of analysis (research workflow, red-team, adjudication, and my own probing) all reasoned from the agent's "stale" framing and built increasingly elaborate freshness machinery. The live `ORDER BY` swap (rank vs date) — a 30-second query — collapsed the entire edifice. The data was never stale. LESSON: when a report says "X is missing," query whether X is RETRIEVABLE-BUT-UNRETURNED before designing a system to fix X's ABSENCE.
