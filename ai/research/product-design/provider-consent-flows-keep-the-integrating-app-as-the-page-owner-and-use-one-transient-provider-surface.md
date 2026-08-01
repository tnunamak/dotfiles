---
title: "Provider consent flows keep the integrating app as the page owner and use one transient provider surface"
date: 2026-07-10
topic: product-design
tags: [consent, oauth, popup, redirect, iframe, cross-tab]
status: complete
sources: [plaid-link, stripe-financial-connections, stripe-checkout, paypal-sdk, web-locks, broadcast-channel]
source_session: 019d4502-2fc3-7ff2-b561-d709fda6e77c
---

## CLAIMS

- Plaid Link runs a provider-owned consent surface from the integrating app and reports completion through explicit success, exit, and event callbacks. [plaid-link]
- Stripe Financial Connections opens an on-page provider modal and resolves a client-side call with a completed session or error. [stripe-financial-connections]
- Stripe Checkout offers either a hosted redirect that returns to the integrating site or an embedded form that completes in the integrating page. [stripe-checkout]
- PayPal's current SDK supports popup, modal, and redirect presentation, with popup-first `auto` mode and an approval callback in the integrating page. [paypal-sdk]
- Web Locks provides origin-scoped mutual exclusion across tabs and workers; BroadcastChannel provides same-origin messaging but not mutual exclusion. [web-locks] [broadcast-channel]

## SOURCES

**plaid-link**
URL: https://plaid.com/docs/link/web/
Accessed: 2026-07-10

**stripe-financial-connections**
URL: https://docs.stripe.com/financial-connections/fundamentals
Accessed: 2026-07-10

**stripe-checkout**
URL: https://docs.stripe.com/payments/checkout
Accessed: 2026-07-10

**paypal-sdk**
URL: https://developer.paypal.com/sdk/react/reference
Accessed: 2026-07-10

**web-locks**
URL: https://developer.mozilla.org/en-US/docs/Web/API/Web_Locks_API
Accessed: 2026-07-10

**broadcast-channel**
URL: https://developer.mozilla.org/en-US/docs/Web/API/Broadcast_Channel_API
Accessed: 2026-07-10

## SYNTHESIS

The convergent user-journey pattern is one stable integrating-app page plus one transient provider-owned consent surface. Redirect variants replace the current page and return explicitly; embedded and popup variants preserve the integrating page and return a narrow completion artifact. None requires two full provider pages to compete for one local runtime.

For a provider marketplace that launches an external app, same-tab app launch followed by a transient provider approval window removes the duplicate-provider-tab path without changing the consent protocol. Independently, a provider runtime that must survive arbitrary same-origin tabs should use hard origin-scoped ownership plus state fan-out: Web Locks for mutual exclusion and BroadcastChannel only for communication.
