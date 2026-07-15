---
title: "Evidence timelines (runs/traces/activity) are reached from the subject they explain, render one typed compact row per event over a closed vocabulary, orient with a histogram, and keep raw payload as the last tab"
date: 2026-06-18
topic: data-explorer-ux
tags: [traces, runs, timelines, activity-feed, observability-ux, prior-art]
status: draft
sources: [datadog-trace-view, datadog-trace-explorer, datadog-correlate, datadog-log-explorer, sentry-breadcrumbs, sentry-issue-details, temporal-workflows, temporal-events, temporal-web-ui, gha-run-logs, gha-run-history, gha-visualization, linear-activity, linear-collapsed-history]
---

## CLAIMS

- Datadog renders a single trace as a flame graph (each span a horizontal bar positioned/sized by start-time and duration, nested by parent/child) with alternate span-list/waterfall views; selecting a span opens a side/lower panel with that span's metadata, tags, and correlated logs, plus a breakdown of where time went. The visual and the detail panel are split — scan the graph, click one bar, read its details in place. [datadog-trace-view]
- Datadog's trace/span list is driven by a search query bar + facet rail; results show as a list, grouped by a facet, or visualized as a timeseries/top-list, and a facet selected in the rail rewrites the query string (query and facets share one source of truth). [datadog-trace-explorer]
- Datadog correlates logs and traces by injecting `trace_id`/`span_id` so a log links to its trace and vice-versa, navigable in both directions — the answer to "show me the evidence for this moment" is a link, not inline-pasted evidence. [datadog-correlate]
- Datadog Log Explorer is a reorderable column-based list over query + facets, with a timeline histogram above the list (volume over time, color-segmented by status) and a side panel for the selected log — compact columnar rows, a scannable time histogram, and saved/shareable views. [datadog-log-explorer]
- Sentry breadcrumbs are a chronological trail of events leading up to an error, each a compact typed row (category, type, level, message, timestamp) with severity coloring, rendered as a tight filterable table inside the issue they explain — never a standalone destination. [sentry-breadcrumbs]
- Sentry issue detail composes header + clickable tag facets + stack trace + breadcrumb timeline; the raw JSON event is a secondary "JSON" affordance, not the default view. [sentry-issue-details]
- Temporal gives each Workflow Execution an append-only Event History that is the source of truth; the UI is a projection of it. [temporal-workflows]
- Temporal's event history is a sequence of strongly-named typed events (`WorkflowExecutionStarted`, `ActivityTaskScheduled`, `ActivityTaskStarted`, `ActivityTaskCompleted`/`Failed`, `TimerStarted`, `WorkflowExecutionSignaled`, …), each carrying a typed attributes payload and referencing prior events by id (`scheduledEventId`) — a closed, documented, finite vocabulary is what makes the timeline scannable and testable. [temporal-events]
- Temporal's Web UI shows event history as a compact event list with a timeline, with filters (pending/failed-only), related-event grouping, expand-on-demand of an event's full attributes, and live updates for running executions — reached by drilling from an execution, not as a global firehose. [temporal-web-ui]
- GitHub Actions logs are organized by job → step; each step is a collapsible group with a status glyph and toggleable per-line timestamps; you can search within the log (matching lines auto-expand their step) and link to a specific line via anchor URL; default is collapsed step headers (scan first), expand the failing step. [gha-run-logs]
- GitHub Actions run history shows status per job and step; you drill from the run into its logs. [gha-run-history]
- GitHub Actions generates a real-time job-DAG visualization graph illustrating run progress with live status per node; the graph and the logs are two projections of the same run, and clicking a job node jumps to that job's logs. [gha-visualization]
- Linear's issue Activity feed is a single chronological feed of compact typed rows (actor + verb + object) threaded inside the issue; "the assignment and delegation history is tracked in its Activity feed, which shows changes over time and who made them," and an agent assigned via the same field lands its actions as rows in the same feed rather than a separate log. [linear-activity]
- Linear (changelog dated 2025-04-03) keeps the activity feed focused by grouping "similar consecutive events and collaps[ing] older activity between comment threads" — consecutive same-type rows collapse with a count while comments stay expanded, the density mechanism for a typed activity feed. [linear-collapsed-history]

## SOURCES

**datadog-trace-view**
URL: https://docs.datadoghq.com/tracing/trace_explorer/trace_view/
Accessed: 2026-06-18

**datadog-trace-explorer**
URL: https://docs.datadoghq.com/tracing/trace_explorer/
Accessed: 2026-06-18

**datadog-correlate**
URL: https://docs.datadoghq.com/tracing/other_telemetry/connect_logs_and_traces/
Accessed: 2026-06-18

**datadog-log-explorer**
URL: https://docs.datadoghq.com/logs/explorer/
Accessed: 2026-06-18

**sentry-breadcrumbs**
URL: https://docs.sentry.io/product/issues/issue-details/breadcrumbs/
Accessed: 2026-06-18

**sentry-issue-details**
URL: https://docs.sentry.io/product/issues/issue-details/
Accessed: 2026-06-18

**temporal-workflows**
URL: https://docs.temporal.io/workflows
Accessed: 2026-06-18

**temporal-events**
URL: https://docs.temporal.io/references/events
Accessed: 2026-06-18

**temporal-web-ui**
URL: https://docs.temporal.io/web-ui
Accessed: 2026-06-18

**gha-run-logs**
URL: https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows/monitoring-workflows/using-workflow-run-logs
Accessed: 2026-06-18

**gha-run-history**
URL: https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows/monitoring-workflows/viewing-workflow-run-history
Accessed: 2026-06-18

**gha-visualization**
URL: https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows/monitoring-workflows/using-the-visualization-graph
Accessed: 2026-06-18

**linear-activity**
URL: https://linear.app/docs/assigning-issues
Accessed: 2026-06-18
Quote: "the assignment and delegation history is tracked in its Activity feed, which shows changes over time and who made them"

**linear-collapsed-history**
URL: https://linear.app/changelog/2025-04-03-collapsed-issue-history
Accessed: 2026-06-18
Quote: "group[s] similar consecutive events and collapse[s] older activity between comment threads"

## SYNTHESIS

Seven convergent patterns govern good evidence-timeline UI. (P1) The timeline is reached from the subject, never as a top-level tab — Sentry breadcrumbs inside an issue, GitHub step logs inside a run, Temporal history inside an execution, Datadog spans inside a trace, Linear activity inside an issue. (P2) Correlation is by stable id and bidirectional — "the answer is a link," not evidence inline-pasted into a status sentence (Datadog logs↔traces, GitHub anchor URLs, Temporal event id refs). (P3) Rows are typed and compact, not free text — one structured row per event over a closed grammar (type/category, actor, object, status, time); density comes from a closed vocabulary + columns, and when volume grows Linear groups similar consecutive events rather than letting rows pile up. (P4) Scan first (collapsed/summary), expand on demand, raw JSON last — GitHub collapsed steps, Temporal expand-on-demand, Sentry/Datadog side panels, JSON as a secondary tab. (P5) A histogram/graph orients "when/where" before the list — Datadog's status-segmented time histogram, GitHub's live job DAG, Datadog's duration breakdown. (P6) Filters/facets share one query state that is the URL (shareable, restorable). (P7) Live and terminal use the same surface — a running run renders in the same component with a progress affordance on the active node, not a separate blank screen. A closed, strongly-typed event vocabulary is the linchpin: it makes rows scannable, filterable, testable, and exportable to OTel/Datadog, whereas free-text log lines can be none of these.
