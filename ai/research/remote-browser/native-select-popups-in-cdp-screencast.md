---
title: "CDP screencasts omit native select popups, while Chromium customizable selects provide a constrained opt-in page-painted alternative"
date: 2026-07-15
topic: remote-browser
tags: [cdp, screencast, chromium, select, browser-streaming, css]
status: draft
sources: [cdp-page-screencast, chromium-customizable-select, mdn-customizable-select, neko-readme, browserless-select, puppeteer-select, local-cdp-experiment]
source_session: 019d2610-c519-7b42-a2d5-f1056474daf8
---

## CLAIMS

- `Page.startScreencast` documents only image encoding, image-size, and frame-sampling parameters; it has no documented control for changing how native form pickers are rendered. [cdp-page-screencast]
- Chromium's `appearance: base-select` places a `<select>` into a configurable/styleable rendering state, including its `::picker(select)` pseudo-element. [chromium-customizable-select]
- Chrome warns that customizable-select parser changes can break existing websites, and MDN reports limited browser support plus possible framework/SSR hydration failures. [chromium-customizable-select] [mdn-customizable-select]
- n.eko streams a desktop in its container over WebRTC, which is an architecture that can include browser/OS chrome rather than only CDP page frames. [neko-readme]
- Browserless and Puppeteer expose APIs that select option values directly and fire the resulting page events; these automation APIs bypass the need to visually operate a native popup. [browserless-select] [puppeteer-select]
- In a local Patchright Chromium 1.61.1 reproduction, a clicked ordinary native `<select>` produced a `Page.startScreencast` frame containing only the focused control; adding `appearance: base-select` to both the select and `::picker(select)` produced a frame containing its three option rows. [local-cdp-experiment]
- In the same local browser, a `style-src 'self'` CSP prevented the injected inline stylesheet from applying (`getComputedStyle(select).appearance` remained `auto`). [local-cdp-experiment]

## SOURCES

**cdp-page-screencast**
URL: https://chromedevtools.github.io/devtools-protocol/tot/Page/#method-startScreencast
Accessed: 2026-07-15
Quote: "Starts sending each frame using the screencastFrame event." The documented parameters are `format`, `quality`, `maxWidth`, `maxHeight`, and `everyNthFrame`.

**chromium-customizable-select**
URL: https://developer.chrome.com/blog/a-customizable-select
Accessed: 2026-07-15
Quote: "A new CSS property `appearance: base-select` that puts the `<select>` element into a new, configurable and styleable state"; "There's risk in breaking existing websites with customizable select, due to the parser changes."

**mdn-customizable-select**
URL: https://developer.mozilla.org/en-US/docs/Learn_web_development/Extensions/Forms/Customizable_select
Accessed: 2026-07-15
Quote: "The CSS and HTML features demonstrated in this article currently have limited browser support" and "Some JavaScript frameworks block these features; in others, they cause hydration failures when Server-Side Rendering (SSR) is enabled."

**neko-readme**
URL: https://github.com/m1k1o/neko
Accessed: 2026-07-15
Quote: "This app uses WebRTC to stream a desktop inside of a docker container."

**browserless-select**
URL: https://docs.browserless.io/bql-schema/operations/mutations/select
Accessed: 2026-07-15
Quote: "Selects a value from a dropdown or multiple select element."

**puppeteer-select**
URL: https://pptr.dev/api/puppeteer.page.select
Accessed: 2026-07-15
Quote: "Triggers a change and input event once all the provided options have been selected."

**local-cdp-experiment**
URL: local://remote-surface/2026-07-15-native-select-screencast
Accessed: 2026-07-15
Quote: Patchright 1.61.1, Chromium headless, 500×300 page with a three-option select: CDP frame after native click omitted options; the same frame after `appearance: base-select` + `::picker(select)` showed all three option rows. A `style-src 'self'` CSP left computed `appearance` as `auto`.

## SYNTHESIS

This is not fixable by a CDP screencast parameter, media emulation, or a stable Chromium launch flag. CDP page capture and desktop capture are different products: n.eko's desktop/WebRTC architecture naturally avoids the boundary, while Browserless/Puppeteer automation avoids opening the visual popup at all. A JavaScript replacement for arbitrary selects would be a semantic rewrite with accessibility, keyboard, form, shadow-DOM, and site-CSS failure modes, so it is not an honest library default.

Chromium's customizable-select mode is the narrow exception worth offering: it retains the native select's browser behavior while moving the picker into the page-rendered top layer, proven here in the same CDP screencast path. It must remain opt-in and feature-detected. It can visibly change a site's presentation, does not affect closed shadow roots, and an inline-style CSP disables it; unsupported Chromium keeps the native-popup limitation. Hosts that need universal fidelity should use a desktop/window capture backend, not depend on CDP page screencasting.
