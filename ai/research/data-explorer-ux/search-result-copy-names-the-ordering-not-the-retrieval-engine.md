---
title: "Search-result copy names the ordering (relevance/newest) not the retrieval engine (BM25/vector/hybrid); default views use canonical routes not serialized defaults"
date: 2026-06-23
topic: data-explorer-ux
tags: [search-ux, honesty-copy, url-state, relevance, default-views]
status: draft
sources: [linear-search, algolia-what-is, stripe-search, linear-custom-views]
source_session: 019db34f-f4a7-77f3-b339-4f7b2b596e64
---

<!-- Extracted from a pdpp honesty-copy doc; internal THE-LENS/critic-verdict and pdpp code refs discarded. -->

## CLAIMS

- Linear's user-facing search copy names only the ordering the user controls ("order these by relevance, last updated or last created") and never exposes retrieval mechanism words (lexical/semantic/hybrid/deduplicated); stop-word behavior lives in a collapsed Q&A, not the result surface. [linear-search]
- Algolia's own docs — describing a hybrid lexical+vector platform — address the end-user experience as "relevance" and "matching, ranking, and filtering"; the words vector/BM25/embeddings live in engineering guides, not user-facing result copy. [algolia-what-is]
- Stripe frames search by the objects found and the fields that match (a query language over fields), never by the index implementation; the user reasons about what matched, not how it was retrieved. [stripe-search]
- Linear's default list (e.g. "All Issues") is a clean canonical route, not a query-string echoing every implicit filter; filters appear in the URL only when a user applies one, and a favorited view can be set as the default page. [linear-custom-views]

## SOURCES

**linear-search**
URL: https://linear.app/docs/search
Accessed: 2026-06-23
Quote: "order these by relevance, last updated or last created."

**algolia-what-is**
URL: https://www.algolia.com/doc/guides/getting-started/what-is-algolia/
Accessed: 2026-06-23
Quote: "Improve relevance — Tune matching, ranking, and filtering to improve results"

**stripe-search**
URL: https://docs.stripe.com/search
Accessed: 2026-06-23

**linear-custom-views**
URL: https://linear.app/docs/custom-views
Accessed: 2026-06-23

## SYNTHESIS

Two reusable honesty rules for search surfaces. (1) Name the ORDERING (relevance / matches / newest-first), never the ENGINE — a per-row "HYBRID"/"lexical"/"semantic"/"deduplicated" badge reads as machine output to a human and is a "developer told you" anti-pattern. Removing the mechanism word does not relax the ordering claim: a relevance-ranked bounded set must not claim "newest first" — the honest label is "top matches for '<q>'" with a separate labeled escape to the chronological set. (2) For a default/unfiltered list view, the canonical bare route IS the shareable default-view identity; do NOT serialize implicit defaults (`?lens=recent&sort=newest&order=desc`) into the querystring, which both duplicates the state (bare path AND param-soup both mean "default") and breaks any "is this the default view?" predicate that keys off "no filters present."
