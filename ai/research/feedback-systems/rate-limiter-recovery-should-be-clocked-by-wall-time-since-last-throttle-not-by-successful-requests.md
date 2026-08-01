---
title: "Client-side rate-limiter recovery clocked by successful requests is the classic self-clocked/ACK-clocked slow-recovery anti-pattern; CUBIC, the AWS SDK adaptive limiter, and BBR all fix it by clocking recovery on wall-time since the last throttle, not on request cadence"
date: 2026-06-12
topic: feedback-systems
tags: [rate-limiting, aimd, cubic, bbr, aws-sdk, congestion-control, backoff, recovery-dynamics]
status: draft
sources: [chiu-jain-summary, aimd-wikipedia, aimd-fc, variable-structure, aimd-lecture, abc-paper, mimd-fairness, cubic-wikipedia, rfc9438, cubic-paper, aws-adaptive-commit, aws-retry-docs, aws-retry-blog, bbr-acmqueue, bbr-ietf]
source_session: 019f4e32-3eea-7e93-8dc2-25f9cdde137d
---

## CLAIMS

- Chiu & Jain (1989) prove AIMD is necessary and sufficient to converge to an efficient AND fair operating point regardless of initial state, but the proof is an existence result about the fixed point and the signs of the operators (increase additive, decrease multiplicative) — it says nothing about recovery/transient time, and its model is N competing flows sharing one bottleneck (fairness is the whole reason additive increase is mandatory). [chiu-jain-summary][aimd-wikipedia][aimd-lecture]
- Follow-up work (AIMD-FC "fast convergence," variable-structure-control reformulations) exists precisely to speed convergence/responsiveness while preserving the Chiu-Jain fixed point, confirming recovery speed is an open tuning dimension orthogonal to the convergence proof. [aimd-fc][variable-structure]
- Pure MIMD (multiplicative increase) does not converge to fairness — it preserves the ratio between flows — which is why TCP uses additive increase; but MAIMD (multiplicative-and-additive increase / multiplicative decrease) does converge to fairness (Chiu & Jain proved this; it is the design basis of MIT's ABC controller, which adds an additive-increase component to its MIMD base for exactly this reason). [mimd-fairness][abc-paper][aimd-wikipedia]
- In an N=1 regime (single client vs one provider) the fairness constraint that mandates additive-only increase does not apply — there is no second flow whose ratio could be preserved — so the increase shape is free to optimize for responsiveness without a convergence penalty. [abc-paper][aimd-wikipedia]
- TCP CUBIC does not rely on the cadence of RTTs/ACKs to grow the window; window size is a cubic function of wall-clock time since the last congestion event, `W(t) = C·(t − K)³ + W_max` with `K = ∛(W_max·(1−β)/C)` and β=0.7, updated on a real-time schedule — so a flow with slow ACKs still recovers on the real-time clock (fast concave snap-back, plateau, cautious convex probe). [cubic-wikipedia][rfc9438][cubic-paper]
- The AWS SDK adaptive-retry `DefaultRateLimiter` recovers via `_CUBICSuccess(time())` — `calculatedRate = scaleConstant·(timestamp − lastThrottleTime − timeWindow)³ + lastMaxRate` — depending only on wall-clock since the last throttle, not on how many requests succeeded; the pacing wait is a separate token bucket whose fill_rate is set by the CUBIC curve (recovery clock decoupled from send clock); and the limiter is dormant until the first throttle, so there is no steady-state tax when the provider is not pushing back. [aws-adaptive-commit][aws-retry-docs][aws-retry-blog]
- BBR transmits based on a clock, not ACKs, sets pacing_rate from a measured bottleneck-bandwidth model rather than per-ACK ratcheting, and does not treat a single loss as a multiplicative cut (loss is not its primary signal). [bbr-acmqueue][bbr-ietf]
- Recovery whose cadence is bounded by the (degraded) rate being recovered is the canonical ACK-clocked / self-clocked slow-recovery anti-pattern: after a deep multiplicative cut, "one increase per RTT/success" makes recovery time scale with the very RTT/interval that the loss inflated. [cubic-wikipedia][bbr-acmqueue]

## SOURCES

**chiu-jain-summary**
URL: https://people.eecs.berkeley.edu/~fox/summaries/networks/chiu_jain
Accessed: 2026-06-12

**aimd-wikipedia**
URL: https://en.wikipedia.org/wiki/Additive_increase/multiplicative_decrease
Accessed: 2026-06-12

**aimd-fc**
URL: https://www.worldscientific.com/doi/10.1142/9789812776730_0041
Accessed: 2026-06-12

**variable-structure**
URL: https://www.sciencedirect.com/science/article/abs/pii/S0005109812001239
Accessed: 2026-06-12

**aimd-lecture**
URL: https://anirudhsk.github.io/teaching/lectures/lec7.pdf
Accessed: 2026-06-12

**abc-paper**
URL: https://arxiv.org/pdf/1905.03429
Accessed: 2026-06-12
Quote: "To achieve fairness, we add an additive-increase component… MAIMD… Chiu and Jain proved… converge to fairness"

**mimd-fairness**
URL: https://www.researchgate.net/publication/4165567_Fairness_in_MIMD_congestion_control_algorithms
Accessed: 2026-06-12

**cubic-wikipedia**
URL: https://en.wikipedia.org/wiki/CUBIC_TCP
Accessed: 2026-06-12

**rfc9438**
URL: https://www.rfc-editor.org/rfc/rfc9438.html
Accessed: 2026-06-12

**cubic-paper**
URL: https://www.cs.princeton.edu/courses/archive/fall16/cos561/papers/Cubic08.pdf
Accessed: 2026-06-12

**aws-adaptive-commit**
URL: https://github.com/aws/aws-sdk-js-v3/commit/8ef104d00eac33cf1a94c54e2daa2d1bff89a0a4
Accessed: 2026-06-12

**aws-retry-docs**
URL: https://docs.aws.amazon.com/sdkref/latest/guide/feature-retry-behavior.html
Accessed: 2026-06-12

**aws-retry-blog**
URL: https://aws.amazon.com/blogs/developer/announcing-updated-retry-behavior-for-aws-sdks-and-tools/
Accessed: 2026-06-12

**bbr-acmqueue**
URL: https://queue.acm.org/detail.cfm?id=3022184
Accessed: 2026-06-12

**bbr-ietf**
URL: https://datatracker.ietf.org/doc/html/draft-cardwell-iccrg-bbr-congestion-control-02
Accessed: 2026-06-12

## SYNTHESIS

When a single client paces itself against a provider that throttles sporadically (429s), the failure mode of "recovery clocked by successes, each success costing one inflated interval" is structural, not a constants problem: the decrease side is event-clocked and cheap (a 429 multiplies the interval instantly, in zero of your own time), while the increase side is self-clocked and expensive (each recovery step costs one full inflated interval, so you pay for recovery in the inflated currency you're trying to escape). No setting of a per-success gain removes the "≥ one inflated interval per recovery step" floor, and cranking the gain toward a per-step multiply pushes you into MIMD-shaped jumps. The fix all three reference systems use is to decouple the recovery cadence from the degraded transport rate: CUBIC and the AWS adaptive limiter via a time-since-last-throttle recovery curve (the load-bearing half is the `time()` argument, not the distance-proportional step shape); BBR via a clock-paced measured-rate model with loss de-emphasized. Practical recommendations: (A) make the interval a function of `now − lastThrottleTime`, recovered on a wall-clock schedule regardless of how many requests complete; and (C) gate adoption of a slower *sustained* rate on throttle *density* (as AWS measures throttled-vs-non-throttled rate) so one stray 429 against a mostly-idle account is a brief blip, not a multi-minute ×4-10 tax. The MAIMD/N=1 reasoning above frees you to pick any responsive increase shape without a convergence penalty.
