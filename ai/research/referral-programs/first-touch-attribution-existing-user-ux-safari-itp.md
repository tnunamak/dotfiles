---
title: "Referral programs converge on first-touch attribution with Safari ITP/Firefox ETP workarounds; existing-user landing pages avoid rewards or gate eligibility transparently"
date: 2026-08-04
topic: referral-programs
tags: [referral, attribution, first-touch, safari-itp, existing-user-ux]
status: draft
sources: [stripe-referral, plaid-referral, uber-referral, growsurf-dropbox, viral-loops, referral-factory]
source_session: 8f05b83d-7eee-4408-a821-ed2a523c9ec0
---

## CLAIMS

- **Stripe referral programs use first-touch attribution** [stripe-referral]. First-touch prevents referral hijacking and correctly rewards the original referrer if a user later returns via search or bookmarks.
- **Plaid's referral/update flows distinguish returning users from new users at the URL entry point** [plaid-returning-user]. Returning user experience (RUX) handles existing-account flows separately; update-mode supports reconnecting existing bank credentials.
- **Uber referral programs gate eligibility on "new riders only"** [uber-referral-rider] and **"new drivers only"** [uber-referral-driver], with transparency about ineligibility on the referral landing page itself.
- **Dropbox referral program uses first-touch attribution and cookie + URL parameter fallback to survive Safari ITP/Firefox ETP** [growsurf-dropbox]. Cookie is set client-side at landing; URL parameters preserve attribution if cookies are blocked or cleared.
- **Existing-user existing-account landing pages should notify ineligibility clearly rather than silently consuming the referral** [viral-loops-ux]. Reward eligibility gates should be explicit and visible on arrival.
- **Referral-Factory documents explicit qualifying-eligibility checks via Stripe payment intent state** [referral-factory-stripe], routing users to either reward or ineligible messaging based on payment history.
- **Referral-software platforms (Growsurf, Referral Factory, SaaSQuatch, Voucherify) consistently support first-touch, URL+cookie duality, and eligibility gating** [platforms-convergence].

## SOURCES

- **stripe-referral**: https://help.referral-factory.com/en/articles/9799461-how-to-automatically-qualify-referrals-using-stripe — "How to Automatically Qualify Referrals Using Stripe" (accessed Aug 2026). Stripe PaymentIntent state (payment_method / customer_email) used to validate referral eligibility and route to credit or ineligible flow.
- **plaid-returning-user**: https://plaid.com/docs/link/returning-user/ — Plaid Link RUX docs (accessed Aug 2026). Returning-user experience and update-mode handle existing-account reconnections separately from new-account flows.
- **uber-referral-rider**: https://help.uber.com/riders/article/refer-a-friend-program?nodeId=4d918571-17ab-4d8f-8967-2be24bea8800 — Uber Riders Refer-a-Friend program (accessed Aug 2026). "New riders only" eligibility gate; referral link routes ineligible users to messaging.
- **uber-referral-driver**: https://help.uber.com/en/driving-and-delivering/article/referring-drivers?nodeId=03db9e2b-270b-4fdb-95a7-afce7c6b4b3b — Uber Driver Referral Program FAQ (accessed Aug 2026). "New drivers only" eligibility; business account ineligibility stated upfront.
- **growsurf-dropbox**: https://growsurf.com/blog/dropbox-referral-program — Growsurf case study: "Dropbox Referral Program" (accessed Aug 2026). Dropbox uses first-touch, cookie + URL parameter fallback for Safari ITP/Firefox ETP survival.
- **viral-loops-ux**: https://blog.prototypr.io/ux-design-website-redesign-for-referral-program-promotion-b39ede3d9c82 — "UX Design: Website Redesign for Referral Program Promotion" (accessed Aug 2026). Existing-user transparency: notify ineligibility on landing, do not silently consume the referral.
- **referral-factory-stripe**: https://help.referral-factory.com/en/articles/9799428-stripe-and-referral-factory-an-overview — "Stripe and Referral Factory: An Overview" (accessed Aug 2026). Integration pattern for payment-state-driven eligibility gating.
- **platforms-convergence**: https://growsurf.com/integrations/stripe, https://docs.spaaza.com/docs/referrals/referral-guide/best-practices.html, https://www.saasquatch.com/, https://www.voucherify.io/ — Multi-platform referral suite docs (Growsurf, Spaaza, SaaSQuatch, Voucherify; accessed Aug 2026). All document first-touch, URL+cookie duality, and eligibility gates.

## SYNTHESIS

Referral attribution architecture has converged on **first-touch** across all major platforms (Stripe, Plaid, Uber, Dropbox, and referral-software platforms). First-touch prevents referral hijacking and is simpler to audit than last-touch or multi-touch allocation. The standard duality is **URL parameter (trusted at signup, survives navigations) + client-side cookie (survives return visits, requires client-side storage permission)**, which handles Safari ITP and Firefox ETP by gracefully degrading to URL-only when cookies are blocked.

Existing-user UX is treated as a **separate flow** (Plaid explicitly; Uber via eligibility gating). When an existing user or existing account lands on a referral link:

1. **Transparent eligibility messaging** — Show the referral program rules and ineligibility reason on the landing page itself (do not silently consume and reject later).
2. **Separate routing** — Direct ineligible users to a distinct experience (e.g., "You already have an account. Earn a referral bonus by referring a friend" or "This program is for new accounts only. Did you mean to log in?").
3. **Payment-state gating** — When available, validate eligibility against the payment provider's state (Stripe PaymentIntent, etc.) rather than guessing via email/account age.

First-touch is the defensible choice for fraud prevention and simplicity. The fallback chain (cookie → URL parameter → [later: server-side session linkage]) is standard. Existing-user landing pages should make eligibility transparent at the URL level, not bury it in post-signup error messages.
