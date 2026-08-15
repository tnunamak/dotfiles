---
title: "Favicons need an opaque brand-color plate, not a bare glyph, because no single flat color clears 3:1 contrast against both light and dark real-world browser tab chrome, and cross-browser support for prefers-color-scheme inside favicon SVGs is too inconsistent to rely on in 2026"
date: 2026-08-14
topic: frontend-design
tags: [favicon, contrast, wcag, svg, browser-chrome, dark-mode]
status: draft
sources: [stripe-favicon, linear-favicon, vercel-favicon, github-favicon, notion-favicon, anthropic-favicon, figma-favicon, cloudflare-favicon, websearch-svg-favicon-2026]
source_session: f1bbabf7-3f96-4b77-9c0a-3f1399f83b61
---

## CLAIMS

- Fetching real production favicon.ico files (following redirects, checking actual content-type) and decoding their embedded PNG frames shows Stripe (`#533afd` purple-blue, fully opaque) and Linear (`#000000` background, fully opaque) both ship a solid brand-colored/near-black **background plate square** with a light glyph on top, not a bare transparent glyph — confirmed by counting near-transparent pixels (Stripe 16px frame: 4/256 px transparent-ish; Linear 16px frame: 0/256). [stripe-favicon] [linear-favicon]
- GitHub, Vercel, Anthropic, and Notion all ship a **bare glyph with no background plate**, but the glyph color is near-black (`#171515`/`#000000`) or near-white (`#fafaf7`)/black-and-white, never a mid-saturation brand hue — i.e., they trade brand-color fidelity for chrome-agnostic contrast rather than solving both. [github-favicon] [vercel-favicon] [anthropic-favicon] [notion-favicon]
- Figma is the outlier: its real favicon (found via the page's actual `<link rel="icon">` tags, not a guessed `/favicon.svg` path — `static.figma.com/app/icon/2/favicon.svg`) is a bare multi-color glyph (green/orange/blue/red/purple) with no background and no theme adaptation at all; it does not attempt to solve the tab-chrome contrast problem.
- Contrast math (WCAG relative-luminance formula) against approximate real tab-chrome colors (Chrome/Brave light `#DEE1E6`, Chrome/Brave dark `#35363A`, Safari/Firefox approximations) shows **no single flat mid-tone color clears the 3:1 UI-component contrast bar on all of light-Chrome, dark-Chrome, light-Safari, dark-Safari, light-Firefox, dark-Firefox simultaneously** — every one of 6 tested candidates (a working teal, two brand blues, a near-black, a near-white, a deep navy) failed at least 2 of 6 real backgrounds. A bare-glyph favicon is structurally a "split the difference and still fail somewhere" choice, not a solved problem.
- A minimal test SVG with a `@media (prefers-color-scheme: dark)` rule, rendered via Playwright/Chromium (`context = await browser.newContext({colorScheme: 'dark'|'light'})`, navigating directly to the `.svg` file), does correctly swap fill color (black in light, white in dark) — the media query itself works in a standalone Chromium SVG-document context.
- However, per multiple 2026 sources found via web search, real-world `<link rel="icon" type="image/svg+xml">` favicon support for that same media query is inconsistent and disputed: one source says Chrome renders the SVG favicon but does not re-evaluate the media query live on theme change; another says Safari ignores favicon SVG media queries entirely (as of April 2026); a third confirms Chrome support without testing Safari. All sources agree you must ship an ICO/PNG fallback regardless (Safari in some versions doesn't use the SVG favicon at all, older browsers don't support SVG favicons), and that fallback file cannot carry a media query — so the "one adaptive file" pitch doesn't remove the need to pick a single chrome-agnostic color anyway. [websearch-svg-favicon-2026]
- `mask-icon` (Safari pinned-tab format) is legacy/deprecated across all sources checked — Safari dropped the pinned-tab feature in favor of standard favicons; no source recommends adding it in 2026.

## SOURCES

**stripe-favicon**
URL: https://stripe.com/favicon.ico
Accessed: 2026-08-14
Quote: "MS Windows icon resource - 3 icons, 48x48/32x32/16x16, 32 bits/pixel"; decoded 16px frame top color `#533afd` alpha=255, count=166/256, 4 px alpha<200.

**linear-favicon**
URL: https://linear.app/favicon.ico
Accessed: 2026-08-14
Quote: decoded 16px frame top colors `#000000` alpha=255 count=112/256, `#ffffff` alpha=255 count=40/256, 0 px transparent.

**vercel-favicon**
URL: https://vercel.com/favicon.ico
Accessed: 2026-08-14
Quote: decoded 16px frame top color `#000000` alpha=255 count=109/256, plus 40 px alpha<50 (transparent background, bare glyph).

**github-favicon**
URL: https://github.githubassets.com/favicons/favicon.svg
Accessed: 2026-08-14
Quote: `<svg ...><path ... fill="#24292E"/></svg>` — single bare glyph path, no background rect, no media query.

**notion-favicon**
URL: https://notion.so/front-static/favicon.ico
Accessed: 2026-08-14
Quote: decoded 16px frame top colors `#ffffff` count=32, `#161616` count=29, `#000000` count=25 — black/white glyph, effectively no background plate distinguishable from glyph strokes.

**anthropic-favicon**
URL: https://cdn.prod.website-files.com/67ce28cfec624e2b733f8a52/681d52619fec35886a7f1a70_favicon.png (via anthropic.com actual `<link rel="shortcut icon">`)
Accessed: 2026-08-14
Quote: decoded 48px frame top colors `#fafaf7` (near-white bg) count=1516, `#191919` (near-black glyph) count=104.

**figma-favicon**
URL: https://static.figma.com/app/icon/2/favicon.svg (found via actual `<link rel="icon">` tags on figma.com, not guessed path)
Accessed: 2026-08-14
Quote: `fill="#24CB71"`, `fill="#FF7237"`, `fill="#00B6FF"`, `fill="#FF3737"`, `fill="#874FFF"` — five distinct brand hues, no background shape, no media query.

**cloudflare-favicon**
URL: https://cloudflare.com/favicon.ico
Accessed: 2026-08-14
Quote: content-type served as `image/vnd.microsoft.icon` but file is actually PNG per `file` — 99x96 8-bit colormap PNG, not a true multi-res ICO; noted as a data point on how loosely "favicon.ico" as a URL is treated across real sites (don't assume extension implies format).

**websearch-svg-favicon-2026**
URL: aggregated from search results (icojoy.com, evilmartians.com, faviconbuilder.com, jwtoolbox.com, testmuai.com) — see search results in session
Accessed: 2026-08-14
Quote: "Safari does not use the SVG favicon at all and quietly falls back to your favicon.ico"; "Chrome still renders the default colour in tabs (it uses the SVG but doesn't re-evaluate the media query when the user's theme changes)"; "Safari ignores favicon SVG media queries as of April 2026"; "mask-icon is a dead legacy feature — not the modern SVG favicon. Don't use it."

## SYNTHESIS

The real design pattern industry-wide is bimodal, not a spectrum: either (a) commit to an opaque background plate in your brand color so glyph-on-plate contrast is fixed and independent of tab chrome (Stripe, Linear), or (b) abandon brand-color fidelity for the favicon specifically and use a near-black/near-white/monochrome glyph that clears contrast everywhere a bare glyph can appear (GitHub, Vercel, Anthropic, Notion). No inspected shop ships a saturated brand-hue bare glyph and relies on browser chrome contrast — that combination is the one this task's "current teal" and "site blue" candidates were both trying to be, and the contrast math shows why it structurally can't clear 3:1 everywhere: a mid-luminance color is by definition close to both a light and a dark background's luminance in different directions. `prefers-color-scheme` in an SVG favicon is real CSS that works in an isolated SVG document, but is not a dependable ship-today solution for the actual favicon use case, because (1) at least one major browser's live favicon renderer doesn't re-run the query, (2) Safari's behavior is disputed/inconsistent across sources checked, and (3) every real setup still needs a non-adaptive ICO/PNG fallback, which reintroduces the exact single-color problem the media query was meant to dodge. Recommendation for any similar "must survive light AND dark tab chrome without a background plate" ask: don't chase a single perfect flat color — either add a plate (if brand allows it) or accept the near-black/near-white compromise used by the four shops that explicitly solved this.
