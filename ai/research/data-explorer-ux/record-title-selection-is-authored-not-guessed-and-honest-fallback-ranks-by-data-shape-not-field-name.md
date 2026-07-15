---
title: "Mature data platforms make the record title/primary-display an AUTHORED field, deliberately separate from the identity key; auto-detection exists only as a documented-fallible convenience, and honest fallback ranks candidates by value data-shape (cardinality/entropy/readability), never by field-name meaning"
date: 2026-06-22
topic: data-explorer-ux
tags: [record-display, title-field, schema-annotations, cardinality, entropy, rdf-labels, faceted-display]
status: draft
sources: [airtable-primary, notion-property, metabase-semantic, metabase-49783, directus-templates, strapi-mainfield, strapi-8280, salesforce-name, sentry-issue-title, supabase-tables, retool-table, json-log-viewers, yscope-viewer, gcp-loggly, dbautodoc, sql-cardinality, detect-secrets, uuid-regex, rdf-labels, es-significant-terms, algolia-searchable, backstage-descriptor, json-schema-annotations, singer-airbyte, plaid-enrich, rjsf-uischema, merge-field-mapping]
---

## CLAIMS

### Title / primary-display field is authored, separate from the key

- Airtable's "primary field" is always the first column, cannot be deleted/moved/hidden, is used as the record's title everywhere (linked-record name, Kanban card), and is explicitly NOT the database primary key (an internal alphanumeric record ID handles identity); it "doesn't even have to be unique or filled in," and authorship is the user's job (best practice: author a formula field concatenating name+address when values are weak). [airtable-primary]
- Notion's API requires exactly one `title` property per data source and throws errors if you create one without a title or add/remove a title; it always has `id: "title"` and controls the page title — a titleless record is structurally impossible rather than auto-guessed. [notion-property]
- Metabase auto-detects a display name via the "Entity Name" semantic type (its sibling "Entity Key" marks the unique identifier), guessed during database sync from column names, with admin override; the auto-detection is documented as fallible (issue #49783: the heuristic mis-tags `fullName`/`firstName`/`lastName` all at once). [metabase-semantic, metabase-49783]
- Directus's per-collection "Display Template" (author-picked fields; nothing auto-guessed for relational display) falls back to the raw primary key when absent. [directus-templates]
- Strapi's per-content-type "Entry title" / `mainField` is author-chosen via "Configure the view"; for component/relation fields where it cannot be set, the editor falls back to the "very non-descript `id` attribute." [strapi-mainfield, strapi-8280]
- Salesforce ships a standard "Name" field on every object as the user-facing identifier (free-text or Auto-Number), mutable and not to be relied on programmatically — the immutable 15/18-char Record ID is the real identity. [salesforce-name]
- Sentry stores `issue_title` in event metadata derived from typed exception data, with `culprit` and `subtitle` as separate honest slots; grouping (fingerprint) is independent of titling and the title is a producer-supplied declared field, with mis-inference tracked as a defect (issue #21433). [sentry-issue-title]
- Supabase/PostgREST and Retool have no authored display-column concept: foreign-key cells render the raw referenced key, and Retool tells users to JOIN the lookup table in SQL to surface a label — tools that give no way to author a display field end up showing IDs/UUIDs. [supabase-tables, retool-table]

### Honest fallback ranks by data-shape, not field name

- JSON log viewers prove field-NAME mapping is per-deployment config, not universal inference: d10xa's viewer ships a configurable mapping (timestamp→`ts`, message→`msg`); hedhyw's defaults to `timestamp`/`level`/`message` and falls back to user config. YScope's viewer separates field selection (config) from value formatting, routing UUID/IP by a declared formatter, not by sniffing the name. [json-log-viewers, yscope-viewer]
- When platforms DO auto-pick a "most relevant field" they use structural/statistical signals — frequency and cardinality — not name semantics: Google Cloud Logging surfaces "JSON payload (most frequent)" fields in the current result set; Loggly ranks by JSON field counts "instead of relying on guesswork." [gcp-loggly]
- Automatic primary-key detection (DBAutoDoc) blends uniqueness (50%), naming pattern (20%), data type (15%), data pattern (15%), with hard rejection of nulls, mostly-empty columns, and a semantic blacklist (dates, quantities, money, descriptive free-text); high cardinality makes a good ROW IDENTIFIER but a bad HUMAN LABEL — for display you want the inverse weighting (the descriptive free-text a PK detector discards). [dbautodoc]
- SQL cardinality gives a three-tier shape taxonomy: high-cardinality = unique IDs/emails (best to identify, worst to label); normal-cardinality = names/addresses/types (the human-meaningful middle); low-cardinality = status flags/booleans/enums. Computable without reading field names. [sql-cardinality]
- "Human-readable vs opaque" is a measurable data-shape property (Shannon entropy + word boundaries + dictionary/n-gram ratio); the meaningful zone is the MIDDLE of the entropy scale — Yelp `detect-secrets` uses length-weighted high-entropy scoring to flag opaque tokens, but entropy alone is insufficient (random noise and uniform data both score extreme), so pair it with structural signals. [detect-secrets]
- UUID/hash/all-digit detection has stable structural regexes (UUID `^[0-9a-fA-F]{8}-...-{12}$`; compact hex `^[0-9a-fA-F]{32}$`/`{40}`/`{64}`; all-digit `^\d+$`) but they are demotion signals, not semantic claims ("not everything that looks like a UUID is one"). [uuid-regex]
- RDF/Linked-Data label selection is the closest formal precedent: try the most-specific declared label (`skos:prefLabel`) → `rdfs:label` (and via subPropertyOf `schema:name`/`foaf:name`/`dcterms:title`) → apply language preference → and only as a last resort derive from the URI local-name, with an explicit warning that putting descriptive text in URIs is bad practice ("things, not strings"). [rdf-labels]
- Elasticsearch `significant_terms`/`significant_text` ranks content relevance by foreground-vs-background statistical surprise, not by a field being named "summary" ("the most popular word… is 'the' but that is hardly significant"). [es-significant-terms]
- Algolia states picking the primary display/searchable attribute is "more an art than a science… no magic formula"; `searchableAttributes` is author-ordered by importance, `attributesToSnippet` truncates long text — the primary field is a declared choice validated against real records, not auto-divined from names. [algolia-searchable]

### Manifest/source-authored display annotations

- Backstage declares an optional display-only `metadata.title` that explicitly does NOT replace the identity key: "only for display purposes… Entity references still always make use of the `name` property… not the title," with graceful fallback to `name` when absent — the canonical separation of authored display label from machine identity. [backstage-descriptor]
- JSON Schema 2020-12 makes `title`/`description` first-class annotation keywords (no validation effect) and collects any unknown/`x-` keyword as an annotation ("Unknown keywords SHOULD be treated as annotations"), the spec basis for vendor `x_`-prefixed display roles. [json-schema-annotations]
- Singer SDK / Meltano and Airbyte have the connector (tap/source) author declare structural role metadata per stream (`primary_keys`, `replication_key`; `source_defined_primary_key`, `default_cursor_field`) and the platform respects source-declared values over inference. [singer-airbyte]
- Plaid normalizes raw rows into authored display primitives (`merchant_name`, `logo_url`, `personal_finance_category` + icon, `counterparties[]`) so clients never parse raw descriptions, with explicit graceful null fallback ("for… checks, transfers where there is no meaningful merchant name, this value will be null"; a category icon exists "when a merchant logo is not available"). [plaid-enrich]
- react-jsonschema-form keeps presentation in a separate `uiSchema` (`ui:title`, `ui:order`) distinct from the data schema — the cross-industry pattern of an authored presentation layer rather than UI heuristics. [rjsf-uischema]
- Merge.dev treats end-user/client field remapping as a separate GET-only override surface so the source-authored mapping stays the default — client may consume the authored display, not author it. [merge-field-mapping]

## SOURCES

**airtable-primary**
URL: https://support.airtable.com/docs/the-primary-field ; https://blog.airtable.com/the-primary-column/ ; https://support.airtable.com/docs/using-formulas-in-airtables-primary-field
Accessed: 2026-06-22

**notion-property**
URL: https://developers.notion.com/reference/property-object ; https://www.notion.com/help/database-properties
Accessed: 2026-06-22

**metabase-semantic**
URL: https://www.metabase.com/docs/latest/data-modeling/semantic-types
Accessed: 2026-06-22

**metabase-49783**
URL: https://github.com/metabase/metabase/issues/49783
Accessed: 2026-06-22

**directus-templates**
URL: https://directus.com/docs/guides/data-model/collections ; https://docs.directus.io/user-guide/content-module/display-templates
Accessed: 2026-06-22

**strapi-mainfield**
URL: https://docs.strapi.io/user-docs/content-manager/configuring-view-of-content-type
Accessed: 2026-06-22

**strapi-8280**
URL: https://github.com/strapi/strapi/issues/8280
Accessed: 2026-06-22

**salesforce-name**
URL: https://help.salesforce.com/s/articleView?id=sf.dev_objectfields.htm&type=5 ; https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_compactlayout.htm
Accessed: 2026-06-22

**sentry-issue-title**
URL: https://develop.sentry.dev/backend/issue-platform/ ; https://docs.sentry.io/api/events/retrieve-an-issue/
Accessed: 2026-06-22

**supabase-tables**
URL: https://supabase.com/docs/guides/database/tables
Accessed: 2026-06-22

**retool-table**
URL: https://docs.retool.com/apps/guides/data/table ; https://community.retool.com/t/foreign-key-column-display/25187
Accessed: 2026-06-22

**json-log-viewers**
URL: https://github.com/d10xa/json-log-viewer ; https://github.com/hedhyw/json-log-viewer
Accessed: 2026-06-22

**yscope-viewer**
URL: https://blog.yscope.com/a-refreshed-log-viewer-for-text-and-json-logs-85f4990ee2f5
Accessed: 2026-06-22

**gcp-loggly**
URL: https://docs.cloud.google.com/logging/docs/view/logs-explorer-interface ; https://www.loggly.com/solution/json-logging/
Accessed: 2026-06-22

**dbautodoc**
URL: https://arxiv.org/pdf/2603.23050
Accessed: 2026-06-22

**sql-cardinality**
URL: https://en.wikipedia.org/wiki/Cardinality_(SQL_statements) ; https://www.thedataschool.co.uk/eamonn-woodham/high-cardinality-vs-low-cardinality/
Accessed: 2026-06-22

**detect-secrets**
URL: https://github.com/Yelp/detect-secrets/blob/master/detect_secrets/plugins/high_entropy_strings.py ; https://www.ncbi.nlm.nih.gov/pmc/articles/PMC12025590/
Accessed: 2026-06-22

**uuid-regex**
URL: https://www.guidsgenerator.com/wiki/uuid-regex ; https://ihateregex.io/expr/uuid/
Accessed: 2026-06-22

**rdf-labels**
URL: https://www.bobdc.com/blog/rdflabels/ ; https://patterns.dataincubator.org/book/preferred-label.html ; https://www.w3.org/2004/12/q/doc/rdf-labels.html
Accessed: 2026-06-22

**es-significant-terms**
URL: https://www.elastic.co/blog/significant-terms-aggregation ; https://www.elastic.co/docs/reference/aggregations/search-aggregations-bucket-significantterms-aggregation
Accessed: 2026-06-22

**algolia-searchable**
URL: https://www.algolia.com/doc/guides/managing-results/must-do/searchable-attributes/how-to/configuring-searchable-attributes-the-right-way
Accessed: 2026-06-22

**backstage-descriptor**
URL: https://backstage.io/docs/features/software-catalog/descriptor-format/
Accessed: 2026-06-22

**json-schema-annotations**
URL: https://json-schema.org/understanding-json-schema/reference/annotations ; https://json-schema.org/draft/2020-12/json-schema-core
Accessed: 2026-06-22

**singer-airbyte**
URL: https://sdk.meltano.com/en/latest/classes/singer_sdk.Stream.html ; https://github.com/airbytehq/airbyte/issues/48829
Accessed: 2026-06-22

**plaid-enrich**
URL: https://plaid.com/docs/api/products/enrich/ ; https://plaid.com/docs/api/products/transactions/
Accessed: 2026-06-22

**rjsf-uischema**
URL: https://rjsf-team.github.io/react-jsonschema-form/docs/api-reference/uiSchema/
Accessed: 2026-06-22

**merge-field-mapping**
URL: https://docs.merge.dev/supplemental-data/field-mappings/overview/ ; https://help.merge.dev/en/articles/8593316-guide-to-overriding-common-model-fields
Accessed: 2026-06-22

## SYNTHESIS

Near-universal architecture across nine data platforms: there IS a dedicated title/primary-display concept, the trustworthy products make it AUTHORED (Airtable primary field, Notion title property, Directus template, Strapi entry title, Salesforce Name — Notion goes furthest: exactly one, required, API-enforced), and it is deliberately SEPARATED from the identity key. Auto-detection exists only as a convenience layer and is documented as a liability (only Metabase truly auto-detects, and its own tracker shows the heuristic mis-firing with override as the fix). When no display field is declared, the honest behavior is to fall back to the KEY and make the gap obvious (Supabase raw FK, Strapi `id`, Notion "Untitled") rather than silently fabricate a title from an arbitrary column. No surveyed product silently promotes the "longest text" or "first non-id string" as a confident title.

The reusable line between honest and guessing: selecting among declared data by its VALUE SHAPE is honest; inferring meaning from a field's NAME is guessing. A concrete honest fallback algorithm (name-blind) for an undeclared row-primary: (Step 0) if a display field is declared, use it and stop. (Step 1) hard-reject null/empty/empty-collection and pure structural id/hash/opaque values (long all-digit, UUID, compact-hex, short unreadable strings). (Step 2) type tier: readable non-empty string eligible; enum/boolean/single-number/timestamp weak fallback; ids never primary. (Step 3) score each candidate string by shape — word/structure signal (spaces, ≥2 words, dictionary hits), mid-range entropy band (reject high-entropy opaque tokens ~>3.5 length-weighted and trivially low-entropy tokens), capped text mass (a 5,000-char body must not beat a clean one-line name — snippet à la Algolia), and cardinality demotion of both extremes toward the descriptive normal-cardinality middle. (Step 4) deterministic tiebreak by declared schema order, never a name-meaning tiebreak. This is a PK-detector inverted: PK detectors weight uniqueness to find identifiers; a label picker inverts that to avoid them. "Highest readability score with capped text mass," not raw "longest," is the defensible default — the same posture RDF takes falling back to `rdfs:label` rather than parsing the URI, and Loggly/Cloud Logging take with frequency over name-divination.

For authored display annotations, the recurring shape across seven systems: one required-ish anchor (a single declared title/name/primary field — the highest-value lowest-burden declaration most authors ever set); a short ordered set of optional secondary roles with defaults (Salesforce compact-layout, Plaid amount/category/counterparty, Singer key/cursor); graceful degradation to the identity key when nothing is declared (never client invention beyond an honest generic); and two coexisting idioms — per-field roles (composable, i18n-friendly, validatable — the dominant choice) vs a per-type template string (Directus `{{ field }}` — more expressive but pushes formatting/locale/escaping into the authored string, harder to validate). Authorship lives with the data-source author, versioned with the schema; a client-side remap, if offered, is a separate override surface, not the default.
