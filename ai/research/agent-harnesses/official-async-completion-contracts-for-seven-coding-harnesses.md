---
title: "Eight coding-agent products have different documented async-delivery boundaries"
date: 2026-07-30
topic: agent-harnesses
tags: [waspflow, async, lifecycle, releases, subagents, acp]
status: draft
sources: [release-map, claude-live, codex-release, codex-v2-main, gemini-release, opencode-live, opencode-main, pi-live, pi-main, qwen-release, qwen-main, kimi-legacy-release, kimi-code-release, kimi-code-main]
source_session: 0d605d44-0bc6-414c-8151-de03a61891a5
---

## CLAIMS

- Provenance rule: a release tag establishes a named version only when a fact is sourced to that tag or its peeled commit. A post-release `main` source and a live documentation page are separately scoped observations, not release guarantees. [release-map]
- This corpus distinguishes eight products: Claude Code 2.1.220 (audited against live, unversioned docs), Codex `rust-v0.146.0`, Gemini CLI `v0.53.0`, OpenCode `v1.18.10`, Pi `v0.83.0`, Qwen Code `v0.21.1`, legacy Kimi CLI `1.49.0`, and Kimi Code `@moonshot-ai/kimi-code@0.31.0`. [release-map]
- Claude Code's live documentation says foreground subagents block the parent and background subagents notify later. It separately documents ordinary subagent resumption and the experimental agent-team limitation that only in-process teammates are not restored by `/resume` or `/rewind`. [claude-live]
- Claude Channels are live-documentation, open-session transport: events are ordered and queue while busy, but sender success is transport acceptance, not a model-processing acknowledgement. Channels do not document delivery to a closed session, durable recovery, or a universal asynchronous model re-wake. [claude-live]
- Codex App Server at `rust-v0.146.0` is a JSON-RPC controller with stored-thread `thread/resume` and `thread/read`, explicit `turn/start`, active-regular-turn `turn/steer`, non-turn-starting `thread/inject_items`, and lifecycle notifications. Direct input is a capability of loaded App Server state; an ordinary CLI thread has `canAcceptDirectInput: null`. [codex-release]
- Codex V2 source at post-release `main` commit `0dcad0c` queues child completion with `trigger_turn=false`; its queue path defers queue-only input until a later turn. This is not evidence for `rust-v0.146.0`, and it does not establish pre-next-decision delivery. [codex-v2-main]
- Gemini CLI `v0.53.0` documents a foreground subagent as an awaited tool result and documents ACP session/prompt control over client-owned stdio. Its documented background-shell interface requires model polling; no automatic background-shell completion delivery was found. [gemini-release]
- OpenCode live documentation exposes agents, server/SDK, plugins/MCP, and ACP; these are integration seams, not a documented preemption or pre-next-decision contract. The cited experimental background implementation is post-release `main` only and is process-local rather than a durable release contract. [opencode-live, opencode-main]
- Pi's `v0.83.0` release parity for the later `sendMessage({ deliverAs: "steer" })` and `triggerTurn` semantics is unverified. Those semantics are post-release `main` and live `latest` documentation observations; if verified at the tag, steer is the explicit active pre-next-LLM seam and `triggerTurn` is idle/new-turn invocation, not the same guarantee. [pi-live, pi-main]
- Qwen Code `v0.21.1` documents background subagents and later task notification while the CLI continues running. Agent teams, daemon/ACP, channel plugins, and task-sidecar recovery are post-release `main` observations, not released contracts. [qwen-release, qwen-main]
- Legacy Kimi CLI `1.49.0` documents isolated subagents, background shell tasks, and an idle main agent starting a new turn when a background task completes. Its task process stops when the CLI exits; busy-turn ordering and durable external recovery are not documented. [kimi-legacy-release]
- Kimi Code `0.31.0` is distinct from legacy Kimi CLI. Its release README establishes the Kimi Code name and listed subagents, hooks, MCP, and ACP features, but not external completion ordering or durable recovery. The previously cited `5c0ec29` README is post-release `main`. [kimi-code-release, kimi-code-main]

## SOURCES

**release-map**
URL: https://github.com/openai/codex/releases/tag/rust-v0.146.0
Related URL: https://github.com/google-gemini/gemini-cli/releases/tag/v0.53.0; https://github.com/anomalyco/opencode/releases/tag/v1.18.10; https://github.com/earendil-works/pi/releases/tag/v0.83.0; https://github.com/QwenLM/qwen-code/releases/tag/v0.21.1; https://github.com/MoonshotAI/kimi-cli/releases/tag/1.49.0; https://github.com/MoonshotAI/kimi-code/releases/tag/%40moonshot-ai%2Fkimi-code%400.31.0
Accessed: 2026-07-30
Scope: release tags and peeled commits: Codex `e363b08c9175ac1cbe5893615dd2cb9ddf95043b`; Gemini `decc0b4`; OpenCode `7902e04`; Pi `845d6ff`; Qwen `41b4ee8`; legacy Kimi `4a550effdfcb29a25a5d325bf935296cc50cd417`; Kimi Code `bc28e9d`. Claude 2.1.220 is identified by its live product documentation and release page, not an archived documentation snapshot.

**claude-live**
URL: https://code.claude.com/docs/en/sub-agents
Related URL: https://code.claude.com/docs/en/agent-teams; https://code.claude.com/docs/en/channels; https://code.claude.com/docs/en/channels-reference; https://code.claude.com/docs/en/sessions; https://code.claude.com/docs/en/hooks
Accessed: 2026-07-30
Scope: live documentation; not a 2.1.220 snapshot.

**codex-release**
URL: https://github.com/openai/codex/blob/e363b08c9175ac1cbe5893615dd2cb9ddf95043b/codex-rs/app-server/README.md
Accessed: 2026-07-30
Scope: `rust-v0.146.0` peeled release commit.

**codex-v2-main**
URL: https://github.com/openai/codex/blob/0dcad0c97217df0ef9511ff1efec9e82720a0fa9/codex-rs/core/src/agent/control.rs#L455-L540
Related URL: https://github.com/openai/codex/blob/0dcad0c97217df0ef9511ff1efec9e82720a0fa9/codex-rs/core/src/session/input_queue.rs#L152-L166
Accessed: 2026-07-30
Scope: post-release `main` only; unverified for `rust-v0.146.0`.

**gemini-release**
URL: https://github.com/google-gemini/gemini-cli/blob/decc0b4/docs/core/subagents.md
Related URL: https://github.com/google-gemini/gemini-cli/blob/decc0b4/packages/core/src/agents/local-session-invocation.ts; https://github.com/google-gemini/gemini-cli/blob/decc0b4/docs/tools/shell.md; https://github.com/google-gemini/gemini-cli/blob/decc0b4/docs/cli/acp-mode.md; https://github.com/google-gemini/gemini-cli/blob/decc0b4/docs/cli/session-management.md
Accessed: 2026-07-30
Scope: `v0.53.0` peeled release commit.

**opencode-live**
URL: https://opencode.ai/docs/agents
Related URL: https://opencode.ai/docs/server; https://opencode.ai/docs/sdk; https://opencode.ai/docs/plugins; https://opencode.ai/docs/mcp-servers; https://opencode.ai/docs/acp; https://opencode.ai/docs/cli
Accessed: 2026-07-30
Scope: live documentation; not a `v1.18.10` snapshot.

**opencode-main**
URL: https://github.com/anomalyco/opencode/blob/c1ee3c6e344c1822814a1a18e99bc14cd1ea36f3/packages/opencode/src/tool/task.ts
Related URL: https://github.com/anomalyco/opencode/blob/c1ee3c6e344c1822814a1a18e99bc14cd1ea36f3/packages/core/src/background-job.ts#L65-L85
Accessed: 2026-07-30
Scope: post-release `main` only; unverified for `v1.18.10` (`7902e04`).

**pi-live**
URL: https://pi.dev/docs/latest/extensions
Related URL: https://pi.dev/docs/latest/rpc
Accessed: 2026-07-30
Scope: live `latest` documentation; not a `v0.83.0` snapshot.

**pi-main**
URL: https://github.com/earendil-works/pi/blob/c13ffe1877c3a47ce9f2fc98d9880447d64a0e87/packages/coding-agent/docs/extensions.md#L1388-L1437
Related URL: https://github.com/earendil-works/pi/blob/c13ffe1877c3a47ce9f2fc98d9880447d64a0e87/packages/coding-agent/src/core/agent-session.ts
Accessed: 2026-07-30
Scope: post-release `main` only; unverified for `v0.83.0` (`845d6ff`).

**qwen-release**
URL: https://github.com/QwenLM/qwen-code/blob/41b4ee8/docs/users/features/sub-agents.md
Accessed: 2026-07-30
Scope: `v0.21.1` peeled release commit.

**qwen-main**
URL: https://github.com/QwenLM/qwen-code/blob/584f6a4bec686e641e48e0ba819ef9d308f9dccc/docs/developers/channel-plugins.md
Related URL: https://github.com/QwenLM/qwen-code/blob/584f6a4bec686e641e48e0ba819ef9d308f9dccc/docs/developers/daemon/03-acp-bridge.md; https://github.com/QwenLM/qwen-code/blob/584f6a4bec686e641e48e0ba819ef9d308f9dccc/packages/core/src/tools/team-create.ts
Accessed: 2026-07-30
Scope: post-release `main` only; unverified for `v0.21.1` (`41b4ee8`).

**kimi-legacy-release**
URL: https://github.com/MoonshotAI/kimi-cli/blob/4a550effdfcb29a25a5d325bf935296cc50cd417/docs/en/guides/interaction.md
Related URL: https://github.com/MoonshotAI/kimi-cli/blob/4a550effdfcb29a25a5d325bf935296cc50cd417/docs/en/customization/agents.md; https://github.com/MoonshotAI/kimi-cli/blob/4a550effdfcb29a25a5d325bf935296cc50cd417/docs/en/reference/kimi-acp.md
Accessed: 2026-07-30
Scope: legacy Kimi CLI `1.49.0` peeled release commit.

**kimi-code-release**
URL: https://github.com/MoonshotAI/kimi-code/blob/bc28e9d/README.md
Accessed: 2026-07-30
Scope: Kimi Code `@moonshot-ai/kimi-code@0.31.0` peeled release commit.

**kimi-code-main**
URL: https://github.com/MoonshotAI/kimi-code/blob/5c0ec2938ac3a01624b6503e5e5df80c9b08f46a/README.md
Accessed: 2026-07-30
Scope: post-release `main` only; unverified for `0.31.0`.

## SYNTHESIS

The implementation question is narrower than “can an integration send text?” Four events remain distinct: a human-visible notification, UI visibility, transport acceptance into an active session, and a receipt that the parent model had the completion in context before its next sampled decision. Starting a new model turn and recovering an already-finished job after restart are separate capabilities again.

Only the Gemini foreground subagent is a documented release-scoped pre-next-decision result, and it is a synchronous tool call rather than an unblocked external completion. Pi may offer an explicit active steer seam after release-tag parity and a race probe. Every other asynchronous path below must be treated as either later/new-turn behavior or undocumented ordering; no adapter is approved for the exact native-like Waspflow contract until its per-row probe passes.

| Product and evidence scope | Native subagents or teams; async task behavior | Integration and lifecycle seams | Identity, persistence, and terminal boundary |
| --- | --- | --- | --- |
| Claude Code 2.1.220 — live, unversioned docs | Foreground and background subagents; teams are experimental and separate from ordinary resumable subagents. Channel is running-session event transport only. | Hooks, MCP/Channels, `/tasks`; channel transport receipt is not model ACK. | Local session/resume; open session required for Channel; terminal/headless behavior is separately documented. |
| Codex `rust-v0.146.0` — release App Server; V2 main-only | App Server proves no native child ordering. Post-release V2 completion is queue-only with `trigger_turn=false`. | App Server stdio JSON-RPC, `turn/steer`, `turn/start`, injection, lifecycle events; WebSocket experimental. | Thread IDs and resume; stored history is not arbitrary TUI attachment; ordinary CLI direct input is null. |
| Gemini CLI `v0.53.0` — release | Foreground subagent is awaited; background shell has model-polled output, not automatic delivery. | ACP stdio, hooks, extensions, MCP/A2A. | Project session IDs and resume; ACP client owns its process; headless avoids TUI. |
| OpenCode `v1.18.10` — live docs and main-only implementation | Release parity for foreground/background implementation is unverified; experimental background main path is synthetic prompt. | Server, SDK, plugins, MCP, ACP, events. | Server avoids TUI; do not infer durable background recovery from process-local main registry. |
| Pi `v0.83.0` — main/live observations only | No release-parity conclusion for steer/trigger or optional extension subagent. | Extension, JSONL RPC, embedded SDK. | Session JSONL/RPC claims need release parity; TUI terminal capability remains distinct from RPC. |
| Qwen Code `v0.21.1` — release plus main-only extras | Released background subagent reports later task notification while running; teams/daemon/channel plugins are main-only. | Release subagent path; main-only hooks, channel, daemon/ACP, sidecar claims. | Any crash sidecar recovery is unverified; no released durable external callback. |
| Legacy Kimi CLI `1.49.0` — release | Background shell/subagent; idle completion starts a new turn. | Hooks, plugins, MCP, Wire, ACP. | Records persist but task process exits with CLI; busy ordering unknown. |
| Kimi Code `0.31.0` — release | Listed subagents only; external completion ordering is not documented. | Hooks, MCP, ACP are features, not an ordering proof. | ACP lifecycle and recovery require a release-tag probe. |
