---
title: "Graceful shutdown is the wrong frame for PDPP's interrupted work: the invariant is that every unit of work carries a durable owner-epoch that a successor can adjudicate, drain is structurally impossible under Docker's 10s default stop, and PDPP's own boot-epoch reconciler is already the right design — silently disabled in production because controller_id defaults to the container hostname"
date: 2026-08-21
topic: pdpp
tags: [interrupted-work, terminal-states, graceful-shutdown, fencing-tokens, reconciler, reaper, checkpoint-commit, boot-epoch, docker-stop-timeout, decision]
status: settled
sources: [temporal-activity-failures, temporal-activity-definition, sdk-go-worker-base, kip-98, kip-447, kafka-design, flink-e2e, flink-stateful, flip-76, cl85, chubby, kleppmann, antirez, k8s-api-conv, k8s-node, k8s-lifecycle, docker-stop, docker-restart, systemd-service, river-client, river-states, river-1256, oban-changelog, oban-lifeline, que-readme, sidekiq-manager, celery-redis-caveats, faktory-workers, pdpp-prod-postgres, pdpp-prod-docker, pdpp-code]
source_session: af82d1f3-1838-4307-a3a9-6bbf07e77c6f
---

<!--
Decision document. Reads and builds on, rather than duplicating:
  - distributed-systems/a-dying-worker-never-writes-its-own-terminal-state-...md (2026-08-21,
    same session, sibling agent) — the Temporal/Kafka prior-art layer. This entry cites it
    rather than restating it, and adds the job-queue adjudication + the PDPP decision.
  - distributed-systems/bounding-a-hung-job-uses-heartbeat-plus-wall-clock-timeout-...md
    (2026-06-14) — the layered bounding model. Still correct; this entry REFUTES its
    closing recommendation for PDPP's case (see CLAIM P-14).
  - distributed-systems/durable-local-work-uses-sqlite-outbox-leases-...md (2026-05-19) —
    surface (c) was built from that entry and needs no change.
Sections D (production measurements) and the state machine / anti-scope in SYNTHESIS are
the new ground.
-->

## CLAIMS

### A. Prior art: who writes the terminal state when the owner dies

- Temporal's server has no crash-detection channel at all; it converts worker silence into a recorded outcome using only a timer: "The Temporal Server doesn't detect failures when a Worker loses communication with the Server or crashes. Therefore, the Temporal Server relies on the Start-To-Close Timeout to force Activity retries." [temporal-activity-failures]
- Silence is not a state in Temporal: "Activities won't record to the Event History until they return or produce an error. If an Activity fails to report to the server at all, it will be retried." A dying worker writes nothing; the service writes `ActivityTaskTimedOut`. [temporal-activity-definition]
- Temporal's graceful shutdown does not wait for in-flight work by default: `WorkerStopTimeout` is "the time delay before hard terminate worker" and its default is **0s**; exceeding it logs "Worker graceful stop timed out." and abandons the activity to the service-side timer. [sdk-go-worker-base]
- Kafka's zombie fence is a per-`transactional.id` epoch: `InitProducerId` "Bumps up the epoch of the PID, so that the any previous zombie instance of the producer is fenced off" and "Recovers (rolls forward or rolls back) any transaction left incomplete by the previous instance." The successor's boot performs the recovery. [kip-98]
- Kafka runs two independent reapers for an abandoned transaction, neither of which is the dying producer: `transaction.timeout.ms` (coordinator-side, 60s default) and the successor's epoch bump. [kip-98] [kafka-design]
- KIP-447 did not weaken the fence when it proved topologically awkward; it re-scoped the fencing key from `transactional.id` to consumer-group metadata (generation ID, member ID, group instance ID): "If one of the field is not matching correctly on server side, the client will be fenced immediately." [kip-447]
- Kafka explicitly declines an end-to-end exactly-once claim: EOS holds "when reading, processing and writing data on Kafka topics"; "Exactly-once delivery for other destination systems generally requires cooperation with such systems... Otherwise, Kafka guarantees at-least-once delivery by default." [kafka-design]
- Kafka's stated preference is to collapse the two commit points rather than coordinate them: "The classic way... would be to introduce a two-phase commit... This can be handled more simply and generally by letting the consumer store its offset in the same place as its output." [kafka-design]
- Chandy-Lamport's snapshot need not be a state the system was ever in; the guarantee is reachability (Theorem 1): "S* is reachable from S_i, and S_j is reachable from S*." The paper poses the objection itself: "Of what use is the algorithm if the recorded global state never occurred?" [cl85]
- Flink's after-pre-commit obligation: "After a successful pre-commit, the commit must be guaranteed to eventually succeed – both our operators and our external system need to make this guarantee." [flink-e2e]
- Flink's documented residual window is the lost acknowledgment: failure "after a successful pre-commit but before notification of that fact (a commit) reaches our operator." Its remedy is a preemptive commit on restore plus idempotence, made possible by storing recovery evidence *in the checkpoint itself* ("the path to the temporary file and target directory"). [flink-e2e]
- Flink barrier alignment stalls healthy channels under backpressure, producing "a vicious cycle of late checkpoints, crash, recovery to a rather outdated checkpoint, more back pressure, and even later checkpoints." [flip-76]
- Chubby's sequencer is a fencing token validated by the *resource*, not the lock service: it "contains the name of the lock, the mode in which it was acquired... and the lock generation number", and the recipient server may check it "against the most recent sequencer that the server has observed." [chubby]
- Chubby names lock-delay as the explicitly second-best mechanism, for resources that cannot validate: "an imperfect but easier mechanism to reduce the risk of delayed or re-ordered requests to servers that do not support sequencers." [chubby]
- Kleppmann's structural objection to Redlock is a capability gap, not a probability argument: Redlock "does not have any facility for generating fencing tokens." [kleppmann]
- antirez's strongest counter is that a fenceable resource does not always exist, and that check-and-set *on the shared resource itself* substitutes for an external token authority. [antirez]
- Kubernetes defines condition status as three-valued and treats absence as `Unknown`, not false: "Condition `status` values may be `True`, `False`, or `Unknown`. The absence of a condition should be interpreted the same as `Unknown`." Absence "typically indicates that reconciliation has not yet finished." [k8s-api-conv]
- `Unknown` drives *different* remediation from `False` in Kubernetes, proving it is not a degenerate false: node `Unknown` yields a `node.kubernetes.io/unreachable` taint; `False` yields `node.kubernetes.io/not-ready`. [k8s-node]

### B. Prior art: is a reaper a smell or a necessity

- River detects a dead worker with a pure wall-clock staleness query and no lease or heartbeat: `WHERE state = 'running' AND attempted_at < @stuck_horizon`, default `RescueStuckJobsAfter` = 1 hour. [river-states] [river-client]
- River documents the duplicate-execution cost of its own reaper in the config comment: "this can result in repeat or duplicate execution of a job that is not actually stuck but is still working." [river-client]
- River closed its heartbeat-rescue PR (#1256, "Active job rescue based on heartbeat") unmerged in favor of a pilot-based alternative chosen for "superior properties around potential bloat for table bloat in `river_job`." [river-1256]
- Oban shipped true heartbeat rescue in v1.x (`oban_beats` joined on `attempted_by`), measured its cost at "3,600 beat records per hour even when the queue is idle," deleted it in v2.0, and returned to a 60-minute wall clock, conceding "jobs may be left in the `executing` state after a crash or forced shutdown." [oban-changelog]
- Oban's Lifeline rescues "purely based on time, rather than any heterogeneous heuristic about the job's expected execution time **or whether the node is still alive**," and carries the same caveat: "This plugin may transition jobs that are genuinely `executing` and cause duplicate execution." [oban-lifeline]
- Faktory holds a live TCP connection and a 15s heartbeat, yet still recovers jobs only via the 30-minute reservation timeout; its heartbeat reaper de-registers the worker but does not recover jobs. [faktory-workers]
- Celery pushes the reaper into the broker as a visibility timeout (Redis default 1 hour) and warns that raising it "will only delay the redelivery of 'lost' tasks in the event of a power failure or forcefully terminated workers." [celery-redis-caveats]
- OSS Sidekiq has no recovery at all — `UnitOfWork#acknowledge` is a no-op and a crashed job "is lost forever" — while stating the value judgment "it is worse to lose a job than to run it twice." [sidekiq-manager]
- Que is the sole surveyed system with no reaper: a Postgres advisory lock "is held until explicitly released or the session ends," so jobs "immediately become available for any other worker to pick up." Its costs are incompatibility with transaction pooling, and that a hung-but-connected worker holds its lock indefinitely. [que-readme]

### C. The bound that actually exists (Docker)

- `docker stop` sends SIGTERM then SIGKILL after a grace period whose Linux default is 10 seconds, supplied by the daemon when the container sets none: "the Daemon determines the default, and is 10 seconds for Linux containers." [docker-stop]
- `--stop-timeout` is fixed at container creation; `STOPSIGNAL`/`--stop-signal` change the first signal. [docker-stop]
- `unless-stopped` differs from `always` only in the manually-stopped-then-daemon-restart case. [docker-restart]
- systemd offers a runtime extension mechanism Docker does not: a `Type=notify` service may send `EXTEND_TIMEOUT_USEC=` to exceed `TimeoutStopSec=`, provided the first message arrives before the original deadline. [systemd-service]

### D. PDPP production measurements (this session, live instance)

- The production container sets **no stop timeout**: `docker inspect pdpp-core-prod-drain` returns `StopTimeout=<nil> StopSignal= Restart=unless-stopped`. No `--stop-timeout`, `STOPSIGNAL`, or `stop_grace_period` appears anywhere in the repo. Production therefore runs on Docker's 10s default. [pdpp-prod-docker]
- The existing 5s connector drain does not save runs. A production shutdown logged `{"drained":0,"elapsedMs":5000,"timedOut":1,"msg":"connector run drain complete"}` — it burned the entire budget and abandoned the run anyway. A second logged `{"drained":1,"elapsedMs":2013,"timedOut":0}`. [pdpp-prod-docker]
- `PDPP_CONTROLLER_ID` is unset in production, so `resolveControllerId` falls back to `os.hostname()`, which under Docker is the container ID and is fresh on every `docker run`. Observed hostnames across three recent containers: `edc87552891f`, `c10370cafb54`, `a73673787f32`. [pdpp-prod-docker] [pdpp-code]
- Consequently the boot reconciler's ownership filter `COALESCE(data_json->>'controller_id', $2) = $2` cannot match a prior container's orphans. The spine holds dozens of distinct `controller_id` values, each with 1–3 boots. [pdpp-prod-postgres]
- **121 `run.started` events in production have no terminal event of any kind** and never will, stranded under dead container IDs dating to 2026-05. The count was re-measured at **123 roughly 40 minutes later in the same session** — the leak is live and accruing, not a historical residue. [pdpp-prod-postgres]
- Both reconcilers are live and race on the same runs. Where the boot reconciler wins (it runs before HTTP mounts), the run gets `run.abandoned` / `controller_terminated_before_run_finished`; four runs on 2026-08-21T15:10:04 took this path. [pdpp-prod-postgres]
- Where the boot reconciler's ownership filter excludes the run, the older controller path writes `run.failed` / `controller_restarted` instead, and no `run.abandoned` exists for it. Sixteen such runs since 2026-08-16, all with `also_abandoned = f`. [pdpp-prod-postgres]
- Historical totals: 134 `run.failed`/`controller_restarted` (2026-04-24 → 2026-08-21) versus 32 `run.abandoned`/`controller_terminated_before_run_finished` (2026-05-11 → 2026-08-21). The older, less honest path is the one that fires more. [pdpp-prod-postgres]
- A representative `controller_restarted` run (`run_1787320963213_2`) emitted `run.state_staged` three times and `run.batch_ingested` before being stamped `run.failed` — records were durably ingested and cursors staged, then the run was recorded as a plain failure. [pdpp-prod-postgres]
- Surface (b): exactly 5 `device_ingest_batch_outcomes` rows are `processing`, all with `durable_prefix_count = record_count` (100/100 ×4, 60/60 ×1), created 2026-08-21 00:52–01:44 UTC. All other 592,458 rows are `accepted`. [pdpp-prod-postgres]
- Those 5 rows are the *head* of the connector's queue (`batch_seq` 188161–188165, with 188160 and below `accepted`), and the collector has sent no batch of any kind since 2026-08-21T01:44:33 — 13.5 hours of silence at time of measurement. The `1b2ef7058` self-heal therefore cannot reach them: it triggers on a retry that is not coming. [pdpp-prod-postgres]
- PDPP already has a persisted monotonic fencing token: `runGenerations`, keyed per connector-instance, incremented on every admission including watchdog reclaim, and persisted to `controller_active_runs.run_generation`. [pdpp-code]
- PDPP already has `run.abandoned` as a first-class terminal event type, present in the terminal set of `check-run-terminal.sql`, `get-run-terminal-event.sql`, `run-history-writer.ts`, `connector-attention-store.ts`, and the `terminal_status` contract in `openspec/specs/reference-implementation-architecture/spec.md`. [pdpp-code]
- `boot_epoch` is stamped **only** on `run.started` spine events. No other durable table carries it — not `device_ingest_batch_outcomes`, not the manual-upload artifact store, not `local_device_outbox`. [pdpp-code]
- Six independent boot-time reconcilers run in `startServer`: orphaned runs, manual-upload artifacts, polyfill manifests, browser-surface leases, unrestored presentation screens, and dirty summary evidence. A seventh (`reconcileAbandonedControllerRuns`) runs from the controller. [pdpp-code]
- The manual-upload reconciler uses a 10-minute wall-clock staleness cutoff (`MANUAL_UPLOAD_IN_FLIGHT_STALE_MS`) rather than an epoch comparison, despite answering the identical question. [pdpp-code]
- Checkpoint commit is all-or-nothing on terminal status: `if (persistState && (done.status === "succeeded" || isCertifiedStreamCollectionFailure))`. Cursors are staged into `newState` during the run and committed only in that branch, so any interruption discards every staged cursor while the ingested records remain durable. [pdpp-code]
- Connector runs execute as `spawn`ed detached child processes, not inside the server's DB session. [pdpp-code]
- Production Postgres has no connection pooler in front of it (`max_connections=100`, no pooler env). [pdpp-prod-postgres]

## SOURCES

**temporal-activity-failures**
URL: https://docs.temporal.io/encyclopedia/detecting-activity-failures
Accessed: 2026-08-21
Quote: "The Temporal Server doesn't detect failures when a Worker loses communication with the Server or crashes. Therefore, the Temporal Server relies on the Start-To-Close Timeout to force Activity retries."

**temporal-activity-definition**
URL: https://docs.temporal.io/activity-definition
Accessed: 2026-08-21
Quote: "Activities won't record to the Event History until they return or produce an error. If an Activity fails to report to the server at all, it will be retried."

**sdk-go-worker-base**
URL: https://github.com/temporalio/sdk-go/blob/master/internal/internal_worker_base.go
Accessed: 2026-08-21
Quote: "Worker graceful stop timed out." / `WorkerStopTimeout` — "the time delay before hard terminate worker." (default 0s)

**kip-98**
URL: https://cwiki.apache.org/confluence/display/KAFKA/KIP-98+-+Exactly+Once+Delivery+and+Transactional+Messaging
Accessed: 2026-08-21
Quote: "Bumps up the epoch of the PID, so that the any previous zombie instance of the producer is fenced off"

**kip-447**
URL: https://cwiki.apache.org/confluence/display/KAFKA/KIP-447%3A+Producer+scalability+for+exactly+once+semantics
Accessed: 2026-08-21
Quote: "If one of the field is not matching correctly on server side, the client will be fenced immediately."

**kafka-design**
URL: https://github.com/apache/kafka/blob/trunk/docs/design/design.md
Accessed: 2026-08-21
Quote: "This can be handled more simply and generally by letting the consumer store its offset in the same place as its output."

**flink-e2e**
URL: https://flink.apache.org/2018/02/28/an-overview-of-end-to-end-exactly-once-processing-in-apache-flink-with-apache-kafka-too/
Accessed: 2026-08-21
Quote: "After a successful pre-commit, the commit must be guaranteed to eventually succeed – both our operators and our external system need to make this guarantee."

**flink-stateful**
URL: https://nightlies.apache.org/flink/flink-docs-master/docs/concepts/stateful-stream-processing/
Accessed: 2026-08-21

**flip-76**
URL: https://cwiki.apache.org/confluence/display/FLINK/FLIP-76%3A+Unaligned+Checkpoints
Accessed: 2026-08-21
Quote: "we may run into a vicious cycle of late checkpoints, crash, recovery to a rather outdated checkpoint, more back pressure, and even later checkpoints."

**cl85**
URL: https://lamport.azurewebsites.net/pubs/chandy.pdf
Accessed: 2026-08-21
Quote: "Of what use is the algorithm if the recorded global state never occurred?"

**chubby**
URL: https://static.googleusercontent.com/media/research.google.com/en//archive/chubby-osdi06.pdf
Accessed: 2026-08-21
Quote: "against the most recent sequencer that the server has observed"

**kleppmann**
URL: https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html
Accessed: 2026-08-21
Quote: Redlock "does not have any facility for generating fencing tokens."

**antirez**
URL: http://antirez.com/news/101
Accessed: 2026-08-21

**k8s-api-conv**
URL: https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md
Accessed: 2026-08-21
Quote: "Condition `status` values may be `True`, `False`, or `Unknown`. The absence of a condition should be interpreted the same as `Unknown`."

**k8s-node**
URL: https://kubernetes.io/docs/reference/node/node-status/
Accessed: 2026-08-21

**k8s-lifecycle**
URL: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/
Accessed: 2026-08-21

**docker-stop**
URL: https://docs.docker.com/reference/cli/docker/container/stop/
Accessed: 2026-08-21
Quote: "the Daemon determines the default, and is 10 seconds for Linux containers, and 30 seconds for Windows containers."

**docker-restart**
URL: https://docs.docker.com/engine/containers/start-containers-automatically/
Accessed: 2026-08-21

**systemd-service**
URL: https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html
Accessed: 2026-08-21
Quote: "The first receipt of this message must occur before `TimeoutStopSec=` is exceeded"

**river-client**
URL: https://github.com/riverqueue/river/blob/master/client.go
Accessed: 2026-08-21
Quote: "Note that this can result in repeat or duplicate execution of a job that is not actually stuck but is still working."

**river-states**
URL: https://github.com/riverqueue/river/blob/master/rivertype/river_type.go
Accessed: 2026-08-21

**river-1256**
URL: https://github.com/riverqueue/river/pull/1256
Accessed: 2026-08-21

**oban-changelog**
URL: https://github.com/oban-bg/oban/blob/main/CHANGELOG.md
Accessed: 2026-08-21
Quote: "3,600 beat records per hour even when the queue is idle"

**oban-lifeline**
URL: https://hexdocs.pm/oban/Oban.Plugins.Lifeline.html
Accessed: 2026-08-21
Quote: "purely based on time, rather than any heterogeneous heuristic about the job's expected execution time or whether the node is still alive"

**que-readme**
URL: https://github.com/que-rb/que
Accessed: 2026-08-21
Quote: "If a Ruby process dies, the jobs it's working won't be lost, or left in a locked or ambiguous state - they immediately become available for any other worker to pick up."

**sidekiq-manager**
URL: https://github.com/sidekiq/sidekiq/blob/main/lib/sidekiq/manager.rb
Accessed: 2026-08-21
Quote: "it is worse to lose a job than to run it twice"

**celery-redis-caveats**
URL: https://docs.celeryq.dev/en/stable/getting-started/backends-and-brokers/redis.html
Accessed: 2026-08-21

**faktory-workers**
URL: https://github.com/contribsys/faktory/wiki/Related-Projects
Accessed: 2026-08-21
Quote: "If a process dies, it will be removed after 1 minute and its jobs recovered after the job reservation timeout has passed (typically 30 minutes)."

**pdpp-prod-postgres**
URL: live instance — `docker exec pdpp-postgres-1 psql -U pdpp -d pdpp`
Accessed: 2026-08-21
Quote: 121 non-terminal `run.started`; 5 `processing` rows all `durable_prefix_count = record_count`; 134 `controller_restarted` vs 32 `controller_terminated_before_run_finished`.

**pdpp-prod-docker**
URL: live instance — `docker inspect pdpp-core-prod-drain`, `docker logs`
Accessed: 2026-08-21
Quote: `StopTimeout=<nil> StopSignal= Restart=unless-stopped`; `{"drained":0,"elapsedMs":5000,"timedOut":1}`

**pdpp-code**
URL: /home/tnunamak/code/pdpp @ cf4f1a701
Accessed: 2026-08-21
Quote: `reference-implementation/lib/controller-boot.ts:163`, `runtime/controller.ts:969`, `runtime/index.ts:4933`, `server/index.ts:8988`

## SYNTHESIS

### 1. The invariant

> **Every unit of work carries, in the same durable write that starts it, the identity of the owner epoch that may finish it; a successor epoch adjudicates any unit whose owner epoch is not its own, and interruption is a terminal state with its own name, written by the successor, never by the dying owner.**

### 2. Is "graceful shutdown" the right frame? No.

It is the wrong frame twice over, and the production data settles it without appeal to taste.

**It is unimplementable here.** Production sets no stop timeout, so Docker's 10s default governs (C, D). Gmail runs take minutes. The gap is two orders of magnitude, and it is not closable: `--stop-timeout` is fixed at container creation, and Docker has no equivalent of systemd's `EXTEND_TIMEOUT_USEC=` runtime extension (C). Any drain long enough to matter would be SIGKILLed mid-write. The existing 5s drain has already been measured failing exactly this way in production — `drained:0, timedOut:1, elapsedMs:5000` (D). It spent its whole budget and abandoned the run regardless. A drain is not a small win here; it is a **negative** one, because it consumes half the SIGKILL budget doing nothing while making the failure look handled.

**It is the wrong question.** The mature systems do not ask "can the dying process finish?" — they ask "who adjudicates work whose owner is gone?" Temporal's server has no crash-detection channel and converts silence into a terminal state with a timer; its `WorkerStopTimeout` defaults to **0s**, meaning it does not wait at all (A). Kafka's coordinator aborts abandoned transactions, and the successor's `InitProducerId` epoch bump fences the zombie and completes the recovery (A). In both, the dying owner writes nothing, by design. A design that depends on the dying process writing its own terminal state is a design with an unhandled `kill -9`.

So: **the boot-time reconciler is not an admission that the write path is missing a state.** That was the tempting hypothesis in the brief, and it is wrong. It is the *correct* location for the work, and it is what Kafka does. What PDPP is missing is not a write-path state — `run.abandoned` already exists (D) — it is a *durable owner-epoch on every unit of work*, and an *ownership predicate that actually matches*.

### 3. The state machine

One unit of work. Four states, three terminal.

```
                    ┌──────────────────────────────────────┐
   admit(epoch E)   │                                      │
  ──────────────►  RUNNING  ──── owner writes ────►  COMPLETED / FAILED
   writes owner_    │  (owner_epoch = E)               (owner E, in-process)
   epoch = E in     │
   the SAME txn     │
                    │  ── successor epoch E' ≠ E ──►  INTERRUPTED
                    │     adjudicates at boot          (successor writes;
                    │                                   owner never does)
```

| State | Meaning | Written by |
|---|---|---|
| `RUNNING` | An owner epoch has claimed this unit and no terminal fact exists. | Owner, in the same transaction that admits the work. |
| `COMPLETED` | Owner observed success and committed its checkpoint. | Owner. |
| `FAILED` | Owner observed a definite failure. Carries the connector's own reason. | Owner. |
| `INTERRUPTED` | **No owner will ever report on this unit.** The claiming epoch is provably not current. Coverage is neither proven nor disproven. | Successor epoch, at boot. Never the owner. |

`INTERRUPTED` is Kubernetes' `Unknown`, and it must stay distinct from `FAILED` for the same reason K8s keeps `Unknown` distinct from `False`: **they have different remedies** (A). `FAILED` on a `chase` login means *ask the human*. `INTERRUPTED` on the same connector means *nobody knows; re-run it on the normal schedule, silently*. Collapsing them is what wakes the owner at 3am for a deploy, and it is exactly what today's `run.failed`/`controller_restarted` does.

Crucially, `INTERRUPTED` is **epoch-derived, not time-derived**. This is the whole design. A wall-clock reaper must guess a threshold and can be wrong in both directions — River, Oban, Celery and Sidekiq all document the duplicate-execution cost of that guess in their own words (B). PDPP does not need the guess: a run stamped with epoch E, observed by epoch E' ≠ E, is *provably* orphaned. There is no threshold to tune and no false positive to trade against. That is a strictly better position than every job queue surveyed, and PDPP's existing `controller-boot.ts` already says so in a comment ("Deliberately NOT time-based... a guess that needs a threshold and can be wrong in both directions").

### 4. Do (a), (b), (c) collapse into one mechanism?

**They share one invariant and one state machine. They need two implementations, not one, and (c) needs none.** Argued from the data, not from tidiness:

- **(a) Runs — epoch adjudication.** Already built and correct in `controller-boot.ts`. Broken in production only by the `controller_id` defect (§5). Fix the identity; keep the mechanism.

- **(b) Device-ingest reservations — epoch adjudication, same shape, different table.** The measured facts make this decisive. All 5 wedged rows are fully durable (`durable_prefix_count = record_count`), so no data is at risk — but they are the *head* of the queue (`batch_seq` 188161–188165) and the collector has been silent for 13.5 hours (D). The `1b2ef7058` self-heal fires on retry, and **the retry is not coming**: the collector is blocked behind its own head-of-line. A fix that requires the client to retry cannot rescue a client that has stopped retrying. Something server-side must adjudicate. And it must be epoch-based, not time-based, for one specific reason: a `processing` row can legitimately be minutes old during a slow-but-live attempt, so a wall-clock reaper would race live work — precisely the duplicate-execution hazard River and Oban document (B). An epoch fence has no such race.

- **(c) Local collector outbox — already correct; change nothing.** It has explicit `ready/leased/succeeded/dead_letter` states with `lease_holder`, `lease_epoch`, `lease_until`, and expiry-based reclaim. This is the one place a *lease* is right, because the owner is on a different machine with no shared transaction, so an epoch handshake is unavailable and time is the only evidence. Note this is not an inconsistency: (a) and (b) get epochs because owner and adjudicator share a database; (c) gets a lease because they do not. **Fit the mechanism to the real topology, not to a uniform-looking abstraction.**

The unification that *is* real and worth building is the **predicate**, not the executor: "this unit's `owner_epoch` is not the current epoch." Six boot reconcilers exist today (D), each re-deriving its own notion of staleness — the manual-upload one uses a 10-minute wall clock to answer a question an epoch answers exactly (D). One shared `isOrphanedByEpoch(row)` helper plus per-table adjudicators is the deep-module split. A single generic "reconcile everything" engine would be shallow abstraction: it would need per-table SQL, per-table projections, and per-table terminal vocabularies injected into it, which is relocation, not decomplecting.

### 5. The defect that matters most (and it is not the one in the brief)

The brief framed this as "we need graceful shutdown." The production data says otherwise: **PDPP already built the right design and it is silently disabled.**

`resolveControllerId` falls back to `os.hostname()`. Under Docker that is the container ID, fresh on every `docker run`. `PDPP_CONTROLLER_ID` is unset in production. So the reconciler's ownership filter — `COALESCE(controller_id, $2) = $2`, written to isolate multi-controller deployments — instead excludes *every prior container*, which is *every orphan there has ever been* (D).

The result: **121 runs are permanently non-terminal in production**, stranded under dozens of dead container IDs going back to May (D). The mechanism designed to prevent exactly this has never once run against a real orphan from a previous container. The 32 `run.abandoned` events it did write came from same-container restarts (`node --watch`, in-container supervisor restarts) — the easy case.

Meanwhile the older `reconcileAbandonedControllerRuns` picks up some of the slack with the *wrong* vocabulary, writing `run.failed`/`controller_restarted` (134 historical, still firing, 16 since 2026-08-16). One of those runs had already staged three cursors and ingested a batch before being recorded as a plain failure (D). The two paths race; the boot one wins when its filter matches, which is rarely.

This is a one-line-class fix with an enormous payoff, and no amount of drain engineering would have found it. It also retroactively explains the incident that prompted this work: the orphaned Slack run was not a drain failure, it was an adjudication failure.

### 6. What becomes unnecessary — what PDPP can DELETE

1. **`reconcileAbandonedControllerRuns` and `ABANDONED_CONTROLLER_RUN_REASON = "controller_restarted"`** (`runtime/controller.ts:969`, ~40 lines plus its `startupControllerRunReconciliation` plumbing through `run-coordinator.ts`). It is a strictly worse duplicate of the boot reconciler: it writes `run.failed` where `run.abandoned` is correct, it reads the `controller_active_runs` flight table instead of the spine, and it loses the race whenever the boot reconciler's filter matches. Once the `controller_id` fix lands, it has no remaining job.

2. **The 5s connector drain** (`drainActiveRuns` + its call site in `server/index.ts:8988`). Measured in production spending its entire budget and abandoning the run anyway (D). It cannot succeed inside a 10s SIGKILL budget for minutes-long work, and it consumes half that budget on the way to failing. Deleting it makes shutdown *faster* and the failure mode *honest*. Keep `activeRunPromises` — the watchdog and `awaitRun` need it.

3. **`MANUAL_UPLOAD_IN_FLIGHT_STALE_MS` (the 10-minute wall clock)**, replaced by the epoch predicate. A guessed threshold answering a question that has an exact answer.

Not deletable, and worth saying so: `runGenerations` stays. It is the intra-epoch fence (two runs of the same connector-instance within one process incarnation) and boot epochs do not subsume it — Chubby and Kafka both keep per-acquisition generations *alongside* coarser identity (A).

### 7. Checkpoint honesty — the second real defect

`commit_on_success` discards every staged cursor unless the run reaches `succeeded` (D). That is what left 79 failed Gmail runs holding 52,830 durable records with no cursor advance, orphaning a UID band.

This is Flink's problem and Flink's answer applies (A). Records are already durably ingested at the moment `run.batch_ingested` is written — that is the pre-commit. After a successful pre-commit, **the commit is an obligation, not an option**. Withholding the cursor does not undo the ingest; it only guarantees the next run re-fetches data it already has, against providers that rate-limit hard.

The fix is not "commit on failure too" — that would advance past unprocessed data and violate the hard constraint. It is to make the commit boundary *per-stream and evidence-bearing*: a stream whose records are durably ingested **and** whose coverage is proven for a bounded slice may commit that slice's cursor regardless of the run's aggregate terminal state. PDPP already has the vocabulary for this — `DETAIL_COVERAGE`, `considered`/`covered`, and the `isCertifiedStreamCollectionFailure` path that already commits per-stream on a *failed* DONE (D). The change is to extend that certified path to `INTERRUPTED`, where the certification comes from the durable ingest record rather than the connector's own DONE message (which will never arrive).

This also protects the fabricated-denominator invariant, and this is the subtle part: an interrupted run must commit **only** the coverage it proved before interruption, and must not let the interruption itself imply coverage. Chandy-Lamport licenses exactly this (A) — the checkpoint need not be a moment that happened, only a state reachable from the start from which the end is still reachable. A per-stream cursor at the last proven-covered boundary is such a state. `covered == considered` over a *bounded slice with a recorded boundary* is honest; the same equality over "whatever I happened to fetch before dying" is the fabrication PDPP already fought. The boundary field is what distinguishes them, and `RuntimeContinuationFact` already carries `boundary`, `slice_start`, `slice_end`.

### 8. Migration path — each stage independently shippable and behavior-preserving

**Stage 0 — Make the existing design work (hours, highest value).**
Set `PDPP_CONTROLLER_ID` to a *deployment-stable* identity (not the container ID) in the production run command and the shipped compose/quickstart artifacts. Behavior-preserving by construction: the reconciler already runs; this only makes its ownership filter match reality. Add a test asserting `resolveControllerId` never silently returns a container-shaped hostname when unset in a container — or better, make the unset case fail closed rather than guessing.
*Verification: after one deploy, the boot log's `selected` count is non-zero for prior-container orphans, and the 121-run backlog begins draining.*

**Stage 1 — Backfill the 121 stranded runs.** One-shot adjudication pass ignoring `controller_id` (single-controller deployment, so every orphan is ours). Emits `run.abandoned` with the existing idempotency index. Reversible: it only adds terminal events where none exist.

**Stage 2 — Delete the loser.** Remove `reconcileAbandonedControllerRuns` and `controller_restarted`. Safe only after Stage 0/1 prove the boot path covers every case. Keep `controller_restarted` readable in the projection layer for history.

**Stage 3 — Delete the drain.** Remove `drainActiveRuns` from the SIGTERM path. Shutdown gets faster; orphans are adjudicated at next boot, which is now correct.

**Stage 4 — Extend the epoch to surface (b).** Add `owner_epoch` to `device_ingest_batch_outcomes`, written in the same INSERT as the `processing` reservation. Boot adjudicates any `processing` row whose epoch is not current: fully-durable rows settle to `accepted` (the outcome `1b2ef7058` already proved correct); partial rows keep their durable prefix and return to a retryable state. This is the only stage needing a migration, and it is additive with a NULL-tolerant predicate for legacy rows.

**Stage 5 — Per-stream checkpoint commit under `INTERRUPTED`.** The largest change; do it last, behind the oracle in §9.

### 9. The falsifiable test

The invariant is falsifiable by a single property, and it should be an oracle, not an example:

> **For every `run.started` in the spine, either a terminal event exists for that run, or its `boot_epoch` equals the current process's boot epoch.**

A SQL predicate over the real database, run in CI against both backends and assertable against production. It is currently **false in production for 121 rows** — which is what makes it a real oracle rather than a tautology. Note it is deliberately stated without reference to `controller_id`: that field is the thing that broke, so the oracle must not depend on it.

Supporting oracles:
- *Kill-9 survival, both surfaces.* Start a run (and a device-ingest batch), `SIGKILL` the server mid-flight, restart, assert: the run has exactly one terminal event and it is `run.abandoned`; the reservation is not `processing`. This is the test that would have caught the `controller_id` defect, because it must run the successor **in a new container**, not just a new process. Running it in-process is what let this bug survive: every existing boot-orphan test shares a `controller_id` with the orphan it creates.
- *No fabricated coverage.* An interrupted run's committed cursor must be ≤ the last boundary with `covered == considered` over a recorded slice. Mutation check: an implementation that commits the whole staged cursor must fail.
- *No sleeping owner.* Adjudicating an interrupted `chase`/`usaa`/`venmo` run must produce zero `needs_human` attention rows and zero ntfy pushes.
- *Deterministic under duplicate boots.* Two successive reconcile passes produce exactly one `run.abandoned` per orphan (the existing partial index already gives this; keep the test).

### 10. What I would NOT build — the anti-scope

- **A longer drain, or `--stop-timeout` tuning.** Rejected on measurement, not taste (C, D). Even a 60s timeout does not cover a Gmail run, and every second spent draining is a second not spent writing terminal state. This is the incidental complexity the whole document exists to reject: machinery whose only job is to compensate for the absence of an owner-epoch.
- **A heartbeat/liveness table for runs or reservations.** Oban shipped this, measured 3,600 rows/hour per idle queue, and deleted it in v2.0; River closed its heartbeat-rescue PR over table bloat; Faktory has heartbeats and still does not use them for job recovery (B). Worse, PDPP does not need the latency: a heartbeat only shortens the gap before a *guess* becomes actionable, and the epoch fence needs no guess. Buying write amplification to accelerate a mechanism we are deleting is the definition of incidental complexity.
- **A time-based reaper for `processing` rows.** It would race live slow attempts and reintroduce the duplicate-execution tradeoff that River, Oban, Celery and Sidekiq all document (B). PDPP has an exact predicate available; taking a probabilistic one instead is a strict regression.
- **A generic cross-table "interrupted work engine."** Six reconcilers should share a *predicate*, not an executor. A unified engine would need per-table SQL, projections and terminal vocabularies injected — relocation dressed as decomplecting.
- **Auto-resume / auto-retry of interrupted runs.** Hard-constrained: `chase`, `usaa`, `venmo`, `heb`, `amazon`, `reddit` need an interactive human login. `INTERRUPTED` must be silent and must let the normal schedule pick the work up. Sidekiq's "worse to lose a job than run it twice" (B) is a *server-side* value judgment and does not transfer to a system whose retry can wake a human at 3am or trip a provider rate limit.
- **Distributed-lock machinery (Redlock, ZooKeeper, external lease service).** Safety lives at the resource, and PDPP's resource is a local transactional database with a monotonic generation column — which *is* Chubby's sequencer, implemented in the strongest available place (A). Adding a lock service would move the check further from the data.
- **Que-style session-scoped ownership.** Genuinely elegant and genuinely unavailable: connector runs are `spawn`ed detached child processes, not holders of the server's DB session (D). Their death does not close a session, so there is no session lifetime to bind to. Worth naming because it is the one design that removes the reconciler entirely, and it is off the table for a structural reason rather than a preference.

### 11. Where I am uncertain, and what would settle it

**The one that matters: does per-stream commit under `INTERRUPTED` hold for every connector, or only for those emitting bounded `DETAIL_COVERAGE`?** The mechanism is only as honest as the coverage evidence beneath it. The corpus already records that no test in the fleet calls a real `collect()`, and that only two connectors are fully coverage-proven (Tier 0). If a connector stages a cursor without proving a bounded slice, committing it under interruption would fabricate a denominator — the exact failure PDPP has fought hardest.

*What would settle it:* a per-connector audit of what is actually staged at `run.state_staged` versus what is proven at `run.detail_coverage_declared`, over real production runs. Concretely — for every `run.state_staged` in the last 30 days, does a `run.detail_coverage_declared` for the same stream and run exist with `covered == considered` and a non-null `boundary`? That is answerable from the spine today, without new instrumentation. Until it is answered, **Stage 5 should ship gated per-connector, defaulting off** — which is also why I put it last.

Lower-confidence items, flagged honestly: Docker's behavior on *daemon restart* and *host reboot* (as opposed to explicit `docker stop`) is governed by the `docker.service` unit's own `TimeoutStopSec` and was not verified from primary sources; it could be shorter than 10s, which would only strengthen the anti-drain conclusion. And I have not verified that no *other* code path writes `processing` reservations outside `ensureProcessingBatch`.
