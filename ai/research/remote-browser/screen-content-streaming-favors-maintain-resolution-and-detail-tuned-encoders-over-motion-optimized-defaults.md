---
title: "Streaming an interactive browser (text/login-form content) should use contentHint='detail'/'text' + degradationPreference='maintain-resolution' with screen-content-specific GStreamer/encoder tuning, not motion-video defaults; CDP Page.startScreencast trades encoder complexity for per-frame bytes and has no dirty-rect optimization"
date: 2026-07-09
topic: remote-browser
tags: [webrtc, contenthint, degradationpreference, screencast, cdp, neko, gstreamer, vp8, av1, text-legibility]
status: draft
sources: [mst-content-hint-ed, mst-content-hint-tr, contenthint-origin-issue, webrtchacks-av1-meet, chromium-throttled-capture-design, gstreamer-vpxenc-docs, cdp-startscreencast-spec, neko-v3-config, guacamole-protocol-manual]
---

## CLAIMS

### contentHint and degradationPreference (W3C spec, directly fetched)

- The W3C Media Capture content hints spec defines exactly four valid `contentHint` values for a video `MediaStreamTrack`: `""`, `"motion"`, `"detail"`, `"text"`. [mst-content-hint-ed]
- `"detail"` is defined as: video where details are extra important, generally applicable to "presentations or web pages with text content, painting or line art." [mst-content-hint-ed]
- `"text"` is defined as the stronger variant: extra-important detail plus content where "significant sharp edges and areas of consistent color can occur frequently," generally applicable to "presentations or web pages with text content." [mst-content-hint-ed]
- The spec is normative on `RTCRtpSender` behavior: unless an app explicitly sets `degradationPreference`, a sender transmitting a track with `contentHint="motion"` MUST use `maintain-framerate`; a track with `contentHint="detail"` or `contentHint="text"` MUST use `maintain-resolution`. [mst-content-hint-ed]
- The spec additionally requires that for `contentHint="text"` tracks encoded with AV1, the sender activate AV1's text-mode encoding tools. [mst-content-hint-ed]
- The current published version is a W3C Working Draft (Web Real-Time Communications Working Group), dated 2025-09-19. [mst-content-hint-tr]
- A Chromium/WebRTC engineer (GitHub user "pbos") states that Chromium's WebRTC stack has historically hard-coded different encoder assumptions for screencast/desktop-capture sources vs. webcam sources — screencast content is assumed non-downscalable because "text will lose its intelligibility" if downscaled — and that `contentHint` was built specifically as an app-level override of that built-in assumption. [contenthint-origin-issue]

### AV1 screen-content coding is live in Chromium today (independent engineering source)

- libWebRTC (used by Chrome/Chromium) has been enabling AV1 screen-content-coding mode for `MediaStreamTrack`s from screen/tab capture, or for any track with `contentHint` set to `"detail"`, for a period of time predating a December 2023 article — measured to reduce frame size/bitrate by roughly 25%+ when engaged. [webrtchacks-av1-meet]
- As of that same article, Google Meet's own screen-share pipeline does not use this AV1 text/detail mode — it continues to use VP8 simulcast on a separate `RTCPeerConnection` for screen sharing, despite the capability being available in the underlying browser stack. [webrtchacks-av1-meet]

### Static-vs-motion tradeoff philosophy (Chromium's own design doc)

- Chromium's official screen-capture design documentation states the UX goal for interactive/mostly-static remote-desktop-style content is explicitly low end-to-end latency plus high per-frame quality ("crisp and readable" text/diagrams) — not smooth motion. [chromium-throttled-capture-design]
- The same document states the opposite priority for animated content: dropping frames is "a very perceivable event and should be avoided at all costs," so the system should accept higher latency and lower quality instead of dropping frames when content is animating. [chromium-throttled-capture-design]
- The design deliberately rate-limits capture-resolution changes (no more than once per 3 seconds) because most video encoders must emit a full keyframe whenever frame dimensions change. [chromium-throttled-capture-design]
- The document states resolution has a larger effect on pixel rate (bitrate/CPU cost) than framerate does for animated content, while framerate has comparatively less effect on perceived UX for that same content — informing why resolution, not framerate, is the dimension to protect. [chromium-throttled-capture-design]
- The document states that downscaling to non-standard/arbitrary resolutions specifically causes "sharp lines and text in the source content image" to "appear fuzzy and/or distorted" in the result — the direct mechanism connecting resolution-preservation to text legibility. [chromium-throttled-capture-design]

### GStreamer vp8enc — the actual encoder n.eko's default pipeline can use (official plugin docs, directly fetched)

- GStreamer's `vp8enc` element exposes a `static-threshold` property (motion-detection threshold, integer) whose official documentation explicitly recommends setting it to `100` "for screen/window sharing," versus a generic default of `1`. [gstreamer-vpxenc-docs]
- `vp8enc`'s `deadline` property (microseconds allowed per frame; `0` = best quality, `1` = realtime) defaults to `1000000` — i.e., best-quality/non-realtime encoding mode unless a pipeline explicitly overrides it to `1` for realtime operation. [gstreamer-vpxenc-docs]
- `vp8enc`'s `resize-allowed` property (permits the encoder to spatially downscale frames under bitrate pressure) defaults to `false`. [gstreamer-vpxenc-docs]
- `vp8enc`'s `keyframe-max-dist` property (maximum frames between keyframes) defaults to `128`. [gstreamer-vpxenc-docs]

### CDP Page.startScreencast — exact parameters (official spec, directly fetched)

- `Page.startScreencast` is marked Experimental in the Chrome DevTools Protocol spec and accepts exactly five optional parameters: `format` (`jpeg` or `png`), `quality` (integer 0–100, JPEG only), `maxWidth` (integer), `maxHeight` (integer), and `everyNthFrame` (integer, "Send every n-th frame"). [cdp-startscreencast-spec]
- No parameter in the `Page.startScreencast` spec provides dirty-rectangle, delta-frame, or change-detection behavior — every emitted frame is a full-frame capture; `everyNthFrame` is the only frame-rate decimation control. [cdp-startscreencast-spec]

### n.eko's actual configuration surface (official docs, directly fetched)

- n.eko's default WebRTC video codec is VP8, set via `NEKO_CAPTURE_VIDEO_CODEC` (default `"vp8"`), and is overridable to other codecs; bitrate is set via `NEKO_CAPTURE_BROADCAST_VIDEO_BITRATE` (default `4096` KB/s), and an h264-specific encoder speed preset is exposed via `NEKO_CAPTURE_BROADCAST_PRESET` (default `"veryfast"`). [neko-v3-config]
- n.eko exposes a full custom GStreamer pipeline override, either as a single-pipeline string (`NEKO_CAPTURE_VIDEO_PIPELINE`) or a JSON-encoded multi-pipeline object (`NEKO_CAPTURE_VIDEO_PIPELINES`) — meaning encoder-level properties such as `vp8enc`'s `static-threshold`/`deadline`/`resize-allowed` are reachable through this override without patching n.eko itself. [neko-v3-config]
- n.eko ships a first-class, separate JPEG screencast capture mode independent of its WebRTC path, configured via `NEKO_CAPTURE_SCREENCAST_ENABLED` (default `false`), `NEKO_CAPTURE_SCREENCAST_PIPELINE` (custom GStreamer pipeline string), `NEKO_CAPTURE_SCREENCAST_QUALITY` (default `"60"`), and `NEKO_CAPTURE_SCREENCAST_RATE` (default `"10/1"`, i.e. 10 fps). [neko-v3-config]
- n.eko exposes an experimental WebRTC bandwidth estimator (`NEKO_WEBRTC_ESTIMATOR_ENABLED`, default `false`) that can dynamically switch between configured pipelines based on estimated available bandwidth, with tunables including `NEKO_WEBRTC_ESTIMATOR_INITIAL_BITRATE` (default `1000000`), `NEKO_WEBRTC_ESTIMATOR_DIFF_THRESHOLD` (default `0.15`), and `NEKO_WEBRTC_ESTIMATOR_DOWNGRADE_BACKOFF` (default `"10s"`). [neko-v3-config]

### Apache Guacamole — region-based streaming as an alternative architecture (official manual, directly fetched)

- The Guacamole protocol streams arbitrary rectangles of PNG/JPEG/WebP image data into named layers/buffers rather than full frames, and provides a server-side `copy` instruction to duplicate a region of already-transferred image data to another location without re-sending pixel data — explicitly modeled on VNC/RDP's screen-region-copy and caching semantics, generalized so on-screen and off-screen image storage use the same mechanism. [guacamole-protocol-manual]

## SOURCES

**mst-content-hint-ed**
URL: https://w3c.github.io/mst-content-hint/
Accessed: 2026-07-09
Quote: "If this {{MediaStreamTrack}}'s {{MediaStreamTrack/kind}} attribute is \"video\", and _value_ is not one of \"\", \"motion\", \"detail\" or \"text\", abort these steps." Detail: "The track should be treated as if video details are extra important. This is generally applicable to presentations or web pages with text content, painting or line art." Text: "The track should be treated as if video details are extra important, and that significant sharp edges and areas of consistent color can occur frequently. This is generally applicable to presentations or web pages with text content." Degradation preference: "An RTCRtpSender transmitting a MediaStreamTrack for which a contentHint attribute has been set MUST use the following degradation preferences, unless an explicit degradationPreference attribute has been set: For a video track with the attribute value 'motion', use maintain-framerate. For a video track with the attribute value 'detail', use maintain-resolution. For a video track with the attribute value 'text', use maintain-resolution." Plus: "For a video track with the attribute value 'text', if the encoding codec is AV1, activate encoding tools for 'text' mode."

**mst-content-hint-tr**
URL: https://www.w3.org/TR/mst-content-hint/
Accessed: 2026-07-09
Quote: W3C Working Draft, Web Real-Time Communications Working Group, dated 19 September 2025.

**contenthint-origin-issue**
URL: https://github.com/w3c/mediacapture-main/issues/478
Accessed: 2026-07-09
Quote: "content is treated differently whether it's screencast or usb webcam devices. It's assumed that screencast can't be downscaled, or text will lose its intelligibility... I created an experimental feature (http://crbug.com/653531, https://wicg.github.io/mst-content-hint/) that permits overriding this assumption" — GitHub user "pbos" (Chromium/WebRTC contributor).

**webrtchacks-av1-meet**
URL: https://webrtchacks.com/the-hidden-av1-gift-in-google-meet/
Accessed: 2026-07-09
Quote: "libWebRTC has been enabling this particular mode for MediaStreamTracks coming from screen sharing (or with a contentHint set to 'detail') for a while now"; "screen sharing (or rather tab sharing which is more privacy friendly) continues to use VP8 simulcast on a separate RTCPeerConnection"; describes "a 25%+ reduction in the frame sizes and hence bitrate" when AV1 screen-content mode is engaged. Author: Philipp Hancke, published 2023-12-19, webrtcHacks (independent WebRTC-engineering blog).

**chromium-throttled-capture-design**
URL: https://www.chromium.org/developers/design-documents/auto-throttled-screen-capture-and-mirroring/
Accessed: 2026-07-09
Quote: "the user experience is maximized when end-to-end latency is low, so that user input actions have an immediate result on the remote display; and also when video frame quality is high, so text and/or diagrams are crisp and readable." On animated content: "Dropping frames is a very perceivable event and should be avoided at all costs. Thus, the system should increase end-to-end latency and decrease video frame quality to compensate." On resolution-change throttling: "capture resolution changes are limited to occur no more than once every three seconds," because "most encoders would need to emit a full key frame whenever frame sizes change." On resolution vs. framerate: "the frame resolution has a much larger impact on the pixel rate and, for animated content, has a lesser impact on the end-user experience." On downscale artifacts: "sharp lines and text in the source content image would appear fuzzy and/or distorted in the down-scaled result."

**gstreamer-vpxenc-docs**
URL: https://gstreamer.freedesktop.org/documentation/vpx/GstVPXEnc.html
Accessed: 2026-07-09
Quote: "\"static-threshold\" gint — Motion detection threshold... Recommendation is to set 100 for screen/window sharing... Default value: 1." "\"deadline\" gint64 — Deadline per frame (usec, 0=best, 1=realtime)... Default value: 1000000." "\"resize-allowed\" gboolean — Allow spatial resampling... Default value: false." "\"keyframe-max-dist\" gint — Maximum distance between keyframes (number of frames)... Default value: 128."

**cdp-startscreencast-spec**
URL: https://chromedevtools.github.io/devtools-protocol/tot/Page/#method-startScreencast
Accessed: 2026-07-09
Quote: Marked "Experimental." Parameters: `format` ("Image compression format", enum `jpeg`/`png`, optional), `quality` ("Compression quality from range [0..100]", optional), `maxWidth` ("Maximum screenshot width", optional), `maxHeight` ("Maximum screenshot height", optional), `everyNthFrame` ("Send every n-th frame", optional).

**neko-v3-config**
URL: https://neko.m1k1o.net/docs/v3/configuration
Accessed: 2026-07-09
Quote: "NEKO_CAPTURE_VIDEO_CODEC = \"vp8\"" (video codec to be used); "NEKO_CAPTURE_BROADCAST_VIDEO_BITRATE = 4096" (broadcast video bitrate in KB/s); "NEKO_CAPTURE_BROADCAST_PRESET = \"veryfast\"" (broadcast speed preset for h264 encoding); "NEKO_CAPTURE_VIDEO_PIPELINE" (shortcut for configuring only a single gstreamer pipeline); "NEKO_CAPTURE_VIDEO_PIPELINES" (pipelines config used for video streaming, JSON object); "NEKO_CAPTURE_SCREENCAST_ENABLED = false"; "NEKO_CAPTURE_SCREENCAST_PIPELINE" (gstreamer pipeline used for screencasting); "NEKO_CAPTURE_SCREENCAST_QUALITY = \"60\""; "NEKO_CAPTURE_SCREENCAST_RATE = \"10/1\"" (screencast frame rate); "NEKO_WEBRTC_ESTIMATOR_ENABLED = false"; "NEKO_WEBRTC_ESTIMATOR_INITIAL_BITRATE = 1000000"; "NEKO_WEBRTC_ESTIMATOR_DIFF_THRESHOLD = 0.15"; "NEKO_WEBRTC_ESTIMATOR_DOWNGRADE_BACKOFF = \"10s\"".

**guacamole-protocol-manual**
URL: https://guacamole.apache.org/doc/gug/guacamole-protocol.html
Accessed: 2026-07-09
Quote: "The Guacamole protocol provides a method of sending an arbitrary rectangle of image data and placing it either within a buffer or in a visible rectangle of the screen." "Raw image data in the Guacamole protocol is streamed as PNG, JPEG, or WebP data over a stream allocated with the 'img' instruction." "[B]oth VNC and RDP provide a means of copying a region of screen data and placing it somewhere else within the same screen, and RDP provides an additional means of copying data to a cache; Guacamole reduces this concept further, as both on-screen and off-screen image storage is the same."

## SYNTHESIS

The spec and Chromium-engineering evidence converge cleanly: for text/UI content, the correct settings are `contentHint = "detail"` or `"text"` on the captured `MediaStreamTrack`, which per the W3C spec normatively forces `degradationPreference = maintain-resolution` unless overridden — meaning the browser will sacrifice framerate before it sacrifices resolution/sharpness under bandwidth pressure. This is the opposite of GStreamer/vp8enc's out-of-the-box behavior in a typical n.eko pipeline, which defaults to `resize-allowed=false` (good) but also defaults to `deadline=1000000` (non-realtime, i.e. not tuned at all for live streaming unless a pipeline override already sets it to `1`) and `static-threshold=1`, i.e. the encoder is not told this is largely-static screen content unless a pipeline explicitly sets `static-threshold=100` as GStreamer's own docs recommend.

Concretely actionable for our two backends:

**n.eko / WebRTC path.** Two levers exist and are independently confirmed reachable in n.eko's real config surface: (1) `contentHint` is a browser-tab/capture-source-side setting, not something n.eko's server config controls directly — if remote-surface's browser-capture step (or a Chromium flag/extension driving the capture tab) can set `contentHint = "detail"` on the captured track before it's fed into the WebRTC sender, do so; this is the single highest-leverage, spec-guaranteed lever found, and per the webrtcHacks finding it is already live in Chromium today for AV1 if AV1 is negotiated. (2) Independently of contentHint, n.eko's `NEKO_CAPTURE_VIDEO_PIPELINE`/`NEKO_CAPTURE_VIDEO_PIPELINES` override lets us hand-tune the GStreamer encoder directly — set `vp8enc`'s `static-threshold=100` (screen-share-recommended) and confirm `deadline` is explicitly `1` (realtime) rather than relying on the library default of `1000000`; `resize-allowed` is already `false` by default, which is correct. If codec choice is flexible, consider whether AV1 is viable in the target Chromium/GStreamer build to get SCC tooling "for free" per the webrtcHacks finding — VP8 (n.eko's default) has no equivalent screen-content-coding mode.

**CDP `Page.startScreencast` fallback path.** The spec confirms this is a naive full-frame-per-tick mechanism with no dirty-rect/delta optimization — its only tuning surface is `format`/`quality`/`maxWidth`/`maxHeight`/`everyNthFrame`. For static login-form content this is actually a reasonable fit despite the naivety: a full JPEG re-encode of a static frame at high `quality` avoids all of the motion-codec blur/macroblocking problems entirely, at the cost of higher steady-state bytes-per-frame than a properly-tuned WebRTC path would use. Given n.eko's own default screencast rate is 10 fps (not full framerate), this mode already assumes low-motion/UI-style content by default — raise `quality` for text sharpness and keep `everyNthFrame`/rate low since there's no cost benefit to polling faster than the content actually changes. Guacamole's region/dirty-rect architecture is the conceptually "correct" answer for mostly-static content (only re-send changed regions, use the `copy` instruction for anything that hasn't moved) but neither CDP screencast nor n.eko's WebRTC path implement anything equivalent — that's a structural gap between what CDP+n.eko offer today and what a purpose-built remote-desktop protocol offers, not a tuning knob we can turn on.

**Priority order:** (1) set `contentHint` on the WebRTC capture track — spec-guaranteed, zero GStreamer changes required; (2) add `static-threshold=100` and force `deadline=1` in the n.eko GStreamer pipeline override; (3) for the CDP screencast fallback, raise JPEG quality and don't over-poll framerate, since the format has no motion-codec blur risk in the first place; (4) if AV1 negotiation is feasible in the deployed browser/GStreamer versions, evaluate it for its screen-content-coding bitrate win specifically on text-heavy tabs.

**Confidence notes:** all CLAIMS above were verified by directly fetching the cited primary source (W3C spec, Chromium design doc, GStreamer plugin docs, CDP spec, n.eko's live docs site, Guacamole's official manual, and a named-author WebRTC-insider engineering blog). A broader research pass also surfaced weaker, not-independently-verified leads worth a follow-up if this area gets revisited: KasmVNC's content-adaptive per-rectangle quality tiers (official docs page timed out on fetch; only cross-checked against a community wiki, not verified verbatim), x264's `tune=stillimage` vs `tune=zerolatency` distinction (forum-sourced, no official x264 web docs exist), and n.eko's own v2-era example pipeline reportedly using `tune=zerolatency` (found via search snippet, not re-fetched). No rigorous first-party or third-party benchmark comparing WebRTC screen-share vs. CDP-screencast polling specifically for text legibility was found anywhere — that gap in the public record still stands.
