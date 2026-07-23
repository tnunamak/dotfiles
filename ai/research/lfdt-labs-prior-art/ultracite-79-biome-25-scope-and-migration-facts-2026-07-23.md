---
title: "Ultracite 7.9 / Biome 2.5 official-doc facts for a uniform monorepo upgrade (scope, JS linting, !!/! ignores, no migration-path)"
date: 2026-07-23
topic: lfdt-labs-prior-art
tags: [ultracite, biome, files-includes, legacy-js, force-ignore, monorepo-upgrade, pdpp]
status: draft
sources: [ultracite-biome-provider, ultracite-languages, ultracite-docs, ultracite-troubleshooting, biome-no-first-exception, biome-configuration, ultracite-releases, biome-v2-3, ultracite-v6-upgrade]
---

## CLAIMS

- Ultracite's base config INTENTIONALLY uses `files.includes: ["**", ...]` (match all, subtract curated generated/build ignores). NOT a 7.9 regression — predates 7.6. [ultracite-biome-provider]
- Ultracite lints JS AND TS as first-class in one pass; NO documented "TS-only" posture, NO named JS→TS incremental-migration mode. Excluding `.js` via `!**/*.js` is an UNDOCUMENTED judgment call, not a blessed pattern. [ultracite-languages] [ultracite-docs]
- Project `biome.jsonc` narrows scope by adding its own `files.includes` with `!` negations, ALWAYS led by `**` (else 0 files match — enforced by biome rule `noBiomeFirstException`). [ultracite-troubleshooting] [biome-no-first-exception]
- `extends` + project `files.includes` = MERGE (combined across chain), reliable only for SINGLE-level extend (project → ultracite/biome/core). Multi-hop chains drop `files.includes` (ultracite 7.6.1 bug + fix). [biome-configuration] [ultracite-releases]
- `!!` force-ignore (Biome 2.3+, official) = fully excluded incl. scanner indexing (use for dist/build). `!` single = lint/format-ignored but still indexed (use for generated-but-relevant). Deprecates `files.experimentalScannerIgnores`. [biome-configuration] [biome-v2-3]
- `files.maxSize` default = 1048576 (1MB); raise it or exclude the file (a 1.5MB openapi JSON was flagged). [biome-configuration]
- 7.6→7.9 changes: 7.6.1 fixed project files.includes overrides; 7.9.0 = Biome 2.5.2 + enabled noShadow/noUnnecessaryConditions/useDestructuring/useArrayFind; 7.9.4 = Biome 2.5.3. Scope mechanics UNCHANGED; new diagnostics come from newly-enabled RULES, not scope. [ultracite-releases]
- NO official ultracite/biome migration guidance for diagnostic explosion on large codebases — plan your own staged rollout. [ultracite-v6-upgrade]

## SOURCES

**ultracite-biome-provider**
URL: https://www.ultracite.ai/docs/provider/biome
Accessed: 2026-07-23

**ultracite-languages**
URL: https://www.ultracite.ai/docs/languages
Accessed: 2026-07-23

**ultracite-docs**
URL: https://www.ultracite.ai/docs/
Accessed: 2026-07-23

**ultracite-troubleshooting**
URL: https://www.ultracite.ai/docs/troubleshooting
Accessed: 2026-07-23

**biome-no-first-exception**
URL: https://biomejs.dev/linter/rules/no-biome-first-exception/
Accessed: 2026-07-23

**biome-configuration**
URL: https://biomejs.dev/reference/configuration/
Accessed: 2026-07-23

**ultracite-releases**
URL: https://github.com/haydenbleasel/ultracite/releases
Accessed: 2026-07-23

**biome-v2-3**
URL: https://biomejs.dev/blog/biome-v2-3/
Accessed: 2026-07-23

**ultracite-v6-upgrade**
URL: https://www.ultracite.ai/docs/upgrade/v6
Accessed: 2026-07-23

## SYNTHESIS

Tim's "no legacy anything" + ultracite's JS-is-first-class design AGREE: the workspace TS-only `files.includes` was the project deferring legacy JS; the correct modern posture is migrate JS→TS and lint everything. Exclude ONLY genuine artifacts (build/generated/fixtures/captured-DOM/.pdpp-data/reports) via `!!`(build) / `!`(generated-relevant). Raise files.maxSize for the openapi JSON. Execute per-workspace, single-level extend only (ultracite/biome/core direct — no intermediate shared config, per the 7.6.1 merge gap). ref-impl last behind its behavioral suite.
