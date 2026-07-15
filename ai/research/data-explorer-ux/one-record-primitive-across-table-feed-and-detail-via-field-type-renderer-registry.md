---
title: "A record renders identically across table/feed/detail via a field-type cell-renderer registry; the view is only a layout config, never a second formatting path"
date: 2026-06-23
topic: data-explorer-ux
tags: [design-system, data-table, cell-renderers, notion, airtable, primer, component-architecture]
status: draft
sources: [notion-views-api, airtable-field-types, airtable-record-detail, primer-datatable, primer-actionlist, linear-redesign, stripe-sail, pragmatic-stripe]
---

<!-- Extracted from a pdpp record-components doc; the pdpp file-shape recommendation discarded, patterns kept. -->

## CLAIMS

- Notion's Views API models a `view` as only a filter/sort/display config over a shared data source; how a property renders is keyed by property TYPE and travels with the field across table/board/gallery — `status_show_as`, `date_format`/`time_format`, and `card_property_width_mode` are per-type display config, so a date can't render two ways across views. [notion-views-api]
- In Notion, surface-specific config is separate from the shared renderer: `width` (table only), `frozen_column_index`, `wrap_cells` (table chrome) vs `group_by`, `cover`, `card_layout` (board/gallery chrome). [notion-views-api]
- Airtable makes a field's TYPE the single source of truth for how a value is displayed, reused across grid/gallery/kanban/timeline; the record-detail layout is built from the SAME table fields (deleting a field from detail "removes it from the record detail page not from the underlying source table"), and a single-select can switch appearance (Field/Stepper/List) without changing the underlying field. [airtable-field-types]
- GitHub Primer's `DataTable` takes `data` + `columns[]` where each column is `{ header, field?, renderCell? }`: `field` gives the default renderer, `renderCell: (data) => ReactNode` overrides it, `rowHeader` marks the identity column, and `sortBy` lives on the column def (not the cell) — so sorting is separable from rendering. [primer-datatable]
- Primer's `ActionList.Item` is a single compound row primitive with named slots (`LeadingVisual`, `TrailingVisual`, `Description`), reused inside `ActionMenu` etc.; both `DataTable` and `ActionList` sit on the `useSlots` mechanism that matches children against `{slot-name: Component}`. [primer-actionlist]
- Linear uses "a set of structured layouts" for list/board/timeline/split/fullscreen and validated the redesign "by type of view" to ensure every decision works in all cases (corroborates the discipline; Linear does not publish the component API). [linear-redesign]
- Stripe's Sail design system is the single build path — components like `ListPage` are reused across product, internal-tool, and embedded (Connect) surfaces — and Stripe frames "tight coupling between disparate components" as the failure state whose fix is the shared system (Stripe does not publish Sail's component API). [stripe-sail]

## SOURCES

**notion-views-api**
URL: https://developers.notion.com/guides/data-apis/working-with-views
Accessed: 2026-06-23
Quote: "a view defines how pages in [a] data source are filtered, sorted, and displayed"

**airtable-field-types**
URL: https://support.airtable.com/docs/supported-field-types-in-airtable-overview
Accessed: 2026-06-23

**airtable-record-detail**
URL: https://support.airtable.com/docs/airtable-interface-layout-record-detail
Accessed: 2026-06-23

**primer-datatable**
URL: https://primer.style/components/data-table
Accessed: 2026-06-23
Quote: "renderCell: provide a custom component or render prop to render the data for this column in a row"

**primer-actionlist**
URL: https://primer.style/components/action-list
Accessed: 2026-06-23

**linear-redesign**
URL: https://linear.app/now/how-we-redesigned-the-linear-ui
Accessed: 2026-06-23
Quote: "Linear relies on a set of structured layouts… list, board, timeline, split, and fullscreen."

**stripe-sail**
URL: https://stripe.dev/blog/migrating-to-typescript
Accessed: 2026-06-23
Quote: "Our JavaScript projects make heavy use of Sail, a shared design system."

**pragmatic-stripe**
URL: https://newsletter.pragmaticengineer.com/p/stripe-part-2
Accessed: 2026-06-23

## SYNTHESIS

Two products publish the mechanism (Airtable field types, Notion property-type config), one publishes the code API (Primer `DataTable`), and two publish the discipline (Linear, Stripe). They converge on: shared headless record model → field-type cell-renderer registry → presentational slotted row/cell primitive → consumed by every surface's thin layout config. The single record model is `{ identity, title, fields: Field[] }`; the registry is `renderers[field.type](value, ctx)` — the single source of truth that makes "a record can't render two different ways" structurally true. The surface owns only chrome: table = column defs + `sortBy` + density + frozen identity column; feed = day-grouping/time ordering; peek/detail = which fields are visible/ordered/sized (same renderers, stacked). Named anti-patterns: two parallel render paths that drift; a detail view re-implementing its own field formatting; sorting/density logic leaking into the cell renderer; a "row" that's secretly a `<tr>`/`<td>` and can't live in a feed; and dispatching on field NAME instead of declared field TYPE. (Source strength: Notion/Airtable/Primer primary with published mechanism; Linear/Stripe corroborate discipline but publish no cell-primitive API.)
