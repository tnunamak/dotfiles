# Daisy spend-watch session notes

## Goal

Use Daisy as a cheap, local token-spend watchdog for frontier coding agents
without making Daisy the coding agent. Daisy should do mechanical monitoring and
surface actionable interruptions only when a session looks like it is burning
tokens in a way Tim may want to redirect.

## Current shape

Runtime lives in `/home/tnunamak/applications/daisy`.

Flow:

```text
Claude/Codex JSONL logs
  -> scripts/agent-spend-watch
  -> tmp/spend-watch-events.jsonl
  -> .pi/extensions/daisy-spend-watch.ts
  -> tmp/daisy-notifications.jsonl
  -> .pi/extensions/daisy-notifications.ts
  -> Pi TUI notifications
```

The separation matters:

- `scripts/agent-spend-watch` is the portable detector. It tails local Claude and
  Codex session logs and emits domain events.
- `daisy-spend-watch.ts` is a Daisy adapter. It turns spend events into generic
  notification intents and can optionally inject a Daisy prompt.
- `daisy-notifications.ts` owns delivery. Today it supports Pi TUI only. Future
  Telegram delivery should be added here, not inside spend-watch.

## Visibility

Shell:

```bash
cd /home/tnunamak/applications/daisy
scripts/agent-spend-watch status
scripts/agent-spend-watch status --json
```

Daisy:

```text
/daisy-spend-watch-status
/daisy-spend-watch-test
/daisy-notifications-status
/daisy-notifications-test
```

`/daisy-spend-watch-status` uses the same JSON status backend as the shell
command. It should report the sidecar PID, watched Claude/Codex file counts, log
freshness, recent event kinds, and latest spend-watch notification inside Daisy.

## Detection rules

Current v1 detectors are deterministic:

- effective token budget threshold
- edit/check retry loop threshold
- repeated same-command failure threshold
- high input/cache to output ratio
- Codex rate-limit pressure from token-count log events

Effective tokens currently follow CodeBurn's rough weighting:

```text
input + output + cache_read * 0.1 + cache_write * 1.25
```

Codex logs do not expose direct spend/usage the same way Claude logs do, so Codex
cost alerts are less precise. Codex is still useful for repeated failures,
retry-ish behavior, and rate-limit pressure.

Dogfood refinement from 2026-05-14: Codex alerts should not display
`effective=0M`; that means usage is unavailable, not free. Repeated-failure
alerts should only fire when the failing output is attributable to a tracked
command. Unmapped failures can stay in evidence but should not interrupt Tim.

Second refinement from 2026-05-14: alerts must include an intervention. Daisy now
adds an event-specific title, an `Action:` line, and a `Suggested prompt:` line.
Multiple alerts for the same repo/session within 30 minutes escalate to
`Pause agent now`. The detector still stays mechanical; intervention language
belongs in the Daisy adapter.

Third refinement from 2026-05-14: session JSONL paths are not a usable product
surface. The detector now hydrates `session_summary` at alert time by reading the
session log and extracting compact context: repo/cwd, model/effort, likely user
task, recent commands, and recent failures. Daisy renders that as a `Context:`
line, and `scripts/agent-spend-watch summarize-session --session PATH` decodes a
path manually.

## Defaults

```bash
DAISY_SPEND_WATCH_AUTOSTART=1
DAISY_SPEND_WATCH_EVENTS=/home/tnunamak/applications/daisy/tmp/spend-watch-events.jsonl
DAISY_NOTIFICATIONS_LOG=/home/tnunamak/applications/daisy/tmp/daisy-notifications.jsonl
DAISY_SPEND_WATCH_INJECT_PROMPTS=0
DAISY_SPEND_WATCH_POLL_MS=5000
DAISY_SPEND_WATCH_LOOKBACK_MINUTES=1440
DAISY_SPEND_WATCH_BUDGET_EFFECTIVE_MTOKENS=50
DAISY_SPEND_WATCH_RETRY_THRESHOLD=3
DAISY_SPEND_WATCH_REPEATED_FAILURE_THRESHOLD=3
DAISY_SPEND_WATCH_CONTEXT_RATIO_THRESHOLD=50
DAISY_SPEND_WATCH_CONTEXT_MIN_EFFECTIVE_MTOKENS=5
DAISY_SPEND_WATCH_CODEX_RATE_LIMIT_PERCENT=80
DAISY_SPEND_WATCH_STATUS_RECENT_RECORDS=50
```

## Open follow-ups

- Add a clean Telegram transport to `daisy-notifications.ts`, gated by config,
  if TUI-only visibility is not enough.
- Decide whether spend alerts should fan out to all configured notification
  transports by severity, or whether producers should keep choosing channels.
- Add a historical summary command once enough real alerts accumulate.
- Consider moving the portable detector into dotfiles or a small standalone repo
  if it proves useful outside Daisy.
