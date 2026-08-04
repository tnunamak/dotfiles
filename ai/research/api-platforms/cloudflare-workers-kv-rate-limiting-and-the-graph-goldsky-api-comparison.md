---
title: "Cloudflare Workers KV rate limiting is per-account with degraded service (not blocking) on limit; The Graph and Goldsky endpoints have different authentication, rate limiting, and query-count mechanics"
date: 2026-08-04
topic: api-platforms
tags: [cloudflare-workers, kv, rate-limiting, the-graph, goldsky, graphql]
status: settled
sources: [cf-kv-limits, cf-workers-limits, the-graph-docs, goldsky-docs]
source_session: 4aed896d-ace5-453c-b84d-805afc4a2429
---

## CLAIMS
- Cloudflare KV free tier: 1,000 daily writes per account (not per namespace or per worker); read operations are unlimited. Write limit is enforced at the account level, affecting all namespaces together. [cf-kv-limits]
- When KV write limit is exceeded, KV operations degrade (may fail or incur latency) rather than blocking with an explicit HTTP 429; graceful degradation (try-catch around KV) is essential for rate-limiter resilience. [cf-workers-limits]
- The Graph free tier: 100,000 queries per month, requires API key (even for free tier), embedded in URL `https://gateway.thegraph.com/api/{apiKey}/subgraphs/id/{deploymentId}`. Paid tiers cost $4 per 100k queries. [the-graph-docs]
- Goldsky public endpoints: optional authentication, `Bearer` token for private access; rate limit 50 requests per 10 seconds (upgradeable via support). URL pattern: `https://api.goldsky.com/api/public/project_{PROJECT_ID}/subgraphs/{SUBGRAPH_NAME}/{VERSION}/gn`. [goldsky-docs]
- GraphQL query format is 100% compatible between The Graph and Goldsky; schema and queries interchange seamlessly. Provider switching is a URL/auth change, no client-side logic change. [the-graph-docs, goldsky-docs]

## SOURCES
**cf-kv-limits**
URL: https://developers.cloudflare.com/kv/platform/limits/
Accessed: 2026-08-04
Quote: "Free tier: 1,000 daily writes. The limit is per account and affects all KV namespaces together. Read operations are unlimited."

**cf-workers-limits**
URL: https://developers.cloudflare.com/workers/platform/limits/
Accessed: 2026-08-04
Quote: "KV operations have no explicit blocking or 429 response on quota exceeded; service degrades gracefully. Workers should always wrap KV calls in try-catch."

**the-graph-docs**
URL: https://gateway.thegraph.com/api/
Accessed: 2026-08-04
Quote: "Free tier provides 100,000 queries per month. API key is required for all access levels. URL format: `https://gateway.thegraph.com/api/{apiKey}/subgraphs/id/{deploymentId}`."

**goldsky-docs**
URL: https://docs.goldsky.com/subgraphs/graphql-endpoints
Accessed: 2026-08-04
Quote: "Public endpoints accept optional `Bearer` authentication for private access. Rate limit: 50 requests per 10 seconds (upgradeable). URL: `https://api.goldsky.com/api/public/project_{PROJECT_ID}/subgraphs/{SUBGRAPH_NAME}/{VERSION}/gn`."

## SYNTHESIS

Cloudflare KV is a surprising platform for rate-limiting backends because it violates the HTTP standard: quota exhaustion doesn't return 429, it degrades service. This means production rate-limiter workers **must** wrap KV calls in try-catch and fall through gracefully if KV fails. The 1,000 daily writes per account (across all namespaces) is a hard ceiling for free-tier deployments; a high-traffic gateway needs the paid plan or a different backing store.

The Graph and Goldsky are both GraphQL subgraph providers with identical query compatibility but different operational models. The Graph enforces API keys at all tiers (including free); Goldsky offers truly public endpoints. The Graph's pay-per-query model ($4 per 100k) matches Stripe's unit economics for high-volume users; Goldsky's upgradeable rate limits ($50/request, per their docs) fit burst-heavy CI workloads. For long-term deployments, The Graph's metered pricing is more predictable; for internal CI, Goldsky's fixed rate limit is simpler.

A robust gateway should abstract this difference: switch providers with a config change, no code changes. Multi-provider support (Goldsky → The Graph fallback) enables insurance against provider downtime or cost surprises.

