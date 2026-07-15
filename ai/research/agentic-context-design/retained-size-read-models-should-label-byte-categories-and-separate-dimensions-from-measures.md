---
title: "Storage/retained-size introspection prior art: label distinct byte categories rather than one opaque total, separate qualitative dimensions from quantitative measures, and preserve drill-through from a number to its composing records"
date: 2026-05-22
topic: agentic-context-design
tags: [read-models, materialized-views, storage-introspection, facets-measures, drill-through, data-explorer]
status: draft
sources: [pg-matviews, bigquery-table-storage, datadog-facets-measures, kibana-field-stats, metabase-drill-through]
---

## CLAIMS

- PostgreSQL materialized views persist derived query results and are refreshed from source tables, but a plain refresh replaces the contents by re-running the backing query — so for hot read paths an explicit incremental projection plus bounded rebuild/reconcile is preferable to blanket refresh. [pg-matviews]
- BigQuery `INFORMATION_SCHEMA.TABLE_STORAGE` distinguishes a current snapshot of storage usage from billing-over-time and breaks out byte categories such as active, long-term, time-travel, physical, and logical bytes — i.e. it labels byte categories rather than presenting one opaque total. [bigquery-table-storage]
- Datadog separates facets (qualitative dimensions) from measures (quantitative values) and attaches units such as bytes to measures. [datadog-facets-measures]
- Elastic/Kibana Discover shows field-level statistics — top values, distributions, cardinality, and examples — before a user builds visualizations, giving an "understand this slice" mode. [kibana-field-stats]
- Metabase drill-through preserves the interaction of clicking a number or chart segment and then zooming in, viewing the composing records, breaking out by a dimension, or auto-explaining the slice. [metabase-drill-through]

## SOURCES

**pg-matviews**
URL: (uncited in source — PostgreSQL materialized views documentation referenced generically)
Accessed: 2026-05-22

**bigquery-table-storage**
URL: (uncited in source — BigQuery INFORMATION_SCHEMA.TABLE_STORAGE referenced generically)
Accessed: 2026-05-22

**datadog-facets-measures**
URL: (uncited in source — Datadog facets/measures referenced generically)
Accessed: 2026-05-22

**kibana-field-stats**
URL: (uncited in source — Elastic/Kibana Discover field statistics referenced generically)
Accessed: 2026-05-22

**metabase-drill-through**
URL: (uncited in source — Metabase drill-through referenced generically)
Accessed: 2026-05-22

## SYNTHESIS

Note: the originating design note named these products and their behaviors but did not include source URLs; the claims above are transcribed from that note and should be re-verified against the vendors' current docs before being treated as settled. The reusable pattern for a size/storage introspection read model: (1) do not present one opaque total — label distinct byte categories (current vs history vs blob, analogous to BigQuery's active/long-term/time-travel split); (2) model size as a typed measure and the things you can slice by (connection, stream, source kind) as dimensions, à la Datadog; (3) keep drill dimensions finite and system/manifest-authored rather than arbitrary JSON paths, to avoid an accidental generic BI engine; (4) preserve drill-through from any number to the records/blobs behind it (Metabase); and (5) make field-level exploration (sampling, cardinality, top values — Kibana Discover) a separate later capability with its own privacy decisions, not smuggled into the size projection. For freshness honesty, report projection state/timestamp per aggregate family that can be stale, and prefer incremental projection + bounded rebuild over full materialized-view refresh on hot paths.
