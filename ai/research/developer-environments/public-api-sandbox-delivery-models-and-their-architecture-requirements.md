---
title: "Public interactive API/protocol sandboxes cluster into three delivery models (shared multi-tenant mock, per-visitor ephemeral instance, local-run try-it), each forcing a different auth, state-reset, and abuse-mitigation architecture on the underlying app"
date: 2026-08-14
topic: developer-environments
tags: [sandbox, api-design, oauth, mcp, developer-experience, multi-tenancy, plaid, stripe, matrix]
status: draft
sources: [stripe-sandboxes, stripe-test-clocks, plaid-sandbox, plaid-institutions, plaid-test-credentials, oidc-playground, oauth-com-playground, swagger-petstore, swagger-petstore-repo, countries-graphql, github-graphql-explorer-retired, matrix-public-homeserver, matrix-ratelimiting, cloudflare-remote-mcp-authless, cloudflare-remote-mcp-oauth-demo, mcp-transport-2026-07-28, mcp-auth-spec-evolution, mcp-oauth-resource-server]
source_session: d06ef289-97a6-443b-8962-fa73c26c141c
---

## CLAIMS

**Delivery model comparison**
- Stripe's sandbox model is per-team/per-user isolated environments provisioned on demand from the Dashboard or CLI (`stripe sandbox create`), not one shared mock — "your team can test in separate sandboxes to make sure that data and actions are completely isolated from other sandboxes," and external users (implementation partners, agencies) can be invited into a specific sandbox without live-mode access. [stripe-sandboxes]
- Stripe explicitly positions sandbox creation as agent-friendly and account-free: "Coding agents should install the Stripe CLI... and run `stripe sandbox create --help` to provision an anonymous Stripe sandbox with working API keys. No account registration required." [stripe-sandboxes]
- Plaid's Sandbox is a single shared, always-on environment (`sandbox.plaid.com`) rather than per-visitor provisioned instances — any developer with sandbox API keys hits the same environment and the same set of fixed named test institutions. [plaid-sandbox] [plaid-institutions]
- Plaid documents Sandbox as intentionally lower-fidelity than Production: "the Sandbox environment provides capabilities for testing core use cases, but does not reflect the full scope and complexity of data that can exist in Production," recommending a follow-up Trial-plan Production test. [plaid-sandbox]
- Swagger Petstore is a single, permanently shared, stateful demo instance (`petstore.swagger.io` / `petstore3.swagger.io`) that lets anonymous visitors add/delete pets directly against the live shared demo data via "Try it out," with no per-visitor isolation. [swagger-petstore] [swagger-petstore-repo]
- The Petstore server itself is a small reference implementation (a Java/Jetty stand-alone server built on the swagger-inflector framework) that can also be run entirely locally via Docker, illustrating the "local-run try-it" delivery model as an alternative to the hosted shared demo. [swagger-petstore-repo]
- countries.trevorblades.com is a single shared, read-mostly public GraphQL API/playground with no visitor accounts or write mutations, sidestepping multi-tenant isolation concerns entirely by only exposing reference data. [countries-graphql]
- GitHub retired its built-in browser GraphQL Explorer (removed from docs November 11, 2025) in favor of directing users to third-party GraphiQL-style clients (GraphiQL, Insomnia, Altair) that visitors run locally/in-browser against GitHub's real API using their own personal access token — a shift from "hosted shared playground" toward "bring-your-own-client against the real authenticated API." [github-graphql-explorer-retired]
- The OpenID Connect Playground (openidconnect.net) and oauth.com's playground are both "local-run/browser-side try-it" tools: they don't host their own fake IdP by default, they require the visitor to register the playground's fixed callback URL (`https://openidconnect.net/callback`) against the visitor's own or a real third-party OIDC provider, and the playground orchestrates the code-exchange steps for the visitor without needing tenant isolation. [oidc-playground] [oauth-com-playground]
- Matrix.org's public homeserver (`matrix.org`) is a shared multi-tenant deployment open to public self-registration, not per-visitor ephemeral instances, and is metered per-account rather than isolated per-user: "a data usage limit of 500MB per 24 hour period, up to a limit of 2GB per 28 days" for accounts not on a paid plan. [matrix-public-homeserver]
- Cloudflare ships a one-command deployable "authless" remote MCP demo template (`npm create cloudflare@latest -- my-mcp-server --template=cloudflare/ai/demos/remote-mcp-authless`) that deploys the visitor's own dedicated Worker instance rather than pointing at one shared Cloudflare-hosted demo endpoint — i.e., Cloudflare's MCP sandbox story is "you provision your own throwaway instance," not "here is our shared public MCP demo server." [cloudflare-remote-mcp-authless]

**Seeded fake-data strategies**
- Stripe seeds no fixed global fixture; instead sandbox test balances/data accumulate from whatever the developer creates via test-mode API calls or the CLI's `stripe fixtures trigger` command, which replays a JSON-described sequence of API calls into the sandbox. [stripe-sandboxes]
- Stripe additionally offers "test clocks" for deterministic time-travel over sandbox objects: "a test clock enables deterministic control over objects in test mode, allowing you to create objects at a frozen time in the past or future, and advance to a specific future time to observe webhooks and state changes"; deleting the associated simulation deletes its test customers and cancels their subscriptions, giving a clean per-simulation teardown. [stripe-test-clocks]
- Plaid seeds Sandbox with a fixed, named set of fake institutions (e.g., "Platypus Bank," "Houndstooth Bank," "Windowpane Bank") plus a documented set of magic test credentials/usernames (e.g., `user_good`, and password strings like `error_ITEM_LOCKED`) that deterministically trigger specific success/error scenarios, alongside an explicit "customize test data" endpoint (`/sandbox/public_token/create`) for generating arbitrary per-test Items on demand. [plaid-institutions] [plaid-test-credentials]
- Swagger Petstore uses live, visitor-mutable shared state with no visible reset guarantee documented for the public hosted instance — any visitor's "Try it out" add/delete pet calls persist against the same shared dataset other visitors see. [swagger-petstore]
- countries.trevorblades.com uses fixed, versioned reference fixture data (a countries/continents/languages dataset) that is read-only from the API consumer's perspective, so there is no reset problem to solve. [countries-graphql]

**Auth story for anonymous visitors**
- Stripe gives every account four keys by default, two live and two sandbox (secret + publishable), and now offers CLI-driven anonymous sandbox creation with working API keys and no account registration at all for agent/dev use. [stripe-sandboxes]
- Plaid requires a real (free) developer account to obtain Sandbox API keys, but once obtained, all Sandbox institutions are accessible with published test usernames/passwords rather than real banking credentials — i.e., authenticated developer, fake end-user credentials. [plaid-sandbox] [plaid-test-credentials]
- The OIDC Playground and oauth.com playground require the visitor to already have (or register) an OAuth/OIDC client against a real or self-run identity provider; the playground itself performs no IdP hosting, so "anonymous login" is delegated entirely to whatever IdP the visitor points it at. [oidc-playground] [oauth-com-playground]
- Google's OAuth 2.0 Playground (developers.google.com/oauthplayground) proxies the visitor's real Google credentials through Google's own servers to demonstrate the flow — "your credentials will be sent to their server as a proxy for the request, though credentials will not be logged" — rather than using a fake IdP. [oauth-com-playground]
- oauthplayground.io keeps credentials and tokens entirely client-side in the browser and documents that "your authorization server must explicitly allow the site origin through CORS for token exchange to succeed" — a fully local-run auth story with no server-side proxy. [oauth-com-playground]
- Swagger Petstore's v3 hosted demo requires no authentication at all for its exposed pet endpoints (the older v2 spec had OAuth2-implicit and API-key-protected user/store endpoints, but the live v3 demo is effectively anonymous/open). [swagger-petstore-repo]
- Matrix.org's public homeserver uses standard self-service account registration (real account, no fake-IdP step) gated by IP-based registration rate limiting rather than a magic no-auth mode. [matrix-public-homeserver] [matrix-ratelimiting]
- Cloudflare's `demos/remote-mcp-server` (OAuth variant) ships with a mock login screen where "you input any email/password" and get redirected back with a working session — a fake-IdP-in-the-box pattern purpose-built for a public try-it demo of the OAuth-protected MCP flow. [cloudflare-remote-mcp-oauth-demo]
- Cloudflare's "authless" MCP template requires no authentication step at all — the tradeoff for a minimal-friction public demo is skipping the auth layer entirely rather than faking it. [cloudflare-remote-mcp-authless]

**Architecture demands**
- Stripe's per-team-isolated-sandbox model requires the underlying platform to support fully multi-tenant, independently-keyed environments that a user (or an agent) can create and destroy on demand via API/CLI, plus a time-simulation subsystem (test clocks) as a first-class object type. [stripe-sandboxes] [stripe-test-clocks]
- Plaid's single-shared-Sandbox model requires the underlying app to support a parallel, separately-addressed environment (`sandbox.plaid.com`) with Sandbox-only endpoints (e.g., `/sandbox/public_token/create`) that cannot be reached in Production, rather than per-visitor orchestration. [plaid-sandbox]
- Matrix's shared public homeserver requires account-level metering/quota enforcement (data caps) plus multi-tier rate limiting inside the reference server implementation (Synapse) across registration, login, message-send, and redaction categories, each keyed differently (by IP, by account, by failed-attempt count). [matrix-public-homeserver] [matrix-ratelimiting]
- The Swagger Petstore shared-mutable-demo model requires no session or multi-tenancy machinery at all, at the cost of visitors being able to see/clobber each other's demo data — an accepted tradeoff because the domain (fake pets) has no real stakes. [swagger-petstore]
- GitHub's move away from a hosted Explorer toward "run a local GraphiQL client against our real authenticated API" pushes all isolation and rate-limiting requirements onto GitHub's existing production API/token infrastructure, requiring no separate sandbox surface to build or maintain at all. [github-graphql-explorer-retired]
- Cloudflare's per-visitor-deployed authless MCP template requires the underlying app to have almost no server-held state (each visitor gets a private Worker instance), while its OAuth demo variant requires the app to implement (or delegate to) a full OAuth authorization-server role, including a mock/dummy user-consent screen. [cloudflare-remote-mcp-authless] [cloudflare-remote-mcp-oauth-demo]

**MCP-specific considerations for a public demo endpoint**
- As of the 2026-07-28 MCP specification revision, the protocol was made stateless at the transport layer: the `initialize`/`initialized` handshake and the `Mcp-Session-Id` header were removed, and "every request now self-describing via inline `_meta` fields for protocol version, client identity, and capabilities" — explicitly to eliminate the sticky-session/shared-Redis/packet-inspecting-gateway operational burden that stateful Streamable HTTP or legacy SSE imposed on public deployments. [mcp-transport-2026-07-28]
- Before that revision, a stateful Streamable-HTTP MCP server assigns a session at initialization via an `Mcp-Session-Id` header, must reject subsequent requests lacking it with HTTP 400, and (per official SDK guidance) legacy HTTP+SSE transport should be enabled "only for completely trusted clients in isolated processes" plus HTTP rate-limiting middleware, because the SSE transport's immediate-202-Accepted POST semantics provide no HTTP-level backpressure on handler concurrency — a specific, documented abuse vector for public MCP endpoints. [mcp-transport-2026-07-28]
- Benchmarks cited for Streamable HTTP vs. legacy SSE show materially different throughput ceilings under concurrency (roughly 290-300 req/s for shared-session-pool Streamable HTTP vs. 29-36 req/s for SSE), relevant to capacity planning a public tool-calling endpoint. [mcp-transport-2026-07-28]
- The MCP authorization spec evolved from ad-hoc API keys, through OAuth 2.1 + PKCE with authorization-server metadata discovery (March 2025), to a June 2025 revision requiring RFC 9728 Protected Resource Metadata (`/.well-known/oauth-protected-resource`) so a public MCP server can advertise which external authorization server issues its tokens, while explicitly prohibiting the MCP server from passing through client-issued tokens to any upstream API ("confused deputy" prevention). [mcp-auth-spec-evolution]
- The November 2025 MCP spec baseline requires remote servers "intended for public use" to implement the full OAuth 2.1 + PKCE flow, while treating a bare bearer token or network-perimeter control (e.g. Cloudflare Access) as acceptable only for internal/trusted-network MCP deployments, not for a server meant to be hit by arbitrary third-party agents. [mcp-oauth-resource-server]
- Concrete public-MCP-endpoint security incidents have already occurred: the widely used `mcp-remote` OAuth-proxy library had a vulnerability where a malicious MCP server's `authorization_endpoint` value was passed unsanitized to a system shell, enabling remote code execution, and Anthropic's own MCP Inspector tool had a separate CSRF-plus-browser-flaw RCE — both cited as reasons to treat "hit an arbitrary remote MCP endpoint" as an active attack surface, not just an abuse-of-quota concern. [mcp-auth-spec-evolution]
- Cloudflare's own recommended pattern for a production-grade OAuth-protected public MCP server on Workers is a first-party `workers-oauth-provider` library that implements the OAuth 2.1 provider role, storing tokens by hash only in KV so a KV compromise cannot recover usable plaintext tokens. [mcp-auth-spec-evolution]

## SOURCES

**stripe-sandboxes**
URL: https://docs.stripe.com/sandboxes
Accessed: 2026-08-14
Quote: "Coding agents should install the Stripe CLI (`npm i -g @stripe/cli`) and run the command `stripe sandbox create --help` to provision an anonymous Stripe sandbox with working API keys. No account registration required."

**stripe-test-clocks**
URL: https://docs.stripe.com/billing/testing/test-clocks
Accessed: 2026-08-14
Quote: "A test clock enables deterministic control over objects in test mode, allowing you to create objects at a frozen time in the past or future, and advance to a specific future time to observe webhooks and state changes."

**plaid-sandbox**
URL: https://plaid.com/docs/sandbox/
Accessed: 2026-08-14
Quote: "The Sandbox environment provides capabilities for testing core use cases, but does not reflect the full scope and complexity of data that can exist in Production."

**plaid-institutions**
URL: https://plaid.com/docs/sandbox/institutions/
Accessed: 2026-08-14
Quote: "Plaid provides several Sandbox-only institutions to write integration tests against... Platypus Bank... Houndstooth Bank and Windowpane Bank."

**plaid-test-credentials**
URL: https://plaid.com/docs/sandbox/test-credentials/
Accessed: 2026-08-14
Quote: "using username user_good and modifying the password — for example, the password error_ITEM_LOCKED allows you to simulate an ITEM_LOCKED error."

**oidc-playground**
URL: https://www.openidconnect.net/
Accessed: 2026-08-14
Quote: "The 'Login redirect URIs' field has to be set to https://openidconnect.net/callback for this demo to work."

**oauth-com-playground**
URL: https://www.oauth.com/playground/oidc.html
Accessed: 2026-08-14
Quote: "generates a random string to use for the state parameter, which the client needs to store for use in a later step to protect against CSRF attacks."

**swagger-petstore**
URL: https://petstore3.swagger.io/
Accessed: 2026-08-14
Quote: "Sample Pet Store Server based on the OpenAPI 3.0 specification."

**swagger-petstore-repo**
URL: https://github.com/swagger-api/swagger-petstore
Accessed: 2026-08-14
Quote: "a stand-alone server implementing the OpenAPI 3 Spec, based on the swagger-inflector framework."

**countries-graphql**
URL: https://github.com/trevorblades/countries
Accessed: 2026-08-14
Quote: "Public GraphQL API for information about countries... You can check out the playground to explore the schema and test out some queries."

**github-graphql-explorer-retired**
URL: https://docs.github.com/en/graphql/guides/using-graphql-clients
Accessed: 2026-08-14
Quote: "The GraphQL Explorer was removed from the documentation on November 11, 2025."

**matrix-public-homeserver**
URL: https://matrix.org/homeserver/pricing/
Accessed: 2026-08-14
Quote: "a data usage limit of 500MB per 24 hour period, up to a limit of 2GB per 28 days."

**matrix-ratelimiting**
URL: https://github.com/matrix-org/synapse/issues/14780
Accessed: 2026-08-14
Quote: "one for registration that ratelimits registration requests based on the client's IP address."

**cloudflare-remote-mcp-authless**
URL: https://developers.cloudflare.com/agents/guides/remote-mcp-server/
Accessed: 2026-08-14
Quote: "npm create cloudflare@latest -- my-mcp-server --template=cloudflare/ai/demos/remote-mcp-authless."

**cloudflare-remote-mcp-oauth-demo**
URL: https://github.com/cloudflare/ai/tree/main/demos/remote-mcp-server
Accessed: 2026-08-14
Quote: "navigate to a mock login screen, input any email/password, and get redirected back to list and call tools."

**mcp-transport-2026-07-28**
URL: https://dev.to/krlz/mcp-went-stateless-what-the-2026-07-28-spec-actually-changes-273k
Accessed: 2026-08-14
Quote: "the initialize/initialized handshake and the Mcp-Session-Id header were removed, with every request now self-describing via inline _meta fields."

**mcp-auth-spec-evolution**
URL: https://medium.com/@ayshsandu/the-evolution-of-mcp-auth-every-spec-every-lesson-2024-11-05-2026-07-28-draft-e3f165a12fdb
Accessed: 2026-08-14
Quote: "RFC 9728 Protected Resource Metadata became mandatory... the June 2025 spec explicitly prohibits MCP servers from passing through tokens to upstream APIs."

**mcp-oauth-resource-server**
URL: https://www.descope.com/blog/post/mcp-auth-spec
Accessed: 2026-08-14
Quote: "The MCP server is a pure Resource Server: it validates access tokens and serves protected content, and delegates every authorization capability... to a dedicated authorization server."

## SYNTHESIS

Three delivery models recur, and they map to three different risk/cost postures, not three points on one spectrum:

1. **Shared multi-tenant mock** (Plaid Sandbox, Petstore, countries.trevorblades.com, matrix.org public homeserver) — cheapest to run, but either needs the demo domain to be genuinely stakes-free (Petstore's fake pets, read-only country data) or needs real per-account metering/rate-limiting machinery bolted onto a real multi-tenant server (Plaid, Matrix). This model breaks down fast for anything with meaningful per-visitor mutable state that visitors would be upset to see clobbered by strangers.
2. **Per-visitor ephemeral/isolated instance** (Stripe sandboxes, Cloudflare's one-command-deploy MCP template) — highest isolation, and increasingly the pattern for "give a stranger real API surface without real stakes." Stripe's `stripe sandbox create --help` (no account, no login) is the strongest precedent for PDPP's stated ambition: an anonymous visitor gets a fully working, isolated instance with zero registration friction.
3. **Local-run try-it** (OIDC Playground, oauth.com playground, GitHub's now-retired-Explorer-in-favor-of-bring-your-own-client, Petstore-via-Docker) — zero hosting cost and zero abuse surface for the operator, at the cost of requiring the visitor to already have a client/environment, which raises friction for a "just click and try" hosted sandbox.

For `sandbox.pdpp.dev` specifically, given the stated goals (grant-scoped data access flows, possibly a live MCP endpoint, possibly per-visitor dedicated instances):

- **Grant-scoped data access flow is best served by a Stripe-style per-visitor ephemeral instance, not a shared mock.** Grant scoping is exactly the kind of "this visitor's mutations must not leak into another visitor's view" property that a shared demo (Petstore-style) cannot honor credibly — a stranger revoking or re-scoping a grant needs to see *their own* clean before/after state, and Stripe's precedent (isolated sandbox per team/session, anonymous creation via CLI/API, no registration) is the closest fit. This likely means: spin up a lightweight per-visitor "Data Connect" instance (container or logical tenant) keyed to a session cookie/short-lived token, seeded with a small fixed fixture of fake personal data (closer to Plaid's named-fixture-institution model than to Stripe's blank-slate-plus-fixtures-replay model, since PDPP's demo value is showing realistic-looking data, not empty state).
- **Auth for anonymous visitors should follow Cloudflare's OAuth-demo pattern (a mock/dummy IdP with an any-email/any-password consent screen), not a fake-no-auth mode and not real credentials.** The point of the sandbox is to demonstrate the grant/consent UX itself; a no-auth shortcut would demo the wrong thing (skip the exact flow visitors are there to see), while requiring a real account creates the registration friction Stripe's anonymous-sandbox precedent shows is unnecessary. A minimal "mock IdP" screen that issues a scoped, revocable token against the visitor's own ephemeral instance mirrors both Cloudflare's demo and the OAuth-for-MCP resource-server pattern below.
- **If a live MCP endpoint is included, treat it as the highest-risk piece and scope it narrowly.** The MCP-specific research surfaces three hard requirements for any public MCP demo endpoint: (1) build against the post-2026-07-28 stateless Streamable HTTP transport, not legacy SSE — the SSE transport's lack of backpressure is a documented, named abuse vector for exactly this "anonymous agent hits a live tool-calling endpoint" scenario; (2) implement the MCP server as a pure OAuth 2.1 resource server with RFC 9728 Protected Resource Metadata, delegating token issuance to PDPP's own auth rather than minting ad hoc keys, and never pass the visitor's token through to any real backing data store (the same confused-deputy risk the spec was hardened against); (3) budget for rate limiting and a hard ceiling on tool-call cost per anonymous session — real RCE vulnerabilities have already been found in both a popular MCP OAuth-proxy library and Anthropic's own Inspector tool, so "public + anonymous + tool-calling" is an active security surface, not just a capacity-planning problem.
- **Per-visitor instance lifecycle should borrow Stripe's test-clock-style clean teardown model**: an explicit "delete this sandbox" action that tears down all associated fake data/grants/tokens together, rather than a cron-based reaper — gives visitors (and PDPP) a deterministic reset point, and avoids the Petstore failure mode of shared, silently-degrading demo state.
- Overall recommendation: **shared mock for the "look, this is what a grant flow looks like" static/read-only exploration tier (cheap, matches Petstore/countries.trevorblades.com), promoted to a per-visitor ephemeral instance the moment a visitor wants to actually mutate a grant or connect the MCP endpoint** (matches Stripe). Don't build per-visitor container orchestration for the entire sandbox surface if most visitors only ever look, not touch — gate the expensive isolated-instance path behind an explicit "start my sandbox" action, the way Stripe gates sandbox creation behind an explicit CLI/API call rather than auto-provisioning on page load.
