---
title: "The best orchestration/control-plane UIs pick one dominant organizing object, make an event/trace timeline first-class, compute health, keep drill-downs one click, and enforce CLI/API parity with the UI"
date: 2026-04-16
topic: data-collection-systems
tags: [control-plane, observability, dashboards, orchestration, ux, prior-art]
status: draft
sources: [temporal, dagster, prefect, trigger-dev, github-actions, airbyte]
---

## CLAIMS

- Temporal keeps the workflow execution as the primary object and treats the append-only event history as the truth source, investing in an event-history timeline refresh for large histories (filtering, pending/failed views, live updates, pause, child-workflow inspection) rather than layering dashboard chrome; it is excellent at "what happened inside this execution?" and weak as a whole-system topology surface. [temporal]
- Dagster deliberately rejected jobs/runs as the primary view and made the asset graph the main organizing object because that is where operator pain is perceived; it treats large-graph scaling (10K+ assets, virtualization, edge-pruning) as a serious product problem and computes health/freshness/lineage rather than generic KPIs. [dagster]
- Prefect is the cleanest reference for separating the control/coordination plane from user infrastructure ("your code and data stay in your environment; only logs and state updates flow back"), treats events as a first-class substrate powering logs/automations/audit logs, and keeps CLI, API, and UI in sync around the same control objects (work pools, runs). [prefect]
- Trigger.dev makes the run page the product (trace + logs in real time on trigger), is powered by OpenTelemetry traces with auto-correlated parent/subtask logs, and exposes the full OTel trace tree over an API (`GET /api/v1/runs/{runId}/trace`) rather than burying it in the UI. [trigger-dev]
- GitHub Actions is a strong reference for simple dependency visualization + log ergonomics: a real-time visualization graph, one click from a graph node to its logs, auto-expanded failed steps, and searchable/downloadable/line-addressable logs with permalinks and reruns. [github-actions]
- Airbyte replaced its "Job History" tab with a Connection Timeline that includes syncs, refreshes, clears, schema updates, settings changes, and user-attributed actions — widening the event model beyond runs and treating configuration changes as first-class operational events. [airbyte]

## SOURCES

**temporal**
URL: https://temporal.io/change-log/updated-event-history-timeline-view-is-now-available ; https://temporal.io/change-log/ui-server-v2-20-0
Accessed: 2026-04-16

**dagster**
URL: https://dagster.io/blog/scaling-dag-visualization ; https://dagster.io/blog/introducing-the-new-dagster-plus-ui ; https://dagster.io/blog/cut-debugging-time-with-dagster
Accessed: 2026-04-16

**prefect**
URL: https://www.prefect.io/how-it-works ; https://docs.prefect.io/v3/concepts/events ; https://docs.prefect.io/v3/concepts/work-pools
Accessed: 2026-04-16

**trigger-dev**
URL: https://trigger.dev/docs/how-it-works ; https://trigger.dev/docs/management/runs/retrieve-trace ; https://trigger.dev/product/observability-and-monitoring
Accessed: 2026-04-16

**github-actions**
URL: https://docs.github.com/en/actions/how-tos/monitor-workflows/use-the-visualization-graph ; https://docs.github.com/en/actions/how-tos/monitor-workflows/use-workflow-run-logs
Accessed: 2026-04-16

**airbyte**
URL: https://airbyte.com/blog/audit-connections-with-the-new-timeline-feature ; https://support.airbyte.com/hc/en-us/articles/16960944967963-Notification-Types-for-Airbyte-Cloud
Accessed: 2026-04-16

## SYNTHESIS

Six cross-product patterns separate world-class control planes from homemade ones. (1) One dominant organizing object (Temporal: workflow execution; Dagster: asset; Airbyte: connection; Trigger.dev: run) plus at most one secondary timeline — homemade tools fail by making services/runs/logs/alerts/topology/config all equally primary, so nothing has navigational force. (2) A timeline or trace is first-class, not a buried tab — the event spine must be a primary design object, not an implementation detail. (3) Health is *computed* from history/checks/freshness, not manually interpreted from raw logs. (4) Drill-down paths are short: one click from graph-node→logs, run→trace, timeline-event→exact changed object. (5) CLI/API parity with the UI keeps the UI honest, improves automation/testing, and stops the dashboard from becoming a bespoke snowflake — if a capability is UI-only, it may be dashboard bloat. (6) The control plane is not the data plane — it observes and orchestrates; only logs/state flow back, not user data.

Homemade signals to avoid: three-plus equal-weight columns showing the whole system, generic card grids, tabs for everything with narrative for nothing, logs as the only debugging primitive, no stable event model underneath, demo-only endpoints, and separate state models for website/CLI/UI. The highest-confidence build order the research supports: (1) a canonical event/trace spine with stable IDs and typed events first; (2) a CLI/API that consumes that same spine and core objects; (3) the live control plane centered on one or two dominant objects with timeline-first debugging; (4) any curated illustrated/marketing flow last, replaying traces captured from the same system rather than dictating the runtime architecture. Invest in failure/debugging UX (stalled runs, revocation mid-poll, invalid metadata, interaction-required, schema drift), not just the happy path, and treat scale (long timelines, many runs/streams, bursts) as a first-order design constraint affecting the event model, filtering, virtualization, and trace pagination.
