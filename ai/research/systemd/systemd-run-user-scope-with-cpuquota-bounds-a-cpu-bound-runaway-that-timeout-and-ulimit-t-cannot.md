---
title: "`timeout` only bounds wall-clock time and `ulimit -t` is a self-imposed, signal-based (ignorable) CPU-time cap, so `systemd-run --user --unit=<name> --pty -p CPUQuota=N% -p RuntimeMaxSec=<n>` (service mode, NOT scope mode) is the correct kernel-enforced, TTY-preserving ceiling on a CPU-bound interactive script"
date: 2026-08-29
topic: systemd
tags: [systemd-run, cgroup, cpuquota, timeout, ulimit, runaway-process, containment]
status: draft
sources: [systemd-resource-control, systemd-kill, systemd-run-manpage, timeout-manpage, cgroup-v2-min-ancestor, empirical-repro]
source_session: a253134e-8cd3-4ed2-a541-bea105c07228
---

## CORRECTION (2026-08-29, same day)

The original version of this entry recommended `systemd-run --user --scope --pty -p CPUQuota=N%`, sourced from an agent research report that turned out to be wrong on one load-bearing point: **`--pty` is explicitly incompatible with `--scope` mode.** Directly tested on this machine (systemd 259):

```
$ systemd-run --user --scope --pty -p CPUQuota=50% -- bash -c 'echo hi'
--pty/--pty-late/--pipe is not compatible in trigger (path/socket/timer units) or --scope mode.
```

And confirmed plain `--scope` (no `--pty`) does not connect a real TTY at all — `[[ -t 0 ]]` reads false inside it. This matters concretely: a wrapped command that needs to prompt for a sudo password (as this script's `--include-tier-2` snap_revs path does) cannot do so inside a bare `--scope`.

**Service mode (`--unit=<name>`) is the correct choice instead**, and was empirically verified end-to-end on this machine: [empirical-repro]
- `systemd-run --user --unit=x --pty -p CPUQuota=50% -- <cmd>` DOES connect a real TTY (`[[ -t 0 ]]` reads true inside it) and blocks synchronously, returning the wrapped command's real exit code.
- `RuntimeMaxSec=` (service-only per the man page — scopes use `TimeoutStopSec=` instead, which was the other original claim, still correct) was verified to actually kill a 30-second sleep after ~2 seconds when set to `RuntimeMaxSec=2`.

Lesson for future use of this entry: an agent-synthesized research report citing correct primary sources (man pages) can still combine them into an incorrect recommendation (the `--pty`+`--scope` combination was never actually tested by that agent, only each flag independently documented). Treat "constructed from real docs" and "verified to actually work together" as different confidence levels — the corrected recommendation below is the one that was run, not just read about.

## CLAIMS

- GNU coreutils `timeout <duration> <command>` bounds only wall-clock elapsed time, not CPU consumption. A process that is CPU-bound (spinning, using 100% of a core) for its entire wall-clock duration is exactly as "caught" by `timeout` as one that's idle the whole time — `timeout` cannot distinguish "ran for 30 minutes doing useful I/O-bound work" from "ran for 30 minutes pinning a core doing nothing." It is a wall-clock ceiling only. [timeout-manpage]
- `ulimit -t <seconds>` sets a per-process CPU-time (not wall-clock) limit and delivers `SIGXCPU` when exceeded — but this is a self-imposed rlimit that the process itself can catch, ignore, or reset (`setrlimit` is not a security boundary against a process that chooses not to cooperate, only a self-discipline mechanism for a process that respects the signal or is killed by the default SIGXCPU disposition if it doesn't handle it). [systemd-resource-control (contrast), general POSIX rlimit semantics]
- `systemd-run --user --scope` for a transient scope does not support `RuntimeMaxSec=` (that option applies to `Type=service` units); the equivalent time ceiling for a scope is `TimeoutStopSec=` from `systemd.kill(5)`, which sends the configured `KillSignal=` (default `SIGTERM`) and then `SIGKILL` after the timeout with no further grace period. [systemd-kill]
- `CPUQuota=` in a systemd unit/scope is not an independent mechanism layered on top of cgroups — it is systemd's direct, friendly interface to the cgroup v2 `cpu.max` controller file. Setting `CPUQuota=50%` on a scope writes the equivalent `cpu.max` quota/period pair for that scope's cgroup. [systemd-resource-control]
- Because `CPUQuota=`/`cpu.max` is enforced by the kernel scheduler at the cgroup level, it cannot be evaded by the contained process regardless of what the process does in userspace — unlike `ulimit -t`, there is no signal for the process to ignore; the kernel simply declines to schedule the cgroup's threads for CPU time beyond the quota. This makes it the correct mechanism specifically for the "process is CPU-bound and won't voluntarily stop" threat model (e.g. a busy-spin bug), as opposed to `timeout` (wall-clock only, doesn't fit "ran for exactly its bound doing nothing useful") or `ulimit -t` (cooperative only). [systemd-resource-control]
- The effective cgroup v2 quota for a nested cgroup is the minimum across every ancestor in the chain, not the nearest ancestor with the file set — a prior, independently verified finding in this same research corpus (see `linux-cgroups/cgroup-v2-effective-quota-is-min-across-ancestor-chain-not-nearest-file.md`), relevant if a `CPUQuota=`-bounded scope is itself launched from within an already-cgrouped session (e.g. a systemd user session slice with its own quota). [cgroup-v2-min-ancestor]
- `--pty` is documented as, and empirically confirmed to be, incompatible with `--scope` mode ("not compatible in trigger (path/socket/timer units) or --scope mode" — the tool's own error text); a bare `--scope` (no `--pty`) does not connect a real TTY (`[[ -t 0 ]]` reads false inside it). [empirical-repro]
- `systemd-run --user --unit=<name> --pty` (service mode, not scope mode) DOES connect a real TTY to the wrapped command and blocks synchronously by default, returning the wrapped command's real exit status to the caller — confirmed by running a command that both checks `[[ -t 0 ]]` and exits with a specific code (7), both of which came through correctly. [empirical-repro]
- `RuntimeMaxSec=2` on a service-mode unit was confirmed to actually terminate a 30-second `sleep` after approximately 2 seconds of wall-clock time, matching the man page's description of the option. [empirical-repro]

## SOURCES

**timeout-manpage**
URL: https://www.gnu.org/software/coreutils/manual/html_node/timeout-invocation.html
Accessed: 2026-08-29
Quote: "timeout — run a command with a time limit... If the command times out, and --preserve-status is not set, then exit with status 124."

**systemd-kill**
URL: https://www.freedesktop.org/software/systemd/man/latest/systemd.kill.html
Accessed: 2026-08-29
Quote: "KillSignal= ... Specifies which signal to use when stopping a service... Defaults to SIGTERM."

**systemd-resource-control**
URL: https://www.freedesktop.org/software/systemd/man/latest/systemd.resource-control.html
Accessed: 2026-08-29
Quote: "CPUQuota=... Assign the specified CPU time quota to the processes executed... This controls the cpu.max attribute on the unit's control group."

**systemd-run-manpage**
URL: https://www.freedesktop.org/software/systemd/man/latest/systemd-run.html
Accessed: 2026-08-29
Quote: "--scope ... Creates a transient .scope unit instead of a .service unit... --pty ... Invoke the command in an interactive fashion, so that STDIN, STDOUT and STDERR of the command running are directly connected to the terminal systemd-run is invoked from."

**cgroup-v2-min-ancestor**
URL: (internal corpus cross-reference)
Accessed: 2026-08-29
Quote: "cgroup v2 (and v1) effective cpu.max/memory.max is the MINIMUM across every ancestor, not the nearest ancestor file found" — see `linux-cgroups/cgroup-v2-effective-quota-is-min-across-ancestor-chain-not-nearest-file.md` in this corpus (2026-08-10, live-reproduced).

**empirical-repro**
URL: n/a (local reproduction, systemd 259 (259.5-0ubuntu3.4), Kubuntu, systemd --user session)
Accessed: 2026-08-29
Quote: "$ systemd-run --user --scope --pty -p CPUQuota=50% -- bash -c 'echo hi' → --pty/--pty-late/--pipe is not compatible in trigger (path/socket/timer units) or --scope mode." / "$ systemd-run --user --unit=test-pty-check --pty -p CPUQuota=50% -- bash -c '[[ -t 0 ]] && echo tty || echo no-tty' → stdin IS a tty" / "RuntimeMaxSec=2 killed a 30s sleep at ~2.1s wall-clock"

## SYNTHESIS

For a personal, interactively-invoked CLI tool that should never legitimately spin for more than a few minutes of cache probing or tens of minutes of actual deletion work, the correct defense-in-depth combination — verified to actually work together, not just independently documented — is: `systemd-run --user --unit=<unique-name> --pty --quiet -p CPUQuota=<N>% -p RuntimeMaxSec=<duration> -- <command>`. `RuntimeMaxSec=` catches the "hung on I/O / waiting on something that will never resolve" case (wall-clock), and `CPUQuota=` catches the "busy-spinning and burning CPU the entire time" case that a wall-clock-only bound cannot distinguish from legitimate long-running work, and that a self-imposed `ulimit -t` cannot guarantee against a process that doesn't die cleanly on `SIGXCPU`. Service mode (`--unit=`), not scope mode, is required specifically because the wrapped command needs a real TTY (e.g. for an interactive `sudo` password prompt) — `--scope` cannot provide one.

This is the concrete answer to "how do I make sure a latent busy-loop bug in this script can never again consume 1000+ CPU-minutes across multiple accumulated instances before a human notices": don't rely on fixing every possible busy-loop bug (the `wait -n` bug documented separately in this corpus is one instance of a general class; there could be others not yet found) — bound the blast radius structurally so that *any* future bug of this shape self-limits automatically. The fix belongs at the invocation layer (built into the script's own entry point via a `systemd-run` re-exec, guarded by a sentinel env var to avoid infinite recursion), not as a patch to any one loop, because the goal is resilience to bugs not yet discovered, not just the one already found. A unique `--unit=` name per invocation (e.g. embedding the PID) avoids collisions between concurrent invocations of different tools sharing the same systemd user session.
