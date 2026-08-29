---
title: "mise (formerly rtx) ships a built-in `mise prune` command that safely removes tool-version installs no longer referenced by any tracked config file, so a disk-cleanup script should delegate to it rather than reimplement version-liveness detection"
date: 2026-08-29
topic: dev-tool-caches
tags: [mise, rtx, version-manager, prune, dev-tools, disk-cleanup]
status: draft
sources: [empirical-repro, mise-help-output]
source_session: a253134e-8cd3-4ed2-a541-bea105c07228
---

## CLAIMS

- `mise` stores installed tool versions under `~/.local/share/mise/installs/<tool>/<version>/` (confirmed via `mise ls --prunable` output referencing this path pattern and `mise prune --dry-run`'s own example output). [empirical-repro]
- `mise prune [--dry-run|-n] [--dry-run-code] [--tools] [--configs] [INSTALLED_TOOL...]` is a real, documented subcommand (confirmed via `mise prune --help` on a live install, mise 2026.8.14). Its own help text states the mechanism precisely: mise tracks every config file (`.mise.toml`, `.tool-versions`, etc.) it has ever been invoked against in `~/.local/state/mise/tracked-configs`; a version is prunable once it is no longer the version specified as current by ANY tracked config. Versions installed via `MISE_<TOOL>_VERSION` env vars or ad hoc `mise exec <tool>@<version>` invocations are also prunable once no longer referenced this way. [mise-help-output]
- `mise prune --dry-run` produces a fully self-explanatory, per-version justification — on a real machine it printed `mise node@22.11.0 is prunable: node is required at 24.19.0 by ~/.config/mise/config.toml` for each of two superseded Node.js versions, followed by the exact `rm`-equivalent actions it would take (uninstall, remove the install dir, remove the matching entry under `~/.cache/mise/<tool>/<version>`). [empirical-repro]
- `mise ls --prunable` lists exactly the versions `mise prune` would remove, independent of running the prune itself — usable as a pure read-only probe (analogous to a `du`-based size probe pattern) before deciding whether to offer the action at all. [empirical-repro]
- `mise prune --dry-run-code` is documented as returning exit code 1 if there is anything prunable and 0 otherwise, specifically for scripting ("This is useful for scripts to check if tools need to be pruned"), making it a clean drop-in for a shell script's existing `count|bytes` two-value probe convention. [mise-help-output]
- Tool stubs (versions invoked via a shim/stub mechanism, tracked separately in `~/.local/state/mise/tracked-stubs`) are excluded from pruning even if not referenced by a config file, which specifically protects one-off `mise exec`/ad hoc invocations from being pruned out from under active use. [mise-help-output]

## SOURCES

**empirical-repro**
URL: n/a (local reproduction, mise 2026.8.14 linux-x64, live installation with 2 real installed Node.js versions)
Accessed: 2026-08-29
Quote: "mise node@22.11.0 is prunable: node is required at 24.19.0 by ~/.config/mise/config.toml / mise node@22.11.0 [dryrun]  uninstall / mise node@22.11.0 [dryrun]  remove ~/.local/share/mise/installs/node/22.11.0 / mise node@22.11.0 [dryrun]  remove ~/.cache/mise/node/22.11.0"

**mise-help-output**
URL: n/a (local `mise prune --help` output, mise 2026.8.14)
Accessed: 2026-08-29
Quote: "mise tracks which config files have been used in ~/.local/state/mise/tracked-configs. Versions which are no longer the latest specified in any of those configs are deleted... You can list prunable tools with `mise ls --prunable`" / "--dry-run-code  Like --dry-run but exits with code 1 if there are tools to prune"

## SYNTHESIS

This is the cleanest possible case for delegation over reimplementation in a disk-cleanup tool: mise's own maintainers have already built and shipped exactly the "is this version still needed, and by what" liveness check that a bash script would otherwise have to reconstruct fragilely (globbing for `.mise.toml`/`.tool-versions` files across a code root, parsing version pins, handling ranges/aliases) — and mise's version is authoritative because it tracks every config it has actually been invoked against, not just what a filesystem walk happens to find.

The one honest caveat (also present in mise's own design, not a script limitation): `mise prune` is blind to a config file mise has never been run against — e.g. a cloned-but-never-`cd`-into project pinning an old version. This is a narrow, low-consequence gap (worst case: that project's pinned version gets pruned, and `mise install` re-fetches it transparently on next use — mise's whole design assumes versions are re-fetchable, so this degrades gracefully rather than silently breaking something). This does NOT justify adding a bespoke supplementary scan; it justifies trusting the delegation as-is, same as how the existing `nvm_versions` category in this codebase already accepts an equivalent scope: "keep default + currently-in-PATH, prune the rest," without independently scanning every project's `.nvmrc`.

For a cleanup tool integration: probe via `mise ls --prunable` (or `mise prune --dry-run-code`, checking exit code) to get a count/estimate without side effects, and execute via `mise prune -y` (mise's own global `--yes`/`-y` flag answers its own confirmation prompts) rather than reimplementing the deletion loop — the tool becomes a thin, correctly-scoped wrapper instead of a second source of truth for "is this version safe to delete."
