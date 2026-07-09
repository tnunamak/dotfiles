---
title: "Production remote-browser/browser-session vendors fix the viewport at session start and scale or letterbox on the client, rather than resizing the remote browser to match the viewer container in real time"
date: 2026-07-09
topic: remote-browser
tags: [viewport, remote-browser, cdp, neko, kasmvnc, novnc, chromium-min-width, browserbase, streaming]
status: draft
sources: [browserbase-viewports, browserbase-live-view, steel-quickstart, steel-mobile-mode, steel-hitl, hyperbrowser-session-params, hyperbrowser-live-view, browserless-live-url, browserless-screencast, anchor-live-view, anchor-start-session, cloudflare-puppeteer, cloudflare-browser-run, kasmvnc-video-rendering, hyperbeam-web-sdk, kernel-blog-replays, neko-issue-595, neko-config, novnc-embedding, novnc-api, aws-live-view-sdk, aws-live-view-docs, chromium-min-width-issue, chromium-min-width-support-thread, cdp-device-metrics-override, chrome-headless-screen-config, cdp-set-window-bounds, cdp-set-window-bounds-bug]
---

## CLAIMS

- Browserbase sets viewport width/height once at session-creation time via `browserSettings.viewport`; no documented API resizes the viewport during an active session. [browserbase-viewports]
- Browserbase "Verified" sessions use a fixed viewport managed by Browserbase; custom viewport dimensions are explicitly unsupported for that mode. [browserbase-viewports]
- Browserbase's Live View embeds the session as a plain `<iframe src="{liveViewLink}">`; the docs describe a "mobile live view" only as choosing a mobile-shaped viewport at session creation, not as the iframe/container driving remote resize. [browserbase-live-view]
- Steel.dev configures viewport via a `dimensions` object at session creation, plus a separate `deviceConfig: { device: "mobile" }` "Mobile Mode" that sets a fixed mobile-shaped viewport — a discrete preset, not a live client-driven resize. [steel-quickstart] [steel-mobile-mode]
- Steel's human-in-the-loop docs give iframe-sizing guidance ("recommended minimum height: 600px") as an operator/CSS recommendation, not as a mechanism that resizes the remote browser. [steel-hitl]
- Hyperbrowser sets screen-resolution emulation via a session-parameters object at session creation; no documented mid-session or client-driven resize was found. [hyperbrowser-session-params] [hyperbrowser-live-view]
- Browserless's LiveURL feature exposes an explicit `resizable` boolean: default/true resizes the underlying browser to match the end user's screen size; false keeps the browser viewport fixed and instead maintains aspect ratio on the client side. [browserless-live-url]
- Browserless documents that changing `page.setViewport()` mid-recording during screencast can visibly distort/stretch the output, implying viewport is normally treated as fixed-for-the-session. [browserless-screencast]
- Anchor Browser sets `browser.viewport.{width,height}` in the session-creation payload (`POST /v1/sessions`); no dedicated dynamic-resize endpoint is documented. [anchor-start-session] [anchor-live-view]
- Cloudflare Browser Rendering is headless-only in its Puppeteer binding; viewport is set via the standard one-shot `page.setViewport({width, height, deviceScaleFactor})` call, not tied to any live client container. [cloudflare-puppeteer]
- Cloudflare's "Browser Run" Live View streams a headless session via CDP (`devtoolsFrontendUrl` / `live.browser.run`), observing a fixed-viewport headless session rather than adapting a headful remote window to the viewer. [cloudflare-browser-run]
- KasmVNC (the substrate under Kasm Workspaces) has server-side dynamic-resize video modes — "Medium," "High," and "Extreme" — documented to match the resolution of the client and automatically resize if the client size changes. [kasmvnc-video-rendering]
- KasmVNC's "Static" mode instead hardcodes server resolution (1280×720) and scales the image client-side, i.e. KasmVNC offers both the "remote adapts" and "client scales a fixed frame" models as selectable quality tiers. [kasmvnc-video-rendering]
- Hyperbeam's Web SDK ties the remote virtual browser's streamed resolution to the CSS dimensions of the client-supplied container element passed to `Hyperbeam(container, embedURL, opts)`, i.e. client-container-drives-remote-size — architecturally the closest commercial analog to container-driven adaptation found, though undocumented as using Xorg-modeline or CDP techniques specifically. [hyperbeam-web-sdk]
- neko (m1k1o/neko) — the open-source WebRTC screen-streaming project both Kernel's live-view stack and remote-surface's own streaming path build on — supports only discrete resolution changes: a startup default via `NEKO_SCREEN=<width>x<height>@<fps>`, an admin-only GUI resolution switcher, and (later versions) `xrandr`-based arbitrary resolution via API, but not continuous auto-resize-to-container. [neko-config]
- An open neko GitHub issue (#595) explicitly requests continuous "resize-follows-container" behavior, contrasting neko unfavorably with WebTop/Selkies-style streaming, and had no maintainer response at time of research. [neko-issue-595]
- Kernel (onkernel.com), a neko-forking Browserbase competitor, reported (per search-engine-cached blog content, not independently re-fetched — see confidence note in SOURCES) that changing X11 display resolution while both its WebRTC live-view and ffmpeg-replay pipelines were active caused crashes/corruption, and that it chose to lock display size during replays rather than solve dynamic resize coordination across the two pipelines. [kernel-blog-replays]
- noVNC documents a `resize` parameter with three modes: `off`, `scale` (client-side canvas scaling of a fixed framebuffer; `scaleViewport=true`), and `remote` (sends the RFB `resizeSession` request asking the server to actually change its X display resolution; `resizeSession=true`) — the direct VNC-world analog to "fixed+letterboxed" vs. "remote adapts." [novnc-embedding] [novnc-api]
- AWS Bedrock AgentCore's `BrowserLiveView` React component (DCV-based) auto-scales the rendered stream to fit its container while preserving aspect ratio, but the remote browser's actual viewport is set separately via `startSession()` and must be manually kept in sync with `remoteWidth`/`remoteHeight` props; mismatches produce cropping or black bars. [aws-live-view-sdk] [aws-live-view-docs]
- Chrome/Chromium enforces a minimum browser window width, community-reported (support-forum sourced, not confirmed against Chromium source) as roughly 500px on Windows/Linux and 400px on Mac, tracked by a long-running Chromium issue ("Chrome window minimum width is now absurdly high," active since around Chrome 97). [chromium-min-width-issue] [chromium-min-width-support-thread]
- The documented, reliable workaround for viewport widths below the OS window-width floor is not window/flag manipulation — `--window-size` is reported unreliable or ignored under newer headless Chrome/ChromeDriver — but CDP's `Emulation.setDeviceMetricsOverride`, which overrides `window.screen.width/height`, `window.innerWidth/innerHeight`, and viewport-meta/media-query evaluation independent of the real OS window size, plus a `mobile` flag for touch/UA emulation. [cdp-device-metrics-override]
- Chrome headless has since added a `--screen-info` flag and CDP `Emulation.addScreen`/`Emulation.removeScreen` (Puppeteer-supported) to define virtual screen geometry for narrow/mobile-like screens in headless mode without touching real OS window sizing. [chrome-headless-screen-config]
- CDP's `Browser.setWindowBounds` sets the actual OS-level window position/size (`left`, `top`, `width`, `height`, `windowState`) and is distinct from `Emulation.setDeviceMetricsOverride` (which overrides only content-viewport metrics); it is subject to the same OS/Chrome minimum-width floor, and a filed Google Issue Tracker bug reports it "does not behave as expected" in some configurations. [cdp-set-window-bounds-bug]

## SOURCES

**browserbase-viewports**
URL: https://docs.browserbase.com/features/viewports
Accessed: 2026-07-09
Quote: "Use the `viewport` field when creating a session to specify the desired width and height... Verified sessions use a fixed viewport managed by Browserbase. Custom viewport dimensions are not supported with Verified."

**browserbase-live-view**
URL: https://docs.browserbase.com/features/session-live-view
Accessed: 2026-07-09
Quote: "<iframe src=\"{liveViewLink}\" sandbox=\"allow-same-origin allow-scripts\" allow=\"clipboard-read; clipboard-write\" />... Show a mobile live view by setting a session's viewport."

**steel-quickstart**
URL: https://docs.steel.dev/overview/sessions-api/quickstart
Accessed: 2026-07-09
Quote: session creation accepts a `dimensions` config object for viewport width/height.

**steel-mobile-mode**
URL: https://docs.steel.dev/overview/sessions-api/mobile-mode
Accessed: 2026-07-09
Quote: "`deviceConfig: { device: \"mobile\" }`" aligns user agent, viewport, and touch capabilities to a fixed mobile device preset.

**steel-hitl**
URL: https://docs.steel.dev/overview/sessions-api/human-in-the-loop
Accessed: 2026-07-09
Quote: "recommended minimum height: 600px" for the embedding iframe container.

**hyperbrowser-session-params**
URL: https://hyperbrowser.ai/docs/sessions/overview/session-parameters
Accessed: 2026-07-09
Quote: session-parameters object includes screen-resolution emulation settings applied at session creation.

**hyperbrowser-live-view**
URL: https://www.hyperbrowser.ai/docs/sessions/live-view
Accessed: 2026-07-09
Quote: `liveUrl` embedded via iframe; `viewOnlyLiveView` flag; 12-hour token expiry.

**browserless-live-url**
URL: https://docs.browserless.io/bql-schema/operations/mutations/live-url
Accessed: 2026-07-09
Quote: "resizable ... When true (default), the browser resizes to match the end-user's screen size. When false, the underlying browser will retain it's current viewport, and the end user's screen will maintain the appropriate aspect ratio."

**browserless-screencast**
URL: https://docs.browserless.io/docs/screencast
Accessed: 2026-07-09
Quote: viewport is set via `page.setViewport()`; docs warn that changing viewport mid-recording can visibly distort/stretch output.

**anchor-live-view**
URL: https://docs.anchorbrowser.io/advanced/browser-live-view
Accessed: 2026-07-09
Quote: describes headful vs. headless live-view URL creation, one-time URLs; no dynamic-resize mechanism documented.

**anchor-start-session**
URL: https://docs.anchorbrowser.io/api-reference/browser-sessions/start-browser-session
Accessed: 2026-07-09
Quote: `browser.viewport.{width,height}` fields in the session-creation payload.

**cloudflare-puppeteer**
URL: https://developers.cloudflare.com/browser-rendering/platform/puppeteer/
Accessed: 2026-07-09
Quote: standard Puppeteer `page.setViewport({width, height, deviceScaleFactor})` usage, headless-only.

**cloudflare-browser-run**
URL: https://developers.cloudflare.com/browser-run/features/live-view/
Accessed: 2026-07-09
Quote: Live View streams a headless session via CDP `devtoolsFrontendUrl` at `live.browser.run`.

**kasmvnc-video-rendering**
URL: https://github.com/kasmtech/KasmVNC/wiki/Video-Rendering-Options
Accessed: 2026-07-09
Quote: "Modes Medium, High, and Extreme match the resolution of the client and automatically resize if the size of the client changes." Static mode: "resolution is fixed at 1280x720, with the image scaled client side."

**hyperbeam-web-sdk**
URL: https://docs.hyperbeam.com/client-sdk/javascript/reference
Accessed: 2026-07-09
Quote: `Hyperbeam(container, embedURL, opts)` — the streamed resolution follows the CSS dimensions of the supplied container element.

**kernel-blog-replays**
URL: https://www.kernel.sh/blog/introducing-browser-session-replays
Accessed: 2026-07-09
Quote: (search-engine-summarized, not independently re-verified by direct fetch — sign-in/redirect issues defeated direct WebFetch) describes forking neko for WebRTC+gstreamer live view plus ffmpeg replay sharing one X11 display, resolution-change crashes/corruption encountered while testing dynamic resizing, and a decision to lock display size while replays run. CONFIDENCE: moderate — re-verify by manual browser visit before treating as settled.

**neko-issue-595**
URL: https://github.com/m1k1o/neko/issues/595
Accessed: 2026-07-09
Quote: "The content adapts to the slightest change on window resize" (describing WebTop/Selkies as the desired behavior, contrasted with neko's fixed-resolution streaming); suggestion to "take a look at their implementation, or even integrate directly the streaming part Selkies." No maintainer reply found at time of research.

**neko-config**
URL: https://neko.m1k1o.net/docs/v2/configuration
Accessed: 2026-07-09
Quote: `NEKO_SCREEN=<width>x<height>@<fps>` startup default (1280x720@30); admin-only GUI resolution switcher; later versions add `xrandr`-based arbitrary resolution via API/GUI (discrete, not continuous).

**novnc-embedding**
URL: https://github.com/novnc/noVNC/blob/master/docs/EMBEDDING.md
Accessed: 2026-07-09
Quote: "resize: How to resize the remote session if it is not the same size as the browser window. Can be one of `off`, `scale` and `remote`."

**novnc-api**
URL: https://novnc.com/noVNC/docs/API.html
Accessed: 2026-07-09
Quote: `resizeSession` — "if a request to resize the remote session should be sent whenever the container changes dimensions... Disabled by default." `scaleViewport` — "if the remote session should be scaled locally so it fits its container... disabled by default."

**aws-live-view-sdk**
URL: https://github.com/aws/bedrock-agentcore-sdk-typescript/blob/main/docs/BROWSER_LIVE_VIEW.md
Accessed: 2026-07-09
Quote: `remoteWidth`/`remoteHeight` props "must match the viewport dimensions used in startSession()"; mismatch produces "cropping or black bars"; default 1920×1080.

**aws-live-view-docs**
URL: https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/browser-dcv-integration.html
Accessed: 2026-07-09
Quote: describes the DCV-based `BrowserLiveView` component auto-scaling the stream to fit its container while preserving aspect ratio.

**chromium-min-width-issue**
URL: https://issues.chromium.org/issues/41408600
Accessed: 2026-07-09
Quote: "Chrome window minimum width is now absurdly high" (title; thread active since ~Chrome 97). CONFIDENCE: moderate — page is sign-in-walled for full comment history, content summarized via search tooling rather than an authenticated direct fetch.

**chromium-min-width-support-thread**
URL: https://support.google.com/chrome/thread/5443420/chrome-windows-minimum-size-limit
Accessed: 2026-07-09
Quote: community-reported minimum window width "500px (Windows) / 400px (Mac)". CONFIDENCE: community-sourced (support forum), not confirmed against the `kMainBrowserContentsMinimumWidth` Chromium source constant directly.

**cdp-device-metrics-override**
URL: https://developer.chrome.com/blog/screen-configuration-with-chrome-headless
Accessed: 2026-07-09
Quote: describes `Emulation.setDeviceMetricsOverride` overriding `window.screen.width/height`, `window.innerWidth/innerHeight`, and viewport-meta/media-query evaluation independent of OS window size, with a `mobile` flag for touch/UA emulation.

**chrome-headless-screen-config**
URL: https://developer.chrome.com/blog/screen-configuration-with-chrome-headless
Accessed: 2026-07-09
Quote: documents `--screen-info` flag and CDP `Emulation.addScreen`/`Emulation.removeScreen` for defining virtual screen geometry in headless Chrome.

**cdp-set-window-bounds-bug**
URL: https://issuetracker.google.com/issues/381908903
Accessed: 2026-07-09
Quote: "does not behave as expected" (issue title; filed ~Dec 2024 against `Browser.setWindowBounds`). CONFIDENCE: title verified, body sign-in-walled — treat as a reliability flag, not a fully characterized bug.

## SYNTHESIS

**Verdict: ahead of the market.** Every commercial browser-session/remote-browser vendor surveyed (Browserbase, Steel.dev, Hyperbrowser, Browserless, Anchor Browser, Cloudflare Browser Rendering, AWS Bedrock AgentCore) fixes the remote browser's viewport at session-creation time and, at best, scales or letterboxes the stream to fit the client container afterward. None of them resize the actual remote browser viewport continuously to track the viewer's container the way @opendatalabs/remote-surface does.

The single partial exception is Browserless's `resizable` boolean on LiveURL — the only vendor-documented feature found that resizes the *remote* browser to match the end-user's screen, and even that is a one-shot boolean captured at connection time, not the continuous, aligned, gutter-cropped resize loop described in the prompt. Hyperbeam's container-CSS-drives-remote-resolution model is architecturally the closest commercial analog, but it's a general Linux-desktop streamer with no documented Xorg-modeline or CDP-specific technique, so it isn't provably solving the same alignment/precision problem.

The strongest supporting evidence is negative-space evidence: neko — the open-source WebRTC streaming substrate that both remote-surface's own pipeline and a direct competitor (Kernel) build on — has an *open, unaddressed* GitHub issue (#595) asking for exactly this "resize follows container" behavior, unresolved at research time. And Kernel, building on the same substrate, explicitly chose to lock display size during session replay rather than solve the dual-pipeline (WebRTC live view + ffmpeg replay) resize-coordination problem — the same class of problem remote-surface's gutter-crop approach appears to solve. That combination (upstream feature request unmet + a competitor on the same substrate opting out of solving it) is reasonably strong evidence that continuous remote-viewport adaptation aligned to CDP window bounds is currently unclaimed territory in the commercial remote-browser space.

The two genuine prior-art analogs for the *technique* (not the browser-specific application) are both from the VNC world, predating any of today's AI-agent browser vendors: KasmVNC's Medium/High/Extreme modes (true server-side dynamic resize of the X display, selectable alongside a fixed-resolution/client-scaled Static mode) and noVNC's `resize=remote` (RFB `DesktopSize`/`ExtendedDesktopSize` extension — client asks server to change its resolution, vs. `resize=scale` which only rescales a fixed framebuffer client-side). remote-surface's approach is at parity with — arguably ahead of, given the Chrome-CDP-specific alignment work (modelines + `Browser.setWindowBounds` + `Emulation.setDeviceMetricsOverride`) — this VNC-world prior art, and is the first found instance of that pattern applied specifically to a CDP-driven headed Chrome/neko stack rather than a generic X11 desktop.

On the Chrome minimum-width problem specifically: the ~500px/400px OS window-width floor is real and community-documented (though the exact Chromium source constant name/value could not be independently confirmed — flag this as a research gap if it matters for citation precision), and the correct, vendor-recommended escape hatch is CDP's `Emulation.setDeviceMetricsOverride` (content-viewport override, independent of real OS window size) rather than window-sizing flags, which are reported unreliable in modern headless Chrome. This directly validates remote-surface's dual-mechanism design: `Browser.setWindowBounds` (+ Xorg modelines) for headful/n.eko where an actual OS window exists and must be resized, and `Emulation.setDeviceMetricsOverride` for pure-CDP setups where only the content viewport needs to shrink below what the OS window would otherwise allow.

**Confidence caveats:** two sources (the Kernel blog post's exact wording, and the Chromium minimum-width bug thread's full comment history) were only accessible via search-engine summarization, not an authenticated direct fetch — both are flagged inline above. If either becomes load-bearing for an external claim (e.g. a blog post or pitch deck), do a manual browser visit to confirm verbatim wording before quoting.
