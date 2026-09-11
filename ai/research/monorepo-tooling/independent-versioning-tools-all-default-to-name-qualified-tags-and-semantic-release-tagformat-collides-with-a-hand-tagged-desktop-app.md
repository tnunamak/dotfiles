---
title: "Every independent-versioning monorepo tool defaults to a NAME-QUALIFIED git tag (`pkg@1.2.3`, `pkg-v1.2.3`) precisely to keep tag namespaces disjoint, so a semantic-release stream left at the default `tagFormat: v${version}` silently annexes the version line of any hand-tagged app in the same repo — and projects shipping two artifact classes never name a workflow bare `release.yml`"
date: 2026-09-11
topic: monorepo-tooling
tags: [release-engineering, semantic-release, versioning, github-actions, desktop-apps, monorepo, tauri]
status: settled
sources: [nx-independent, release-please-manifest, lerna-modes, semrel-config, semrel-monorepo-wrappers, semrel-get-tags, gh-token-recursion, tauri-workflows, tauri-tags, standardnotes, sentry-craft, vscode-devprocess, grafana-workflows, signal-workflows, electron-workflows, vscode-workflows, astro-pnpm-changesets, tauri-updater, dataconnect-local]
source_session: c76aaf16-6ffb-4eb2-8033-468cb69a25e2
---

## CLAIMS

### Tag namespacing is the universal answer to "many release streams, one repo"

- Nx `release.projectsRelationship` defaults to `"fixed"` (all projects released in lock step); setting `"independent"` lets versions diverge and creates a separate git tag per project. [nx-independent]
- Nx's DEFAULT `releaseTagPattern` changes with the mode: `v{version}` in fixed mode, `{projectName}@{version}` in independent mode. Nx docs instruct that the pattern should include `{projectName}` "so each generated tag is unique". [nx-independent]
- release-please's manifest mode (its multi-package mode) uses a default tag search pattern of `<component-name>-v<release-version>`; getting the unqualified `v<release-version>` form requires explicitly setting `include-component-in-tag: false`. [release-please-manifest]
- release-please's `linked-versions` plugin exists to force lockstep across a named group: when any component in the group updates, it picks the highest version among them and sets all group components to that version. `separate-pull-requests: false` is the default (one consolidated release PR). [release-please-manifest]
- Lerna documents two modes: fixed/locked (a single version line stored under the `version` key in `lerna.json`) and independent (maintainers increment package versions independently; a prompt per changed package). Lerna's own feature page shows a `v1.0.0` tag example but does NOT explicitly document a different tag format per mode. [lerna-modes]
- semantic-release's `tagFormat` defaults to `v${version}` and "must contain the `version` variable exactly once and compile to a valid Git reference". The configuration page documents no monorepo support. [semrel-config]
- semantic-release has no native multi-package mode: the one-repo/one-package assumption is baked in, and multi-package use means either one invocation per package (each with its own `tagFormat`) or a third-party wrapper. `semantic-release-monorepo` namespaces generated tags as `<PACKAGE_NAME>-v<VERSION>` explicitly "to avoid version collisions"; RimacTechnology's variant defaults to `my-package-name@1.0.1` and warns it is essential to choose a format that keeps each workspace's releases unique. [semrel-monorepo-wrappers]
- tauri-apps/tauri versions its Rust crates and npm packages INDEPENDENTLY via Covector (`.changes/config.json`), with e.g. `tauri v2.11.5`, `tauri-build v1.5.7-edition2024.0`, `@tauri-apps/cli v2.11.4`, and `tauri-bundler v2.9.4` live simultaneously on separate tracks. Its tag format is `<package-name>-v<version>` (`tauri-v2.11.5`, `@tauri-apps/cli-v2.11.4`, `tauri.js-v0.9.1`). [tauri-tags]
- Counting tauri-apps/tauri's remote tags: 1788 are name-qualified versus 28 bare `v<semver>` — and the bare ones are all legacy v1-era (`v1.0.0-rc.*`, `v1.0.1`–`v1.0.5`). The project migrated AWAY from a shared `v*` namespace as it grew multiple packages. [tauri-tags]
- standardnotes/app ships an Electron desktop app and the SNJS library from one repo (the formerly separate `snjs` and `desktop` repos redirect to it). Its workflows are artifact-qualified — `desktop.release.prod.yml`, `desktop.build.manual.yml`, `desktop.build.reuse.yml`, `web.release.prod.yml`, `mobile.release.prod.yml`, `snjs.pr.yml`, `publish.yml` — with no `release.yml`. Tag formats are mixed: bare `v3.21.0` alongside scoped `@standardnotes/desktop@3.202.4`. [standardnotes]
- COUNTEREXAMPLE on versioning (not on naming): grafana/grafana forces its `@grafana/*` npm packages to the exact server release version via `lerna version "$VERSION" --exact --force-publish`, i.e. deliberate LOCKSTEP between the server artifact and the npm packages; npm `@grafana/data` versions match `grafana/grafana` release tags (e.g. `13.2.1`). Grafana supports the artifact-qualified *naming* claim while contradicting the *independent-versioning* one. [grafana-workflows]
- microsoft/vscode publishes nothing to npm from the app repo (root `package.json` is `"name": "code-oss-dev", "private": true`); its desktop release pipeline is Azure DevOps (`build/azure-pipelines/product-build.yml`, `product-release.yml`, `product-publish.yml`), not GitHub Actions. Companion libraries live in separate repos. [vscode-workflows]
- signalapp/Signal-Desktop's `publish-packages.yml` is gated `if: github.repository == 'signalapp/Signal-Desktop-Private'`, so publication runs only from a private mirror, never the public repo. [signal-workflows]
- getsentry/sentry-javascript releases via Sentry's Craft tool (`.craft.yml`): `release.yml` is `workflow_dispatch` and invokes `getsentry/craft`; `auto-release.yml` triggers on `pull_request: types: [closed]` for branches matching `prepare-release/VERSION`. [sentry-craft]
- semantic-release issue #735 records a historical collision from insufficiently distinct tag prefixes: with `schema-validator` and `validator` packages, a `tagFormat` of `validator/${version}` returned the schema-validator version, because the generated regexp lacked a leading caret. Current `master` DOES anchor — `lib/branches/get-tags.js` builds `^${escapedTemplate}(.+)` — so this specific bug is fixed; the residual lesson is that a prefix which is a strict prefix of another still needs care. [semrel-monorepo-wrappers, semrel-get-tags]
- semantic-release discovers prior versions by matching each git tag against a regexp built from `tagFormat` (escaping the template, substituting `(.+)` for the version, anchoring with `^`) and keeping only tags where the captured group passes `semver.valid(semver.clean(version))`. Tags not matching the CURRENT `tagFormat` are discarded entirely. Consequence: changing `tagFormat` in an existing repo makes semantic-release blind to every previously-cut tag, so it computes the next version from a clean slate unless a tag in the new format is created first. [semrel-get-tags]

### Nobody shipping two artifact classes names a workflow `release.yml`

- tauri-apps/tauri (Rust crates + `@tauri-apps/api`/`@tauri-apps/cli` npm packages from one repo) has NO `release.yml`. Its release-related workflows are `covector-version-or-publish.yml`, `covector-status.yml`, `covector-comment-on-fork.yml`, `publish-cli-js.yml`, `publish-cli-rs.yml` — all verb- or tool-qualified. [tauri-workflows]
- grafana/grafana (server binaries + deb/rpm packages + npm packages, one repo) splits by artifact class in the filename: `release-npm.yml` ("Release NPM packages"), `release-build.yml` ("Build Release Packages"), plus `github-release.yml`, `publish-artifact.yml`, `create-release-tag.yml`, `create-release-branch.yml`, `bump-version.yml`, `release-verify-packages.yml`. No bare `release.yml`. [grafana-workflows]
- Grafana's `release-build.yml` runs on `push` to `main` and `release-*.*.*` branches AND a weeknight `schedule` cron, while `release-npm.yml` is `workflow_call`-only (invoked with an explicit `version`, `build_id`, and `version_type` of canary/nightly/stable). Building is continuous; publishing is explicitly invoked. [grafana-workflows]
- signalapp/Signal-Desktop has `publish-packages.yml` (on `push` to `main`) and separately `reproducible-builds.yml` (`workflow_dispatch` only, taking `package` and `version_tag` inputs) and `reproducible-build-scheduler.yml`. No `release.yml`. [signal-workflows]
- electron/electron has no `release.yml`; it uses platform-qualified publish workflows — `linux-publish.yml`, `macos-publish.yml`, `windows-publish.yml`, `release-build.yml`, `pipeline-segment-electron-publish.yml`. [electron-workflows]
- microsoft/vscode's `.github/workflows` contains no release workflow at all (the desktop release pipeline lives outside GitHub Actions); its Actions workflows are PR/test/scan jobs plus `monaco-editor.yml` and `chat-lib-package.yml` for the separately-shipped library artifacts. [vscode-workflows]
- By contrast, projects with exactly ONE artifact class do use the bare name: withastro/astro has `release.yml`, pnpm/pnpm has `release.yml` + `create-release-pr.yml`, changesets/changesets has `publish.yml`. vercel/next.js uses `trigger_release.yml` + `create_release_branch.yml`. [astro-pnpm-changesets]

### Desktop releases are human-gated in practice

- VS Code runs a monthly, human-driven release train, not merge-triggered publication: "Iterations are roughly month based… We will begin a milestone on a Monday and end on a Friday". The final week is the "end game", during which a build goes to the `insiders` channel; the stable release is published "sometime midweek, after 24 hours with no changes to the pre-release". [vscode-devprocess]
- Tauri's updater compares `update.version > current` by default to decide whether to apply an update, requires a `pubkey` embedded in `tauri.conf.json` and a `TAURI_SIGNING_PRIVATE_KEY` at build time, and warns "if you lose this key you will NOT be able to publish new updates". The docs do not document any rollback or un-publish mechanism. [tauri-updater]

### GitHub Actions: GITHUB_TOKEN suppresses recursive triggers

- "When you use the repository's `GITHUB_TOKEN` to perform tasks, events triggered by the `GITHUB_TOKEN` will not create a new workflow run", with the only exceptions being `workflow_dispatch`/`repository_dispatch` (which always run) and `pull_request` opened/synchronize/reopened (which run in an approval-required state). [gh-token-recursion]
- Consequence: a `release: [created]` -triggered workflow does NOT fire for a GitHub Release created by semantic-release's `@semantic-release/github` plugin using the default `GITHUB_TOKEN`. The isolation is a side effect of the token identity, not of any declared configuration — swapping in a PAT or GitHub App token to that publishing workflow silently starts firing the other workflow. [gh-token-recursion]

### Measured on PDP-Connect/data-connect at commit cb0852f5f (2026-09-11)

- The repo's `.releaserc.yaml` sets `tagFormat: "v${version}"` (semantic-release's default) for the lockstep npm stream of `@pdpp/connector-protocol`, `@pdpp/collector-runtime`, and `@pdpp/local-collector`. [dataconnect-local]
- The desktop app's own hand-cut tags occupy the identical namespace: `v0.7.54`, `v0.7.52`, `v0.7.51`, … alongside semantic-release's `v1.0.0`, `v2.0.0`, `v2.1.0`, `v2.1.1`, `v2.2.0`. `src-tauri/tauri.conf.json` version is `0.7.54`. [dataconnect-local]
- `scripts/release-github.mjs::getLatestRemoteTagVersion()` selects the desktop app's next version by listing `refs/tags/v*` from origin and filtering on `/^v\d+\.\d+\.\d+$/` — a predicate that matches the npm stream's tags as readily as the desktop app's. [dataconnect-local]
- Executing `node scripts/release-github.mjs --show-versions` reports: `tauri.conf.json version: 0.7.54`, `latest remote tag version: v2.2.0`, `suggested next version: 2.2.1`. The npm stream's version has become the desktop app's suggested next version. [dataconnect-local]
- `assertVersionOrdering` hard-fails any version not greater than the latest remote tag, so `node scripts/release-github.mjs --check-version --version 0.7.55` prints "Version 0.7.55 must be greater than latest remote tag v2.2.0". The honest next desktop version is unreleasable through the repo's own tool. [dataconnect-local]
- GitHub Release `v2.1.1` was created by `github-actions[bot]`; `v0.7.54` was created by a human user. Tag `v2.2.0` exists on origin with no corresponding GitHub Release. [dataconnect-local]
- `.github/workflows/release.yml` (name: "Release manual-install artifacts") triggers on `pull_request`, `release: [created]`, and `workflow_dispatch`; only its `publish` job and artifact-staging step are gated on `github.event_name == 'release'`, so PR runs build the full 4-platform matrix without publishing. [dataconnect-local]
- `src-tauri/tauri.conf.json` sets `"createUpdaterArtifacts": false` and registers only the `deep-link` plugin — the app ships no auto-updater, so a published release reaches users only when they manually download an installer. [dataconnect-local]
- Only one `release`-event run of `release.yml` exists in the repo's history (`DataConnect v0.7.54`, 2026-08-01) and it concluded `failure`. Every other run of that workflow was `pull_request`-triggered. [dataconnect-local]

## SOURCES

**nx-independent**
URL: https://nx.dev/docs/guides/nx-release/release-projects-independently
Accessed: 2026-09-11
Quote: "By default Nx releases all projects together in lock step, equivalent to `\"fixed\"`." / fixed → `v{version}`; independent → `{projectName}@{version}`; "you should include `{projectName}` in the pattern so each generated tag is unique."

**release-please-manifest**
URL: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md
Accessed: 2026-09-11
Quote: "create separate pull requests for each package instead of a single manifest release pull request" (`separate-pull-requests`, default `false`). Default tag search pattern `<component-name>-v<release-version>`; `include-component-in-tag: false` reduces it to `v<release-version>`. linked-versions: "When any component in the specified group is updated, we pick the highest version amongst the components and update all group components to the same version (keeping them in sync)."

**lerna-modes**
URL: https://lerna.js.org/docs/features/version-and-publish
Accessed: 2026-09-11
Quote: "Fixed mode Lerna projects operate on a single version line. The version is kept in the `lerna.json` file at the root of your project under the `version` key." / "Independent mode Lerna projects allows maintainers to increment package versions independently of each other."

**semrel-config**
URL: https://semantic-release.gitbook.io/semantic-release/usage/configuration
Accessed: 2026-09-11
Quote: "The `tagFormat` must contain the `version` variable exactly once and compile to a valid Git reference." Default: `v${version}`.

**semrel-monorepo-wrappers**
URL: https://www.npmjs.com/package/semantic-release-monorepo ; https://github.com/pmowrer/semantic-release-monorepo ; https://github.com/RimacTechnology/semantic-release-monorepo ; https://github.com/semantic-release/semantic-release/issues/735
Accessed: 2026-09-11
Quote: tags namespaced `<package-name>-<version>` "to avoid version collisions"; default `<PACKAGE_NAME>-v<VERSION>`. Rimac: tags default to `my-package-name@1.0.1`, "essential to choose a format that ensures each workspace/release is unique." Issue #735: `validator/${version}` matched `schema-validator/...` because the generated regexp had no leading caret.

**semrel-get-tags**
URL: https://raw.githubusercontent.com/semantic-release/semantic-release/master/lib/branches/get-tags.js
Accessed: 2026-09-11
Quote: builds the tag regexp by escaping the `tagFormat` template and substituting `(.+)` for the version, anchored as `^${escapedTemplate}(.+)`; per tag `const [, version] = tag.match(tagRegexp) || [];` and the tag is kept only if `semver.valid(semver.clean(version))` passes.

**gh-token-recursion**
URL: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow
Accessed: 2026-09-11
Quote: "When you use the repository's `GITHUB_TOKEN` to perform tasks, events triggered by the `GITHUB_TOKEN` will not create a new workflow run, with the following exceptions: `workflow_dispatch` and `repository_dispatch` events always create workflow runs. `pull_request` events with the `opened`, `synchronize`, or `reopened` activity types: … creates workflow runs in an approval-required state."

**tauri-workflows**
URL: https://github.com/tauri-apps/tauri/tree/dev/.github/workflows
Accessed: 2026-09-11
Quote: directory listing includes `covector-version-or-publish.yml`, `covector-status.yml`, `covector-comment-on-fork.yml`, `publish-cli-js.yml`, `publish-cli-rs.yml`; no `release.yml`.

**tauri-tags**
URL: `git ls-remote --tags https://github.com/tauri-apps/tauri` ; https://github.com/tauri-apps/tauri/blob/dev/.changes/config.json
Accessed: 2026-09-11
Quote: tag counts by shape — bare `v<semver>`: 28 (all v1-era `v1.0.0-rc.*`, `v1.0.1`–`v1.0.5`); name-qualified (`tauri-v*`, `@tauri-apps/cli-v*`, `tauri.js-v*`, …): 1788.

**standardnotes**
URL: https://api.github.com/repos/standardnotes/app/contents/.github/workflows (via `gh api`)
Accessed: 2026-09-11
Quote: listing is `clipper.release.prod.yml codeql-analysis.yml desktop.build.manual.yml desktop.build.reuse.yml desktop.release.prod.yml desktop.release.reuse.yml git-sync.yml ios.testflight.yml mobile.release.closed-beta.yml mobile.release.prod.yml pr.yml publish.yml releases.notify.yml snjs.pr.yml snjs.upgrade.event.yml web.release.prod.yml` — no `release.yml`.

**sentry-craft**
URL: https://github.com/getsentry/sentry-javascript/blob/develop/.craft.yml ; .../.github/workflows/release.yml ; .../auto-release.yml
Accessed: 2026-09-11
Quote: `release.yml` is `workflow_dispatch` invoking `getsentry/craft`; `auto-release.yml` on `pull_request: types: [closed]` for `prepare-release/VERSION` branches.

**vscode-devprocess**
URL: https://github.com/microsoft/vscode/wiki/Development-Process
Accessed: 2026-09-11
Quote: "Iterations are roughly month based, rather than week based. We will begin a milestone on a Monday and end on a Friday" / "The final week of the milestone is what we call the 'end game'." / "During the endgame we make a build available on the `insiders` channel… and then produce a final `stable` release." / published "sometime midweek, after 24 hours with no changes to the pre-release."

**grafana-workflows**
URL: https://api.github.com/repos/grafana/grafana/contents/.github/workflows (via `gh api`); files `release-npm.yml`, `release-build.yml`
Accessed: 2026-09-11
Quote: `release-npm.yml` → `name: Release NPM packages`, `on: workflow_call` with required `version`/`build_id`/`version_type` inputs. `release-build.yml` → `name: Build Release Packages`, `on: workflow_dispatch`, `schedule: cron '0 0 * * 1-5'`, `push: branches: [release-*.*.*, main]`.

**signal-workflows**
URL: https://api.github.com/repos/signalapp/Signal-Desktop/contents/.github/workflows (via `gh api`)
Accessed: 2026-09-11
Quote: `publish-packages.yml` → `name: Publish Packages`, `on: push: branches: [main]`. `reproducible-builds.yml` → `name: Reproducible Builds`, `on: workflow_dispatch` with `package` and `version_tag` inputs.

**electron-workflows**
URL: https://api.github.com/repos/electron/electron/contents/.github/workflows (via `gh api`)
Accessed: 2026-09-11
Quote: listing includes `linux-publish.yml`, `macos-publish.yml`, `windows-publish.yml`, `release-build.yml`, `pipeline-segment-electron-publish.yml`; no `release.yml`.

**vscode-workflows**
URL: https://api.github.com/repos/microsoft/vscode/contents/.github/workflows (via `gh api`)
Accessed: 2026-09-11
Quote: listing is `chat-lib-package.yml chat-perf.yml codeql.yml component-fixtures.yml copilot-setup-steps.yml css-order-scan.yml monaco-editor.yml pr-darwin-test.yml pr-linux-cli-test.yml pr-linux-test.yml pr-node-modules.yml pr-win32-test.yml pr.yml sessions-e2e.yml telemetry.yml` — no release workflow.

**astro-pnpm-changesets**
URL: https://api.github.com/repos/withastro/astro/contents/.github/workflows ; .../pnpm/pnpm/... ; .../changesets/changesets/... ; .../vercel/next.js/... (via `gh api`)
Accessed: 2026-09-11
Quote: astro → `release.yml`, `preview-release.yml`; pnpm → `release.yml`, `create-release-pr.yml`; changesets → `publish.yml`; next.js → `trigger_release.yml`, `create_release_branch.yml`.

**tauri-updater**
URL: https://v2.tauri.app/plugin/updater/
Accessed: 2026-09-11
Quote: default comparison is "update.version > current"; `pubkey` in `tauri.conf.json`, `TAURI_SIGNING_PRIVATE_KEY` at build; "if you lose this key you will NOT be able to publish new updates".

**dataconnect-local**
URL: local checkout PDP-Connect/data-connect @ cb0852f5f08b238a32ec894d4230f0a9b997f6c6 (`.releaserc.yaml`, `scripts/release-github.mjs`, `src-tauri/tauri.conf.json`, `.github/workflows/{release,npm-release}.yml`, `git ls-remote --tags origin`, `gh api repos/PDP-Connect/data-connect/releases`, `gh run list`)
Accessed: 2026-09-11
Quote: `node scripts/release-github.mjs --show-versions` → "tauri.conf.json version: 0.7.54 / latest remote tag version: v2.2.0 / suggested next version: 2.2.1". `--check-version --version 0.7.55` → "Version 0.7.55 must be greater than latest remote tag v2.2.0".

## SYNTHESIS

The reusable lesson is narrower and sharper than "monorepos are hard": **a git tag namespace is a shared mutable global, and semantic-release's default `tagFormat` claims all of it.** Every serious independent-versioning tool — Nx, release-please, the semantic-release monorepo wrappers — arrived independently at the same defense, name-qualifying the tag. That convergence is the finding. The unqualified `v${version}` form is only correct when the repo has exactly one thing to version, which is also exactly the condition under which projects name a workflow `release.yml`.

The failure mode this produces is quiet and delayed, which is what makes it worth writing down. Nothing errors at publish time; the npm stream tags happily. The damage surfaces later and elsewhere, in whatever *other* tool reads tags to answer "what version are we on". Any `git describe`, any `refs/tags/v*` scan, any "latest release" badge is a victim. In data-connect the victim was a version-suggestion helper whose `^v\d+\.\d+\.\d+$` filter was a perfectly reasonable predicate on the day it was written and became wrong the moment a second release stream adopted the same shape. Note the asymmetry in severity: the npm stream is unharmed (it only ever moves forward), while the desktop app is locked out — its next honest version is *smaller* than the squatter's, so the ordering assertion that exists to prevent mistakes now prevents the correct action. A guardrail pointed at the wrong namespace becomes a blocker.

The second reusable lesson is about **accidental isolation**. Two release systems in this repo are kept from colliding by GitHub's GITHUB_TOKEN no-recursion rule — an implicit, undeclared property of the token identity rather than anything either workflow says. It works, but nothing in either file tells a future maintainer that it is load-bearing, and the routine act of swapping in a PAT or GitHub App token (for branch protection, or to get richer release notes) silently converts "npm patch published" into "full 4-platform desktop build fires". Isolation that depends on an undocumented platform default should be restated as an explicit condition in the workflow itself, where it can be read.

On automation: the prior art does not say desktop apps *cannot* be released automatically — it says the industry consistently splits **build** from **publish**, and automates the first while gating the second. Grafana builds on every push to main and on a nightly cron, then requires an explicit invocation carrying a `version_type` to publish. VS Code builds continuously to `insiders` and cuts stable only after a human-run endgame and a 24-hour quiet period. data-connect already has the right shape by accident — its `release.yml` builds the whole matrix on every PR and publishes only on a release event — so the answer to "is manual release inertia?" is: the *gate* is sound engineering and matches everyone; what is inertia is that the gate was never named, documented, or separated from the npm stream's namespace. The real argument for gating here is weaker than the usual one, though, and worth stating honestly: with `createUpdaterArtifacts: false` there is no auto-updater, so a bad release does not push itself to anyone. The cost of a bad desktop release is a bad installer sitting on a releases page, not a fleet-wide silent upgrade. The gate is justified by code-signing/notarization cost and by the fact that an installed app cannot be recalled once downloaded — not by updater blast radius.

Tauri's own repo is the sharpest single data point, because it is the same technology stack and it *migrated*: 1788 name-qualified tags against 28 bare `v*`, and every bare one is v1-era. A project does not rewrite its tag convention for fun. It did so at exactly the moment one repo started carrying more than one releasable thing.

**The honest counterexample is Grafana, and it cuts only one way.** Grafana forces its `@grafana/*` npm packages to the server's exact version (`lerna version "$VERSION" --exact --force-publish`) — deliberate lockstep between an application artifact and its libraries. So "always version independently" is *not* the finding, and citing Grafana for both naming and versioning would be cherry-picking. The distinction that survives both cases is about **audience coupling**: Grafana's `@grafana/*` packages exist to build plugins *for a specific Grafana server*, so a plugin author genuinely needs to know "which server does this target," and the shared version answers that question. Lockstep is right when the library's version is meaningfully *about* the app. It is wrong when the two have independent consumers — which is the data-connect case, where `@pdpp/local-collector` is an `npx`-invoked CLI with users who may never install the desktop app. Ask "does a library consumer need the app's version number to know what they have?" — if no, independent.

On lockstep versus independent for this shape: lockstep across a *library and an application with different audiences* is the one case the tooling's own defaults argue against. Nx and release-please both treat "fixed" as appropriate for a set of packages released together as a unit — which the three `@pdpp/*` packages genuinely are (they are already correctly lockstepped, and `.releaserc.yaml` documents why). A desktop app is a different audience with a different cadence and a version number users read and quote in bug reports. Forcing it to 2.2.1 because a library published a feature would be a lie told to users to satisfy a tool. Independent versioning with disjoint tag namespaces is the answer, and it is what every tool would do by default if asked.
