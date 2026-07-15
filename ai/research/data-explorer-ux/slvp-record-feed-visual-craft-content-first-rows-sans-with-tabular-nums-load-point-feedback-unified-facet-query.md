---
title: "SLVP record-feed visual craft converges: content-first two-line rows on a tight grid, one proportional sans with tabular-nums (never mono for body), load feedback at the load point (not viewport top), and one facet-is-query-builder model"
date: 2026-06-22
topic: data-explorer-ux
tags: [visual-design, row-anatomy, typography, tabular-nums, loading-states, faceted-search, design-systems]
status: draft
sources: [linear-925, linear-perf, primer-actionlist, sentry-issues, stripe-payment-details, stripe-dashboard, airtable-grid, airtable-detail, notion-lists, notion-dbviews, teams-activity-feed, aubergine-feeds, geist-typography, primer-typography, stripe-design, tnum-vs-mono, raycast-design, madegood-mono, pencilandpaper-tables, geist-spinner, geist-skeleton, bbc-gel-loadmore, github-loadmore, slack-lazy, nng-infinite-scroll, nng-skeleton, nprogress, uxpatterns-infinite, addyosmani-cls, linear-filters, datadog-facets, datadog-syntax, github-filtering, sentry-facet-map, google-faceted-nav, patternfly-filters, material-chips, airtable-grouping, notion-advanced-filters]
---

## CLAIMS

### Feed row anatomy

- Linear packs an issue row (title, status, priority, assignee, labels, project, cycle) into one ~32px line: every element aligns to a 4px grid and the palette is grey-heavy — most text/icons at 40-60% opacity, full saturation reserved for status/priority/interactive elements — so density works *because* the grid is tight. [linear-925, linear-perf]
- GitHub Primer ActionList specifies leading visuals at fixed sizes (octicons 16px, avatars 20px; place a 16px octicon inside the 20px area to center-align mixed lists) and two description variants: `inline` (secondary text beside the label, can `truncate`) and `block` (secondary text on a second line — the canonical two-line row). Trailing visual/text is right-aligned for status/counters. Dividers (`showDividers`) are off by default and inset to align with content. [primer-actionlist]
- Sentry's issue-stream row carries content on its primary lines — the error message (title) and the culprit (where it happened, e.g. `raven.scripts.runner in main`) — plus an inline 24h sparkline, event count, and last-seen relative time; the two primary text lines are content, not "type · service · time." [sentry-issues]
- Stripe's transactions list shows one payment-intent per row with amount, status, description/merchant, and timestamp (real content, never bare type metadata); clicking any row opens a payment-detail overlay (the same component shipped as an embeddable "payment-details" element), not an inline expand. [stripe-payment-details, stripe-dashboard]
- Airtable makes row height the density dial: "Short" default = one line + small thumbnails for maximum record density; taller options progressively reveal more text/linked-records/images (shorter = more records, taller = more content per record). Every row is anchored by the authored primary field; Space expands a row to a full detail panel. [airtable-grid, airtable-detail]
- Notion's list view drops the grid to just a clickable item title with selected properties pushed to the far right (drag-reorderable, visibility-toggleable); opening a row uses Side peek / Center peek / Full page progressive disclosure. Recommended when "you don't need a ton of properties." [notion-lists, notion-dbviews]
- Activity-feed design canon (Microsoft Teams, Aubergine) states a row must tell a self-contained story: avatar (actor) + activity-type icon + title (actor + reason) + truncated text preview + timestamp + location; avatars alone are insufficient and a text preview saves the user from clicking into each item. [teams-activity-feed, aubergine-feeds]
- The named anti-pattern: no SLVP-grade product sets a record row's primary line to `<type> · <source> · <time>`; each surfaces real content (merchant+amount, error+culprit, subject/snippet) on line 1 and relegates source/type/time to a muted secondary line — the "self-contained story" requirement. A metadata-only row is the canonical debug-log look that forces a click to learn what each row is. [teams-activity-feed, sentry-issues, stripe-dashboard]

### Typography in dense feeds

- Vercel Geist's spec reserves monospace for code/data/tabular figures only: "Geist Sans sets UI and prose; Geist Mono sets code, data, and tabular figures"; paired tokens (`label-14` sans vs `label-14-mono`) swap only the family, so mono is a per-field override on otherwise-sans rows, and body paragraphs are never set in mono. [geist-typography]
- GitHub Primer builds hierarchy with font weight and size, not color: "Adjust font weight to add emphasis… Refrain from utilizing color as a primary method of emphasis." Weight tokens are 400/500/600; on `bgColor-muted` backgrounds use `fgColor-default` and never `fgColor-muted` (fails 4.5:1 WCAG AA). [primer-typography]
- Stripe renders money/numerics in the same Söhne sans with `font-feature-settings: "tnum"` (tabular figures) plus tightened tracking — NOT a monospace font. The broadly-cited engineering rule: to stop digits jittering, use `font-variant-numeric: tabular-nums` rather than a full monospace swap, which otherwise makes a dashboard "look like a terminal." [stripe-design, tnum-vs-mono]
- Raycast — a text-driven command-palette product — uses zero monospace outside inline `<code>` chips in docs; its entire UI is Inter, proving "looks like a dev tool" does not require mono. Hierarchy is a tight weight/size/opacity ladder on one sans (primary 14px/500, secondary 14px/400, metadata 13px/400; opacity-based color tiers). [raycast-design]
- The "mono everywhere" anti-pattern is documented: monospace as a decorative "tech" signal reads slower than proportional fonts at 14-16px body sizes and produces "costume-y" designs; the clean pattern pairs a sans for UI/body with its matching mono for code only (Geist Sans+Mono, IBM Plex Sans+Mono). [madegood-mono]
- Field consensus for a two-tier row (from shadcn/Tailwind design-token systems Linear's aesthetic shares): primary 14px/medium near-black, secondary 13px/regular muted; row heights condensed 40px / regular 48px / relaxed 56px (a two-line cell needs ≥48px); exactly two weights (400 + 500) and a 2-3 step foreground→muted color ladder. [pencilandpaper-tables]

### Loading/pending placement in a scrollable list

- Vercel Geist mounts the Spinner at the trigger for pagination/button-fetches ("used… for buttons, pagination, etc." and "row-level retries"; "Mount the Spinner only after the action starts"), and splits by case: Skeleton when async data fills a known layout, LoadingDots for inline copy, Progress when total work is known. [geist-spinner, geist-skeleton]
- BBC GEL's "Load more" places the spinner directly ABOVE the button (at the load point), announces "loading, please wait" via an ARIA live region, and on arrival focuses a separator confirming how many items loaded ("items 12 to 18:"). [bbc-gel-loadmore]
- GitHub's collapsed "Load more" is a documented failure of misplaced feedback: users report the affordance forces a scroll to the bottom which then "scrolls you back to the top," a round-trip. [github-loadmore]
- Slack fetches older messages on scroll in modest batches ("the ever-magical 42 for a page of history"), with feedback at the scroll edge, not a global top bar. [slack-lazy]
- NN/G names the "illusion of completeness" failure: without an in-context loading indicator (or a Load More button) at the scroll edge where content appends, a bottom whitespace gap reads as "no more content." Skeletons should preview a known layout and must reserve space to minimize CLS; animate skeletons via `transform` (not `background-position`) to hold 60fps. [nng-infinite-scroll, nng-skeleton, addyosmani-cls]
- A fixed `top:0` progress bar (NProgress-style) is an acknowledged anti-pattern for appended content: it is above the fold and invisible once scrolled, especially on mobile; documented mitigation is to pair it with localized in-context loading states for the updated component. It is appropriate only for full-route transitions. [nprogress]
- Mobile pattern: pending feedback lives in the list footer at the bottom edge (thumb-reachable), pre-fetched before the true end via an `onEndReached`-style threshold; the top is reserved for pull-to-refresh. [uxpatterns-infinite]

### Facet rail vs operator language

- Linear treats facet click and typed query as ONE model: the filter menu is searchable and shows the number of matching issues next to each option; every selection becomes an editable formula pill where clicking `is` toggles to `is not` and adding a second value shifts to `is either of`; negation reuses the operator ("does not include"), no separate negative UI. [linear-filters]
- Datadog keeps the facet panel and query bar as two bidirectionally-synced views of one query ("the search bar and URL automatically reflect your selections from the facet panel"): a facet click writes `key:value` verbatim, a second same-facet value writes `type:("api" OR "api-ssl")`, cross-facet selections join by space (AND); qualitative facets show per-value counts. [datadog-facets, datadog-syntax]
- GitHub's issue sidebar IS a query-builder: a label selection writes `label:"in progress"`, type writes `type:"Bug"`, state writes `is:open`; multiple selections AND implicitly; `-` negates any filter, and `has:`/`no:` test presence and are negatable. [github-filtering]
- Sentry's facet-map rail clicks edit the same token query, and its counts are result-scoped: "the event and user counts represent the counts given the search, environments, or time period selected… different from the counts in the header which are the total counts across the lifetime of the issue." Negation is the `!` operator. [sentry-facet-map]
- Facet-count consensus: counts should be dynamic and result-scoped, recomputed as filters change; never leave a 0-count option as a live clickable dead-end — Google's guidance is to grey-out/disable zero-count options; empty-result moments are the most damaging in search (Baymard ~69% abandon). [google-faceted-nav, sentry-facet-map]
- Many values without a wall: parent→child scoping (Linear "filter by project first"), collapsible grouped sections with "collapse all" (Airtable), nested AND/OR filter groups (Notion), and search-within-the-menu. [airtable-grouping, notion-advanced-filters, linear-filters]
- Chips are the single unified state surface with one "Clear filters" regardless of source facet: PatternFly renders every selection as a chip with "Clear filters" after the last; Material 3 says "do not display a single chip by itself — chips should appear in a set" and the `×` dismisses one filter. [patternfly-filters, material-chips]

## SOURCES

**linear-925**
URL: https://www.925studios.co/blog/linear-design-breakdown-saas-ui-2026
Accessed: 2026-06-22

**linear-perf**
URL: https://performance.dev/how-is-linear-so-fast-a-technical-breakdown
Accessed: 2026-06-22

**primer-actionlist**
URL: https://primer.style/components/action-list/ ; https://primer.style/product/components/action-list/
Accessed: 2026-06-22

**sentry-issues**
URL: https://docs.sentry.io/product/issues/ ; https://docs.sentry.io/product/issues/issue-details/
Accessed: 2026-06-22

**stripe-payment-details**
URL: https://docs.stripe.com/connect/supported-embedded-components/payment-details
Accessed: 2026-06-22

**stripe-dashboard**
URL: https://docs.stripe.com/dashboard/basics
Accessed: 2026-06-22

**airtable-grid**
URL: https://support.airtable.com/docs/airtable-grid-view
Accessed: 2026-06-22

**airtable-detail**
URL: https://support.airtable.com/docs/airtable-interface-layout-record-detail
Accessed: 2026-06-22

**notion-lists**
URL: https://www.notion.com/help/lists
Accessed: 2026-06-22

**notion-dbviews**
URL: https://www.notion.com/help/guides/using-database-views
Accessed: 2026-06-22

**teams-activity-feed**
URL: https://learn.microsoft.com/en-us/microsoftteams/platform/concepts/design/activity-feed-notifications
Accessed: 2026-06-22

**aubergine-feeds**
URL: https://www.aubergine.co/insights/a-guide-to-designing-chronological-activity-feeds
Accessed: 2026-06-22

**geist-typography**
URL: https://vercel.com/geist/typography ; https://vercel.com/design.md
Accessed: 2026-06-22

**primer-typography**
URL: https://primer.style/foundations/typography/ ; https://github.com/primer/primitives/blob/main/DESIGN_TOKENS_GUIDE.md
Accessed: 2026-06-22

**stripe-design**
URL: https://raw.githubusercontent.com/VoltAgent/awesome-design-md/main/design-md/stripe/DESIGN.md
Accessed: 2026-06-22

**tnum-vs-mono**
URL: https://dev.to/alanwest/tabular-numbers-in-css-font-variant-numeric-vs-monospace-hacks-25cn
Accessed: 2026-06-22

**raycast-design**
URL: https://raw.githubusercontent.com/VoltAgent/awesome-design-md/main/design-md/raycast/DESIGN.md ; https://getdesign.md/raycast/design-md
Accessed: 2026-06-22

**madegood-mono**
URL: https://madegooddesigns.com/best-monospace-fonts-2026/ ; https://www.jetbrains.com/lp/mono/
Accessed: 2026-06-22

**pencilandpaper-tables**
URL: https://www.pencilandpaper.io/articles/ux-pattern-analysis-enterprise-data-tables ; https://github.com/arhamkhnz/ui-prompts/blob/main/dashboard-ui-prompt-v40.md
Accessed: 2026-06-22

**geist-spinner**
URL: https://vercel.com/geist/spinner
Accessed: 2026-06-22

**geist-skeleton**
URL: https://vercel.com/geist/skeleton
Accessed: 2026-06-22

**bbc-gel-loadmore**
URL: https://bbc.github.io/gel/components/load-more/
Accessed: 2026-06-22

**github-loadmore**
URL: https://github.com/orgs/community/discussions/5119 ; https://github.com/orgs/community/discussions/134214
Accessed: 2026-06-22

**slack-lazy**
URL: https://slack.engineering/making-slack-faster-by-being-lazy/
Accessed: 2026-06-22

**nng-infinite-scroll**
URL: https://www.nngroup.com/articles/infinite-scrolling-tips/
Accessed: 2026-06-22

**nng-skeleton**
URL: https://www.nngroup.com/articles/skeleton-screens/
Accessed: 2026-06-22

**nprogress**
URL: https://github.com/rstacruz/nprogress ; https://github.com/gatsbyjs/gatsby/issues/2975
Accessed: 2026-06-22

**uxpatterns-infinite**
URL: https://uxpatterns.dev/patterns/navigation/infinite-scroll ; https://addyosmani.com/blog/infinite-scroll-without-layout-shifts/
Accessed: 2026-06-22

**addyosmani-cls**
URL: https://addyosmani.com/blog/infinite-scroll-without-layout-shifts/
Accessed: 2026-06-22

**linear-filters**
URL: https://linear.app/docs/filters
Accessed: 2026-06-22

**datadog-facets**
URL: https://docs.datadoghq.com/logs/explorer/facets/
Accessed: 2026-06-22

**datadog-syntax**
URL: https://docs.datadoghq.com/logs/explorer/search_syntax/
Accessed: 2026-06-22

**github-filtering**
URL: https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/filtering-and-searching-issues-and-pull-requests ; https://github.blog/changelog/2026-04-02-improved-search-for-github-issues-is-now-generally-available/
Accessed: 2026-06-22

**sentry-facet-map**
URL: https://docs.sentry.io/product/issues/issue-details/ ; https://sentry.io/changelog/improved-search-ui/
Accessed: 2026-06-22

**google-faceted-nav**
URL: https://developers.google.com/search/blog/2014/02/faceted-navigation-best-and-5-of-worst ; https://www.brokenrubik.com/blog/faceted-search-best-practices
Accessed: 2026-06-22

**patternfly-filters**
URL: https://www.patternfly.org/2022.11/guidelines/filters/
Accessed: 2026-06-22

**material-chips**
URL: https://m3.material.io/components/chips/guidelines
Accessed: 2026-06-22

**airtable-grouping**
URL: https://support.airtable.com/docs/grouping-records-in-airtable
Accessed: 2026-06-22

**notion-advanced-filters**
URL: https://www.notion.com/help/guides/using-advanced-database-filters
Accessed: 2026-06-22

## SYNTHESIS

Four independent visual-craft findings for a dense record/activity feed:

Row anatomy: the consensus polished row is content-first — a fixed-size leading type-glyph/avatar slot, a primary line that is CONTENT (merchant+amount, error+culprit, subject, snippet — something a human recognizes), a muted secondary line where source/type/time ride *alongside* content, an abbreviated right-aligned time, whole-row-as-target opening a peek/overlay (not a "View" button or inline expand), and hierarchy by muted-with-pops color on a tight grid rather than borders/zebra. Density is a dial (Linear ~32px / Airtable Short one-line; ≥48px two-line). The one hard rule: never ship a primary line of `<type> · <source> · <time>`.

Typography: one proportional sans is the row default; monospace is a per-field override reserved for protocol strings (IDs, hashes, trace IDs, raw JSON, code). Hierarchy is carried by weight → size → color/opacity in that order (weight first, color last; Primer forbids color as primary emphasis). Numbers use `font-variant-numeric: tabular-nums`, not a mono font, to align without the terminal look. The "pale all-mono, uniform-weight, hairline-divided" list is the recognized "raw dev tool" anti-pattern; the minimal fix is three edits — swap body to sans (mono only on ID/code fields), raise the primary line to weight 500-600, add a foreground→muted color ladder + tabular-nums.

Loading placement: put pending feedback at the load point (inside/above the Load-more control + reserved-height skeleton rows at the insertion point + an `aria-live` announcement), never solely at a fixed viewport-top bar (the NProgress anti-pattern, invisible once scrolled). Reserve any top progress bar for full-route transitions. On mobile, footer loader at the bottom edge, pre-fetched before the true end; top reserved for pull-to-refresh.

Facet vs operators: leading products ship ONE model, two surfaces — the clickable rail is a query-builder that writes the equivalent operator/chip into one shared URL-encoded query, and editing the query reselects the rail; the chip row is the canonical state. Counts are result-scoped and dynamic, visibly distinguished from lifetime totals (Sentry states this outright), and zero-count options are disabled/hidden, never live dead-ends. Many values are tamed by search-within-menu, parent→child scoping, and collapsible groups. Inversion is the same chip with a flipped operator (`is not` / `-` / `!`), never a separate negative control.
