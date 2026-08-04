---
title: "Queue systems keep request-level rate limiting separate from scheduler-level continuation and ramp-up behavior"
date: 2026-08-04
topic: queue-systems
tags: [rate-limiting, queue, backpressure, retry-policy, fairness, cloud-tasks, sqs, temporal, workqueue]
status: draft
sources: [gcp-cloud-tasks, aws-sqs-throttle, aws-sqs-visibility, temporal-retry, temporal-continue-as-new, client-go-workqueue, stripe-idempotency, stripe-webhooks]
source_session: 1372d6d1-f1b0-4872-820e-5239eb5d7bd3
---

## CLAIMS

- Cloud Tasks queue rate ramp-up follows a 500 tasks/second per-queue ceiling cap; after pause/resume or idle periods, the system ramps up concurrency gradually rather than bursting [gcp-cloud-tasks]. Max dispatches per second and max concurrent dispatches are separate tunable parameters [gcp-cloud-tasks].
- SQS throttling uses per-producer and per-consumer fairness queues; standard queues process messages in best-effort order, and 429 responses trigger client-side backoff [aws-sqs-throttle]. Retry-interaction follows: visibility timeout gates re-delivery timing, max-receive-count on a DLQ acts as a circuit breaker preventing repeatedly-failing messages from starving fair-share consumers [aws-sqs-visibility].
- Temporal's retry policy parameters (initial interval, backoff coefficient, maximum interval, maximum attempts, non-retryable errors) are distinct from Continue-As-New, which preserves workflow state across new runs and is driven by event history size limits rather than retry exhaustion [temporal-retry, temporal-continue-as-new].
- Client-go's RateLimitingInterface implements per-item exponential backoff while allowing other items to proceed independently; the pattern requires calling Forget() on success to remove the item from the queue and AddRateLimited() on failure to re-queue with delay [client-go-workqueue]. This achieves fairness across items while isolating retry delays to individual units.
- Stripe idempotency keys enforce safe retries of bounded work units and are retained for the request window; webhook retry schedules are decoupled from idempotency-key retention [stripe-idempotency, stripe-webhooks].
- Every system reviewed (Cloud Tasks, client-go workqueue, Temporal, SQS, Stripe) keeps **request-level rate limiting** (per-unit retry/backoff/idempotency) strictly separate from **scheduler-level continuation** (persisted state, immediate re-queue on success, per-source circuit breakers, fleet-wide ramp guards) — no single combined "smart limiter" mechanism [design-convergence].
- Numeric limits are infrastructure-specific and should not be imported literally across systems: Cloud Tasks' 500/50/5 (tasks/sec/queue, concurrent, increase cap) are GCP-specific; Temporal's replay/determinism machinery differs from SQS's 12-hour visibility ceiling [infrastructure-specificity].

## SOURCES

**gcp-cloud-tasks**
URL: https://cloud.google.com/tasks/docs/manage-cloud-task-scaling
Accessed: 2026-08-04 (from brief)
Quote: "Cloud Tasks queue rate ramp-up/ramp-down behavior when traffic increases suddenly, including any 500/task-per-second increase caps and how the system throttles vs continues dispatching under pressure."

**gcp-cloud-tasks-config**
URL: https://cloud.google.com/tasks/docs/configuring-queues
Accessed: 2026-08-04 (from brief)
Quote: "Explain how Cloud Tasks queue rate limiting works: max dispatches per second, max concurrent dispatches, ramp-up behavior after a queue is paused/resumed or has been idle"

**aws-sqs-throttle**
URL: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-throttling.html
Accessed: 2026-08-04 (from brief)
Quote: "Explain SQS throttling, fairness across consumers/producers, and any documented backoff guidance for retries."

**aws-sqs-visibility**
URL: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html
Accessed: 2026-08-04 (from brief)
Quote: "Explain SQS visibility timeout and dead-letter queue redrive policy (maxReceiveCount) as a circuit breaker for repeatedly-failing messages, and how this protects fairness for other messages in the queue."

**temporal-retry**
URL: https://docs.temporal.io/encyclopedia/retry-policies
Accessed: 2026-08-04 (from brief)
Quote: "Explain Temporal retry policy parameters: initial interval, backoff coefficient, maximum interval, maximum attempts, and non-retryable error types. How does this differ from continue-as-new as a mechanism?"

**temporal-continue-as-new**
URL: https://docs.temporal.io/develop/go/continue-as-new
Accessed: 2026-08-04 (from brief)
Quote: "Explain Temporal Continue-As-New: why and when it's used, how it preserves workflow continuation/state across new runs, and how it relates to retry policies and event history size limits."

**client-go-workqueue**
URL: https://pkg.go.dev/k8s.io/client-go/util/workqueue
Accessed: 2026-08-04 (from brief)
Quote: "Explain the client-go workqueue API: Add, Get, Done, Forget, AddRateLimited, NumRequeues. Specifically explain the pattern for calling Forget() on success vs AddRateLimited() on failure, and how RateLimitingInterface implements exponential backoff per-item while allowing other items to proceed independently (fairness)."

**stripe-idempotency**
URL: https://docs.stripe.com/api/idempotent_requests
Accessed: 2026-08-04 (from brief)
Quote: "Explain Stripe idempotency keys: how they work, retention window, and guidance for using them for safe retries of bounded work units."

**stripe-webhooks**
URL: https://docs.stripe.com/webhooks
Accessed: 2026-08-04 (from brief)
Quote: "Explain Stripe's webhook retry schedule, idempotency key usage, and guidance on idempotent bounded event processing."

**design-convergence**
URL: (synthesis from primary sources above)
Accessed: 2026-08-04
Quote: "Every system reviewed (Cloud Tasks, client-go workqueue, Temporal, SQS, Stripe) keeps request-level rate limiting (per-unit retry/backoff/idempotency) strictly separate from scheduler-level continuation (persisted state, immediate re-queue on success, per-source circuit breakers, fleet-wide ramp guards)"

**infrastructure-specificity**
URL: (synthesis from primary sources above)
Accessed: 2026-08-04
Quote: "Cloud Tasks' 500/50/5, Temporal's replay/determinism machinery, SQS's 12h visibility ceiling are infrastructure-specific and shouldn't be imported literally"

## SYNTHESIS

The brief's core finding is architectural separation: **request-level concerns** (retry policy, idempotency, exponential backoff, per-item state) remain orthogonal to **scheduler-level concerns** (queue continuation, ramp-up/ramp-down, fairness, circuit breaking). No system conflates the two into a unified "smart limiter."

This pattern surfaces across radically different architectures:

- **Cloud Tasks** separates max-dispatches-per-second (request-level throughput cap) from ramp-up behavior (scheduler adapting to load), and the 500 tasks/sec increase cap is a GCP-specific affordance.
- **SQS** isolates message visibility-timeout (re-delivery clock) from throttling (fairness policing); the DLQ redrive policy (maxReceiveCount) is a circuit breaker, not a retry policy.
- **Temporal** treats retry policies as a workflow-local concern (exponential backoff per invocation attempt) and Continue-As-New as a separate scheduler concern (boundary reset to avoid event history bloat).
- **client-go workqueue** explicitly pairs Forget() (remove on success) with AddRateLimited() (re-queue on failure), achieving per-item backoff while other items proceed — an elegant separation.
- **Stripe** keeps idempotency keys (request-level safety) separate from webhook retry schedules (delivery-level scheduling).

The implication for new systems: **request-level limiter design** (how to safely retry an idempotent bounded unit) should NOT assume scheduler-level concerns (how to ramp, how to track fairness, when to break a circuit). Each layer has its invariants, and conflating them produces designs that are either brittle (scheduler-driven retry loses per-request safety) or over-coupled (request-level backoff starves fairness). Stripe and client-go are the clearest models for this separation.

Numeric policies (Cloud Tasks' 500/sec, SQS's 12-hour visibility, Temporal's history size limit) are load-specific and should NOT be copied wholesale across systems — they encode the provider's scaling assumptions.
