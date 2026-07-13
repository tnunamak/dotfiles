# BeeLlama watchdog report

## Behavior

`bee-llama-watchdog` is a user-service watchdog for `llama-bee.service`. It
runs every 30 seconds by default and observes only systemd's `ActiveState`,
`SubState`, and `ActiveEnterTimestampMonotonic` for that unit. It never makes
an HTTP request to Bee: no queue, task, generation, completion, health,
metrics, or other engine endpoint is configured or called.
Consequently, monitoring cannot queue, cancel, inspect, or time out an engine
task.

The restart criterion is deliberately narrow and explainable: systemd must
report the stable pairs `inactive/dead` or `failed/failed` twice
consecutively. At the default cadence the second observation is normally 30
seconds after the baseline. `active/running` records the current monotonic activation generation
and clears the count. A transitioning high-level state (`activating`,
`deactivating`, `reloading`, or `refreshing`), any other state/substate pair, a
failed or timed-out systemd command, and malformed output all clear the count
and cannot trigger a restart. This is fail-closed: a long or blocked request is
not evidence that the service is unavailable, and no request-duration timeout
is part of the watchdog's decision.

## Startup/restart grace correction — 2026-07-13

The incident timeline was: `systemctl restart llama-bee` began at 07:48:16;
the old server required `SIGKILL` at 07:48:26; the replacement started at
07:48:27 and was still loading; a watchdog action at 07:48:29 caused a
redundant second restart. The watchdog now carries the complete systemd state
tuple instead of collapsing it to `ActiveState`. `deactivating/stop-*` and
`activating/start` are explicitly transitional, while the replacement's new
`active/running` monotonic activation generation clears any prior dead-unit
evidence. If a brief replacement generation is missed between polls, a larger
monotonic activation timestamp on a later dead observation likewise discards
the old generation's evidence. Model loading is not checked at all:
`llama-bee.service` is `Type=simple`, so `active/running` is expected before
the model is ready to serve requests.

This is state-based grace, not a fixed sleep. It waits for a systemd state
transition or a new activation generation, never an arbitrary number of
seconds. The tradeoff is intentional: if systemd still says `active/running`,
the watchdog declines to diagnose a hung or loading engine; only two stable,
confirmed dead/failed observations permit recovery. That keeps legal long work
and an operator restart out of the watchdog's failure domain.

This leaves normal recovery intact. `llama-bee.service` has its own
`Restart=on-failure` policy; if the unit remains `inactive` or `failed` after
that recovery path, the watchdog performs a bounded additional restart. It
does not attempt to detect an engine process that systemd still reports active:
without a proven non-perturbing liveness signal, restarting that process would
be a false-positive risk to legal 16k-token work.

Before an allowed restart, it writes capped evidence under the disk-backed
`$XDG_STATE_HOME/bee-llama-watchdog/evidence/` (or
`~/.local/state/bee-llama-watchdog/evidence/`): the unit's journal,
`nvidia-smi`, and process state. Each artifact is capped at 256 KiB, commands
time out after five seconds, and only the newest 30 evidence directories are
retained. The process-state artifact is metadata only (`pid`, `ppid`, `stat`,
`etime`, CPU, memory, executable name, and wait channel); it never requests
command arguments or command text. The watchdog keeps a durable restart
history and permits no more than two automated restart attempts in a rolling
30-minute window. It records the attempt before running `systemctl`, so an
ambiguous or failed command cannot bypass the safety budget. If that history is
unreadable or the limit is reached, it logs and does not restart.

The interval, `--inactive-threshold` (default 2), rate-limit settings, state
directory, and system command paths are available as CLI flags and
`BEE_LLAMA_WATCHDOG_*` environment variables for deterministic testing and
local overrides. No endpoint or HTTP-timeout override exists.

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
python3 -m py_compile bin/.local/bin/bee-llama-watchdog
bash -n setup.sh
uv run --no-project python -m unittest discover -s tests -v
systemd-analyze --user verify systemd/.config/systemd/user/bee-llama-watchdog.service
```

The focused suite deterministically covers active service stability; the
two-sample stable-dead/failed recovery boundary; active, transition, and
unknown resets; strict state/substate parsing; strict rate accounting; evidence
capture; CLI validation; and an isolated real Stow installation. Its
`test_operator_restart_and_model_loading_never_restart` sequence is exactly:
`active/running` → `deactivating/stop-sigkill` → `activating/start` → new
`active/running` while the model is not ready → ready. It asserts zero restart
actions and zero evidence captures. `test_second_confirmed_dead_observation_recovers_once` proves that
two `failed/failed` observations still produce one restart.
`test_new_activation_generation_discards_old_dead_evidence` proves that a
larger monotonic activation timestamp discards old-generation evidence before
starting a new two-observation recovery decision. The suite also asserts that
the watchdog source contains no engine HTTP client, queue/task fields, or
endpoint path.

## Incident correction and limits

The prior watchdog fetched Bee task state every 30 seconds. During the reported
long request, a blocking probe caused cancellation events at approximately
06:00:29, 06:01:09, 06:01:49, 06:02:29, and 06:03:08. The watchdog no longer
contains that probe or any timeout-based request liveness clock.

Confidence is high that this watchdog itself no longer perturbs Bee requests:
the executable has no HTTP or task-observation code, and its deterministic
test enforces that boundary. This does not prove that systemd can distinguish a
live-but-hung engine from one doing legitimate long work; it cannot. The design
intentionally declines that ambiguous restart, so an active-but-unresponsive
unit still requires operator diagnosis or a future proven passive heartbeat.
