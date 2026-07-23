---
title: "Antigravity is a separate CLI and quota provider, not a Gemini CLI authentication mode"
date: 2026-07-23
topic: ai-quota-monitoring
tags: [antigravity, gemini, quotas, providers]
status: draft
sources: [google-deprecation, google-transition, antigravity-usage, antigravity-install, antigravity-linux, antigravity-repo, codexbar-antigravity]
---

## CLAIMS

- Google ended Google-account access to Gemini CLI for consumer, Google AI Pro, and Google AI Ultra tiers on 2026-06-18, while Gemini Code Assist Standard, Enterprise, Google Cloud, and paid API-key access remain supported. [google-deprecation] [google-transition]
- Google directs affected consumer users to Antigravity CLI, a distinct Go CLI that shares an architecture with the Antigravity desktop app. [google-transition]
- Antigravity CLI exposes `/usage` and `/quota`, which refresh and display per-model remaining quota and reset information. [antigravity-usage]
- Google's supported Antigravity CLI installation channel on Linux and macOS is a per-user installer that places `agy` in `~/.local/bin`; the separately documented APT repository installs the Antigravity desktop product as package `antigravity`, not a standalone `agy` package. [antigravity-install] [antigravity-linux]
- The Antigravity CLI repository identifies `agy` as the product CLI and is currently a documentation/support repository rather than a complete open-source implementation. [antigravity-repo]
- CodexBar reads Antigravity quotas through the local desktop language-server status endpoints and also implements an OAuth-backed remote source; its implementation treats Antigravity as a provider separate from Gemini. For expired OAuth access, it discovers the installed Antigravity artifact's client ID and exact 35-byte `GOCSPX-` client secret, then uses Google's standard refresh-token grant. [codexbar-antigravity]
- A redacted local request trace established the consumer-account sequence: use the CLI-owned login, call `daily-cloudcode-pa.googleapis.com/v1internal:loadCodeAssist` with `ideType: ANTIGRAVITY`, then call the read-only `retrieveUserQuotaSummary` method with the returned account-scoped project. The summary reports distinct `gemini-weekly` and `3p-weekly` pools. This observation is implementation evidence, not a documented public API contract.
- Live expired-token testing disproved the initial assumption that `agy models` refreshes the CLI-owned token file: the command succeeds from a static model list while the file remains expired. The reliable background path is a standard Google refresh-token grant using OAuth client metadata discovered from the installed `agy` binary. Clawmeter should retain the resulting access token only in memory so it can preserve its no-credential-rewrite behavior.

## SOURCES

**google-deprecation**
URL: https://developers.google.com/gemini-code-assist/docs/deprecations/code-assist-individuals
Accessed: 2026-07-23

**google-transition**
URL: https://github.com/google-gemini/gemini-cli/discussions/27274
Accessed: 2026-07-23

**antigravity-usage**
URL: https://antigravity.google/docs/cli/commands/usage
Accessed: 2026-07-23

**antigravity-install**
URL: https://antigravity.google/docs/cli/install
Accessed: 2026-07-23

**antigravity-linux**
URL: https://antigravity.google/download/linux
Accessed: 2026-07-23

**antigravity-repo**
URL: https://github.com/google-antigravity/antigravity-cli
Accessed: 2026-07-23

**codexbar-antigravity**
URL: https://github.com/steipete/CodexBar/tree/main/Sources/CodexBarCore/Providers/Antigravity
Accessed: 2026-07-23

## SYNTHESIS

Clawmeter should add Antigravity as a distinct provider rather than changing Gemini's
meaning. Gemini remains valid for enterprise, Cloud, and API-key users. For consumer
Google accounts, Antigravity is now the supported quota-bearing harness.

The best background source is the official CLI's login file plus the account-scoped
quota-summary sequence observed above. For an expired access token, Clawmeter can
read the existing refresh token, discover the installed CLI's OAuth client metadata
using CodexBar's bounded artifact-scanning pattern, and use Google's standard token
endpoint. The refreshed access token should stay in process memory; Clawmeter must
not rewrite the CLI-owned login file. This avoids keeping a TUI or desktop language
server alive. Because the quota endpoint and binary layout are internal contracts,
the provider must isolate them, bound client-candidate attempts and response sizes,
reject partial measurements instead of inventing zero usage, and fail soft if the
shape changes.

Because Antigravity can report both Gemini and Claude model pools, presentation must
use the provider name "Antigravity" and preserve model labels. Clawmeter should not
merge those pools into the existing Gemini or Claude provider rows without evidence
that they draw from the same quota.
