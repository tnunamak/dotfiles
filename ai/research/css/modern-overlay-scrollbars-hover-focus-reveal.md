---
title: "Modern docs-site sidebar scrollbars use a CSS-only hover/focus-within reveal (transparent-until-interaction thumb), not scrollbar-width:thin always-visible or a fully-hidden scrollbar"
date: 2026-08-04
topic: css
tags: [scrollbar, accessibility, docs-site, css-only]
status: draft
sources: [stripe-docs-css, mdn-scrollbar-gutter, chrome-scrollbar-styling, roselli-scrollbar-a11y, bailey-custom-scrollbars]
source_session: unknown
---

## CLAIMS

- Stripe's docs site ships a transparent-thumb-until-hover scrollbar with no JS: `::-webkit-scrollbar-thumb{background-color:transparent}` and paints the thumb only on `:hover`. [stripe-docs-css]
- No pure-CSS technique fully replicates macOS's overlay-scrollbar timing (appear-on-scroll, auto-fade-after-idle) across Chrome/Firefox/Safari; that exact behavior is OS/browser-native only. [chrome-scrollbar-styling]
- `:hover`/`:focus-within` + a transition on `scrollbar-color`/`background-color` achieves "invisible at rest, visible on interaction" with zero JS and zero scroll-jank risk. [chrome-scrollbar-styling]
- `scrollbar-gutter` (Baseline 2024) reserves layout space for a *classic* scrollbar to prevent reflow, but is inert for overlay-style/hidden-thumb scrollbars — it only matters on platforms where the browser still renders a classic scrollbar track (e.g. Windows Chrome/Firefox without overlay mode). [mdn-scrollbar-gutter]
- Firefox animates `scrollbar-color` transitions; Chrome/Safari currently swap it instantly, so a real fade in Chromium/WebKit requires the `::-webkit-scrollbar-thumb` background-color transition as a fallback alongside the standard `scrollbar-color` property. [chrome-scrollbar-styling]
- Accessibility specialists (Adrian Roselli, Eric Bailey) argue against hiding scrollbars entirely: touching scrollbar defaults means owning the a11y consequences, including WCAG 1.4.11 non-text contrast on the thumb-vs-track when visible, and hidden scrollbars remove a discoverability affordance for users who don't know to hover. [roselli-scrollbar-a11y] [bailey-custom-scrollbars]
- A bottom fade-mask (`mask-image: linear-gradient` truncating content) is an independent, non-scrollbar affordance that signals "more content below" — it does not by itself compensate for a scrollbar that gives zero indication a panel is scrollable to a user who hasn't started interacting. [roselli-scrollbar-a11y]

## SOURCES

**stripe-docs-css**
URL: https://b.stripecdn.com/docs-statics-srv/assets/docs.ee40288ef4b8d7752cd3.css
Accessed: 2026-08-04
Quote: "::-webkit-scrollbar-thumb{background-color:transparent} ... :hover::-webkit-scrollbar-thumb{background-color:rgba(255,255,255,.2)}"

**mdn-scrollbar-gutter**
URL: https://developer.mozilla.org/en-US/docs/Web/CSS/scrollbar-gutter
Accessed: 2026-08-04

**chrome-scrollbar-styling**
URL: https://developer.chrome.com/docs/css-ui/scrollbar-styling
Accessed: 2026-08-04

**roselli-scrollbar-a11y**
URL: https://adrianroselli.com/2019/01/baseline-rules-for-scrollbar-usability.html
Accessed: 2026-08-04

**bailey-custom-scrollbars**
URL: https://ericwbailey.website/published/dont-use-custom-css-scrollbars/
Accessed: 2026-08-04

## SYNTHESIS

For a docs-site sidebar/TOC rail: use `scrollbar-width: thin` + `scrollbar-color: transparent transparent` at rest, swap to a visible thumb color on `:hover` AND `:focus-within` (not hover alone — keyboard users tabbing into the rail need the same cue), with matching `::-webkit-scrollbar-thumb` rules for Chromium/WebKit since `scrollbar-color` transitions don't animate there. Do not go fully invisible (`scrollbar-width: none` with nothing else) — that fails the discoverability argument for users who never hover/focus the region. A bottom fade-mask is a good complementary affordance but is not a substitute for the interactive reveal; keep both. `scrollbar-gutter: stable` is a cheap defensive addition but is not the core fix and has no effect once the thumb-hiding trick is in play on overlay-scrollbar platforms.

Was not able to independently verify react.dev / Linear / Vercel docs sidebar scrollbar behavior via WebFetch (renders CSS/JS behavior invisibly to a markdown-only fetch) — only the Stripe finding is source-confirmed. Treat "this is the common modern docs pattern" beyond Stripe as informed pattern-matching, not confirmed observation.
