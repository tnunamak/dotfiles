---
title: "When the SIGTERM grace window is shorter than a unit of work, mature systems do not try to finish and do not record Failed — they checkpoint, release the work back to the queue as retryable, and let the next run resume; grace-window defaults (Docker 10s, k8s 30s, systemd 90s) are far below typical long-job durations"
date: 2026-08-21
topic: distributed-systems
tags: [graceful-shutdown, sigterm, drain, checkpoint, terminal-states, cancel-vs-fail, job-scheduling, prior-art]
status: draft
sources: [docker-stop, docker-run, docker-kill, docker-rm, k8s-pod-lifecycle, k8s-lifecycle-hooks, k8s-disruptions, k8s-pod-failure-policy, k8s-api-conventions, systemd-service, systemd-system-conf, sidekiq-signals, sidekiq-deployment, sidekiq-best-practices, sidekiq-iteration, celery-workers, celery-config, celery-tasks, celery-redis, river-shutdown, river-godoc, river-rescuer-src, river-stuck, temporal-activity-failures, temporal-workflow-execution, temporal-failures-ref, temporal-cli-workflow, temporal-sdk-go-worker, temporal-api-enums]
source_session: af82d1f3-1838-4307-a3a9-6bbf07e77c6f
---

<!--
Companion to bounding-a-hung-job-uses-heartbeat-plus-wall-clock-timeout-a-startup-reaper-and-fencing-tokens.md
(2026-06-14), which covers the DETECTION side: heartbeats, wall-clock ceilings, startup reapers,
fencing tokens. This entry covers the SHUTDOWN/DRAIN side that entry does not: what a worker
should DO in the seconds between SIGTERM and SIGKILL, and what terminal state it should write.
-->

## CLAIMS

### Grace-window defaults — the budget you actually get

- `docker stop` sends the container's stop signal (image `STOPSIGNAL`, else `SIGTERM`) and waits a timeout before escalating: "The `--stop-timeout` flag sets the number of seconds to wait for the container to stop after sending the pre-defined system call signal. If the container does not exit after the timeout elapses, it's forcibly killed with a `SIGKILL` signal." The daemon default is **10 seconds for Linux containers** (30 seconds for Windows containers); `docker run` without `--stop-timeout` inherits that daemon default. [docker-stop] [docker-run]
- `docker kill` skips the grace window entirely: "The main process inside the container is sent `SIGKILL` signal (default)." [docker-kill]
- `docker rm -f` also skips it: the `--force`/`-f` flag is documented as "Force the removal of a running container (uses SIGKILL)." So `rm -f` is not a fast `stop` — it is a `kill`, and gives the process **zero** drain time. [docker-rm]
- Kubernetes: "A Pod is granted a term to terminate gracefully, which defaults to 30 seconds" (`terminationGracePeriodSeconds`), after which SIGKILL is sent. [k8s-pod-lifecycle]
- A Kubernetes `preStop` hook does **not** add to the budget, it consumes it: "If a `PreStop` hook hangs during execution, the Pod's phase will be `Terminating` and remain there until the Pod is killed after its `terminationGracePeriodSeconds` expires. This grace period applies to the total time it takes for both the `PreStop` hook to execute and for the Container to stop normally." The hook is also blocking: "PreStop hooks are not executed asynchronously from the signal to stop the Container; the hook must complete its execution before the TERM signal can be sent." [k8s-lifecycle-hooks]
- systemd `TimeoutStopSec=` "configures the time to wait for the service itself to stop. If it does not terminate in the specified time, it will be forcibly terminated by SIGKILL". It "Defaults to `DefaultTimeoutStopSec=` from the manager configuration file", and `DefaultTimeoutStopSec=` "default[s] to 90 s in the system manager and 90 s in the user manager." [systemd-service] [systemd-system-conf]
- systemd is the only one of the three with a documented budget-extension protocol: a `Type=notify`/`notify-reload` service can send `EXTEND_TIMEOUT_USEC=...` to push the stop deadline past `TimeoutStopSec=`, provided "The first receipt of this message must occur before `TimeoutStopSec=` is exceeded" and the service keeps repeating it within the interval. [systemd-service]

### What workers actually do with an unfinishable job

- **Sidekiq abandons and requeues; it does not try to finish.** "TERM tells Sidekiq to exit within N seconds, where N is set by the `-t` timeout option and defaults to 25." "If any jobs are still running when the timeout is up, Sidekiq **will** push those jobs back to Redis so they can be rerun later." The Signals wiki says such jobs are "forcefully terminated and pushed back to Redis to be executed again when Sidekiq starts up." [sidekiq-deployment] [sidekiq-signals]
- Sidekiq explicitly names long jobs as the hazard, not the grace window: "Long running jobs (jobs running longer than the default 25 second timeout) can lead to job loss or duplicate execution" — and recommends `Sidekiq::Job#interrupted?` or the Iteration pattern as the remedy. [sidekiq-deployment]
- **Sidekiq's Iteration pattern is the canonical checkpoint-and-resume answer.** "The job can be decomposed into a sequence of elements to process; Sidekiq can stop and restart the job anywhere within this sequence using a cursor." On shutdown the job "will flush its current state to Redis and raise `Sidekiq::Job::Interrupted`, so it can be re-enqueued and restarted with the latest cursor." The cursor "stores the current point in the dataset being processed. For instance, if you are processing a CSV file, the cursor might be a row number." [sidekiq-iteration]
- Sidekiq treats re-execution as the baseline contract, not an exception: "Sidekiq will execute your job at least once, not exactly once. Even a job which has completed can be re-run." Hence "Idempotency means that your job can safely execute multiple times." [sidekiq-best-practices]
- **Celery's TERM is a warm shutdown that DOES try to finish** — the opposite policy: "When shutdown is initiated the worker will finish all currently executing tasks before it actually terminates." Additional TERM signals are ignored during warm shutdown; escalation is via `INT` (Ctrl-C) or `QUIT`, not a second TERM. Cold shutdown is `QUIT`: "The worker will stop all currently executing tasks and terminate immediately." [celery-workers]
- Celery 5.5 added a *bounded* warm shutdown because the unbounded one is unusable under a short grace window: "Soft shutdown is a time limited warm shutdown, initiated just before the cold shutdown. The worker will allow `worker_soft_shutdown_timeout` seconds for all currently executing tasks to finish before it terminates. If the time limit is reached, the worker will initiate a cold shutdown and cancel all currently executing tasks." Defaults: `worker_soft_shutdown_timeout` = **0.0** ("the soft shutdown will be practically disabled"; docs recommend "10, 30, 60 seconds"), `worker_enable_soft_shutdown_on_idle` = **False**. [celery-workers] [celery-config]
- **Celery's default acknowledgement mode loses the task rather than requeueing it.** "the default behavior is to acknowledge the message in advance, just before it's executed, so that a task invocation that already started is never executed again." Even with `task_acks_late` enabled, "the worker will acknowledge the message if the child process executing the task is terminated (either by the task calling `sys.exit()`, or by signal) even when `acks_late` is enabled. This behavior is intentional" — because "We assume that a system administrator deliberately killing the task does not want it to automatically restart." Requeue-on-signal requires additionally setting `task_reject_on_worker_lost`, whose "Default: Disabled." and which carries "Warning: Enabling this can cause message loops". [celery-tasks] [celery-config]
- Celery's redelivery backstop is the broker visibility timeout, documented separately: "The visibility timeout defines the number of seconds to wait for the worker to acknowledge the task before the message is redelivered to another worker." "The default visibility timeout for Redis is 1 hour." [celery-redis]
- **River (Go) uses a two-phase soft-then-hard stop and persists results so cancelled work is immediately reworkable.** "While stopping, a River client tries to halt jobs as gracefully as possible so that no jobs are lost, and any that have to be cancelled will be eligible to be reworked as soon as possible." `SoftStopTimeout` "controls how long running jobs have to finish normally (soft stop) before their work contexts are cancelled (hard stop)." `StopAndCancel` "skips the soft stop phase entirely and immediately cancels the work context of all running jobs. It still waits for jobs to return and persists their results so that cancelled jobs can be picked up by another client as soon as possible." [river-shutdown]
- River makes the honest-terminal-state requirement explicit and load-bearing: "In the event of cancellation, jobs must return `ctx.Err()` or another error. Failing to do so would cause their result to be marked as a success (even if the client is stopping), and the job wouldn't be worked again." [river-shutdown]
- River's rescuer is the slow backstop for a process that died without writing a state: `RescueStuckJobsAfter` "is the amount of time a job can be running before it is considered stuck. A stuck job which has not yet reached its max attempts will be scheduled for a retry, while one which has exhausted its attempts will be discarded." Default is **1 hour** (`JobRescuerRescueAfterDefault = time.Hour`), swept every **30 seconds** (`JobRescuerIntervalDefault = 30 * time.Second`). River's docs frame this delay as the *cost of an unclean exit*: an unclean shutdown leaves jobs "in `running` state. These jobs will eventually be rescued so they can be reworked, but not for an hour". [river-godoc] [river-rescuer-src] [river-shutdown]
- River's `JobStuckThreshold` (default 10 seconds) is a *different, in-process* mechanism from the rescuer — it fires when a job ignores context cancellation after `JobTimeout`. Do not cite 10s as a rescue interval. [river-stuck]
- **Temporal does not deliver the shutdown to the Activity at all by default.** Go SDK `worker.Options.WorkerStopTimeout` is documented "Optional: worker graceful stop timeout / default: 0s", described internally as "the time delay before hard terminate worker"; `Worker.Run` will "Stop the worker when interruptCh receives signal", with `InterruptCh()` being the SIGTERM/Ctrl-C helper. With the 0s default, in-flight activities are neither waited for nor cancelled — the process exits and they are orphaned. [temporal-sdk-go-worker]
- **Temporal's server cannot see the shutdown and deliberately resolves it by timeout-then-retry, not by marking Failed.** "The Temporal Server doesn't detect failures when a Worker loses communication with the Server or crashes. Therefore, the Temporal Server relies on the Start-To-Close Timeout to force Activity retries." "The main use case for the Start-To-Close timeout is to detect when a Worker crashes after it has started executing an Activity Task." On heartbeat timeout "the Activity Task fails and a retry occurs if a Retry Policy dictates it", recorded as an `ActivityTaskTimedOut` event. [temporal-activity-failures]
- **Temporal's heartbeat payload IS the checkpoint, and it survives into the retry.** "A Heartbeat can include an application layer payload that can be used to save Activity Execution progress. If an Activity Task Execution times out due to a missed Heartbeat, the next Activity Task can access and continue with that payload." On a TimeoutFailure "the last Heartbeat details it emitted is attached." Caveat: heartbeats are throttled to min(heartbeat timeout × 0.8, 60s), so the checkpoint can lag the true progress — though "Throttling does not apply to the final Heartbeat message in the case of Activity Failure." [temporal-activity-failures] [temporal-failures-ref]

### Terminal-state taxonomy — a decision ABOUT the work vs the work erroring

- Temporal's `WorkflowExecutionStatus` proto enum has nine values: `UNSPECIFIED=0, RUNNING=1, COMPLETED=2, FAILED=3, CANCELED=4, TERMINATED=5, CONTINUED_AS_NEW=6, TIMED_OUT=7, PAUSED=8`. Canceled, Terminated, TimedOut and Failed are each **structurally distinct** terminal states, not variants of failure. [temporal-api-enums]
- Temporal's prose keeps the distinction semantic, not cosmetic: Failed = "The Workflow Execution returned an error and failed" (the work's own error); Cancelled = "The Workflow Execution **successfully handled** a cancellation request" (success language for a cooperative external request); Terminated = "The Workflow Execution was terminated"; Timed Out = "The Workflow Execution reached a timeout limit." [temporal-workflow-execution]
- Cancel is cooperative and permits cleanup; Terminate is imposed and does not: "Canceling a running Workflow Execution records a `WorkflowExecutionCancelRequested` event in the Event History. The Service schedules a new Command Task, and the Workflow Execution performs any cleanup work supported by its implementation." Versus: "Workflow code cannot see or respond to terminations. To perform clean-up work in your Workflow code, use `temporal workflow cancel` instead." [temporal-cli-workflow]
- Temporal's failure-type taxonomy encodes the same split by *origin*: `ApplicationFailure` is the only type created by user code — "Workflow, and Activity, and Nexus Operation code use Application Failures to communicate application-specific failures that happen"; `CanceledFailure` arises "When Cancellation of a Workflow, Activity or Nexus Operation is requested"; `TerminatedFailure` "is used as the `cause` of an error when a Workflow is terminated"; `TimeoutFailure` "represents the timeout of an Activity or Workflow." [temporal-failures-ref]
- **Kubernetes encodes the identical distinction** with the `DisruptionTarget` pod condition, added "to indicate that the Pod is about to be deleted due to a disruption", with reasons `PreemptionByScheduler`, `DeletionByTaintManager`, `EvictionByEvictionAPI`, `DeletionByPodGC`, `TerminationByKubelet`. It exists precisely to distinguish an externally-decided termination from a container that failed on its own. Stable since v1.31. [k8s-disruptions]
- **Kubernetes states outright that a shutdown-caused termination should not be counted as a failure.** The canonical pod-failure-policy example is `action: Ignore` on `onPodConditions: [type: DisruptionTarget]`, documented as: "you can learn how to use Pod failure policy to ignore Pod disruptions from incrementing the Pod retry counter towards the `.spec.backoffLimit` limit." Without it, "the Pod disruption would result in terminating the entire Job (as the `.spec.backoffLimit` is set to 0)." [k8s-pod-failure-policy]
- **The "indeterminate must be Unknown, never False" rule is explicit in the Kubernetes API conventions.** "Condition `status` values may be `True`, `False`, or `Unknown`. The absence of a condition should be interpreted the same as `Unknown`." And directly on in-flight work: "A possible monotonic condition could be `Succeeded`. A `True` status for `Succeeded` would imply completion and that the resource was no longer active. **An object that was still active would generally have a `Succeeded` condition with status `Unknown`.**" [k8s-api-conventions]
- The conventions also require writing the condition early rather than omitting it: "Controllers should apply their conditions to a resource the first time they visit the resource, even if the `status` is Unknown. This allows other components in the system to know that the condition exists and the controller is making progress." And they warn that transitions themselves should be `Unknown`, not `False`: "Intermediate states may be indicated by setting the `status` of the condition to `Unknown`." [k8s-api-conventions]
- The conventions explain *why* a `Failed`-style negative-polarity name makes this worse: "'Ready' or 'Succeeded' may be easier to understand than 'Failed', because 'Failed=Unknown' or 'Failed=False' may cause double-negative confusion." [k8s-api-conventions]

## SOURCES

**docker-stop**
URL: https://docs.docker.com/reference/cli/docker/container/stop/
Accessed: 2026-08-21
Quote: "The `--stop-timeout` flag sets the number of seconds to wait for the container to stop after sending the pre-defined system call signal. If the container does not exit after the timeout elapses, it's forcibly killed with a `SIGKILL` signal." Daemon default: 10s Linux, 30s Windows.

**docker-run**
URL: https://docs.docker.com/reference/cli/docker/container/run/
Accessed: 2026-08-21
Quote: "The `--stop-signal` flag sends the system call signal to the container to exit." Default follows the image's `STOPSIGNAL` or `SIGTERM`; `--stop-timeout` default is set by the daemon (10s Linux).

**docker-kill**
URL: https://docs.docker.com/reference/cli/docker/container/kill/
Accessed: 2026-08-21
Quote: "The main process inside the container is sent `SIGKILL` signal (default)."

**docker-rm**
URL: https://docs.docker.com/reference/cli/docker/container/rm/
Accessed: 2026-08-21
Quote: "Force the removal of a running container (uses SIGKILL)."

**k8s-pod-lifecycle**
URL: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/
Accessed: 2026-08-21
Quote: "A Pod is granted a term to terminate gracefully, which defaults to 30 seconds."

**k8s-lifecycle-hooks**
URL: https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/
Accessed: 2026-08-21
Quote: "If a `PreStop` hook hangs during execution, the Pod's phase will be `Terminating` and remain there until the Pod is killed after its `terminationGracePeriodSeconds` expires. This grace period applies to the total time it takes for both the `PreStop` hook to execute and for the Container to stop normally."

**k8s-disruptions**
URL: https://kubernetes.io/docs/concepts/workloads/pods/disruptions/
Accessed: 2026-08-21
Quote: "A dedicated Pod `DisruptionTarget` condition is added to indicate that the Pod is about to be deleted due to a disruption." Reasons: PreemptionByScheduler, DeletionByTaintManager, EvictionByEvictionAPI, DeletionByPodGC, TerminationByKubelet.

**k8s-pod-failure-policy**
URL: https://kubernetes.io/docs/tasks/job/pod-failure-policy/
Accessed: 2026-08-21
Quote: "you can learn how to use Pod failure policy to ignore Pod disruptions from incrementing the Pod retry counter towards the `.spec.backoffLimit` limit."

**k8s-api-conventions**
URL: https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md
Accessed: 2026-08-21
Quote: "Condition `status` values may be `True`, `False`, or `Unknown`. The absence of a condition should be interpreted the same as `Unknown`." … "An object that was still active would generally have a `Succeeded` condition with status `Unknown`."

**systemd-service**
URL: https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html (verified against local `man 5 systemd.service`, systemd 261.2)
Accessed: 2026-08-21
Quote: "it configures the time to wait for the service itself to stop. If it does not terminate in the specified time, it will be forcibly terminated by SIGKILL … Defaults to DefaultTimeoutStopSec= from the manager configuration file."

**systemd-system-conf**
URL: https://www.freedesktop.org/software/systemd/man/latest/systemd-system.conf.html (verified against local `man 5 systemd-system.conf`)
Accessed: 2026-08-21
Quote: "DefaultTimeoutStartSec= and DefaultTimeoutStopSec= default to 90 s in the system manager and 90 s in the user manager."

**sidekiq-signals**
URL: https://github.com/sidekiq/sidekiq/wiki/Signals
Accessed: 2026-08-21
Quote: "TERM signals that Sidekiq should shut down within the `-t` timeout option given at start-up. The timeout defaults to 25 seconds"; jobs still executing are "forcefully terminated and pushed back to Redis to be executed again when Sidekiq starts up."

**sidekiq-deployment**
URL: https://github.com/sidekiq/sidekiq/wiki/Deployment
Accessed: 2026-08-21
Quote: "If any jobs are still running when the timeout is up, Sidekiq **will** push those jobs back to Redis so they can be rerun later." … "Long running jobs (jobs running longer than the default 25 second timeout) can lead to job loss or duplicate execution."

**sidekiq-best-practices**
URL: https://github.com/sidekiq/sidekiq/wiki/Best-Practices
Accessed: 2026-08-21
Quote: "Sidekiq will execute your job at least once, not exactly once. Even a job which has completed can be re-run."

**sidekiq-iteration**
URL: https://github.com/sidekiq/sidekiq/wiki/Iteration
Accessed: 2026-08-21
Quote: "The job can be decomposed into a sequence of elements to process; Sidekiq can stop and restart the job anywhere within this sequence using a cursor." … "the IterableJob will flush its current state to Redis and raise `Sidekiq::Job::Interrupted`, so it can be re-enqueued and restarted with the latest cursor."

**celery-workers**
URL: https://docs.celeryq.dev/en/stable/userguide/workers.html
Accessed: 2026-08-21
Quote: "When shutdown is initiated the worker will finish all currently executing tasks before it actually terminates." … "Soft shutdown is a time limited warm shutdown, initiated just before the cold shutdown."

**celery-config**
URL: https://docs.celeryq.dev/en/stable/userguide/configuration.html
Accessed: 2026-08-21
Quote: `worker_soft_shutdown_timeout` "Default: 0.0."; `worker_enable_soft_shutdown_on_idle` "Default: False."; `task_reject_on_worker_lost` "Default: Disabled."

**celery-tasks**
URL: https://docs.celeryq.dev/en/stable/userguide/tasks.html
Accessed: 2026-08-21
Quote: "the worker will acknowledge the message if the child process executing the task is terminated (either by the task calling `sys.exit()`, or by signal) even when `acks_late` is enabled. This behavior is intentional"

**celery-redis**
URL: https://docs.celeryq.dev/en/stable/getting-started/backends-and-brokers/redis.html
Accessed: 2026-08-21
Quote: "The visibility timeout defines the number of seconds to wait for the worker to acknowledge the task before the message is redelivered to another worker." "The default visibility timeout for Redis is 1 hour."

**river-shutdown**
URL: https://riverqueue.com/docs/graceful-shutdown
Accessed: 2026-08-21
Quote: "In the event of cancellation, jobs must return `ctx.Err()` or another error. Failing to do so would cause their result to be marked as a success (even if the client is stopping), and the job wouldn't be worked again."

**river-godoc**
URL: https://pkg.go.dev/github.com/riverqueue/river
Accessed: 2026-08-21
Quote: "A stuck job which has not yet reached its max attempts will be scheduled for a retry, while one which has exhausted its attempts will be discarded."

**river-rescuer-src**
URL: https://github.com/riverqueue/river/blob/master/internal/maintenance/job_rescuer.go
Accessed: 2026-08-21
Quote: `JobRescuerRescueAfterDefault = time.Hour`; `JobRescuerIntervalDefault = 30 * time.Second`

**river-stuck**
URL: https://riverqueue.com/docs/stuck-jobs
Accessed: 2026-08-21
Quote: "A job is considered stuck when it exceeds `Config.JobTimeout`, River cancels its context, and it still hasn't returned after `Config.JobStuckThreshold` (default 10 seconds)."

**temporal-activity-failures**
URL: https://docs.temporal.io/encyclopedia/detecting-activity-failures
Accessed: 2026-08-21
Quote: "The Temporal Server doesn't detect failures when a Worker loses communication with the Server or crashes. Therefore, the Temporal Server relies on the Start-To-Close Timeout to force Activity retries." … "A Heartbeat can include an application layer payload that can be used to save Activity Execution progress. If an Activity Task Execution times out due to a missed Heartbeat, the next Activity Task can access and continue with that payload."

**temporal-workflow-execution**
URL: https://docs.temporal.io/workflow-execution
Accessed: 2026-08-21
Quote: Cancelled — "The Workflow Execution successfully handled a cancellation request."; Failed — "The Workflow Execution returned an error and failed."

**temporal-failures-ref**
URL: https://docs.temporal.io/references/failures
Accessed: 2026-08-21
Quote: "Workflow, and Activity, and Nexus Operation code use Application Failures to communicate application-specific failures that happen." … "A Terminated Failure is used as the `cause` of an error when a Workflow is terminated."

**temporal-cli-workflow**
URL: https://docs.temporal.io/cli/workflow
Accessed: 2026-08-21
Quote: "Workflow code cannot see or respond to terminations. To perform clean-up work in your Workflow code, use `temporal workflow cancel` instead."

**temporal-sdk-go-worker**
URL: https://pkg.go.dev/go.temporal.io/sdk/worker and https://github.com/temporalio/sdk-go/blob/master/internal/worker.go
Accessed: 2026-08-21
Quote: "Optional: worker graceful stop timeout // default: 0s"; `InterruptCh()` "returns channel which will get data when system receives interrupt signal from OS. Pass it to worker.Run() func to stop worker with Ctrl+C."

**temporal-api-enums**
URL: https://github.com/temporalio/api/blob/master/temporal/api/enums/v1/workflow.proto
Accessed: 2026-08-21
Quote: `WORKFLOW_EXECUTION_STATUS_COMPLETED = 2; ..._FAILED = 3; ..._CANCELED = 4; ..._TERMINATED = 5; ..._CONTINUED_AS_NEW = 6; ..._TIMED_OUT = 7; ..._PAUSED = 8;`

## SYNTHESIS

**The question this answers.** When SIGTERM arrives and the grace window (10s Docker, 30s k8s, 90s systemd) is an order of magnitude shorter than the job (minutes to hours), what should the worker do in those seconds? The evidence says: **not finish, and not fail.** The four systems surveyed converge on release-the-work-back-as-retryable, and the two best-engineered ones (Sidekiq Iteration, Temporal heartbeat details) add checkpoint-so-the-retry-is-cheap.

**Three distinct strategies, and only one scales.** (1) *Try to finish* — Celery's warm shutdown. Unbounded by design and therefore unusable under a fixed grace window; Celery itself conceded this in 5.5 by adding a *bounded* soft shutdown, which still ships disabled (`worker_soft_shutdown_timeout` = 0.0). (2) *Abandon and requeue whole* — Sidekiq's baseline, River's `StopAndCancel`. Correct and safe, but the retry redoes all work, so it only scales if jobs are short. (3) *Checkpoint, then requeue from the checkpoint* — Sidekiq Iteration's cursor flushed to Redis on `Interrupted`, Temporal's heartbeat payload that "the next Activity Task can access and continue with". This is the only strategy where a 10-second window and a 4-hour job coexist without either lying or losing work. Note what the good implementations spend the window on: not finishing the job, but **writing a small amount of state fast**. The grace window is a budget for persisting a cursor, not for doing work.

**The corollary nobody states but everybody implements: shutdown must be a first-class outcome, distinct from failure.** Temporal gives it its own proto enum values (`CANCELED=4`, `TERMINATED=5`, `TIMED_OUT=7`, all separate from `FAILED=3`) and describes Cancelled in success language — "successfully handled a cancellation request". Kubernetes gives it a dedicated `DisruptionTarget` pod condition whose entire purpose is separating "someone decided to stop this" from "this container broke", and then makes the accounting consequence explicit: the documented `action: Ignore` policy exists so disruptions do not increment the retry counter toward `backoffLimit`. The generalizable rule is about **origin, not severity**: Failed means the work itself errored and the same input would likely error again; Canceled/Terminated/Interrupted means a decision was made *about* the work by something outside it, and the identical input would likely succeed on retry. Collapsing the second into the first poisons every downstream consumer — alerting pages on deploys, retry budgets get burned by restarts, health dashboards show red for a rollout, and (worst) an operator learns to ignore the failure signal.

**And when you cannot determine the outcome, say Unknown — never False.** Kubernetes' API conventions state this outright, and the example they choose is exactly our case: "An object that was still active would generally have a `Succeeded` condition with status `Unknown`." They further instruct writing the `Unknown` condition eagerly rather than omitting it, and warn that `Failed=False` invites double-negative confusion. `False` is a *positive claim that the thing did not succeed*. An interrupted run has not earned that claim. Reporting `Unknown` with a `reason` (the conventions require `Reason`) preserves the distinction between "we know it didn't work" and "we stopped watching" — which is the difference between an actionable alert and a false one.

**Two footguns worth internalizing.** First, Temporal's Go `WorkerStopTimeout` defaults to **0s** — SIGTERM neither waits for nor cancels in-flight activities, so they are silently orphaned and only resolved minutes later by heartbeat/start-to-close timeout. The safety comes entirely from the server-side timeout-then-retry, not from the shutdown path; heartbeating with progress payloads is what converts that from lost work into a resumed checkpoint. Second, River documents the inverse failure: a cancelled job that returns `nil` instead of `ctx.Err()` is "marked as a success (even if the client is stopping), and the job wouldn't be worked again." Both are the same lesson from opposite directions — **the terminal state you write on the way out is the whole contract**, and an unwritten or dishonest one loses work as surely as a crash. Celery makes the third version of this mistake by default: early acknowledgement means a signal-killed task is neither retried nor recorded failed, it is simply gone (and `acks_late` alone does not fix it — you also need `task_reject_on_worker_lost`, which ships disabled and warns about message loops).

**Practical shape for a system with a short window.** Install the SIGTERM handler and stop accepting new work immediately (Sidekiq's TSTP quiet, River's soft stop). Give in-flight work a *bounded* finish attempt sized to a fraction of the real grace window, never an unbounded one. On expiry, write a checkpoint plus a non-failure terminal state (`interrupted`/`canceled` with a reason) and exit — the write must be small and fast enough to complete well inside the remaining budget, which is the actual design constraint. Keep an external reaper as the backstop for the case where you did not get to write anything at all (River's 1-hour rescuer, Sidekiq Pro's orphan sweep) — but treat reaching the reaper as a bug in the shutdown path, since River explicitly frames the hour of delay as the cost of an unclean exit. Finally, do not confuse `docker stop` with `docker rm -f` or `docker kill`: the latter two send SIGKILL and give you **zero** window, so no drain protocol can save you — which makes "which command does the deploy actually run?" a correctness question, not an ops detail.

**Confidence.** High on all defaults and quoted semantics (each pinned to an official doc, proto, or source constant; systemd figures were additionally cross-checked against local man pages). High on the Temporal/Kubernetes terminal-state distinction — both are stated in primary docs, not inferred. Moderate on Temporal's worker-shutdown *mechanics* (wait-on-WaitGroup-then-abandon): this is unambiguous in SDK source but I found no prose doc stating it, so treat the code as the authority. Not verified: how Temporal counts Canceled/Terminated in emitted metrics — the structural and semantic distinction is documented, the metrics accounting is not, so do not assume `workflow_failed` excludes them. Also not verified: any documented link between Celery's soft shutdown and the Redis visibility timeout — the two concepts live on unconnected pages and the causal story is inference.
