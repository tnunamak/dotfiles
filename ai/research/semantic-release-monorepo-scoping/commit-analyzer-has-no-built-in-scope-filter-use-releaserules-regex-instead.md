---
title: "@semantic-release/commit-analyzer has no built-in option to require a Conventional-Commit scope before triggering a release — the workaround is a releaseRules regex, not a config flag"
date: 2026-08-20
topic: semantic-release-monorepo-scoping
tags: [semantic-release, monorepo, conventional-commits, ci-cd, npm-publish]
status: draft
sources: [commit-analyzer-issue-174, commit-analyzer-issue-252, chronicles-devto]
source_session: b9fd0b58-b353-4691-8b78-193cbb78fa5f
---

## CLAIMS

- `@semantic-release/commit-analyzer` has no native "require this scope" or "ignore
  commits without a matching scope" toggle — this is a long-standing open feature
  request, not an oversight in reading the docs. [commit-analyzer-issue-174]
- The documented workaround is `releaseRules` with a regex scope match (e.g.
  `{ "type": "fix", "scope": "/service.*/", "release": "patch" }`); a commit that
  matches no rule (neither the custom `releaseRules` nor the preset's defaults)
  triggers no release at all — this is what makes the technique work as a filter,
  not just a classifier. [commit-analyzer-issue-174]
- A more complete pattern for true multi-package monorepos programmatically builds
  `releaseRules` per package: block commits scoped to *other* tracked packages
  (`release: false`), allow commits scoped to the current package, and allow
  unscoped commits to pass through to all packages. Requires a distinct `tagFormat`
  per package (e.g. `${packageName}-v${version}`) to version independently.
  [chronicles-devto]
- There is an open, separate feature request for path-based (not scope-based)
  commit filtering — "only count commits touching this directory" — which does not
  exist natively either; a third-party wrapper (`semantic-release-monorepo`)
  achieves this by rewriting the plugin context to filter `context.commits` by
  which workspace's files a commit touched, and by walking dependency relationships
  to cascade releases when a dependency package changes. [commit-analyzer-issue-252]

## SOURCES

**commit-analyzer-issue-174**
URL: https://github.com/semantic-release/commit-analyzer/issues/174
Accessed: 2026-08-20
Quote: "the commit analyzer should only match commits with a scope like 'service/deps' and should not match commits without a scope of 'service*'"

**commit-analyzer-issue-252**
URL: https://github.com/semantic-release/commit-analyzer/issues/252
Accessed: 2026-08-20
Quote: "option to pass in a directory path or glob to filter commits by"

**chronicles-devto**
URL: https://dev.to/antongolub/the-chronicles-of-semantic-release-and-monorepos-5cfc
Accessed: 2026-08-20

## SYNTHESIS

For a repo that mixes npm-publishable packages with unrelated commit types (e.g. a
desktop-app build triggered by non-npm-scoped commits, as in PDP-Connect/data-connect),
copying another repo's `.releaserc` verbatim is wrong if that other repo publishes
everything on any `feat`/`fix`/`perf` commit (no scope gating) — that config will
misfire and cut a release on a commit that never touched the npm packages. The correct
fix, given no native support exists, is an explicit `releaseRules` allowlist requiring
one of the tracked packages' scopes (or no scope, if that repo wants unscoped commits
to count too) — not a third-party wrapper, unless the repo has enough independently
versioned packages to justify the added, unaudited dependency surface inside a
trusted-publishing (OIDC) release pipeline.
