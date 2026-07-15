---
title: "Personal-data event webhooks favor hint-only payloads, CloudEvents binary HTTP binding, per-subscription HMAC signing, and monotonic replay cursors"
date: 2026-05-27
topic: api-contract-design
tags: [webhooks, event-subscriptions, cloudevents, hmac, hint-only, sse, replay]
status: draft
sources: [stripe-webhooks, stripe-signature, plaid-webhook-verification, google-drive-push, msgraph-webhooks, msgraph-resource-data, msgraph-subscription, github-webhooks, mcp-resources, websub, sse, webpush-rfc8030, cloudevents-spec]
---

<!-- Reusable per-platform webhook prior-art extracted from a pdpp event-subscription note.
     pdpp-specific v1 wire recommendations and confidence tables were dropped. -->

## CLAIMS

- Stripe now offers Thin Events (hint only: `id`, `type`, `related_object` URL) alongside legacy Snapshot Events and recommends thin events for new integrations when you always need latest state or want smaller payloads. [stripe-webhooks]
- Stripe signs with `Stripe-Signature: t=…,v1=HMAC_SHA256(t + "." + raw_body, whsec_…)`, a default 5-minute timestamp tolerance, and a per-endpoint secret (not the API key); it retries up to 3 days (~25 attempts, exponential backoff), disables an endpoint after 3 days of failure, and allows manual resend up to 15 days; retries resend the same `event.id` and clients dedupe by stored ID; endpoint filtering uses an `enabled_events` array supporting `*` wildcards. [stripe-webhooks][stripe-signature]
- Plaid webhooks are hint-only (`DEFAULT_UPDATE`/`HISTORICAL_UPDATE` carry a `new_transactions` count + `item_id`; client calls `/transactions/sync` with a cursor to materialize); signing is a `Plaid-Verification` ES256 JWT whose `kid` resolves via authenticated `/webhook_verification_key/get` (not public JWKS), body integrity via `request_body_sha256` JWT claim, replay window 5 minutes from `iat`. [plaid-webhook-verification]
- Google Drive push channels are strictly hint-only: notifications carry headers (`X-Goog-Channel-ID`, `X-Goog-Resource-State`: `sync|add|remove|update|trash`) and never the resource body; the client calls `changes.list(pageToken)`; channels TTL out (typically 1–24h) requiring `channels.stop` + re-`watch`; the body is intentionally minimal because a channel created under one OAuth scope may fan out to a broader-access process, so Google forces a scoped re-fetch. [google-drive-push]
- Microsoft Graph is two-mode: default hint-only, opt-in `includeResourceData: true` requires the subscriber to supply an `encryptionCertificate` (RSA public key); Graph then sends an encrypted symmetric key + encrypted resource data inline; lifecycle uses `expirationDateTime` (max varies: 60min presence, 4230min mail) and a separate `lifecycleNotificationUrl` for `subscriptionRemoved`/`missed`/`reauthorizationRequired`; a `validationToken` must be echoed within 10s on create. [msgraph-webhooks][msgraph-resource-data][msgraph-subscription]
- GitHub webhooks embed the full resource inline (`X-GitHub-Event`, `X-GitHub-Delivery` UUID, `X-Hub-Signature-256: sha256=HMAC(secret, body)`) and are effectively single-attempt with failed deliveries surfaced for manual redelivery for 8 days. [github-webhooks]
- MCP `notifications/resources/updated` is hint-only by design (client subscribes with a URI, server emits only the URI, client follows up with `resources/read`); the spec is silent on reconnect/missed events, and the transport does not preserve missed notifications across disconnects. [mcp-resources]
- WebSub is hub-mediated pub/sub (subscriber POSTs `hub.callback`/`hub.topic`/`hub.secret`, hub verifies intent with `hub.challenge`, deliveries signed `X-Hub-Signature`); SSE is a one-way `text/event-stream` HTTP stream with built-in `Last-Event-ID` reconnect suited to clients behind NAT; WebPush (RFC 8030 + 8291 VAPID) mandates strict end-to-end content encryption. [websub][sse][webpush-rfc8030]
- CloudEvents 1.0 requires `id`, `source` (URI ref), `specversion`, `type` (optional `time`, `subject`, `datacontenttype`, `dataschema`, `data`); the HTTP binary binding puts attributes in `ce-*` headers with the body as data (allowing an HMAC signature over the raw body while staying conformant), and gives free interoperability with Knative, Azure Event Grid, AWS EventBridge, and Argo Events. [cloudevents-spec]

## SOURCES

**stripe-webhooks**
URL: https://docs.stripe.com/webhooks
Accessed: 2026-05-27

**stripe-signature**
URL: https://docs.stripe.com/webhooks/signature
Accessed: 2026-05-27

**plaid-webhook-verification**
URL: https://plaid.com/docs/api/webhooks/webhook-verification/
Accessed: 2026-05-27

**google-drive-push**
URL: https://developers.google.com/drive/api/guides/push
Accessed: 2026-05-27

**msgraph-webhooks**
URL: https://learn.microsoft.com/en-us/graph/webhooks
Accessed: 2026-05-27

**msgraph-resource-data**
URL: https://learn.microsoft.com/en-us/graph/change-notifications-with-resource-data
Accessed: 2026-05-27

**msgraph-subscription**
URL: https://learn.microsoft.com/en-us/graph/api/resources/subscription
Accessed: 2026-05-27

**github-webhooks**
URL: https://docs.github.com/en/webhooks/about-webhooks
Accessed: 2026-05-27

**mcp-resources**
URL: https://modelcontextprotocol.io/specification/2025-06-18/server/resources
Accessed: 2026-05-27

**websub**
URL: https://www.w3.org/TR/websub/
Accessed: 2026-05-27

**sse**
URL: https://html.spec.whatwg.org/multipage/server-sent-events.html
Accessed: 2026-05-27

**webpush-rfc8030**
URL: https://datatracker.ietf.org/doc/html/rfc8030
Accessed: 2026-05-27

**cloudevents-spec**
URL: https://github.com/cloudevents/spec/blob/main/cloudevents/spec.md
Accessed: 2026-05-27

## SYNTHESIS

For personal-data event subscriptions the fintech/data camp (Stripe, Plaid, Google Drive push) converges on hint-only payloads (event type + cursor + counts, no record bodies) forcing a scoped re-fetch through the query API where projection is centralized — the strongest argument being Google's scope-projection safety: the moment a server embeds data, every downstream system handling the notification gets that data. The recommended v1 shape combines Stripe's HMAC-with-timestamp signing (a per-subscription secret, never the bearer client token — different lifecycle, different threat model), Plaid's hint+cursor materialization, and the CloudEvents 1.0 binary HTTP binding (free interop, HMAC over the body). Solve MCP's missed-event gap by emitting a monotonic `since_cursor` on every event so a reconnecting client can `GET /events?since=<cursor>` and replay. Anti-patterns to avoid: GitHub-style single-delivery + manual redelivery (doesn't scale to autonomous clients), embedding record bodies before a real volume/latency problem, reusing the bearer token as the signing key, a bespoke envelope when CloudEvents costs nothing, and WebSub hub indirection with no third-party fan-out story.
