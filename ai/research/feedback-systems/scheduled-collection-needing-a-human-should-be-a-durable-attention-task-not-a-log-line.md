---
title: "Workflow schedulers separate schedule-execution policy from workflow logic and model human-attention as a durable, channel-agnostic task with its own lifecycle — not a notification read-state"
date: 2026-05-21
topic: feedback-systems
tags: [scheduling, retries, backoff, human-in-the-loop, notifications, attention, connector-health]
status: draft
sources: [temporal-schedule, gha-environments, prefect-automations, fivetran-connectors, fivetran-alerts, plaid-items, zapier-error-settings, mdn-push-practices, mdn-notifications-api]
---

## CLAIMS

- Temporal schedules model overlap, catchup windows, paused state, and `pause_on_failure`, treating schedule-execution policy as separate from the workflow logic it runs. [temporal-schedule]
- GitHub Actions environments separate a triggered job from an approval gate and allow wait timers up to 30 days, making the human gate explicit rather than pretending a paused job is still executing. [gha-environments]
- Prefect automations separate triggers from actions and include notification, pause/resume schedule, suspend/resume run, and inferred action targets. [prefect-automations]
- Fivetran distinguishes active, broken, delayed, incomplete, and paused connections, and its Alerts surface separates errors that block syncing from warnings that may need fixing. [fivetran-connectors][fivetran-alerts]
- Plaid Item repair uses explicit update/relink flows for credentials, MFA, revoked access, and required user action, and `LOGIN_REPAIRED` lets an app silence repair messaging when the account heals elsewhere. [plaid-items]
- Zapier distinguishes retry/autoreplay from a repeated-error shutdown policy and lets teams override behavior per Zap, supporting per-connection policy rather than one global schedule behavior. [zapier-error-settings]
- MDN's Web Push and Notifications guidance supports contextual opt-in, useful time-sensitive pushes, service-worker notifications on mobile, and treating permission/subscription/test status as separate facts. [mdn-push-practices][mdn-notifications-api]

## SOURCES

**temporal-schedule**
URL: https://docs.temporal.io/schedule
Accessed: 2026-05-21

**gha-environments**
URL: https://docs.github.com/en/actions/reference/deployments-and-environments
Accessed: 2026-05-21

**prefect-automations**
URL: https://docs.prefect.io/v3/concepts/automations
Accessed: 2026-05-21

**fivetran-connectors**
URL: https://fivetran.com/docs/getting-started/fivetran-dashboard/connectors
Accessed: 2026-05-21

**fivetran-alerts**
URL: https://fivetran.com/docs/getting-started/fivetran-dashboard/alerts
Accessed: 2026-05-21

**plaid-items**
URL: https://plaid.com/docs/api/items/
Accessed: 2026-05-21

**zapier-error-settings**
URL: https://help.zapier.com/hc/en-us/articles/14167175792909-Decide-how-your-Zap-handles-errors-with-advanced-settings
Accessed: 2026-05-21

**mdn-push-practices**
URL: https://developer.mozilla.org/en-US/docs/Web/API/Push_API/Best_Practices
Accessed: 2026-05-21

**mdn-notifications-api**
URL: https://developer.mozilla.org/en-US/docs/Web/API/Notifications_API/Using_the_Notifications_API
Accessed: 2026-05-21

## SYNTHESIS

Across workflow schedulers (Temporal, GitHub Actions, Prefect), data-sync fleets (Fivetran, Plaid), and automation tools (Zapier), the recurring design is: (1) a schedule expresses desired freshness and launch eligibility, not a guarantee every tick starts a run; (2) a run is a bounded execution attempt that can finish as waiting-for-operator / retryable-failed / not-retryable-failed / succeeded / succeeded-with-gaps; (3) human attention is a durable typed object with its own lifecycle (open, acknowledged, snoozed, resolved, superseded, expired) and ownership — not a log line or a notification read-state; (4) notification is delivery evidence attached to the task and is channel-agnostic (email, web push, mobile push, ntfy, Slack) — no single channel becomes the authoritative state; and (5) account repair is its own lifecycle distinct from data freshness — a connection can have usable stale data while being unhealthy for fresh sync, so the dashboard must not show green merely because old data exists or a notification was delivered. Two durable normative additions this survey implies: dedupe repeated schedule ticks by connection/schedule/attention-kind/resource (update last-seen + occurrence count rather than spawning new prompts), and after attention clears, default to latest-only catch-up rather than replaying one run per missed tick, with bounded/operator-triggered backfill only where the connector has true interval semantics.
