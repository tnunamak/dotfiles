---
title: "Leading event/audit systems emit one event per state-transition, not per re-touch; the retry/touch count lives in mutable current-state, not the append-only log"
date: 2026-06-12
topic: data-collection-systems
tags: [event-sourcing, audit-log, idempotency, temporal, kafka, cqrs, prior-art]
status: draft
sources: [temporal, event-sourcing, stripe-events, kafka-compaction, cloudtrail]
source_session: 019d189c-d050-7a92-af4a-aab2be41b5f1
---

## CLAIMS

- Temporal deliberately withholds retries from the durable Workflow Event History: an `ActivityTaskStarted` event does not appear until the activity completes or fails after exhausting all retries, explicitly "to avoid filling the Event History with noise"; the pending attempt count is read from the mutable Describe API (`Info.Attempt`), not the log. [temporal]
- The determinism reason Temporal gives: withholding per-retry events keeps the workflow command sequence deterministic across replays regardless of internal retry count; per-retry events would make history unbounded and non-reproducible. [temporal]
- In event sourcing / DDD, the aggregate validates a command against its current state and, if the command would not change state, returns a successful no-op without emitting an event; events are named in past tense because they assert a state change already happened (Greg Young: "events are a recording of the action that occurred"). [event-sourcing]
- The DDD escape hatch: when a no-op re-touch carries audit/compliance significance, record it as a distinct lower-frequency event type (`*.attempted`/`*.rejected`), never by re-emitting the original `*.changed` event; the right choice depends on whether the log's purpose is state reconstruction or a full behavioral audit trail. [event-sourcing]
- Stripe `Event` objects are immutable snapshots of changes; `*.updated` types are phrased as transitions, `data.previous_attributes` contains only modified attributes, and an idempotent write that changes nothing does not produce a fresh event; delivery may repeat (at-least-once) and consumers dedup on the stable `evt_…` id — a transport duplicate, not a new event. [stripe-events]
- Kafka separates two cleanup policies by use case: `cleanup.policy=delete` (retention) for audit trails/event logs that need the full transition sequence, and `cleanup.policy=compact` for state-stores/changelogs that keep at least the last state per key; compaction is explicitly NOT suited for audit/history because it discards intermediate values. [kafka-compaction]
- AWS CloudTrail — the strongest "log everything" case — still splits read-only (`Get*`/`Describe*`) from write (`Put*`/`Delete*`) events, disables high-volume data events by default, and the standard bloat-control is "log only write events"; because the `readOnly` flag is occasionally wrong (e.g. GuardDuty `GetRemainingFreeTrialDays` marked `readOnly:false`), classify by intent and effect, not by method-name heuristics. [cloudtrail]

## SOURCES

**temporal**
URL: https://docs.temporal.io/encyclopedia/retry-policies ; https://docs.temporal.io/encyclopedia/event-history ; https://docs.temporal.io/blog/idempotency-and-durable-execution
Accessed: 2026-06-12
Quote: "the ActivityTaskStarted Event will not show up in the Workflow Execution Event History until the Activity Execution has completed or failed (having exhausted all retries). This is to avoid filling the Event History with noise. Use the Describe API to get a pending Activity Execution's attempt count."

**event-sourcing**
URL: https://microservices.io/patterns/data/event-sourcing.html ; https://codeopinion.com/idempotent-aggregates/ ; https://blog.ttulka.com/events-vs-commands-in-ddd/ ; https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/domain-events-design-implementation
Accessed: 2026-06-12

**stripe-events**
URL: https://docs.stripe.com/api/events/object ; https://docs.stripe.com/webhooks ; https://docs.stripe.com/api/idempotent_requests
Accessed: 2026-06-12

**kafka-compaction**
URL: https://docs.confluent.io/kafka/design/log_compaction.html ; https://developer.confluent.io/courses/architecture/compaction/ ; https://kafka.apache.org/documentation/
Accessed: 2026-06-12

**cloudtrail**
URL: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-management-events-with-cloudtrail.html ; https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-data-events-with-cloudtrail.html ; https://repost.aws/knowledge-center/cloudtrail-data-management-events
Accessed: 2026-06-12

## SYNTHESIS

The consensus contract for an honest, minimal re-touch audit log: (1) Emit on transition, suppress on re-touch — decide before the append whether re-processing actually changed the entity, enforced at the write model (Temporal engine, DDD aggregate, Stripe diff), not by hoping a consumer filters later. (2) Put the touch/attempt count in mutable latest-per-key current-state (a status table, a compacted changelog, Temporal `Info.Attempt`) so history stays bounded and replayable while "how many times / is it still pending" stays cheap to query. (3) Re-touch becomes audit-worthy only when it is a genuinely new fact — record it as a distinct named type (`*.attempted`/`*.deferred`), and prefer folding repeated identical re-touches into a count on a single terminal event over N events. (4) Make any unavoidable re-emission an idempotent no-op via a stable identity + unique constraint. A run that emits thousands of events is closer to Temporal's "fill the history with noise" failure mode than to a clean transition log; the fix is to fold per-retry/per-detail re-touches into bounded transition events plus a counter, not to raise the event cap. Auditability is preserved, not lost: "we tried N times and it stayed pending" is reconstructable from the run-lifecycle transition events plus the current-state attempt counter.
