---
title: "Related-record navigation returns ids by default and expands only DECLARED relationships (never foreign-key-by-name heuristics); unreachable/missing targets are omission or null, not typed errors"
date: 2026-06-04
topic: api-contract-design
tags: [rest, relationships, resource-expansion, json-api, graphql-relay, postgrest]
status: draft
sources: [stripe-expand, jsonapi, relay-connections, postgrest-embedding, airtable-notion]
source_session: 019db34f-f4a7-77f3-b339-4f7b2b596e64
---

## CLAIMS

- Stripe returns nested object fields as ids by default; clients opt in via repeated `expand[]=<path>` params. Expansion is declared per object (the API reference lists exactly which fields are expandable — no foreign-key heuristic; an unexpandable id stays a string), supports dotted paths (`invoice.subscription`) capped at depth 3, and on list endpoints paths are rooted at the wrapper (`data.source.invoice`). [stripe-expand]
- JSON:API v1.1 gives a resource `attributes` and a sibling `relationships` member, each holding a typed resource-identifier object (`type` + `id`), not a full record; clients sideload via `?include=author,comments.author` and the server returns related records in a top-level `included` array under a "full linkage" rule (every included record must be reachable through a relationship chain from primary data). Sparse fieldsets (`fields[TYPE]=…`) compose with `include`; `self` links preserve every supplied query param so the document is refreshable; unreachable targets are OMITTED from `included`, not emitted as a typed error. [jsonapi]
- GraphQL Relay Cursor Connections wrap `edges[]` + `pageInfo`; each edge holds `node` + an opaque `cursor` plus edge-only fields; pagination uses `first`/`after` or `last`/`before` with consistent ordering required across directions; `pageInfo.hasNextPage`/`hasPreviousPage` separates "is there more" from "what comes next." [relay-connections]
- PostgREST infers embedded resources from declared foreign keys in the Postgres schema; when two FKs target the same table it requires a `!<fk-name>` disambiguation hint and returns `PGRST201` rather than guessing; reverse (one-to-many) embedding names the FK constraint; many-to-many requires the join table's FKs to be part of its primary key. The lesson: never auto-detect relationships from column names — either the schema declares it or the server refuses. [postgrest-embedding]
- Airtable linked-record fields and Notion relations are foreign-key/page-ID pointers between tables/databases, surfaced as typed cell values, and both treat navigability as a first-class UI affordance — a cell value renders as a clickable chip that opens the related record. Both hide the parent/child join asymmetry behind a bidirectional linked-cell UI. [airtable-notion]

## SOURCES

**stripe-expand**
URL: https://docs.stripe.com/expand ; https://docs.stripe.com/expand/use-cases
Accessed: 2026-06-04

**jsonapi**
URL: https://jsonapi.org/format/
Accessed: 2026-06-04

**relay-connections**
URL: https://relay.dev/graphql/connections.htm ; https://graphql.org/learn/pagination/
Accessed: 2026-06-04

**postgrest-embedding**
URL: https://docs.postgrest.org/en/stable/references/api/resource_embedding.html
Accessed: 2026-06-04

**airtable-notion**
URL: https://www.whalesync.com/blog/airtable-vs-notion-the-ultimate-guide
Accessed: 2026-06-04

## SYNTHESIS

Convergent design rules for related-record navigation in a resource API:

1. ID-default, expansion-opt-in: nested references come back as ids; a full payload is fetched only when the client asks (Stripe `expand[]`, JSON:API `include`). This keeps the base payload cheap and makes hydration a paid, explicit action.
2. Declaration is the only source of truth — never foreign-key-by-name heuristics. Stripe ships the expandable graph in its API reference; PostgREST refuses ambiguous embeds rather than guessing. "Any field ending in `_id` is a link" is explicitly out of scope for a trustworthy contract.
3. Depth discipline: Stripe caps at 3; JSON:API allows arbitrary depth but requires intermediate hops to be serialized too (full linkage). One hop covers most navigation; multi-hop needs explicit reverse-edge declaration, not a heuristic.
4. Missing/unreachable targets are data absence, not errors: JSON:API omits them from `included`; the honest UI renders "no related X" calmly rather than an error toast. Null for has-one, empty list for has-many.
5. Ordering is part of the contract: expanded has-many children need a defined order (a cursor field or primary key) so the page is reproducible (Relay requires consistent ordering across pagination directions).
6. The parent/child join is asymmetric and direction matters: for a declared has-many, the foreign-key field lives on the *child* and holds the *parent's* key. From a parent record the navigable target is the *filtered child list* (`child?filter[fk]=parent_key`), not a single child page; from a child record the FK value links back to the *parent's* detail. Airtable/Notion hide this behind a bidirectional linked-cell UI; a one-directional server contract must build each direction distinctly. Navigability is two things: inline expansion (related record in the payload) vs linkable identity (an id-shaped value rendered as a hyperlink even without expansion — cheap, no extra request).
7. Discoverability comes through stream/resource metadata that advertises which relations are expandable and usable, so a UI renders navigable chips for usable relations and dims/hides unusable ones with a reason — never invents links from raw payload fields. Edge-typed metadata (Relay edges with their own attributes) belongs to graph products, not a personal resource server.
