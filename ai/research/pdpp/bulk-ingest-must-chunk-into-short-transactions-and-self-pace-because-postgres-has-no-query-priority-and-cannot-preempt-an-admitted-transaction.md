---
title: "PDPP's console-freezing bulk ingest is caused by unchunked, multi-second single transactions sharing one connection pool with interactive requests in one Node process — fix by chunking bulk work into short, self-paced transactions and giving interactive queries a role-scoped short statement_timeout, because Postgres has no query priority and cannot preempt a transaction once admitted"
date: 2026-08-21
topic: pdpp
tags: [postgres, admission-control, contention, workload-isolation, bulk-ingest, statement-timeout, connection-pool, chunking, backpressure, single-user]
status: settled
sources: [pg-priorities-wiki, pg-alterrole, pg-set, pg-runtime-config-client, pg-vacuum-cost, pg-explicit-locking, pg-warm-standby, oracle-drm, sqlserver-resource-governor, cockroachdb-admission-control, tidb-resource-control, pgbouncer-config, linux-cfs, sched7, cgroups-v2, rocksdb-write-stalls, rails-in-batches, stripe-rate-limits, node-postgres-pool, live-measurement]
source_session: af82d1f3-1838-4307-a3a9-6bbf07e77c6f
---

## CLAIMS

- Live measurement (2026-08-21, read-only, `pdpp-postgres-1`/`pdpp-core-prod-drain`): the source-detail page took 44.5s wall-clock (HTTP 200, server-side) while a Google Maps re-ingest of 299,248 records plus embedding generation ran concurrently; `pg_stat_activity` showed an `INSERT INTO semantic_search_blob ... SELECT` running 8.2s and a `SELECT ... FROM records WHERE connector_instance_id = $1 AND stream = $2 AND deleted = FALSE AND id > $3` running 10.7s; cancelling the ingest dropped the page to 6.0s. [live-measurement]
- Live EXPLAIN (ANALYZE, BUFFERS) of the same SELECT shape, at rest with nothing else running, against `connector_instance_id = 'cin_2de5ede05c8cc8d45935c414', stream = 'messages'` (2,192,453 live rows for that instance/stream): 4014ms execution time, `Index Scan using records_pkey on records` (i.e., scanning by primary key `id`, not by a covering index), filtering away 378,591 rows to return 500, reading 81,862 buffers from disk (`shared hit=31609 read=81862`). The `records` table (5,612,924 live rows) has seven indexes but none has `id` as a trailing/covering column alongside `(connector_instance_id, stream, deleted)` — `idx_pg_records_stream_cursor` is keyed on `(connector_instance_id, stream, deleted, cursor_value, primary_key_text)`, not `id`. This is a genuine missing-index defect independent of contention: at rest, 4s for one page-load query is already bad. [live-measurement]
- Live architecture (2026-08-21, read-only): the RI runs as one Node process (`server/index.ts`, confirmed via `ps aux` inside `pdpp-core-prod-drain` — no `child_process`/`fork`/`worker_threads` used for connector execution or scheduling); the HTTP server, the run scheduler, and the connector/embedding runtime share this single process, single event loop, and single Postgres connection pool. `postgres-storage.ts` and `postgres-search.ts` construct `new Pool({ connectionString: config.databaseUrl })` with no `max` option set anywhere in the codebase, so node-postgres's library default (`max: 10`) applies — the same 10-connection pool serves interactive HTTP request handlers and the background bulk-ingest/embedding pipeline. [live-measurement]
- Live config (2026-08-21, read-only): Postgres 16.14, `max_connections = 100`, `statement_timeout = 0` (unset — no server-side or session-level statement budget exists anywhere today); the app container (`pdpp-core-prod-drain`) is capped at 6 CPU / 6 GB, but the Postgres container (`pdpp-postgres-1`) has `NanoCpus=0, Memory=0` (unconstrained), sharing an unconstrained 24-CPU/124GB host. [live-measurement]
- PostgreSQL's own wiki states plainly: "PostgreSQL has no facilities to limit what resources a particular user, query, or database consumes, or correspondingly to set priorities such that one user/query/database gets more resources than others. It's necessary to use operating system facilities to achieve what limited prioritization is possible." [pg-priorities-wiki]
- `vacuum_cost_delay`/`vacuum_cost_limit` throttle I/O only for `VACUUM` and `ANALYZE`, documented under "19.10 Vacuuming," not the general resource-consumption section; there is no equivalent GUC that applies a cost-based delay to arbitrary user `INSERT`/`SELECT`/`COPY` statements. [pg-vacuum-cost]
- `statement_timeout` and `lock_timeout` are ordinary GUCs settable per-role via `ALTER ROLE rolename [IN DATABASE dbname] SET statement_timeout = ...`, and scopable to a single transaction inside a pooled connection via `SET LOCAL` (which reverts at transaction end, unlike bare `SET`, which leaks across pooled clients under PgBouncer transaction-mode pooling). [pg-alterrole] [pg-set] [pg-runtime-config-client]
- Once a transaction is admitted, Postgres holds its acquired locks for the transaction's full duration: `INSERT`/`UPDATE`/`DELETE` acquire `ROW EXCLUSIVE`, which conflicts with several other lock modes, and nothing external (no client-side pacer, no rate limiter) can interrupt or shrink an already-running transaction from outside — only `statement_timeout`/`lock_timeout` (evaluated at the DB) or killing the backend can. [pg-explicit-locking]
- PgBouncer's `pool_mode` (session/transaction/statement) is a connection-multiplexing knob only; it has no query-priority or admission-control mechanism — it does not inspect query cost/duration to prioritize clients. Separate `[databases]` aliases pointing at the same database with different `pool_size` values partition connection-count budgets ("lanes") but do not preempt a running batch connection to let an interactive one through. [pgbouncer-config]
- Oracle Resource Manager (consumer groups + resource plans, CPU allocation, active-session-pool limits), SQL Server Resource Governor (workload groups/resource pools with CPU/memory/IO caps, classifier function at logon), CockroachDB admission control (per-node work queues by priority, explicit "elastic" vs "regular" work classification), and TiDB resource control (Request-Unit token-bucket per resource group) are all kernel/engine-level admission control systems with no Postgres equivalent; the shared transferable principle across all four is classify work into named lanes at admission time and make batch/background work self-limiting (concurrency cap + rate limit + timeout), not evenly competing with interactive work. [oracle-drm] [sqlserver-resource-governor] [cockroachdb-admission-control] [tidb-resource-control]
- Linux CFS's `SCHED_BATCH` and `SCHED_IDLE` classes, and cgroups v2 `cpu.weight`/`cpu.idle`/`io.weight`, implement proportional-share scheduling with a floor (batch always makes progress but is capped to a minority share) rather than strict lower priority (which risks unbounded starvation/priority inversion); `SCHED_IDLE` deliberately avoids being true-idle-only "in order to avoid priority inversion problems which would deadlock the machine." [linux-cfs] [sched7] [cgroups-v2]
- RocksDB throttles/stalls writes based on internal backlog signals (level-0 SST count, estimated pending-compaction-bytes) entirely inside its own write path, because it owns both the write path and the compaction path; this is storage-engine-side admission control, not client-side pacing, and Postgres has no equivalent hook exposed to an external client for arbitrary bulk writers. [rocksdb-write-stalls]
- Rails `ActiveRecord::Batches#in_batches` documents `relation.in_batches { |r| r.delete_all; sleep(10) }` as the idiom for "throttle the delete queries," with a default batch size of 1000 rows, chosen to bound per-transaction lock duration and memory, not row count per se. [rails-in-batches]
- Stripe's bulk/migration guidance separately warns that rate limiting (request volume) does not prevent `lock_timeout` 429s from concurrent writes to the same object, and recommends serializing writes to a given object rather than only slowing throughput — an independent confirmation that pacing and lock contention are different failure modes. [stripe-rate-limits]
- Streaming replication is asynchronous by default with documented lag "typically under one second assuming the standby is powerful enough to keep up with the load," but requires a second full Postgres instance (storage, config, replication role, `pg_hba.conf`, and monitoring of replication lag/slot bloat). [pg-warm-standby]

## SOURCES

**pg-priorities-wiki**
URL: https://wiki.postgresql.org/wiki/Priorities
Accessed: 2026-08-21
Quote: "PostgreSQL has no facilities to limit what resources a particular user, query, or database consumes, or correspondingly to set priorities such that one user/query/database gets more resources than others."

**pg-alterrole**
URL: https://www.postgresql.org/docs/current/sql-alterrole.html
Accessed: 2026-08-21

**pg-set**
URL: https://www.postgresql.org/docs/current/sql-set.html
Accessed: 2026-08-21

**pg-runtime-config-client**
URL: https://www.postgresql.org/docs/current/runtime-config-client.html
Accessed: 2026-08-21

**pg-vacuum-cost**
URL: https://www.postgresql.org/docs/current/runtime-config-vacuum.html
Accessed: 2026-08-21

**pg-explicit-locking**
URL: https://www.postgresql.org/docs/current/explicit-locking.html
Accessed: 2026-08-21

**pg-warm-standby**
URL: https://www.postgresql.org/docs/current/warm-standby.html
Accessed: 2026-08-21
Quote: "typically under one second assuming the standby is powerful enough to keep up with the load"

**oracle-drm**
URL: https://docs.oracle.com/en/database/oracle/oracle-database/19/admin/managing-resources-with-oracle-database-resource-manager.html
Accessed: 2026-08-21

**sqlserver-resource-governor**
URL: https://learn.microsoft.com/en-us/sql/relational-databases/resource-governor/resource-governor?view=sql-server-ver17
Accessed: 2026-08-21

**cockroachdb-admission-control**
URL: https://www.cockroachlabs.com/docs/stable/admission-control
Accessed: 2026-08-21

**tidb-resource-control**
URL: https://docs.pingcap.com/tidb/stable/tidb-resource-control/
Accessed: 2026-08-21
(Full-text extraction failed at fetch time — JS-rendered docs site; URL is the correct primary-source location for a well-established, publicly documented product feature.)

**pgbouncer-config**
URL: https://www.pgbouncer.org/config.html ; https://www.pgbouncer.org/features.html
Accessed: 2026-08-21

**linux-cfs**
URL: https://www.kernel.org/doc/html/latest/scheduler/sched-design-CFS.html
Accessed: 2026-08-21

**sched7**
URL: https://man7.org/linux/man-pages/man7/sched.7.html
Accessed: 2026-08-21
Quote: "SCHED_IDLE ... in order to avoid priority inversion problems which would deadlock the machine."

**cgroups-v2**
URL: https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html
Accessed: 2026-08-21

**rocksdb-write-stalls**
URL: https://github.com/facebook/rocksdb/wiki/Write-Stalls
Accessed: 2026-08-21
Quote: "RocksDB has extensive system to slow down writes when flush or compaction can't keep up... slow down incoming writes to the speed that the database can handle."

**rails-in-batches**
URL: https://api.rubyonrails.org/classes/ActiveRecord/Batches.html
Accessed: 2026-08-21

**stripe-rate-limits**
URL: https://docs.stripe.com/rate-limits
Accessed: 2026-08-21

**node-postgres-pool**
URL: https://node-postgres.com/apis/pool
Accessed: 2026-08-21
(Default `max: 10` per Pool instance when unset; confirmed against PDPP's own `postgres-storage.ts`/`postgres-search.ts`, neither of which passes `max`.)

**live-measurement**
Source: direct read-only inspection of `pdpp-postgres-1`/`pdpp-core-prod-drain` on 2026-08-21 (`pg_stat_activity`, `EXPLAIN (ANALYZE, BUFFERS)`, `\d records`, `docker inspect`, `docker exec ... ps aux`, and reading `reference-implementation/server/postgres-storage.ts`, `postgres-search.ts`). No production data modified; no connector runs triggered.

## SYNTHESIS

### The invariant

**An interactive request's Postgres work must never wait behind a bulk job's transaction — because no single transaction bulk ingest issues may run longer than the interactive-request latency budget.** This is a statement about transaction *duration*, not about concurrency, CPU, or priority — because duration is the one property Postgres actually lets you bound (`statement_timeout`/`lock_timeout`), and it is also the *cause* actually measured today: an 8.2s INSERT and a 10.7s SELECT, each one transaction, each already admitted, neither preemptible once running.

### Why the "obvious" fixes are the wrong ones

The research converges hard on one negative fact: **Postgres has no query priority, no admission control, and no way to preempt an admitted transaction** (confirmed directly on the PostgreSQL wiki). Every enterprise system that DOES have this — Oracle Resource Manager, SQL Server Resource Governor, CockroachDB, TiDB — implements it *inside the query engine itself*, at a layer PDPP does not own and cannot replicate by configuration. `vacuum_cost_delay` looks like a precedent for cost-based self-throttling but is hard-scoped to VACUUM/ANALYZE only; it is not a general mechanism, and there is no way to point it at an arbitrary `INSERT...SELECT`. PgBouncer pool partitioning caps *how many* batch connections can exist, which is real but orthogonal — it does nothing once a connection is already running a long statement. A read replica is the closest thing to "real" isolation available, but on this box (Postgres unconstrained on a 24-CPU/124GB host, the *app* container capped at 6/6, not Postgres) there is no evidence the resource ceiling is even the binding constraint — CPU/memory headroom is not what caused the 44.5s page load; a single held lock and pool contention did. Building a second Postgres instance to fix a single held lock is solving the wrong layer, and it roughly doubles the operational surface (a second instance to patch, back up, and monitor for replication-slot bloat) for a single-user system with no ops team. This is the OWN/RENT/DELETE objective function (`project_own_rent_delete_objective_function_v1`) failing on RENT cost for a DELETE-sized problem.

Because Postgres gives no preemption, the two research forks converge on the same structural fact from opposite directions: RocksDB's write-stall mechanism works *because RocksDB owns the write path* and can insert delay inside `write()` itself; Postgres offers no equivalent hook to an external client. Client-side pacing (chunking + sleeping) can prevent the *next* batch from starting, but cannot interrupt a batch already inside Postgres. **This means workload-side pacing is necessary but not sufficient** — it must be paired with a hard ceiling on the size of any single admitted unit of work, or the tail is unbounded regardless of how politely you pace between units.

### The recommended design

Two independently shippable changes, composing exactly the way the four-mechanism survey said they would (partition + chunk/backpressure, not partition-only or chunk-only):

**1. Chunk every bulk-ingest transaction to a bounded row count / bounded wall-clock duration, and commit each chunk as its own transaction.** The Google Maps embedding write (`postgresSemanticIndexInsertManyGuarded` in `postgres-search.ts`) and the coverage-scan SELECT that feeds it currently run as unchunked bulk operations processing the full 299,248-record set (or large sub-batches of it) inside single transactions. Cap each transaction to, e.g., 500-1000 rows or a measured ~200ms execution budget (Rails' `in_batches` 1000-row default is the closest documented precedent, chosen for exactly this reason — bounding lock-hold duration, not row count per se). This directly bounds the worst case an interactive query can be blocked behind, because it bounds how long any one lock can be held. It is also a **behavior-preserving refactor**, not new machinery: the batch SQL shape is unchanged; only its row-count/duration boundary moves.

**2. Give the bulk-ingest connection role a bounded `statement_timeout`/`lock_timeout` via `ALTER ROLE ... SET`, distinct from the interactive path.** This is the backstop for chunk #1 — if a chunk still runs long (e.g., embedding generation on an anomalously large batch), the DB itself kills it rather than letting it run unbounded. This requires either a second Postgres role for bulk work (clean, matches the "classify at admission" principle from Oracle/SQL Server/Cockroach/TiDB) or, more cheaply and without a schema/role change, `SET LOCAL statement_timeout = '2s'` wrapped around each bulk chunk's transaction in application code, which the RI already fully controls since it owns every query call site.

Do **not** stop there without also addressing pool starvation: the shared 10-connection node-postgres pool (no `max` set) means a burst of bulk-chunk transactions can still starve interactive HTTP handlers of a connection even if each individual transaction is now short — a queueing problem, not a lock-duration problem. The fix is cheap and composes with #1/#2: **split the single Pool into two Pools in the same process** (e.g., `interactivePool` sized ~6-8, `bulkPool` sized ~2-3, both well under `max_connections=100`), so a burst of chunked bulk work cannot exhaust the connections interactive handlers need. This is the PgBouncer "pool alias partitioning" principle (Q1) applied at the node-postgres layer directly, without adding an infrastructure component — cheaper than deploying PgBouncer for a single Node process talking to a single Postgres instance.

None of this requires touching the observed second finding (the 4-second-at-rest source-detail query) to close the contention question, but it is real and should be fixed on its own merits: add an index covering `(connector_instance_id, stream, deleted, id)` so the cursor-style `id > $3 ORDER BY id LIMIT n` pagination stops falling back to a full-index-order scan-and-filter over `records_pkey`. This is unrelated to admission control and should ship as a separate, independently gated change — conflating it with the contention fix would violate D14 (behavior preservation is a gate; prove each change's effect in isolation).

### What it deletes or prevents

- Deletes the need for a second Postgres instance, PgBouncer, or any new infrastructure component — the fix is entirely inside the existing single Node process and existing Postgres instance.
- Deletes the possibility of a single unchunked bulk transaction holding a lock for 8-11 seconds (measured today), because no transaction chunk can run longer than its bound.
- Prevents pool starvation from a burst of even-short chunked transactions, which chunking alone would not fix.
- Prevents the class of defect the maintenance-drain fix already established as correct at the DB layer: **raising a timeout is not a fix; making the work cheap is** — this design applies that precedent to contention, not just to the drain-discovery-query case it originated from.

### Anti-scope — what NOT to build, and why

- **A read replica.** Confirmed independently by both research forks: over-engineering for a single-user system where Postgres itself is not resource-constrained; doubles operational surface (second instance to patch/back up/monitor for replication-slot bloat) to solve a lock-duration problem replication does not address (a replica has the same problem writing its own bulk work, and reads still need to reach *some* freshness bound).
- **PgBouncer.** Solves connection multiplexing, which is not the measured problem (max_connections=100 is nowhere near exhausted); adds a new proxy component, new config surface, and new failure mode (PgBouncer's own `SET` semantics under transaction-mode pooling, which the research explicitly flags as a footgun) to solve what a two-Pool split inside the existing Node process solves for free.
- **A custom in-process query-priority scheduler** (e.g., a priority queue that reorders which pending query fires next). This attempts to build, in userland, the exact class of mechanism (Oracle DRM/SQL Server Resource Governor/Cockroach admission control) that costs those vendors dedicated kernel-level engineering teams — and it still could not preempt a transaction Postgres has already admitted, so it would not even solve the measured problem. Rejected under the canon's "reject shallow abstraction" test: it adds machinery whose promised guarantee it cannot actually deliver.
- **OS-level `nice`/cgroup manipulation of Postgres backend PIDs.** The Postgres wiki names this as the *only* native lever, but it is fragile (per-connection PIDs churn under pooling, requires the app to know and re-nice each new backend PID at connection time) and unsupported by Postgres itself. Chunking + role-scoped timeouts + pool partitioning achieve the same practical outcome without touching OS process priorities.
- **A generic "backoff on observed interactive p99" adaptive controller** modeled on the congestion-control corpus entries (`congestion-control-theory-transfers-to-http-scrapers...`, `client-side-rate-governance-uses-three-separable-layers...`). Those entries solve a different problem — pacing *outbound* requests against a *remote* provider whose rate limit is unknown and where 429 is the only signal. Here the ceiling (connection pool size, transaction duration bound) is fully known and locally controlled; AIMD-style discovery is solving a harder problem than exists. One research fork also found no strong documented prior art for exactly this pattern (self-throttle against a *co-located* workload's p99) — building it now would be inventing unproven plumbing to solve a problem two much simpler, well-precedented mechanisms (chunking + timeouts) already solve.

### Falsifiable test

Extend the canary harness (`reference-implementation/scripts/canary/deploy-canary.ts`, `feat/canary-harness-0821`, not yet on `main`) with a `sql_scalar` check using its existing `must_be_at_most` predicate:

1. **Pre-registered metric**: p95 wall-clock latency of the source-detail page's `records` query, sampled via `pg_stat_activity`/`pg_stat_statements` mean/max `total_exec_time` for that query's `queryid`, OR (simpler, no `pg_stat_statements` dependency) an HTTP-level canary check hitting the source-detail endpoint directly during a triggered bulk-ingest fixture.
2. **Before**: with the fix NOT deployed, trigger a bulk ingest (reusable fixture, not a real OTP-costing connector run — a synthetic bulk INSERT/embedding-write load against a scratch connector_instance_id) and confirm interactive query latency exceeds a bound (reproduce today's ~44s, or a scaled-down deterministic equivalent).
3. **After**: same fixture, same concurrent load, with chunking + role-scoped `statement_timeout` + pool split deployed; assert p95 interactive latency stays under a fixed bound (e.g., 2s) via `must_be_at_most`, and assert `pg_stat_activity.query_start` age for any single bulk-writer transaction never exceeds the chunk's duration bound (a second `sql_scalar` check, `must_be_at_most` against `EXTRACT(EPOCH FROM (now() - query_start))` filtered to the bulk role).
4. Both checks are `blocking: true` in the manifest per D15/D14 — pre-registered before deploy, not narrated after.

### Staged migration (each step independently shippable, behavior-preserving)

1. **Add `ALTER ROLE <bulk_role> SET statement_timeout = '5s'` (or similar bound) for the connection role the ingest/embedding pipeline uses.** Zero behavior change for anything that already completes within the bound; only anomalously-long unchunked work is affected, and today that work is exactly the defect. Ships alone, immediately measurable via the canary's `sql_scalar` check on `pg_stat_activity` age.
2. **Split the single node-postgres `Pool` into `interactivePool`/`bulkPool`**, routing HTTP request handlers through one and the connector/embedding runtime through the other. Pure plumbing change; total connections stay well under `max_connections=100`. Independently testable: confirm interactive requests never block on pool `.connect()` during a bulk run.
3. **Chunk `postgresSemanticIndexInsertManyGuarded` and its feeding coverage-scan SELECT to a bounded batch size** (start at 1000 rows per the Rails precedent; tune against measured per-chunk duration against this schema/hardware). Each chunk commits independently; total ingest work is unchanged, only its transaction boundaries move. This is the change most likely to need iteration — measure per-chunk duration live and adjust batch size to land chunks well under step 1's timeout.
4. **(Separate change, not gating 1-3) Add the covering index for the source-detail page's `id`-ordered pagination query.** Independently shippable, independently measurable via the same EXPLAIN ANALYZE method used to characterize it here; fixes the ~4s-at-rest floor that steps 1-3 do not touch.

Sequence matters only weakly here (unlike the D17 ledger/state-machine ordering) — steps 1 and 2 are pure safety nets and can land in either order or together; step 3 is the actual fix for the measured incident and should land before declaring the invariant proven; step 4 is fully independent and can land any time.
