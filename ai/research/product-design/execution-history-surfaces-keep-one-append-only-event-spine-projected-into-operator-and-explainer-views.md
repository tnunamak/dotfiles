---
title: "Execution-history / trace surfaces converge on one append-only event spine as source of truth, projected into different views; hybrid event-history + trace/span semantics, a two-panel timeline+inspector detail, and mandatory artifact drilldown"
date: 2026-04-16
topic: product-design
tags: [tracing, observability, event-history, timeline-ui, workflow, waterfall]
status: draft
sources: [jaeger, opentelemetry, grafana-traces, temporal, trigger-dev, inngest]
---

## CLAIMS

- Jaeger models traces as DAGs of spans with references, tags, and logs; its UI is a search list + waterfall trace view + dependency graph, making durations/concurrency/causal structure visually obvious, but is weak at product/domain semantics unless spans are heavily enriched. [jaeger]
- OpenTelemetry's trace data model distinguishes duration-bearing spans, point-in-time events, and links (causal relationships that are not strict parent/child), plus attributes and status — a clear split between spans and events, with links carrying async causality. [opentelemetry]
- Grafana's trace view is most useful for its surrounding affordances — trace search/filtering, critical-path highlighting, span filters, and cross-links to logs/metrics/profiles + a service/node graph — teaching that a timeline gets far more useful when it links to the exact adjacent evidence explaining the selected moment. [grafana-traces]
- Temporal treats each execution's event history as the source of truth: an ordered append-only record accessible from code, CLI, and UI; the modern UI emphasizes filters, pending/failed-only views, live updates, and related-event grouping — the execution history is a first-class object, not exhaust from logs. [temporal]
- Trigger.dev's run-page timeline shows the run lifecycle including the phase before execution starts (queueing, waiting) plus attempts and realtime updates — exposing queueing/waiting/retries explicitly rather than collapsing them. [trigger-dev]
- Inngest renders traced function runs as a resizable two-panel waterfall (left: timeline/bars/hierarchy; right: contextual details for the selected step) with retry attempts as distinct spans and step-level input/output/error payloads in the details panel. [inngest]

## SOURCES

**jaeger**
URL: https://www.jaegertracing.io/docs/2.16/features/ ; https://www.jaegertracing.io/docs/2.0/terminology/
Accessed: 2026-04-16

**opentelemetry**
URL: https://opentelemetry.io/docs/concepts/signals/traces/
Accessed: 2026-04-16

**grafana-traces**
URL: https://grafana.com/docs/grafana/latest/visualizations/explore/trace-integration/ ; https://grafana.com/docs/learning-paths/beyla-tempo/explore-traces/
Accessed: 2026-04-16

**temporal**
URL: https://temporal.io/change-log/updated-event-history-timeline-view-is-now-available ; https://docs.temporal.io/web-ui
Accessed: 2026-04-16

**trigger-dev**
URL: https://trigger.dev/changelog/run-page-timeline ; https://trigger.dev/docs/runs ; https://trigger.dev/docs/realtime/overview
Accessed: 2026-04-16

**inngest**
URL: https://www.inngest.com/docs/platform/monitor/traces
Accessed: 2026-04-16

## SYNTHESIS

The strongest prior art converges on one rule: keep one append-only source of truth for execution history, then project it into different views for different audiences. Do not choose between an event log and a trace model — use a hybrid: event-history semantics for exact ordered state transitions and auditability, trace/span semantics for durations, overlaps, waits, retries, and causal links. The right shape is an append-only event history that can be rendered as a trace-like waterfall AND as a simpler milestone timeline.

Role assignment across the exemplars: Temporal is the model for the substrate (event history as a first-class ordered append-only object accessible from code/CLI/UI, not log exhaust); Jaeger/OpenTelemetry/Grafana are the model for making time and causality visible (waterfall for durations/overlaps, links for async handoff, span filtering, critical-path emphasis, cross-links to adjacent evidence); Trigger.dev/Inngest are the model for operator-facing run history (distinguish queued/waiting/executing/completed/failed/canceled; show retries as separate attempts not a collapsed blob; show the "before execution starts" phase; a resizable two-panel timeline+inspector; exact input/output/error payloads in the detail panel).

Generalizable design rules: (1) the canonical model is typed events with optional span semantics — every event has stable identity + ordering, some open/close duration-bearing spans, and all UI derives from this model; (2) use spans for duration (runs, queries, waits), point events for state transitions (issued, revoked, minted), and links for cross-boundary causality; (3) event rows must point to real artifacts (payloads, snapshots, diffs), not just human summaries — artifact drilldown is what separates a reference surface from a pretty event log; (4) top-level surface = an index/list answering "what's active / failed / recently finished / to inspect next," separate from the deep detail page; (5) detail = two-panel (timeline+waterfall left, inspector right), better than a three-panel "system diagram" because one item can be selected and understood deeply; (6) group the raw stream into semantic blocks and provide filters (by type, pending/failed-only, object id) + live updates with a pause control; (7) split projections by audience — a full-fidelity operator surface vs a compressed curated explainer that hides retries and compresses repeated updates — but both must project the SAME spine, or the system drifts.

Anti-patterns to avoid: "card soup" (a dashboard of loosely-related cards with no sequencing/source-of-truth); logs pretending to be history (unstable shape, weak identity/correlation, encourages string-scraping); tree-only structure with no links (misrepresents async handoff and cross-object causality); span-waterfall-only with no exact history (operators/reviewers need exact order/ids/state/artifacts); no retry/pending/queue visibility (hides real lifecycle friction); a topology/service map as the truth source (it is a secondary projection, not the substrate); and demo-only traces the live stack cannot reproduce (the explainer should replay a real or scenario-generated trace from the same model).
