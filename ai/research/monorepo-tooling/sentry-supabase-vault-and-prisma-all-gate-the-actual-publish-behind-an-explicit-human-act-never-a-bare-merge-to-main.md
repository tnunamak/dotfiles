---
title: "Sentry, Supabase, HashiCorp Vault, and Prisma all gate the actual library/app publish behind an explicit human act — never a bare merge-to-main — and mostly avoid app/library version coupling by using separate repos rather than in-repo path filters"
date: 2026-09-11
topic: monorepo-tooling
tags: [release-engineering, versioning, monorepo, github-actions, ci-cd, workflow-dispatch]
status: draft
sources: [sentry-craft, supabase-cli-js, hashicorp-vault-crt, prisma-orm-versioning]
source_session: 6752a63b-8db6-4cba-b8ad-2508ccf816a6
---

## CLAIMS

- getsentry/sentry (CalVer'd, Docker-only self-hosted/SaaS app, no PyPI packaging) and getsentry/sentry-javascript (lockstep-SemVer SDK monorepo, ~40 packages sharing one version via a root `.version.json`) are fully separate repos/release trains under one shared release *tool*, `getsentry/craft`; both gate the real publish on `workflow_dispatch` (manual `version`/`force`/`merge_target` inputs) or on merging a specifically-named `prepare-release/VERSION` PR — never a bare push-to-main. [sentry-craft]
- supabase/supabase (studio dashboard + docs) ships only a weekly-cron-triggered Docker image with no SemVer and zero npm publishing; supabase/cli and supabase/supabase-js are separate repos on independent version lines (`v2.118.0-beta.25` vs `v3.0.0-next.29`) with no shared version number. [supabase-cli-js]
- supabase-js's stable-release job is the strictest human-gate found in this sweep: it only runs on `workflow_dispatch`, and additionally queries the GitHub API in-workflow (`teams.getMembershipForUserInOrg`) to hard-fail (`exit 1`) unless the triggering actor belongs to the `@supabase/admin` or `@supabase/sdk` GitHub team — enforced in the workflow itself, not just via branch-protection UI. [supabase-cli-js]
- supabase/cli uses semantic-release driven by conventional commits on push to `develop`/`main` (auto-computed version bump, no separate approval step beyond normal PR review) — i.e. one repo in the same company uses "automatic on push" while a sibling repo enforces "manual + team-membership check," for the same overall product. [supabase-cli-js]
- HashiCorp Vault versions its `api` and `sdk` Go submodules (nested in the same repo, each own `go.mod`) on numeric lines with zero correspondence to vault core (`v2.1.0` core vs `api/v1.23.0` vs `sdk/v0.25.1`), using Go's module-subpath tag convention (`<subpath>/vX.Y.Z`) — the only mechanism in this sweep that requires no CI workflow at all to keep versions decoupled, because a Go module has no separate "publish" step beyond pushing a tag (the Go module proxy just discovers it). [hashicorp-vault-crt]
- Vault core's own release runs through a heavyweight, promotion-gated, cross-repo pipeline (`.release/ci.hcl`: `merge`→`build`→`prepare` [delegates to a separate `hashicorp/crt-workflows-common` repo]→`enos-release-testing-oss`), scoped only to `main`/`release/**` — structurally incapable of touching the `api`/`sdk` submodules since no workflow references them. [hashicorp-vault-crt]
- terraform-plugin-sdk and terraform-plugin-framework are fully separate repositories from hashicorp/terraform (not subdirectories), sidestepping app/library version coupling the same way Supabase does — by never sharing a repo, rather than by any in-repo gating logic. [hashicorp-vault-crt]
- prisma/orm (renamed from prisma/prisma) enforces hard lockstep across every workspace package via one root `package.json` version, explicitly to preserve a "one read of root package.json tells you the version of everything" invariant (quoted rationale) — but the user-facing `prisma` CLI now lives in a fully separate repo, `prisma/prisma-cli`, whose version is aligned to prisma/orm's only by an explicit, dated "operator ruling," not automatic coupling. [prisma-orm-versioning]
- prisma/orm auto-publishes an npm `dev` dist-tag on every push to main with an unchanged root version (no human step), but only publishes to the `latest` dist-tag when a maintainer merges a `chore(release): ...` PR — i.e. dev-channel is fully automatic, stable-channel publish is gated on a human-merged PR, and a pre-publish check hard-fails the release if `-dev.` versioned dependencies would leak into a CLI release (an incident-driven guardrail: they cite a past release, `prisma@8.0.0-rc.3`, that shipped two dev-dependency leaks "because nothing looked"). [prisma-orm-versioning]

## SOURCES

**sentry-craft**
URL: https://github.com/getsentry/sentry (`.craft.yml`, `.github/workflows/release.yml`) and https://github.com/getsentry/sentry-javascript (`.version.json`, `.craft.yml`, `.github/workflows/release.yml`, `auto-release.yml`, `canary.yml`)
Accessed: 2026-09-11
Quote: "we only have this here to make uv happy which we intend to use for dependency management, not packaging" (sentry's `pyproject.toml` version-field comment, confirming no PyPI packaging); sentry's `.craft.yml`: `versioning: policy: calver`; sentry-javascript `.version.json`: `{"version": "10.67.0", "_comment": "Auto-generated by scripts/bump-version.js. Used by the gitflow sync workflow to detect version bumps."}`

**supabase-cli-js**
URL: https://github.com/supabase/supabase (`.github/workflows/publish_image.yml`) and https://github.com/supabase/cli (`.github/workflows/release.yml`) and https://github.com/supabase/supabase-js (`.github/workflows/publish.yml`)
Accessed: 2026-09-11
Quote: supabase-js `publish.yml` release-stable job: `if: github.event_name == 'workflow_dispatch' && github.event.inputs.version_specifier != ''`, and an in-workflow team check that fails with "You must be a member of @supabase/admin or @supabase/sdk"; supabase/cli `release.yml` manual-recut comment: "Use it when: a previous release published stale bytes under a version that semantic-release keeps re-computing... or a downstream step (GH release, brew, scoop) failed after npm published."

**hashicorp-vault-crt**
URL: https://github.com/hashicorp/vault (`api/go.mod`, `sdk/go.mod`, `.release/ci.hcl`, tags via `gh api repos/hashicorp/vault/tags`) and https://github.com/hashicorp/terraform-plugin-sdk, https://github.com/hashicorp/terraform-plugin-framework
Accessed: 2026-09-11
Quote: tag namespaces observed directly: core `v2.1.0`, `api/v1.23.0`, `sdk/v0.25.1` coexisting with no numeric correspondence; `.release/ci.hcl` `github.release_branches = ["main", "release/**"]` with a `depends` chain `merge`→`build`→`prepare` (delegating to `hashicorp/crt-workflows-common`)→`enos-release-testing-oss`.

**prisma-orm-versioning**
URL: https://github.com/prisma/orm (`docs/oss/versioning.md`, root `package.json`, `.github/workflows/publish.yml`) and https://github.com/prisma/prisma-cli (`docs/oss/versioning.md`)
Accessed: 2026-09-11
Quote: "Every workspace package — publishable, private, the workspace root, and example apps — carries the same `version`. One read of root `package.json` answers 'what version is this code?' for the entire repository."; prisma-cli's versioning doc: "ported from prisma/prisma by operator ruling (2026-08-10): this repo adopts that versioning machinery and its version number"; incident citation: "`prisma@8.0.0-rc.3` shipped two of them... because nothing looked."

## SYNTHESIS

This extends the existing `monorepo-tooling` findings (esp. [[independent-versioning-tools-all-default-to-name-qualified-tags-and-semantic-release-tagformat-collides-with-a-hand-tagged-desktop-app]] and [[tauri-and-electron-run-opposite-versioning-models-crate-npm-cli-numbers-drift-independently-in-tauri-while-electron-is-one-package-with-chromium-locked-cadence]]) with a second, orthogonal axis: not just *how* projects keep version numbers/tags from colliding, but *what actually gates the publish action itself*. Across five ecosystems (Sentry, Supabase, Grafana [previously captured], HashiCorp, Prisma) the near-universal answer is: **automatic build/test on every push is fine and common, but the actual artifact-publish step is always either (a) restricted to a different repo entirely, so there is no shared trigger surface, or (b) explicitly gated on a human action** — a `workflow_dispatch` with required inputs, a named release-prep PR merge, or (Supabase's case) an in-workflow GitHub-team-membership check that fails the job outright for unauthorized actors. No project in this sweep auto-publishes a *stable* release purely from a conventional merge to main; supabase/cli's semantic-release is the closest to "automatic," but even that only fires on conventional-commit signal, not unconditionally, and still requires normal PR-merge review.

The clearest structural insight for a repo (like PDP-Connect/data-connect) shipping both a desktop app and npm libraries: separating app and libraries into different repos (Supabase's approach, and Terraform's for plugin SDKs) eliminates the coupling problem by construction — no path filters, no version-gating logic needed, because there's no shared workflow trigger surface. Staying in one repo (Grafana, Prisma-within-orm) requires either accepting forced lockstep (Grafana's `lerna version --exact --force-publish` stamps the app's version onto every package at publish time, overriding whatever's committed) or building an explicit cross-boundary contract with guardrails (Prisma's conformance check blocking `-dev.` dependency leaks, added *after* an incident). Vault's Go-submodule case is the outlier: because Go modules have no publish step beyond a git tag, "accidental publish" isn't structurally possible the way an npm publish is — the analogous risk (tagging a not-ready commit) is a review/discipline problem, not a CI-trigger problem, which is a genuinely different risk shape from every npm/PyPI-publishing project surveyed here.
