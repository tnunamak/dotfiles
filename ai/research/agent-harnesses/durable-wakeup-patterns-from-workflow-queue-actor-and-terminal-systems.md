---
title: "Durable-workflow, job-queue, actor, and terminal-automation systems all put engineering into the boundary Waspflow is missing: a durable receipt plus at-least-once dedup, never a bare terminal signal"
date: 2026-07-30
topic: agent-harnesses
tags: [waspflow, async, durability, wakeup, terminal-automation, gastown, firstmate]
status: draft
sources: [temporal-docs, stepfunctions-docs, otp-docs, gha-docs, bullmq-docs, vscode-docs, tmux-man, sdnotify-docs, tmux-sendkeys-issues, codex-notify-docs, gastown-firstmate-corpus]
source_session: 019ca16f-3acb-7cb2-bd7f-bbcea114d54c
---

## CLAIMS

- Extends, and does not duplicate, [official-async-completion-contracts-for-seven-coding-harnesses.md](official-async-completion-contracts-for-seven-coding-harnesses.md) (per-harness documented boundaries) and [waspflow-native-like-completion-adapters-should-use-a-tiered-contract.md](waspflow-native-like-completion-adapters-should-use-a-tiered-contract.md) (the per-harness adapter matrix). This doc covers the layer above: what durable-workflow, job-queue, actor, CI, IDE, and terminal-automation systems teach about waking a busy/idle/blocked/closed/restarted owner, and whether any achieves native-like injection without owning the parent event loop. [temporal-docs] [stepfunctions-docs] [otp-docs] [gha-docs] [bullmq-docs] [vscode-docs] [tmux-man] [sdnotify-docs]
- Every system that achieves a strong delivery/ordering/acknowledgment guarantee does so by owning the durable wait state it delivers into. The axis that varies is *who* owns it, not whether ownership is required: a caller-authored loop (Temporal, Erlang/OTP, Gas Town, FirstMate — high setup burden, the caller builds and runs the engine) versus a shared/hosted engine the caller merely calls into (AWS Step Functions, BullMQ, systemd socket activation — low setup burden, the caller attaches to an engine someone else operates). No system surveyed eliminates the ownership requirement; Step Functions relocates it to AWS's managed service rather than removing it. [temporal-docs] [otp-docs] [gha-docs] [gastown-firstmate-corpus]
- AWS Step Functions' Task Token pattern (`SendTaskSuccess`/`SendTaskFailure` against a single-use token, with `SendTaskHeartbeat`/`HeartbeatSeconds` detecting a silently-dead worker and routing a missed callback into Retry/Catch) is in the hosted-engine cluster alongside BullMQ and systemd socket activation, not a categorically distinct "no owner" case: AWS's own state-machine engine persists the paused execution, tracks the heartbeat/timeout window, and resumes on callback — it owns the wait exactly as Temporal owns its Workflow Task loop, just as a managed service rather than caller-authored code. What transfers to Waspflow is the *shape* (durable receipt + heartbeat + explicit timeout-to-reconciliation, callable by any external process holding a token), not an ownership-exempt mechanism — Waspflow's supervisor, like the Step Functions caller, still needs a durable engine (its own, since none of these hosted services fit its terminal-automation problem) to hold that wait state. [stepfunctions-docs]
- BullMQ's `QueueEvents` is Redis-Streams-backed specifically because "streams provide guarantees that the events are delivered and not lost during disconnections such as it would be the case with standard pub-sub"; its flow-parent gate (`waiting-children` state, not dequeue-eligible until every child's completion decrements a dependency count to zero) is a durable state-transition wake, and stalled-job detection (lock-renewal timeout, bounded `maxStalledCount` retries) is its crash/restart reconciliation. Like Step Functions, this is a hosted-engine (Redis) case: the caller attaches to a durable store it doesn't have to author, it doesn't get to skip having one. [bullmq-docs]
- tmux itself documents no ordering, atomicity, or acknowledgment guarantee for `send-keys` relative to a target program's execution state; `man tmux` describes it only as sending keys, with no interlock concept. `anthropics/claude-code#23513` directly confirms this failure mode: keystrokes rendering into a freshly-spawned pane before the shell has finished initializing, with no tmux-side readiness check. `tmux/tmux#1517` is a separate, narrower corroboration — a `copy-pipe-and-cancel`-driven internal command sequence racing within tmux's own command execution, not the same pane-readiness race — but it independently supports the same underlying claim that `send-keys`-adjacent tmux operations carry no completion/ordering guarantee. [tmux-man] [tmux-sendkeys-issues]
- No coding-agent TUI documents a reliable, standardized "I am idle and ready for input" signal beyond heuristic screen-content matching. OSC 133/633 exists for shell-prompt boundaries, not agent-turn boundaries. Codex CLI is the sole confirmed exception, and it has two distinct signals that must not be conflated: (1) the in-TUI `[tui].notification_method` (`auto`/`osc9`/`bel`) plus `[tui].notifications` filtering, which can be configured for both `agent-turn-complete` and `approval-requested`; and (2) the separate external `notify` command hook, which as of this pass's access date fires only for `agent-turn-complete` — two open upstream issues (`openai/codex#19921`, open; `openai/codex#11808`, closed) both confirm `approval-requested` is not yet wired to the external hook, only to the in-TUI notification. For a Waspflow adapter the external `notify` hook, not the in-TUI OSC 9 render, is the relevant integration point, and today it is narrower than the in-TUI signal. No equivalent of either signal was found for Claude Code or Gemini CLI. [codex-notify-docs] [tmux-sendkeys-issues]
- Claude Code's community-observed mid-response input queuing (flush "at the next LLM pause," not confirmed end-of-turn) is real behavior but is tracked in `anthropics/claude-code#49373`, which is closed as a duplicate (a weaker citation grade than an open, actively-tracked issue) — and whether externally injected `tmux send-keys` bytes reach the identical stdin-handling code path as real keystrokes is architecturally plausible but not confirmed by any Anthropic source. [tmux-sendkeys-issues]
- Conclusion for the framing question: terminal/TUI automation is strictly a best-effort fallback for coding-agent completion delivery, never a designed native-like integration point; Gas Town documents an explicit poll fallback for harnesses without a turn-boundary hook, naming Codex and Gemini specifically. FirstMate's completion detection is multi-signal (status-verb files plus pane-content hashing), but its own source corpus doc does not state a primary-hook-versus-fallback hierarchy between those two signals the way Gas Town's does for Codex/Gemini — so FirstMate supports "terminal scraping is heuristic," not "FirstMate documents a hook/fallback structure." [tmux-sendkeys-issues] [gastown-firstmate-corpus]
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
URL: https://github.com/anthropics/claude-code/issues/23513
Related URL: https://github.com/tmux/tmux/issues/1517; https://github.com/anthropics/claude-code/issues/49373; https://github.com/anthropics/claude-code/issues/15854
Accessed: 2026-07-30
Scope: bug-tracker evidence, not specification. `claude-code#23513` directly confirms the fresh-pane readiness race. `tmux/tmux#1517` is a distinct, narrower tmux `send-keys`-adjacent ordering bug (`copy-pipe-and-cancel` internal race), cited only as separate corroboration that tmux gives no completion/ordering guarantee, not as the same failure mode as #23513. `claude-code#49373` is closed as a duplicate — noted as a weaker citation grade than an open issue, not withdrawn.

**codex-notify-docs**
URL: https://learn.chatgpt.com/docs/config-file/config-advanced (redirected from https://developers.openai.com/codex/config-advanced)
Related URL: https://github.com/openai/codex/issues/19921 (open); https://github.com/openai/codex/issues/11808 (closed)
Accessed: 2026-07-30
Scope: first-party OpenAI documentation, directly fetched (confidence upgraded from a prior secondary-source-only citation). Documents `[tui].notification_method` (`auto`/`osc9`/`bel`), `[tui].notifications` event filtering (`agent-turn-complete`, `approval-requested`), and the separate external `notify` command hook, which the docs state supports "currently only `agent-turn-complete`." The two linked issues are open/closed feature requests asking OpenAI to extend the external `notify` hook to also cover `approval-requested`, confirming the in-TUI/external-hook gap is current and known upstream, not a misreading of the docs.

**gastown-firstmate-corpus**
URL: local — ai/research/agentic-cli-design/large-scale-agent-orchestrators-gastown-agent-orchestrator.md; ai/research/agentic-cli-design/tmux-agent-supervisors-firstmate-oragent.md
Accessed: 2026-07-30
Scope: existing corpus docs, re-summarized without new claims about Gas Town/FirstMate internals.

## SYNTHESIS

Two questions organize this pass. First: does any system achieve native-like injection into a busy actor's next decision without owning that actor's execution substrate? No — every system studied requires *some* process or engine to own the durable wait state. The axis that actually varies is who owns it: a caller-authored loop (Temporal, Erlang/OTP, GitHub Actions, Gas Town, FirstMate — you build and run the engine) versus a shared, hosted engine the caller merely calls into (Step Functions, BullMQ, systemd socket activation — someone else runs the engine, the caller attaches with a token/client/socket connection). Step Functions is in the second cluster, not a categorically distinct "no owner" case — AWS's state-machine engine still persists the paused execution and tracks the heartbeat/timeout window exactly as Temporal's replay engine or Gas Town's tmux-session-owning roles do, just as a managed service rather than caller-authored code. Second: is terminal automation a legitimate adapter or only a fallback? Every primary source checked — tmux's own lack of a `send-keys` ordering/ack guarantee (confirmed directly by `claude-code#23513`, separately corroborated by the narrower `tmux/tmux#1517`), and the near-total absence of a standardized cross-tool readiness signal — supports "fallback only." Codex CLI is the one confirmed exception, and even there the useful integration point (the external `notify` hook) is narrower than the in-TUI notification: the hook fires only for `agent-turn-complete` today, not `approval-requested`, per OpenAI's own docs and two upstream issues asking for the gap to be closed.

The actionable transfer to Waspflow is not a specific technology but a repeated shape: every comparable system that must tolerate a busy/idle/crashed/duplicate-signal owner puts a durable, idempotent receipt in front of the actual delivery mechanism (Step Functions' token+heartbeat, BullMQ's Streams+stalled-job detection, Gas Town's Beads+nudge queue, FirstMate's locked wake-queue+retirement-receipt recheck) and treats the terminal/notification layer itself as at-least-once and lossy. Waspflow should adopt the same shape — durable receipt with a dedup key, per-harness cooperative signal where documented (Codex's external `notify` hook today, for `agent-turn-complete` only) with heuristic pane classification as the explicit, labeled fallback elsewhere, and no claim of exactly-once or pre-next-decision delivery until the harness-specific empirical probe passes. A hosted-engine-as-a-service (the Step Functions/BullMQ/systemd shape) is a model Waspflow could aspire to become for its own callers, not a shortcut that exempts Waspflow from owning a durable wait state itself. Full narrow architecture, rejected alternatives, and the discriminating probe list are in the closure report at `/home/tnunamak/.tmp/external-owner-wakeup-prior-art-0730.md` (not part of this repo; reproduce on request rather than treating that path as durable).
