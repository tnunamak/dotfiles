---
title: "Time-bucket volume histograms bucket server-side (indexed GROUP BY / rollups), auto-fit the resting domain to populated extent, and pick adaptive granularity snapped to a calendar ladder"
date: 2026-06-23
topic: data-explorer-ux
tags: [histograms, time-series, postgres, brin, timescaledb, elasticsearch, d3, grafana, performance]
status: draft
sources: [crunchy-brin, crunchy-time-bins, timescale-caggs, es-auto-date-histogram, es-date-histogram, es-empty-buckets, d3-time-ticks, grafana-interval, grafana-full-range-volume, stripe-retention, datadog-log-explorer]
source_session: 41ab3da7-be0a-46bc-8e60-06f5e655268f
---

<!-- Extracted from a pdpp over-time-chart performance doc; pdpp verdicts/code discarded. -->

## CLAIMS

- The convergent scaling answer is to never bucket raw rows in the client: push `GROUP BY <time_bucket>` into the datastore (served by a time-range index or a pre-aggregated rollup) and return only the ~N tiny bucket rows. [crunchy-time-bins]
- A BRIN index on the timestamp column suits append-only, naturally time-ordered event data: it summarizes block ranges (min/max per page range), is ~1/100th the size of a B-tree, drives a Bitmap Index Scan that skips blocks outside the date filter, and matched B-tree on a `date_trunc` hourly aggregation while using >99% less space (tested to 100M rows); it degrades on out-of-order inserts/updates and is wrong for point lookups. [crunchy-brin]
- Postgres can parallelize the aggregation; a parallel seq-scan sometimes beat the indexed scan when the range covered most of the table. [crunchy-time-bins]
- TimescaleDB continuous aggregates are incrementally-maintained materialized views over `time_bucket(...), count(*)`; a 7-day dashboard over a 400M-row hypertable dropped from 14s to a few thousand pre-aggregated points, with the biggest lever being bucket width matching dashboard resolution and counts being cleanly composable into hierarchical (hourly→daily `SUM`) rollups. [timescale-caggs]
- Elasticsearch date histograms are intrinsically cheap because dates are stored as epoch-ms `long` and bucket assignment is integer arithmetic; the dominant cost is the number of buckets returned, so "avoid bucket explosion" is the headline optimization. [es-date-histogram]
- Elasticsearch `auto_date_histogram` takes a target `buckets` count (default 10) and snaps the interval to a fixed ladder — seconds ×{1,5,10,30}, minutes ×{1,5,10,30}, hours ×{1,3,12}, days ×{1,7}, months ×{1,3}, years ×{1,5,10,20,50,100} — with a `minimum_interval` floor; the day→7-day→month jump means daily overflow yields ~1/7th of the requested count. [es-auto-date-histogram]
- d3-time `scale.ticks(count)` computes `target = span/count` and picks the ladder candidate geometrically closest to the target so ticks land on human boundaries (midnights, month starts); count is a hint, default 10. [d3-time-ticks]
- Grafana's `$__interval` is computed per-render as time-range ÷ panel pixel width so bucket count stays in a readable band; `$__timeGroup(col, $__interval)` does the server-side bucketing. [grafana-interval]
- Grafana's full-range log-volume histogram anchors the domain start to the first matching row's timestamp and the end to "now" (fits the domain to where data exists rather than a fixed calendar window). [grafana-full-range-volume]
- Elasticsearch zero-fills only on request: `min_doc_count: 0` fills interior gaps and `extended_bounds {min,max}` extends zero buckets to the chart edges (does not filter — use a range filter/`hard_bounds` to restrict). [es-empty-buckets]
- GitHub's contribution graph is a cautionary color-bucketing counter-pattern: green levels are adaptive quartiles of non-zero days (an undocumented silent rule), so the same commit count looks different across users. [es-empty-buckets]
- Observability tools default to a recent trailing window (Datadog "last 15 minutes"; Stripe reports default to the prior month and keep a trailing retention window — 13 months live, full detail only ~30 days), avoiding the empty-desert problem by never showing decades by default. [datadog-log-explorer]

## SOURCES

**crunchy-brin**
URL: https://www.crunchydata.com/blog/postgresql-brin-indexes-big-data-performance-with-minimal-storage
Accessed: 2026-06-23

**crunchy-time-bins**
URL: https://www.crunchydata.com/blog/easy-postgresql-time-bins
Accessed: 2026-06-23

**timescale-caggs**
URL: https://dev.to/philip_mcclarence_2ef9475/optimizing-continuous-aggregate-performance-for-large-datasets-39mj
Accessed: 2026-06-23

**es-auto-date-histogram**
URL: https://www.elastic.co/docs/reference/aggregations/search-aggregations-bucket-autodatehistogram-aggregation
Accessed: 2026-06-23

**es-date-histogram**
URL: https://www.elastic.co/docs/reference/aggregations/search-aggregations-bucket-datehistogram-aggregation
Accessed: 2026-06-23

**es-empty-buckets**
URL: https://seanmcgary.com/posts/elasticsearch-date-histogram-aggregation---filling-in-the-empty-buckets
Accessed: 2026-06-23

**d3-time-ticks**
URL: https://github.com/d3/d3-time/blob/main/src/ticks.js
Accessed: 2026-06-23

**grafana-interval**
URL: https://codesignal.com/learn/courses/getting-started-with-grafana-using-postgres-demo-metrics/lessons/time-bucketing-in-grafana
Accessed: 2026-06-23

**grafana-full-range-volume**
URL: https://grafana.com/blog/2022/03/02/new-in-grafana-8.4-how-to-use-full-range-log-volume-histograms-with-grafana-loki/
Accessed: 2026-06-23

**stripe-retention**
URL: https://support.stripe.com/questions/stripe-event-retention-period
Accessed: 2026-06-23

**datadog-log-explorer**
URL: https://docs.datadoghq.com/logs/explorer/
Accessed: 2026-06-23

## SYNTHESIS

For a records-per-time-bucket chart at scale (0 → millions of rows), the phased answer is: (1) baseline = one index-backed server `GROUP BY date_trunc(<unit>, ts)` endpoint (BRIN on the timestamp for append-only streams, else a `(entity_id, ts)` B-tree) returning ~30–60 `{bucket, count}` rows — this replaces client-side full-table scans with zero new infrastructure; (2) scale ceiling, built only when proven needed = a per-entity day-bucket rollup / continuous aggregate that coarser views `SUM()` up from (counts compose). Resting domain (no filter) should auto-fit to the populated extent (`min(ts) … now`, Grafana-style), then let granularity coarsen so a decades-long corpus renders as a calm ~30–60 dense bars, not a sparse day desert. Granularity = `span / target` snapped to a calendar ladder (matching ES `auto_date_histogram`, d3-time, Grafana `$__interval`), always captioned with the active unit ("· by week") so the bucketing is never a silent rule. Zero-fill within the chosen window (`generate_series` LEFT JOIN counts) so gaps mean real silence — never collapse-to-dense (which lies about cadence) and never encode meaning in a hidden statistical rule (the GitHub-quartile mistake). The chart is off the first-paint critical path: stream the list first, fetch the aggregate as a separate deferred request.
