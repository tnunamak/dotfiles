---
title: "Heterogeneous record feeds use one row template with only the leading glyph varying, two-tier text color, trailing relative time, and an 'Upcoming' section placed at the top in full accent color (not dimmed)"
date: 2026-06-23
topic: data-explorer-ux
tags: [timeline, feed, heterogeneous-rows, design-tokens, geist, primer, day-grouping, upcoming-section]
status: draft
sources: [geist-designmd, geist-typography, geist-colors, geist-spacing, vercel-activity-log, vercel-deployments-redesign, vercel-nav-redesign, vercel-managing-deployments, designmd-vercel, primer-primitives, primer-typography, primer-color, primer-primitives-color, primer-action-list, primer-action-list-product, primer-timeline-item, primer-relative-time, primer-label, primer-react-timeline, github-notifications-docs, github-feed-chronological, gfg-primer-timeline, datadog-explorer, datadog-visualize, datadog-attributes, grafana-logs-integration, grafana-logs-viz, copilot-dashboard, copilot-transactions, copilot-recurrings, monarch-recurring, monarch-bill-blog, monarch-bill-sync, ynab-scheduled, transaction-history-ux, eleken-calendar-ui, eleken-fintech-guide]
source_session: 54d88b26-a0b7-4d76-aa78-d07fc197cad8
---

## CLAIMS

- Vercel, GitHub, Datadog, and Grafana all unify the feed row structure and vary only the leading glyph — primary text, secondary text, and trailing-time positions stay fixed while the leading icon/badge and text content change per record kind; this is the single most-repeated decision across the sources. [vercel-activity-log] [github-notifications-docs] [datadog-explorer] [grafana-logs-integration]
- What leads each row differs by product: GitHub notifications use a 16px Octicon color-coded by state (open=green, merged=purple, closed=red); GitHub's homepage feed uses an actor avatar + `[actor][verb][target]` card; GitHub PR/issue timelines use a 32px badge circle for system events and an avatar for user events; Vercel's Activity Log uses no icon (user name leads, event type is a plain string); Datadog logs use a colored status pill in a dedicated leftmost column; Grafana logs use a thin colored vertical bar on the left edge encoding log level. [github-notifications-docs] [primer-timeline-item] [vercel-activity-log] [datadog-explorer] [grafana-logs-viz]
- Metadata hierarchy is two-tier text color always: primary text in the default foreground (`--fgColor-default #1f2328` Primer / `gray-1000 #171717` Geist) and all metadata (source, context, timestamp) in a single muted token (`--fgColor-muted #59636e` Primer / `gray-900 #4d4d4d` Geist). [primer-color] [geist-colors]
- Relative time is trailing muted text with the exact time on hover; GitHub ships a `<relative-time>` web component that flips to "on Mon DD" for older dates and "on Mon DD, YYYY" past a year boundary, always with an ISO `datetime` attribute for a11y. [primer-relative-time] [vercel-activity-log]
- Datadog and Grafana start metadata subordinated (collapsed/hidden) and let the user promote a field to a visible column; the row shows timestamp + severity + one-line message, with full structured detail on expand in a side/inline panel. [datadog-visualize] [grafana-logs-viz]
- Grafana hoists "common labels" (shared by all visible rows) into a meta bar above the list so repeated metadata is not reprinted per row. [grafana-logs-viz]
- GitHub uses a condensed timeline variant (`TimelineItem--condensed`: smaller borderless badge, reduced padding) for low-signal system events (label added, assignee changed) versus a full avatar + body for high-signal user events. [primer-timeline-item] [primer-react-timeline]
- Datadog and Grafana decisively use columnar/list rows rather than cards because a log stream can be thousands of rows and cards fall apart past a few dozen; the rule is cards for low-volume narrative feeds, flat dense rows for high-volume record streams. [datadog-explorer] [grafana-logs-integration]
- Dev-tool feeds (Vercel Activity Log, GitHub homepage feed) do NOT day-group — they use continuous newest-first scroll with relative timestamps and no date headers; GitHub notifications can group by date but only as a non-default, non-sticky text-divider toggle. [vercel-activity-log] [github-feed-chronological] [github-notifications-docs]
- Finance feeds (Copilot, Monarch, YNAB, Monzo) consistently DO day-group with "Today" / "Yesterday" / "Weekday, Month Day" headers, recent first, relative labels for the two nearest days then full date. [copilot-transactions] [monarch-recurring] [ynab-scheduled]
- For upcoming/scheduled items, Copilot, Monarch, and YNAB independently converge: placement at the TOP of the feed (above past), label "Upcoming" (YNAB says "Scheduled"; "Future" is never user-facing), forward-chronological internal order (soonest first), full color with a distinct accent (usually blue) NOT dimmed, and a named section header as the separator (never an unlabeled divider alone). [copilot-dashboard] [monarch-recurring] [ynab-scheduled]
- Google Calendar dims the PAST, not the future — the inverse proof that action-oriented upcoming items get accent, read-only history gets dimming. [eleken-calendar-ui]
- Monarch Money's Recurring page (mini-calendar → "Upcoming" section forward-chronological blue accent → "Complete" past section full weight, each with a bold labeled header) is the cleanest single reference for the upcoming-section pattern. [monarch-recurring] [monarch-bill-blog]
- Consumer apps show the upcoming section expanded by default; collapse-with-count is a pragmatic engineering accommodation only when the future set is large enough to bury present-day content. [copilot-transactions] [monarch-recurring]
- Vercel Geist uses three font weights only — 400 (read/body), 500 (interact/buttons), 600 (announce/headings) — with no letter-spacing on labels/copy/buttons and aggressive heading compression (-4.32px at 72px → -0.28px at 14px). [geist-typography] [geist-designmd]
- Geist feed-relevant type tokens: `heading-16` (16/24/600, day header), `label-14` (14/20/400, row primary), `label-13` (13/16/400, dense primary), `copy-13` (13/18/400, secondary), `label-13-mono` / `label-12-mono` (monospace for IDs/hashes/timestamps). [geist-typography] [geist-designmd]
- Geist light-theme color roles: primary text `gray-1000 #171717`, secondary `gray-900 #4d4d4d`, tertiary `gray-700 #8f8f8f`, default border `gray-400 #eaeaea`, link/accent/focus `blue-700 #006bff`, success `green-700 #28a948`, warning `amber-700 #ffae00`, error `red-700 #fc0035`; focus ring `0 0 0 2px #fff, 0 0 0 4px #006bff`. [geist-colors] [geist-designmd]
- Geist spacing is a sparse 4px base scale (steps 5/7/9 intentionally absent): 4/8/12/16/24/32/40px; radii `rounded-sm` 6px, `rounded-md` 12px, `rounded-lg` 16px, `rounded-full` 9999px. [geist-spacing] [geist-designmd]
- GitHub Primer functional type tokens: `--text-title-small` (16/600, sub-section/day header), `--text-body-medium` (14/400, default UI/row primary), `--text-caption` (12/400, single-line meta); base weights light 300 / normal 400 / medium 500 / semibold 600. [primer-typography] [primer-primitives]
- Primer's text hierarchy is exactly three tiers — `--fgColor-default #1f2328`, `--fgColor-muted #59636e`, `--fgColor-disabled #818b98`; there is no `--fgColor-subtle` (subtle exists only for backgrounds); accent `--fgColor-accent #0969da`, danger `#d1242f`, success `#1a7f37`, done/merged `#8250df`. [primer-color] [primer-primitives-color]
- Primer's ActionList (LeadingVisual / Description inline|block / TrailingVisual + Group/GroupHeading/Divider) is a heterogeneous-row primitive where items with icons, avatars, or no leading visual coexist and unset slots are simply absent. [primer-action-list] [primer-action-list-product]
- Primer's Timeline `.TimelineBadge` is a 32×32 circle with a thick `--bgColor-default` border overlapping a 2px `--borderColor-muted` connector rail; the condensed variant shrinks the badge to 16px and drops the border; badge `data-variant` (accent/success/attention/severe/danger/done/open/closed) sets emphasis bg + white text. [primer-react-timeline] [primer-timeline-item]
- Both Geist and Primer reserve monospace for machine-format fixed-width values only — timestamps, IDs/hashes/SHAs, amounts (tabular figures for column alignment), and log/code/JSON bodies — never for row titles, descriptions, or human labels. [geist-typography] [grafana-logs-viz]
- On mobile, the columnar desktop view collapses to a stacked single-column three-slot row (leading glyph + primary text + trailing relative time), dropping non-essential columns and pushing detail into a full-screen drawer on tap; finance apps are mobile-first with the day-grouped list + top Upcoming section as the native pattern. [vercel-deployments-redesign] [datadog-visualize] [eleken-fintech-guide]

## SOURCES

**geist-designmd**
URL: https://vercel.com/design.md
Accessed: 2026-06-23
Quote: "machine-readable Geist token spec — primary source for type/color/space"

**geist-typography**
URL: https://vercel.com/geist/typography
Accessed: 2026-06-23

**geist-colors**
URL: https://vercel.com/geist/colors
Accessed: 2026-06-23

**geist-spacing**
URL: https://vercel.com/geist/spacing
Accessed: 2026-06-23

**vercel-activity-log**
URL: https://vercel.com/docs/activity-log
Accessed: 2026-06-23

**vercel-deployments-redesign**
URL: https://vercel.com/changelog/redesigned-deployments-list
Accessed: 2026-06-23
Quote: "May 27, 2026 redesigned deployments list."

**vercel-nav-redesign**
URL: https://vercel.com/changelog/dashboard-navigation-redesign-rollout
Accessed: 2026-06-23

**vercel-managing-deployments**
URL: https://vercel.com/docs/deployments/managing-deployments
Accessed: 2026-06-23

**designmd-vercel**
URL: https://designmd.cc/benchmarks/vercel
Accessed: 2026-06-23

**primer-primitives**
URL: (npm) @primer/primitives@11.9.0 dist CSS
Accessed: 2026-06-23
Quote: "base typography, base size, functional typography, light-theme color"

**primer-typography**
URL: https://primer.style/foundations/typography
Accessed: 2026-06-23

**primer-color**
URL: https://primer.style/foundations/color
Accessed: 2026-06-23

**primer-primitives-color**
URL: https://primer.style/foundations/primitives/color
Accessed: 2026-06-23

**primer-action-list**
URL: https://primer.style/components/action-list
Accessed: 2026-06-23

**primer-action-list-product**
URL: https://primer.style/product/components/action-list/
Accessed: 2026-06-23

**primer-timeline-item**
URL: https://primer.style/components/timeline-item
Accessed: 2026-06-23

**primer-relative-time**
URL: https://primer.style/product/components/relative-time/
Accessed: 2026-06-23

**primer-label**
URL: https://primer.style/product/components/label/
Accessed: 2026-06-23

**primer-react-timeline**
URL: (source) primer/react Timeline.tsx + Timeline.module.css
Accessed: 2026-06-23

**github-notifications-docs**
URL: https://docs.github.com/en/account-and-profile/managing-subscriptions-and-notifications-on-github/viewing-and-triaging-notifications/managing-notifications-from-your-inbox
Accessed: 2026-06-23

**github-feed-chronological**
URL: https://github.blog/changelog/2025-02-14-reverting-feed-activity-sorting-back-to-chronological-ordering/
Accessed: 2026-06-23

**gfg-primer-timeline**
URL: https://geeksforgeeks.org/primer-css-timeline
Accessed: 2026-06-23

**datadog-explorer**
URL: https://docs.datadoghq.com/logs/explorer/
Accessed: 2026-06-23

**datadog-visualize**
URL: https://docs.datadoghq.com/logs/explorer/visualize/
Accessed: 2026-06-23

**datadog-attributes**
URL: https://docs.datadoghq.com/logs/log_configuration/attributes_naming_convention/
Accessed: 2026-06-23

**grafana-logs-integration**
URL: https://grafana.com/docs/grafana/latest/explore/logs-integration/
Accessed: 2026-06-23

**grafana-logs-viz**
URL: https://grafana.com/docs/grafana/latest/panels-visualizations/visualizations/logs/
Accessed: 2026-06-23

**copilot-dashboard**
URL: https://help.copilot.money/en/articles/6045480-dashboard-tab-overview
Accessed: 2026-06-23

**copilot-transactions**
URL: https://help.copilot.money/en/articles/9554412-transactions-tab-overview
Accessed: 2026-06-23

**copilot-recurrings**
URL: https://help.copilot.money/en/articles/9778259-recurrings-tab-overview
Accessed: 2026-06-23

**monarch-recurring**
URL: https://help.monarch.com/hc/en-us/articles/4890751141908-Tracking-Recurring-Expenses-and-Bills
Accessed: 2026-06-23

**monarch-bill-blog**
URL: https://www.monarch.com/blog/track-recurring-bills-and-subscriptions
Accessed: 2026-06-23

**monarch-bill-sync**
URL: https://help.monarch.com/hc/en-us/articles/29446697869076-Getting-Started-with-Bill-Sync
Accessed: 2026-06-23

**ynab-scheduled**
URL: https://support.ynab.com/en_us/scheduled-transactions-a-guide-BygrAIFA9
Accessed: 2026-06-23

**transaction-history-ux**
URL: https://medium.com/design-bootcamp/from-confusion-to-clarity-improving-transaction-history-ux-2e43f2838954
Accessed: 2026-06-23

**eleken-calendar-ui**
URL: https://www.eleken.co/blog-posts/calendar-ui
Accessed: 2026-06-23

**eleken-fintech-guide**
URL: https://www.eleken.co/blog-posts/modern-fintech-design-guide
Accessed: 2026-06-23

## SYNTHESIS

For a reverse-chronological feed mixing many record kinds from many sources, the strongest and most-repeated finding is: unify the row structure, vary only the leading glyph. Lock the primary-text / secondary-text / trailing-time slots and let only the leading icon (and text content) change per kind — this is what keeps a heterogeneous list scannable. Lead with a type+state glyph rather than a colored pill (a 16px octicon carries type and status pre-attentively), reserve colored badges for a small fixed enum like severity, and keep two-tier text color as the whole hierarchy (default + one muted token; do not invent a third row text color).

The honest tension is day-grouping: dev-tool feeds deliberately do *not* day-group (continuous relative-time scroll), while finance feeds consistently do. For a multi-year, mixed-source personal corpus the finance camp is right (day headers are load-bearing wayfinding across years — include the year), but this is a deliberate departure from the dev-tool pattern, not a copy of it. The highest-confidence sub-finding is the Upcoming section: Copilot, Monarch, and YNAB independently converge on top-of-feed, labeled "Upcoming", forward-chronological, full accent color (not dimmed — dimming is for the past, per Google Calendar), with a mandatory labeled section header; collapse-with-count is a defensible deviation only when the future set is large. Anchor concrete values on the published Geist and Primer tokens (three weights max, sparse 4px spacing, monospace only for machine values, single accent used sparingly). Both design systems' relative-time-with-ISO-datetime, condensed-variant-for-low-signal, and promote-to-column/detail-panel progressive disclosure are directly reusable primitives.
