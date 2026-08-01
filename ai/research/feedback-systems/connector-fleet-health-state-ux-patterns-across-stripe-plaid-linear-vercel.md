---
title: "Connector/integration fleet health UX converges on six principles: split auth-failure from runtime-failure, one named affordance per state, a vetted end-user display_message layer, warn-before-break, recovery-as-transition, and lightweight-card/full-detail history"
date: 2026-05-15
topic: feedback-systems
tags: [connector-health, integration-status, plaid, stripe, vercel, fivetran, status-ux, backoff]
status: draft
sources: [stripe-webhooks, stripe-connect, stripe-webhook-support, plaid-item-errors, plaid-update-mode, plaid-webhooks, linear-changelog, linear-slack, vercel-github, vercel-commits, vercel-errors, fivetran-alerts, airbyte-2426, zapier-troubleshoot, segment-delivery, carbon-status, trevor-calabro, isdown-linear]
source_session: 019d371d-a0ee-7013-b42f-a34bac5c806f
---

## CLAIMS

- Stripe auto-disables a webhook endpoint after ~3 days of continuous failures in live mode and emails the account owner; re-enable is an explicit Enable button. [stripe-webhooks][stripe-webhook-support]
- Stripe Connect surfaces account state (`complete`, `pending_verification`, `restricted`, `disabled`) as a persistent red banner with a one-line reason and a deep link into the exact action; each requirement carries a `resolution_path` (`form`/`notice`/`support`/`underwriting_case`) rendered as a discrete checklist rather than "contact support". [stripe-connect]
- Plaid's Item state machine has five named states — `HEALTHY`, `PENDING_EXPIRATION` (UK/EU consent expiry ≤7 days), `PENDING_DISCONNECT` (US/CA 7-day scheduled disconnect), `ITEM_LOGIN_REQUIRED` (re-auth needed), and generic `ERROR` — where re-auth states require Link update mode and generic errors are usually wait-and-retry. [plaid-item-errors][plaid-update-mode]
- Plaid errors carry three layers: `error_code` (machine), `error_message` (developer English), and `display_message` (pre-vetted end-user copy the host app is meant to show directly). [plaid-item-errors]
- Plaid fires a `LOGIN_REPAIRED` webhook automatically when an Item exits the bad state without going through your app (because the same user fixed it in another Plaid-linked app), signaling the host to stop nagging the user. [plaid-webhooks]
- Plaid does not blindly auto-retry during `ITEM_LOGIN_REQUIRED`; it stops syncing and waits for the user, and when the Item recovers the next sync covers all data missed during the outage. [plaid-item-errors]
- Plaid's recovery affordance is granular: Link update mode re-launches only the specific failed step (e.g. a new OTP), not a full reconnect. [plaid-update-mode]
- Linear renamed the Slack integration's "Reconnect" copy to "Update connection" because the integration was still connected — using the harsher word only when the integration is actually broken. [linear-changelog][linear-slack]
- Linear historically shipped silent integration connection errors and explicitly fixed them so a proper error now displays; auto-disconnect without UI explanation is a documented footgun (Plain–Linear April 2026 incident). [linear-changelog][isdown-linear]
- Vercel emits 7+ deployment status events (`pending`, `building`, `ready`/`success`, `error`/`failed`, `canceled`, `ignored`, `skipped`, `promoted`) collapsed to ~4 visible pill states, and makes instant rollback ("Promote" a prior good deployment) a first-class affordance. [vercel-github][vercel-errors]
- Vercel does not prominently surface a broken Git integration; the user must notice commits stopped triggering deployments and triangulate via GitHub's own settings — the silent-failure anti-pattern Linear called out. [vercel-commits]
- Fivetran splits alerts into Errors (red, block syncing) vs Warnings (yellow, non-blocking), and auto-resolves an Error on the next successful sync with no manual "mark as fixed". [fivetran-alerts]
- Airbyte's first-pass status coloring lumped `Incomplete` into green alongside Succeeded — treating an incomplete run as success is a recognized anti-pattern. [airbyte-2426]
- Zapier uses a three-tier error taxonomy (Stopped = turned off after repeated failures, Errored = one run failed but still active, Held = paused awaiting review), and trigger-level errors never appear in task history because the failure precedes run creation — so a Zap can be paused while the dashboard shows "no errors". [zapier-troubleshoot]
- Segment separates configuration health (per-source/destination tiles) from flow health (a separate Event Delivery dashboard) — "is it set up correctly?" vs "is data actually flowing?". [segment-delivery]
- Carbon Design System's status-indicator vocabulary distinguishes caution/critical-instability from a process failure needing immediate attention from informational, and recommends encoding status with at least two of {color, shape, symbol} for colorblind accessibility. [carbon-status]
- A status pill that only decorates a dashboard relocates confusion rather than resolving it unless it is paired with cause, time-of-failure, and next-action. [trevor-calabro]

## SOURCES

**stripe-webhooks**
URL: https://docs.stripe.com/webhooks
Accessed: 2026-05-15

**stripe-connect**
URL: https://docs.stripe.com/connect/handling-api-verification
Accessed: 2026-05-15

**stripe-webhook-support**
URL: https://support.stripe.com/questions/troubleshooting-webhook-delivery-issues
Accessed: 2026-05-15

**plaid-item-errors**
URL: https://plaid.com/docs/errors/item/
Accessed: 2026-05-15

**plaid-update-mode**
URL: https://plaid.com/docs/link/update-mode/
Accessed: 2026-05-15

**plaid-webhooks**
URL: https://plaid.com/docs/api/webhooks/
Accessed: 2026-05-15

**linear-changelog**
URL: https://linear.app/changelog
Accessed: 2026-05-15

**linear-slack**
URL: https://linear.app/docs/slack
Accessed: 2026-05-15

**vercel-github**
URL: https://vercel.com/docs/git/vercel-for-github
Accessed: 2026-05-15

**vercel-commits**
URL: https://vercel.com/kb/guide/why-aren-t-commits-triggering-deployments-on-vercel
Accessed: 2026-05-15

**vercel-errors**
URL: https://vercel.com/docs/errors/error-list
Accessed: 2026-05-15

**fivetran-alerts**
URL: https://fivetran.com/docs/using-fivetran/fivetran-dashboard/alerts
Accessed: 2026-05-15

**airbyte-2426**
URL: https://github.com/airbytehq/airbyte/issues/2426
Accessed: 2026-05-15

**zapier-troubleshoot**
URL: https://getordersyncpro.com/blogs/zapier-zap-failures-troubleshooting
Accessed: 2026-05-15

**segment-delivery**
URL: https://segment.com/docs/connections/delivery-overview/
Accessed: 2026-05-15

**carbon-status**
URL: https://carbondesignsystem.com/patterns/status-indicator-pattern/
Accessed: 2026-05-15

**trevor-calabro**
URL: https://trevorcalabro.substack.com/p/fixing-bad-status-design
Accessed: 2026-05-15
Quote: "a table full of badges, timestamps, and vague labels does not automatically [improve UX]. In a lot of cases, it just relocates the confusion."

**isdown-linear**
URL: https://isdown.app/status/plain/incidents/575855-linear-integrations-are-being-disconnected
Accessed: 2026-05-15

## SYNTHESIS

Six cross-shop principles for any connector/integration health surface: (1) auth-failure (user must act, stop auto-retrying) and runtime-failure (system retries, user does nothing) are different states — conflating them confuses users; (2) every state owns exactly one named affordance (a verb on a button), never "fix this somehow"; (3) a vetted end-user `display_message` layer must exist separate from the machine reason code (Plaid's three-layer model is the gold standard); (4) warn before you break when the system can foresee expiry (Plaid's 7-day `PENDING_DISCONNECT` is the exemplar); (5) recovery is a state transition the system should detect and reflect automatically (Plaid `LOGIN_REPAIRED`, Fivetran auto-resolve), not a manual "I fixed it" button; (6) history is lightweight at the card level and full at the detail level — none of these products put sparklines on a per-row card. A distinct gap in the schedule-driven case (vs Plaid's event-driven model): a "cooling_off / retrying-soon" state that shows the next-attempt time is needed so users don't read an auto-paused connector as dead (the Zapier failure mode) — always show a duration, never a bare "Paused". Amber can carry several distinct states as long as each also has a distinct icon and pill word (Carbon's two-of-three rule).
