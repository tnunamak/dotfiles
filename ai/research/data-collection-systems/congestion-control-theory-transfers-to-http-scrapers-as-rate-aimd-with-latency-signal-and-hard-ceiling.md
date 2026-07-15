---
title: "TCP congestion-control theory transfers to a single-provider HTTP scraper as rate-based AIMD with a latency early-signal and a hard safety ceiling, because for a consumer account 'loss' (429/ban) is expensive"
date: 2026-06-10
topic: data-collection-systems
tags: [congestion-control, aimd, tcp, bbr, vegas, http-scraping, prior-art]
status: draft
sources: [chiu-jain, jacobson, tcp-vegas, bbr, netflix-limits, aws-adaptive, farkiani-2025]
---

## CLAIMS

- Chiu & Jain (1989) proved geometrically that only additive-increase/multiplicative-decrease converges to both fairness and efficiency simultaneously; the convergence is an asymptotic attractor independent of the number of senders and their initial states. For a single sender fairness is trivially satisfied, but AIMD remains the correct law for probing an unknown ceiling from below without destructive overshoot. [chiu-jain]
- TCP Reno/CUBIC is loss-based: it must overfill the pipe (cause loss) each AIMD cycle to re-estimate the bottleneck; this is design-correct in TCP because a retransmit costs microseconds. For a consumer HTTP scraper the "loss" equivalent is a 429/silent-throttle/ban, whose cost (account suspension, session invalidation) is orders of magnitude higher — so relying on triggering 429s to estimate the ceiling is the first broken TCP assumption. [jacobson]
- TCP Vegas (Brakmo et al. 1994) uses rising RTT as an early congestion signal and backs off before a drop; BBR (Google 2016) estimates BtlBw and RTprop continuously and sets send rate to match rather than probing by overflow ("highest throughput and lowest delay when the bottleneck arrival rate equals BtlBw and inflight equals BDP"). The HTTP analogue: if a provider adds latency before issuing 429s, a latency-aware governor can back off before the hard signal. [tcp-vegas] [bbr]
- Window and rate are equivalent by Little's Law (`rate = window / RTT`) when latency is stable; TCP uses a window because network RTT is variable and ACKs self-clock the sender. For a single HTTP endpoint, RTT is dominated by roughly-constant server processing time, so rate and window carry the same information and rate control (inter-request interval) is simpler. BBR itself names `pacing_rate` as primary and uses cwnd only as a safety bound. [bbr]
- Netflix concurrency-limits is the correct model only when requests are genuinely parallel and the bottleneck is in-flight concurrency (server thread-pool exhaustion), signalled by latency increase under high concurrency (Vegas/Gradient2). [netflix-limits]
- AWS SDK adaptive mode confirms rate (not concurrency) for the single-resource case: its rate limiter controls `fill_rate` with AIMD triggered by throttling responses, and the docs state the strategy "assumes the client works against a single resource." [aws-adaptive]
- Farkiani et al. (2025, arXiv:2510.04516v3) independently reach the same conclusion: their Adaptive Token Bucket controls token generation *rate* with AIMD on 429 signals (concurrency is not a control variable) and reduces 429 errors 70-97% versus exponential backoff. [farkiani-2025]
- Retry/backoff and the rate governor are structurally separate (in TCP, retransmission and congestion control interact only through the loss signal); conflating them double-pays the wait — if a retry loop already sleeps Retry-After and the governor also applies a cooldown for the same event, backoff is paid twice. [jacobson]

## SOURCES

**chiu-jain**
URL: (Chiu & Jain 1989, "Analysis of the Increase/Decrease Algorithms for Congestion Avoidance in Computer Networks," Computer Networks and ISDN 17(1) — no URL in source)
Accessed: 2026-06-10
Quote: "foundational AIMD proof (fairness + efficiency)"

**jacobson**
URL: https://ee.lbl.gov/papers/congavoid.pdf
Accessed: 2026-06-10

**tcp-vegas**
URL: https://pages.cs.wisc.edu/~akella/CS740/F08/740-Papers/BOP94.pdf
Accessed: 2026-06-10

**bbr**
URL: https://queue.acm.org/detail.cfm?id=3022184
Accessed: 2026-06-10
Quote: "pacing_rate is BBR's primary control parameter. A secondary parameter, cwnd_gain, bounds inflight to a small multiple of the BDP to handle network and receiver pathologies."

**netflix-limits**
URL: https://netflixtechblog.medium.com/performance-under-load-3e6fa9a60581 ; https://github.com/Netflix/concurrency-limits
Accessed: 2026-06-10

**aws-adaptive**
URL: https://docs.aws.amazon.com/sdkref/latest/guide/feature-retry-behavior.html
Accessed: 2026-06-10
Quote: "the adaptive retry strategy assumes the client works against a single resource."

**farkiani-2025**
URL: https://arxiv.org/html/2510.04516v3
Accessed: 2026-06-10

## SYNTHESIS

For a single-provider HTTP scraper the correct minimal architecture is: one adaptive controller, one control variable (rate / token fill rate), AIMD dynamics (additive increase on success, multiplicative decrease on 429 or rising latency), and a hard safety ceiling. Three essential surrounding components: (1) a congestion signal — 429 as the hard signal, rising median latency vs a rolling minimum baseline as the soft/early Vegas-style signal that arrives before the ban and costs no quota; (2) a retry/backoff layer kept structurally separate from the rate governor to avoid double-paying the wait; (3) a hard ceiling that the additive increase may never exceed, because unlike TCP (where overrun costs a retransmit) a consumer account has no cheap recovery from repeated overrun.

Three TCP assumptions break for a consumer-account client: loss is *not* cheap (so don't rely on touching the ceiling to estimate it); startup overshoot is *not* recoverable (prefer linear increase from a conservative start over slow-start's binary-search doubling); and there *is* a hard policy ceiling (the provider's rate limit) that is a safety boundary, not part of the convergence dynamics. Window-vs-rate resolves to rate for sequential/low-concurrency scraping; concurrency-window control (Netflix Gradient/Vegas) is the right abstraction only for a high-parallelism pipeline where in-flight concurrency is the bottleneck. Incidental-complexity smells this diagnosis catches: dual pacing+concurrency pre-flight waits (two controllers on one variable), a fixed launch-jitter floor (a hand-tuned constant that caps throughput before AIMD can find the real ceiling), and a self-terminating recovery exit living in the rate governor instead of the retry layer.
