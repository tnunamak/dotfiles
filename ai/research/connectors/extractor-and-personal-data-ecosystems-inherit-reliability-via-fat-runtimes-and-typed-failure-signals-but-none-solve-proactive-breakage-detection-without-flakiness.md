---
title: "Extractor ecosystems (yt-dlp, gallery-dl, streamlink, RSS-Bridge, Home Assistant) and personal-data aggregators (HPI, Dogsheep, Airbyte, Screenpipe, Surfer) all inherit reliability through fat shared runtimes and typed failure-kind signals, verify without credentials only structurally or via fixtures, and none has solved proactive breakage detection without flaky CI"
date: 2026-08-13
topic: connectors
tags: [yt-dlp, extractor-ecosystems, personal-data-aggregation, breakage-detection, shared-runtime, fixture-testing]
status: draft
sources: [ytdlp-contributing, gallerydl, streamlink, rssbridge, ha-coordinator, hpi-design, dogsheep, airbyte-cdk-blog, screenpipe, surfer]
source_session: 1f934c1f-19c7-4d9d-9b1d-52f5e457e91e
---

## CLAIMS
- yt-dlp (~1,800 extractors) deliberately excludes live extractor tests from CI (`pytest -m "not download"` in core.yml); contributors run `hatch test <Extractor>` manually pre-merge, and breakage detection is purely reactive via the `1_broken_site.yml` issue template. yt-dlp also bans AI/LLM-assisted contributions outright. [ytdlp-contributing]
- gallery-dl (~450 extractors, median ~142 LOC) runs live-site tests on a nightly cron with skip-not-fail semantics for 5xx/timeouts and a static `AUTH_REQUIRED` skip-list — the only surveyed ecosystem doing proactive live detection, at the cost of accepted flakiness. Tests live in declarative tuples under `test/results/<site>.py`, fully decoupled from extractor source. [gallerydl]
- streamlink's plugin CI is zero-network URL-regex matching only (`PluginCanHandleUrl` should_match lists); its CONTRIBUTING.md sets explicit inclusion criteria (no DRM, no paid-login-only, no unmaintained sites) to bound maintenance burden up front; its `validate.Schema` DSL turns per-site parsing into a declarative pipeline. [streamlink]
- RSS-Bridge's per-source contract is the thinnest surveyed (one PHP class implementing `collectData()`, many bridges <100 LOC, e.g. DuckDuckGoBridge at 53 lines); bridges throw typed `RateLimitException`/`CloudFlareException` so core decides policy; CI validates structure only and never calls `collectData()` live. [rssbridge]
- Home Assistant's `DataUpdateCoordinator` reduces the author's reliability surface to `_async_update_data()` raising typed `UpdateFailed(retry_after=...)`; config-flow's resumable step machinery is reused by the Repairs platform for re-auth/fix flows; CI mocks the vendor SDK constructor itself so no credentials touch CI. [ha-coordinator]
- Airbyte's stated reason for the low-code CDK is inherited reliability at scale: consolidating hundreds of bespoke connectors onto one interpreter so a shared fix repairs N connectors at once ("formulaic" API connectors). [airbyte-cdk-blog]
- HPI separates export (get bytes to disk, separate repos like ghexport) from access/normalization (parse, reconcile multi-source), each independently testable; Dogsheep's github-to-sqlite uses per-endpoint fixture-JSON replay tests — the cheap credential-less CI pattern. [hpi-design] [dogsheep]
- Screenpipe's `pipe.md` puts capability/permission declarations in frontmatter enforced by the runtime at OS level ("even a compromised agent cannot access denied data") — enforcement lives in a layer the author cannot bypass. [screenpipe]
- The 2024–2026 browser-automation-first personal-data cohort (Surfer Protocol ~1.4k stars) has the weakest verification story surveyed: no fixture suite, no breakage detection beyond community reports — UI-scraping connectors are a structurally lower trust class than API connectors everywhere. [surfer]

## SOURCES
**ytdlp-contributing**
URL: https://github.com/yt-dlp/yt-dlp/blob/master/CONTRIBUTING.md
Accessed: 2026-08-13
Quote: "core.yml CI workflow explicitly excludes extractor/download tests — pytest -m 'not download'" (agent summary of workflow + contributing docs)

**gallerydl**
URL: https://github.com/mikf/gallery-dl
Accessed: 2026-08-13
Quote: "test/results/<site>.py — declarative __tests__ tuples... runs against live sites nightly via cron CI... AUTH_REQUIRED static skip-list auto-skips" (agent summary)

**streamlink**
URL: https://github.com/streamlink/streamlink
Accessed: 2026-08-13
Quote: "PluginCanHandleUrl classes with should_match/should_not_match URL lists, zero network calls, zero auth" (agent summary)

**rssbridge**
URL: https://github.com/RSS-Bridge/rss-bridge
Accessed: 2026-08-13
Quote: "BridgeImplementationTest.php is structural-only — naming convention, constant non-emptiness, parameter-schema validity — never calls collectData()" (agent summary)

**ha-coordinator**
URL: https://developers.home-assistant.io/docs/integration_fetching_data
Accessed: 2026-08-13
Quote: "author writes only _async_update_data()... backoff via a typed UpdateFailed(retry_after=...) exception" (agent summary)

**hpi-design**
URL: https://github.com/karlicoss/HPI/blob/master/doc/DESIGN.org
Accessed: 2026-08-13
Quote: "HPI explicitly separates export (separate repos like ghexport...) from access/normalization" (agent summary)

**dogsheep**
URL: https://github.com/dogsheep/github-to-sqlite
Accessed: 2026-08-13
Quote: "fixture JSON files (commits.json, issues.json...) and per-endpoint unit tests" (agent summary)

**airbyte-cdk-blog**
URL: https://airbyte.com/blog/maintaining-hundreds-of-api-connectors-with-the-low-code-cdk-and-connector-builder
Accessed: 2026-08-13
Quote: "most API connectors are 'formulaic,' which is why they built the low-code CDK" (agent summary)

**screenpipe**
URL: https://docs.screenpi.pe/pipes
Accessed: 2026-08-13
Quote: "even a compromised agent cannot access denied data" (agent-relayed quote)

**surfer**
URL: https://github.com/Surfer-Org/Protocol
Accessed: 2026-08-13
Quote: "no visible fixture-based test suite, no documented breakage-detection mechanism" (agent summary)

## SYNTHESIS
Companion to [no-connector-ecosystem-verifies-function-registries-verify-identity-and-evidence-carrying-artifacts-are-emerging-white-space.md], both feeding the PDPP connector strategy (pdpp inbox/8-13-26-connector-dx-strategy.md). The convergent architecture across every mature ecosystem is: connector = provider facts + typed failure-kind signals; runtime = all policy (retry/backoff/pacing/scheduling). The unresolved industry-wide tension is breakage detection — deterministic-but-blind CI (yt-dlp, streamlink, RSS-Bridge) vs. live-but-flaky nightly probes (gallery-dl); nobody has a third option. PDPP's structural edge: its connectors run continuously on owners' machines under a protocol that already emits coverage/health evidence, so the fleet itself can be the monitor (post-merge), with recorded-transcript replay + fault injection covering pre-merge — a genuine third way if health projections are trustworthy. Secondary steals: HA's config-flow/Repairs reuse for credential repair, streamlink's admission criteria as reliability policy, Screenpipe's runtime-enforced capability frontmatter, decoupled declarative test files. Caveat: quotes marked "agent summary" were relayed by research subagents, not re-fetched verbatim — verify before citing externally.
