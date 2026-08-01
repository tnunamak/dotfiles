---
title: "Durable local collectors are built from a SQLite outbox with explicit leases, first-class bounded work units, and destination-confirmed checkpoints"
date: 2026-05-19
topic: distributed-systems
tags: [outbox, queue, checkpointing, leases, backfill, local-agent, sqlite, temporal]
status: draft
sources: [outbox, sqlite-txn, sqlite-wal, solid-queue, que, celery-visibility, sidekiq, k8s-leases, airbyte-checkpoint, meltano-state, temporal-workflows, temporal-activities, airflow-catchup, dagster-backfill, tailscale-cli, tailscale-update, syncthing-autostart, syncthing-service, syncthing-rest, dropbox-linux, systemd-timers, systemd-resources, launchd]
source_session: 019d96dc-b062-7be1-80e0-b2a931dcd464
---

<!-- Reusable industry prior-art extracted from a pdpp local-collector design note. pdpp-specific
     primitives/naming and OpenSpec promotion decisions were dropped. -->

## CLAIMS

- The transactional outbox pattern stores outbound work in the same durable boundary as the state change that created it, then drains it asynchronously with at-least-once delivery and idempotent consumers; the durable invariant is that work must not be acknowledged until the destination effect is durable. [outbox]
- SQLite is a good substrate for a local outbox: it gives local ACID transactions, predictable portability, and WAL mode for concurrent readers with a single writer — but SQLite alone is not enough; the schema still needs explicit states, leases, attempts, and recovery rules. [sqlite-txn][sqlite-wal]
- DB-backed job queues (Rails Solid Queue, Que) use boring relational persistence for job state, claiming, retries, and durability instead of treating in-memory or JSON append files as the source of truth. [solid-queue][que]
- Redis-backed worker systems (Celery, Sidekiq) surface the stale-lease / visibility-timeout failure mode: if a worker claims work and dies, that work must become claimable again. [celery-visibility][sidekiq]
- Kubernetes Lease objects record holder identity and renewal metadata; a durable claim should record who claimed a unit, until when, and under which epoch — not a boolean lock. [k8s-leases]
- A durable outbox should carry explicit states (e.g. `ready`, `leased`, `succeeded`, `dead_letter`) and fields such as `leased_by`, `lease_epoch`, `lease_until`, `attempt_count`, `last_error`, `next_attempt_at`, with idempotent destination acknowledgements. [outbox][k8s-leases][celery-visibility]
- Airbyte, Singer, and Meltano converge that progress should be committed from destination-confirmed state, not source-observed state: source observation says what was seen; durable checkpointing says what is safe to resume after. [airbyte-checkpoint][meltano-state]
- Singer/Meltano state uses per-stream bookmarks rather than a single global cursor, because some streams are naturally sorted/cursorable while others need signposts, partition windows, or backfill units. [meltano-state]
- Temporal's durable-workflow model breaks long-running work into replay-safe steps with idempotent activities and explicit history; a system can preserve the same correctness shape without adopting Temporal itself. [temporal-workflows][temporal-activities]
- Airflow and Dagster partition/backfill models treat missed intervals or partitions as first-class work units, not invisible failure text; this matters for "read all conversations / all session files / all attachments / all transactions in a window." [airflow-catchup][dagster-backfill]
- Checkpoints should be per stream and, when needed, per partition/window/file/page, and should advance only after records and known gaps for that exact boundary are durably committed; unproven ranges should remain replayable or be represented as explicit backlog/gap units. [airbyte-checkpoint][dagster-backfill]
- Tailscale, Syncthing, Dropbox's Linux daemon, systemd, and launchd all separate setup phases rather than hiding everything behind one installer; the recurring shape is install, authenticate/enroll, run once, install service, inspect status, view logs, update, troubleshoot. [tailscale-cli][syncthing-autostart][dropbox-linux][systemd-timers][launchd]
- Syncthing and Tailscale demonstrate local status plus central visibility: the local agent must be inspectable from the device while a dashboard shows fleet health, version drift, queue/backlog health, and last successful sync. [tailscale-cli][syncthing-rest]
- systemd timers and launchd agents provide mature host-native scheduling, boot/login behavior, jitter, catch-up behavior, and resource controls — reason to use host-native service primitives rather than inventing a custom cross-platform scheduler daemon. [systemd-timers][systemd-resources][launchd]
- A local device agent should expose stable lifecycle commands (`doctor`, `enroll`, `backfill`, `service install/status/logs/uninstall`), with the first backfill made explicit, interruptible, resumable, visible, and resource-budgeted; steady-state collection should use OS-native service/timer mechanisms with jitter and catch-up. [tailscale-cli][syncthing-service][systemd-timers][launchd]
- Recover-and-drain the durable outbox first, then scan for new source work within budget — scanning first repeats expensive work, increases queue pressure, and delays recovery from already-prepared records. [outbox][airbyte-checkpoint]

## SOURCES

**outbox**
URL: https://microservices.io/patterns/data/transactional-outbox.html
Accessed: 2026-05-19

**sqlite-txn**
URL: https://www.sqlite.org/transactional.html
Accessed: 2026-05-19

**sqlite-wal**
URL: https://www.sqlite.org/wal.html
Accessed: 2026-05-19

**solid-queue**
URL: https://github.com/rails/solid_queue
Accessed: 2026-05-19

**que**
URL: https://github.com/que-rb/que
Accessed: 2026-05-19

**celery-visibility**
URL: https://docs.celeryq.dev/en/3.1/getting-started/brokers/redis.html#visibility-timeout
Accessed: 2026-05-19

**sidekiq**
URL: https://github.com/sidekiq/sidekiq/wiki/Reliability
Accessed: 2026-05-19

**k8s-leases**
URL: https://kubernetes.io/docs/concepts/architecture/leases/
Accessed: 2026-05-19

**airbyte-checkpoint**
URL: https://airbyte.com/blog/checkpointing
Accessed: 2026-05-19

**meltano-state**
URL: https://sdk.meltano.com/en/v0.53.4/implementation/state.html
Accessed: 2026-05-19

**temporal-workflows**
URL: https://docs.temporal.io/workflows
Accessed: 2026-05-19

**temporal-activities**
URL: https://docs.temporal.io/activities
Accessed: 2026-05-19

**airflow-catchup**
URL: https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/dag-run.html
Accessed: 2026-05-19

**dagster-backfill**
URL: https://docs.dagster.io/guides/build/partitions-and-backfills/backfilling-data
Accessed: 2026-05-19

**tailscale-cli**
URL: https://tailscale.com/docs/reference/tailscale-cli
Accessed: 2026-05-19

**tailscale-update**
URL: https://tailscale.com/docs/features/client/update
Accessed: 2026-05-19

**syncthing-autostart**
URL: https://docs.syncthing.net/users/autostart
Accessed: 2026-05-19

**syncthing-service**
URL: https://docs.syncthing.net/v2.0.0/users/syncthing.html
Accessed: 2026-05-19

**syncthing-rest**
URL: https://docs.syncthing.net/dev/rest.html
Accessed: 2026-05-19

**dropbox-linux**
URL: https://help.dropbox.com/installs/linux-commands
Accessed: 2026-05-19

**systemd-timers**
URL: https://www.freedesktop.org/software/systemd/man/latest/systemd.timer.html
Accessed: 2026-05-19

**systemd-resources**
URL: https://www.freedesktop.org/software/systemd/man/254/systemd.resource-control.html
Accessed: 2026-05-19

**launchd**
URL: https://www.launchd.info/
Accessed: 2026-05-19

## SYNTHESIS

The small set of durable primitives that makes crash/rate-limit/device-move robustness correct-by-construction rather than a growing pile of one-off patches: a durable local outbox (SQLite + WAL) with explicit lease/retry states and holder-identity leases; bounded work units as first-class (stream partition, file batch, page, date range) so large first backfills are not all-or-nothing; destination-confirmed checkpoints per stream/boundary; explicit backlog/gap units instead of failure text; recover-and-drain-before-scan startup order; and an inspectable device-agent CLI plus host-native (systemd/launchd) scheduling with resource budgets. The recurring lesson is to never acknowledge work until the destination effect is durable, and never advance a checkpoint on local observation alone.
