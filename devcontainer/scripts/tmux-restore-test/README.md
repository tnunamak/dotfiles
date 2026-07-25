# tmux-restore test harness

Reproducible Docker-based test harness for the tmux-resurrect post-crash recovery flow. Built to validate the systemd-restore.sh / post-save-backup.sh fixes after the 2026-04-25 incident, but generalized for future systemd-related dotfiles testing.

## What it does

1. Builds an Ubuntu 25.10 container with systemd as PID 1 (matching the host)
2. Mounts the dotfiles repo read-only at `/workspace`
3. Installs the tmux config + plugins inside the container as user `tester` (UID 1000)
4. Starts `tmux.service` and `tmux-restore.service` (systemd user units)
5. Runs a scenario script that creates tmux state and simulates a power-loss crash
6. "Reboots" the container by `SIGKILL`-ing PID 1 and `docker start`-ing again
7. Asserts the post-restart state matches expectations

The SIGKILL is critical: a clean `docker stop` triggers an orderly shutdown that lets tmux save state, defeating the simulation. SIGKILL on PID 1 mimics power loss faithfully.

## Quick start

```bash
cd ~/code/dotfiles/devcontainer/scripts/tmux-restore-test

# Run a single scenario with the current (fixed) scripts
bash run.sh                           # default scenario: dangling-symlink
bash run.sh --scenario cliff-shrink

# Run with the OLD (pre-fix) scripts to confirm they fail
bash run.sh --scripts-dir old-scripts --scenario dangling-no-best

# Run the full matrix (6 scenarios × fixed/old)
bash run-matrix.sh

# Keep the container around for debugging after the run
bash run.sh --keep
docker exec -it -u tester -e XDG_RUNTIME_DIR=/run/user/1000 tmux-restore-test zsh
```

## Standalone tool tests (not crash-recovery scenarios)

These don't use `run.sh`'s SIGKILL/reboot cycle — they exercise a specific tool
at scale in the same container image.

```bash
bash agent-resume-scale-test.sh --fixture       # RECOMMENDED: real crash-time
                                                 # data, 169 entries — see below
bash agent-resume-scale-test.sh                 # synthetic, 200-entry sidecar
bash agent-resume-scale-test.sh --entries 500   # push synthetic scale further
bash agent-resume-scale-test.sh --keep          # leave container up for inspection
```

Guards `bin/.local/bin/tmux-agent-resume` against the 2026-07-24 regression:
five `jq --argjson "$var"` calls built shell command-lines from full sidecar
JSON, which worked silently below ~150 entries and hard-crashed
("Argument list too long") above it — `attend-boot-restore`, the real
boot-time trigger, was silently non-functional at production scale
(169 entries) for an unknown period before anyone noticed. See CLAUDE.md
"2026-07-24" section and commits `45a18ba` / `b287acf`.

**`--fixture` vs synthetic data — use `--fixture` unless you need to push past
169 entries.** The synthetic generator (default) was the first attempt at this
test and does NOT reliably reproduce the crash: at 200 entries / ~35KB it ran
clean against the confirmed pre-fix code. Investigation found the trigger
wasn't entry *count* alone but the size of individual fields (`cli_args` up to
4.3KB per entry in the real capture) pushing the total argv past the kernel's
`ARG_MAX`. `fixtures/agent-resume-real-169.json` is a scrubbed copy of the
actual sidecar that crashed production — cwd/pane/pid/tool/session_id
structure preserved, `cli_args` replaced with placeholder text AT THE SAME
LENGTH as the real value (0 to 4,333 chars), no real paths, task content, or
usernames. Confirmed by direct reproduction: this fixture crashes
`jq: Argument list too long` at the same line against `tmux-agent-resume` as
of commit `45a18ba~1`, and runs clean (16/16 assertions) against the fix.

Known limitation: the test container has no `claude`/`codex` binaries, so
`attend-boot-restore`'s launch step (`run_entry`/`resume_command`) fails
fast for every entry rather than actually resuming an agent. The harness
therefore only asserts that *some* dispatch happens and that the tool's own
JSON/lease bookkeeping stays correct — not an exact per-window apply count.
Under sustained load (200 near-simultaneous failed launches) the container's
tmux server has been observed to die outright (not reproduced with a smaller
`--entries`, not tied to any of the JSON-scale bug fixes — separate, unresolved,
low priority since it does not reflect a real reboot's launch pattern, where
most reboots restore far fewer live agents than saved sidecar entries).

## Validated scenarios

| Scenario | What it tests | Why it discriminates fixed vs old |
|----------|---------------|-----------------------------------|
| `no-crash` | Sanity: clean reboot, no crash. | Both versions should pass. |
| `dangling-symlink` | `last` symlink dangles after crash; backups/ + best.txt intact. | Both pass — old script falls back to best.txt. |
| `dangling-no-best` | `last` dangles, best.txt gone, 2000+ saves in live dir. | **OLD fails:** `find | sort | awk exit` triggers SIGPIPE → `set -e` aborts. |
| `no-backups-dir` | `backups/` dir entirely removed. | Both pass when live dir has saves. |
| `cliff-shrink` | No crash, but session shrinks 8 → 1 window across saves. | **OLD fails:** cliff guard works one save behind, doesn't catch. |
| `empty-live-dir` | First save only; live copy deleted. | **OLD fails:** post-save-backup never made backup (early-exit on first dangling-`last` save). |
| `pane-capture-skip` | Patch 3: assistant panes skipped at pane-content capture time. 4 windows (0,1 = claude stubs with marker scrollback; 2,3 = plain), `GROUPED_CLONES=20` to mirror the real many-clone env. Asserts assistant content (any clone) absent, plain content present, no `/tmp` leak. | **Buggy (newline-delimited skip set) fails:** the space-glob skip check never matches newline-separated pids, so assistant content is captured across all clones. Run buggy via `--scripts-dir <dir-with-newline-bug>`. Fixed passes 9/0. |

## Architecture

- `Dockerfile` — minimal Ubuntu 25.10 + systemd + tmux + dbus
- `harness/install-dotfiles.sh` — runs in container, sets up dotfiles via stow + writes systemd unit files with paths corrected for the test user
- `harness/populate-state.sh` — runs in container, creates tmux windows, triggers saves, simulates crash
- `harness/assert-restored.sh` — runs in container after reboot, checks 5 conditions: service result, no SIGPIPE in journal, restore log shows expected outcome, `last` symlink valid, expected window count
- `run.sh` — outside-container orchestrator
- `run-matrix.sh` — runs all scenarios × versions, tabulates discriminator/regression counts

## Reusing for other dotfiles testing

This harness is the cleanest way to test anything in dotfiles that depends on:
- systemd as PID 1 (user units, services)
- A "reboot" (container restart with state preservation)
- Stow-managed dotfiles

To add a non-tmux test:
1. Bind-mount the relevant package read-only via `DOTFILES_MOUNT` (already done — whole repo is mounted)
2. Add an install step to `install-dotfiles.sh` that stows your package and sets up your service
3. Write a populate script and assertion script that exercise the behavior
4. Add a scenario branch in `run.sh`'s case statement

The container has dbus + logind running, so `systemctl --user`, `loginctl`, etc. all work as on a real Linux desktop.

## Limitations

- **GPU passthrough deliberately not used.** The tmux test doesn't need it, and it would couple the test container to host driver state. If a future test needs GPU, follow the `~/code/anka-redactor` pattern (separate container, GPU only when needed).
- **NVIDIA toolkit / CUDA libs not installed.** Same reasoning.
- **Uses `--privileged` and `--cgroupns=host`.** This is the standard pattern for systemd-in-docker and is acceptable in an isolated test container. Don't use this image for anything user-facing.
- **The container image is fully self-contained** — building it doesn't read any host secrets or credentials. Bind mounts are read-only.

## When to rebuild the image

Image rebuild is needed when:
- `Dockerfile` changes
- `harness/*.sh` changes (they're COPY'd into the image)

The bind-mounted dotfiles repo is read live, so changes to `tmux/.config/tmux/scripts/*.sh` take effect immediately on the next `bash run.sh` — no rebuild needed.
