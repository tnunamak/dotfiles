# Adaptive backlog recovery in multi-connector schedulers — prior art

Date: 2026-07-16. Sources accessed 2026-07-16.

## Question

What prior art usefully informs connector-neutral scheduled recovery of a
durable backlog, without importing a distributed-workflow engine or claiming
that an external queue's exact mechanics are PDPP requirements?

## Evidence reviewed

1. [Kubernetes client-go workqueue API](https://pkg.go.dev/k8s.io/client-go/util/workqueue)
2. [Kubernetes rate-limiting queue source](https://github.com/kubernetes/client-go/blob/master/util/workqueue/rate_limiting_queue.go)
3. [Google Cloud Tasks queue rate limits](https://docs.cloud.google.com/tasks/docs/configuring-queues#define_rate_limits)
4. [Google Cloud Tasks scaling-risk guidance](https://docs.cloud.google.com/tasks/docs/manage-cloud-task-scaling)
5. [Temporal Continue-As-New](https://docs.temporal.io/develop/go/workflows/continue-as-new)
6. [Amazon SQS visibility timeout](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html)

## What the sources actually establish

### Kubernetes client-go

**Evidence.** The workqueue package describes its queue as FIFO-fair and
"stingy": an item is not processed concurrently and duplicate adds before
processing coalesce. It also permits re-enqueue while processing. The
rate-limiting interface defines `AddRateLimited` as the delayed enqueue
operation. Crucially, `Forget` only clears the rate limiter's tracking and
still requires the caller to call `Done`; it does not enqueue the item.

**Correction to the earlier claim.** It is false to say that success calls
`Forget` and thereby requeues immediately. A controller may explicitly add an
item again after success, but that is controller policy, not `Forget`'s
behavior. `AddRateLimited` is the operation that requeues after the limiter's
delay.

**Design inference.** A per-connection deduplicated fair queue and tail
requeue after a productive envelope are appropriate PDPP analogies. They do
not prove a whole-burst lease or a particular continuation cap.

### Google Cloud Tasks

**Evidence.** Queue rate limits apply to both first attempts and retries, and
Cloud Tasks exposes independent maximum dispatch-rate and concurrent-dispatch
limits. Its scaling guidance warns that suddenly draining a backlog can
overload queue or target infrastructure and recommends gradual ramping for its
own high-throughput environment.

**Design inference.** A small configurable fleet-wide envelope concurrency
budget is justified as a coarse protection separate from per-source/provider
pacing. PDPP should not copy Cloud Tasks' 500/50/5 numbers or claim that Cloud
Tasks supplies its budget.

### Temporal Continue-As-New

**Evidence.** Continue-As-New closes one workflow execution, starts another in
the same chain with a fresh event history, and passes normal workflow
parameters/current state forward. Its stated use is bounding workflow history.

**Design inference.** Persisting the small state required to continue safely is
a useful principle. It is not evidence for an inline burst loop, a queue
fairness policy, or adopting Temporal's deterministic workflow machinery.

### Amazon SQS

**Evidence.** Visibility timeout prevents simultaneous processing in the usual
case, but standard queues remain at-least-once; a message can reappear after a
crash/timeout and may be delivered more than once. FIFO message groups order
their messages without an indefinite group lock.

**Design inference.** Per-envelope fencing plus idempotent durable gap work is
the relevant lesson. It supports safe interleaving/retry, not a claim that one
connection must be exclusively leased for an entire recovery burst.

## Conclusions for this change

The evidence supports four modest, separable controls:

1. Fair per-key queueing with duplicate suppression.
2. A bounded, independently configured fleet concurrency guard.
3. Durable, replay-safe continuation/debt facts rather than process-local
   assumptions.
4. Per-envelope exclusivity/fencing and idempotent work, not a burst-wide lock.

The following are design decisions, not externally established facts: exact
instance-scoped before/after eligible-gap counting, the 13-envelope cap, the
one-forward-envelope debt, typed event names, and a default concurrency budget
of two. They are chosen to preserve PDPP's live owner-run behavior while
making direct scheduled recovery safe and testable. Source-specific rate,
cooldown, backoff, and attention policy remain PDPP's existing governor
responsibility.
