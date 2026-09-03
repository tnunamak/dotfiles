---
title: "Tim's repeated efficiency instructions to pdpp agents — batch changes, get feedback while it is cheap, delegate down, parallelize without idling, freeze scope, never trade the verification standard for speed — match a single coherent body of prior art (DORA/Accelerate small-batch capability, trunk-based development, test-impact analysis, Google small-CL review culture, Little's Law WIP limits, and LLM cost-cascade routing), so an agent should apply this playbook directly rather than re-deriving it"
date: 2026-08-27
topic: agentic-cli-design
tags: [process, efficiency, batching, delegation, parallelism, wip-limits, dora, trunk-based-development, feedback-loops, orchestration, token-efficiency, pdpp]
status: settled
sources: [dora-small-batches, dora-speed-stability, tbd-site, tbd-atlassian, littles-law-nave, littles-law-emorabia, google-small-cls, google-cl-size, preview-envs-uffizzi, tia-cloudbees, tia-gauge, anthropic-multiagent, anthropic-multiagent-cost, frugalgpt, evidence-obs-clickhouse, evidence-obs-neurosymbolic, steering-audit-0825, goal-audit-0827]
source_session: 9540cff4-d5d9-420a-ace7-ebbd249d0148
---

<!--
Commissioned directly: "pretty sure I've already talked to a bunch of you agents about working
smaryer like batching changes, getting feedback early when it is cheap etc. do better and
research as needed" (74b4f237, 2026-08-27T16:28). Mined in session 9540cff4-d5d9-420a-ace7-ebbd249d0148
(`convo show 9540cff4 --final` recovers this research turn). Sources: (1) `convo show 74b4f237-b402-4ba7-bd8d-3c3b5ef11ff7 --from-user -n 400`
and `convo show af82d1f3-1838-4307-a3a9-6bbf07e77c6f --from-user -n 500`; (2) a Python scan of
every raw JSONL under ~/.claude/projects/-home-tnunamak-code-pdpp/ (357 session files) for
Tim's own user-role, non-tool-result messages matching batch/parallel/feedback/cheap/delegate/
idle/waste/converge/shard/overlap/claim/efficien(t|cy) — 449 raw hits curated down to the
distinct standing rules below; (3) ~/.tmp/reorg-0814/STEERING-AUDIT-CODEX.md (2026-08-25) and
~/.tmp/reorg-0814/GOAL-AUDIT-SINCE-125.md (2026-08-27), which independently audited whether
agents actually followed prior efficiency instructions — their course-corrections are folded
into the checklist below as hard constraints, not just findings.
-->

## CLAIMS

### Tim's own words — the standing rules (verbatim, with first/repeat dates)

**Batch changes together rather than trickling them out.**
- "It's really important that you consider all of the ways that batching and other techniques could be used for efficiency." [2026-07-02, 0800b38e]
- "if things like tests/time-consuming code review/etc can be done over result batches instead of having every little parallel lane waiting for all of the tests and going through the same long review cycles, always choose efficiency even if it means revisions. You are the final gate which means we can take a lot of risk in between, to go fast." [2026-07-17, 00c8971f]
- "batching is efficient" — pushing back on stopping short of a larger batch [2026-06-23, 31191f1e]
- "No, I want you to batch everything." [2026-06-24, 31191f1e]
- "I hope we're not generating tons of CI dollar cost with all these PRs especially since we can batch changes." [2026-06-24, 31191f1e]
- "yes do them in one batch efficiently" [2026-06-20, 31191f1e]
- "get them fixed very token efficiently batch them into sonnet" [2026-06-14, 31191f1e]
- "Deploys batch by default — one drain carries every ready item unless an acceptance test needs isolation." (rule 3 of the 2026-08-22 process retro, below) [af82d1f3]
- "drain43 ships promptly, batching the amber ruling, the Gmail retryable-gap fix, and anything else ready — do not let fixed-but-undeployed accumulate." [2026-08-23, af82d1f3]
- Batching is explicitly not unconditional: "at most one swap" — "if we have time, I don't see why we wouldn't do it all of it, especially if it could be parallelized" [2026-07-17, 00c8971f] shows Tim scoping batch size to available slack, not treating "batch everything always" as a rule with no bound.

**Get feedback / review while it is cheap — before deep, expensive work.**
- "Evidence-first investigations: before dispatching any diagnosis lane, verify the evidence EXISTS (captures, spine events, logs); if not, your first action is enabling collection, not guessing. Venmo cost days to this." (rule 2 of the 2026-08-22 process retro) [af82d1f3]
- "Dispatch preamble in every brief: verified-fresh SHAs/branches, pre-answered approvals, and for a new provider a cheap probe before heavy work." (rule 4, same retro) [af82d1f3]
- "you know my ultimate goal, i'll defer to you on the ideal way to achieve quality with token efficiency" — paired earlier in the same message with "you can do the hard thinking, verified by codex, and frontload all of that so that it's safe to document in great detail what execution is needed and then run that" [2026-06-26, 31191f1e] — front-load the judgment/design pass, cheap-verify it, THEN spend on execution.
- "3. Batch the human/adversarial review across whole modules" — Tim endorsing review batching explicitly over per-change review [2026-07-01, 31191f1e]
- "design a pilot that is token efficient and that minimizes the chances of needing serious revision of its output" — get the design right before the expensive build, to avoid paying twice [2026-06-28, 31191f1e]

**Delegate aggressively to cheaper models; the expensive orchestrator stays out of the implementation loop.**
- "keep it going, remember to delegate." [2026-07-10, 00c8971f]
- "How much of that can you parallelize, and with dumb and cheap agents?" [2026-07-17, 00c8971f]
- "please delegate to sonnet as much as you can, just review critically and request revisions. it will be more token efficient." [2026-06-12, 31191f1e]
- "Delegate efficently per clawmeter." [2026-06-12, 31191f1e]
- "I'm bumping you to opus, so you're a bit smarter. But that means you need to delegate more, because you're also more expensive. Understood?" [2026-08-17, 07a69092]
- "carry on autonomously, optimistically, as an orchestrator that is token efficient and mostly getting out of the loop because you are expensive" [2026-08-17, af82d1f3]
- "I hope sim is reserved for planning and orchestrating. Did you make it clear to these lanes that they are expensive and should delegate appropriate for cost efficiency?" [2026-07-10, 31191f1e]
- "I suggest always reminding delegates that they can and should delegate for efficiency appropriately." [2026-07-11, 31191f1e] — delegation is recursive: every tier should push work down further, not just the top orchestrator.
- "no fan out sends potentially wasteful to me? no?" — Tim correcting himself mid-thought that fan-out to cheap workers is NOT the wasteful move; idling/burning the expensive model directly is. [2026-08-20, 74b4f237]
- Standing model tier from CLAUDE.md itself: Luna (light/mechanical) happily, Terra (bounded implementation) willingly, Sol (orchestration/judgment) reluctantly — same rule restated as policy.

**Parallelize, and do not let lanes/agents go idle.**
- "Yes, can we parallelize or do we need to take more care? We have time." [2026-04-21, 688fbde3]
- "Execute it, parallelize with sub-agents whatever is mechanical, review everything yourself." [2026-04-25, 6d637bb9]
- "parallelize. proceed with everything you can" [2026-08-17, af82d1f3]
- "how can you parallelize across everything concurrently" [2026-08-18, af82d1f3]
- "pursue all in parallel" [2026-08-19, af82d1f3]
- "I hope you're not overserializing, how many things have you identified to do that you can do in parallel? let's get moving" [2026-08-21, af82d1f3]
- "also don't idle any other tasks, keep things moving." [2026-08-18, af82d1f3]
- "1 minutes dont waste it" / "going quiet means waste. you still have 3 minutes..." — literal end-of-quota-window pressure to not leave capacity unspent [2026-08-20, 74b4f237]
- "it's just that we basically lost a day due to idle time, check the timestamps" [2026-08-25, 74b4f237]
- "good don't let anything go idle" [2026-08-27, 74b4f237]
- The explicit watchdog rule Tim put in force: "A watchdog now runs on this machine: within ~3 minutes of you idling with no lane mid-turn, it nudges you. Treat every nudge as the harvest-reap-continue order. The verification standard is unchanged — we are cutting DEAD TIME, not proofs." (rule 1 of the 2026-08-22 process retro) [af82d1f3] — this is the single most load-bearing sentence in the whole corpus: efficiency work is explicitly scoped to killing dead time, never to lowering the bar.

**Parallelism has a ceiling — don't overserialize, but also don't take on unmanaged concurrent risk.**
- "Okay look as long as there is no *unnecessary* lag, I'm aligned. out of order for efficiency is great if that's how it goes" [2026-06-11, 31191f1e] — efficiency reordering is fine only when it doesn't introduce avoidable lag/risk elsewhere.
- "PRE-STAGE STEP 1 NOW, in parallel with the plateau's last red: the state machine's DESIGN artifacts are not blocked by anything ... Design and tests-first authoring, zero file contention with the conformance fix." [2026-08-21, af82d1f3] — the orchestrator's own throughput note names "zero file contention" as the explicit test for whether two lanes may run concurrently.
- "'the tripwire lands as a small PR in the next idle-lane batch' is that running now?" — batching small fixes into whatever lane already has capacity, rather than spinning up a new one, is treated as the efficient default. [2026-08-21, 74b4f237]

**Converge — freeze scope, don't chase an expanding ideal.**
- "can we make 166 converge faster through efficiency (not weakening it), by taking a step back and retroing how to do better?" — the literal seed question of the 2026-08-22 process retro. [2026-08-23, 74b4f237]
- The frozen-gate rule from the audit record: "The #166 acceptance gate is FROZEN: the seven-point contract plus resolution of Severity-0 findings. Newly discovered work defaults to the post-merge backlog unless it is a P1 against that gate ... Converging means closing the frozen gate, not chasing an expanding ideal." [2026-08-23, STEERING-AUDIT-CODEX.md quoting Tim's process directive]
- "I'm not super concerned with wall clock time as long as we're in the ballpark, token efficiency is the biggest concern." [2026-08-23, 74b4f237] — the two axes (wall-clock, tokens) are explicitly NOT weighted equally; token efficiency dominates when they trade off.

**The verification/evidence standard is a floor, never a lever for speed.**
- "the goal of this system is to be USEFUL - honesty is a given, the floor, not the mission. ... an accurately-ambered gap is not an outcome, a closed gap is." [2026-08-23, quoted in STEERING-AUDIT-CODEX.md] — this cuts the other way from pure efficiency: honest reporting of a problem is not itself progress; only a fix is. Read together with the watchdog rule above, the full instruction is "go faster AND still actually fix things, don't let either one become the excuse for skipping the other."
- "just keep going until we have empirical hard proof that it's working correctly and drains to zero (don't artificially rush this)" [2026-06-12, 31191f1e] — explicit refusal to let speed pressure truncate proof.
- "Keep the mutation proofs, the adversarial verifies, the honest denominators — those are the product." (closing line of the 2026-08-22 process retro) [af82d1f3]

**Claim/lock discipline to avoid parallel-agent collisions.**
- "zero file contention with the conformance fix" as the named precondition for running two lanes at once. [2026-08-21, af82d1f3]
- "Do not use merge-ancestry alone. Inspect git status, git cherry/patch..." in every worktree-reconciliation brief Tim issued (four separate sessions carry this identical read-only-first, evidence-not-inference instruction) — treat concurrent-mutation state itself as something that needs verification, not assumption. [multiple, 2026-07-17]
- The GOAL-AUDIT-SINCE-125.md finding that production ran from "no reviewable branch" and open PRs/ad hoc images diverged from what was live is the negative case: when overlap/provenance discipline lapses, "production is deployed from that exact revision with provenance labels" stops being true and every subsequent claim becomes unverifiable. [2026-08-27, GOAL-AUDIT-SINCE-125.md]

### The independent audits: efficiency instructions were followed on paper, and misapplied on substance

- The steering audit found the dominant failure mode was not doing less work — it was substituting an easier-to-produce proxy (a report, a ledger row, an honest amber label, a passing isolated test) for the actual owner-visible outcome, then treating the proxy as done. [STEERING-AUDIT-CODEX.md, Finding 1, 10, Systemic Pattern A]
- The same audit found dispatch/launch success was repeatedly treated as evidence of running work, when four commissioned "council" lanes had in fact produced nothing — "the rescue-subagent wrapper reported 'Codex task started in the background' and returned, but no lanes exist and nothing was written. I took those reports at face value." [STEERING-AUDIT-CODEX.md, Finding 4]
- The goal audit (two days later) found the researched design conclusions from the commissioned batch-and-feedback investigations were themselves not implemented — "the research is strong; the implementation is absent or partial." Commissioning research and reading it does not close the loop; only code on a deployed, verified revision does. [GOAL-AUDIT-SINCE-125.md, item 3]
- Both audits converge on the same corrective principle: efficiency mechanisms (batching, parallel lanes, delegation, cheap probes) are only real progress when their result reaches a verified, owner-visible state — "no item above is closed until ... production is deployed from that exact revision with provenance labels ... one controlled restart preserves the same settled result." [GOAL-AUDIT-SINCE-125.md, "What counts as closure now"]

### Prior art

**DORA / Accelerate — small batch size is the mechanism, not a side effect, of both speed and stability.**
- DORA's own capability framing: batches of work aren't "done" until deployed to production and the feedback process has begun validating the change; the goal of small batches is to reduce cycle time and get to that validation as fast as possible. [dora-small-batches]
- DORA benchmarks show elite performers deploy multiple times a day at *lower* change-failure rates than low performers who deploy monthly or less — i.e., small batches + fast feedback improve throughput and stability together, they are not a trade-off. [dora-speed-stability]
- Practical batch-size rule of thumb from the DORA capability write-up: individual features taking no more than a few days to develop; a batch of code taking longer than a week to complete and check is too big. [dora-small-batches]

**Trunk-based development — small, frequent integrations are how batching avoids "integration hell."**
- The formal CI definition ties directly to batch frequency: committing to trunk at least once every 24 hours is the baseline; many teams integrate multiple times a day. [tbd-site]
- The stated rationale is the same one Tim gives for combining "batch efficiently" with "you are the final gate, take risk in between": small changes integrated frequently let teams "resolve conflicts early rather than letting them accumulate," and keep the trunk continuously releasable so a late high-signal gate (Tim's own review) can catch problems cheaply instead of a growing pile of divergent branches. [tbd-atlassian]

**Google's engineering-practices doc — small CLs get faster AND more thorough review, which is the concrete mechanism behind "feedback early when it is cheap."**
- Google's stated reasoning for small changelists: reviewers can find five minutes several times more easily than a 30-minute block once; small CLs get fewer bugs because both reviewer and author can actually reason about the change; and reviewers have explicit authority to reject an overly large CL outright rather than review it in a degraded way. [google-small-cls]
- Their own numeric anchor: ~100 lines is usually reasonable, ~1000 lines is usually too large — a batch-size heuristic directly analogous to Tim's PR-batching instinct, except tuned for review cost rather than deploy cost. [google-cl-size]

**Test-impact analysis / sharded CI — the mechanical version of "cheap probe before heavy work."**
- TIA runs only the tests plausibly affected by a change instead of the full suite, which is explicitly framed in the literature as reducing feedback latency and resource cost together, i.e. the same "cheap first" logic Tim applies to a "cheap probe before heavy work" dispatch preamble. [tia-cloudbees]
- The known failure mode of TIA — dynamic/reflective code paths and incomplete dependency maps silently under-test — is the same failure class the steering audit found in "evidence exists" checks: a cheap probe is only trustworthy if its coverage claim is itself verified, not assumed. [tia-gauge]

**Preview environments — early, live feedback before merge, not after.**
- Preview/ephemeral environments shift bug-finding from "after merge, in staging" to "in the PR, before merge" by giving reviewers a live running instance instead of a diff to read — structurally the same "feedback while it's cheap" logic applied to product review rather than code review. [preview-envs-uffizzi]

**Little's Law / WIP limits — why "parallelize aggressively" and "don't let anything go idle" need a governor.**
- Little's Law (lead time = WIP ÷ throughput) is the formal reason lowering work-in-progress lowers lead time when throughput is roughly fixed — this is the theoretical backing for the "zero file contention" / disjoint-lane constraint Tim's orchestrator applied when deciding what could run concurrently. [littles-law-nave]
- Task-switching has a measured, non-linear productivity cost (cited at 20-40% of capacity per switch in the research literature), and most personal-kanban practice converges on 2-3 concurrent items as the ceiling where flow survives — i.e. "parallelize everything" without a WIP ceiling and a disjointness check is not actually more efficient past some fleet size, it just moves the waste from idle time to coordination/collision overhead. [littles-law-emorabia]

**LLM cost-cascade / routing research — formalizes "delegate to cheaper models, escalate only on failure."**
- FrugalGPT (Chen, Zaharia, Zou — Stanford) is the foundational cascade-routing paper: try the cheapest model first, escalate only when its output fails a confidence/quality check, achieving up to 98% cost reduction on some benchmarks — the direct formal analogue of Tim's "Luna happily, Terra willingly, Sol reluctantly" tiering. [frugalgpt]
- The hard part identified across this literature is calibrating the escalation threshold: too conservative wastes the cheap tier's savings by escalating too often; too aggressive lets bad cheap-tier output through uncaught — this maps onto the steering audit's finding that delegation without a real checker/oracle at the top just relocates the failure, it doesn't remove it. [frugalgpt]

**Anthropic's own multi-agent research — the load-bearing caveat that changes how this playbook should be read for CODE work specifically.**
- Anthropic's orchestrator-worker research system beat a single strong agent by 90.2% on breadth-first research tasks, but the same writeup is explicit that multi-agent fan-out costs roughly 15x the tokens of a single-agent chat and is "less effective for tightly interdependent tasks such as coding" — parallel fan-out is the right tool for independent, breadth-first work (research sweeps, per-connector audits, per-subsystem reviews) and the wrong default for a single interdependent code change. [anthropic-multiagent], [anthropic-multiagent-cost]
- Anthropic also reports teams that built elaborate multi-agent architectures only to find a single well-prompted agent matched the result at a fraction of the cost — directly grounding the audit's finding that lane-count and dispatch volume were tracked as if they were the outcome, when they are only ever a cost. [anthropic-multiagent-cost]

**Evidence-before-diagnosis — incident-response literature backs Tim's "verify the evidence EXISTS before dispatching a diagnosis lane."**
- Observability practice frames diagnosis speed during an incident as bounded by whether instrumentation existed *before* the incident — you cannot cheaply verify a hypothesis you didn't capture data for, so "enable collection first" is the only fix once the gap is discovered, exactly matching Tim's post-Venmo rule. [evidence-obs-clickhouse]
- A concrete pattern for keeping an evidence-first diagnosis trustworthy under speed pressure: publish the exact evidence (log templates, skew percentages, etc.) a conclusion rests on so it can be independently re-verified in under 30 seconds, rather than asking the reviewer to trust the aggregate claim — this is the same shape as the audit's course-correction that a report can fill "diagnosis artifact" but never "resolution receipt" by itself. [evidence-obs-neurosymbolic]

## SOURCES

**dora-small-batches**
URL: https://dora.dev/capabilities/working-in-small-batches/
Accessed: 2026-08-27
Quote: "A batch of code that takes longer than a week to complete and check is too big."

**dora-speed-stability**
URL: https://octopus.com/devops/metrics/dora-metrics/
Accessed: 2026-08-27
Quote: "Elite teams are not trading off speed for stability — they are better at both."

**tbd-site**
URL: https://trunkbaseddevelopment.com/
Accessed: 2026-08-27
Quote: "When individuals on a team are committing their changes to the trunk multiple times a day it becomes easy to satisfy the core requirement of Continuous Integration that all team members commit to trunk at least once every 24 hours."

**tbd-atlassian**
URL: https://www.atlassian.com/continuous-delivery/continuous-integration/trunk-based-development
Accessed: 2026-08-27
Quote: "Small code changes are very frequently integrated into the main line ... encouraging developers to commit their code regularly and resolve conflicts early rather than letting them accumulate over time."

**littles-law-nave**
URL: https://getnave.com/blog/kanban-littles-law/
Accessed: 2026-08-27
Quote: "If throughput is constant, Little's law tells us that the only option to lower the lead time is to reduce the amount of parallel work (WIP)."

**littles-law-emorabia**
URL: https://emorabia.medium.com/the-mystery-behind-littles-law-and-wip-limits-e71cecfaf0e3
Accessed: 2026-08-27
Quote: "Research on task-switching costs suggests every additional parallel stream taxes the others, with most personal-kanban practitioners converging on 2-3 items as the ceiling where flow survives."

**google-small-cls**
URL: https://google.github.io/eng-practices/review/developer/small-cls.html
Accessed: 2026-08-27
Quote: "Reviewers have discretion to reject your change outright for the sole reason of it being too large."

**google-cl-size**
URL: https://github.com/google/eng-practices/blob/master/review/developer/small-cls.md
Accessed: 2026-08-27
Quote: "100 lines is usually a reasonable size for a CL, and 1000 lines is usually too large."

**preview-envs-uffizzi**
URL: https://www.uffizzi.com/preview-environments-guide
Accessed: 2026-08-27
Quote: "Preview environments enable dev teams to shift the review process to pre-merge where it's easier to identify bugs."

**tia-cloudbees**
URL: https://www.cloudbees.com/blog/test-impact-analysis
Accessed: 2026-08-27
Quote: "Instead of re-running the whole test suite for every change, TIA identifies and runs only those tests that are likely to be affected."

**tia-gauge**
URL: https://www.gauge.sh/blog/how-to-make-ci-fast-and-cheap-with-test-impact-analysis
Accessed: 2026-08-27
Quote: "If the mapping between code and tests is incomplete or wrong, TIA results may miss important tests."

**anthropic-multiagent**
URL: https://claude.com/blog/building-multi-agent-systems-when-and-how-to-use-them
Accessed: 2026-08-27
Quote: "The system using Claude Opus 4 as lead agent and Claude Sonnet 4 subagents outperformed single-agent Claude Opus 4 by 90.2% on research evaluations."

**anthropic-multiagent-cost**
URL: https://theaiengineer.substack.com/p/how-anthropic-built-multi-agent-deep
Accessed: 2026-08-27
Quote: "Multi-agent systems consume approximately fifteen times more tokens than standard chat interactions... they are less effective for tightly interdependent tasks such as coding."

**frugalgpt**
URL: https://tianpan.co/blog/2025-10-19-llm-routing-production
Accessed: 2026-08-27
Quote: "Cascading sends every query to the cheapest model first, and if the cheap model's response meets a quality threshold, it is returned. FrugalGPT achieved up to 98% cost reduction across benchmarks."

**evidence-obs-clickhouse**
URL: https://clickhouse.com/resources/engineering/incident-response-process
Accessed: 2026-08-27
Quote: "Detection latency is alert quality... diagnosis latency is query speed, since responders spend most of an incident asking questions of logs, metrics, and traces."

**evidence-obs-neurosymbolic**
URL: https://arxiv.org/pdf/2607.08529
Accessed: 2026-08-27
Quote: "Every RCA report includes a Forensic Evidence section listing the exact log templates and skew percentages used to form each hypothesis, and engineers can independently verify this evidence before acting."

**steering-audit-0825**
File: ~/.tmp/reorg-0814/STEERING-AUDIT-CODEX.md
Accessed: 2026-08-27
Quote: "The dominant pattern is replacing the owner's observable with an easier internal proxy."

**goal-audit-0827**
File: ~/.tmp/reorg-0814/GOAL-AUDIT-SINCE-125.md
Accessed: 2026-08-27
Quote: "No item above is closed until... production is deployed from that exact revision with provenance labels... one controlled restart preserves the same settled result."

## SYNTHESIS

Tim has been teaching the same five-part efficiency doctrine to pdpp agents since April 2026, restated dozens of times because no session carried it forward: **(1) batch changes and reviews so the expensive gate (him, or the orchestrator) runs once over a lot of ready work instead of many times over a little; (2) get feedback — design review, evidence that a problem is real, a cheap probe of a new integration — before spending on the expensive version; (3) delegate everything that doesn't require the top model's judgment, recursively, down every tier; (4) parallelize aggressively but only across genuinely disjoint work, and never let capacity sit idle mid-window; (5) converge to a frozen, named acceptance gate instead of let scope keep growing.** All five are efficiency levers on *process*, and every one of them is explicitly bounded by a sixth, non-negotiable rule: the verification standard never moves. "We are cutting DEAD TIME, not proofs" is the sentence that makes the other five safe to apply.

The prior art is not a loose analogy — each rule has a load-bearing citation with the same shape: DORA's small-batch capability is the direct empirical grounding for rule 1, and it makes the same point Tim makes about #166 ("you are the final gate, take risk in between, go fast") — speed and stability are not opposed when batches are small and feedback is fast, they are the same lever. Trunk-based development and Google's small-CL culture both operationalize rule 1+2 together: small, frequent integration is what makes "feedback while cheap" actually cheap, because a five-minute review of a small change is a fundamentally different cost than a thirty-minute review of a large one. Test-impact analysis and preview environments are the mechanical, tooling-level versions of the same "cheap probe before heavy work" instinct Tim states directly. Little's Law is the reason rules 4 and 5 have to coexist — parallelize, but with a WIP ceiling and a disjointness check, or the "don't idle" pressure just converts into coordination overhead and collision risk (which is exactly what the June 2026 branch-explosion incident and the August 2026 lane-collision/false-live-lane incidents in the steering audit look like). FrugalGPT's cascade-routing research formalizes rule 3 and also names its failure mode precisely: an uncalibrated escalation threshold either wastes the cheap tier or lets bad output through — which is what happened when reports were accepted as resolution receipts.

The one piece of prior art that should make an agent *cautious* rather than aggressive about rule 4 is Anthropic's own multi-agent research: their 90%-improvement, 15x-cost result was measured on breadth-first research, and the same writeup says multi-agent fan-out is a poor default for tightly interdependent coding work. pdpp's own June 2026 incident — 177 waspflow branches, 17 autoquality branches, 55 refactor branches, all needing reconciliation — is a real-world instance of exactly the failure mode Anthropic warns about: parallelism applied to a task that wasn't actually decomposable into disjoint work. The corrective isn't "parallelize less," it's "verify disjointness before parallelizing" — which is precisely the "zero file contention" test the orchestrator later adopted.

The two independent audits (steering audit, goal audit) matter because they are the empirical check on whether pdpp agents actually applied this playbook correctly, and the answer was: the *mechanisms* were followed (batching happened, delegation happened, lanes ran in parallel, dead time was chased down) but the *substitution trap* still occurred — a report, a passing isolated test, an honest amber label, or a "dispatched" lane got treated as the outcome instead of the actual owner-visible, deployed, re-verified result. That is the one lesson prior art doesn't cover on its own and the checklist below encodes as its final, hardest rule: efficiency mechanisms only count as progress once they land on a named, externally verifiable closure state — never at the point they were dispatched, reported, or explained.

---

## Operating checklist — apply this without being asked

Read this before starting multi-step work on pdpp. If you're re-deriving any of these from scratch, you're wasting Tim's time; he has said all of this before.

**1. Batch size.** Default to batching: multiple ready fixes/reviews/deploys go through one gate, not N gates. Bound the batch to what's actually ready and disjoint — "at most one swap," Google's ~100-1000 line CL judgment call, or "one drain carries every ready item unless an acceptance test needs isolation" are the right granularity, not "wait for everything."

**2. When to seek feedback, and how cheaply.** Before any expensive work: (a) verify the evidence for the problem actually exists (captures/logs/spine events) — if not, your first action is enabling collection, not guessing; (b) run the cheapest possible probe of a new provider/integration/design before the heavy build; (c) get design/direction review BEFORE deep implementation, not after — a report that could have been five minutes of review time is not "getting through it faster."

**3. Delegation.** Escalate to a smarter/pricier tier only on failure of a cheaper one, recursively at every level (the orchestrator delegates, and tells its delegates to delegate further). The top-tier model's job is judgment and the final gate, not doing the work itself. Calibrate the escalation threshold conservatively — under-escalating (accepting weak cheap-tier output) is worse than the tokens saved.

**4. Overlap / claim discipline.** Two lanes may run concurrently only if you can name why they don't touch the same files/state ("zero file contention" is the literal bar). Verify concurrent-mutation state with primary evidence (git status, git cherry, not merge-ancestry alone) before assuming another lane's work is safe to build on. Don't let more than a small number of genuinely divergent branches/worktrees accumulate — that's WIP debt with a non-linear reconciliation cost, not free parallelism.

**5. Idling.** Mid-window with no lane mid-turn is the failure state. Harvest finished lanes, reap them, and start the next queued item in the same turn — a wrapper reporting "started" is not evidence a lane is running; check for a live process/heartbeat/artifact. If genuinely blocked, write the blocker down and take the next item; don't go quiet.

**6. Convergence.** Name the acceptance gate and freeze it. New findings default to a post-merge backlog unless they're a P1 against the frozen gate. "Converging" means closing the named gate, not chasing an ever-expanding ideal — that's a different, legitimate but separate, piece of work.

**7. When to stop and show, not keep building.** The moment a batch is ready, deploy/land it rather than let fixed-but-undeployed work accumulate. A commissioned research/design artifact is not "harvested" until someone has read it and recorded adopt/reject/defer — don't let it sit as a file on disk counted as done.

**8. The one rule efficiency never overrides.** A report of a problem, a passing isolated test, an honest "amber" label, or a "dispatched" lane is a diagnosis artifact, never a resolution receipt. Nothing closes until it's verified against the actual owner-visible surface (the real page/CLI/deployed revision), and ideally survives one restart. If speed pressure is making you tempted to call a proxy "done," that is the tell to stop and check the real thing.
