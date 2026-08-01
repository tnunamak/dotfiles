---
title: "Products escape bounded relevance search two ways: a relevance-to-chronological sort switch within the search surface, and a browse-door into a specific container's full list; and present the bounded pool as a sortable/filterable object"
date: 2026-06-19
topic: data-explorer-ux
tags: [search-ux, sort-switch, browse-door, faceting, result-set-model, personal-archive]
status: draft
sources: [slack-search-messages, slack-engineering, notion-search, notion-api, gmail-sort, github-sort, stripe-activity-breakdown, algolia-refinement, glean-search, kibana-discover, weaviate-hybrid, hebbia, google-my-activity, datadog-explorer, rewind]
source_session: a9f44c73-fad1-46cd-ac52-9e7e2848c866
---

## CLAIMS

- Slack search.messages exposes `sort` = `score` (relevance, default) or `timestamp` (chronological), with `timestamp` mode cursor-paginated (cursormark `next_cursor`) — a shipped, mass-usage precedent for the relevance→chronological sort switch as the exhaustive path. [slack-search-messages][slack-engineering]
- Notion search offers Best Matches (relevance), Last Edited Newest/Oldest, and Created Newest/Oldest sort options within the search window, with API `next_cursor`/`has_more` pagination over date-sorted results; switching sort can surface records the relevance ranking omitted (the count can change). [notion-search][notion-api]
- Gmail ships a "Most relevant / Most recent" toggle on all platforms (Computer, Android, iPhone/iPad) documented in Google's official support page — a shipped, cross-platform sort switch (not a mobile-only test). [gmail-sort]
- GitHub search supports Relevance/Newest/Oldest/Recently-Updated sort within the search surface (`sort:created`/`updated`/`interactions`), but has no automated handoff from global search to a per-repo list — users navigate there manually. [github-sort]
- Stripe's Activity Breakdown is the canonical browse-door: a bounded summary total links in one click to the full filtered Payments list. [stripe-activity-breakdown]
- Algolia's primary recommendation for relevance overflow is post-query refinement (facets, filter chips), NOT a mode switch to a browsable sorted list — appropriate for a single bounded catalog rather than a cross-source federation. [algolia-refinement]
- Glean (closest personal/enterprise cross-app search peer) presents a bounded ranked pool with filter controls (app/date/person) and a Relevance/Date sort toggle, accepting the date-sort seam at the product level. [glean-search]
- Kibana Discover treats the query as a persistent state you filter, facet, and re-sort in place (bounded 10,000 window for relevance; `search_after`+PIT for exhaustive sorted access) — the engineering-native "result set as manipulable object." [kibana-discover]
- Weaviate hybrid search treats the fused result as a refineable object: `filters` reduce the candidate pool at query time, and a `boost` (time/numeric decay) rescores the fused pool without changing set membership. [weaviate-hybrid]
- Hebbia Matrix presents bounded semantic results (~100 docs per query) as a sortable/filterable table object (rows = documents, columns = analyst questions) — the strongest enterprise instance of the result-set-as-object model. [hebbia]
- Google My Activity presents personal data as a filterable time-ordered log (by product, by date range) with no relevance ranking — the precedent for the exhaustive chronological escape/browse dimension. [google-my-activity]
- Datadog Log Explorer is the engineering gold standard for "result set as manipulable object": query once, then facet/group/switch-view/adjust-time-window within the same result context; the "expand time window" is the exhaustion escape hatch. [datadog-explorer]
- Rewind AI / screenpipe (personal screen/audio archive) offers AI semantic search plus chronological timeline browsing — "search to find, then navigate the timeline for surrounding context" — validating that for personal-archive products the completeness bar is met by a chronological browse, not by deep relevance pagination. [rewind]

## SOURCES

**slack-search-messages**
URL: https://api.slack.com/methods/search.messages
Accessed: 2026-06-19
Quote: "sort: Return matches sorted by either score or timestamp. Default: score. cursor: Use this... send the value of next_cursor returned in the previous call's results."

**slack-engineering**
URL: https://slack.engineering/search-at-slack/
Accessed: 2026-06-19
Quote: "Recent search finds messages matching all terms in reverse chronological order; Relevant search relaxes the age constraint and uses the Lucene score."

**notion-search**
URL: https://www.notion.com/help/search
Accessed: 2026-06-19
Quote: "You can sort by: Best Matches (default), Last Edited: Newest First, Last Edited: Oldest First, Created: Newest First, Created: Oldest First."

**notion-api**
URL: https://developers.notion.com/reference/post-search
Accessed: 2026-06-19
Quote: "sort.timestamp accepts last_edited_time or created_time; the response includes next_cursor and has_more."

**gmail-sort**
URL: https://support.google.com/mail/answer/6593
Accessed: 2026-06-19
Quote: "Tip: To sort emails in chronological order, above the search results, click Most relevant then Most recent."

**github-sort**
URL: https://docs.github.com/en/search-github/getting-started-with-searching-on-github/sorting-search-results
Accessed: 2026-06-19
Quote: "You can sort by relevance, newest, oldest, or most recently updated."

**stripe-activity-breakdown**
URL: https://docs.stripe.com/reports/activity-breakdown
Accessed: 2026-06-19
Quote: "Click a total to drill into the underlying filtered Payments list."

**algolia-refinement**
URL: https://medium.com/design-bootcamp/post-query-refinement-suggestions-in-search-ux-and-an-algolia-demo-app-502eb9aa2fbd
Accessed: 2026-06-19
Quote: "Algolia's recommended response to unmet queries is post-query refinement with facet chips, not deeper pagination."

**glean-search**
URL: https://glean.com/product/search
Accessed: 2026-06-19
Quote: "Bounded ranked results with filter controls (app, date, person) and a Sort by Relevance/Date toggle."

**kibana-discover**
URL: https://www.elastic.co/guide/en/kibana/current/discover.html
Accessed: 2026-06-19
Quote: "Search and filter documents, analyze field structures... and save findings; adjust filters, time ranges, and sort within the result."

**weaviate-hybrid**
URL: https://weaviate.io/developers/weaviate/search/hybrid
Accessed: 2026-06-19
Quote: "To narrow your search results, use a filter... a boost parameter rescores the fused candidate pool."

**hebbia**
URL: https://www.hebbia.com/
Accessed: 2026-06-19
Quote: "Matrix presents semantic results in a sortable/filterable table capped near 100 documents per query."

**google-my-activity**
URL: https://support.google.com/myaccount/answer/3118687
Accessed: 2026-06-19
Quote: "My Activity is a filterable chronological log of your personal data by product and date range."

**datadog-explorer**
URL: https://docs.datadoghq.com/logs/explorer/
Accessed: 2026-06-19
Quote: "Run a query, then facet, group, switch views, and adjust the time range within the same result context."

**rewind**
URL: https://skywork.ai/skypage/en/Rewind-AI-&-Limitless:-The-Ultimate-Guide-to-Your-Digital-Memory/1976181260991655936
Accessed: 2026-06-19
Quote: "Search for something, find relevant hits, then navigate the timeline for surrounding context."

## SYNTHESIS

There are TWO distinct, complementary escapes from a bounded relevance result, and products
ship them separately: (a) the SORT SWITCH — relevance→chronological within the same search
surface, over the same query, where the chronological mode is exhaustively cursor-paginated
(Slack sort=timestamp, Notion Last-Edited, Gmail Most-recent, GitHub Newest, Elasticsearch
switch-to-sorted-field); and (b) the BROWSE DOOR — a bounded summary/preview linking to a
specific container's full paginated list (Stripe Activity Breakdown, Notion dashboard widget →
database). The sort switch is more broadly implemented; the browse-door is favored when the
result set is heterogeneous or multi-entity. For personal-archive products (Gmail, Rewind,
My Activity) completeness is the real bar, so the chronological exhaustion path is essential —
catalog-search "fix your query" refinement (Algolia, Meilisearch) is insufficient there.
Independently, several products model the bounded result itself as a SORTABLE/FILTERABLE OBJECT
rather than a paginated stream (Airtable Deep Match "Top 20," Glean, Kibana Discover, Datadog
Log Explorer, Weaviate fused-pool, Hebbia table): the same bounded pool, re-orderable in place
and faceted, with an explicit clearly-labeled mode switch to the exhaustive chronological
surface as the escape hatch. A "Most Recent" toggle that silently swaps the pool from semantic
to lexical (changing the count) is the wrong implementation — the seam must be labeled as a
distinct mode, which is what Slack/Gmail/Notion do.
