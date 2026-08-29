---
title: "A plain `env VAR=value` prefix in front of `systemd-run --user` has no effect inside the spawned unit — systemd-run does not inherit the invoking shell's environment at all, so only vars explicitly named via its own `--setenv=` survive the boundary, and relying on the prefix silently runs the wrapped command against the real environment instead of the intended override"
date: 2026-08-29
topic: systemd
tags: [systemd-run, environment-variables, setenv, testing-pitfall, sandboxing]
status: draft
sources: [empirical-repro, systemd-run-manpage]
source_session: a253134e-8cd3-4ed2-a541-bea105c07228
---

## CLAIMS

- `env VAR=value systemd-run --user -- <command>` does NOT set `VAR` inside the process `<command>` runs as. The `env` prefix only affects the environment of the `systemd-run` client process itself (the thing that talks to the systemd manager over D-Bus); it has no bearing on the environment the systemd user manager constructs for the new unit. [empirical-repro]
- This holds even for `export`ed variables set earlier in the same shell session, not just inline `env VAR=value` prefixes — `systemd-run --user` unconditionally starts the unit's environment from the systemd user manager's own environment block, not the caller's. [empirical-repro]
- `HOME` in particular resolves correctly by default inside a `systemd-run --user` unit (from the invoking user's passwd entry, since it's a `--user` manager instance), which makes the failure mode worse, not better: an attempted override (`env HOME=/some/scratch/dir systemd-run --user -- <command>`) silently fails, and the command runs with the REAL `$HOME` instead of erroring or visibly using the wrong one — there is no diagnostic signal that the override didn't take. [empirical-repro]
- The only mechanism that reliably crosses the boundary is `systemd-run`'s own `-E NAME[=VALUE]` / `--setenv=NAME[=VALUE]` flag, repeated once per variable. When `=VALUE` is omitted, the value is pulled from `systemd-run`'s own (caller-side) environment at invocation time — this variant DOES correctly propagate a value the caller has set, unlike the bare `env` prefix approach. [systemd-run-manpage] [empirical-repro]
- `PATH` is subject to the exact same silent-override-failure — a caller expecting a custom/sandboxed `PATH` (e.g. test fixture binaries prepended to `PATH`) to reach the wrapped command via `env PATH=... systemd-run --user -- <command>` will instead see systemd's own default `PATH` (e.g. `/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin`) inside the unit, silently resolving to different binaries than intended. [empirical-repro]

## SOURCES

**empirical-repro**
URL: n/a (local reproduction, systemd 259 (259.5-0ubuntu3.4), Kubuntu, systemd --user session)
Accessed: 2026-08-29
Quote: "export MY_TEST_VAR=\"should-appear\" ... systemd-run --user --unit=env-check --pty --quiet -- bash -c 'echo \"MY_TEST_VAR=$MY_TEST_VAR\"' → MY_TEST_VAR=" (empty; the exported var did not cross) / "systemd-run --user --unit=env-check2 --pty --quiet --setenv=MY_TEST_VAR=\"should-appear\" -- bash -c 'echo $MY_TEST_VAR' → MY_TEST_VAR=should-appear" (crosses correctly via --setenv)

**systemd-run-manpage**
URL: https://www.freedesktop.org/software/systemd/man/latest/systemd-run.html
Accessed: 2026-08-29
Quote: "-E NAME[=VALUE], --setenv=NAME[=VALUE] — Runs the service process with the specified environment variable set... When \"=\" and VALUE are omitted, the value of the variable with the same name in the program environment will be used."

## SYNTHESIS

This gotcha caused a real, unintended deletion during development of a `systemd-run`-based containment wrapper for a disk-cleanup CLI tool: an ad-hoc debugging command used `env HOME="$SCRATCH_DIR" ... systemd-run --user ... -- bash cleanup --clean --yes ...`, intending to sandbox the run against a throwaway `$HOME`. The override silently failed, the wrapped `cleanup --clean --yes` ran against the real `$HOME`, and it deleted three real (if reproducible — `node_modules`, not source) directories before the mistake was noticed from the tool's own output showing real project paths.

The failure is dangerous specifically because it degrades gracefully in the wrong direction: there is no error, no warning, and the command still runs — just against different, unintended data. A caller who has correctly used this exact idiom (`env VAR=val some-command`) for every other subprocess-wrapping tool their entire career has no reason to suspect `systemd-run` is different, and the tool gives no signal that it is.

The durable rule: **before running or writing a test for any script/wrapper that internally calls `systemd-run --user` (directly, or via re-exec, as in a containment wrapper), never rely on an outer `env VAR=...` prefix or shell `export` to reach the wrapped command.** Either (a) pass every variable the wrapped command needs via the script's own `--setenv=NAME` list (verify the list is complete — a var silently missing from it is exactly this same failure mode one level down), or (b) when testing ad hoc from a terminal, use `systemd-run`'s `--setenv=` directly rather than an `env` prefix, even for a "quick check." For any tool wrapping `systemd-run --user` — including this dotfiles repo's `cleanup --clean` containment wrapper — this means its own internal `--setenv=` list is a single point of failure: every variable the wrapped script reads from its environment must appear there, or it silently reverts to the real machine's default (which, for `$HOME` and `$PATH`, means "the real environment," not "no value").
