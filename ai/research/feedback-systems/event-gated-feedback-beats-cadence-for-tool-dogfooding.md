---
title: "For agent tool dogfooding, event-gated feedback (on friction/notable-success) beats time cadence, with a rate cap"
date: 2026-06-25
topic: feedback-systems
tags: [feedback, sampling, dogfooding, experience-sampling, telemetry, rate-limit]
status: settled
sources: [himmelstein-esm, otel-sampling, oneuptime-sampling, centercode-dogfood, chameleon-nps, failure-aware-obs]
source_session: 019f005e-b205-77b3-9faa-01fe0eac7ed7
---

## CLAIMS

- Experience-sampling research splits prompting into interval-contingent (fixed schedule), signal-contingent (random/time), and event-contingent (triggered by a target event); event-contingent maximizes relevant observations but the burden is the event itself. [himmelstein-esm]
- For rare/sporadic events, only an event-contingent design reliably catches them; a random cadence mostly fires when nothing noteworthy happened — and tool failures are exactly such rare events. [himmelstein-esm]
- A uniform time cadence is equivalent to telemetry "head sampling," which structurally cannot guarantee capturing error/anomaly events; event-triggered feedback is "tail sampling" (decide to keep after seeing the outcome). [otel-sampling]
- Production tracing biases the sampling budget toward anomalies — a commonly cited split is ~50% errors / 30% slow traces / 20% random baseline — rather than sampling uniformly. [oneuptime-sampling]
- Product/UX consensus: trigger feedback on a completed meaningful interaction (after success or notable friction), never mid-flow, with stacked rate caps (per-survey frequency + global cooldown); behavior-triggered prompts outperform random delivery (>25-30% response vs random). [chameleon-nps]
- The #1 dogfooding-feedback failure is feeling like a "second job" with no payoff; the fix is capture at the moment of friction, one low-friction home, route by type/severity, and only ask when there's something real. [centercode-dogfood]
- Agent-observability research uses failed tool calls, retries, fallbacks, execution errors, and loop indicators as first-class cost-correlated friction signals captured during execution, and prefers deterministic programmatic scorers over agent self-assessment. [failure-aware-obs]
- Prompt fatigue is rate-sensitive: ESM response rate is ~95% at 1-2 prompts/day and degrades sharply above ~8/day, and studies cap duration at 1-2 weeks. [himmelstein-esm]

## SOURCES

**himmelstein-esm**
URL: https://pmc.ncbi.nlm.nih.gov/articles/PMC6591090/
Accessed: 2026-06-25
Quote: "if there are concerns about power or other reasons to maximize the number of within-person observations, event-contingent sampling is recommended... if the events are very rare, only an event-contingent design might make sense."

**otel-sampling**
URL: https://opentelemetry.io/docs/concepts/sampling/
Accessed: 2026-06-25
Quote: Head sampling "cannot ensure that all traces with an error within them are sampled"; tail sampling decides after the trace completes, enabling always-sampling error/latency traces.

**oneuptime-sampling**
URL: https://oneuptime.com/blog/post/2026-02-06-head-based-vs-tail-based-sampling-opentelemetry/view
Accessed: 2026-06-25
Quote: Bias the budget toward anomalies (errors/slow) and keep only a thin random sample of routine traffic.

**centercode-dogfood**
URL: https://www.centercode.com/blog/dogfooding-101
Accessed: 2026-06-25
Quote: "The fastest way to kill engagement is to collect feedback and never respond to it... give feedback one low-friction home and close the loop." A broken button, a confusing label, and a feature idea should not all land in the same pile.

**chameleon-nps**
URL: https://www.chameleon.io/blog/nps-survey-best-practices-to-improve-engagement-guide-infographic
Accessed: 2026-06-25
Quote: An NPS survey should be triggered by an in-app experience after a successful task completion; never interrupt mid-flow.

**failure-aware-obs**
URL: https://arxiv.org/html/2606.01365v1
Accessed: 2026-06-25
Quote: A failure-aware observability framework uses "token counts, tool-call counts, retry events, evidence gaps, execution errors, and loop indicators" as cost-correlated proxies captured during execution.

## SYNTHESIS

Design for the multi-tool dogfooding-feedback system (devspecs, waspflow, darshana,
clawmeter, pdpp): trigger a feedback entry only when a roster tool was used AND something
noteworthy happened (failure / retry / fallback / abandon / schema-migration error like ds's
"no such column" / notable clean success on non-trivial work) — not on mere usage, never on a
pure cadence. Stack rate caps: one feedback write per session max, per-tool cooldown (~N days),
de-dup by error signature. Keep exactly one thin cadence floor: a single hard-capped "tried X
lately?" nudge if a tool has had zero events for ~30 days, to cover the one event-contingent
blind spot (a tool you stopped reaching for). Define the trigger on generic tool-call outcomes
so it generalizes across CLIs/MCPs/skills with no per-tool logic — adding a tool is adding a
name to a watchlist. The agent's prose is the payload; the instrumented event is the gate.
This validates and sharpens the existing devspecs instruction ("log when you actually used it;
failures and rough edges are the most valuable signal; no filler usage").
