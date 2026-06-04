# Memo: `/tmp` RAM exhaustion from tmux-resurrect pane-content snapshots

_Status: open problem, documented for investigation. No fix applied. Recorded 2026-06-04._

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
