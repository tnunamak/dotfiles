---
title: "Bounded discovery feeds pair a preview with a one-click 'See all N' escape ramp to a fully-paginated list; cross-source search ranks globally, never with per-source quotas"
date: 2026-06-19
topic: data-explorer-ux
tags: [search-ux, pagination, escape-ramp, global-ranking, faceted-search, stripe, notion]
status: draft
sources: [stripe-activity-breakdown, notion-db-views, notion-search, linear-display-options, github-search, datadog-pagination, algolia-pagination, algolia-infinite-scroll, elasticsearch-pagination, linear-pagination, slack-pagination]
source_session: 019db87f-3c01-7b80-9802-b7a53e9031de
---

<!-- Extracted from a pdpp spec-validation doc; internal corpus citations and pdpp code refs discarded, external-URL-backed patterns kept. -->

## CLAIMS

- Stripe's Activity Breakdown links every bounded summary/aggregate row to the full cursor-paginated list for the matching entity (click a dollar total → land on a filtered Payments list of every contributing transaction); the architecture separates bounded "summary/discovery" from the fully-paginated per-entity list (keyset via `starting_after`). [stripe-activity-breakdown]
- Notion's dashboard views (2026) embed bounded filtered database views as widgets, each linking out to the full underlying database; the same split appears in workspace search (bounded "best matches" → the full page/database one click away). [notion-db-views]
- Linear's cross-project "My Issues" view is bounded to your issues; the exhaustive destinations are the per-project/per-team lists, and the scoped view labels its scope explicitly. [linear-display-options]
- Datadog's Log Explorer is capped at 1,000 entries in a single view with no inline "See all" path beyond the cap (the escape is dropping to the API or CSV export, not surfaced inline) — the named dead-end anti-pattern. [datadog-pagination]
- Algolia separates "search" (relevance-ranked bounded top-N) from "browse" (catalog exploration, no query, full scan), recommending a "see more"/"show all" button that expands a bounded first page to the full set. [algolia-infinite-scroll]
- Algolia's core ranking is a single global ranking across the index; multi-index federation is done with independent `multipleQueries` merged by relevance score client-side, and the recommended federated-search UX merges by global relevance, not per-index quota. [algolia-pagination]
- Elasticsearch queries over a multi-index pattern (`GET /logs-*/_search`) return a global top-K by score (BM25/RRF computed across all shards/indices); per-shard truncation exists for efficiency but the final merge is global, not a per-index quota. [elasticsearch-pagination]
- Linear, GitHub, Slack, and Notion search all rank globally with no per-team/per-repo/per-channel/per-database quota; where GitHub groups by type tabs or Slack groups by channel, the grouping is a presentation layer while ranking within each group stays global. [github-search]

## SOURCES

**stripe-activity-breakdown**
URL: https://docs.stripe.com/reports/activity-breakdown
Accessed: 2026-06-19

**notion-db-views**
URL: https://www.notion.com/help/guides/when-to-use-each-type-of-database-view
Accessed: 2026-06-19

**notion-search**
URL: https://www.notion.com/help/search
Accessed: 2026-06-19

**linear-display-options**
URL: https://linear.app/docs/display-options
Accessed: 2026-06-19

**github-search**
URL: https://docs.github.com/en/search-github
Accessed: 2026-06-19

**datadog-pagination**
URL: https://docs.datadoghq.com/logs/guide/collect-multiple-logs-with-pagination/
Accessed: 2026-06-19

**algolia-pagination**
URL: https://www.algolia.com/doc/guides/building-search-ui/ui-and-ux-patterns/pagination/js
Accessed: 2026-06-19

**algolia-infinite-scroll**
URL: https://www.algolia.com/doc/guides/building-search-ui/ui-and-ux-patterns/infinite-scroll/js
Accessed: 2026-06-19

**elasticsearch-pagination**
URL: https://www.elastic.co/docs/reference/elasticsearch/rest-apis/paginate-search-results
Accessed: 2026-06-19

**linear-pagination**
URL: https://linear.app/developers/pagination
Accessed: 2026-06-19

**slack-pagination**
URL: https://slack.engineering/evolving-api-pagination-at-slack/
Accessed: 2026-06-19

## SYNTHESIS

Two reusable patterns, each with a named anti-pattern. (A) A discovery/preview feed must never dead-end: every bounded slice shows the exact full count and a one-click "See all N in <entity>" link to a fully-paginated per-entity list. Stripe (Activity Breakdown → full Payments list) and Notion (dashboard widget → full database) are the strongest precedents; the Datadog 1,000-cap with no inline exit is the canonical dead-end anti-pattern. (B) Cross-source search issues ONE global call and returns a globally-ranked best-matches-anywhere list; it does NOT union each source's top-few under per-source quotas (which buries the globally best hit from a high-volume source — searching "overdraft" where all 12 best hits are one source, but a quota returns only 3). The critical distinction: grouping a global ranking by type/source for scannability (GitHub tabs, Slack channels) is fine; a per-source QUOTA that distorts ranking is the anti-pattern used by no leading search product.
