---
title: "The data-explorer workbench is one surface (query + multi-select facets + volume-histogram-as-filter + result list + in-place detail, URL-encoded, paginated not capped); app-access transparency is a list → per-app scope → per-app activity hierarchy"
date: 2026-06-18
topic: data-explorer-ux
tags: [data-explorer, faceted-search, histogram-filter, access-transparency, oauth-apps, workbench]
status: draft
sources: [datadog-explorer, posthog-filters, algolia-search-ui, google-connections, github-oauth-apps, plaid-link]
---

## CLAIMS

### Data-explorer workbench

- Datadog's Log Explorer is one surface combining: a single query bar with structured syntax + autocomplete (the query string is the single source of truth); a left facet panel of indexed dimensions with counts where clicking a value adds a filter to the query (multi-select) rather than navigating away; a timeseries histogram above the results that is itself a filter (dragging a region narrows the time window); a result list whose row opens a side panel with the full event + raw/JSON; a time-range selector distinct from and composing with the query; and Saved Views persisting query + range + columns as a URL-addressable, shareable view. [datadog-explorer]
- PostHog models a filter as a three-part tuple: the property (autocompleted from schema) + an operation typed to the property (`= equals`, `≠`, `∈ contains`, `∉`, `~ matches regex`, `>/</≥/≤`, `is set`/`is not set` — the operator menu changes with field type) + a comparison value where `equals`/`contains` accept multiple values (OR-within-a-filter) with autocomplete on known values. [posthog-filters]
- Algolia's instant-search convention standardizes: instant results as you type (no submit step), multi-select refinement lists with counts (AND across facets, OR within a facet), query suggestions/autocomplete sourced from the index, and URL syncing of the full search state so a search is shareable and back-button-safe. [algolia-search-ui]

### App/client access transparency

- Google's "Apps with access to your account" (myaccount.google.com/connections) uses a single linked-apps list, one row per third-party app grouped by app (not per-scope/per-grant), each drilling into a per-app detail page that states in plain language which data and services the app can access, described in graded tiers (get basic profile / view (read) data / manage (edit/create/delete) data), with "See details" and one-click remove-access plus an explicit consequence warning. [google-connections]
- GitHub's "Authorized OAuth Apps" is a flat list one row per app/token from a single Settings→Applications location, framed as review-oriented ("verify that no new applications with expansive permissions are authorized"), with revoke-first per-app actions (three-dot → Revoke, plus Revoke all). [github-oauth-apps]
- Plaid Link scopes consent at grant time — the user selects which specific accounts to share before any data flows — establishing the concrete "these are the accounts/data this app will see" framing that a post-hoc review surface should mirror. [plaid-link]

## SOURCES

**datadog-explorer**
URL: https://docs.datadoghq.com/logs/explorer/
Accessed: 2026-06-18

**posthog-filters**
URL: https://posthog.com/docs/product-analytics/trends/filters
Accessed: 2026-06-18

**algolia-search-ui**
URL: https://www.algolia.com/doc/guides/building-search-ui/ui-and-ux-patterns/in-depth/
Accessed: 2026-06-18
Quote: "(in-depth UI/UX page 404'd at retrieval; records the well-established instant-search convention rather than a live quote)"

**google-connections**
URL: https://support.google.com/accounts/answer/3466521 ; https://support.google.com/accounts/answer/13533235 ; https://myaccount.google.com/connections
Accessed: 2026-06-18

**github-oauth-apps**
URL: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/reviewing-your-authorized-applications-oauth
Accessed: 2026-06-18

**plaid-link**
URL: https://plaid.com/docs/link/
Accessed: 2026-06-18

## SYNTHESIS

Two convergent shapes.

Data-explorer workbench (Datadog + PostHog + Algolia): one surface = query bar (autocomplete) + facet/refinement rail (multi-select, counts) + a volume histogram that doubles as a time filter + a result list whose row opens an in-place detail panel, with the entire state encoded in a shareable URL, and pagination instead of silent result caps. This is one renderer parameterized by scope — a per-entity table is the same workbench with that entity pre-applied as a facet. Type-aware operators and value autocomplete require declared field types as the substrate. Instant-refinement (no submit step) and URL sync are table stakes; "click, only first click honored, wait for refresh" is the opposite of the standard.

App-access transparency (Google + GitHub + Plaid): the front-door list object is the client/app (grouped by app, revoke-first, access-expansiveness visible) → a per-app detail restating what this app can read in graded, concrete, owner-legible tiers (read/write; which sources/streams) → per-app activity (what it actually read, and when last used). Consent should be re-presented in the same concrete terms the user saw at grant time (Plaid's account-selection framing), closing the "it was just a bunch of checkboxes" gap. "Last used" is a trivial projection of the same disclosure/trace spine.
