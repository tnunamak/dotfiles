---
title: "Lease reclamation (Chubby/etcd/ZooKeeper leases, Redlock's contested fencing gap) and checkpoint commit-ordering (Kafka offset timing, Flink barriers, WAL) are the two primitives that decide whether interrupted work resumes cheaply or must restart from zero; applied to PDPP, the fix is a distinct interrupted terminal state plus a per-connector drain budget, not a longer flat timeout"
date: 2026-08-21
topic: distributed-systems
tags: [leases, fencing-tokens, chubby, etcd, zookeeper, redlock, checkpointing, kafka, flink, wal, resumability, graceful-shutdown, pdpp, prior-art]
status: draft
sources: [chubby-paper, etcd-api, k8s-lease, zookeeper-recipes, redlock-antirez, redis-locks-docs, kleppmann-locking, kafka-delivery-semantics, flink-stateful, chandy-lamport-arxiv, postgres-wal, sqlite-wal, sqlite-atomic-commit, two-phase-commit-wikipedia, stripe-pagination, github-pagination, rfc9110-range, tus-protocol, rsync-man]
source_session: af82d1f3-1838-4307-a3a9-6bbf07e77c6f
---

<!--
Companion / do-not-duplicate map (read before extending this entry — three sibling entries
written the same day in this same session already cover the shutdown/terminal-state ground):
- distributed-systems/when-the-shutdown-grace-window-is-shorter-than-a-unit-of-work-mature-systems-checkpoint-and-requeue-rather-than-finish-or-fail.md
  — THE definitive entry on grace-window defaults (Docker/k8s/systemd), what Sidekiq/Celery/River/
  Temporal DO in the shutdown window, and the Temporal/Kubernetes terminal-state taxonomy
  (CANCELED/TERMINATED/TIMED_OUT vs FAILED, k8s DisruptionTarget condition, "Unknown never False").
  Do NOT re-derive any of this — it is the primary answer to "what should SIGTERM do."
- distributed-systems/a-dying-worker-never-writes-its-own-terminal-state-the-service-writes-it-via-timeout-and-the-fencing-epoch-invalidates-the-zombie.md
  — the deep Temporal + Kafka KIP-98/KIP-447 zombie-fencing dive (producer epochs, transaction.timeout.ms).
- distributed-systems/bounding-a-hung-job-uses-heartbeat-plus-wall-clock-timeout-a-startup-reaper-and-fencing-tokens.md
  (2026-06-14) — heartbeat-vs-wall-clock timeout SELECTION and startup reapers across Temporal/Sidekiq/
  k8s Jobs/Step Functions/Celery/GoodJob/Kleppmann's fencing-token argument (cited again below because
  the specific primary-source lock-service mechanics — Chubby/etcd/ZooKeeper/Redlock — were not covered
  there and are the actual "how does the fence work under the hood" layer that entry references but does
  not source).
- distributed-systems/durable-local-work-uses-sqlite-outbox-leases-and-destination-confirmed-checkpoints.md
  (2026-05-19) — local SQLite-outbox lease/checkpoint schema recommendation. Cited, not re-derived.

THIS entry's unique contribution: (1) primary-source lock-SERVICE mechanics (Chubby session
leases/jeopardy, etcd lease TTL/keepalive, ZooKeeper ephemeral nodes/herd effect, the precise
shape of the Redlock controversy) that the fencing-token entries above assume but don't source;
(2) checkpoint COMMIT-ORDERING semantics (Kafka at-most/at-least/exactly-once by commit timing,
Flink's Chandy-Lamport-derived barriers, the WAL redo/undo pattern) which none of the three
siblings touch; (3) resumability patterns (cursor pagination, HTTP Range, tus, rsync); (4) the
only entry among the four with a concrete PDPP applied recommendation.
-->

## CLAIMS

### Lease/lock reclamation mechanics

- Google Chubby's session model: a lease is the master's promise not to unilaterally end a session before a deadline it can only push forward, never backward; **default lease extension is 12 seconds**. `KeepAlive` RPCs are held open (unanswered) by the master until near-expiry, so a client effectively always has one in flight; replies piggyback event notifications and cache invalidations, keeping all traffic client-initiated (works through firewalls) and forcing invalidation acknowledgement before extension. If a client's local lease timer expires without a completed KeepAlive round-trip, it cannot assume the session is dead: it disables its cache and enters **jeopardy** (fires a `jeopardy` event), then waits a **grace period, default 45 seconds** — a KeepAlive success inside that window re-enables the cache (`safe` event); otherwise the session is declared `expired`. Locks are session-scoped, so lock loss is detected identically to session loss. Chubby's **sequencer** (an opaque token naming lock, mode, and generation number, checked via `CheckSequencer()`) is the direct ancestor of Kleppmann's fencing-token argument. [chubby-paper]
- etcd leases: a client requests a TTL; any key attaches to at most one lease via `Put`; a bidirectional streaming RPC (`LeaseKeepAlive`) renews it. **On expiry or explicit `LeaseRevoke`, every key attached to that lease is deleted**, and each deletion fires a normal watch event to observers — this delete-on-expiry primitive is what service-discovery and locking patterns are built directly on top of (key presence = liveness, deletion = loss). [etcd-api]
- Kubernetes' `coordination.k8s.io/v1 Lease` object is etcd-backed and purpose-built to cut write load: kubelet node heartbeats update only `spec.renewTime` on a per-node Lease object rather than the full Node API object, and `kube-controller-manager`/`kube-scheduler` HA replicas use the identical Lease mechanism (via client-go's `leaderelection` package) for leader election — one primitive reused for both node liveness and control-plane leader election. [k8s-lease]
- ZooKeeper ephemeral znodes are auto-deleted when the ensemble judges the owning session expired (client silent past a negotiated timeout in `[2×tickTime, 20×tickTime]`), firing a watch notification to every current watcher of that znode. This is the mechanism behind the documented **herd effect**: if N clients all watch the same lock/leader znode, one deletion wakes all N simultaneously though only one can win. The documented fix is the **ephemeral sequential node** recipe: each candidate creates an ephemeral sequential child under a shared parent; the lowest sequence number holds the lock/leadership; every other client watches only the znode immediately preceding its own sequence number (never the leader node, never all nodes) — so a single deletion wakes exactly one waiter. [zookeeper-recipes]
- The Redlock controversy is a genuine, still-open disagreement between named experts — not a smoothed-over "reasonable people differ." Per-axis: **clocks** — Kleppmann says Redlock needs synchronized clocks to be safe; antirez (Redis's creator) concedes clock jumps are a real risk (recommends monotonic clocks) but disputes that tight synchronization is required, claiming roughly 10% drift tolerance suffices. **GC/process pauses (the crux)** — Kleppmann's argument is general: any lease lock without a fencing token is unsafe under an arbitrary pause, because a resumed process cannot know its lease already expired; antirez's rebuttal is narrower, specific to Redlock's own algorithm (it timestamps before acquiring a majority and recomputes elapsed time after, so a pause occurring before the final validity check causes the client to self-reject) — he frames this as answering Kleppmann's specific worked example, not refuting the general claim. **Fencing tokens** — not disputed as a concept, disputed on applicability: fencing requires the *protected resource* to reject stale tokens, which most Redlock use cases (moving physical objects, calling non-transactional external APIs) don't have; antirez's position is that a resource capable of enforcing fencing "probably doesn't need a distributed lock at all," framing Redlock as an efficiency lock rather than a correctness lock. Current Redis docs have been revised to carry an explicit consistency disclaimer (implement fencing tokens; don't assume a lock is held just because the process is alive; Redis TTL expiry does not use a monotonic clock) while linking both Kleppmann's and antirez's posts for readers to weigh. [redlock-antirez] [redis-locks-docs] [kleppmann-locking]

### Checkpoint / cursor commit-ordering semantics

- Kafka's three delivery semantics reduce to **when the offset commit happens relative to processing**, not to anything more exotic: at-most-once commits (or auto-commits on a timer) *before* processing completes, so a crash between commit and completion silently and permanently skips that message; at-least-once commits *after* processing succeeds, so a crash before commit causes reprocessing on restart (a possible duplicate, never a loss — Kafka's typical default); exactly-once (scoped to Kafka-to-Kafka) folds the offset commit into the same transaction as the produced output via `sendOffsetsToTransaction`, requiring the idempotent producer (dedup via per-partition sequence numbers) plus `transactional.id`-scoped transactions and downstream `isolation.level=read_committed`. [kafka-delivery-semantics]
- Kafka's own documented recommendation for external (non-Kafka) sinks is to **collapse the two commit points into one atomic write** rather than attempt distributed/two-phase commit across them: "letting the consumer store its offset in the same place as its output... is better because many of the output systems a consumer might want to write to will not support a two-phase commit." [kafka-delivery-semantics]
- Flink achieves exactly-once state consistency across a distributed pipeline **without stopping the world**, using checkpoint **barriers**: special records tagged with a checkpoint ID, injected at sources, flowing strictly in-line with data (in aligned mode, "barriers never overtake records"). A multi-input operator **aligns**: on receiving barrier N on one input channel, it buffers further records from that channel until barrier N arrives on every input channel, then snapshots its own state and forwards the barrier — each operator briefly blocks only its own inputs, never the whole job. **Unaligned checkpoints** let barriers overtake buffered records instead, capturing in-flight buffered data as part of the checkpoint so checkpoint duration decouples from throughput/backpressure. Flink's docs state directly this mechanism "is inspired by the standard Chandy-Lamport algorithm for distributed snapshots" (Chandy & Lamport, 1985) — the barrier is the streaming analog of the algorithm's original marker message, and barrier alignment is the analog of channel-state recording. [flink-stateful] [chandy-lamport-arxiv]
- The write-ahead-log pattern guarantees a crash mid-transaction never leaves a half-applied state, via two structurally opposite but equally valid mechanisms: Postgres and SQLite WAL mode are REDO-style (log the change and flush it durably, apply to data pages lazily — Postgres states the invariant directly: changes "must be written only after those changes have been logged, that is, after WAL records describing the changes have been flushed to permanent storage"), while SQLite's traditional rollback-journal mode is UNDO-style (copy the *original* page content into a journal before overwriting in place; commit = deleting the journal; a crash leaves a detectable "hot journal" that the next opener replays to restore the original pages). Recovery in either direction either fully replays a committed transaction or fully discards an uncommitted one — never a partial mix of both. [postgres-wal] [sqlite-wal] [sqlite-atomic-commit]
- Classical two-phase commit names the "genuinely cannot know" state explicitly: a participant that has voted Yes ("prepared") and is now waiting on the coordinator's final decision is **in doubt** — if the coordinator fails permanently, "some participants will never resolve their transactions... it will block until a commit or rollback is received." 2PC is fundamentally blocking for exactly this reason, and "cannot dependably recover from a failure of both the coordinator and a cohort member during the commit phase" — the strongest classical precedent for a case that is honestly unresolvable from inside the system without querying an external party. [two-phase-commit-wikipedia]

### Resumability

- Cursor-based pagination is the standard mechanism for resuming a killed paginated pull without restarting from page 1, because the cursor is an opaque bookmark (an object ID or opaque token) rather than a page offset that shifts under concurrent insertions/deletions. Stripe's list API cursor (`starting_after`/`ending_before`) is literally an existing object's ID: "a cursor to use in pagination... defines your place in the list." GitHub's REST API exposes the next page as a fully-formed URL in the `Link` response header (`rel="next"`); persisting that URL (or Stripe's cursor value) is the documented resumability mechanism in both cases. Neither doc set uses one canonical name for "persist the cursor to survive a restart" beyond "cursor-based pagination." [stripe-pagination] [github-pagination]
- HTTP Range requests (RFC 9110 §14, superseding RFC 7233) exist explicitly for this purpose: "Clients often encounter interrupted data transfers as a result of canceled requests or dropped connections. When a client has stored a partial representation, it is desirable to request the remainder of that representation in a subsequent request rather than transfer the entire representation." The client sends `Range: bytes=X-`; the server responds `206 Partial Content` with `Content-Range` describing the enclosed span. tus.io's resumable-upload protocol makes the identical pattern explicit for uploads: a `HEAD` request against the upload URL must always return the exact `Upload-Offset` already received (even if 0), and the client resumes via `PATCH` starting at that offset, sending only the remaining bytes. [rfc9110-range] [tus-protocol]
- rsync's delta-transfer algorithm compares block checksums rather than re-sending whole files, and its `--partial` flag keeps a partially-transferred file on the destination specifically so the *next* run's delta comparison has a real basis to resume from instead of starting against an empty/discarded destination; `--append` (which implies `--partial`) resumes append-only growing files directly. [rsync-man]

## SOURCES

**chubby-paper**
URL: https://static.googleusercontent.com/media/research.google.com/en//archive/chubby-osdi06.pdf
Accessed: 2026-08-21
Quote: session lease default extension "12 seconds"; jeopardy grace period "45 seconds by default."

**etcd-api**
URL: https://etcd.io/docs/latest/learning/api/
Accessed: 2026-08-21

**k8s-lease**
URL: https://kubernetes.io/docs/concepts/architecture/leases/
Accessed: 2026-08-21

**zookeeper-recipes**
URL: https://zookeeper.apache.org/doc/current/recipes.html
Accessed: 2026-08-21

**redlock-antirez**
URL: http://antirez.com/news/101
Accessed: 2026-08-21

**redis-locks-docs**
URL: https://redis.io/docs/latest/develop/clients/patterns/distributed-locks/
Accessed: 2026-08-21

**kleppmann-locking**
URL: https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html
Accessed: 2026-08-21
Quote: "If you need locks for correctness, please don't use Redlock."

**kafka-delivery-semantics**
URL: https://kafka.apache.org/documentation/#semantics
Accessed: 2026-08-21
Quote: "letting the consumer store its offset in the same place as its output. This is better because many of the output systems a consumer might want to write to will not support a two-phase commit."

**flink-stateful**
URL: https://nightlies.apache.org/flink/flink-docs-stable/docs/concepts/stateful-stream-processing/
Accessed: 2026-08-21
Quote: "Flink's checkpointing mechanism is inspired by the standard Chandy-Lamport algorithm for distributed snapshots."

**chandy-lamport-arxiv**
URL: https://arxiv.org/abs/1506.08603
Accessed: 2026-08-21
(Carbone et al., "Lightweight Asynchronous Snapshots for Distributed Dataflows," citing Chandy & Lamport, "Distributed Snapshots: Determining Global States of Distributed Systems," ACM TOCS 1985.)

**postgres-wal**
URL: https://www.postgresql.org/docs/current/wal-intro.html
Accessed: 2026-08-21
Quote: "changes to data files... must be written only after those changes have been logged, that is, after WAL records describing the changes have been flushed to permanent storage."

**sqlite-wal**
URL: https://www.sqlite.org/wal.html
Accessed: 2026-08-21

**sqlite-atomic-commit**
URL: https://www.sqlite.org/atomiccommit.html
Accessed: 2026-08-21

**two-phase-commit-wikipedia**
URL: https://en.wikipedia.org/wiki/Two-phase_commit_protocol
Accessed: 2026-08-21
Quote: "If the coordinator fails permanently, some participants will never resolve their transactions: After a participant has sent an agreement message... it will block until a commit or rollback is received."

**stripe-pagination**
URL: https://docs.stripe.com/api/pagination
Accessed: 2026-08-21

**github-pagination**
URL: https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api
Accessed: 2026-08-21

**rfc9110-range**
URL: https://www.rfc-editor.org/rfc/rfc9110.html
Accessed: 2026-08-21
Quote: (§14) "Clients often encounter interrupted data transfers as a result of canceled requests or dropped connections. When a client has stored a partial representation, it is desirable to request the remainder of that representation in a subsequent request rather than transfer the entire representation."

**tus-protocol**
URL: https://tus.io/protocols/resumable-upload
Accessed: 2026-08-21

**rsync-man**
URL: https://download.samba.org/pub/rsync/rsync.1
Accessed: 2026-08-21

## SYNTHESIS

**Two primitives, one question each.** Lease mechanics (Chubby/etcd/ZooKeeper/Redlock) answer "how does a *second* party safely conclude the first party is gone and reclaim what it held" — and the answer is always some combination of a renewable TTL, a grace/jeopardy period before treating silence as death, and a fencing token that survives a resurrected zombie. Checkpoint commit-ordering (Kafka/Flink/WAL) answers a different question: "given that work *will* be interrupted, where exactly is the line between 'definitely done' and 'must redo,' and how far back does redo have to go." These compose: a lease tells you *when* to reclaim; a checkpoint tells you *how much* work the reclaiming party actually has to redo. A system with good lease reclamation but no checkpointing still restarts every reclaimed unit of work from zero — which is correct but wasteful; the checkpoint is what turns "restart" into "resume."

**The Redlock disagreement is worth preserving in its precise shape, not flattening.** The two most commonly repeated one-liners about Redlock — "it's unsafe" and "the criticism doesn't apply to most real uses" — are both defensible readings of the same underlying disagreement, because Kleppmann and antirez are answering different questions: Kleppmann asks "is this safe as a *correctness* primitive under adversarial pauses," antirez asks "is this good enough as an *efficiency* primitive to avoid duplicate work in the common case." Neither is wrong; the error is using it as the former when only the latter was validated. This matters directly for anything modeling a lease/reservation (see the PDPP device-ingest note below): decide up front which of the two questions your lease actually needs to answer, because the correctness bar requires a fencing-capable backing store and the efficiency bar does not.

**Kafka's "collapse the commit points" advice generalizes past Kafka.** The lesson — write the checkpoint and the output atomically in one store, rather than trying to coordinate two separate commits — is the same insight underlying the transactional outbox pattern (see the companion 2026-05-19 SQLite-outbox entry) and is directly transferable to any pull-based collector: if a connector's cursor advance and its record insert land in one transaction, there is no window in which a crash can produce "recorded the data but forgot where I was" or the reverse.

**Resumability is a cursor-shape discipline, not a checkpointing-frequency discipline.** The pagination/Range/tus/rsync survey converges on one mechanical rule: resumability requires the checkpoint to be a durable, externally-meaningful position (an object ID, a byte offset, a content hash) rather than an internal counter tied to the specific run that produced it. A cursor meaning "the 400th record returned by *this* API call sequence" cannot survive a restart if the sequence itself isn't guaranteed stable across calls; a cursor meaning "everything with an ID greater than X" survives trivially, because the guarantee lives in the data model, not in the run.

## Application to PDPP

**The concrete defect.** PDPP's controller (`reference-implementation/runtime/controller.ts`) already has a graceful-shutdown primitive — `drainActiveRuns(timeoutMs)` awaits in-flight run promises with a hard deadline before `process.exit`, wired to the SIGTERM handler in `server/index.ts` — but two choices undermine it. First, the drain window is a flat `CONNECTOR_DRAIN_TIMEOUT_MS = 5000` applied uniformly to every connector, when real connector work (Gmail IMAP pagination, Slack API pagination, bank OTP flows, browser-surface CDP sessions) routinely runs tens of seconds to minutes — for most in-flight runs this is not a grace period in the sense the companion `when-the-shutdown-grace-window...` entry describes, it's a 5-second head start on the exact outcome SIGKILL would produce. Second, both the drain-timeout path and the boot-time `reconcileAbandonedControllerRuns` reconciler resolve an interrupted run to `event_type: "run.failed"` / `status: "failed"` with `reason: "controller_restarted"` — collapsing "we don't know" into "we affirmatively know it failed," which is the exact mistake the companion entry's Kubernetes citation warns against ("Failed=False may cause double-negative confusion" — here it's worse, an outright false-positive claim of failure).

**Recommended design, each point keyed to a precedent above or in a sibling entry:**

1. **Adopt the companion `when-the-shutdown-grace-window...` entry's core recommendation directly: SIGTERM should stop admitting new work immediately, then give in-flight work a *bounded* finish attempt, then write a checkpoint plus a non-failure terminal state on expiry — never attempt an unbounded "try to finish."** PDPP's `drainActiveRuns` already implements the shape of "bounded finish attempt." What's missing is sizing it per-connector rather than as one global constant — the same lesson as the Brex incident that entry cites (a platform-level timeout is meaningless if nothing on the work side uses the budget it grants). PDPP already tracks a per-connector `maxRunWallClockMs` for its watchdog; the drain deadline on SIGTERM should derive from that same budget (or the remaining portion of it), not a separate flat constant.

2. **Add a distinct `run.interrupted` (or equivalent) terminal reason, and stop mapping `controller_restarted` to `run.failed`.** This is the single highest-leverage change, and it is now directly precedented three ways in this corpus, not just one: Temporal's `CANCELED`/`TERMINATED`/`TIMED_OUT` are structurally distinct proto values from `FAILED` (companion entry); Kubernetes' API conventions state outright that indeterminate work "would generally have a `Succeeded` condition with status `Unknown`" and warn that a negative-polarity name like "Failed" makes the false-positive risk worse (companion entry); and this entry's own two-phase-commit citation shows the in-doubt state is a first-class, textbook-recognized outcome distinct from both commit and abort. `controller_restarted` should become the *reason code* attached to a new non-failure terminal status, exactly as the companion entry's Kubernetes `DisruptionTarget` example uses `action: Ignore` so a shutdown-caused termination doesn't increment a failure-driven retry counter.

3. **Give source/coverage health a third disposition for interrupted runs, distinct from both healthy and failed.** This is the actual fix for "the affected sources go to an unknown/degraded health state until something runs again" — that downstream symptom is *correct* behavior given today's taxonomy (an interrupted run genuinely shouldn't count as proof of coverage), but it's reached via the wrong path: misclassifying it as a hard failure likely trips the same alerting/attention surfaces a real failure would, exactly the "alerting pages on deploys" failure mode the companion entry warns about.

4. **Keep the boot-time reconciler, but change what it assumes and what it writes.** The SIGKILL/OOM/power-loss case is real, and a startup reconciler is the correct backstop for it — structurally identical to River's rescuer and Sidekiq's orphan sweep, both of which the companion entry frames explicitly as "the cost of an unclean exit," a rare path, not the common one. Once the SIGTERM-time drain is properly sized (point 1), the reconciler should mostly stop firing on ordinary deploys, and when it does fire it should write the same `interrupted` status from point 2 with `controller_restarted` as the reason — because a run found abandoned at boot is in the identical epistemic position as a run whose own drain window expired: no positive evidence either way.

5. **Treat resumability as the next lever once the taxonomy is fixed, not before.** If connector runs checkpoint their cursor position *during* the run (per-page, per-batch — mirroring Stripe/GitHub's opaque-cursor pagination pattern from this entry, and the companion 2026-05-19 SQLite-outbox entry's destination-confirmed per-stream checkpoints) rather than only at the end, an `interrupted` run stops being pure waste: the next scheduled attempt resumes from the last confirmed cursor instead of re-fetching from zero — the same principle as tus/HTTP-Range/rsync resuming from a durable offset instead of restarting a transfer. This is a real follow-on, not the immediate fix: fixing the terminal-state taxonomy is what makes "interrupted" an honest, distinct, and therefore *safely resumable* state in the first place; resumability without the taxonomy fix just makes a mislabeled-as-failed run also silently retryable, which hides the mislabeling rather than fixing it.

**Related surfaces flagged, not solved here (matches the task's own stated scope).** The device-ingest reservation that can sit in `processing` (`server/device-ingest-attempt-context.ts`, `server/routes/ref-device-exporters.ts`) is the same lease-without-expiry gap this entry's lease section describes — it needs either a TTL-based lease with a renewal protocol (Chubby/etcd-style) or a startup reaper (Sidekiq/River-style), and per a quick read of those files currently appears to have neither. Before reaching for a distributed lock library here, apply the Redlock-controversy framing above: decide whether the reservation needs correctness-grade fencing (requires a backing store that can reject stale tokens) or is only an efficiency guard against duplicate work (a simple TTL is enough) — PDPP is a single-process controller against its own SQLite/Postgres store, which is much closer to GoodJob's session-scoped-advisory-lock shape (crash-safe by construction, no explicit heartbeat needed) than to a genuine multi-node Redlock scenario. The local collector's own SQLite outbox (`packages/polyfill-connectors/src/local-device-outbox.ts`) already has the right substrate per the companion 2026-05-19 entry; audit its gaps, if any, against that entry's checklist (explicit lease/attempt/`next_attempt_at` fields, destination-confirmed advancement) rather than against this one.
