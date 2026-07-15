---
title: "Brush-to-filter histograms write the EXISTING time control (not a parallel range) and their bars must reconcile with the list count and name their counting rule"
date: 2026-06-23
topic: data-explorer-ux
tags: [histograms, brushing, filters, accessibility, d3-brush, grafana, datadog, honesty]
status: draft
sources: [grafana-full-range-volume, grafana-logs-explore, datadog-log-explorer, stripe-workbench, sentry-issues, github-insights, observable-brushing, d3-brush, uswds-time-picker]
---

<!-- Extracted from a pdpp over-time-chart UX doc; pdpp code refs and internal LENS/gate framing discarded. -->

## CLAIMS

- Grafana Explore places the volume graph directly above the log-line list, driven by one query; clicking and dragging on the histogram zooms into a range by updating the EXISTING time picker and re-running the query — the brush writes into the existing time control, not a parallel range object. [grafana-full-range-volume]
- Grafana auto-derives the bucket interval from the span and snaps it to friendly units (1 minute, 1 hour, 1 day), never arbitrary widths, and anchors the histogram start to the first result row's timestamp and the end to the time picker's To range. [grafana-full-range-volume]
- Grafana makes bar-vs-window staleness explicit: zooming does not trigger a new query, and a "Reload log volume" button recomputes buckets at the new resolution — it never silently implies old bars describe the new window. [grafana-full-range-volume]
- Grafana stacks sub-series only from a reliable signal: it uses the `level` label if present, else parses, else renders "unknown" — it does not invent a level. [grafana-logs-explore]
- Datadog Log Explorer renders the list and a timeseries as two visualizations of the same filtered set; drag-on-graph zooms the single global time frame (preset list + calendar picker), so the graph drag and the picker write the same window. [datadog-log-explorer]
- Stripe Workbench Logs keeps the filtered LIST as the primary affordance with the over-time view a calm secondary timeline, and surfaces explicit retention bounds rather than implying infinite history. [stripe-workbench]
- Sentry's per-issue frequency sparkline is a named anti-pattern: users repeatedly report the chart's bar counts not reconciling with the count shown beside it (a trust break), and a related bug where changing the bar-chart interval doesn't re-bucket. [sentry-issues]
- GitHub Insights contributor/commit graphs apply hidden counting rules (merge/empty commits excluded, weekly commits summed onto Sunday, unavailable >10,000 commits) that make the bars not mean what a naive reader assumes — a "lies by omission" anti-pattern. [github-insights]
- Brushing is the right tool for continuous selection ("when you don't want to limit a user to a pre-defined category/region"); for pre-defined categories a single click/select beats a drag. [observable-brushing]
- A brush must NEVER be the only way to select a range: it must be paired with a keyboard/touch form input for start/end, a text/tabular equivalent, descriptive alt text, and focusable arrow-key-adjustable handles. [uswds-time-picker]

## SOURCES

**grafana-full-range-volume**
URL: https://grafana.com/blog/2022/03/02/new-in-grafana-8.4-how-to-use-full-range-log-volume-histograms-with-grafana-loki/
Accessed: 2026-06-23
Quote: "Click and drag on the histogram to zoom into a specific time range… Grafana will then update the time picker and re-run the query for that narrower selection."

**grafana-logs-explore**
URL: https://grafana.com/docs/grafana/latest/visualizations/explore/logs-integration/
Accessed: 2026-06-23

**datadog-log-explorer**
URL: https://docs.datadoghq.com/logs/explorer/
Accessed: 2026-06-23

**stripe-workbench**
URL: https://docs.stripe.com/workbench/overview
Accessed: 2026-06-23

**sentry-issues**
URL: https://github.com/getsentry/sentry/issues/48625
Accessed: 2026-06-23
Quote: users report "the amount of events be consistent with the time frame shown in the graphs"

**github-insights**
URL: https://docs.github.com/en/repositories/viewing-activity-and-data-for-your-repository/viewing-a-projects-contributors
Accessed: 2026-06-23

**observable-brushing**
URL: https://observablehq.com/blog/linked-brushing
Accessed: 2026-06-23

**d3-brush**
URL: https://d3js.org/d3-brush
Accessed: 2026-06-23

**uswds-time-picker**
URL: https://designsystem.digital.gov/components/time-picker/accessibility-tests/
Accessed: 2026-06-23

## SYNTHESIS

The canonical pattern (Grafana's "volume band above the list") is a quiet full-width bar strip directly above the feed whose bars are records-per-bucket of the SAME filtered set the list shows. Four reusable invariants: (1) a brush writes the EXISTING `(since, until)` control, never a parallel range object (Grafana + Datadog both do this); (2) bars must come from the true filtered totals (a server aggregate), NOT from loaded/capped rows — counting only the loaded window is the Sentry-class reconciliation lie; (3) the counting rule must be legible on the chart (kind label + per-bar tooltip), defeating the GitHub-Insights silent-rule failure; (4) the brush is an enhancement layered on a keyboard/touch date control, never the only path (the a11y floor), and single-click-a-bar is supported because brushing is the wrong tool for one pre-defined bucket. The overarching honesty principle across Grafana/Sentry: a bar must describe the set it claims to describe.
