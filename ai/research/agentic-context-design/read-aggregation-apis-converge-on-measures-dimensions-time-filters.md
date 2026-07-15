---
title: "Read/aggregation APIs across the industry converge on the same primitive vocabulary: measures, dimensions, time+granularity, filters, limit/order, optional total"
date: 2026-05-28
topic: agentic-context-design
tags: [aggregation, olap, pagination, faceted-search, mcp, token-efficiency, api-design]
status: draft
sources: [elastic, opensearch, stripe-pagination, stripe-sigma, github-pagination, linear-pagination, relay-connections, slack-search, snowflake-datetrunc, snowflake-widthbucket, oracle-rollup, mssql-groupby, algolia-facets, algolia-disjunctive, cube-query, ga-runreport, metabase-mbql, mcp-token-mindstudio, mcp-token-newstack, mcp-token-pydantic]
---

## CLAIMS

- Elasticsearch/OpenSearch `terms` aggregation exposes `field`, `size` (default 10 — this is top-N), `order` (`_count`/`_key`), `missing` (names a bucket for the absent-field case, only with `min_doc_count: 0`), and `min_doc_count` (default 1); counts can be approximate on sharded data. [elastic]
- Elasticsearch `date_histogram` distinguishes `calendar_interval` (DST/calendar-aware, single quantity: minute|hour|day|week|month|quarter|year) from `fixed_interval` (constant SI multiples); `time_zone` shifts bucket boundaries; `min_doc_count: 0` + `extended_bounds` produces a gap-free zero-filled series. [elastic][opensearch]
- Elasticsearch `cardinality` is HyperLogLog++ approximate distinct with a `precision_threshold` that trades memory for accuracy; exact distinct requires enumerating every value. [elastic]
- Elasticsearch `composite` aggregation streams every bucket via an `after_key` cursor, but cannot sort by a metric and gives no upfront total. [elastic]
- Stripe's live API is list+cursor only (`limit`, `starting_after`, `ending_before`, `has_more`); no `total_count` unless opted in, and then accurate only to 10,000; it offers no aggregation on the live API — aggregation lives in the separate Sigma product (~3h lag, SQL-shaped). [stripe-pagination][stripe-sigma]
- GitHub search returns `{ total_count (capped at 1000), incomplete_results, items }`. [github-pagination]
- Relay-style GraphQL connections (GitHub/Linear/Shopify) use `first`/`after` + `pageInfo{hasNextPage,endCursor}` + optional `totalCount`. [relay-connections][linear-pagination]
- Slack's `paging.total` is estimated and the API is migrating to cursor-mark pagination. [slack-search]
- Total count is never guaranteed across mature systems: every one caps, estimates, or opts it in. [github-pagination][slack-search][relay-connections]
- SQL `date_trunc(unit, ts)` canonical units are minute, hour, day, week, month, quarter, year. [snowflake-datetrunc]
- `COUNT(DISTINCT)` is exact distinct but is incompatible with CUBE/ROLLUP/GROUPING SETS. [mssql-groupby][oracle-rollup]
- `width_bucket` produces an equi-width numeric histogram; `percentile_cont` produces percentiles. [snowflake-widthbucket]
- Algolia faceted search takes `facets[]`, `facetFilters` (inner array OR, outer AND), `maxValuesPerFacet`, and returns `facets: { field: { value: count } }` alongside `hits`, plus `exhaustiveFacetsCount` (exact-vs-approximate flag). [algolia-facets]
- Algolia disjunctive faceting ("count as if this facet's own filter were not applied") is NOT in the API; the client library issues one extra query per disjunctive facet. [algolia-disjunctive]
- Cube.js query shape is `{ measures[], dimensions[], filters[{member,operator,values}], timeDimensions[{dimension,dateRange,granularity}], limit, offset, order, total }`; `timeDimensions` fuses time filter with time bucket, and omitting `granularity` makes it filter-only (no grouping). [cube-query]
- Google Analytics `runReport` shape is `{ dimensions[], metrics[], dateRanges[], dimensionFilter, metricFilter, orderBys, limit, keepEmptyRows }`. [ga-runreport]
- Metabase MBQL shape is `{ aggregation: [["count"],["distinct",f],["sum",f]], breakout: [...], filter: [...] }`. [metabase-mbql]
- For AI-agent-facing tools, dumping rows so the agent aggregates in-context costs tokens per row and pagination does not save an agent with a tool-call budget; the fix is server-side aggregation tools (e.g. `count_open_issues_by_priority` instead of `list_all_issues`), since server-side computation is ~free while in-context aggregation costs hundreds-to-thousands of tokens. [mcp-token-mindstudio][mcp-token-newstack][mcp-token-pydantic]

## SOURCES

**elastic**
URL: https://www.elastic.co/docs/reference/aggregations/search-aggregations-bucket-terms-aggregation ; https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-bucket-datehistogram-aggregation.html ; https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-metrics-cardinality-aggregation.html
Accessed: 2026-05-28

**opensearch**
URL: https://docs.opensearch.org/latest/aggregations/bucket/date-histogram/
Accessed: 2026-05-28

**stripe-pagination**
URL: https://docs.stripe.com/api/pagination
Accessed: 2026-05-28

**stripe-sigma**
URL: https://docs.stripe.com/data/how-sigma-works
Accessed: 2026-05-28

**github-pagination**
URL: https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api
Accessed: 2026-05-28

**linear-pagination**
URL: https://linear.app/developers/pagination
Accessed: 2026-05-28

**relay-connections**
URL: https://relay.dev/graphql/connections.htm
Accessed: 2026-05-28

**slack-search**
URL: https://api.slack.com/methods/search.messages
Accessed: 2026-05-28

**snowflake-datetrunc**
URL: https://docs.snowflake.com/en/sql-reference/functions/date_trunc
Accessed: 2026-05-28

**snowflake-widthbucket**
URL: https://docs.snowflake.com/en/sql-reference/functions/width_bucket
Accessed: 2026-05-28

**oracle-rollup**
URL: https://oracle-base.com/articles/misc/rollup-cube-grouping-functions-and-grouping-sets
Accessed: 2026-05-28

**mssql-groupby**
URL: https://learn.microsoft.com/en-us/sql/t-sql/queries/select-group-by-transact-sql
Accessed: 2026-05-28
Quote: "COUNT(DISTINCT) is incompatible with CUBE/ROLLUP/GROUPING SETS"

**algolia-facets**
URL: https://www.algolia.com/doc/guides/managing-results/refine-results/faceting
Accessed: 2026-05-28

**algolia-disjunctive**
URL: https://support.algolia.com/hc/en-us/articles/11923043923217
Accessed: 2026-05-28

**cube-query**
URL: https://cube.dev/docs/product/apis-integrations/rest-api/query-format
Accessed: 2026-05-28

**ga-runreport**
URL: https://developers.google.com/analytics/devguides/reporting/data/v1/rest/v1beta/properties/runReport
Accessed: 2026-05-28

**metabase-mbql**
URL: https://github.com/metabase/metabase/wiki/(Incomplete)-MBQL-Reference
Accessed: 2026-05-28

**mcp-token-mindstudio**
URL: https://www.mindstudio.ai/blog/optimize-mcp-server-token-usage
Accessed: 2026-05-28

**mcp-token-newstack**
URL: https://thenewstack.io/how-to-reduce-mcp-token-bloat/
Accessed: 2026-05-28

**mcp-token-pydantic**
URL: https://pydantic.dev/articles/engineering-mcp-tools-for-token-efficiency
Accessed: 2026-05-28

## SYNTHESIS

Every surveyed read/aggregation system converges on the same small set of orthogonal primitives: measures, dimensions, time+granularity, filters, limit/order, and an optional (often approximate) total. The durable, hard design decisions are semantic, not breadth: calendar-vs-fixed time buckets, whether/how to name the null/missing bucket, zero-fill, exact-vs-approximate distinct, and whether total is guaranteed. A single time-dimension construct with optional granularity (Cube.js) and a uniform `{field, op, values}` filter triple are the two most reusable steals. Features to defer as "advanced/separate mode": nested/sub-aggregations, CUBE/ROLLUP/GROUPING SETS (incompatible with COUNT(DISTINCT)), percentiles, composite/bucket pagination (adds cursor state, forbids metric sort, no total), disjunctive facet counts (N extra queries), and numeric-histogram `width_bucket` — each trades bounded response size for breadth. For an agent consumer specifically, server-side aggregation is a token-budget primitive, not an analytics nicety — the opposite of Stripe's live/Sigma split, and correct precisely because the consumer is context-bounded.
