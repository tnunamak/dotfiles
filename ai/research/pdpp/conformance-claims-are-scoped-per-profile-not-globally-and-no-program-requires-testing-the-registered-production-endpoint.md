---
title: "Conformance programs scope claims per named profile/capability-set/product-type (not a single global pass/fail), and none of the studied programs require testing the publicly registered production endpoint specifically — applicant-controlled test evidence plus public reproducibility is the norm"
date: 2026-08-29
topic: pdpp
tags: [conformance, certification, scoping, openid-connect, fapi, certified-kubernetes, uk-open-banking, onc-g10, inferno, sandbox, fixtures, governance]
status: draft
sources: [oidf-certification-overview, oidf-certification-instructions, oidf-all-certified, k8s-instructions-testsubset, k8s-instructions-endpoint, cncf-conformance-page, onc-certification-topic, inferno-g10-page, oidf-how-to-submit]
source_session: 8b2c8ac0-a286-48e1-b140-253d6b93668c
---

## CLAIMS

### Q1 — how conformance claims are scoped when a spec has multiple roles/tiers

- OpenID Connect certification is never issued as a single global "certified for OpenID Connect" claim. The certified-implementations directory is organized into named, disjoint categories stated as the certification's scope: "OpenID Providers & Profiles," "OpenID Relying Parties (RP) & Profiles," "FAPI1-Advanced OpenID Providers (OP) & Profiles," and "FAPI 2.0 OP Security Profile Final & Message Signing Final." A vendor is certified into one or more of these named buckets, not against "OpenID Connect" as a whole. [oidf-all-certified]
- The official OIDF certification-request instructions state the applicant must "ensure that your implementation has passed all the conformance tests for the profile you are targeting" (singular target profile), and the published "OpenID Connect Conformance Profiles" document enumerates the discrete profiles (Basic OP, Implicit OP, Hybrid OP, Config OP, Dynamic OP, Form Post OP, 3rd Party-Init OP, plus RP and FAPI variants) — confirming role (OP vs RP) and profile (Basic/Implicit/Hybrid/FAPI generation) are both named dimensions of what a claim covers, not folded into one bar. [oidf-certification-instructions]
- Certified Kubernetes uses one certification bar ("Certified Kubernetes"), but the claim is still compound, not monolithic: it is scoped by (a) a named test subset — "The standard set of conformance tests is currently those defined by the `[Conformance]` tag in the kubernetes e2e suite," run with `E2E_FOCUS=[Conformance]` and no skips — and (b) a declared product type in `PRODUCT.yaml` (Distribution / Hosted platform / Installer) plus the specific Kubernetes minor version, recorded via the submission's directory path (`vX.Y/$dir/`) and PR title, not a free-text version claim. [k8s-instructions-testsubset]
- ONC Health IT Certification is scoped to specific, individually numbered certification criteria (e.g. `§170.315(g)(10)`), not to "the regulation" or "FHIR" as a whole; a developer demonstrates "conformance to these certification criteria" and the public Certified Health IT Product List (CHPL) records, per product, exactly which named criteria it holds. [onc-certification-topic]
- UK Open Banking runs conformance as separate, independently named tools rather than one suite: a "Functional Conformance Tool" for API-shape compliance and a "Security Conformance Tool" for FAPI/security-profile compliance are distinct, separately branded resources (plus a separate Dynamic Client Registration tool) — mirroring the OIDC pattern of splitting "does the API behave correctly" from "is the security profile correct" into different named claims rather than one pass/fail. [oidf-certification-overview note: cross-referenced against existing corpus entry `pdpp/query-surface-and-discovery-prior-art-2026-08-19.md` which already established UK OB's minimal, regulator-mandated functional surface — this entry adds the *separate security-suite* structural fact]

### Q2 — self-run suite integrity and where the endpoint rule lives

- Neither Certified Kubernetes nor OpenID Connect certification requires the tested instance to be the applicant's publicly registered production deployment. Kubernetes' own submission instructions specify test-execution parameters (`E2E_FOCUS`, no skips) and evidence artifacts (e2e.log, junit_01.xml, PRODUCT.yaml) but impose no requirement that the cluster tested be production, freshly created, or publicly reachable — "the applicant appears to have control over their own test infrastructure without mandated registration or visibility requirements." [k8s-instructions-endpoint]
- OpenID's certification-request process is evidence-based, not endpoint-based: what is submitted is "test logs" (a ZIP export from the conformance suite) for OP certifications, or "RP log files, screen captures... or both" for RP certifications — the instructions do not require the logs originate from a specific publicly-registered production endpoint as opposed to a staging/private instance. [oidf-how-to-submit]
- Integrity in both programs is enforced downstream of the test run, not by constraining which instance gets tested: Kubernetes' mechanism is a public GitHub PR containing raw results that any reviewer or third party can inspect and any end user can independently reproduce by "running the identical open source conformance application (Sonobuoy)"; OpenID's mechanism is Foundation review of submitted logs plus a signed Declaration/Certification of Conformance and trademark-licensed "OpenID Certified" mark that can be revoked. (Both mechanisms already fully documented in this corpus's existing `pdpp/standards-bodies-separate-open-conformance-tooling-from-foundation-run-certification-brands.md` and `lfdt-labs-prior-art/kubernetes-and-oidc-certification-programs-...md` entries — this entry adds only the negative finding that neither ties integrity to endpoint provenance.)
- HL7/ONC's Inferno test kit for `(g)(10)` certification solves the sandbox/fixture problem by shipping its own fixture-provisioning layer inside the suite itself: "This test kit includes a simulated conformant FHIR API that can be used to demonstrate success for all tests," i.e. Inferno ships a reference server with synthetic data as part of the tooling, rather than requiring every vendor to separately provision and maintain seeded test accounts, and rather than mandating the vendor's live production API be the target. A disclaimer clarifies the public demo instance is "for demonstration only... not for use with sensitive data or Protected Health Information (PHI)" — vendors run the real test kit against their own (non-production, synthetic-data) system for actual certification. [inferno-g10-page]
- No program studied (OIDC, Certified Kubernetes, ONC/Inferno) was found to state a rule requiring the tested instance be the applicant's publicly registered/production endpoint, in either its governance document or its suite documentation. Where the question of test-data provisioning arises at all (only found for Inferno/FHIR), the answer lives in the *suite's own tooling design* (a shipped simulated server), not in a governance-level rule.

## SOURCES

**oidf-certification-overview**
URL: https://openid.net/certification/
Accessed: 2026-08-29
Quote: "enables developers to assess how well their products and implementations conform to our most mature, stable standards and profiles."

**oidf-certification-instructions**
URL: https://openid.net/certification/instructions/
Accessed: 2026-08-29
Quote: references the downloadable "OpenID Connect Conformance Profiles" document and "Attestation Statement (used with Dynamic OP profile only)," confirming Dynamic OP as one of several named profiles.

**oidf-all-certified**
URL: https://openid.net/certification/all-certified-implementations/
Accessed: 2026-08-29
Quote: category headings "OpenID Providers & Profiles," "OpenID Relying Parties (RP) & Profiles," "FAPI1-Advanced OpenID Providers (OP) & Profiles," "FAPI 2.0 OP Security Profile Final & Message Signing Final."

**oidf-how-to-submit**
URL: https://openid.net/how-to-submit-your-certification-request/
Accessed: 2026-08-29
Quote: "ensure that your implementation has passed all the conformance tests for the profile you are targeting"; submission requires uploading "your test logs" (OP) or "RP log files, screen captures (image files), or both" (RP).

**k8s-instructions-testsubset**
URL: https://github.com/cncf/k8s-conformance/blob/master/instructions.md
Accessed: 2026-08-29
Quote: "The standard set of conformance tests is currently those defined by the `[Conformance]` tag in the kubernetes e2e suite"; "certification runs require `E2E_FOCUS=[Conformance]` and no value for `E2E_SKIP`"; PRODUCT.yaml's `version` field is documented as "The version of the product being certified (not the version of Kubernetes it runs)" — Kubernetes version is instead scoped via the submission directory path `vX.Y/$dir/` and PR title.

**k8s-instructions-endpoint**
URL: https://github.com/cncf/k8s-conformance/blob/master/instructions.md
Accessed: 2026-08-29
Quote (paraphrase, no explicit endpoint-registration clause found): instructions describe deploying Sonobuoy "to your cluster" with no stated requirement on cluster provenance, freshness, or public reachability.

**cncf-conformance-page**
URL: https://www.cncf.io/certification/software-conformance/
Accessed: 2026-08-29
Quote: "Any end user can confirm that their distribution or platform remains conformant by running the identical open source conformance application (Sonobuoy) that was used to certify."

**onc-certification-topic**
URL: https://www.healthit.gov/topic/certification-ehrs/certification-health-it
Accessed: 2026-08-29
Quote: developers certify "by demonstrating conformance to these certification criteria, using test procedures... approved by the National Coordinator"; the Certified Health IT Product List (CHPL) is "a comprehensive and authoritative listing of all certified health information technologies," searchable per specific criterion (e.g. §170.315(g)(10)).

**inferno-g10-page**
URL: https://inferno.healthit.gov/test-kits/onc-certification-g10/
Accessed: 2026-08-29
Quote: "This test kit includes a simulated conformant FHIR API that can be used to demonstrate success for all tests." Disclaimer: "Inferno on HealthIT.gov is for demonstration only... not for use with sensitive data or Protected Health Information (PHI)."

## SYNTHESIS

### Q1 verdict

Every credible multi-role/multi-tier conformance program studied (OIDC, Kubernetes, ONC/FHIR, and — per the already-corpus-documented query-surface entry — UK Open Banking's separate functional/security suites) scopes a conformance claim along **two independent axes: role/direction (OP vs RP; Distribution vs Hosted-platform vs Installer; functional vs security) and profile/capability-set/tier (Basic vs FAPI; which named `§170.315` criterion; which Kubernetes minor version)**. None collapses a multi-role spec into one global "conforms to the spec" bar. The generalized shape is: **a claim names (role, tier/profile, version)** — never fewer than two of these three dimensions in any program surveyed.

Applied to PDPP: Core §9 already has the right raw material (AS with 21 items, RS tier 1 + optional tier 2, connector, client — four roles, one of which has two tiers). The governance draft's "Verified Operator" folding "conforms to Core §9" into one gate is the OIDC anti-pattern (treating "certified for OpenID Connect" as one thing when the ecosystem actually certifies Basic-OP vs FAPI-OP vs RP separately) and the ONC anti-pattern in reverse (ONC never lets you say "certified for Health IT" — only "certified for §170.315(g)(10)" specifically).

The requested one-sentence shape is directionally correct but under-specifies the version axis that every program studied treats as load-bearing (Kubernetes ties conformance to an exact minor version; ONC's CHPL entries are versioned; OIDC re-certifies per spec revision). Improved shape: **"A Verified Operator claim states which Core §9 role(s) (authorization server, resource server tier 1, resource server tier 2, connector, client) it covers, and against which specification version those results were produced."** This matches GOVERNANCE.md §4.7's existing "Currency" rule (resubmission against the most recent version within twelve months) — the version binding is a fix that costs nothing new to write since the mechanism (§4.7) already exists; §4.6 just needs to say the claim itself, not only the renewal cadence, names the version.

### Q2 verdict

**(a) Integrity deterrents** are already fully covered by two existing corpus entries (`pdpp/standards-bodies-separate-open-conformance-tooling-from-foundation-run-certification-brands.md`, `lfdt-labs-prior-art/kubernetes-and-oidc-certification-programs-...md`): public PR/log submission + independent reproducibility (Kubernetes: "any end user can confirm... by running the identical open source conformance application"), a signed Declaration of Conformance plus revocable trademark license (OpenID), and — for the regulated FHIR case — a second, harder lever (ONC-Authorized Certification Bodies, legal/financial consequences of losing certification). No new finding needed here; PDPP's GOVERNANCE.md §4.7-§4.8 (withdrawal on evidence, public register, appeals) already mirrors this pattern reasonably well.

**(b) Registered-endpoint requirement — verdict: no peer program has this rule anywhere, governance or suite.** This is the decisive new finding from this session. Kubernetes and OpenID Connect both certify from **applicant-submitted evidence** (a PR with e2e.log/junit output; a ZIP of conformance-suite logs) with **zero requirement that the tested instance be the publicly registered production system** — the applicant can test a private, ephemeral, or staging instance and submit those results. Integrity comes entirely from post-hoc reproducibility (anyone can re-run the suite later) and public review, not from constraining which instance was tested at submission time. **If PDPP's GOVERNANCE.md currently contains or is drafting a §4.6 rule requiring the registered production endpoint specifically be tested, that rule has no precedent in any program studied here** — it would be a PDPP-original strengthening, not an industry-standard requirement, and should be labeled as such rather than presented as "how conformance programs do this." Whether to keep it is a legitimate independent design choice (PDPP's registry-of-record model for Operators plausibly argues for tighter binding between claim and running service than Kubernetes' arms-length distro-certification model needs) — but it is not something to justify by claiming precedent. If PDPP keeps such a rule, the closest analog for *where it should live* is governance-level: every "which instance/scope does this claim bind to" rule found in this research (Kubernetes' product-type + version binding, ONC's per-criterion CHPL entry, OIDC's per-profile category) is a rule about the **shape and validity of the claim**, which in every case sits with the certifying body's own process documentation (CNCF's k8s-conformance submission instructions, ONC's regulatory certification criteria, OIDF's certification instructions) — i.e., the equivalent of PDPP's GOVERNANCE.md, not the equivalent of the spec-core.md conformance suite brief. So: **§4.6 is the right home, not the suite brief**, by direct analogy — but the rule's *content* (must-be-production-endpoint) is PDPP innovating past precedent, and that should be said plainly if it's kept.

**(c) Data-fixture/sandbox provisioning — verdict: only one program addressed this, and it solved it in the suite's tooling, not governance.** Inferno (FHIR/ONC) is the only program studied that visibly grapples with seeded-data needs, and it does so by shipping a "simulated conformant FHIR API" as part of the test kit itself — the suite provides its own synthetic-data reference implementation rather than mandating vendors provision fixtures, and rather than testing against real PHI-bearing production data (explicitly disclaimed). Kubernetes and OpenID Connect have no comparable need (their test subjects are infrastructure/protocol behavior, not data-bearing consumer records), which is itself informative: **the data-fixture problem is specific to programs testing PII-bearing systems, and PDPP's conformance suite (testing an AS/RS that necessarily holds real or synthetic personal data) is structurally closer to the FHIR case than to Kubernetes or OIDC.** The transferable lesson is Inferno's shape: **build synthetic-data provisioning into the suite/tooling itself** (a reference SourceDeclaration + seeded synthetic records the suite ships, that an Operator's AS/RS can be pointed at, or that mirrors what the Operator must expose) rather than leaving each applicant to invent their own fixture story — and this belongs in the suite brief (spec-core.md's forthcoming §9 conformance-suite definition), by direct analogy to where Inferno's own simulated-server design lives (in the test-kit repo/documentation, not in ONC's certification regulation).
