---
title: "Leading tools model long-running work with closed named-state machines (not prose), treat needs-human/no-data as first-class states, earn recovery from fresh evidence rather than a button click, push live progress over an append-only event log, and keep the same recovery op on matched CLI and UI faces"
date: 2026-06-18
topic: product-design
tags: [status-ux, state-machine, recovery, liveness, cli-ui-parity, observability, prior-art]
status: draft
sources: [sentry-states, sentry-issues, sentry-issue-details, linear-workflows, temporal-events, triggerdev-runs, triggerdev-realtime, triggerdev-usage, gha-run-logs, gha-rerun, gha-visualization, stripe-payment-status, stripe-identity, datadog-monitor-config, datadog-monitor-status, gh-cli-rerun, gh-cli-watch]
source_session: 019d96dc-b062-7be1-80e0-b2a931dcd464
---

## CLAIMS

- Sentry models issue status as an explicit state machine — `New → Ongoing → Escalating`, `Resolved`, `Archived`, and `Regressed` ("a resolved issue that's come up again") — and ships a diagram of which transitions are automatic vs manual. Resolving is a deliberate "I believe this is fixed" assertion that Sentry automatically reverses (`Regressed`) if a matching event recurs. [sentry-states]
- Sentry's issue tabs are saved filtered lists shown with their literal query: `All Unresolved (is:unresolved)`, `For Review (is:unresolved is:for_review)`, `Regressed (is:regressed)`, `Archived`, `Escalating`. "For Review" is the subset needing a human decision. [sentry-issues]
- A Sentry issue detail page shows first/last-seen, first/last release, and a chronological activity section (assignments, regressions, escalations, comments) — recovery is logged as events on the entity's own timeline, not as ephemeral toast. [sentry-issue-details]
- Linear groups statuses into fixed categories that define ordering and semantics — `Backlog → Unstarted → Started → Completed / Canceled`, plus reserved `Triage` and `Duplicate`; teams add custom statuses within a category but cannot reorder categories. The category is the stable color-coded meaning; the label is customizable detail. [linear-workflows]
- Temporal tracks progress by appending Events to an append-only ordered Event History (`WorkflowExecutionStarted`, `ActivityTaskScheduled/Started/Completed`); this history is the single source of truth for "what happened / where are we now," powers durable crash recovery, and supports `Reset` to a prior point. [temporal-events]
- Trigger.dev models a run as an addressable entity (unique run ID, status, payload, output, metadata) with an explicit lifecycle (Pending → executing → final: completed/failed/canceled); recovery verbs are first-class (`runs.replay()`, `runs.cancel()`, `runs.reschedule()`), and re-run creates a new run rather than mutating the old one. [triggerdev-runs]
- Trigger.dev Realtime lets a client subscribe to a run's state changes as they happen (`subscribeToRun` / `useRealtimeRun`) — progress is pushed, not polled. [triggerdev-realtime]
- A Trigger.dev run exposes its recorded duration and cost — terminal records carry "how long it took," the data needed to set an expectation for the next run. [triggerdev-usage]
- GitHub Actions distinguishes in-progress from a terminal conclusion (success/failure/canceled/neutral), backed by the Checks API (a check suite per run, check run per job, steps within); a failed run can be re-run. [gha-run-logs]
- GitHub Actions offers "Re-run failed jobs" vs "Re-run all jobs" as distinct buttons (available up to 30 days, optional debug logging); the same operation has a CLI form `gh run rerun [<run-id>] --failed` with the run-id as an optional positional. [gha-rerun]
- GitHub Actions generates a real-time graph illustrating run progress with per-node status while running. [gha-visualization]
- A Stripe PaymentIntent has an explicit status the client retrieves and branches on (`succeeded`, `requires_action`, `requires_payment_method`, `processing`); Stripe explicitly recommends webhooks over polling ("polling … is much less reliable and might cause rate limiting"), pushing truth on `payment_intent.succeeded`/`payment_intent.payment_failed`. `requires_action` is a named state meaning the human must act next. [stripe-payment-status]
- Stripe Identity Verification Sessions run `requires_input → processing → verified` (plus `canceled`/`redacted`) and emit an event on every status change; `requires_input` = "checks completed and at least one failed," a precise actionable state distinct from a system failure. [stripe-identity]
- Datadog monitors have separate alert, warning, and optional recovery thresholds ("an additional condition for alert recovery"); the advice is to auto-resolve only when actually fixed, and a monitor that auto-resolves while still bad re-triggers at the next evaluation — recovery is a measured condition, not a timer. The "No data" advanced condition offers `Show NO DATA` / `Evaluate as zero` / `Show OK` as explicit operator choices, making "no signal" first-class and distinct from "bad signal." [datadog-monitor-config]
- Datadog's monitor status page confirms `OK` as a named state, shows a Transitions graph so "when did it recover" is answerable, and notes that a manual resolve only "temporarily changes the monitor status to `OK` until its next evaluation," after which it re-checks against fresh data. [datadog-monitor-status]
- GitHub's CLI manual documents `gh run rerun` with the run-id as an optional positional, while the interactive run-selection example (being prompted to choose a run when none is given) belongs to `gh run watch`, not `rerun`. [gh-cli-rerun][gh-cli-watch]

## SOURCES

**sentry-states**
URL: https://docs.sentry.io/product/issues/states-triage/
Accessed: 2026-06-18

**sentry-issues**
URL: https://docs.sentry.io/product/issues/
Accessed: 2026-06-18

**sentry-issue-details**
URL: https://docs.sentry.io/product/issues/issue-details/
Accessed: 2026-06-18

**linear-workflows**
URL: https://linear.app/docs/configuring-workflows
Accessed: 2026-06-18

**temporal-events**
URL: https://docs.temporal.io/workflow-execution/event
Accessed: 2026-06-18

**triggerdev-runs**
URL: https://trigger.dev/docs/runs
Accessed: 2026-06-18

**triggerdev-realtime**
URL: https://trigger.dev/docs/realtime
Accessed: 2026-06-18

**triggerdev-usage**
URL: https://trigger.dev/docs/run-usage
Accessed: 2026-06-18

**gha-run-logs**
URL: https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows/monitoring-workflows/using-workflow-run-logs
Accessed: 2026-06-18

**gha-rerun**
URL: https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-workflow-runs/re-running-workflows-and-jobs
Accessed: 2026-06-18

**gha-visualization**
URL: https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows/monitoring-workflows/using-the-visualization-graph
Accessed: 2026-06-18

**stripe-payment-status**
URL: https://docs.stripe.com/payments/payment-intents/verifying-status
Accessed: 2026-06-18

**stripe-identity**
URL: https://docs.stripe.com/identity/verification-sessions
Accessed: 2026-06-18

**datadog-monitor-config**
URL: https://docs.datadoghq.com/monitors/configuration/
Accessed: 2026-06-18

**datadog-monitor-status**
URL: https://docs.datadoghq.com/monitors/status/
Accessed: 2026-06-18

**gh-cli-rerun**
URL: https://cli.github.com/manual/gh_run_rerun
Accessed: 2026-06-18

**gh-cli-watch**
URL: https://cli.github.com/manual/gh_run_watch
Accessed: 2026-06-18

## SYNTHESIS

Cross-tool patterns for any surface that shows long-running work and its recovery:

- **A run/issue is an addressable entity whose status is a closed set of named states**, never free text (Trigger.dev, GitHub Actions, Stripe, Datadog, Sentry, Linear).
- **Color is bound to a named category**, not a freestanding hue — nobody ships green/yellow without an adjacent legend word (Linear categories, Datadog OK/Warn/Alert).
- **"Needs a human" is its own state**, separate from "failed" and "running" (Stripe `requires_action`/Identity `requires_input`; Sentry "For Review"; Datadog `Warn` vs `Alert`) — distinguish states by *the next actor*.
- **Closing the loop is an explicit, reversible assertion verified by fresh evidence** — Sentry auto-reverses to `Regressed` on recurrence; Datadog recovery is a measured threshold crossing and a premature resolve re-triggers. Health must be re-earned by new data, never asserted-and-frozen.
- **Long-running work is shown as live, pushed progress over an append-only event log, with terminal duration recorded** (Temporal history; GitHub real-time graph + streaming logs; Trigger.dev Realtime + run duration). The finished record's duration seeds the next expectation.
- **Push beats poll for status truth** (Stripe webhooks-over-polling; Trigger.dev subscribe; GitHub real-time graph).
- **The same recovery op has matched CLI and UI forms** (GitHub "Re-run failed jobs" ≡ `gh run rerun --failed`; Trigger.dev console action ≡ `runs.replay(runId)`) — same verb, same noun (run ID), same result across surfaces.
- **Re-running creates a new attempt linked to the prior one**, never silently mutating the failed record (Trigger.dev runs/attempts; GitHub re-run).
- **`No Data` is a legitimate, named, configurable outcome** shown as "we have no signal yet," never masquerading as a verdict (Datadog "No data" advanced condition).

For a device-local recovery whose truth must appear in a web console, the composition is: initiate with CLI⇄UI parity → CLI streams structured local progress (named phases, counts with a denominator, ETA seeded from last duration — never a bare cursor) → CLI emits run events so the console mirrors live phase/count and enters a bounded verifying state → both surfaces converge on the same terminal record (ID, duration, new-vs-unchanged counts) → the state transition to healthy is earned by that fresh evidence, not asserted by a click, and degrades again on a later failure.
