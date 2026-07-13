# BeeLlama watchdog report

## Behavior

`bee-llama-watchdog` is a user-service watchdog for `llama-bee.service`.
It checks that unit first, then checks `http://127.0.0.1:5051/health`, and
only polls `/slots` while health reports `{"status": "ok"}`. It runs every
30 seconds by default.

It observes only `id_task`, `is_processing`,
`n_prompt_tokens_processed`, and `next_token.n_decoded`. Every processing task
is tracked independently, so a progressing parallel task cannot hide a stalled
one. Idle slots, a changed/disappeared task, malformed data, unavailable/non-OK
health, and counter resets clear the relevant watchdog state. Increased prompt
or decode counters clear that task's stagnant count.

The first observation of a task is a baseline, not evidence of stagnation. Only
after six subsequent same-task observations with neither counter changed does
the watchdog restart; this is a baseline plus six stagnant comparisons. It also
restarts after six `/slots` timeouts while the health check remains OK.

The implementation does not use `/metrics`, completion counters, prompts, or
generated content. It never parses or logs payload content beyond those four
fields. It captures the raw service journal as bounded evidence, as required,
but does not inspect or interpret its message content. It does not act on tmux,
Pi, or Daisy; its only automated action is
`systemctl --user restart llama-bee.service`.

Before an allowed restart, it writes capped evidence under the disk-backed
`$XDG_STATE_HOME/bee-llama-watchdog/evidence/` (or
`~/.local/state/bee-llama-watchdog/evidence/`): the unit's journal, `nvidia-smi`,
and process state. Each artifact is capped at 256 KiB, commands time out after
five seconds, and only the newest 30 evidence directories are retained. The
process-state artifact is metadata only (`pid`, `ppid`, `stat`, `etime`, CPU,
memory, executable name, and wait channel); it never requests command arguments
or command text. The watchdog keeps a durable restart history and permits no more than two automated
restart attempts in a rolling 30-minute window. It records the attempt before
running `systemctl`, so an ambiguous or failed command cannot bypass the safety
budget. If that history is unreadable or the limit is reached, it logs and does
not restart.

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

The canonical unit remains at
`systemd/.config/systemd/user/bee-llama-watchdog.service`. Its dedicated,
no-fold stow package is `bee-watchdog-systemd/`; that package symlinks to the
canonical unit and is listed in both `PACKAGES` and `NO_FOLD_PKGS`. It therefore
installs this service without attempting to take ownership of unrelated user
units already present in `~/.config/systemd/user`.

## Verification

Run:

```bash
uv run --no-project python -m unittest discover -s tests -v
systemd-analyze --user verify systemd/.config/systemd/user/bee-llama-watchdog.service
```

The focused suite has 17 deterministic tests covering prompt and generation
progress, idle/task-change resets, malformed slots, loading/non-OK health,
timeout classification and accumulation, the baseline-plus-six comparison
threshold, multiple processing slots, evidence commands, durable restart
history, failed-restart accounting, and the two-attempts-per-30-minutes guard.
The evidence test asserts that the process snapshot excludes both `args` and
`command` fields.
It also performs an isolated real Stow installation with unrelated pre-existing
units and verifies that only the executable and watchdog unit are linked.

## Final adversarial review

The final review corrected three defects: the original single-slot parser could
silently stop liveness detection under parallel load; an `ETIMEDOUT` wrapped by
`URLError` was not classified as a timeout; and the general `systemd` package
was not installed (while naively adding it would conflict with unrelated units).
The implementation now tracks every unique active task, handles wrapped kernel
timeouts, and uses the dedicated stow package described above. The six-sample
boundary and strict pre-restart rate accounting are covered by explicit tests.
