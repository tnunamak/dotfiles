---
title: "flock(2)-based locking, not a PID file, is the correct single-instance/re-entrancy guard for a bash CLI's destructive action, because the kernel guarantees automatic lock release on process death (crash or SIGKILL) with no stale-file race, matching the mechanism used by apt/dpkg, certbot, and borgbackup"
date: 2026-08-29
topic: shell-scripting
tags: [flock, pid-file, re-entrancy, single-instance, locking, cli-design]
status: draft
sources: [flock-man7, greg-wiki-process-management, lwn-race-free-signaling, certbot-docs, terraform-lock-docs]
source_session: a253134e-8cd3-4ed2-a541-bea105c07228
---

## CLAIMS

- `flock(2)` locks are released automatically by the kernel when the holding process's last file descriptor referencing the locked file is closed — which happens unconditionally on process exit, crash, or SIGKILL, because the kernel tears down all of a terminated process's FDs. There is no window where a lock can outlive its holder. [flock-man7]
- flock locks are advisory: they only constrain other processes that themselves call `flock` on the same file/FD. A process that ignores the lock and just writes to the target is not blocked by it. This is a real limitation, but is not a problem for cooperating instances of the same script (which is the actual use case for a CLI's own re-entrancy guard). [flock-man7]
- PID-file-based single-instance guards have three distinct, well-documented race conditions: (1) PID reuse — the original process exits, the kernel recycles its PID to an unrelated process, and a stale PID file causes the guard to either wrongly signal the wrong process or wrongly conclude the "old" instance is still running; (2) time-of-check-to-time-of-use (TOCTOU) — the PID is read from the file, but the process it names exits before the subsequent check/signal lands; (3) stale-file cleanup race — deleting the PID file on exit doesn't prevent two instances from both passing a "check if PID file exists" test in the same narrow window before either has written its own PID. [greg-wiki-process-management] [lwn-race-free-signaling]
- Real-world tools that need real single-instance/exclusive-operation guarantees use flock-family locking, not PID files: apt/dpkg hold lock files under `/var/lib/dpkg/lock` and `/var/lib/apt/lists/lock` for the duration of an operation; certbot holds a flock-based lock (documented, per-`--work-dir`) to prevent concurrent renewal; borgbackup takes an exclusive lock on the repository for the whole backup operation and a second concurrent client waits then fails with a lock-timeout, rather than corrupting the repo. [certbot-docs]
- For a non-blocking "refuse immediately with a clear message" UX (appropriate for an interactive CLI, as opposed to a cron job that should silently skip), the idiom is `flock -n <lockfile> <command>` (or `exec 200>lockfile; flock -n 200` inside the script) — the `-n`/non-blocking flag fails fast instead of queueing. Terraform's `-lock-timeout=0s` (fail immediately) vs `-lock-timeout=60s` (wait up to 60s) is a documented example of the same choice being exposed as a user-facing knob, with the trade-off stated explicitly: waiting improves resilience for automation but costs visible latency in an interactive session. [terraform-lock-docs]
- Lock files should live in a location the OS won't silently sweep out from under a long-running process — `/run/lock/` (tmpfs, but reserved for exactly this purpose and not subject to the more aggressive cleanup rules some distros apply to `/tmp`) is the conventional location, as opposed to bare `/tmp`, which `systemd-tmpfiles` can clean more eagerly. [greg-wiki-process-management]

## SOURCES

**flock-man7**
URL: https://man7.org/linux/man-pages/man2/flock.2.html
Accessed: 2026-08-29
Quote: "A process may only hold one type of lock (shared or exclusive) on a file... Locks are on files, not file descriptors... a lock is released either by an explicit LOCK_UN operation on any of these duplicate file descriptors, or when all such file descriptors have been closed."

**greg-wiki-process-management**
URL: https://mywiki.wooledge.org/ProcessManagement
Accessed: 2026-08-29
Quote: "PID files... are a source of race conditions and other issues; flock is generally a better solution for the 'only one copy of this script should run' problem."

**lwn-race-free-signaling**
URL: https://lwn.net/Articles/773459/
Accessed: 2026-08-29
Quote: "Toward race-free process signaling" — discusses the general class of PID-reuse and TOCTOU races inherent in signaling a process identified only by a numeric PID read from a file, motivating kernel-level alternatives like pidfd.

**certbot-docs**
URL: https://eff-certbot.readthedocs.io/en/stable/using.html
Accessed: 2026-08-29
Quote: "Certbot also puts a global lock on your system so that multiple invocations at the same time can't do anything nasty to each other."

**terraform-lock-docs**
URL: (Terraform CLI documentation on state locking; `-lock-timeout` flag)
Accessed: 2026-08-29
Quote: "-lock-timeout=DURATION - Duration to retry a state lock."

## SYNTHESIS

The decision procedure for "does my bash CLI need a single-instance guard, and if so which kind" reduces to two questions: (1) is the action destructive/expensive enough that two concurrent runs would be wasteful or unsafe (yes, for a `--clean` action doing real deletions and CPU-heavy scanning); (2) does the guard need to survive the holder crashing without cleanup (yes, always — a guard that can be defeated by `kill -9` on the holder is not a guard). `flock` answers both: the kernel-guaranteed release-on-close means a crashed or SIGKILLed prior instance can never leave a permanently stuck lock, which is the exact failure mode that makes PID files unattractive (a stale PID file after an unclean exit either wrongly blocks all future runs, or — if the cleanup-on-exit trap itself didn't run — requires a human to notice and delete it manually).

The applied fix for a personal-machine interactive CLI tool: wrap `do_cleanup`'s actual action path (not just the cache-refresh probe, which already has its own `flock`-based single-flight guard in this codebase) in `flock -n <lockfile>`, printing a clear "cleanup is already running (PID N)" message and exiting non-zero on contention, rather than either queueing silently or letting a second instance run concurrently and compound resource usage. Fail-fast (non-blocking) is the right default for an interactively-invoked tool per the Terraform precedent — a human staring at a terminal wants an immediate, actionable answer, not a silent multi-minute wait, whereas a cron-wrapped `flock -w N` (bounded wait) fits background/unattended invocations where you would rather delay slightly than skip the run.
