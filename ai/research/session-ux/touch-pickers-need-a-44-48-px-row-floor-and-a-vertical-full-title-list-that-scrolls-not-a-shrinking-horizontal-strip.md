---
title: "A touch picker needs a ~44-48 px row hit-target floor and a vertical full-title list that scrolls, because horizontal strips collapse to unreadable slivers past a low item count"
date: 2026-07-16
topic: session-ux
tags: [touch-targets, mobile, picker-geometry, vertical-tabs, wcag, material, apple-hig]
status: draft
sources: [apple-hig-accessibility, material-accessibility, wcag-target-min, wcag-target-enhanced, nng-touch-target, firefox-vertical-tabs, firefox-bug-597564, tst-docs]
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = interpretation. Skippable. No citations here.
-->

## CLAIMS

- Apple's Human Interface Guidelines specify a minimum hit target of at least 44×44 pt for all touchscreen controls and interactive elements. [apple-hig-accessibility]
- Google Material Design specifies a minimum touch target of 48×48 dp, which is about 9 mm physical regardless of screen size, with a recommended touchscreen target range of 7–10 mm and ≥8 dp of spacing between targets. [material-accessibility]
- WCAG 2.2 Success Criterion 2.5.8 Target Size (Minimum), Level AA, requires pointer targets of at least 24×24 CSS px (with defined exceptions), to help ensure targets can be activated without accidentally activating an adjacent target. [wcag-target-min]
- WCAG 2.2 Success Criterion 2.5.5 Target Size (Enhanced), Level AAA, requires pointer targets of at least 44×44 CSS px (with defined exceptions). [wcag-target-enhanced]
- NN/g recommends interactive elements at least 1 cm × 1 cm to support selection and prevent fat-finger errors, noting average fingertips are 1.6–2 cm wide and the typical thumb impact area averages ~2.5 cm. [nng-touch-target]
- Firefox promotes vertical tabs specifically because they let you see more open tabs and full tab titles at a glance and give a clearer overview than a single horizontal row when many tabs are open. [firefox-vertical-tabs]
- Firefox stops shrinking horizontal tabs at a minimum width and then scrolls the tab strip rather than shrinking tabs into illegibility; a Mozilla bug thread explicitly criticizes Chrome's approach of shrinking tabs "smaller and smaller until they are unidentifiable." [firefox-bug-597564]
- Tree Style Tab's stated rationale for a vertical tree list is that with many tabs it helps to understand the relations between tabs. [tst-docs]

## SOURCES

**apple-hig-accessibility**
URL: https://developer.apple.com/design/human-interface-guidelines/accessibility
Accessed: 2026-07-16
Quote: "Give all touchscreen controls and interactive elements a hit target that measures at least 44x44 pt." (Live page is a JS-rendered SPA; sentence recovered from current page text, corroborated identically by multiple current secondary sources. ~44 pt ≈ 9 mm.)

**material-accessibility**
URL: https://m1.material.io/usability/accessibility.html
Accessed: 2026-07-16
Quote: "Touch targets should be at least 48 x 48 dp." / "A touch target of this size results in a physical size of about 9mm, regardless of screen size." / "The recommended target size for touchscreen elements is 7-10mm." / "In most cases, touch targets should be separated by 8dp of space or more".

**wcag-target-min**
URL: https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html
Accessed: 2026-07-16
Quote: "The size of the target for pointer inputs is at least 24 by 24 CSS pixels, except when:" / "The intent of this success criterion is to help ensure targets can be easily activated without accidentally activating an adjacent target."

**wcag-target-enhanced**
URL: https://www.w3.org/WAI/WCAG22/Understanding/target-size-enhanced.html
Accessed: 2026-07-16
Quote: "The size of the target for pointer inputs is at least 44 by 44 CSS pixels except when:"

**nng-touch-target**
URL: https://www.nngroup.com/articles/touch-target-size/
Accessed: 2026-07-16
Quote: "Interactive elements must be at least 1cm × 1cm (0.4in × 0.4in) to support adequate selection time and prevent fat-finger errors." / "The average person's fingertips are 1.6–2cm (0.6–0.8 in) wide. The impact area of the typical thumb is even larger — an average of 2.5cm (1 inch) wide!"

**firefox-vertical-tabs**
URL: https://www.firefox.com/en-US/features/vertical-tabs/
Accessed: 2026-07-16
Quote: "See more of your open tabs and full tab titles at a glance." / "If you keep a lot of tabs open, vertical tabs give you a clearer overview than a single row."

**firefox-bug-597564**
URL: https://bugzilla.mozilla.org/show_bug.cgi?id=597564
Accessed: 2026-07-16
Quote: "Chrome's approach of making tabs smaller and smaller until they are unidentifiable is kind of ridiculous." (Thread debates the tab min-width floor below which Firefox scrolls rather than shrinks.)

**tst-docs**
URL: https://piro.sakura.ne.jp/xul/_treestyletab.html.en
Accessed: 2026-07-16
Quote: "If you often use many many tabs, it will help your web browsing because you can understand relations of tabs."

## SYNTHESIS

The touch guidance converges on a narrow band and it directly sizes the mobile picker:

- **Row hit-target floor ≈ 44–48 px.** Apple (44 pt), Material (48 dp), WCAG AAA (44 px) and NN/g (~1 cm ≈ 38 px) all land in a 44–48 px window. WCAG's 24 px AA is the *legal* floor, not the craft floor — a full-width picker row should be **≥44 px tall** (matching the existing corpus 44px-touch-floor entry), with ≥8 px between rows so an adjacent-window mis-tap doesn't switch to the wrong context. On a ~50-column / ~360 px-wide phone this means each row spans the full width and the finger targets the whole row, not a glyph.

- **Vertical list, full titles, scroll — never a horizontal strip.** The tab-strip literature is the direct analogy to tmux's status line: a horizontal strip has two failure modes past a low count, shrink-to-unidentifiable (Chrome) or scroll-and-hide (Firefox), both destroying at-a-glance scanning. Firefox's own remedy is to go vertical so full titles stay legible. Tim's mobile pain (the strip + prefix picker being his ONLY nav on ~50 columns) is exactly this failure. The mobile picker should be a full-screen VERTICAL list of full-width rows showing the full label, scrolled — not the compressed status strip.

- **List-length limit per viewport.** At a 44–48 px row + 8 px gap, only ~8–12 rows fit above the fold on a phone before scrolling. With ~27 windows, an unfiltered list is 2–3 screens of scroll. This is the geometric argument that the mobile picker must be **filterable/searchable first** (type-to-narrow), so the visible list is short by the time the thumb reaches for it — reinforcing the search-first conclusion for the cold tail. Pinned hot slots (fixed ordinal rows at the top) give the thumb a stable, no-scroll target for the frequent windows.

- **Front-loaded labels matter more on touch.** A full-width vertical row shows the whole 12–40 char label, but the eye still reads left-first (F-pattern); combined with the label-scent entry, the differentiator must sit at the left edge of each row so a thumb-scan down the list works.
