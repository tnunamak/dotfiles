---
title: "Mature data systems treat search, filter/facet, relationship, and display as separate explicitly-authored axes — never inferred from 'it's a string field'"
date: 2026-06-24
topic: data-collection-systems
tags: [search, schema-authoring, indexing, display-metadata, prior-art]
status: draft
sources: [algolia, elasticsearch, airtable, salesforce, stripe, plaid, github, slack, openapi, prisma, segment, mcp, diataxis]
---

## CLAIMS

- Algolia requires searchable attributes to be declared explicitly and warns against searching URLs or image paths; attribute order affects ranking; filter/facet fields (`attributesForFaceting`) are declared separately from searchable text — a field can be readable without being searchable or aggregatable. [algolia]
- Elasticsearch distinguishes analyzed `text` fields (full-text search) from `keyword` fields (exact match, sorting, aggregations); multi-fields give one source value several index representations without changing `_source` — retrieval/presentation declarations should not mutate record data. [elasticsearch]
- Airtable's primary field represents each record and is special for display; field type alone does not determine the record's identity label, so a client should not guess a title from "first string field." [airtable]
- Salesforce compact layouts and REST search-result layouts return, as metadata separate from object schema, which fields represent a record on constrained surfaces — result presentation is an authored contract, not something each client infers. [salesforce]
- Stripe resource objects keep IDs, expandable references, metadata, and display text as distinct semantics; Search is a separate API surface (not every resource/field is searched the same way); metadata is structured lookup context, and system IDs should be found via exact/filter affordances rather than indexed as semantic text. [stripe]
- Plaid Transactions separate merchant, geolocation, category, account, and date fields; Plaid Identity fields (name, address, phone, email) have different use/sensitivity than transaction text — names may be lexical/actor/display roles, but phone/email/address should not become semantic body fields by default. [plaid]
- GitHub issues/PRs share concepts but declare explicit fields (title, body, comments, author, PR markers) — related streams can share a role vocabulary while declaring source-specific fields. [github]
- Slack `conversations.history` returns paginated/time-bounded message records from scoped conversations, and the Conversations API unifies conversation kinds behind a common interface — chat connectors should declare message text, actor, thread/time, and bounded read-escalation affordances explicitly. [slack]
- OpenAPI's premise is that machine-readable descriptions let consumers interact with a service with minimal implementation logic — a prose-only authoring guide is not enough; the contract must be machine-enforced. [openapi]
- Prisma relations are explicit declared links between models — relationships should be declared, not discovered by clients matching `*_id` fields. [prisma]
- Segment Protocols tracking plans validate observed data against the spec and produce violations — documentation should be paired with honesty tests that fail when declarations drift. [segment]
- MCP tools are model-callable operations with names, descriptions, and schemas — output must carry enough schema metadata for a model to choose the next action without inspecting raw records. [mcp]
- Diátaxis distinguishes tutorials, how-to, reference, and explanation; an authoring guide should be a short task checklist plus examples, with deeper rationale kept in reference/design docs. [diataxis]

## SOURCES

**algolia**
URL: https://www.algolia.com/doc/api-reference/api-parameters/searchableAttributes ; https://www.algolia.com/doc/api-reference/api-parameters/attributesForFaceting
Accessed: 2026-06-24

**elasticsearch**
URL: https://www.elastic.co/docs/reference/elasticsearch/mapping-reference/text ; https://www.elastic.co/docs/reference/elasticsearch/mapping-reference/multi-fields
Accessed: 2026-06-24

**airtable**
URL: https://support.airtable.com/docs/the-primary-field ; https://support.airtable.com/docs/supported-field-types-in-airtable-overview
Accessed: 2026-06-24

**salesforce**
URL: https://developer.salesforce.com/docs/atlas.en-us.api_tooling.meta/api_tooling/tooling_api_objects_compactlayoutinfo.htm ; https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/resources_list.htm
Accessed: 2026-06-24

**stripe**
URL: https://docs.stripe.com/api ; https://docs.stripe.com/search ; https://docs.stripe.com/api/metadata
Accessed: 2026-06-24

**plaid**
URL: https://plaid.com/docs/api/products/transactions/ ; https://plaid.com/docs/api/products/identity/
Accessed: 2026-06-24

**github**
URL: https://docs.github.com/rest/issues/issues
Accessed: 2026-06-24

**slack**
URL: https://docs.slack.dev/reference/methods/conversations.history ; https://docs.slack.dev/apis/web-api/using-the-conversations-api
Accessed: 2026-06-24

**openapi**
URL: https://spec.openapis.org/oas/v3.2.0.html
Accessed: 2026-06-24

**prisma**
URL: https://www.prisma.io/docs/orm/prisma-schema/data-model/relations
Accessed: 2026-06-24

**segment**
URL: https://www.twilio.com/docs/segment/protocols/tracking-plan/create
Accessed: 2026-06-24

**mcp**
URL: https://modelcontextprotocol.io/specification/2025-06-18/server/tools
Accessed: 2026-06-24

**diataxis**
URL: https://diataxis.fr/
Accessed: 2026-06-24

## SYNTHESIS

Five reusable findings for anyone authoring a data/connector schema: (1) mature systems separate schema/type from search, filter, relation, and display behavior and keep them as independent declarations; (2) search configuration must be explicit — good search products do not blindly search every string, they prioritize natural-language fields and exclude URLs, paths, hashes, status codes, and IDs; (3) presentation is authored metadata (Airtable primary field, Salesforce compact layouts show constrained surfaces need explicitly-chosen display fields), not inferred from field order or type; (4) relationships are contracts — explicit relation metadata (Prisma/OpenAPI style) beats clients guessing from `*_id`; (5) documentation must be backed by enforcement — Segment-style validation that fails when live artifacts drift. The operational consequence: require every stream to declare at least one presentation role and at most one primary-title, require top-level natural-language fields to be searchable unless intentionally excluded by rule, keep a formatting type separate from a placement role, and write the authoring guide as a short review checklist that points to honesty tests rather than a long field-by-field taxonomy essay.
