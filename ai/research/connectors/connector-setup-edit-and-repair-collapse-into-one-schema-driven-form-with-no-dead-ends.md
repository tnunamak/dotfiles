---
title: "Mature integration platforms render one schema-driven credential form that serves setup, edit, and repair identically; repair is edit triggered from an error state (connection identity + history preserved), validate-before-store, and no dead ends"
date: 2026-06-14
topic: connectors
tags: [connectors, setup-ux, credential-capture, reauthorization, airbyte, nango, plaid, stripe, prior-art]
status: draft
sources: [airbyte-spec, airbyte-protocol, nango-full, nango-reauth, plaid-update-mode, stripe-keys, merge-link, vercel-integrations]
---

## CLAIMS

- Airbyte connectors ship a `connectionSpecification` — a JSONSchema in the connector's `spec.json` declaring field names/labels/types/`description`/`examples`/`placeholder`, `airbyte_secret: true` for masked fields, `oneOf` for multi-mode auth, and `order` for sequencing. Airbyte's UI auto-renders any spec as a form with no per-connector UI code; the "Edit source" flow re-renders the same form pre-populated with non-secret values (secrets omitted, shown as a masked "set" indicator), and a disconnected/errored connector shows the same edit form with an error banner. [airbyte-spec] [airbyte-protocol]
- Nango declares per-provider auth type and credential/config fields in `providers.yaml`; its Connect UI auto-renders the required fields. Nango validates credentials at capture time for providers that support it and rejects invalid credentials before storing them (error state `invalid_credentials`). [nango-full]
- Nango's re-authorization flow is architecturally identical to setup — same flow/UI/API — just triggered on an existing `connection_id`: on `invalid_credentials`, a webhook fires, the host shows a Reconnect button, a reconnect session token is generated (operation `override`), the same auth flow opens, and on success the same `connection_id` is preserved with history and schedule intact. [nango-reauth]
- Plaid's Item state machine (`HEALTHY`, `PENDING_EXPIRATION`, `ITEM_LOGIN_REQUIRED`, `ERROR`) drives repair via Link "update mode" — the same Link component used for setup, scoped to the specific Item, showing only the minimum re-auth steps needed; a `LOGIN_REPAIRED` webhook tells the host to stop showing the repair CTA even if repair happened elsewhere. Plaid does NOT auto-retry on `ITEM_LOGIN_REQUIRED` — the Item sits broken until the owner acts, presented as a single clear repair CTA. [plaid-update-mode]
- Stripe's credential UX: a live secret key is shown exactly once at creation and cannot be revealed later; existing keys display masked with an identifying prefix (`sk_live_...****`); rotation is atomic (revoke old + issue replacement with no downtime, plus scheduled rotation); restricted keys allow scoped, purpose-limited credentials. [stripe-keys]
- Merge Link is an embedded iFrame driven entirely by integration metadata (no per-integration host UI code); re-authentication uses a re-link URL re-opening Link for a specific Linked Account, preserving the account ID and history and refreshing only the credential. [merge-link]
- Linear and Vercel use the same token-setup pattern for API-token integrations: instruction text (where to find the token, what scope), a masked `type="password"` input, a "Test connection"/"Verify token" step before saving, never re-showing the token after save, and a masked "set" indicator; rotation via a "Regenerate"/"Replace token" field. [vercel-integrations]

## SOURCES

**airbyte-spec**
URL: https://docs.airbyte.com/connector-development/connector-specification-reference
Accessed: 2026-06-14

**airbyte-protocol**
URL: https://docs.airbyte.com/platform/understanding-airbyte/airbyte-protocol
Accessed: 2026-06-14

**nango-full**
URL: https://nango.dev/docs/llms-full.txt ; https://docs.nango.dev/llms.txt
Accessed: 2026-06-14

**nango-reauth**
URL: https://nango.dev/docs/guides/auth/auth-guide#re-authorize-an-existing-connection
Accessed: 2026-06-14

**plaid-update-mode**
URL: https://plaid.com/docs/link/update-mode/
Accessed: 2026-06-14

**stripe-keys**
URL: https://stripe.com/docs/keys
Accessed: 2026-06-14

**merge-link**
URL: https://docs.merge.dev/merge-unified/merge-link/overview/
Accessed: 2026-06-14

**vercel-integrations**
URL: https://vercel.com/docs/integrations/install-an-integration
Accessed: 2026-06-14

## SYNTHESIS

The convergent design across Airbyte (`connectionSpecification`), Nango (`providers.yaml` + Connect UI), Merge (Link), and Stripe/Linear/Vercel token flows: every connector declares its credential fields in a schema, one generic UI component renders any schema as a form, and setup / edit / repair are one form with a context-aware trigger — no per-connector UI code and no dead ends. Three flows collapse: Setup (no pre-population, new identity), Edit/rotation (non-secret fields pre-filled, secret shown as a masked "set" indicator, identity preserved), and Repair (the same form triggered from an error state, with error context; identity, history, and schedule preserved, only the stored secret replaced). Two cross-cutting rules: (1) validate-before-store — a bounded synchronous probe against the provider (Airbyte source test, Nango capture-time check, "Zapier test step") that echoes non-secret account identity on success and stores nothing on failure; degrade gracefully to first-sync validation for connectors without a probe rather than blocking the form. (2) Never echo a secret; show a masked indicator, rotate rather than delete+recreate. The "no dead ends" principle: every unsupported connector should present an honest named state with a path (runbook link, docs, notify-me) rather than a blank "not supported" wall, so a user never has to wonder whether it's a bug or a product decision.