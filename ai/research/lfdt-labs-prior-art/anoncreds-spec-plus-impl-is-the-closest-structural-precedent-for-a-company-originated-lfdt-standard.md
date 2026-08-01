---
title: "AnonCreds shows a company-originated spec-plus-reference-implementation project is neutralized as the entry condition for becoming its own LFDT/Hyperledger project, not before joining or slowly afterward, and it lands in a dedicated single-purpose GitHub org under a foundation-generic contributors byline with contributors keeping copyright"
date: 2026-07-17
topic: lfdt-labs-prior-art
tags: [anoncreds, hyperledger, lf-decentralized-trust, spec-plus-reference-implementation, licensing, copyright, project-lifecycle, vendor-neutrality]
status: draft
sources: [anoncreds-spec-repo, anoncreds-rs-repo, anoncreds-cargo-toml, anoncreds-rs-maintainers, anoncreds-rs-contributing, anoncreds-org-search, hyperledger-lifecycle-search, anoncreds-origin-search, anoncreds-neutralization-search, anoncreds-license-md, anoncreds-notices-md]
source_session: 019f9057-6ed2-77a1-ac39-4c6122c144ef
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation/conclusions. Skippable. No citations here.
Filename = the claim in kebab-case (greppable), under the matching topic/ dir.
Add one line to INDEX.md when you create this.
-->

## CLAIMS

- AnonCreds is split across multiple single-purpose repos under one dedicated GitHub organization (`github.com/anoncreds`, org id 202152041) that is separate from the general `hyperledger` GitHub org: `anoncreds-spec` (v1.0 spec source), `anoncreds-spec-v2` (forward-looking v2 spec), `anoncreds-rs` (Rust reference implementation), `anoncreds-v2-rs`, `anoncreds-clsignatures-rs`, `anoncreds-wrapper-javascript`, `anoncreds-methods-registry`, `anoncreds-revocation`, `anoncreds` (org-level meta repo), and `governance`. [anoncreds-org-search]
- Legacy repos under `hyperledger/anoncreds-spec` and `hyperledger/anoncreds-rs` are archived redirect shells; the live repos are the `anoncreds/*` copies. The archived `hyperledger/anoncreds-spec` repo's description is literally "The former home of the AnonCreds specification." [anoncreds-spec-repo]
- The repo-family naming convention is project-name-prefixed (`anoncreds-<component>`), not company-prefixed and not foundation-prefixed — mirroring the general Hyperledger/LFDT convention of one org per project holding `<project>-<component>` repos. [anoncreds-org-search]
- No repo named `anoncreds-clj` (Clojure) exists in the family; language bindings found are Rust (`anoncreds-rs`, `anoncreds-v2-rs`), JavaScript/Node/React Native (`anoncreds-wrapper-javascript`), and Python (wrapper inside `anoncreds-rs/wrappers/python`). [anoncreds-org-search]
- The spec repo (`anoncreds-spec`) is licensed under the Linux Foundation **Community Specification License v1.0**; its `4._License.md` states any source/sample code embedded in the spec repo defaults to Apache 2.0, but the Community Specification License governs in case of conflict. [anoncreds-license-md]
- Verbatim from `anoncreds-spec/4._License.md`: "Specifications in the repository are subject to the **Community Specification License 1.0** available at https://github.com/CommunitySpecification/1.0." and "If source code is included in this repository... that code is subject to the Apache 2.0 license unless otherwise designated. In the case of any conflict... the terms of the Community Specification License shall apply." [anoncreds-license-md]
- The code reference-implementation repo `anoncreds-rs` is licensed Apache-2.0 (confirmed both via the GitHub API `license` field and the repo's `LICENSE` file, which is the standard Apache 2.0 text). [anoncreds-rs-repo]
- `anoncreds-spec`'s own GitHub-API `license` field is *also* reported as Apache-2.0 (because it ships the standard Apache `LICENSE` file for any embedded code/samples alongside the Community Specification License text for the spec prose itself, per its own `4._License.md`), i.e. the repo carries two license regimes side by side rather than one blended license. [anoncreds-spec-repo] [anoncreds-license-md]
- The spec repo has a numbered top-level document structure (`1._Community_Specification_License-v1.md`, `2._Scope.md`, `3._Notices.md`, `4._License.md`, `5._Governance.md`, `6._Contributing.md`, `8._Code_of_Conduct.md`) that formally embeds the license and governance docs as first-class numbered spec sections, not as separate boilerplate files. [anoncreds-spec-repo]
- The copyright/author line in the code reference implementation's package manifest (`anoncreds-rs/rust/Cargo.toml`) reads: `authors = ["Hyperledger AnonCreds Contributors <anoncreds@lists.hyperledger.org>"]` — a foundation/project-generic "Contributors" byline tied to a Hyperledger mailing list, not a specific company name. [anoncreds-cargo-toml]
- `anoncreds-rs/CONTRIBUTING.md` states explicitly: "All contributors retain the original copyright to their stuff, but by contributing to this project, you grant a world-wide, royalty-free, perpetual, irrevocable, non-exclusive, transferable license to all users under the terms of the license under which this project is distributed." — i.e. a DCO/inbound-license grant model; LF/Hyperledger does NOT take copyright assignment. [anoncreds-rs-contributing]
- `anoncreds-rs/MAINTAINERS.md` states maintainer lists live in a single shared `anoncreds/governance` repo's `config.yaml` ("Access Control YAML file"), and that "All other AnonCreds Project repository MAINTAINERS.md files point to this file" — i.e. governance/maintainer identity is centralized once per project family, not duplicated per repo. [anoncreds-rs-maintainers]
- AnonCreds' cryptographic/product lineage originated at Evernym, was contributed to the Sovrin Foundation, then became Hyperledger Indy (accepted into Hyperledger in 2017); Evernym itself did not formally join Hyperledger until 2018, after the codebase had already been contributed, specifically to avoid exerting inappropriate influence over the project in its early years. [anoncreds-origin-search]
- AnonCreds was carved out of the Hyperledger Indy project and accepted as its OWN standalone Hyperledger project in October 2022 (publicly announced November 15, 2022), more than 5 years after AnonCreds functionality first existed inside Indy (since 2017). [anoncreds-origin-search]
- The explicit, stated motivation for spinning AnonCreds out of Indy into its own project was to make it "ledger-agnostic" — i.e. removing its dependency on the Hyperledger Indy ledger specifically so it would not be tied to one project/vendor's infrastructure, enabling use "with any number of platforms for storage rather than being tied to a specific ledger." [anoncreds-origin-search]
- The AnonCreds v1.0 specification working group's explicit deliverable was defined as: "an AnonCreds v1.0 specification that describes the existing implementation minus any dependency on the Hyperledger Indy ledger ('ledger-agnostic')" — i.e. the neutralization (removing ledger-specific coupling) was scoped as the FIRST specification-writing task after project creation, not a precondition completed before project creation. [anoncreds-spec-repo] [anoncreds-origin-search]
- The `anoncreds-rs` reference implementation was created by duplicating the existing `indy-shared-rs` repo and then removing "non-AnonCreds" parts, rather than starting a byte-for-byte fresh, unencumbered rewrite; the volume of changes needed to make it ledger-agnostic was reported as "surprisingly small." [anoncreds-origin-search]
- `anoncreds-rs`'s own README "Credit" section attributes the initial implementation to `indy-shared-rs`, "developed by the Verifiable Organizations Network (VON) team based at the Province of British Columbia" — a named external contributing organization credited by name in the reference-implementation repo itself, distinct from the Evernym/Sovrin origin story for the underlying AnonCreds concept. [anoncreds-rs-repo]
- Hyperledger/LF Decentralized Trust's formal project lifecycle has four stages: Proposal (often incubated first in the lower-commitment, lower-scrutiny "Hyperledger Labs"), Incubation (formal TOC-approved project via an HIP, given a real GitHub org/repos), Graduated (renamed from "Active"; reflects PROCESS maturity, not product maturity/GA), and Dormant (replaces "Deprecated"). [hyperledger-lifecycle-search]
- Graduation exit criteria require, among other things, an in-progress or complete OpenSSF Best Practices Badge and evidence of real-world (not just demo) usage. [hyperledger-lifecycle-search]
- AnonCreds entered directly as an Incubation-stage Hyperledger project in October 2022 (skipping/bypassing a separate Hyperledger Labs pre-stage), because it was already a mature, "de facto standard" component being carved out of an existing Graduated project (Indy), not a from-scratch idea. [anoncreds-origin-search] [hyperledger-lifecycle-search]

## SOURCES

**anoncreds-org-search**
URL: web search "AnonCreds spec repository github hyperledger anoncreds-rs anoncreds-clj repo family"; https://github.com/anoncreds
Accessed: 2026-07-17
Quote: "The `anoncreds` GitHub organization also includes: anoncreds-clsignatures-rs, anoncreds-wrapper-javascript, anoncreds-methods-registry (\"The AnonCreds Objects Method Registry, a registry of implementations for registering and resolving AnonCreds Objects on different Verifiable Data Registries\"), governance."

**anoncreds-spec-repo**
URL: https://github.com/anoncreds/anoncreds-spec (via `gh api repos/anoncreds/anoncreds-spec`); https://github.com/hyperledger/anoncreds-spec (via `gh api repos/hyperledger/anoncreds-spec`); https://raw.githubusercontent.com/anoncreds/anoncreds-spec/main/README.md
Accessed: 2026-07-17
Quote: (hyperledger/anoncreds-spec API) `"description":"The former home of the AnonCreds specification.","archived":true`. (anoncreds/anoncreds-spec README) "This repository contains the source content for the AnonCreds open specification, a part of the Hyperledger AnonCreds Project... This open specification is based on the open source AnonCreds verifiable credential implementation in the Hyperledger AnonCreds GitHub repository anoncreds-rs. That implementation was originally part of the Hyperledger Indy open source project, accepted into Hyperledger in 2017."

**anoncreds-rs-repo**
URL: https://github.com/anoncreds/anoncreds-rs (via `gh api repos/anoncreds/anoncreds-rs`); https://raw.githubusercontent.com/anoncreds/anoncreds-rs/main/README.md
Accessed: 2026-07-17
Quote: API `"license":{"key":"apache-2.0","name":"Apache License 2.0",...}`. README: "The initial implementation of anoncreds-rs is derived from indy-shared-rs that was developed by the Verifiable Organizations Network (VON) team based at the Province of British Columbia, and derives largely from the implementations within Hyperledger Indy-SDK."

**anoncreds-cargo-toml**
URL: https://raw.githubusercontent.com/anoncreds/anoncreds-rs/main/Cargo.toml
Accessed: 2026-07-17
Quote: "authors = [\n    \"Hyperledger AnonCreds Contributors <anoncreds@lists.hyperledger.org>\",\n]\ndescription = \"Verifiable credential issuance and presentation for Hyperledger AnonCreds (https://www.hyperledger.org/projects), which provides a foundation for self-sovereign identity.\"\n...\nlicense = \"Apache-2.0\""

**anoncreds-rs-maintainers**
URL: https://raw.githubusercontent.com/anoncreds/anoncreds-rs/main/MAINTAINERS.md
Accessed: 2026-07-17
Quote: "This file defines the Maintainers processes (adding, removing) and duties for all repositories in the LF Decentralized Trust AnonCreds Project... All other AnonCreds Project repository MAINTAINERS.md files point to this file. ... Maintainers for this repository are listed in the [Access Control YAML file]... [Access Control YAML file]: https://github.com/anoncreds/governance/blob/main/config.yaml"

**anoncreds-rs-contributing**
URL: https://raw.githubusercontent.com/anoncreds/anoncreds-rs/main/CONTRIBUTING.md
Accessed: 2026-07-17
Quote: "All contributors retain the original copyright to their stuff, but by contributing to this project, you grant a world-wide, royalty-free, perpetual, irrevocable, non-exclusive, transferable license to all users under the terms of the license under which this project is distributed."

**anoncreds-license-md**
URL: https://raw.githubusercontent.com/anoncreds/anoncreds-spec/main/4._License.md ; https://raw.githubusercontent.com/anoncreds/anoncreds-spec/main/3._Notices.md
Accessed: 2026-07-17
Quote: "Specifications in the repository are subject to the Community Specification License 1.0 available at https://github.com/CommunitySpecification/1.0. ... If source code is included in this repository, or for sample or reference code included in the specification itself, that code is subject to the Apache 2.0 license unless otherwise designated. In the case of any conflict or confusion within this specification repository between the Community Specification License and the Apache 2.0 license or other designated license, the terms of the Community Specification License shall apply."

**anoncreds-notices-md**
URL: https://raw.githubusercontent.com/anoncreds/anoncreds-spec/main/3._Notices.md
Accessed: 2026-07-17
Quote: "Per Community Specification License 1.0 Section 2.1.3.3, Licensees may indicate their acceptance of the Community Specification License by issuing a pull request to the Specification's repository's 3_Notices.md file (this file), including the Licensee's name, authorized individuals' names, and repository system identifier (e.g. GitHub ID), and specification version."

**anoncreds-origin-search**
URL: web search "AnonCreds Hyperledger Indy Evernym history transition Sovrin origin"; web search "AnonCreds Hyperledger project proposal HIP 2022 vendor neutral Indy dependency removed independent VON"; https://www.lfdecentralizedtrust.org/blog/2022/11/15/announcing-hyperledger-anoncreds-open-source-open-specification-privacy-preserving-verifiable-credentials
Accessed: 2026-07-17
Quote: "Hyperledger AnonCreds was accepted as its own project at the Hyperledger Foundation in October 2022, though AnonCreds within Hyperledger dates back to the start of the Hyperledger Indy project in 2017. The motivation for taking AnonCreds out of the Indy project was to simplify the technology, reflecting the reality that AnonCreds can use any number of platforms for storage rather than being tied to a specific ledger." Also: "The AnonCreds working group is producing an AnonCreds v1.0 specification that describes the existing implementation minus any dependency on the Hyperledger Indy ledger ('ledger-agnostic')." Also: "The Rust implementation of AnonCreds was created by duplicating the repo of its previous home in the indy-shared-rs repository, and the subsequent removal of the 'non-AnonCreds' parts of the repo... the volume of changes needed to make it ledger-agnostic was surprisingly small." Also (Evernym join timing): "Evernym itself didn't formally join Hyperledger until 2018, despite having created the core codebase — it was the high value they placed on Indy's independence that kept Evernym from joining Hyperledger until then, since they felt their pride as creators of Indy might cause them to exert inappropriate influence over its initial formative stages."

**hyperledger-lifecycle-search**
URL: web search "Hyperledger Foundation project lifecycle stages proposal incubation active graduated maturity vendor neutral"; https://toc.hyperledger.org/governing-documents/project-lifecycle.html; https://toc.hyperledger.org/governing-documents/project-incubation-exit.html
Accessed: 2026-07-17
Quote: "Graduated in this case refers to the project itself rather than its product and it is therefore more about the maturity of process than the maturity of the product or General Availability (GA)." Also: "a team seeking to graduate from Incubation shall have started the OpenSSF Best Practices Badge application and be nearly complete with incomplete badge requirements referenced in their graduation proposal." Also: "ideas should start in Hyperledger Labs... entering Incubation does not guarantee that the project will eventually get to the Graduated state."

**anoncreds-neutralization-search**
URL: web search ""anoncreds" github organization "governance" repo owner maintainers Linux Foundation Decentralized Trust org transfer 2025"
Accessed: 2026-07-17
Quote: "This organization contains multiple repositories including anoncreds/governance, anoncreds/anoncreds, anoncreds/anoncreds-spec, anoncreds/anoncreds-spec-v2, anoncreds/anoncreds-methods-registry, anoncreds/anoncreds-clsignatures-rs, anoncreds/anoncreds-revocation, anoncreds/anoncreds-v2-rs, and anoncreds/anoncreds-wrapper-javascript."

## SYNTHESIS

AnonCreds is a strong structural precedent for PDP-Connect (pdpp spec + data-connect reference app + data-connectors) on almost every axis we care about, with one important nuance to correct in our own planning assumptions.

1. **Repo family shape**: one dedicated GitHub org per project (`anoncreds`, not `hyperledger`), holding a spec repo, a reference-implementation repo, wrapper/binding repos, and a shared `governance` repo that all other repos' MAINTAINERS.md files point back to. This maps directly onto a `PDP-Connect` org holding `pdpp` (spec), `data-connect` (reference app), `data-connectors`, plus one `governance` repo — rather than trying to cram governance into each repo or scatter it under a generic LFDT org.

2. **Licensing split is real and repo-scoped, not project-scoped**: the SPEC repo carries the Community Specification License v1.0 as primary, with Apache 2.0 as a fallback specifically for embedded sample/reference code, and an explicit conflict-resolution clause favoring the spec license. The CODE repos (reference implementation) carry plain Apache-2.0. This is a clean, precedented split we should copy exactly for pdpp (spec) vs data-connect/data-connectors (code) rather than inventing our own scheme.

3. **Copyright model is DCO, not assignment.** The Cargo.toml `authors` field uses a foundation-generic "Hyperledger AnonCreds Contributors <mailing-list>" byline — deliberately not a company name — and CONTRIBUTING.md is explicit that contributors retain their own copyright and merely grant a license. LF/Hyperledger never takes copyright assignment. This is the answer to "does the foundation own the code" — it doesn't; it's inbound-licensed only. PDP-Connect should adopt an identical generic project-contributors byline (not "Vana Contributors" or similar) plus a DCO/license-grant CONTRIBUTING clause.

4. **The neutralization timing answer is decisive and is the single most decision-relevant fact**: AnonCreds was NOT neutralized before entering the foundation. It ran inside Hyperledger Indy, coupled to the Indy ledger, for 5+ years (2017–2022) as a component of somebody else's (Evernym-originated, later community-owned) project. The ledger-agnostic rewrite — the actual "remove vendor/infra coupling" work — was scoped as the FIRST DELIVERABLE of the newly-created standalone project's working group, done publicly, incrementally, and was reported as smaller in scope than expected. Evernym's own company-to-foundation trust move (waiting a year to formally join Hyperledger despite having authored the code, specifically to avoid founder-capture optics) is a distinct, second neutralization signal at the CORPORATE level, separate from the CODE-level neutralization. Net: entering as-is and neutralizing over time, in public, as project work — not a private pre-cleanup — is the proven, precedented path. This directly supports doing the PDP-Connect transfer with pdpp/data-connect/data-connectors entering LFDT with Vana-originated history intact, and treating "remove Vana-specific coupling" as an early post-entry working-group task rather than a blocking pre-condition.

5. **Lifecycle mechanics**: AnonCreds skipped Hyperledger Labs and went straight into Incubation because it was already a mature, widely-used component being carved out of a Graduated project — this is likely also PDP-Connect's shape (mature working code, not a green-field idea), so we should expect/ask for direct Incubation entry rather than a Labs detour, citing this precedent.

One caution: AnonCreds' "de facto standard" claim and its unusually fast Incubation entry both rest on it already having 5+ years of production usage and an existing standards-track specification effort before the org spinout — the precedent supports skipping Labs only if PDP-Connect can make a comparably strong existing-adoption case; it is not evidence that brand-new specs skip Labs.
