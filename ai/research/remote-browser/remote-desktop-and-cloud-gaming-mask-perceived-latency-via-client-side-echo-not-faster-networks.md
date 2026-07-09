---
title: "Remote-desktop and cloud-gaming systems mask perceived input latency with client-side local echo/prediction, aggressive stale-frame discard, and off-main-thread decode — not by making the round-trip itself faster"
date: 2026-07-09
topic: remote-browser
tags: [latency, perceived-performance, webrtc, cdp-screencast, cursor-rendering, webcodecs, input-coalescing, novnc, rdp, cloud-gaming]
status: draft
sources: [rfc6143, guacamole-protocol, guacamole-display-jsdoc, ms-rdpemsc, rdp-cursor-shadow-community, valve-source-netcode, valve-lag-compensation, ggpo-site, mdn-coalesced-events, mdn-predicted-events, w3c-pointerevents, novnc-rfb-source, webrtc-playout-delay, w3c-webrtc-stats, mdn-createimagebitmap, chrome-blog-createimagebitmap, mdn-rvfc, webdev-rvfc, webcodecs-explainer, chrome-webcodecs-docs, cdp-screencast-bug, webrtc-insertable-streams, nng-powers-of-10, webdev-rail, nvidia-reflex-docs, digital-foundry-stadia]
---

<!--
CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
SOURCES = per slug: URL + Accessed date + optional verbatim quote.
SYNTHESIS = interpretation/conclusions for @opendatalabs/remote-surface. Skippable.
-->

## CLAIMS

### Local echo / client-side prediction (cursor + input)

- The RFB (VNC) protocol's Cursor pseudo-encoding lets the client render the mouse cursor locally instead of waiting for the server to composite it into the frame, and the spec states this exists specifically to improve perceived performance over high-latency links. [rfc6143]
- noVNC/KasmVNC's VNC-family clients implement client-side cursor rendering via this same pseudo-encoding mechanism (a "local vs remote cursor" mode). [novnc-rfb-source]
- Apache Guacamole's protocol has a dedicated `cursor` instruction that sets a client-side cursor layer from server-sent image data plus a hotspot, distinct from the browser's native ("hardware") cursor; since Guacamole 0.9.4 the client prefers CSS3 cursors over the software-rendered fallback layer specifically because CSS cursors render faster/locally. [guacamole-protocol] [guacamole-display-jsdoc]
- Microsoft RDP has a dedicated protocol extension (MS-RDPEMSC) for cursor shape/position updates that supersedes the base spec's slower-path mouse pointer updates; the client renders the cursor locally once it has the shape data. [ms-rdpemsc]
- Enabling RDP's cursor-shadow/blend visual effect breaks this optimization: because the shadow can't be blended locally, RDP falls back to server-side cursor drawing, reintroducing round-trip latency on every cursor move — corroborated across multiple independent community/support threads as a known, fixable cause of "laggy/jumpy" RDP cursor behavior. [rdp-cursor-shadow-community]
- Valve's Source engine predicts the local player's own movement/actions client-side from raw input before server acknowledgment, and smooths server corrections over time (`cl_smoothtime`) rather than snapping the view to the corrected position, specifically to avoid a visible jarring correction. [valve-source-netcode]
- Valve's Source engine additionally performs server-side lag compensation — rewinding server simulation state to what the shooting client saw — to combine with client prediction and minimize the felt effect of network latency in combat resolution. [valve-lag-compensation]
- GGPO rollback netcode predicts remote players' inputs when they haven't yet arrived over the network, continues simulating without waiting, and on misprediction rolls back to the last-confirmed state and replays buffered inputs forward to the present frame; the project's own description is that this makes play "feel just as responsive as offline." [ggpo-site]

### Input coalescing / event batching / send-rate

- The W3C Pointer Events spec (and its MDN documentation) defines `PointerEvent.getCoalescedEvents()`, which lets an application retrieve all the fine-grained pointer positions a user agent batched into one dispatched event, reducing event-handling overhead without losing precision. [mdn-coalesced-events] [w3c-pointerevents]
- The same spec/API family defines `PointerEvent.getPredictedEvents()`, which returns user-agent-computed *future* pointer positions extrapolated from recent velocity/trajectory, explicitly so an application can "draw ahead" to reduce perceived latency. [mdn-predicted-events] [w3c-pointerevents]
- noVNC's client throttles outgoing pointer-move events to a fixed client-enforced minimum interval (`MOUSE_MOVE_DELAY = 17` ms in `core/rfb.js`), rather than sending every native mousemove event over the wire. [novnc-rfb-source]
- WebRTC's playout-delay RTP header extension lets a sender request a receiver-side jitter-buffer delay range, including explicitly disabling all smoothing (min delay = max delay = 0) for low-latency use cases. [webrtc-playout-delay]
- The W3C WebRTC-Stats spec defines standard counters (`jitterBufferDelay`, `packetsDiscarded`, `framesDropped`, etc.) that make jitter-buffer and discard behavior measurable at the application layer. [w3c-webrtc-stats]

### Decode-path latency

- `createImageBitmap()` decodes off the main thread only when called from inside a Web Worker; calling it on the main thread still decodes on the main thread, per Chrome's own engineering blog on the feature (a nuance not made clear by MDN's prose alone). [mdn-createimagebitmap] [chrome-blog-createimagebitmap]
- `HTMLVideoElement.requestVideoFrameCallback()` fires once per new video frame sent to the compositor (bounded by the lower of video framerate and display refresh rate), unlike `requestAnimationFrame()`, which only tracks display refresh and can fire without a new frame having arrived; Chrome's own web.dev documentation notes the callback can still be up to one vsync late relative to actual compositing because it runs on the main thread while compositing happens on the compositor thread. [mdn-rvfc] [webdev-rvfc]
- The WebCodecs API's official W3C explainer states its low-latency guidance directly: paint every decoded video frame as soon as possible, and release each `VideoFrame` promptly to avoid stalling the decoder — framed as a corrective to `<video>` + MediaSource Extensions, whose low-latency mode is "implicit, not standardized, and not supported by all major browsers." [webcodecs-explainer]
- Chrome's official WebCodecs documentation states the API does frame processing asynchronously and off the main thread by design, and recommends moving per-frame handling into a Web Worker. [chrome-webcodecs-docs]
- Chrome DevTools Protocol's `Page.startScreencast`/`Page.screencastFrameAck` flow had a multi-year bug (tracked as Chromium issue 40934921) where the backend sent screencast frames at a fixed rate regardless of whether the client had acked prior frames — i.e., acking had no effect on flow control — until it was fixed to gate frame delivery on the client's ack once a max-inflight-frames threshold was reached. [cdp-screencast-bug]
- The WebRTC Insertable Streams explainer states a general design principle for the sender side of a low-latency pipeline: prefer discarding frames (or not generating them) over queueing them when a stage can't keep up, rather than building a backlog. [webrtc-insertable-streams]

### Cursor rendering and perceived-latency thresholds

- Nielsen Norman Group's "Powers of 10" framework (from Jakob Nielsen's original response-time research) states 0.1 second (100ms) is the response-time limit for a user interface to feel like the user's action is directly, instantaneously causing the on-screen result. [nng-powers-of-10]
- Google's RAIL performance model states a user-facing goal of responding to input within 100ms, but derives an actual engineering budget of roughly 50ms for input handling itself, reasoning that other work competes for the same 100ms window; web.dev's own page notes RAIL has since been superseded by Core Web Vitals as Google's recommended framework. [webdev-rail]
- NVIDIA's Reflex developer documentation defines end-to-end "system latency" as peripheral + render/render-queue + display (motion-to-photon) latency, and documents "Frame Warp," a shipped technique that re-samples the latest input just before scan-out and warps the already-rendered frame to that more current input — i.e., local input correction applied at the last possible moment before display. [nvidia-reflex-docs]
- Independent hands-on measurement (Digital Foundry, GDC 2019) of Google Stadia found roughly 166ms button-to-photon latency on Assassin's Creed Odyssey at 1080p/30fps, as a real-world baseline for full-round-trip cloud-streaming input latency. [digital-foundry-stadia]

## SOURCES

**rfc6143**
URL: https://datatracker.ietf.org/doc/html/rfc6143
Accessed: 2026-07-09
Quote: "A client that requests the Cursor pseudo-encoding is declaring that it is capable of drawing a pointer cursor locally... This can significantly improve perceived performance over slow links." (§7.8.1)

**guacamole-protocol**
URL: https://guacamole.apache.org/doc/gug/protocol-reference.html
Accessed: 2026-07-09
Quote: "cursor — Sets the client's cursor to the image data from the specified rectangle of a layer, with the specified hotspot."

**guacamole-display-jsdoc**
URL: https://guacamole.apache.org/doc/1.5.0/guacamole-common-js/Guacamole.Display.html
Accessed: 2026-07-09
Quote: "Since version 0.9.4, Guacamole will use CSS3 cursors if your browser supports them."

**ms-rdpemsc**
URL: https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-rdpemsc/
Accessed: 2026-07-09
Quote: "Multiparty Cloud Extension... replacing the slow-path and fast-path mouse pointer updates from the base RDP spec" for cursor shape/position propagation.

**rdp-cursor-shadow-community**
URL: (multiple independent Microsoft Q&A / community support threads on RDP cursor lag)
Accessed: 2026-07-09
Quote: "essentially it is impossible to use a slow or high latency connection with cursor shadowing turned on" — disabling pointer/cursor shadow restores local cursor rendering and fixes jumpy/laggy cursor motion. Secondary/community-sourced; mechanism is consistent with MS-RDPEMSC's local-rendering design (blended shadow effects cannot be composited client-side, forcing server-side cursor draw).

**valve-source-netcode**
URL: https://developer.valvesoftware.com/wiki/Source_Multiplayer_Networking
Accessed: 2026-07-09
Quote: "prediction uses the client's keypresses to make a 'best guess' of the player's position... the client has to correct its own position since the server has final authority," with corrections smoothed via `cl_smoothtime` rather than snapped.

**valve-lag-compensation**
URL: https://developer.valvesoftware.com/wiki/Lag_Compensation
Accessed: 2026-07-09
Quote: Server-side rewind of simulation state to reconstruct what a shooting client saw, used "to combat network latency almost to the point of elimination" when combined with client-side prediction.

**ggpo-site**
URL: https://www.ggpo.net/
Accessed: 2026-07-09
Quote: "if the remote inputs have not yet arrived when it's time to execute a frame, the networking code will predict what it expects the remote players to do... since there's no waiting, the game feels just as responsive as it does offline." On misprediction: rollback to last-correct state, replay inputs forward.

**mdn-coalesced-events**
URL: https://developer.mozilla.org/en-US/docs/Web/API/PointerEvent/getCoalescedEvents
Accessed: 2026-07-09
Quote: "the user agent has less event handling to perform... lets applications access all un-coalesced position changes for precise handling of pointer movement data."

**mdn-predicted-events**
URL: https://developer.mozilla.org/en-US/docs/Web/API/PointerEvent/getPredictedEvents
Accessed: 2026-07-09
Quote: "returns a sequence of PointerEvent instances that are estimated future pointer positions, calculated by the user agent based on past points, current velocity, and trajectory... Applications can use these predicted events to 'draw ahead' to a predicted position, which may reduce perceived latency."

**w3c-pointerevents**
URL: https://www.w3.org/TR/pointerevents/
Accessed: 2026-07-09
Quote: Normative spec home for `getCoalescedEvents()` and `getPredictedEvents()`.

**novnc-rfb-source**
URL: https://github.com/novnc/noVNC/blob/master/core/rfb.js
Accessed: 2026-07-09
Quote: `const MOUSE_MOVE_DELAY = 17;` — pointer-move sends are throttled via a client-side timer (`_handleMouseMove()` / `_handleDelayedMouseMove()`), not sent per native event. Cursor pseudo-encoding negotiation (`pseudoEncodingCursor`) confirmed in the same source tree and corroborated by noVNC issues `#974`, `#1744`, `#1090`.

**webrtc-playout-delay**
URL: https://webrtc.googlesource.com/src/+/main/docs/native-code/rtp-hdrext/playout-delay/README.md
Accessed: 2026-07-09
Quote: "proposes an RTP extension to enable the RTP sender to try and limit the amount of playout delay at the receiver in a certain range," including disabling all smoothing (min delay = max delay = 0) for low-latency scenarios.

**w3c-webrtc-stats**
URL: https://www.w3.org/TR/webrtc-stats/
Accessed: 2026-07-09
Quote: Defines `jitterBufferDelay`, `packetsDiscarded`, `framesDropped` and related fields for measuring receiver-side buffering/discard behavior.

**mdn-createimagebitmap**
URL: https://developer.mozilla.org/en-US/docs/Web/API/Window/createImageBitmap
Accessed: 2026-07-09
Quote: Available from both `Window` and `WorkerGlobalScope`; threading behavior (decode happens wherever the call is made) not made explicit in MDN prose — see chrome-blog-createimagebitmap for the operative clarification.

**chrome-blog-createimagebitmap**
URL: https://developer.chrome.com/blog/createimagebitmap-in-chrome-50
Accessed: 2026-07-09
Quote: "if you call `createImageBitmap()` on the main thread, that's exactly where the decoding will be done... To truly decode off the main thread, you need to call it inside a Web Worker."

**mdn-rvfc**
URL: https://developer.mozilla.org/en-US/docs/Web/API/HTMLVideoElement/requestVideoFrameCallback
Accessed: 2026-07-09
Quote: Fires "when a new video frame is sent to the compositor," at the lower of video frame rate and browser paint refresh rate.

**webdev-rvfc**
URL: https://web.dev/articles/requestvideoframecallback-rvfc
Accessed: 2026-07-09
Quote: "it's possible the API is one vsync late relative to when a video frame is rendered" — because rVFC runs on the main thread while compositing happens on the compositor thread.

**webcodecs-explainer**
URL: https://github.com/w3c/webcodecs/blob/main/explainer.md
Accessed: 2026-07-09
Quote: "Paint every video frame ASAP for lowest latency"; "IMPORTANT: Release the frame to avoid stalling the decoder." Also describes MSE's low-latency mode as "implicit, not standardized, and not supported by all major browsers."

**chrome-webcodecs-docs**
URL: https://developer.chrome.com/docs/web-platform/best-practices/webcodecs
Accessed: 2026-07-09
Quote: "the WebCodecs API does all the heavy lifting asynchronously and off the main thread... it's preferable to move handling of individual frames and encoded chunks into a web worker."

**cdp-screencast-bug**
URL: https://issues.chromium.org/issues/40934921 ; https://chromedevtools.github.io/devtools-protocol/tot/Page/
Accessed: 2026-07-09
Quote: Chromium engineer commit note: "in reality, calling screencastFrameAck or not does not make any difference. The frames are still sent by the backend at the same rate, without waiting." Fixed so the backend "wait[s] for `Page.screencastFrameAck` to be called after it has reached the maximum number of inflight frames."

**webrtc-insertable-streams**
URL: https://github.com/w3c/webrtc-insertable-streams (explainer)
Accessed: 2026-07-09
Quote: "queueing issues can be mitigated at the sender by not queueing, instead preferring to discard frames or not generating them in the first place."

**nng-powers-of-10**
URL: https://www.nngroup.com/articles/powers-of-10-time-scales-in-ux/
Accessed: 2026-07-09
Quote: "0.1 second is the response time limit if you want users to feel like their actions are directly causing something to happen on screen... to create the illusion of direct manipulation, a user interface must be faster than 0.1 second."

**webdev-rail**
URL: https://web.dev/articles/rail
Accessed: 2026-07-09
Quote: "Respond to user input in under 100 ms"; because other work competes for that window, "it's safe to assume only the remaining 50 ms is available for actual input handling." Page also notes Core Web Vitals has since superseded RAIL as Google's recommended model.

**nvidia-reflex-docs**
URL: https://developer.nvidia.com/performance-rendering-tools/reflex
Accessed: 2026-07-09
Quote: Defines system latency as peripheral + render/render-queue + display latency; "Frame Warp... samples the latest mouse position and warps the rendered frame just before scan out to the most up-to-date camera position." Vendor documentation — treat any specific ms/percentage figures as NVIDIA-reported, not independently verified.

**digital-foundry-stadia**
URL: (Digital Foundry GDC 2019 Stadia hands-on coverage, games-press outlet)
Accessed: 2026-07-09
Quote: Measured approximately 166ms button-to-photon latency on Assassin's Creed Odyssey via Stadia at 1080p/30fps. Independent measurement, not a primary vendor source — cite as a real-world baseline only.

## SYNTHESIS

Every mature remote-interaction system converges on the same three-part answer to "how do you mask latency you can't eliminate," and none of them try to make the round trip itself invisible — they route around it:

**1. Never let the cursor (or any locally-owned, locally-predictable state) wait on the network.** RFC 6143 states this as explicit design intent in 2011 (or earlier, since RFB predates the RFC); RDP, Guacamole, and noVNC all independently converged on the identical mechanism: ship a cursor bitmap once, then move/render it locally on every subsequent frame, with the network only used to *change* the cursor image, not to move it. The RDP cursor-shadow failure mode is instructive: the one time RDP can't render the cursor locally (because a visual effect requires server-side blending), the perceived-latency win evaporates and users report exactly "laggy/glitchy" — a strong structural match for the reported "focusing/blurring inputs feels glitchy" complaint. That symptom pattern (something that *should* be pure client-side state pierces through to a round trip) is the first thing to audit in remote-surface: is focus/blur state change requiring a server round-trip before the UI reflects it, when it could be optimistically applied client-side and reconciled/corrected if the server disagrees?

**2. Treat the browser's own pointer-event APIs as underused, standards-track local-prediction tools.** `getPredictedEvents()` and `getCoalescedEvents()` are shipped, standardized, zero-dependency mechanisms to draw ahead of the network and reduce outgoing event volume simultaneously — this is a near-free win that doesn't require inventing a prediction model. noVNC's `MOUSE_MOVE_DELAY = 17ms` throttle is the send-side complement: don't flood the wire with every native mousemove, batch to a fixed interval close to one frame at 60fps.

**3. On the decode/paint path, off-thread decode and aggressive frame freshness beat trying to shrink network latency.** For CDP screencast specifically, the Chromium `screencastFrameAck` bug is the single highest-leverage finding: if remote-surface's CDP backend (or the Chromium version it targets) doesn't correctly gate frame delivery on acks, frames queue server-side under any load and *feel* laggy even with zero network latency — which matches the reported "feels laggy even on the same host" symptom almost exactly. This should be verified directly: confirm the target Chromium build honors ack-gated flow control, and confirm the client acks every received frame promptly rather than batching acks. For the WebRTC/n.eko backend, the playout-delay extension (min=max=0) and WebCodecs' "paint ASAP, release frames promptly" guidance are the direct levers; `requestVideoFrameCallback` over polling `<video>.currentTime` in a rAF loop is a smaller but real win, with the caveat that it's not perfectly frame-accurate (compositor-thread vs main-thread skew).

Priority order for `@opendatalabs/remote-surface`, cheapest-and-highest-leverage first: (a) verify CDP ack flow control isn't silently defeated; (b) render the OS cursor and any focus/blur/hover visual state fully client-side, reconciling against server state only when it actually diverges, rather than round-tripping every interaction; (c) adopt `getPredictedEvents()`/coalesced events on the input path; (d) move video frame decode/paint off the main thread (Worker + WebCodecs, or at minimum `createImageBitmap` inside a Worker) and prefer newest-frame-wins over any queuing. The 100ms Nielsen / 50ms RAIL thresholds are the budget to hold the whole pipeline against, not just network RTT.

Caveats: Parsec's specific architecture could not be verified against a primary source (only a generic patent filing and marketing copy were found) and should not be cited as evidence for any specific technique. Likewise, "always discard stale frames at render time" is a widely asserted cloud-gaming pattern but the strongest primary backing found is WebCodecs' "release frames promptly" and Insertable Streams' "discard over queue" guidance — real but adjacent, not a named cloud-gaming engineering blog. An arXiv paper with a WebRTC/latency-adjacent title surfaced during the sweep but has strong signatures of being non-genuine (implausible "patentable UX governor" framing) and was excluded entirely — do not resurrect it if it resurfaces in a future search.
