---
title: "Integration-health UX converges on one synthesized worst-wins verdict, a typed required-action (kind/audience/urgency/plain-English + machine-code/terminal), and a satisfaction + self-heal contract that flips back to green with no manual step"
date: 2026-06-15
topic: feedback-systems
tags: [connector-health, integration-status, required-action, self-heal, error-messages, plaid, stripe, datadog]
status: draft
sources: [plaid-update-mode, plaid-item-errors, plaid-items-api, stripe-onboard, stripe-verification-updates, stripe-api-verification, stripe-capabilities, stripe-review-accounts, stripe-remediation-links, stripe-changelog-disabled-reason, stripe-changelog-error-codes, datadog-status-page, datadog-config, datadog-integration-monitor, datadog-aggregation, github-suspend, vercel-error-list, vercel-git-settings, nango-invalid-grant, nango-logs, nng-error-heuristic, logrocket-errors, uxcc-errors]
---

## CLAIMS

- Mature integration products (Plaid, Stripe, Datadog, GitHub, Vercel) converge on a three-part contract: (1) ONE synthesized verdict rendered verbatim by each surface, never re-derived from raw fields per screen; (2) a typed required-action attached to every unhealthy verdict (which field is wrong, machine code, plain-English reason, who can fix it); (3) a satisfaction + self-heal contract that detects the action was done and flips back to green with no separate "now run it" step. [plaid-item-errors] [stripe-verification-updates] [datadog-status-page]
- Plaid's Item error envelope carries three layers in one object: error_code (machine state), display_message (owner-facing, jargon-free remediation), and error_message (engineer detail) — e.g. ITEM_LOGIN_REQUIRED's display_message is "Username or password incorrect: If you've recently updated your account with this institution, be sure you're entering your updated credentials." [plaid-item-errors]
- Plaid's ITEM_LOGIN_REQUIRED is the single broken state (delivered via webhook or returned inline) whose troubleshooting is exactly one instruction: send the Item through Link's update mode, which auto-prompts the user for only the input needed to fix it. [plaid-item-errors] [plaid-update-mode]
- Plaid's PENDING_DISCONNECT (US/CA) / PENDING_EXPIRATION (UK/EU) is a pre-broken warning fired ~7 days before consent expires — a distinct, named, pre-emptive verdict with its own one-action fix — and Plaid never shows a green Item while a PENDING_* is live. [plaid-items-api]
- Plaid update mode repairs the EXISTING connection, not a re-setup: Link is initialized with a link_token configured with the existing Item's access_token, presents an abbreviated flow requesting only the minimum input needed, and does not rotate tokens ("Plaid does not require you to rotate these tokens when an item is reconnected as it is the same underlying item") so downstream processor tokens and schedules survive untouched. [plaid-update-mode]
- Plaid's LOGIN_REPAIRED webhook fires when an Item exits ITEM_LOGIN_REQUIRED without going through update mode in your app (e.g. the same account was fixed in another app): "Upon receiving this webhook, you can dismiss any messaging you are presenting to the user telling them to fix their Item" — the banner removes itself, proving the verdict must be a pure projection of live evidence with no sticky UI state. [plaid-update-mode] [plaid-items-api]
- Stripe Connect answers "is this OK?" with two booleans (charges_enabled, payouts_enabled) and, if either is false, points to the requirements hash for "what exactly do I do?" — state-first (instantly legible), action-detail one layer down. [stripe-onboard]
- Stripe's requirements hash tiers outstanding actions by urgency: currently_due (act now, has a current_deadline), past_due (overdue → functionality already disabled), eventually_due (collect up-front or later), and pending_verification ("No action is required" but functionality stays disabled until Stripe review clears). [stripe-verification-updates]
- Stripe's requirements.errors[] is a typed triple — requirement (which machine field), code (machine-readable reason to branch on), reason (non-localized plain-English owner message) — and Stripe warns that adding a new code is a breaking change, so consumers must branch on code but degrade gracefully to reason for display. [stripe-api-verification]
- Stripe's requirements.disabled_reason (an enum since the 2024-11-20 API change) names WHY a whole capability is off and encodes non-owner-fixable/terminal cases (e.g. rejected.inactivity, risk-review requirements that "you can't provide using the API"), cleanly separating owner-fixable (collect a field → pending_verification → enabled) from not-owner-fixable (needs a remediation link or platform/Stripe-side action). [stripe-capabilities] [stripe-changelog-disabled-reason]
- Stripe generates an account-specific remediation link (valid 90 days, reusable) from the Dashboard's "Actions required" list; the account clicks → Stripe-hosted page → submits only the missing info; when multiple actions exist the list orders them most-urgent-first (Information request → past_due → currently_due → future → eventually_due). [stripe-review-accounts] [stripe-remediation-links]
- After resubmission Stripe sits in pending_verification and auto-enables on success; consumers listen for account.updated events and re-render — the verdict heals itself with no manual "re-enable" button, and the stated goal is to understand status "without examining webhook logs." [stripe-verification-updates] [stripe-review-accounts]
- Datadog monitors use a small closed status set (OK | Warn | Alert | No Data, plus Unknown for integration monitors) with one status per monitor, where Warn is the explicit "degraded but not broken" tier between OK and Alert. [datadog-status-page] [datadog-config]
- Datadog's No Data is a first-class verdict, never silently shown as OK — "No data is reporting" when a metric is expected to always report is a distinct status you can even notify on, because "looks fine but isn't reporting" is the dangerous failure. [datadog-status-page] [datadog-config]
- Datadog's Muted is an orthogonal axis, not a status: muting "suppresses notifications without resolving the underlying condition" — the monitor is still Alert and also muted — and integration-monitor Unknown shows in No-Data grey without flipping the overall monitor green. [datadog-status-page] [datadog-integration-monitor]
- Datadog aggregation is an explicit single decision: simple alert rolls up to ONE verdict (worst-wins — one Alert group makes the monitor Alert) while multi-alert emits per-group rows; the rollup is computed once, not implied by N independent signals. [datadog-aggregation]
- GitHub App suspension is one clear named state ("cannot access resources owned by that installation account") that must be "unsuspended in the same way it was suspended" — if the app owner suspended it the user cannot unsuspend it — rendering the owner-fixable vs not-owner-fixable distinction as UX by showing the action only to the party who can act. [github-suspend]
- Vercel's Git "disconnected" is one named broken state with enumerated causes and a single reconnect flow, but its false-disconnect race (Vercel "was unable to retrieve the app installation from GitHub, which made it appear as if the Vercel GitHub App was never installed") is the cautionary tale that a verdict must distinguish "genuinely broken" from "we can't currently read the truth" (fix: "wait a couple of minutes and try connecting again"). [vercel-error-list] [vercel-git-settings]
- Nango proactively refreshes each OAuth token at least once/24h and notifies via webhook when credentials become invalid; it operationalizes recoverable-vs-terminal as runtime policy — a 401 is retryable (exponential backoff 3s→10m cap), but if credentials do not change on the next fetch Nango treats it as a definitive auth failure and stops retrying, and for revoked refresh tokens (Salesforce invalid_grant, permanent) the only fix is to mark the account for re-authentication and tell the user. [nango-invalid-grant] [nango-logs]
- The universal error-message guidance (Nielsen heuristic 9 and UX writing sources) is two-layer legibility: a state-first tiny enum read instantly, one plain-language jargon-free blame-free action sentence ("state what the issue is, then what the user can do"), specific not generic (avoid "invalid input"), with technical detail demoted to developer-facing logs one layer down. [nng-error-heuristic] [logrocket-errors] [uxcc-errors]

## SOURCES

**plaid-update-mode**
URL: https://plaid.com/docs/link/update-mode/
Accessed: 2026-06-15
Quote: "Plaid does not require you to rotate these tokens when an item is reconnected as it is the same underlying item."

**plaid-item-errors**
URL: https://plaid.com/docs/errors/item/
Accessed: 2026-06-15
Quote: "Username or password incorrect: If you've recently updated your account with this institution, be sure you're entering your updated credentials"

**plaid-items-api**
URL: https://plaid.com/docs/api/items/
Accessed: 2026-06-15
Quote: "Fired when an Item exits ITEM_LOGIN_REQUIRED without going through update mode in your app."

**stripe-onboard**
URL: https://docs.stripe.com/connect/saas/tasks/onboard
Accessed: 2026-06-15
Quote: "If either of those attributes is false, check the Account's requirements hash to determine what information is needed."

**stripe-verification-updates**
URL: https://docs.stripe.com/connect/handle-verification-updates
Accessed: 2026-06-15
Quote: "currently_due / past_due / pending_verification, future_requirements"

**stripe-api-verification**
URL: https://docs.stripe.com/connect/handling-api-verification
Accessed: 2026-06-15
Quote: "requirements.errors[] requirement/code/reason"

**stripe-capabilities**
URL: https://docs.stripe.com/connect/account-capabilities
Accessed: 2026-06-15
Quote: "per-capability requirements, disabled_reason"

**stripe-review-accounts**
URL: https://docs.stripe.com/connect/dashboard/review-actionable-accounts
Accessed: 2026-06-15
Quote: "'Actions required' list, ordering"

**stripe-remediation-links**
URL: https://stripe.com/docs/connect/dashboard/remediation-links
Accessed: 2026-06-15

**stripe-changelog-disabled-reason**
URL: https://docs.stripe.com/changelog/acacia/2024-11-20/account-disabled-reason
Accessed: 2026-06-15
Quote: "account disabled_reason becomes an enum (2024-11-20)"

**stripe-changelog-error-codes**
URL: https://docs.stripe.com/changelog/basil/2025-03-31/adds-requirement-error-codes
Accessed: 2026-06-15
Quote: "adds requirement error codes (2025-03-31)"

**datadog-status-page**
URL: https://docs.datadoghq.com/monitors/status/status_page/
Accessed: 2026-06-15
Quote: "OK/Warn/Alert/No Data, Unknown, muted"

**datadog-config**
URL: https://docs.datadoghq.com/monitors/configuration/
Accessed: 2026-06-15
Quote: "No Data, thresholds, recovery"

**datadog-integration-monitor**
URL: https://docs.datadoghq.com/monitors/types/integration/
Accessed: 2026-06-15
Quote: "Unknown shown as No-Data grey, overall stays OK"

**datadog-aggregation**
URL: https://docs.datadoghq.com/monitors/guide/alert_aggregation/
Accessed: 2026-06-15
Quote: "simple vs multi-alert rollup"

**github-suspend**
URL: https://docs.github.com/en/apps/maintaining-github-apps/suspending-a-github-app-installation
Accessed: 2026-06-15
Quote: "A GitHub App must be unsuspended in the same way it was suspended."

**vercel-error-list**
URL: https://vercel.com/docs/errors/error-list
Accessed: 2026-06-15
Quote: "unable to retrieve the app installation from GitHub, which made it appear as if the Vercel GitHub App was never installed"

**vercel-git-settings**
URL: https://vercel.com/docs/project-configuration/git-settings
Accessed: 2026-06-15
Quote: "disconnect/reconnect flow"

**nango-invalid-grant**
URL: https://nango.dev/blog/salesforce-oauth-refresh-token-invalid-grant/
Accessed: 2026-06-15
Quote: "these errors are permanent, and the only way to fix them is to ask the user to re-authenticate"

**nango-logs**
URL: https://nango.dev/docs/guides/platform/logs
Accessed: 2026-06-15
Quote: "per-connection status, operations"

**nng-error-heuristic**
URL: https://www.uxtigers.com/post/heuristic-9-error-messages
Accessed: 2026-06-15
Quote: "state what the issue is in plain language, then what the user can do about it"

**logrocket-errors**
URL: https://blog.logrocket.com/ux-design/writing-clear-error-messages-ux-guidelines-examples/
Accessed: 2026-06-15

**uxcc-errors**
URL: https://uxcontent.com/how-to-write-error-messages/
Accessed: 2026-06-15

## SYNTHESIS

Five mature integration products independently converge on the same connector-health contract, which is a strong reusable template. (A) ONE synthesized verdict — a small closed enum, worst-wins rollup, computed once server-side and rendered verbatim so no surface re-derives state (Plaid Item status, Stripe enabled-booleans, Datadog OK/Warn/Alert/No-Data). Crucially the verdict ships with its mandatory orthogonal modifiers (Datadog "muted rides alongside," Plaid "never green while PENDING_*") — a modifier must never hide the headline, and "No Data / can't-tell" is never rendered as green (Datadog No-Data; Vercel's false-disconnect warns against collapsing "I can't read the truth" into either "broken" or "fine").

(B) A typed required-action, not a CTA string: which field is wrong, a machine code you branch on (handling unknown codes gracefully — Stripe treats new codes as breaking), a plain-English non-localized owner message you display directly (Stripe reason, Plaid display_message), an urgency tier (Stripe currently/past/eventually_due + pending_verification), and — the most-missed fields — an audience (owner vs maintainer; GitHub's "fixed the way it broke," Stripe's risk-review path) and a terminal flag (Stripe disabled_reason rejected.*): some states are not owner-fixable and must say so honestly instead of showing a false reconnect affordance. A third, often-missed "wait" bucket (Stripe pending_verification, Datadog syncing) means "nothing is wrong that you can fix; we're working/verifying."

(C) A satisfaction + self-heal contract: the repair lands on the EXISTING connection with the minimum input required and without rotating tokens/breaking schedules (Plaid update mode), and the verdict flips back to green automatically on a satisfaction event (Stripe account.updated → pending_verification → enabled; Plaid confirming pull) — including external self-heal that auto-dismisses the banner (Plaid LOGIN_REPAIRED). Nango operationalizes the recoverable→auto-retry-with-backoff vs terminal→surface-one-action branch as runtime policy, and the rule "don't surface an owner action while automatic recovery still has budget" falls straight out of it. Layered over all of this is the two-layer legibility standard (Nielsen heuristic 9): a glanceable plain-language state on top, engineer-grade codes/conditions/traces one layer down, specific never generic, and never two adjacent chips asserting incompatible facts.
