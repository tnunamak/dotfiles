---
title: "Durable-workflow, job-queue, actor, and terminal-automation systems all put engineering into the boundary Waspflow is missing: a durable receipt plus at-least-once dedup, never a bare terminal signal"
date: 2026-07-30
topic: agent-harnesses
tags: [waspflow, async, durability, wakeup, terminal-automation, gastown, firstmate]
status: draft
sources: [temporal-docs, stepfunctions-docs, otp-docs, gha-docs, bullmq-docs, vscode-docs, tmux-man, sdnotify-docs, tmux-sendkeys-issues, codex-osc9, gastown-firstmate-corpus]
---

## CLAIMS

- Extends, and does not duplicate, [official-async-completion-contracts-for-seven-coding-harnesses.md](official-async-completion-contracts-for-seven-coding-harnesses.md) (per-harness documented boundaries) and [waspflow-native-like-completion-adapters-should-use-a-tiered-contract.md](waspflow-native-like-completion-adapters-should-use-a-tiered-contract.md) (the per-harness adapter matrix). This doc covers the layer above: what durable-workflow, job-queue, actor, CI, IDE, and terminal-automation systems teach about waking a busy/idle/blocked/closed/restarted owner, and whether any achieves native-like injection without owning the parent event loop. [temporal-docs] [stepfunctions-docs] [otp-docs] [gha-docs] [bullmq-docs] [vscode-docs] [tmux-man] [sdnotify-docs]
- Every system that achieves a strong delivery/ordering/acknowledgment guarantee does so by owning the execution substrate it delivers into: Temporal's replay-based Workflow Task model, Erlang/OTP's per-process mailbox, GitHub Actions' platform scheduler, Gas Town's and FirstMate's self-spawned tmux sessions/worktrees. [temporal-docs] [otp-docs] [gha-docs] [gastown-firstmate-corpus]
- AWS Step Functions' Task Token pattern (`SendTaskSuccess`/`SendTaskFailure` against a single-use token, with `SendTaskHeartbeat`/`HeartbeatSeconds` detecting a silently-dead worker and routing a missed callback into Retry/Catch) is the one system in this survey with a strong durability/ack story that does **not** require owning the parent's execution loop — any external process can hold a token and call two SDK methods. It transfers as a *shape* (durable receipt + heartbeat + explicit timeout-to-reconciliation), not as an infrastructure dependency. [stepfunctions-docs]
- BullMQ's `QueueEvents` is Redis-Streams-backed specifically because "streams provide guarantees that the events are delivered and not lost during disconnections such as it would be the case with standard pub-sub"; its flow-parent gate (`waiting-children` state, not dequeue-eligible until every child's completion decrements a dependency count to zero) is a durable state-transition wake, and stalled-job detection (lock-renewal timeout, bounded `maxStalledCount` retries) is its crash/restart reconciliation. [bullmq-docs]
- tmux itself documents no ordering, atomicity, or acknowledgment guarantee for `send-keys` relative to a target program's execution state; `man tmux` describes it only as sending keys, with no interlock concept. Two independent bug reports corroborate a real race: `tmux/tmux#1517` and `anthropics/claude-code#23513`, the latter showing keystrokes rendering into a pane before a freshly spawned process is ready to read them, with no tmux-side readiness check. [tmux-man] [tmux-sendkeys-issues]
- No coding-agent TUI documents a reliable, standardized "I am idle and ready for input" signal beyond heuristic screen-content matching. OSC 133/633 exists for shell-prompt boundaries, not agent-turn boundaries; the sole confirmed exception is Codex CLI's `[tui] notification_method`, which emits OSC 9 for exactly `agent-turn-complete` and `approval-requested` — real and documented, but harness-specific, opt-in, one-directional, and not a general readiness contract. No equivalent was found for Claude Code or Gemini CLI. [codex-osc9] [tmux-sendkeys-issues]
- Claude Code's community-observed mid-response input queuing (flush "at the next LLM pause," not confirmed end-of-turn) is real behavior but is tracked as an open, unformalized issue (`anthropics/claude-code#49373`), and whether externally injected `tmux send-keys` bytes reach the identical stdin-handling code path as real keystrokes is architecturally plausible but not confirmed by any Anthropic source. [tmux-sendkeys-issues]
- Conclusion for the framing question: terminal/TUI automation is strictly a best-effort fallback for coding-agent completion delivery, never a designed native-like integration point; every comparable prior-art system that relies on it (Gas Town's documented poll fallback for harnesses without a turn-boundary hook including Codex and Gemini; FirstMate's entire mechanism) layers a durable, locked, escalation-aware queue on top rather than trusting the raw terminal signal. [tmux-sendkeys-issues] [gastown-firstmate-corpus]
- Two systems studied achieve genuine wake-without-polling for an owning *process* (not content delivery into a busy actor): systemd socket activation, where the listening socket exists before the service process does and `accept()` itself is the wake with zero cooperation required from the eventual service; and tmux hooks (`set-hook`), which run against any pane/session with zero cooperation from the process inside the pane, but only as a passive flag or side-effect command — never a forced interrupt of an attached client's input. [sdnotify-docs] [tmux-man]

## SOURCES

**temporal-docs**
URL: https://docs.temporal.io/tasks
Related URL: https://docs.temporal.io/references/events
Accessed: 2026-07-30
Scope: live docs. Architectural claims (History as source of truth, bundled Workflow Task delivery, replay-based recovery) corroborated across multiple hits; the ~5s Sticky Queue eviction default and exact "effectively once" phrasing came via search-tool synthesis after two `docs.temporal.io/encyclopedia/...` URLs 404'd — treat the numeric default as unverified until directly refetched.

**stepfunctions-docs**
URL: https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html
Accessed: 2026-07-30
Scope: directly fetched; Task Token, heartbeat, and timeout-to-Catch/Retry claims are high confidence.

**otp-docs**
URL: https://www.erlang.org/doc/system/ref_man_processes.html
Accessed: 2026-07-30
Scope: directly fetched reference manual; mailbox ordering, `noproc`/`DOWN` semantics.

**gha-docs**
URL: https://docs.github.com/en/actions/using-jobs/using-jobs-in-a-workflow
Related URL: https://docs.github.com/en/actions/concepts/workflows-and-actions/workflow-artifacts
Accessed: 2026-07-30
Scope: directly fetched for `needs:` DAG gating and cascading-skip default; 90-day artifact retention default is search-synthesized, not directly fetched.

**bullmq-docs**
URL: https://docs.bullmq.io/guide/events
Related URL: https://docs.bullmq.io/guide/flows; https://docs.bullmq.io/guide/jobs/stalled
Accessed: 2026-07-30
Scope: directly fetched.

**vscode-docs**
URL: https://code.visualstudio.com/docs/terminal/shell-integration
Related URL: https://code.visualstudio.com/docs/editor/tasks
Accessed: 2026-07-30
Scope: directly fetched; OSC 633 A/B/C/D markers, `problemMatcher.background` pattern fields.

**tmux-man**
URL: man tmux (local, tmux 3.6)
Accessed: 2026-07-30
Scope: `send-keys`, `wait-for`, `monitor-activity`/`monitor-bell`/`monitor-silence`, hooks, control mode (`-CC`) sections.

**sdnotify-docs**
URL: https://www.freedesktop.org/software/systemd/man/latest/sd_notify.html
Related URL: https://github.com/systemd/systemd/pull/4745
Accessed: 2026-07-30
Scope: direct WebFetch of the freedesktop.org page 403'd; claims rest on search-tool summaries of that page plus the linked GitHub PR discussion. The socket/epoll/socket-activation mechanism is corroborated by the man7.org mirror and held at higher confidence than the exact wording of the "main-PID-exit-before-READY is a start failure" design-rationale claim.

**tmux-sendkeys-issues**
URL: https://github.com/tmux/tmux/issues/1517
Related URL: https://github.com/anthropics/claude-code/issues/23513; https://github.com/anthropics/claude-code/issues/49373; https://github.com/anthropics/claude-code/issues/15854
Accessed: 2026-07-30
Scope: bug-tracker evidence, not specification; used to corroborate the absence of a formal delivery/ordering/ack contract, not as a claim about intended behavior.

**codex-osc9**
URL: Codex CLI `[tui] notification_method` config (secondary source describing the config surface: codex.danielvaughan.com/2026/04/10/codex-cli-agent-notifications-desktop-alerts-monitoring)
Accessed: 2026-07-30
Scope: secondary source corroborating a config surface; treat the existence of OSC 9 `agent-turn-complete`/`approval-requested` as medium confidence pending a direct Codex source/docs citation.

**gastown-firstmate-corpus**
URL: local — ai/research/agentic-cli-design/large-scale-agent-orchestrators-gastown-agent-orchestrator.md; ai/research/agentic-cli-design/tmux-agent-supervisors-firstmate-oragent.md
Accessed: 2026-07-30
Scope: existing corpus docs, re-summarized without new claims about Gas Town/FirstMate internals.

## SYNTHESIS

Two questions organize this pass. First: does any system achieve native-like injection into a busy actor's next decision without owning that actor's execution substrate? No — every strong-guarantee system studied (Temporal, Erlang/OTP, GitHub Actions, Gas Town, FirstMate) owns the loop it delivers into. Step Functions' Task Token pattern is the closest non-owning exception, but it works because its "parent" is a passive, externally-callable rendezvous point by design — a property a coding-agent TUI's stdin/model-context does not share. Second: is terminal automation a legitimate adapter or only a fallback? Every primary source checked — tmux's own `send-keys` documentation, two independent bug reports, and the near-total absence of a standardized cross-tool readiness signal — supports "fallback only." The one narrow exception (Codex's OSC 9 turn-complete notification) is real but scoped to one harness and one direction.

The actionable transfer to Waspflow is not a specific technology but a repeated shape: every comparable system that must tolerate a busy/idle/crashed/duplicate-signal owner puts a durable, idempotent receipt in front of the actual delivery mechanism (Step Functions' token+heartbeat, BullMQ's Streams+stalled-job detection, Gas Town's Beads+nudge queue, FirstMate's locked wake-queue+retirement-receipt recheck) and treats the terminal/notification layer itself as at-least-once and lossy. Waspflow should adopt the same shape — durable receipt with a dedup key, per-harness cooperative signal where documented (Codex's OSC 9 today) with heuristic pane classification as the explicit, labeled fallback elsewhere, and no claim of exactly-once or pre-next-decision delivery until the harness-specific empirical probe passes. Full narrow architecture, rejected alternatives, and the discriminating probe list are in the closure report at `/home/tnunamak/.tmp/external-owner-wakeup-prior-art-0730.md` (not part of this repo; reproduce on request rather than treating that path as durable).
