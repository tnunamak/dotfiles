---
title: "Unified-API platforms distinguish 'auth broke, recover in place (same identity + history)' from 'permanently deleted'; reconnect refreshes the credential on the existing connection rather than recreating it"
date: 2026-06-14
topic: api-contract-design
tags: [connection-lifecycle, reauthorization, plaid, stripe, nango, merge, oauth, prior-art]
status: draft
sources: [plaid-update-mode, plaid-items, plaid-item-login-required, stripe-oauth-deauth, nango-reauth, merge-linked]
---

## CLAIMS

- Plaid models a broken-auth connection as the Item state `ITEM_LOGIN_REQUIRED` (password change, revoked OAuth consent, expired session); recovery is Link **update mode** — the *same* `access_token` is passed into `/link/token/create`, the Item is repaired in place, and a `LOGIN_REPAIRED` webhook fires when it exits the bad state. History, records, and the app's `access_token` reference are unchanged; Plaid never creates a new Item on auth failure. [plaid-update-mode] [plaid-item-login-required]
- Plaid's other Item states form a lifecycle: `HEALTHY`, `PENDING_EXPIRATION`/`PENDING_DISCONNECT` (consent expires in 7 days, UK/EU vs US/CA — pre-emptive update mode), `ITEM_LOGIN_REQUIRED`, and other `ERROR`. Permanent deletion is a separate operation: `POST /item/remove` removes the Item, after which it returns `ITEM_NOT_FOUND` and the only recovery is creating a new Item. [plaid-items] [plaid-item-login-required]
- Stripe Connect treats `POST connect.stripe.com/oauth/deauthorize` as terminal from the platform's perspective; there is no platform-side "reactivate." Reconnecting requires re-running the OAuth connect flow, which may map back to the same underlying `stripe_user_id` but is treated as a re-initiation. Stripe Connect has no formal platform-initiated "pause then resume" state. [stripe-oauth-deauth]
- Nango surfaces a connection with expired/invalid credentials as needing re-authorization and exposes a re-auth flow that **reuses the existing connection ID** while swapping the underlying token; `DELETE /connection/{id}` is the separate terminal removal. [nango-reauth]
- Merge.dev provides a re-link URL that re-opens Link for a specific Linked Account, preserving the Linked Account ID and collected history and refreshing only the credential; a disconnected account is otherwise re-linked. [merge-linked]
- Across Plaid, Nango, Merge, and Stripe, "stop collection because a credential broke" is handled distinctly from "permanently destroy the connection": the former is recoverable in place with identity preserved; the latter is terminal (though reconnecting the same underlying account may yield a new connection). [plaid-item-login-required] [nango-reauth]

## SOURCES

**plaid-update-mode**
URL: https://plaid.com/docs/link/update-mode/
Accessed: 2026-06-14

**plaid-items**
URL: https://plaid.com/docs/api/items/
Accessed: 2026-06-14

**plaid-item-login-required**
URL: https://plaid.com/docs/errors/item/
Accessed: 2026-06-11

**stripe-oauth-deauth**
URL: https://stripe.com/docs/connect/oauth-reference
Accessed: 2026-06-14

**nango-reauth**
URL: https://docs.nango.dev (guides/api-authorization/re-authorization; SPA-rendered, index confirmed but content not extractable at access time)
Accessed: 2026-06-14

**merge-linked**
URL: https://docs.merge.dev/merge-unified/merge-link/overview/
Accessed: 2026-06-14

## SYNTHESIS

The consistent prior-art pattern for connection-bearing data platforms: separate "auth/credential failure stopped collection" (recoverable in place — same connection identity, same history, credential refreshed via an update/re-auth flow) from "deliberate hard delete" (terminal). Plaid's update mode is the gold standard: the broken Item is repaired by re-auth on the same `access_token`, and recovery is modeled as a *state transition* (LOGIN_REPAIRED webhook) rather than a re-create. Nango and Merge follow the same in-place-reconnect shape. Stripe is the outlier — deauthorize is terminal — which is appropriate for payment processing (dormant authorization carries compliance risk) but is the wrong model for a data-access system whose value is accumulated historical data. Transferable rule: when the durable asset is the connection's collected history and identity, model "pause/broken → resume" as a credential refresh on the preserved identity, not as delete-and-recreate; a deterministic connection identity means recreation and reactivation converge on the same record anyway, so an explicit in-place reactivate is strictly cleaner.