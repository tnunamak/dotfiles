---
title: "The filter rail and the typed query language are ONE model shown two surfaces — clicking a facet authors the operator; counts are result-scoped and 0-count options are never live dead-ends"
date: 2026-06-22
topic: data-explorer-ux
tags: [faceted-search, filters, query-builder, chips, count-badges, negation, linear, datadog, github]
status: draft
sources: [linear-filters, datadog-facets, datadog-search-syntax, github-issues-filter, github-issues-search-ga, sentry-issue-details, sentry-search, google-faceted-nav, brokenrubik-faceted, notion-advanced-filters, airtable-grouping, patternfly-filters, material-chips]
---

<!-- Extracted from a pdpp filter-rail doc; pdpp con:/stream: recommendations discarded, patterns kept. -->

## CLAIMS

- Linear's filter menu shows the number of matching issues per option and supports free-text search within the filter menu; every selection becomes an editable "formula" pill where clicking the operator flips `is`→`is not` and adding a value auto-changes `is`→`is either of`; negation reuses the same chip (select all labels, switch to "does not include"). [linear-filters]
- Datadog keeps the facet panel and the search bar as two views of one query, kept in sync bidirectionally ("the search bar and URL automatically reflect your selections from the facet panel"); clicking a facet writes `key:value`, a second value writes `type:("api" OR "api-ssl")`, different facets join with a space (AND); qualitative facets show a per-value count, and autocomplete orders values by descending log count. [datadog-facets]
- GitHub's issue sidebar is literally a query-builder: "the filters shown in the search text box are updated accordingly" as you choose data; label → `label:"in progress"`, state → `is:open`; multiple selections join with implicit AND; `-` negates any filter and `has:`/`no:` test presence/absence. [github-issues-filter]
- Sentry's right-rail facet map ("top 10 keys sorted by frequency") clicks add `key:value` tokens to the same query; negation is the `!` operator; and Sentry explicitly distinguishes result-scoped counts ("given the search, environments, or time period selected") from lifetime total counts in the header. [sentry-issue-details]
- Faceted-search consensus is dynamic, result-scoped counts that update as other filters apply ("Blue (47)" sets a true expectation, "Blue (0)" warns of a dead end); 0-count options are handled by grey-out/disable (Google) or hide/show-only-non-empty (Elasticsuite/Doofinder), never left as a live clickable dead-end. [google-faceted-nav]
- Many filter values are tamed by search-within-the-filter-menu, parent→child scoping (Linear "filter by project first" to narrow milestones), and collapsible/grouped sections with collapse-all (Airtable). [linear-filters]
- Chips are the single unified surface for active state with one "Clear filters" regardless of source; PatternFly ("every selection will always show up as a chip") and Material 3 ("do not display a single chip by itself; chips should appear in a set", dismissible via `×`). [patternfly-filters]

## SOURCES

**linear-filters**
URL: https://linear.app/docs/filters
Accessed: 2026-06-22

**datadog-facets**
URL: https://docs.datadoghq.com/logs/explorer/facets/
Accessed: 2026-06-22

**datadog-search-syntax**
URL: https://docs.datadoghq.com/logs/explorer/search_syntax/
Accessed: 2026-06-22

**github-issues-filter**
URL: https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/filtering-and-searching-issues-and-pull-requests
Accessed: 2026-06-22

**github-issues-search-ga**
URL: https://github.blog/changelog/2026-04-02-improved-search-for-github-issues-is-now-generally-available/
Accessed: 2026-06-22

**sentry-issue-details**
URL: https://docs.sentry.io/product/issues/issue-details/
Accessed: 2026-06-22
Quote: "the event and user counts represent the counts given the search, environments, or time period selected… different from the counts in the header which are the total counts across the lifetime of the issue."

**sentry-search**
URL: https://docs.sentry.io/concepts/search/
Accessed: 2026-06-22

**google-faceted-nav**
URL: https://developers.google.com/search/blog/2014/02/faceted-navigation-best-and-5-of-worst
Accessed: 2026-06-22

**brokenrubik-faceted**
URL: https://www.brokenrubik.com/blog/faceted-search-best-practices
Accessed: 2026-06-22

**notion-advanced-filters**
URL: https://www.notion.com/help/guides/using-advanced-database-filters
Accessed: 2026-06-22

**airtable-grouping**
URL: https://support.airtable.com/docs/grouping-records-in-airtable
Accessed: 2026-06-22

**patternfly-filters**
URL: https://www.patternfly.org/2022.11/guidelines/filters/
Accessed: 2026-06-22

**material-chips**
URL: https://m3.material.io/components/chips/guidelines
Accessed: 2026-06-22

## SYNTHESIS

SLVP-grade products dodge "filters vs operators" confusion by making them ONE model shown two surfaces: the clickable rail/facet panel is a query-BUILDER — clicking a facet writes the equivalent operator/chip into a single shared, URL-encoded query, and editing the query reselects the rail. The chip row is the one canonical view of active state, with a single "Clear filters." Counts are result-scoped and dynamic (recomputed against the current query) and visibly distinguished from lifetime totals (Sentry states this explicitly). 0-count options are never live dead-ends — grey-out/disable or hide. Many values are tamed by search-within-the-menu, parent→child scoping, top-N-by-frequency-then-more, and collapsible grouped sections. Inversion is the same chip with a flipped operator (Linear `is not`, GitHub `-`/`no:`, Sentry `!`), never a separate negative UI. The count-badge = exactly what clicking yields (count-as-promise / reachability).
