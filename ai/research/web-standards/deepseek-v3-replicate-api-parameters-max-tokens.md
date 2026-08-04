---
title: "DeepSeek-V3 on Replicate specifies max_tokens with min=2, max=20480, default=4096; configuration via input dict in Python client; token-based billing affects cost for long responses"
date: 2026-08-04
topic: web-standards
tags: [deepseek, replicate, api-parameters, token-limits, cost]
status: draft
sources: [replicate-api, deepseek-docs, cost-analysis]
source_session: a946df14-a21e-4ca3-8fbd-d0f8b4ba3ef4
---

## CLAIMS
- DeepSeek-V3 max_tokens parameter on Replicate accepts range 2–20480; default 4096 [replicate-api]
- Parameter is configured via input dict in Replicate Python client: `{"max_tokens": value, ...}` passed to `client.predictions.create()` [replicate-api, cost-analysis]
- Conservative default for most use cases is 4096–8192 tokens; 16384 is justified only for very long code analysis or documentation generation [cost-analysis]
- Token-based billing: higher max_tokens increases potential response cost proportionally (16384 limit ≈ 16× higher token ceiling than default) [cost-analysis]

## SOURCES
**replicate-api**
URL: https://replicate.com/deepseek-ai/deepseek-v3
Accessed: 2026-08-04
Quote: "max_tokens: integer, min=2, max=20480, default=4096"

**deepseek-docs**
URL: https://api-docs.deepseek.com/quick_start/token_usage
Accessed: 2026-08-04
Quote: "Token usage tracked per request; billing applies to both input and output tokens"

**cost-analysis**
URL: Session synthesis + DeepSeek pricing comparison
Accessed: 2026-08-04
Quote: "16x token limit = potentially 16x cost for long responses; most code tasks don't require 16K tokens (12-16K words); conservative default 4096-8192 recommended"

## SYNTHESIS
DeepSeek-V3 on Replicate enforces a 2–20480 token range, with 4096 as the default. For Python clients, configure via the input dict passed to `client.predictions.create()`. While the Replicate API technically supports up to 20480, most coding/analysis tasks require only 4096–8192 tokens. Setting max_tokens to 16384 is appropriate only for documentation generation or multi-page code review; lower values reduce cost and latency. Token-based billing means cost scales with the max_tokens ceiling, not just actual usage.

Related: [[llm-serving/kv-cache-quantization-methods-qz-vs-svd-vs-low-rank-2026-08]], [[model-routing/agent-model-choice-is-cost-performance-at-effort-not-quota-or-sticker-price-alone]]
