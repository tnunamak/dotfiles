---
title: "Tauri's Rust crates, CLI crate, and npm packages carry independently-drifting version numbers under Covector's dependency-cascade model, while Electron avoids the problem entirely by shipping one npm package whose major version is locked to Chromium's release train"
date: 2026-09-11
topic: monorepo-tooling
tags: [tauri, electron, covector, semver, npm, crates-io, release-cadence]
status: draft
sources: [tauri-config, tauri-registries, tauri-workflow, covector-readme, electron-releases, electron-timelines, vscode-types, vscode-lsp-node]
source_session: 698afd6a-f3f4-47be-bd3a-f151e5c3b96b
---

## CLAIMS

- Tauri's `.changes/config.json` (Covector config) declares no monorepo-wide "linked" version — each of its ~13 Rust crates and 2 npm packages has its own path, publish command, and `dependencies` array that only cascades a bump to dependents, without forcing a shared version number. [tauri-config]
- Live registry data proves the drift is real, not theoretical: on 2026-09-11, crates.io `tauri`=2.11.5, `tauri-cli`=2.11.4, `tauri-utils`=2.9.3; npm `@tauri-apps/cli`=2.11.4 (matches its wrapped Rust crate), `@tauri-apps/api`=2.11.1 (does NOT match the `tauri` core crate it binds to, despite both being "the JS/Rust halves of the same API"). [tauri-registries]
- One Tauri crate (`tauri-build`) even carries a different MAJOR (`tauri-build-v1.5.7-edition2024.0`) coexisting with the rest of the monorepo's 2.x line, per GitHub Releases tags. [tauri-registries]
- Tauri's release automation (`.github/workflows/covector-version-or-publish.yml`, triggered on every push to `dev`) gates publishing behind a full ubuntu/macos/windows integration-test matrix, then runs `covector version-or-publish`: opens a version-bump PR if `.changes/` files are present, else publishes to npm+crates.io; publishing is dependency-ordered so lower-level crates land on crates.io before dependents. [tauri-workflow]
- Covector itself (the tool, not just Tauri's use of it) explicitly supports both independent-per-package and linked/cascading versioning in the same config — Tauri chose the cascade-without-lockstep hybrid, this is a project decision, not a tool limitation. [covector-readme]
- Electron sidesteps the whole problem structurally: it ships as a single npm package (no separate crate-vs-binding split, since it isn't Rust), so there's nothing to keep in sync. Its versioning is instead driven entirely externally: majors ship every 8 weeks (4-week alpha + 4-week beta) locked to Chromium's even-numbered release train (documented example: "Electron 26 uses Chromium 116, while Electron 27 uses Chromium 118"), with exactly 3 stable major lines supported concurrently and a tiered backport policy (newest line gets all fixes, middle line gets fixes "as time and bandwidth warrants," oldest gets security-only). [electron-timelines]
- GitHub Releases confirm the 3-concurrent-lines pattern in practice: on 2026-09-11 the repo was actively shipping patches to 42.11.x, 43.7.x, and 44.3.x in the same window, plus advancing a 45.0.0-alpha line for the next major. [electron-releases]
- Apps built on these frameworks rarely add a third version-coupling pattern of their own: Spacedrive (Tauri, Rust+Bun/Turborepo) keeps all its workspace packages `"private": true` and publishes none of them to npm. VS Code (Electron) also keeps its root app package private, but its `@types/vscode` npm package happens to share VS Code's own monthly release number (both at 1.137.0 on 2026-09-11) with no documented rationale found for why — this looks like a "regenerate and tag with the release you documented" convention, not a semver dependency. [vscode-types]
- The cleanest fully-decoupled example is `microsoft/vscode-languageserver-node`, a separate repo from VS Code entirely, whose npm packages sit at a `v4.x`/`v3.x` line with zero numeric relationship to VS Code editor's `1.13x.x` line. [vscode-lsp-node]

## SOURCES

**tauri-config**
URL: https://raw.githubusercontent.com/tauri-apps/tauri/dev/.changes/config.json
Accessed: 2026-09-11
Quote: "No global 'version' or 'linked' setting exists... no monorepo-wide version constraint that forces all packages to bump together" (WebFetch summary of the live config file; per-package `dependencies` arrays cascade bumps, e.g. `tauri` depends on `tauri-macros, tauri-utils, tauri-runtime, tauri-runtime-wry, tauri-build`).

**tauri-registries**
URL: https://crates.io/api/v1/crates/tauri, https://crates.io/api/v1/crates/tauri-cli, https://crates.io/api/v1/crates/tauri-utils, https://registry.npmjs.org/@tauri-apps/cli, https://registry.npmjs.org/@tauri-apps/api, https://api.github.com/repos/tauri-apps/tauri/releases
Accessed: 2026-09-11
Quote: crates.io `tauri` `max_stable_version`: "2.11.5"; `tauri-cli`: "2.11.4"; `tauri-utils`: "2.9.3". npm dist-tags: `@tauri-apps/cli` latest "2.11.4"; `@tauri-apps/api` latest "2.11.1". Release tag list includes `tauri-build-v1.5.7-edition2024.0` alongside `tauri-v2.11.5`.

**tauri-workflow**
URL: https://raw.githubusercontent.com/tauri-apps/tauri/dev/.github/workflows/covector-version-or-publish.yml
Accessed: 2026-09-11
Quote: triggers `on: push: branches: - dev`; job step described as "publish when no change files present"; requires `contents: write` and `id-token: write` permissions for OIDC npm provenance.

**covector-readme**
URL: https://github.com/jbolda/covector
Accessed: 2026-09-11
Quote: "Transparent and flexible change management for publishing packages and assets. Publish and deploy from a single asset repository, monorepos, and even multi-language repositories."

**electron-timelines**
URL: https://www.electronjs.org/docs/latest/tutorial/electron-timelines
Accessed: 2026-09-11
Quote: "The latest three stable major versions are supported by the Electron team." / "Electron ships major versions every 8 weeks" with "a four-week alpha phase and a four-week beta phase." / "Electron 26 uses Chromium 116, while Electron 27 uses Chromium 118."

**electron-releases**
URL: https://api.github.com/repos/electron/electron/releases
Accessed: 2026-09-11
Quote: recent tags include `v45.0.0-alpha.6`, `v43.7.0`, `v44.3.0`, `v42.11.3`, `v45.0.0-alpha.5`, `v44.2.0`, `v43.6.0`, `v42.11.2` — three stable lines plus one alpha line advancing concurrently.

**vscode-types**
URL: https://registry.npmjs.org/@types/vscode, https://api.github.com/repos/microsoft/vscode/releases, https://raw.githubusercontent.com/microsoft/vscode/main/package.json
Accessed: 2026-09-11
Quote: `@types/vscode` dist-tag latest "1.137.0"; VS Code app's own recent release tags include "1.137.0", "1.136.2", "1.136.1"; root `package.json` has `"name": "code-oss-dev", "private": true, "version": "1.139.0"`.

**vscode-lsp-node**
URL: https://api.github.com/repos/microsoft/vscode-languageserver-node/tags
Accessed: 2026-09-11
Quote: tag list includes `v4.0.0`, `v2.6.2`, `v2.6.0`, `v2.5.0`, `release/4.1.0`, `release/4.0.0`, `release/3.5.1` — a fully independent version line with no numeric relationship to the VS Code editor version.

## SYNTHESIS

The decisive variable is not "monorepo vs polyrepo" or "Rust vs JS" — it's **how many independently-publishable artifact classes exist and whether any consumer needs to correlate their version numbers to use them together**. Tauri has ~15 artifact classes (11+ Rust crates, 2 npm packages, plus a CLI that exists as both a crate and an npm wrapper) with real inter-dependencies, so it needs Covector's dependency-cascade model — strict lockstep would force meaningless patch bumps across the whole graph on every unrelated crate change, while pure independence would let a breaking dependency change ship without forcing dependents to catch up. The cascade-without-lockstep hybrid is the actual answer to "how do you version a dependency graph without either extreme."

Electron never faces this because Chromium/V8/Node are vendored wholesale into one binary and one npm wrapper — there is no internal dependency graph to reconcile, only an external one (Chromium's ship schedule), which is why its "versioning strategy" reads more like a support-calendar policy than a semver-graph policy.

For apps built on either framework: the two VS Code data points suggest a spectrum rather than a rule. A types/docs package that's regenerated per release and tagged with the same number as the release it documents (`@types/vscode`) is a cheap convention, not a dependency — nothing breaks if the numbers drift, so no automation enforces them staying aligned. A genuinely reusable library spun out to its own repo (`vscode-languageserver-node`) gets its own independent line immediately, because its consumers (other editors, not just VS Code) have no reason to care what VS Code's version number is. This maps directly onto the "audience coupling" test from [[independent-versioning-tools-all-default-to-name-qualified-tags-and-semantic-release-tagformat-collides-with-a-hand-tagged-desktop-app]]: does a consumer of the npm artifact need the app's version number to make sense of what they have? If no (Tauri's `@tauri-apps/api`, VS Code's LSP packages), independent versioning is correct and the apparent "drift" is not a bug. If yes (Grafana's plugin packages per that same entry), deliberate lockstep is correct. Neither Tauri nor Electron nor VS Code offers a case of an app deliberately lockstepping its own desktop release number with a general-purpose SDK package — that specific combination wasn't found in the wild across the examples checked, which is itself a useful negative data point for anyone tempted to reach for lockstep by default in an app+SDK repo.
