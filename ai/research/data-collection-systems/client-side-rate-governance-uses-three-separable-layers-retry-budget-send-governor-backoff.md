---
title: "Mature client-side rate governance uses three separable layers — retry budget, one send governor (rate OR concurrency), and backoff — and never stacks two send governors on one upstream"
date: 2026-06-10
topic: data-collection-systems
tags: [rate-limiting, congestion-control, aimd, gcra, backoff, prior-art]
status: draft
sources: [aws-adaptive, netflix-concurrency, envoy-adaptive, google-sre, scrapy-autothrottle, gcra, finagle, temporal-worker]
---

## CLAIMS

- AWS SDK adaptive retry mode adds a client-side rate limiter (a TCP-CUBIC variant) on top of standard backoff; on any throttling response it sets `fill_rate = measured_tx_rate × 0.7` (multiplicative decrease) and grows via a CUBIC curve between throttles; the rate limiter is driven by error frequency (429/throttling codes), not latency, and gates both initial requests and retries per SDK client instance. [aws-adaptive]
- AWS explicitly recommends adaptive mode only when a client targets a single resource at high volume; a single rate limiter shared across unrelated resources over-throttles the healthy ones when one is throttled. [aws-adaptive]
- Netflix concurrency-limits ports TCP congestion control to limit in-flight concurrency (not rate): Vegas estimates queue depth `L × (1 − minRTT/sampleRTT)`; Gradient2 tracks divergence of short- vs long-window RTT EMAs. Concurrency limits are self-calibrating (limit falls automatically as latency rises) whereas rate limits need the right number known upfront. [netflix-concurrency]
- Envoy's adaptive concurrency filter implements the Netflix Gradient algorithm (`gradient = (minRTT + buffer)/sampleRTT`, `limit_new = gradient × limit_old + sqrt(limit_old)`), periodically re-measuring minRTT at reduced concurrency; it is latency-driven and needs no server-side quota config. [envoy-adaptive]
- Google SRE Book Ch. 21 client-side throttling is rejection-driven: over a 2-minute window it drops requests locally with `P(drop) = max(0, (requests − K × accepts)/(requests + 1))`, K≈2, so the client only begins dropping after ~50% rejection; requires knowing which responses are quota rejections, not latency. [google-sre]
- Scrapy AutoThrottle (the polite-scraping analog) computes `target_delay = response_latency / AUTOTHROTTLE_TARGET_CONCURRENCY` then EMAs `new_delay = (prev_delay + target_delay)/2`; non-200 responses are treated as slow so their latency does not shorten the delay, biasing toward caution on errors; it paces while a separate `CONCURRENT_REQUESTS_PER_DOMAIN` caps concurrency. [scrapy-autothrottle]
- GCRA (ITU-T I.371) tracks a Theoretical Arrival Time; during idle gaps TAT resets to `t_a + I` rather than accumulating credit unboundedly, preventing a paused client from bursting hours×rate on resume. It is a smoothing primitive for a known quota, not a discovery primitive — layer AIMD on top when the quota is unknown. [gcra]
- Finagle's RetryBudget caps total retries at ~20% of requests plus a 10/s floor, replenished at 0.2× the request rate; it is a budget (whether to retry), orthogonal to backoff (when to retry), preventing retry storms. [finagle]
- Temporal documents the double-constraint anti-pattern: setting both a concurrency limit and a rate limit (`maxWorkerActivitiesPerSecond`) lower than the concurrency permits makes the rate limiter the silent binding constraint (underutilized workers, high schedule_to_start latency). [temporal-worker]

## SOURCES

**aws-adaptive**
URL: https://docs.aws.amazon.com/sdkref/latest/guide/feature-retry-behavior.html
Accessed: 2026-06-10

**netflix-concurrency**
URL: https://github.com/Netflix/concurrency-limits
Accessed: 2026-06-10

**envoy-adaptive**
URL: https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/adaptive_concurrency_filter
Accessed: 2026-06-10

**google-sre**
URL: https://sre.google/sre-book/handling-overload/
Accessed: 2026-06-10

**scrapy-autothrottle**
URL: https://docs.scrapy.org/en/latest/topics/autothrottle.html
Accessed: 2026-06-10

**gcra**
URL: https://brandur.org/rate-limiting ; https://konghq.com/blog/engineering/how-to-design-a-scalable-rate-limiting-algorithm
Accessed: 2026-06-10

**finagle**
URL: https://github.com/twitter/finagle/blob/develop/doc/src/sphinx/Clients.rst
Accessed: 2026-06-10

**temporal-worker**
URL: https://docs.temporal.io/dev-guide/worker-performance
Accessed: 2026-06-10

## SYNTHESIS

A consistent three-layer model emerges across every surveyed system. Layer 1 — retry budget (count): max retries as a fraction of requests (Finagle 20% + floor), gating *whether* to retry, orthogonal to rate/concurrency. Layer 2 — send governor: either a rate governor (GCRA/token-bucket + AIMD, AWS CUBIC; responds to error codes) OR a concurrency governor (Netflix Gradient/Vegas, Envoy; responds to latency) — pick one primary per upstream, and if you truly need both, derive one from the other. Layer 3 — retry backoff (delay): exponential + jitter or Retry-After, applied *after* a failed send when scheduling the retry, which then re-enters Layer 2.

Transferable rules: (1) separate layers by signal type — rate governors react to 429/quota, concurrency governors react to RTT; (2) retries must pass through the same send gate as originals or you get retry storms; (3) prevent double-delay by lifecycle separation — pacing gate fires *before* a send, backoff fires *after* a failure, so their delays are additive not multiplicative; the dangerous pattern is applying both in the same wait loop; (4) conservative start, signal-driven ascent; (5) non-200 latency must not shorten the pacing delay; (6) isolate rate state per upstream/domain; (7) concurrency limits are self-calibrating while rate limits need a known quota or an AIMD outer loop; (8) never deploy two independent send governors over one upstream — ensure any rate ceiling sits at or above the throughput the concurrency limit naturally produces, or one becomes dead code and confusion. The clean composition when both a concurrency signal and a rate gate exist: one pre-flight gate (GCRA), two signal inputs (AIMD adjusts the GCRA fill rate; concurrency is an input to that adjustment, not a second blocking gate).
