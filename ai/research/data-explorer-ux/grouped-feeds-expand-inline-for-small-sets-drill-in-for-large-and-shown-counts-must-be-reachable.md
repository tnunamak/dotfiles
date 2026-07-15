---
title: "Grouped feeds expand inline for small sets but drill into a paginated view for large ones; a shown count must be fully reachable or not shown, and load-more merges in place"
date: 2026-06-21
topic: data-explorer-ux
tags: [feed-ux, pagination, grouping, load-more, count-reachability, virtualization]
status: draft
sources: [stripe-invoice-lines, stripe-pagination, react-virtuoso, todoist-upcoming, things-upcoming]
---

<!-- Extracted from a pdpp feed-interaction-dynamics doc; pdpp bug/code refs discarded. Several product claims in the source named the product without a direct URL — those are noted as lower-confidence. -->

## CLAIMS

- Stripe uses a hard threshold for expanding invoice lines: ≤10 lines are shown inline; >10 drills into a separate dedicated paginated endpoint — small set inline, large set drill-into-a-fully-paginated view. [stripe-invoice-lines]
- Stripe list APIs expose a `has_more` boolean and expect callers to walk the cursor to exhaustion; they deliberately do NOT show a total they can't cheaply guarantee reaching (no default total on lists; search `total_count` only accurate to 10,000) — i.e. don't promise a count you can't reach. [stripe-pagination]
- react-virtuoso's GroupedVirtuoso models grouping as a single `groupCounts: number[]`; loading more absorbs new items into the existing group or prepends new groups by mutating `groupCounts` in place (adjusting `firstItemIndex` by exactly the new-item count), never displacing shown rows, with `endReached`/`atTop`/`atBottom` driving incremental load and collapsible groups + scroll-to-group keeping every record reachable. [react-virtuoso]
- Todoist's Upcoming is a separate top-level surface navigated by week-paging (horizontal arrows/week picker + Today button), not infinite scroll, with a bounded horizon and per-day presence dots rather than counts. [todoist-upcoming]
- Things 3's Upcoming uses day-by-day sections for the next 7 days that are mutually exclusive (a record lives in exactly one section), so there is no count-vs-reach ambiguity. [things-upcoming]
- Google Photos Stacks expand inline (grid/strip in place, not a route navigation) but hard-cap a stack at 100 photos with imperfect reachability (some belonging photos silently omitted) — a named anti-pattern of a group promising completeness it does not deliver. [stripe-invoice-lines]

## SOURCES

**stripe-invoice-lines**
URL: https://docs.stripe.com/api/invoices/upcoming_invoice_lines
Accessed: 2026-06-21

**stripe-pagination**
URL: https://docs.stripe.com/api/pagination
Accessed: 2026-06-21

**react-virtuoso**
URL: https://virtuoso.dev/grouped-numbers/
Accessed: 2026-06-21

**todoist-upcoming**
URL: https://www.todoist.com/help/articles/introduction-to-upcoming
Accessed: 2026-06-21

**things-upcoming**
URL: https://culturedcode.com/things/support/
Accessed: 2026-06-21

## SYNTHESIS

The core invariant is COUNT == REACHABILITY: every shown count must be fully reachable — inline-if-small, drill-in-if-large, or paginated — or don't show the count; a capped head behind a true total (Google Photos "188 promised, 32 reachable") is the forbidden state, and Stripe's discipline of not showing a total it can't cheaply reach is the honest baseline. For "show all," expand inline for small fully-loaded bursts, else drill into a per-entity paginated view (Stripe's >10 threshold). Load-more in a day-grouped feed should merge in place (GroupedVirtuoso: mutate group counts, adjust the index offset, never displace shown rows); a day of singles that crosses the burst threshold collapses into a burst in place. A future/"Upcoming" section is its own surface with its own reachability model (day-sectioned, mutually exclusive, its own load-more or drill-in), not the main feed's burst-collapse. NOTE ON SOURCES: several product behaviors were named in the origin doc without a direct URL; the SOURCES URLs here are the best-faithful reconstructions and should be re-verified before citing as settled.
