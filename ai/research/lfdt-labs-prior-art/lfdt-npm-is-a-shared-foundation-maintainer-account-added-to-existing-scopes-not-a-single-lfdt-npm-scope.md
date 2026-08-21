---
title: "LFDT's npm continuity mechanism is a shared foundation maintainer account (lfdt-npm) added per-package to existing project-owned scopes, not a unified @lfdt npm scope or a documented transfer runbook"
date: 2026-08-20
topic: lfdt-labs-prior-art
tags: [npm, publishing, oidc, trusted-publishing, provenance, governance, bus-factor]
status: draft
sources: [hyperledger-indy-vdr-npm, hyperledger-cactus-common-npm, openssf-npm-best-practices, npm-trusted-publishers-docs, openjs-trusted-publishing-caution, cacti-governance]
source_session: 5c3f462b-0296-4bd4-9a7c-6927a5d5f7d1
---

## CLAIMS

- `lfdt-npm <npm@lfdecentralizedtrust.org>` is a real, live npm maintainer account, listed as a co-maintainer on `@hyperledger/indy-vdr-nodejs` alongside `hyperledger-lf`, `hyperledger-ghci`, `openwalletfoundation`, and an individual maintainer. [hyperledger-indy-vdr-npm]
- `lfdt-npm` is NOT added uniformly across all LFDT/Hyperledger-lineage packages: `@hyperledger/cactus-common` lists only `hyperledger-ghci` and `hyperledger-lf` as maintainers, with no `lfdt-npm` entry. The account appears to be added per-package, likely as projects get touched post-Hyperledger→LFDT rebrand, not applied foundation-wide in one pass. [hyperledger-cactus-common-npm]
- There is no npm scope literally named `@lfdt` in current use as a unifying foundation scope; `lfdt-npm` is a maintainer *account* added into project-owned scopes (e.g. `@hyperledger/*`), not a scope of its own. [hyperledger-indy-vdr-npm]
- npm's GitHub Actions OIDC "trusted publishing" feature (`id-token: write`, no long-lived `NPM_TOKEN`) is npm's own implementation of the cross-registry OpenSSF "Trusted Publishers" standard, the same model PyPI and RubyGems use. [npm-trusted-publishers-docs]
- OpenSSF-aligned npm best-practices guidance (via lirantal/npm-security-best-practices, cited approvingly by Contrast Security) recommends both provenance attestations and trusted publishing as standard hardening to eliminate long-lived npm tokens. [openssf-npm-best-practices]
- OpenJS Foundation's Security Collaboration Space explicitly cautions AGAINST relying on npm Trusted Publishing for "critical" packages as of its most recent guidance, citing immature 2FA enforcement controls and that the mechanism as implemented would not have stopped attacks like Shai-Hulud. [openjs-trusted-publishing-caution]
- No LFDT or CNCF-published document was found describing a formal npm-scope-ownership transfer or bus-factor/continuity runbook (e.g., "what to do when a maintainer with npm publish rights leaves"). Hyperledger Cacti's GOVERNANCE.md covers maintainer addition/removal (3/4 maintainer approval) and release-decision quorum, but is silent on npm-registry-account mechanics specifically. [cacti-governance]

## SOURCES

**hyperledger-indy-vdr-npm**
URL: https://www.npmjs.com/package/@hyperledger/indy-vdr-nodejs
Accessed: 2026-08-20
Quote: maintainers via `npm view @hyperledger/indy-vdr-nodejs maintainers`: `['hyperledger-lf <npm@hyperledger.org>', 'hyperledger-ghci <npm-ci@hyperledger.org>', 'openwalletfoundation <npm@openwallet.foundation>', 'lfdt-npm <npm@lfdecentralizedtrust.org>', 'rafaelapb <rafael.belchior@tecnico.ulisboa.pt>']`

**hyperledger-cactus-common-npm**
URL: https://www.npmjs.com/package/@hyperledger/cactus-common
Accessed: 2026-08-20
Quote: maintainers via `npm view @hyperledger/cactus-common maintainers`: `['hyperledger-ghci <npm-ci@hyperledger.org>', 'hyperledger-lf <npm@hyperledger.org>']` — no `lfdt-npm`.

**openssf-npm-best-practices**
URL: https://github.com/lirantal/npm-security-best-practices
Accessed: 2026-08-20
Quote: recommends provenance attestations and trusted publishing (OIDC) to eliminate long-lived npm token risk; endorsed by Contrast Security as "well aligned with the software security community's best thinking on software supply chain security."

**npm-trusted-publishers-docs**
URL: https://docs.npmjs.com/trusted-publishers/
Accessed: 2026-08-20
Quote: "This feature implements the trusted publishers industry standard specified by the Open Source Security Foundation (OpenSSF)... Trusted publishing requires npm CLI version 11.5.1 or later and Node version 22.14.0 or higher." Publishing via trusted publishing from GitHub Actions or GitLab CI/CD automatically generates provenance attestations.

**openjs-trusted-publishing-caution**
URL: https://openjsf.org/blog/publishing-securely-on-npm
Accessed: 2026-08-20
Quote: "npmjs.com's implementation of Trusted Publishing is promising for JavaScript, but it's not ready for critical packages just yet" — cites immature 2FA enforcement; "We believe Trusted Publishing represents the future, but it's not yet ready for adoption in critical projects, as in its current state it wouldn't prevent attacks such as Shai-Hulud."

**cacti-governance**
URL: https://github.com/hyperledger-cacti/cacti/blob/main/GOVERNANCE.md
Accessed: 2026-08-20
Quote: maintainer addition/removal requires "three-quarters approval of the proposal by the existing maintainers"; release decisions by maintainer majority. No npm-registry-account-specific transfer procedure documented.

## SYNTHESIS

For any PDP-Connect/LFDT-adjacent package (e.g. `@pdpp/*`) that already lists `lfdt-npm <npm@lfdecentralizedtrust.org>` as a maintainer: this is real, precedented LFDT practice, not a one-off. Treat it as the institutional-continuity mechanism (foundation-controlled account co-owning publish rights alongside individual maintainers) and recommend adding `lfdt-npm` to any *new* publishable package's maintainer list at first-publish time — this is how the pattern actually propagates across the Hyperledger/LFDT npm footprint (per-package, not automatic).

For OIDC trusted publishing recommendations: cite OpenSSF/npm docs as the standard being followed, but the OpenJS caution is a legitimate, citable counterpoint worth one line of risk acknowledgment in any recommendation — not a reason to avoid it (a project already doing this successfully, like `@pdpp/cli`, is by definition ahead of a "not ready yet" bar aimed at much higher-value critical-infra packages).

Don't claim there's a documented LFDT npm bus-factor/transfer runbook — there isn't one to point to. The `lfdt-npm` account itself is the de facto mitigation; say so plainly rather than implying governance maturity that doesn't exist yet.
