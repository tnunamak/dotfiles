---
title: "Biome 2.5.7 does not merge files.includes across an extends chain, and overrides[] targeting .js files (but not .ts) is silently ignored under the same chain"
date: 2026-08-18
topic: biome
tags: [biome, extends, overrides, files-includes, javascript, typescript, ultracite]
status: draft
sources: [biome-docs-configure, biome-docs-big-projects, isolated-repro]
source_session: 23896aef-d22b-4cf7-90f3-5ac2c728ef83
---

## CLAIMS

- When a Biome config uses `extends` (e.g. `extends: ["ultracite/biome/core", "ultracite/biome/type-aware"]`), the local config's own top-level `files.includes` array REPLACES rather than merges with the extended config's `files.includes` — a local `files.includes` containing only negative (`!`/`!!`-prefixed) patterns and no positive `"**"` entry silently falls back to matching everything, not "everything except these excludes." [isolated-repro]
- Adding an explicit `"**"` as the first entry of the local `files.includes` array does NOT fix this — the exclude patterns still fail to take effect when `extends` is present, even though the identical array (with or without the leading `"**"`) works correctly with `root: true` and no `extends`. [isolated-repro]
- `overrides[]` entries that set `linter`/`formatter` config scoped to `.ts` files (e.g. disabling `noAwaitInLoops` for `src/**/*.ts`) work correctly under this same `extends` chain — confirmed both by isolated repro and by observing a real Biome invocation's diagnostics. [isolated-repro]
- `overrides[]` entries scoped to `.js` files specifically (same syntax, same `includes` glob shape, targeting `.js` instead of `.ts`) do NOT take effect under the same `extends` chain, whether using `formatter.enabled: false`, `linter.enabled: false`, or the more specific `javascript.formatter.enabled: false` — even when placed as the first entry in the `overrides` array (Biome docs state the first matching override wins). This reproduces with `root: true` + `extends` present, and does NOT reproduce with `root: true` and no `extends` (the same override correctly excludes the `.js` file). [isolated-repro]
- Passing an explicit file path on the Biome CLI (`biome check path/to/file.js`) always checks that file regardless of `files.includes` config — CLI-specified paths bypass includes/excludes. `--config-path` also does not change this. [biome-docs-configure]
- `biome check`'s own `--only`/`--skip` flags for rule-level filtering do not interact with or fix either bug above (tested independently). [isolated-repro]
- `.biomeignore` files and git's local exclude (`.git/info/exclude`) have no effect on Biome 2.x's file selection — Biome 2.x replaced `.biomeignore` with the `files.includes` mechanism. [isolated-repro]

## SOURCES

**biome-docs-configure**
URL: https://biomejs.dev/guides/configure-biome/
Accessed: 2026-08-18
Quote: "Paths and globs inside Biome's configuration file are resolved relative to the folder the configuration file is in. An exception to this is when a configuration file is extended by another."

**biome-docs-big-projects**
URL: https://biomejs.dev/guides/big-projects/
Accessed: 2026-08-18
Quote: "Entries defined in extends are resolved from the path where the biome.json file is defined and are processed in order, with settings in later files overriding earlier ones... if a file can match three patterns, only the first one is used."

**isolated-repro**
URL: (local, not a web source — minimal repro built during this session)
Accessed: 2026-08-18
Quote: "Checked 698 files" (unchanged regardless of files.includes content) vs "Checked 699 files" (root:true, no extends, same includes array) — the file-discovery count is identical whether files.includes excludes the target files or not, when extends is present.

## SYNTHESIS

This is a real, confirmed defect (or at minimum severe undocumented limitation) in Biome
2.5.7's config-merging when `extends` is combined with either top-level `files.includes` or
`overrides[]` for `.js`-extension files. It cost roughly half a day of investigation on the
`data-connectors` repo (Move A / PDPP) because the symptom masquerades as "our exclude glob is
wrong" when the glob is actually correct and the merge semantics are the real problem.

Practical implications for any `ultracite`/multi-layer Biome config:
1. If a package's `biome.jsonc` uses `extends` (near-universal with `ultracite`) and needs its
   own excludes beyond what the extended config already covers, do NOT rely on the local
   `files.includes` array — it silently no-ops. Verify with `biome check . --max-diagnostics=1`
   and check the "Checked N files" count actually drops when adding an exclude.
2. `.ts`-scoped `overrides[]` for rule toggles (the common case: disabling one lint rule for
   one path glob) work fine under `extends` — this is the well-trodden path and is safe to use.
3. `.js`-scoped `overrides[]` (formatter/linter enable-toggling specifically) is NOT safe under
   `extends` — don't trust it without testing. If a package needs to protect specific `.js`
   files from Biome's formatter (e.g. raw-data-shaped fixture files using `.js` extension for a
   real-world reason, like Twitter's archive export format), the only proven-working
   workaround found was a wrapper script around `biome check --reporter=json` that filters a
   checked-in, exact-path exception list out of the diagnostics before computing the exit code
   — see `scripts/check-biome.ts` in the `data-connectors` repo (commit
   `14d582c` on `move-a-polyfill-connectors`) for a working implementation.
4. Before filing an upstream Biome issue: worth checking if this reproduces on a newer Biome
   version than 2.5.7 first, since this project pins that exact version.
