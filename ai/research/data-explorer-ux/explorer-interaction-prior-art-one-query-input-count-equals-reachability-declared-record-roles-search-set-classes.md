---
title: "Explorer interaction prior art: one query input where chips == operators == facets over a single URL state, count-equals-reachability (hide totals you can't prove), declared (never guessed) record display roles, and three honesty classes of search result set"
date: 2026-06-21
topic: data-explorer-ux
tags: [query-ui, faceted-search, count-reachability, record-display, search-honesty, pagination]
status: draft
sources: [gmail-chips, stripe-search, linear-filters, datadog-facets, stripe-pagination, google-photos-stacks, virtuoso-grouped, things3, todoist-upcoming, airtable-primary, notion-property, datadog-explorer, gharchive]
---

## CLAIMS

### Query / filter / search

- One query input is the norm: Gmail's single bar handles free-text + chips + an advanced builder with no separate id box; Stripe's one search bar does text + filters + id lookup. A pasted exact id is handled by a "jump to record" affordance, not a second input box. [gmail-chips, stripe-search]
- Chips == the operator behind them: Gmail's "Has attachment" chip equals `has:attachment` (chips on web and mobile); Linear's click-to-refine chips produce the same query as the operators exposed in its API — novice and power user build the identical query by recognition vs recall. [gmail-chips, linear-filters]
- Facets are part of the one query state, not a parallel system: Datadog's facet-panel selections reflect in the query bar + URL as one state, removing the "do my checkboxes AND my query both apply?" ambiguity. [datadog-facets]
- Negation is first-class in both UI and syntax: Stripe's leading `-` negates any filter; Gmail supports `-term` and a "Doesn't have" form field; Linear has an "is not" chip toggle. [stripe-search, gmail-chips, linear-filters]
- A displayed count must mean one clear thing: Datadog's facet number is the count in the current filtered query scope, updating as filters change; Stripe refuses a total it can't cheaply guarantee (no default list total; search total capped at 10,000). [datadog-facets, stripe-pagination]
- Keyboard: Gmail/Linear submit on Enter and expose a Cmd-K jump — table-stakes speed. [gmail-chips, linear-filters]
- Mobile keeps chips and moves the advanced panel to a filter button/bottom sheet, so filtering power survives the small screen (Gmail). [gmail-chips]

### Reachability / collapse / load-more

- A count is a promise = a handle to its exact reachable set: Stripe ties a count to its exact filtered set via URL state and refuses unreachable totals; Linear shows true per-group totals tied to full membership. [stripe-search, linear-filters]
- Grouped/burst counts should be the TRUE per-group total, not the currently-loaded count (Linear true per-group count). [linear-filters]
- "Show all" for a group: small = inline (Google Photos Stacks inline expand, hard-capped at 100); large = drill into a separate paginated endpoint (Stripe invoice lines ≤10 inline, >10 a separate paginated endpoint). [google-photos-stacks, stripe-pagination]
- Load-more in grouped virtual lists mutates group counts in place and adjusts the first-item index by the new-item count so shown rows never get displaced/reordered (react-virtuoso GroupedVirtuoso). [virtuoso-grouped]
- Future/upcoming content is its own surface: Things 3 uses mutually-exclusive day sections; Todoist's Upcoming is its own week-paged surface — one record lives in one place, and future records don't ride the main feed. [things3, todoist-upcoming]

### Record presentation

- The title/primary is a DECLARED role, never guessed: Airtable's primary field is the declared title across all views; Notion's schema requires exactly one title property; schema.org uses `name`/`mainEntity`. [airtable-primary, notion-property]
- Field TYPE and presentation ROLE are two axes: Airtable lets only primary-eligible types be the title but role is a separate declaration, and interface layouts pick a title + preview roles — a `text` field can be title OR body, so type alone cannot say which; JSON Schema `title`/`description` are display annotations. [airtable-primary]
- Honest generic fallback beats a confident wrong card: Datadog renders arbitrary logs as a generic key/value attribute table and makes reserved standard attributes special only when present; Google My Activity and GitHub (GH Archive) use a generic base schema (header/title/time) plus a typed-detail renderer. [datadog-explorer, gharchive]

### Search-result-set honesty classes

- relevance_bounded: a semantic/top-match candidate pool, NOT an exhaustive count of all conceptual matches; the count is the pool size (a bounded sample / `lower_bound` at most), and it should not expose a "sort newest" affordance implying completeness. Precedent: Stripe search total only to 10,000. [stripe-pagination]
- keyword_pageable (exhaustive lexical): a keyword/filter set walkable to exhaustion via cursor; an `exact` count is provable and fully reachable. Precedent: Stripe `has_more` walk-to-exhaustion. [stripe-pagination]
- chronological browse: the time-ordered corpus under a scope with no relevance promise; `exact` and fully paginated. [stripe-pagination]

## SOURCES

**gmail-chips**
URL: https://9to5google.com/2020/02/19/gmail-search-chips/ ; https://support.google.com/mail/answer/7190 ; https://blocksender.io/using-boolean-and-and-not-operators-in-gmail-search/
Accessed: 2026-06-21

**stripe-search**
URL: https://docs.stripe.com/dashboard/search
Accessed: 2026-06-21

**linear-filters**
URL: https://linear.app/docs/filters
Accessed: 2026-06-21

**datadog-facets**
URL: https://docs.datadoghq.com/logs/explorer/facets/
Accessed: 2026-06-21

**stripe-pagination**
URL: https://docs.stripe.com/api/pagination ; https://docs.stripe.com/api/pagination/search ; https://docs.stripe.com/invoicing/preview
Accessed: 2026-06-21

**google-photos-stacks**
URL: https://www.tomsguide.com/ (Google Photos Stacks coverage; inline expand hard-capped at 100)
Accessed: 2026-06-21

**virtuoso-grouped**
URL: https://virtuoso.dev/react-virtuoso/api-reference/grouped-virtuoso/
Accessed: 2026-06-21

**things3**
URL: https://culturedcode.com/things/support/articles/4001304/
Accessed: 2026-06-21

**todoist-upcoming**
URL: https://todoist.com/help/articles/plan-ahead-with-upcoming-view-KgKpuaGq
Accessed: 2026-06-21

**airtable-primary**
URL: https://support.airtable.com/docs/the-primary-field ; https://support.airtable.com/docs/interface-layout-record-review
Accessed: 2026-06-21

**notion-property**
URL: https://developers.notion.com/reference/property-object
Accessed: 2026-06-21

**datadog-explorer**
URL: https://docs.datadoghq.com/logs/explorer/
Accessed: 2026-06-21

**gharchive**
URL: https://www.gharchive.org/
Accessed: 2026-06-21

## SYNTHESIS

The load-bearing interactions of a record/query explorer, each with a named precedent:

Query model — one input, one state. Leading products expose a single query surface where a clicked chip, a typed operator, and a selected facet all resolve to the same URL-encoded query; a pasted id is a "jump" affordance rather than a second box; negation is first-class in both chip and syntax; Enter submits and Cmd-K jumps. The anti-pattern is two parallel filtering systems (a "search values" box plus a separate "go to id" box) or requiring operator syntax as the only path.

Count discipline — count == reachability. A displayed number is a promise that its set is reachable to the last member; when an exact reachable count can't be cheaply guaranteed, hide it rather than show an ambiguous or shrunken figure (Stripe refuses totals beyond 10,000; Linear shows true group totals). Grouped/burst counts should be the true per-group total, not the loaded count. Small groups expand inline; large groups drill into a complete paginated endpoint. Load-more in grouped virtual lists must merge in place and never reorder/displace shown rows. Future/upcoming content belongs on its own surface, not the main feed.

Record presentation — declared, not guessed. The title/primary is a declared role (Airtable primary field, Notion required title property), and field TYPE (timestamp/currency/text/person/media/url/geo) is a separate axis from presentation ROLE (primary/secondary/event-time/actor/amount/media) — the same type can carry different roles, so the manifest/schema must declare which. An undeclared record renders an honest generic card (label + time + identity + humanized key/value table), never a guessed typed card (Datadog's generic attribute table; GH Archive's base-schema-plus-typed-detail). Humanized labels come from declared annotations; mechanical key-formatting is a last-resort label only, never a semantic inference.

Search honesty — three result-set classes. A relevance_bounded set (semantic top-match pool) must never render as an exhaustive "all matches" set or expose a "sort newest" affordance implying completeness — its count is a bounded pool size / lower bound. A keyword_pageable set is exhaustively walkable with a provable exact count. A chronological browse is the time-ordered corpus under a scope, exact and fully paginated. "All records matching X" should either create an exhaustive pageable set or state the exact set is unavailable — never dress a bounded relevance pool as complete.
