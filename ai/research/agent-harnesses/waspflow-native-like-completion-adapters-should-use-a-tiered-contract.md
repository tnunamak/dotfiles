---
title: "Waspflow completion adapters require evidence for delivery order, turn ownership, and recovery"
date: 2026-07-30
topic: agent-harnesses
tags: [waspflow, adapters, async, lifecycle, receipts, recovery]
status: draft
sources: [completion-contracts]
---

## CLAIMS

- The provenance-qualified fact record is [Eight coding-agent products have different documented async-delivery boundaries](official-async-completion-contracts-for-seven-coding-harnesses.md). Its release map scopes each claim to a release, post-release `main`, or live documentation. [completion-contracts]
- A sender/controller acknowledgement does not establish that a parent model processed a completion. A delivery acknowledgement requires an observed follow-up tool call or a persisted parent conversation item containing the completion identity. [completion-contracts]
- A successful native-like asynchronous-delivery probe must show a completion receipt in parent model context before the parent’s next sampled decision, without a foreground wait. [completion-contracts]

## SOURCES

**completion-contracts**
URL: local — ai/research/agent-harnesses/official-async-completion-contracts-for-seven-coding-harnesses.md
Accessed: 2026-07-30
Quote: Internal source map and fact record; use its primary sources for product claims.

## SYNTHESIS

The matrix intentionally has only three delivery labels. “Documented pre-next-decision” is stronger than a notification, controller request, or UI update. “Documented next/new-turn only” means the source describes later delivery or an explicitly started turn, not delivery into an already-ending parent turn. “Not documented” includes useful control surfaces whose ordering is not specified.

| Harness and evidence | Delivery state | Minimum setup and owner | Receipt and recovery boundary | Required empirical gap — all results UNRUN |
| --- | --- | --- | --- | --- |
| Claude Code 2.1.220 — live, unversioned docs | **not documented**. Channel is ordered open-session transport; background subagent notice is later-turn visibility. | Waspflow runs a small local Channel/MCP server; user configures it and keeps the target session open. | Treat transport acceptance as pending. Ack only on an observed follow-up tool or persisted conversation item. Closed Channel has no delivery contract; ordinary subagent resume is separate from team-teammate recovery. | Race a completion against active model work, busy tool work, and permission pause; close/restart both sides; replay one completion ID; establish whether Waspflow or user owns Channel/session startup. |
| Codex `rust-v0.146.0` App Server; V2 post-release main | **documented next/new-turn only** for V2 queue-only completion, but only post-release main. Release App Server documents `turn/steer` for an active regular turn and `turn/start` for a new turn, not a completion ordering guarantee. | Waspflow owns an App Server process/thread from start. Do not assume it can attach to an ordinary TUI thread. | Store thread ID plus Waspflow receipt. `thread/inject_items` persists context but starts no turn; `thread/resume` restores stored thread state. | Test active, busy, and permission pauses; restart server and CLI; duplicate receipt acknowledgement; confirm exact ownership and `canAcceptDirectInput` boundary for the intended TUI/controller. |
| Gemini CLI `v0.53.0` | **documented pre-next-decision** only for foreground awaited subagent result; that is synchronous, not an external async completion. Background shell is **not documented**. | For an external next turn, Waspflow owns the ACP stdio client/process and issues `prompt`; user otherwise owns normal CLI session. | Persist session ID and receipt; ACP prompt acceptance is not completion delivery acknowledgement. | Test active/busy/permission behavior of ACP prompt, restart/load, duplicate acknowledgement, and whether the ACP-owned process rather than TUI owns setup. |
| OpenCode `v1.18.10`; server live docs; background source main-only | **not documented**. Server prompt/control is a new-turn/controller seam, not documented preemption. Main-only experimental background synthetic prompt is not release parity and is non-durable. | Waspflow owns `opencode serve` and a session, if it elects to use the controller. | Use server session/event data plus durable Waspflow receipt; do not treat process-local background state as recovery. | Test active/busy/permission ordering, server/session restart, duplicate acknowledgement, and exact server-versus-user setup ownership. |
| Pi `v0.83.0`; steer evidence main/live only | **not documented** for the release. Conditional future result: release-parity steer is the explicit active pre-next-LLM seam; `triggerTurn` is next/new-turn only. | User installs a project extension; Waspflow owns its sidecar work and any controlled Pi/RPC process. | Record receipt externally; do not claim extension restoration across process restart. | Verify `845d6ff` parity first, then race steer through active/busy/permission states, restart, duplicate acknowledgement, and TUI versus RPC ownership. |
| Qwen Code `v0.21.1` | **documented next/new-turn only** while CLI runs: background subagent later task notification. | User starts the native background subagent; Waspflow only needs receipt storage unless adopting unverified main-only controllers. | Native notification is not durable recovery. Treat main-only team/daemon/channel/sidecar features as unavailable for released adapter design. | Test active/busy/permission timing, CLI close/restart, duplicate acknowledgement, and who owns task/session restart. |
| Legacy Kimi CLI `1.49.0` | **documented next/new-turn only**: an idle main agent starts a new turn on background-shell completion. | User invokes native background shell or subagent; Waspflow owns durable receipt storage. | Task process ends with CLI; saved record is not a resumed task. | Test busy and permission ordering, CLI restart, duplicate acknowledgement, and native-task versus ACP setup ownership. |
| Kimi Code `0.31.0` | **not documented**. Release features do not establish ACP external-completion order or recovery. | No native-like external adapter. Any ACP experiment requires Waspflow to own its client/process. | Keep a durable receipt and reconcile on a user-started/new ACP turn. | Run release-tag ACP lifecycle probe for active/busy/permission, close/restart, duplicate acknowledgement, and client/TUI ownership before choosing an adapter. |

For every row, use an idempotent Waspflow receipt such as `{jobId, parentIdentity, completionId, outcome, resultRef, deliveredAt, acknowledgedAt}`. The receipt is durable recovery bookkeeping, not proof of model delivery. Until the row-specific probe passes, the conservative fallback is durable receipt reconciliation followed by a documented user- or controller-started turn; it must not be described as native-like asynchronous delivery.
