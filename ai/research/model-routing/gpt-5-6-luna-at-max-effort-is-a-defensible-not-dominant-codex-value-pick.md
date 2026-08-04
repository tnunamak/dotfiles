---
title: "GPT-5.6 Luna at max reasoning effort is a defensible cost/quality pick for bounded Codex coding tasks, but is not a broadly-consensus 'best Codex setting' and is not the default Codex tier"
date: 2026-08-02
topic: model-routing
tags: [codex, gpt-5.6, reasoning-effort, model-economics, luna, sol, terra, cost-per-success]
status: settled
sources: [openai-gpt-5-6-launch, openai-codex-config-reference, openai-codex-models-page, arcprize-gpt-5-6, deepswe-leaderboard, javascripthacker-combined-leaderboard, majesticlabs-luna-max-blog]
source_session: unknown
---

## CLAIMS

- Codex CLI's official config reference lists `model_reasoning_effort` values as `minimal | low | medium | high | xhigh`, with `xhigh` itself "model-dependent"; it does **not** list `max` as a config-file value. [openai-codex-config-reference]
- The OpenAI models page (learn.chatgpt.com/docs/models) separately documents `max` as a real reasoning level for GPT-5.6 models generally ("more time for the hardest problems") and describes it as an opt-in "Max mode" in the Codex CLI/app UI, gated behind an "Advanced"/settings toggle rather than being the default — "If you don't see Max in your options, you'll have to enable it... most tasks do not need Max or Ultra." [openai-codex-models-page]
- Codex CLI's default ("Power") tier is `gpt-5.6-sol` at medium reasoning, not Luna at any effort; Luna requires opening "Advanced" settings to select. [openai-codex-models-page]
- On OpenAI's own GPT-5.6 launch tables (vendor-reported, grade C in the minnows model-catalog), Luna scores below Sol and Terra on every single published metric at default effort — including coding-relevant ones: Artificial Analysis Coding Agent Index (Sol 80.0, Terra 77.4, Luna 74.6), SWE-Bench Pro (Sol 64.6%, Terra 63.4%, Luna 62.7%), DeepSWE v1.1 (Sol 72.7%, Terra 69.6%, Luna 67.2%), Terminal-Bench 2.1 (Sol 88.8%, Terra 87.4%, Luna 84.7%). [openai-gpt-5-6-launch]
- On ARC Prize's third-party verified effort ladder (grade B, the highest-grade cross-model evidence in the local catalog), Luna at `max` scores lower in raw accuracy than Sol or Terra at every effort tier on ARC-AGI-1 and ARC-AGI-2, but is cost-efficient: Luna@max = 88.0% ARC-AGI-1 at $0.67/task; Sol@medium = 92.5% at $0.47/task (higher score, lower cost, dominates Luna@max on this axis); Sol@high = 97.0% at $0.74/task (higher score, close cost). On ARC-AGI-2, Sol@medium (67.1% @ $0.47) also beats Luna@max (59.5% @ $0.67) on both axes simultaneously. [arcprize-gpt-5-6]
- Score-per-dollar computed directly from the ARC Prize ladder (score ÷ cost_per_task) shows Luna@medium (5.14 pts/$ on ARC-AGI-1) and Luna@low (4.89 pts/$) — not Luna@max (1.31 pts/$) — as Luna's own best value points; Sol@medium (1.97 pts/$) beats Luna@max on both accuracy and $/point. Luna@max is not a Pareto-optimal point among the tiers this corpus can verify. [arcprize-gpt-5-6] (derivation: see minnows data-model-catalog `performance/arcprize-gpt-5-6-2026-07.json`, computed 2026-08-02)
- A third-party leaderboard (DeepSWE, `mini-swe-agent` harness, 113 long-horizon coding tasks across 91 repos/5 languages, dated 2026-07-25) reports, at effort=max: gpt-5.6-sol 73%±3% pass@1 at $8.39/task avg; gpt-5.6-terra 70%±3% at $3.96/task; gpt-5.6-luna 67%±4% at $0.61/task. [deepswe-leaderboard] [javascripthacker-combined-leaderboard]
- On that same DeepSWE reading, Luna@max is ~13.75x cheaper than Sol@max for a 6-point pass@1 gap, and the reported confidence intervals for Sol/Terra/Luna@max overlap, meaning the point-estimate ranking is not statistically decisive at this sample size. [majesticlabs-luna-max-blog]
- The claim "Luna Max is the best Codex setting" as a specific slogan could not be found on Hacker News or in a general web/Reddit search; the only sources repeating cost/quality framing favorable to Luna@max are a small number of AI-tooling blogs (Majestic Labs, a "javascripthacker" leaderboard-merge blog) plus derivative SEO content-mill pages, all ultimately citing the same DeepSWE leaderboard reading. This is not a broad community consensus, it is a handful of analysts converging on one third-party benchmark's cost/quality framing. [deepswe-leaderboard]
- OpenAI's own Codex model guidance explicitly recommends starting with Sol if uncertain and reserving Luna for "specific, high-volume tasks where you know what success looks like" — i.e. a task-shape recommendation, not a universal "use Luna at max" default. [openai-codex-models-page]

## SOURCES

**openai-gpt-5-6-launch**
URL: https://openai.com/index/gpt-5-6/
Accessed: 2026-08-02 (also previously ingested into minnows model-catalog on 2026-07-09 as source_id `openai-gpt-5-6-2026-07-09`)
Quote: (page returned HTTP 403 to direct fetch on 2026-08-02; figures cross-checked against the already-ingested transcription in `~/code/minnows/data/model-catalog/performance/openai-gpt-5-6-launch-2026-07.json`, itself sourced from this URL)

**openai-codex-config-reference**
URL: https://developers.openai.com/codex/config-reference (redirects to https://learn.chatgpt.com/docs/config-file/config-reference)
Accessed: 2026-08-02
Quote: "minimal | low | medium | high | xhigh" with "xhigh is model-dependent" — no `max` value listed for `model_reasoning_effort` in the config file reference.

**openai-codex-models-page**
URL: https://developers.openai.com/codex/models (redirects to https://learn.chatgpt.com/docs/models)
Accessed: 2026-08-02
Quote: "Max gives the selected model more time to reason about a single task. Use it for the hardest problems, when depth matters more than speed or usage. If you don't see Max in your options, you'll have to enable it in your app settings. That said, most tasks do not need Max or Ultra." / "Start with the default Power setting, which uses gpt-5.6-sol with medium reasoning... Open Advanced when you want gpt-5.6-luna or a specific model, reasoning effort, or speed."

**arcprize-gpt-5-6**
URL: https://arcprize.org/results/openai-gpt-5-6 and https://arcprize.org/leaderboard
Accessed: 2026-07-09 (already ingested into minnows model-catalog, source_id `arcprize-gpt-5-6-2026-07-09`); re-derived score/cost ratios locally 2026-08-02 from `~/code/minnows/data/model-catalog/performance/arcprize-gpt-5-6-2026-07.json`, evidence_grade B (third_party_board).

**deepswe-leaderboard**
URL: https://deepswe.datacurve.ai/
Accessed: 2026-08-02
Quote: "gpt-5.6-sol [max]: Pass@1 73%±3%, Avg Cost $8.39 | gpt-5.6-terra [max]: 70%±3%, $3.96 | gpt-5.6-luna [max]: 67%±4%, $0.61" — evaluated "using mini-swe-agent for consistency," 113 tasks, 91 repos, 5 languages.

**javascripthacker-combined-leaderboard**
URL: https://www.javascripthacker.com/blog/combined-ai-coding-leaderboard-cursorbench-deepswe
Accessed: 2026-08-02
Quote: Reports a slightly different reading of the same DeepSWE data ("GPT-5.6 Luna Max: Mean correctness 64.14%, Mean cost $0.50"; Sol Max 69.93%/$7.04) — the blog explicitly states it hand-merged CursorBench and DeepSWE, i.e. this is a secondary aggregation, not the primary leaderboard; treat the direct deepswe.datacurve.ai numbers as more authoritative than this transcription.

**majesticlabs-luna-max-blog**
URL: https://majesticlabs.dev/blog/202608/using-gpt-5-6-luna-at-max
Accessed: 2026-08-02
Quote: "Luna Max matched GPT-5.5 XHigh's point estimate and finished 6 points behind Sol Max. Its reported average cost was $0.61, compared with $8.39 for Sol Max, or about 13.75x lower... the confidence intervals overlap, so the small score gaps don't establish definitive rank differences." Author: David Paluy, company blog (Majestic Labs), not OpenAI or an independent benchmark org.

## SYNTHESIS

**Verdict: the claim does not hold as stated.** "Luna max is THE best Codex setting" is an overreach — no single (model, effort) tuple is best across the accuracy axis, the cost axis, and the pass-rate-per-dollar axis simultaneously; the honest finding is that the (model × effort) space is a genuine Pareto frontier, and Luna@max occupies a real but narrow slice of it (cheapest tier that still clears "high absolute pass-rate", ~$0.50-0.61/task on 113-task DeepSWE reading), not a dominant point.

Three separate weakenings of the claim, in order of how much they matter:

1. **Not dominant on quality-per-dollar even within its own effort ladder.** On the one grade-B (third-party, ARC Prize verified) effort-stratified series this corpus has, Luna@max is beaten on BOTH accuracy and cost by Sol@medium on ARC-AGI-1 and ARC-AGI-2. Luna's own best score/$ points are medium/low effort, not max. This directly contradicts a literal "luna max is best" reading, though ARC-AGI is a reasoning benchmark, not a coding benchmark, so it's an imperfect proxy.

2. **On the one relevant third-party coding benchmark (DeepSWE, mini-swe-agent harness), Luna@max is a genuinely strong cost/quality point** — 67% pass@1 at $0.61/task vs Sol@max's 73% at $8.39/task, i.e. ~92% of Sol's quality at ~7% of Sol's cost. This is the real evidence behind the "best value" flavor of the claim, and it is a legitimate finding — but (a) it's a single leaderboard reading with wide, overlapping confidence intervals (the source itself says score gaps aren't statistically decisive), (b) it used `mini-swe-agent`, not Codex's own native harness, so it doesn't directly measure "Codex CLI performance," and (c) "cheapest tier that still clears a quality bar" is a defensible operating point, not "the best," full stop — Sol@max is still the highest absolute-quality point on the same table.

3. **"Luna max" is not even the default or most-discoverable Codex configuration.** Official OpenAI docs confirm Sol@medium is the Codex CLI default; Luna requires opening "Advanced" settings, and Max mode is a separate opt-in toggle that most users won't see without deliberately enabling it. OpenAI's own guidance steers users toward Sol for anything not "specific, high-volume, know-what-success-looks-like" work. So even accepting Luna@max's value proposition, calling it "the best Codex setting" broadly (vs. a good bounded-task setting) contradicts the vendor's own routing guidance.

4. **No broad community consensus exists.** Targeted HN/Reddit searches for this specific claim returned nothing on record. The supportive sources are a handful of AI-tooling blogs (Majestic Labs primarily) all citing one third-party leaderboard, echoed by SEO/content-mill aggregator sites with no independent data. This is "a few analysts converged on one benchmark reading," not "the community has settled on this."

**Bottom line for waspflow / minnows model-choice-policy purposes:** Luna@max is a legitimate, evidence-backed *operating point* for `implement.quota-tight`-style bounded coding work where cost matters more than ceiling quality — comparable in spirit to the existing `implement.quota-tight` op (Sonnet 5 @ low) on the Claude side. It should NOT replace Sol@xhigh in `implement.accuracy-first` or `review.audit`, and it should not be adopted as a blanket default. The existing minnows policy pack's `preferred_over` entry (gpt-5.6-luna > gpt-5.4-mini for "cheap-tier work") is consistent with this finding and needs no change; there is not yet strong enough evidence to add a new ratified `preferred_over` edge naming Luna@max specifically as superior to Sol or Terra at any effort — the DeepSWE reading is directionally supportive but single-source with overlapping CIs.

**What would raise confidence:** an independent (non mini-swe-agent) reading of GPT-5.6 tier×effort on a coding benchmark, ideally using Codex's native harness; a second benchmark corroborating the DeepSWE cost/quality shape; narrower confidence intervals (more than 113 tasks) so the Sol/Terra/Luna gap at max is statistically separable.
