---
title: "CodexBar can raise parser confidence without accounts but cannot validate undocumented producer contracts"
date: 2026-07-16
topic: ai-quota-monitoring
tags: [clawmeter, codexbar, quotas, provider-integrations, contract-testing]
status: draft
sources: [openrouter-credits, openrouter-key, synthetic-quotas, kiro-billing, codexbar-providers, codexbar-diagnose, clawmeter-source]
---

## CLAIMS

- OpenRouter documents `data.total_credits` and `data.total_usage` on its credits endpoint, while its key endpoint separately exposes finite or unlimited limits and daily, weekly, and monthly usage. [openrouter-credits] [openrouter-key]
- Clawmeter commit `affd2cce` decodes OpenRouter credits as top-level `total_credits` and `usage`, then assigns a synthetic one-year reset to the balance. [clawmeter-source]
- Clawmeter commit `affd2cce` drops Synthetic quota entries whose calculated utilization is zero, reads at most two entries, and assigns a synthetic 24-hour reset when no reset is present. [clawmeter-source]
- Synthetic documents a Bearer-authenticated `/v2/quotas` endpoint but labels its API as under development. [synthetic-quotas]
- Kiro documents monthly credit renewal and add-on credit expiry, but the cited billing documentation does not define a versioned machine-readable CLI usage schema. [kiro-billing]
- CodexBar commit `6d71af30` implements provider integrations using a mixture of documented APIs, undocumented web APIs, local application protocols, browser sessions, local databases, and CLI text parsing. [codexbar-providers]
- The same CodexBar revision exposes a real-provider JSON diagnostic with safe usage metadata and closed error categories while excluding raw errors, responses, tokens, cookies, emails, account IDs, org IDs, and billing history. [codexbar-diagnose]

## SOURCES

**openrouter-credits**
URL: https://openrouter.ai/docs/api/api-reference/credits/get-credits
Accessed: 2026-07-16

**openrouter-key**
URL: https://openrouter.ai/docs/api/reference/limits
Accessed: 2026-07-16

**synthetic-quotas**
URL: https://dev.synthetic.new/docs/synthetic/quotas
Accessed: 2026-07-16

**kiro-billing**
URL: https://kiro.dev/docs/billing/
Accessed: 2026-07-16

**codexbar-providers**
URL: https://github.com/steipete/CodexBar/tree/6d71af30b84d8ee0b02361648b2123e0921a8277/Sources/CodexBarCore/Providers
Accessed: 2026-07-16

**codexbar-diagnose**
URL: https://github.com/steipete/CodexBar/blob/6d71af30b84d8ee0b02361648b2123e0921a8277/Sources/CodexBarCLI/CLIDiagnoseCommand.swift
Accessed: 2026-07-16

**clawmeter-source**
URL: https://github.com/tnunamak/clawmeter/tree/affd2cce4f882322df7f890d44ea919b239ba031/internal/provider
Accessed: 2026-07-16

## SYNTHESIS

A five-worker GPT-5.6 Luna/low audit plus an independent Luna/low cross-review covered
OpenRouter, Synthetic, z.ai, GitHub Copilot, Kimi, Codebuff, Kiro, Amp, OpenCode Go,
and Antigravity. Deterministic fixtures, mock transports, malformed-input tests, and
free-client inspection can substantially increase confidence that Clawmeter parses and
fails safely. They cannot establish that an undocumented authenticated producer still
emits the inferred contract for a random entitled user.

The normalized account-free implementation ceilings after bounded work were:
OpenRouter 91%, z.ai 90%, Copilot 86%, Kiro 84%, Kimi 82%, Codebuff 80%, Amp 80%,
Synthetic 76%, Antigravity 72%, and OpenCode Go 67%. Corresponding live-user ceilings
without entitled-account validation were 84%, 84%, 78%, 76%, 76%, 72%, 70%, 69%, 58%,
and 60%. These are review judgments, not statistical confidence intervals.

Prioritize semantic repairs for OpenRouter, Synthetic, Copilot, and z.ai. Investigate
Kimi's credential-writing side effect and build bounded parser harnesses for Kiro and
Codebuff. Defer Amp, OpenCode Go, and Antigravity until a stronger producer contract or
real-user evidence exists. Browser cookies and localStorage are not substitutes for a
stable contract.

For Clawmeter consumers, the executable is the right compatibility boundary. Clawmeter
already has an internal-only Go package layout and Waspflow already consumes its JSON
process output with timeouts, schema-version checks, per-provider error handling, and
committed fixtures. CodexBar's diagnostic pattern is worth adopting as a separate,
privacy-safe troubleshooting contract; its loopback HTTP server is not justified without
a measured long-running consumer need. Provider fetch internals should remain private so
undocumented upstream changes do not become public SDK obligations.
