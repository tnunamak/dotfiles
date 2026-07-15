---
title: "Consent/identity standards separate verified from self-declared claims in the data model, but almost none mandate how the UI must attribute them"
date: 2026-06-12
topic: oauth-mcp-auth
tags: [consent, attribution, verifiable-credentials, oidc, privacy, prior-art]
status: draft
sources: [kantara-cr, iso-27560, dpv, w3c-vc, oidc-ida, iab-tcf, p3p, barth-mitchell, apple-privacy-labels, dti, cfpb-1033, gnap, eudi-arf, haip, oid4vp]
---

## CLAIMS

- Kantara Consent Receipt (CR v1.0 2017, v1.1 2018) became ISO/IEC TS 27560:2023; it records controller, purposes, PII categories, legal basis, retention, and recipients as a machine-readable artifact, but every field is a claim by the controller about itself with no per-field attribution and no enforcement hook — a receipt, not a gate. [kantara-cr] [iso-27560]
- W3C DPV (1.0 2022, 2.0 late 2024) is a descriptive RDF vocabulary for consent/processing/legal-basis/purpose; it models obligations as concepts but has no type distinguishing "platform-enforced" from "controller-committed" and no normative guidance on UI presentation. [dpv]
- W3C Verifiable Credentials (VC 1.0 2019, 2.0 2025) provide cryptographic per-claim issuer attribution, but only ever applied to claims *about the subject* — no standardized credential type exists for a verifier attesting to its own data-handling (e.g. "we delete in 30 days"). [w3c-vc]
- OpenID Connect for Identity Assurance (final 2023) defines a `verified_claims` container whose explicit goal is that "it is explicit which claims are verified, reducing the risk of RPs accidentally processing unverified claims as verified" — but it is unidirectional (OP asserts about the user) and does not mandate how the RP's consent screen renders the distinction. [oidc-ida]
- IAB Europe TCF (v1.0 2018 → v2.3 2025) is the closest deployed system with per-claim-source attribution at scale (framework-defined purpose text vs vendor-declared purposes), but it does not mandate an attribution UX; the Belgian DPA's 2022 decision (upheld 2023) found vendor self-declarations are unaudited and CMPs collapse the source distinction into dark patterns. [iab-tcf]
- P3P (W3C Rec 2002, obsoleted 2018) was the machine-readable privacy-promise layer; EPAL (IBM 2003) was its intended enforcement counterpart but was never standardized. Barth & Mitchell (WITS '05) formalized an "enforces" relation between an EPAL enforcement policy and a coarser P3P promise. P3P died from no enforcement (Google posted a literal "This is not a P3P policy" string to bypass IE cookie-blocking), no incentives, and complexity. [p3p] [barth-mitchell]
- Apple Privacy Nutrition Labels (2020) render developer-self-declared data-collection claims in a platform-controlled, developer-uncontrollable UI — the one prior art where attribution-split is visible in a mass-market UI — but a 2021 Washington Post investigation found a third of "Data Not Collected" apps were in fact collecting data; Apple's response was future-update rejection, an accountability not a runtime-enforcement mechanism. [apple-privacy-labels]
- Data Transfer Initiative's Data Trust Registry (pilot 2024–25) vets recipients out-of-band (Trust Level 1 = self-attestation; Level 2 = outside audit) rather than via in-band protocol attribution. [dti]
- CFPB Section 1033 (finalized Oct 2024, in legal limbo 2025) requires third parties to certify purpose-limitation/retention/deletion-on-revocation in the authorization disclosure but specifies no machine-readable attribution protocol or mandated consent-UI rendering. [cfpb-1033]
- IETF GNAP (RFC 9635, Oct 2024) models presenting attested vs self-asserted identifiers to the AS but only for authentication, not for data-handling commitments. [gnap]
- The EUDI ARF two-certificate model (RPAC authenticates who the RP is; RPRC specifies what data and for which registered intended use) makes the wallet abort a presentation that exceeds the declared intended use; HAIP 1.0 (2025) mandates the wallet display the trust-list-verified RP name instead of the self-declared `client_name`; OpenID4VP 1.0 adds a `verifier_info` array of third-party attestations but leaves its use "at the discretion of the Wallet." [eudi-arf] [haip] [oid4vp]

## SOURCES

**kantara-cr**
URL: https://kantarainitiative.org/download/7902/ ; https://kantara.atlassian.net/wiki/spaces/archive/pages/3508790/Consent+Receipt+Specification
Accessed: 2026-06-12
Quote: "security, communication, and maintenance of this information is outside the scope of this document."

**iso-27560**
URL: https://www.iso.org/standard/80392.html
Accessed: 2026-06-12

**dpv**
URL: https://w3id.org/dpv/ ; https://w3c.github.io/dpv/ ; https://w3c.github.io/dpv/guides/consent-27560
Accessed: 2026-06-12

**w3c-vc**
URL: https://www.w3.org/TR/vc-data-model-2.0/
Accessed: 2026-06-12

**oidc-ida**
URL: https://openid.net/specs/openid-connect-4-identity-assurance-1_0.html ; https://openid.net/specs/openid-ida-verified-claims-1_0.html
Accessed: 2026-06-12
Quote: "This way, it is explicit which claims are verified, reducing the risk of RPs accidentally processing unverified claims as verified claims."

**iab-tcf**
URL: https://iabeurope.eu/transparency-consent-framework/ ; https://github.com/InteractiveAdvertisingBureau/GDPR-Transparency-and-Consent-Framework
Accessed: 2026-06-12

**p3p**
URL: https://en.wikipedia.org/wiki/P3P ; https://lorrie.cranor.org/blog/2012/12/03/p3p-is-dead-long-live-p3p/
Accessed: 2026-06-12
Quote: "Until we see enforcement actions to back up voluntary privacy standards... users will not be able to rely on them."

**barth-mitchell**
URL: https://theory.stanford.edu/~jcm/papers/barth-mitchell-2005.pdf ; http://www.adambarth.com/papers/2005/barth-mitchell.pdf
Accessed: 2026-06-12

**apple-privacy-labels**
URL: https://developer.apple.com/app-store/app-privacy-details/ ; https://developer.apple.com/documentation/bundleresources/privacy_manifest_files ; https://digitalwatchdog.org/idac-policy-brief-apple-privacy-nutrition-labels/
Accessed: 2026-06-12

**dti**
URL: https://dtinit.org/ ; https://dt-reg.org/about/
Accessed: 2026-06-12

**cfpb-1033**
URL: https://www.consumerfinance.gov/personal-financial-data-rights/
Accessed: 2026-06-12

**gnap**
URL: https://datatracker.ietf.org/doc/rfc9635/
Accessed: 2026-06-12

**eudi-arf**
URL: https://eu-digital-identity-wallet.github.io/eudi-doc-architecture-and-reference-framework/ ; https://bmi.usercontent.opencode.de/eudi-wallet/eidas-2.0-architekturkonzept/content/ecosystem-architecture/trust/wallet-relying-party-authentication/
Accessed: 2026-06-12
Quote: "The EUDI Wallet ensures that RP presentation requests align with their declared intended use... EUDIW fails the process if the request exceeds the declared intended use."

**haip**
URL: https://dzone.com/articles/haip-1-0-securing-verifiable-presentations
Accessed: 2026-06-12

**oid4vp**
URL: https://openid.net/specs/openid-4-verifiable-presentations-1_0.html
Accessed: 2026-06-12
Quote: "a non-empty array of attestations about the Verifier relevant to the Credential Request"

## SYNTHESIS

Across 25 years of standards work the *ingredients* of an attribution split all exist — a dedicated verified-vs-unverified container (OIDC IDA `verified_claims`), cryptographic per-claim issuer attribution (VC), a trust-list name that overrides self-declared client metadata (HAIP), purpose bound to an authorizing certificate with mechanical abort (EUDI RPRC), vendor-attributed purposes at scale (TCF), and a platform-controlled render of developer-declared claims (Apple). What is consistently *absent* is a spec that normatively mandates how the consent surface must render client-authored claims distinctly from platform/protocol-authored ones. Standards bodies repeatedly declared UI presentation out of scope (W3C-CG "presentation is a deployment concern," IETF "UX out of band"), and that gap is the single most-cited cause of failure: the two systems that left rendering to implementers (P3P, TCF) saw the source distinction erode into theater. The durable, reusable lessons: (1) a data-model split without normative UI rendering degrades to dark patterns; (2) self-declaration without audit degrades to inaccuracy (Apple ~1/3 mislabeled); (3) adoption of a new consent layer requires a forcing function — legal mandate (eIDAS 2.0/EUDI) or dominant platform (Apple) — because standards-community "best practice" notes historically do not move implementers; (4) a promise layer needs a defined enforcement counterpart or it is correctly criticized as theater (the P3P/EPAL failure).
