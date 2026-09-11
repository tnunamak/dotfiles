---
title: "semantic-release merges the repo's own .releaserc over any --extends config, so a CLI --extends file cannot override plugins the repo file already defines; pass options programmatically (or make the override the found config) instead"
date: 2026-09-10
topic: semantic-release-monorepo-scoping
tags: [semantic-release, extends, get-config, workflow_dispatch, choice-input, actionlint]
status: draft
sources: [sr-get-config, gh-choice-empty]
source_session: dd24f6bb-c6a6-4bec-af33-8f527c823738
---

## CLAIMS
- In semantic-release 25.0.9 `lib/get-config.js`, options are built as `{ ...config, ...cliOptions }` (config = the cosmiconfig hit, e.g. `.releaserc.yaml`), then `extends` is loaded and merged as `{ ...extendsOptions, ...options }`: every key the repo file defines wins over the extended file, `plugins` included. [sr-get-config]
- Verified by execution against the installed loader: with `.releaserc.yaml` present in cwd, `getConfig(ctx, { extends: forced.json })` resolved the repo's commit-analyzer `releaseRules`; in a cwd without `.releaserc.yaml` the same call resolved the extended file's rules; `getConfig(ctx, { plugins: forced.plugins })` (the programmatic-API shape, cliOptions) resolved the forced rules. [sr-get-config]
- Consequence: `npx semantic-release --extends <alt-config>` is NOT a way to swap `plugins`/`branches`/`tagFormat` for one run when the repo already has a release config; it only fills keys the repo file omits. [sr-get-config]
- GitHub `workflow_dispatch` `type: choice` inputs with an empty-string option (`options: ["", "patch", ...]`) are rejected by actionlint (`string should not be empty [syntax-check]`) and reported by users as buggy in the dispatch form, especially with `default`/`required`; the conventional shape is a sentinel first option such as `none`. [gh-choice-empty]

## SOURCES
**sr-get-config**
URL: https://github.com/semantic-release/semantic-release/blob/v25.0.9/lib/get-config.js
Accessed: 2026-09-10
Quote: "let options = { ...config, ...cliOptions };" … "return { ...result, ...extendsOptions }; }, {})), ...options, };"

**gh-choice-empty**
URL: https://github.com/orgs/community/discussions/172518
Accessed: 2026-09-10
Quote: "physically I can use an empty string its just that its really buggy when setting other options (default, required etc) even completely breaks the entire page in some cases"

## SYNTHESIS
`--extends` is designed for shareable base configs that the repo file refines, so precedence runs repo-file > extends. A "forced release" or any per-run override that writes an alternate config and passes it via `--extends` silently does nothing whenever the repo has its own `.releaserc*`; the run looks normal and the ordinary rules apply. Found while gating PDP-Connect/data-connect #95, where the forced path would have reported "scope gate bypassed" while publishing nothing. Working alternatives: call `semanticRelease(options, { cwd, env })` programmatically with the override in `options` (cliOptions win over the file), or ensure the override is the config cosmiconfig finds first. Any test of such an override must go through `get-config.js`, not the config builder, or it cannot see this. Unrelated but from the same review: don't use `""` as a `choice` option in `workflow_dispatch`; use a sentinel.
