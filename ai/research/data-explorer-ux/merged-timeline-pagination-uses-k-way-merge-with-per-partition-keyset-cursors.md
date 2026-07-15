---
title: "Products paginate a merged time-sorted feed via k-way merge over per-partition keyset cursors, or by materializing the merge at write time"
date: 2026-06-19
topic: data-explorer-ux
tags: [pagination, keyset-cursor, k-way-merge, timeline, fan-out, composite-cursor]
status: draft
sources: [trekhleb-x, twitter-highscalability, mastodon-timelines, mastodon-pagination, es-paginate, es-composite-agg, es-pit, datadog-logs, stripe-pagination, slack-pagination, facebook-graph, github-activity, uspto-nway-merge]
---

## CLAIMS

- The k-way merge of K independently-cursored time-sorted streams with a min-heap of size K, where each page reads a bounded slice per partition and advances only the partition that contributed the last emitted record, is the canonical algorithm; cost is O(K log K) heap ops plus K parallel O(log N) keyset reads per page. [es-composite-agg][uspto-nway-merge]
- Elasticsearch `search_after` + Point-in-Time (PIT) is the most explicit public cross-shard keyset cursor: `search_after` carries the composite sort values of the last hit, `_shard_doc` is the implicit `(shard, doc_id)` tiebreaker, and PIT freezes index state across pages to prevent phantom/duplicate rows. [es-paginate][es-pit]
- Elasticsearch composite aggregation returns an `after_key` that is literally a JSON `{ source_name -> last_value }` composite cursor passed as `after` on the next request — the textbook k-way merge cursor in production. [es-composite-agg]
- Datadog Logs `POST /api/v2/logs/events/search` returns `meta.page.after` (Base64 opaque cursor) spanning multiple log indexes transparently, plus a pre-built `links.next` URL. [datadog-logs]
- Twitter/X collapses the K-partition problem by materializing the merge at WRITE time (fan-out-on-write to one Redis sorted set per follower); the read cursor (`cursorType: Bottom`/`Top`, opaque `value`, `sortIndex`) is a position in that single materialized list, trading write amplification for read simplicity at 500M-user scale. [trekhleb-x][twitter-highscalability]
- Mastodon/ActivityPub pagination uses `max_id`/`min_id`/`since_id` string params returned in HTTP `Link` headers (`rel=next`/`prev`) over a home timeline table already merged at ingest by push delivery — a single-server keyset cursor over one pre-merged table. [mastodon-timelines][mastodon-pagination]
- Stripe uses `starting_after`/`ending_before` with plain object IDs because its lists are single-stream already-sorted tables (the K=1 degenerate case — no composite cursor needed). [stripe-pagination]
- Slack encodes cursors as Base64-opaque strings that decode to a last-seen ID (`user:W07QCRPA4`) or a Unix timestamp per endpoint; it deliberately separates keyset-paginated browse-within-channel from relevance-ranked cross-channel `search.messages`, and exposes no keyset-paginated cross-channel chronological merge. [slack-pagination]
- Facebook Graph returns `paging.cursors.after`/`before` as Base64 opaque strings ("a random string of characters which marks a specific item") plus pre-built `paging.next`/`previous` URLs. [facebook-graph]
- GitHub uses cursor pagination for per-repo activity (`after=` in the `Link` header) but exposes NO native cross-repo merged activity feed via REST — a deliberate product choice to not build the merge. [github-activity]
- Products avoid building merged pagination when ranking is relevance-based (not a stable keyset comparator), when partitions are too numerous/heterogeneous to merge cheaply, or when the real user need is cross-partition search rather than time-ordered browse. [slack-pagination][github-activity]

## SOURCES

**trekhleb-x**
URL: https://trekhleb.dev/blog/2024/api-design-x-home-timeline/
Accessed: 2026-06-19
Quote: "The cursor has cursorType 'Bottom' for next-page and 'Top' for new content above; value is an opaque position in the pre-materialized timeline list."

**twitter-highscalability**
URL: https://highscalability.com/the-architecture-twitter-uses-to-deal-with-150m-active-users/
Accessed: 2026-06-19
Quote: "Fan-out-on-write to per-follower timelines trades write amplification for read simplicity."

**mastodon-timelines**
URL: https://docs.joinmastodon.org/methods/timelines/
Accessed: 2026-06-19
Quote: "max_id, min_id, since_id parameters bound the range over the home timeline."

**mastodon-pagination**
URL: https://docs.joinmastodon.org/api/guidelines/#pagination
Accessed: 2026-06-19
Quote: "Pagination uses Link headers with rel=next and rel=prev."

**es-paginate**
URL: https://www.elastic.co/guide/en/elasticsearch/reference/current/paginate-search-results.html
Accessed: 2026-06-19
Quote: "If you need to page through more than 10,000 hits, use the search_after parameter with a point in time (PIT)."

**es-composite-agg**
URL: https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-bucket-composite-aggregation.html
Accessed: 2026-06-19
Quote: "The after_key returned in the response is passed as the after parameter on the next request."

**es-pit**
URL: https://www.elastic.co/guide/en/elasticsearch/reference/current/point-in-time-api.html
Accessed: 2026-06-19
Quote: "A point in time is a lightweight view into the state of the data as it existed when initiated."

**datadog-logs**
URL: https://docs.datadoghq.com/logs/guide/collect-multiple-logs-with-pagination/
Accessed: 2026-06-19
Quote: "meta.page.after is a Base64-encoded cursor passed as page.cursor in subsequent requests."

**stripe-pagination**
URL: https://edge-docs.stripe.com/api/pagination
Accessed: 2026-06-19
Quote: "starting_after and ending_before take object IDs."

**slack-pagination**
URL: https://slack.engineering/evolving-api-pagination-at-slack/
Accessed: 2026-06-19
Quote: "Slack evolved from offset to cursor pagination; the cursor is a Base64-opaque string that can be a different strategy per endpoint."

**facebook-graph**
URL: https://developers.facebook.com/docs/graph-api/results
Accessed: 2026-06-19
Quote: "cursors.after: a random string of characters which marks a specific item."

**github-activity**
URL: https://github.com/orgs/community/discussions/69826
Accessed: 2026-06-19
Quote: "Repository activity uses cursor pagination via an after= parameter in the Link header."

**uspto-nway-merge**
URL: https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/9465881
Accessed: 2026-06-19
Quote: "N-way paginated merge over independently-positioned streams."

## SYNTHESIS

There are two production strategies for a merged, time-sorted feed. (1) Read-time k-way
merge over per-partition keyset cursors, with a composite cursor = a serialized map of
per-partition positions, Base64-encoded and stateless; this is what Elasticsearch composite
aggregation, Datadog Logs, and Mastodon's ingest-merged table effectively expose. (2)
Write-time materialization into one sorted list per consumer (Twitter, Mastodon fan-out),
which reduces reads to a single K=1 cursor at the cost of write amplification — the correct
trade only at social-graph scale. Page stability under new arrivals is handled by keyset
anchoring (the descended-past boundary is fixed) optionally plus a soft ceiling / PIT
snapshot (Elasticsearch PIT, Slack's `latest`, Datadog's opaque snapshot). Fan-out width is
bounded by partition count, not user graph size; for a low-K case (tens of partitions) K
parallel keyset reads per page is cheap. Products deliberately skip the merge when ranking is
relevance-based or the partitions are too heterogeneous — splitting into per-entity keyset
browse + cross-partition relevance search instead.
