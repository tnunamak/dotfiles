---
title: "Recovery systems use explicit bounded leases and separate liveness from a hard execution timeout"
date: 2026-07-13
topic: session-ux
tags: [recovery, leases, heartbeat, timeout, agent-sessions]
status: draft
sources: [aws-task-state, aws-step-functions-best-practices]
source_session: 019f5b22-7c53-7f52-869d-1326e067d54b
---

## CLAIMS

- AWS Step Functions defines a positive `TimeoutSeconds` as the maximum time an activity or task may run, and marks it failed when the worker does not respond within that bound. [aws-task-state]
- Step Functions heartbeats are a separate liveness signal; `HeartbeatSeconds` must be below the task timeout and a missed heartbeat fails the task. [aws-task-state]
- AWS recommends explicit task timeouts because otherwise a workflow can remain stuck waiting for a response. [aws-step-functions-best-practices]

## SOURCES

**aws-task-state**
URL: https://docs.aws.amazon.com/step-functions/latest/dg/state-task.html
Accessed: 2026-07-13

**aws-step-functions-best-practices**
URL: https://docs.aws.amazon.com/step-functions/latest/dg/sfn-best-practices.html
Accessed: 2026-07-13

## SYNTHESIS

A resurrect snapshot is neither a lease nor a heartbeat. The tmux recovery
boundary should therefore keep a bounded, explicit execution permit separate
from saved layout metadata. This implementation records the grant time as the
initial confirmed heartbeat and treats expiry as the fail-closed execution gate;
future launcher-owned heartbeats can refresh liveness without making the hard
expiry implicit or unbounded.
