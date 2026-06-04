# Memo: `/tmp` RAM exhaustion from tmux-resurrect pane-content snapshots

_Status: ROOT-CAUSED + fix VALIDATED in harness (2026-06-04). Live 53GB reclaimed. Patches committed to dotfiles; activate via next reboot's tmux-restore.service ExecStartPre (NOT applied live yet — live stress-testing on the 259-clone env caused save pile-ups, so activation is deferred to a clean boot). See "Resolution" below._

## Resolution (2026-06-04)

**Root cause (confirmed, not the memo's original hedge):** `strip_assistant_pane_contents()`
in the fork's `save-assistant-sessions.sh` does `mktemp -d` (line 877) with NO trap and NO
disk-backed TMPDIR, extracts the full ~1GB `pane_contents.tar.gz` to delete assistant panes,
then `rm -rf` at line 906. When a save is SIGKILL'd mid-strip (overlapping 5-min saves; the
strip is slow), the GB-sized dir leaks in `/tmp` (tmpfs = RAM). The 49 tiny plain-file orphans
are the same story for the line-661 named temps (EXIT trap can't catch SIGKILL).

**Ideal fix (chosen): don't capture assistant pane scrollback at all.** Assistant TUIs relaunch
fresh on restore, so their captured scrollback is discarded anyway — the strip was remedial
surgery undoing work that shouldn't happen. Skipping capture makes the archive ~1GB smaller,
deletes the leaky strip function entirely, and is restore-safe (every restore path guards on
`pane_contents_file_exists`). Non-assistant pane contents are preserved (user wants those).

**Delivery, split by ownership:**
- **Upstream tmux-resurrect `save.sh`** (NOT owned; no PR — avoid maintainer): runtime Patch 3
  in `patch-assistant-resurrect.sh` makes `dump_pane_contents` skip assistant panes.
- **Fork `timvw/tmux-assistant-resurrect`** (owned, has Docker test suite): committed + tested +
  pushed. Add batch `assistant_subtree_pids` to `lib-detect.sh` (one `ps` snapshot + one awk pass,
  proven equivalent to `pane_has_assistant` but ~0.013s vs 0.34s/42s — per-pane was the slowness
  that *caused* the SIGKILL leak). Remove `strip_assistant_pane_contents()` + its call. Add a
  regression test asserting batch == authoritative.

**Perf proof (2026-06-04):** per-pane `pane_has_assistant` over the grouped-session pane list =
42s (would re-cause SIGKILL). Batch `assistant_subtree_pids` = 0.013s, exact match vs authoritative
(agree=27 missed=0 extra=0 on unique pane pids).

**Critical bug found during live testing (fixed):** `assistant_subtree_pids` prints pids
NEWLINE-separated, but the patch's skip check is a space-glob `case " $_ar_skip " in *" $pid "*`.
Newlines never match the space-glob → every assistant pane was captured anyway. Only surfaced on
the real 259-grouped-clone env (the single-session harness scenario false-greened past it, partly
because the silent claude stub had no scrollback to capture). Fix: normalize with
`tr '\n' ' '` in the patch. The harness scenario was then hardened: `GROUPED_CLONES=20` +
stubs that print marker scrollback + content-based assertions. Discriminator proof: buggy
(newline) patch → harness FAILS (assistant content captured); fixed patch → harness PASSES 9/0.

**Lesson:** validate in the harness BEFORE touching live. Live stress-testing here (triggering
saves + killing them mid-flight) orphaned `tmux_spinner.sh` processes twice ("Saving..." stuck in
status) and piled up overlapping saves on the 259-clone env. The harness with `GROUPED_CLONES`
replicates the failure mode faithfully — use it.

**Harness scenario:** `pane-capture-skip` (in `devcontainer/scripts/tmux-restore-test/`). Run:
`bash run.sh --scenario pane-capture-skip` (fixed, expect PASS) or
`bash run.sh --scripts-dir <buggy-scripts> --scenario pane-capture-skip` (buggy, expect FAIL).

---

_Original investigation notes below (recorded 2026-06-04, pre-fix)._

## Summary

On this Ubuntu 25.10 workstation, `/tmp` is a RAM-backed `tmpfs`. The tmux session-save
machinery (tmux-continuum + tmux-resurrect + the local `tmux-assistant-resurrect` fork)
creates large temporary directories under `/tmp` on every autosave. These directories
accumulate and consume system memory. At time of writing, `/tmp` holds ~55 GB of these
snapshot directories, which counts directly against physical RAM and pushes the machine
into heavy swap usage.

## Environment

- OS: Ubuntu 25.10 (Questing Quokka).
- RAM: ~124 GB total.
- `/tmp` is mounted by systemd's `tmp.mount` (unit shipped by the `systemd` package,
  `static`, not in `/etc/fstab`).
- The shipped default in `/usr/lib/systemd/system/tmp.mount` is:
  `Options=mode=1777,strictatime,nosuid,nodev,size=50%,nr_inodes=1m`
  i.e. `/tmp` is a `tmpfs` sized at 50% of RAM (~63 GB on this machine).
- tmpfs contents are held in RAM (spillable to swap) and are accounted under `Shmem`
  in `/proc/meminfo`. They do not appear in per-process RSS, so they are invisible to
  `ps`/`top` and only show up via `free` (`shared` column), `df -t tmpfs`, or
  `/proc/meminfo` `Shmem`.

## Mechanism

1. **tmux-continuum autosave interval.**
   `~/.tmux/plugins/tmux-assistant-resurrect/config/resurrect-assistants.conf:37`
   sets `@continuum-save-interval '5'` — an autosave fires every 5 minutes.

2. **Pane-content capture is enabled.**
   `~/.config/tmux/tmux.conf:62` sets `@resurrect-capture-pane-contents 'on'`.
   Each save captures the full scrollback of every pane into tmux-resurrect's
   `pane_contents.tar.gz` (under `@resurrect-dir`, which is `~/.tmux/resurrect`,
   `tmux.conf:61`).

3. **Post-save hook unpacks into `/tmp`.**
   `tmux-assistant-resurrect.tmux:27` registers a post-save hook:
   `@resurrect-hook-post-save-all "bash .../scripts/save-assistant-sessions.sh"`.
   That script's `strip_assistant_pane_contents()` function
   (`save-assistant-sessions.sh:867`) removes assistant panes from the saved
   pane-contents archive. To do so it extracts the archive into a temporary directory
   created with a bare `mktemp -d` (`save-assistant-sessions.sh:877`), which — with no
   `TMPDIR` set — resolves to `/tmp/tmp.XXXXXXXX`. The extracted layout is
   `/tmp/tmp.XXXXXXXX/pane_contents/pane-{session_name}:{window_index}.{pane_index}`.

4. **Snapshot size.**
   Because scrollback is large (long-running build/log/agent output), each extracted
   snapshot is on the order of 1.3–1.5 GB. Individual pane files range from a few hundred
   bytes to ~1.5 MB; a single snapshot directory contained ~6,000 pane files.

## Observed state (2026-06-04)

- Live `/tmp`: `df` reports a 63 GB ceiling, 62 GB used.
- Live mount options (`findmnt -no OPTIONS /tmp`):
  `rw,nosuid,nodev,nr_inodes=1048576,inode64` (no explicit `size=`; reflects the
  boot-time 50% default).
- `/tmp/tmp.*` directories: 99 present, ~55 GB combined; 48 of them larger than 500 MB.
- Directory mtimes span multiple days; the largest (~1.3–1.5 GB) cluster at scattered,
  non-current timestamps rather than tracking the 5-minute save cadence.
- `/proc/meminfo` `Shmem` ≈ 56 GB; swap fully consumed (≈ 0 free of 16 GB).
- Uptime: ~4 days (mount predates any config changes below).

## Cleanup behaviour of the hook

`strip_assistant_pane_contents()` (`save-assistant-sessions.sh:867–907`) removes its
`mktemp -d` directory on all observed code paths: on extract failure (`rm -rf "$tmpdir"`),
on repack failure (`rm -f "${archive}.tmp"`), and unconditionally at the end of the
function (`rm -rf "$tmpdir"`). `~/.tmux/resurrect/assistant-save.log` shows routine saves
completing successfully (`saved N session(s)` followed by `stripped pane contents for N
pane(s)`) with no extract/repack warnings.

Given that the routine path cleans up, the accumulated `/tmp/tmp.*` directories do not
correspond to the current successful save cycle. Their timestamps do not match the
5-minute cadence. The source of the orphaned directories has not been confirmed; candidate
explanations not yet verified include: saves interrupted (e.g. by the next timer or pane
teardown) between `mktemp -d` and the cleanup `rm`; the restore path
(`restore-assistant-sessions.sh`, which also calls `mktemp`); manual or test invocations;
or directories created by a prior version of the script before the cleanup logic existed.

## Related: `tmp.mount` size override (present, not yet effective)

A drop-in exists at `/etc/systemd/system/tmp.mount.d/size.conf`:

```
[Mount]
Options=mode=1777,strictatime,nosuid,nodev,size=8G,nr_inodes=1m
```

This overrides the shipped `size=50%` with a fixed `size=8G`. `systemctl cat tmp.mount`
shows both the shipped line and the override (the override is last and wins). The override
has **not** been applied to the running filesystem: a tmpfs keeps the size it was mounted
with, and `/tmp` was mounted at boot ~4 days ago under the 50% default. The override takes
effect only when `/tmp` is next mounted (reboot, or a remount — and a live remount to a
size below current usage is rejected by the kernel while `/tmp` is full).

## Interaction to note

If the `size=8G` override becomes active (after reboot) while the snapshot mechanism above
is unchanged, the total `/tmp` budget (8 GB) is smaller than a few snapshots
(~1.5 GB each). A `/tmp` filled by accumulated or concurrent snapshots would cause the
hook's `mktemp -d`/extract step to fail with `No space left on device`, which would affect
the pane-content stripping step (and potentially other `/tmp` writes), rather than the
prior failure mode of consuming RAM until swap is exhausted.

## Relevant files

- `~/.config/tmux/tmux.conf` — `@resurrect-dir` (61), `@resurrect-capture-pane-contents` (62).
- `~/.tmux/plugins/tmux-assistant-resurrect/config/resurrect-assistants.conf` — `@continuum-save-interval '5'` (37).
- `~/.tmux/plugins/tmux-assistant-resurrect/tmux-assistant-resurrect.tmux` — post-save hook registration (27).
- `~/.tmux/plugins/tmux-assistant-resurrect/scripts/save-assistant-sessions.sh` — `strip_assistant_pane_contents()` (867), `mktemp -d` (877).
- `~/.tmux/plugins/tmux-assistant-resurrect/scripts/restore-assistant-sessions.sh` — `mktemp` (50).
- `/usr/lib/systemd/system/tmp.mount` — shipped `size=50%` default.
- `/etc/systemd/system/tmp.mount.d/size.conf` — `size=8G` override (not yet effective).
- `~/.tmux/resurrect/assistant-save.log` — save-hook activity log.
