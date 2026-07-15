---
title: "Activity feeds sort grouped/aggregated bursts by their newest member, newest-first; ordering by arrival or oldest member is the documented anti-pattern"
date: 2026-06-22
topic: data-explorer-ux
tags: [activity-feed, sorting, grouping, aggregation, chronological]
status: draft
sources: [getstream-aggregation, gmail-thread-sort, github-feed-revert, android-notifications, slack-grouping, datadog-log-patterns, aubergine-chrono-feeds]
---

<!-- Extracted from a pdpp burst-ordering doc; the pdpp bug site and code refs discarded. -->

## CLAIMS

- Stream (getstream.io) activity feeds sort aggregated groups by the group's `updated_at` DESC ("most recently active group first"); a new activity bumps the group's `updated_at` and bubbles it to the top. Non-time ordering requires explicit `ranking`/`score_strategy` opt-in. [getstream-aggregation]
- Gmail's regular Inbox sorts conversations by the LAST message's date (newest member); Priority Inbox historically used the FIRST message's date (oldest member) and users flagged it confusing. Within a thread messages are oldest-first, but threads rank by newest message (a deliberate split-axis). [gmail-thread-sort]
- GitHub reverted algorithmic/out-of-sequence feed ordering back to strict chronological in Feb 2025 after user backlash; bundles ("pushed N commits") sit at their event time and "the newest activity appears first." [github-feed-revert]
- Android/Material notifications default to newest-first within a group; `setSortKey()` overrides draw the "everything is jumbled up / a message drops down a few minutes later" complaint. [android-notifications]
- Slack's consecutive-message grouping never reorders the timeline; a grouped block stays anchored at its real channel-sequence position — grouping is presentation-only over a monotonic sequence. [slack-grouping]
- Datadog Log Patterns is the legitimate non-time counter-example: clusters are sorted by VOLUME desc (to find the noisiest pattern), but the non-time organizing axis is explicit and labeled. [datadog-log-patterns]
- Chronological-to-algorithmic feed switches (Strava, Instagram) drew backlash and re-added chronological ordering; the lesson is to establish a legible, stable ordering and not let grouping silently break time order. [aubergine-chrono-feeds]

## SOURCES

**getstream-aggregation**
URL: https://getstream.io/activity-feeds/docs/javascript/aggregation/
Accessed: 2026-06-22
Quote: "aggregated groups sorted by the group's updated_at DESC (most recently active group first)"

**gmail-thread-sort**
URL: https://support.google.com/mail/thread/4048418
Accessed: 2026-06-22

**github-feed-revert**
URL: https://github.blog/changelog/2025-02-14-reverting-feed-activity-sorting-back-to-chronological-ordering/
Accessed: 2026-06-22
Quote: "the out-of-sequence ordering of activity can make it difficult to be effective… now we're sorting all activity chronologically. The newest activity appears first."

**android-notifications**
URL: https://developer.android.com/develop/ui/views/notifications/group
Accessed: 2026-06-22

**slack-grouping**
URL: https://engineeringenablement.substack.com/p/slack-system-design-what-actually
Accessed: 2026-06-22

**datadog-log-patterns**
URL: https://docs.datadoghq.com/logs/explorer/analytics/patterns/
Accessed: 2026-06-22

**aubergine-chrono-feeds**
URL: https://www.aubergine.co/insights/a-guide-to-designing-chronological-activity-feeds
Accessed: 2026-06-22

## SYNTHESIS

For a reverse-chron, day-bucketed feed that groups consecutive same-source records into "bursts," the convergent rule is: give each burst `latestAt = max(member timestamp)`, sort bursts newest-first by that within the day, and keep members newest-first inside each burst. The scan-invariant is that every timestamp only goes backward top-to-bottom, across both burst headers and within-burst items. Ordering bursts by arrival/first-seen (a Map-insertion artifact) or by oldest member (the Gmail Priority-Inbox mistake) is the anti-pattern. If a feed renders all bursts then all singles, that is the same class of bug — order the day's render units (bursts + singles) together by their newest timestamp. A non-time axis (Datadog volume) is only acceptable when it is the visible, labeled organizing axis.
