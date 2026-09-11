---
title: "OpenAI launch charts can hide exact effort-and-cost curves in accessible SVG labels even when rendered text omits them"
date: 2026-09-05
topic: model-routing
tags: [openai, model-routing, reasoning-effort, benchmarks, chart-retrieval]
status: draft
sources: [openai-gpt-5-6-launch, openai-gpt-6-astra-launch, gpt56-svg-artifact, astra-hydration-artifact]
source_session: unknown
---

## CLAIMS

- The GPT-5.6 launch post contains a chart titled Agents Last Exam whose browser-accessible SVG labels identify GPT-5.6 Sol, Terra, and Luna, each at Low/Medium/High/XHigh/Max, with an exact score and an `API cost (USD)` value. [openai-gpt-5-6-launch] [gpt56-svg-artifact]
- The GPT-5.6 Agents Last Exam labels report Sol scores 44.8/51.9/52.1/53.6/52.7% and displayed API costs $248/$519/$577/$763/$1,087 from Low through Max; Terra 40.3/42.6/46.3/48.5/50.4% and $89/$128/$264/$381/$544; Luna 30.7/36.1/45.4/48.7/50.3% and $24/$57/$141/$254/$429. [gpt56-svg-artifact]
- The recovered GPT-5.6 SVG labels name `API cost (USD)` but do not name a denominator, so they do not establish a per-task or per-success cost. [gpt56-svg-artifact]
- The GPT-6 Astra launch page’s public Next.js hydration payload contains Vega-Lite specifications with explicit effort labels, scores, and chart x-values; a saved extraction records, for example, five labelled Terminal-Bench 4.0 settings. [openai-gpt-6-astra-launch] [astra-hydration-artifact]
- Direct non-browser retrieval of the GPT-5.6 launch URL returned a Cloudflare JavaScript/cookie challenge in this environment, while browser SVG access succeeded in another shared browser session. [openai-gpt-5-6-launch] [gpt56-svg-artifact]

## SOURCES

**openai-gpt-5-6-launch**
URL: https://openai.com/index/gpt-5-6/
Accessed: 2026-09-05
Quote: “max gives GPT‑5.6 even more time than xhigh to reason and explore alternatives” and “ultra goes further by coordinating four agents in parallel by default.”

**gpt56-svg-artifact**
URL: `~/code/minnows/tmp/workstreams/gpt56-launch-svg-evidence-2026-09-05.json`
Accessed: 2026-09-05
Quote: `Model: GPT-5.6 Sol; Effort Level: Xhigh; API cost (USD): $763; Score: 53.6%`.

**openai-gpt-6-astra-launch**
URL: https://openai.com/index/gpt-6-astra/
Accessed: 2026-09-05
Quote: The public page contains charted benchmark comparisons; exact chart data was recovered separately from its hydration payload.

**astra-hydration-artifact**
URL: `~/code/minnows/tmp/workstreams/astra-launch-chart-evidence-2026-09-05.json`
Accessed: 2026-09-05
Quote: Terminal-Bench 4.0 records Astra Low/Medium/High/Xhigh/Max as 49.70/53.94/57.88/57.58/56.67%, with x-values $4.95/$6.15/$7.21/$7.48/$10.35 labelled `api_cost_usd`.

## SYNTHESIS

Rendered article prose and static text extraction can lose the actual decision curve while leaving a chart visible and accessible. For a launch-page evidence pass, inspect in this order: SVG `aria-label`/accessible nodes; Next.js `self.__next_f.push` chunks, recursively decoding embedded JSON strings; then visible table prose. Persist a small raw extraction artifact with source URL, observed date, method, chart title, and exact label/value pairs.

The extraction is not permission to normalize ambiguous chart costs. A label that says only `API cost (USD)` must retain that unit until the publisher identifies whether it is per task, suite total, or another aggregate. Ultra/multi-agent points belong in a separate mode dimension from single-model reasoning effort.
