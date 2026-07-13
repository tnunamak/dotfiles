# BeeLlama watchdog report

## Behavior

`bee-llama-watchdog` is a user-service watchdog for `llama-bee.service`. It
runs every 30 seconds by default and observes only systemd's `ActiveState` for
that unit. It never makes an HTTP request to Bee: no queue, task, generation,
completion, health, metrics, or other engine endpoint is configured or called.
Consequently, monitoring cannot queue, cancel, inspect, or time out an engine
task.

The restart criterion is deliberately narrow and explainable: systemd must
report `inactive` or `failed` twice consecutively. At the default cadence this
is two observations across 60 seconds. `active` clears the count. A
transitioning state (`activating`, `deactivating`, or `reloading`), a failed or
timed-out systemd command, and any unrecognized response are `unknown`; each
clears the count and cannot trigger a restart. This is fail-closed: a long or
blocked request is not evidence that the service is unavailable, and no
request-duration timeout is part of the watchdog's decision.

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
two-sample inactive boundary; active and unknown resets; `failed` and
`inactive` systemd states; transitional, timed-out, and failed systemd probes;
strict rate accounting; evidence capture; CLI validation; and an isolated real
Stow installation. It also asserts that the watchdog source contains no engine
HTTP client, queue/task fields, or endpoint path.

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
