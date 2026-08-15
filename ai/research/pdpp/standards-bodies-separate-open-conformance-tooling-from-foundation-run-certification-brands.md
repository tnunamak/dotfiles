---
title: "Standards ecosystems consistently separate open conformance tooling (public good) from foundation-run certification (brand/legal), and implementers layer their own harnesses on top of both"
date: 2026-08-14
topic: pdpp
tags: [conformance, certification, standards-bodies, test-harness, openid, kubernetes, fhir, matter, wpt, governance]
status: draft
sources: [oidf-conformance-suite, oidf-self-cert-faq, oidf-submit-cert, oidf-third-party-policy, oidf-fapi-testing, oidf-cert-fee-update, cncf-conformance-page, cncf-k8s-conformance-wg, cncf-k8s-conformance-instructions, cncf-conformance-tests-md, sonobuoy-faq, cncf-blog-2017-cert, wpt-bocoup-history, wpt-readme, wpt-interop-proposal-guide, wpt-interop-repo, chromium-wpt-docs, webkit-wpt-docs, mozilla-wpt-sync, inferno-about, onc-inferno-blog, inferno-g10-testkit, healthit-buzz-touchstone-atm, aegis-touchstone, uscore-general-requirements, csa-notice, csa-why-certify, csa-test-harness-repo, khronos-adopters-trademark, khronos-cts-opensource, usb-if-compliance-tools]
source_session: unknown
---

## CLAIMS

### Ownership split: who maintains the test tooling vs. who grants certification

- The OpenID Foundation runs an open-source conformance test suite ("an open source project run by the OpenID Foundation... available for all to utilize at any time") and is separately the body that grants the "OpenID Certified" mark via a self-certification process where implementers submit results for OIDF review and publication. [oidf-conformance-suite] [oidf-self-cert-faq]
- The original OIDC conformance test software was written by an individual contributor (Roland Hedberg) starting ~2013, funded/organized labor described by OIDF's Mike Jones as "at least a man-year of work" across test software, profiles, and the legal framework; it is now a Foundation-run, multi-contributor project. [oidf-conformance-suite]
- Implementers self-certify by running the suite, exporting results, and signing a Declaration/Certification of Conformance (via DocuSign) plus paying a fee; OIDF explicitly disclaims any special relationship with third-party consultants who assist with certification. [oidf-submit-cert] [oidf-third-party-policy]
- The Kubernetes e2e conformance test suite is defined and owned inside the Kubernetes project itself, governed by SIG Architecture ("a subset of e2e tests that SIG Architecture has approved to define the core set of interoperable features that all conformant Kubernetes clusters must support"), while Sonobuoy — the tool that runs the suite — originated as a Heptio project and is now maintained by VMware under the `vmware-tanzu` GitHub org. [cncf-conformance-tests-md] [sonobuoy-faq]
- CNCF (not the Kubernetes project, not SIG Architecture) grants the "Certified Kubernetes" mark, and a separate CNCF Kubernetes Software Conformance Working Group — organizationally under CNCF, not a Kubernetes SIG — owns the certification process, collaborating with SIG Architecture (definition) and SIG Testing (mechanics). Certification requires a signed participation form referencing "Certified Kubernetes Terms" and grants a trademark license to use the "Certified Kubernetes" logo. [cncf-conformance-page] [cncf-k8s-conformance-wg] [cncf-k8s-conformance-instructions]
- web-platform-tests (WPT) is explicitly not W3C-run: it was deliberately spun out of the W3C HTML Working Group into an independent GitHub org with "no governance set up initially, just an IP-neutral contributors license agreement," and today "functions as an informal and independent project with no single company backing the project, and no contract in place between the participating companies... no governing Corporation, as is the case for the W3C." [wpt-bocoup-history]
- WPT has **no certification layer at all** — no "conformant browser" mark exists; wpt.fyi is a comparative results archive, not a pass/fail gate, and no threshold makes a browser "certified." This is a confirmed absence (checked against the WPT README and web-platform-tests.org docs), not merely an unmentioned feature. [wpt-readme] [wpt-bocoup-history]
- Inferno (HL7 FHIR testing) was built by MITRE under an ONC/ASTP government contract as public-good, open-source (Apache 2.0) tooling: "MITRE began developing Inferno in 2018 as an open-source testing framework to support the ONC Health IT Certification Program," and ONC's own blog confirms it "partnered with MITRE to develop the Inferno suite." [inferno-about] [onc-inferno-blog]
- Actual FHIR `(g)(10)` certification decisions are made by independent, federally accredited ONC-Authorized Certification Bodies (ONC-ACBs) using ONC-Authorized Testing Labs (ONC-ATLs) — not by MITRE or ONC directly issuing pass/fail. [inferno-g10-testkit]
- Touchstone (AEGIS.net) is a commercial, proprietary testing platform ("Touchstone has evolved from a research project into a full commercial product... a pricing model reflecting a production-hardened, full-featured enterprise-class product") used for HL7 FHIR Connectathons since 2015 and general implementation-guide conformance testing. [aegis-touchstone]
- Matter's SDK (`connectedhomeip`) is Apache-2.0 open source and usable by anyone including non-members ("The Matter SDK is an open source implementation of the Matter Specification"), but the Connectivity Standards Alliance (CSA) restricts certification and trademark use to members: "Certification by the Alliance of any device, software, product or service is limited to members of the Alliance," and "Only the Alliance and its members may use Alliance trademarks and logos, including... the Matter trademarks and logos." [csa-notice]
- CSA-run certification requires testing at a CSA Authorized Test Provider: "All new product certifications require product testing at a Connectivity Standards Alliance Authorized Test Provider." [csa-why-certify]
- Khronos places its conformance test suites (e.g. Vulkan CTS, OpenGL/OpenGL ES CTS) fully in open source, usable by anyone, while running a separate Adopters Program that gates use of the API name/logo: "All implementations of the Vulkan API must be tested for conformance in the Khronos Vulkan Adopter Program before the Vulkan name or logo may be used in association with an implementation of the API." Becoming an Adopter is independent of Khronos membership. [khronos-cts-opensource] [khronos-adopters-trademark]
- USB-IF provides free compliance test tooling (Command Verifier / USB30CV / USB4CV) downloadable from usb.org, while "Certified USB" logo use is a separate licensing step gated by USB-IF as the trademark-owning nonprofit trade association. [usb-if-compliance-tools]

### How suites stay implementation-neutral

- WPT's neutrality mechanism is open, cross-vendor contribution plus a shared, project-run scoreboard (wpt.fyi) that no single vendor controls; the Interop project layers a formal, consensus-gated prioritization process on top — a proposed focus area must be "covered by web-platform-tests" with tests "fully automated and included in Chrome, Edge, Firefox and Safari desktop runs on wpt.fyi" before it can be adopted as a scored focus area. [wpt-interop-proposal-guide]
- No formal, documented multi-vendor-mandatory-review policy for ordinary WPT pull requests was found; neutrality appears to rely on open review norms and each vendor's own import/export review loop rather than a WPT-side reviewer quota. [wpt-bocoup-history] — **unverified/gap**, not a confirmed governance mechanism.
- Kubernetes conformance neutrality is enforced by excluding provider-specific behavior from the test definition (no `SkipIfProviderIs`, tests must "limit itself to capabilities exposed via APIs") and by requiring a 100%-pass, zero-skip run using Sonobuoy's dedicated `--mode=certified-conformance` mode for any certification submission. [cncf-conformance-tests-md] [sonobuoy-faq]
- OpenID's suite is continuously regression-tested against multiple vendor-provided cloud environments ("regression tested against various vendor-provided cloud environments at least once every 24 hours"), and the original FAPI conformance code came from a vendor donation (OpenBanking Ltd.) rather than being authored by any one certifying party — though this donation detail is lower-confidence (found once, not re-confirmed on a second fetch). [oidf-conformance-suite]
- HL7 FHIR's implementation-neutrality is structural rather than procedural: HL7 (membership-funded SDO) writes the spec with no enforcement power, ONC (federal regulator) adopts and enforces it via rulemaking, and the two test tools (Inferno, government-funded/open; Touchstone, commercial/third-party) are both downstream of, and independent from, the vendors being tested. [inferno-about] [aegis-touchstone]
- Matter/CSA neutrality relies on independent, CSA-contracted Authorized Test Labs performing the actual conformance run and reporting results to CSA, separating the party that built the product from the party that tests it. [csa-why-certify]

### Conformance levels / profiles

- OpenID Connect certification is organized into discrete per-spec profiles rather than a graded ladder: OP profiles (Basic, Implicit, Hybrid, Config, Dynamic, Form Post, 3rd-Party-Init), separate RP profiles, and FAPI has two generations (FAPI 1.0 Advanced-Final; FAPI 2.0 Security Profile Final + Message Signing Final) plus jurisdiction-specific derivative profiles (UK Open Banking, Australia CDR, Brazil FAPI-BR, Saudi KSA-OB). New specs run a members-only "pilot" phase before general self-certification availability. [oidf-fapi-testing]
- Kubernetes has one certification bar ("Certified Kubernetes"), but submissions are classified by product type (Distribution, Hosted platform, Installer) via `PRODUCT.yaml` metadata, and certification is versioned per Kubernetes minor release, with only the current release plus two prior versions supported for certification. [cncf-k8s-conformance-instructions]
- WPT itself has no profile/conformance-level concept — it's organized by specification (each top-level directory maps to a W3C spec shortname) with multiple test *types* (testharness.js, reftest, crashtest, wdspec, visual, manual) coexisting per directory, and aggregation happens only informally via dashboards. The Interop project adds a percentage score (tests passing across all major engines) over a curated subset of WPT tests as its one form of graded measurement — but that is an Interop-layer construct, not a WPT/W3C conformance level. [wpt-interop-proposal-guide] [wpt-interop-repo]
- FHIR conformance is profile-based via Implementation Guides, not monolithic: servers declare conformance to a specific IG version in `CapabilityStatement.instantiates`, and profile-level support is declared via `CapabilityStatement.rest.resource.supportedProfile`, with a "must support" rule requiring population of all mandatory and must-support elements defined by that profile's StructureDefinition. Inferno/Touchstone test kits target one or more specific IGs (e.g., US Core, International Patient Summary), not "FHIR" generically. [uscore-general-requirements] [inferno-g10-testkit]
- Matter certification test-plan selection is PICS-driven: a Device Type determines applicable clusters, each cluster has a PICS template describing supported attributes/commands/features, and top-level PICS codes gate whether an entire cluster's test case runs at all, with step-level PICS gating individual test steps. [csa-test-harness-repo]

### Implementer harnesses vs. the official suite

- The Matter ecosystem shows the clearest two-stage pattern: CSA publishes a free, open Test Harness tool (github.com/project-chip/certification-tool) plus the open-source `chip-tool` CLI, and manufacturers self-test with these during development before paying for a one-shot Authorized Test Lab run — documented as standard vendor practice (Espressif, Silicon Labs) though not found to be formally *mandated* by CSA in any primary source. [csa-test-harness-repo]
- For OpenID Connect, no documented case was found of any named implementer (Keycloak, Auth0, Google, Okta) running a distinct internal harness that is separately validated against the official suite before self-certifying; the pattern found instead is implementers running the official hosted suite directly against test builds prior to formal certification submission. This is flagged explicitly as an unconfirmed absence, not a confirmed non-existence. [oidf-conformance-suite]
- For Kubernetes, no independently verified detail was found on vendor-specific internal test suites (OpenShift, EKS, GKE, AKS) beyond the shared, public conformance-evidence submission mechanism (a GitHub PR to `cncf/k8s-conformance` containing e2e.log, junit_01.xml, and PRODUCT.yaml). [cncf-k8s-conformance-instructions]
- For FHIR, no public evidence was found of a distinct internal Epic/Oracle Health certification harness separate from Inferno/Touchstone; publicly documented tooling is limited to vendor developer sandboxes (Open Epic, Oracle Health/Cerner Code console) used alongside the standard test kits. [inferno-g10-testkit] — flagged as a genuine research gap, not a confirmed absence.
- Browser engines maintain large internal-only test suites alongside WPT, with varying sync direction: Chromium runs true two-way sync (a `wpt-import` script pulls upstream; local changes auto-export as upstream PRs via a bot, capped at "CLs that change over 1000 files will not be exported"); WebKit vendors WPT and treats it as more one-directional (fixes should land upstream first, then be re-imported, per an explicit contributor rule); Gecko/Firefox runs genuine two-way sync via a dedicated `wpt-sync` tool that converts local changes into upstream PRs automatically. All three keep separate, large engine-specific suites (Chromium's `web_tests`, WebKit's native LayoutTests, Firefox's mochitests/reftests) for implementation-detail testing outside the shared conformance corpus. [chromium-wpt-docs] [webkit-wpt-docs] [mozilla-wpt-sync]

### Funding and maintenance models

- OpenID's conformance suite is free to use for testing; a fee applies only for official certification submission. OIDF's overall funding is reported as roughly one-third membership dues, one-third certification fees, one-third directed funding projects (medium-confidence paraphrase of OIDF's own funding page). The certification program itself was historically loss-making and cross-subsidized by the Foundation, "exceeding 70% in 2020," prompting a 2021 fee increase; current fees are $700/member vs. $3,500/non-member per new OIDC deployment, and $1,000/member vs. $5,000/non-member for FAPI. [oidf-conformance-suite] [oidf-cert-fee-update]
- Kubernetes/Sonobuoy tooling and the e2e conformance suite are free open-source software with no charge to run; CNCF charges only at the certification/branding step, and that fee is tiered — free for CNCF members and non-profits, with commercial non-members paying a fee comparable to CNCF membership itself. [cncf-blog-2017-cert]
- WPT's founding infrastructure investment came from a single vendor funding a third party to build shared tooling: "Rick Byers from Google liked the idea of an interoperability metric and funded Bocoup to operationalize the regular execution of tests and publication of results, which later drove wpt.fyi." Historical hosting mixed Google Cloud Platform, AWS, and Heroku, with a mix of Bocoup consultancy staff and Google employees as documented contacts — current (2026) hosting/funding specifics were not independently confirmed. [wpt-bocoup-history]
- Inferno's funding is a direct government contract (ONC/ASTP funds MITRE to build and maintain it as public-good, Apache-2.0 software); Touchstone's funding is commercial SaaS revenue (AEGIS.net); HL7 itself is funded by membership dues (reported ~1,600 members, 500+ corporate) and has separately advocated for government funding support given federal reliance on FHIR. [inferno-about] [aegis-touchstone]
- Matter's SDK is developed collaboratively by Alliance member engineers as open-source software; certification/Authorized-Test-Lab fees plus membership dues are CSA's commercial mechanism, structurally separate from the free SDK and free Test Harness tooling — though no primary CSA source was found stating this split as an explicit funding policy (it is inferred from the observed structure, not a quoted disclosure). [csa-notice] [csa-test-harness-repo]

### An important complication: tooling and certification aren't always cleanly separated

- HL7 FHIR breaks the clean "one public-good tool, one certifying brand" pattern: Touchstone is not just HL7's voluntary Connectathon tool, it is *also* a second ONC-approved regulatory pathway to the exact same `§170.315(g)(10)` legal certification that Inferno gates, via Drummond Group packaging Touchstone as "Drummond G10 FHIR API+ powered by Touchstone." ONC's own announcement frames this as giving developers a choice "between two options: (1) Drummond G10 FHIR API+ powered by Touchstone or (2) certification using the Inferno test tool." So the FHIR case is two *competing* accredited test tools feeding the same regulatory gate — one government-funded/open, one commercial/proprietary — not a single public-good tool feeding a single certifying foundation. [healthit-buzz-touchstone-atm]
- FHIR/ONC certification is also categorically different from every other case studied here: it is a *regulatory* requirement with real legal/financial consequences (ineligibility for CMS incentive programs, information-blocking penalties), not a *voluntary* brand mark. OpenID, CNCF, Matter/CSA, and Khronos certifications are all optional trust signals with no legal force — a vendor can ship an uncertified product with no penalty beyond losing the marketing mark. [inferno-g10-testkit]

## SOURCES

**oidf-conformance-suite**
URL: https://openid.net/certification/about-conformance-suite/
Accessed: 2026-08-14
Quote: "The conformance suite is an open source project run by the OpenID Foundation... available for all to utilize at any time."

**oidf-self-cert-faq**
URL: https://openid.net/what-is-self-certification-faq/
Accessed: 2026-08-14
Quote: "The Self-Certification process allows implementers to use the OpenID Foundation's conformance tests to follow a self-certification process, and once complete, certified implementations can use the 'OpenID Certified' certification mark."

**oidf-submit-cert**
URL: https://openid.net/how-to-submit-your-certification-request/
Accessed: 2026-08-14

**oidf-third-party-policy**
URL: https://openid.net/certification/third-party-support-certification-policy/
Accessed: 2026-08-14
Quote: "Any such contract relationship is solely between you and the contractor and does not involve the OpenID Foundation, nor does it grant you any special status with respect to your need to meet the objective certification program criteria."

**oidf-fapi-testing**
URL: https://openid.net/certification/certification-fapi_op_testing/
Accessed: 2026-08-14

**oidf-cert-fee-update**
URL: https://openid.net/openid-foundation-certification-program-update-program-expansion-and-fees-increases/
Accessed: 2026-08-14
Quote: "The OpenID Foundation continued to heavily subsidize the certification program, exceeding 70% in 2020."

**cncf-conformance-page**
URL: https://www.cncf.io/training/certification/software-conformance/
Accessed: 2026-08-14
Quote: "CNCF runs the Certified Kubernetes Conformance Program."

**cncf-k8s-conformance-wg**
URL: https://github.com/cncf/k8s-conformance/blob/master/README-WG.md
Accessed: 2026-08-14

**cncf-k8s-conformance-instructions**
URL: https://github.com/cncf/k8s-conformance/blob/master/instructions.md
Accessed: 2026-08-14

**cncf-conformance-tests-md**
URL: https://github.com/kubernetes/community/blob/main/contributors/devel/sig-architecture/conformance-tests.md
Accessed: 2026-08-14
Quote: "The Kubernetes Conformance test suite is a subset of e2e tests that SIG Architecture has approved to define the core set of interoperable features that all conformant Kubernetes clusters must support."

**sonobuoy-faq**
URL: https://sonobuoy.io/docs/v0.56.6/faq/
Accessed: 2026-08-14
Quote: "A valid certification run may not skip any conformance tests."

**cncf-blog-2017-cert**
URL: https://www.cncf.io/blog/2017/10/20/introducing-software-certification-kubernetes/
Accessed: 2026-08-14

**wpt-bocoup-history**
URL: https://www.bocoup.com/blog/wpt-an-overview-and-history
Accessed: 2026-08-14
Quote: "WPT functions as an informal and independent project with no single company backing the project, and no contract in place between the participating companies... there is no governing Corporation, as is the case for the W3C, or Steering Group Agreement, as is the case for the WHATWG."

**wpt-readme**
URL: https://github.com/web-platform-tests/wpt/blob/master/README.md
Accessed: 2026-08-14

**wpt-interop-proposal-guide**
URL: https://github.com/web-platform-tests/interop/blob/main/proposal_guide.md
Accessed: 2026-08-14
Quote: "to be accepted, the proposed feature must be covered by web-platform-tests... tests must be fully automated and included in Chrome, Edge, Firefox and Safari desktop runs on wpt.fyi."

**wpt-interop-repo**
URL: https://github.com/web-platform-tests/interop
Accessed: 2026-08-14

**chromium-wpt-docs**
URL: https://chromium.googlesource.com/chromium/src/+/HEAD/docs/testing/web_platform_tests.md
Accessed: 2026-08-14
Quote: "CLs that change over 1000 files will not be exported."

**webkit-wpt-docs**
URL: https://docs.webkit.org/Infrastructure/WPTTests.html
Accessed: 2026-08-14
Quote: "Contributors should not modify tests in [the imported path] unless the same test changes are made in Web Platform Tests' primary repository."

**mozilla-wpt-sync**
URL: https://github.com/mozilla/wpt-sync
Accessed: 2026-08-14
Quote: "provides two-way repository sync between web-platform-tests and gecko... runs merged upstream PRs through gecko CI... any changes to this directory are automatically converted into pull requests against the upstream repository, and merged if they pass CI."

**inferno-about**
URL: https://inferno-framework.github.io/about/
Accessed: 2026-08-14
Quote: "MITRE began developing Inferno in 2018 as an open-source testing framework to support the ONC Health IT Certification Program."

**onc-inferno-blog**
URL: https://www.healthit.gov/blog/interoperability/onc-is-fhird-up-unwrapping-the-new-inferno-testing-suite/
Accessed: 2026-08-14
Quote: "ONC has partnered with MITRE to develop the Inferno suite of HL7® FHIR® servers."

**inferno-g10-testkit**
URL: https://inferno.healthit.gov/test-kits/onc-certification-g10/
Accessed: 2026-08-14

**healthit-buzz-touchstone-atm**
URL: https://www.healthit.gov/buzz-blog/healthit-certification/new-testing-method-available-for-standardized-api-criterion
Accessed: 2026-08-14
Quote: "ONC's approval of Drummond's 170.315(g)(10) conformance test suites on the AEGIS.net Touchstone FHIR test tool and developer platform gives health IT developers two options for the ONC certification of the criterion: (1) Drummond G10 FHIR API+ powered by Touchstone or (2) certification using the Inferno test tool."

**aegis-touchstone**
URL: https://www.aegis.net/touchstone/
Accessed: 2026-08-14
Quote: "Touchstone has evolved from a research project into a full commercial product."

**uscore-general-requirements**
URL: https://www.hl7.org/fhir/us/core/general-requirements.html
Accessed: 2026-08-14
Quote: "servers SHALL be able to populate all profile data elements that are mandatory and flagged as Must Support as defined by that profile's StructureDefinition."

**csa-notice**
URL: https://github.com/project-chip/connectedhomeip/blob/master/NOTICE
Accessed: 2026-08-14
Quote: "Only the Alliance and its members may use Alliance trademarks and logos, including... the Matter trademarks and logos."

**csa-why-certify**
URL: https://csa-iot.org/certification/why-certify/
Accessed: 2026-08-14
Quote: "All new product certifications require product testing at a Connectivity Standards Alliance Authorized Test Provider."

**csa-test-harness-repo**
URL: https://github.com/project-chip/certification-tool
Accessed: 2026-08-14

**khronos-adopters-trademark**
URL: https://www.khronos.org/legal/khronos-trademark-guidelines
Accessed: 2026-08-14
Quote: "All implementations of the Vulkan API must be tested for conformance in the Khronos Vulkan Adopter Program before the Vulkan name or logo may be used in association with an implementation of the API."

**khronos-cts-opensource**
URL: https://www.khronos.org/news/press/khronos-open-sources-opengl-and-opengl-es-conformance-tests
Accessed: 2026-08-14

**usb-if-compliance-tools**
URL: https://www.usb.org/compliancetools
Accessed: 2026-08-14

## SYNTHESIS

### The pattern, generalized

Across every ecosystem studied, the same three-layer split recurs, though the legal weight of the top layer varies enormously:

1. **Conformance tooling** (test suite + runner) is public good: open source, free to run, usable by anyone whether or not they intend to certify. Ownership varies — sometimes the standards org itself (OpenID Foundation, HL7's IG tooling), sometimes a separate government-funded body (MITRE/ONC for Inferno), sometimes a corporate donation that became community infrastructure (Sonobuoy from Heptio/VMware, WPT infra seeded by Google-funded Bocoup work), sometimes the open-source reference implementation's own SDK repo (Matter's `connectedhomeip`, Khronos's CTS).
2. **Certification** (the brand/logo/legal mark) is run by a distinct legal entity — a foundation or trade association — that owns the trademark, defines the legal terms of use, and often charges a fee that is explicitly separate from tooling access (OIDF, CNCF, CSA, Khronos, USB-IF all fit this exactly). W3C/WPT is the deliberate counter-example: no certification layer exists at all, and neutrality is achieved entirely through open cross-vendor tooling rather than any brand gate.
3. **Implementation-specific harnesses** sit on both sides of the boundary: browser engines keep large internal suites that WPT supplements rather than replaces; Matter device makers self-test with free CSA tooling before paying for lab certification; FHIR IGs define profile-specific "must support" testing that a generic Inferno/Touchstone run maps onto per-IG, not per-vendor.

### Direct mapping to PDPP's intended layering

This maps closely onto PDPP's plan, with the FHIR case as the important caution:

- **PDPP spec repo as public-good conformance tooling** matches the OpenID (suite run by the standards body, free to use, fee only at certification) and Matter (open SDK + free Test Harness, paid-only at the ATL step) patterns more than the WPT pattern (no certification layer at all). Since PDPP intends the Vana Foundation to run certification, PDPP is choosing the OpenID/CNCF/CSA model, not the WPT model — worth being explicit about that choice, since WPT shows a mature, credible standard can also choose to have *no* certification layer and rely purely on open scoreboards (wpt.fyi-style). If PDPP wants a certification mark, it should look at how OIDF/CNCF/CSA structure the legal separation (trademark ownership, participation agreement, fee schedule) — not treat "spec repo ships conformance tools" as sufficient on its own to reach a defensible brand.
- **Vana Foundation as certifying body, legally distinct from the spec repo** is exactly the OpenID Foundation / CNCF / CSA shape: a foundation-owned trademark, a signed conformance declaration or participation agreement, and (per every example) a fee structure that funds the certification program somewhat independently of the free tooling — OIDF's program has historically run at a loss subsidized by the Foundation, which is a funding-model risk PDPP/Vana Foundation should plan for explicitly rather than assume certification fees will self-fund.
- **Data Connect (the app) and data-connectors (the connector library) keeping their own product testing** matches every implementer-harness pattern found: Chromium/WebKit/Gecko's internal suites alongside WPT, Matter device makers' internal use of the free Test Harness before ATL submission, and (implicitly, since no contrary evidence was found) OIDC/Kubernetes implementers running the official suite directly rather than building a parallel internal conformance harness. The precedent argues Data Connect's and data-connectors' existing test harnesses should stay positioned as *implementation validation*, feeding into but never substituting for whatever conformance suite the PDPP spec repo publishes — and specifically, neither should be the thing Vana Foundation certification runs against, the way CSA certification runs against the CSA-defined PICS/test-plan structure and not against any single vendor's internal harness.
- **The FHIR caution**: HL7's case shows conformance/certification separation can blur when a *regulator* enters the picture — Touchstone became a second accredited path to the same legal gate as Inferno, turning "one public good, one certifier" into "two competing accredited tools." PDPP has no regulator today, but if PDPP conformance ever becomes a legal/procurement requirement (e.g. referenced by a Data Act-style regulation — see the existing `data-act-and-pdpp` entry in this same directory), expect exactly this kind of pressure toward multiple accredited test paths, and plan the Foundation's certification terms to explicitly allow or foreclose that before it's forced by circumstance.
- **Neutrality mechanism to borrow**: the two most credible technical-neutrality mechanisms found are (a) WPT/Interop's rule that a feature must already have fully-automated, cross-engine-passing tests before it counts for anything, and (b) Kubernetes' 100%-pass/zero-skip conformance mode plus explicit exclusion of provider-specific behavior from the test definition. Both are stronger neutrality guarantees than "the foundation reviews it" — PDPP's spec-repo conformance tooling should aim for a similarly mechanical bar (e.g., a Source Declaration is Core-conformant only if it validates independent of any profile extension, per the existing `[[source-declarations-separate-identities-profiles-and-authorization-artifacts]]` entry) rather than relying on Foundation judgment calls at certification time.
