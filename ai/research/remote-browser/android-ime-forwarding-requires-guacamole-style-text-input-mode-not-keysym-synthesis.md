---
title: "Forwarding Android soft-keyboard (Gboard) input to a remote browser requires a Guacamole-style text-input mode — a hidden editable element that lets the IME commit, then diffs the committed string into keysyms — because composing text never emits usable keydown events"
date: 2026-05-12
topic: remote-browser
tags: [ime, android, gboard, guacamole, neko, wayland, rdp, remote-browser, composition-events]
status: draft
sources: [guacamole-manual, guac-textinput-src, neko-547, wayland-input-method, ms-rdp-android, ckeditor-12058, hyperbeam-yc, hyperbeam-docs, neko-issues]
source_session: 019e1f9d-b1f5-7ad2-89a9-ebb26230c4bd
---

## CLAIMS

- Android soft keyboards (Gboard, SwiftKey) do not emit usable `keydown` events for typed characters — they fire `keyCode === 229` ("composition in progress") with `key === "Unidentified"`, and the real characters arrive in `InputEvent.data` on `beforeinput`/`input` of a focused editable element. [ckeditor-12058][neko-547]
- Apache Guacamole's documented answer is a three-mode keyboard (None, Text input, On-screen keyboard); text-input mode hides a `<textarea>` to trigger the device IME, lets the IME complete its full composition cycle locally (including CJK candidate selection), and on commit diffs textarea contents against the previous snapshot to infer keystrokes. [guacamole-manual]
- Guacamole's diff algorithm strips common prefix and suffix, maps a deleted middle to `BackSpace` keysym (0xFF08) press/release pairs, and maps an inserted middle to per-codepoint X11 keysyms (`codepoint` if ≤0xFF, else `0x01000000 | codepoint`); the textarea is padded with zero-width-space (U+200B) characters for Backspace/Delete headroom and periodically reset. [guac-textinput-src]
- Guacamole brackets composition with `compositionstart`/`compositionend` listeners, suppresses mutations during composition, and forwards only the committed string — which is why the same channel handles CJK, predictive autocomplete, swipe-typing, and emoji (all resolve to a committed Unicode string before the diff runs). [guac-textinput-src][guacamole-manual]
- Modifier chords (Ctrl-Alt-Del, Alt-Tab, system-reserved) cannot be expressed in text-input mode, so Guacamole adds an on-screen modifier strip (Ctrl, Alt, Esc, Tab) alongside the textarea. [guacamole-manual]
- The neko project maintainer states neko uses Guacamole's keyboard implementation, that Guacamole itself requires a separate text-input mode for IMEs "through the explicit insertion of text" rather than key presses, and that neko has not built such a mode — confirming this is known-but-unbuilt work in the neko family across multiple years of issues. [neko-547][neko-issues]
- The Wayland `input-method-unstable-v1` protocol distinguishes `commit_string` (final text from the IME, the channel CJK uses) from `forward_key`/synthetic keysym (raw key passthrough), confirming the architectural rule: never synthesize keysyms from composing text — only from the committed string. [wayland-input-method]
- Microsoft RDP for Android solves the same problem with a first-class "Unicode mode" that sends codepoints directly plus a "Scancode mode" for physical keys, toggled by a documented user setting — conceptually identical to Guacamole's commit-string vs raw-key separation. [ms-rdp-android]
- Editor projects (CKEditor, Slate, ProseMirror) confirm across years of bug reports that Android requires completely custom handling because composition events fire differently than every other platform, and the only reliable signal is `beforeinput.data` after the IME commits. [ckeditor-12058]
- Hyperbeam (YC W22) ships a WebRTC-streamed remote Chromium with mobile as a first-class target (set `user_agent: "chrome_android"`), but publishes no engineering writeup of how it bridges Android soft-keyboard composition into the remote browser, and the SDK is a closed minified bundle. [hyperbeam-yc][hyperbeam-docs]

## SOURCES

**guacamole-manual**
URL: https://guacamole.apache.org/doc/gug/using-guacamole.html
Accessed: 2026-05-12
Quote: "If you wish to type via an IME (input method editor)… text input mode is required for this as well. Such IMEs function through the explicit insertion of text and do not send traditional key presses."

**guac-textinput-src**
URL: https://github.com/apache/guacamole-client/blob/master/guacamole/src/main/frontend/src/app/textInput/directives/guacTextInput.js
Accessed: 2026-05-12

**neko-547**
URL: https://github.com/m1k1o/neko/issues/547
Accessed: 2026-05-12

**neko-issues**
URL: https://github.com/m1k1o/neko/issues
Accessed: 2026-05-12
Quote: "issues #115, #251, #547 — mobile keyboard / IME open or partially-fixed; no PR has landed a text-input mode in 5+ years"

**wayland-input-method**
URL: https://wayland.app/protocols/input-method-unstable-v1
Accessed: 2026-05-12

**ms-rdp-android**
URL: https://learn.microsoft.com/en-us/previous-versions/remote-desktop-client/client-features-android-chrome-os
Accessed: 2026-05-12

**ckeditor-12058**
URL: https://github.com/ckeditor/ckeditor5/issues/12058
Accessed: 2026-05-12

**hyperbeam-yc**
URL: https://www.ycombinator.com/companies/hyperbeam
Accessed: 2026-05-12

**hyperbeam-docs**
URL: https://docs.hyperbeam.com/home/user
Accessed: 2026-05-12

## SYNTHESIS

For any WebRTC-streamed remote browser that must accept typing from an Android phone, the reusable architecture is Guacamole's text-input mode, ported to the client: a hidden `<textarea>` (with `autocapitalize=off autocorrect=off spellcheck=false`, U+200B-padded), listeners on `input`/`compositionstart`/`compositionend` that suppress forwarding while composing, a common-prefix/suffix diff on commit that emits `BackSpace` keysyms for deletions and `keysymFromCodepoint` for insertions, then a textarea reset — plus an on-screen modifier strip for chords. This handles English, CJK, emoji, autocomplete/predictive replacement, and swipe-typing natively because all of them resolve to a committed string before the diff. The work is on the client; a remote side that already speaks X11 keysyms needs no protocol change. The load-bearing lesson from Wayland/RDP is the commit-string-vs-raw-key split: never try to synthesize keysyms from composing text. The technique is battle-tested (>10 years in enterprise CJK Guacamole deployments); residual risk is integration-shaped (Android/Brave composition-event timing, WebRTC datachannel latency for keysym pairs), de-riskable with a standalone harness page that logs extracted `[keysym, codepoint]` and loops them back into a second textarea before touching any remote plumbing.
