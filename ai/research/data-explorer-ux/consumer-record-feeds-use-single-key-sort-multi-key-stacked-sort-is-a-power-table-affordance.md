---
title: "Consumer record feeds use a single-key, direction-baked sort with a canonical default; stacked multi-key sort is a power-table (saved-view) affordance only"
date: 2026-06-23
topic: data-explorer-ux
tags: [sorting, feed-ux, github, linear, airtable, notion, blanks-first]
status: draft
sources: [github-sort, linear-display-options, linear-board-ordering, airtable-sort, notion-views-api, stripe-dashboard, nng-filters-facets]
---

<!-- Extracted from a pdpp rich-sort doc; pdpp server/code refs discarded, patterns kept. -->

## CLAIMS

- GitHub's issue/PR list has ONE Sort dropdown above the list with single-key, direction-baked options (Newest/Oldest created, Most/Least commented, Newest/Oldest updated, Most-reacted), a canonical default (Newest), and no stacked sort or drag-to-reorder; sort is separate from filter (same set, different order). [github-sort]
- Linear orders issues within groupings by a single property (Status/Manual/Priority/Last created/Last updated/Due date/Link count) with a reverse toggle (not a stack of keys); the board-ordering menu is a single radio list; grouping is an orthogonal axis. [linear-display-options]
- Airtable's grid view exposes multi-level stacked sort ("Add another sort", drag handles to reorder keys, X to remove), with per-field direction labels semantic to the type (text A→Z, date earliest→latest); the API takes `sort[0][field]/direction`, `sort[1]…`. [airtable-sort]
- Airtable's named honesty gotcha: "in almost all cases, sorting in ascending order will place blank values first," so a field-sort over sparse data floats no-value records to a surprising position. [airtable-sort]
- Notion database views carry a `sorts` array of `{property, direction}` rules applied in order — stacked multi-key — but it is a property of a named, persisted view, and every sort key is a declared database property. [notion-views-api]
- Stripe keeps consumer dashboard lists filter-first with column/recency sort, pushing true multi-key/arbitrary-field sorting to a separate analytical surface (Sigma/SQL), not the consumer list UI. [stripe-dashboard]
- Sort and filter are distinct operations; sort reorders the SAME set and must never add/drop records (conflating them is a usability + honesty break). [nng-filters-facets]

## SOURCES

**github-sort**
URL: https://docs.github.com/en/issues/tracking-your-work-with-issues/filtering-and-searching-issues-and-pull-requests
Accessed: 2026-06-23
Quote: "To clear your sort selection, click Sort → Newest."

**linear-display-options**
URL: https://linear.app/docs/display-options
Accessed: 2026-06-23

**linear-board-ordering**
URL: https://linear.app/changelog/2022-08-18-board-ordering
Accessed: 2026-06-23

**airtable-sort**
URL: https://support.airtable.com/docs/sorting-records-in-airtable-views
Accessed: 2026-06-23
Quote: "sorting in ascending order will place blank values first"

**notion-views-api**
URL: https://developers.notion.com/guides/data-apis/working-with-views
Accessed: 2026-06-23

**stripe-dashboard**
URL: https://docs.stripe.com/dashboard/basics
Accessed: 2026-06-23

**nng-filters-facets**
URL: https://www.nngroup.com/articles/filters-vs-facets/
Accessed: 2026-06-23

## SYNTHESIS

The prior art decides single-key vs stacked, and it splits cleanly by surface: a consumer record FEED uses a single labeled, direction-baked sort with a canonical default (GitHub, Linear, Stripe consumer lists); stacked multi-key sort is a power-TABLE affordance reserved for grid/database surfaces where every column is a declared, typed, fully-covered field and the user is a builder operating a saved view (Airtable grid, Notion saved-view `sorts[]`). Named anti-patterns to avoid: the asc-blanks-first lie over sparse data; "stacked-sort theatre" (offering a multi-key stack the backend can't honor); name-guessed field sort (offering "sort by amount" because a field is named `amount` rather than being server-declared sortable — the cardinal sin); sort that changes membership (must reorder the same set); and ordering an unordered set (a relevance-ranked bounded sample cannot honestly claim "newest first").
