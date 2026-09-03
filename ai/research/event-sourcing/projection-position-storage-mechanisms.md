---
title: "Event-sourcing frameworks store projection positions independently per consumer with configurable seeding strategies"
date: 2026-08-17
topic: event-sourcing
tags: [projection, checkpoint, position-storage, marten, axon, eventstoredb, rama]
status: draft
sources: [marten-projection, axon-tracking, eventstoredb-persistent, rama-stream]
source_session: 4156745b-a33e-4b8c-895b-d4227f1638ce
---

## CLAIMS

- **Marten** stores projection progress in a single `mt_event_progression` row per `ProjectionVersion` (projection name + version pair), keyed by `projection_name` and `last_seq_id`. Rebuilds replay from the beginning; versions isolate consumers entirely [marten-projection].

- **Axon Framework** stores tracking tokens in `token_entry` table with composite key `(processor_name, segment)`, serialized as bytea blob (typically 100–500 bytes). Seeding is configurable: `createTailToken()` (earliest events, default), `createHeadToken()` (newest, default for Sagas), or `createTokenAt(Instant)` (specific time). Segments enable distributed processing across instances [axon-tracking].

- **EventStoreDB** stores persistent subscription positions server-side in internal system streams, not queryable as user tables. Seeding at creation is configurable: from beginning, from end, or from timestamp. Once a subscription is created, it resumes from its last checkpoint; the `start_from` argument is ignored on resume [eventstoredb-persistent].

- **Rama** tracks stream topology progress automatically in an internal system PState (`$$__streaming-state-<topologyId>`), not user-queryable. Seeding is automatic from offset 0 and not configurable. PState migrations restart if migration ID changes, resume if unchanged [rama-stream].

- **Checkpoint write overhead is configurable across all frameworks except Marten/Rama**. Axon's `andTokenClaimInterval()` and EventStoreDB's persistence threshold (default: after each ack, configurable to batch) control write frequency. At ~1M events + 25 consumers, Axon produces ~25 rows; EventStoreDB and Rama have implicit/minimal overhead; Marten has one row per projection but rebuild is the scaling wall [axon-tracking, eventstoredb-persistent].

- **Position isolation is always independent per consumer identifier** (projection version, processor segment, subscription group, or topology partition). Multi-instance deployments coordinate via these keys but do not share position state [marten-projection, axon-tracking, eventstoredb-persistent, rama-stream].

## SOURCES

**marten-projection**  
URL: https://martendb.io/events/projections/  
Accessed: 2026-08-17  
Quote: "By incrementing the version number, you signal to Marten that this projection should be treated as a separate entity (with its own underlying storage)."

**axon-tracking**  
URL: https://docs.axoniq.io/axon-framework-reference/4.11/events/event-processors/streaming/  
Accessed: 2026-08-17  
Quote: "A Streaming Processor dedicated to a Saga will default the initial token to the head of the stream to avoid processing historical events that could cause unwanted side effects."

**axon-token-entry**  
URL: https://github.com/AxonFramework/AxonFramework/blob/main/messaging/src/main/java/org/axonframework/eventhandling/tokenstore/jpa/TokenEntry.java  
Accessed: 2026-08-17  
Quote: Schema with `processor_name`, `segment`, `owner`, `timestamp`, `token` (blob), `token_type` as primary key on `(processor_name, segment)`.

**eventstoredb-persistent**  
URL: https://developers.eventstore.com/server/v21.10/persistent-subscriptions  
Accessed: 2026-08-17  
Quote: "If the subscriber doesn't know the last checkpoint, it can subscribe to the beginning of the stream or start processing events from the end of the stream, so all the historical events will be ignored. The subscription will resume from the last acknowledged event if it already exists and will ignore the start_from argument in this case."

**eventstoredb-checkpoint-threshold**  
URL: https://developers.eventstore.com/server/v22.10/persistent-subscriptions  
Accessed: 2026-08-17  
Quote: "By default a subscription will persist a checkpoint after each acknowledgement, which can cause high write load on the database for busy subscriptions which receive a large number of events. For example using a threshold of 100 means that a checkpoint is written at most once for every 100 events processed."

**rama-stream**  
URL: https://redplanetlabs.com/docs/~/stream.html  
Accessed: 2026-08-17  
Quote: "Stream topologies track progress with an internal PState with a name of the form `$$__streaming-state-<topologyId>`."

**rama-pstate-migration**  
URL: https://redplanetlabs.com/docs/~/pstates.html  
Accessed: 2026-08-17  
Quote: "Migration IDs are tracked per location and are used to determine what to do when a module is updated while it is still migrating values on disk. If this remains the same, it continues where it left off. Otherwise, it restarts from the beginning of the PState."

## SYNTHESIS

All four frameworks isolate projection/consumer state independently—no shared position across consumers of the same event source. Seeding behavior differs: Marten replays from start (no choice); Axon, EventStoreDB, and Rama offer configurable windows (earliest, latest, or time-based). Checkpoint writes are tunable in Axon and EventStoreDB but fixed in Marten (single write per batch) and Rama (implicit, batch-friendly).

At single-process scale (~1M events, ~25 consumers), position storage overhead is negligible (Rama < EventStoreDB < Axon ≤ Marten). The real cost is rebuild time for Marten and checkpoint frequency for high-throughput Axon/EventStoreDB deployments—both are tunable. Cluster benefits (segments, load balancing, UI visibility) exist in Axon and Rama but add no value to mono deployments. EventStoreDB's server-side management simplifies ops but trades query visibility for less operational surface.

**For small-scale, single-process evaluation**: Rama's automatic, implicit tracking and Marten's simplicity are both valid; EventStoreDB's tunable threshold is a practical middle ground. Axon over-engineers for mono but is the only choice if future distribution is planned.
