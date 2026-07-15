---
title: "Actionability is a separate signal from status: leading tools expose an explicit next-action and a named repair flow rather than forcing users to infer what to do from health labels, and separate automatic machine state from the human-facing triage buckets"
date: 2026-06-29
topic: product-design
tags: [actionability, status-ux, next-action, triage, repair-flow, prior-art]
status: draft
sources: [stripe-status, datadog-status-page, plaid-update-mode, sentry-states]
---

## CLAIMS

- Stripe maps detailed PaymentIntent lifecycle states into Dashboard payment statuses but still exposes an explicit `next_action` when the integration must do more work — actionability is surfaced separately from status, not inferred from it. [stripe-status]
- Datadog's monitor status page uses the alert as the entry point, then presents investigation context and quick actions together to move the incident toward resolution — action controls and context belong together but stay scoped to that incident. [datadog-status-page]
- Plaid treats a broken Item as update-mode work: when access stops working the user is sent through a focused repair flow, and the system can dismiss the repair messaging when repair happens elsewhere — repair is a named flow, not an ambiguous internal condition in a generic failure bucket. [plaid-update-mode]
- Sentry issue status can be assigned automatically, while triage tabs (unresolved / for-review) shape what the user sees first — the authoritative machine state and the human-facing triage buckets are distinct layers. [sentry-states]

## SOURCES

**stripe-status**
URL: https://docs.stripe.com/payments/payment-intents/verifying-status
Accessed: 2026-06-29

**datadog-status-page**
URL: https://docs.datadoghq.com/monitors/status/status_page/
Accessed: 2026-06-29

**plaid-update-mode**
URL: https://plaid.com/docs/link/update-mode/
Accessed: 2026-06-29

**sentry-states**
URL: https://docs.sentry.io/product/issues/states-triage/
Accessed: 2026-06-29

## SYNTHESIS

When a system has many internal states (health, freshness, coverage, retryability, needs-owner, needs-maintainer, passively-checking), the prior art says: do not force the user to infer "what should I do" from a health label like `Degraded` or `Checking`. Keep an authoritative machine-side state as the source of truth (Stripe lifecycle, Sentry auto-assigned status), and project it into a small set of human task groups — "what requires me," "what is worth reviewing," "what is a system/maintainer issue," "what is only being checked." Surface an explicit next-action (Stripe `next_action`) and route a repair to a named, focused flow (Plaid update mode) rather than an ambiguous row in a generic failure bucket. Two supporting rules: counts must match the visible scope (a hero "3 need you" counts only rows under "Needs you"; other buckets get their own headings/counts), and a single entity should not be duplicated across task groups — its strongest task owns its row, with lower-priority facts on its detail surface. Do not leak internal taxonomy labels into the owner-facing surface.
