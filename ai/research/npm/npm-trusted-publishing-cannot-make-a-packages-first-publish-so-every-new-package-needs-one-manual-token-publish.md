---
title: "npm trusted publishing (OIDC) cannot perform a package's FIRST publish — a trusted publisher can only be configured on a package that already exists, with no scope- or org-level pre-registration, so every brand-new package name needs exactly one manual token-based publish before CI can take over"
date: 2026-09-10
topic: npm
tags: [npm, trusted-publishing, oidc, provenance, github-actions, supply-chain]
status: draft
sources: [npm-trusted-publishers, npm-trust-cli, npm-cli-8544, gh-changelog-ga, philnash-provenance]
source_session: dfc169dc-2b2a-4341-b3d3-3ab4b1129fc4
---

## CLAIMS

- npm trusted publishing requires npm CLI >= 11.5.1 and Node.js >= 22.14.0 for the publish flow itself. [npm-trusted-publishers]
- The separate `npm trust` CLI command, which configures trusted publishers from the command line rather than the website, has a HIGHER floor: npm >= 11.15.0. Do not conflate the two version requirements. [npm-trust-cli]
- The workflow needs `permissions: id-token: write`. The same permission backs both the OIDC credential exchange and the provenance attestation. [npm-trusted-publishers]
- `NODE_AUTH_TOKEN` is NOT needed for the publish itself. npm's official example still sets it, but only in a separate step for installing private dependencies with a read-only token — unrelated to publishing. [npm-trusted-publishers]
- **A trusted publisher can only be configured on a package that ALREADY EXISTS on the registry.** npm's own docs state the requirement outright. [npm-trust-cli]
- There is **no org-level or scope-level pre-registration** to work around this, an acknowledged gap versus PyPI (which does support pre-registering a trusted publisher for a not-yet-existing project). The documented workaround is to publish an initial version manually with a token, then configure the trusted publisher for all later releases. [npm-cli-8544]
- The trusted-publisher entry takes the repository owner, repository name, and the **workflow filename only — not a path** — and the filename must include its `.yml`/`.yaml` extension and match the real file exactly. Environment name is optional. Up to 10 connections per package; a connection's fields are immutable once created (delete and recreate to change). [npm-trusted-publishers]
- npm documents provenance as AUTOMATIC under trusted publishing, stating `--provenance` is not required. [npm-trusted-publishers]
- That automatic-provenance claim is contradicted by at least one first-hand practitioner report: a maintainer found they "needed to add the `--provenance` flag so that my package would publish successfully," and noted others hit the same thing. Treat "provenance is fully automatic" as documented-but-not-universally-observed. [philnash-provenance]
- `--access public` (or `publishConfig.access: "public"`) is still required for a scoped package's first publish. Trusted publishing changes authentication only, not the package-visibility default; scoped packages still default to restricted. [npm-trusted-publishers]
- Trusted publishing with OIDC reached general availability on 2025-07-31. [gh-changelog-ga]

## SOURCES

**npm-trusted-publishers**
URL: https://docs.npmjs.com/trusted-publishers/
Accessed: 2026-09-10
Quote: "When you publish using trusted publishing, npm automatically generates and publishes provenance attestations for your package... you don't need to add the `--provenance` flag." Also, on configuration: "Enter only the filename, not the full path."

**npm-trust-cli**
URL: https://docs.npmjs.com/cli/v11/commands/npm-trust/
Accessed: 2026-09-10
Quote: "The package you're configuring must already exist on the npm registry."

**npm-cli-8544**
URL: https://github.com/npm/cli/issues/8544
Accessed: 2026-09-10
Quote: "it's not possible to publish the initial version of a package using OIDC, it needs to be published manually or using a token." / "The main problem is that the UI on npmjs.com requires a package to exist before you can edit its settings and enable OIDC publishing."

**gh-changelog-ga**
URL: https://github.blog/changelog/2025-07-31-npm-trusted-publishing-with-oidc-is-generally-available/
Accessed: 2026-09-10
Quote: Announcement that npm trusted publishing with OIDC is generally available.

**philnash-provenance**
URL: https://philna.sh/blog/2026/01/28/trusted-publishing-npm/
Accessed: 2026-09-10
Quote: "I did not find this to be the case. I needed to add the `--provenance` flag so that my package would publish successfully."

## SYNTHESIS

The reusable trap is a **chicken-and-egg bootstrap**, and it bites at exactly the wrong moment: you design a token-free OIDC publish pipeline, wire it up correctly, and it cannot perform the one publish you were trying to automate — the first one. Any plan that says "new package, publish via trusted publishing from CI" has an unavoidable manual step that must be surfaced in the plan rather than discovered when the first tag fires. Budget for it: one maintainer publishes `x.y.z` with a credential, creates the trusted-publisher entry, and only then does CI own releases.

This differs from PyPI, so intuition carried over from Python tooling is wrong here. If a future npm release adds scope-level pre-registration, npm/cli#8544 is the issue to re-check.

Second reusable point: **do not assert "provenance is automatic, no flag needed" as a flat fact.** The docs say it; a credible practitioner report contradicts it. Passing `--provenance` explicitly alongside `publishConfig.provenance: true` is redundant rather than conflicting — I found no documentation or issue describing that combination as an error — so the cheap, defensible move is to request it in both places and let redundancy absorb the uncertainty.

Two smaller version traps worth keeping: the `npm trust` CLI's floor (11.15.0) is higher than the publish flow's (11.5.1), and `--access public` remains necessary for scoped packages because trusted publishing touches authentication only, not visibility. Pinning Node 24 in a workflow satisfies both the Node and (via bundled npm) the CLI floor.

Applied in practice: PDP-Connect/data-connectors#97, which made `@pdpp/polyfill-connectors` publishable. The workflow there states the bootstrap constraint in its own header comment specifically so the next person does not rediscover it. Note this entry covers the *mechanism*; it deliberately says nothing about whether the OIDC handshake was observed working, because that cannot be exercised until the manual bootstrap exists.
