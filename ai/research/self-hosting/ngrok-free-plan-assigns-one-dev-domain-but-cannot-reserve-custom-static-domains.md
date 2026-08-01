---
title: "ngrok’s free plan assigns one stable development domain but cannot reserve or customize static domains"
date: 2026-07-22
topic: self-hosting
tags: [ngrok, tunnels, domains, onboarding, federation]
status: settled
sources: [ngrok-free-limits, ngrok-javascript, ngrok-signup]
source_session: 019f8b9a-52e7-7bc0-9b69-0c53f68381c7
---

## CLAIMS

- ngrok’s free plan includes one automatically assigned development domain, which can be used for up to three online endpoints. [ngrok-free-limits]
- Free-plan users cannot choose, reserve, or create a custom static domain; custom names and bring-your-own domains require a paid plan. [ngrok-free-limits]
- The official JavaScript SDK exposes `forward({ addr, authtoken })` and returns a listener whose URL is the public endpoint; the SDK package contains the ngrok agent and does not require a separately installed binary. [ngrok-javascript]
- ngrok’s signup page currently offers GitHub and Google signup options. [ngrok-signup]

## SOURCES

**ngrok-free-limits**
URL: https://ngrok.com/docs/pricing-limits/free-plan-limits
Accessed: 2026-07-22

**ngrok-javascript**
URL: https://ngrok.com/docs/getting-started/javascript
Accessed: 2026-07-22

**ngrok-signup**
URL: https://dashboard.ngrok.com/signup
Accessed: 2026-07-22

## SYNTHESIS

For a non-technical self-hosting flow, ask the operator for an authtoken and
let the SDK create an endpoint on the account’s assigned development domain.
Do not promise a free operator-selected static domain or send the person on a
dashboard hunt for one: that product assumption is currently false. The
assigned domain is stable enough for a small collective but free HTTP browser
traffic has an ngrok interstitial and finite transfer/request limits, so it is
not a production alias-service substitute.
