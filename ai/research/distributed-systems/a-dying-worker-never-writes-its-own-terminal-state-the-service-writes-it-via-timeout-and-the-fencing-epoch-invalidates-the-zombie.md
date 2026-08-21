---
title: "A dying worker never writes its own terminal state: Temporal's service writes it via timeout expiry (the timeout IS the terminal state) and Kafka's transaction coordinator aborts via transaction.timeout.ms or the next InitProducerId epoch bump — both systems then downgrade the guarantee to at-least-once execution plus idempotency"
date: 2026-08-21
topic: distributed-systems
tags: [temporal, kafka, exactly-once, kip-98, kip-447, terminal-states, heartbeat, fencing-tokens, producer-epoch, graceful-shutdown, interrupted-work, prior-art]
status: draft
sources: [temporal-activity-failures, temporal-workflow-status, temporal-activity-definition, temporal-workflow-failures, sdk-go-activity, sdk-go-activity-pkg, sdk-go-worker-base, sdk-go-internal-worker, sdk-go-worker-pkg, kafka-design, kip-98, kip-447]
source_session: af82d1f3-1838-4307-a3a9-6bbf07e77c6f
---

<!--
Scope note: this entry answers WHO WRITES THE TERMINAL STATE when the owning process
dies mid-flight. It deliberately does NOT re-derive the layered bounding model in
`bounding-a-hung-job-uses-heartbeat-plus-wall-clock-timeout-a-startup-reaper-and-fencing-tokens.md`
(2026-06-14), which covers heartbeat-vs-wall-clock timeout selection, startup reapers,
and Kleppmann fencing tokens across Sidekiq/k8s/Step Functions/Celery/GoodJob. That entry
treats heartbeat as a DETECTION mechanism; this one establishes the stronger structural
claim that detection expiry is itself the durably-recorded outcome, and adds the Kafka
EOS half (KIP-98/KIP-447 epoch fencing) which the earlier entry does not touch.
-->

## CLAIMS

### A. Temporal — terminal states and who writes them

- A Temporal Workflow Execution has exactly two Open statuses (Running, Paused) and six Closed statuses: Completed, Failed, Canceled, Terminated, Continued-As-New, and Timed Out. An Open status means the execution "can still make progress"; a Closed status means it cannot proceed further. [temporal-workflow-status]
- **The Temporal Server does not detect worker crashes.** The docs state it directly: "The Temporal Server doesn't detect failures when a Worker loses communication with the Server or crashes. Therefore, the Temporal Server relies on the Start-To-Close Timeout to force Activity retries." The same sentence appears in the Go SDK's `ActivityOptions.StartToCloseTimeout` doc comment. [temporal-activity-failures] [sdk-go-activity]
- **CONFIRMED — the load-bearing claim.** When a worker dies mid-activity, the activity lands in TimedOut, and the *service* writes it: the server records an `ActivityTaskTimedOut` event on timeout expiry and, if a Retry Policy applies, "the Temporal Service schedules another Activity Task." The dying worker writes nothing. The timeout expiring IS the terminal transition — there is no separate crash-detection channel. [temporal-activity-failures]
- The corollary that makes this airtight: "Activities won't record to the Event History until they return or produce an error. If an Activity fails to report to the server at all, it will be retried." Silence is not a state; only a service-side timer converts silence into a recorded outcome. [temporal-activity-definition]
- The three activity timeouts are orthogonal and answer different questions. ScheduleToStart bounds Task Queue → worker pickup ("detects individual worker crashes or task queue backlogs"); it is **non-retryable by design** — "It does not trigger any retries regardless of the Retry Policy." StartToClose bounds a single Activity Task Execution attempt (the hard per-attempt ceiling, and the crash backstop). ScheduleToClose bounds the entire Activity Execution "from when the first Activity Task is scheduled to when the last Activity Task reaches a Closed status" — i.e. across all retries. ScheduleToStart and ScheduleToClose both default to infinity. [temporal-activity-failures] [sdk-go-activity]
- HeartbeatTimeout is a *faster* crash detector layered on StartToClose, not a replacement: "A Heartbeat Timeout is the maximum time between Activity Heartbeats. If this timeout is reached, the Activity Task fails and a retry occurs if a Retry Policy dictates it." A heartbeat is defined as a ping that "informs the Temporal Service that the Activity Execution is making progress and the Worker has not crashed." [temporal-activity-failures]
- Cancellation is *pull-based through the heartbeat channel*: "Activity Cancellations are delivered to Activities from the Temporal Service when they Heartbeat." An activity that never heartbeats therefore cannot observe cancellation. In the Go SDK the delivery mechanism is context cancellation: `RecordHeartbeat` — "If the activity is either canceled or the workflow/activity doesn't exist, then we would cancel the context with error [context.Canceled]." [temporal-activity-failures] [sdk-go-activity-pkg]
- Heartbeat details are the resume checkpoint, and they are delivered *only on the retry path*: "If there were heartbeat details reported by activity from the failed attempt, the details would be delivered along with the activity task for the retry attempt." The Go API is explicitly framed around the *last failed attempt* — `GetHeartbeatDetails` "extracts heartbeat details from the last failed attempt. This is used in combination with the retry policy," and `HasHeartbeatDetails` "checks if there are heartbeat details from the last attempt." [sdk-go-activity] [sdk-go-activity-pkg]
- **Heartbeat throttling caveat — the checkpoint you read back is older than the one you wrote.** The worker does not forward every heartbeat: it throttles to the smaller of (`heartbeatTimeout * 0.8`, else `defaultHeartbeatThrottleInterval` = 30s) and `maxHeartbeatThrottleInterval` = 60s. During a throttle window "The Worker stops sending Heartbeats, but continues receiving Heartbeats from the Activity and remembers the most recent one." So resume-from-heartbeat can rewind by up to a throttle interval of work. The one exception: "Throttling does not apply to the final Heartbeat message in the case of Activity Failure." [temporal-activity-failures]
- Heartbeat details are also surfaced on the timeout error itself: RecordActivityHeartbeat's `details` "can be seen in the workflow when it receives TimeoutError." [sdk-go-activity]

### B. Temporal — graceful shutdown

- `WorkerStopTimeout` is a *grace period before forced termination*, not a promise to finish. The Go SDK source comment is blunt: "WorkerStopTimeout is the time delay before hard terminate worker." Its **default is 0s** — i.e. by default Temporal does *not* wait for in-flight activities at all. [sdk-go-internal-worker] [sdk-go-worker-pkg]
- The mechanism is a bounded WaitGroup await, and exceeding it is logged, not escalated. `baseWorker.Stop()`: "Wait for pollers, task dispatch, and task processing to complete, or until stopTimeout elapses" via `awaitWaitGroup(&bw.stopWG, bw.options.stopTimeout)`; on failure it logs "Worker graceful stop timed out." then cancels the background context with `ErrWorkerShutdown` and returns. An activity still running past the timeout is simply abandoned by the worker — which lands it back in case A above (the service times it out and retries it elsewhere). [sdk-go-worker-base]
- `Stop()` "is a blocking call and cleans up all the resources associated with worker" and per the public API "may panic if called a second time." `worker.Run()` blocks and stops on an interrupt channel; `InterruptCh()` "returns channel which will get data when system receives interrupt signal from OS." [sdk-go-worker-base] [sdk-go-worker-pkg]

### C. Temporal — the actual guarantee

- **The exact guarantee language, which is narrower than "exactly once" and broader than "at least once":** "For an Activity with a Retry Policy that allows retries, Temporal guarantees that the Activity will be observed as completed exactly once. However, the Activity may be executed multiple times and may even partially complete more than once during this process." Exactly-once is a property of the *observed workflow history*, not of side effects. [temporal-activity-definition]
- Temporal therefore *recommends* rather than guarantees idempotency: "Temporal recommends that Activities be idempotent." An Activity "is idempotent if multiple Activity Task Executions do not change the state of the system beyond the first Activity Task Execution." The recommended idempotency key is the Workflow Run ID + Activity ID combination, "since this is guaranteed to be consistent across retry attempts but unique among Workflow Executions." [temporal-activity-definition]
- Worker crash mid-*Workflow* Task is handled by the same service-side-timer shape but does **not** produce a terminal workflow state: Workflow Task Timeout is "the maximum amount of time allowed for a Worker to execute a Workflow Task after the Worker has pulled that Workflow Task from the Task Queue" and is "primarily available to recognize whether a Worker has gone down so that the Workflow Execution can be recovered on a different Worker." The workflow stays Running and is retried on another worker — a failed Workflow Task does not fail the Workflow. [temporal-workflow-failures]
- **Ambiguity flag.** Temporal's docs distinguish "Activity Execution" (the logical unit, which has Closed status) from "Activity Task Execution" (one attempt). Timeouts fire on different levels — StartToClose/Heartbeat kill an *attempt*, ScheduleToClose closes the *execution* — so "the activity timed out" is ambiguous without naming the level. The retry-vs-terminal distinction lives entirely in the Retry Policy: a StartToClose timeout is a terminal state for the attempt but merely an intermediate event for the execution.

### D. Kafka — KIP-98 commit boundary and zombie fencing

- The commit-boundary problem statement is an *atomicity across two logs* problem: a consume-transform-produce pipeline writes its output to topic partitions and its input offset to the internal offsets topic, and "a set of messages may be considered consumed only if the entire 'consume-transform-produce' executed in its entirety." Idempotence alone cannot solve it because "idempotent producers don't provide guarantees for writes across multiple TopicPartitions. For this, one needs stronger transactional guarantees." KIP-98's answer is to fold the offset commit into the producer transaction via `sendOffsetsToTransaction`. [kip-98]
- Kafka's own design docs describe the same trick from the consumer side: "The consumer's position is stored as a message in an internal topic, so we can write the offset to Kafka in the same transaction as the output topics receiving the processed data." [kafka-design]
- **The zombie fence is a fencing-token mechanism keyed on `transactional.id`.** The invariant is "Exactly one active producer with a given TransactionalId. This is achieved by fencing off old generations when a new instance with the same TransactionalId comes online." `InitPidRequest` / `InitProducerId` does two things atomically: it "Bumps up the epoch of the PID, so that the any previous zombie instance of the producer is fenced off and cannot move forward with its transaction," and it "Recovers (rolls forward or rolls back) any transaction left incomplete by the previous instance of the producer." [kip-98]
- Kafka's design docs confirm the epoch bump is triggered by ordinary application restart, with no operator action: setting `transactional.id` "configures the producer for transactional delivery and also makes sure that a restarted application causes any in-flight transaction from the previous instance to abort." [kafka-design]
- The idempotent-producer layer underneath is a per-(producer-ID, partition) sequence-number dedupe: "the broker assigns each producer an ID and deduplicates messages using a sequence number that is sent by the producer along with every message." [kafka-design]

### E. Kafka — who aborts a dead producer's transaction, and when

- **Two independent reapers, and neither is the dying producer.** (1) Time-based, by the coordinator: `transaction.timeout.ms` is "The maximum amount of time in ms that the transaction coordinator will wait for a transaction status update from the producer before proactively aborting the ongoing transaction" (default 60s). (2) Event-based, by the successor: the next `InitProducerId` for that `transactional.id` bumps the epoch and rolls the orphaned transaction forward or back. A producer that dies mid-transaction leaves records that are never made visible to `read_committed` consumers in the interim. [kip-98] [kafka-design]
- This is the direct structural analogue of Temporal's model: the crashed participant writes no terminal state; a durable third party (transaction coordinator / Temporal Service) converts silence into a recorded outcome on a timer, with a fencing epoch ensuring a resurrected zombie cannot later contradict it.
- Transaction outcome is materialized as data, not just metadata: "Any records written by the transactional producer will be marked as being part of the transactions, and then when the transaction commits or aborts, transaction marker records are written to indicate the outcome of the transaction. This is how the read-committed consumer does not see records from aborted transactions." [kafka-design]
- Abort does **not** auto-rewind the consumer: "in the event of a transaction abort, the application's state and in particular the current position of the consumer must be reset explicitly so that it can reprocess the records processed by the aborted transaction." The design doc repeats this caveat — on abort the stored position reverts "although the consumer has to refetch the committed offset because it does not automatically rewind." Recovery is partly the application's job. [kafka-design]

### F. Kafka — KIP-447 and the honest scope of "exactly once"

- KIP-98's fencing was keyed only on `transactional.id`, which forced a producer-per-input-partition topology to stay safe across rebalances. The cost was structural: "Every producer come with separate memory buffers, a separate thread, separate network connections," which means "we cannot effectively use the output of multiple tasks to improve batching" and creates "unneeded load on brokers since there are more concurrent transactions and more redundant metadata management." [kip-447]
- KIP-447 moves the fence from the transaction coordinator to the *group* coordinator by passing `ConsumerGroupMetadata` (generation ID, member ID, group instance ID) into `sendOffsetsToTransaction` — "Sends a list of specified offsets to the consumer group coordinator, and also marks those offsets as part of the current transaction." Fencing then rides on the consumer group generation: "If one of the field is not matching correctly on server side, the client will be fenced immediately." A producer holding a stale generation after a rebalance is rejected, so one producer can safely serve many input partitions. [kip-447]
- Kafka's design docs still recommend the KIP-98-era topology as the default: "In order to handle transactions properly in combination with rebalancing, it is advisable to use one producer instance for each consumer instance. More complicated and efficient schemes are possible, but at the cost of greater complexity." The KIP-447 path is enabled in the reference tool only behind `--use-group-metadata`. **Flag:** the docs and the KIP disagree in emphasis — KIP-447 exists precisely to remove the producer-per-consumer constraint, but the mainline docs have not been rewritten to lead with it. [kafka-design] [kip-447]
- **Kafka does NOT claim end-to-end exactly-once.** It scopes the claim to the Kafka boundary: "Kafka supports exactly-once delivery in Kafka Streams, and the transactional producer and the consumer using read-committed isolation level can be used generally to provide exactly-once delivery when reading, processing and writing data on Kafka topics. Exactly-once delivery for other destination systems generally requires cooperation with such systems, but Kafka provides the primitives which makes implementing this feasible." The default is weaker still: "Otherwise, Kafka guarantees at-least-once delivery by default." [kafka-design]
- Kafka explicitly calls out vendors who overclaim — a useful piece of framing: "Many systems claim to provide 'exactly-once' delivery semantics, but it is important to read the fine print, because sometimes these claims are misleading (i.e. they don't translate to the case where consumers or producers can fail, cases where there are multiple consumer processes, or cases where data written to disk can be lost)." [kafka-design]
- The recommended pattern for external sinks is to **collapse the two commit points into one**, not to attempt distributed commit: "The classic way of achieving this would be to introduce a two-phase commit between the storage of the consumer position and the storage of the consumers output. This can be handled more simply and generally by letting the consumer store its offset in the same place as its output. This is better because many of the output systems a consumer might want to write to will not support a two-phase commit." Kafka Connect's HDFS connector is cited as the reference implementation of this. [kafka-design]
- **Ambiguity flag.** KIP-98 concedes the consumer side is weaker than the producer side — "the guarantees are a bit weaker" — because log compaction, segment deletion, consumer `seek`, and consuming only a subset of a transaction's partitions all break atomic *consumption* of a committed transaction. Atomicity is guaranteed for the write, not for any particular read. [kip-98]

## SOURCES

**temporal-activity-failures**
URL: https://docs.temporal.io/encyclopedia/detecting-activity-failures
Accessed: 2026-08-21
Quote: "The Temporal Server doesn't detect failures when a Worker loses communication with the Server or crashes. Therefore, the Temporal Server relies on the Start-To-Close Timeout to force Activity retries." / "An Activity Heartbeat is a ping from the Worker that is executing the Activity to the Temporal Service. Each ping informs the Temporal Service that the Activity Execution is making progress and the Worker has not crashed." / "Activity Cancellations are delivered to Activities from the Temporal Service when they Heartbeat." / "Throttling does not apply to the final Heartbeat message in the case of Activity Failure." / "This timeout is non-retryable by design. It does not trigger any retries regardless of the Retry Policy."

**temporal-workflow-status**
URL: https://docs.temporal.io/workflow-execution
Accessed: 2026-08-21
Quote: Open: "Running", "Paused". Closed: "Cancelled", "Completed", "Continued-As-New", "Failed", "Terminated", "Timed Out".

**temporal-activity-definition**
URL: https://docs.temporal.io/activity-definition
Accessed: 2026-08-21
Quote: "For an Activity with a Retry Policy that allows retries, Temporal guarantees that the Activity will be observed as completed exactly once. However, the Activity may be executed multiple times and may even partially complete more than once during this process." / "Activities won't record to the Event History until they return or produce an error. If an Activity fails to report to the server at all, it will be retried." / "Temporal recommends that Activities be idempotent."

**temporal-workflow-failures**
URL: https://docs.temporal.io/encyclopedia/detecting-workflow-failures
Accessed: 2026-08-21
Quote: "This Timeout is primarily available to recognize whether a Worker has gone down so that the Workflow Execution can be recovered on a different Worker."

**sdk-go-activity**
URL: https://raw.githubusercontent.com/temporalio/sdk-go/master/internal/activity.go
Accessed: 2026-08-21
Quote: "If there were heartbeat details reported by activity from the failed attempt, the details would be delivered along with the activity task for the retry attempt." / StartToCloseTimeout: "Maximum time of a single Activity execution attempt. Note that the Temporal Server doesn't detect Worker process failures directly."

**sdk-go-activity-pkg**
URL: https://raw.githubusercontent.com/temporalio/sdk-go/master/activity/activity.go
Accessed: 2026-08-21
Quote: "RecordHeartbeat sends a heartbeat for the currently executing activity. If the activity is either canceled or the workflow/activity doesn't exist, then we would cancel the context with error [context.Canceled]." / "GetHeartbeatDetails extracts heartbeat details from the last failed attempt. This is used in combination with the retry policy."

**sdk-go-worker-base**
URL: https://raw.githubusercontent.com/temporalio/sdk-go/master/internal/internal_worker_base.go
Accessed: 2026-08-21
Quote: "// Wait for pollers, task dispatch, and task processing to complete, or until stopTimeout elapses." / "if success := awaitWaitGroup(&bw.stopWG, bw.options.stopTimeout); !success { ... bw.logger.Info(\"Worker graceful stop timed out.\", \"Stop timeout\", bw.options.stopTimeout) }"

**sdk-go-internal-worker**
URL: https://raw.githubusercontent.com/temporalio/sdk-go/master/internal/internal_worker.go
Accessed: 2026-08-21
Quote: "// WorkerStopTimeout is the time delay before hard terminate worker"

**sdk-go-worker-pkg**
URL: https://pkg.go.dev/go.temporal.io/sdk/worker
Accessed: 2026-08-21
Quote: "Optional: worker graceful stop timeout / default: 0s" / "Stop the worker. This may panic if called a second time." / "InterruptCh returns channel which will get data when system receives interrupt signal from OS."

**kafka-design**
URL: https://raw.githubusercontent.com/apache/kafka/trunk/docs/design/design.md (rendered at https://kafka.apache.org/documentation/#semantics), sections "Message Delivery Semantics" and "Using Transactions"
Accessed: 2026-08-21
Quote: "Kafka supports exactly-once delivery in Kafka Streams, and the transactional producer and the consumer using read-committed isolation level can be used generally to provide exactly-once delivery when reading, processing and writing data on Kafka topics. Exactly-once delivery for other destination systems generally requires cooperation with such systems, but Kafka provides the primitives which makes implementing this feasible... Otherwise, Kafka guarantees at-least-once delivery by default." / "Many systems claim to provide \"exactly-once\" delivery semantics, but it is important to read the fine print, because sometimes these claims are misleading." / "The classic way of achieving this would be to introduce a two-phase commit between the storage of the consumer position and the storage of the consumers output. This can be handled more simply and generally by letting the consumer store its offset in the same place as its output." / "configures the producer for transactional delivery and also makes sure that a restarted application causes any in-flight transaction from the previous instance to abort."

**kip-98**
URL: https://cwiki.apache.org/confluence/display/KAFKA/KIP-98+-+Exactly+Once+Delivery+and+Transactional+Messaging
Accessed: 2026-08-21
Quote: "a set of messages may be considered consumed only if the entire 'consume-transform-produce' executed in its entirety." / "idempotent producers don't provide guarantees for writes across multiple TopicPartitions. For this, one needs stronger transactional guarantees." / "Bumps up the epoch of the PID, so that the any previous zombie instance of the producer is fenced off and cannot move forward with its transaction." / "Recovers (rolls forward or rolls back) any transaction left incomplete by the previous instance of the producer." / "Exactly one active producer with a given TransactionalId. This is achieved by fencing off old generations when a new instance with the same TransactionalId comes online." / transaction.timeout.ms: "The maximum amount of time in ms that the transaction coordinator will wait for a transaction status update from the producer before proactively aborting the ongoing transaction."

**kip-447**
URL: https://cwiki.apache.org/confluence/display/KAFKA/KIP-447%3A+Producer+scalability+for+exactly+once+semantics
Accessed: 2026-08-21
Quote: "Every producer come with separate memory buffers, a separate thread, separate network connections." / "Sends a list of specified offsets to the consumer group coordinator, and also marks those offsets as part of the current transaction." / "If one of the field is not matching correctly on server side, the client will be fenced immediately."

## SYNTHESIS

Both systems independently converge on the same three-part answer to "what happens to a unit of work when its owning process dies mid-flight," and the shape is worth lifting wholesale.

**1. The dying process is never the writer of its own terminal state.** This is the central design commitment. Temporal's server has no crash-detection channel at all — it has only timers, and the docs say so outright. Kafka's coordinator has only `transaction.timeout.ms` and the next `InitProducerId`. In both cases the participant that knows it is dying is precisely the participant that cannot be trusted to report it, so the authority to close the record is held by a durable third party. The practical design rule: never model a terminal state that only the worker can write. If your state machine has a `failed` transition reachable only from worker code, a `kill -9` produces a permanently-stuck row.

**2. Silence is not a state; a timer converts silence into a state.** "The timeout IS the terminal state" is accurate for Temporal and worth stating that starkly. There is no `crashed` status — only `TimedOut`, written by the service when a timer expires. Kafka is identical: an orphaned transaction is neither committed nor aborted (and is invisible to `read_committed`) until either the coordinator's 60s timer or the successor's epoch bump resolves it. The corollary for any system: every non-terminal state needs an owning deadline, and that deadline must be enforced by something that outlives the worker. A state with no deadline is a leak.

**3. The fencing epoch, not the timeout, is what makes it safe.** The timeout closes the record; the epoch prevents a resurrected zombie from reopening it. Kafka makes this explicit and monotonic (producer epoch per `transactional.id`; KIP-447 additionally binds it to the consumer group generation). Temporal achieves the same effect implicitly — a timed-out attempt's completion is rejected because the service has already moved to a new attempt. This is Kleppmann's fencing token in production form, and it is the answer to the classic objection "what if the worker was only paused, not dead?" Note the direction of the design: Kafka *strengthened* the fence over time (KIP-98 keyed on `transactional.id` alone forced producer-per-partition; KIP-447 moved the fence to the group generation to relax the topology without weakening safety). If a fencing key forces an awkward topology, the fix is a better-scoped key, not a weaker fence.

**4. Both then honestly downgrade the guarantee, and both put idempotency on the application.** Temporal's precise language — "observed as completed exactly once. However, the Activity may be executed multiple times and may even partially complete more than once" — is the most useful sentence in this entry. Exactly-once is a property of the *durable history*, not of side effects. Kafka says the same at its boundary: exactly-once holds for Kafka-topic-to-Kafka-topic, at-least-once is the default, and external sinks "generally requires cooperation with such systems." Neither system claims to make an arbitrary side effect idempotent; both provide a stable idempotency key instead (Temporal: Workflow Run ID + Activity ID; Kafka: producer ID + sequence number) and hand the problem to the application. Any design doc that claims end-to-end exactly-once without naming the idempotency key is overclaiming, by these systems' own standard.

**5. Kafka's external-sink advice is the sleeper lesson: collapse the commit points rather than coordinating them.** "Let the consumer store its offset in the same place as its output" is a stronger and simpler recommendation than two-phase commit, and it generalizes far beyond Kafka — if the checkpoint and the output land in one atomic write to one store, there is no commit boundary to lose a process across. This is the same insight as the outbox pattern and is directly applicable wherever a worker must record both "what I did" and "how far I got."

**6. Graceful shutdown is a courtesy with a default of zero, not a correctness mechanism.** Temporal's `WorkerStopTimeout` defaults to `0s` and its source comment calls it "the time delay before hard terminate worker." Exceeding it logs a line and abandons the activity — which is safe *only because* mechanism 1 exists to catch it. This is the right layering and a good sanity check on one's own design: if graceful shutdown were load-bearing for correctness, a `SIGKILL` would lose work. Build the timeout-and-fence path first; treat graceful drain purely as a latency optimization that reduces how often the recovery path runs.

**Caveats for anyone citing this entry.** Temporal's "Activity Execution" (logical, has a Closed status) vs "Activity Task Execution" (one attempt) distinction makes "the activity timed out" ambiguous — StartToClose/Heartbeat terminate an *attempt*, ScheduleToClose terminates the *execution*, and only the Retry Policy decides which is terminal. On the Kafka side, KIP-98 concedes atomicity is a property of the write and not of any particular read ("the guarantees are a bit weaker" for consumption, due to compaction, segment deletion, `seek`, and partial-partition consumption), and the mainline Kafka docs still lead with the pre-KIP-447 producer-per-consumer topology that KIP-447 was written to relax.
