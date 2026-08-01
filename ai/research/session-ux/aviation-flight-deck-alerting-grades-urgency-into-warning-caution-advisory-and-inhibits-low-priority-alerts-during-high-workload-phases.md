---
title: "Aviation flight-deck alerting grades urgency into a small fixed ladder (warning / caution / advisory / memo) where each tier prescribes a different response speed, and inhibits lower-priority alerts during high-workload phases rather than deleting them"
date: 2026-07-16
topic: session-ux
tags: [alerting, urgency-tiers, dark-cockpit, inhibits, interruption-policy, aviation]
status: draft
sources: [airbus-ecam-levels, airbus-inhibit, ecam-wiki, apple-interruption-levels, onesignal-levels]
source_session: e2305330-9057-48c1-bcaf-6a28f00e4617
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation/conclusions. Skippable. No citations here.
-->

## CLAIMS

- Airbus's "dark cockpit" philosophy makes the *absence* of illuminated warnings the normal state: no light means all systems nominal, so any lit surface is itself signal — the periphery is silent by default and only illuminates on a real condition. [ecam-wiki] [airbus-ecam-levels]
- Airbus ECAM grades alerts into a small fixed ladder, and each tier is defined by required *response speed*, not by topic: Level 3 Warning (red) = failure requiring immediate action, continuous repetitive chime + master warning light; Level 2 Caution (amber) = crew must be aware but no immediate action, single chime + steady amber master caution; Level 1 Caution (amber) = loss of redundancy, requires monitoring, message only with NO aural; Advisory = a parameter is drifting, auto-calls the system page and the parameter pulses, no master light; Memo = green status reminder of a temporarily-selected function. [airbus-ecam-levels]
- The aural signal is graded with the visual: a red Warning gets a *continuous repetitive* chime, an amber Caution gets a *single* chime, and a Level 1 caution / advisory gets *no sound at all* — sound is reserved for the tiers that demand action, quieter tiers are visual-only. [airbus-ecam-levels]
- During takeoff and landing (the highest-workload, most safety-critical phases) ECAM *inhibits* lower-priority warnings and cautions so pilots are not distracted when busiest; inhibited alerts are not discarded, they are held and presented after the inhibit window ends. [airbus-inhibit] [ecam-wiki]
- The inhibit is phase-scoped and time-bounded, not global: takeoff inhibit runs across defined sub-phases (e.g. ~80 kts through 1500 ft), landing inhibit runs from ~800 ft to touchdown, and individual alerts can carry their own per-phase inhibit logic. [airbus-inhibit]
- ECAM couples each alert to its own remedy: on a failure it auto-displays the relevant procedure/checklist and the affected system synoptic ("monitor – manage – review"), so the alert and the means to resolve it arrive together rather than the alert being a bare interrupt. [airbus-ecam-levels] [ecam-wiki]
- Apple's iOS notification framework encodes the same graded ladder for consumer software with four fixed interruption levels — Passive (silent, no screen wake, appears in list only), Active (default: sound + screen wake, does NOT break Focus), Time Sensitive (breaks through Focus/scheduled delivery, distinct banner), Critical (bypasses silent switch and all controls, entitlement-gated for emergencies) — mapping urgency to how much of the user's attention the OS is permitted to seize. [apple-interruption-levels] [onesignal-levels]
- Apple gates the top two tiers behind escalating friction: Time Sensitive requires an app capability and the user is asked on first receipt whether to keep allowing it (and can turn it off if a message wasn't actually time-sensitive), and Critical requires an Apple-approved entitlement plus separate user opt-in — the platform structurally resists over-claiming urgency. [apple-interruption-levels]

## SOURCES

**airbus-ecam-levels**
URL: https://pilotpulse360.com/airbus-ecam/
Accessed: 2026-07-16
Quote: "Level 3 – Warnings (Red): A failure requiring immediate action... accompanied by a continuous repetitive chime and the master warning light. Level 2 – Cautions (Amber): failures that require crew attention but not immediate action... single chime, steady amber master caution light. Level 1 – Cautions: enunciated by a caution (amber) ECAM message only (no aural warning)."

**airbus-inhibit**
URL: https://www.aviationhunt.com/airbus-a320-warnings-and-cautions/
Accessed: 2026-07-16
Quote: "the computer inhibits some warnings and cautions for certain flight phases to avoid alerting the pilots unnecessarily at times when they have high workloads (T/O & Landing)... inhibited alerts are not lost — they are simply delayed."

**ecam-wiki**
URL: https://en.wikipedia.org/wiki/Electronic_centralised_aircraft_monitor
Accessed: 2026-07-16
Quote: "dark cockpit concept, where the absence of illuminated warnings indicates that all systems are functioning normally."

**apple-interruption-levels**
URL: https://developer.apple.com/design/human-interface-guidelines/notifications
Accessed: 2026-07-16
Quote: "Passive, Active, Time Sensitive, and Critical" interruption levels; Time Sensitive requires a capability and users are prompted on first receipt and can turn it off; Critical requires an approved entitlement and separate opt-in.

**onesignal-levels**
URL: https://documentation.onesignal.com/docs/en/ios-focus-modes-and-interruption-levels
Accessed: 2026-07-16
Quote: "Passive: Low-priority notifications. No sound or vibration. They do not interrupt the user and do not break through Focus modes... Time Sensitive: Behaves like Active but includes a special banner. Time Sensitive notifications can break through Focus modes... Critical: Highest priority notifications. Bypass all device controls and Focus modes."

## SYNTHESIS

The flight-deck answer to "which window states may flash/push vs. merely indicate" is a small, fixed urgency ladder whose tiers are defined by *how fast a human must respond*, not by what the event is about. Three properties transfer directly to the terminal-workshop redesign:

1. **Response-speed tiers, not topic tiers.** Airbus's Warning/Caution/Advisory maps cleanly onto the four workshop events: *agent-blocked-on-me* = Warning (immediate, push + sound); *agent-finished* / *service-error-burst* = Caution (should be seen soon, visual + single soft cue, no repeating alarm); *long-command-done* = Advisory (drifting-parameter analog — passive pulse in the periphery, no sound); routine state = Memo/dark (silent label only). Both Airbus and Apple independently converged on ~4 levels — that is the right cardinality; more tiers are unusable, fewer can't separate "act now" from "notice eventually."

2. **Dark by default makes the periphery itself a signal.** If normal windows carry no decoration, any decorated window is meaningful with zero scanning cost. This is the anti-noise mechanism Tim wants — richness is spent only on the exception, so a lit surface never has to compete with a lit-but-fine surface.

3. **Inhibit, don't delete, during high-workload phases.** When Tim is heads-down driving one window, low-tier signals from other windows should be *held and shown on return*, not fired mid-flow and not dropped. The inhibit is phase-scoped (only while focused/working) and time-bounded (released on defocus), and only the top tier (agent-blocked) may pierce it — the flight-deck rule that takeoff/landing inhibits everything except immediate-action warnings. Apple's escalating friction on Time Sensitive/Critical is the software enforcement of the same discipline: a tier that can seize attention must be expensive to claim, or everything drifts up to it.
