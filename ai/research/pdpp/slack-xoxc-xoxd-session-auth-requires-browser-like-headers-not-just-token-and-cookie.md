---
title: "Slack xoxc/xoxd browser-session-token auth (used by slackdump and PDPP's Slack connector) is documented in third-party implementations as needing browser-like request headers (Origin: https://app.slack.com), not just the Authorization/token + d cookie pair"
date: 2026-08-10
topic: pdpp
tags: [slack, auth, xoxc, xoxd, http-headers, connector]
status: draft
sources: [shaharia-blog, papermtn-blog]
source_session: 7dd49c6d-fefa-40d1-bf35-0bcd43c3eb67
---

## CLAIMS

- A third-party Go SDK guide for using Slack xoxc/xoxd session tokens builds
  a custom HTTP client that adds the xoxd token as a cookie AND sets
  browser-like headers including `Origin: https://app.slack.com`, passed to
  the Slack client alongside the xoxc token. [shaharia-blog]
- The `d` cookie (xoxd-prefixed) has a long-lived but non-infinite expiry;
  Slack shortened its default TTL as of December 2025, though it still
  commonly persists over a year. [shaharia-blog]
- Standard/official Slack Web API auth (app tokens) only requires the
  Authorization header or a POST token param — no special header posture is
  documented for that path. The extra header requirements are specific to
  the unofficial xoxc/xoxd *session*-based auth model, not Slack's supported
  OAuth token model. [shaharia-blog]
- PDPP's Slack connector (`packages/polyfill-connectors/connectors/slack/slack-api.ts`)
  authenticates `stars.list`/`usergroups.list`/`reminders.list`/
  `conversations.info` using exactly this xoxc token + `d`/`d-s` cookie
  pair, with only `Content-Type`/`Cookie`/`User-Agent` (`Authorization:
  Bearer` for GET) — no `Origin`, `Referer`, or `Sec-Fetch-*` headers are
  sent anywhere in the module. [pdpp-connector-code]

## SOURCES

**shaharia-blog**
URL: https://shaharia.com/blog/slack-browser-tokens-golang-sdk-bypass-app-creation/
Accessed: 2026-08-10
Quote: "you can build a custom HTTP client that adds the xoxd token as a cookie and browser-like headers including setting Origin to https://app.slack.com, which then gets passed to the Slack client alongside the xoxc token"

**papermtn-blog**
URL: https://www.papermtn.co.uk/retrieving-and-using-slack-cookies-for-authentication/
Accessed: 2026-08-10
Quote: (corroborating xoxc/xoxd session-cookie extraction/usage pattern; not directly quoted on headers)

**pdpp-connector-code**
URL: (local) packages/polyfill-connectors/connectors/slack/slack-api.ts, current repo HEAD 2ff3b99ed
Accessed: 2026-08-10
Quote: "headers: { 'Content-Type': 'application/x-www-form-urlencoded', Cookie: buildSlackSessionCookieHeader(cookie), 'User-Agent': USER_AGENT }" (slackApiPost); "headers: { Authorization: `Bearer ${token}`, Cookie: ..., 'User-Agent': ... }" (slackApiGet)

## SYNTHESIS

This is corroborating (not proving) evidence for a live PDPP UAT failure:
`stars`/`user_groups`/`reminders`/`dm_read_states` return `slack_auth_failed`
(401/invalid_auth) against a real workspace even though the SAME xoxc+d
credential succeeds for slackdump's own archive/resume subprocess in the
same run. Two independent, mutually-exclusive theories exist across
different (non-current) PDPP branch lineages: (a) a TLS ClientHello
fingerprint mismatch requiring a real Chromium transport (commit
e8800b655, not on `waspflow/slack-terminal-gaps-0810`), and (b) a stale/
rotated credential snapshot requiring post-archive credential re-adoption
(commit 5b879ce13, also not on that branch, and architecturally
inapplicable — that branch's connector re-reads credentials from a
snapshot cache the current branch's connector does not have).

Neither theory could be live-verified in this session (no live Slack
credentials, no browser-transport architecture in scope per task
constraints). This header gap is a third, independently-sourced, testable-
in-principle candidate that is simpler to fix (no new runtime dependency)
and consistent with "xoxc/xoxd is an unofficial session-replay auth model
that expects a browser-shaped request, not just the right token/cookie
values." It was not proven as root cause; it should be treated as a
reasonable, low-risk hardening applied alongside honestly disclosing the
failure as unconfirmed pending live acceptance, not as a claimed fix.
