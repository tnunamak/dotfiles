---
title: "Read/data APIs converge on one canonical list array, opaque cursors, lean-by-default field selection, paired highlight tags, and never dumping the whole schema"
date: 2026-06-09
topic: api-contract-design
tags: [api-design, pagination, cursors, search, highlighting, mcp, odata, airbyte, graphql]
status: draft
sources: [stripe-pagination, stripe-charges, stripe-expand, stripe-errors, linear-pagination, linear-graphql, plaid-transactions, plaid-errors, openai-mcp, openai-deep-research, mcp-tools, anthropic-tools, es-highlight, opensearch-highlight, algolia-response, typesense-search, meilisearch-search, weaviate-fusion, airbyte-protocol, singer-spec, steampipe-docs, odata-tutorial, apollo-federation, rfc9396]
source_session: 019d35d2-84c0-7322-8615-9b5076e452db
---

<!-- Reusable interface-contract prior-art extracted from a pdpp MCP data-surface note.
     pdpp-specific battery findings and "already fixed" annotations were dropped. -->

## CLAIMS

- Stripe's list envelope has exactly four top-level fields and one canonical array: `{ object:"list", url, has_more, data:[…] }`; every element self-describes via its own `id` + `object` discriminator so any item is identifiable out of context. Pagination metadata sits beside the array, never duplicating it. [stripe-pagination][stripe-charges]
- Stripe pagination uses opaque `starting_after`/`ending_before` (an object ID already received), `limit` default 10 / max 100, and a `has_more` boolean; the two cursors are mutually exclusive. [stripe-pagination]
- Linear uses Relay-style `first`/`after` + `pageInfo { hasNextPage endCursor }`, default page 50. [linear-pagination]
- Plaid offers classic `count`(max 500)/`offset`(default 0) on `/transactions/get` and a modern delta-sync on `/transactions/sync` returning `added`/`modified`/`removed` + `next_cursor` + `has_more`. [plaid-transactions]
- For fan-out across multiple sources, an opaque cursor beats an offset: an opaque token can encode per-source state (e.g. `base64({sourceA:curX, sourceB:curY})`) and expose one `has_more`+`next_cursor` while resuming each source independently, whereas offset forces all sources onto one numeric coordinate and breaks when data shifts. [stripe-pagination][linear-pagination][plaid-transactions]
- Linear GraphQL makes response shape = query shape (the server only serializes requested fields), which is ideal for a token-metered API because the caller controls payload size. [linear-graphql]
- Stripe is lean by default (related objects returned as IDs) and opts into joins via `expand[]` (recursive via dotted paths; on lists expansions start at `data.`); "return a fixed wide record then project" still materializes and serializes the wide record before trimming. [stripe-expand]
- Stripe's error envelope is `error.{type, code, message, param}` + `request_id` on every response; Plaid's adds `{error_type, error_code, error_message, display_message (user-safe, nullable), documentation_url, suggested_action, status, request_id}` and explicitly prefers `error_code`/`error_type` over HTTP status for app-level errors. [stripe-errors][plaid-errors]
- The OpenAI MCP `search` result object is `{id, title (human-readable, citable), url (canonical for citation)}` with optional snippet/`text`; the `fetch` result is `{id, title, text (full text), url, metadata}`. Setting `title` = snippet destroys citable identity and dedup. [openai-mcp][openai-deep-research]
- The MCP spec says a tool returning structured content SHOULD also return the serialized JSON in a TextContent block — this is a backwards-compat serialized mirror, not a second independent payload; declare an `outputSchema` for client validation. Protocol errors use JSON-RPC codes (`-32602` etc.); tool-execution errors return a successful result with `isError: true`. [mcp-tools]
- Anthropic's tool guidance: return only high-signal information, eschew low-level identifiers (`uuid`, `mime_type`), implement pagination/range/filter/truncation with sane defaults (Claude Code caps tool responses at 25k tokens), and offer a `response_format` enum (`concise`/`detailed`). [anthropic-tools]
- Every major search engine highlights matches with a paired, balanced, body-safe open/close tag: `<em>…</em>` (Elasticsearch, OpenSearch, Algolia, Meilisearch defaults) or `<mark>…</mark>` (Typesense default), configurable via `pre_tags`/`post_tags` (or equivalents); zero engines use a bare punctuation mark, which is unbalanced and collides with prose/numbers/CSV. [es-highlight][opensearch-highlight][algolia-response][typesense-search][meilisearch-search]
- Hybrid-fusion search exposes a single higher-is-better fused score with a per-result breakdown: Elasticsearch/Qdrant RRF (`Σ 1/(k+rank)`, k≈60), Weaviate Relative-Score-Fusion (default since 1.24, with `explainScore`). [weaviate-fusion]
- The Airbyte protocol's `AirbyteCatalog` (from `discover`) lists `AirbyteStream`s each with `name` + `json_schema` + `supported_sync_modes` + `source_defined_primary_key`; its cursor precedence is `source_defined_cursor:true` (source picks, non-overridable) → caller's `cursor_field` → `default_cursor_field` → else illegal; state is an opaque black box the source emits and nothing else may parse. [airbyte-protocol]
- Singer defines three message types — SCHEMA (`schema` JSON Schema + `stream` + `key_properties` + optional `bookmark_properties`), RECORD, STATE — with schema emitted per-stream and interleaved (never one monolithic dump); `key_properties` may be an empty list to explicitly indicate no primary key. [singer-spec]
- Steampipe translates APIs to Postgres foreign tables and notes that querying all columns is inefficient because projection prunes upstream API calls, not just bytes — "you should only query the columns that you need." A typed tool with enumerated filters + per-stream introspection is more discoverable and token-efficient for an LLM than raw SQL (which needs table/column names a priori). [steampipe-docs]
- OData v4 fetches schema once (`$metadata` CSDL at one endpoint, each response carries `@odata.context` pointing back), uses a closed typed operator vocabulary (`$filter` with `eq/gt/ge/lt/le/and/or` + functions + lambda `any`/`all`, `$select`/`$expand`/`$top`/`$skip`/`$count`/`$orderby`/`$search`), and expresses relationships as `@odata.id`/`$ref` entity references instead of re-embedding entities. [odata-tutorial]
- Apollo Federation combines subgraphs into one supergraph via a router; GraphQL's defining property is that the client asks for exactly the fields it wants and discovers schema via introspection on demand (`__type(name:)` for one type, not the whole schema per response). [apollo-federation]
- RFC 9396 (Rich Authorization Requests) states `scope` is sufficient only for coarse-grained authorization and defines `authorization_details` as a JSON array of typed objects (required `type` + common `locations`, `actions`, `datatypes`, `identifier`, `privileges`) whose combined field values multiply. [rfc9396]

## SOURCES

**stripe-pagination**
URL: https://docs.stripe.com/api/pagination
Accessed: 2026-06-09

**stripe-charges**
URL: https://docs.stripe.com/api/charges/list
Accessed: 2026-06-09

**stripe-expand**
URL: https://docs.stripe.com/api/expanding_objects
Accessed: 2026-06-09

**stripe-errors**
URL: https://docs.stripe.com/api/errors
Accessed: 2026-06-09

**linear-pagination**
URL: https://linear.app/developers/pagination
Accessed: 2026-06-09

**linear-graphql**
URL: https://linear.app/developers/graphql
Accessed: 2026-06-09

**plaid-transactions**
URL: https://plaid.com/docs/api/products/transactions
Accessed: 2026-06-09

**plaid-errors**
URL: https://plaid.com/docs/errors
Accessed: 2026-06-09

**openai-mcp**
URL: https://platform.openai.com/docs/mcp
Accessed: 2026-06-09

**openai-deep-research**
URL: https://platform.openai.com/docs/guides/deep-research
Accessed: 2026-06-09

**mcp-tools**
URL: https://modelcontextprotocol.io/specification/2025-06-18/server/tools
Accessed: 2026-06-09
Quote: "a tool that returns structured content SHOULD also return the serialized JSON in a TextContent block"

**anthropic-tools**
URL: https://www.anthropic.com/engineering/advanced-tool-use
Accessed: 2026-06-09
Quote: "return only high-signal information… eschew low-level technical identifiers (uuid, mime_type)"

**es-highlight**
URL: https://www.elastic.co/guide/en/elasticsearch/reference/current/highlighting.html
Accessed: 2026-06-09

**opensearch-highlight**
URL: https://opensearch.org/docs/latest/search-plugins/searching-data/highlight/
Accessed: 2026-06-09

**algolia-response**
URL: https://www.algolia.com/doc/guides/building-search-ui/going-further/understanding-the-api-response/
Accessed: 2026-06-09

**typesense-search**
URL: https://typesense.org/docs/29.0/api/search.html
Accessed: 2026-06-09

**meilisearch-search**
URL: https://www.meilisearch.com/docs/reference/api/search
Accessed: 2026-06-09

**weaviate-fusion**
URL: https://weaviate.io/developers/weaviate/search/hybrid
Accessed: 2026-06-09

**airbyte-protocol**
URL: https://docs.airbyte.com/understanding-airbyte/airbyte-protocol
Accessed: 2026-06-09

**singer-spec**
URL: https://github.com/singer-io/getting-started/blob/master/docs/SPEC.md
Accessed: 2026-06-09

**steampipe-docs**
URL: https://steampipe.io/docs/sql/steampipe-sql
Accessed: 2026-06-09
Quote: "querying all columns is inefficient… you should only query the columns that you need. This will save Steampipe from making API calls to gather data that you don't want"

**odata-tutorial**
URL: https://www.odata.org/getting-started/basic-tutorial/
Accessed: 2026-06-09

**apollo-federation**
URL: https://www.apollographql.com/docs/federation
Accessed: 2026-06-09

**rfc9396**
URL: https://datatracker.ietf.org/doc/html/rfc9396
Accessed: 2026-06-09

## SYNTHESIS

For a token-metered read/query API (especially one exposed to an LLM over MCP), the industry consensus is: exactly one canonical list array with pagination metadata beside it (never a duplicated second hit array); opaque cursors over offsets (an opaque token can carry per-source state for fan-out); lean-by-default responses with two opt-in levers (`fields=` sparse fieldset + Stripe `expand[]`); a two-level error taxonomy with a coarse `type`, a stable `code`, separate developer vs user-safe messages, a machine pointer, and `request_id` on every response; paired body-safe highlight tags (`<mark>`/`<em>`) with `title` kept distinct from `snippet`; and a single higher-is-better fused score for hybrid search. The deepest shared discipline across Airbyte, Singer, Steampipe, OData, GraphQL/Federation and MCP is *never dump the whole schema* — fetch per-stream/per-type on demand and dedup expanded entities with `@odata.id`/`$ref`-style references. A useful framing: a stream/cursor/catalog data API is "an Airbyte-shaped catalog wearing an OData-shaped query dress," exposed through the MCP/OpenAI search-fetch contract, under an RFC 9396-style typed-consent layer.
