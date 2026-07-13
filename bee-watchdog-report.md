# BeeLlama watchdog report

## Behavior

`bee-llama-watchdog` is a user-service watchdog for `llama-bee.service`.
It checks that unit first, then checks `http://127.0.0.1:5051/health`, and
only polls `/slots` while health reports `{"status": "ok"}`. It runs every
30 seconds by default.

It observes only `id_task`, `is_processing`,
`n_prompt_tokens_processed`, and `next_token.n_decoded`. Idle slots, a changed
task, malformed data, unavailable/non-OK health, and counter resets clear the
watchdog state. Increased prompt or decode counters clear the stagnant sample
count. It therefore restarts only after six repeated, identical observations of
one processing task, or six `/slots` timeouts while the health check remains OK.

The implementation does not use `/metrics`, completion counters, prompts, or
generated content. It does not act on tmux, Pi, or Daisy; its only automated
action is `systemctl --user restart llama-bee.service`.

Before an allowed restart, it writes capped evidence under the disk-backed
`$XDG_STATE_HOME/bee-llama-watchdog/evidence/` (or
`~/.local/state/bee-llama-watchdog/evidence/`): the unit's journal, `nvidia-smi`,
and process state. Each artifact is capped at 256 KiB, commands time out after
five seconds, and only the newest 30 evidence directories are retained. The
watchdog keeps a durable restart history and permits no more than two automated
restarts in a rolling 30-minute window. If that history is unreadable or the
limit is reached, it logs and does not restart.

Loopback endpoint URLs, polling interval, thresholds, rate-limit settings,
state directory, and system command paths are available as CLI flags and
`BEE_LLAMA_WATCHDOG_*` environment variables for deterministic testing and
local overrides. Endpoint overrides remain restricted to unauthenticated
`http://127.0.0.1` URLs.

## Installation

Run `./setup.sh`, then enable the user unit:

```bash
systemctl --user daemon-reload
systemctl --user enable --now bee-llama-watchdog.service
```

## Verification

Run:

```bash
uv run --no-project python -m unittest discover -s tests -v
systemd-analyze --user verify systemd/.config/systemd/user/bee-llama-watchdog.service
```

The focused test suite covers prompt progress, generation progress, idle and
task-change resets, malformed slots, loading/non-OK health, timeout-based
recovery, stagnant-threshold recovery, durable restart history, and the
two-restarts-per-30-minutes guard.
