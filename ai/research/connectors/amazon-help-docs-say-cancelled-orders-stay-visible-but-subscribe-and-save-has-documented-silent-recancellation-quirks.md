---
title: "Amazon's own help documentation says cancelled orders remain visible under Your Orders, but Subscribe & Save has a documented history of silently re-cancelling, re-pricing, or re-scheduling recurring deliveries with no email notice"
date: 2026-08-22
topic: connectors
tags: [amazon, subscribe-and-save, order-history, cancelled-orders, browser-scraping, connectors]
status: draft
sources: [amazon-cancel-items-orders, amazon-order-history, amazon-archived-orders, phatwallet-sns-change, slickdeals-sns-price-increase, slickdeals-sns-cancellation-warning, slickdeals-sns-overcharge-psa]
source_session: aeafd460-e6ea-44b8-b3bb-ed70b28b3b84
---

## CLAIMS

- Amazon's own help pages describe cancelled orders as staying visible under a
  "Cancelled Orders" filter/tab in Your Orders, not disappearing from order history.
  [amazon-cancel-items-orders] [amazon-order-history]
- Amazon's "Archived Orders" feature is opt-in and owner-controlled (the owner explicitly
  archives/unarchives an order); it is not a mechanism by which Amazon itself silently
  hides cancelled orders from a year-filtered list view. [amazon-archived-orders]
- No official Amazon documentation or forum consensus was found describing a policy or
  rendering change where cancelled orders (Subscribe & Save or otherwise) are dropped
  from the `timeFilter=year-N` list view. Reports of "disappeared" orders are almost
  universally resolved by date-filter confusion (a UI default that hides older years),
  not genuine server-side removal.
- Subscribe & Save (S&S) has real, community-documented quirks distinct from ordinary
  orders: Amazon has silently cancelled an S&S delivery and re-placed it later at a
  different (often higher) price, sometimes with no cancellation email at all.
  [phatwallet-sns-change] [slickdeals-sns-price-increase]
- At least one anecdotal forum report describes an S&S cancellation disappearing even
  from the dedicated cancelled-orders tab — but this is a single anecdote, not a
  documented pattern, and does not by itself establish a reproducible rendering
  condition. [slickdeals-sns-cancellation-warning]
- Community threads (50+ users in one case) report Amazon overcharging or silently
  altering S&S orders without notice, which is a distinct defect class from "order
  vanishes from history" but comes from the same subsystem (S&S's own scheduling/pricing
  logic runs somewhat independently of the standard order pipeline).
  [slickdeals-sns-overcharge-psa]

## SOURCES

**amazon-cancel-items-orders**
URL: https://www.amazon.com/gp/help/customer/display.html?nodeId=GSL37WQTJZUYA9QE
Accessed: 2026-08-22
Quote: "You can find your cancelled orders in Your Orders by selecting the Cancelled Orders filter."

**amazon-order-history**
URL: https://www.amazon.com/gp/help/customer/display.html?nodeId=TtIlfDXS8T0dtYXu0z
Accessed: 2026-08-22

**amazon-archived-orders**
URL: https://www.amazon.com/gp/help/customer/display.html?nodeId=G7882F7JTSV9N5BS
Accessed: 2026-08-22
Quote: "Archived orders are hidden from your order history until you choose to unarchive them."

**phatwallet-sns-change**
URL: https://phatwalletforums.com/topic/37993/amazon-subscribe-save-anyone-else-notice-the-change
Accessed: 2026-08-22

**slickdeals-sns-price-increase**
URL: https://slickdeals.net/f/17807865-amazon-no-longer-allowing-subscribe-and-save-delivery-date-change-without-price-increases
Accessed: 2026-08-22

**slickdeals-sns-cancellation-warning**
URL: https://slickdeals.net/f/11291011-amazon-subscribe-and-save-cancellation-warning
Accessed: 2026-08-22

**slickdeals-sns-overcharge-psa**
URL: https://slickdeals.net/f/12567832-psa-amazon-subscribe-save-check-your-order-history-closely-amazon-may-be-overcharging-you-for-certain-sd-purchases-edited-to-add-first-s-s-purchase-can-get-changed-first
Accessed: 2026-08-22

## SYNTHESIS

For any PDPP connector touching Amazon order history (`packages/polyfill-connectors/connectors/amazon`),
this means: if a scrape shows fewer cancelled orders than a prior scrape of the same
account, do not reach first for "Amazon changed what it shows" — that has no supporting
precedent in Amazon's own docs or community reports at the granularity of a few weeks.
Reach first for a scraper-side explanation (DOM shape variant for a never-shipped/
zero-total order, a race in the list page's render-completeness wait, an
under-tested code path) or, if the missing orders are specifically Subscribe & Save,
consider that S&S's cancellation/re-pricing pipeline is documented as behaving
somewhat independently of normal orders and may be a source of genuine data
inconsistency worth a targeted, permission-scoped live capture to confirm — but that is
a hypothesis to verify with a real DOM fixture, not something to assume from prior art.
As with H-E-B's passkey prompt (see the sibling `connectors/heb-passkey-...` entry), the
right next step when this recurs is capturing a real DOM snapshot the next time a
cancelled order is present during a permitted run, not guessing selector or timing
behavior against undocumented Amazon UI.
