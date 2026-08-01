---
title: "Redirect a coding agent's scratch to a disk-backed dir SCOPED to the agent (agent-only TMPDIR + CLAUDE_CODE_TMPDIR), not via a GLOBAL TMPDIR override of an intentionally small RAM tmpfs"
date: 2026-07-11
topic: agentic-context-design
tags: [tmpfs, TMPDIR, CLAUDE_CODE_TMPDIR, codex-sandbox, ENOSPC, systemd, scratch]
status: draft
sources: [systemd-tempdirs, kernel-tmpfs, systemd-v258-quota, cc-tmpdir-doc, cc-issue-46479, cc-issue-15700, cc-issue-51814, cc-issue-31024, cc-issue-35442, codex-sandbox, codex-config-ref, tmpdir-side-effects, prezto-emacs-socket, slurm-tmpdir, humansfix-cc-tmp, tmpfiles-cleanup, archwiki-tmpfs]
source_session: 019d8d21-4983-7270-ad8a-be3c2b6338bf
---

<!--
CLAIMS = verifiable statements, each [source-slug]. SOURCES = URL + accessed + quote.
SYNTHESIS = interpretation (skippable, no citations).
-->

## CLAIMS

### Why /tmp is RAM-backed (the benefits you lose by moving TMPDIR to disk)

- On systemd systems `/tmp/` is "typically on tmpfs and thus backed by RAM/swap, and flushed out on each reboot"; `/var/tmp/` is "typically a proper, persistent file system, and thus backed by physical storage." [systemd-tempdirs]
- tmpfs "lives completely in the page cache and optionally on swap" and "grows and shrinks to accommodate the files it contains"; "everything in tmpfs is temporary in the sense that no files will be created on your hard drive." [kernel-tmpfs]
- tmpfs default size is "half of your physical RAM without swap" when unspecified; it can swap unneeded pages out. [kernel-tmpfs]
- Because tmpfs is RAM/swap-backed, temp-file churn never hits the SSD (reduced write wear) and the directory is cleared on every boot with no cleanup script; the mount also carries nosuid/nodev(/noexec) so attackers can't stage executables there. [archwiki-tmpfs][systemd-tempdirs]
- The documented rule of thumb: "/tmp/ should be used for smaller, size-bounded files only; /var/tmp/ should be used for everything else. Data that shall survive a boot cycle shouldn't be placed in /tmp/." [systemd-tempdirs]
- systemd-tmpfiles ages files by default: `/tmp` cleaned after ~10 days, `/var/tmp` after ~30 days; on disk-backed temp dirs the reboot-clear guarantee is gone, so aging is the only automatic cleanup. [tmpfiles-cleanup]

### The failure mode (why agents specifically stress a small tmpfs)

- Claude Code accumulates temp files under `/tmp/claude-$UID/` without rotation/cleanup; in one report it wrote ~771 GB and filled a 1 TB disk in a crash-restart loop. [cc-issue-46479]
- On a tmpfs, quota exhaustion is the failure: strace shows "Disk quota exceeded" (EDQUOT); once the tmpfs/quota is saturated the Bash tool "silently returns empty output" (reads back empty as if the command produced none). [cc-issue-51814][cc-issue-35442]
- tmpfs can exhaust inodes before space; the default mount has a fixed `nr_inodes`, and millions of small files hit that limit while `df -h` still shows free space. [archwiki-tmpfs]
- Claude Code's own error tells you to "set CLAUDE_CODE_TMPDIR to a directory on a filesystem with room" for the real-ENOSPC case. [cc-tmpdir-doc]

### The community convention for agents

- `CLAUDE_CODE_TMPDIR` (added v2.1.4/2.1.5) overrides Claude Code's temp directory; set it before launching (`export CLAUDE_CODE_TMPDIR=/abs/path; claude`); path must be absolute + writable. Documented use cases: disk-quota environments, security policy, and performance (fast storage). [cc-tmpdir-doc]
- CLAUDE_CODE_TMPDIR is only PARTIALLY respected: CWD-tracking files and some background-task paths are hardcoded to `/tmp/claude-<hex>-cwd` / `/tmp/claude/<workspace>/tasks` regardless of the env var (open bugs). So a small `/tmp` must remain writable even with the override set. [cc-issue-31024][cc-issue-15700]
- Codex CLI `workspace-write` sandbox includes BOTH `/tmp` and `$TMPDIR` in its writable roots by default (`SandboxPolicy::WorkspaceWrite` unless `exclude_slash_tmp` / `exclude_tmpdir_env_var`); i.e. Codex honors a redirected `$TMPDIR` (it reads it into the write allowlist) AND keeps `/tmp` writable. [codex-sandbox][codex-config-ref]
- The systemd `$TMPDIR` precedence rule is universal: "If the $TMPDIR environment variable is set, use that path, and neither use /tmp/ nor /var/tmp/ directly." So a redirected TMPDIR captures all well-behaved tooling. [systemd-tempdirs]
- Practitioner cleanup convention: don't hand-roll a reaper — drop a `d /path 0750 user user <age>` rule in `/etc/tmpfiles.d/` and let `systemd-tmpfiles-clean.timer` (15 min after boot, then every 24 h) age it; use `x`/`X` to protect paths, dry-run removals, and "do not treat tmpfiles.d as a magic disk-pressure tool — it is policy-based cleanup, not capacity planning." [tmpfiles-cleanup]
- humansfix Claude-Code guide recommends OS-level cleanup (tmpwatch/systemd-tmpfiles), scheduled deletion of old `/tmp` files, streaming instead of temp files, and >80% disk alerts — it does NOT recommend a global TMPDIR override. [humansfix-cc-tmp]

### The scoping question — global TMPDIR override has documented side effects

- `TMPDIR` "has a special meaning in shell environments"; exporting it globally in an rc/CI change caused unrelated GitLab-CI internal steps to fail (`FATAL: open /builds/build/tmp/...: no such file or directory`). The maintainer's rule: `export TMPDIR=/foo` "will cause problems," whereas `TMPDIR=/foo tool ...` (command-scoped) "is fine." [tmpdir-side-effects]
- A global TMPDIR in `~/.zprofile` broke `emacsclient`: a GUI-launched emacs server had no TMPDIR (socket in `/tmp/emacs$UID/`) while a terminal client had TMPDIR set (looked in the other path) → socket mismatch. GUI-vs-terminal divergence is inherent because rc-file exports only reach shell-launched processes. [prezto-emacs-socket]
- Build process trees re-source rc files mid-build and can clobber an intended TMPDIR; not all tools honor TMPDIR (Java uses `java.io.tmpdir`), so a global setting gives false consistency. [tmpdir-side-effects]
- On HPC/Slurm, recommended practice is explicitly NOT to set TMPDIR in rc files, because the scheduler assigns a fast per-job TMPDIR only "unless $TMPDIR has already been set, in which case it will be ignored." [slurm-tmpdir]

### The enlarge-tmpfs option and systemd v258+ quota

- tmpfs can be resized live without reboot: `mount -o remount,size=Ng /tmp`. But it counts against RAM+swap, so a bigger cap commits more RAM. [archwiki-tmpfs][kernel-tmpfs]
- Since systemd v258, a per-user quota on tmpfs `/tmp` and `/dev/shm` is enabled by default at ~80% of the tmpfs size (fields `tmpLimit`/`tmpLimitScale`, `homectl --tmp-limit=`), specifically "to make it harder for users to DoS the system by consuming all disk space in /tmp." Resizing the tmpfs does NOT auto-update the quota (must `setquota`). [systemd-v258-quota]

### This machine (live state, 2026-07-11, grounds the recommendation)

- `/tmp` = tmpfs `size=16777216k` (16 G), `nr_inodes=1048576`, nosuid/nodev; at check time 24% space used, 27% inodes used. systemd 259 → the v258 80% per-user quota applies (a user is already capped ~12.8 G of the 16 G). [live-check]
- `~/.tmp` resolves to `/` on `/dev/nvme0n1p5` (disk-backed, 1.4 T) but that root partition is 87% full (~170 G free). Both `tmp-reaper.timer` and `systemd-tmpfiles-clean.timer` are active. Neither `TMPDIR` nor `CLAUDE_CODE_TMPDIR` is currently set. [live-check]

## SOURCES

**systemd-tempdirs**
URL: https://systemd.io/TEMPORARY_DIRECTORIES/
Accessed: 2026-07-11
Quote: "The former is typically on tmpfs and thus backed by RAM/swap, and flushed out on each reboot. ... /tmp/ should be used for smaller, size-bounded files only; /var/tmp/ should be used for everything else. ... If the $TMPDIR environment variable is set, use that path, and neither use /tmp/ nor /var/tmp/ directly."

**kernel-tmpfs**
URL: https://www.kernel.org/doc/html/latest/filesystems/tmpfs.html
Accessed: 2026-07-11
Quote: "tmpfs lives completely in the page cache and optionally on swap. ... The default is half of your physical RAM without swap. ... Everything in tmpfs is temporary in the sense that no files will be created on your hard drive."

**systemd-v258-quota**
URL: https://github.com/systemd/systemd/releases/tag/v258 ; https://lwn.net/Articles/1028275/ ; https://github.com/systemd/systemd/pull/36010
Accessed: 2026-07-11
Quote: "per-user quota is now enabled on /dev/shm/ and /tmp/ (the latter only if backed by tmpfs) ... default limit of 80% quota of the backing fs ... to make it harder for users to DoS the system"; "Remounting the tmpfs with a larger size does not automatically update the quota."

**cc-tmpdir-doc**
URL: https://claudelog.com/faqs/what-is-claude-code-tmpdir-in-claude-code/
Accessed: 2026-07-11
Quote: "CLAUDE_CODE_TMPDIR is an environment variable that overrides the default temporary directory used by Claude Code ... Added in v2.1.4/v2.1.5 ... the path must be an absolute directory path with write permissions."

**cc-issue-46479**
URL: https://github.com/anthropics/claude-code/issues/46479
Accessed: 2026-07-11
Quote: "Claude Code fills entire disk via /tmp/claude-{uid} temp files (771 GB crash loop)" — closed as not planned; no temp size cap, no rotation.

**cc-issue-15700**
URL: https://github.com/anthropics/claude-code/issues/15700
Accessed: 2026-07-11
Quote: "Background tasks ignore $TMPDIR and hardcode /tmp/claude/ ... hardcodes /tmp/claude/<workspace-path>/tasks ... regardless of what $TMPDIR is set to." (open)

**cc-issue-51814**
URL: https://github.com/anthropics/claude-code/issues/51814
Accessed: 2026-07-11
Quote: "Bash tool silently returns empty output when /tmp/claude-$UID/ exceeds tmpfs quota."

**cc-issue-31024**
URL: https://github.com/anthropics/claude-code/issues/31024
Accessed: 2026-07-11
Quote: "CLAUDE_CODE_TMPDIR not respected for CWD tracking files on multi-user servers ... CWD tracking files ignore CLAUDE_CODE_TMPDIR and always write to /tmp/claude-<hex>-cwd."

**cc-issue-35442**
URL: https://github.com/anthropics/claude-code/issues/35442
Accessed: 2026-07-11
Quote: "[BUG] Bash tool silently returns empty output when /tmp is full (ENOSPC)."

**codex-sandbox**
URL: https://developers.openai.com/codex/concepts/sandboxing ; https://agent-safehouse.dev/docs/agent-investigations/codex
Accessed: 2026-07-11
Quote: "SandboxPolicy::WorkspaceWrite includes TMPDIR and /tmp by default unless exclude_tmpdir_env_var or exclude_slash_tmp is set."

**codex-config-ref**
URL: https://developers.openai.com/codex/config-reference
Accessed: 2026-07-11
Quote: "exclude_slash_tmp — Exclude /tmp from writable roots in workspace-write mode; exclude_tmpdir_env_var — exclude $TMPDIR from writable roots."

**tmpdir-side-effects**
URL: https://groups.google.com/g/kas-devel/c/s4IEekC37Ro
Accessed: 2026-07-11
Quote: "export TMPDIR=/foo will cause problems, vs. TMPDIR=/foo kas ... which is fine. ... suddenly gitlab ci internal steps started failing ... FATAL: open /builds/build/tmp/artifacts...: no such file or directory."

**prezto-emacs-socket**
URL: https://github.com/sorin-ionescu/prezto/issues/1206
Accessed: 2026-07-11
Quote: "if you launch emacs by clicking the desktop icon, it appears it won't get a $(TMPDIR) ... emacsclient would fail to find the socket file, because the terminal would have $(TMPDIR) defined."

**slurm-tmpdir**
URL: https://sciwiki.fredhutch.org/compdemos/tmpdir/ ; https://docs.rc.ufl.edu/scheduler/temp_directories/
Accessed: 2026-07-11
Quote: "SLURM will set $TMPDIR ... unless $TMPDIR has already been set, in which case it will be ignored ... make sure you do not have $TMPDIR set [in .bashrc/.bash_profile]."

**humansfix-cc-tmp**
URL: https://humansfix.ai/guides/claude-code/temp-files-filling-disk
Accessed: 2026-07-11
Quote: "Schedule a task to delete files in /tmp older than 1 hour ... Configure OS-level cleanup of temp directories on a schedule [tmpwatch/systemd-tmpfiles] ... Set up alerts for disk usage above 80%." (No TMPDIR override recommended.)

**tmpfiles-cleanup**
URL: https://penguin-gym-linux.com/en/articles/tutorials/tmp-cleanup ; https://dev.to/lyraalishaikh/stop-cache-creep-on-linux-practical-systemd-tmpfiles-cleanup-policies-for-tmp-vartmp-4m55
Accessed: 2026-07-11
Quote: "d /tmp/myapp 0750 myapp myapp 1d ... systemd-tmpfiles-clean.timer ... 15 minutes after boot ... every 24 hours ... Do not treat tmpfiles.d as a magic disk-pressure tool — it is policy-based cleanup, not capacity planning."

**archwiki-tmpfs**
URL: https://wiki.archlinux.org/title/Tmpfs
Accessed: 2026-07-11
Quote: "the tmpfs can be temporarily resized without the need to reboot ... mount -o remount,size=1g /tmp ... A mount can run out of inodes before it runs out of space."

**live-check**
URL: (local) `findmnt /tmp`, `df -h/-i /tmp`, `systemctl --version`, `systemctl list-timers`
Accessed: 2026-07-11
Quote: "/tmp tmpfs size=16777216k,nr_inodes=1048576,nosuid,nodev; 24% space / 27% inodes used; systemd 259; tmp-reaper.timer + systemd-tmpfiles-clean.timer active; TMPDIR and CLAUDE_CODE_TMPDIR unset; ~/.tmp on / (87% full, 170G free)."

## SYNTHESIS

**Should you redirect at all? Yes — agent scratch is the exact workload tmpfs `/tmp` is documented NOT to hold.** The systemd rule of thumb is explicit: `/tmp` is for "smaller, size-bounded files only." Coding agents violate that by design — they capture large command outputs, extract packages, hold browser profiles, and fan out parallel workers, producing GB-scale, unbounded, sometimes-crash-orphaned scratch (the 771 GB crash-loop is the tail, but even the median run is exactly the "everything else" that belongs in `/var/tmp`-class storage). The RAM-tmpfs is not wrong; the agent is simply the wrong tenant for it. So the fix is to move the agent's scratch, not to change what `/tmp` is.

**Global vs scoped: SCOPE it to the agents. Do NOT put `export TMPDIR=~/.tmp` in the shell rc.** This is the user's actual question and the evidence lands firmly on scoped:

1. A global rc export moves ALL your normal dev scratch (compiler intermediates, node, pnpm, mktemp scripts) off the fast RAM tmpfs onto disk — you'd surrender the speed / zero-SSD-wear / auto-clear-on-reboot benefits for work that was never the problem. The user made the tmpfs small *on purpose* and already routes heavy work to `~/.tmp` by hand; a global override contradicts that intent and over-corrects.
2. It has documented, nasty side effects that have nothing to do with agents: the GitLab-CI internal-step breakage, the emacs-server socket-path divergence, build trees re-sourcing rc and clobbering it, Slurm refusing to assign its fast per-job dir when TMPDIR is preset. The maintainer consensus is blunt: command-scoped `TMPDIR=/foo tool` is fine, `export TMPDIR=/foo` "will cause problems."
3. It is *also* incomplete: rc exports only reach shell-launched processes, so GUI apps and systemd services keep hitting the small tmpfs anyway — you take the downside without full coverage.

**The recommended shape (surgical, covers both agents):** wrap the agent launch so TMPDIR is exported only into the agent's process tree, and also set the Claude-native var. Concretely, a shell function/alias:

```sh
claude() { TMPDIR="$HOME/.tmp/agent" CLAUDE_CODE_TMPDIR="$HOME/.tmp/agent/claude" command claude "$@"; }
codex()  { TMPDIR="$HOME/.tmp/agent" command codex "$@"; }
```

- Setting `TMPDIR` in the wrapper covers all well-behaved subprocesses the agent spawns (the universal systemd precedence rule) AND is exactly what Codex's sandbox reads into its writable-roots set — so Codex needs no extra config; it will honor the redirected `$TMPDIR` while keeping `/tmp` writable.
- Setting `CLAUDE_CODE_TMPDIR` additionally moves Claude Code's own internal temp tree. **Caveat to preserve `/tmp` writability:** Claude Code has open bugs where CWD-tracking files and some background-task paths are hardcoded to `/tmp/claude-*` / `/tmp/claude/…` and ignore both env vars — so `/tmp` must stay writable and non-full. The wrapper reduces the bulk to disk but does not let you make `/tmp` read-only.
- This is a scalpel that keeps the RAM tmpfs pristine for all normal dev work while removing the agents (the real offenders) from it — matching the user's existing "heavy work → `~/.tmp`" discipline rather than fighting it.

**Enlarge the tmpfs instead? No, as the primary fix.** Raising the 16 G cap commits more RAM to a workload that grows unbounded (it just moves the ENOSPC threshold, per tmpfiles-cleanup's "policy-based cleanup, not capacity planning"), and on systemd 258+ the per-user 80% quota won't follow a live resize without a manual `setquota`. It also does nothing about inode exhaustion (already at 27% here — parallel workers writing many small files can hit `nr_inodes=1048576` before the space cap). A modest enlargement is a fine *secondary* comfort margin, but the redirect is the fix.

**Two machine-specific cautions worth flagging to the user:**
- `~/.tmp` sits on `/` which is already **87% full (~170 G free)**. Redirecting GB-scale agent scratch there trades a small-tmpfs ENOSPC for a *root-partition* ENOSPC, which is worse (can wedge the whole system, not just the agent). Pick a scratch dir on the roomiest disk-backed volume, and keep the existing `tmp-reaper.timer` / add a `d $HOME/.tmp/agent … 1d` rule so orphaned agent scratch (crash loops!) is reaped — the community convention is systemd-tmpfiles aging, not a bespoke reaper.
- Because Claude Code's temp handling is partly hardcoded to `/tmp/claude-*` and fails *silently* (Bash tool returns empty output on tmpfs-full), keep a lightweight `/tmp` free-space check; the redirect shrinks the risk but doesn't eliminate the silent-failure class.

**Confidence:** High on the scoped-not-global recommendation (multiple independent primary sources on both the tmpfs rationale and the global-TMPDIR hazards, plus the systemd precedence rule that makes scoping sufficient). Medium on the exact Claude-Code hardcoded-path residue (drawn from open GitHub issues that may be fixed in a later release than the ones cited — re-verify `CLAUDE_CODE_TMPDIR` coverage against the installed version before assuming `/tmp` can be shrunk further). The "don't point scratch at an 87%-full root" caution is specific to this box's live state.
