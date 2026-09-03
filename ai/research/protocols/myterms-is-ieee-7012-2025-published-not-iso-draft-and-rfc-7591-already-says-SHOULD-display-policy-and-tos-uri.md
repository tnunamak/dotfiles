---
title: "MyTerms is IEEE 7012-2025 (published Jan 2026, individual = FIRST party), not an ISO draft; and RFC 7591 §2 already says the AS SHOULD display policy_uri/tos_uri — so a spec that says MAY is weaker than the vocabulary it claims to reuse"
date: 2026-09-03
topic: protocols
tags: [myterms, ieee-p7012, rfc-7591, consent, oauth, privacy-terms, customer-commons, dpv, gdpr, prior-art]
status: draft
sources: [rfc7591, ieee-7012-page, dpv-p7012-ext, cc-agreements, cc-p2b1, cc-tm-registry, gdpr-art7, gdpr-rec42, iso29184, kantara-cr-policyurl, edpb-05-2020, oidc-dcr, myterms-info-standards, projectvrm-protocols, github-myterms-odrl]
source_session: 4b217cfe-663c-45f9-bf66-5814f6817317
---

<!--
Produced while answering two PDPP spec questions: (1) does Core need to support
client terms/privacy policy, (2) is PDPP drifting from MyTerms. Both questions
were posed on premises that turned out to be wrong; the corrections are the
durable finding here.
-->

## CLAIMS

- RFC 7591 Section 2 defines `tos_uri` as a "URL string that points to a human-readable terms of service document for the client that describes a contractual relationship between the end-user and the client that the end-user accepts when authorizing the client," and states "The authorization server SHOULD display this URL to the end-user if it is provided." [rfc7591]
- RFC 7591 Section 2 defines `policy_uri` as a "URL string that points to a human-readable privacy policy document that describes how the deployment organization collects, uses, retains, and discloses personal data," and states "The authorization server SHOULD display this URL to the end-user if it is provided." [rfc7591]
- The display keyword in RFC 7591 for both fields is SHOULD, not MAY. A downstream spec that reuses the RFC 7591 vocabulary but writes "the AS MAY display them" is strictly weaker than the source vocabulary — a silent downgrade, not a design choice. [rfc7591]
- RFC 7591 Section 2 says of both fields "The value of this field MUST point to a valid web page" and "The value of this field MAY be internationalized, as described in Section 2.2." Localization is Section 2.2, which says "Human-readable client metadata values and client metadata values that reference human-readable values MAY be represented in multiple languages and scripts" using BCP 47 tags appended to member names after a `#` delimiter. [rfc7591]
- RFC 7591 has NO opinion on recording or retaining the displayed `policy_uri`/`tos_uri` values in any durable consent or grant record. It is a registration-metadata vocabulary; the display sentence is the end of its interest. [rfc7591]
- MyTerms is IEEE P7012, published as **IEEE 7012-2025**, official title "IEEE Standard for Machine Readable Personal Privacy Terms," status Active Standard, published 2026-01-20. It is NOT an ISO standard and is no longer a draft. [ieee-7012-page]
- IEEE 7012-2025's scope statement: "Contractual interactions and agreements between individuals and the service providers they engage on a network, including websites, applications and AI agents, are covered in this standard. It describes how individuals, acting as first parties, can proffer their privacy requirements as contractual terms and arrive at agreements recorded and kept by both sides." [ieee-7012-page]
- **The individual is the FIRST party in P7012, and the service provider is the second party** — the inverse of the usual "site publishes terms, user accepts" direction. Any restatement that makes the individual the proffering non-first-party has the role labels backwards. [ieee-7012-page] [dpv-p7012-ext]
- IEEE 7012-2025 PAR approval date is 2017-12-06; no expiry shown on the standard's page. [ieee-7012-page]
- The IEEE page states "The first party shall point to a preferred agreement, or a set of agreements, from which the second party shall accept one" — i.e. terms are selected from a roster, not authored per relationship. [ieee-7012-page]
- Customer Commons keeps the roster. Published MyTerms agreements as of 2026-09-03 include **P2B1 v0.9** and **SD-BY-AT v0.9**, each a dereferenceable versioned URL. [cc-agreements]
- P2B1's canonical URL resolves HTTP 200 in BOTH the dot and hyphen version forms: `https://customercommons.org/agreements/p2b1/0.9/` and `https://customercommons.org/agreements/p2b1/0-9/`. Secondary write-ups cite the hyphen form; both work, so a citation of either is not wrong. [cc-p2b1]
- P2B1 (nicknamed #NoStalking) means in plain language "don't track me off your site, and don't let others track me on your site or anywhere else"; its own page states "Machine-readability of P2B1 will be guided by P7012." [cc-p2b1]
- **A dereferenceable MyTerms agreement identifier exists TODAY.** Any protocol whose purpose/terms field already accepts an absolute URI can reference a rostered term with zero schema change. This makes "reference rather than invent" a concrete option, not an aspiration. [cc-agreements] [cc-p2b1]
- myterms.info names five standardized agreements at the January 2026 launch — SD-BASE, SD-BASE-DP, PDC-AI, PDC-GOOD, PDC-INTENT — a larger roster than the two live on customercommons.org/agreements/, so the roster is actively being built and a citation of "how many terms exist" goes stale fast. [myterms-info-standards]
- Customer Commons' "TM Registry" is a trademark-licensing directory (who may use the MyTerms™ mark — IEEE, and a forming "MyTerms Alliance"), NOT a registry of machine-readable term identifiers. Do not cite it as the term registry; the terms live under /agreements/. [cc-tm-registry]
- The W3C Data Privacy Vocabulary CG publishes "Extension for IEEE P7012 (P7012)" v2.1, a Draft Community Group Report dated 16 March 2025 — the only formal bridge artifact between P7012 and existing semantic-web privacy vocabulary. [dpv-p7012-ext]
- The DPV P7012 extension defines First Party as "The human individual or person whose personal data or privacy is involved" and Second Party as "An entity is any organisation with which a person makes or intends to make a contractual agreement" — independently confirming the role direction. [dpv-p7012-ext]
- The DPV P7012 extension defines the agreement-recording objects: `Agreement` ("A compound set of terms or clauses, proposed and offered before a formal contract between parties"), `AgreementRegistry` ("A registry hosting agreements that acts as a common repository for parties"), and `AgreementInteractionRecord` ("A record of interactions conducted in the course of establishing and negotiating agreements"). [dpv-p7012-ext]
- The DPV P7012 extension recommends "using ODRL Information Model 2.2 for a standardised structure and interpretation of the terms," alongside DCAT. So the term-content expression layer is ODRL, not a P7012-native format. [dpv-p7012-ext]
- GDPR Article 7(1): "Where processing is based on consent, the controller shall be able to demonstrate that the data subject has consented to processing of his or her personal data." This is the strongest citation for recording-what-was-displayed; it is a demonstrability duty, and a link the controller cannot show it displayed cannot be demonstrated. [gdpr-art7]
- GDPR Recital 42: "Where processing is based on the data subject's consent, the controller should be able to demonstrate that the data subject has given consent to the processing operation" and "For consent to be informed, the data subject should be aware at least of the identity of the controller and the purposes of the processing for which the personal data are intended." [gdpr-rec42]
- P7012 defines no wire format and is explicitly protocol-agnostic; ProjectVRM's Sept 2025 "Protocols for MyTerms" sketches carrying a MyTerms URI in OAuth ("OAuth 2.0 can carry MyTerms as a parameter or in a request object") and OIDC ID tokens, but this is an exploratory blog proposal soliciting feedback, NOT normative standard text. [projectvrm-protocols]
- Adoption is near zero as of publication: Doc Searls' own January 2026 post is titled "Toward a Proof of Concept for MyTerms," and the MyTerms Alliance was still forming at launch. The one public code artifact modelling P7012 in ODRL+DPV (`coolharsh55/myterms`) had ~10 commits, 2 stars, a placeholder README, and no releases. [projectvrm-protocols] [github-myterms-odrl]
- **No OAuth-family spec requires recording what was displayed.** Full-text search of RFC 7591, OIDC Core 1.0, and OIDC Dynamic Client Registration 1.0 finds zero obligation to persist displayed client metadata into a token, grant, or consent record. The display sentence is where their interest ends. [rfc7591] [oidc-dcr]
- OIDC Dynamic Client Registration 1.0 §2 restates RFC 7591's rule for `policy_uri`: "The OpenID Provider SHOULD display this URL to the End-User if it is given." It adds no obligation beyond RFC 7591 and never mentions consent records. [oidc-dcr]
- **The recording precedent lives in the consent-receipt lineage, not the identity-protocol lineage.** ISO/IEC 29184:2020 §5.2.8 "Ongoing reference" Control states verbatim: "The organization shall keep and make available the version of the notice presented when the PII principal gave consent, as well as the most recent relevant version for easy reference by that PII principal." Additional information: "Versions of notices should be retained for as long as they are associated with retained PII." This is normative "shall" and is the strongest single citation for recording-what-was-shown. [iso29184]
- **Every recording precedent pins a VERSION, not a bare URI** — because a URI is mutable and a recorded URL proves only which document was pointed at, not what it said at the time. ISO/IEC 29184 §5.2.8 says "the version of the notice presented." Kantara Consent Receipt v1.1.0 §4.4.10 makes `policyURL` REQUIRED and pins it to the policy "in effect when the consent was obtained," adding that the link "SHOULD continue to point to the old policy until there is evidence of an updated consent" — i.e. Kantara pushes the version-stability burden onto the controller's URL hygiene. A design that records only the URI should say plainly that it proves less than a snapshot does. [iso29184] [kantara-cr-policyurl]
- EDPB Guidelines 05/2020 on consent, para. 108, is the clearest regulatory-guidance statement of the rationale: a controller "could retain information on the session in which consent was expressed, together with documentation of the consent workflow at the time of the session, and a copy of the information that was presented to the data subject at that time. It would not be sufficient to merely refer to a correct configuration of the respective website." It is illustrative ("could"), not a binding MUST. [edpb-05-2020]
- GDPR Art. 13's enumerated information duties never mention "privacy policy," "terms of service," or a policy/ToS URL as such — they enumerate content (identity, purposes, retention, rights), not an artifact. Do not cite Art. 13 as requiring a policy link. [gdpr-art13]
- Current DPV is v2.3 (25 Feb 2026). `dpv:PrivacyNotice` and `dpv:ConsentNotice` exist and are distinct; `dpv:ConsentRecord` links to a notice via `dpv:hasNotice`. `dpv:PrivacyPolicy` and `dpv:TermsAndConditions` do NOT exist as DPV terms — the community deliberately prefers "Notice" over "Policy." DPV's shape (a consent record referencing a notice OBJECT, not a bare URL string) independently corroborates the version-pinning point above. [dpv-p7012-ext]
- Google Play's Prominent Disclosure rule is the strongest app-store precedent for display *timing*: disclosure "must be immediately preceded" by the runtime permission request and "cannot only be placed in a privacy policy or terms of service." Apple ASRG 5.1.1(i) is weaker — it requires a privacy-policy link in App Store Connect metadata and "within the app in an easily accessible manner," which is a listing/settings duty, not a moment-of-consent one. Neither imposes any recording obligation. [google-play] [apple-asrg]
- No regime found names AI training as a purpose that triggers a heightened privacy-policy requirement. A rule conditioning an AI-training purpose on the presence of a policy URL rests on the specifying protocol's own risk judgment, not on external prior art. UNVERIFIED that any such precedent exists; searched and not found.
- The IEEE 7012-2025 normative text is gated behind the IEEE GET Program / Xplore. Claims about its exact internal normative language sourced from blogs or aggregators are verbatim-per-secondary-source, not independently verifiable without registering. The scope statement and title ARE readable on the free standards.ieee.org project page. [ieee-7012-page]

## SOURCES

**rfc7591**
URL: https://www.rfc-editor.org/rfc/rfc7591
Accessed: 2026-09-03
Quote: "URL string that points to a human-readable privacy policy document that describes how the deployment organization collects, uses, retains, and discloses personal data. The authorization server SHOULD display this URL to the end-user if it is provided."

**ieee-7012-page**
URL: https://standards.ieee.org/ieee/7012/7192/
Accessed: 2026-09-03
Quote: "It describes how individuals, acting as first parties, can proffer their privacy requirements as contractual terms and arrive at agreements recorded and kept by both sides."

**dpv-p7012-ext**
URL: https://w3c-cg.github.io/dpv/2.1/standards/p7012/
Accessed: 2026-09-03
Quote: "A registry hosting agreements that acts as a common repository for parties" (AgreementRegistry); "We recommend using existing relevant standards...particularly the Data Catalog Vocabulary (DCAT), and using ODRL Information Model 2.2 for a standardised structure and interpretation of the terms."

**cc-agreements**
URL: https://customercommons.org/agreements/
Accessed: 2026-09-03
Quote: "Agreements can be recorded by both sides in ways that can be tracked and audited by both as well."

**cc-p2b1**
URL: https://customercommons.org/agreements/p2b1/0.9/ (and .../p2b1/0-9/ — both HTTP 200)
Accessed: 2026-09-03
Quote: "Machine-readability of P2B1 will be guided by P7012 – Standard for Machine Readable Personal Privacy Terms."

**cc-tm-registry**
URL: https://customercommons.org/tm-registry/
Accessed: 2026-09-03
Quote: "MyTerms™ is a registered trademark of Customer Commons."

**gdpr-art7**
URL: https://gdpr-info.eu/art-7-gdpr/
Accessed: 2026-09-03
Quote: "Where processing is based on consent, the controller shall be able to demonstrate that the data subject has consented to processing of his or her personal data."

**gdpr-rec42**
URL: https://gdpr-info.eu/recitals/no-42/
Accessed: 2026-09-03
Quote: "For consent to be informed, the data subject should be aware at least of the identity of the controller and the purposes of the processing for which the personal data are intended."

**iso29184**
URL: https://cdn.standards.iteh.ai/samples/70331/6d728e6153bb462fb03f476c9d961311/ISO-IEC-29184-2020.pdf (preview PDF; text extracted locally, clause located at §5.2.8)
Accessed: 2026-09-03
Quote: "The organization shall keep and make available the version of the notice presented when the PII principal gave consent, as well as the most recent relevant version for easy reference by that PII principal." / Additional information: "Versions of notices should be retained for as long as they are associated with retained PII."

**kantara-cr-policyurl**
URL: Kantara Consent Receipt Specification v1.1.0 (2018-02-20) §4.4.10, mirror at https://www.surveillancetrust.org/wp-content/uploads/2023/10/Consent-Receipt-Specification.pdf
Accessed: 2026-09-03
Quote: "REQUIRED: A link to the PII Controller's privacy statement/policy and applicable terms of use in effect when the consent was obtained, and the receipt was issued. If a privacy policy changes, the link SHOULD continue to point to the old policy until there is evidence of an updated consent from the PII Principal." (JSON field: `policyURL`)

**edpb-05-2020**
URL: https://www.edpb.europa.eu/system/files/documents/files/file1/edpb_guidelines_202005_consent_en.pdf (Guidelines 05/2020 on consent, v1.1, adopted 4 May 2020), para. 108
Accessed: 2026-09-03
Quote: "a controller could retain information on the session in which consent was expressed, together with documentation of the consent workflow at the time of the session, and a copy of the information that was presented to the data subject at that time. It would not be sufficient to merely refer to a correct configuration of the respective website."

**oidc-dcr**
URL: https://openid.net/specs/openid-connect-registration-1_0.html
Accessed: 2026-09-03
Quote: "policy_uri: OPTIONAL. URL that the Relying Party Client provides to the End-User to read about how the profile data will be used... The OpenID Provider SHOULD display this URL to the End-User if it is given."

**gdpr-art13**
URL: https://gdpr-info.eu/art-13-gdpr/
Accessed: 2026-09-03
Quote: Art. 13(1)-(2) enumerate identity, purposes/legal basis, recipients, transfer safeguards, retention period, and rights. The terms "privacy policy" and "terms of service" do not appear.

**google-play**
URL: https://support.google.com/googleplay/android-developer/answer/11150561
Accessed: 2026-09-03
Quote: "Requests for in-app user consent and runtime permission requests must be immediately preceded by an in-app disclosure... Cannot only be placed in a privacy policy or terms of service."

**apple-asrg**
URL: https://developer.apple.com/app-store/review/guidelines/
Accessed: 2026-09-03
Quote: "All apps must include a link to their privacy policy in the App Store Connect metadata field and within the app in an easily accessible manner."

**myterms-info-standards**
URL: https://myterms.info/ieee7012-standards/
Accessed: 2026-09-03
Quote: Lists "SD-BASE", "SD-BASE-DP", "PDC-AI", "PDC-GOOD", "PDC-INTENT"; "Published January 2026 in the IEEE Get Program."

**projectvrm-protocols**
URL: https://projectvrm.org/2025/09/06/protocols-for-myterms/
Accessed: 2026-09-03
Quote: "OAuth 2.0 can carry MyTerms as a parameter or in a request object, recording consent/acceptance with the access transaction."

**github-myterms-odrl**
URL: https://github.com/coolharsh55/myterms
Accessed: 2026-09-03
Quote: "experimental contracts for IEEE P7012 based on ODRL and DPV"

## SYNTHESIS

Two premises that sound authoritative and are both wrong, each of which changes the resulting design decision:

**"Our spec says the AS MAY display policy_uri/tos_uri, and RFC 7591 is where we got the vocabulary."** Then the spec is weaker than its own cited source. RFC 7591 says SHOULD for both fields. Raising MAY→SHOULD is not a new normative opinion that needs prior-art justification; it is fixing an unintended downgrade. This reframes the whole decision: the expensive-sounding half of the proposal is free, and the only part that needs defending is the *recording* obligation. Check the source vocabulary's actual keyword before arguing about whether to strengthen your own.

**"MyTerms — the individual proffers, the first party agrees."** The individual IS the first party. Getting this backwards inverts the standard's entire point (its whole reason to exist is that today the site is the one setting terms). Also: it is IEEE, not ISO, and it is published (Jan 2026), not a draft to be evaluated at leisure.

On the real design question — recording what was displayed — the split in prior art is clean and worth remembering: **display obligations are common, recording-what-was-displayed obligations are rare, and they live in a different standards family than the display obligations do.** The OAuth/OIDC lineage (RFC 7591, OIDC Core, OIDC DCR) says display and stops; full-text search finds no persistence obligation anywhere in it. The consent-receipt lineage (Kantara CR → ISO/IEC 29184 → ISO/IEC 27560) is where recording is actually specified, and ISO/IEC 29184 §5.2.8 is the strongest citation in the whole set because it is normative "shall." So adding a record-what-was-shown rule to an OAuth-family protocol is a genuine extension of that family, not a gap-fill — argue it on dispute-resolution merits, and do not claim it "aligns with OAuth practice," because it does not.

**The sharpest trap here, and the thing most worth carrying forward: every recording precedent pins a version, not a bare URI.** ISO/IEC 29184 says "the version of the notice presented." Kantara pins `policyURL` to the policy "in effect when the consent was obtained." DPV models a consent record as referencing a Notice *object*, not a URL string. The reason is the same in all three: the URL belongs to the other party and its content can change the day after consent. A spec that records only the URI and then claims the record shows "what the user saw" is overclaiming — it shows which document they were pointed at. That is still worth having (it is cheap, needs no new field if a `client_display`-shaped object already exists, and converts an unfalsifiable "we showed them the policy" into something checkable), but the honest framing is *which document*, with a snapshot-or-digest SHOULD for deployments that need more. Write the limitation into the spec text rather than letting an implementer discover it in a dispute.

On MyTerms compatibility, the genuinely useful finding is that **a dereferenceable rostered identifier exists today** (`customercommons.org/agreements/p2b1/0.9/`). That turns "reference rather than invent" from a principle into an executable option for any protocol whose purpose/terms field takes an absolute URI — no schema change required. The corresponding risk is equally concrete: minting a closed bespoke vocabulary for terms a roster already names makes two records of the same real-world agreement machine-incomparable, which is exactly what the roster model exists to prevent. Keeping a purpose/terms field open to unrecognized URIs is what preserves the option, and it costs nothing.

Temper the enthusiasm on two axes. P7012 defines no wire format and is protocol-agnostic, so "compatible" is currently true at the terms-vocabulary layer and unproven at the negotiation/dual-record layer — P7012 expects both parties to hold a record and allows a counter-offer, and most OAuth-family designs define only the authorization server's copy and issue after consent rather than negotiating. And adoption is near zero: five named terms, a forming alliance, a proof of concept still described as forthcoming. Reference it as a hedge; do not build a dependency on it yet.

Research-hygiene note for next time: `customercommons.org/tm-registry/` sounds like the term registry and is not — it is trademark licensing. The terms are under `/agreements/`. And the P2B1 URL works with both `0.9` and `0-9`, so a mismatch between two sources on that path segment is not evidence that one of them is wrong.
