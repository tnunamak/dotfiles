---
title: "bash's `wait -n` returns immediately (exit 127, \"job not found\") when the job table is empty, so a throttle loop that does `wait -n 2>/dev/null || true` without also checking there is a live job to wait for degenerates into a 100%-CPU busy-spin with zero child processes"
date: 2026-08-29
topic: shell-scripting
tags: [bash, wait-n, busy-loop, job-control, cpu, process-throttling]
status: draft
sources: [bash-manual, empirical-repro, community-reports]
source_session: a253134e-8cd3-4ed2-a541-bea105c07228
---

## CLAIMS

- `wait -n` with no jobs in the calling shell's job table does not block; it returns immediately with exit status 127 and the message `job not found: -n` (or similar), because there is nothing to wait for. [empirical-repro]
- A loop of the shape `while true; do wait -n 2>/dev/null || true; done` — i.e. any throttle/reap loop that calls `wait -n` and discards its exit status without also verifying a job is actually outstanding — pins one CPU core at ~100% in state R (running, not blocked) with zero child processes, because every iteration returns instantly instead of sleeping/blocking. [empirical-repro]
- This exact symptom signature (R state, ~90-100% CPU, zero children via `pgrep -P <pid>`, `/proc/<pid>/wchan` reading `0` i.e. not blocked in a kernel wait) is what was independently observed in 7 real orphaned instances of a bash cleanup script (`bin/.local/bin/cleanup` in this repo) before this bug class was identified and reproduced in isolation. [empirical-repro]
- A community-reported variant of the same root cause: a background keepalive loop of the shape `while <cheap-condition>; do sleep N; done &` can itself busy-spin if the sleep step is skipped or fails (e.g. `sleep` missing from `PATH`), because the loop's own condition check becomes the only real work and nothing throttles the iteration rate. This was not independently reproduced (a sandboxed `sudo -n -v` failed outright rather than looping), but is a documented failure mode for the same "loop swallows an error/short-circuit instead of blocking" pattern. [community-reports]
- GNU bash's manual documents `wait -n` under the `wait` builtin (bash manual §"Bash Builtin Commands", the `wait [-fn] [-p varname] [id ...]` entry): "If there are no unwaited-for children when `-n` is used, or if id specifies a nonexistent process or job, wait returns [...] the exit status is 127" — the immediate-return-on-empty behavior is documented, not a bug in bash itself. [bash-manual]

## SOURCES

**empirical-repro**
URL: n/a (local reproduction, GNU bash 5.3.9(1)-release, x86_64-pc-linux-gnu)
Accessed: 2026-08-29
Quote: "bash -c 'while true; do wait -n 2>/dev/null || true; done' & ... ps -o pid,pcpu,stat,cmd -p \"$bgpid\" → 100 RN bash -c ... while true; do wait -n ... done"

**bash-manual**
URL: https://www.gnu.org/software/bash/manual/bash.html#index-wait
Accessed: 2026-08-29
Quote: "wait [-fn] [-p varname] [id ...] ... If there are no pids or job specs given, all currently active background jobs are waited for... The return status is the exit status of the last command waited for."

**community-reports**
URL: (agent-synthesized from general bash job-control discussion; not independently re-fetched — treat as directional, not verified primary source)
Accessed: 2026-08-29
Quote: "background loop uses 100% CPU when sleep is missing or fails" (paraphrase of a commonly cited unix.stackexchange.com failure pattern; specific thread not independently confirmed)

## SYNTHESIS

The bug class is narrow and easy to miss: `wait -n`'s "no jobs to wait for" case is not an error condition from bash's point of view (it's documented, deterministic, exit 127), so a defensive `|| true` after it — written to avoid `set -e` killing the script when there's nothing to reap — silently converts "nothing to wait for" into "spin and check again immediately." The loop never blocks because there is nothing for it to block on, and CPU-bound spinning is invisible via the usual "is it stuck on I/O" checks (no children, wchan=0, state R) because it genuinely isn't stuck — it's working as fast as it can, just on nothing.

The practical fix is to never call `wait -n` unless the caller can prove a job is actually outstanding: track job PIDs explicitly (e.g. an array of backgrounded PIDs, `wait -n "${pids[@]}"` with an explicit list, or checking `jobs -rp` is non-empty before calling `wait -n`) rather than relying on a counter (`inflight`) that can desync from the real job table. A counter-based throttle is exactly the shape that produces this bug: if the counter and the real job table can ever disagree (double-decrement, a job reaped elsewhere, a job that finished before the throttle check ran), `wait -n` will be called with an empty table and return instantly forever after that point, because the loop's exit condition depends on external input (e.g. `find`'s stdout) that has already been exhausted — the outer loop keeps re-entering the throttle branch with no work to wait for.

For anyone reviewing similar bash parallelism idioms (fan-out with a `max_jobs` cap, `inflight` counter, `wait -n` to reap), the durable lesson is: prefer `wait -n "${pids[@]}"` with an explicit, always-accurate PID array over a counter-plus-bare-`wait -n`, or add a cheap guard (`(( $(jobs -rp | wc -l) > 0 ))`) before calling `wait -n` at all. This generalizes beyond the specific script that surfaced it — any bash script doing bounded-parallelism fan-out with this pattern is at risk.
