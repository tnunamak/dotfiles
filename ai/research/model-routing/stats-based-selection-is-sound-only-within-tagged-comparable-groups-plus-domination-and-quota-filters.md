---
title: "Model selection is sound as identity-blind stats only WITHIN tagged-comparable benchmark groups plus a domination filter and a quota filter; learned routers are not worth calibrating for a small custom pool; five human-set slots are irreducible"
date: 2026-07-15
topic: model-routing
tags: [model-selection, routing, difficulty-estimation, benchmarks, comparability, routellm, nvidia-classifier, routing-plateau, quota, effort]
status: draft
sources: [openrouter-auto, anthropic-effort-docs, claude-code-model-config, routellm-paper, routellm-github, frugalgpt-arxiv, irt-router, ucci-cascade, confidence-tokens, revisable-by-design, controllability-trap, portkey-conditional-routing, portkey-task-routing, martian-routerbench, braintrust-routers-2026, openai-agents-models, langgraph-comparison, nvidia-prompt-complexity-classifier, nvidia-llm-router-blueprint, modernbert-router-recipe, unified-routing-cascading, routerbench-arxiv, llmrouterbench-arxiv, routerarena-arxiv, irt-router-acl, graphrouter-iclr, avengers-pro-arxiv, hybridllm-arxiv, routing-plateau-arxiv, routellm-iclr-v4, leaderboard-illusion, azure-foundry-model-router, openrouter-models-api, omniroute, litellm-router]
source_session: ac9e632b-99e9-4ba2-a900-4b477a5cd48c
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation/conclusions. Skippable. No citations here.
-->

Researched 2026-07-15 for waspflow's model-choice design (context: `docs/design/MODEL_CHOICE_ROUTING.md` in `~/code/waspflow`). Synthesizes five subagent research passes: input dimensions for routing, reusability/licensing of routers, whether NVIDIA's complexity classifier is frontier, calibration cost of learned routers on a small custom pool, and identity-blind stats-based selection feasibility.

## CLAIMS

### Input dimensions: difficulty and a cost/quality dial dominate; task-type is a weak proxy; stakes/reversibility is recognized but unindexed
- The dominant routing-product inputs cluster into (a) a learned prediction over the prompt itself (embeddings/classifier/meta-model) and (b) a caller-set cost↔quality knob — not a task-type taxonomy. [openrouter-auto][routellm-paper]
- OpenRouter's Auto Router (Not-Diamond-powered) exposes `cost_quality_tradeoff` (integer 0–10, default 7; 0=pure quality, 10=cheapest), `allowed_models`, and `session_id`; docs state it considers "prompt complexity, task type, and model capabilities" internally but the caller-facing schema is a dial + pool constraint, not a taxonomy; docs are explicit it is "not a cost-minimizer." [openrouter-auto]
- RouteLLM's learned score is functionally "how hard/frontier-requiring is this query" — a per-query difficulty estimate, not a type lookup. [routellm-paper]
- Portkey's conditional routing operates on request params + caller-supplied metadata; for task-based routing it recommends keyword-match, upstream tags, or a small classifier — i.e., it is a config engine, not an opinionated axis choice. [portkey-conditional-routing][portkey-task-routing]
- Difficulty/complexity estimation is treated in the 2025-2026 literature as superior to task-type routing: cascades (FrugalGPT) escalate on discovered per-query difficulty rather than assumed type; IRT-Router jointly models query difficulty and model ability; the critique of type-based lookup is that "routers make routing decisions before conditioning on an actual candidate response ... which leaves out a crucial signal," and two same-type tasks can differ 10x in difficulty while a static type→model map gives them the same model. [frugalgpt-arxiv][irt-router][ucci-cascade]
- Anthropic's effort docs (verified primary source): effort is "a single model" dial trading thoroughness vs. token efficiency; API default is `high`; effort affects all tokens including tool calls; recommendation is "Consider dynamic effort: Adjust effort based on task complexity"; for Opus 4.7/4.8, "Start with `xhigh` for coding and agentic ... step down to `medium`/`low` only when you've measured that the lower level holds quality on your evals." [anthropic-effort-docs]
- OpenAI GPT-5.6 recommends `medium` as balanced default, `low` for latency-sensitive, `high`/`xhigh` when measured gains justify it; GPT-5.6 treats effort as a ceiling not a floor (may do zero reasoning on easy prompts even at high effort). [claude-code-model-config note: this GPT-5.6 claim sourced from a secondary explainer, not verified primary]
- Claude Code subagents use `model` (`sonnet|opus|haiku|<full id>|inherit`, default `inherit`) plus a separate `effort` field (`low…max`, defaults to inherit); guidance is role/tier-based (Opus for orchestration/judgment, Sonnet for implementation, Haiku for search/lookups) — a capability tier bound to sub-agent ROLE, not a per-task difficulty estimate. [claude-code-model-config]
- OpenAI Agents SDK, LangGraph, CrewAI, and AutoGen/AG2 all bind model choice to sub-agent role/node/type (free model string per agent, or a manager LLM that delegates) — none of these frameworks expose a per-task difficulty estimate as an input; they push difficulty judgment onto the human/config author. [openai-agents-models][langgraph-comparison]
- Stakes/reversibility is a recognized and rising but not yet standardized routing input, orthogonal to difficulty: the "Irreversibility Cost Principle" states unavoidable costs of irreversible actions "cannot be reduced by improving the planner, prompt, or LLM" — the only leverage is routing to a stronger model or a human before the action; verification is argued to be most valuable for high-impact/irreversible actions (DB writes, code merges, sends); an "Irreversibility Budget" governance proposal maps each action to a 0→1 un-undoability scalar, accumulates it, and pauses for human re-authorization when a budget is hit. [revisable-by-design][controllability-trap]

### Reusability/licensing: nothing off-the-shelf fits a non-proxying CLI; the reusable core is a difficulty signal, not a router
- RouteLLM (Apache-2.0, self-hostable, ships pretrained routers `mf`/`bert`/`causal_llm`/`sw_ranking` on HuggingFace trained on Chatbot Arena preference data + GPT-4-judge augmentation) has a `Controller` object that computes a win-rate score and returns a strong-vs-weak decision separable from actually issuing the downstream completion — the closest thing to a reusable, proxy-free recommender. But its code is dormant (no commits since 2024-08-10, verified via GitHub API), it is binary (strong/weak, not N-tier), and the `mf`/`sw_ranking` routers still need an OpenAI key to embed at decision time. [routellm-github]
- Not Diamond's SDK is public but the repo is archived (`archived: true`, last push 2025-12-11) with no LICENSE file (license field null); `model_select()` requires a network call to Not Diamond's hosted API — the intelligence is not in the SDK. [ad40240889bc0da79 source, no separate slug — see synthesis note]
- OpenRouter Auto Router is a pure gateway feature (itself powered by Not Diamond); the decision is inseparable from routing traffic through OpenRouter — cannot get the recommendation without being the inference customer. [openrouter-auto]
- FrugalGPT/cascades are a research repo + technique (Apache-2.0, last push 2025-02), not a maintained drop-in library; the cascade shape (score a cheap response, then escalate) requires a response to score first, which doesn't map to picking a model BEFORE spawning an interactive agent CLI. [frugalgpt-arxiv]
- Martian's ML router is hosted SaaS (not separable); `deimos-router` (rule-based config router) has no license; Unify is proprietary SaaS; Portkey's gateway core is open-sourced (Apache-2.0, ~March 2026) but its routing is config inside the gateway proxy, not a standalone decision library; LiteLLM's "Router" is MIT and self-hostable but does deployment/fallback/cost/latency selection across replicas of the SAME model pool, not prompt-difficulty model selection — the wrong kind of routing for choosing which model. [martian-routerbench][portkey-conditional-routing]
- NVIDIA's `prompt-task-and-complexity-classifier` (HuggingFace, NVIDIA Open Model License, ~0.2B params, DeBERTa-v3-base backbone, 512-token default) loads standalone via plain `transformers`, needs no inference stack/gateway/API, and outputs task type (11 categories) plus a numeric `prompt_complexity_score` computed as a transparent weighted sum (0.35 creativity + 0.25 reasoning + 0.15 constraint + 0.15 domain-knowledge + 0.05 contextual + 0.05 few-shots). This is the one artifact that is genuinely reusable and proxy-free, though it is a ~200M-param PyTorch dependency — heavy for a bash CLI, would need a sidecar/subprocess. [nvidia-prompt-complexity-classifier]

### Is the NVIDIA classifier frontier? No — it is a data-curation/convenience tool, not a deployed router, including at NVIDIA itself
- The best routers in the 2025-2026 literature predict "which model wins on THIS query" from empirical eval/preference data via four families: learned preference (RouteLLM matrix factorization on ~80k Chatbot Arena win/loss battles), correctness-vector clustering (Avengers/Avengers-Pro: embed query → K-means → per-cluster empirical accuracy, training-free), psychometric IRT (IRT-Router, ACL 2025: 2PL-MIRT joint query-difficulty/model-ability model), and graph/GNN (GraphRouter, ICLR 2025: heterogeneous task/query/model graph). [irt-router-acl][graphrouter-iclr]
- RouteLLM's matrix-factorization variant achieves 95% of GPT-4 quality at ~26% of GPT-4 calls (~48% cheaper than random routing; ~85% cost cut vs. always-GPT-4 on MT-Bench). [routellm-paper]
- LLM-as-judge is used at TRAINING time to cheaply generate preference labels, not deployed as the router itself at inference time — a per-query judge call burns the cost savings routing exists to capture, and "simple kNN beats complex learned routers" per a dedicated benchmark paper. [routing-plateau-arxiv note: kNN claim also appears in routing-plateau; separately cited paper arXiv:2505.12601 in source report]
- A 0.2B complexity tagger (HybridLLM-class, ICLR 2024) ranks roughly co-equal with learned preference routers on peak in-domain quality — ~40% fewer large-model calls at near-no quality drop, similar ballpark to RouteLLM; the 2026 consolidating benchmark LLMRouterBench finds routing methods are "broadly comparable," and RouterBench/RouterEval/"The Routing Plateau" all report deployable router families clustering at a shared accuracy ceiling far below the oracle. [hybridllm-arxiv][llmrouterbench-arxiv][routing-plateau-arxiv]
- The complexity tagger's real disadvantage is NOT peak quality but out-of-domain generalization and multi-turn drift; its advantages are latency (single-digit ms) and cheap retraining on your own workload. [af00ec42deb1c2119 source]
- NVIDIA's classifier was trained on 4,024 prompts to output task type + a hand-weighted complexity score, which is not calibrated to which model wins — HybridLLM-style routers are instead trained on the actual weak-vs-strong outcome gap; same size class, different (and correct) training target. [nvidia-prompt-complexity-classifier]
- No documented case exists of the NVIDIA classifier being used in a real production router, including at NVIDIA: its HuggingFace model card and NeMo Curator docs present it as a distributed data-curation classifier (JSONL-in → annotate/filter → JSONL-out for post-training datasets); NVIDIA's own production LLM Router Blueprint does NOT load this model — it uses a Qwen-1.7B intent classifier and a CLIP-embedding + trained-NN auto-router instead; the classifier appears only in "related reading." Third-party complexity routers (kani, NadirRouter, smart-model-router) all ship their own classifiers; none load NVIDIA's. [nvidia-llm-router-blueprint]
- The genuine 2026 frontier has two peaks: (a) best deployable QUALITY signal is response-conditioned cascade routing (Dekoninck et al., "Unified Routing and Cascading," arXiv:2410.10347: cascade-routing AUC 76.31 > routing 74.43 > threshold cascade 73.03 on RouterBench; up to +14% on SWE-Bench) — but it costs a cheap-model generation up front, and naive threshold cascades can fall below always-strong once overhead is counted; (b) best practical COST-EFFICIENCY signal is embedding+clustering over empirical accuracy (Avengers-Pro: training-free, Pareto-dominant in LLMRouterBench, up to +4% accuracy / −31.7% cost vs. best single model), and it beats the learned neural routers — evidence the "learned predictor" frontier has hit diminishing returns. [unified-routing-cascading][avengers-pro-arxiv]
- In RouterArena (arXiv:2510.00202, Oct 2025), proprietary SaaS router Not Diamond ranked #12 ("frequently selects expensive models"); open routers (CARROT, vLLM Semantic Router, GraphRouter) led on cost-efficiency. [routerarena-arxiv]

### Calibration cost on a small custom pool: not worth it; a threshold/cascade heuristic captures most of the value; RouteLLM transfer is narrow
- RouteLLM's own ICLR v4 camera-ready claims routers "generalize very well across different model pairs without any retraining," but the tested transfer pairs are Claude 3 Opus/Sonnet and Llama 3.1 70B/8B — both family-internal swaps preserving a large, monotonic strong≫weak capability gap, the same shape as the GPT-4/Mixtral pair it trained on; there is no test on a compressed or inverted gap (two near-equal frontier models, or a smaller-but-smarter model). [routellm-iclr-v4]
- The router predicts P(strong model wins | query) ≈ a query-difficulty score; this transfers only as long as the new "strong" model genuinely wins the same hard queries — for a modern pool with a small, non-monotonic gap across task types, the learned win-rate signal has no principled reason to map cleanly. Even when weights transfer, the routing threshold must be recalibrated per model-pair and per workload — "no retraining" is not "no calibration." [routellm-iclr-v4]
- RouteLLM routers trained on human Arena data alone perform "at the level of the random router" out-of-domain on MMLU, and "close to random" on GSM8K (verbatim) — the published checkpoints only work because of GPT-4-judge augmentation, so reuse requires the `*_augmented` `mf` checkpoint specifically. [routellm-iclr-v4]
- Avengers-Pro's "training-free" claim is honest about gradients but hides a real setup cost: its router is a k-means + per-cluster lookup table requiring every candidate model to be run on every calibration query — concretely ~8 frontier models × ~1,822 calibration queries ≈ ~14,600 paid frontier-API calls just to build the table, before routing one production query; adding/swapping a model requires re-running it across all calibration queries, and the table degrades if the task mix shifts. [avengers-pro-arxiv]
- Avengers-Pro vs. best single model (GPT-5-medium): +7% accuracy at equal cost, OR equal accuracy at −27% cost, OR 90% accuracy at −63% cost; independently echoed by LLMRouterBench ("nearly dominates the frontier"). [avengers-pro-arxiv][llmrouterbench-arxiv]
- RouteLLM's own labeling cost: ~65k human Arena battles + ~120k GPT-4-judged pairs costing ~$700 + ~1,500 MMLU golden labels; the augmentation (not the 65k human pairs) did the out-of-domain generalization work. An ablation shows ~1,500 well-targeted samples (<2% of data) moved routers from near-random to strong; calibration-style routers saturate around ~150 pairs. Estimated dollar cost to generate coding preference pairs with a mid-tier judge (~$0.03–0.06/pair): N=500 → ~$8–16; N=2,000 → ~$32–62; N=10,000 → ~$160–310 — judging cost is not the bottleneck, sourcing diverse representative prompts is. [routellm-iclr-v4]
- "The Routing Plateau" (2026): top routers are statistically indistinguishable; kNN ranks top-2 on all benchmarks and beats every trained method on BCE; full fine-tuning buys only ~0.69pp over frozen kNN (abstract verbatim-confirms the qualitative claim that "many methods, including kNN... converge to a narrow performance range... far below the oracle"; the precise 0.23pp/0.69pp figures are body-sourced, not abstract-verified). [routing-plateau-arxiv]
- LLMRouterBench (2026): several learned routers, including commercial OpenRouter (−24.7%), fail to beat "always use the best single model"; sophisticated routers "deliver nearly indistinguishable results." Diminishing returns on pool size: the biggest gain is small→moderate pool size; "a moderate pool plus a robust router gives most of the achievable benefit" — the marginal model matters, marginal router sophistication doesn't. [llmrouterbench-arxiv]
- Even a random router captures ~half of RouteLLM's savings; the learned edge over random is a bounded multiplier (~48–75% cheaper than random) because most queries are easy and any decent threshold routes 70–86% of them to the cheap model. FrugalGPT-style cascades match GPT-4 at up to 98% cost reduction using only a quality/confidence scorer, no pairwise preference labels; the sophisticated combined routing+cascading strategy beats a plain threshold cascade by only ≤2%, and that edge widens only with many models and clean estimates — neither is true for a 3-tier pool. [routellm-iclr-v4][unified-routing-cascading]
- The real bottleneck for all approaches is the oracle gap (10–30pp): "only one model is right and the router can't tell which" is a prediction problem no fancier router closes; raw self-reported confidence "cannot serve as a filtering criterion" — use self-consistency (resample k=5, accept on agreement), perplexity, or a small calibrated probe instead. [af0707dd34b50da863 source note]

### Identity-blind stats-only selection: unsound as pure blind; sound within a domination + quota filter; five human-set slots are irreducible
- No shipped 2026 production system does true identity-blind selection where a new model auto-qualifies purely from a published stats table with no hand-maintained list: LiteLLM Router routes by deployment property (cost/latency/least-busy) but is identity-blind only AMONG a human-written YAML deployment list; OpenRouter `auto` (Not-Diamond-powered) picks per-request from a "curated set" that docs say "may be updated as new models become available" — i.e., humans update it; Azure Foundry Model Router (2025-11-18) is the high-water mark — it auto-expands its pool in place ("new underlying models are added without changing the version identifier") but expansion is Microsoft-curated (they onboard + retrain), not stats-triggered. [azure-foundry-model-router][openrouter-auto]
- The data layer for stats-only selection is fully productized (OpenRouter `/api/v1/models` supports `?supported_parameters=tools&sort=pricing-low-to-high`) but no system closes the loop so a brand-new catalog row auto-qualifies into live traffic without a human blessing it. [openrouter-models-api]
- Cross-vendor benchmark comparability is CATASTROPHICALLY broken as raw numbers: a benchmark name is not a comparable number because the harness/scaffold around a model moves scores 10-20+ points with the model unchanged — OpenAI's own SWE-bench Verified launch: best scaffold took GPT-4o from 16%→33.2% (doubled); the same Opus 4.5 scored 50.2%–55.4% across three agent systems; Anthropic-reported 69.2% vs. Scale SEAL's 51.9% on the same model (17.3-pt gap); "The Leaderboard Illusion" (NeurIPS 2025, arXiv:2504.20879) documents Arena is structurally biased by selective disclosure. The only fix is one operator running one fixed harness across all models — i.e., a `comparability_group` tag (metric × source_type × harness), with vendor tables, third-party boards, and digitized charts held in separate, non-cross-rankable groups even for the "same" benchmark. [leaderboard-illusion]
- RouterBench (built specifically for routing) is dead, frozen on 2023 models (Claude-v1/v2, GPT-3.5); only rolling boards (LiveBench/LiveCodeBench) and Artificial Analysis stay current; no maintained public dataset isolates narrow task types like "code review" specifically. [routerbench-arxiv]
- "Latest frontier wins" is directionally true but the frontier is a cluster, not a point: Artificial Analysis (June 2026) found only 13 of 351 priced models sit on the intelligence-price Pareto frontier (~96% dominated); old BIG models are essentially always dominated and auto-excluded, and price decline (~10×/yr) keeps them off the frontier since new models arrive both better and cheaper — BUT effort is a load-bearing axis (Sonnet 5's value proposition is a wider cost-performance range via effort) so `(model, effort)` must be treated as distinct arms, effort scaling is non-monotonic (GPT-5 accuracy DECREASED with effort in one measurement, 49.6%→48.1%), and an old TINY model can remain cost-optimal for short-context, high-volume, low-stakes work. [af628680c6025c958 source]
- Quota-headroom-aware selection is shipped prior art (OmniRoute tracks 5h+weekly windows per provider/model, has a `headroom` strategy, and blends ~9 factors including remaining quota + cost in `auto` mode; LiteLLM does the load-balancing half via rate-limit/budget filters), but the dollars↔quota exchange rate has no automatic optimum anywhere observed — subscriptions run 15-30x cheaper than API for the same work, and providers hard-separate the currencies (setting `ANTHROPIC_API_KEY` is an all-or-nothing reroute, not graceful spillover). [omniroute]
- Hiding model identity from a preference JUDGE avoids a real, ranking-flipping bias: self-preference in LLM-as-judge is robust (Panickssery, NeurIPS 2024: ~10pt GPT-4 self-bias, ~25pt Claude, ~+0.14 family-wide); relabeling identical text as "Claude" vs. "Gemini" shifts scores up to ~50 points and can fully reverse rankings (arXiv:2508.21164); LMArena blinds identity by design for this reason — but blinding is necessary, not sufficient, since even blind judges are gamed by verbosity/style. Conversely, identity IS a legitimate prior at the POLICY layer that raw stats miss, because published stats are contaminated and cherry-picked (MMLU ~29% contaminated) and there is a ~37% benchmark-to-deployment reliability gap — a lab's track record on instruction-following/tool-use/cross-run consistency is real, non-redundant signal, as long as "identity" means earned outcome history (lineage-as-evidence) rather than the brand label (brand-as-halo). No rigorous proof was found that raw brand reputation beats a good held-out benchmark — only that it beats a single vendor-published number. [af628680c6025c958 source]
- The irreducible human-set slots identified: (1) the task→benchmark-axis mapping (no public dataset isolates narrow task types like "code review" — requires a private eval); (2) the performance bar per task family ("adequate" vs. "audit-grade"); (3) the trust/comparability weighting of stat sources (which `comparability_group`s are cross-rankable — cannot be inferred, must be tagged); (4) the quota↔dollar exchange rate (a policy/shadow-price choice, not a derivable optimum); (5) the candidate-admission gate (a brand-new model still needs a human/steward to run it through a fixed harness before it can win live traffic — the one thing no shipped system automates). [af628680c6025c958 source]
- The recommended sound minimum-viable design: capability filters (context length, tools, vision, JSON-mode) plus, WITHIN a single tagged comparability group, a domination filter (drop any arm Pareto-dominated on tagged-comparable stats — auto-retires stale models with zero hand-list) and a quota filter (drop exhausted-window arms via live quota tracking, plus a burn-rate shadow-price knob for quota vs. dollars) — this captures the real wins of "blind" selection (new-model auto-consideration among tagged candidates, stale-model auto-drop, quota-awareness) while keeping the five human-set slots explicit. [af628680c6025c958 source]

## SOURCES

**openrouter-auto**
URL: https://openrouter.ai/docs/guides/routing/routers/auto-router
Accessed: 2026-07-15
Quote: "cost_quality_tradeoff (0-10, default 7)... not a cost-minimizer"

**anthropic-effort-docs**
URL: https://platform.claude.com/docs/en/build-with-claude/effort
Accessed: 2026-07-15
Quote: "Consider dynamic effort: Adjust effort based on task complexity." / "Start with xhigh for coding and agentic ... step down to medium/low only when you've measured that the lower level holds quality on your evals."

**claude-code-model-config**
URL: https://code.claude.com/docs/en/model-config
Accessed: 2026-07-15

**routellm-paper**
URL: https://arxiv.org/pdf/2406.18665
Accessed: 2026-07-15
Quote: "Our routers generalize very well across different model pairs without any retraining." (ICLR 2025 camera-ready v4)

**routellm-github**
URL: https://github.com/lm-sys/RouteLLM
Accessed: 2026-07-15
Quote: last code push verified via GitHub API as 2024-08-10 (dormant despite 2026 star/metadata activity)

**routellm-iclr-v4**
URL: https://arxiv.org/pdf/2406.18665
Accessed: 2026-07-15
Quote: routers trained on human Arena data alone perform "at the level of the random router" out-of-domain on MMLU, "close to random" on GSM8K; transfer tested on Claude 3 Opus/Sonnet and Llama 3.1 70B/8B (family-internal, large-gap pairs)

**frugalgpt-arxiv**
URL: https://www.emergentmind.com/topics/frugalgpt (secondary summary) / https://github.com/stanford-futuredata/FrugalGPT (Apache-2.0, verified, last push 2025-02)
Accessed: 2026-07-15

**irt-router**
URL: https://arxiv.org/html/2606.27457 (Cluster-Route-Escalate) and IRT-Router ACL 2025
Accessed: 2026-07-15

**irt-router-acl**
URL: arXiv:2506.01048 (ACL 2025)
Accessed: 2026-07-15

**ucci-cascade**
URL: https://arxiv.org/pdf/2605.18796
Accessed: 2026-07-15

**confidence-tokens**
URL: https://arxiv.org/pdf/2410.13284
Accessed: 2026-07-15

**revisable-by-design**
URL: https://arxiv.org/pdf/2604.23283
Accessed: 2026-07-15
Quote: "the unavoidable costs of irreversible actions ... cannot be reduced by improving the planner, prompt, or LLM"

**controllability-trap**
URL: https://arxiv.org/pdf/2603.03515
Accessed: 2026-07-15

**portkey-conditional-routing**
URL: https://portkey.ai/docs/product/ai-gateway/conditional-routing
Accessed: 2026-07-15

**portkey-task-routing**
URL: https://portkey.ai/blog/task-based-llm-routing/
Accessed: 2026-07-15

**martian-routerbench**
URL: https://withmartian.com/post/introducing-routerbench
Accessed: 2026-07-15

**braintrust-routers-2026**
URL: https://www.braintrust.dev/articles/best-llm-routers-2026
Accessed: 2026-07-15

**openai-agents-models**
URL: https://openai.github.io/openai-agents-python/agents/ and https://openai.github.io/openai-agents-python/models/
Accessed: 2026-07-15

**langgraph-comparison**
URL: https://dev.to/pockit_tools/langgraph-vs-crewai-vs-autogen-the-complete-multi-agent-ai-orchestration-guide-for-2026-2d63
Accessed: 2026-07-15

**nvidia-prompt-complexity-classifier**
URL: https://huggingface.co/nvidia/prompt-task-and-complexity-classifier
Accessed: 2026-07-15
Quote: complexity score = 0.35·creativity + 0.25·reasoning + 0.15·constraint + 0.15·domain-knowledge + 0.05·contextual + 0.05·few-shots; trained on 4,024 prompts

**nvidia-llm-router-blueprint**
URL: https://github.com/NVIDIA-AI-Blueprints/llm-router
Accessed: 2026-07-15
Quote: NVIDIA's production router uses a Qwen-1.7B intent classifier + CLIP-embedding/trained-NN auto-router; the complexity classifier does not appear as a loaded component

**modernbert-router-recipe**
URL: https://www.philschmid.de/fine-tune-modern-bert-in-2025 ; dataset DevQuasar/llm_router_dataset-synth, F1≈0.93
Accessed: 2026-07-15

**unified-routing-cascading**
URL: arXiv:2410.10347 (Dekoninck et al., ICML 2025)
Accessed: 2026-07-15
Quote: cascade-routing AUC 76.31 > routing 74.43 > threshold cascade 73.03 on RouterBench; up to 14% gain on SWE-Bench

**routerbench-arxiv**
URL: arXiv:2403.12031
Accessed: 2026-07-15
Quote: frozen on 2023-era models (Claude-v1/v2, GPT-3.5)

**llmrouterbench-arxiv**
URL: arXiv:2601.07206 (2026)
Accessed: 2026-07-15
Quote: routing methods are "broadly comparable"; commercial OpenRouter −24.7% vs. best single model

**routerarena-arxiv**
URL: arXiv:2510.00202 (Oct 2025)
Accessed: 2026-07-15
Quote: Not Diamond ranked #12, "frequently selects expensive models"

**graphrouter-iclr**
URL: arXiv:2410.03834 (ICLR 2025)
Accessed: 2026-07-15

**avengers-pro-arxiv**
URL: arXiv:2508.12631 (also original Avengers arXiv:2505.19797)
Accessed: 2026-07-15
Quote: +7% accuracy at equal cost, OR equal accuracy at −27% cost, OR 90% accuracy at −63% cost vs. GPT-5-medium

**hybridllm-arxiv**
URL: arXiv:2404.14618 (ICLR 2024)
Accessed: 2026-07-15
Quote: up to 40% fewer large-model calls at near-no quality drop

**routing-plateau-arxiv**
URL: arXiv:2606.07587 (2026)
Accessed: 2026-07-15
Quote: "many methods, including kNN... converge to a narrow performance range... far below the oracle" (abstract-verified qualitative claim); 0.23pp/0.69pp figures are body-sourced, not abstract-verified

**leaderboard-illusion**
URL: arXiv:2504.20879 (NeurIPS 2025)
Accessed: 2026-07-15

**azure-foundry-model-router**
URL: Azure AI Foundry Model Router docs (2025-11-18 release)
Accessed: 2026-07-15
Quote: "new underlying models are added without changing the version identifier"

**openrouter-models-api**
URL: https://openrouter.ai/docs (models list API, `?supported_parameters=tools&sort=pricing-low-to-high`)
Accessed: 2026-07-15

**omniroute**
URL: OmniRoute project docs (quota-headroom routing, `headroom` strategy)
Accessed: 2026-07-15

**litellm-router**
URL: LiteLLM Router docs
Accessed: 2026-07-15

## SYNTHESIS

The five reports converge on one architecture, and it is NOT "pick blind from stats." It is: capability-filter (hard requirements, no judgment) → within a single tagged-comparable benchmark group → domination filter (Pareto-drop dominated arms, which auto-retires stale models with zero hand-list) → quota filter (drop exhausted-window arms; treat quota vs. dollars as two ledgers with an explicit shadow-price knob, not a derived optimum) → task-shaped human prior wherever the stat is missing, untagged, or low-confidence. This is sound, buildable, and — per the identity-blind report — is close to what waspflow's own `minnows/model-catalog` + `model-choice-policy` already encode (`comparability_group` tagging, "never invent rates or scores," explicit operating points).

Two things are NOT worth building: (1) a learned router (RouteLLM-style, Avengers-Pro-style) calibrated to your own small pool — the routing-plateau finding says sophisticated routers cluster within ~1pp of a trivial threshold/kNN baseline, and the two genuinely reusable open options are either dormant (RouteLLM, no commits since Aug 2024) or hide a real setup cost (Avengers-Pro needs ~14,600 paid calibration calls just to build the lookup table); (2) the NVIDIA prompt-complexity classifier as a "frontier" signal — it is a data-curation/dataset-bucketing tool whose complexity score was never calibrated to which model wins a query, and even NVIDIA's own production router doesn't load it.

The two most important disagreements/tensions worth flagging explicitly for the design doc:
- Task-type (`task_family`) vs. difficulty as the primary axis: the routing-products literature says difficulty is the dominant, superior axis and type is a coarse proxy; the agent-frameworks literature says role/type-bound model tiers ARE the dominant deployed pattern (Claude Code, OpenAI Agents SDK, CrewAI all bind model to sub-agent role, not to a runtime difficulty estimate). Reading: type is a legitimate ROLE/DEFAULT-TIER hint (that's how agents actually ship), but it is the weakest of the three axes as a quality signal — difficulty and stakes/reversibility should modulate it, not be replaced by it.
- "Latest frontier always wins" vs. effort/tiny-model niches: true for auto-excluding old BIG models (Pareto-dominated), but false as a universal rule because effort is a load-bearing, non-monotonic axis (treat `(model, effort)` as the real arm, not `model` alone) and small old models can remain cost-optimal for high-volume/low-stakes work.

The comparability-catastrophe finding (10-20+ point swings from harness/scaffold alone, same model) is probably the single highest-leverage constraint for the design doc: any stats-driven filter that cross-ranks numbers from different harnesses/vendors/source-types without a `comparability_group`-style tag is unsound by construction, independent of how good the selection algorithm on top of it is.
