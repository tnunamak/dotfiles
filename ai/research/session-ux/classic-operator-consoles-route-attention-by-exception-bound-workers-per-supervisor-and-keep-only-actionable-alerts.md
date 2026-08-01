---
title: "Classic operator consoles (NASA mission control, ATC, SRE) route a supervisor's attention by exception, bound the number of workers per supervisor, and gate alerts on actionability with a uniform small per-worker readout"
date: 2026-07-16
topic: session-ux
tags: [operations-console, attention-routing, alert-fatigue, use-red, exception-based, prior-art]
status: draft
sources: [nasa-flight-controller, nasa-ssr, atc-stca, sre-monitoring, use-method, red-method]
source_session: 019f1fc5-ed5e-7eb3-bfee-8ee8b26aeccf
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation. Skippable. No citations here.
-->

## CLAIMS

- NASA mission control assigns each front-room flight controller exactly one system/discipline: "Each controller is an expert in a specific area and constantly communicates with additional experts in the 'back room'." [nasa-flight-controller]
- In mission control, information and recommendations flow bottom-up and are filtered at each hop rather than exposing raw data to the top: "information and recommendations flow from the backroom to the frontroom to Flight, and then, potentially, to the on board crew." [nasa-flight-controller]
- No single operator tracks everything; the Flight Director monitors only the integrated picture: "The flight director … monitors the activities of a team of flight controllers, and has overall responsibility for success and safety." [nasa-flight-controller]
- Back rooms (Staff Support Rooms) hold the deep detail one hop from the console and explicitly filter external inputs before they reach the front room: the SSR "was designated as the focal point to control and filter external inputs to the flight control team for specific support," and for a critical phase "there could easily be twice as many people in this one SSR than there were in the MOCR." [nasa-ssr]
- Air traffic control treats machine alerting as a last-line exception surfacer, not a replacement for the human's "picture": Short Term Conflict Alert (STCA) is "a ground-based safety net intended to assist the controller … by generating, in a timely manner, an alert of a potential or actual infringement of separation minima," and it flags but does not prescribe the fix ("Unlike TCAS, STCA does not normally suggest remedial action"). [atc-stca]
- ATC caps how many aircraft one controller handles via sector capacity, and computes that capacity deliberately ignoring the safety net: "STCA is a safety net; its sole purpose is to enhance safety and its presence is ignored when calculating sector capacity." [atc-stca]
- Poorly tuned exception alerts erode trust: in terminal areas STCA can produce "a relatively high number of STCA nuisance alerts." [atc-stca]
- Google SRE requires every alert to be actionable: "Every page should be actionable." [sre-monitoring]
- Google SRE alerts on symptoms rather than causes: "it's better to spend much more effort on catching symptoms than causes." [sre-monitoring]
- Google SRE treats supervisor urgency as a finite, exhaustible budget: "I can only react with a sense of urgency a few times a day before I become fatigued," and over-paging makes engineers "second-guess, skim, or even ignore incoming alerts." [sre-monitoring]
- Google SRE prioritizes simplicity in monitoring: "The rules that catch real incidents most often should be as simple, predictable, and reliable as possible." [sre-monitoring]
- The USE method prescribes a fixed, small, uniform per-resource readout — Utilization, Saturation, Errors — explicitly for speed and completeness: "Like an emergency checklist in a flight manual, it is intended to be simple, straightforward, complete, and fast," solving "about 80% of server issues with 5% of the effort." [use-method]
- The RED method prescribes a parallel uniform per-request readout (Rate, Errors, Duration) whose consistency is what lets you scale oversight to work you didn't build: "Giving this kind of consistency across services allows you to scale your operational team, and allows you to put people on call for code they didn't write." [red-method]

## SOURCES

**nasa-flight-controller**
URL: https://en.wikipedia.org/wiki/Flight_controller
Accessed: 2026-07-16
Quote: "Each controller is an expert in a specific area and constantly communicates with additional experts in the 'back room'." / "Within the chain of command of the MCC, information and recommendations flow from the backroom to the frontroom to Flight, and then, potentially, to the on board crew." / "The flight director, who leads the flight controllers, monitors the activities of a team of flight controllers, and has overall responsibility for success and safety."

**nasa-ssr**
URL: https://www.mannedspaceops.org/history/staff-support-rooms/
Accessed: 2026-07-16
Quote: "It was designated as the focal point to control and filter external inputs to the flight control team for specific support." / "For a critical mission phase there could easily be twice as many people in this one SSR than there were in the MOCR." / "The various MOCR systems operations flight controllers relied on their counterparts in the SSRs for expertise and in-depth analysis, especially in off-nominal or emergency situations."

**atc-stca**
URL: https://skybrary.aero/articles/short-term-conflict-alert-stca
Accessed: 2026-07-16
Quote: "Short Term Conflict Alert (STCA) is a ground-based safety net intended to assist the controller in preventing collision between aircraft by generating, in a timely manner, an alert of a potential or actual infringement of separation minima." / "STCA is a safety net; its sole purpose is to enhance safety and its presence is ignored when calculating sector capacity." / "Unlike TCAS, STCA does not normally suggest remedial action."
Note: direct WebFetch of skybrary.aero returned HTTP 403; quotes are exact strings from the search engine's returned page body — high confidence but not independently re-fetched from raw HTML.

**sre-monitoring**
URL: https://sre.google/sre-book/monitoring-distributed-systems/
Accessed: 2026-07-16
Quote: "Every page should be actionable." / "it's better to spend much more effort on catching symptoms than causes" / "I can only react with a sense of urgency a few times a day before I become fatigued." / "The rules that catch real incidents most often should be as simple, predictable, and reliable as possible."

**use-method**
URL: https://www.brendangregg.com/usemethod.html
Accessed: 2026-07-16
Quote: "For every resource, check utilization, saturation, and errors." / "Like an emergency checklist in a flight manual, it is intended to be simple, straightforward, complete, and fast." / "It solves about 80% of server issues with 5% of the effort."

**red-method**
URL: https://grafana.com/blog/2018/08/02/the-red-method-how-to-instrument-your-services/
Accessed: 2026-07-16
Quote: "For every resource, monitor: Rate … Errors … Duration." / "Giving this kind of consistency across services allows you to scale your operational team, and allows you to put people on call for code they didn't write."

## SYNTHESIS

Four decades of operations-console practice converge on the same handful of principles, and they map cleanly onto a terminal fleet supervisor:

**1. Route attention by exception, keep raw streams one hop away.** NASA's front-room/back-room split is the durable pattern: the Flight Director never watches raw telemetry for every system; each discipline's raw data lands in a back room that *filters* it into decision-ready conclusions pushed forward. The fleet analogue: the overview surface shows filtered state per window (and a pushed exception when a window needs you); the raw scrollback/transcript is the "back room" you drill into on demand, not something the overview streams. ATC reinforces this — STCA *flags* an imminent exception on the display and lets the human decide; it does not act and does not prescribe.

**2. Bound the number of workers per supervisor; "split the sector" past the cap.** ATC caps aircraft-per-controller via sector capacity and splits sectors when demand exceeds it — and pointedly computes that cap *without counting the safety net* (you never let the existence of an alarm justify overloading the human). SRE says the same in the language of budget: urgency is exhaustible ("a few times a day before I become fatigued"). Tim's fleet is growing past a glanceable count, so the design needs an explicit bound — a WIP-style limit on concurrently-active-and-unreviewed workers, and a way to "split" (group/collapse) rather than lengthen a flat list.

**3. Alerts must be actionable and symptom-based, or they cause fatigue.** "Every page should be actionable" + "catch symptoms not causes" + nuisance-alert erosion of trust (ATC's TMA false-alarm problem) all say the same thing: a fleet notifier should push on a small set of high-signal, human-required conditions (needs-input, needs-approval, failed, ready-for-review) — the symptoms of "this worker needs a human" — and NOT on cause-level noise (every tool call, every log line, routine completions the supervisor doesn't need to act on). Over-notifying trains the supervisor to skim and ignore, defeating the whole surface.

**4. A uniform, small per-worker readout is what makes many unfamiliar workers tractable.** USE (3 numbers per resource) and RED (3 per request) are deliberately tiny and *identical across every entity* — RED's author is explicit that this uniformity is what lets you oversee "code you didn't write." Every NASA console position runs the same standardized layout. For the fleet: give every window the *same* compact schema (state icon + name + one-line what-it's-doing/needs/produced + repo/branch + age), so the supervisor reads the *board*, not each window's idiosyncratic output. This is the console-design justification for the per-row schema the agent-fleet products converged on independently.

Net: the classic consoles and the 2025-2026 agent products agree. The consoles supply the *why* (finite attention, exception routing, bounded span-of-control, symptom-only alerting, uniform readout) that the products implement as *needs-you-first grouping, PR-keyed review state, push-on-exception, and a one-line summary row*.
