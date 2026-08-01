---
title: "Company-originated Linux Foundation projects (CNCF, LFDT/Hyperledger) enter Sandbox/Labs with vendor infrastructure and branding intact; formal vendor-neutrality of metadata, resources, and governance is an Incubation/Graduation-stage requirement, not an entry gate"
date: 2026-07-17
topic: lfdt-labs-prior-art
tags: [linux-foundation, cncf, lfdt, hyperledger, vendor-neutrality, project-lifecycle, donation, sandbox, labs, incubation, graduation]
status: draft
sources: [cncf-lifecycle, cncf-incubation-template, cncf-vendor-neutrality-guide, cncf-toc-issue-2231, lfdt-labs-proposal, lfdt-labs-github, hiero-announcement, hedera-hiero-blog, backstage-spotify-sandbox-post, ibm-fabric-token-donation, coindesk-hyperledger-labs, lfdt-toc-project-lifecycle, lfdt-aifaq-incubation-proposal]
source_session: 019f5128-5759-7c61-9407-764bfcf59b6d
---

## CLAIMS

- CNCF's formal project lifecycle has three active maturity stages — Sandbox, Incubating, Graduated — and the criteria for Incubation and Graduation are maintained as separate, higher-bar application templates layered ON TOP OF the prior stage's criteria, not required at Sandbox entry. [cncf-lifecycle]
- The CNCF Incubation application template requires, as a named criterion, "All project metadata and resources are vendor-neutral" and (as a suggested/governance item) "Governance clearly documents vendor-neutrality of project direction" — i.e., vendor-neutrality is explicitly gated at the Incubation step, evaluated as new/continuation criteria once a project seeks to leave Sandbox. [cncf-incubation-template]
- CNCF's own "What it Means to be a Vendor Neutral Project" guide is written as a general best-practices document (how to communicate, host, and govern neutrally) and is not stratified by maturity stage in its text — it is the reference standard that Incubation/Graduation applications point to and are scored against, rather than a Sandbox-entry gate itself. [cncf-vendor-neutrality-guide]
- A 2026 CNCF TOC initiative (open issue) states that vendor-neutrality guidelines are "explicitly linked to by the TOC as requirements for a project to move to either Incubation or Graduation," and separately reports that vendor-neutrality gaps (unwritten governance rules, employer-specific container LABEL/maintainer metadata) still show up in 24 of 42 due-diligence reports (57%) over 5 years across projects including HAMi, Crossplane, wasmCloud, KServe, OpenFGA, and Knative — i.e., neutrality is checked and enforced at the DD (due-diligence) gate for level-changes, and imperfect neutrality persists in already-Incubating/Graduated projects, confirming it is a maturity-gate concern, not a pre-entry cleanliness bar. [cncf-toc-issue-2231]
- Backstage, built and used internally by Spotify for years, was accepted into CNCF Sandbox in September 2020 as Spotify's own internal developer-portal tool, explicitly to be "developed with input and contributions from the community" going forward — the donation happened first, community-driven neutralization was the stated FUTURE plan, not a pre-condition already satisfied at entry. [backstage-spotify-sandbox-post]
- Spotify continues to run its own internal Backstage instance and, as of the current search, sells a commercial SaaS product "Spotify Portal" ("Backstage in a box") explicitly branded around Backstage — years after Sandbox entry and progression to Incubating status — showing that even sustained company-branding/commercial association is compatible with continued CNCF maturity progression rather than being purged at any single gate. [backstage-spotify-sandbox-post]
- LF Decentralized Trust (formerly Hyperledger)'s Labs tier is explicitly designed as a low-bar, non-TAC-overseen on-ramp: code is contributed "AS-IS," is community- (not TAC-) managed, receives no legal/security review, and carries no requirement to meet "any functional requirements" before being hosted under the `hyperledger-labs` (now LFDT Labs) GitHub org. [lfdt-labs-proposal][coindesk-hyperledger-labs]
- The original Hyperledger Labs proposal explicitly reserves the "Hyperledger project" identity and its associated formal/legal weight for later, TAC-overseen Incubation: Labs contributors "may refer to this type of work as a 'Hyperledger Lab'" but it "is not permitted to publicly refer to work under the hyperledger-labs org as a 'Hyperledger project'" — i.e., the identity/branding-neutrality bar only attaches once a project formally enters Incubation via a HIP. [lfdt-labs-proposal]
- Hedera's entire core network codebase (consensus node, mirror node, SDKs, JSON-RPC relay) was donated wholesale to LF Decentralized Trust as the project "Hiero" in September 2024; the Hedera Council continued (and continues) to operate the Hedera mainnet as "an instance of the Hiero codebase," and post-donation migration work (e.g., the Hiero Local Node repo) was still using Hedera/hashgraph-branded GitHub namespaces, NPM package names, and terminology well after the LFDT transfer, with namespace migration described as ongoing rather than a pre-donation precondition. [hiero-announcement][hedera-hiero-blog]
- The canonical LFDT/Hyperledger TOC "Project Lifecycle" governing document defines only four formal project states — Proposal, Incubation, Graduated, and Dormant/Archived — and does NOT mention "Labs" anywhere; Labs sits entirely outside this formal lifecycle document, confirming (independently of the Labs proposal doc itself) that Labs is a non-TOC-governed, pre-formal on-ramp with no standing in the document that carries the formal requirements. [lfdt-toc-project-lifecycle]
- The formal "Be vendor neutral" requirement in the LFDT/Hyperledger lifecycle is attached to the PROPOSAL step — the gate a project must clear to ENTER Incubation ("Proposals that are approved enter into an Incubation state") — alongside having a clear description, defined scope, committed development resources, and identified maintainers; it is not attached to Labs, which precedes and sits outside the Proposal/Incubation/Graduated pipeline entirely. [lfdt-toc-project-lifecycle]
- A live, current (2025) LFDT Incubation proposal (AIFAQ, moving from Labs into Incubation) demonstrates exactly this gate in practice: its incubation proposal makes an explicit, itemized vendor-neutrality case — "No vendor-specific code paths are required to use AIFAQ," "supports multi-cloud and hybrid deployments," "maintainers represent multiple institutional affiliations, not a single corporate sponsor" — showing that vendor-neutrality is something a project must actively DEMONSTRATE and ARGUE FOR to clear the Labs-to-Incubation transition, not something presumed true of Labs code by default. [lfdt-aifaq-incubation-proposal]
- No source found in this research states or implies that a company must strip its own infrastructure dependencies, SaaS defaults, or branding from a codebase BEFORE it can be donated into an LF Labs tier, a CNCF Sandbox project, or (per the IBM/Fabric case) even during ongoing incubation — the pattern found in every concrete example is the reverse: donate the working, company-shaped code first, neutralize incrementally as the project matures and community/governance requirements tighten at each subsequent gate. [lfdt-labs-proposal][backstage-spotify-sandbox-post][ibm-fabric-token-donation]
- IBM's continued relationship with Hyperledger Fabric (which it originally contributed) shows the same incremental pattern from the maintainer side: years after Fabric's initial 2015-era donation and 2017 Incubation, IBM open-sourced ADDITIONAL previously-proprietary/commercial components (Fabric Token SDK, the IBM Blockchain Platform Console, becoming the community-owned Fabric Operations Console) in 2021 — vendor-neutralization of a donated codebase is documented here as a multi-year, incremental process driven by the maintainer's own choices, not a single before/after gate enforced by the foundation. [ibm-fabric-token-donation]

## SOURCES

**cncf-lifecycle**
URL: https://contribute.cncf.io/projects/lifecycle/
Accessed: 2026-07-17
Quote: "Projects can find the criteria for Incubation by reviewing the Incubation application template" / "Projects can find the criteria for Graduation by reviewing the Graduation application template" — criteria for each stage are maintained as separate, additive templates rather than a single unified entry bar; Sandbox entry criteria (minimum 3 maintainers from 2+ organizations) do not include a vendor-neutrality item.

**cncf-incubation-template**
URL: https://github.com/cncf/toc/blob/main/.github/ISSUE_TEMPLATE/template-incubation-application.md
Accessed: 2026-07-17
Quote: "All project metadata and resources are vendor-neutral." (Application Process Principles, required) and "Governance clearly documents vendor-neutrality of project direction." (Governance and Maintainers, suggested) — both appear as Incubation-stage criteria, referencing the external vendor-neutrality guide.

**cncf-vendor-neutrality-guide**
URL: https://contribute.cncf.io/projects/best-practices/community/vendor-neutrality/
Accessed: 2026-07-17
Quote: "wherever possible, community meetings, events, resources, and infrastructure should be hosted on resources belonging to the CNCF, or on other neutral, 3rd-party resources... If self-hosting is required, project sponsors should try to still separate resources affiliated with the CNCF project from resources attached to their products."

**cncf-toc-issue-2231**
URL: https://github.com/cncf/toc/issues/2231
Accessed: 2026-07-17
Quote: "guidelines on vendor neutrality are explicitly linked to by the TOC as requirements for a project to move to either Incubation or Graduation" — and reports the finding appears in "24 of 42 DD reports (57%) scanned over the last 5 years," spanning HAMi, Crossplane, wasmCloud, KServe, OpenFGA, and Knative.

**lfdt-labs-proposal**
URL: https://github.com/LF-Decentralized-Trust-labs/LF-Decentralized-Trust-labs.github.io/blob/main/proposal.md
Accessed: 2026-07-17
Quote: "Code from Labs is code provided 'AS-IS', shared with the Hyperledger community (and beyond) without guarantee of any kind." / "It is not permitted to publicly refer to work under the hyperledger-labs org as an 'Hyperledger project'... One may refer to this type of work as a 'Hyperledger Lab'." / "If at any point a lab wants to enter Incubation and become a project, a HIP will need to be submitted for TOC consideration."

**lfdt-labs-github**
URL: https://github.com/hyperledger-labs
Accessed: 2026-07-17

**hiero-announcement**
URL: https://www.lfdecentralizedtrust.org/blog/introducing-hiero-bringing-hederas-core-network-software-to-linux-foundation-decentralized-trust
Accessed: 2026-07-17
Quote: "the entire Hiero codebase, including core network components and SDKs, will be available under the Apache 2.0 license" — announced as a full, direct codebase transfer of Hedera's production network software, not a pre-cleaned subset.

**hedera-hiero-blog**
URL: https://hedera.com/hiero-open-source/
Accessed: 2026-07-17
Quote: "The Hedera public ledger now operates as an instance of the Hiero codebase" — confirms the Hedera Council continues operating production infrastructure directly on the donated codebase post-transfer; the hiero-local-node repo README (github.com/hashgraph/hedera-local-node) documents ongoing hashgraph→hiero namespace migration work occurring after the LFDT transfer.

**backstage-spotify-sandbox-post**
URL: https://engineering.atspotify.com/2020/9/cloud-native-computing-foundation-accepts-backstage-as-a-sandbox-project
Accessed: 2026-07-17
Quote: "we wanted the open source version to be developed with input and contributions from the community" — stated as the plan going forward from Sandbox acceptance, not a completed precondition.

**ibm-fabric-token-donation**
URL: https://www.coindesk.com/markets/2021/06/09/ibm-donates-code-improvements-to-open-source-hyperledger
Accessed: 2026-07-17
Quote: IBM, "the original code contributor and continues to be a major maintainer of Fabric," open-sourced the Fabric Token SDK and the previously-licensed IBM Blockchain Platform Console (becoming the community-owned Fabric Operations Console) in 2021 — years after Fabric's original donation and incubation, illustrating incremental, maintainer-driven neutralization rather than a single foundation-enforced entry gate.

**coindesk-hyperledger-labs**
URL: https://coindesk.com/opening-hyperledger-consortium-create-experimental-labs-startups
Accessed: 2026-07-17
Quote: Labs code "will not be required to meet any functional requirements," will not receive "intellectual property rights to identify as a 'Hyperledger Project,'" will not get "legal and security checks before major releases," and will not be "supported by the official Hyperledger marketing campaign" — describing Labs as an explicitly low-bar, low-formality on-ramp by design.

**lfdt-toc-project-lifecycle**
URL: https://toc.hyperledger.org/governing-documents/project-lifecycle.html
Accessed: 2026-07-17
Quote: "Project Proposals must be submitted to the TOC for review, using Proposal Template. Proposals that are approved enter into an Incubation state." Proposal requirements include: "Have a clear description," "Have a well-defined scope," "Identify committed development resources," "Identify initial maintainers," and "Be vendor neutral." "Labs" does not appear anywhere in this document; only Proposal, Incubation, Graduated, and Dormant/Archived are defined states.

**lfdt-aifaq-incubation-proposal**
URL: https://lf-hyperledger.atlassian.net/wiki/spaces/labs/pages/20291014
Accessed: 2026-07-17
Quote: "The project supports multi-cloud and hybrid deployments (Snowflake, AWS, Azure, GCP, on-prem)"; "No vendor-specific code paths are required to use AIFAQ"; "The maintainers represent multiple institutional affiliations, not a single corporate sponsor" — presented as part of an active proposal case FOR moving AIFAQ from Labs into Incubation, i.e. vendor-neutrality is argued/demonstrated at the transition, not assumed of Labs code.

## SYNTHESIS

For the data-connect transfer into an LFDT lab: bundled Vana infrastructure at Labs-entry is normal, not a violation, and this is now confirmed by the canonical governing document, not just inferred by analogy. The LFDT/Hyperledger TOC's actual "Project Lifecycle" document defines exactly four formal states — Proposal, Incubation, Graduated, Dormant/Archived — and Labs is not one of them; Labs sits entirely outside the document that carries the "Be vendor neutral" requirement. That requirement is attached specifically to the PROPOSAL step, which is the formal gate a project clears to ENTER Incubation, not the gate to enter Labs. The live AIFAQ incubation proposal shows this playing out in real time: a project makes an itemized, argued case for its own vendor-neutrality ("no vendor-specific code paths," multi-cloud support, multi-institution maintainers) specifically AS PART OF the ask to leave Labs and enter Incubation — confirming neutrality is something to be demonstrated at that transition, not a precondition already satisfied by Labs-resident code. This is reinforced by CNCF's structurally identical pattern (Backstage/Spotify entered Sandbox with the tool still Spotify's internal product; "all project metadata and resources are vendor-neutral" is a named Incubation-template criterion, not a Sandbox one) and by the IBM/Fabric case, where vendor-specific-to-neutral migration (Token SDK, Blockchain Platform Console → Fabric Operations Console) unfolded incrementally over years post-donation rather than as a single entry gate.

Practical implication: it is safe and consistent with both the written LFDT lifecycle policy and observed practice (CNCF Backstage, LFDT Hiero/Hedera) to transfer data-connect into an LFDT lab with Vana infrastructure/defaults still wired in. The one live guardrail at Labs entry is identity/branding, not infrastructure: per the Labs proposal doc, don't call it a "Hyperledger/LFDT project" pre-Incubation — refer to it as "an LFDT Lab." The infrastructure-neutrality work (making Vana-specific dependencies configurable/optional, demonstrating it can run without Vana's specific backend, documenting multi-institution governance) becomes the real, evidenced ask only when/if a Proposal is filed to move from Labs into Incubation — at which point expect to write the data-connect equivalent of AIFAQ's "no vendor-specific code paths are required" claim, and to have it checked. This is a high-confidence finding: it rests on the actual current LFDT TOC governing document (not just the older Labs proposal essay), a live real-world LFDT incubation proposal demonstrating the exact mechanism, CNCF's directly-quoted Incubation template, and two independent real-company-donation precedents (Backstage/Spotify at CNCF, Hiero/Hedera at LFDT itself) with no counter-example found anywhere of infrastructure-neutrality being required before Labs/Sandbox entry.
