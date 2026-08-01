---
title: "OSS remote-browser/streaming substrates ship Apache-2.0, a host-neutral small core with in-tree adapters, and a SECURITY.md that disclaims multi-tenant safety"
date: 2026-05-27
topic: oss-strategy
tags: [open-source, licensing, remote-browser, streaming-substrate, multi-tenant, apache-2, playwright]
status: draft
sources: [neko, neko-releases, kasmvnc, kasm-community, kasm-license, selkies, browserless, browserless-issue, browser-use-cloud, browser-use-cloud-md, anthropic-computer-use, patchright, testdino-playwright]
source_session: 019d2610-c519-7b42-a2d5-f1056474daf8
---

<!-- Reusable OSS-posture prior-art extracted from a pdpp remote-surface note.
     pdpp/@opendatalabs-specific package decisions and open questions were dropped. -->

## CLAIMS

- n.eko (m1k1o/neko) is Apache-2.0 with solo-maintainer governance; v3 added a public REST API with OpenAPI 3.0, Prometheus metrics, and made the server consumable as a Go library, but has no formal plugin SPI after ~6 years ("fork or import the Go package") and its `SECURITY.md` only describes vuln reporting — no multi-tenant safety claim, no API-stability promise; multi-tenancy is delegated to a separate orchestrator (neko-rooms). [neko][neko-releases]
- Kasm Workspaces is classic open-core: open images and KasmVNC (GPL-2.0), proprietary/source-available server orchestration/admin/auth/DLP plane gated by EULA; Community Edition is gratis-not-libre (5-session cap, non-commercial); KasmVNC is a fully separable Xvnc fork usable standalone. [kasmvnc][kasm-community][kasm-license]
- Selkies (MPL-2.0, ~1.8k stars, actively soliciting maintainers), noVNC (MPL-2.0), and Guacamole (Apache-2.0 + ASF governance) all share a clean boundary — transport + input + display below, product semantics above; Guacamole's `guacd` is the cleanest small-core+adapters model (protocol-agnostic daemon, per-protocol VNC/RDP/SSH adapters). [selkies]
- browserless is dual-licensed SSPL-1.0 OR commercial with a deliberately thin public contract (`ws://host:3000` + Puppeteer/Playwright CDP — reusing an existing protocol rather than inventing one); all managed-service assumptions (API tokens, concurrency caps, region routing, billing) sit behind the WS endpoint, none in the protocol. [browserless][browserless-issue]
- Browser-Use Cloud (v3, 2026) is a managed REST API (`api.browser-use.com/api/v3`, `X-Browser-Use-API-Key`, 15-min session cap, `live_url` embeddable preview, BYO-LLM keys, persistent "Browser Profile") — session/agent/profile/live_url are managed-service concepts, not substrate concepts. [browser-use-cloud][browser-use-cloud-md]
- Anthropic computer-use is a schema-less tool baked into the model where the host owns the loop (capture screenshot, transform coords, execute click, return `tool_result`); Anthropic does not retain screenshots/inputs (ZDR-eligible), the host owns data, and the docs are blunt that isolation is the host's job: "Operate in a dedicated VM or container with minimal privileges." [anthropic-computer-use]
- Playwright's architecture is a client SDK ↔ persistent WebSocket ↔ Playwright Server ↔ CDP-patched browsers (the single bidirectional channel is the source of stability and auto-wait), with two-stage provisioning (npm/pip client + driver from GitHub Releases); Patchright is a drop-in fork patching the driver (avoids `Runtime.enable`, uses Routes for init-scripts, strips telltale launch flags) while keeping the client API identical. [testdino-playwright][patchright]
- None of n.eko, KasmVNC, Selkies, Guacamole, noVNC, or browserless OSS claim multi-tenant safety in their core repo; multi-tenancy is universally treated as a host-level concern (Kasm punts isolation to per-container Docker/Xvnc; Anthropic mandates a dedicated VM/container). [anthropic-computer-use][kasm-license][neko]
- License posture across the cohort: n.eko and Guacamole are Apache-2.0 (dominant for substrate, includes patent grant); Selkies/noVNC are MPL-2.0 (file-level copyleft, per-file compliance overhead); KasmVNC is GPL-2.0 (strong copyleft, downstream friction); browserless is SSPL-1.0-or-commercial (not OSI, AGPL-shaped + commercial gate). [neko][selkies][kasmvnc][browserless]

## SOURCES

**neko**
URL: https://github.com/m1k1o/neko
Accessed: 2026-05-27

**neko-releases**
URL: https://neko.m1k1o.net/docs/v3/release-notes
Accessed: 2026-05-27

**kasmvnc**
URL: https://github.com/kasmtech/KasmVNC
Accessed: 2026-05-27

**kasm-community**
URL: https://kasm.com/community-edition
Accessed: 2026-05-27

**kasm-license**
URL: https://docs.kasm.com/docs/latest/license/index.html
Accessed: 2026-05-27

**selkies**
URL: https://github.com/selkies-project/selkies
Accessed: 2026-05-27

**browserless**
URL: https://github.com/browserless/browserless
Accessed: 2026-05-27

**browserless-issue**
URL: https://github.com/browserless/browserless/issues/3850
Accessed: 2026-05-27

**browser-use-cloud**
URL: https://docs.browser-use.com/cloud/api-reference
Accessed: 2026-05-27

**browser-use-cloud-md**
URL: https://github.com/browser-use/browser-use/blob/main/CLOUD.md
Accessed: 2026-05-27

**anthropic-computer-use**
URL: https://platform.claude.com/docs/en/agents-and-tools/tool-use/computer-use-tool
Accessed: 2026-05-27
Quote: "Operate in a dedicated VM or container with minimal privileges."

**patchright**
URL: https://github.com/Kaliiiiiiiiii-Vinyzu/patchright
Accessed: 2026-05-27

**testdino-playwright**
URL: https://testdino.com/blog/playwright-architecture
Accessed: 2026-05-27

## SYNTHESIS

For publishing a remote-browser/streaming control substrate as OSS, the cohort points to a consistent posture: license Apache-2.0 (matches n.eko and Guacamole, maximizes OEM/SaaS-embedder adoption, patent grant matters for a control protocol; avoid MPL-2.0 per-file overhead, GPL-2.0 downstream friction, and SSPL's non-OSI FUD); keep the default export host-neutral (substrate = transport, input, clipboard, IME, geometry, leases, diagnostics), adopting Guacamole's `guacd` boundary and Anthropic's "host owns the loop" contract; use a small core + in-tree version-pinned adapters (Playwright model) rather than out-of-tree drivers (Selenium model), with a stable internal adapter interface so a stealth/hardened variant (Patchright-equivalent) can drop in; skip a pre-built plugin SPI (n.eko has none after 6 years — export a library + REST/WS surface); make `SECURITY.md` process-only and explicitly disclaim multi-tenant safety ("assumes one trust boundary per session; the host is responsible for sandboxing, tenant isolation, egress controls, credential handling; default config is not safe for multi-tenant production"); and keep managed-service concepts (API keys, quotas, billing/regions, tenant-tied session ids, `live_url` preview tokens, agent-loop opinions, LLM config, audit-retention promises) out of the substrate entirely. Avoid implying security via README adjectives ("secure," "isolated") without a scoped threat model.
