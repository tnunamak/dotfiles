# P0: root disk at 95% — 116.5 GB reclaimable with zero risk

Verified 2026-09-10 ~20:45 by direct measurement. This is the single highest-value
fix found so far, and it is safe.

## The situation

```
/dev/nvme0n1p5  1.4T  1.2T   69G  95% /
```

69 GB free on root. `~/code/*-waspflow-*` (132 worktree dirs) = **129 GB total**.

But the space is NOT mostly source or git objects:

- **336 `node_modules` directories inside those worktrees = 116.5 GB** (90% of it)
- ~2.5 GB per worktree, evenly spread — build artifacts, not work

## Recommended fix (safe, reversible, no git state touched)

Delete only `node_modules` inside waspflow worktrees. These are regenerable with
`npm ci` / `pnpm install`, contain no source, and are not tracked by git.

```bash
# 1. Re-verify the list before acting
find /home/tnunamak/code/*-waspflow-* -maxdepth 3 -type d -name node_modules -prune -print0 > /tmp/nm.z
tr '\0' '\n' < /tmp/nm.z | wc -l          # expect ~336

# 2. Delete
xargs -0 -a /tmp/nm.z rm -rf

# 3. Confirm
df -h /
```

Expected result: **69 GB free → ~185 GB free.**

Nothing is lost: any worktree you return to just needs a dependency install.

## Second, smaller win (optional, 25 GB) — requires judgment

38 of the 132 worktree dirs are **orphaned**: present on disk but NOT registered
in `git worktree list` for either parent repo. Total **25 GB**. List:
`/home/tnunamak/.tmp/recovery/orphans-safe-to-delete.txt`

Counts reconcile: 132 total = 92 registered + 40 orphaned; 40 orphaned − 2 with
real uncommitted work = **38 safe**.

```bash
xargs -a /home/tnunamak/.tmp/recovery/orphans-safe-to-delete.txt rm -rf
```

Note this overlaps the node_modules win above — do the node_modules pass first,
then this is only worth a few GB more. Mostly it is tidiness, not space.

## DO NOT DELETE — two orphans hold real uncommitted work

The naive "delete all orphaned worktrees" cleanup would have destroyed this:

| dir | branch | uncommitted |
|---|---|---|
| `clawmeter-waspflow-clawmeter-model-support` | `waspflow/clawmeter-model-support` | `internal/diagnose/diagnose.go` +45/−2 and `diagnose_test.go` +23 — a real change **with tests** |
| `vana-node-ops-waspflow-mainnet-phase0-sonnet-0817` | `waspflow/mainnet-phase0-sonnet-0817` | `ansible/inventory/hosts.yml`, `ansible/playbooks/README.md`, `docs/mainnet-hash-archive-rebuild.md`, `mise.toml` — 34 insertions |

**Both diffs are already backed up** to
`/home/tnunamak/.tmp/recovery/rescued-diffs/*.tracked.patch` (with HEAD sha and
status), so even a mistaken delete is now recoverable via `git apply`.

These two look like genuine unfinished work worth either committing or deliberately
dropping — your call, not mine.

## A measurement trap worth knowing about

My first scan flagged ~32 orphans as "risky" with `unpushed` counts of 243, 351,
and 50. Those numbers were **artifacts, not findings**: worktrees share the parent
repo's object store, so `git log --branches --not --remotes` inside a worktree
reports the *whole repo's* unpushed branches, not that worktree's work. Identical
counts within a repo group were the tell. Likewise the 11 and 6 stashes live in the
parent repos (`context-gateway`, `data-connectors`) — verified — so deleting
worktree dirs cannot lose them.

Only `git status --porcelain` (per-worktree, real) identified the 2 genuine cases.

## Also found

`systemctl --user --failed` → 19 failed units, mostly benign crash-handler noise:
13× `drkonqi-coredump-launcher@*`, 2× `whoopsie-upload-all@*`,
`desktop-layout-restore.service`, `systemd-tmpfiles-clean.service`, and
`pdpp-claude_code-collector.service`.

Two of those are worth a look, the rest are noise:
- **`pdpp-claude_code-collector.service`** — a real data-collection service of yours; if it should be running, this is a genuine breakage.
- **`systemd-tmpfiles-clean.service`** — failing tmpfiles cleanup plausibly *contributes to* the disk-full condition. Worth checking: `systemctl --user status systemd-tmpfiles-clean.service`.
- `desktop-layout-restore.service` — may relate to the incomplete session restore after the crash.

No broken symlinks found in `~/.claude/*` or `~/code/*`.
