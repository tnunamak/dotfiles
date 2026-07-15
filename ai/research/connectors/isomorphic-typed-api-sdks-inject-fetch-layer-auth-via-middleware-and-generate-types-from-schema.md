---
title: "The 2026 consensus for isomorphic typed API SDKs is an injectable fetch defaulting to globalThis.fetch, middleware/closure auth, typed error hierarchies, auto-pagination iterators, and types generated from a schema"
date: 2026-06-11
topic: connectors
tags: [sdk-design, isomorphic, openapi, typescript, stripe, supabase, plaid, zod]
status: draft
sources: [stripe-node, supabase-js, openapi-fetch, openapi-typescript, plaid-node, hey-api, openapi-zod-client]
---

## CLAIMS

- Stripe's `stripe-node` defines a thin abstract `HttpClient` interface (`makeRequest`) with a Node default (`NodeHttpClient`, built-in `http`) and a browser `FetchHttpClient` (`globalThis.fetch`); callers inject any conforming client via `new Stripe(key, { httpClient })`, so the SDK never unconditionally imports `node:http`. [stripe-node]
- Stripe uses a single `StripeError` base class with typed subtypes (`StripeAPIError`, `StripeConnectionError`, `StripeInvalidRequestError`, etc.) carrying `.code`, `.statusCode`, `.type`, `.param`; and list endpoints expose `.autoPagingEach(fn)` and `[Symbol.asyncIterator]()` for transparent cross-page iteration. [stripe-node]
- Stripe's public TypeScript types are hand-maintained and track only the latest API version, with a separate `@stripe/stripe-js` browser package. [stripe-node]
- `supabase-js` is an explicitly isomorphic library that uses `globalThis.fetch` uniformly (available in browser and Node 18+) and accepts a custom `fetch` at construction (e.g. SvelteKit's enhanced `fetch` in server load functions) — the modern "just accept a fetch function" approach rather than an HttpClient hierarchy. [supabase-js]
- `openapi-fetch` is ~6 kB, zero-runtime, browser+Node, wraps `globalThis.fetch`, accepts a custom `fetch` in `createClient({ baseUrl, fetch })`, and injects auth via composable middleware (`client.use({ onRequest })`), cleanly separating auth from transport. [openapi-fetch]
- `openapi-typescript` generates type-only `.d.ts` from any OpenAPI 3.0/3.1 spec and can fetch the spec from a live URL (`npx openapi-typescript https://.../openapi.json -o types.d.ts`); paired with `openapi-fetch` (`createClient<paths>(...)`) this yields fully typed requests/responses with zero runtime overhead. [openapi-typescript]
- Supabase generates database types from a live schema via a thin CLI (`supabase gen types` → `types/supabase.ts`) — a precedent for a bespoke generator that introspects a live schema and emits TypeScript. [supabase-js]
- Plaid's `plaid-node` is auto-generated from OpenAPI via `openapi-generator`, uses `axios` under the hood, and is primarily Node-targeted (not meaningfully isomorphic); its `Configuration` accepts `baseOptions` for auth — illustrating the downsides of generated axios clients (large bundle, awkward in browser/edge, harder to mock). [plaid-node]
- Zod schema-first SDKs derive types via `z.infer<>` and validate responses at runtime, but add bundle weight (~60 kB; Zod v4 ~15 kB min+gzip) and per-response latency; schemas must still be kept in sync with the live API or generated from it. [hey-api][openapi-zod-client]
- `openapi-typescript`/`openapi-fetch` are used by Vercel, OpenCode, and PayPal (per hey-api docs). [hey-api]

## SOURCES

**stripe-node**
URL: https://github.com/stripe/stripe-node
Accessed: 2026-06-11
Additional: https://raw.githubusercontent.com/stripe/stripe-node/master/src/RequestSender.ts ; https://raw.githubusercontent.com/stripe/stripe-node/master/README.md ; src/net/FetchHttpClient.ts ; src/net/HttpClient.ts ; src/stripe.core.ts

**supabase-js**
URL: https://supabase.com/docs/reference/javascript/introduction
Accessed: 2026-06-11

**openapi-fetch**
URL: https://openapi-ts.dev/openapi-fetch/
Accessed: 2026-06-11
Additional: https://openapi-ts.dev/openapi-fetch/api ; https://openapi-ts.dev/openapi-fetch/middleware-auth

**openapi-typescript**
URL: https://openapi-ts.dev/introduction
Accessed: 2026-06-11
Additional: https://openapi-ts.dev/cli

**plaid-node**
URL: https://raw.githubusercontent.com/plaid/plaid-node/master/README.md
Accessed: 2026-06-11

**hey-api**
URL: https://github.com/hey-api/openapi-ts
Accessed: 2026-06-11

**openapi-zod-client**
URL: https://github.com/astahmer/openapi-zod-client
Accessed: 2026-06-11

## SYNTHESIS

The modern consensus for a typed, isomorphic HTTP-API SDK (2026):
1. Accept an injectable `fetch` defaulting to `globalThis.fetch` — sufficient for isomorphism now; a full `HttpClient` interface hierarchy (Stripe) is the heavier alternative, only needed for non-fetch transports.
2. Layer auth via middleware or a capturing closure, not hardcoded headers (openapi-fetch's `onRequest` middleware is the clean pattern).
3. Provide typed error classes with structural `.code`/`.status` fields under a single base error.
4. Provide auto-pagination async iterators for list endpoints.

Schema→types generation, three options:
- Emit OpenAPI from the server and run `openapi-typescript` + `openapi-fetch` — leverages a battle-tested ecosystem, but dynamic/per-tenant field schemas must be expressed generically (`additionalProperties`), reducing payload-type precision; structural path-keyed types are ergonomic in openapi-fetch but verbose by hand.
- A bespoke generator that fetches a custom capability/schema document and emits `.d.ts` — highest fidelity to a non-OpenAPI schema, at the cost of building/maintaining the generator (Supabase's `gen types` is the precedent).
- Zod schema-first with runtime validation — catches server response regressions at the SDK boundary, best where responses are untrusted or the server may lag the client, but heaviest; a middle path is Zod for request-parameter validation only.

Avoid the Plaid-style generated axios client if isomorphism/edge/browser use or easy mocking matters. Enforcement discipline worth copying: dogfood the SDK (Stripe's own dashboard uses the public `stripe-node`), enforce package boundaries structurally, back them with `no-restricted-imports` lint rules, and let generated types be the mechanical enforcer (a server response-shape change that isn't reflected in the SDK becomes a downstream TypeScript error).
