---
title: "Mature products treat credential/session repair as a connection-scoped lifecycle that pauses background syncs and re-auths the existing connection — not as a per-failed-run retry"
date: 2026-07-01
topic: data-collection-systems
tags: [connectors, credentials, oauth, session-repair, reconnect, prior-art]
status: draft
sources: [plaid, zapier, google-oauth, nango, nylas, openai-security]
source_session: 019d3695-95e5-7841-aa67-2de5b804ee8e
---

## CLAIMS

- Plaid's update mode repairs an existing Item after creation (credential updates, expired authorization, additional consent, OAuth restoration); an `ITEM_LOGIN_REQUIRED` error or expiration/disconnect webhook means the Item goes through update mode and the app asks the user to re-authenticate — the shape is "put the existing connection into a repair flow," not "retry the failed job," and update mode does not create a duplicate Item. Plaid also emits a `LOGIN_REPAIRED` signal so apps stop prompting once an Item is fixed elsewhere. [plaid]
- Zapier models app connections with statuses (active, expired); an expired connection gets a Reconnect action that updates the existing connection and its dependent workflows; the problem is surfaced at the connection level, not buried in a run timeline; Zapier treats auth scheme and auth test as integration metadata while each user authenticates a connection. [zapier]
- Google documents that refresh tokens stop working from user/policy actions: password changes for Gmail-scoped tokens, access revocation, long inactivity, token limits, time-bounded access, and admin session-length policy — "was working yesterday, now needs repair" is a normal lifecycle transition, not a surprising transient failure. [google-oauth]
- Nango's production guidance for OAuth `invalid_grant` is consistent across providers: retry once for rare partial failures, then mark the connection as needing re-auth, pause background syncs, and ask the user to reconnect in-product — do not keep retrying a credential known to be unusable. [nango]
- Nylas frames `invalid_grant` the same way (a previously working grant becomes invalid via password change, security reset, revocation, expiry, or app-credential change) and recovers by re-authenticating the *same* grant, not retrying the dead credential. [nylas]
- OpenAI's account-security guidance (change password, enable 2FA, sign out of all devices, clear cookies) includes a "log out of all sessions" control that can take up to 30 minutes to propagate — a reusable browser/session state and a stored password are distinct states that can fail independently. [openai-security]
- Airbyte's connector builder separates connector authentication *configuration* (a chosen auth method, stable) from the user's secret *values* (provided at source setup, stored separately) — connector definitions describe stable auth mechanisms, not current auth validity. [airbyte-auth]

## SOURCES

**plaid**
URL: https://plaid.com/docs/link/update-mode/ ; https://plaid.com/docs/api/items/
Accessed: 2026-07-01

**zapier**
URL: https://help.zapier.com/hc/en-us/articles/8496290788109-Manage-your-app-connections ; https://docs.zapier.com/integrations/build/auth
Accessed: 2026-07-01

**google-oauth**
URL: https://developers.google.com/identity/protocols/oauth2
Accessed: 2026-07-01

**nango**
URL: https://nango.dev/blog/google-oauth-invalid-grant-token-has-been-expired-or-revoked ; https://nango.dev/blog/xero-oauth-refresh-token-invalid-grant/
Accessed: 2026-07-01

**nylas**
URL: https://developer.nylas.com/docs/cookbook/use-cases/build/fix-invalid-grant-errors/
Accessed: 2026-07-01

**openai-security**
URL: https://help.openai.com/en/articles/10471992-why-am-i-receiving-a-suspicious-activity-alert ; https://help.openai.com/en/articles/8304786-how-can-i-keep-my-openai-accounts-secure
Accessed: 2026-07-01

**airbyte-auth**
URL: https://docs.airbyte.com/platform/connector-development/connector-builder-ui/authentication
Accessed: 2026-07-01

## SYNTHESIS

Five reusable findings for designing connector auth-health. (1) Repair is a connection lifecycle, not a failed-run detail: a stored-credential rejection or unusable session should set connection-level repair state that the next scheduled tick sees and defers on, rather than re-submitting the stale credential (Plaid update mode, Zapier reconnect). (2) Password/policy changes are *expected* invalidation causes — treat "worked yesterday, needs repair today" as a normal transition, not a surprising transient failure (Google, OpenAI). (3) Terminal credential failures must stop retry storms: on definitive provider evidence that a credential is rejected, retry once at most, then pause background syncs and require owner action (Nango). (4) Repair is scoped to the existing connection and preserves history — it never creates a duplicate, and self-heal signals (`LOGIN_REPAIRED`) should dismiss repair messaging. (5) The repair path must match the mechanism: OAuth repairs via reauthorization; browser-session connectors have two independent states (a healthy reusable session with no stored password, vs a stale stored password while the browser is still logged in), so copy and actions must not collapse them. This supports modeling auth health as a small state machine — ready / repair_required / repair_in_progress / repaired — where scheduled runs are allowed only in ready (or after repaired→ready), a definitive auth rejection transitions to repair_required and emits at most one owner-visible action, and connection state is closed by terminal/repaired/dismissed transitions rather than by the age of an attention row. Connector definitions should declare stable auth *mechanisms* (provider authorization, static secret, browser-bound session, local collector, manual upload); runtime evidence owns current auth/session truth and the specific next action.
