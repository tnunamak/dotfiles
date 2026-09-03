> **Headline findings:** Ship a pinned, library-compatible browser build when the connector must be reproducible; use the system Chrome/Edge only as an explicit compatibility mode. Playwright supports hermetic per-project browser bundles, and Puppeteer downloads a matching Chrome-for-Testing build by default.
> Headless Chromium is the cross-platform default. Xvfb is needed for headed Linux CI, but macOS and Windows do not have a direct Xvfb equivalent: use the native logged-in GUI session, or move the browser to a Linux remote-browser service/container when a visible browser is required.
> A Neko-style design is a remote desktop/browser: the desktop app controls a browser over CDP/Playwright WebSocket while a Linux container owns Xorg/desktop capture and optionally streams it over WebRTC. It is useful for human takeover and debugging, but adds a service, transport, display, and session lifecycle.
> Browser resource usage is workload- and page-dependent. Size it with concurrency limits, queueing, timeouts, health checks, and cleanup; do not promise a fixed “MB per tab” budget. Chromium’s sandbox protects browser subprocesses from web content, not the connector, its native dependencies, or the host filesystem/network.
> For PDPP, the practical default is: bundled per-OS Playwright Chromium, headless collection, a visible/remote-browser escape hatch, and OS-level isolation around connector code whenever connectors are not fully trusted.

---
title: "Cross-platform desktop browser runtimes use pinned browser bundles and headless execution, while headed automation needs an OS GUI session or a remote Linux browser"
date: 2026-08-31
topic: cross-platform-connector-runtime
tags: [playwright, puppeteer, chromium, browserless, neko, desktop, sandboxing, cross-platform]
status: settled
sources: [playwright-browsers, playwright-docker, playwright-ci, puppeteer-config, puppeteer-browsers, chrome-headless, chromium-sandbox, browserless, browserless-workers, neko, neko-faq, octoparse, apify-images, windows-interactive-services, apple-lifecycle]
source_session: unknown
---

## CLAIMS

### Packaging: bundled browser versus system browser

- Playwright downloads browser binaries for its supported engines into OS-specific caches: `%USERPROFILE%\\AppData\\Local\\ms-playwright` on Windows, `~/Library/Caches/ms-playwright` on macOS, and `~/.cache/ms-playwright` on Linux [playwright-browsers].
- Playwright can install browsers into the project/package tree with `PLAYWRIGHT_BROWSERS_PATH=0`, which is its documented hermetic-install mode [playwright-browsers].
- Playwright can also launch branded Google Chrome and Microsoft Edge already installed on the machine, but it does not install those branded browsers by default and its browser-cache variable does not control their installation path [playwright-browsers].
- Puppeteer downloads a specific Chrome build by default so that its API works with the expected browser; it can instead launch a different Chrome or Chromium using `executablePath` [puppeteer-config].
- Puppeteer supports skipping downloads, changing its cache directory, selecting a browser, and computing an executable path for a downloaded build through its configuration and `@puppeteer/browsers` APIs [puppeteer-config] [puppeteer-browsers].
- Browser bundles are large: Playwright documents individual installed browser directories in the rough range of 180–281 MB in one example, before application packaging, profiles, caches, fonts, and OS dependencies [playwright-browsers].
- The browser and automation-library versions are a compatibility unit. Playwright warns that a project cannot locate browser executables when the Docker image and project versions do not match; Apify similarly warns that replacing the preinstalled Puppeteer/Chrome pairing can create incompatibility [playwright-docker] [apify-images].

**Implication.** A desktop collector should normally ship or download a pinned browser build per OS/architecture, store it in a versioned application-data directory, and launch it by an explicit path. System Chrome/Edge is useful for user profiles, enterprise policy, extensions, and “use my logged-in browser” workflows, but it creates version drift, installation discovery, policy, and permission failure modes. It should be a deliberate fallback, not the reproducibility baseline.

### Headless, headed, and the display problem

- Chrome’s current headless mode runs without visible UI on Linux, macOS, and Windows; since Chrome 112 it creates platform windows but does not display them, while retaining the normal browser implementation [chrome-headless].
- Playwright launches headless by default. On Linux, its CI documentation says headed execution requires Xvfb and shows `xvfb-run` as the invocation pattern [playwright-ci].
- Xvfb is therefore a Linux display-server solution, not a cross-platform browser requirement. On macOS, the equivalent choices are headless Chrome or a real logged-in macOS GUI session managed by WindowServer/loginwindow; on Windows, the choices are headless Chrome or a real interactive user desktop. This is an architectural inference from Chrome’s cross-platform headless support and the OS session models, not a claim that Apple or Microsoft ships an Xvfb clone [chrome-headless] [apple-lifecycle] [windows-interactive-services].
- macOS `launchd` starts `loginwindow`, which establishes and monitors the user session and user applications; a GUI browser needs that session rather than an X11 display variable [apple-lifecycle].
- Windows services run in session 0 and cannot directly interact with the user as of Windows Vista. Microsoft recommends a separate hidden GUI process created in the interactive user context and connected to the service by IPC [windows-interactive-services].
- A Windows service should not be treated as a headed-browser display host. If a workflow truly requires visible UI automation, launch the browser helper in the logged-in user session, or keep the browser remote; do not depend on service-session windows being visible or interactive [windows-interactive-services].

**Practical modes:**

| Mode | Linux | macOS | Windows | Best use |
| --- | --- | --- | --- | --- |
| Headless | Native, no X server needed | Native, no WindowServer display needed | Native, no interactive desktop needed | Normal collection and CI |
| Headed local | Xorg/Wayland session or Xvfb | Logged-in WindowServer session | Logged-in interactive user session | Debugging, login/CAPTCHA, human takeover |
| Headed remote | Xorg/Xvfb in container plus VNC/WebRTC | Usually a separate Mac host/session | Usually a separate Windows host/session | Shared browser, operator review, persistent profile |

### Neko-style remote-browser pattern

- Neko is a self-hosted virtual browser that runs in Docker and uses WebRTC to stream a desktop to a web client [neko].
- Neko is Linux/Xorg-oriented: its FAQ describes a Debian/Xorg/PulseAudio base and says the recommended Docker setup uses those components; it can also run without Docker on a suitable Linux GUI host [neko-faq].
- Neko is broader than a browser. Its project documentation says it can run other Linux applications and lists automated-browser use cases where Playwright or Puppeteer can be installed and used inside the environment [neko].
- Playwright documents a related but thinner remote pattern: run its browser server in Docker and connect from a host or another machine over a WebSocket endpoint. The client and server Playwright versions must match [playwright-docker].
- Browserless packages the remote-browser pattern as an HTTP/WebSocket service. Its quickstart runs a Docker image, exposes a WebSocket endpoint, and accepts Puppeteer or Playwright connections [browserless].
- Browserless separates browser endpoints such as Chromium and Chrome and offers persistent sessions, reconnects, timeouts, queuing, and concurrency controls as service concerns [browserless].

The Neko-like architecture is therefore:

```text
desktop UI / connector controller
        │  authenticated HTTP, CDP, or Playwright WebSocket
        ▼
browser broker / session supervisor
        ▼
Linux browser runtime: Chromium + user profile + Xorg/Xvfb
        │
        └── optional screen/audio/input stream via WebRTC or VNC
```

It solves cross-OS headed behavior by making the browser OS a server-side Linux concern. It does not remove the need for browser lifecycle, profile isolation, authentication, timeouts, cleanup, or patching. For a desktop product, use it as an opt-in “inspect this live session” or “run in remote browser” path, not as the only runtime unless the product accepts network/service dependence.

### Resource cost and capacity planning

- Playwright recommends one worker in CI to prioritize stability and reproducibility, and says wider parallelization should be enabled only when the host has enough resources [playwright-ci].
- Playwright recommends `--ipc=host` for Chromium in Docker because Chromium can run out of memory and crash without sufficient shared memory; it also recommends `--init` to avoid zombie processes [playwright-docker].
- Browserless exposes concurrency and queue limits because too many sessions can exhaust worker resources; its guidance is to start with a low concurrency value and increase it while monitoring CPU and memory [browserless-workers].
- Browserless uses session timeouts because an unclosed browser can remain alive, consume a concurrency slot, and hold resources until the timeout expires [browserless-workers].
- Browserless provides CPU/memory health thresholds and pressure reporting, which reflects that capacity is a property of the host, workload, and number of live sessions rather than a fixed browser constant [browserless].
- Browser profiles and caches can grow independently of the browser executable. A Browserless issue documents cache, logs, profile, and storage directories growing to very large sizes when long-lived sessions are retained [browserless].
- Apify maintains specialized images containing only the needed browser and warns that adding multiple browser stacks can make an image about three times larger and much slower to build/download [apify-images].

For a desktop runtime, budget four separate resources: executable/download size; per-browser process memory and shared memory; profile/cache/disk growth; and concurrency/CPU during navigation, JavaScript, rendering, PDF, screenshots, and media. Enforce a maximum number of active sessions, per-job timeout, profile cleanup policy, output-size limit, and crash/child-process reaping. Measure representative connector journeys on minimum supported hardware before choosing defaults.

### Per-OS gotchas

- Linux has the richest container recipe, but the recipe is not “just copy Chrome”: the image needs compatible system libraries, fonts, shared memory, and a display stack for headed mode. Playwright’s supported images include browsers and system dependencies, and its documentation says Alpine/musl images are not supported for its Firefox/WebKit browser builds [playwright-docker].
- Linux container root disables the Chromium sandbox in the official Playwright image. For untrusted sites, Playwright recommends a non-root user plus the supplied seccomp profile; it also warns that the image is intended for testing/development and is not recommended as-is for visiting untrusted websites [playwright-docker].
- macOS can run headless Chromium directly, but a headed child needs access to the user GUI session. A launch-at-login/background-agent design and a system daemon are different products; the latter should not assume it can create or control a visible desktop [chrome-headless] [apple-lifecycle].
- Windows can run headless Chromium directly, but a service and an interactive desktop are separate sessions. A service-hosted headed browser needs a user-session helper and IPC, or it should be remote; session 0 is not a dependable visible desktop [chrome-headless] [windows-interactive-services].
- System-browser mode is especially policy-sensitive on macOS and Windows because enterprise browser policy, extensions, profiles, update cadence, and user locks are outside the collector’s release. Bundled Chromium avoids those dependencies but increases installer size and requires its own update/signing path [playwright-browsers] [puppeteer-config].
- Architecture must be part of the release matrix. Browser downloads and Docker images are platform/architecture-specific; Browserless’s published image metadata, for example, exposes separate amd64 and arm64 manifests for Chromium [browserless].

### How the named ecosystems package browsers

- **Playwright:** automation package plus versioned browser downloads; optional hermetic package-local browsers; optional branded system Chrome/Edge; official Linux Docker images with browsers and dependencies; remote `run-server` mode over WebSocket [playwright-browsers] [playwright-docker].
- **Puppeteer:** package install normally downloads a matching Chrome build into a cache; configuration can skip downloads, choose another browser, or launch a system executable; `@puppeteer/browsers` provides explicit browser download and executable-path management [puppeteer-config] [puppeteer-browsers].
- **Browserless:** a browser service, commonly in Docker, that owns browser binaries, launch parameters, sessions, concurrency, queues, timeouts, health, and updates. Clients connect with Puppeteer/Playwright rather than carrying the browser locally [browserless] [browserless-workers].
- **Neko:** a Linux container/desktop image with a browser and display/audio stack, plus a WebRTC streaming/control plane. It is a remote visual desktop pattern, not a native macOS/Windows browser bundle [neko] [neko-faq].
- **Scraping desktop apps:** Octoparse documents both a built-in browser mode embedded in the client and a local Chrome mode for sites needing existing login/CAPTCHA state; it also offers cloud execution. This is a product-level hybrid: deterministic embedded runtime for ordinary tasks, user/system browser for compatibility and identity-sensitive tasks [octoparse].
- **Apify:** the cloud/container model uses specialized Docker base images such as Puppeteer+Chrome, Playwright+Chrome, or Playwright with all supported browsers. It pins the image/library/browser relationship and advises using the smallest image that meets the task [apify-images].

### Does browser automation need OS-level isolation?

- Chromium’s sandbox is a multiprocess, OS-backed boundary intended to limit renderer and other browser subprocesses that process untrusted web content; its implementation differs by OS [chromium-sandbox].
- Chromium documents different platform primitives: Linux uses namespaces and seccomp-BPF, macOS uses Seatbelt, and Windows uses restricted tokens, job objects, alternate desktops, and integrity levels [chromium-sandbox].
- The browser process itself is not uniformly sandboxed. Chromium’s platform table marks the browser process as unsandboxed on all platforms, and lists other platform-specific unsandboxed services [chromium-sandbox].
- Playwright’s Docker guidance explicitly distinguishes trusted end-to-end tests from crawling/scraping untrusted websites and recommends a separate container user plus seccomp for the latter [playwright-docker].
- Therefore, browser sandboxing is not a substitute for isolating the connector runtime. It primarily addresses compromised web-content processes. A connector can still be compromised through its own parser, native module, Node/Python process, browser-launch flags, profile files, or broker/API; it may also retain host filesystem and network authority outside the browser subprocess boundary [chromium-sandbox] [playwright-docker].

**Security conclusion for PDPP.** If connector code is trusted and only the target page is untrusted, a correctly configured bundled Chromium sandbox may be a useful defense-in-depth layer. If connectors are third-party, downloaded, or allowed native descendants, put the whole connector behind an OS-level boundary: Linux namespaces/seccomp/bubblewrap or a VM/container; macOS App Sandbox or a VM where practical; Windows restricted token/job/AppContainer or a VM where practical. Also enforce network allowlists and filesystem scoping at the outer boundary. Treat `--no-sandbox` as an explicit degraded mode for trusted local development, never as the production isolation design.

## SOURCES

**playwright-browsers**  
URL: https://playwright.dev/docs/browsers  
Accessed: 2026-08-31. Browser download locations, hermetic install, system Chrome/Edge support, and example browser sizes.

**playwright-docker**  
URL: https://playwright.dev/docs/docker  
Accessed: 2026-08-31. Docker images, system dependencies, headless/headed runtime concerns, IPC, init, sandbox, seccomp, remote server, and version matching.

**playwright-ci**  
URL: https://playwright.dev/docs/ci  
Accessed: 2026-08-31. Headless default, Linux Xvfb requirement for headed CI, worker guidance, and browser caching guidance.

**puppeteer-config**  
URL: https://pptr.dev/guides/configuration  
Accessed: 2026-08-31. Default matching Chrome download, `executablePath`, cache, and skip-download configuration.

**puppeteer-browsers**  
URL: https://pptr.dev/browsers-api  
Accessed: 2026-08-31. Explicit Chrome-for-Testing downloads, executable-path computation, and dependency installation.

**chrome-headless**  
URL: https://developer.chrome.com/docs/automation-and-testing/headless  
Accessed: 2026-08-31. Current cross-platform headless behavior and Chrome 112 platform-window change.

**chromium-sandbox**  
URL: https://chromium.googlesource.com/chromium/src/+/main/docs/design/sandbox.md  
Accessed: 2026-08-31. Chromium sandbox model, Windows restricted-token/job/desktop mechanisms, and OS-backed security assumptions.

**browserless**  
URL: https://github.com/browserless/browserless  
Accessed: 2026-08-31. Docker/WebSocket deployment, supported clients, and managed-browser rationale.

**browserless-workers**  
URL: https://docs.browserless.io/enterprise/private-deployment/worker-settings  
Accessed: 2026-08-31. Concurrency, queueing, global timeouts, resource pressure, and session cleanup.

**neko**  
URL: https://github.com/m1k1o/neko  
Accessed: 2026-08-31. Docker/WebRTC virtual browser, Linux application scope, and Playwright/Puppeteer automation use case.

**neko-faq**  
URL: https://github.com/m1k1o/neko/blob/master/webpage/docs/faq.md  
Accessed: 2026-08-31. Xorg/PulseAudio/Linux runtime and non-Docker installation notes.

**octoparse**  
URL: https://www.octoparse.com/download  
Accessed: 2026-08-31. Built-in browser, local Chrome, CAPTCHA/login, and cloud/local extraction modes.

**apify-images**  
URL: https://docs.apify.com/actors/development/actor-definition/dockerfile  
Accessed: 2026-08-31. Specialized Playwright/Puppeteer browser images and browser/library/image-size tradeoffs.

**windows-interactive-services**  
URL: https://learn.microsoft.com/en-us/windows/win32/services/interactive-services  
Accessed: 2026-08-31. Session 0, noninteractive services, and interactive-user helper process guidance.

**apple-lifecycle**  
URL: https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/Lifecycle.html  
Accessed: 2026-08-31. `launchd`, `loginwindow`, and the macOS user-session lifecycle.

## SYNTHESIS

For the PDPP desktop connector runtime, use a per-OS release containing the connector runtime and one pinned, compatible Chromium build. Keep Playwright/Puppeteer browser discovery explicit and versioned; put large browser assets in versioned application data if installer size or independent updates require it. Default collection to headless mode.

Treat headed operation as a separate capability. On Linux, it can be local Xvfb/Xorg. On macOS and Windows, it needs a user GUI session; if the app cannot safely and reliably own that session, connect to a Linux browser service instead. A Neko/Browserless-style remote path is valuable for visual debugging, human takeover, and persistent profiles, but it is a more complex distributed subsystem.

Use browser contexts or short-lived profiles for per-connector state, close pages and browsers in `finally`/equivalent cleanup, cap concurrency, cap session duration, and monitor CPU, memory, shared memory, and disk. Browser sandboxing is necessary defense in depth for hostile pages, but it does not satisfy PDPP’s stronger connector-isolation requirement by itself.

Confidence: high for Playwright/Puppeteer/browserless/Chromium behavior because the cited sources are current project documentation; medium-high for the macOS/Windows headed-session recommendation because the “no direct Xvfb equivalent” conclusion is an architectural synthesis from platform session documentation rather than a single vendor statement.
