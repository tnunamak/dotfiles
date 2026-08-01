---
title: "Leading products expose one tokenized query surface where chips, facets, free-text, and operators are a single synchronized query state"
date: 2026-06-21
topic: data-explorer-ux
tags: [search-ui, filters, facets, query-model, chips, schema-driven-presentation]
status: draft
sources: [linear-filters, linear-changelog, linear-devs, github-projects-antipattern, helpscout, datadog-facets, datadog-explorer, notion-property, airtable-primary-field, airtable-record-detail, datadog-standard-attrs, schema-org-mainentity, jsonschema-annotations, stripe-search, gmail-chips, gmail-refine, google-my-activity, gharchive]
source_session: 019db34f-f4a7-77f3-b339-4f7b2b596e64
---

## CLAIMS

- Linear uses tokenized, click-to-refine filter chips (not typed operator syntax): clicking "is" offers "is not", clicking the value opens a selectable list, and operators are context-aware ("is" → "is either of" as values are added); operator/keyword syntax is reserved for the API/GraphQL layer, with an advanced builder for nested AND/OR. [linear-filters][linear-changelog][linear-devs]
- Mixing typed operator syntax INTO a token field is an anti-pattern (GitHub Projects "text mode vs token mode" confusion — needing a space before a comma to exit text mode — users called it "very unwieldy"). [github-projects-antipattern]
- Operator-syntax-in-the-bar is used where power matters (Help Scout: `subject:(coffee OR tea) assigned:Josie tag:carrots`, AND by default, OR/NOT explicit). [helpscout]
- In Datadog Log Explorer the facet panel and the search bar are ONE synchronized query state reflected in the query bar and the URL (and vice versa), not two parallel systems. [datadog-facets][datadog-explorer]
- Datadog facet counts = the number of records matching that value WITHIN the current filtered query scope, not the full corpus; counts update as filters change. [datadog-facets]
- Notion's TITLE property is the schema-required primary field: exactly one per database, enforced at the schema/API level, rendered as both the row's display label and the page header; the schema DECLARES the title, the renderer does not infer it. [notion-property]
- Airtable's PRIMARY FIELD is the record title across all views (grid, Kanban card, linked-record reference) — a declared role, and only field TYPES eligible to be a primary field may serve as it; interface record-review layouts let you choose a title field + up to 2 preview fields (title + preview1 + preview2). Field TYPE is separate from ROLE. [airtable-primary-field][airtable-record-detail]
- Datadog's honest generic fallback renders arbitrary structured logs as a generic key/value attribute table (flat keys as attributes, nested as an expandable tree), with only a few reserved standard attributes (service/host/level/message/timestamp) treated specially when present — it does not guess which field is the title. [datadog-standard-attrs]
- Presentation roles are DECLARED, not inferred, in the specs: schema.org `name` = title/primary, `description` = body, exactly one `mainEntity`; JSON Schema `title`/`description` annotations are explicitly for display. [schema-org-mainentity][jsonschema-annotations]
- Stripe's Dashboard search is ONE bar that does free-text AND filters AND operators (negate any filter with a leading `-`, multiple terms AND'd) and is also where you paste an exact id to resolve it; filter/search state is reflected in the URL query string so the URL is a handle to the exact filtered set. [stripe-search]
- Gmail resolves the query-model tension in one bar: clickable recognition-over-recall search chips ("Has attachment" == `has:attachment`) on web and mobile; an advanced-search form with a first-class "Doesn't have" negation field; operators (`from:john has:attachment -filename:pdf`, AND by default, `-` for NOT) building the same query the chips build; "Create filter" saves a search as a view. [gmail-chips][gmail-refine]
- Heterogeneous activity renders through one generic item component over a common base schema: Google My Activity uses `header`/`title`/`time`/`products`, day-grouped and expandable; the GitHub event schema is common fields + a type-specific serialized `payload` rendered conditionally. [google-my-activity][gharchive]

## SOURCES

**linear-filters**
URL: https://linear.app/docs/filters
Accessed: 2026-06-21
Quote: "Refine a filter by clicking parts of the chip; operators are context-aware."

**linear-changelog**
URL: https://linear.app/changelog/2021-11-08-linear-preview-new-filters
Accessed: 2026-06-21
Quote: "New tokenized filters with click-to-refine chips."

**linear-devs**
URL: https://linear.app/developers/filtering
Accessed: 2026-06-21
Quote: "and/or/every operator syntax is available at the API/GraphQL layer."

**github-projects-antipattern**
URL: https://github.com/community/community/discussions/15655
Accessed: 2026-06-21
Quote: "Users found the mixed text/token filter field very unwieldy — needing a space before a comma to exit text mode."

**helpscout**
URL: https://docs.helpscout.com/article/47-search-filters-with-operators
Accessed: 2026-06-21
Quote: "subject:(coffee OR tea) assigned:Josie tag:carrots — AND by default, OR/NOT explicit."

**datadog-facets**
URL: https://docs.datadoghq.com/logs/explorer/facets/
Accessed: 2026-06-21
Quote: "Facet selections are reflected in the query and the URL; facet counts reflect the current filtered scope."

**datadog-explorer**
URL: https://docs.datadoghq.com/logs/explorer/
Accessed: 2026-06-21
Quote: "The facet panel and search bar share one query state."

**notion-property**
URL: https://developers.notion.com/reference/property-object
Accessed: 2026-06-21
Quote: "Every database has exactly one title property, enforced by the API."

**airtable-primary-field**
URL: https://support.airtable.com/docs/the-primary-field
Accessed: 2026-06-21
Quote: "Only fields supported as the primary field are able to be used as the title."

**airtable-record-detail**
URL: https://support.airtable.com/docs/airtable-interface-layout-record-detail
Accessed: 2026-06-21
Quote: "Choose the title field and up to two preview fields for a record-review layout."

**datadog-standard-attrs**
URL: https://docs.datadoghq.com/standard-attributes/
Accessed: 2026-06-21
Quote: "Reserved standard attributes (service, host, status, message, timestamp) are treated specially; other attributes render as key/value."

**schema-org-mainentity**
URL: https://schema.org/mainEntity
Accessed: 2026-06-21
Quote: "mainEntity: indicates the primary entity described in a Web page."

**jsonschema-annotations**
URL: https://json-schema.org/understanding-json-schema/reference/annotations
Accessed: 2026-06-21
Quote: "title and description annotations are for display: a short title and a longer description."

**stripe-search**
URL: https://docs.stripe.com/dashboard/search
Accessed: 2026-06-21
Quote: "Negate any filter with a leading hyphen; multiple terms are AND'd; one bar does free-text, filters, operators, and id lookup."

**gmail-chips**
URL: https://9to5google.com/2020/02/19/gmail-search-chips/
Accessed: 2026-06-21
Quote: "Search chips let users refine without operators; a 'Has attachment' chip equals has:attachment."

**gmail-refine**
URL: https://support.google.com/mail/answer/7190
Accessed: 2026-06-21
Quote: "Advanced search offers a 'Doesn't have' field; operators build the same query as the chips."

**google-my-activity**
URL: https://developers.google.com/data-portability/schema-reference/my_activity
Accessed: 2026-06-21
Quote: "Each activity item fills a common base schema: header, title, time, products."

**gharchive**
URL: https://www.gharchive.org/
Accessed: 2026-06-21
Quote: "GitHub events have common fields plus a type-specific payload, different for each event type."

## SYNTHESIS

The canonical query model (best exemplified by Gmail and Stripe) is ONE input surface where
common filters are recognition-over-recall chips with typeahead, negation is a first-class chip
toggle / "is not" (and also `-` for power users), and operators build the exact same query the
chips build. Facets, chips, and free-text are a single synchronized query state (Datadog),
reflected in the URL so the URL is a shareable handle to the exact filtered set (Stripe); a
facet count means "count within the current filtered result set," and if that can't be computed
exactly it should be hidden rather than shown ambiguously. Bolting typed operators into a token
field is a known anti-pattern (GitHub Projects). For presentation, roles (title/primary,
body/detail, plus typed roles like timestamp/amount/actor/media) should be DECLARED by the
schema/manifest (Notion title, Airtable primary field, schema.org name/mainEntity), never
guessed by the renderer; the honest fallback for an undeclared record is a humanized key/value
table (Datadog), and a single generic item component reading declared common roles renders
heterogeneous records with no per-source code (Google My Activity, GitHub events).
