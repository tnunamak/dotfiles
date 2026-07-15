---
title: "node-oidc-provider can express custom Rich Authorization Requests but its RAR feature is experimental, it has no atomic single-use-token primitive, and it is Koa-native inside a Fastify app"
date: 2026-06-11
topic: oauth-mcp-auth
tags: [oauth, oidc-provider, rich-authorization-requests, rfc9396, koa, fastify, build-vs-buy]
status: draft
sources: [oidc-provider-readme, oidc-provider-npm, oidc-provider-repo]
---

## CLAIMS

- `oidc-provider` (panva/node-oidc-provider), evaluated at version 9.8.4 (latest at access date), exposes RFC 9396 Rich Authorization Requests via `features.richAuthorizationRequests` with a `validate(ctx, value, client)` hook and `rarForAuthorizationCode` / `rarForCodeResponse` / `rarForBackchannelResponse` transformers. [oidc-provider-readme]
- The `richAuthorizationRequests` feature is experimental: it requires `ack: 'experimental-01'`, and the docs state "Breaking changes between experimental feature updates may occur and these will be published as MINOR semver oidc-provider updates." [oidc-provider-readme]
- The library's `Grant` model exposes `addRar` (alongside `addOIDCScope`, `addResourceScope`, `save`), so a custom RAR type and custom fields (e.g. arbitrary `streams[].fields`, `access_mode`, `purpose_code`) round-trip through the grant — RAR is genuinely free-form. [oidc-provider-readme]
- `oidc-provider` has no atomic single-use / consume-once token primitive; a "single_use" semantic is opaque data to the library and must be enforced at the introspection/resource-server layer by the application. [oidc-provider-readme]
- Custom consent is supported via `interactions.url(ctx, interaction)` redirecting to your own consent UI, building a `Grant`, calling `Grant.prototype.save()`, returning `{ consent: { grantId } }`; `loadExistingGrant` lets you bypass the library's default OIDC scope-consent checks for first-party flows. [oidc-provider-readme]
- `features.resourceIndicators` (RFC 8707) is present, but its `getResourceServerInfo` helper ships as a placeholder the integrator MUST replace. [oidc-provider-readme]
- `extraParams` registers extra authorization-request params into `ctx.oidc.params`. [oidc-provider-readme]
- `oidc-provider` is Koa-native; mounting it in a Fastify/Express app requires a bridge such as `@fastify/middie` or `@fastify/express` (`fastify.use('/oidc', provider.callback())`), running a Koa request lifecycle inside the host app. [oidc-provider-readme]
- The running library at 9.8.4 emitted "WARNING: Unsupported runtime. Use Node.js v22.x LTS" — it pins an LTS engine. [oidc-provider-readme]

## SOURCES

**oidc-provider-readme**
URL: https://raw.githubusercontent.com/panva/node-oidc-provider/main/docs/README.md
Accessed: 2026-06-11
Quote: "Breaking changes between experimental feature updates may occur and these will be published as MINOR semver oidc-provider updates."

**oidc-provider-npm**
URL: https://npmjs.com/package/oidc-provider
Accessed: 2026-06-11
Quote: "oidc-provider@9.8.4"

**oidc-provider-repo**
URL: https://github.com/panva/node-oidc-provider
Accessed: 2026-06-11

## SYNTHESIS

When evaluating `node-oidc-provider` as a drop-in OAuth/OIDC authorization server for a product with a custom grant model, the executed spike (mounting 9.8.4, driving a custom-typed `authorization_details` through the library's own hooks) shows:

- Expressibility is not fit. A custom RAR type and its bespoke fields round-trip cleanly (the `validate` hook fires; custom fields survive into the grant via `Grant.addRar`), so the library can *carry* a novel grant model. But the library is OIDC-first: it forces dev signing keys/`jwks`, `devInteractions`, and OIDC scope/claims consent machinery you must actively disable to reach a non-OIDC consent model.
- Any product-defining "consume-once" / single-use token semantic has no library equivalent and must live at the introspection/RS layer regardless — this is the decisive negative finding for products whose differentiator is a non-standard token lifecycle.
- Real integration costs beyond code: a Koa-in-Fastify mount (two middleware models in one process), an LTS engine pin, and an experimental RAR flag whose breaking changes arrive in MINOR version bumps — a material stability liability for anything that must be spec-faithful and long-lived.
- General build-vs-buy heuristic surfaced: outsource a commodity surface only once it is *settled*; drawing a library boundary through code that is still actively changing freezes in-flight design into an external contract at the moment of least certainty. And for a *reference* implementation (whose value is being read to learn the protocol), a framework black-box raises the cost of the artifact's primary use case, tilting the decision toward keeping commodity plumbing inspectable and first-party.
