---
title: "Leading products put future-dated items in a separate named 'Upcoming/Scheduled/Pending' section, never interleaved atop a newest-first feed"
date: 2026-06-21
topic: data-explorer-ux
tags: [timeline, activity-feed, reverse-chronological, future-dated, ux-pattern, accessibility]
status: draft
sources: [ynab, stripe-invoices, gmail-scheduled, things3, todoist, datadog-grafana, ms-teams-activity, fullcalendar, wcag-color, aria-feed]
---

## CLAIMS

- YNAB places not-yet-cleared / future items in a collapsible "Pending" section of the register, walled off so they don't affect balances, marked with a clock icon; editing one promotes it into the real register. [ynab]
- Stripe surfaces future-dated invoices in a dedicated "Scheduled" section/filter with a status badge; the "upcoming invoice" is a PREVIEW (id prefixed `upcoming_`), not a created object, and is EXCLUDED from the List-invoices endpoint; the horizon is bounded (~2–60 days). [stripe-invoices]
- Gmail keeps scheduled (future-send) mail in a separate "Scheduled" label, not interleaved with Sent; capped at 100 pending. [gmail-scheduled]
- Things 3 clamps "Today" to today and routes all future-dated items to a separate "Upcoming" list that is FORWARD-chronological (soonest first), day-bucketed, and auto-promoted into Today when the date arrives; later-today items are demoted to a de-emphasized "This Evening" at the bottom of Today. [things3]
- Todoist isolates future-dated tasks in an "Upcoming" view (separate from Today), forward-chronological and day-grouped; overdue is its own category. [todoist]
- Datadog and Grafana terminate the default time window at "now"; viewing the future is opt-in syntax (`now+`), and some surfaces (Datadog frames, Grafana Alerting) disallow future ranges entirely. [datadog-grafana]
- Activity-feed design canon (Microsoft Teams guidance) treats a chronological activity feed as strictly reverse-chronological of actions that already happened; there is no "future" treatment because the feed is past-and-now by definition. [ms-teams-activity]
- FullCalendar's `nowIndicator` line separates past/future on a time grid but it is a positional axis, not a newest-first feed, and is off by default. [fullcalendar]
- Label conventions split by domain: finance uses "Pending" (YNAB) or "Scheduled" (Stripe, Gmail); task/agenda uses "Upcoming" (Things, Todoist) and "Scheduled" (Google Calendar's list view is named "Schedule"). [ynab][stripe-invoices][things3][todoist]
- WCAG use-of-color guidance requires distinguishing future entries with a text label/pill, not position or color alone. [wcag-color]
- The ARIA feed pattern (`role="log"` + `aria-live="polite"` for append feeds, `aria-busy` while loading, `aria-posinset`/`aria-setsize` for item position) is silent on sort order — ordering is the application's call. [aria-feed]

## SOURCES

**ynab**
URL: https://support.ynab.com/ (YNAB support docs — register / scheduled transactions)
Accessed: 2026-06-21
Quote: "Not-yet-cleared items appear in a collapsible Pending section, marked with a clock icon; editing promotes them into the register."

**stripe-invoices**
URL: https://docs.stripe.com/api/invoices (List invoices; upcoming invoice preview)
Accessed: 2026-06-21
Quote: "The upcoming invoice is a preview, not a created object, and is excluded from the List invoices endpoint."

**gmail-scheduled**
URL: https://support.google.com/mail/answer/9214606 (Schedule emails in Gmail)
Accessed: 2026-06-21
Quote: "Scheduled mail lives under the Scheduled label; up to 100 messages can be pending."

**things3**
URL: https://culturedcode.com/things/support/ (Things 3 — Today / Upcoming)
Accessed: 2026-06-21
Quote: "Upcoming lists future-dated to-dos forward-chronologically, bucketed by day, auto-promoted into Today when the date arrives."

**todoist**
URL: https://todoist.com/help (Todoist — Upcoming view)
Accessed: 2026-06-21
Quote: "The Upcoming view shows future tasks separate from Today, forward-chronological and grouped by day."

**datadog-grafana**
URL: https://docs.datadoghq.com/dashboards/guide/ and https://grafana.com/docs/grafana/latest/dashboards/use-dashboards/ (time range controls)
Accessed: 2026-06-21
Quote: "Default time windows end at now; future ranges are opt-in and some surfaces disallow them."

**ms-teams-activity**
URL: https://learn.microsoft.com/en-us/microsoftteams/ (activity feed design guidance)
Accessed: 2026-06-21
Quote: "A chronological activity feed is reverse-chronological of actions that already happened."

**fullcalendar**
URL: https://fullcalendar.io/docs/nowIndicator
Accessed: 2026-06-21
Quote: "nowIndicator: Determines whether or not to display a marker indicating the current time. Off by default."

**wcag-color**
URL: https://www.w3.org/WAI/WCAG21/Understanding/use-of-color.html
Accessed: 2026-06-21
Quote: "Color is not used as the only visual means of conveying information."

**aria-feed**
URL: https://www.w3.org/WAI/ARIA/apg/patterns/feed/
Accessed: 2026-06-21
Quote: "The feed pattern describes append behavior, aria-busy, and posinset/setsize but does not prescribe sort order."

## SYNTHESIS

The convergent pattern across finance, task, log, and calendar products is: clamp the main
newest-first feed to "now"/today, and put future-dated items in a SEPARATE, NAMED section —
never interleaved above today's activity. Inside that section, order FORWARD-chronologically
(soonest-first) and bucket by day, and let items auto-cross the boundary by date (computed at
render from `now`) rather than by manual promotion. Collapsed-by-default with a count is
appropriate when the count drives the next action. For a mixed personal corpus (finance +
messages + calendar + tasks), "Upcoming" is the most neutral umbrella label; "Scheduled"
skews finance/email and "Pending" collides with the bank meaning of in-flight. Distinguish
the section with a text label/pill (not color/position alone) and expose it as a labeled
region for a11y.
