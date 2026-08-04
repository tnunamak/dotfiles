---
title: "Reverse filter via relationship is a constrained alternative to reverse-expansion for cross-stream/cross-table queries; PostgREST !inner demonstrates the pattern"
date: 2026-08-04
topic: api-contract-design
tags: [rest, relationships, filtering, postgrest, reverse-expansion, json-api]
status: draft
sources: [postgrest-inner-filter, pdpp-filter-via-design]
source_session: 11cdc48d-2ed2-4494-bcca-aaf3bcc160e3
---

## CLAIMS

- PostgREST resource embedding supports a `!inner` (inner join) and `!left` (left join) syntax for embedding related resources when the relationship direction is "many-to-one from the requesting table" — the `!inner` operator filters the primary resource by the existence/match of a related record, effectively a reverse filter. [postgrest-inner-filter]
- A constrained reverse-filter contract (`filter[via.<rel>.<field>]`) allows queries like "get all messages where I reacted to them" (filter messages by the existence of a reaction from a given user) without materializing full reverse-expansion payloads. The pattern requires: (1) explicit relationship declaration in the schema (never name-heuristic), (2) single-hop depth (nested `via` rejected), (3) `EXISTS`-based SQL translation, (4) primary data unchanged (only the filter set depends on the reverse edge). [pdpp-filter-via-design]
- Reverse expansion (full related-record payloads in the response) is a different, higher-cost mechanism than reverse filtering; the two are separable contract choices. A reverse-filter reduces request size and backend compute; a reverse-expand hydrates related data inline at the cost of larger payloads and schema-depth coupling. [pdpp-filter-via-design]
- Nested reverse-filtering (`filter[via.other_rel.field]` where `other_rel` itself is a reverse relationship) is explicitly deferred as a slippery slope — each hop multiplies backend complexity and testing surface; single-hop reverse-filter is the load-bearing boundary. [pdpp-filter-via-design]

## SOURCES

**postgrest-inner-filter**
URL: https://docs.postgrest.org/en/v12/references/api/resource_embedding.html
Accessed: 2026-08-04
Quote: "Resource Embedding with inner join using ! operator; allows filtering by existence of related records"

**pdpp-filter-via-design**
Source: Research brief 11cdc48d-2ed2-4494-bcca-aaf3bcc160e3, findings from PDPP read-surface analytics design investigation
Accessed: 2026-08-04
Context: Design decision to support `filter[via.<rel>.<field>]` for reverse-relationship queries ("messages I reacted to") as a bounded alternative to reverse expansion; explicitly defers nested `via` and full hydration; uses EXISTS-based SQL.

## SYNTHESIS

Reverse filtering via a relationship is a practical middle ground between ID-only foreign keys (forces client to make extra requests) and full reverse expansion (expensive, schema-coupling risk). The pattern:

1. **Narrow scope, high signal:** Reverse filters answer specific questions ("do I have a reaction to this?") without materializing the full related set in the response payload. Costs ~one EXISTS subquery per record, not N embedded payloads.

2. **Explicit boundaries prevent scope creep:** Single-hop (direct reverse relationship only) keeps the query plan and test matrix bounded. Nested reverse-filters (`via.another_rel`) would require transitive relationship definitions and add quadratic test cases. The design explicitly rejects this to preserve contract stability.

3. **Orthogonal to expansion:** A resource can support both `include=relatedItems` (forward expansion) and `filter[via.someRelation.field]` (reverse filtering) independently — different use cases, different cost profiles. Don't conflate them.

4. **Schema declaration required:** PostgREST's `!inner` requires the foreign-key relationship to exist in the database schema (enforced at SQL-generation time); reverse-filter contracts should do the same — no name-based heuristics. A schema version mismatch (missing or renamed relationship) surfaces as a declarative 400, not silent empty results.

5. **Pagination and ordering:** Reverse-filtered result sets use the *primary* resource's natural ordering (primary key or a declared sort field), not the reverse relationship's children. The filter doesn't change which resource is the "primary" result; it only gates which rows are included.

**Related prior art:** Relay Cursor Connections support filtering/sorting on the primary resource; JSON:API sparse fieldsets and filtering are similarly primary-centric. The orthodoxy is to filter at the level of the primary result set, not to introduce secondary-resource joins into the order/pagination contract.

