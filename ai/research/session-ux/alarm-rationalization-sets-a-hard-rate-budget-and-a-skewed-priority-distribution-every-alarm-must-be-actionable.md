---
title: "Industrial alarm rationalization (EEMUA 191 / ISA 18.2) makes every alarm prove it is actionable, caps the operator at ~1 alarm per 10 minutes with a hard flood ceiling, and mandates a skewed priority distribution (~80/15/5) — turning 'how much may we interrupt' into an engineered budget, not a preference"
date: 2026-07-16
topic: session-ux
tags: [alarm-budget, rationalization, eemua-191, isa-18-2, actionability, priority-distribution, alarm-flood]
status: draft
sources: [seqent-rationalization, eemua-benchmarks, isa-flood, processvue-kpi]
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation/conclusions. Skippable.
-->

## CLAIMS

- Alarm rationalization requires every alarm to justify itself against a fixed test: is it necessary, is it set correctly, and does it give the operator enough time and information to respond — an alarm with no defined operator response is removed, not kept. [seqent-rationalization]
- The steady-state rate budget is ~1 alarm per operator per 10 minutes during normal operations (≈6/hour, ≈150/day); a rate below 6/hour is the acceptable target and rates above ~30/hour indicate a seriously deficient system. [eemua-benchmarks] [processvue-kpi]
- The budget derives from empirical human-performance data, not convention: the 1998 Bransby & Jenkinson survey found ~1 alarm per 10 minutes was very likely to be acceptable, and the standards adopted it directly. [processvue-kpi]
- There is a separate, much tighter upset/flood ceiling: no more than 10 alarms in the first 10 minutes of a major upset; ISA-18.2 formally defines an alarm flood as >10 alarms activating within any 10-minute period, a rate at which an operator can no longer meaningfully process each one. [eemua-benchmarks] [isa-flood]
- A mature system must have a skewed priority distribution — roughly 80% low / 15% medium / 5% high — so that a "high priority" signal is rare enough to still mean something; a flat distribution defeats prioritization. [eemua-benchmarks]
- A small number of "bad actor" alarms dominates an unrationalized system: the top ten alarms typically account for 60–80% of all alarm occurrences, so fixing a handful of chattering/redundant sources reclaims most of the noise budget. [seqent-rationalization] [processvue-kpi]
- The standing-alarm population (alarms currently active/unacknowledged) should stay below ~10 per operator; a large standing population is itself a defect because it hides new alarms in a wall of old ones. [eemua-benchmarks]
- The benchmark gap is enormous in practice — most unrationalized facilities exceed these targets by an order of magnitude — and the standards treat that excess as a design failure to be engineered out, not a fact of life to tolerate. [processvue-kpi] [eemua-benchmarks]

## SOURCES

**seqent-rationalization**
URL: https://seqent.com/blog/alarm-rationalization-explained/
Accessed: 2026-07-16
Quote: "For each alarm, the review asks: is this alarm necessary? Is it set correctly? Does it give the operator enough time and information to respond?... The top ten alarms in a typical unrationalised system account for 60 to 80 percent of all alarm occurrences."

**eemua-benchmarks**
URL: https://www.empoweredautomation.com/eemua-alarm-management
Accessed: 2026-07-16
Quote: "no more than one alarm per operator per ten minutes during normal operations; roughly 150 alarms per operator per day. During a major plant upset, no more than ten alarms should present in the first ten minutes... priority distribution roughly 5% high / 15% medium / 80% low."

**isa-flood**
URL: https://www.symestic.com/en-us/what-is/mes-alarm-management
Accessed: 2026-07-16
Quote: "ISA-18.2 defines an alarm flood as more than 10 alarms activating within any 10-minute period, a rate high enough that an operator can no longer meaningfully process each one individually."

**processvue-kpi**
URL: https://www.processvue.com/downloads/Alarm_system_performance_KPIs_V1_0.pdf
Accessed: 2026-07-16
Quote: "The Bransby & Jenkinson survey performed in 1998 concluded that one alarm per ten minutes was considered very likely to be acceptable... fewer than 6 alarms per operator per hour is the acceptable target; rates above 30 indicate a seriously deficient alarm management system."

## SYNTHESIS

This is the direct source for the redesign's "alarm budget" decision — and it says the budget is not a preference, it is the definition of whether the system works. Two numbers transfer:

**The steady-state cap: ~1 interrupt / 10 min ≈ 6/hour.** For the workshop, treat >6 attention-grabbing signals (flash/push/sound) per hour as *the system is broken by definition*, and >30/hour as seriously deficient. Note the unit: this is per *operator*, aggregated across ALL 27 windows, not per window. Twenty-seven windows each politely pinging once an hour is a 27/hour flood — so the budget must be enforced globally, with a coalescing/token-bucket limiter across the whole workshop, not per-source. This is the industrial correction to the naive "each window notifies for its own events" design, which is exactly the "individually sensible defaults compound into a wall" failure Slack/Linear also hit.

**The flood ceiling: >10 in 10 min = flood.** If more than ~10 signals want to fire in a 10-minute window (e.g. a service crash-loops, or five agents finish at once), the correct behavior is to STOP delivering individual alerts and collapse to one aggregate "N windows need attention — open the dashboard" signal. Cascading N per-item interrupts during a storm is the defining alarm-management anti-pattern (and matches the Temporal "runtime failure must not surface as N workflow failures" rule from the feedback-systems corpus).

**Actionability is the admission test.** Every candidate signal must name the operator response it enables. "Agent blocked on me" → I unblock it (actionable, top tier). "Command finished" → I look at output (actionable, low tier). "Service logged a warning" → often *no* required action → it must NOT be an alarm; it goes to the dashboard/detail layer. This is the same gate as the SRE five-question test already captured in `feedback-systems/mature-integrations-only-interrupt...`, restated as an industrial standard.

**The 80/15/5 distribution keeps 'high' meaningful.** If the workshop ever has agent-blocked (top tier) firing as often as command-done (bottom tier), the tiers have collapsed and trust decays. Budget the tiers: the interrupt-me tier should be the rare 5%, and if it isn't, the classifier is miscalibrated — not the human's tolerance that's wrong. And because a few "bad actors" produce most noise (a flapping dev server, a chatty agent), most of the budget is reclaimed by silencing a handful of sources, not by tuning everything.
