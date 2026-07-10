---
title: "Preventing mobile keyboard layout shift on a full-viewport (100dvh) video/stream viewer requires layering interactive-widget=overlays-content, the VirtualKeyboard API, and window.visualViewport as an iOS Safari fallback — dvh alone does not solve it"
date: 2026-07-10
topic: remote-browser
tags: [mobile-keyboard, visual-viewport, virtualkeyboard-api, dvh, ios-safari, layout-shift, viewport-meta]
status: draft
sources: [w3c-css-viewport-1, chrome-viewport-resize-blog, mdn-viewport-meta, mdn-bcd-issue-29011, mdn-virtualkeyboard-api, mdn-virtualkeyboard-overlayscontent, mdn-bcd-virtualkeyboard-json, webkit-bugzilla-230225, zouhir-safari-vk-blog, mdn-visualviewport, mdn-visualviewport-resize-event, tkte-ch-visual-viewport, wicg-visual-viewport-issue-79, w3c-css-values-4-dynamic-viewport, chromium-issue-40891557, mdn-css-length-viewport-units, webdev-viewport-units, webkit-standards-positions-65, webkit-bugzilla-153224, webkit-bugzilla-202120, webkit-bugzilla-176205, webkit-bugzilla-265578, chromium-issue-40924170]
---

## CLAIMS

- The `interactive-widget` viewport meta value has three states: `resizes-visual` (default — resizes only the visual viewport, not the initial/layout viewport), `resizes-content` (resizes both initial and visual viewport, since visual viewport size derives from initial viewport), and `overlays-content` (must not resize either viewport; performs the same steps as `VirtualKeyboard.overlaysContent = true`). [w3c-css-viewport-1]
- Chrome supports `interactive-widget` from Chrome 108+; it is explicitly NOT supported on Chrome for iOS/iPadOS because those builds run WebKit, not Blink. [chrome-viewport-resize-blog]
- Firefox supports `interactive-widget` from version 132+. [mdn-viewport-meta]
- Safari (all platforms, including iOS) does not support any value of `interactive-widget`. An MDN browser-compat-data bug (filed Feb 2026) had mistakenly shown ambiguous support for the umbrella feature on Safari/iOS while showing no support for each individual value; this was corrected to explicitly show no support. [mdn-bcd-issue-29011]
- WebKit's own tracking bug for implementing `interactive-widget` (Bugzilla #259770) and its standards-positions discussion (#65, "Needs position") remain open/unresolved; no 2025–2026 WebKit release notes mention it shipping. [webkit-bugzilla-230225][webkit-standards-positions-65]
- The VirtualKeyboard API (`navigator.virtualKeyboard`) lets a page opt out of automatic keyboard-triggered viewport resizing via `overlaysContent = true`, after which the keyboard overlays page content instead of shrinking the viewport, and the page adapts layout itself. [mdn-virtualkeyboard-api][mdn-virtualkeyboard-overlayscontent]
- The API exposes a `geometrychange` event (fires on keyboard show/hide with `event.target.boundingRect`) and CSS environment variables `env(keyboard-inset-top|right|bottom|left|width|height)` giving the exact keyboard rectangle. [mdn-virtualkeyboard-overlayscontent]
- MDN explicitly marks the VirtualKeyboard API as NOT Baseline "because it does not work in some of the most widely-used browsers." [mdn-virtualkeyboard-api]
- Per MDN's raw browser-compat-data (`api/VirtualKeyboard.json`), Chrome supports it from version 94 (Chrome Android, Edge, WebView Android mirror that support); Firefox and Safari (desktop and iOS) both have `version_added: false` — explicitly unsupported. [mdn-bcd-virtualkeyboard-json]
- WebKit's tracking bug for implementing the VirtualKeyboard API (Bugzilla #230225) remains open. [webkit-bugzilla-230225]
- `window.visualViewport` (the VisualViewport API) is Baseline "Widely available," supported across browsers since August 2021, including Safari/iOS. It exposes `height`, `offsetLeft`, `offsetTop`, and `resize`/`scroll` events. [mdn-visualviewport][mdn-visualviewport-resize-event]
- On iOS Safari, the virtual keyboard resizes only the visual viewport, not the layout viewport (initial containing block) — the opposite of Android Chrome/Firefox, which (in `resizes-content` mode) resize the initial containing block. This is stated by WebKit's own standards-positions repo. [webkit-standards-positions-65]
- iOS Safari does not support `interactive-widget` (confirmed by MDN BCD correction) or the VirtualKeyboard API (confirmed by MDN BCD raw data), making `visualViewport` the only cross-engine signal available for keyboard-open detection on iOS. [mdn-bcd-issue-29011][mdn-bcd-virtualkeyboard-json]
- WICG's visual-viewport spec repo has an open issue stating Safari 15 did not trigger a `resize` event when the virtual keyboard appeared — evidence the API is not perfectly reliable even where nominally supported. [wicg-visual-viewport-issue-79]
- Per the W3C CSS Values and Units Level 4 spec: large (`lv*`)/default (`v*`) viewport units assume dynamically-expanding UA interfaces (e.g. browser toolbars) are retracted; small (`sv*`) units assume they're expanded; dynamic (`dv*`) units track the UA interface state live. [w3c-css-values-4-dynamic-viewport]
- The same spec explicitly states UAs "may have some dynamically-shown interfaces that intentionally overlay content and do not cause any shifts in layout ... (Typically on-screen keyboards will fit into this category.)" — i.e., per spec, the on-screen keyboard is by default NOT one of the things `dvh`/`svh`/`lvh` are defined to track. [w3c-css-values-4-dynamic-viewport]
- A Chromium bug thread corroborates this: "the on-screen keyboard is not considered part of the UA UI, and therefore it does not affect the size of the viewport units ... it's expected for Chrome not to adjust the sizes of the svh/dvh/lvh/vh units when the Virtual Keyboard is shown." [chromium-issue-40891557]
- `100dvh` visibly reflowing when the keyboard opens happens because the browser is resizing the *initial viewport itself* (e.g., under `interactive-widget=resizes-content`, or a browser's pre-opt-in default), and `dvh` recomputes against that now-smaller initial viewport — not because `dvh` has special keyboard-tracking logic. [w3c-css-viewport-1]
- MDN cautions that dynamic viewport units are "not stable, even when the viewport itself is unchanged," and that using them can "cause the content to resize while a user is scrolling" with a UI/performance cost — small (`svh`) and large (`lvh`) units are fixed/stable unless the viewport itself is resized. [mdn-css-length-viewport-units]
- web.dev: "When the dynamic toolbars are expanded, the dynamic viewport is equal to the size of the small viewport. When the dynamic toolbars are retracted, the dynamic viewport is equal to the size of the large viewport." [webdev-viewport-units]
- iOS Safari has multiple long-standing, still-open WebKit bugs describing `position: fixed`/`sticky` elements misbehaving while the virtual keyboard is open: tapping an input inside a `position: fixed` container scrolls to the top of the page (Bugzilla #153224); `position: sticky` fails to pin to the bottom of the screen with the keyboard open (Bugzilla #202120); no built-in way to account for virtual keyboard height on iOS WebKit (Bugzilla #176205); visual viewport height updates late when Safari UI is expanded (Bugzilla #265578). [webkit-bugzilla-153224][webkit-bugzilla-202120][webkit-bugzilla-176205][webkit-bugzilla-265578]
- A Chromium bug (#40924170) documents `dvh`/`innerHeight` going stale after keyboard close until the next tap — a reliability caveat even on the Chromium side. [chromium-issue-40924170]

## SOURCES

**w3c-css-viewport-1**
URL: https://www.w3.org/TR/css-viewport-1/
Accessed: 2026-07-10
Quote: "overlays-content: Interactive UI widgets MUST NOT resize the initial viewport nor the visual viewport. The user agent must perform the same steps as when VirtualKeyboard.overlaysContent is set to true." / "resizes-content: Interactive UI widgets MUST resize the initial viewport by the interactive widget. Since the visual viewport's size is derived from the initial viewport, resizes-content will cause a resize of both the initial and visual viewports." / "resizes-visual: Interactive UI widgets MUST resize the visual viewport but MUST NOT resize the initial viewport."

**chrome-viewport-resize-blog**
URL: https://developer.chrome.com/blog/viewport-resize-behavior
Accessed: 2026-07-10 (page marked "Last updated 2022-10-28 UTC")
Quote: "Note that this meta tag extension is only supported by Chrome 108 and up at the time of writing. Support excludes Chrome on iOS and iPadOS, as these versions are powered by Apple's WebKit instead of Chrome's Blink rendering engine."

**mdn-viewport-meta**
URL: https://developer.mozilla.org/en-US/docs/Web/HTML/Guides/Viewport_meta_element
Accessed: 2026-07-10
Quote: "resizes-visual: The visual viewport gets resized by the interactive widget. This is the default." / "overlays-content: Neither the viewport nor the visual viewport gets resized by the interactive widget."

**mdn-bcd-issue-29011**
URL: https://github.com/mdn/browser-compat-data/issues/29011
Accessed: 2026-07-10
Quote: "The table claims that Safari/WebView on iOS supports content=\"interactive-widget=[value]\", but for each value that it may have, the table says there is no support." (resolved via PR #29064 by correcting the data to show no support)

**mdn-virtualkeyboard-api**
URL: https://developer.mozilla.org/en-US/docs/Web/API/VirtualKeyboard_API
Accessed: 2026-07-10 (page "last modified on Nov 6, 2025")
Quote: "The VirtualKeyboard API provides developers control over the layout of their applications when the on-screen virtual keyboard appears and disappears on devices such as tablets, mobile phones, or other devices where a hardware keyboard may not be available." / "This feature is not Baseline because it does not work in some of the most widely-used browsers."

**mdn-virtualkeyboard-overlayscontent**
URL: https://developer.mozilla.org/en-US/docs/Web/API/VirtualKeyboard/overlaysContent
Accessed: 2026-07-10 (page "Document last modified: 2023-10-30")
Quote: "If the overlaysContent property is set to true, the browser no longer resizes the viewport when the virtual keyboard appears. The virtual keyboard instead overlays the content of the web page, and you can adapt the page layout as appropriate using the Virtual Keyboard API and your own custom CSS and JavaScript." / "The VirtualKeyboard API also exposes the following CSS environment variables: keyboard-inset-top, keyboard-inset-right, keyboard-inset-bottom, keyboard-inset-left, keyboard-inset-width, and keyboard-inset-height."

**mdn-bcd-virtualkeyboard-json**
URL: https://github.com/mdn/browser-compat-data/blob/main/api/VirtualKeyboard.json (raw compat data, fetched directly)
Accessed: 2026-07-10
Quote: Chrome `"version_added": "94"`; Chrome Android/Edge/WebView Android `"mirror"` Chrome; Firefox `"version_added": false`; Safari `"version_added": false`; Safari iOS `"mirror"` Safari.

**webkit-bugzilla-230225**
URL: https://bugs.webkit.org/show_bug.cgi?id=230225
Accessed: 2026-07-10
Quote: "Implement the VirtualKeyboard API" (status: open/unresolved as of access date)

**zouhir-safari-vk-blog**
URL: (blog post, zouhir.org) — secondary source, corroborating only
Accessed: 2026-07-10 (post dated 2026-03-15)
Quote: "Safari does not support the Virtual Keyboard API at all — no navigator.virtualKeyboard, no geometrychange, no CSS environment variables. Six years after the spec was published, WebKit hasn't shipped it."

**mdn-visualviewport**
URL: https://developer.mozilla.org/en-US/docs/Web/API/VisualViewport
Accessed: 2026-07-10 (page "last modified on Jun 2, 2026")
Quote: "The VisualViewport interface of the CSSOM view API represents the visual viewport for a given window." Baseline status: "Widely available — This feature is well established and works across many devices and browser versions. It's been available across browsers since August 2021."

**mdn-visualviewport-resize-event**
URL: https://developer.mozilla.org/en-US/docs/Web/API/VisualViewport/resize_event
Accessed: 2026-07-10
Quote: The resize event "is fired when the visual viewport is resized, allowing you to position elements relative to the visual viewport as it is zoomed, which would normally be anchored to the layout viewport."

**tkte-ch-visual-viewport**
URL: https://www.tkte.ch/ (engineering blog covering Safari 13's VisualViewport rollout) — secondary source
Accessed: 2026-07-10
Quote: "When focusing an input, the Visual Viewport shrinks as the OSK gets shown, and if the input would be obscured by the OSK, browsers offset the Visual Viewport against the Layout Viewport so that the input remains in view." / "In Safari on iOS, as the keyboard gets shown, the Layout Viewport remains the same size but the Visual Viewport shrinks... Safari offsets the Layout Viewport so that the focussed content remains in view."

**wicg-visual-viewport-issue-79**
URL: https://github.com/WICG/visual-viewport/issues/79
Accessed: 2026-07-10
Quote: "Safari 15 does not trigger a resize event when the virtual keyboard is coming up"

**w3c-css-values-4-dynamic-viewport**
URL: https://www.w3.org/TR/css-values-4/#dynamic-viewport-size
Accessed: 2026-07-10
Quote: "The large viewport-percentage units (lv*) and default viewport-percentage units (v*) are defined with respect to the large viewport size: the viewport sized assuming any UA interfaces that are dynamically expanded and retracted to be retracted." / "UAs may have some dynamically-shown interfaces that intentionally overlay content and do not cause any shifts in layout—and therefore have no effect on any of the viewport-percentage lengths. (Typically on-screen keyboards will fit into this category.)"

**chromium-issue-40891557**
URL: https://issues.chromium.org/issues/40891557 (Chromium issue tracker)
Accessed: 2026-07-10
Quote: "the on-screen keyboard is not considered part of the UA UI, and therefore it does not affect the size of the viewport units ... it's expected for Chrome not to adjust the sizes of the svh/dvh/lvh/vh units when the Virtual Keyboard is shown."

**mdn-css-length-viewport-units**
URL: https://developer.mozilla.org/en-US/docs/Web/CSS/length (viewport-percentage units section)
Accessed: 2026-07-10
Quote: "The sizes of the [small/large] viewport-percentage units are fixed, and therefore stable, unless the viewport itself is resized." / "The sizes of the dynamic viewport-percentage units are not stable, even when the viewport itself is unchanged" with caution that using them "can cause the content to resize while a user is scrolling a page."

**webdev-viewport-units**
URL: https://web.dev/blog/viewport-units
Accessed: 2026-07-10 (page "Last updated 2022-11-29 UTC", author Bramus)
Quote: "When the dynamic toolbars are expanded, the dynamic viewport is equal to the size of the small viewport. When the dynamic toolbars are retracted, the dynamic viewport is equal to the size of the large viewport."

**webkit-standards-positions-65**
URL: https://github.com/WebKit/standards-positions/issues/65
Accessed: 2026-07-10
Quote: "the virtual keyboard on Safari iOS currently resizes only the visual viewport without affecting page layout, while on Android Chrome and Firefox it resizes the initial-containing-block" (issue status: "Needs position", opened Sept 2022)

**webkit-bugzilla-153224**
URL: https://bugs.webkit.org/show_bug.cgi?id=153224
Accessed: 2026-07-10
Quote: "Tapping into an <input> within a position:fixed element scrolls to the top of the page"

**webkit-bugzilla-202120**
URL: https://bugs.webkit.org/show_bug.cgi?id=202120
Accessed: 2026-07-10
Quote: "CSS position: sticky does not pin element to bottom of screen when virtual keyboard is open"

**webkit-bugzilla-176205**
URL: https://bugs.webkit.org/show_bug.cgi?id=176205
Accessed: 2026-07-10
Quote: "On webkit ios there is [no] way for accounting for virtual keyboard height"

**webkit-bugzilla-265578**
URL: https://bugs.webkit.org/show_bug.cgi?id=265578
Accessed: 2026-07-10
Quote: "Visual viewport height updated late when Safari UI is expanded"

**chromium-issue-40924170**
URL: https://issues.chromium.org/issues/40924170
Accessed: 2026-07-10
Quote: (bug report) dvh/innerHeight can go stale after keyboard close until the next tap/interaction.

## SYNTHESIS

For a full-viewport (100dvh) modal video/stream viewer that must not reflow when a user focuses an input and the on-screen keyboard opens, there is no single API that covers both major engines — Chromium and WebKit have taken structurally different approaches, and the right fix is a layered stack, feature-detected, not a single CSS or JS trick:

**Recommended stack, ranked:**

1. **Base CSS: switch the viewer's full-screen height from `100dvh` to `100svh` (or `100lvh`).** Per spec, the on-screen keyboard is explicitly *not* one of the things dynamic viewport units are defined to track by default — `dvh` exists to handle browser-chrome retraction (URL bar hide/show), a different problem. `100dvh` reflowing on keyboard-open is actually a side effect of the browser resizing the *initial viewport itself* (old Android Chrome default, or explicit `resizes-content`), not `dvh`-specific keyboard awareness. `svh`/`lvh` are stable regardless of chrome state and won't move once painted.

2. **Add `<meta name="viewport" content="...,interactive-widget=overlays-content">` unconditionally.** Zero cost — ignored on unsupported browsers (falls back to default `resizes-visual`), and on Chrome 108+/Firefox 132+ it prevents any viewport resize at all when the keyboard opens, which is exactly the desired "keyboard overlays, layout stable" behavior. This is the single highest-leverage line for the majority of Android traffic.

3. **Layer `navigator.virtualKeyboard.overlaysContent = true` in JS (feature-detected with `"virtualKeyboard" in navigator`).** Redundant with #2 on the same Chromium engines for the core overlay behavior, but unlocks `env(keyboard-inset-bottom)` and the `geometrychange` event — needed if you want to pad an input bar by the exact keyboard height rather than just letting the keyboard cover whatever's underneath it.

4. **For iOS Safari — which supports neither `interactive-widget` nor the VirtualKeyboard API — use `window.visualViewport` as the fallback and as a universal cross-check.** Listen for `resize`/`scroll` on `visualViewport`, drive a CSS custom property (e.g. `--vvh`) from `visualViewport.height`, and use that only for the elements that truly need keyboard-aware repositioning (e.g., an input bar), not the whole viewer shell — the viewer shell should already be stable via `svh`/`lvh`. This is architecturally necessary because iOS Safari shrinks only the *visual* viewport and scrolls/offsets the layout viewport underneath it to keep the focused input visible — it never resizes the layout viewport the way Android Chrome's older modes did, so CSS viewport units alone give no signal there at all.

5. **Avoid anchoring input bars with raw `position: fixed; bottom: 0`.** iOS Safari has multiple long-standing, still-open WebKit bugs where `position: fixed`/`sticky` elements misbehave while the keyboard is open (scroll-to-top on focus, failure to pin to bottom). Compute the input bar's position from `visualViewport.height + visualViewport.offsetTop` in JS instead of trusting fixed positioning to hold still.

**Why not just `dvh` + `window.resize`:** this is the naive path that reproduces the exact bug in the prompt. `window`'s `resize` event only fires when the layout viewport itself changes (browser/mode dependent), giving no signal at all on iOS Safari, and even on Chromium there's a documented staleness bug where `dvh`/`innerHeight` can lag after the keyboard closes.

**Confidence caveat carried over from research:** the claim "under Chrome's current `resizes-visual` default, `100dvh` should not reflow for the keyboard" is a defensible inference from combining the CSS Viewport Module spec text with the Chrome blog post, not something one primary source states outright in so many words — verify on a real Android/Chrome device before treating it as certain in an implementation. Everything else above (interactive-widget support matrix, VirtualKeyboard API support matrix, visualViewport Baseline status, iOS Safari's visual-viewport-only resize behavior, and the open position:fixed bugs) is grounded in primary spec text, vendor docs, or vendor-maintained bug trackers.
