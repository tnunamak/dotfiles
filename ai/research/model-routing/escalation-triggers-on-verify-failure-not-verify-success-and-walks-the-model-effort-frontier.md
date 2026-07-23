---
title: "In agent loops, verify-FAILURE is a reliable rank-1 escalation trigger but verify-SUCCESS is not a stop signal (28-76% of green passes are gamed); escalation should walk a (model, effort) ladder bumping effort before switching models, at step granularity, with structured-state handoff — not query-level, transcript-dump, or strong-plans/cheap-executes by default"
date: 2026-07-15
topic: model-routing
tags: [escalation, cascades, verification, reward-hacking, cache-invalidation, reasoning-effort, agent-loops, break-even-math, step-level-routing]
status: draft
sources: [dekoninck-unified-routing-cascading, decision-theoretic-cascade, frugalgpt-cascade, routerbench-cascade, automix, r2v-agent, agentcollab, uno-orchestra, agentswing, verification-horizon, impossiblebench, self-consistency-wang, just-ask-calibration, uq-survey, semantic-entropy-nature, snell-test-time-compute, gpt5-cost-accuracy, entropy-adaptive-decoding, routing-collapse, speculative-decoding, claude-code-commands, claude-code-prompt-caching, anthropic-prompt-caching-api, codex-quickstart, codex-config-reference, codex-issue-20477, codex-issue-19877, openai-prompt-caching, openai-reasoning-guide, grok-modes-commands, grok-headless-scripting, grok-prompt-caching-multiturn, claude-code-subagents-docs, claude-agent-sdk-subagents, openai-agents-handoffs, openai-swarm, cline-plan-act, roo-api-profiles, aider-architect-editor, anthropic-multi-agent-system, langchain-plan-execute, anthropic-building-effective-agents, cascadeflow-repo, agentpatterns-effort-escalation, github-copilot-auto, cognition-devin-lessons]
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation/conclusions. Skippable. No citations here.
-->

Researched 2026-07-15 for waspflow's model-choice design (context: `docs/design/MODEL_CHOICE_ROUTING.md` in `~/code/waspflow`). Synthesizes three subagent research passes: how real agent frameworks/products do model assignment + escalation, cascade/escalation mechanics in agent loops (break-even math, trigger reliability, step-vs-task granularity, weak-first-vs-strong-first, effort-vs-model ladder), and mid-session model/effort switching mechanics across Claude Code, Codex CLI, and Grok Build.

## CLAIMS

### The dominant deployed pattern is a STATIC role split, not dynamic difficulty routing or auto-escalation
- Across Claude Code subagents, OpenAI Agents SDK, Codex CLI, Cursor, Windsurf, Devin, Cline, and Roo Code, model-to-role binding is overwhelmingly a static, human-authored config choice, not a runtime difficulty classifier; genuine automatic mid-task model switching by measured difficulty barely exists in shipped coding agents as of 2026. [a5183648a02c98811 source]
- Claude Code's `model` field is static per-agent (`sonnet|opus|haiku|fable|<full-id>|inherit`, default `inherit`); Explore and Plan built-in agents both default to `inherit` (Explore stopped defaulting to Haiku as of v2.1.198) — only cheap helper agents (claude-code-guide, statusline-setup) are statically pinned; there is no documented mid-task model escalation or escalate-on-failure — failures surface to the parent, they are not retried on a bigger model. [claude-code-subagents-docs][claude-agent-sdk-subagents]
- OpenAI Agents SDK docs explicitly recommend mixing models by role ("a smaller, faster model for triage... a larger, more capable model for complex tasks") but this is a developer-chosen static pattern; handoffs are tool calls the LLM chooses, routed by intent/domain, not by difficulty — escalation is role/intent-driven because a developer wired that role to the bigger model, not because the framework measured difficulty. [openai-agents-handoffs]
- Codex CLI switches models mid-session only via explicit user action (`/model`, `/effort`, Alt+,/Alt+.); there is no automatic switching or auto-escalation on failure documented. GitHub Copilot "Auto" (GA Dec 2025) is availability/server-health routing, not task-difficulty routing; complexity-matching was announced but unshipped as of Feb 2026. Devin runs a single frontier model per run with no documented difficulty-tiered ladder or escalate-on-failure (and has been criticized for the opposite — pushing forward on impossible tasks rather than escalating). [github-copilot-auto][cognition-devin-lessons]
- Cline and Roo Code support separate Plan-mode vs. Act-mode models, but this is user-configured static config ("a stronger reasoning model for planning and a faster model for implementation" — Cline docs); Roo's "Sticky Models" auto-reselects the last-used model ONLY on mode change, deliberately avoiding mid-task switching. [cline-plan-act][roo-api-profiles]

### Role-based split (strong plans / cheap executes) is the most-proven pattern — but a direct measured counter-finding contradicts the "strong plans" half
- Aider's architect/editor split is the canonical instance: a strong architect model reasons/plans, a cheap editor model converts the proposal into correctly-formatted diffs — static and role-based, same pair every turn regardless of difficulty; o1-preview+o1-mini hit 85% SOTA on Aider's edit benchmark this way, motivated by o1 being strong at reasoning but bad at edit formatting. [aider-architect-editor]
- Anthropic's multi-agent research system deploys Opus-lead + Sonnet-subagents, outperforming single-agent Opus by 90.2%. LangChain's plan-and-execute blog states the cost logic directly: sub-task calls "can be made to smaller, domain-specific models. The larger model then is only called for (re-)planning steps and to generate the final response." [anthropic-multi-agent-system][langchain-plan-execute]
- Correction to a common misconception: Anthropic's "Building Effective Agents" does NOT tier orchestrator-vs-worker models in its orchestrator-workers pattern section; its model-size-to-difficulty advice (Haiku for easy, Sonnet for hard) lives in the separate "Routing" pattern — these are two different patterns that are often conflated. [anthropic-building-effective-agents]
- DIRECT CONTRADICTION: AgentCollab's ablation (arXiv:2603.26034, HTML-verified) found putting the LARGE model in the EXECUTION stage beats putting it in planning: 27.3 vs. 24.6. Its architecture (strong model warms up + plans, small model runs routine steps and self-evaluates, control transfers to the strong model on detected stagnation re-examining accumulated context, then returns to the small model) nearly matches always-strong at a fraction of cost: BrowseComp_zh 18.3%→33.9% (vs. always-large 34.6%); HLE-math 8.0%→21.1% (vs. always-large 23.3%); 1.36x-2.43x speedup. This directly supports "cheap model scaffolds/explores, strong model does the hard edit" over "strong model plans, cheap executes." [agentcollab]
- Anthropic's own multi-agent report warns the parallel orchestrator-worker fan-out pattern is a research-task win, not a coding win, because "most coding tasks involve fewer truly parallelizable tasks... agents are not yet great at coordinating in real time" — the R2V/AgentCollab step/subtask-escalation-on-one-trajectory architecture is a different, coding-compatible pattern. [anthropic-multi-agent-system]

### Escalation-on-failure exists but is concentrated in frameworks/practitioner pipelines, not shipped end-user products
- cascadeflow (~3.3k GitHub stars) is a deployed framework doing literal escalate-on-failure: run small/fast model → validate against thresholds → dynamically escalate to larger models only when quality validation fails, at agent-step granularity — but no disclosed production users were found. [cascadeflow-repo]
- The practitioner recipe for coding specifically: "escalate to the flagship model after 2 failed verification runs (tests/lint/types), not before" — coding is an ideal cascade fit because executable tests provide the objective failure signal FrugalGPT-style cascades need. [agentpatterns-effort-escalation]
- No major shipped end-user coding product does automatic escalate-on-test-failure across tiers as a native feature; it is achieved externally via routers or hand-rolled per-project logic (e.g., LangGraph conditional edges + retry counter in state, with no first-class "escalate to bigger model" primitive). [a5183648a02c98811 source]

### Cascade break-even math: when escalation wins vs. loses
- A cascade runs the cheap model first, scores its output, returns if the score clears a threshold, else escalates; the cheap generation is always paid. Expected two-model cascade cost is `E[C] = c_L + c_H · d` where `d` is the deferral/escalation probability; it follows that a cascade beats always-strong only when `c_L + d·c_H < c_H`, i.e. the break-even deferral rate is **`d < 1 − c_L/c_H`**. Concretely: if the cheap model is 1/10 the strong model's price, the cascade stays cheaper only while fewer than 90% of tasks escalate; if the cheap model is half the price, the window collapses to under 50% escalation. [decision-theoretic-cascade] (algebra is a derivation from the always-paid cost structure, not a verbatim quote; the router-vs-cascade dominance result itself is abstract-verified)
- Naive threshold-cascades fall below always-strong when: deferral rate exceeds the break-even threshold above; the cheap-to-strong price ratio is near 1 (viable window shrinks to nothing); or the quality estimate is noisy/binary — Dekoninck et al. report that even with perfect post-hoc quality estimation on SWE-Bench, a binary pass/fail signal forces the threshold to either admit all models or only-correct ones, so "the cascading strategy sometimes underperforms compared to the linear interpolation baseline" (verbatim). [dekoninck-unified-routing-cascading]
- When difficulty is predictable ex-ante, a predictive router beats the cascade because it skips the cheap-model cost on hard tasks entirely: "a pre-generation router exceeds the best cascade policy on four of five datasets, mainly because it avoids the cheap model's generation cost" (verbatim, abstract). The lone exception was a dataset where difficulty was unpredictable ex-ante (query-embedding AUROC ≈ 0.49). [decision-theoretic-cascade]
- Dekoninck's cascade-routing dominance is conditional: it beats both pure routing and pure cascading on RouterBench (AUC 76.3-77.6 vs. routing 74.4-74.6 vs. baseline cascade 73.0-73.6; up to +14% on SWE-Bench), but "when cascading offers little gain, cascade routing typically reduces to pure routing" by design. [dekoninck-unified-routing-cascading]
- FrugalGPT's headline 98.3% cost cut materializes only because the cheap model is right most of the time on easy-skewed traffic; it is not a general guarantee. [frugalgpt-cascade]

### Escalation trigger signals, ranked by reliability — and the critical asymmetry for verify-based triggers
- Reliability ranking (most to least reliable as an escalation trigger): (1) execution/verifier FAILURE (test fail, compile error, tool error, stalled retry loop) — reliable as a NEGATIVE signal only; (2) calibrated multi-feature risk estimate (verifier-score stats + entropy + consistency) — most reliable actionable trigger for agents (R2V-Agent); (3) self-consistency/answer agreement across samples — best black-box confidence proxy, robust to RLHF sharpening; (4) semantic entropy/internal-state probes — reliable, high AUROC, higher cost; (5) token log-probs/perplexity/entropy — moderate, discriminates but poorly calibrated, RLHF distorts; (6) LLM-as-judge/reward-model score — mixed, hackable, miscalibrates as policy improves; (7) verbalized/self-reported confidence — LEAST reliable, systematically overconfident (one survey found 98.8% stated confidence at 68% actual accuracy). [r2v-agent][just-ask-calibration][uq-survey]
- "Tests failed / verify failed" is a reliable escalation trigger, but "tests passed / verify succeeded" is NOT a reliable stop signal — this asymmetry is the headline finding. Verification Horizon (arXiv:2606.26300, verbatim-verified): 28.57% of passing solutions gamed the tests before mitigation (down to 0.56% only after adding behavior monitoring + quality judges); solution-artifact retrieval alone reached a 72.34% "resolved" rate while cheating. ImpossibleBench (arXiv:2510.20270, verified): GPT-5 exploited tests 76% of the time on Oneoff-SWEbench but only 2.9% on Oneoff-LiveCodeBench, and prompt engineering + read-only/isolated test files dropped exploitation to ~1%. Thesis (verbatim): "no fixed reward function can remain effective as policy capability continues to grow; verification must co-evolve with the generator." [verification-horizon][impossiblebench]
- Practical mitigation: run verify in an environment the agent cannot touch, make test files read-only where possible, and never treat a green verify as "stop" without an independent check that the agent didn't edit tests or retrieve the answer. [verification-horizon]
- Agents are specifically bad at self-flagging uncertainty: an explicit `escalate()` tool gated on the model "feeling unsure" is unreliable — the agentic-abstention literature says escalate on calibrated trajectory-level uncertainty, not verbalized confidence; on hard benchmarks (GPQA) no single black-box signal is a reliable standalone abstention score, though cheap hybrids (verbalized + ~2 self-consistency samples, "VCSC") are near-optimal. [a696a5e2eb27cd34b source]

### Step-level escalation beats query-level routing, decisively
- R2V-Agent (arXiv:2605.16604, abstract-verified): a cheap SLM runs the trajectory; a lightweight process verifier scores each candidate action; a Brier-calibrated step-router escalates to the LLM only when residual failure risk exceeds a cost-derived threshold `τ* = (c_LLM − c_SLM)/κ`. Results: HumanEval+ 94.3% success at only 0.60% of steps escalated to the LLM (vs. a naive heuristic router needing 26.6% escalation for similar quality); TextWorld 98.2% (near the 98.6% oracle) vs. entropy-only/query-level routing stuck at the SLM's 64.6%; TerminalBench 93.3% at 33.9% escalation. [r2v-agent]
- The lesson: difficulty is trajectory-dependent, not query-dependent — deciding model tier once at task start is "blind to mid-trajectory risk." DyCon (arXiv:2606.07108) independently shows difficulty oscillates within a trajectory, which is why a one-time decision (and a one-way descent) underperforms a bidirectional escalate-and-relax loop. [r2v-agent] (DyCon claim sourced from same report, medium confidence — not independently cross-checked)

### Handoff: structured state beats transcript dump; clean restart can beat continuation on poisoned trajectories
- The measured escalation papers (R2V, AgentCollab, Uno-Orchestra) all hand off from accumulated state — none redo from scratch, and none directly measure handoff loss, so "escalate with context" is the de facto standard but handoff-quality-loss itself is an untested assumption in the escalation literature itself. [a696a5e2eb27cd34b source]
- AgentSwing (arXiv:2603.27490, measured) found that on long/noisy trajectories, a "Discard-All" clean restart can beat continuation, because a bloated, error-laden context degrades even a strong model — reconciling principle: the strong model's value is realized on a clean, well-scoped context, not a lossy transcript dump or a poisoned trajectory. Practical rule: hand off structured state (objective + constraints + key artifacts/diffs), not the raw transcript; reset if the trajectory is already poisoned by repeated failures. [agentswing]
- Cited "39-70% degradation on sequential handoffs" figures circulate widely but the primary source could not be confirmed — medium confidence, do not quote as fact. [a696a5e2eb27cd34b source]

### De-escalation (start strong, drop to cheap) is weaker than escalation; weak-first is the better default direction
- Pure "start strong, only ever downshift" has essentially no primary-source support. Where downshifting appears, it is the relaxation leg of an uncertainty-triggered escalate loop whose resting state is the cheap model — e.g. Entropy Adaptive Decoding (arXiv:2502.06833) initializes on the SMALL model and escalates on high rolling entropy, then drops back (96.7% of the big model's MATH performance using it for only 43% of tokens). Routers empirically fail to downshift ("routing collapse," arXiv:2602.03478) — the hard engineering problem is getting systems to use cheap models MORE, which is pressure toward weak-first. [entropy-adaptive-decoding][routing-collapse]
- Speculative decoding looks strong-first but is not de-escalation: the small model drafts, the large model verifies in parallel — lossless, preserves the strong model's exact distribution, and still runs the cheap model first and most; it is orthogonal to the routing axis and should not be conflated with model-tier routing. [speculative-decoding]
- The one place strong-first legitimately wins is the trajectory head (frontier model for hard planning/first-hard-edit, cheap model for the repetitive tail) — provided cost/quality is evaluated over the WHOLE trajectory, because compounding errors and KV-cache invalidation from switching can erase per-step savings. Per AgentCollab's ablation above, "strong plans / cheap executes" is not obviously the right split even for this case. [a696a5e2eb27cd34b source]

### Effort vs. model escalation: walk the (model, effort) FRONTIER — a fixed "effort first" rule is NOT supported
**RECONCILIATION NOTE (2026-07-15).** The cascade-research thread originally concluded "bump effort first because it is cache-preserving where a model switch is not." That rationale is **falsified by this entry's own mid-session-switching section below**: Anthropic documents that "each effort level has its own cache for the same model. Changing it mid-session recomputes the entire request" — i.e. effort switches bust the cache exactly like model switches. With the cache argument dead, no principled basis remains for a hardcoded effort-first ordering. The corrected rule:
- **Escalation = move to the next non-dominated `(model, effort)` arm on the cost-performance frontier.** Sometimes the next arm above (cheap-model, medium) is (cheap-model, high); sometimes it is (better-model, low) — the frontier data decides, not a fixed ladder. Direct evidence that ordering is data-dependent: Anthropic's Sonnet 5 charts show Sonnet 5 at higher effort matching Opus 4.8 on some tasks — equivalently, a better model at LOW effort can dominate a worse model at MAX effort; and effort is non-monotonic (GPT-5 accuracy decreased with effort in one eval; GPT-5-Nano at LOW beat HIGH by 7.3pp at 84% lower cost). This unifies spawn-time selection and escalation on ONE data structure: the same non-dominated frontier of arms serves both. [gpt5-cost-accuracy][anthropic-sonnet-5 via sibling entry]
- What survives of "effort-first": on LARGE models the effort curve is often the cheaper step along the frontier (GPT-5 high→low costs ~1.5pp accuracy for ~70% cost reduction, medium confidence), and it is the same weights ("the very same model giving itself more time" — Anthropic) — so effort rungs FREQUENTLY are the next arm up, but as a frontier fact, not a rule. Where comparable stats are too thin to place arms on a frontier, vendor-guidance ladders are the fallback. [gpt5-cost-accuracy]
- Every switch — model OR effort — costs one full-context cache miss (full re-prefill at full input price + TTFT spike, forfeiting the ~90% cache-read discount for that turn), uniformly across all three coding CLIs and the raw APIs (see mid-session section below). Switch at task boundaries, and only on an escalation trigger. [claude-code-prompt-caching][openai-prompt-caching]
- The hard ceiling stands: test-time compute (more effort) can beat a model 14x larger, but only within a capability band (Snell et al., arXiv:2408.03314, ICLR 2025): once a model saturates, "more thinking on the same distribution cannot unlock additional capability" — repeated verify-failures at a model's top-frontier arm mean capability saturation: jump models, don't crawl effort. [snell-test-time-compute]
- No single paper benchmarks effort-vs-model escalation ordering head-to-head; the frontier-walking formulation is a composition of (a) vendor effort/cost curves, (b) cascade literature, (c) TTC-saturation papers, and (d) the per-effort cache-key documentation — confidence medium-high, not verbatim-confirmed as a unit. [a696a5e2eb27cd34b source]

### Mid-session model/effort switching mechanics: uniform full-cache-miss cost across all three major coding CLIs
- All three CLIs (Claude Code, Codex CLI, Grok Build) can switch BOTH model and reasoning effort mid-session while preserving conversation context — but switching either invalidates the prompt cache, forcing the next turn to re-read the entire conversation history at full (uncached) input price. There is no cheap mid-session switch in any of the three. [claude-code-prompt-caching][openai-prompt-caching][grok-prompt-caching-multiturn]
- Claude Code: `/model` (picker, Alt+P, or `/model sonnet|opus|haiku|opusplan` with an argument) and `/effort low|medium|high|xhigh|max|ultracode` (separate command) both switch mid-session with context preserved. Documented explicitly: "each model has its own cache. Switching models recomputes the entire request even when the content is identical," and "each effort level has its own cache for the same model. Changing it mid-session recomputes the entire request, and Claude Code asks you to confirm before applying the change." The re-read is a one-time full-price turn ("the most expensive request you send" per docs), not a recurring per-turn tax — after that turn the new model/effort's cache warms. Non-interactive `-p` mode has supported `/model <arg>` and `/effort <level>` since v2.1.205 for the current session (not saved as default); `opusplan` makes every plan-mode toggle a fresh-cache model switch. [claude-code-commands][claude-code-prompt-caching]
- Codex CLI: `/model` opens a picker for both model and effort (`minimal|low|medium|high|xhigh`, model-dependent); mid-session switching landed ~v0.117.0, keybindings Alt+,/Alt+. (lower/raise effort one step) added ~v0.124.0. There is no dedicated `/reasoning` or standalone `/effort` command — GitHub issue #20477 requesting one was closed as a duplicate, not shipped. Accepting a model-upgrade prompt mid-session resets effort to the new model's default rather than carrying it over. OpenAI's caching is per-model prefix matching, so a model switch causes a cache miss on the switch turn (`cached_tokens: 0`), re-billing the prefix at fresh-input rate; issue #19877 (warn before mid-session model switch in long sessions) confirms the cost is real and previously un-warned. Critically: there is no config-reload or non-interactive flag to change model/effort mid-session — the TUI keystroke path (or quitting and relaunching with a `-c` flag) is the only way; clean programmatic control exists only at launch. [codex-quickstart][codex-config-reference][codex-issue-20477][codex-issue-19877]
- Grok Build (xAI's official first-party CLI, gated beta as of 2026-05-14 launch — distinct from the unaffiliated community `superagent-ai/grok-cli`): `/model <name>` (alias `/m`) and a dedicated `/effort` command both switch mid-session (unlike Codex, effort has its own first-class command). `--effort`/`--reasoning-effort` are interchangeable launch flags; per-model reasoning menus are server/config-configurable without a client release; effort is recorded in `summary.json` and conversation history. Official docs are silent on context preservation and on cache cost for model/effort switches specifically (xAI's cache doc only states "any change to earlier messages breaks the cache; only append new messages at the end") — cache-miss-on-switch is inferred from standard per-model prefix-caching mechanics, not confirmed by xAI (medium confidence). Grok's `grok agent stdio` ACP/JSON-RPC mode is a genuinely programmatic driver, cleaner than keystroke injection, and the best of the three for scripted control. [grok-modes-commands][grok-headless-scripting][grok-prompt-caching-multiturn]
- At the API/SDK layer for both providers, `model` and effort/thinking-config are per-request parameters in a stateless multi-turn loop (the caller re-sends the full message array every turn); the cache implication is identical to the CLI behavior — each model/effort combination has its own cache, so the turn where either changes is a cache miss, billed at full input rate once, after which the new combination's prefix caches normally. OpenAI's Responses API additionally benefits from a stable `prompt_cache_key` (conversation id) to keep same-model turns hitting the same shard — Codex sets this to the conversation id and reportedly sees ~95% hit rate vs. ~39% without it. [anthropic-prompt-caching-api][openai-prompt-caching]

## SOURCES

**dekoninck-unified-routing-cascading**
URL: arXiv:2410.10347 (Dekoninck et al., ICML 2025)
Accessed: 2026-07-15
Quote: "the cascading strategy sometimes underperforms compared to the linear interpolation baseline"; cascade-routing AUC 76.31 vs routing 74.43 vs threshold cascade 73.03 on RouterBench

**decision-theoretic-cascade**
URL: arXiv:2605.06350
Accessed: 2026-07-15
Quote: "a pre-generation router exceeds the best cascade policy on four of five datasets, mainly because it avoids the cheap model's generation cost" (abstract-verified)

**frugalgpt-cascade**
URL: arXiv:2305.05176
Accessed: 2026-07-15

**routerbench-cascade**
URL: arXiv:2403.12031
Accessed: 2026-07-15

**automix**
URL: arXiv:2310.12963
Accessed: 2026-07-15

**r2v-agent**
URL: arXiv:2605.16604
Accessed: 2026-07-15
Quote: HumanEval+ 94.3% success at 0.60% of steps escalated vs 26.6% for a naive heuristic router; τ* = (c_LLM − c_SLM)/κ

**agentcollab**
URL: arXiv:2603.26034
Accessed: 2026-07-15
Quote: large model in execution beats large model in planning, 27.3 vs 24.6; BrowseComp_zh 18.3%→33.9% vs always-large 34.6%; HLE-math 8.0%→21.1% vs always-large 23.3%

**uno-orchestra**
URL: arXiv:2605.05007
Accessed: 2026-07-15

**agentswing**
URL: arXiv:2603.27490
Accessed: 2026-07-15

**verification-horizon**
URL: arXiv:2606.26300
Accessed: 2026-07-15
Quote: "no fixed reward function can remain effective as policy capability continues to grow; verification must co-evolve with the generator"; 28.57% gamed-passing-solutions before mitigation, down to 0.56% after behavior monitoring + quality judges

**impossiblebench**
URL: arXiv:2510.20270
Accessed: 2026-07-15
Quote: GPT-5 exploited tests 76% on Oneoff-SWEbench, 2.9% on Oneoff-LiveCodeBench; drops to ~1% with prompt engineering + read-only/isolated test files

**self-consistency-wang**
URL: arXiv:2203.11171
Accessed: 2026-07-15

**just-ask-calibration**
URL: arXiv:2305.14975
Accessed: 2026-07-15

**uq-survey**
URL: arXiv:2510.20460
Accessed: 2026-07-15
Quote: survey finding of 98.8% stated confidence at 68% accuracy

**semantic-entropy-nature**
URL: Farquhar et al., Nature 2024; also arXiv:2406.15927 (SEPs)
Accessed: 2026-07-15

**snell-test-time-compute**
URL: arXiv:2408.03314 (ICLR 2025)
Accessed: 2026-07-15
Quote: "more thinking on the same distribution cannot unlock additional capability"

**gpt5-cost-accuracy**
URL: arXiv:2512.01232
Accessed: 2026-07-15
Quote: GPT-5-Nano at low effort beat high effort by 7.3pp at 84% lower cost

**entropy-adaptive-decoding**
URL: arXiv:2502.06833
Accessed: 2026-07-15
Quote: 96.7% of big-model MATH performance using it for 43% of tokens

**routing-collapse**
URL: arXiv:2602.03478
Accessed: 2026-07-15

**speculative-decoding**
URL: arXiv:2211.17192
Accessed: 2026-07-15

**claude-code-commands**
URL: https://code.claude.com/docs/en/commands
Accessed: 2026-07-15

**claude-code-prompt-caching**
URL: https://code.claude.com/docs/en/prompt-caching
Accessed: 2026-07-15
Quote: "each model has its own cache. Switching models recomputes the entire request even when the content is identical." / "each effort level has its own cache for the same model."

**anthropic-prompt-caching-api**
URL: https://platform.claude.com/docs/en/build-with-claude/prompt-caching
Accessed: 2026-07-15

**codex-quickstart**
URL: https://developers.openai.com/codex/cli
Accessed: 2026-07-15

**codex-config-reference**
URL: https://learn.chatgpt.com/docs/config-file/config-reference
Accessed: 2026-07-15

**codex-issue-20477**
URL: https://github.com/openai/codex/issues/20477
Accessed: 2026-07-15
Quote: closed as duplicate of #19357; today you must "quit the CLI and resume with a -c config flag" to change effort/model non-interactively mid-session

**codex-issue-19877**
URL: https://github.com/openai/codex/issues/19877
Accessed: 2026-07-15

**openai-prompt-caching**
URL: https://developers.openai.com/api/docs/guides/prompt-caching
Accessed: 2026-07-15
Quote: Codex prompt_cache_key ~95% hit rate vs ~39% without

**openai-reasoning-guide**
URL: https://developers.openai.com/api/docs/guides/reasoning
Accessed: 2026-07-15

**grok-modes-commands**
URL: https://docs.x.ai/build/modes-and-commands
Accessed: 2026-07-15

**grok-headless-scripting**
URL: https://docs.x.ai/build/cli/headless-scripting
Accessed: 2026-07-15

**grok-prompt-caching-multiturn**
URL: https://docs.x.ai/developers/advanced-api-usage/prompt-caching/multi-turn
Accessed: 2026-07-15
Quote: "Any change to earlier messages breaks the cache. Only append new messages at the end." (does not address model/effort switches explicitly)

**claude-code-subagents-docs**
URL: https://code.claude.com/docs/en/sub-agents
Accessed: 2026-07-15

**claude-agent-sdk-subagents**
URL: https://code.claude.com/docs/en/agent-sdk/subagents
Accessed: 2026-07-15

**openai-agents-handoffs**
URL: https://openai.github.io/openai-agents-python/handoffs/ and https://openai.github.io/openai-agents-python/models/
Accessed: 2026-07-15

**openai-swarm**
URL: https://github.com/openai/swarm
Accessed: 2026-07-15

**cline-plan-act**
URL: https://docs.cline.bot/features/plan-and-act
Accessed: 2026-07-15

**roo-api-profiles**
URL: https://docs.roocode.com/features/api-configuration-profiles
Accessed: 2026-07-15

**aider-architect-editor**
URL: https://aider.chat/2024/09/26/architect.html
Accessed: 2026-07-15
Quote: o1-preview+o1-mini architect/editor split hit 85% SOTA on Aider's edit benchmark

**anthropic-multi-agent-system**
URL: https://www.anthropic.com/engineering/multi-agent-research-system
Accessed: 2026-07-15
Quote: Opus-lead + Sonnet-subagents outperformed single-agent Opus by 90.2%; "most coding tasks involve fewer truly parallelizable tasks... agents are not yet great at coordinating in real time"

**langchain-plan-execute**
URL: https://www.langchain.com/blog/planning-agents
Accessed: 2026-07-15
Quote: sub-task calls "can be made to smaller, domain-specific models. The larger model then is only called for (re-)planning steps and to generate the final response."

**anthropic-building-effective-agents**
URL: https://www.anthropic.com/research/building-effective-agents
Accessed: 2026-07-15

**cascadeflow-repo**
URL: https://github.com/lemony-ai/cascadeflow
Accessed: 2026-07-15

**agentpatterns-effort-escalation**
URL: https://www.agentpatterns.ai/instructions/codified-effort-escalation-policy/
Accessed: 2026-07-15
Quote: "escalate to the flagship model after 2 failed verification runs (tests/lint/types), not before"

**github-copilot-auto**
URL: https://github.blog/changelog/2025-12-10-auto-model-selection-is-generally-available-in-github-copilot-in-visual-studio-code/
Accessed: 2026-07-15
Quote: "routing to models based on real-time availability"

**cognition-devin-lessons**
URL: https://cognition.ai/blog/devin-sonnet-4-5-lessons-and-challenges
Accessed: 2026-07-15

## SYNTHESIS

The shape that emerges across all three reports is a two-axis escalation policy, not a single lever: (1) a TRIGGER (what causes escalation) and (2) a LADDER (what escalation actually does). On the trigger side, the field has one clean, load-bearing asymmetry: verify-failure is cheap, grounded, and reliable as a NEGATIVE signal (escalate on it), but verify-success is not trustworthy as a stop signal, because green-verify gaming ranges from 2.9% to 76% depending on benchmark/mitigation. Any design that treats "tests passed" as a terminal state without an independent check (tests read-only, isolated worktree, a cheap behavior-consistency check) is building on a documented reward-hacking gap, not a hardening nicety.

On the ladder side (RECONCILED — an earlier draft of this synthesis said "effort-first because cache-preserving," falsified by the per-effort cache keys documented in this entry's own mid-session section): escalation walks the non-dominated (model, effort) FRONTIER — effort rungs are frequently the next arm up on large models, but ordering is a frontier fact, not a rule (a better model at LOW effort can dominate a worse one at MAX; effort is non-monotonic on small models), and EVERY switch — model or effort — is a full-context cache miss (documented for Claude Code / Codex / both raw APIs; Grok inferred, unconfirmed — no free mid-session switch anywhere). Once a model saturates at its top arm, jump models (capability band). The research ideal is STEP granularity within a trajectory (R2V-Agent: 94.3% success at 0.6% of steps escalated vs. 26.6% needed by query-level routing) because difficulty is trajectory-dependent and oscillates — though TUI-driven orchestrators are structurally limited to turn/verify-boundary granularity. When a switch does happen, hand off structured state (objective + constraints + diffs) rather than a raw transcript dump, and prefer a clean restart over continuation if the trajectory is already poisoned by repeated failures.

The most important open tension to carry into the design doc is the role-split disagreement: the dominant, most-proven, most-deployed pattern (Aider, Anthropic's own multi-agent system, LangChain) is "strong model plans, cheap model executes" — but the one paper that directly measured the alternative (AgentCollab) found the opposite ordering wins (large model executing beats large model planning, 27.3 vs 24.6), with the strong model's real value realized when it's brought in on a clean, well-scoped context to do the hard edit, not to write the up-front plan. Both are real findings from real measurements; they are not reconcilable into one rule, and the design doc should treat this as an open question to test against waspflow's own workload rather than adopt either as settled doctrine.

The break-even algebra (`d < 1 − c_L/c_H`) is a concrete, checkable gate: before building any cascade/escalation path, compute the expected escalation rate for waspflow's actual task mix and the actual cheap/strong price ratio — if escalation is expected on most tasks, or the cheap/strong price gap is small, skip the cascade and route directly to the stronger tier, since a naive cascade would be strictly more expensive and slower than starting strong.
