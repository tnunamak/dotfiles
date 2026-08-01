---
title: "Raycast and Stripe keep list rows minimal, push depth into a side detail pane, treat zero-results as a routing opportunity, and render filter chips as dual suggested/active states"
date: 2026-06-23
topic: data-explorer-ux
tags: [command-palette, search-ranking, filter-chips, detail-pane, status-pills, progressive-disclosure, raycast, stripe]
status: draft
sources: [raycast-fallback, raycast-aliases, raycast-list-api, raycast-detail-api, raycast-colors, raycast-best-practices, raycast-fresh-look, raycast-deep-dive, raycast-quicklook, stripe-dash-search, stripe-filter-controls, stripe-chip, stripe-dash-basics, stripe-connect-filters, stripe-search-api, stripe-may-2024, designmd-stripe, designmd-stripe-breakdown, eleken-stripe, eleken-filter-ux, saasframe-stripe, nng-progressive-disclosure]
source_session: 019d45f8-df0e-75d0-af07-12f3ebaa7527
---

## CLAIMS

- Raycast root search ranks by two local signals only — text match (acronym/prefix-of-words, e.g. `sf` → "Search Files", not full BM25) weighted by frequency × recency of use; there is no cloud ML or collaborative filtering, and all ranking is on-device. [raycast-fresh-look] [raycast-deep-dive]
- When Raycast root search returns exactly zero results, the list is replaced by a "Fallback Commands" section — a user-ordered list of commands (File Search, Google Search, any Quicklink or Script Command with a single argument) that each receive the typed string as their argument; the section appears only on empty results, not as a persistent "also try" affordance, and pressing Enter invokes the fallback with the query pre-filled. [raycast-fallback]
- Raycast's Action Panel (Cmd-K) lists every available action for the current selection with its keyboard shortcut inline, so shortcut education happens at the moment of use rather than in onboarding. [raycast-best-practices]
- Any Raycast command can be assigned a user alias; typing alias + Space + query routes directly to the command with the query pre-filled, collapsing a multi-step flow into one gesture. [raycast-aliases]
- Raycast's 2021 "fresh look" redesign enlarged leading row icons to a 16pt monoline grid explicitly to make rows quicker to scan. [raycast-fresh-look]
- When `isShowingDetail` is true, Raycast renders a persistent right-side panel with a Markdown area plus a structured `List.Item.Detail.Metadata` panel (Label / Link / TagList / Separator) that updates in real time as the user navigates up/down; official guidance is to NOT also show row accessories when the detail pane is shown, to avoid information doubling. [raycast-detail-api] [raycast-list-api]
- Raycast's master-detail split is persistent (not a modal/drawer): the panel updates live as the keyboard selection moves, keeping the user in the list and in keyboard mode. [raycast-list-api]
- Raycast ships a user-controlled "Compact" density mode that blends elements for a minimal appearance during search-and-execute flows. [raycast-list-api]
- Raycast list-item `accessories` (trailing right-aligned metadata) render right-to-left from the trailing edge, placing the most important metadata closest to the text. [raycast-list-api]
- Extensions can use Raycast's built-in client-side filter (`filtering={true}` on `<List>`) or handle `onSearchTextChange` for custom/server-side ranking. [raycast-list-api]
- The Stripe payments/transactions list leads with the amount column (left anchor), right-aligned within its column using tabular numbers (`font-feature-settings: 'tnum'`) so decimals align without a monospace font. [designmd-stripe] [saasframe-stripe]
- Stripe's dashboard UI uses only two font weights — 400 (dominant, ~1,136 occurrences) and 300 (subdued, ~242 occurrences) — with no 500/600/700; hierarchy is communicated through color and size, not weight: amount 16px `#061b31`, description 14px `#273951`, date/metadata 14px `#64748d`. [designmd-stripe] [designmd-stripe-breakdown]
- Stripe status badges use a pale (100-level) tinted background with 600-700-level text (e.g. pale-green background, dark-green "Succeeded"), border-radius ~100px, keeping status present on every row without saturating the feed. [designmd-stripe] [eleken-stripe]
- Stripe surfaces a few prominent filters inline and hides the rest behind a "More filters" expandable list organized into named categories (Account, Capability, Properties, Risk Management, Metadata), with metadata filters last. [stripe-connect-filters] [stripe-filter-controls]
- Stripe's chip pattern has two distinct states rendered as separate elements — a Suggested chip (field name + `+`, invites interaction) and an Active chip (`FieldName: Value` + `×` to clear); wrapping an active chip in a Link triggers a documented bug where onClose and the Link press fire simultaneously (clears the filter and reopens the menu). [stripe-filter-controls] [stripe-chip]
- Stripe shows a "Clear filters" link at the end of the chip row only when at least one filter is active, keeping the toolbar clean at rest. [stripe-filter-controls]
- Stripe's payments list shows exactly four data points per row — amount, description/customer, status badge, date — with card brand as a small icon and payment IDs / risk scores / fingerprints / metadata behind the row-click detail view. [designmd-stripe] [saasframe-stripe]
- Stripe reveals bulk-selection checkboxes and contextual row actions (retry, refund) on hover only; the resting feed carries no persistent action columns. [eleken-stripe]
- Stripe money formatting: always full decimals in list view (`$49.00`, `$1,234.56`), locale-aware symbol placement, tabular numbers, right-aligned amount column, no cents for zero-decimal currencies (JPY/KRW), and a secondary original-currency line for foreign settlements. [designmd-stripe]
- Stripe does not offer saved filters/views in the standard payments list (Stripe Sigma's saved SQL queries are a separate analytics product) — a genuine gap in its filter UX. [stripe-search-api] [stripe-dash-search]
- Raycast v2 (and developers.raycast.com) uses Inter via a WebKit WebView (TypeScript + React); Raycast v1 was native Swift/AppKit using SF Pro. [raycast-deep-dive]

## SOURCES

**raycast-fallback**
URL: https://manual.raycast.com/v1/fallback-commands
Accessed: 2026-06-23
Quote: "when your search term doesn't have any matching result, you see a list of pre-defined commands."

**raycast-aliases**
URL: https://manual.raycast.com/v1/command-aliases-and-hotkeys
Accessed: 2026-06-23

**raycast-list-api**
URL: https://developers.raycast.com/api-reference/user-interface/list
Accessed: 2026-06-23

**raycast-detail-api**
URL: https://developers.raycast.com/api-reference/user-interface/detail
Accessed: 2026-06-23
Quote: "When isShowingDetail is true, do not also show accessories on List.Item."

**raycast-colors**
URL: https://developers.raycast.com/api-reference/user-interface/colors
Accessed: 2026-06-23

**raycast-best-practices**
URL: https://developers.raycast.com/information/best-practices
Accessed: 2026-06-23
Quote: "Build a habit of using ⌘K to search for an action. See and learn the keyboard shortcut to control Raycast even faster."

**raycast-fresh-look**
URL: https://www.raycast.com/blog/a-fresh-look-and-feel
Accessed: 2026-06-23
Quote: "making it quicker to scan for what you need to find"

**raycast-deep-dive**
URL: https://www.raycast.com/blog/a-technical-deep-dive-into-the-new-raycast
Accessed: 2026-06-23

**raycast-quicklook**
URL: https://www.raycast.com/changelog/windows/0-50
Accessed: 2026-06-23

**stripe-dash-search**
URL: https://docs.stripe.com/dashboard/search
Accessed: 2026-06-23

**stripe-filter-controls**
URL: https://docs.stripe.com/stripe-apps/patterns/filter-controls
Accessed: 2026-06-23
Quote: "Render each state separately — wrapping an active chip in a Link causes onClose and the Link's press event to be sent simultaneously, which clears the filter and reopens the menu."

**stripe-chip**
URL: https://docs.stripe.com/stripe-apps/components/chip
Accessed: 2026-06-23

**stripe-dash-basics**
URL: https://docs.stripe.com/dashboard/basics
Accessed: 2026-06-23

**stripe-connect-filters**
URL: https://docs.stripe.com/connect/dashboard/filters
Accessed: 2026-06-23

**stripe-search-api**
URL: https://docs.stripe.com/search
Accessed: 2026-06-23

**stripe-may-2024**
URL: https://support.stripe.com/questions/dashboard-update-may-2024
Accessed: 2026-06-23

**designmd-stripe**
URL: https://designmd.cc/benchmarks/stripe
Accessed: 2026-06-23
Quote: "Stripe token audit (May 2026, live CSS extraction)."

**designmd-stripe-breakdown**
URL: https://www.designmd.run/blog/stripe-design-system-breakdown
Accessed: 2026-06-23

**eleken-stripe**
URL: https://www.eleken.co/blog-posts/making-it-like-stripe
Accessed: 2026-06-23

**eleken-filter-ux**
URL: https://www.eleken.co/blog-posts/filter-ux-and-ui-for-saas
Accessed: 2026-06-23

**saasframe-stripe**
URL: https://www.saasframe.io/examples/stripe-payments-dashboard
Accessed: 2026-06-23

**nng-progressive-disclosure**
URL: https://www.nngroup.com/articles/progressive-disclosure/
Accessed: 2026-06-23

## SYNTHESIS

Raycast and Stripe converge on the same skeleton for a searchable record feed: a lean scan-list plus a rich detail surface, with chips as a state receipt rather than a query builder. From Raycast, the highest-leverage ideas are (1) frequency × recency local ranking as the first ranking signal you ship — "things I ran recently" surfaces the right item without any ML; (2) zero-results as a routing opportunity, not a dead end — a ranked list of context-sensitive escapes ("search all time", "relax filters", "search the web") that each accept the typed string; (3) shortcut teaching in-flow via an action panel; and (4) a persistent master-detail split that keeps the list minimal (icon + title + date + status) and pushes full fields into a side pane that tracks keyboard navigation.

From Stripe, the load-bearing decisions are amount-leads column order with tabular numbers, hierarchy via color+size instead of bold weight, tinted (not solid) status pills, progressive "More filters" disclosure (4-5 inline, the rest behind a category-organized menu), the dual suggested-vs-active chip with a conditional "Clear filters", and hover-only bulk/row actions. The adversarially-confirmed gap — Stripe has no saved views on the main list — is a spot where a data explorer can exceed the benchmark. Two implementation traps are worth carrying: don't wrap an active chip in a Link (Stripe's documented double-event bug), and don't show row accessories while a detail pane is open (Raycast's information-doubling guidance). Note that Raycast/Stripe pixel metrics (row heights, exact spacing) are inferred from screenshots and not published — treat them as approximate.
