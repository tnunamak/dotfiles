---
title: "Long-press in a CDP browser stream is a held native touch sequence, not a right-click"
date: 2026-07-16
topic: remote-browser
tags: [cdp, touch, long-press, mobile, context-menu]
status: settled
sources: [cdp-input, guacamole-touch, local-chromium-experiment]
---

## CLAIMS

- CDP `Input.dispatchTouchEvent` accepts ordered `touchStart`, `touchMove`, `touchEnd`, and `touchCancel` events; start/move carry active touch points while end/cancel carry none. [cdp-input]
- Apache Guacamole documents long-press as a remote-desktop-specific gesture (panning or magnification), not as a universal right-click translation. [guacamole-touch]
- In local mobile-emulated Chromium 150, a CDP `touchStart`, 750 ms wait, and `touchEnd` delivered remote `touchstart`/`touchend` and triggered the page's `selectstart` path without a synthetic mouse click or context-menu event. [local-chromium-experiment]

## SOURCES

**cdp-input**
URL: https://chromedevtools.github.io/devtools-protocol/tot/Input/#method-dispatchTouchEvent
Accessed: 2026-07-16
Quote: "TouchEnd and TouchCancel must not contain any touch points, while TouchStart and TouchMove must contains at least one."

**guacamole-touch**
URL: https://guacamole.apache.org/doc/0.9.0/gug/using-guacamole.html
Accessed: 2026-07-16
Quote: "If the remote display is already fully visible, long-pressing will not bring up the magnifier, but will instead put Guacamole in a panning mode."

**local-chromium-experiment**
URL: local Patchright Chromium 150 mobile-emulation experiment in `/home/tnunamak/.tmp/rs-clean-waspflow-rs-android`
Accessed: 2026-07-16
Quote: "during: touchstart; after: touchstart, touchend, selectstart, click."

## SYNTHESIS

A browser stream should preserve the remote page's native long-press semantics (selection, page-defined context menu, or link behavior) by forwarding the physical hold as a raw touch sequence. Translating it to right-click is a remote-desktop policy that changes page semantics and does not recover native text selection. The client must emit `touchStart` at local touch start and defer `touchEnd` until release; a delayed synthetic sequence after detecting the hold is too late to preserve its duration.
