---
title: "Interruptions carry a measured resumption-lag and stress cost, so mature interruption design defers non-urgent signals to natural task breakpoints within a bounded delay (bounded deferral) and keeps ambient status in the periphery — interrupting mid-task is the expensive default to avoid"
date: 2026-07-16
topic: session-ux
tags: [interruption-science, resumption-lag, bounded-deferral, breakpoints, calm-technology, notification-defaults, attention-cost]
status: draft
sources: [mark-chi08, mark-fragmentation, horvitz-bounded-deferral, iqbal-oasis-breakpoints, calm-tech-case, slack-rebuild, gitnotifier-routing]
source_session: unknown
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation/conclusions. Skippable.
-->

## CLAIMS

- Interruption is measurably costly: Gloria Mark's controlled study found interrupted work is rated significantly higher in stress (p<.001), frustration (p<.01), and workload than non-interrupted work, and people compensate by working faster — which produces the stress/error cost, not a productivity gain. [mark-chi08]
- The popularized "~23 min 15 s to resume interrupted work" figure traces to Mark's interviews rather than a single peer-reviewed headline result; the lab papers report the effect direction (higher stress/effort, faster/altered work) robustly, so the *existence* of a large resumption cost is well-grounded even where the exact minutes are soft. [mark-chi08]
- Knowledge work is already heavily fragmented at baseline: workers averaged ~12 working spheres/day and switched spheres about every ~10.5 minutes — so each externally-imposed interrupt lands on top of an already-thin attention span. [mark-fragmentation]
- Bounded deferral (Horvitz et al., Microsoft Research) is the canonical remedy: defer an incoming alert for a *bounded* time when the user is busy, trading a small, capped delay in awareness for a large reduction in disruption — "balancing awareness about potentially urgent information with the cost of interruption." [horvitz-bounded-deferral]
- Delivering a notification at a task *breakpoint* (a natural pause in the user's activity) rather than mid-task measurably reduces frustration and reaction time; the OASIS/breakpoint line of work links delivery to the perceptual structure of the task. [iqbal-oasis-breakpoints]
- Calm technology (Amber Case, building on Weiser & Brown) prescribes: require the smallest possible amount of attention; use the periphery (a signal that stays peripheral until it matters, like a car engine you notice only when it changes); communicate without needing to "speak"; work even when it fails; and use the minimum technology that solves the problem. [calm-tech-case]
- Slack's 2026 notification rebuild found the noise problem was structural, not user error, and fixed it by *simplifying defaults*: replacing four preference paradigms with three (all / mentions / mute); the vast majority of users adopted the quieter "mentions and DMs" default, per-channel override usage fell, and support tickets dropped. [slack-rebuild]
- Cross-tool practitioner consensus (GitHub/Linear/Slack) reframes overload as a design failure and prescribes routing by *role/action-needed*, not by membership: the person who must act gets a direct signal, watchers get nothing, and broadcast-to-a-channel-when-one-person-must-act is named an anti-pattern. [gitnotifier-routing]

## SOURCES

**mark-chi08**
URL: https://ics.uci.edu/~gmark/chi08-mark.pdf
Accessed: 2026-07-16
Quote: "interruptions by working faster, but this comes at a price: experiencing more stress, higher frustration, time pressure and effort... stress was rated as significantly different across interruption type (F(2,92)=12.15, p<.001) and was highest for both interruption conditions."

**mark-fragmentation**
URL: https://ics.uci.edu/~gmark/chi08-mark.pdf
Accessed: 2026-07-16
Quote: "Each person worked on an average of 12.2 different working spheres every day, and they switched working spheres, on average, every 10 minutes and 29 seconds." (reported across Mark's UC Irvine fragmentation studies)

**horvitz-bounded-deferral**
URL: https://erichorvitz.com/bdef_studies.htm
Accessed: 2026-07-16
Quote: "bounded deferral is a method aimed at reducing the disruptiveness of incoming messages and alerts in return for bounded delays in receiving information... a means for balancing awareness about potentially urgent information with the cost of interruption."

**iqbal-oasis-breakpoints**
URL: https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/TOCHI-Oasis-final.pdf
Accessed: 2026-07-16
Quote: "notifications are deferred for a short time in exchange for a meaningful reduction in the ensuing interruption cost, achieved by linking notification delivery to the perceptual structure of user tasks."

**calm-tech-case**
URL: https://www.caseorganic.com/post/principles-of-calm-technology
Accessed: 2026-07-16
Quote: "Technology should require the smallest possible amount of attention... Technology should make use of the periphery... Technology can communicate, but doesn't need to speak... Technology should work even when it fails... The right amount of technology is the minimum needed to solve the problem."

**slack-rebuild**
URL: https://slack.engineering/how-slack-rebuilt-notifications/
Accessed: 2026-07-16
Quote: "the noise problem wasn't just about volume—it was baked into the architecture itself... the new system replaces four legacy preference paradigms with a simplified model centered on three options: all messages, mentions, or mute."

**gitnotifier-routing**
URL: https://www.gitnotifier.com/blog/github-linear-slack-notification-overload
Accessed: 2026-07-16
Quote: "that is not a focus problem—it is a notification design problem... a better pattern is personal routing... route alerts by role, not by repository or project membership."

## SYNTHESIS

This entry supplies the *when* and *how-delivered* to complement the *what-tier* (aviation) and *how-much* (alarm budget) entries. The science says interrupting Tim mid-task is the expensive default — it costs measurable stress and a resumption lag on top of an attention span already fragmented to ~10-minute spheres. So the delivery policy:

1. **Bounded deferral is the core mechanism.** Non-top-tier signals (agent-finished, service-error that isn't crash-looping, command-done) should NOT fire the instant they occur. Hold them and release at the next natural breakpoint — Tim defocuses a window, submits a prompt, a command he's watching completes — capped by a bounded max delay so awareness is never lost, only smoothed. This is the software-notification form of the aviation phase-inhibit: hold low tiers while heads-down, flush on the pause. Only agent-blocked (the immediate-action tier) pierces the deferral, because it is on Tim's critical path — the workshop is idle waiting for him, so deferring it wastes wall-clock, exactly the one case where interrupt-cost is worth paying.

2. **Periphery is the resting state; center is earned.** Per calm tech, the default surface for every window state is a peripheral indicator (a colored tab, a count, a dim glyph) that Tim can pull at will and that never speaks. A signal moves to the center (flash/push/sound) only for the earned top tier, then moves back. "Communicate without speaking" is the license to make agent-finished a silent visual state-change, not a ping.

3. **Route by action-needed, not by source — and enforce it with a quiet default.** Slack's and the cross-tool consensus both say: the win comes from *simpler, quieter defaults*, and from routing a signal only to the person who must act. For a single-operator workshop that means: a window generates an attention signal only when *Tim* is the required actor (agent-blocked-on-him, his long command done), and everything a subsystem can resolve itself (agent still working, transient error being retried) stays ambient. The default posture is the quiet one; loud is the opt-in exception the top tier claims. Slack's data — most users keep the quiet default, override usage falls, tickets drop — is direct evidence that a well-chosen quiet default beats giving the user more knobs.
