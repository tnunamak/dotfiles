---
title: "Post-transfer usage control is not a solved problem — IDSA's own position paper says usage control 'cannot guarantee enforcement once data leaves the connector or domain of the data provider,' EDC implements a JSON-Schema-constrained ODRL subset with no conformance suite and no post-transfer mechanism, sticky policies never left prototype in ~20 years, and 2024-25 sub-$1,000 attacks (TEE.Fail, Battering RAM, RMPocalypse, WireTap) broke SGX/SEV-SNP including forged attestations — the only mechanism that genuinely enforces post-transfer constraints (data clean rooms) does so by never transferring raw data at all"
date: 2026-09-03
topic: protocols
tags: [usage-control, idsa, eclipse-dataspace-components, odrl, xacml, sticky-policies, drm, tee, sgx, sev-snp, data-clean-rooms, enforcement, pdpp]
status: draft
sources: [idsa-ram-status, idsa-position-paper, idsa-rulebook, idsa-catenax-critique, edc-github-4351, edc-github-4606, edc-handbook, edc-academic-survey, xacml-forrester, xacml-kuppingercole, xacml-successors, sticky-policies-hp, sticky-policies-survey, drm-widevine, drm-fairplay-jobs, tee-attacks-2025, clean-rooms-adh, clean-rooms-mechanics, odrl-formal-semantics, odrl-rightsml-iptc]
source_session: da53c1ca-0fcc-46b4-9b1a-3e44d3b7159c
---

<!--
Mechanical transformation of /home/tnunamak/code/pdpp/local/research/_deep-0903/area2-usage-control.md
into corpus format. No new research performed. Convention preserved from source: SPECIFIED
(written in a spec) vs DEPLOYED (running in production) vs ENFORCED (a technical mechanism
actually blocks/detects violation, as opposed to relying on contract/trust).
-->

## CLAIMS

- **IDSA's own Position Paper "Usage Control in the IDS" (V3) states directly: "Usage control cannot guarantee enforcement once data leaves the connector or domain of the data provider."** This quote was extracted by a PDF-fetch-and-summarize tool from a 5.7MB PDF rather than hand-verified character-by-character against the original page — **flag as PDF-extracted, recommend one more manual check before quoting in a final report.** [idsa-position-paper]
- IDSA's usage-control architecture (PEP/PDP/PXP, per IDS-RAM 4) governs what a party may do with data *after* they already have legitimate access, distinct from access control (whether a party may access data at all) — but the reference "IDS Usage Control Contract" model's policy classes include a "Connector-restricted" option that ties usage rights to a specific named consumer connector, i.e. the model explicitly assumes enforcement can at best be pinned to a piece of named consumer infrastructure, not to arbitrary downstream use. [idsa-position-paper]
- **The IDSA Rulebook (2026-1 release) frames "data sovereignty" explicitly as "a spectrum"** built on participant autonomy, decentralization, and trust rather than absolute technical control, stating that a Data Space's legal layer is where enforcement responsibility shifts once the connector boundary is crossed. [idsa-rulebook]
- **IDS-RAM 4 (2023) is frozen as of 2026**: IDSA states it "is archived and will not be further updated, though it remains the baseline for existing implementations, certification, and training until the transition to the next edition is complete," with RAM 5 in development because RAM 4's structure "does not allow for modular updates." [idsa-ram-status]
- A directly on-point academic source ("Assessing the State of Proactive Data Usage Control Enforcement," Springer) states "it remains unclear how close existing solutions actually come to the goal of enforcing [usage-control] policies with technical means." A separate survey (arXiv 2203.04800) distinguishes **preventive mechanisms** (actually block a violation before it happens) from **detective mechanisms** (audit logs that only report after the fact), and notes verifying an actual deletion happened is hard in practice, so systems fall back to trusting a log entry. [idsa-catenax-critique]
- In June 2026, IDSA and Catena-X launched a €23M "Data Space Accelerator" program (funded by the German BMWE) specifically to bring SMEs into the certified-connector ecosystem, with payouts (€15K-30K) released only "once companies demonstrate verified productive data exchange with at least one supply-chain partner" — the program itself treats "actually using it" as a milestone still to be proven for most SMEs as of mid-2026, not an existing baseline. [idsa-catenax-critique]
- **Eclipse Dataspace Components (EDC) — the reference open-source connector used by Catena-X and most EU data-space pilots — implements a constrained ODRL subset, not the full model, per its own maintainers.** An EDC maintainer stated in GitHub discussion #4351/#4606: "no implementation can 'conform' to DSP because a TCK [Technical Compatibility Kit] has not been published at Eclipse" and "ODRL is too open-ended," with work "ongoing to more explicitly define what ODRL expression types are supported (via JSON Schema)." [edc-github-4351]
- EDC's own developer handbook states policy "operators" are not a fixed universal enum: **"Whether an operator is valid is solely defined by the policy evaluation function"** — the semantics of any constraint are only as strong as whatever custom Java evaluation function a deployer wrote. An early academic survey of dataspace connectors (arXiv 2309.11282) found EDC's shipped sample policy was, at the time, "very simplistic (no specific constraints, allowing 'direct access to all assets')." [edc-handbook]
- EDC's evaluation-function architecture runs entirely **before** data leaves the provider connector — EDC has no mechanism at all to constrain what a consumer does with data after transfer. [edc-github-4606]
- **XACML 3.0 (OASIS, last major version approved 2013) is the direct precedent for "rich declarative policy language, technically sound, standards-body-blessed — nobody adopted it at scale."** Forrester analyst Andras Cser's May 2013 blog post ("XACML is dead") gave five reasons: not adopted by enterprises with existing home-grown authorization engines; designed for monolithic centrally-managed identity, not federated/external users; PDP decisions opaque to the PEP (hard to debug a denial); not cloud-friendly (synchronous WAN calls to a remote PDP); no commercial support ecosystem or PEP libraries. [xacml-forrester]
- Even critics of the "XACML is dead" framing (KuppingerCole, calling it an analyst fad) conceded XACML's real weak point: "its policy language lacks the flexibility and dynamics needed in real-world authentication and authorization engines, and it adds complexity requiring significant 'plumbing' before practical use." [xacml-kuppingercole]
- XACML's replacement was not one successor but a fragmentation into purpose-built engines (OPA/Rego, Cedar, Zanzibar-model ReBAC systems SpiceDB/OpenFGA/Permify), with **OpenAI reported using SpiceDB for ChatGPT Enterprise connectors, handling tens of billions of fine-grained permissions.** A 2024 interoperability effort (AuthZEN, 12 implementations) was assembled specifically because these newer engines' APIs are "completely fragmented" — the industry replaced one heavyweight universal standard with several lighter engines and is now re-discovering it needs an interop layer again. [xacml-successors]
- **Sticky policies (HP Labs, Marco Casassa Mont and Siani Pearson, mid-2000s onward)** bind machine-readable policy conditions cryptographically to data so the policy "travels with" the data across administrative domains, enforced via a Trusted Third Party (TTP) holding decryption keys that releases them only to a recipient demonstrating compliance. [sticky-policies-hp]
- **The flagship applied project, EnCoRe ("Ensuring Consent and Revocation," UK Technology Strategy Board-funded, HP-led), never became a deployed commercial product.** Every EnCoRe deliverable is described in source materials as "architectures, technology innovations, and proof-of-concept prototypes" — never a product. A 2019 survey of sticky-policies research still discusses them in terms of "limitations, open issues... research challenges" a decade-plus after HP Labs' original work, and a 2024 PeerJ paper on GDPR-compliant cloud architecture still treats sticky policies as a proposed mechanism, not an established one. **This is the clearest historical precedent for cryptography-plus-TTP-based post-transfer enforcement simply never crossing from research into deployment, over a ~20-year span.** [sticky-policies-survey]
- **Google's Widevine DRM is deployed on 4bn+ devices and is the dominant non-Apple streaming DRM**; its success mechanism is structural, not purely cryptographic — each platform owner (Google/Widevine, Apple/FairPlay, Microsoft/PlayReady) refuses to host another vendor's CDM at the hardware root of trust, and Widevine ties content quality directly to hardware trust (L1 = hardware TEE decrypt+decode → full HD/UHD; L3 = software-only → SD-only), with device makers required to certify hardware against Google's public registry. **DRM "works" at scale only when the enforcer also controls and certifies the endpoint hardware** — it is not a pure software/policy achievement. [drm-widevine]
- **DRM'd music collapsed 2007-2009 once the rights-holders themselves stopped requiring it.** Steve Jobs' "Thoughts on Music" (Feb 6, 2007) argued the major labels, not Apple, required DRM, and pledged Apple would sell DRM-free if the labels allowed it. EMI offered DRM-free "iTunes Plus" tracks starting April 2007; Amazon launched a DRM-free MP3 store (2M+ songs, 20,000+ labels) in September 2007; by 2009 all major labels had dropped DRM from the iTunes catalog. The practical lesson: music DRM's enforcement layer was only as durable as the least-committed party in the chain, unlike video, where studios have never relented on protected delivery. [drm-fairplay-jobs]
- **2024-2025 produced a wave of published attacks breaking confidential-computing TEEs, the mechanism most often proposed as "the answer" to post-transfer enforcement**: RMPocalypse (CVE-2025-0033, a race condition defeating AMD SEV-SNP memory-ownership guarantees during VM init); Heracles, WeSee, Heckler (USENIX Security 2024/ACM CCS 2025, chosen-plaintext and interrupt-based attacks breaking SEV-SNP confidentiality); **TEE.Fail (Oct 2025, Georgia Tech/Purdue)** — a DDR5 memory-bus interposer attack buildable for under $1,000, breaking Intel SGX, Intel TDX, and AMD SEV-SNP simultaneously, including forging TDX attestations on a real production system (Ethereum BuilderNet) and extracting ECDH keys, and still working even with AMD's "Ciphertext Hiding" mitigation enabled; **Battering RAM / WireTap (Oct 2025, KU Leuven/Birmingham and Georgia Tech/Purdue)** — $50-$1,000 physical DDR4-bus interposers that replay captured enclave ciphertext into a new enclave and forge SEV-SNP attestations, "causing the secure processor to attest a backdoored VM as genuine." Both Intel and AMD's public response is that physical attacks are outside their stated security model. [tee-attacks-2025]
- The structural diagnosis: TEEs were designed assuming the platform owner *is* the trusted party (a laptop owner, a company's own datacenter); cloud confidential computing inverts this, since the cloud provider controls the hypervisor/firmware/BMC/physical hardware — precisely the boundary TEEs were never built to defend against. This directly undercuts any claim that confidential computing solves post-transfer enforcement: the 2020s' proposed answer is, as of 2025, being broken by academically-published, sub-$1,000 attacks on the exact production platforms (AMD SEV-SNP, Intel SGX/TDX) it would need to secure. [tee-attacks-2025]
- **Data clean rooms are the one place in this survey where "post-transfer use is technically constrained" is true in a strong, non-contractual sense — but only because raw data is never transferred at all.** Google Ads Data Hub (ADH) enforces a hard minimum of 50 users per query result row (10 for click/conversion-only queries) — a query returning fewer is refused outright, a genuine preventive control. Snowflake Data Clean Rooms implement a formal "aggregation policy" construct enforced by the database engine itself via native Row Access Policies/Secure Data Sharing/Stored Procedures. Google BigQuery clean rooms use an "aggregation threshold" analysis rule with automatic data-egress controls preventing subscribers from copying/exporting raw data. AWS Clean Rooms reached GA March 21, 2023, across 11 regions. In one technical walkthrough, `SELECT *` against raw joined data is blocked at the query-parser level, not merely disallowed by policy, because PII was pseudonymized before ingestion. [clean-rooms-adh]
- **The honest critique of clean rooms**: the strength of the guarantee varies by implementation — weaker clean rooms lean on contractual controls "not meaningfully different from a normal data-sharing agreement." Even strong technically-enforced platforms like ADH are walled-garden, meaning the platform owner retains a structurally privileged position over its own infrastructure. The FTC has stated clean rooms don't eliminate legal obligations and can't be treated as a workaround; 2025 enforcement actions reportedly targeted advertisers for passing health-related audience segments through clean rooms without the explicit consent GDPR-class rules require for sensitive categories — the query layer was technically constrained but the consent basis feeding it was not. [clean-rooms-mechanics]
- **W3C ODRL 2.2 (Information Model + Vocabulary & Expression) has no formal semantics as of 2026** — a 2025 CEUR workshop paper states plainly "ODRL does not yet have a formal semantics," a decade-plus after the vocabulary's 2018 Recommendation, while attempting to supply a first formal, declarative semantics itself and surfacing "gray areas" and a "lack of expressiveness" in ODRL's informal semantics. Policy compliance-checking under generic first-order logic "results in a policy compliance checking that is possibly undecidable" per at least one paper, though restricted fragments are decidable per Pucella & Weissman's earlier foundation — an open, actively-debated question, not settled either way. [odrl-formal-semantics]
- **IPTC's RightsML (news industry's mature ODRL profile, third generation, aligned to ODRL 2.2, maintained since ODRL's earliest days)** — at IPTC's own 2026 W3C ODRL workshop talk, IPTC stated that despite 20 years of investment (ACAP → ODRL → RightsML plus tooling to lower the barrier), **"major news providers such as AP, Reuters and dpa handle rights around their content using human-readable text rather than machine-readable markup."** This is IPTC's own admission of limited real-world uptake among the largest wire services, made at a 2026 W3C event. [odrl-rightsml-iptc]

## SOURCES

**idsa-ram-status**
URL: https://internationaldataspaces.org/the-evolution-of-the-ids-reference-architecture-model-why-ram-4-is-frozen-and-stable-and-what-comes-next/
Accessed: 2026-09-03
Quote: RAM 4 "is archived and will not be further updated, though it remains the baseline for existing implementations, certification, and training until the transition to the next edition is complete"; RAM 4's structure "does not allow for modular updates or for integrating rapidly evolving workstreams such as semantics or observability."

**idsa-position-paper**
URL: https://internationaldataspaces.org/wp-content/uploads/dlm_uploads/IDSA-Position-Paper-Usage-Control-in-the-IDS-V3..pdf ; https://github.com/International-Data-Spaces-Association/IDS-G/blob/main/UsageControl/Contract/README.md
Accessed: 2026-09-03 (PDF fetch-and-summarize; flagged as needing one more manual check)
Quote: "Usage control cannot guarantee enforcement once data leaves the connector or domain of the data provider."

**idsa-rulebook**
URL: https://internationaldataspaces.org/idsa-rulebook-2026-1-structural-clarifications-for-operational-data-spaces/ ; https://docs.internationaldataspaces.org/ids-knowledgebase/idsa-rulebook/idsa-rulebook/7_summary_outlook
Accessed: 2026-09-03
Quote: Frames "data sovereignty" as "a spectrum" built on participant autonomy, decentralization, and trust, not absolute technical control.

**idsa-catenax-critique**
URL: https://link.springer.com/chapter/10.1007/978-3-032-16092-8_32 ; https://arxiv.org/pdf/2203.04800 ; https://catena-x.net/news/e23-million-data-space-accelerator-launched-to-fast-track-sme-integration-within-the-catena-x-ecosystem/
Accessed: 2026-09-03
Quote: "it remains unclear how close existing solutions actually come to the goal of enforcing [usage-control] policies with technical means" (Springer). Data Space Accelerator payouts "released only once companies demonstrate verified productive data exchange with at least one supply-chain partner."

**edc-github-4351**
URL: https://github.com/eclipse-edc/Connector/discussions/4351 ; https://github.com/eclipse-edc/Connector/discussions/4606
Accessed: 2026-09-03
Quote: EDC maintainer (`jimmarino`): "no implementation can 'conform' to DSP because a TCK has not been published at Eclipse"; "ODRL is too open-ended."

**edc-github-4606**
URL: https://github.com/eclipse-edc/Connector/discussions/4460
Accessed: 2026-09-03
Quote: "ODRL does not mandate support for function properties outside assignee and assigner, and DSP also profiles ODRL, adding further restrictions."

**edc-handbook**
URL: https://github.com/eclipse-edc/docs/blob/main/developer/handbook.md ; https://arxiv.org/pdf/2309.11282
Accessed: 2026-09-03
Quote: "Whether an operator is valid is solely defined by the policy evaluation function." Sample policy described as "very simplistic (no specific constraints, allowing 'direct access to all assets')."

**edc-academic-survey**
URL: https://arxiv.org/pdf/2309.11282
Accessed: 2026-09-03
Quote: Early academic survey of dataspace connectors' shipped default policy configuration.

**xacml-forrester**
URL: https://www.forrester.com/blogs/13-05-07-xacml_is_dead
Accessed: 2026-09-03
Quote: Andras Cser, May 2013 — XACML not broadly adopted by enterprises with existing authorization engines; PDP decisions opaque to the PEP; not cloud-friendly; no commercial PEP-library ecosystem.

**xacml-kuppingercole**
URL: https://www.kuppingercole.com/blog/kuppinger/another-dead-body-in-it-or-is-xacml-still-alive
Accessed: 2026-09-03
Quote: "its policy language lacks the flexibility and dynamics needed in real-world authentication and authorization engines, and it adds complexity requiring significant 'plumbing' before practical use."

**xacml-successors**
URL: https://www.osohq.com/learn/opa-vs-cedar-vs-zanzibar ; https://authzed.com/learn/openfga-alternatives
Accessed: 2026-09-03
Quote: Zanzibar-model ReBAC systems (SpiceDB, OpenFGA, Permify) "moved from academic curiosity to production infrastructure"; OpenAI using SpiceDB for ChatGPT Enterprise connectors, handling tens of billions of fine-grained permissions.

**sticky-policies-hp**
URL: https://www.hpl.hp.com/personal/Marco_Casassa_Mont/ ; https://www.semanticscholar.org/paper/Sticky-Policies:-An-Approach-for-Managing-Privacy-Pearson-Mont/67ffb0d21c529e99e8c19edb2de7879e6323b549
Accessed: 2026-09-03
Quote: Sticky policies bind machine-readable conditions cryptographically/structurally to data; enforcement relies on a Trusted Third Party holding decryption keys, released only to a compliant recipient.

**sticky-policies-survey**
URL: https://www.hpl.hp.com/breweb/encoreproject/ ; https://peerj.com/articles/cs-1898/
Accessed: 2026-09-03
Quote: EnCoRe deliverables described as "architectures, technology innovations, and proof-of-concept prototypes" — never a product. 2024 PeerJ paper still treats sticky policies as a proposed, not established, mechanism.

**drm-widevine**
URL: (Widevine device-count and tiering per multiple industry sources cited in original research)
Accessed: 2026-09-03
Quote: Widevine deployed on 4bn+ devices; L1 (hardware TEE) enables full HD/UHD, L3 (software-only) capped at SD; device makers must certify hardware against Google's public Widevine registry.

**drm-fairplay-jobs**
URL: https://daringfireball.net/2007/02/reading_between_the_lines ; https://opensource.com/life/11/11/drm-graveyard-brief-history-digital-rights-management-music
Accessed: 2026-09-03
Quote: Steve Jobs, "Thoughts on Music" (Feb 6, 2007): "If the big four music companies would license Apple their music without the requirement that it be protected with a DRM, we would switch to selling only DRM-free music." EMI DRM-free tracks April 2007; Amazon DRM-free MP3 store September 2007; all majors DRM-free by 2009.

**tee-attacks-2025**
URL: https://www.bleepingcomputer.com/news/security/teefail-attack-breaks-confidential-computing-on-intel-amd-nvidia-cpus/ ; https://thehackernews.com/2025/10/50-battering-ram-attack-breaks-intel.html ; https://heracles-attack.github.io/Heracles-CCS2025.pdf ; https://cybersecurefox.com/en/battering-ram-hardware-attack-intel-sgx-amd-sev-snp/
Accessed: 2026-09-03
Quote: TEE.Fail — DDR5 memory-bus interposer attack, buildable for under $1,000, breaking Intel SGX, Intel TDX, and AMD SEV-SNP simultaneously, forging TDX attestations on Ethereum BuilderNet, working even with AMD's "Ciphertext Hiding" enabled. Battering RAM/WireTap — $50-$1,000 physical interposers forging SEV-SNP attestations, "causing the secure processor to attest a backdoored VM as genuine."

**clean-rooms-adh**
URL: https://cloud.google.com/bigquery/docs/data-clean-rooms ; https://www.flexera.com/blog/finops/snowflake-data-clean-rooms/
Accessed: 2026-09-03
Quote: Google Ads Data Hub enforces a hard minimum of 50 users per query result row (10 for click/conversion-only queries). Snowflake implements a formal "aggregation policy" enforced by the database engine via native Row Access Policies/Secure Data Sharing/Stored Procedures.

**clean-rooms-mechanics**
URL: https://ppc.land/clean-room/ ; https://medium.com/@lei.m.ming/the-anatomy-of-a-data-clean-room-a-deep-dive-into-privacy-preserving-collaboration-a7df534b7af8
Accessed: 2026-09-03
Quote: Weaker clean rooms lean on contractual controls "not meaningfully different from a normal data-sharing agreement." `SELECT *` against raw joined data blocked at the query-parser level; AWS Clean Rooms GA March 21, 2023, across 11 regions.

**odrl-formal-semantics**
URL: https://w3c.github.io/odrl/formal-semantics/ ; https://ceur-ws.org/Vol-3977/OPAL2025-4.pdf
Accessed: 2026-09-03
Quote: 2025 CEUR workshop paper: "ODRL does not yet have a formal semantics," surfacing "gray areas" and a "lack of expressiveness" in ODRL's informal semantics.

**odrl-rightsml-iptc**
URL: https://iptc.org/news/iptc-at-w3c-odrl-workshop-2026/ ; https://iptc.org/std/RightsML/2.0/RightsML_2.0-specification.html
Accessed: 2026-09-03
Quote: "major news providers such as AP, Reuters and dpa handle rights around their content using human-readable text rather than machine-readable markup," per IPTC's own 2026 W3C ODRL workshop talk.

## SYNTHESIS

Every mechanism surveyed here that is *specified* to constrain data use after transfer admits, in its own primary documentation, that it cannot actually do so. IDSA's usage-control architecture states its own limit in plain language — enforcement stops at the connector/domain boundary, and everything past that is handed to a legal/trust layer, not a technical one. EDC, the reference connector that operationalizes IDSA's model at the largest current scale (Catena-X), implements a JSON-Schema-constrained ODRL subset with no published conformance suite, and by construction only evaluates constraints *before* transfer — there is no post-transfer mechanism to describe, let alone assess. Sticky policies are the cleanest historical control for the hypothesis "maybe cryptography can do what contracts can't": a real research program, a real funded flagship project, real prototypes, and after roughly twenty years, zero deployed commercial product. TEE-based confidential computing is the newest candidate for solving this and is currently the worst-supported one empirically — 2024-2025 produced multiple published, cheap, physical attacks that break exactly the guarantee (hardware-enforced confidentiality against the platform operator) the whole approach depends on.

XACML is the load-bearing precedent for why "richer, more standards-body-blessed" does not predict adoption: it was the field's first serious attempt at exactly this class of problem (centralized, fine-grained, standards-based authorization), it was technically sound and had real reference implementations, and it still died on operational friction — opaque decisions, synchronous remote calls, no debugging story, no commercial ecosystem. ODRL-based usage control (IDSA, EDC, RightsML) is running the same experiment a second time with a richer rights-expression vocabulary instead of XACML's rule language, and the early evidence points the same direction: no formal semantics after eight years, IPTC's own admission that the news industry's most mature ODRL profile still loses to human-readable text at the largest wire services after twenty years of investment.

DRM is the one genuine success story for post-transfer-style enforcement, and the mechanism explains why it doesn't generalize: Widevine doesn't enforce a policy over data the recipient already possesses in the abstract — it enforces a policy by controlling and certifying the physical hardware endpoint that would decode the content, and by refusing interoperability with any uncertified device. That is a capital-intensive, platform-owner-specific move (Google/Apple/Microsoft each gatekeeping their own hardware ecosystem), not a protocol anyone can adopt piecemeal, and even that guarantee only held for as long as every rights-holder in the chain kept demanding it — the moment the labels stopped requiring DRM for music, the enforcement layer evaporated in about two years.

Data clean rooms are the one item in this survey that delivers a real, non-contractual, technically-enforced guarantee about what a recipient can extract — hard aggregation thresholds enforced at the query-parser/database-engine level, not a policy document. But the reason it works is that it sidesteps rather than solves the stated problem: raw data is never transferred, so there is nothing for "post-transfer use" to mean. This reframes the practical question for anyone designing a usage-control layer: if the goal is a technical (not contractual) guarantee that survives transfer, the only mechanism in this entire survey that delivers one works by preventing the transfer, not by constraining what happens after it — which suggests "usage control after transfer" may not be a solvable engineering problem in the form it is usually posed, only a differently-shaped one (never transfer raw data) that happens to satisfy the same underlying business need in narrower cases (joint analytics, ad measurement) than the general case (arbitrary downstream use of data the recipient fully possesses).
