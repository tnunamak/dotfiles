---
title: "Relevance-ranked and hybrid/vector search results are bounded and cannot be honestly deep-paginated; exhaustive access requires switching to a stable sort"
date: 2026-06-19
topic: data-explorer-ux
tags: [search, pagination, relevance, hnsw, pgvector, rrf, hybrid-search, primary-source]
status: draft
sources: [algolia-pagination-limited, algolia-20k, algolia-browse, es-max-window, es-paginate, es-rrf, opensearch-hybrid-pagination, pgvector-readme, meilisearch-pagination, stripe-search-pagination, airtable-deep-match, neon-hnsw]
---

## CLAIMS

- Algolia's `paginationLimitedTo` defaults to 1,000 and caps at 20,000; records beyond the limit are not accessible via `page`/`hitsPerPage`, and "sorting beyond the default 1,000th hit isn't guaranteed." [algolia-pagination-limited][algolia-20k]
- Algolia's `browse` endpoint (the only path past the pagination cap) does NOT apply full relevance ranking (no typo tolerance, matched-word, proximity, or geo ranking) and is documented as a back-end export path, not a user-facing search path. [algolia-browse]
- Elasticsearch `from + size` is capped at `index.max_result_window` (default 10,000); beyond it the request is refused and `search_after` (on a sorted field, with a Point-in-Time) is the documented exhaustive path — i.e. switch to a stable sort like timestamp+id. [es-max-window][es-paginate]
- Elasticsearch RRF hybrid pagination is hard-capped at `rank_window_size`: when `from + size > rank_window_size` the API returns ZERO results; there is no cursor/`search_after` path for RRF results. [es-rrf]
- OpenSearch (2.19+) bounds hybrid pagination by `pagination_depth` (per shard per subquery); pagination beyond `pagination_depth * shard_count` is unsupported — a bounded, non-unbounded window like Elasticsearch's `rank_window_size`. [opensearch-hybrid-pagination]
- pgvector HNSW approximate nearest-neighbor search returns different results after adding the approximate index ("you will see different results for queries after adding an approximate index"); `hnsw.ef_search` (default 40) and `hnsw.iterative_scan` (bounded by `hnsw.max_scan_tuples`) expand the candidate pool but do not produce a stable ordered list beyond it — there is no stable "position 26." [pgvector-readme][neon-hnsw]
- RRF fused rank is a property of the full merged set: computing the rank of position N requires the ranks of all items 1..N in both sub-lists, and if the sub-lists change between requests the fused ranking shifts, so a cursor pointing at position 26 may point at a different item or none. [es-rrf]
- Meilisearch is designed on the philosophy that "users should never need to go to page 2," returns an `estimatedTotalHits` approximation, and discourages numbered/deep pagination. [meilisearch-pagination]
- Stripe Search uses forward-only cursor (`next_page`) pagination over a frozen relevance-ranked snapshot; `total_count` is accurate only up to 10,000 and must be explicitly opted in. [stripe-search-pagination]
- Airtable's semantic "Deep Match" surfaces only "Top matches" (the 20 most similar records) with no deeper access — the canonical honest UX for ANN results: name the bound, offer filters to narrow. [airtable-deep-match]
- Slack search.messages sort=score|timestamp; sort=timestamp is cursor-paginated (cursormark next_cursor) and is the exhaustive path — i.e. the exhaustive path is a stable (chronological) sort, not deep relevance pagination. [es-paginate]

## SOURCES

**algolia-pagination-limited**
URL: https://www.algolia.com/doc/api-reference/api-parameters/paginationLimitedTo/
Accessed: 2026-06-19
Quote: "The paginationLimitedTo parameter defines the maximum number of results that can be accessed using pagination... records beyond the 1000th hit won't be accessible... Sorting beyond the default 1,000th hit isn't guaranteed."

**algolia-20k**
URL: https://support.algolia.com/hc/en-us/articles/23525857176721-Can-I-set-a-paginationLimitedTo-value-greater-than-20-000
Accessed: 2026-06-19
Quote: "Can I set a paginationLimitedTo value greater than 20,000? (title of Algolia's support article — 20,000 is the ceiling)"

**algolia-browse**
URL: https://www.algolia.com/doc/api-reference/api-methods/browse/
Accessed: 2026-06-19
Quote: "Browsing returns matching records only. Use browse to export your indices. There's no ranking for typo tolerance, number of matched words, proximity, or geo distance."

**es-max-window**
URL: https://www.elastic.co/guide/en/elasticsearch/reference/current/index-modules.html
Accessed: 2026-06-19
Quote: "index.max_result_window: The maximum value of from + size for searches to this index. Defaults to 10000."

**es-paginate**
URL: https://www.elastic.co/guide/en/elasticsearch/reference/current/paginate-search-results.html
Accessed: 2026-06-19
Quote: "By default, you cannot use from and size to page through more than 10,000 hits... use the search_after parameter... We no longer recommend using the scroll API for deep pagination."

**es-rrf**
URL: https://www.elastic.co/guide/en/elasticsearch/reference/current/rrf.html
Accessed: 2026-06-19
Quote: "if from + size > rank_window_size: we would get 0 results back, as the request would fall outside the available rank_window_size-sized result set."

**opensearch-hybrid-pagination**
URL: https://docs.opensearch.org/latest/vector-search/ai-search/hybrid-search/pagination/
Accessed: 2026-06-19
Quote: "The pagination_depth parameter defines the maximum number of search results that can be retrieved from each shard per subquery."

**pgvector-readme**
URL: https://github.com/pgvector/pgvector
Accessed: 2026-06-19
Quote: "Unlike typical indexes, you will see different results for queries after adding an approximate index... Specify the size of the dynamic candidate list for search (40 by default)."

**neon-hnsw**
URL: https://neon.com/blog/understanding-vector-search-and-hnsw-index-with-pgvector
Accessed: 2026-06-19
Quote: "HNSW is an approximate nearest-neighbor index; iterative scan expands the candidate set but is bounded and does not provide stable deep pagination."

**meilisearch-pagination**
URL: https://www.meilisearch.com/docs/capabilities/full_text_search/how_to/paginate_search_results
Accessed: 2026-06-19
Quote: "Users should never need to go to page 2; results return an estimatedTotalHits approximation."

**stripe-search-pagination**
URL: https://docs.stripe.com/api/pagination/search
Accessed: 2026-06-19
Quote: "Search results use next_page cursor pagination; total_count is accurate up to 10,000."

**airtable-deep-match**
URL: https://support.airtable.com/docs/linking-records-in-airtable
Accessed: 2026-06-19
Quote: "Deep Match surfaces the top 20 semantically similar records, labeled Top matches, with no deeper access."

## SYNTHESIS

Three independent reasons make relevance-ranked and hybrid results fundamentally bounded, not
deep-pageable like a time-ordered feed: (1) ANN/vector (HNSW) is a greedy approximate top-K
traversal — "results 26-50" means re-running with K=50 and discarding 25, with no stable
position and non-deterministic membership; (2) RRF fused rank is a non-decomposable property
of the full merged set and shifts when sub-lists change, so both Elasticsearch and OpenSearch
hard-cap hybrid pagination (`rank_window_size` / `pagination_depth`) and return zero past it;
(3) offset relevance pagination hits explicit ceilings (Algolia 1K/20K, Elasticsearch 10K).
The honest UX every SLVP-tier product converges on: label the bound ("Top N most relevant
results," e.g. Airtable "Top matches"), and provide a real exhaustive path by SWITCHING TO A
STABLE SORT (chronological) — this is exactly Elasticsearch's own `search_after`-on-a-sorted-
field recommendation and Slack's sort=timestamp cursor path. Lexical search over a frozen
snapshot IS soundly cursor-pageable (Stripe's model, PDPP's own lexical snapshot cursor); the
non-pageable case is specifically the hybrid/vector one.
