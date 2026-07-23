---
title: "Remote-surface clipboard shortcuts require a bidirectional clipboard channel separate from key forwarding"
date: 2026-07-15
topic: remote-browser
tags: [clipboard, keyboard, novnc, guacamole, cdp]
status: draft
sources: [novnc-clipboard, novnc-rfb, guacamole-manual, guacamole-faq, mdn-clipboard, hyperbeam-examples]
---

## CLAIMS

- noVNC reads the local clipboard asynchronously when its canvas receives focus and passes the text to its paste callback; it writes remote clipboard text using `navigator.clipboard.writeText()`. [novnc-clipboard]
- noVNC connects that paste callback to VNC clipboard protocol messages rather than text-key injection. [novnc-rfb]
- Guacamole automatically synchronizes local clipboard contents to remote systems when Clipboard API access is enabled and provides a manual clipboard textarea. [guacamole-manual]
- Guacamole says DOM `copy`/`paste` events alone are unsuitable for remote desktop because they are shortcut-dependent, platform-dependent, and copy requires synchronous event handling despite a remote round trip. [guacamole-faq]
- Async Clipboard API access is secure-context-only; reads/writes face browser-specific activation or permission requirements, and iframe use may require `clipboard-read` / `clipboard-write` Permissions Policy. [mdn-clipboard]
- Hyperbeam's public JavaScript examples contain no documented clipboard API. [hyperbeam-examples]

## SOURCES

**novnc-clipboard**
URL: https://github.com/novnc/noVNC/blob/master/core/clipboard.js
Accessed: 2026-07-15

**novnc-rfb**
URL: https://github.com/novnc/noVNC/blob/master/core/rfb.js
Accessed: 2026-07-15

**guacamole-manual**
URL: https://guacamole.apache.org/doc/gug/using-guacamole.html#copying-pasting-text
Accessed: 2026-07-15

**guacamole-faq**
URL: https://guacamole.apache.org/faq/
Accessed: 2026-07-15

**mdn-clipboard**
URL: https://developer.mozilla.org/en-US/docs/Web/API/Clipboard_API#security_considerations
Accessed: 2026-07-15

**hyperbeam-examples**
URL: https://docs.hyperbeam.com/client-sdk/javascript/examples
Accessed: 2026-07-15

## SYNTHESIS

Clipboard data transfer and keyboard command forwarding are separate concerns. Copy, paste, and cut need directional clipboard semantics; selection, undo, and redo are remote keyboard commands. A browser-streaming implementation may offer a documented plain-text fast path using `Input.insertText`, but full paste/copy/cut semantics require a policy-gated remote clipboard channel and a manual fallback for browsers that deny Clipboard API access.
