---
title: "Changesets defaults to independent versioning while Lerna and Nx release default to fixed/lockstep, and only Changesets ships a dedicated doc for mixing an unpublished app with published libraries"
date: 2026-09-11
topic: monorepo-tooling
tags: [changesets, lerna, release-please, semantic-release, nx-release, versioning-strategy]
status: draft
sources: [changesets-config, changesets-versioning-apps, lerna-version-publish, release-please-linked-versions-issue, semantic-release-monorepo-readme, nx-release-independent, nx-json-schema]
source_session: fc2f39f5-38fe-4e77-995f-90a2f4ca45a7
---

## CLAIMS

- Changesets' out-of-the-box default (empty `fixed`/`linked` config arrays) is **fully independent** per-package versioning — lockstep is opt-in via the `fixed` or `linked` config keys. [changesets-config]
- Changesets is the only one of the five tools surveyed with a **dedicated first-party doc** (`versioning-apps.md`) for versioning a non-published application alongside published libraries in the same repo, via `"private": true` + the `privatePackages` config (default `{version: false, tag: false}`, opt into `{version: true, tag: true}` to still version/tag the app without publishing it). [changesets-versioning-apps]
- Changesets' own rationale for why an app can safely depend on an ignored/private library it would otherwise be blocked from depending on: "private packages are not published to npm, it is safe for them to depend on skipped packages." [changesets-versioning-apps]
- Lerna's default is the opposite: **fixed/locked mode**, tying all package versions together on one version line in `lerna.json`; maintainers' own stated tradeoff is "a major change in any package will result in all packages having a new major version." Independent mode is opt-in. [lerna-version-publish]
- Lerna's own example repo mixes publishable libraries with a non-published Remix app, handled the same way as Changesets (`"private": true` in package.json, `--no-private` flag) — not a distinct mechanism, just the same npm-native idiom Lerna happens to document with an app-in-monorepo example. [lerna-version-publish]
- release-please's manifest mode defaults to **independent versioning per component**; lockstep is opt-in via the `linked-versions` plugin, which forces full version parity within a named group. [release-please-linked-versions-issue]
- release-please's own issue tracker (googleapis/release-please#1075) explicitly names "libraries→applications" as a **known, unsolved gap**: linked-versions forces full parity (bad when app1 1.0.0→1.1.0 shouldn't force app2 from 2.0.0 down to 1.1.0), and there is no built-in way to reference another component's version without forcing shared versioning — "writing a custom plugin is one workaround." Not verified whether this issue has since been resolved. [release-please-linked-versions-issue]
- semantic-release's core has **no monorepo support at all** — it assumes one package per repo, causing git tag collisions across packages if used naively in a monorepo. All monorepo behavior comes from third-party plugins that split along the same fixed-vs-independent line: `multi-semantic-release` behaves like Lerna's fixed mode (releases all changed packages together, atomically); `semantic-release-monorepo` (pmowrer) does independent per-package versioning by assigning commits to packages via touched files, namespacing tags as `<package-name>-<version>` to avoid collisions. Neither plugin's README mentions applications vs libraries or private/unpublished packages at all. [semantic-release-monorepo-readme]
- Nx release's schema-level default is **fixed** (`projectsRelationship: "fixed" | "independent"`, `default: "fixed"` per the nx.json reference schema) — all projects version together unless you set `projectsRelationship: "independent"` globally or per release-group. [nx-json-schema]
- Nx's own framing for when to go independent: "useful when you have a monorepo with projects that are not released on the same schedule." Nx release-groups let different subsets of one workspace use different relationships (e.g., a fixed group of libraries and an independent app), and Nx explicitly supports cross-group dependency updates — but no first-party Nx doc found gives a worked example naming "app + libraries" as the scenario; this is an inference from the general mechanism, not a confirmed maintainer statement. [nx-release-independent]

## SOURCES

**changesets-config**
URL: https://github.com/changesets/changesets/blob/main/docs/config-file-options.md
Accessed: 2026-09-11
Quote: "This option can be used to declare that packages should be version-bumped and published together" (fixed); "This option can be used to declare that packages should 'share' a version, instead of being versioned completely independently" (linked); default (both arrays empty) is fully independent per-package versioning.

**changesets-versioning-apps**
URL: https://github.com/changesets/changesets/blob/main/docs/versioning-apps.md
Accessed: 2026-09-11
Quote: "Changesets only versions NPM package.json files, you can trigger releases for other package formats by creating workflows which trigger on tags/releases being created by changesets." / "private packages are not published to npm, it is safe for them to depend on skipped packages."

**lerna-version-publish**
URL: https://lerna.js.org/docs/features/version-and-publish
Accessed: 2026-09-11
Quote: section heading "Fixed/Locked mode (default)"; "Use this if you want to automatically tie all package versions together. One issue with this approach is that a major change in any package will result in all packages having a new major version." / "It's common to publish only a subset of the projects. Some projects can be private (e.g., used only for tests), some can be demo apps."

**release-please-linked-versions-issue**
URL: https://github.com/googleapis/release-please/issues/1075 (surfaced via search of linked-versions plugin commit f398bdf and manifest-releaser.md)
Accessed: 2026-09-11
Quote: "Using the linked-versions plugin forces all components to share the same version, which doesn't work when containers should version independently — e.g., if app1 goes from 1.0.0→1.1.0, you wouldn't want app2 to jump from 2.0.0→1.1.0" — cites "libraries→applications" as a common unsolved pattern.

**semantic-release-monorepo-readme**
URL: https://github.com/pmowrer/semantic-release-monorepo
Accessed: 2026-09-11
Quote: "commits are assigned to packages based on the files that a commit touched"; "generated git tags are namespaced using the given package's name: `<package-name>-<version>`." No mention of apps/libraries or private packages anywhere in the README.

**nx-release-independent**
URL: https://nx.dev/docs/guides/nx-release/release-projects-independently
Accessed: 2026-09-11
Quote: independent mode is "useful when you have a monorepo with projects that are not released on the same schedule."

**nx-json-schema**
URL: https://canary.nx.dev/docs/reference/nx-json (nx.json reference schema, corroborated via search since direct fetch of the guide page did not state the default explicitly)
Accessed: 2026-09-11
Quote: "projectsRelationship · \"fixed\" | \"independent\" default:\"\\\"fixed\\\"\" Whether projects are released together at the same version (\"fixed\") or each at their own version (\"independent\")."

## SYNTHESIS

Across all five tools, "fixed/lockstep" and "independent" are universally supported concepts, but the **default** split roughly by tool lineage: changeset-file-based tools that grew up in JS-package-only monorepos (Changesets, release-please) default to independent; classic "one version for the whole repo" tools (Lerna, Nx release) default to fixed. semantic-release has no opinion because it has no native monorepo concept at all — you import that opinion by picking a plugin.

For a repo mixing one unpublished desktop app with several published npm libraries, the tools split into two tiers of readiness:
1. **Changesets** is the only tool with dedicated, first-party documentation for exactly this shape (`versioning-apps.md`), via `private: true` + `privatePackages`, with an explicit maintainer-stated safety argument for why the app can depend on internal-only libraries.
2. **Lerna** solves it with the same idiom (`private: true`) but only via an example, not a dedicated doc.
3. **release-please** and **Nx release** have the general mechanism (independent-by-default plus opt-in grouping) but release-please's own issue tracker admits the "partial coupling without full lockstep" version of this problem (app depends on a lib, should bump together sometimes, but shouldn't be forced to always share a version) is unsolved without a custom plugin.
4. **semantic-release**'s plugin ecosystem doesn't address the app/library distinction at all in the docs checked — every plugin assumes all packages are meant for npm publication.

Practical implication for future tool selection on a mixed app+library repo: default to Changesets unless there's a strong reason (existing Nx workspace, Conventional-Commits-only discipline, etc.) to pick another tool — it's the only one where "don't publish the app, but still version/tag it, and let it safely depend on internal libs" is a named, supported, documented use case rather than something assembled from lower-level primitives.
