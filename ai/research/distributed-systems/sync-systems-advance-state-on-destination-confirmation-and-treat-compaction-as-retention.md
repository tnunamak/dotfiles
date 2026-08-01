---
title: "Sync systems advance state only after destination-confirmed progress, treat log compaction as retention policy not source history, and make idempotency a construction boundary"
date: 2026-05-26
topic: distributed-systems
tags: [sync, checkpointing, log-compaction, idempotency, record-versioning, airbyte, kafka, stripe]
status: draft
sources: [airbyte-checkpoint, meltano-state, kafka-compaction, stripe-idempotency]
source_session: 019d189c-d050-7a92-af4a-aab2be41b5f1
---

<!-- Reusable industry prior-art extracted from a pdpp record-version-semantics note.
     pdpp-specific verdict, local Codex replay notes, and backup-table names were dropped. -->

## CLAIMS

- Sync systems advance state only after destination-confirmed progress: Airbyte describes checkpointing as valid when the destination echoes state, meaning it has committed records up to that point. [airbyte-checkpoint]
- Meltano/Singer-style state tracks per-stream bookmarks and acknowledges at-least-once (not exactly-once) delivery. [meltano-state]
- Log-compacted systems keep the latest value per key while treating compaction as a retention policy, not as the source event history itself: Kafka/Confluent frames compaction as retaining at least the last update per primary key and using null payloads as deletes. [kafka-compaction]
- Idempotent mutation APIs prevent duplicate effects from retries by recording the first result for an idempotency key and comparing repeat parameters — idempotency is a server-side construction boundary, not a post-hoc cleanup job. [stripe-idempotency]

## SOURCES

**airbyte-checkpoint**
URL: https://airbyte.com/blog/checkpointing
Accessed: 2026-05-26

**meltano-state**
URL: https://sdk.meltano.com/en/v0.53.2/implementation/state.html
Accessed: 2026-05-26

**kafka-compaction**
URL: https://docs.confluent.io/kafka/design/log_compaction.html
Accessed: 2026-05-26

**stripe-idempotency**
URL: https://docs.stripe.com/api/idempotent_requests
Accessed: 2026-05-26

## SYNTHESIS

When deciding record-version/history semantics for a sync or personal-data system, the consistent prior-art lesson is to build correctness at the boundary rather than reconcile after the fact: advance state only on destination confirmation, keep the change log append-only, treat any compaction/dedup as an explicit owner-chosen retention policy (with backup + dry-run), and enforce idempotency at write time. This argues against a general "cursor vs retained record" reconciler that would force the store to understand source-specific derived-field semantics it does not own; prefer fixing the connector at the source, keeping a guarded owner-run repair tool, and adding version/churn observability so the next regression is visible without ad-hoc SQL.
