---
title: "Keyset pagination guarantees positional stability, not a frozen result set; a time boundary that must not drift must be pinned into the versioned cursor"
date: 2026-06-21
topic: data-explorer-ux
tags: [keyset-cursor, pagination, snapshot, point-in-time, relay, total-count]
status: draft
sources: [stripe-pagination, slack-pagination, twitter-x, relay-connections, jsonapi-cursor, use-the-index-luke, es-pit]
---

## CLAIMS

- Keyset pagination's default guarantee is POSITIONAL stability (no offset-style skip/duplicate) via the keyset tuple `(sort_col, id)` with a unique tiebreaker; it does NOT freeze the result set — the set may change between requests. [use-the-index-luke][stripe-pagination]
- Stripe list cursors (`starting_after`/`ending_before`) are object IDs (positional), not a time watermark or snapshot token; the docs describe no point-in-time snapshot freezing the result set across pages. [stripe-pagination]
- Slack's documented scheme is `WHERE id <= :cursor ORDER BY id DESC` with the anchor being the last row's id carried in the opaque cursor — not a recomputed offset and not a pinned clock. [slack-pagination]
- Twitter/X `since_id`/`max_id` bound the range to row IDs captured in the first page's metadata; the anchor is a row ID, not a wall-clock. [twitter-x]
- The Relay/GraphQL connections spec mandates consistent ORDERING page-to-page but does NOT mandate a stable point-in-time snapshot; pinning a per-traversal snapshot (encode a session id to serve one snapshot) is an explicit OPTIONAL "MAY" reserved for rare cases. [relay-connections]
- The JSON:API cursor-pagination profile agrees that a stable snapshot across a traversal is opt-in, not the default. [jsonapi-cursor]
- Explicit-pin mechanisms (Elasticsearch PIT + `search_after`; "capture a max keyset up front and paginate up to it") deliberately MISS all inserts during the sweep — designed for exhaustive exports, not interactive live feeds. [es-pit]
- Relay models `totalCount` as a first-class server-side connection field (a true count of the whole connection, not of loaded items) and advises that if the server can produce a true total it should; JSON:API allows an exact server-computed `total` (or `estimatedTotal` when costly). [relay-connections][jsonapi-cursor]

## SOURCES

**stripe-pagination**
URL: https://docs.stripe.com/api/pagination
Accessed: 2026-06-21
Quote: "starting_after and ending_before are object IDs; the result set is allowed to change between requests."

**slack-pagination**
URL: https://slack.engineering/evolving-api-pagination-at-slack/
Accessed: 2026-06-21
Quote: "WHERE id <= cursor ORDER BY id DESC — the anchor is the last row's id carried in the opaque cursor."

**twitter-x**
URL: https://developer.twitter.com/en/docs/twitter-api/pagination
Accessed: 2026-06-21
Quote: "since_id and max_id bound the range to tweet IDs, not wall-clock time."

**relay-connections**
URL: https://relay.dev/graphql/connections.htm
Accessed: 2026-06-21
Quote: "Ordering must be consistent page to page; serving one consistent snapshot per traversal is an optional mechanism reserved for rare cases."

**jsonapi-cursor**
URL: https://jsonapi.org/profiles/ethanresnick/cursor-pagination/
Accessed: 2026-06-21
Quote: "A stable snapshot across a traversal is opt-in; the server may expose a total or an estimatedTotal count."

**use-the-index-luke**
URL: https://use-the-index-luke.com/no-offset
Accessed: 2026-06-21
Quote: "The keyset (seek) method paginates on (sort_col, id); offset is the anti-pattern. Stability comes from the keyset tuple."

**es-pit**
URL: https://www.elastic.co/guide/en/elasticsearch/reference/current/point-in-time-api.html
Accessed: 2026-06-21
Quote: "A point in time freezes the index state; used for exhaustive sorted traversal, it will not see inserts made during the sweep."

## SYNTHESIS

A subtle but important corollary: a `WHERE time <= :now` clamp on a keyset-paginated feed is
NOT pinned by default. If `:now` is recomputed per request, a row whose scheduled/semantic
time crosses from future into past mid-traversal sorts ABOVE the keyset cursor and is silently
skipped for the whole session (appearing only on a fresh reload) — a real, if rare, gap that
keyset's positional guarantee does not cover. The documented fix is exactly the opt-in
snapshot the specs reserve for rare cases: pin `now` into the versioned cursor at first-page
capture so the entire traversal shares one consistent point-in-time boundary (bump the cursor
version and reject stale cursors so old tabs re-anchor). The trade-off — a row that crosses
into the past mid-session stays classified as "upcoming" until reload — is a consistent,
predictable state rather than a silent skip. For a bounded future/upcoming projection, prefer
Relay's true `totalCount` over a bare `has_more`, since the set is small enough for an exact
`COUNT(*)` to be cheap and more useful.
