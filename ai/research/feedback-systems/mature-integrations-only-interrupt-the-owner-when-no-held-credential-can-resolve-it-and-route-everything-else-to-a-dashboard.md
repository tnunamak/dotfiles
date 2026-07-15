---
title: "Mature integration products only interrupt the human when no automatic operation with held credentials can resolve the condition, and route every other honest signal to a dashboard/detail layer rather than the attention channel"
date: 2026-06-15
topic: feedback-systems
tags: [connector-health, calm-technology, alerting, silence-discipline, oauth-lifecycle, progressive-disclosure]
status: draft
sources: [plaid-item-errors, plaid-update-mode, plaid-items-api, nango-token-refresh, nango-webhooks, stripe-capabilities, stripe-verification, google-oauth, temporal-workflows, sre-monitoring, sre-alerting-slos, calm-tech-wiki, calm-tech-case, nng-progressive-disclosure]
---

## CLAIMS

- Plaid's canonical Item states are HEALTHY (silent), PENDING_EXPIRATION / PENDING_DISCONNECT (a ~7-day pre-emptive webhook warning), ITEM_LOGIN_REQUIRED (human required — auth broken, resolved via Link update mode), and transient ERROR (system retries silently); Plaid interrupts the user only for ITEM_LOGIN_REQUIRED, which cannot be resolved without the human's credentials. [plaid-item-errors] [plaid-update-mode]
- Plaid's LOGIN_REPAIRED webhook fires when an Item exits the bad state even if it was repaired elsewhere (e.g. the same account fixed in another app), giving the app an explicit "stop nagging" signal so recovery is a state transition, not a button click. [plaid-items-api] [plaid-update-mode]
- Nango automatically refreshes OAuth access tokens before expiry (silently) and at least once every 24h to prevent inactivity revocation; on refresh failure it sends the app a webhook, and the app (not Nango) decides whether to prompt the user — the platform owns the token lifecycle completely and notifies only after exhausting its own recovery. [nango-token-refresh] [nango-webhooks]
- Nango's webhooks surface only terminal outcomes (connection created, sync finished success/failure, auth refresh failure) and never surface the mechanism (individual token-refresh attempts, intermediate retries, rate-limit encounters, internal backoff state). [nango-webhooks]
- Stripe Connect tiers required actions by human-necessity: eventually_due (system monitors, no interrupt), currently_due (human required before a deadline), past_due (human required, urgent, capability disabled), with disabled_reason as a system-derived status; when a currently_due requirement is satisfied it simply disappears from the array — the absence of the requirement is the positive signal, not an explicit success notification. [stripe-capabilities] [stripe-verification]
- Google OAuth access tokens expire every 3600s and the client silently exchanges the refresh token for a new one with zero user involvement; human re-auth is required only when the user actively changes the trust relationship (explicit revoke, ~6-month inactivity expiry, or password change in some configs). [google-oauth]
- Temporal separates automatic silent activity retries (with backoff until the retry policy exhausts) from terminal workflow failure (human inspects and decides), and treats task-queue health (no pollers, lag) as a separate global runtime indicator — a runtime problem must not cascade as individual workflow failures. [temporal-workflows]
- The Google SRE Book's five-question alert test asks whether a rule detects an otherwise-undetected condition that is urgent, actionable, and imminently user-visible; whether it can ever be safely ignored (if so it is a design defect); whether it definitely indicates user harm; whether an action is possible and whether it could be safely automated; and whether others are already paged (redundancy = noise). [sre-monitoring]
- The SRE Book prescribes alerting on symptoms ("what's broken") not causes ("why") — "A healthy monitoring and alerting pipeline is simple... It focuses primarily on symptoms for paging, reserving cause-oriented heuristics to serve as aids to debugging problems" — and favors a dashboard over email alerts for subcritical problems. [sre-monitoring]
- The SRE Workbook holds that alerts should notify a human only for actionable, specific threats to the error budget, and that "Pages and tickets are the only valid ways to get a human to take action." [sre-alerting-slos]
- Alert fatigue is a documented self-reinforcing failure: after roughly 100 low-signal alerts per day operators develop "alert blindness," and once they stop trusting the channel, real alerts are also missed — the primary cause being honest-but-non-actionable alerts. [sre-monitoring]
- Weiser & Brown's calm technology (1995) is "that which informs but doesn't demand our focus or attention," resting on three principles: the user's attention should reside mainly in the periphery; technology should increase effective use of the periphery; and it should convey familiarity/situational awareness without active checking. [calm-tech-wiki]
- Amber Case's eight calm-technology principles include: technology should require the smallest possible amount of attention; inform without demanding focus; make use of the periphery; work even when it fails (graceful degradation); and use the right (minimum) amount of technology to solve the problem. [calm-tech-case]
- Products cited as calm technology (Tailscale, Time Machine/Backblaze, Dropbox) share a pattern: ambient status available on demand in the periphery (a menu-bar dot, "last backed up X hours ago"), with active interruption reserved only for human-required failures (auth expired, no backup in N days, storage full). [calm-tech-wiki]
- NN/g progressive disclosure defers secondary content to lower-level views: "higher-level pages contain higher-level concepts; lower-level pages fill in the details for those users who want to know everything" — the mechanism for keeping an attention layer clean while a full-fidelity inspection layer remains one click away. [nng-progressive-disclosure]

## SOURCES

**plaid-item-errors**
URL: https://plaid.com/docs/errors/item/
Accessed: 2026-06-15
Quote: "ITEM_LOGIN_REQUIRED = only human-required state"

**plaid-update-mode**
URL: https://plaid.com/docs/link/update-mode/
Accessed: 2026-06-15
Quote: "LOGIN_REPAIRED webhook = explicit 'stop nagging'"

**plaid-items-api**
URL: https://plaid.com/docs/api/items/
Accessed: 2026-06-15
Quote: "PENDING_DISCONNECT = pre-emptive 7-day warning"

**nango-token-refresh**
URL: https://nango.dev/docs/guides/auth/token-refreshing
Accessed: 2026-06-15
Quote: "Silent automatic refresh; failure → webhook only"

**nango-webhooks**
URL: https://docs.nango.dev/guides/platform/webhooks-from-nango
Accessed: 2026-06-15
Quote: "Webhook shape: only terminal outcomes, not mechanism"

**stripe-capabilities**
URL: https://stripe.com/docs/connect/account-capabilities
Accessed: 2026-06-15
Quote: "eventually_due / currently_due / past_due tiering"

**stripe-verification**
URL: https://stripe.com/docs/connect/handling-api-verification
Accessed: 2026-06-15
Quote: "Auto-clear on satisfaction; absence = positive signal"

**google-oauth**
URL: https://developers.google.com/identity/protocols/oauth2/web-server#offline
Accessed: 2026-06-15
Quote: "Silent refresh; human only for revoked trust"

**temporal-workflows**
URL: https://docs.temporal.io/workflows
Accessed: 2026-06-15
Quote: "Runtime health ≠ workflow health; terminal = human"

**sre-monitoring**
URL: https://sre.google/sre-book/monitoring-distributed-systems/
Accessed: 2026-06-15
Quote: "Email alerts are of very limited value and tend to easily become overrun with noise; instead, you should favor a dashboard that monitors all ongoing subcritical problems."

**sre-alerting-slos**
URL: https://sre.google/workbook/alerting-on-slos/
Accessed: 2026-06-15
Quote: "Pages and tickets are the only valid ways to get a human to take action."

**calm-tech-wiki**
URL: https://en.wikipedia.org/wiki/Calm_technology
Accessed: 2026-06-15
Quote: "Calm technology: that which informs but doesn't demand our focus or attention. — Weiser & Brown"

**calm-tech-case**
URL: https://calmtech.com
Accessed: 2026-06-15
Quote: "Amber Case's eight principles of calm technology (formalizing Weiser & Brown)."

**nng-progressive-disclosure**
URL: https://www.nngroup.com/articles/progressive-disclosure/
Accessed: 2026-06-15
Quote: "higher-level pages contain higher-level concepts; lower-level pages fill in the details"

## SYNTHESIS

Across Plaid, Nango, Stripe, Google OAuth, and Temporal a single agency-frontier rule recurs: involve the human when and only when the condition cannot be resolved by any operation the system can perform with credentials and access it already holds, and inaction would cause permanent loss. Everything the system can retry, wait out, rotate, or refresh, it does silently. Plaid's ITEM_LOGIN_REQUIRED is the archetype of the exception (credentials the system does not have), and its LOGIN_REPAIRED webhook is the archetype of self-heal — recovery is a state transition, not a user button. Stripe adds the urgency dimension (eventually/currently/past_due) and the "absence-of-requirement is the success signal" idea; Temporal adds the crucial rule that a runtime failure must surface as one global indicator, never as N cascaded per-item failures.

The complementary "silence discipline" comes from Google SRE: an alert that can be automated or safely ignored is a design defect; alert on symptoms not causes; route subcritical, self-healing, cause-level information to a dashboard, not an attention channel — because honest-but-non-actionable alerts are precisely what produce alert fatigue and, ultimately, missed real alerts. Calm technology (Weiser & Brown; Amber Case) supplies the design ideal: default to the periphery, shift to the center only when human action is genuinely required, and build trust by being right when you speak rather than by speaking often. The honesty↔usefulness tension resolves via two-layer honesty backed by NN/g progressive disclosure: an attention layer that shows only what the human can act on, and a full-fidelity inspection/detail layer one click down that never lies and never withholds — suppressing a non-actionable signal from the attention channel is correct behavior, not dishonesty, so long as the truth remains accessible.
