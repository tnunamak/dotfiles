---
title: "Data-collection frameworks either split delivery modes behind a shared message format or unify them behind one pipeline; unified adapters win only when you control both sides"
date: 2026-06-05
topic: data-collection-systems
tags: [ingestion, connectors, etl, airbyte, kafka-connect, push-vs-pull, prior-art]
status: draft
sources: [ietf-set, openid-ssf, scim, activitypub, websub, oauth2, otel-collector, kafka-connect, airbyte, debezium, nifi, fluentd-vector]
source_session: 019d33e2-4b34-76b0-9a9e-001d576fa54f
---

## CLAIMS

- IETF Security Event Tokens split message format from delivery across three RFCs: RFC 8417 defines the SET (a JWT envelope) independent of transport, RFC 8935 defines push delivery, RFC 8936 defines poll delivery — the same token is deliverable by either. [ietf-set]
- OpenID Shared Signals Framework (final Sept 2025) unifies the management plane (stream creation/config/verification) while making push (`urn:ietf:rfc:8935`) vs poll (`urn:ietf:rfc:8936`) an interchangeable delivery choice within one stream; CAEP and RISC are event-type profiles on top. [openid-ssf]
- SCIM separates synchronous CRUD provisioning (RFC 7644) from asynchronous subscription-based eventing (separate spec); RFC 7642 frames CSP-to-CSP push vs pull as deployment patterns of one protocol. [scim]
- W3C ActivityPub splits by trust context: client-to-server (within a user's own server) vs server-to-server federation; the inbox is a push target, the outbox a pull source. [activitypub]
- WebSub (W3C Rec, from PubSubHubbub) is the canonical "push as an overlay on polling" model: publisher/hub/subscriber, and explicitly "won't change or break your current polling infrastructure, and if for some reason something fails, you can still resort to polling." [websub]
- The OAuth 2.0 ecosystem is the strongest precedent for modular per-interaction specs: RFC 6749 core plus separate specs for Device Grant, CIBA, Introspection, RAR (RFC 9396), PKCE — each with its own lifecycle and trust model, composed over shared token mechanics. [oauth2]
- OpenTelemetry Collector genuinely unifies push (OTLP) and pull (Prometheus scraping) behind one receiver interface producing internal `pdata`; downstream processors/exporters are agnostic to how data arrived — but it assumes systems the operator controls/instrumented, with no consent model, no grant-based access, no interactive auth, and no bounded "run." [otel-collector]
- Kafka Connect makes all source connectors exclusively poll-based (`SourceTask.poll()` with framework-managed offsets): "SourceTask uses a pull interface and SinkTask uses a push interface"; push sources are adapted by writing to an intermediate store that a source connector then polls, not by adding a push path to the framework. [kafka-connect]
- The Airbyte protocol (`read(Config, Catalog, State) -> Stream<Record|State>`, RECORD/STATE over stdout, per-stream/global/legacy state modes) is exclusively pull-based with no push/webhook path; webhook data is handled by receiving into S3/DB then polling with a source connector. [airbyte]
- Debezium unifies pull+push within one connector: a bounded initial snapshot (pull) then continuous WAL/binlog streaming (push), with one offset store and one change-event output format spanning both phases; incremental snapshots (1.6+) run ad-hoc snapshots while streaming continues via a signaling table. [debezium]
- Apache NiFi (FlowFile processor DAG) and Fluentd/Fluent Bit/Vector (source→transform→sink) unify every mode behind a common internal event representation, but are execution platforms/daemons, not protocol specs, and assume continuous operation with cooperative systems. [nifi] [fluentd-vector]

## SOURCES

**ietf-set**
URL: https://datatracker.ietf.org/doc/rfc8417/ ; https://datatracker.ietf.org/doc/html/rfc8935 ; https://datatracker.ietf.org/doc/html/rfc8936
Accessed: 2026-06-05

**openid-ssf**
URL: https://openid.net/specs/openid-sharedsignals-framework-1_0-final.html ; https://openid.net/specs/openid-caep-1_0-final.html
Accessed: 2026-06-05

**scim**
URL: https://datatracker.ietf.org/doc/html/rfc7644 ; https://www.rfc-editor.org/rfc/rfc7642.html
Accessed: 2026-06-05

**activitypub**
URL: https://www.w3.org/TR/activitypub/
Accessed: 2026-06-05

**websub**
URL: https://www.w3.org/TR/websub/
Accessed: 2026-06-05
Quote: "implementing it won't change or break your current polling infrastructure, and if for some reason something fails, you can still resort to polling."

**oauth2**
URL: https://datatracker.ietf.org/doc/html/rfc6749 ; https://www.oauth.com/oauth2-servers/map-oauth-2-0-specs/ ; https://openid.net/specs/openid-client-initiated-backchannel-authentication-core-1_0.html
Accessed: 2026-06-05

**otel-collector**
URL: https://opentelemetry.io/docs/collector/architecture/ ; https://opentelemetry.io/docs/collector/building/receiver/
Accessed: 2026-06-05

**kafka-connect**
URL: https://kafka.apache.org/41/kafka-connect/connector-development-guide/ ; https://docs.confluent.io/platform/current/connect/design.html
Accessed: 2026-06-05
Quote: "SourceTask uses a pull interface and SinkTask uses a push interface."

**airbyte**
URL: https://docs.airbyte.com/understanding-airbyte/airbyte-protocol ; https://docs.airbyte.com/platform/connector-development/connector-specification-reference
Accessed: 2026-06-05

**debezium**
URL: https://debezium.io/documentation/reference/stable/features.html ; https://debezium.io/blog/2021/10/07/incremental-snapshots/
Accessed: 2026-06-05

**nifi**
URL: https://nifi.apache.org/docs/nifi-docs/html/overview.html
Accessed: 2026-06-05

**fluentd-vector**
URL: https://vector.dev/docs/architecture/pipeline-model/ ; https://fluentbit.io/
Accessed: 2026-06-05

## SYNTHESIS

Two viable architectures, and the choice is governed by the trust/control boundary. Systems that *unify* delivery modes behind one pipeline (OTel Collector, Kafka Connect, Debezium, NiFi, Fluentd/Vector) succeed because they collect from systems the operator controls, instruments, or has API/log access to, with cooperative structured streams and continuous daemons. Systems that *split* modes (IETF SET, OpenID SSF, SCIM, ActivityPub, WebSub, OAuth 2.0) do so behind a shared message/token format, which lets implementers adopt only what they need. The deepest analogy gap for any collector that pulls personal data from platforms the user does *not* control (via browser automation against non-cooperating sources) is: interactive authentication is first-class not an edge case, scope enforcement is a consent obligation not an optimization, and a bounded run with explicit start/done has audit advantages a continuous receiver lacks. The pragmatic synthesis these systems point to: keep a bounded-run, pull-based collection profile as the primary primitive (validated at scale by Airbyte and Kafka Connect's deliberate poll-only source decision); add thin sibling push/batch-import profiles that share one RECORD/STATE message format and one state/scope model (the IETF SET / WebSub / SSF pattern of shared format + modular delivery); and do NOT build a unified receiver/adapter framework, which either compromises the bounded model's auditability or degenerates into conditional paths that are "unified" in name only.
