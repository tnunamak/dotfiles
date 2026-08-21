---
title: "Derived-state staleness after a code upgrade is detected by storing the computing code's version on the derived row — input checkpoints structurally cannot see a formula change — and rebuild starves unless the budget is split by fixed ratio or alternating lanes rather than drain-dirty-then-history"
date: 2026-08-16
topic: distributed-systems
tags: [projections, cqrs, event-sourcing, rebuild, backfill, materialized-views, dbt, marten, rama, migration, starvation]
status: draft
sources: [marten-rebuild, marten-daemon, marten-optimizing, axon-streaming, axon-replay, kurrent-projections, event-driven-rebuild, es-reindex, es-zero-downtime, es-rethrottle, algolia-move, algolia-tmp, pg-refresh, pg-ivm, pg-ivm-wiki, dbt-clone, dbt-slim-backfill, rama-pstates, rama-operating, datomic-indexes, datomic-overview, gitlab-bbm, shopify-maintenance-tasks, shopify-rails-at-scale, stripe-online-migrations, maui-backfill]
source_session: af82d1f3-1838-4307-a3a9-6bbf07e77c6f
---

## CLAIMS

### Recording a projection's version

- Marten binds a projection's code version to its storage: `ProjectionVersion` is a property on the projection class, and incrementing it causes Marten to write to a **separate set of database tables**, so v1 and v2 coexist during a blue/green cutover. [marten-rebuild]
- Marten's `GateSideEffectsBehindPriorVersion` suppresses side effects while a new projection version replays history the prior version already handled, then switches to live mode — a rebuild must not re-fire effects. [marten-rebuild]
- Axon Framework has **no projection version field**: rebuild is `StreamingEventProcessor#resetTokens(resetContext)`, triggered by a human. `@ResetHandler` clears the read model before replay, and `ReplayStatus` on the token lets handlers distinguish replayed from live events. [axon-streaming] [axon-replay]
- Axon requires the processor to be stopped on **every** instance before reset or another node re-claims the token and the reset fails; a single-process app avoids this constraint entirely. [axon-streaming]
- A brand-new Axon processor starts at index 0 and processes all history **as if not replaying**, so `ReplayStatus` misreports for newly-introduced projections. [axon-streaming]
- Elasticsearch and Algolia version the **artifact name**, not the code: the index carries a version suffix (`my_index_v1`, `my_index_v2`) and the application only ever names an alias; Algolia builds `<index>_tmp` and atomically calls `moveIndex(tmp, prod)`. [es-zero-downtime] [algolia-move]
- dbt detects that the **computing code** changed by comparing the current project against a stored `manifest.json` — effectively a content hash of every model's compiled code and config — via `dbt build --select state:modified+ --state <path>`, where the `+` suffix also selects everything downstream. [dbt-clone]
- EventStoreDB/KurrentDB and pg_ivm record no code version at all; a human triggers the reset. [kurrent-projections] [pg-ivm]

### Detecting staleness cheaply

- Checkpoint comparison is the dominant data-staleness mechanism: Marten stores one row per shard in `mt_event_progression` keyed by `ShardName` holding the highest event sequence processed; "stale" is `checkpoint < high_water_mark`. [marten-daemon]
- Marten's high water mark is "the furthest known event sequence that the daemon knows all events at or below can be safely processed in order" and **advances contiguously, stalling on sequence gaps** — including gaps from in-flight transactions, not only failures. [marten-daemon]
- Marten, Axon, and EventStoreDB independently converge on the same invariant: write the checkpoint/progression row **in the same transaction as the projected data**. Axon further recommends storing the token in the same database as the projection so a rollback undoes both. [marten-daemon] [axon-streaming] [event-driven-rebuild]
- pg_ivm detects change with triggers and hidden bookkeeping columns prefixed `__ivm_` (e.g. `__ivm_count__`), invisible to `SELECT *`; user columns may not use that prefix. [pg-ivm]
- Content hashing is used for **code**-change detection (dbt), not for data staleness; checkpoints are used for data staleness, not code change. No surveyed system uses one mechanism for both. [dbt-clone] [marten-daemon]

### Incremental vs full rebuild

- `REFRESH MATERIALIZED VIEW CONCURRENTLY` is **not** the incremental option: it computes the new result alongside the old and diffs row-by-row, so cost is proportional to **source table size, not change size**. It requires at least one unique index covering all rows, which is the join key that makes the diff possible. It buys a non-blocking apply and nothing else. [pg-refresh]
- pg_ivm performs true trigger-driven incremental maintenance, with `pgivm.refresh_immv(immv text, with_data boolean DEFAULT true)` as the full-refresh path (`with_data => false` unpopulates and **drops the triggers**). [pg-ivm]
- pg_ivm is documented as blocking writes until the view update completes, taking an early lock on the view to serialize concurrent maintenance, raising an error under REPEATABLE READ / SERIALIZABLE where anomalies are detectable, and supporting only simple queries with basic aggregations/joins. Its stated sweet spot is "a small fraction of a base table is modified infrequently." [pg-ivm] [pg-ivm-wiki]
- dbt practitioners state explicitly that the `on_schema_change` config is not sufficient for a code change **because it does not deal with historical data**; the documented remedy is `dbt run --full-refresh --select state:modified+ --state <path>` — full-refresh only the models whose code changed. [dbt-slim-backfill]
- dbt's `is_incremental()` returns false when the target relation does not exist, so a modified incremental model silently full-refreshes in an empty CI schema; the documented fix is `dbt clone` first, which requires zero-copy cloning. [dbt-clone]
- Marten offers a rebuild-ordering option: `opts.Events.UseOptimizedProjectionRebuilds = true` rebuilds single-stream projections **stream-by-stream in reverse order of last modification**, so recently-touched data becomes correct first. [marten-optimizing]

### Rama's read-through migration (no rebuild window)

- Rama separates the immutable append-only `depot` log from the durable derived index (`PState`). A module update can change topology code and add/remove PStates and depots. [rama-pstates]
- Rama PState migrations are declared with arbitrary user transformation functions and **take effect instantly by applying the migration function on read, while the on-disk data migrates in the background**; the documentation states "the existence of a migration doesn't slow down the module update at all." The same technique has been extended to instant depot migrations. [rama-pstates]
- When a Rama migration is not expressible as a function, Red Planet Labs' documented advice is to **recompute a new PState from depot data** via an explicitly blue/green procedure: launch a new module with the same code, mirror each depot, configure topologies to process from the beginning, let it catch up, stop appends on the original, then remove the mirrors. [rama-operating]
- In Rama, naming is identity: anything present in the old module but absent from the new is **destroyed**, there is **no rename**, and destructive removals must be explicitly named in the update command. [rama-operating]
- Datomic's docs explicitly distinguish accumulate-only (semantic) from append-only (structural) and state Datomic is **not** append-only and does not have append-only performance characteristics — so "just replay the log" is not Datomic's mechanism. Its four derived index trees (EAVT, AEVT, AVET, VAET) are cacheable in peers precisely because they are immutable, and views are rederived by running the same Datalog rules against an `as-of` database value rather than materializing and migrating. [datomic-overview] [datomic-indexes]

### Budgeting the rebuild / starvation

- **No surveyed system documents a canonical two-queue "dirty rows vs. fold history" budget design.** Direct search returns HPC job-scheduler backfill literature, which transfers only by analogy. Any such design is invented, not adopted. [maui-backfill]
- GitLab's batched background migrations are the most concrete budgeted design: table `batched_background_migrations` with statuses `active`, `paused`, `finalizing`, `finished`, `failed`, `finalized`, and columns `batch_size`, `sub_batch_size` (two-level batching), `job_interval`, and `total_tuple_count` for progress percentage. [gitlab-bbm]
- GitLab adapts the batch size based on the performance of **the last 20 jobs**, and on repeated timeout-type failures (`retries > MAX_ATTEMPTS && can_split?`) **splits a job into two with smaller batch size**. [gitlab-bbm]
- GitLab health-gates the loop, pausing when autovacuum is active on the target table (default-on since 18.0), the WAL queue pending archival exceeds a threshold, the WAL rate is over threshold, or the Patroni Apdex SLI is below target; **paused migrations resume after a 10-minute interval**. It runs 2 migrations concurrently by default and never two targeting the same table. [gitlab-bbm]
- GitLab documents that **cursor-based migrations may not report progress accurately**. [gitlab-bbm]
- Shopify's `maintenance_tasks` exposes `collection` → `process(item)`, `collection_batch_size(n)` (default 100), and `throttle_on(backoff: duration) { condition }` where the condition is **app-specific** — Shopify's own checks replication lag, DB threads, and write availability. Default backoff is 30s; the cursor is automatically persisted across interruptions. [shopify-maintenance-tasks]
- Shopify documents when **not** to use the pattern: if the task is not collection-based, or batches are very large, throttling/interruption buys little; and "if your application can't handle a half-completed migration, maintenance tasks are probably the wrong tool." [shopify-maintenance-tasks]
- Elasticsearch throttles `_reindex` with `requests_per_second` (default `-1` = off) by **injecting sleep between batches** — deliberately bursty, not smooth — and `POST _reindex/<task_id>/_rethrottle` adjusts a running job, with speed-ups applying immediately and slow-downs after the current batch to avoid scroll timeouts. [es-reindex] [es-rethrottle]
- In Stripe's four-phase online migration (dual-write → move reads → write only new → delete old), the expensive part was **finding** the objects needing migration, not transforming them; enumeration was offloaded to offline Hadoop/Scalding over DB snapshots rather than querying production, and individual changes were kept to a few hundred lines. [stripe-online-migrations]

### Operator visibility

- Marten exposes `AllProjectionProgress()`, `ProjectionProgressFor()`, and `WaitForNonStaleProjectionDataAsync()` with `NonStaleDataTimeoutMode.ReturnStaleData`. [marten-daemon]
- Marten splits error policy by mode — `opts.Projections.Errors` vs `opts.Projections.RebuildErrors`, with `SkipApplyErrors` / `SkipSerializationErrors` / `SkipUnknownEvents`; rebuilds are deliberately more permissive and bad events go to a dead-letter queue rather than wedging the rebuild. [marten-rebuild]
- Elasticsearch requires `POST _reindex?wait_for_completion=false` plus polling `GET _tasks/<task_id>`; the parent task shows only *completed* slices. Not setting `wait_for_completion=false` is the classic failure, as a proxy kills the connection on a long reindex. [es-reindex]
- Elasticsearch's documented pre-swap verification is comparing `_count` on old vs new — the only step that catches documents that silently failed the new mapping. [es-zero-downtime]
- The Elasticsearch/Algolia rebuild is a **point-in-time snapshot**, not a live mirror: writes during the rebuild are lost unless dual-written, paused at cutover, or replayed by a timestamp catch-up loop that reruns until an iteration finds nothing. Algolia has the same unsolved gap, and additionally cannot move an index that has replicas (`replicas`, `enableReRanking`, and `mode` are not copyable to the temp index), while analytics stay with the old index name. [es-zero-downtime] [algolia-tmp] [algolia-move]
- Rama exposes a module operation log in the Cluster UI showing updates, scales, option changes, and microbatch pauses/resumes. [rama-operating]
- Shopify exposes `tick_count`/`tick_total` plus a web UI and a lifecycle state machine (`new → enqueued → running → pausing/paused → interrupted → cancelling/cancelled → succeeded/errored`) with ActiveSupport notifications. [shopify-maintenance-tasks]

## SOURCES

**marten-rebuild**
URL: https://martendb.io/events/projections/rebuilding.html
Accessed: 2026-08-16

**marten-daemon**
URL: https://martendb.io/events/projections/async-daemon.html
Accessed: 2026-08-16
Quote: "the furthest known event sequence that the daemon knows all events at or below can be safely processed in order"

**marten-optimizing**
URL: https://martendb.io/events/optimizing
Accessed: 2026-08-16

**axon-streaming**
URL: https://docs.axoniq.io/axon-framework-reference/4.11/events/event-processors/streaming/
Accessed: 2026-08-16

**axon-replay**
URL: https://www.axoniq.io/blog/axon-framework-4-6-0-replay-context-propagation
Accessed: 2026-08-16

**kurrent-projections**
URL: https://docs.kurrent.io/server/v22.10/projections
Accessed: 2026-08-16

**event-driven-rebuild**
URL: https://event-driven.io/en/rebuilding_event_driven_read_models/
Accessed: 2026-08-16

**es-reindex**
URL: https://www.elastic.co/guide/en/elasticsearch/reference/8.19/docs-reindex.html
Accessed: 2026-08-16

**es-zero-downtime**
URL: https://www.elastic.co/blog/changing-mapping-with-zero-downtime
Accessed: 2026-08-16

**es-rethrottle**
URL: https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-reindex-rethrottle
Accessed: 2026-08-16

**algolia-move**
URL: https://www.algolia.com/doc/libraries/sdk/methods/search/operation-index
Accessed: 2026-08-16

**algolia-tmp**
URL: https://support.algolia.com/hc/en-us/articles/4407531208337-What-is-a-temporary-index
Accessed: 2026-08-16

**pg-refresh**
URL: https://www.postgresql.org/docs/current/sql-refreshmaterializedview.html
Accessed: 2026-08-16

**pg-ivm**
URL: https://github.com/sraoss/pg_ivm
Accessed: 2026-08-16

**pg-ivm-wiki**
URL: https://wiki.postgresql.org/wiki/Incremental_View_Maintenance
Accessed: 2026-08-16

**dbt-clone**
URL: https://docs.getdbt.com/best-practices/clone-incremental-models
Accessed: 2026-08-16

**dbt-slim-backfill**
URL: https://datatonic.com/insights/adding-autonomy-dbt-continuous-deployment-slim-backfills/
Accessed: 2026-08-16

**rama-pstates**
URL: https://redplanetlabs.com/docs/~/pstates.html
Accessed: 2026-08-16
Quote: "the existence of a migration doesn't slow down the module update at all"

**rama-operating**
URL: https://redplanetlabs.com/docs/~/operating-rama.html
Accessed: 2026-08-16

**datomic-indexes**
URL: https://docs.datomic.com/indexes/index-model.html
Accessed: 2026-08-16

**datomic-overview**
URL: https://docs.datomic.com/datomic-overview.html
Accessed: 2026-08-16

**gitlab-bbm**
URL: https://docs.gitlab.com/development/database/batched_background_migrations/
Accessed: 2026-08-16

**shopify-maintenance-tasks**
URL: https://github.com/Shopify/maintenance_tasks
Accessed: 2026-08-16
Quote: "If your application can't handle a half-completed migration, maintenance tasks are probably the wrong tool."

**shopify-rails-at-scale**
URL: https://railsatscale.com/2023-01-04-how-we-scaled-maintenance-tasks-to-shopify-s-core-monolith/
Accessed: 2026-08-16

**stripe-online-migrations**
URL: https://stripe.com/blog/online-migrations
Accessed: 2026-08-16

**maui-backfill**
URL: https://docs.adaptivecomputing.com/maui/8.2backfill.php
Accessed: 2026-08-16

## SYNTHESIS

The load-bearing distinction the survey exposes: **only Marten and Rama version the code that computes a projection.** Everything else versions the artifact (index name, table name) and relies on a human to notice "the code changed, rebuild now." That is the whole gap. A system can have many input checkpoints — last event seq, manifest generation, schedule checkpoint, source revision — and still be blind to an upgrade, because every one of those answers "did the inputs change?" and none answers "did the formula change?". These are orthogonal axes and no amount of input-checkpoint sophistication substitutes for the code-version axis.

dbt's `state:modified` is the cheapest transferable detector, and it scales all the way down: store a hash of the computing code (or a hand-bumped integer, which is more honest because a formatting change should not trigger a fleet rebuild) on each derived row, and staleness after upgrade is the indexed comparison `row.projection_code_version != CURRENT_CODE_VERSION`. This needs no new infrastructure, no checkpoint stream, and no second table — it is one integer column and one comparison, and it makes the "existing users see stale status, new users are fine" failure mechanically impossible to ship, because a row computed by old logic cannot claim freshness.

Rama's read-through migration is the strongest structural idea and the one most under-appreciated at small scale: apply the new computation lazily on read while the background worker backfills, so there is no rebuild window and no duplicate storage. Combined with the version column it gives an honest three-state read: version matches (serve it), version differs but recompute-on-read is cheap (recompute inline, serve it, mark clean), version differs and recompute is expensive (serve it labelled stale, enqueue). This beats Marten's blue/green duplicate tables for a single-owner app, where the value of zero-downtime is near zero and doubled storage is a real cost.

On budgeting, the honest finding is negative: **the two-lane starvation problem is not solved in the literature**, and the HPC scheduler analogies do not transfer. What the shipped systems actually provide are a persisted resumable cursor (Shopify), health-gated pause with a fixed resume interval (GitLab, Shopify `throttle_on`), and failure-driven batch splitting (GitLab). The starvation-safe scheduling policy itself must be invented, and the two sound primitives are a **fixed-ratio budget split** (never drain-dirty-then-history, which starves under sustained write load) or **alternating lanes across ticks**, which gives a hard N-tick bound rather than a soft time reservation. Instrument the two lags separately — history-cursor position and dirty-queue depth — because if both grow monotonically no scheduling policy will save it.

Three invariants worth keeping regardless of scale, all free: write the checkpoint/version in the **same transaction** as the derived data (Marten, Axon, ESDB agree independently); **do not re-fire side effects during a replay** (Marten's `GateSideEffectsBehindPriorVersion`, Axon's `ReplayStatus`); and **verify counts before the swap** (the Elasticsearch `_count` step, the only one that catches rows that silently failed the new logic). Conversely, what a one-process SQLite/Postgres app should refuse: pg_ivm (extension dependency, not production-hardened, blocks writes, errors under stricter isolation, no SQLite analogue), `REFRESH MATERIALIZED VIEW CONCURRENTLY` (Postgres-only, and a full recompute anyway), multi-instance token claiming and leader election (Axon's stop-all-instances rule, Marten `HotCold`, Shopify cross-pod tables — this is where most of the complexity in these systems lives and it buys nothing at one process), GitLab's adaptive sizing off 20-job history, and Stripe's offline enumeration (it solves "finding rows costs more than migrating them," a problem that does not exist at small scale).
