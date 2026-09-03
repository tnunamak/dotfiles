---
title: "npm 10.x's --ignore-scripts does not suppress a -w-targeted workspace's own prepare lifecycle script, though npm 12.x does"
date: 2026-08-18
topic: npm
tags: [npm, workspaces, ignore-scripts, prepare, lifecycle-scripts, ci, monorepo]
status: draft
sources: [npm-docs-install, isolated-repro]
source_session: 23896aef-d22b-4cf7-90f3-5ac2c728ef83
---

## CLAIMS

- Running `npm install --ignore-scripts -w packages/<pkg>` in an npm workspaces monorepo, where `packages/<pkg>/package.json` declares a `"prepare"` script, DOES run that `prepare` script on npm 10.9.8 — despite `--ignore-scripts` being set. Confirmed with a minimal 2-line repro (`packages/foo/package.json` with `"prepare": "node -e \"console.log('PREPARE RAN'); process.exit(1)\""`) — the sentinel printed and the process exited nonzero. [isolated-repro]
- The identical scenario (same package.json, same `--ignore-scripts -w` flags) does NOT run the `prepare` script on npm 12.0.2 — `--ignore-scripts` behaves as documented there. [isolated-repro]
- npm's own documentation for `--ignore-scripts` does not carve out an exception for `prepare` under `-w`-scoped installs — the documented exception is narrower ("commands explicitly intended to run a particular script, such as `npm start`... will still run their intended script if ignore-scripts is set, but they will not run any pre- or post-scripts"), which does not describe `npm install -w` triggering a workspace's own `prepare`. [npm-docs-install]
- When this fires on an interdependent pair of workspaces (workspace B's `prepare` script needs workspace A's build output, e.g. via a `file:`/symlinked local dependency), the `prepare` script can run BEFORE npm has finished creating the sibling workspace's `node_modules/<scope>/<pkg>` symlink — producing a broken build (missing type declarations, etc.) for whichever workspace's `prepare` fires second in npm's own internal processing order (not necessarily the order workspaces are listed with `-w`). Re-running the same `npm install -w ...` command does not self-heal this — the same broken build recurs every time. [isolated-repro]

## SOURCES

**npm-docs-install**
URL: https://docs.npmjs.com/cli/v10/commands/npm-install (via `npm help install` on npm 10.9.8)
Accessed: 2026-08-18
Quote: "ignore-scripts ... Default: false ... If true, npm does not run scripts specified in package.json files. Note that commands explicitly intended to run a particular script, such as npm start, npm stop, npm restart, npm test, and npm run-script will still run their intended script if ignore-scripts is set, but they will not run any pre- or post-scripts."

**isolated-repro**
URL: (local, not a web source — minimal repro built during this session, plus reproduction against the real `data-connect`/PDPP monorepo's `collector-runtime`/`connector-protocol` workspaces)
Accessed: 2026-08-18
Quote: "npm error command failed / npm error command sh -c node -e \"console.log('PREPARE RAN'); process.exit(1)\" / npm error PREPARE RAN" — printed despite `--ignore-scripts --no-audit --no-fund -w packages/foo` on npm 10.9.8; absent under identical invocation on npm 12.0.2.

## SYNTHESIS

This cost a full CI-iteration cycle (2 failed pushes) on `data-connectors`
(`.github/scripts/cross-repo-integrity/check-tarball-digest-drift.sh`) because local testing
happened to use whatever npm ships with the ambient Node install (12.0.2, bundled with Node
24), while the CI job pinned Node 22 via `.nvmrc` for an unrelated reason — and Node 22 ships
npm 10.9.8, which has this gap. The fix that worked cleanly under npm 12 reproduced the exact
original failure under npm 10, with zero code changes — purely an npm-version difference in
`--ignore-scripts` semantics for workspace `prepare` hooks.

Practical implications:
1. When testing an `npm install --ignore-scripts -w ...` fix locally, verify against the SAME
   npm major version the target environment (CI, Docker base image, etc.) actually uses — don't
   assume `--ignore-scripts` behaves identically across npm major versions for workspace
   lifecycle hooks. `nvm install <version>` + `nvm use` to get the matching npm is cheap
   insurance.
2. If a workspace's `prepare` script needs to not run during a scoped `-w` install (e.g. to
   control build order explicitly, or because the environment doesn't have the tool the
   `prepare` script needs yet), `--ignore-scripts` alone is not sufient on npm 10.x. The
   working mitigation found here: temporarily rewrite the `prepare` script to a no-op (e.g.
   `"true"`) in the package.json before the install, then restore the original file (`git
   checkout --` if it's a git checkout) before doing anything downstream that inspects or packs
   that package.json — the packed/observed content must match what's actually shipped.
3. This is a real, narrow, reproducible npm defect worth an upstream issue if not already
   filed — the repro is a 2-line package.json and one install command.
