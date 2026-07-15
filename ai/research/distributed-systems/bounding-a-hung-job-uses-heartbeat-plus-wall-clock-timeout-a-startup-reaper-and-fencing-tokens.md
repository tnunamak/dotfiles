---
title: "Leading job systems bound a hung run with a wall-clock ceiling plus a liveness heartbeat, recover crashed runs with a startup reaper, and prevent zombie double-dispatch with fencing tokens — pure wall-clock TTL alone is insufficient for correctness"
date: 2026-06-14
topic: distributed-systems
tags: [job-scheduling, timeouts, heartbeat, fencing-tokens, distributed-locking, watchdog, reaper, prior-art]
status: draft
sources: [temporal-failures, temporal-heartbeat, sidekiq-reliability, k8s-jobs, aws-sfn, celery-visibility, kleppmann-locking, redis-locks, goodjob]
---

## CLAIMS

- Temporal separates three orthogonal Activity timeouts: ScheduleToStart (scheduling→pickup), StartToClose (hard wall-clock ceiling per attempt), and Heartbeat (max silence between `RecordHeartbeat` calls). It recommends setting both StartToClose (hard cap) and Heartbeat (fast liveness detection, fires in seconds/minutes not hours) for long-running activities; heartbeats are SDK-throttled to at most every `heartbeatTimeout × 0.8` and the final heartbeat before failure is delivered immediately. [temporal-failures] [temporal-heartbeat]
- Sidekiq Pro `super_fetch` uses process-level liveness, not per-job timeouts: each process heartbeats to Redis every few seconds (expires after 60s), and an orphan reaper on startup (and hourly via full SCAN) re-enqueues jobs whose owning process heartbeat has expired. Recovery timing is best-effort ("might recover in 5 minutes or 3 hours"); restarting a process is the recommended trigger to look for orphans. [sidekiq-reliability]
- Kubernetes Jobs enforce `spec.activeDeadlineSeconds` as a pure wall-clock ceiling for the whole Job (takes precedence over `backoffLimit`); on exceed, all Pods are terminated and the Job fails with `DeadlineExceeded`. Liveness is tracked by an external control plane, not by the job process. [k8s-jobs]
- AWS Step Functions tasks support `HeartbeatSeconds` (fails with `States.HeartbeatTimeout` if `SendTaskHeartbeat` is not called in the window) within an outer `TimeoutSeconds`; a task token from `GetActivityTask` is vended to exactly one worker and the workflow only advances on `SendTaskSuccess`/`SendTaskFailure` — the liveness decision is made by a durable external state machine, not the worker. [aws-sfn]
- Celery's Redis broker uses a visibility timeout: a claimed task becomes reclaimable if not acknowledged within the window, and Celery explicitly warns that any task running longer than the visibility timeout will be delivered twice — pure wall-clock timeouts must exceed worst-case task duration or tasks double-dispatch. [celery-visibility]
- Kleppmann's distributed-locking analysis: a process can acquire a lock, pause (GC/deschedule), have its lease expire, and resume unaware — so for *correctness* you need fencing tokens (a strictly monotonically increasing integer issued per acquisition, included in every storage write, with the storage layer rejecting writes bearing a token lower than the last seen). Pure TTL locks suffice only as a best-effort efficiency optimization. [kleppmann-locking] [redis-locks]
- GoodJob uses PostgreSQL advisory locks for job ownership: because advisory locks are session-scoped, a process crash ends the session and auto-releases the lock — crash-safe liveness with no explicit heartbeat, since the live DB connection *is* the heartbeat. [goodjob]

## SOURCES

**temporal-failures**
URL: https://docs.temporal.io/encyclopedia/detecting-activity-failures
Accessed: 2026-06-14

**temporal-heartbeat**
URL: https://docs.temporal.io/activities#heartbeat-timeout
Accessed: 2026-06-14

**sidekiq-reliability**
URL: https://github.com/sidekiq/sidekiq/wiki/Reliability
Accessed: 2026-06-14

**k8s-jobs**
URL: https://kubernetes.io/docs/concepts/workloads/controllers/job/#job-termination-and-cleanup
Accessed: 2026-06-14

**aws-sfn**
URL: https://docs.aws.amazon.com/step-functions/latest/dg/concepts-amazon-states-language.html
Accessed: 2026-06-14

**celery-visibility**
URL: https://docs.celeryq.dev/en/stable/userguide/configuration.html#visibility-timeout
Accessed: 2026-06-14

**kleppmann-locking**
URL: https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html
Accessed: 2026-06-14
Quote: "If you need locks only on a best-effort basis (as an efficiency optimization, not for correctness), I would recommend sticking with the straightforward single-node locking algorithm for Redis. If you need locks for correctness, please don't use Redlock."

**redis-locks**
URL: https://redis.io/docs/latest/develop/clients/patterns/distributed-locks/
Accessed: 2026-06-14

**goodjob**
URL: https://github.com/bensheldon/good_job
Accessed: 2026-06-14

## SYNTHESIS

A layered model recurs across mature job systems for "is this run still alive, and how do I stop a hung one from wedging future runs without double-dispatching a live one": (1) a wall-clock ceiling that hard-caps a run's duration (Temporal StartToClose, k8s `activeDeadlineSeconds`, Step Functions `TimeoutSeconds`); (2) a liveness heartbeat for fast detection of a silent worker (Temporal Heartbeat, Step Functions HeartbeatSeconds, Sidekiq process heartbeat) — faster than a wall-clock timeout but requiring the worker to emit signals; (3) a crash-recovery reaper that sweeps orphaned state on startup (Sidekiq) or is unnecessary because liveness is bound to a crash-releasing resource (GoodJob's session-scoped advisory lock); and (4) fencing tokens / a monotonic run-generation to prevent a resumed zombie from writing concurrently with its replacement (Kleppmann). Key transferable rules: pure wall-clock TTL is a correctness hazard unless it strictly exceeds worst-case duration (Celery's double-delivery warning); heartbeats need a worker-side protocol change, so a black-box subprocess is better bounded by an external wall-clock watchdog that kills it (SIGKILL as the fence); a startup reaper is complementary to a live watchdog, not a substitute (the watchdog dies with the process, the reaper survives restart); and the durable source of truth should be external state (DB/Redis) with any in-memory map as a fast-path cache — in-memory-as-source-of-truth is exactly what leaks on a hang or crash. For a single-process system with SIGKILL on the subprocess, fencing tokens are optional insurance rather than strictly required, but a durable external state + startup reaper are needed for full crash-restart safety.