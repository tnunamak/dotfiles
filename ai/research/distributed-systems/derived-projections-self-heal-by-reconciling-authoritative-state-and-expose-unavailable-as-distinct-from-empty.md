---
title: "Derived projections self-heal by reconciling authoritative state and expose unavailable as distinct from empty"
date: 2026-07-16
topic: distributed-systems
tags: [projections, reconciliation, materialized-views, health, self-healing]
status: draft
sources: [kubernetes-controllers, postgres-materialized-views, postgres-refresh, kafka-streams-state]
---

## CLAIMS

- Kubernetes controllers repeatedly compare current state with declared desired state and act to move current state closer, rather than assuming one mutation hook permanently establishes convergence. [kubernetes-controllers]
- Kubernetes recommends separate controllers for particular aspects of state and reports controller failures through observed state, rather than one interlinked monolithic control loop. [kubernetes-controllers]
- PostgreSQL materialized views return persisted derived rows directly, and the documentation explicitly warns that those rows are not always current. [postgres-materialized-views]
- `REFRESH MATERIALIZED VIEW` completely replaces the derived contents from its backing query; `WITH NO DATA` leaves the view explicitly unscannable rather than representing the missing contents as an empty result. [postgres-refresh]
- Kafka Streams restores failed local state stores by replaying their changelog before the task resumes processing, making the durable source/checkpoint—not the last local cache contents—the recovery authority. [kafka-streams-state]

## SOURCES

**kubernetes-controllers**
URL: https://kubernetes.io/docs/concepts/architecture/controller/
Accessed: 2026-07-16

**postgres-materialized-views**
URL: https://www.postgresql.org/docs/16/rules-materializedviews.html
Accessed: 2026-07-16

**postgres-refresh**
URL: https://www.postgresql.org/docs/18/sql-refreshmaterializedview.html
Accessed: 2026-07-16

**kafka-streams-state**
URL: https://kafka.apache.org/31/streams/architecture/
Accessed: 2026-07-16

## SYNTHESIS

For a derived owner-health projection, mutation-time dirty marking is an optimization and diagnostic signal, not a sufficient correctness boundary. The read model needs an idempotent reconciler that compares the canonical connection set and durable source checkpoints with observed projection rows, creates missing rows, repairs stale rows, removes or classifies orphans, and reports any failed repair as unavailable evidence. Empty, unobserved, and unavailable are different states: exact zero requires an exhaustive clean source; a never-observed source is not zero; a dirty or failed source is unknown. Keep record-count authority, manifest declaration, and projection health orthogonal so an unexpected retained stream remains visible without being mistaken for a declared stream or corrupt record payload.
