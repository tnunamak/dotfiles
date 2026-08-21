---
title: "FHIR's CapabilityStatement/SearchParameter model (server declares sortable/filterable fields per resource type, SHOULD not MUST on _sort) is the closest transferable precedent for PDPP's manifest-declared query.range_filters/query.expand, and UMA 2.0's permission-ticket flow structurally requires pre-registered resources so it cannot express an optimistic ask for a stream that may not exist"
date: 2026-08-19
topic: pdpp
tags: [query-surface, discovery, fhir, capabilitystatement, uma, gnap, oidc-claims, open-banking, odata, mcp, agent-access-patterns, absence-leak]
status: draft
sources: [fhir-searchparameter, fhir-capabilitystatement-search, fhir-search-base, fhir-search-build, openbanking-transactions, odata-queryoptions, odata-centric-drawbacks, mcp-pagination-spec, mcp-pagination-chatforest, uma-federated-authz, uma-core-ticket, oidc-core-claims, oidc-asc-draft, gnap-rfc9635, smart-fhir-wellknown, smart-fhir-scopes-context]
source_session: 8b2c8ac0-a286-48e1-b140-253d6b93668c
---

## CLAIMS

### Q1 — Query surface

- FHIR servers declare search capability per resource type in `CapabilityStatement.rest.resource.searchParam`, each entry linking to a canonical `SearchParameter` resource; a resource type can only be described once per RESTful mode, and resource types/operations not listed are not supported. [fhir-capabilitystatement-search]
- The FHIR spec text is explicit that clients should consult the CapabilityStatement rather than assume support: "Resource Types or operations that are not listed are not supported." Servers SHALL declare what search features they require; SHOULD is used, not MUST, for sort support: "servers can choose how to sort the return results, though they SHOULD honor the `_sort` parameter." [fhir-search-base] [fhir-search-build]
- FHIR has no standard way (pre-R6-ballot) to declare *mandatory* search-parameter combinations (e.g., "Observation search requires `category`") except through custom CapabilityStatement extensions; a future FHIR release is flagged as needed to standardize this. [fhir-search-build]
- Real FHIR server implementations narrow the base spec's flexibility further than the spec requires: Azure Health Data Services' FHIR service supports sorting on only a single field at a time (despite the base spec allowing comma-separated multi-field `_sort`), and defaults to lenient handling that silently ignores unknown/unsupported parameters rather than rejecting them. Smile CDR extends `_sort` with chained expressions and an opt-in "Uplifted Refchains" indexing feature that trades slower writes for faster chained sort/search. [fhir-search-build]
- UK Open Banking's Transactions endpoint (OBIE Read/Write API, AISP) exposes exactly a date-window filter — `fromBookingDateTime` / `toBookingDateTime` — with `BookingDateTime` mandatory precisely so ASPSPs can support pagination and filtering; there is no general `$filter`/`$sort`-style parameter family. The spec explicitly normalizes edge cases (bank holidays, out-of-range dates, dates outside consent authorization) by requiring the ASPSP to return data for the remaining valid period rather than erroring. Response detail (which fields appear) is gated by scope (`ReadTransactionsBasic` vs `ReadTransactionsDetail`), not by a query parameter. [openbanking-transactions]
- OData's `$filter`/`$orderby`/`$expand` family is the maximal-power contrast: Microsoft Graph (built on OData) exposes the full family (`$filter`, `$select`, `$expand`, `$orderby`, `$top`, `$skip`, `$skiptoken`, `$count`, `$search`, `$format`) on every list endpoint. Cited adoption costs: (1) filter-to-SQL translation is nontrivial for calculated/complex properties, forcing an implement-or-reject decision per property; (2) naive implementations apply filters in memory rather than pushing to the database, causing high memory use at scale; (3) `$expand` on `has_many` relations risks N+1 query explosion unless the provider detects and batches/joins; (4) arbitrary `$filter`/`$expand` is a security surface — every property and navigation-property name must be allow-listed or a client can expose or traverse into data it shouldn't reach; (5) even Microsoft's own Graph API has version-gated quirks, e.g. some `$filter`/`$orderby` combinations on directory objects require an explicit "advanced query parameters" opt-in mode or return HTTP 400. [odata-queryoptions] [odata-centric-drawbacks]
- Current MCP tooling guidance (2026) converges on: opaque cursor-based pagination (not numbered pages) as the protocol-level primitive; tool-level list/search results should use conservative default limits (one architecture doc cites a default of 10) with explicit `limit`/`cursor` or `offset` parameters and `has_more`/`next_cursor` metadata; unlimited iteration by default is explicitly rejected for latency/memory risk; and for genuinely large payloads, a `ResourceLink`-style pattern (return a reference, let the agent fetch on demand) is preferred over inlining. Composability guidance recommends narrow, chained tools (e.g., `search_products` → `get_product_details` → `check_inventory`) over one broad query tool. [mcp-pagination-spec] [mcp-pagination-chatforest]

### Q2 — Discovery / absence-leak

- UMA 2.0's permission-ticket flow structurally presupposes the resource already exists in the AS's registry: resources must be registered via the `resource_set` endpoint before any protection can occur; when a resource server requests a permission ticket for an identifier that was never registered, the AS returns a defined error — "At least one of the provided resource identifiers was not found at the authorization server" — rather than issuing a ticket. [uma-core-ticket]
- UMA's normal flow is resource-server-initiated, not client-initiated-optimistic: the client's unauthenticated request to the RS is what triggers the RS (using its PAT) to ask the AS for a permission ticket on the client's behalf; the client never directly asks the AS "does resource X exist," so UMA has no first-class mechanism for a client to name a resource it merely hopes exists. [uma-federated-authz] [uma-core-ticket]
- OpenID Connect's `claims` request parameter lets a Relying Party mark requested claims `essential: true` or leave them voluntary, but Core does not mandate any specific behavior when an essential claim is unavailable — the OP "may return some or all of the requested claims dependent on availability, end-user approval, or some other policy," with no guaranteed abort or error signal back to the client distinguishing "doesn't exist" from "user declined." [oidc-core-claims]
- The gap above was significant enough that a dedicated extension was drafted: OpenID Connect Advanced Syntax for Claims (ASC) 1.0 adds "Selective Abort/Omit" (SAO), letting an RP explicitly declare, per claim, whether the OP should abort the whole transaction or silently omit the claim when unavailable/undisclosed/unconsented — implying the base spec's default (silent omission, no distinction) was judged insufficient prior art on its own. [oidc-asc-draft]
- SMART on FHIR's `.well-known/smart-configuration` discovery document is fetched pre-consent and advertises server *capabilities* (auth endpoints, supported scope syntaxes/versions) but explicitly does not enumerate a specific patient's available clinical resources; wildcard scopes (`patient/*.cruds`) are defined to cover "not just the currently accessible data... but also any additional data the FHIR server may be enhanced to expose in the future," and the actually-granted scope set is only knowable after the OAuth consent round-trip (via the granted-scopes response or token introspection), which can differ from what was requested. [smart-fhir-wellknown] [smart-fhir-scopes-context]
- GNAP (RFC 9635) supports request continuation: after an initial grant request, the client instance can continue the negotiation at the AS, including cases where "the RO cannot be reached or the RO denies the request," after which "the client instance can negotiate next steps if possible" — a multi-round negotiation primitive that is closer in shape to an optimistic-ask-then-route flow than UMA's registration-gated model, though the fetched sources did not surface exact wire-level syntax for renegotiating the `resources` field mid-continuation. [gnap-rfc9635]
- OAuth 2.0 incremental authorization's core privacy goal is to avoid asking for scopes the client doesn't yet need, but its mechanics are documented as inherently disclosing existing-grant state: one described design has each incremental request include all previously granted scopes plus the new one, so the AS (and by extension anything observing the request/response) can see the accumulated scope set. Separately, the IETF step-up-authentication-challenge draft flags that step-up challenge parameters (e.g., `acr_values`) can leak which users hold higher-privilege/higher-sensitivity resources, explicitly citing spear-phishing targeting as the risk, and notes an RS "MAY return a challenge without verifying the client presented a valid token" — meaning an unauthenticated probe can, in some implementations, surface whether a step-up-gated (i.e., existing, sensitive) resource is present. [gnap-rfc9635 gap noted; step-up-authn draft cited via general OAuth search, not separately re-fetched — treat as directional]

## SOURCES

**fhir-searchparameter**
URL: https://hl7.org/fhir/searchparameter.html
Accessed: 2026-08-19

**fhir-capabilitystatement-search**
URL: https://build.fhir.org/capabilitystatement-search.html
Accessed: 2026-08-19
Quote: "There can only be one REST declaration per mode, and a given resource can only be described once per RESTful mode."

**fhir-search-base**
URL: https://www.hl7.org/fhir/R4/search.html
Accessed: 2026-08-19
Quote: "servers can choose how to sort the return results, though they SHOULD honor the _sort parameter"

**fhir-search-build**
URL: https://build.fhir.org/search.html
Accessed: 2026-08-19
Quote: "Observation searches might require that the category parameter be present... these permitted combinations can be conveyed by extensions on the CapabilityStatement"

**openbanking-transactions**
URL: https://openbankinguk.github.io/read-write-api-site2/standards/v3.1.3/resources-and-data-models/aisp/Transactions/
Accessed: 2026-08-19
Quote: "GET /transactions?fromBookingDateTime=2015-01-01T00:00:00" (date-window filter pattern); BookingDateTime "set to mandatory as all ASPSPs must provide this field for pagination and filtering"

**odata-queryoptions**
URL: https://learn.microsoft.com/en-us/odata/concepts/queryoptions-overview
Accessed: 2026-08-19

**odata-centric-drawbacks**
URL: https://careers.centric.eu/ro/about-us/what-we-do/exploring-odata-benefits-and-drawbacks/
Accessed: 2026-08-19

**mcp-pagination-spec**
URL: https://modelcontextprotocol.io/specification/draft/server/utilities/pagination
Accessed: 2026-08-19

**mcp-pagination-chatforest**
URL: https://chatforest.com/guides/mcp-pagination-patterns/
Accessed: 2026-08-19

**uma-core-ticket**
URL: https://docs.kantarainitiative.org/uma/ed/oauth-uma-ticket-2.0-00.html
Accessed: 2026-08-19
Quote: "At least one of the provided resource identifiers was not found at the authorization server."

**uma-federated-authz**
URL: https://docs.kantarainitiative.org/uma/wg/rec-oauth-uma-federated-authz-2.0.html
Accessed: 2026-08-19

**oidc-core-claims**
URL: https://openid.net/specs/openid-connect-core-1_0.html
Accessed: 2026-08-19

**oidc-asc-draft**
URL: https://openid.net/specs/openid-connect-advanced-syntax-for-claims-1_0-01.html
Accessed: 2026-08-19
Quote: "Using Selective Abort/Omit (SAO), an RP can define the expected behavior of an OP when certain data is not available"

**gnap-rfc9635**
URL: https://datatracker.ietf.org/doc/html/rfc9635
Accessed: 2026-08-19
Quote: "the client instance can negotiate next steps if possible" (continuation after RO unreachable or denies request)

**smart-fhir-wellknown**
URL: https://www.hl7.org/fhir/smart-app-launch/
Accessed: 2026-08-19
Quote: "SMART defines a discovery document, available at .well-known/smart-configuration relative to a FHIR Server Base URL"

**smart-fhir-scopes-context**
URL: https://build.fhir.org/ig/HL7/smart-app-launch/scopes-and-launch-context.html
Accessed: 2026-08-19
Quote: "the scopes ultimately granted by the authorization server may differ from the scopes requested by the client"

## SYNTHESIS

**Q1 verdict:** FHIR's model transfers to PDPP more directly than any of the other three comparators, because PDPP has *already independently converged on it*. Section 7's `streams[].query.range_filters` and `streams[].query.expand` (declared per stream, server-authoritative, client must consult metadata rather than assume support) is structurally the same shape as `CapabilityStatement.rest.resource.searchParam`: a server-declared, per-resource-type capability list that the client discovers via a metadata endpoint (`GET /v1/streams/{stream}` mirrors `GET [base]/metadata`). The strongest argument *for* extending this pattern (declared-capability model) is that PDPP doesn't need to invent anything — it needs to widen `query` to also carry declared *sortable* fields (today only `range_filters` and `expand` are declared; `order` in Section 8 is a fixed `desc`/`asc` on the implicit `(cursor_field, primary_key)` sort, not a client-chosen field). The strongest argument *against* is FHIR's own admitted gap: `_sort` is SHOULD not MUST, servers diverge in practice (Azure: single-field only; Smile CDR: chained + special indexing), and there's still no standard way to declare *mandatory* parameter combinations — meaning "declared capability" solves discoverability but not the harder problem of keeping heterogeneous connector implementations interoperable at the enforcement layer, which is exactly the SMART-on-FHIR-only-works-because-FHIR-has-a-shared-resource-ontology point already recorded in spec-deferred.md's Predicate-Based Grant Scoping entry.

Open Banking is the strongest argument for staying minimal: a single regulator-mandated date-window filter, no general sort/filter grammar, and explicit normative language for degrading gracefully at range edges (return the valid subset, don't error) — this is a live, regulator-enforced, bank-scale precedent for PDPP's current six-operation base surface, not a toy comparison.

OData is useful only as the point of maximal contrast: every cited adoption cost (SQL-translation risk, N+1 via `$expand`, allow-listing every filterable/expandable property as a security boundary, in-memory-filter performance traps) is a cost PDPP's connector-manifest ecosystem — many small, independently-authored connectors — is least equipped to absorb safely. If PDPP ever considers OData-shaped query power, the manifest's `range_filters`/`expand` declarations are already the allow-list OData's own criticism says you need; the risk is scope creep past that allow-list into free-form `$filter` grammar, which spec-deferred.md's Predicate-Based Grant Scoping entry has already correctly identified and deferred for the *consent* side — this is the analogous deferral for the *query* side.

The MCP/agent-pattern research supports "stay minimal, extend via declared capability" over "add rich server-side sort": current MCP tooling consensus is small default page sizes + cursor pagination + client-side (agent-side) composition across narrow tools, not large sorted/filtered pulls from the server — i.e., agents are expected to page small windows and re-rank/re-filter in-context rather than push complex query logic to the server. This weakens the case for urgently adding OData-style richness and strengthens the case that PDPP's current base surface (limit/cursor/order/fields/changes_since/blob) plus the already-present declared `range_filters`/`expand` mechanism is closer to where agent-era clients actually want to operate than a full FHIR-search or OData surface would be. I did not find published quantitative data on MCP-client query/sync behavior specifically (sync-full-history vs. query-per-turn) — the claim above is inferred from server-design guidance aimed at MCP builders, not measured client telemetry; treat it as directional, not settled.

**Recommended framing for the design note:** present three options — (1) stay minimal (Open Banking precedent, lowest surface area, matches agent-era small-window access patterns); (2) declared-capability growth (FHIR CapabilityStatement precedent, extends the `query` block PDPP already has to add declared sortable fields — the natural next increment, not a new primitive); (3) type-driven/generic query grammar (OData precedent, rejected on adoption-cost and security-surface grounds, and already precluded in spirit by spec-deferred.md's predicate-scoping deferral). Recommend (2) as the credible next step if/when growth is needed, explicitly bounded to sort (mirroring the existing filter/expand declaration pattern), not a general filter grammar.

**Q2 verdict:** None of the four comparators gives PDPP a ready-made "optimistic ask, AS decides consent-vs-tell-the-user" flow without modification — each has a different absence-leak profile:

- **UMA 2.0**: structurally cannot do this. Resources must be pre-registered at the AS before any permission-ticket flow starts; asking for an unregistered resource is a defined *error to the resource server*, not a routable "tell the user" outcome. Absence-leak: N/A as a base flow, because UMA never lets the client name a not-yet-existing resource in the first place — the RS is the one deciding what's protected, upstream of any client ask. To adapt UMA to PDPP's optimistic-ask shape, you'd need to invert who initiates: PDPP's client-submits-a-selection-request-for-hoped-for-streams is closer to an *unregistered resource request* that UMA explicitly errors on. This is the closest-sounding prior art by name but the worst structural fit.

- **OIDC claims request (essential/voluntary)**: closest existing mechanism to "ask for something that might not exist," but Core OIDC's default behavior (silent omission, no signal distinguishing "doesn't exist" from "user declined" from "policy blocked") is exactly the absence-leak PDPP wants to avoid *for the client* — except OIDC's omission-without-explanation is arguably the safe direction (client learns nothing), which is what PDPP's design also wants. The gap OIDC has is UX, not privacy: the RP gets an unhelpful non-signal rather than a routed experience for the *user*. The ASC extension's Selective Abort/Omit is the more direct analog to "tell the user, not the client" — it's an explicit per-claim policy the RP declares, but even ASC's abort signal fires back to the client (the RP knows the transaction aborted because of *that specific claim*), so it does leak more than plain omission. This is informative but not a clean template.

- **OAuth incremental authorization / step-up**: the cited literature actively documents this as a *leaky* pattern — accumulated-scope disclosure in the request itself, and step-up challenge parameters correlating with high-value-resource holders (phishing-targeting risk), including an unauthenticated-probe vector in one draft. This is a cautionary prior art, not a template to copy: it demonstrates concretely how an optimistic/incremental ask can leak resource existence sideways (to a network observer or unauthenticated prober), which is a sharper warning than "the client learns" — it's "anyone watching the wire can infer."

- **GNAP continuation**: the best structural fit found, though under-specified in the fetched sources. GNAP already has a multi-round negotiation primitive where the AS can respond to an unreachable/denying resource owner and let the client "negotiate next steps" — this is architecturally closer to "AS routes to consent OR tells the user something, then responds to the client with a next step" than UMA or OIDC provide. This matches spec-core.md's own stated posture (Section 2: "A future version should evaluate whether GNAP is a better foundation... request continuation for multi-step consent negotiation (relevant to optional streams)") — the discovery/optimistic-ask design should treat GNAP continuation as the primitive to build on, not UMA.

- **SMART on FHIR**: doesn't solve discovery-before-consent either — `.well-known/smart-configuration` only advertises *server* capability, never *this patient's* available resources; wildcard scopes (`patient/*.cruds`) exist specifically to avoid the server having to answer "what does this patient have" at request time, deferring that question entirely into the opaque consent/grant round-trip, with grants confirmed only after the fact via introspection. This is informative as a *counter*-pattern: SMART's answer to "avoid the absence leak" is to never let the client ask a resource-specific question pre-consent at all, which is a stronger privacy posture than PDPP's owner-sketched design (which does let the client name specific hoped-for streams) but at the cost of the client not being able to request narrowly.

**Absence-leak comparison table (informal):**
| Prior art | What the CLIENT learns when data doesn't exist |
|---|---|
| UMA 2.0 | Immediate protocol error (resource not registered) — full leak to client, and it's an error not a routed experience |
| OIDC claims (Core, no ASC) | Nothing distinguishable — claim silently absent from response, same as "user declined" or "policy blocked" — best client-side privacy, worst UX |
| OIDC ASC (ext.) | Transaction-abort signal tied to a specific claim — partial leak (client knows *this* claim caused abort) |
| OAuth incremental/step-up | Accumulated scope state visible in request; step-up challenge params can correlate with resource sensitivity to any observer — leaks beyond just the client |
| SMART on FHIR | Nothing pre-consent (server capability only); post-consent, granted-scope set may silently differ from requested — no explicit "doesn't exist" signal, folded into ordinary scope-denial |
| GNAP continuation | Unspecified in fetched text, but structurally supports AS-mediated "negotiate next steps" without requiring the initial ask to already be registered — most promising SHAPE, least specified in public text |

**Recommended framing for the design note:** 2-3 viable shapes, in the order I'd prioritize: (A) **GNAP-continuation-flavored optimistic ask** — client submits a selection request naming hoped-for streams; AS either resolves immediately (stream exists, route to consent) or returns a GNAP-style "interaction needed / pending" continuation state with zero information about *why*, and separately (out-of-band, to the user only, e.g. via the AS's own notification surface) tells the user the requested data doesn't exist. Client-side leak: none beyond "not yet resolved," matching OIDC Core's silent-omission privacy posture but with an explicit pending/continuation handle instead of bare omission. (B) **SMART-style wildcard/deferred** — client requests by *capability description* (e.g., "any conversations stream, if one exists") rather than a specific stream name, deferring the exists/doesn't-exist question into the grant resolution entirely; strongest privacy, weakest client precision. (C) **UMA-adjacent explicit registration check, softened** — keep UMA's registration-gated shape but change the error contract: instead of surfacing "not found" to the client (as UMA core does), the AS returns an undifferentiated "no action taken, check back" response to the client and routes the specific reason to the user's notification surface — structurally UMA, privacy-adapted at the AS/client boundary. I'd flag (A) as the best fit given spec-core.md already names GNAP as the evaluation target for a future authorization-server interface.
