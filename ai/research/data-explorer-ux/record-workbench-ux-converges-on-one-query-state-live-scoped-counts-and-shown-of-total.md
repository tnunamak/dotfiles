---
title: "Record/log workbench UX converges across leading tools on one canonical query state (string ⇄ builder), live query-scoped facet counts, histogram-as-filter, shown-of-total counts, index-sourced autocomplete, and virtualization instead of silent caps"
date: 2026-06-18
topic: data-explorer-ux
tags: [data-explorer, search, faceted-filter, virtualization, autocomplete, saved-views, prior-art]
status: draft
sources: [datadog-saved-views, datadog-facets, datadog-search-syntax, datadog-visualize, github-code-search, github-issue-filter, github-search-syntax, posthog-filters, notion-views, devtools-network, algolia-routing, tanstack-virtual, airtable-grid, raycast-manual]
---

## CLAIMS

- A Datadog Log Explorer "Saved View" persists exactly three things: a search query with its time range; a default visualization plus its properties; and a selected subset of facets to display. Live/relative time ranges are the canonical save form — "fixed time ranges are converted as such on save." [datadog-saved-views]
- Datadog facets show "a summary of [their] content for the scope of the current query" — qualitative facets list top unique values each with a count of matching logs, clicking a value toggles the search on it, checkboxes add/remove values, and the value list is itself searchable for high cardinality; numeric ("Measure") facets provide a min/max slider plus numeric inputs. Counts are scoped to (and update with) the current query. [datadog-facets]
- Datadog search syntax expresses the full operator surface in the query string: `key:value` attribute search (reserved attributes unprefixed, custom attributes use `@`), inclusive ranges `@http.status_code:[200 TO 299]`, negation/existence (`-@field:*` = not containing, `@field:*` = is set), wildcards (`service:web*`, `?` for a single char), escaping via quotes, and arrays (`@user_perms:(4 6)` = both, `[2 TO 6]` = any in range). [datadog-search-syntax]
- Datadog's Timeseries visualization plots a measure (or facet unique-count) over the selected time frame, optionally split by up to three facets, with a configurable roll-up interval and a bars/lines/areas choice (bars recommended for counts). The roll-up interval is the performance knob. [datadog-visualize]
- GitHub code search treats whitespace-separated terms as implicit AND ("equivalent to `hello AND world`"), also supports explicit `OR`/`NOT`, exact-phrase via quotes, escaping, regular expressions delimited `/.../`, and qualifiers (`language:`, `path:`, `repo:`). A single text box can carry AND/OR/NOT/exact-phrase/regex without a builder UI. [github-code-search]
- GitHub issue/PR filtering makes the faceted-search OR/AND rule concrete: logical OR within a field uses comma syntax (`label:"bug","wip"`); logical AND across a field uses separate filters (`label:"bug" label:"wip"`); exclusion uses a leading `-` (`-author:octocat`). [github-issue-filter]
- GitHub's general search syntax requires whitespace-containing values to be quoted (`build label:"bug fix"`, `cats NOT "hello world"`). [github-search-syntax]
- PostHog filters use a three-part typed tuple: property → operation → value, where the operator menu is typed to the property and `equals`/`contains` accept multiple values (OR-within-filter) with value autocomplete. This is the "builder" rendering of the same grammar Datadog/GitHub express as a query string. [posthog-filters]
- Notion attaches filters, sorts, and groups to a named view; a database holds multiple such views each with its own config, supports multiple stacked sort rules (sort by A then B), and supports grouping records by a property into collapsible sections. [notion-views]
- Chrome DevTools Network panel sources filter autocomplete from data actually seen: for `domain` it "populates the autocomplete drop-down menu with all of the domains it has encountered," and likewise for `has-response-header`. Type filters (Fetch/XHR, JS, CSS, Img, …) are multi-select via Cmd/Ctrl-click. Dragging on the Overview timeline filters to requests active in that window (inclusive). The bottom status bar "displays the number of the shown requests out of the total," and hiding rows updates that ratio rather than silently truncating. [devtools-network]
- Algolia InstantSearch's `routing` option serializes the full UI state (query, refinements, page, sort) into the URL and hydrates back from it, with a `stateMapping` hook for clean human-readable URLs. Shareable/back-button-safe state is a first-class documented concern. [algolia-routing]
- TanStack Virtual windows scrollable content so only the visible rows are mounted to the DOM, keeping large result sets smooth — the documented alternative to hard-capping a list for performance. [tanstack-virtual]
- Airtable's grid provides an expand control that opens the full record in place (in-grid detail), selectable rows, reorderable/hideable/resizable columns, and adjustable row height for denser or richer display. [airtable-grid]
- Raycast's core is a single text field that is simultaneously launcher and filter: results filter instantly with no submit, the first result is the default action on Enter, and arrow keys move the selection. (Partly observed product behavior; the fetched manual landing page is a shell.) [raycast-manual]

## SOURCES

**datadog-saved-views**
URL: https://docs.datadoghq.com/logs/explorer/saved_views/
Accessed: 2026-06-18

**datadog-facets**
URL: https://docs.datadoghq.com/logs/explorer/facets/
Accessed: 2026-06-18

**datadog-search-syntax**
URL: https://docs.datadoghq.com/logs/explorer/search_syntax/
Accessed: 2026-06-18

**datadog-visualize**
URL: https://docs.datadoghq.com/logs/explorer/visualize/
Accessed: 2026-06-18

**github-code-search**
URL: https://docs.github.com/en/search-github/github-code-search/understanding-github-code-search-syntax
Accessed: 2026-06-18

**github-issue-filter**
URL: https://docs.github.com/en/issues/tracking-your-work-with-issues/filtering-and-searching-issues-and-pull-requests
Accessed: 2026-06-18

**github-search-syntax**
URL: https://docs.github.com/en/search-github/getting-started-with-searching-on-github/understanding-the-search-syntax
Accessed: 2026-06-18

**posthog-filters**
URL: https://posthog.com/docs/product-analytics/trends/filters
Accessed: 2026-06-18

**notion-views**
URL: https://www.notion.com/help/views-filters-and-sorts
Accessed: 2026-06-18

**devtools-network**
URL: https://developer.chrome.com/docs/devtools/network/reference
Accessed: 2026-06-18

**algolia-routing**
URL: https://www.algolia.com/doc/guides/building-search-ui/going-further/routing-urls/js/
Accessed: 2026-06-18

**tanstack-virtual**
URL: https://tanstack.com/virtual/latest/docs/introduction
Accessed: 2026-06-18

**airtable-grid**
URL: https://support.airtable.com/docs/grid-view
Accessed: 2026-06-18

**raycast-manual**
URL: https://manual.raycast.com/
Accessed: 2026-06-18
Quote: "(partly observed product behavior; the fetched manual landing page is a shell)"

## SYNTHESIS

A convergent workbench emerges across every surveyed tool, useful for any "search-and-inspect a large record set" UI.

- **One canonical query state, two faces.** Datadog/GitHub express the full operator set (AND/OR/NOT, ranges, wildcards, existence, exact phrase) as a query string; PostHog/Notion express the same as a builder (property → operator → value rows). Treat these as two renderings of one serializable state — and that state is what gets saved (Datadog Saved Views) and URL-encoded (Algolia routing).
- **Counts are live, scoped, and framed as shown/total.** Datadog facet counts are scoped to the current query; DevTools always shows "shown requests out of the total." Never surface a bare "N of M" without a reachable denominator.
- **The volume chart is a filter, not decoration.** Both Datadog and DevTools make the time distribution draggable to narrow the result set, with a roll-up/coarseness knob so it stays cheap. Removing it removes both whole-set context and a primary filter affordance.
- **Multi-select is explicit, accumulative, and survives loading.** DevTools type filters and Datadog facet checkboxes accumulate selections (Cmd/Ctrl-click; checkboxes), toggle cleanly, and are distinct chips/checkboxes — never a fire-and-forget click whose second tap is dropped while results reload.
- **Autocomplete is sourced from the real index**, spanning field → operator → value (DevTools populates from domains/headers it has encountered; Algolia suggests from the index; Datadog suggests facet keys/values).
- **In-place detail, then raw.** Row → side panel / expand-in-grid (Airtable); raw JSON is an available face of a richly-rendered record, not the default.
- **Virtualize the full set; don't cap it.** TanStack Virtual is the documented performance fix (window the DOM) that makes "show the whole paged set" viable, removing the justification for silent caps.

Anti-patterns the survey rules out: silent caps with no "of M" and no path to the rest; deleting a volume chart for "performance" when the roll-up interval is the performance knob; fire-and-forget selection that drops the second click during loading; hardcoded suggestion lists; two divergent renderers for the same "show records" job; raw JSON as the default record view; a jump-to-record control that gives no feedback on hit or miss.
