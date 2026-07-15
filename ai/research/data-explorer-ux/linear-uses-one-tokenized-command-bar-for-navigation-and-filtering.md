---
title: "Linear uses one tokenized command bar for navigation and filtering — value-first autocomplete, structured filter chips, negation by operator-mutation, and OR hidden behind Advanced"
date: 2026-06-23
topic: data-explorer-ux
tags: [command-palette, filters, filter-chips, autocomplete, keyboard-ux, visual-system, linear]
status: draft
sources: [linear-filters, linear-search, linear-redesign-2, linear-design-reset, linear-changelog-2024, refero-linear, typio-inter, cmdk-patterns, productivitystack-linear]
---

## CLAIMS

- Linear does not place a separate filter bar alongside search: the command menu (`/`) handles free-text search, `F` opens the filter picker from the same surface, and active-filter chips appear in the header bar below the single entry point — the user never operates two input zones. [linear-filters] [linear-search]
- Filter autocomplete resolves the property from the value: typing "Andreas" surfaces "Assignee is Andreas"; typing "High" surfaces "Priority is High" — no intermediate step of first selecting the property. [linear-filters]
- In the search/command menu, a single character + Space scopes results to an entity type: `i ` = issues, `p ` = projects, `u ` = users, `t ` = teams, `l ` = labels, `f ` = favorites, `d ` = documents; the scope label is shown contextually in the UI, not in a help page. [linear-search]
- Each filter chip is a structured token with three independently clickable zones — `[property] [operator] [value(s)]`. The operator zone opens a popover to switch is/is-not; the value zone re-opens a picker; the property is intentionally not re-editable (remove and re-add instead). [linear-filters]
- The operator adapts to value cardinality automatically: adding a second value changes `is` to `is either of`; removing it reverts. Operator vocabulary: `is / is not` (single), `is either of / is not` (multi), `includes any / all / neither / either / none` (labels/links), `before / after` (dates). Inapplicable operators are never shown. [linear-filters]
- Negation is a one-click toggle on an existing chip's operator (`is` → `is not`, `includes any` → `includes none`); there is no separate exclude input and no NOT-prefix syntax in the chip input. [linear-filters]
- AND is the implicit default across all chips; explicit OR and nested groups live only in an "Advanced filter" builder reached from the filter menu — OR is never surfaced on the default bar. [linear-filters]
- The filter picker shows a count of matching issues next to each filterable property and value, so the user can see a filter's impact before applying it. [linear-filters]
- `Option/Alt + V` saves the current filter combination as a named custom view that appears in the sidebar, promoting a filter query to a first-class navigation destination. [linear-search]
- Typing `@status`, `@assignee`, `@team` in global search auto-creates and applies a filter chip as the mention is typed. [linear-search]
- Row hierarchy leads with the issue title at full weight; status dot, priority glyph, assignee avatar, labels, ID (Berkeley Mono), and relative timestamp are placed after it at reduced visual weight, so the left-edge title column is the scan axis. [refero-linear]
- Linear's redesign uses Inter Variable at weight 510 (between Regular and Medium) as the UI emphasis weight rather than 600/700, producing hierarchy through precision rather than heaviness; weight 300 appears only on large display headings. [linear-redesign-2] [refero-linear] [typio-inter]
- Berkeley Mono is used exclusively for technical identifiers (issue IDs like ENG-2703, keyboard shortcuts, code references) and never for prose or UI labels — its presence signals "precise identifier." [refero-linear]
- Cards/surfaces express elevation via a 1px inset border (`#23252a`) plus an `rgba(0,0,0,0.4)` drop shadow, never via fill-color change alone; the accent color is rationed to one primary action per screen. [refero-linear] [linear-redesign-2]
- The color system is generated in LCH (perceptually uniform) color space rather than HSL, enabling consistent dark/light theme generation. [linear-redesign-2] [refero-linear]
- Dark-theme tokens (documented by a third-party design-system extract): canvas `#08090a`, card `#0f1011`, row `#161718`, hairline border `#23252a`, primary text `#f7f8f8`, secondary text `#8a8f98`, muted `#62666d`, indigo accent `#5e6ad2`, acid-lime primary action `#e4f222`. [refero-linear]
- Spacing is compact on a 4px base: radii 2px (badges) / 6px (inputs, buttons) / 12px (cards); element gap 8-12px; card padding 24-32px; teardowns estimate 36-44px issue-row height in compact mode. [refero-linear]
- Linear treats its keyboard/pointer command surface as desktop-first and ships a separate, more limited mobile app rather than replicating the command palette on touch — a deliberate choice to not compromise the desktop UX for touch parity. [productivitystack-linear]

## SOURCES

**linear-filters**
URL: https://linear.app/docs/filters
Accessed: 2026-06-23
Quote: "Official source for filter categories, operators, chip behavior, and advanced filter AND/OR."

**linear-search**
URL: https://linear.app/docs/search
Accessed: 2026-06-23
Quote: "Official source for shortcut modes, prefix narrowing, @ mention filters, sort behavior."

**linear-redesign-2**
URL: https://linear.app/now/how-we-redesigned-the-linear-ui
Accessed: 2026-06-23
Quote: "Design team retrospective on hierarchy, LCH colors, sidebar/header changes (2024)."

**linear-design-reset**
URL: https://linear.app/blog/a-design-reset
Accessed: 2026-06-23
Quote: "Co-founder Karri Saarinen on the redesign rationale, inverted-L chrome, and concept exploration process."

**linear-changelog-2024**
URL: https://linear.app/changelog/2024-03-20-new-linear-ui
Accessed: 2026-06-23

**refero-linear**
URL: https://styles.refero.design/style/90ce5883-bb24-4466-93f7-801cd617b0d1
Accessed: 2026-06-23
Quote: "Third-party documented design tokens: Inter Variable weights/sizes/tracking, Berkeley Mono role, color values, spacing table, elevation approach."

**typio-inter**
URL: https://typ.io/s/2jmp
Accessed: 2026-06-23
Quote: "Typography specimen of Inter Variable as deployed on linear.app."

**cmdk-patterns**
URL: https://medium.com/design-bootcamp/command-palette-ux-patterns-1-d6b6e68f30c1
Accessed: 2026-06-23

**productivitystack-linear**
URL: https://productivitystack.io/guides/linear-app-complete-guide/
Accessed: 2026-06-23
Quote: "2026 usage guide confirming keyboard-first, command-palette-centered workflow."

## SYNTHESIS

Linear's central move is collapsing navigation, search, and filtering into one tokenized command surface instead of separate input zones. Two design decisions carry most of the value: (1) value-first autocomplete — resolving the property from the typed value removes the "which field is this?" step that most filter UIs impose; and (2) the structured chip — `[property][operator][value]` with independently clickable zones, an operator that mutates with cardinality, and negation-by-operator-mutation — which keeps the creation flow positive while making negation and multi-select discoverable in-context.

The deliberate constraints are as instructive as the affordances: property is not editable in place (remove/re-add preserves an unambiguous chip identity), OR is progressively disclosed behind Advanced (AND-only serves ~95% of queries), and there is no raw query-syntax text box on the main bar (the picker *is* the query builder; syntax belongs to API/CLI). Match counts in the picker convert filtering from guesswork into navigation. On the visual system, the transferable principles are hierarchy through weight-precision (510, not bold) and color, elevation via border+shadow not fill, one accent rationed per screen, monospace reserved strictly as a semantic signal for machine identifiers, and perceptual (LCH) color for any programmatic theme generation. Linear's mobile stance — desktop-first command surface, simplified separate mobile app — is a deliberate constraint and is explicitly *not* the model to copy for a mobile-primary surface.
