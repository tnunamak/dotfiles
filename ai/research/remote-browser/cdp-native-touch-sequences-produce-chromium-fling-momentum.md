---
title: "CDP native touch sequences produce Chromium fling momentum, while remote-desktop products may instead expose wheel emulation"
date: 2026-07-15
topic: remote-browser
tags: [cdp, touch, scrolling, fling, momentum, remote-desktop]
status: settled
sources: [cdp-input, guacamole-touch, hyperbeam-events, local-chromium-experiment]
source_session: 019f67e2-364b-7881-ad01-170e699f88bd
---

## CLAIMS

- CDP `Input.dispatchTouchEvent` accepts `touchStart`, `touchMove`, `touchEnd`, and `touchCancel`; end and cancel contain no touch points, while start and move contain at least one. [cdp-input]
- Guacamole's relative touchpad mode maps a two-finger drag to a mouse scroll wheel, rather than documenting native touch forwarding. [guacamole-touch]
- Hyperbeam's public JavaScript event API documents keyboard, mouse, and mouse-wheel events; its documented programmatic scroll event is a wheel event. [hyperbeam-events]
- In a local Chromium 149 mobile-emulation experiment, a CDP `touchStart` followed by five 16 ms-spaced `touchMove` events and `touchEnd` increased `scrollY` from 485 immediately after release to 2,161 after 800 ms; the project's `dispatchCdpPointerInput` path likewise continued from 462 at release to 1,494 after 800 ms. [local-chromium-experiment]

## SOURCES

**cdp-input**
URL: https://chromedevtools.github.io/devtools-protocol/tot/Input/#method-dispatchTouchEvent
Accessed: 2026-07-15
Quote: "TouchEnd and TouchCancel must not contain any touch points, while TouchStart and TouchMove must contains at least one."

**guacamole-touch**
URL: https://guacamole.apache.org/doc/gug/using-guacamole.html#relative-mode-touchpad
Accessed: 2026-07-15
Quote: "The mouse scroll wheel can be operated by dragging two fingers up or down."

**hyperbeam-events**
URL: https://docs.hyperbeam.com/client-sdk/javascript/examples
Accessed: 2026-07-15
Quote: "Sends a keyboard, mouse, or mouse wheel event to the Hyperbeam browser."

**local-chromium-experiment**
URL: local Patchright Chromium 149 CDP experiment in `/home/tnunamak/.tmp/rs-clean-waspflow-rs-scroll`
Accessed: 2026-07-15
Quote: "Direct CDP: beforeEnd 406; after touchEnd: 485 (0 ms), 705 (50 ms), 1084 (100 ms), 1649 (200 ms), 2150 (400 ms), 2161 (800 ms). Project dispatchCdpPointerInput path: 462 at release, 1494 after 800 ms."

## SYNTHESIS

Do not compensate a touch drag with a constant wheel multiplier: it changes direct-manipulation geometry without creating native momentum. For a touch-capable CDP target, forward the mapped raw sequence and let Chromium estimate velocity and run its own fling. Retain wheel translation as the default compatibility mode for remote-desktop or wheel-only transports. A synthetic, cancelable inertia tail is only warranted after a target-specific test demonstrates that its backend does not preserve the browser's native fling.
