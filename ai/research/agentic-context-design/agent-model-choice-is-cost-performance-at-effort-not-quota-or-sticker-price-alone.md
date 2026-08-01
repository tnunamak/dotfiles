---
title: "Agent model choice is cost–performance at a chosen effort/reasoning level (and cost-per-successful-task), not sticker $/MTok or remaining quota alone"
date: 2026-07-09
topic: agentic-context-design
tags: [cost-performance, effort, model-choice, sonnet-5, gpt-5.5, grok, tokensmash, clawmeter, pareto]
status: draft
sources: [anthropic-sonnet-5, anthropic-models-overview, openai-gpt-5-5, openai-codex-pricing, xai-models-docs, ai-agents-that-matter, local-tooling-map]
source_session: 4fc3911a-6dc4-4250-971f-3beb4e941df7
---

<!--
Captures the Anthropic Sonnet 5 cost–performance × effort framing the owner
remembered, plus primary pricing/quality data for OpenAI and xAI as of access
date. High bar: vendor primary pages + the academic cost-per-success doctrine.
NOT a live model catalog — rates and evals go stale; re-fetch before relying
on numbers for spend decisions.
-->

## CLAIMS

### Evaluation doctrine (what "good" means)

- Evaluating coding agents on accuracy alone misleads; the correct joint objective is the **accuracy-vs-cost Pareto frontier**, and the practical metric is **cost per successful task**, not proxy self-meters or raw token counts. [ai-agents-that-matter]
- Joint optimization of accuracy and cost cut variable cost **41–53%** while maintaining accuracy in the "AI Agents That Matter" study framing. [ai-agents-that-matter]

### Anthropic — Sonnet 5 cost–performance × effort (the remembered post)

- Anthropic published **cost–performance curves at different effort levels** for Claude Sonnet 5 vs Sonnet 4.6 vs Opus 4.8 on **BrowseComp** (agentic search) and **OSWorld-Verified** (computer use). [anthropic-sonnet-5]
- Anthropic states Sonnet 5 is a **strict improvement** over Sonnet 4.6 on those curves and covers a **much wider range of cost–performance options** than Opus 4.8; medium effort is "substantially improved cost efficiency," and higher effort can **match Opus 4.8 on some tasks**. [anthropic-sonnet-5]
- Anthropic explicitly frames model selection as: **between Sonnet 5 and Opus 4.8, adjust effort to balance cost and performance**. [anthropic-sonnet-5]
- Sonnet 5 standard API pricing in the charts is **$3 / MTok input and $15 / MTok output**; Opus 4.8 is **$5 / $25**. [anthropic-sonnet-5]
- Introductory Sonnet 5 pricing is **$2 / $10** through **2026-08-31**, then **$3 / $15**. [anthropic-sonnet-5] [anthropic-models-overview]
- Sonnet 5 uses an **updated tokenizer**; the same input can map to **~1.0–1.35× more tokens** depending on content; intro pricing is set so migration is **roughly cost-neutral**. [anthropic-sonnet-5]
- Official current-model API rates (standard, not intro): Fable 5 **$10/$50**, Opus 4.8 **$5/$25**, Sonnet 5 **$3/$15** (intro **$2/$10** through 2026-08-31), Haiku 4.5 **$1/$5**. [anthropic-models-overview]
- On Claude Opus 4.8 and Claude Sonnet 5, **`effort` defaults to `high`** on Claude API and Claude Code (set explicitly for other levels). [anthropic-models-overview]
- Anthropic corrected the BrowseComp cost–performance chart on launch day (2026-06-30) because an earlier simpler methodology **underestimated Sonnet 5**; the updated chart matches the system-card methodology (10M token budget with compaction and programmatic tool calling). [anthropic-sonnet-5]

### OpenAI — GPT-5.5 quality, efficiency, and Codex pricing axes

- OpenAI reports GPT-5.5 **Terminal-Bench 2.0 = 82.7%** (vs GPT-5.4 75.1%, Claude Opus 4.7 69.4%, Gemini 3.1 Pro 68.5% in their table) and **SWE-Bench Pro (Public) = 58.6%** (vs GPT-5.4 57.7%, Claude Opus 4.7 **64.3%**, Gemini 3.1 Pro 54.2%), with an asterisk noting labs have claimed memorization evidence on SWE-Bench Pro. [openai-gpt-5-5]
- OpenAI reports GPT-5.5 **OSWorld-Verified = 78.7%** (vs GPT-5.4 75.0%, Claude Opus 4.7 78.0%) and **BrowseComp = 84.4%** (GPT-5.5 Pro 90.1%; Claude Opus 4.7 79.3%). [openai-gpt-5-5]
- OpenAI claims GPT-5.5 improves coding scores vs GPT-5.4 **while using fewer tokens**, and that on Artificial Analysis's Coding Index it delivers SOTA intelligence at **half the cost** of competitive frontier coding models (vendor claim citing external index). [openai-gpt-5-5]
- API pricing stated in the GPT-5.5 launch post: **gpt-5.5 = $5 / $30 per 1M input/output**; **gpt-5.5-pro = $30 / $180**; Batch/Flex at half standard; Priority at 2.5×. [openai-gpt-5-5]
- In Codex, GPT-5.5 is available with **Fast mode = 1.5× token generation speed for 2.5× cost**. [openai-gpt-5-5]
- Codex ChatGPT plans (not API $/MTok) as of access date: Free $0, Go $8/mo, Plus $20/mo, Pro from $100/mo, Business $20/user/mo annual; API-key path bills at standard API rates. [openai-codex-pricing]
- Codex **credit rate card** (credits per 1M tokens): GPT-5.5 **125 / 12.50 / 750** (input / cached / output); GPT-5.4 **62.50 / 6.250 / 375**; GPT-5.4 mini **18.75 / 1.875 / 113**. [openai-codex-pricing]
- OpenAI documents that Plus/Pro local-message allowance in a **shared 5h window** is model-dependent (e.g. Plus: GPT-5.5 ~15–80, GPT-5.4 ~20–100, GPT-5.4 mini ~60–350 messages / 5h), so **model choice is also a quota lever**, not only quality. [openai-codex-pricing]

### xAI / Grok — official model menu and API rates (limited joint cost–quality curves)

- Official xAI models page (access date) lists chat API rates: **grok-4.5 = $2.00 / $6.00** (500k context); **grok-4.3 and grok-4.20 variants = $1.25 / $2.50** (1M context); code API **grok-build-0.1 = $1.00 / $2.00** (256k). [xai-models-docs]
- xAI's published model-selection guidance: for "everything else, including code, use **Grok 4.5**" as "the most intelligent and fastest model we've built." [xai-models-docs]
- Unlike Anthropic's Sonnet 5 post, the official xAI models page (as accessed) does **not** publish effort×cost–performance curves comparable to BrowseComp/OSWorld charts; Grok Build/subscription quota is a **separate** surface from API $/MTok. [xai-models-docs]

### Tooling map (this machine — where data lives)

- **minnows data pack `model-catalog`** is the versioned multi-consumer home for pricing + sparse quality/effort JSON (`data/model-catalog/`, tags `data-model-catalog-v*`, fetch via pack README / releases / `fetch-data-pack.sh`). [local-tooling-map]
- **clawmeter** tracks **provider quota windows** (remaining allowance / reset), including Grok Build subscription usage and xAI prepaid credits — not task quality and not model ranking. [local-tooling-map]
- **tokensmash** stores versioned **per-model $/MTok (and Codex credit) tables** and computes session cost from transcripts for Claude Code and Codex; it can align with the minnows pack over time; (as of 2026-07-09) its in-tree tables predate the pack and still lack Grok session parsing. [local-tooling-map]
- **waspflow** orchestrates multi-provider lanes and only applies **billing-path accident guards** (e.g. API-key vs subscription); it does not encode cost–performance or effort ladders. [local-tooling-map]

## SOURCES

**anthropic-sonnet-5**
URL: https://www.anthropic.com/news/claude-sonnet-5
Accessed: 2026-07-09
Quote: "The charts below compare the performance of Sonnet 5 with Sonnet 4.6 and Opus 4.8 at different effort levels on the agentic search evaluation BrowseComp and the computer use evaluation OSWorld-Verified. Sonnet 5 (orange line) is a strict improvement over Sonnet 4.6 (gray line) and covers a much wider range of cost-performance options than Opus 4.8 (yellow line). It provides substantially improved cost efficiency at medium effort; its higher-effort performance can match Opus 4.8 on some tasks. Between Sonnet 5 and Opus 4.8, users can adjust the effort level to find the right balance of cost and performance." … "The charts show Sonnet 5 priced at $3 per million input tokens and $15 per million output tokens. … Opus 4.8 is priced at $5/MTok input and $25/MTok output. xhigh = extra high effort level." … "introductory pricing of $2 per million input tokens and $10 per million output tokens through August 31, 2026, after which it will be priced at $3 … and $15 …" … "updated tokenizer … roughly 1.0–1.35× depending on the content type. The introductory pricing is set so that the transition to Sonnet 5 is roughly cost-neutral." … changelog note that the original BrowseComp chart methodology underestimated Sonnet 5 and was updated to match the system-card methodology.

**anthropic-models-overview**
URL: https://platform.claude.com/docs/en/about-claude/models/overview
Accessed: 2026-07-09
Quote: Latest models comparison pricing: Fable 5 $10/$50, Opus 4.8 $5/$25, Sonnet 5 $3/$15 with footnote "Introductory pricing of $2 / $10 per MTok applies to Claude Sonnet 5 through August 31, 2026", Haiku 4.5 $1/$5. "On Claude Opus 4.8, the effort parameter defaults to high on all surfaces… On Claude Sonnet 5, it defaults to high on the Claude API and Claude Code."

**openai-gpt-5-5**
URL: https://openai.com/index/introducing-gpt-5-5/
Accessed: 2026-07-09
Quote: Terminal-Bench 2.0 GPT-5.5 82.7% vs GPT-5.4 75.1% vs Claude Opus 4.7 69.4%; SWE-Bench Pro GPT-5.5 58.6% vs Opus 4.7 64.3% (asterisk: memorization evidence noted); OSWorld-Verified 78.7%; "Across all three evals, GPT-5.5 improves on GPT-5.4's scores while using fewer tokens."; "On Artificial Analysis's Coding Index, GPT-5.5 delivers state-of-the-art intelligence at half the cost of competitive frontier coding models."; API "gpt-5.5 … $5 per 1M input tokens and $30 per 1M output tokens" and "gpt-5.5-pro … $30 … and $180"; Codex "Fast mode, generating tokens 1.5x faster for 2.5x the cost."

**openai-codex-pricing**
URL: https://developers.openai.com/codex/pricing
Accessed: 2026-07-09
Quote: Plan tiers Free $0 / Go $8 / Plus $20 / Pro from $100 / Business $20 user/mo annual; credit rate card GPT-5.5 125/12.50/750, GPT-5.4 62.50/6.250/375, GPT-5.4 mini 18.75/1.875/113 credits per 1M tokens; Plus local messages/5h ranges GPT-5.5 15-80, GPT-5.4 20-100, GPT-5.4 mini 60-350.

**xai-models-docs**
URL: https://docs.x.ai/developers/models
Accessed: 2026-07-09
Quote: Chat API Pricing table: grok-4.3 $1.25/$2.50 (1M), grok-4.20 variants $1.25/$2.50 (1M), grok-4.5 $2.00/$6.00 (500k); Code API grok-build-0.1 $1.00/$2.00 (256k). "For everything else, including code, use Grok 4.5. It is the most intelligent and fastest model we've built."

**ai-agents-that-matter**
URL: https://arxiv.org/abs/2407.01502
Accessed: 2026-07-09
Quote: (paper abstract / established claim used in local research): evaluate agents on the accuracy-vs-cost Pareto frontier; joint optimization cut variable cost 41-53% with maintained accuracy; cost-per-success is the metric. Also cited in local research entry token-saving-proxies-rtk-headroom-net-positive-on-real-tasks-but-self-metrics-inflated.md.

**local-tooling-map**
URL: local — minnows `data/model-catalog/` + `data/index.json`; clawmeter `internal/provider/`; tokensmash `src/tokensmash/data/pricing/*.json`; waspflow `lib/billing.sh`
Accessed: 2026-07-09
Quote: minnows pack model-catalog v0.1.0 includes anthropic/openai/codex-credits/xai pricing JSON + sparse performance claims; fetch via data/README.md and scripts/fetch-data-pack.sh. clawmeter: Grok Build subscription usage; API prepaid credits. tokensmash in-tree pricing still Claude/Codex-only without Grok session parser. waspflow billing is env-key guards only.

## SYNTHESIS

What you remembered was real and specific: Anthropic's Sonnet 5 launch post is the cleanest **primary** statement that agent model choice is a **curve** (quality vs cost) parameterized by **effort**, not a single "best model" or a sticker $/MTok. That is **not** stored in clawmeter (quota), tokensmash (invoice math), or waspflow (orchestration).

How to use this without fooling yourself:

1. **Pick the axis that matches the bill.** Subscription workers (Claude Code OAuth, Codex Plus/Pro, Grok Build login) burn **quota windows** — clawmeter. API workers burn **$/MTok or credits** — tokensmash tables + invoice. Mixing them is how "cheap model" still nukes the week.
2. **Prefer cost-per-successful-task over cheaper tokens.** A model that needs more retries, higher effort, or denser tokenization can lose on task cost while winning on rate card (Sonnet 5 tokenizer note; OpenAI's "fewer tokens" claim for GPT-5.5).
3. **Effort/reasoning is a first-class dial.** Anthropic publishes this explicitly; OpenAI exposes reasoning/effort and Fast mode (speed×cost); Grok has configurable reasoning in product docs but **no** vendor cost–performance curves comparable to Sonnet 5's BrowseComp/OSWorld charts as of access date.
4. **Do not cross-rank vendors from launch blogs alone.** Harnesses differ (SWE-Bench Pro asterisk, vendor-internal Expert-SWE, Artificial Analysis index weighting). Treat tables as **same-vendor relative** guidance unless an independent fixed harness is cited.
5. **Grok gap for this machine:** official API rates are clear; quality×cost curves are thin; subscription free-tier vs weekly Build quota are different gates (clawmeter currently reads Build subscription protobuf, which can show 0% while free-tier limits still fire). tokensmash still needs a Grok session parser + pricing file before Grok lanes enter cost studies.

Practical default for orchestration (opinion, not a claim): default mid-tier + explicit medium/high effort for implementation; escalate model *or* effort only on failed verify/revise; keep recovery/cleanup on the cheapest model that can still write the report; check `clawmeter status --agent` before fleet spawn.

**Staleness:** pricing and evals move monthly. Re-fetch the three vendor primary URLs before any spend-critical decision; this entry is a snapshot dated 2026-07-09.
