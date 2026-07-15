---
title: "Best-in-class date-range controls merge presets + absolute + relative into ONE popover with a single on-screen representation"
date: 2026-06-23
topic: data-explorer-ux
tags: [date-picker, filters, time-range, relative-dates, presets, accessibility]
status: draft
sources: [datadog-time-frames, grafana-time-range, grafana-semi-relative, linear-filters, linear-api-filtering, stripe-date-range, github-date-qualifiers, primer-datepicker, primer-datepicker-journey, airtable-conditions, notion-filters, uxpatterns-date-range]
---

<!-- Extracted from a pdpp Explore date-controls doc; pdpp code line refs and wiring recs discarded. -->

## CLAIMS

- Datadog exposes presets and absolute dates in ONE time selector ("a list of common time frames and a calendar picker"), and encodes `from_ts`/`to_ts` plus `live=true` in the URL where `live` records whether the range is relative (sliding) vs frozen. [datadog-time-frames]
- Datadog documents a three-way window taxonomy: sliding (both ends move with time, e.g. `5h`), growing (fixed start, end tracks now), and fixed (both ends frozen); relative syntax is `N{unit}` for sliding and `… to now` for growing. [datadog-time-frames]
- Grafana's time-range popover has two regions — an Absolute range (From/To fields + calendar) and a Relative quick-list — and the From/To fields accept either an exact timestamp or a relative expression (`now-24h`); `/unit` suffixes (`now/d`, `now/w`, `now-1M/M`) snap to calendar boundaries. [grafana-time-range]
- Grafana's "semi-relative" range = an absolute start with a `now` end (a growing window), explicitly distinguished from a fully-relative window; the trigger button is the single representation and reveals exact timestamps + their source on hover. [grafana-semi-relative]
- Linear treats date as a filter category; the filter chip is both the single representation and the editor (click the operator/value segment to change it), and relative windows are first-class in the API as ISO-8601 durations against now (`completedAt: { gt: "-P2W" }`). [linear-api-filtering]
- Stripe's dashboard date control serves preset OR custom from one dropdown (choosing "Custom" opens the calendar in the same surface) and keeps a separate dropdown for the comparison period; it documents boundary semantics (a `Jan 13 – Jan 14` range filters `Jan 13 00:00:00 → Jan 14 23:59:59`). [stripe-date-range]
- GitHub search date qualifiers use `created:>2020-01-01`, `created:>=…`, `created:<…`, and range `created:2020-01-01..2020-12-31` (ISO-8601 dates), so one text qualifier = one honest statement of the window. [github-date-qualifiers]
- GitHub Primer's date-picker case study documents that an early version auto-filled and submitted a preset but "you wouldn't see which range you had actually chosen"; the fix was a hybrid input (calendar/date fields + preset list in one popover, with the chosen preset reflected into the date fields as the single source of truth) plus an Apply/Cancel action bar because auto-submit-on-end-date caused errors. [primer-datepicker-journey]
- Notion offers a native relative filter (date property → `is within` → `the past week`/`the past month`) alongside absolute operators; Airtable's `is within` is rolling ("past year = past 365 days, not the previous calendar year") and a calendar month requires two bounded conditions, so rolling-vs-calendar must be stated in copy. [notion-filters]
- A dual-calendar panel is standard on desktop (≥~861px) collapsing to single on mobile; range-selection progress should be announced via `aria-live` and the completed range summarized as one string. [uxpatterns-date-range]

## SOURCES

**datadog-time-frames**
URL: https://docs.datadoghq.com/dashboards/guide/custom_time_frames/
Accessed: 2026-06-23

**grafana-time-range**
URL: https://grafana.com/docs/grafana/latest/visualizations/dashboards/use-dashboards/
Accessed: 2026-06-23

**grafana-semi-relative**
URL: https://grafana.com/blog/2022/02/03/pro-tip-how-to-use-semi-relative-time-ranges-in-grafana/
Accessed: 2026-06-23

**linear-filters**
URL: https://linear.app/docs/filters
Accessed: 2026-06-23

**linear-api-filtering**
URL: https://linear.app/developers/filtering
Accessed: 2026-06-23
Quote: "completedAt: { gt: \"-P2W\" } (closed in the last 2 weeks)"

**stripe-date-range**
URL: https://support.stripe.com/questions/customizing-the-date-range-for-dashboard-home-charts
Accessed: 2026-06-23

**github-date-qualifiers**
URL: https://docs.github.com/en/search-github/searching-on-github/searching-issues-and-pull-requests
Accessed: 2026-06-23

**primer-datepicker**
URL: https://primer.style/product/components/date-time-picker/
Accessed: 2026-06-23

**primer-datepicker-journey**
URL: https://medium.com/primer-design/the-journey-of-a-date-picker-90621a04381f
Accessed: 2026-06-23
Quote: "we didn't show the selected date range. So if you picked 'Last 7 days,' it would auto-fill the dates, but you wouldn't see which range you had actually chosen."

**airtable-conditions**
URL: https://support.airtable.com/docs/filtering-records-using-conditions
Accessed: 2026-06-23

**notion-filters**
URL: https://www.notion.so/help/views-filters-and-sorts
Accessed: 2026-06-23

**uxpatterns-date-range**
URL: https://uxpatterns.dev/patterns/forms/date-range
Accessed: 2026-06-23

## SYNTHESIS

Every SLVP-tier product converges on the same shape: ONE control that is both the active-state display and the editor; presets, absolute calendar, and relative text all live inside that one control's popover and resolve into the same displayed state. Nobody renders a lit-up preset button AND a duplicate "Since X" pill — that double-representation is the anti-pattern (the same state shown two ways). The resolved window is always visible and unambiguous: the label names not just the dates but the kind of window (sliding/growing/fixed, per Datadog; inclusive end-of-day, per Stripe). Relative human phrasing ("last 7 days") is the default vocabulary; absolute is the precise fallback. Presets can apply instantly, but a hand-picked custom `[start, end]` deserves an explicit Apply step (Primer's documented mistake was auto-submitting). Keep unrelated concerns (comparison period) out of the primary range control.
