---
title: "Major API platforms (Stripe, Linear, Plaid, Vercel) converge on REST with kebab-case paths and consistent namespacing (Stripe: /v1/{domain}/{resource}, Linear: GraphQL /graphql, Plaid: /link / /accounts / resource-typed paths); GraphQL avoids HTTP verb semantics; no industry consensus on versioning (URL path vs header)"
date: 2026-08-04
topic: api-contract-design
tags: [api-design, rest, graphql, naming-conventions, stripe, linear, plaid, vercel]
status: draft
sources: [stripe-docs, linear-api, plaid-docs, vercel-docs, nordicapis]
source_session: adc05a9e-a747-4eea-a6c5-ac8954657dd1
---

## CLAIMS
- Stripe REST: `/v{version}/{domain}/{resource}[/{id}][/{sub-resource}]` with snake_case resource names, e.g. `/v1/charges`, `/v1/payment_intents` [stripe-docs]
- Linear uses GraphQL `/graphql` endpoint (single POST target) with camelCase field names; avoids HTTP verb semantics entirely [linear-api]
- Plaid REST: `/accounts`, `/link`, `/products/{product}` with kebab-case paths; resource naming is semantic not numeric [plaid-docs]
- Vercel REST: `/v{version}/` prefix, kebab-case paths (`/deployments`, `/analytics`), JSON request/response bodies [vercel-docs]
- No industry consensus on versioning placement: Stripe uses URL path (/v1/); GraphQL APIs often omit version (schema is authoritative) [nordicapis]

## SOURCES
**stripe-docs**
URL: https://docs.stripe.com/api
Accessed: 2026-08-04
Quote: "API structure: /v1/{domain}/{resource}[/{id}][/{sub-resource}]; snake_case resource names"

**linear-api**
URL: https://api.linear.app/graphql
Accessed: 2026-08-04
Quote: "GraphQL endpoint at /graphql; camelCase fields; no explicit versioning in URL"

**plaid-docs**
URL: https://plaid.com/docs/api/
Accessed: 2026-08-04
Quote: "REST endpoints: /accounts, /link, /products/{product}; kebab-case resource paths; semantic naming"

**vercel-docs**
URL: https://vercel.com/docs/rest-api
Accessed: 2026-08-04
Quote: "API: /v{version}/ prefix; kebab-case paths; JSON bodies; consistent across all resources"

**nordicapis**
URL: https://nordicapis.com/4-popular-apis-with-great-naming-conventions/
Accessed: 2026-08-04
Quote: "Versioning strategies vary: URL path (Stripe, Vercel), headers, or schema-driven (GraphQL); no consensus"

## SYNTHESIS
REST APIs prefer kebab-case paths and explicit resource naming (Stripe, Plaid, Vercel). GraphQL APIs (Linear) use a single endpoint and camelCase field names, eliminating HTTP verb semantics entirely. Versioning is fragmented: Stripe embeds version in URL paths (/v1/); GraphQL APIs often rely on schema evolution. For new REST APIs, follow Stripe/Vercel's pattern: `/v{version}/{resource}[/{id}][/{sub-resource}]` with kebab-case. For GraphQL, adopt a single `/graphql` endpoint with camelCase fields and schema-versioned evolution. No single "best" approach; choose based on your client ecosystem and backward-compatibility needs.

Related: [[api-contract-design/javascript-contracts-should-ship-as-pinned-packages-while-source-json-and-release-artifacts-remain-authoritative]], [[api-contract-design/reverse-filter-via-relationship-is-a-constrained-alternative-to-reverse-expansion]]
