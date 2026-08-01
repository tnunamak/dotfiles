---
title: "With a same-filesystem warm pnpm store, each extra git-worktree `pnpm install` costs ~100 MB + ~5 s (symlink/dir metadata + a few copied files), NOT the package bytes — so per-worktree dedup is already ~solved; the real N-worktree cost drivers are postinstall side effects and install wall-time, addressed by skipping the browser download + `--frozen-lockfile --offline`, with `enableGlobalVirtualStore` the near-zero-metadata endgame (pnpm v11 only)"
date: 2026-07-11
topic: monorepo-tooling
tags: [pnpm, git-worktree, node_modules, hardlink, content-addressable-store, package-import-method, enableGlobalVirtualStore, reflink, ext4, patchright, playwright, waspflow, pdpp, multi-agent]
status: draft
sources: [pnpm-git-worktrees, pnpm-global-virtual-store, pnpm-package-import-method, pnpm-faq-store-drive, pnpm-reflink, observed-pdpp-machine, gitworktree-org-node-modules]
source_session: 00c8971f-a662-42f0-9b0c-861e142db76b
---

<!--
Answers: "N parallel git-worktree agent workers on one pnpm monorepo each run
`pnpm install` — how to avoid duplicated disk/time/network?" Split OBSERVED (on
Tim's machine, 2026-07-11, pnpm 10.33.0, pdpp) from DOCUMENTED convention. The
headline: after pnpm's built-in hardlink dedup the disk problem is already small;
the leverage is postinstall + wall-time, then enableGlobalVirtualStore once on
pnpm v11. Re-verify the machine numbers before relying on them — store contents,
pnpm version, and FS layout drift.
-->

## CLAIMS

### What pnpm already dedupes (the baseline) — OBSERVED on this machine

- The pnpm content-addressable store is GLOBAL and single: `pnpm store path` = `/home/tnunamak/.local/share/pnpm/store/v11` (2.9 GB), one store shared by every project/worktree. [observed-pdpp-machine]
- The store and the worktrees are on the SAME filesystem — both `/dev/nvme0n1p5` (ext4, mounted `/`), including the `~/.tmp/pdpp-*` waspflow worktrees. Same FS is the precondition for hardlinking. [observed-pdpp-machine]
- Hardlinking is actually happening (not silently copying): a sample package file (`clean-stack@5.3.0/.../index.js`) in a warm worktree has `st_nlink = 89` and shares the SAME inode (14927767) across the main checkout and a `~/.tmp` worktree. 23 worktrees had that package materialized; one inode backs them all. [observed-pdpp-machine]
- The genuine incremental disk of the Nth identical worktree install is small: adding a 2nd byte-identical warm install to the FS raised `df` used by only ~98 MB (measured as a real disk-used delta, the honest number). The apparent `du -sh node_modules` = 1.6 GB is almost entirely hardlinked-shared bytes counted once. [observed-pdpp-machine]
- Of that ~98 MB, only ~6 MB is genuinely-new file BYTES: just 853 files in `.pnpm` have `st_nlink == 1` (pnpm copied, not hardlinked, e.g. patched/rewritten files); the rest of the ~98 MB is inode/directory/symlink METADATA — per worktree ≈ 52k regular files, 3.3k symlinks, 9.4k directories. [observed-pdpp-machine]
- A warm, offline, frozen-lockfile install in a fresh worktree took ~5 s wall (`pnpm install --frozen-lockfile --prefer-offline`, ~20 MB fs-output). So per-worktree install is cheap in BOTH disk and time once the store is warm. [observed-pdpp-machine]

### The real cost drivers for N worktrees — OBSERVED / DOCUMENTED

- Store bytes: ~0 incremental per worktree when store is shared + warm + same-FS. NOT a driver here. [observed-pdpp-machine]
- Per-worktree `.pnpm` metadata (symlinks/dirs) × N: the dominant DISK cost, but it is only ~100 MB/worktree — small vs a naive full copy (~1.6 GB/worktree). [observed-pdpp-machine]
- `pnpm install` wall-time × N (~5 s each even offline): a real but modest driver; parallelizable. [observed-pdpp-machine]
- Cold-store network fetches: a driver ONLY if a worktree's lockfile differs from what's in the warm store (new/changed deps); identical lockfiles fetch nothing. [observed-pdpp-machine]
- Postinstall side effects that do NOT dedupe are the sharp edge: pdpp `packages/polyfill-connectors` has `"postinstall": "node ./scripts/install-patchright-browser.mjs"`, which shells `patchright install chromium`. The browser lands in the SHARED Playwright cache (`~/.cache/ms-playwright`, 1.9 GB, one copy across all worktrees), so bytes dedupe — but the postinstall STILL runs (spawns) per worktree unless skipped, and on a cold cache it downloads. `PATCHRIGHT_SKIP_BROWSER_DOWNLOAD=1` / `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1` short-circuits it (the script honors both). [observed-pdpp-machine]
- `node_modules` is `.gitignore`d, so each new worktree starts with NO `node_modules` and each agent runs its own install. waspflow itself only does `git worktree add` (see `lib/worktree.sh`); it does NOT run `pnpm install`, so the install policy (offline flags, skip-download) is set by whatever wraps the agent, not by waspflow. [observed-pdpp-machine]

### package-import-method and reflink — OBSERVED / DOCUMENTED

- `package-import-method` values: `auto` (default) tries clone(reflink)→hardlink→copy; `hardlink`, `clone`, `copy`, `clone-or-copy`. `clone` = copy-on-write (reflink / APFS clone). [pnpm-package-import-method]
- On this machine `package-import-method` is unset (= `auto`), and the FS is ext4 which does NOT support reflinks: `cp --reflink=always` fails "Operation not supported". So `clone` cannot help here; `auto` correctly resolves to hardlink, which is what was observed. Setting `package-import-method=clone` would be counterproductive on ext4. [observed-pdpp-machine][pnpm-reflink]
- The hard requirement: the store must be on the same drive/FS as the install, else pnpm COPIES instead of links. This is the classic silent killer (e.g. store on `/` but worktrees on a different mount) — NOT triggered here because everything is on one ext4 volume. [pnpm-faq-store-drive]

### The documented solution for exactly this use case — DOCUMENTED

- pnpm ships an official page "pnpm + Git Worktrees for Multi-Agent Development" recommending: a bare-repo hub with per-branch worktrees, plus `enableGlobalVirtualStore: true` in `pnpm-workspace.yaml`, plus helper scripts (`pnpm worktree:new`, `shell/wt.sh`). The pnpm repo itself uses this. [pnpm-git-worktrees]
- `enableGlobalVirtualStore: true` removes the per-project `.pnpm` directory entirely: each worktree's `node_modules` becomes only SYMLINKS into a single shared virtual store at `<store-path>/links/`. This eliminates the per-worktree metadata cost (the ~100 MB × N above) and makes new-worktree installs near-instant. [pnpm-global-virtual-store]
- Status/caveat: `enableGlobalVirtualStore` is EXPERIMENTAL and disabled by default for project installs as of pnpm v11 (auto-on only for `pnpm dlx` / global installs). This machine runs pnpm 10.33.0 — the flag is NOT available without upgrading to v11. Trust caveat: "Do not use one writable pnpm store for mutually untrusted agents or users." ESM caveat: it can break `NODE_PATH`-based hoisting workarounds. [pnpm-global-virtual-store][pnpm-git-worktrees]

### Manual node_modules sharing — DOCUMENTED

- Symlinking one worktree's `node_modules` into another is explicitly discouraged: it only works if both branches have IDENTICAL dependencies; when deps diverge, the sharing worktree silently gets wrong versions → hard-to-debug breakage. The store-based approach is the safe alternative. This correctness caveat applies to ANY "share the parent's node_modules read-only across branches" scheme. [pnpm-git-worktrees][gitworktree-org-node-modules]

## SOURCES

**pnpm-git-worktrees**
URL: https://pnpm.io/git-worktrees
Accessed: 2026-07-11
Quote: "each worktree's node_modules contains only symlinks into a single content-addressable store on disk." / "Do not use one writable pnpm store for mutually untrusted agents or users."

**pnpm-global-virtual-store**
URL: https://pnpm.io/global-virtual-store
Accessed: 2026-07-11
Quote: "Both projects symlink directly to the same location in the global virtual store. There's no per-project .pnpm directory." (Experimental / disabled by default for project installs in v11; auto-on for dlx + global installs.)

**pnpm-package-import-method**
URL: https://pnpm.io/faq (and settings docs)
Accessed: 2026-07-11
Quote: auto (default) = "try to clone or hardlink the packages, if it fails, fallback to copy"; modes: hardlink | copy | clone | clone-or-copy | auto.

**pnpm-faq-store-drive**
URL: https://pnpm.io/faq
Accessed: 2026-07-11
Quote: "the package store should be on the same drive and filesystem as installations, otherwise packages will be copied, not linked."

**pnpm-reflink**
URL: https://github.com/pnpm/reflink
Accessed: 2026-07-11
Quote: pnpm's @reflink/reflink clones files via CoW on reflink-capable filesystems (Btrfs subvolumes, APFS); not available on plain ext4.

**observed-pdpp-machine**
URL: (local, Tim's machine — not a URL)
Accessed: 2026-07-11
Quote: measured — store `/home/tnunamak/.local/share/pnpm/store/v11` (2.9 GB) on `/dev/nvme0n1p5` ext4; worktree package file st_nlink=89 sharing inode 14927767 with main checkout; 2nd identical worktree install = ~98 MB df-used delta, ~6 MB of new file bytes (853 nlink==1 files), ~5 s wall with `--frozen-lockfile --prefer-offline`; ext4 `cp --reflink=always` = "Operation not supported"; pdpp `packages/polyfill-connectors` postinstall shells `patchright install chromium` into shared `~/.cache/ms-playwright`; waspflow `lib/worktree.sh` does git worktree add only, no install; pnpm 10.33.0.

**gitworktree-org-node-modules**
URL: https://www.gitworktree.org/guides/node-modules
Accessed: 2026-07-11
Quote: node_modules is gitignored → per-worktree; sharing across branches with divergent deps causes version conflicts; pnpm's content-addressable store is the safe way to avoid duplication.

## SYNTHESIS

The instinct "N worktrees each drag in a massive node_modules" is mostly already solved by
pnpm on THIS machine, and the solving is silent: one global content-addressable store on the
same ext4 volume as the worktrees, so `auto` import-method resolves to hardlink and each extra
worktree costs ~100 MB of metadata (not ~1.6 GB of bytes) and ~5 s. The single most important
thing to VERIFY (not assume) is the same-FS invariant — if the store and the worktrees ever land
on different mounts, pnpm silently switches to copy and every worktree balloons. Here they don't.

So the ranked recommendation, machine-specific:

1. Confirm and hold the same-FS + warm-store invariant (already true). Nothing to change; this
   is the biggest win and it's already banked. Guard: keep the store and `~/.tmp` on `/`.
2. Make each per-worktree install cheap and side-effect-free: run `pnpm install --frozen-lockfile
   --prefer-offline` (or `--offline`) with `PATCHRIGHT_SKIP_BROWSER_DOWNLOAD=1` +
   `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1` exported for agents that don't drive a browser. This kills
   the only non-deduping per-worktree cost (the patchright postinstall spawn/download) and removes
   resolution/network from the ~5 s. Best home for this is the waspflow spawn wrapper, since
   waspflow itself doesn't install.
3. Do NOT set `package-import-method=clone` — ext4 has no reflink, so clone can't beat hardlink
   here (it would only add fallback-to-copy risk). Leave it `auto`.
4. Endgame for the metadata cost (the ~100 MB × N): `enableGlobalVirtualStore: true` collapses the
   per-worktree `.pnpm` into pure symlinks into `<store>/links/`, making new worktrees near-free in
   both disk and time. BUT it needs pnpm v11 (this box is 10.33.0) and is still experimental — so
   it's a "when you upgrade" move, not today. It is the officially-blessed answer to precisely this
   multi-agent-worktree problem.
5. Avoid manual node_modules symlink-sharing across worktrees. Correctness caveat is real: divergent
   branch deps → silent wrong versions. The store already gives you the sharing safely; don't
   reinvent it unsafely.

Honest verdict on problem size: after pnpm's built-in dedup this is a SMALL problem on this machine
— roughly 100 MB and 5 s per worktree, dominated by inode/symlink metadata and (if not skipped) a
postinstall spawn. It only becomes a big problem if the same-FS invariant breaks (→ full copies) or
the browser download runs cold per worktree. The exotic schemes (bare-repo layout,
enableGlobalVirtualStore, CoW clone) are worthwhile polish, not the fix for a bleeding wound.
