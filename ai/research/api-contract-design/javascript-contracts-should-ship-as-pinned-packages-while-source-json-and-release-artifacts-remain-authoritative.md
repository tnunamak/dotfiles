---
title: "JavaScript consumers should receive a pinned package while source JSON and immutable release artifacts remain authoritative"
date: 2026-07-15
topic: api-contract-design
tags: [npm, schemas, catalogs, versioning, provenance]
status: draft
sources: [octokit-openapi, stripe-openapi, npm-trusted-publishers, github-immutable-releases, github-dependabot]
source_session: 019e5b17-6096-7cf2-aec9-42244f40d8ac
---

## CLAIMS

- GitHub's Octokit project distributes its official OpenAPI specification as the `@octokit/openapi` Node package and documents consuming its generated schemas from Node. [octokit-openapi]
- Stripe publishes its OpenAPI specification as JSON and YAML files in its public repository for SDK generation. [stripe-openapi]
- npm trusted publishing lets a specific GitHub Actions workflow publish without a long-lived npm token and automatically produces provenance for public packages from public repositories. [npm-trusted-publishers]
- GitHub immutable releases protect release assets and tags from later modification, and create a release attestation tying assets to the release tag and commit. [github-immutable-releases]
- Dependabot can update npm manifest and lock-file dependencies through version-update pull requests. [github-dependabot]

## SOURCES

**octokit-openapi**
URL: https://github.com/octokit/openapi
Accessed: 2026-07-15

**stripe-openapi**
URL: https://github.com/stripe/openapi/blob/master/README.md
Accessed: 2026-07-15

**npm-trusted-publishers**
URL: https://docs.npmjs.com/trusted-publishers/
Accessed: 2026-07-15

**github-immutable-releases**
URL: https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases
Accessed: 2026-07-15

**github-dependabot**
URL: https://docs.github.com/en/code-security/concepts/supply-chain-security/dependabot-version-updates
Accessed: 2026-07-15

## SYNTHESIS

For a JSON contract whose primary consumers are TypeScript applications, publish a small exact-version npm package and retain the raw JSON plus immutable GitHub release assets. The package is a delivery mechanism: it gives package-manager resolution, lock-file pinning, offline build-time reads, standard upgrade PRs, and provenance. It must not become a second authored source of truth; generate it from the catalog and schemas already owned by the source repository.

GitHub release assets remain valuable for inspection, non-JavaScript consumers, and independent integrity verification. Requiring every JavaScript consumer to download, unpack, verify, and vendor them creates repeated bespoke dependency management. Runtime HTTP/CDN fetching is unsuitable for a contract used for build-time validation: it makes behavior depend on availability and an unpinned remote value.
