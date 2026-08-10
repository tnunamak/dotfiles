# Deep bug hunt — PDPP reference implementation (2026-07-03)

Diagnosis-first correctness audit of `reference-implementation/`. Emphasis on
non-RED code (races, off-by-one, null/undefined, error handling, resource
leaks, async mistakes, boundary conditions, logic inversions, state/lifecycle
bugs). One fix applied (SEARCH-1); everything else is diagnosis-only.

**Author:** autonomous bug-hunt run (Tim Nunamaker <tnunamak@gmail.com>).
**Branch:** `waspflow/sp2-bughunt`. **Not pushed.**

---

## Methodology

- **Fan-out + verify.** Six adversarial sub-agents each owned a subsystem
  cluster (scheduler/runtime, search/explore, streaming/browser-surface,
  read-models/verdict, postgres/db/records, routes/ref-control). Each was told
  to *disprove* every candidate before recording it, and to report exact
  `file:line`, concrete triggering state → wrong result, severity, and
  confidence.
- **Independent re-verification of the strongest claims.** Every finding rated
  *high* below was re-read and re-derived by the orchestrator directly (the
  maker is not the judge). Two claims were **downgraded** on that pass
  (DB-MIGRATION-1, EXPLORE contract note) — recorded honestly.
- **Repro-first for the top finding.** VERDICT-1 was reproduced with a
  standalone executable model of the exact comparison logic before recording.
- **Direct deep reads** by the orchestrator covered pure-logic modules that
  came back clean: `scheduler-source-pressure-cooldown.ts`, `queries/index.ts`,
  `connection-setup-plan.ts`, `explore-timeline-substrate.ts`,
  `record-version-stats.js`, `retained-size-read-model.js`,
  `deployment-diagnostics.ts`, `connector-detail-gap-store.js`, and the
  `controller.ts` drain/watchdog lifecycle.

**Overall:** this is an unusually defensive, well-tested codebase. Most
subsystems came back clean; the surviving findings are concentrated in
concurrency/lifecycle state machines (controller run-cleanup, neko-adapter
start/stop) and in a handful of dialect-divergence / precedence-collapse bugs
where a Postgres port or a rank-mapping dropped a case its SQLite/6-value
counterpart handled.

Confidence/severity are the orchestrator's after re-verification, which
sometimes differs from the sub-agent's original rating.

---

## Ranked summary (most severe first)

| ID | Sev | Conf | File | One-liner |
|----|-----|------|------|-----------|
| VERDICT-1 | high | high | `runtime/rendered-verdict.ts:517-537` | Worst-wins disposition uses 4-bucket tone-rank for a 6-value domain → drops `awaiting_owner`/`owner_refresh_due` |
| CTRL-1 | high | high | `runtime/controller.ts:2578,2594` | `finalizeRunCleanup` deletes a *different live run's* `activeRuns` entry (no identity check) → breaks single-active-run invariant |
| HEALTH-1 | high | high | `runtime/connection-health.ts:1485,1478,2574` | Durably-rejected credential on a previously-successful connection projects `healthy` |
| PG-CURSOR-1 | high | high | `server/postgres-records.js:1265-1280` | Postgres cursor pagination silently drops rows when `cursor_value` is NULL (SQLite has the 4-branch seek; PG omits it) |
| PG-SPINE-STATUS-1 | high | high | `lib/postgres-spine.ts:788-800` | Status-filtered spine pagination slices *before* filtering with no over-fetch → misses genuinely-`succeeded` runs |
| PG-SEMANTIC-LIMIT-1 | high | high | `server/postgres-search.js:704-712` | JSONB semantic fallback applies `LIMIT` before ranking → arbitrary (non-nearest) top-K |
| STREAM-1 | high | high | `server/streaming/neko-adapter.js:997-1007` | Concurrent SSE attach double-starts a companion (orphaned AbortController + duplicate poll loop) |
| STREAM-2 | high | med | `server/streaming/neko-adapter.js:991-1019` | `start()` never re-checks `closed` across awaits → `stop()` race resurrects browser client + leaks poll loop |
| SPINE-SYNC-1 | high | high | `lib/spine.ts:643` | `listSpineEventsPage` returns a Promise force-cast to a sync type under Postgres → `undefined`/`TypeError` for non-awaiting callers |
| PG-BACKFILL-1 | med-high | high | `server/postgres-storage.js:1909-1921` | Orphan `connector_instance_id` synthesized when a `connector_id` maps to 0 or ≥2 instances |
| STREAM-3 | med | high | `server/streaming/routes.js:802-833` | Minted-but-never-attached companion has no TTL sweep → unbounded leak |
| STREAM-4 | med | high | `server/streaming/routes.js:678-728` | `handleNekoHttpProxy` never aborts upstream on client disconnect |
| STREAM-5 | med | high | `server/streaming/neko-adapter.js:613-704` | In-flight `getBrowserClient()` resurrects a client after `closeBrowserClient()` already ran |
| PG-LEASE-IDX-1 | med | high | `server/db.js:698-700,1438-1440` | SQLite pending-lease unique index omits `surface_subject_id` (PG includes it) → blocks per-subject concurrent leases on SQLite |
| CTRL-2 | med | high | `runtime/controller.ts:675` | `settledRunIds` grows unbounded (added on every completion, removed only on a rare reclaim path) |
| CTRL-3 | med | high | `runtime/scheduler.ts:446` + `run-executor.ts:669,803` | `runtime.history` grows unbounded and is full-scanned per dispatch tick |
| SEARCH-1 | med | med | `server/search-semantic.js:988` | **FIXED** — `compareHits` returned NaN on non-finite distance, breaking the total order |
| ROUTE-AUDIT-1 | med | med | `server/routes/owner-connection-intent.ts:340-375` | Awaited success-audit between an irreversible mint and the response → audit failure orphans a live secret + returns 500 |
| ROUTE-URI-1 | med | med | `server/routes/rs-read.ts:1915,2095,2728` | `decodeURIComponent` throws before `queryContext` init → untyped 500 + lost audit on a malformed id |
| PG-LIKE-1 | low | med | `server/postgres-search.js:274-294,356-364` | `scope_key` LIKE-prefix unescaped for `%`/`_` in stream names |
| STREAM-6 | low | med | `server/streaming/routes.js:186-207` | WS upgrade proxy misses abrupt (non-`error`) client-close cleanup |
| STREAM-7 | low | med | `server/streaming/playground.js:476` | Single module-level `cleanupBrowser` clobbered across concurrent backends (dev-only) |
| METADATA-1 | low | high | `server/metadata.ts:85` | Link-local IPv6 `fe80::/10` under-detected (only `fe80:` matched) |
| SCHED-STOP-1 | low | med | `runtime/scheduler/run-executor.ts:816-839` | `stop()` racing a manual run emits a misleading `failed: unknown` audit record |
| DB-MIGRATION-1 | low | med | `server/db.js:1523` | `NULL AS surface_subject_id` in a one-shot rebuild — **downgraded** (NULL→NULL on the real path) |
| SEARCH-DATE-1 | low | low | `server/search.js:1702`, `search-semantic.js:2477` | `created_at + 'Z'` relies on V8-lenient Date parsing (fragile, not currently broken) |

---

## By subsystem

### Verdict rendering

#### VERDICT-1 (high / high) — disposition worst-wins collapses a 6-value domain through a 4-value tone rank
`runtime/rendered-verdict.ts:517-537`, `connectionDisposition`.

`ForwardDisposition` has six values with a real severity order
(`complete` < `owner_refresh_due` < `checking` < `resumable` < `awaiting_owner`
< `terminal`, per `deriveForwardDisposition` in `connection-health.ts:2331`).
The worst-wins loop compares them via `TONE_RANK[dispositionTone(...)]`, but
`dispositionTone` maps those six onto only four tones:

- `complete` → green (0), `owner_refresh_due` → **green (0)** — tied
- `resumable` → amber (2), `awaiting_owner` → **amber (2)** — tied

The loop guard is strict `if (rank > worstRank)`, so a stream disposition can
never override a snapshot disposition that shares its tone.

**Repro (verified with a standalone model of the exact logic):**
- snapshot `resumable` + one required stream computing `awaiting_owner` → both
  amber → connection reported **`resumable`** (should be `awaiting_owner`). A
  connection actually blocked on the owner is framed as "the next run will fill
  it."
- snapshot `complete` + a required stream computing `owner_refresh_due` → both
  green → reported **`complete`** (should be `owner_refresh_due`). The
  special-case at line 531 only patches the *reverse* direction (snapshot
  already `owner_refresh_due`, streams roll to `complete`).
- Control: snapshot `resumable` + required `terminal` → red overrides
  correctly (proves the mechanism only fails on tied tones).

`detail.forward_disposition` is the documented single source of truth: it drives
`forward_statement`, the `terminal` flag on connection-level required actions,
and the progress headline. Blast radius is partially bounded because
`buildRequiredActions` reads the connection-level attention axis directly, so an
`add_info` action can still fire — but the forward statement/progress headline
misreport, and a divergence originating purely from a stream-level
`attention_open` (without the connection axis open) can be missed entirely.

**Fix (diagnosis-only — behavior-changing, ambiguous intended ordering, wide
verdict test surface):** compare on a dedicated `DISPOSITION_RANK` over the
6-value `ForwardDisposition` domain instead of reusing the 4-bucket tone rank.

### Runtime / controller / scheduler

#### CTRL-1 (high / high) — `finalizeRunCleanup` can delete a different, live run's entry
`runtime/controller.ts:2578` (guard) and `:2594` (delete).

The idempotency guard checks `!activeRuns.has(input.key)` — *presence*, not
*identity*. Race:
1. Run A (key K) hangs; the wall-clock watchdog force-finalizes A →
   `activeRuns.delete(K)`, `settledRunIds.add(A)`.
2. A's abort is cooperative, so A's process hasn't exited. Run B is admitted at
   key K (`assertNoConflictingActiveRun(K)` sees no entry) →
   `activeRuns.set(K, B)`.
3. A's original promise finally settles → its `.finally()` calls
   `finalizeRunCleanup(A)` again. Now `activeRuns.has(K)` is true (it's **B**),
   so the guard is bypassed and line 2594 does `activeRuns.delete(K)` —
   deleting **B's** live entry.

After that, `activeRuns` shows no active run for a connector that is running B;
the next `runNow` bypasses `assertNoConflictingActiveRun` and admits a third
concurrent run, defeating the single-active-run-per-connector invariant. The DB
layer already hardened exactly this race (`deleteActiveRun(connectorInstanceId,
runId)` is scoped by both fields); the in-memory map was not.

**Fix (diagnosis-only — core run lifecycle, RED-adjacent; couldn't run the full
run-lifecycle test suite to prove no regression):** before mutating, require
`activeRuns.get(input.key)?.run_id === input.runId`; otherwise this cleanup is
for a superseded run and should no-op (still record it settled). This is
behavior-preserving on the normal path.

#### CTRL-2 (med / high) — `settledRunIds` grows unbounded
`runtime/controller.ts:675` (decl), added at `:2581`/`:2593` on every
completion, removed only at `:2639` in the rare stale-reclaim branch. One string
leaks per historical run for the process lifetime. Fix: delete from
`settledRunIds` at the end of `finalizeRunCleanup` once its guard purpose is
served, or use a bounded/TTL structure.

#### CTRL-3 (med / high) — `runtime.history` grows unbounded and is rescanned per tick
`runtime/scheduler.ts:446`, pushes at `run-executor.ts:669`/`:803` and
`scheduler.ts:634`, full-array `filter` per connector per tick at
`scheduler/dispatch-governor.ts:410`. `hydratePersistence` caps only the
*initial* load (`listRunHistory(500)`); nothing trims afterward. Both memory and
per-tick CPU degrade over the process lifetime. Fix: cap to a bounded window (or
index by connector key to avoid the full-array filter).

#### SCHED-STOP-1 (low / med) — `stop()` racing a manual run yields `failed: unknown`
`runtime/scheduler/run-executor.ts:816-839`. If `stop()` sets
`runtime.running = false` just as a manual `runWithRetries` enters, the loop
breaks at `attempt = 0`, `lastError = null` → `finalizeExhaustedFailure(...,
null, 0)` writes a synthetic `failed: "unknown"` audit record for a run that
never attempted anything. Fix: emit a distinct `scheduler_stopped` outcome for
the `attempt === 0 && lastError === null` break.

### Connection health

#### HEALTH-1 (high / high) — durably-rejected credential projects `healthy`
`runtime/connection-health.ts`: `isHealthyConditionSet` (1485-1498),
`hasDegradingCondition` (1478-1480), `readinessBlockedCondition` (2574-2587).

For a connection whose latest run **succeeded** (`CollectionSucceeded === true`,
Fresh, coverage complete) but whose durable credential evidence is
`{capable:true, rejected:true}`:
- `credentialsValidCondition` returns `CredentialsValid: false, severity:
  blocked` (verified — `credentialRejectedCondition` sets `severity:"blocked"`).
- `classifyReadinessBlocked` → `readinessBlockedCondition` **returns null when
  `CollectionSucceeded === "true"`**, short-circuiting past the blocked
  credential.
- `classifyDegradedEvidence` → `hasDegradingCondition` **explicitly excludes
  `CredentialsValid`**.
- `classifyHealthy` → `isHealthyConditionSet` **never references
  `CredentialsValid`** → returns `healthy`.

The only escape is `classifyOpenAttention`, which requires a structured
attention record to also be open — independent of durable credential rejection.
The whole purpose of `ConnectionCredentialEvidence` (per its docstring) is the
case where the run succeeded but the credential *later* broke, so no fresh
attention/failure exists yet. Result: green pill, no reconnect prompt, until the
next run happens to fail on its own.

**Fix (diagnosis-only — behavior-changing on a core, heavily-tested,
owner-facing projection):** add a `CredentialsValid` check to
`isHealthyConditionSet`, and don't let `CollectionSucceeded === "true"`
short-circuit `readinessBlockedCondition` past a `blocked`-severity
`CredentialsValid: false`.

### Streaming / browser-surface

Cluster root cause for STREAM-1/2/5: `neko-adapter.js`'s `closed`/`started`
state machine is checked only at function entry, never re-validated across
`await` boundaries, so `start()`/`stop()`/`getBrowserClient()` interleave into
double-start and use-after-close races. Fixing the recheck discipline resolves
three findings at once.

#### STREAM-1 (high / high) — concurrent SSE attach double-starts a companion
`server/streaming/neko-adapter.js:997-1007` (+ route attach at
`routes.js:942,1079`). `streamingSessions.attach()` is non-exclusive (verified
by direct read of `streaming-session-store.ts:245-278`: no consumption gate;
`attached_at` is set once but never blocks re-attach). Two concurrent
`GET .../events` on one token both get a session and both call
`companion.start()`. In `start()`, the only guard is `if (started) return;`
(line 997) but `started = true` is set at line 1004, **after four awaits**
(`authenticate`, `applyViewportBestEffort`, `setupFocusDetectionBestEffort`,
`applyInitialNavigation`). Both calls pass the guard while `started` is still
false, both run `abortController = new AbortController()` (line 998 — second
orphans the first), both reach line 1005 launching **two** `pollLoop()`s.
`stop()` only aborts/awaits the current pair, so the first loop leaks. Fix: set
`started`/`starting` synchronously before the first await, or single-flight via
a `startPromise` (as `getBrowserClient` does for `browserClientPromise`).

#### STREAM-2 (high / med) — `stop()`/`start()` race resurrects a browser client
`server/streaming/neko-adapter.js:991-1019`. `start()` checks `closed` only at
entry (line 992). If `stop()` runs during an in-flight `start()`,
`pollLoopPromise` is still null so `stop()`'s `await` is a no-op and
`closeBrowserClient()` runs immediately; meanwhile `authenticate()` early-returns
with **no signal check** when already authed and the best-effort steps swallow
abort errors, so `start()` proceeds past the abort to `applyInitialNavigation()`
→ `getBrowserClient()`, reconnecting a **new** client *after* close and kicking
off a poll loop `stop()` already returned without awaiting. Fix: `if (closed)
return;` after every await in `start()`; have `stop()` await a generation token.

#### STREAM-3 (med / high) — minted-but-never-attached companion never reaped
`server/streaming/routes.js:802-833` (mint), teardown reachable only from the
SSE handler (`:1064`) and `invalidateForInteractionResolved` (`:1355`). The
session store's `purgeExpired` is lazy and has no hook into the route-local
`companions` Map. A minted token whose tab is abandoned before attach, or whose
interaction resolves via any path other than `respondToInteraction`, leaks the
companion (plus its telemetry subscription/ring) forever. The comment at
`routes.js:1022-1024` claims TTL-driven teardown that no code backs. The sibling
`run-target-registry.js` has a proper TTL sweep. Fix: add a sweep, or an
on-expire callback from the session store.

#### STREAM-4 (med / high) — HTTP proxy never aborts upstream on client disconnect
`server/streaming/routes.js:678-728`. After `res.hijack()` (line 693) the only
cleanup is `upstream.once('error', ...)`. No `raw.on('close', () =>
upstream.destroy())`, so an early client disconnect leaves the upstream
`ClientRequest`/TCP connection open until n.eko finishes or times out —
aggravated because n.eko endpoints are long-lived/streaming. Fix: add
`raw.on('close', () => { if (!upstream.destroyed) upstream.destroy(); })`.

#### STREAM-5 (med / high) — in-flight `getBrowserClient()` resurrects a closed client
`server/streaming/neko-adapter.js:613-650` vs `:691-704`. `closeBrowserClient()`
only inspects the synchronous `browserClient` field (still null mid-connect),
so its `if (!browserClient) return;` fires while the in-flight IIFE is still
awaiting `client.connect`. The IIFE then assigns `browserClient = client` /
`browserClientConnected = true`, leaving a live, orphaned client the fast path
will hand out again. Fix: `closeBrowserClient()` should await/attach to
`browserClientPromise` (or use a generation counter) and close whatever it
produces.

#### STREAM-6 (low / med) — WS upgrade proxy misses abrupt client close
`server/streaming/routes.js:186-207`. `socket.pipe(upstream)` auto-ends on a
graceful `'end'`, but an abrupt drop (RST) fires only `'close'`, which has no
listener — only `'error'` is wired. Fix: add
`socket.once('close', () => upstream.destroy())`.

#### STREAM-7 (low / med, dev-only) — playground `cleanupBrowser` clobbered across backends
`server/streaming/playground.js:476,719,849,669-689`. `inFlights`/`cachedSessions`
are keyed per backend so two different-backend sessions coexist, but each assigns
the single module-level `cleanupBrowser`; the exit hook tears down only the
survivor, leaking the first backend's browser at process exit. Gated by
`NODE_ENV !== "production"`. Fix: track cleanups in a `Map<backend, fn>`.

### Postgres / storage / records

#### PG-CURSOR-1 (high / high) — cursor pagination drops rows on NULL cursor_value
`server/postgres-records.js:1265-1280`. The SQLite reference
(`records.js:1265-1336`) implements a dedicated 4-branch `cursorMissing` seek for
rows whose `cursor_field` value is NULL; the Postgres port implements only the
non-missing formula. With ≥2 NULL-cursor rows: ASC (`NULLS LAST`) skips the rest
of the NULL bucket once a page ends inside it (and can flip `has_more` false);
DESC (`NULLS FIRST`) landing in the NULL bucket yields zero rows and terminates
early. Fix: port the `cursorMissing` branch (`cursor_value IS NULL AND
primary_key_text {op} $pk` for ASC; the OR-form for DESC).

#### PG-SPINE-STATUS-1 (high / high) — status-filtered spine pagination misses matches
`lib/postgres-spine.ts:788-800` (with 715-786, `hasMore` at 831). Wired via
`getLatestConnectorRunSummary(id, 'succeeded')` at `server/index.js:1992`. The
Postgres path fetches `limit+1` rows with no status predicate, slices to `limit`,
*then* filters by status → a connector whose most-recent run failed but has an
earlier succeeded run returns `null`. SQLite (`spine.ts:1436-1483`) over-fetches
`limit*4` and filters incrementally to `limit+1` post-filter results; the port
has no compensating over-fetch. Fix: over-fetch when `filters.status` is set and
derive `hasMore`/`nextCursor` from the filtered set.

#### PG-SEMANTIC-LIMIT-1 (high / high) — JSONB semantic fallback returns non-nearest top-K
`server/postgres-search.js:704-712`. In the pgvector-unavailable JSONB fallback
(`semanticEmbeddingColumnMode==='jsonb'`), the SQL applies `LIMIT $3` with no
`ORDER BY`; Postgres returns an arbitrary subset and only then does JS compute
cosine distance and sort. True nearest neighbors outside the sample are silently
dropped. Fix: remove the premature `LIMIT` (let JS sort/slice be the sole ranker
under a far-above-realistic safety cap), or push distance into SQL.

#### SPINE-SYNC-1 (high / high) — `listSpineEventsPage` returns a Promise typed as sync
`lib/spine.ts:643`: `return postgresListSpineEventsPage(...) as unknown as
SpineEventPage`. Under Postgres, a caller that trusts the sync return type and
skips `await` (e.g. `.events.filter(...)`) gets a Promise → `.events` is
undefined → `TypeError`, or a silent empty page. The `as unknown as` cast
suppresses the type error that would otherwise catch this. Fix: make the
signature uniformly `Promise<SpineEventPage>`, await internally, update call
sites, drop the cast.

#### PG-BACKFILL-1 (med-high / high) — orphan connector_instance_id on ambiguous connector_id
`server/postgres-storage.js:1909-1921` (`defaultConnectorInstanceIdForBackfill`,
used 1949-2147). The schema's unique key is `(owner_subject_id, connector_id,
source_kind, source_binding_key)`, so a `connector_id` may map to 0 or ≥2
instances. The helper assumes exactly one and synthesizes a possibly-nonexistent
id into backfilled legacy columns → broken downstream joins, no error. Fix:
throw when `rows.length !== 1` (as the sibling local-device migration does) or
disambiguate + verify existence.

#### PG-LEASE-IDX-1 (med / high) — SQLite pending-lease index omits surface_subject_id
`server/db.js:698-700` and `:1438-1440`. Postgres
(`postgres-storage.js:1122-1128`) keys the one-pending-lease unique index on
`COALESCE(surface_subject_id,'')`; the two SQLite index defs omit it, so a second
subject requesting a pending lease for the same `(connector_id, profile_key,
account_key)` collides. Per-subject concurrent lease admission is broken on
SQLite only. Fix: add `COALESCE(surface_subject_id,'')` to both SQLite index
defs.

#### PG-LIKE-1 (low / med) — unescaped LIKE metacharacters in scope_key prefix
`server/postgres-search.js:274-294,356-364`. A stream name containing `%`/`_` is
interpolated raw into a `LIKE` pattern → over-broad delete or cross-stream key
leak. Requires an adversarial/atypical stream name. Fix: `ESCAPE '\'` with
escaping, or `left(scope_key, length($p)) = $p`.

#### DB-MIGRATION-1 (low / med — DOWNGRADED) — `NULL AS surface_subject_id` in a rebuild
`server/db.js:1523`. A sub-agent rated this high (data loss). **Downgraded on
re-verification:** the same function calls `addColumnIfMissing(...,
'surface_subject_id', ...)` immediately before the rebuild (line 1456), so on the
normal forward-migration path the old column is all-NULL when the `SELECT NULL AS
surface_subject_id` runs — NULL→NULL, no loss. Loss only in a contrived
intermediate state (column populated but the CHECK not yet widened). Still worth
fixing for robustness/consistency (every other column is carried by name), but
zero effect on any deployment that has already run this one-shot migration. Fix:
`NULL AS surface_subject_id` → `surface_subject_id`.

#### Other storage notes (low)
- `postgres-storage.js:2796-2798`, `:2831-2833` — two migration ROLLBACKs
  unguarded (a throwing ROLLBACK would mask the original error); never fires in
  practice.
- `db.js:1458-1538` — the `browser_surface_leases` rebuild isn't wrapped in
  `raw.transaction()` like its siblings; current statement order is retry-safe,
  so latent hardening only.
- `postgres-records.js:1914-1915` — lexicographic ISO-timestamp comparison in
  dataset time bounds; byte-identical to the SQLite reference
  (`records.js:4614-4615`), so a mirrored pre-existing issue, not PG-specific.

### Search / explore

#### SEARCH-1 (med / med) — **FIXED** — `compareHits` NaN broke the total order
`server/search-semantic.js:988`. `if (a.distance !== b.distance) return
a.distance - b.distance;` returns NaN when a distance is NaN (a degenerate
embedding vector from the local Transformers.js backend has no value-level
guard), breaking the strict total order the comparator is documented to provide
(page slicing / has_more / cursor round-trips). **Applied** (commit
`d29c8d0e8`): coerce non-finite distances to `+Infinity` so they sort
deterministically to the end. Verified with a standalone model: antisymmetry
holds, no NaN comparisons, and finite-distance ordering is byte-identical to
before.

#### SEARCH-DATE-1 (low / low) — fragile `created_at + 'Z'` parsing
`server/search.js:1702`, `search-semantic.js:2477`. SQLite `datetime('now')`
yields `"YYYY-MM-DD HH:MM:SS"` (space-separated, no offset); the code relies on
V8's lenient non-standard parsing of `"...SSZ"`. Verified *not currently broken*
on Node/V8 — flagged as latent fragility only. Fix: format as ISO-8601 at write
time or parse explicitly.

**Explore/search cleared (no bug):** k-way merge and cursor carry-forward in
`rs-explore-timeline`; `denseBuckets`/UTC week-floor in
`rs-explore-record-buckets`; `roundRobinMerge`; lexical/semantic cursor slice
math; hybrid dedup/merge; limit clamping. The `computeTotal + afterPositions`
co-occurrence in `explore-timeline-substrate.ts` fetchUpcoming was investigated
and **disproven as a live bug** — the operation only ever pairs
`computeTotal:true` with `afterPositions:null` (first page) and
`computeTotal:false` with a cursor (`rs-explore-timeline/index.ts:1137,1254`).

### Routes / metadata

#### ROUTE-AUDIT-1 (med / med) — success-audit awaited between mint and response
`server/routes/owner-connection-intent.ts:340-375` (same pattern in
`owner-connection-run.ts:437-459`). A valid `enroll_local_collector` intent
persists a live enrollment code, then `await emitConnectionIntentAudit(...)`. If
the spine emit throws, control falls to the outer catch → emits a *failed* audit
and returns 500, but the enrollment code is already live for its TTL and the
client never received it. Fix: emit the audit best-effort (or after building the
response) so an audit failure can't convert a successful mutation into a 500.

#### ROUTE-URI-1 (med / med) — `decodeURIComponent` throws before typed-error path
`server/routes/rs-read.ts:1915` (record detail), `:2095` (field-window), `:2728`
(blob). `GET .../records/%` (bare `%`) throws in `decodeURIComponent` before
`queryContext` is assigned; the catch sees `queryContext === null` and calls
`ctx.handleError` with an untyped `URIError`, bypassing `rejectQuery` — no
`query.received`/`query.rejected` spine event, likely a generic 500 instead of a
typed 400. Companion case at `owner-connection-run.ts:281,303,306`
(`readRunTarget` decodes unguarded on the non-owner reject path). Fix: wrap the
decode in a typed `invalid_argument` error or init `queryContext` before
decoding.

#### METADATA-1 (low / high) — link-local IPv6 under-detected
`server/metadata.ts:85`. `normalized.startsWith("fe80:")` matches only one `/16`
of the `fe80::/10` link-local range (RFC 4291). `https://[fe90::1]/` is
mis-reported as public. Under-inclusive (fails toward "not private/trusted"),
not an escalation direction. Fix: `/^fe[89ab]/.test(normalized)`.

#### Route notes (low / not bugs)
- `rs-read.ts:2251-2253` — inline `buildOwnerReadGrantForManifest` doesn't filter
  null-`name` streams like its module-level twin (`:1110`); `{name: undefined}`
  grant entry for a malformed manifest. Impact depends on downstream search-grant
  handling.
- `rs-read.ts:1336` — client streams-list overwrites `req._pdpp_resolver_warnings`
  instead of appending; harmless today (sole writer).
- `rs-read.ts:499-502` — `coerceWindowSelectorParams` regex `/^-?\d+$/` accepts
  negative `offset_chars`/`limit_chars`; bug only if the substrate doesn't clamp.
- `rs-mutation.ts` DELETE routes never pass `allowStatuses`, so deleting a
  still-`draft` connector instance by id fails resolution — plausibly intentional.

---

## Fixes applied

| ID | Commit | Rationale for applying |
|----|--------|------------------------|
| SEARCH-1 | `d29c8d0e8` | Pure hardening in non-RED search code; behavior-preserving (byte-identical) for all finite distances; only changes ordering for NaN, which was already undefined. Verified with a standalone total-order/antisymmetry check and `node --check`. |

Everything else is left **diagnosis-only** because it either changes observable
behavior on a heavily-tested/RED-adjacent surface (VERDICT-1, HEALTH-1, CTRL-1,
STREAM-*), requires porting non-trivial SQL logic with a full DB test run to
prove (PG-*), or was downgraded on re-verification (DB-MIGRATION-1).

## Highest-value follow-ups

1. **CTRL-1** — smallest fix (an identity check), highest correctness payoff
   (restores the single-active-run invariant). Behavior-preserving on the normal
   path; ship behind the run-lifecycle test suite.
2. **HEALTH-1** and **VERDICT-1** — owner-facing honesty bugs (green pill on a
   broken credential; owner-blocked framed as self-healing). Both need care
   because they change projection output that many tests pin.
3. **PG-CURSOR-1 / PG-SPINE-STATUS-1 / PG-SEMANTIC-LIMIT-1** — silent
   wrong-results on live Postgres read paths; each is a port that dropped a case
   its SQLite counterpart handles. Fix + a dialect-parity test per pair.
