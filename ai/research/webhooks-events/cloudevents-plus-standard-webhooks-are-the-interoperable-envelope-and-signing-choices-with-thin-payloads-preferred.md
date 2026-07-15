---
title: "CloudEvents 1.0 (envelope) plus Standard Webhooks v1 (signing/retry) are the most interoperable webhook choices, and thin pointer payloads are the industry-preferred delivery mode for sensitive data"
date: 2026-06-11
topic: webhooks-events
tags: [webhooks, cloudevents, standard-webhooks, hmac, event-delivery, thin-payloads]
status: draft
sources: [cloudevents-spec, standard-webhooks-spec, standard-webhooks-home, stripe-webhooks, github-webhooks]
---

## CLAIMS

- CloudEvents 1.0 required attributes are `specversion`, `id`, `source`, `type`; optional standard attributes include `time`, `subject`, `datacontenttype`, `dataschema`; extension attributes must be lowercase alphanumeric, ≤20 chars, with no underscores. [cloudevents-spec]
- CloudEvents defines two HTTP bindings: structured mode (entire event JSON in the body, `content-type: application/cloudevents+json`, SDK-parseable from content-type alone) and binary mode (`data` raw in the body, CloudEvents attributes as `ce-<name>` headers). [cloudevents-spec]
- CloudEvents' normative dedupe rule is that `source` + `id` uniquely identify an occurrence; `"1.0"` is the correct `specversion` for the entire 1.x family, and profile/extension versioning belongs in extension attributes or `type`, not in a forked `specversion` string. CloudEvents is an envelope spec only — it does not define signing, retry, or disable conventions. [cloudevents-spec]
- Standard Webhooks requires three headers on every delivery: `webhook-id` (stable unique message id, idempotency key), `webhook-timestamp` (integer unix seconds), and `webhook-signature` (space-delimited list of `v1,<base64>` tokens, the list supporting zero-downtime secret rotation). [standard-webhooks-spec]
- Standard Webhooks symmetric signing: `signed_string = "{webhook-id}.{webhook-timestamp}.{body}"`, `key = base64_decode(secret without the "whsec_" prefix)`, `signature = hmac_sha256(key, signed_string)`, header value `"v1," + base64(signature)`; recommended key size 24–64 random bytes; an asymmetric ed25519 alternative uses `whsk_`/`whpk_` prefixes. [standard-webhooks-spec]
- Standard Webhooks describes both thin and full payloads, recommends thin payloads for large datasets (noting the tradeoff that thin payloads require a follow-up API call), and recommends payload size under 20 KB. [standard-webhooks-spec]
- Standard Webhooks retry/disable conventions: at-least-once delivery with exponential backoff + jitter over multiple days; a reference schedule of 0s, 5s, 5m, 30m, 2h, 5h, 10h, 14h, 20h, 24h (10 attempts, ~75 hours total); `2xx` = success, `3xx` = failure (no redirect following), `410 Gone` = auto-disable endpoint, `429`/`502`/`504` = throttle; `retry-after` should be respected; consumers MUST use `webhook-id` as the idempotency key; after persistent failure, notify via another channel AND disable delivery. [standard-webhooks-spec] [standard-webhooks-home]
- Stripe webhooks use envelope `{id, type, created, livemode, data: {object: {...}}}` (a full snapshot of the changed resource), sign with `Stripe-Signature: t=<unix_ts>,v1=<hmac_hex>,...` over `"{t}.{body}"` (multiple `v1=` tokens during rotation; a legacy `v0=` SHA-1 token is deprecated), retry with exponential backoff up to 3 days, and do not conform to CloudEvents. [stripe-webhooks]
- Stripe's v2 API introduces thin events — `{type, object: "v2.event", related_object: {type, url}, reason}` — whose SDK `fetchRelatedObject()` retrieves current state, a strategic direction toward pointer payloads. [stripe-webhooks]
- GitHub webhooks send `X-GitHub-Event`, `X-GitHub-Delivery` (GUID), and `X-Hub-Signature-256: sha256=<hmac_hex>` (signed over the body only, with a legacy `X-Hub-Signature` SHA-1 still emitted); the payload is the full resource JSON with no envelope wrapper; there is no automatic retry (operators redeliver via the GitHub UI); GitHub does not conform to CloudEvents. [github-webhooks]

## SOURCES

**cloudevents-spec**
URL: https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/spec.md
Accessed: 2026-06-11

**standard-webhooks-spec**
URL: https://github.com/standard-webhooks/standard-webhooks/blob/main/spec/standard-webhooks.md
Accessed: 2026-06-11

**standard-webhooks-home**
URL: https://www.standardwebhooks.com/
Accessed: 2026-06-11

**stripe-webhooks**
URL: https://stripe.com/docs/webhooks
Accessed: 2026-06-11

**github-webhooks**
URL: https://docs.github.com/en/webhooks/webhook-events-and-payloads
Accessed: 2026-06-11

## SYNTHESIS

For a new event-delivery system, CloudEvents 1.0 JSON structured mode (envelope) plus Standard Webhooks v1 signing/retry is the most interoperable pairing: CloudEvents handles the envelope but explicitly leaves signing/retry/disable undefined, and Standard Webhooks fills exactly that gap with an off-the-shelf-verifiable HMAC scheme. Two anti-patterns to avoid: forking `specversion` (e.g. a vendor-suffixed `"1.0-myprofile"`) breaks interoperability with Knative/EventBridge/Azure Event Grid/Argo Events — put profile versioning in an extension attribute instead; and omitting the event-id from the signed string (as older/Stripe/GitHub schemes do, signing only `{ts}.{body}` or the body alone) permits replay of a captured `{ts}.{body}` under a different event id within the timestamp tolerance — Standard Webhooks' `{id}.{ts}.{body}` closes this.

Thin (pointer) payloads are the industry-converged choice for sensitive data: Plaid webhooks carry only identifiers (`item_id`, `account_id`, `transaction_id`) and route receivers to the read API; Google push notifications carry a `resourceId`/`resourceUri`; MCP `notifications/resources/updated` carries a URI; and Stripe's v2 thin events with `fetchRelatedObject()` are moving the same way. The pattern: the notification proves an event happened and provides a handle/cursor; the read API delivers the actual data under full authorization. This centralizes authorization/projection enforcement at one read choke point, minimizes PII on the delivery wire (which is signed and POSTed to arbitrary consumer endpoints), and avoids the hazard of signing large/paginated bodies. The tradeoff Standard Webhooks names — a follow-up API call — is negligible for any non-trivial receiver. Practical refinements many implementations miss: treat `410 Gone` as an auto-disable signal, treat `429`/`502`/`504` as throttle (reset backoff without consuming a retry slot) and honor `retry-after`, rather than counting every non-2xx as a failure.
