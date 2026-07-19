---
title: "Mature remote-display systems (RFB, RDP, SPICE, Guacamole, n.eko, CDP, cloud gaming) converge on media, input, clipboard, cursor, and session/floor-control as separable planes — but disagree on how many wire channels to spend on that separation"
date: 2026-07-17
topic: remote-browser
tags: [rfb, vnc, rdp, spice, guacamole, x11, wayland, neko, cdp, cloud-gaming, protocol-design, remote-surface]
status: draft
sources: [rfc6143, rfc6143-vncdotool, realvnc-params, guacamole-protocol-ref, guacamole-protocol-chapter, ms-rdpbcgr-svc, ms-rdpedyc, ms-rdpeclip, ms-rdpea, spice-protocol, spice-gtk-api, wayland-vs-x11-abhik, wayland-vs-x11-glukhov, neko-issue-371, neko-webrtc-config, chrome-remote-desktop-wikipedia, cdp-input-domain, cdp-page-screencast, sunshine-deepwiki-udp, webrtc-datachannel-64kb, corpus-clipboard-channel, corpus-latency-cursor, corpus-viewport-fix, corpus-screen-content, corpus-injection-sdk, corpus-oss-strategy]
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation/conclusions. Skippable. No citations here.
-->

## SCOPE AND PURPOSE

Evidence-gathering lane for `@opendatalabs/remote-surface`'s plane/concern decomposition (CDP synthetic-input-over-canvas backend vs n.eko WebRTC-video/native-X11-input backend). This file is EXTERNAL PRIOR ART ONLY — what mature remote-display systems (RFB/VNC, Apache Guacamole, RDP, SPICE, X11/Wayland, n.eko, Chrome Remote Desktop, cloud gaming, CDP) actually shipped as their channel/plane taxonomy. It does not propose a design for remote-surface; the orchestrator synthesizes that from this plus the other research lanes.

Per standing rule, `ai/research/INDEX.md` was read first. Reused entries from the existing `remote-browser/` corpus are cited inline as `corpus-*` slugs below and NOT re-researched; new findings target the systems this task named that were not yet in the corpus: RFB's explicit message-type taxonomy, RDP virtual channels, SPICE's channel model, X11-vs-Wayland's input/render separation, Guacamole's protocol-instruction taxonomy and design philosophy, n.eko's own connection/media/control decoupling, Chrome Remote Desktop's Chromoting, CDP's Input/Page/Emulation domain split, and cloud-gaming (Sunshine/Moonlight) UDP channel separation. Session/floor-control (who has input authority in a shared/multi-viewer session) surfaced as a genuinely new, load-bearing concern not yet in the corpus and is captured here.

## CLAIMS

### RFB/VNC — one transport stream, typed messages, NO separate channels

- RFB/VNC operates over a single reliable byte-stream transport (typically one TCP connection); after handshake, ALL traffic — framebuffer updates, input, and clipboard — flows through that one stream, distinguished only by a leading message-type byte per message. [rfc6143] [rfc6143-vncdotool]
- Server-to-client message types are FramebufferUpdate (0), SetColorMapEntries (1), Bell (2), ServerCutText (3, clipboard). Client-to-server message types are SetPixelFormat (0), SetEncodings (2), FramebufferUpdateRequest (3), KeyEvent (4), PointerEvent (5), ClientCutText (6, clipboard). [rfc6143]
- RFB's Cursor pseudo-encoding lets the client render the pointer locally instead of waiting for the server to composite it into the framebuffer, explicitly for perceived-performance reasons over slow links — i.e. cursor position/shape is functionally a separate concern from bulk framebuffer pixels even though it rides the same wire message stream. [rfc6143] [corpus-latency-cursor]
- RFB's ClientInit handshake carries a 1-byte "shared-flag" declaring whether the connecting client will allow other VNC viewers to share the same desktop session concurrently; the base RFC leaves arbitration among multiple simultaneous input-sending clients to the server implementation. [rfc6143-vncdotool]
- RealVNC's server implementation (not part of the base RFC) adds explicit floor-control primitives on top of bare RFB: a `FloorControlEnable` flag restricting control to one viewer at a time, and independent `AcceptKeyEvents`/`AcceptPointerEvents` toggles used together to make a connection view-only. [realvnc-params]

### Apache Guacamole — richest first-class channel taxonomy of the surveyed systems

- Guacamole is a protocol-abstraction layer sitting between the browser client and native remote protocols (RDP/VNC/SSH); the browser only ever speaks the Guacamole protocol, never the native ones, so the native protocol's own channel model is hidden behind Guacamole's own. [guacamole-protocol-chapter]
- The Guacamole wire protocol is instruction-based (comma-delimited, length-prefixed, semicolon-terminated), chosen specifically because it can be parsed incrementally as bytes arrive (unlike JSON/XML, which need the full message before decode) and can be multiplexed via a "nest" instruction so long-running streams don't block independent short instructions. [guacamole-protocol-ref] [guacamole-protocol-chapter]
- Guacamole's instruction set spans (by declared purpose) at minimum: rendering/compositing (arc/cfill/clip/close/copy/curve/dispose/distort/img/lfill/line/lstroke/move/rect/transform/etc.), a dedicated `cursor` instruction, a dedicated first-class `audio` stream type, a dedicated first-class `clipboard` stream type, input (`key`, client- and server-side `mouse`), connection/handshake/control (`connect`/`disconnect`/`error`/`ready`/`select`/`sync`/`nop`), and separate first-class stream types for `file`, `pipe` (named pipes), `video`, and filesystem `object`s (get/put/undefine). [guacamole-protocol-ref]
- Guacamole's stated design philosophy is explicit device-independence: never assume a particular input modality is present or absent because of an inferred device class; the codebase supports mouse and touch simultaneously rather than switching between them. [guacamole-protocol-chapter]
- Guacamole synchronizes clipboard automatically via the Clipboard API when permitted, with a manual textarea fallback, and states that DOM copy/paste events alone are unsuitable because they are shortcut-dependent, platform-dependent, and require synchronous handling despite a remote round trip — clipboard is architecturally distinct from keyboard-shortcut forwarding. [corpus-clipboard-channel]

### RDP — virtual channels are the generalized "everything besides core video/input" extensibility mechanism

- RDP's core connection carries core PDUs (graphics, input) over an I/O channel plus an optional message channel, both encapsulated in the main RDP connection; ALL non-core functionality (clipboard, audio redirection, device forwarding, diagnostics, extended input like multitouch/pen) is delegated to virtual channels layered on top, not folded into the core protocol. [ms-rdpbcgr-svc] [ms-rdpedyc]
- RDP has two virtual-channel generations: Static Virtual Channels (SVCs), fixed at connection time, capped at 31 per connection, cannot open/close mid-session; and Dynamic Virtual Channels (DVCs), which multiplex over one special SVC named "DRDYNVC" and CAN be opened/closed on the fly during a live session, including transport over UDP for lower latency. [ms-rdpbcgr-svc] [ms-rdpedyc]
- Clipboard (CLIPRDR) ships as a dedicated, separately-specified, stateful static virtual channel with its own documented state machine — clipboard is not a variant of keyboard/input traffic. [ms-rdpeclip]
- Audio (MS-RDPEA) can run over either a static virtual channel ("RDPSND") or, in modern deployments, a dynamic virtual channel, with distinct DVC names for reliable vs lossy/UDP transport (`AUDIO_PLAYBACK_DVC` vs `AUDIO_PLAYBACK_LOSSY_DVC`) — i.e. even within "audio" the transport-reliability tradeoff is itself an explicit, named protocol choice. [ms-rdpea]
- Modern Microsoft-authored DVCs cover per-concern extensions individually: `Microsoft::Windows::RDS::Input` (multitouch/pen), `::Geometry` (geometric rendering), `::DisplayControl` (display/monitor configuration), `::Telemetry` (performance metrics) — each a separately named, separately versioned channel rather than one monolithic "everything else" channel. [ms-rdpedyc]

### SPICE — the most fully decomposed named-channel model surveyed

- SPICE splits a session into multiple numbered channel types, each with its own connection and message set: MAIN (1), DISPLAY (2), INPUTS (3), CURSOR (4), PLAYBACK (5, audio out), RECORD (6, audio in/mic), TUNNEL (7, obsolete), SMARTCARD (8), USBREDIR (9), PORT (10), WEBDAV (11). [spice-protocol]
- CURSOR is a channel fully separate from DISPLAY: cursor position/shape updates do not share a wire channel with framebuffer/video content. [spice-protocol]
- The client first connects a MAIN channel, receives a session ID, and the server advertises which additional channels are available; the client then opens one connection per channel type it wants, referencing that session ID — i.e. channel membership is negotiated, not assumed fixed. [spice-protocol]
- Clipboard/agent communication (guest-clipboard sync, authentication, display configuration) rides an opaque agent sub-protocol carried over the MAIN channel rather than getting its own numbered channel — SPICE treats "control/session plumbing" and "clipboard/agent" as coupled, unlike Guacamole and RDP, which give clipboard its own first-class channel. [spice-protocol]
- Authentication is scoped to the MAIN channel only; once the main channel's security context is established, DISPLAY/INPUTS/CURSOR/etc. instantiate without separately re-authenticating — session/control-plane identity is centralized in one channel that all media/input channels trust. [spice-protocol]
- On the server (libspice) side, MAIN and INPUTS are handled by one class of handler (`reds.c`), while DISPLAY and CURSOR each get a dedicated per-display worker thread, and PLAYBACK/RECORD get their own audio-specific handlers (`snd_worker.c`) — the wire-level channel taxonomy is mirrored by a matching server-side threading/ownership taxonomy, not just a labeling convenience. [spice-gtk-api]

### X11 vs Wayland — rendering and input separation is a SECURITY boundary, not just an organizational one

- X11 is architecturally monolithic: the X server handles window management, compositing, AND input dispatch, with any connected client historically able to observe or inject input/screen content system-wide (no per-app isolation) — this is described as the core reason X11 lacks a sandboxing story. [wayland-vs-x11-abhik] [wayland-vs-x11-glukhov]
- Wayland's compositor consolidates display-server + window-manager + compositor into one process, but its defining property is that each client can only see/render to its own surface and receives only its own input events; any cross-application interaction (global hotkeys, screen capture, input injection) requires an explicit, separately-brokered protocol extension rather than ambient access. [wayland-vs-x11-abhik] [wayland-vs-x11-glukhov]
- Wayland rendering is client-side-buffer + damage-tracked: the client renders into its own GPU buffer and tells the compositor only which region changed, versus X11's copy-through-the-server model — a rendering-pipeline-level instance of "push work and diffs to the edge, keep the center thin." [wayland-vs-x11-abhik]
- XWayland (the X11 compatibility shim under a Wayland compositor) explicitly does NOT inherit Wayland's isolation guarantee: X11 clients running under XWayland can still snoop each other, because X11's original no-isolation semantics persist within that compatibility layer. [wayland-vs-x11-abhik]

### n.eko — control/input is explicitly decoupled from BOTH its concrete transports

- n.eko streams desktop audio/video to the browser over WebRTC and uses a WebSocket connection as the signaling and control channel; API users are told not to depend on WebSocket internals, only on connection-state semantics (connected/connecting/disconnected). [neko-webrtc-config] [neko-issue-371 via WebSearch synthesis]
- n.eko's v3 architecture proposal treats connection, media-streaming, and control as three SEPARATE pluggable interfaces, each independently implementable by more than one underlying transport — e.g., media backends could be WebRTC (bidirectional) or plain HTTP (receive-only), and control data can be carried over "both underlying connections or media streaming," i.e. either the WebSocket or a WebRTC data channel. [neko-issue-371]
- This makes control (mouse/keyboard/gamepad/custom-device input) NOT bound to a fixed transport by design — the same logical "control" concern can travel over the signaling channel or the low-latency media peer connection depending on deployment, which is a stronger decoupling claim than most of the fixed-channel systems above (RFB/SPICE/RDP each hard-wire input to one specific channel). [neko-issue-371]
- n.eko explicitly separates in-band media feedback from out-of-band control signaling needed for features like gamepad vibration, cursor-position broadcast to other viewers, and keyboard-layout changes — i.e. cursor/session-state broadcast to OTHER connected viewers is its own concern, relevant to remote-surface's multi-viewer case. [neko-issue-371]
- (Corpus, not re-verified here) n.eko has no formal plugin SPI, delegates multi-tenancy entirely to an external orchestrator (neko-rooms), and ships Apache-2.0 with a SECURITY.md that only covers vuln reporting, not multi-tenant safety. [corpus-oss-strategy]

### Chrome Remote Desktop (Chromoting) and cloud gaming (Sunshine/Moonlight) — same media/input split, over different transports

- Chrome Remote Desktop's proprietary "Chromoting" protocol runs its P2P connection over WebRTC/ICE (Direct/STUN/TURN negotiation), observed via `chrome://webrtc-internals` using VP8 with `googContentType: screen` for the media, with keyboard/mouse forwarding logically separate from the video RTP stream — consistent with the general WebRTC pattern where one peer connection can carry multiple independent media tracks and a data channel simultaneously. [chrome-remote-desktop-wikipedia]
- WebRTC RTCDataChannel — the mechanism available for out-of-band input/control traffic alongside media tracks on the same peer connection — has a documented ~64KB per-message practical send limit in Chrome (worked around by chunking), which is a real constraint on using the data channel for anything bulkier than input events (e.g. file transfer or large clipboard payloads would need chunking or a separate path). [webrtc-datachannel-64kb]
- Sunshine/Moonlight (NVIDIA GameStream-derived cloud-gaming stack) separates SESSION SETUP (HTTP/HTTPS "NVHTTP" for discovery/pairing, RTSP for stream negotiation) from the DATA PLANE (UDP), and once streaming starts, ALL of video, audio, and control/input data flow over UDP, not the RTSP control channel; Sunshine specifically uses four separate UDP sockets, each bound to a specific port offset. [sunshine-deepwiki-udp]
- Sunshine's control-channel messages are individually encrypted (AES-GCM with a monotonically increasing sequence number as IV) and separately typed from the video/audio RTP-encapsulated packets, even though all three ride the same UDP transport family — protocol-level separation of concerns can exist without separate TRANSPORTS. [sunshine-deepwiki-udp]
- Input return-path in cloud gaming carries not just raw device events but per-monitor cursor position/click context for multi-monitor setups, and the host injects received input as virtual input locally — structurally identical to n.eko's X11/native-input model, just over a game-streaming-specific UDP protocol instead of WebRTC. [sunshine-deepwiki-udp]

### CDP — domain-per-concern, but no first-class clipboard/audio/cursor domain

- CDP organizes concerns into separate top-level domains: `Page` (navigation/lifecycle, and the screencast media path via `Page.startScreencast`), `Emulation` (viewport/device metrics simulation), `Input` (dispatchKeyEvent/dispatchMouseEvent/dispatchTouchEvent/insertText, plus higher-level synthesizeTapGesture/synthesizeScrollGesture/synthesizePinchGesture and drag interception via dispatchDragEvent/setInterceptDrags), and `DOM` (structure access). [cdp-input-domain]
- `Page.startScreencast` documents only image encoding/size/frame-sampling parameters — no delta/dirty-rect optimization, and (per corpus) no control over native picker/select rendering, which lives outside the page-paint surface entirely. [cdp-page-screencast] [corpus-screen-content]
- CDP has no first-class clipboard, cursor-shape, or audio domain analogous to RFB/SPICE/RDP/Guacamole's dedicated channels — those concerns must be synthesized by the SDK layer on top of `Input.insertText`/JS clipboard APIs (clipboard) or are simply absent (CDP screencast carries no server-rendered cursor at all; the OS cursor is whatever the OS/consumer renders). [cdp-input-domain] [corpus-clipboard-channel]

## SOURCES

**rfc6143**
URL: https://datatracker.ietf.org/doc/html/rfc6143
Accessed: 2026-07-17
Quote: "The RFB protocol can operate over any reliable transport, either byte-stream or message based. It usually operates over a TCP/IP connection." Message types: server→client FramebufferUpdate(0)/SetColorMapEntries(1)/Bell(2)/ServerCutText(3); client→server SetPixelFormat(0)/SetEncodings(2)/FramebufferUpdateRequest(3)/KeyEvent(4)/PointerEvent(5)/ClientCutText(6). Cursor pseudo-encoding §7.8.1 (also previously verified — see corpus-latency-cursor).

**rfc6143-vncdotool**
URL: https://vncdotool.readthedocs.io/en/0.8.0/rfbproto.html
Accessed: 2026-07-17
Quote: ClientInit shared-flag byte semantics; "the RFB protocol as defined provides no security beyond the optional and cryptographically weak password check" — floor-control among simultaneous clients left to server implementations.

**realvnc-params**
URL: https://help.realvnc.com/hc/en-us/articles/360002251297-RealVNC-Server-Parameter-Reference
Accessed: 2026-07-17
Quote: `FloorControlEnable` "so that only one VNC Viewer user has control of this computer at a time"; `AcceptKeyEvents`/`AcceptPointerEvents` used together to make a connection view-only.

**guacamole-protocol-ref**
URL: https://guacamole.apache.org/doc/gug/protocol-reference.html
Accessed: 2026-07-17
Quote: Full instruction list incl. `cursor` ("Sets the client's cursor to the image data from the specified rectangle"), `clipboard` ("Allocates a new stream, associating it with given clipboard metadata"), `audio`/`video`/`file`/`pipe` stream-allocation instructions, `key`/`mouse` input instructions, `connect`/`ready`/`sync`/`disconnect`/`error` control instructions.

**guacamole-protocol-chapter**
URL: https://guacamole.apache.org/doc/gug/guacamole-protocol.html ; https://guacamole.apache.org/doc/gug/introduction.html
Accessed: 2026-07-17
Quote: On device independence: "never assume you have a particular device... just because your browser has or is missing a specific feature." On instruction format rationale: parsable incrementally as bytes arrive, unlike JSON/XML which "requires the entirety of the... message to be available at the time of decoding"; `nest` instruction multiplexes independent streams so long instructions don't block others.

**ms-rdpbcgr-svc**
URL: https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-rdpbcgr/343e4888-4c48-4054-b0e3-4e0762d1993c
Accessed: 2026-07-17
Quote: Static Virtual Channels "allow lossless communication between client and server components over the main RDP data connection"; capped at 31, fixed at connection time, cannot open/close mid-session.

**ms-rdpedyc**
URL: https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-rdpedyc/1edc9fd6-c7f9-4de9-82d6-5d13ee41d03a
Accessed: 2026-07-17
Quote: DVCs multiplex over the "DRDYNVC" static virtual channel, "can be opened and closed on the fly during an RDP session," and may transport over UDP for lower latency. Named Microsoft DVCs incl. `Microsoft::Windows::RDS::Input`, `::Geometry`, `::DisplayControl`, `::Telemetry`.

**ms-rdpeclip**
URL: https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-rdpeclip/a373b2b9-3737-4c5f-a296-bc91a2f53344
Accessed: 2026-07-17
Quote: CLIPRDR is a static virtual channel "dedicated to synchronization of the clipboard between the server and the client," documented as a stateful protocol with its own state machine.

**ms-rdpea**
URL: https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-rdpea/40527932-258d-4664-bf5a-e569222e23ed
Accessed: 2026-07-17
Quote: Audio transport over static channel "RDPSND" or DVC `AUDIO_PLAYBACK_DVC` (reliable) / `AUDIO_PLAYBACK_LOSSY_DVC` (UDP, lossy).

**spice-protocol**
URL: https://www.spice-space.org/spice-protocol.html
Accessed: 2026-07-17
Quote: Channel type enum SPICE_CHANNEL_MAIN=1 / DISPLAY=2 / INPUTS=3 / CURSOR=4 / PLAYBACK=5 / RECORD=6 / TUNNEL=7(obsolete) / SMARTCARD=8 / USBREDIR=9 / PORT=10 / WEBDAV=11; main-channel-only authentication; agent/clipboard messages carried over MAIN as an opaque agent sub-protocol.

**spice-gtk-api**
URL: https://www.spice-space.org/api/spice-gtk/ch02.html ; https://gitlab.com/spice/spice-gtk/blob/master/src/channel-main.c
Accessed: 2026-07-17
Quote: Client-side dedicated channel classes (CursorChannel, PlaybackChannel, RecordChannel); server-side "Main and Inputs channels are controlled by handler functions (reds.c)... display and cursor channels are handled by a red worker thread per display... audio playback and record channels have their own handlers (snd_worker.c)."

**wayland-vs-x11-abhik**
URL: https://www.abhik.ai/concepts/systems/wayland-x11
Accessed: 2026-07-17
Quote: On X11: "any client can potentially capture the screen or inject input events... trust the server completely." On Wayland: "Applications running under Wayland have no access to the input events or rendering output of other applications... must go through explicit, controlled interfaces." XWayland: "X11 security model persists (XWayland clients can snoop each other)."

**wayland-vs-x11-glukhov**
URL: https://www.glukhov.org/post/2026/01/wayland-vs-x11-comparison/
Accessed: 2026-07-17
Quote: Corroborating description of X11's monolithic X-server/window-manager/compositor split vs Wayland's consolidated compositor and damage-tracked client-side rendering.

**neko-webrtc-config**
URL: https://neko.m1k1o.net/docs/v3/configuration/webrtc
Accessed: 2026-07-17
(WebSearch-summarized; corroborates WebSocket-as-signaling/control-channel role and WebRTC-as-media-transport role.)

**neko-issue-371**
URL: https://github.com/m1k1o/neko/issues/371
Accessed: 2026-07-17
Quote: "Control can use both underlying connections or media streaming for transmitting and receiving control data." "Various media streaming backends can have various features. For example, WebRTC can have a feature to send media to the server, while HTTP can only receive media from the server." "The user can control the target system using various human interface devices... Custom or virtual devices can be used as well."

**chrome-remote-desktop-wikipedia**
URL: https://en.wikipedia.org/wiki/Chrome_Remote_Desktop
Accessed: 2026-07-17
Quote: "a proprietary protocol also developed by Google, internally called Chromoting... transmits the keyboard and mouse events from the client to the server, relaying the graphical screen updates back." Connection modes Direct/STUN/TURN via ICE.

**cdp-input-domain**
URL: https://chromedevtools.github.io/devtools-protocol/tot/Input/
Accessed: 2026-07-17
Quote: `dispatchKeyEvent`/`dispatchMouseEvent`/`dispatchTouchEvent`/`insertText`/`setInterceptDrags`/`dispatchDragEvent`/`synthesizeTapGesture`/`synthesizeScrollGesture`/`synthesizePinchGesture` method list, and CDP's domain split across Page/Emulation/Input/DOM.

**cdp-page-screencast**
URL: https://chromedevtools.github.io/devtools-protocol/tot/Page/#method-startScreencast
Accessed: 2026-07-17 (previously verified — see corpus-screen-content)
Quote: Documented parameters are only `format`/`quality`/`maxWidth`/`maxHeight`/`everyNthFrame`.

**sunshine-deepwiki-udp**
URL: https://deepwiki.com/LizardByte/Sunshine/4-core-streaming-architecture ; https://deepwiki.com/LizardByte/Sunshine/4.4-udp-streaming-and-data-plane
Accessed: 2026-07-17
Quote: "NVHTTP for HTTP/HTTPS-based discovery, pairing, and session initiation; RTSP for stream negotiation; and UDP Streams for low-latency video, audio, and control data transmission... Sunshine uses four separate UDP sockets for streaming... Encrypted control messages are wrapped in a control_encrypted_t structure... seq field used as a monotonically increasing sequence number (IV for AES-GCM)." DeepWiki is a third-party-generated documentation aggregator over the LizardByte/Sunshine source, not the project's own prose — treat structural claims as high-confidence (source-code-derived) but treat exact prose framing as secondhand.

**webrtc-datachannel-64kb**
URL: https://developer.chrome.com/blog/webrtc-rtcdatachannel-demo-api-changes-and-chrome-talks-to-firefox
Accessed: 2026-07-17
Quote: "you should not try to send more than 64KB at a time via the DataChannel.send() API — this limitation is temporary and will be removed once Chrome incorporates the SCTP User Message Interleaving extension."

**corpus-clipboard-channel** (reused, not re-verified)
File: remote-browser/remote-surface-clipboard-shortcuts-require-a-bidirectional-clipboard-channel-separate-from-key-forwarding.md

**corpus-latency-cursor** (reused, not re-verified)
File: remote-browser/remote-desktop-and-cloud-gaming-mask-perceived-latency-via-client-side-echo-not-faster-networks.md

**corpus-viewport-fix** (reused, not re-verified)
File: remote-browser/production-remote-browser-vendors-fix-viewport-at-session-start-and-scale-or-letterbox-on-the-client.md

**corpus-screen-content** (reused, not re-verified)
File: remote-browser/screen-content-streaming-favors-maintain-resolution-and-detail-tuned-encoders-over-motion-optimized-defaults.md

**corpus-injection-sdk** (reused, not re-verified)
File: remote-browser/injection-based-remote-browser-sdks-should-shrink-to-one-required-transport-object-per-side.md

**corpus-oss-strategy** (reused, not re-verified)
File: oss-strategy/remote-browser-substrate-oss-uses-apache-2-neutral-core-and-disclaims-multi-tenant-safety.md

## SYNTHESIS

**The convergent taxonomy.** Every mature system in this survey — regardless of era (RFB 1998, RDP 1996, SPICE 2007, Guacamole 2010, n.eko 2020s) or transport substrate (TCP, WebRTC, UDP) — independently arrives at treating these as logically distinct concerns, even when they don't all get separate wire channels:

1. **Media/framebuffer** (bulk pixels or encoded video)
2. **Cursor** (position + shape) — notably, this is almost always split OUT of media even in the most primitive systems (RFB's Cursor pseudo-encoding is 2011-RFC-old; SPICE gives it a fully separate numbered channel; Guacamole gives it a dedicated instruction). The universal reason given is perceived-latency: cursor motion is the one thing users notice most if it round-trips.
3. **Input** (keyboard/mouse/touch/gamepad events, direction: client→server)
4. **Clipboard** (bidirectional, but structurally NOT the same as key-forwarding — RDP and Guacamole both give it a dedicated, stateful sub-protocol; SPICE is the one system that folds it into a generic agent-channel instead of giving it true first-class status)
5. **Audio** — where present (SPICE, Guacamole, RDP, cloud gaming), always a separate channel/instruction/DVC from video, and even audio-in (mic/record) vs audio-out (playback) get separately-named channels in SPICE and separately-named DVCs in RDP.
6. **Session/control-plane** (connect/handshake/who's-authenticated/who-has-input-authority) — SPICE makes this explicit and load-bearing: authentication lives ONLY on the MAIN channel, and every other channel trusts that established context rather than re-authenticating. RFB/RealVNC and X11-vs-Wayland both surface a second, distinct sub-concern here: **floor control / shared-vs-exclusive input authority**. This is not a niche feature — RealVNC ships it as first-class server config (`FloorControlEnable`, `AcceptKeyEvents`/`AcceptPointerEvents` view-only toggles) and Wayland's entire security model is built around "no ambient cross-client input/render access unless a broker explicitly grants it." For remote-surface's multi-viewer case (browser stream with more than one connected viewer), "who currently has input authority, and is this viewer view-only" is real prior art, not a speculative feature.
7. **Viewport/geometry** — appears mostly as a control-plane negotiation rather than a data channel: RDP's `DisplayControl` DVC, SPICE's per-channel negotiation off the MAIN session, and CDP's `Emulation` domain all treat "what size/shape is the remote surface" as configuration state exchanged on the control path, not as traffic on the media path. (Corpus already covers remote-surface's own viewport-fix-at-session-start finding — this generalizes it: geometry negotiation is architecturally control-plane, not media-plane, across every system surveyed.)

**Where systems diverge: how many WIRE channels to spend on that taxonomy.** RFB spends exactly one (typed messages on one stream) — the taxonomy is conceptual, not architectural. SPICE spends the most (11 named channel types, one TCP connection each, cursor and audio-in and audio-out all separately numbered). RDP sits in between: a fixed core (video+input) plus an open-ended, dynamically-extensible virtual-channel mechanism for everything else, where clipboard/audio/multitouch each get their OWN named channel rather than sharing a generic "extras" channel. Guacamole is architecturally RFB-like (one instruction stream) but semantically SPICE-like (first-class named instruction types per concern, including audio/clipboard/file/pipe/filesystem that RFB never had at all) — it gets SPICE-grade taxonomy richness on an RFB-grade single-stream transport, which is directly relevant if remote-surface wants channel-count discipline without concern-taxonomy poverty.

**n.eko's specific and unusual contribution: control is transport-agnostic by design, not just multiplexed.** Every other system in this survey picks ONE fixed transport per concern (RFB: everything on the TCP stream; SPICE: INPUTS always its own channel; RDP: input always in the core I/O channel). n.eko's v3 architecture is qualitatively different — it defines connection, media, and control as three separate pluggable INTERFACES where control explicitly "can use both underlying connections or media streaming," i.e. the SAME logical input concern can be implemented over the WebSocket OR a WebRTC data channel depending on deployment needs. This is the strongest direct evidence that "media transport" and "control-plane transport" are separable interface concerns even when a given deployment happens to route them over the same wire — which matters directly for remote-surface's two-backend reality (CDP puts input on the CDP command channel, n.eko puts input over WebSocket-or-WebRTC-data-channel by n.eko's own admission) since it implies the plane boundary is real even where the transport happens to collapse.

**CDP is the outlier for concern-completeness, not concern-separation.** CDP does separate concerns into domains (Page for media/screencast+navigation, Emulation for viewport, Input for keys/mouse/touch/gestures/drag, DOM for structure) — so the *separation* pattern holds. What CDP conspicuously lacks, that every dedicated remote-display protocol has, is first-class treatment of cursor-as-a-concern (no server-rendered cursor concept at all in screencast), clipboard-as-a-concern (must be synthesized from `Input.insertText` + page-level JS Clipboard API calls, per the existing corpus finding), and audio. This is architecturally expected — CDP was designed for devtools automation of a single page, not for operating a remote display — but it means an SDK built on CDP (remote-surface's CDP backend) has to MANUFACTURE the cursor/clipboard/session-control planes that n.eko's WebRTC+native-input backend gets closer to for free from the underlying X11/agent layer, while CDP gets native browser-level input semantics (click counts, native touch fling, native select popups being the one place it loses — see corpus) that n.eko's OS-level input has to approximate.

**Honest gaps / caveats.**
- n.eko's exact JSON wire-message schema (specific event names for keydown/mousemove/etc, and whether the current shipped build — not just the v3 design proposal — actually implements input-over-data-channel or still hard-codes WebSocket) was not verified against source; issue #371 is a DESIGN PROPOSAL/roadmap discussion, not confirmed shipped behavior. Treat "control is transport-pluggable" as n.eko's stated architectural INTENT, not a verified current-release fact.
- Sunshine architecture claims are sourced from DeepWiki, a third-party AI-generated documentation aggregator over the LizardByte/Sunshine source rather than the project's own docs or a primary spec — structural facts (four UDP sockets, AES-GCM sequence numbers) are source-code-derived and likely reliable, but exact prose/framing should be treated as secondhand.
- SPICE's agent/clipboard-over-MAIN-channel design was not cross-checked against the full SPICE protocol spec PDF (only the summary page and spice-gtk API docs were fetched) — the claim that clipboard has no dedicated numbered channel is well-supported by the channel-type enum but the full agent-message spec wasn't read line-by-line.
- This lane deliberately did NOT investigate WebXR/VR remote-input, USB/smartcard redirection semantics in depth (SPICE/RDP both have them but they're out of scope for remote-surface's browser-only backends), or Kasm's own KasmVNC-specific protocol extensions beyond what's already in the corpus's OSS-strategy entry.
- No claim here has been validated against remote-surface's actual source code — that cross-check (does remote-surface's current plane boundary already match or diverge from this taxonomy) is explicitly the orchestrator's synthesis job, not this lane's.
