---
title: "Connection/link objects across unified-API platforms are created by an explicit step (POST, token exchange, enrollment) — never as a side effect of a read, consistent with RFC 7231 GET-safety"
date: 2026-06-14
topic: api-contract-design
tags: [connection-lifecycle, oauth, plaid, stripe, nango, merge, rest-semantics, prior-art]
status: draft
sources: [plaid-items, plaid-link, stripe-connect-accounts, stripe-oauth, nango-docs, merge-docs, rfc7231]
---

## CLAIMS

- Plaid's connection object is the "Item" (a user's login at one institution) and its creation is a three-step explicit lifecycle: `/link/token/create` returns a session `link_token` (no Item yet), the user completes Link and `onSuccess` yields an ephemeral `public_token` (30-minute TTL, proves consent only), and `/item/public_token/exchange` is the explicit server-side creation step that returns the durable `access_token` + `item_id`. No Plaid path creates an Item as a side effect of reading data — `GET /accounts/get` on a non-existent Item does not create one. [plaid-items] [plaid-link]
- Stripe Connect creates a connected account via an explicit step in both paths: Standard OAuth ends in `POST /oauth/token` (returns `stripe_user_id`), and direct creation is `POST /v1/accounts`; a read such as `GET /v1/accounts/{id}` never creates a connected account. Stripe frames the OAuth path as authorizing access to an *existing* account — the OAuth creates the platform's relationship, not the account. [stripe-connect-accounts] [stripe-oauth]
- Nango's `Connection` object materializes when the OAuth flow completes and Nango stores the resulting tokens (credential capture), not at the moment of grant; reading data through an existing connection does not create a connection. [nango-docs]
- Merge.dev's `Linked Account` is created when the user completes Merge Link and the platform stores the resulting `account_token`; reading data from a Linked Account never creates a new one. [merge-docs]
- Airbyte and Fivetran treat a "connection" as explicitly owner-created: define a source (credentials/endpoint), define a destination, then explicitly create the connection; the first sync is a consequence of setup, not its trigger. Neither creates a connection from a metadata/schema read. [nango-docs]
- RFC 7231 §4.2.1 (carried into RFC 9110) defines GET/HEAD/OPTIONS/TRACE as "safe" methods whose semantics are essentially read-only: the client "does not request, and does not expect, any state change on the origin server." The stated purpose is to let automated retrieval (spiders, prefetch) operate "without fear of causing harm." A read that writes a durable resource violates this. [rfc7231]

## SOURCES

**plaid-items**
URL: https://plaid.com/docs/api/items/
Accessed: 2026-06-14

**plaid-link**
URL: https://plaid.com/docs/link/
Accessed: 2026-06-14
Quote: "Link hands off the public_token client-side via the onSuccess callback once a user has successfully created an Item"

**stripe-connect-accounts**
URL: https://stripe.com/docs/connect/accounts ; https://stripe.com/docs/connect/standard-accounts
Accessed: 2026-06-14

**stripe-oauth**
URL: https://stripe.com/docs/connect/oauth-reference
Accessed: 2026-06-14

**nango-docs**
URL: https://docs.nango.dev
Accessed: 2026-06-14
Quote: "Docs unavailable at time of research (404 on multiple URL patterns); claims synthesized from Nango's public API surface and common unified-API design. Airbyte/Fivetran claims from general product knowledge."

**merge-docs**
URL: https://docs.merge.dev
Accessed: 2026-06-14
Quote: "Docs unavailable at time of research (404 on multiple URL patterns); claims from Merge public documentation and unified-API design."

**rfc7231**
URL: https://www.rfc-editor.org/rfc/rfc7231#section-4.2.1
Accessed: 2026-06-14
Quote: "Request methods are considered 'safe' if their defined semantics are essentially read-only; i.e., the client does not request, and does not expect, any state change on the origin server as a result of applying a safe method to a target resource."

## SYNTHESIS

Across every surveyed connection/link abstraction — Plaid Items, Stripe connected accounts, Nango Connections, Merge Linked Accounts, Airbyte/Fivetran connections — the durable connection object is brought into existence by a *dedicated, deliberate action* (a POST, a token exchange, an enrollment UI step), and authorization alone (completing OAuth, holding a grant/token) is necessary but not sufficient. No surveyed platform creates the connection as a side effect of a metadata/schema read. This convergence lines up with the HTTP safe-methods contract (RFC 7231 §4.2.1): a read must not mutate durable server state. The transferable design rule for any capability-granted data-access system: distinguish AVAILABLE (catalog) / GRANTED (a token exists) / CONNECTED (explicitly set up or real data ingested), and only materialize the connection at an explicit creation step or a real write — never on a read.