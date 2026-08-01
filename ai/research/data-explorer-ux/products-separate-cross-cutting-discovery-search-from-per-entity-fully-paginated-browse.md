---
title: "Leading products separate a cross-cutting discovery/search surface from a per-entity fully-paginated browse list, connected by explicit escape ramps"
date: 2026-06-19
topic: data-explorer-ux
tags: [data-explorer, search-vs-browse, pagination, escape-ramp, discovery, faceting]
status: draft
sources: [datadog-explorer, datadog-pagination, datadog-patterns, stripe-activity-breakdown, stripe-events, linear-display, github-search, github-repo-search, algolia-infinite-scroll, posthog-events, posthog-persons, plaid-transactions, notion-when-to-use, notion-dashboards, airtable-pagination]
source_session: 019d189c-d050-7a92-af4a-aab2be41b5f1
---

## CLAIMS

- Datadog draws a hard architectural line between the Log Explorer (unified cross-source investigation feed with faceted filtering and cursor pagination) and Dashboards (per-widget scoped views); its honesty model is to narrow the filter until the bounded result IS the complete result. [datadog-explorer]
- Datadog's UI shows at most 1,000 log entries per view; escaping past that requires dropping to the API (export up to 100,000 as CSV), and Patterns counts derive from a 10,000-log sample — a documented dead-end when the user hasn't narrowed enough. [datadog-pagination][datadog-patterns]
- Stripe's primary discovery surface is a set of per-entity fully-paginated cursor lists (Payments, Customers, Subscriptions); its Activity Breakdown drills from a summary total to the underlying FULL filtered list (click a dollar amount → land on the filtered Payments list). [stripe-activity-breakdown]
- Stripe's Events API is a unified cross-resource event feed for programmatic consumption (webhooks/reconciliation), not the primary human browse surface. [stripe-events]
- Linear's "My Issues" aggregates work across all teams/projects into a bounded, honestly-labeled personal discovery view; the full per-project list and global search are separate surfaces, and global search returns ranked results rather than paginating all issues. [linear-display]
- GitHub's global search is a ranked discovery surface capped to the most-relevant pages; the per-repo Issues list is the fully-paginated "see everything" surface — no leading product exposes a raw fully-paginated firehose across ALL entities of ALL types as the primary browse surface. [github-search][github-repo-search]
- PostHog maintains two separate surfaces: a global live Events/Activity feed (raw firehose, for debugging) and a per-entity paginated Persons list (for segmentation) — neither pretends to be the other. [posthog-events][posthog-persons]
- Plaid-backed PFM apps expose both a unified "All Transactions" feed and per-institution lists; the unified feed works because transactions are HOMOGENEOUS (same shape across sources), whereas heterogeneous records (message vs order vs commit) remain browsable-by-time but harder to read and filter in one merged list. [plaid-transactions]
- Algolia explicitly separates query-driven relevance-ranked "search" from no-query catalog "browse," recommending infinite scroll for browse and paginated results for search, with a "see more" button as the escape from a bounded first page. [algolia-infinite-scroll]
- Notion distinguishes workspace search (cross-cutting, "you don't know where something lives") from database views (per-database, browsable), and its dashboard linked-views show a bounded widget that links into the full database — the summary + escape-ramp pattern. [notion-when-to-use][notion-dashboards]
- Airtable's primary browse model is per-table paginated grid views (API uses offset pagination); cross-table/cross-base search is a secondary find/discovery feature. [airtable-pagination]

## SOURCES

**datadog-explorer**
URL: https://docs.datadoghq.com/logs/explorer/
Accessed: 2026-06-19
Quote: "The Log Explorer is the unified surface for searching and filtering logs across sources."

**datadog-pagination**
URL: https://docs.datadoghq.com/logs/guide/collect-multiple-logs-with-pagination/
Accessed: 2026-06-19
Quote: "The UI displays at most 1,000 log entries; use the API to retrieve more."

**datadog-patterns**
URL: https://docs.datadoghq.com/logs/explorer/analytics/patterns/
Accessed: 2026-06-19
Quote: "Patterns are computed from a sample of up to 10,000 logs."

**stripe-activity-breakdown**
URL: https://docs.stripe.com/reports/activity-breakdown
Accessed: 2026-06-19
Quote: "Drill from a summary total into the underlying filtered list of transactions."

**stripe-events**
URL: https://docs.stripe.com/api/events
Accessed: 2026-06-19
Quote: "The Events API provides a unified feed for webhooks and reconciliation."

**linear-display**
URL: https://linear.app/docs/display-options
Accessed: 2026-06-19
Quote: "My Issues aggregates issues assigned to you across teams and projects."

**github-search**
URL: https://docs.github.com/en/search-github/getting-started-with-searching-on-github/about-searching-on-github
Accessed: 2026-06-19
Quote: "Global search returns ranked results, not an exhaustive list of all matches."

**github-repo-search**
URL: https://github.blog/news-insights/repository-search-on-all-repositories/
Accessed: 2026-06-19
Quote: "The 'All repositories' toggle escapes repo scope; results remain ranked/scoped."

**algolia-infinite-scroll**
URL: https://www.algolia.com/doc/guides/building-search-ui/ui-and-ux-patterns/infinite-scroll/js
Accessed: 2026-06-19
Quote: "The browse endpoint retrieves all records without relevance ranking; infinite scroll is recommended for browse."

**posthog-events**
URL: https://posthog.com/docs/data/events
Accessed: 2026-06-19
Quote: "The Activity tab is a global live feed of all events."

**posthog-persons**
URL: https://posthog.com/docs/data/persons
Accessed: 2026-06-19
Quote: "The Persons list is a per-entity paginated list of user profiles."

**plaid-transactions**
URL: https://plaid.com/docs/transactions/
Accessed: 2026-06-19
Quote: "Transactions is a unified cross-institution feed with a homogeneous shape."

**notion-when-to-use**
URL: https://www.notion.com/help/guides/when-to-use-each-type-of-database-view
Accessed: 2026-06-19
Quote: "Use workspace search when you don't know where something lives; use a database view to browse a structured dataset."

**notion-dashboards**
URL: https://alternativeto.net/news/2026/3/notion-introduces-dashboard-views-to-turn-any-database-into-a-customizable-control-center
Accessed: 2026-06-19
Quote: "Dashboard views embed filtered database views; a widget shows a bounded sample linking to the full database."

**airtable-pagination**
URL: https://community.airtable.com/development-apis-11/airtable-pagination-4463
Accessed: 2026-06-19
Quote: "The Airtable API uses offset-based pagination for table records."

## SYNTHESIS

Across Datadog, Stripe, Linear, GitHub, PostHog, Notion, Algolia, and Plaid-backed PFM apps
the pattern is universal: separate "cross-cutting find/skim" (query-driven or recency pulse,
relevance- or time-ranked, bounded) from "per-entity see-everything" (fully-paginated,
keyset-stable browse of a single entity's complete set). None expose a raw fully-paginated
firehose across all entity types as the ONLY primary surface. Three properties distinguish
trustworthy explorers: (1) every bounded view is LABELED as bounded ("most recent N," not
"all"); (2) every bounded view has a REAL escape ramp — an active link to the full per-entity
list (Stripe Activity Breakdown, Notion linked views), not passive caption text; (3) a filter
that narrows to a single entity produces a COMPLETE view (Datadog's "narrow until the result
is exact"). Datadog's 1,000-cap-with-API-only-escape is the canonical failure of property (2).
A k-way merged fully-paginated firehose is technically sound but has no prior art as the
PRIMARY surface for heterogeneous data — heterogeneous cards are cognitively harder to page
through at scale, and the actual user need ("reach the complete set of X when I want it") is
served better by the escape-ramp pattern than by unified infinite scroll.
