---
title: "Remote input surfaces forward mouse buttons, preserve backend click-count semantics, and treat touch fling as a separate policy from drag distance"
date: 2026-07-15
topic: remote-browser
tags: [input, mouse, touch, scrolling, cdp, novnc]
status: draft
sources: [novnc-rfb, guacamole-mouse, guacamole-touch, hyperbeam-events, cdp-input]
source_session: 6a2ccfd6-e5d5-4dd3-bcaa-7819d39f4bf3
---

## CLAIMS

- noVNC forwards mouse down/up button masks and separately cancels the browser `contextmenu` event; it does not replace remote right-click with a local menu. [novnc-rfb]
- Apache Guacamole's mouse implementation cancels `contextmenu` specifically so right-click is sent properly. [guacamole-mouse]
- Guacamole maps mobile touchpad gestures to remote mouse operations: two-finger tap is right-click and two-finger drag operates the scroll wheel. [guacamole-touch]
- Hyperbeam's public client event API represents right-click as mouse `button: 2` and scrolling as a wheel event. [hyperbeam-events]
- CDP `Input.dispatchMouseEvent` has a `clickCount` field, while `Input.dispatchTouchEvent` accepts touch start/move/end/cancel sequences. [cdp-input]

## SOURCES

**novnc-rfb**
URL: https://github.com/novnc/noVNC/blob/master/core/rfb.js
Accessed: 2026-07-15

**guacamole-mouse**
URL: https://github.com/apache/guacamole-client/blob/main/guacamole-common-js/src/main/webapp/modules/Mouse.js
Accessed: 2026-07-15
Quote: "Block context menu so right-click gets sent properly"

**guacamole-touch**
URL: https://guacamole.apache.org/doc/gug/using-guacamole.html#using-touch-devices
Accessed: 2026-07-15

**hyperbeam-events**
URL: https://docs.hyperbeam.com/client-sdk/javascript/examples
Accessed: 2026-07-15

**cdp-input**
URL: https://chromedevtools.github.io/devtools-protocol/1-3/Input/
Accessed: 2026-07-15

## SYNTHESIS

For a browser-stream surface, prevent the local context menu while preserving the already-forwarded right-button press/release; a second synthetic click is wrong. CDP clients should carry click count explicitly instead of inventing a `dblclick` transport event. Touch drag distance and post-release inertia are different concerns: keep direct manipulation 1:1, then either forward native touch to a browser backend or add a separately bounded, cancelable fling policy.
