---
title: "RTK and Headroom net-save ~20-25% tokens on real coding tasks (no accuracy cost) but go net-negative on tiny tasks; their self-reported savings meters are inflated"
date: 2026-06-26
topic: agentic-context-design
tags: [rtk, headroom, token-savings, compression, benchmarks, prompt-caching, codex]
status: settled
sources: [local-ab-tokensmash, taco-paper, ai-agents-that-matter, mroczek-rtk-critique, llmlingua2-agent-failure, princeton-pareto, anthropic-caching, berkeley-prompt-compression]
---

## CLAIMS

- The user's OWN A/B runs (tokensmash, 2026-06-11, N=1/cell, 74 task runs): on real/larger codebases RTK netted mean **-24.5% total tokens** (6/6 saved, zero correctness regressions); Headroom **-20.5%** (6/7 saved). [local-ab-tokensmash]
- On tiny 1-file fixture tasks both go NET-NEGATIVE: RTK mean **+32.5%** (one run +81%), Headroom **+11.5%** — the per-command/instruction overhead outweighs savings when the task is trivial. [local-ab-tokensmash]
- RTK's "+81%" tiny-task blowup has a confirmed root cause: on isolated Codex homes Codex tries `rtk --ultra-compact -- cat RTK.md` to bootstrap, gets nothing useful, and falls back to running every command twice (18 tool calls vs 8 baseline). It's a prompt/bootstrap-confusion bug, not a filtering failure — fix by not encouraging Codex to probe for the rtk binary in AGENTS.md. [local-ab-tokensmash]
- RTK's self-reported "99.3% savings" (`rtk gain`) measures bytes stripped from Bash stdout, which is ~1% of total session tokens — NOT API cost or task cost. The real ~20-25% comes from turn-count/output reduction across the session. Independent reviewers call the headline number "deeply misleading." [local-ab-tokensmash, mroczek-rtk-critique]
- Independent peer-reviewed evidence agrees with the shape: TACO (arXiv:2604.19572) measured intelligent terminal-output compression on 6 coding benchmarks at net **-2.7% to -27%** tokens (auxiliary compression cost <2%) with accuracy FLAT or IMPROVED — because it strips low-information-density execution traces, not signal. [taco-paper]
- The savings only hold for SIGNAL-PRESERVING compression. Dumb truncation is untested for accuracy; and LLMLingua-2 above ~30% token removal caused COMPLETE task failure on agent tasks via format destruction (tool-call JSON / diff syntax corrupted) — coding agents are format-sensitive in a way QA tasks aren't. [llmlingua2-agent-failure, berkeley-prompt-compression]
- Native prompt caching already cuts the DOLLAR cost of repeated context ~90%, making external compression redundant for cost on static prefixes; the proxies' remaining value is CONTEXT-WINDOW CAPACITY on long sessions (the 200K limit), not price. A proxy that rewrites the prefix can BREAK caching and raise dollar cost even while cutting token count. [anthropic-caching]
- The correct metric is cost-per-SUCCESSFUL-task from the API invoice (Pareto: accuracy vs cost), not any proxy self-meter; no published study has run this A/B for RTK or Headroom. [princeton-pareto, ai-agents-that-matter]
- RTK only intercepts the Bash tool; Claude Code's built-in Read/Grep/Glob bypass it, so it doesn't touch the heaviest token drivers (file reads, system prompt, reasoning). [mroczek-rtk-critique]

## SOURCES

**local-ab-tokensmash**
URL: local — ~/.local/state/tokensmash/ab-runs/ (19 dirs, 74 runs, 2026-06-11)
Accessed: 2026-06-26
Quote: Real codebases RTK -24.5% / Headroom -20.5%, no regressions; tiny tasks RTK +32.5% / Headroom +11.5%. RTK tiny blowup = Codex double-running commands after a failed `rtk ... cat RTK.md` bootstrap probe. N=1/cell; no turn-count surfaced as a first-class metric.

**taco-paper**
URL: https://arxiv.org/abs/2604.19572
Accessed: 2026-06-26
Quote: Terminal-observation compression on SWE-Bench Lite/CompileBench/DevEval/TerminalBench: net -2.7% to -27% tokens, aux cost <2%, accuracy flat-to-+2.95pp.

**ai-agents-that-matter**
URL: https://arxiv.org/abs/2407.01502
Accessed: 2026-06-26
Quote: Evaluate agents on the accuracy-vs-cost Pareto frontier; joint optimization cut variable cost 41-53% with maintained accuracy. Cost-per-success is the metric.

**mroczek-rtk-critique**
URL: https://mroczek.dev/articles/the-token-compression-illusion-why-im-skeptical-of-rtk/
Accessed: 2026-06-26
Quote: The "60-90% savings" reflects bytes stripped from Bash output, not the LLM invoice; RTK ignores file reads, repo context, system prompts, reasoning tokens. Silent truncation broke Playwright debugging (issue #690).

**llmlingua2-agent-failure**
URL: https://arxiv.org/abs/2411.15927
Accessed: 2026-06-26
Quote: LLMLingua-2 above ~30% token removal caused complete task failure on Web-Shopping agent tasks via structured-output/format destruction.

**princeton-pareto**
URL: https://arxiv.org/abs/2407.01502
Accessed: 2026-06-26
Quote: (see ai-agents-that-matter) — accuracy-vs-cost frontier; a tool that moves cost without moving accuracy up is net-negative.

**anthropic-caching**
URL: https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching
Accessed: 2026-06-26
Quote: Cached prefix reads bill ~10% of input; caching addresses repeated-prefix cost, not context-window capacity. A prefix-rewriting proxy can break cache hits.

**berkeley-prompt-compression**
URL: https://arxiv.org/abs/2407.08892
Accessed: 2026-06-26
Quote: Extractive reranker compression improved F1 (+7.89 on 2WikiMultihop) by removing noise; abstractive at the same ratio was worse (-4.69). Compression quality, not ratio, decides the outcome.

## SYNTHESIS

For this setup: keep RTK and Headroom — on real multi-file work they net ~20-25% with no
correctness cost, corroborated by independent benchmarks (TACO). Stop trusting the `rtk gain`
99.3% meter; the honest figure is ~20-25% and it comes from session-wide turn/output reduction,
not the byte-stripping the meter counts. Two concrete actions this surfaced: (1) the RTK
instruction block in AGENTS.md actively HARMS Codex on isolated homes (it probes `cat RTK.md`
and then double-runs commands, +81%) — so the RTK block is not just attention bloat, it's a
correctness/token liability for Codex; trimming/rewording it is justified by data, not just
tidiness. (2) Native prompt caching covers dollar-cost, so value these proxies for context-window
capacity on long sessions, not for price. Missing to be fully sure: a cost-per-successful-task
A/B from the API invoice with N>1; the local runs are N=1/cell and don't surface turn count.
