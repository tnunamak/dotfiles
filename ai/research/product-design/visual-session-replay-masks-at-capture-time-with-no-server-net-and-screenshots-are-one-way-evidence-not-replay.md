---
title: "Visual session replay masks at capture time with no server-side net, and a timestamped-screenshot+action log is one-way evidence, not deterministic replay"
date: 2026-07-16
topic: product-design
tags: [session-replay, rrweb, sentry, playwright, screenshots, redaction, privacy, deterministic-replay, ci-evidence, pramana]
status: draft
sources: [rrweb-guide, rrweb-observer, rrweb-replay, rrweb-optimize, sentry-privacy, sentry-replay-config, sentry-troubleshoot, sentry-unmask-issue, sentry-rrweb-fork, sentry-retention, pw-trace-viewer, pw-tracing-api, pw-screenshots, pw-videos, pw-ci, gh-runners, gh-upload-artifact-badchars, gh-artifact-retention, ffmpeg-x11grab, cypress-artifacts, lighthouse-filmstrip, fowler-eventsourcing, rr-project, fullstory-private, logrocket-network, datadog-privacy, strac-image-redaction]
source_session: 019ce297-6779-78c0-a12e-667fda61949e
---

## CLAIMS

### rrweb / Sentry visual replay (DOM-delta model)
- rrweb records an initial full DOM snapshot (serialized JSON tree with node IDs) plus timestamped incremental DOM-mutation deltas via `MutationObserver`; it does NOT record pixels/video and does NOT re-run JavaScript on replay, so replay is a reconstruction of the recorded DOM stream, not a re-execution of the computation. [rrweb-guide][rrweb-observer][rrweb-replay]
- rrweb replay is deterministic from the JSON event stream and inlines CSS into events (to reproduce `:hover` etc.), but external web fonts, images, and cross-origin assets are URL-referenced, not inlined — full visual fidelity offline depends on those origins (and, for a hosted player, on CORS) being reachable. [rrweb-replay][rrweb-optimize][sentry-troubleshoot]
- rrweb event-stream size is workload-dependent and not published as a canonical number by rrweb; a common secondary benchmark is ~1–5 MB gzipped per 30-min session (~30–170 KB/min), inflated by canvas/animation/heavy mutation. [rrweb-optimize]
- Sentry Session Replay is private by default: `maskAllText`, `maskAllInputs`, `blockAllMedia` all default `true`; text is replaced char-by-char with `*`, and the default blocked-media set is `img, svg, video, object, picture, embed, map, audio`. Selectors `.sentry-mask`/`.sentry-block`/`.sentry-ignore` (and explicit `.sentry-unmask`/`.sentry-unblock`) tune this. [sentry-privacy][sentry-replay-config]
- Sentry masking runs CLIENT-SIDE, before upload: masked text and blocked media never leave the browser. The docs' own corollary is the leak: disabling default masking and missing an element containing PII "means risking sensitive content leaving the user's browser." [sentry-privacy]
- Documented Sentry/rrweb leak vectors that survive default masking: `srcdoc` iframes are not masked; canvas recording has "currently no PII scrubbing" at all (opt-in, 2 fps image export); cross-origin iframe recording exposes unencrypted `postMessage` traffic and is broken/unsupported; and globally unmasking has no hard floor for detectable sensitive fields (open issue getsentry/sentry-javascript#10258). [sentry-troubleshoot][sentry-unmask-issue]
- Sentry maintains a fork of rrweb (getsentry/rrweb) with build flags that conditionally compile out iframe/canvas/shadow-DOM recording, so what is captured depends on build configuration, not just runtime options. [sentry-rrweb-fork]
- Sentry replay retention is fixed at ingestion (not user-configurable): 90 days paid, 30 days free; over-quota returns HTTP 429. [sentry-retention]

### Playwright trace / screenshots / video
- A Playwright trace.zip contains the action log, complete per-action DOM snapshots (Before/Action/After), a screenshot film-strip timeline, network, console, and optional sources — it is reconstructed action-by-action DOM, not a real video, and captures full rendered text + input state (a privacy risk equivalent to rrweb). [pw-trace-viewer][pw-tracing-api]
- The Playwright tracing API exposes NO masking/redaction option; masking (`mask`, `maskColor` → pink `#FF00FF` box) exists only for `page.screenshot()` / `toHaveScreenshot`, not for traces. Trace.zip has no documented stable public schema. [pw-tracing-api][pw-screenshots]
- Playwright per-test video (`video: 'retain-on-failure'|'on-first-retry'|…`) records WebM scaled to fit (default 800×800), written on browser-context close; screenshots support `screenshot: 'only-on-failure'`. [pw-videos][pw-screenshots]

### VM/OS-level recording + artifact economics
- Linux headless capture is Xvfb + `ffmpeg -f x11grab`; size is a direct function of target bitrate (~7.5 MB/min per 1 Mbps H.264), and VP9/H.265 trade smaller files for markedly higher CPU. [ffmpeg-x11grab]
- macOS GitHub-hosted runners cannot get the TCC Screen Recording permission programmatically (documented by TestCafe and actions/runner-images#7818/#8951); full-desktop video on hosted `macos-latest` is effectively blocked without self-hosted runners; standard runners document no GPU. [gh-runners]
- Ordering of artifact cost per minute (smallest→largest): rrweb JSON deltas < Playwright trace.zip < screenshot filmstrip (WebP) < full video; only the video floor (~1–10+ MB/min) and rrweb range are order-of-magnitude estimates, not published fixed benchmarks. [rrweb-optimize][ffmpeg-x11grab][pw-trace-viewer]

### GitHub Actions portability
- `actions/upload-artifact` rejects paths containing `" : < > | * ? \r \n` "due to limitations with certain file systems such as NTFS" — timestamps (`HH:MM:SS`) and `sha256:` digests are the classic offenders; artifact NAMES additionally reject `/`. [gh-upload-artifact-badchars]
- Artifact retention defaults to 90 days, is settable per-upload via `retention-days` (min 1, max 90 public / 400 private), is not retroactive, and quota is recalculated only every 6–12h so deletes don't free quota immediately; hitting quota blocks new uploads. [gh-artifact-retention]

### Deterministic replay vs captured observation
- Event sourcing's litmus (Fowler): state must be rebuildable purely from the recorded event log ("blow away the application state and confidently rebuild it from the log") — requires all state changes to flow through recorded inputs. [fowler-eventsourcing]
- rr/Pernosco is the deterministic-replay gold standard: it records all inputs + nondeterministic CPU effects and REPLAYS by re-execution, guaranteeing identical instruction-level control flow, memory, and register contents. [rr-project]
- A timestamped screenshot + action log records OUTPUTS at discrete instants, not the inputs that produce state; it fails the event-sourcing rebuild test by construction, samples discretely (misses state between shots — the reason rrweb records every mutation rather than periodic snapshots), and its capture clock is an external observer of the system rather than the system's own event clock. [fowler-eventsourcing][rr-project][rrweb-observer]

### The "no server-side net" invariant, cross-vendor
- Every major visual-replay vendor masks at capture time and states that masked data is never collected server-side: Sentry ("on the client, before it is sent to the server"), Datadog (masked data "is not collected in its original form … not sent to the backend"), LogRocket (excluded data "is never sent … cannot be included again on that page"; and sanitizing an input does NOT sanitize a network request carrying the same value), FullStory (private-by-default, most-restrictive-rule-wins). The shared corollary: a missed/misconfigured selector leaks raw PII that no post-hoc server step can recover. [sentry-privacy][datadog-privacy][logrocket-network][fullstory-private]
- Post-hoc image redaction is documented-unreliable: OCR misses skewed/low-contrast/abbreviated text, and blackout overlays are reversible if underlying pixels/layers survive — irreversible redaction requires destroying pixel data, not covering it. [strac-image-redaction]

## SOURCES

**rrweb-guide** — https://github.com/rrweb-io/rrweb/blob/main/guide.md — Accessed 2026-07-16
**rrweb-observer** — https://github.com/rrweb-io/rrweb/blob/master/docs/observer.md — Accessed 2026-07-16
**rrweb-replay** — https://github.com/rrweb-io/rrweb/blob/master/docs/replay.md — Accessed 2026-07-16
**rrweb-optimize** — https://github.com/rrweb-io/rrweb/blob/master/docs/recipes/optimize-storage.md — Accessed 2026-07-16
**sentry-privacy** — https://docs.sentry.io/platforms/javascript/session-replay/privacy/ — Accessed 2026-07-16
**sentry-replay-config** — https://docs.sentry.io/platforms/javascript/session-replay/configuration/ — Accessed 2026-07-16
**sentry-troubleshoot** — https://docs.sentry.io/platforms/javascript/session-replay/troubleshooting/ — Accessed 2026-07-16
**sentry-unmask-issue** — https://github.com/getsentry/sentry-javascript/issues/10258 — Accessed 2026-07-16
**sentry-rrweb-fork** — https://github.com/getsentry/rrweb — Accessed 2026-07-16
**sentry-retention** — https://docs.sentry.io/pricing/quotas/manage-replay-quota/ — Accessed 2026-07-16
**pw-trace-viewer** — https://playwright.dev/docs/trace-viewer — Accessed 2026-07-16
**pw-tracing-api** — https://playwright.dev/docs/api/class-tracing — Accessed 2026-07-16
**pw-screenshots** — https://playwright.dev/docs/screenshots — Accessed 2026-07-16
**pw-videos** — https://playwright.dev/docs/videos — Accessed 2026-07-16
**pw-ci** — https://playwright.dev/docs/ci — Accessed 2026-07-16
**gh-runners** — https://docs.github.com/en/actions/reference/runners/github-hosted-runners — Accessed 2026-07-16
**gh-upload-artifact-badchars** — https://github.com/actions/upload-artifact/issues/85 — Accessed 2026-07-16
**gh-artifact-retention** — https://github.com/actions/upload-artifact — Accessed 2026-07-16
**ffmpeg-x11grab** — https://ffmpeg.org/ffmpeg-devices.html#x11grab — Accessed 2026-07-16
**cypress-artifacts** — https://docs.cypress.io/app/guides/screenshots-and-videos — Accessed 2026-07-16
**lighthouse-filmstrip** — https://developer.chrome.com/docs/lighthouse/overview — Accessed 2026-07-16
**fowler-eventsourcing** — https://martinfowler.com/eaaDev/EventSourcing.html — Accessed 2026-07-16
**rr-project** — https://rr-project.org/ — Accessed 2026-07-16
**fullstory-private** — https://help.fullstory.com/hc/en-us/articles/360044349073-Fullstory-Private-by-Default — Accessed 2026-07-16
**logrocket-network** — https://docs.logrocket.com/reference/network — Accessed 2026-07-16
**datadog-privacy** — https://docs.datadoghq.com/session_replay/browser/privacy_options/ — Accessed 2026-07-16
**strac-image-redaction** — https://www.strac.io/blog/image-redaction — Accessed 2026-07-16

## SYNTHESIS

For a CI reliability harness that wants "Sentry-style visual replay" of automated
journeys (e.g. Pramana / BUI-739), the prior art forces two hard conclusions.

1. **A timestamped-screenshot + action log is EVIDENCE, not replay.** It records
   outputs at discrete instants; it cannot re-derive or re-execute the run (fails
   Fowler's rebuild test), it is blind between shots (the exact reason rrweb records
   every mutation), and its capture clock drifts from the system's own event clock.
   If replayability is the goal, the right primitive is an event-sourced input log
   (rrweb-style DOM-mutation stream, or a true record/replay layer), not a filmstrip.
   Screenshots are legitimate corroborating evidence, never the record of record.

2. **Any visual capture (screenshots, video, rrweb, Playwright trace) redacts at
   CAPTURE TIME with no server-side net.** Every vendor masks in the browser before
   upload because there is no reliable way to un-leak PII later; post-hoc image
   redaction is documented-unreliable. So adding pixels to an evidence bundle moves
   the privacy boundary from a server-side, defense-in-depth, closed-schema gate
   (which a textual metadata ledger can enforce and re-verify) to a single
   capture-time selector list whose one miss is a permanent, unrecoverable leak —
   with concrete known bypasses (canvas has zero PII scrubbing, `srcdoc` iframes,
   cross-origin iframes, global-unmask footguns).

Implication for a system already built on a redacted, closed-schema, server-re-verified
textual ledger (`capture_mode: off`, forbidden-key sweep, ingest 422): visual replay is
a SEPARATE, higher-risk sensitivity class, not an extension of the safe-metadata channel.
If pursued, it must be its own opt-in artifact lane with (a) DOM-level default-block
masking proven against the known bypasses, (b) a distinct sensitivity/retention class,
(c) out-of-band binary storage with its own lifecycle (a text-only, binary-refusing
evidence writer cannot carry it), and (d) portable artifact paths (no `:` in dir names).
GitHub Actions specifics: hosted macOS can't screen-record, artifact paths reject `:`/`<`
etc., retention is a per-upload `retention-days` lever capped at 90/400 days. Default
recommendation for a reliability harness whose product claim is a deterministic oracle,
not human forensics: keep the authoritative record textual/event-sourced; treat any
pixels as a bounded, separately-consented, capture-time-masked debug aid — never the
thing a pass/fail verdict is read from.
