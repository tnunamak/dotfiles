---
title: "RFC 9396 §5 makes the AS reject an authorization_details object of known type carrying unknown fields, so a 'deferred' RAR request-side field can never be adopted early — and the owner-proffered-terms layer has no OAuth-family precedent at all (UMA scopes owner policy OUT, GNAP never mentions terms), while ISO/IEC TS 27560 is a Technical Specification whose *receipt* needs only two fields"
date: 2026-09-03
topic: protocols
tags: [rfc-9396, rar, oauth, uma, gnap, iso-27560, iso-29184, odrl, dpv, myterms, ieee-7012, consent-records, kantara, ancr, aipref, rsl, tdmrep, gpc, iab-tcf, fhir-consent, solid-sai, prior-art, pdpp]
status: draft
sources: [rfc9396, rfc9635, uma-grant, dpv-27560-guide, iso-27560-cat, dpv-p7012-ext, dpv-current, odrl-vocab, odrl-model, ieee-7012-page, cc-agreements, kantara-groups, kantara-ancr, aipref-vocab, rsl, fhir-consent, solid-sai, gpc, google-consent-mode, tdmrep-cg]
source_session: 696eaf38-e052-44a1-942e-19d9580b448d
---

<!--
Produced for a PDPP owner-commissioned prior-art sweep on whether owner-proffered
terms (MyTerms/IEEE 7012) belong in Core v0.1. Extends the same-day entry
myterms-is-ieee-7012-2025-... which covers the display-vs-recording split;
this one covers the OBJECT and NEGOTIATION layer, plus the RAR extensibility rule
that decides where such a field can legally live.
-->

## CLAIMS

- **RFC 9396 §5 (Authorization Error Response) is fail-closed on unknown fields inside a known type:** the AS "MUST refuse to process any unknown authorization details type or authorization details not conforming to the respective type definition," and MUST abort with `invalid_authorization_details` if an object "is an object of known type but containing unknown fields." [rfc9396]
- Consequence, and the durable design lesson: **a RAR-based protocol cannot "defer" a request-side field and let clients adopt it early.** Any new member of a defined `authorization_details` type is illegal on the wire until the type definition includes it. A deferred request-side field arrives as a breaking change, not an additive one — the opposite of the usual optional-absent reasoning. Additive-by-default intuitions from JSON APIs and from RFC 7519 §4 ("claims that are not understood MUST be ignored") do NOT transfer to RAR. [rfc9396]
- RFC 9396 §2.2 grants extensibility only *within* the type: "An API MAY define its own extensions, subject to the type of the respective authorization object. It is anticipated that API designers will use a combination of common data fields defined in this specification as well as fields specific to the API itself." §2.2's common fields are `type`, `locations`, `actions`, `datatypes`, `identifier`, `privileges`. [rfc9396]
- RFC 9396 §6.1 states "there is no standardized mechanism to compare two arbitrary authorization detail requests" and warns an AS "should not rely on simple object comparison." So adding fields to the request side also complicates incremental-authorization comparison; keeping a field grant-side-only avoids that entirely. [rfc9396]
- RFC 9396 §3.1: "When gathering user consent, the AS MUST present the merged set of requirements represented by the authorization request." §14.3 registers `authorization_details` as an RFC 7662 introspection-response member (corroborating the existing corpus entry on that point). [rfc9396]
- The fail-closed posture recurs one layer below the wire, in implementations: PDPP's reference `GrantSchema` (`packages/reference-contract/src/public/index.ts`) sets `additionalProperties: false`, so even a grant-side field cannot be populated by a deployment without a contract change. Worth checking before describing any JSON-Schema-validated record field as "optional, so deployments can start using it early" — `additionalProperties: false` and RFC 9396 §5 produce the same outcome for different reasons. [pdpp-grant-schema]
- **UMA 2.0 deliberately scopes the resource owner's policy OUT.** Grant spec §6.1: "The setting of policy conditions, the resource owner-authorization server interface, and the resource owner-resource server interface are outside the scope of this specification." UMA's resource owner is explicitly an individual or legal person (§1.2). So the closest user-managed-access standard to an owner-terms design declines to define owner terms. [uma-grant]
- UMA's `claims_interaction_endpoint` (§2, OPTIONAL) is "A static endpoint URI at which the authorization server declares that it interacts with end-user requesting parties to gather claims" — real interactive-gathering precedent, but it gathers *requesting-party* claims, not the owner's terms. Do not cite it as precedent for owner-proffered terms. [uma-grant]
- **GNAP (RFC 9635) contains ZERO occurrences of "privacy policy" or "terms of service"** (full-text search of the RFC text file). Its only consent language is §1.4 (Trust Relationships): "The AS is expected to follow the decisions made by the RO, through either interactive consent requests, repeated interactions, or automated rules" — consent as process, never as a persisted artifact. [rfc9635]
- Citation trap, same family as the six-stale-citations entry: a delegated research pass placed that GNAP quote at "§1.4.4.12" and the `interact` field at "§2.5". Both are wrong — verified by grepping the RFC text: the quote is in **§1.4**, and `interact` is defined under **§2 (Requesting Access)**; §2.5 is "Interacting with the User." Deeply-nested section numbers returned by fetch-and-summarize tools are the highest-risk citations in this domain. [rfc9635]
- **ISO/IEC 27560 is a Technical Specification, not an International Standard:** "ISO/IEC TS 27560:2023 · Privacy technologies — Consent record information structure · Edition 1, 2023-08 · Technical Specification." Calling it "ISO/IEC 27560" overstates its tier. Adopted identically as INCITS/ANSI and DS national standards. Normative text paywalled. [iso-27560-cat]
- ISO/IEC TS 27560's **consent record has four sections** — Header (identifier, creation timestamp), Processing (purposes, personal data), Parties (entities involved), Events (consent given, withdrawn) — per the W3C DPV guide's rendering. [dpv-27560-guide]
- **A 27560-conformant consent RECEIPT requires only two fields** — a unique receipt identifier and the schema version — and "The information and contents are undefined and left to each implementer to specify." So "we support ISO 27560 receipts" is a nearly vacuous claim; the *record* is the substantive target. [dpv-27560-guide]
- **27560 inverts Kantara's receipt direction.** Per the DPV guide: "According to [ISO-27560], records are generated and maintained by organisations (Controller, Third Party), and are utilised to provide receipts to a Data Subject. In contrast, the Kantara Consent Receipt Specification v1.1.0, upon which [ISO-27560] is based, defines Consent Receipts as being provided by a Data Subject to a Controller." DPV itself declines to restrict either direction. [dpv-27560-guide]
- **27560's Notice field is MANDATORY and version-pinned:** "This field MUST be present. Reference to the specific version of the notice (`privacy_notice` in [ISO-27560]) associated with consent, indicated using `dpv:hasNotice`." This independently confirms the version-not-URI pattern recorded in the companion entry, and confirms `dpv:hasNotice` exists (one delegated pass could not verify it). [dpv-27560-guide]
- The DPV↔27560 guide is a **Final** Community Group Report (15 Feb 2026) — a stronger artifact than the DPV↔P7012 extension, which is still a **Draft** CG Report at v2.1 (16 Mar 2025). [dpv-27560-guide] [dpv-p7012-ext]
- **Correction after a direct re-check:** DPV core v2.3 (25 Feb 2026, Final CG Report) explicitly lists `STANDARD-IEEE-7012` among its current extensions. The bridge is not stranded. It remains a Community Group artifact rather than a W3C Standard. [dpv-current] [dpv-p7012-ext]
- The DPV P7012 extension §6.3.2 documents the negotiation and dual-record mechanics: "If the EntityAgent does not accept [the agreement], it can make a counter-offer to negotiate with an agreement of its choice" and "The PersonAgent and EntityAgent keep a record of the request, negotiation, and contract by logging each step." [dpv-p7012-ext]
- **`odrl:Request` and `odrl:Privacy` are NOT ODRL Information Model subclasses.** The Information Model §2.1 says "The Policy class is the parent class to the Set, Offer, and Agreement subclasses." `Request` (§4.1.3) and `Privacy Policy` (§4.1.2) exist only in the separate *Vocabulary & Expression* document's Common Vocabulary layer. Citing "ODRL 2.2 Agreement/Offer/Request" as one model conflates two documents. [odrl-model] [odrl-vocab]
- ODRL's owner-direction term is `Request`: "A Policy that proposes a Rule over an Asset from an assignee" (§4.1.3) — i.e. proposed by the receiving party, the structural analogue of an individual proffering terms. Also in the Common Vocabulary: `Consenting Party` "The Party to obtain consent from" (§4.3.5), `Consented Party` "The Party who obtains the consent" (§4.3.6), `Obtain Consent` (§4.4.31). Section numbers verified against the live TOC. [odrl-vocab]
- **ODRL models purpose as a Constraint left operand, not an object:** §4.5.19 Purpose = "A defined purpose for exercising the action of the Rule." And §4.5.31 `Version` = "The version of the target Asset" — the *asset's* version, not the policy's; ODRL has no policy-version property, only `uid` (IRI, MUST) and `profile` (§3.1.3). A design needing versioned terms must put the version in the identifier URI. [odrl-vocab] [odrl-model]
- **Every standard surveyed keeps purpose separate from agreement**, by four independent mechanisms: DPV as distinct classes (`dpv:Purpose`/`dpv:Consent`/`dpv:ConsentRecord`); ODRL as constraint-inside-policy; ISO/IEC TS 27560 as a field inside the Processing section; and SMART on FHIR by architectural decoupling — scopes carry resource type + CRUDS only, while purpose-of-use lives in the separate v3 ActReason PurposeOfUse value set consumed by Consent/Contract/Provenance/AuditEvent. Routing an agreement URI through a purpose field is therefore against unanimous prior art. [dpv-current] [odrl-vocab] [dpv-27560-guide] [fhir-consent]
- **FHIR R5 Consent supplies the best field-level model for a terms reference:** `policyBasis` = "A Reference or URL used to uniquely identify the policy the organization will enforce ... should be dereferencable to a computable policy" and `policyText` = "A Reference to the human readable policy explaining the basis for the Consent." R5 deleted R4's `Consent.policy`/`policyRule`, renamed `performer`→`grantee`, added `grantor`/`controller`/`manager`, and merged `scope` into `category` — so any R4-era Consent citation is stale. [fhir-consent]
- **Kantara's ANCR is "Anchored Notice & Consent Receipts", not "Advanced"** (Kantara's own group listing and WG page), and it is a **work group, not a specification** — chartered to "update version 1.1 of the Consent Receipt Specification." Its one published Kantara Recommendation is on a different artifact: "Transparency Performance Indicators: PII Controller Identification for Valid Consent." Schema drafts live on Kantara's Confluence and were not fetchable. [kantara-groups] [kantara-ancr]
- Kantara's WG page states CR v1.1 "was included in ISO/IEC 29184 Online privacy notices and consent (released on 6 June 2020) as Appendix B where it is described as a Consent Receipt Notice" — the lineage is CR v1.1 → 29184 Appendix B → TS 27560. No primary Kantara document was found formally deprecating v1.1.0. UNVERIFIED. [kantara-ancr]
- **IEEE 7012-2025's free project page carries normative-sounding dual-record language** beyond the scope statement already recorded: terms are "chosen from a collection of standard-form agreements in a roster kept by an independent and neutral non-business entity," and on consent "the chosen contract or agreement shall be signed electronically by both parties or their agents, and a matching record shall be kept by both sides in a form that can be retrieved, audited, or disputed." The full standard is offered at no cost through IEEE GET, but Xplore returned HTTP 418 in this environment, so this research verified the page summary rather than the full text. [ieee-7012-page]
- **The AI-training licensing family is the only place publisher-proffered machine-readable terms ship at scale, and NONE of them keeps an acceptance record.** RSL 1.0 (Recommendation, RSL TSC, Dec 2025; namespace `https://rslstandard.org/rsl`; permits include `ai-train`; payment models `free`/`attribution`/`subscription`/`inference`), TDMRep (W3C **Community Group Final Report**, not a Recommendation; `tdm-reservation` + `tdm-policy`; implements EU DSM Art. 4), RFC 9309 robots.txt (the only formal RFC), and Cloudflare pay-per-crawl are all unilateral published offers. This is strong precedent for *publishing* terms and a conspicuous absence of precedent for a *bilateral agreement record*. [rsl] [tdmrep-cg] [aipref-vocab]
- **IETF AIPREF is the live centre of gravity and is still a draft:** `draft-ietf-aipref-vocab-07` (19 Aug 2026), Intended status Proposed Standard, expires 20 Feb 2027, authors Paul Keller (Open Future) and Martin Thomson (Mozilla), AI Preferences WG; abstract "defines a vocabulary for expressing preferences regarding how digital assets are used by automated processing systems." Companion `draft-ietf-aipref-attach-05` adds a `Content-Usage` HTTP header and robots.txt directive. Not RFCs. TDMRep's CG is deferring further formalization pending this work. `ai.txt`/`llms.txt` are conventions with no defining IETF/W3C document. [aipref-vocab] [tdmrep-cg]
- **Global Privacy Control is the sharpest counter-example in the set:** individual-proffered like MyTerms, but a single binary `Sec-GPC` signal with no purpose list, no terms, and no record on either side — and it achieved real legal force (CCPA) precisely by carrying almost no semantics. Adopted as an official W3C Privacy Working Group work item in November 2024. [gpc]
- Google consent mode v2 is explicitly **not** a record: "Since consent mode doesn't save consent choices, update the consent status as soon as a user interacts with your consent management solution." Signals are `ad_storage`, `analytics_storage`, `ad_user_data`, `ad_personalization`. [google-consent-mode]
- Solid SAI Access Grants show a genuine purpose/authorization split — an app-authored Access Need Group (why) versus an owner-issued Access Grant (what), with `grantedBy`/`grantedAt`/`grantee`/`hasAccessNeedGroup`/`hasDataGrant` stored "in the Agent Registry of the Data Owner" (§9.3) — but SAI is a **Draft** Community Group Report, and ODRL-for-Solid is separate academic work, not part of SAI. [solid-sai]
- The Customer Commons roster page names JLINC as the example of agreements "recorded by both sides in ways that can be tracked and audited by both," and lists P2B1 v0.9 and SD-BY-AT v0.9. A delegated pass reported that P7012 is not mentioned on the roster pages; that is wrong — the P2B1 term page states machine-readability "will be guided by P7012" (also recorded in the companion entry). [cc-agreements]

## SOURCES

**rfc9396**
URL: https://www.rfc-editor.org/rfc/rfc9396.txt
Accessed: 2026-09-03 (fetched as text and grepped locally, not summarized)
Quote: §5 — "The AS MUST refuse to process any unknown authorization details type or authorization details not conforming to the respective type definition. The AS MUST abort processing and respond with an error invalid_authorization_details to the client if any of the following are true of the objects in the authorization_details structure: * contains an unknown authorization details type value, * is an object of known type but containing unknown fields, ..." / §2.2 — "An API MAY define its own extensions, subject to the type of the respective authorization object." / §6.1 — "there is no standardized mechanism to compare two arbitrary authorization detail requests" / §3.1 — "When gathering user consent, the AS MUST present the merged set of requirements represented by the authorization request."

**pdpp-grant-schema**
URL: local — `~/code/pdpp/packages/reference-contract/src/public/index.ts:342` @ `origin/main`
Accessed: 2026-09-03
Quote: `const GrantSchema = { additionalProperties: false, properties: { ... client: { properties: { client_display: ClientDisplaySchema, client_id: NonEmptyStringSchema }, required: ["client_id"] } ... } }`

**rfc9635**
URL: https://www.rfc-editor.org/rfc/rfc9635.txt
Accessed: 2026-09-03 (fetched as text; section attribution derived by locating the enclosing heading, not by tool summary)
Quote: §1.4 — "AS/RO: The AS is expected to follow the decisions made by the RO, through either interactive consent requests, repeated interactions, or automated rules (as described in Section 1.6)." Full-text search for "privacy policy" and "terms of service": zero hits.

**uma-grant**
URL: https://docs.kantarainitiative.org/uma/wg/rec-oauth-uma-grant-2.0.html
Accessed: 2026-09-03 (Kantara Recommendation, 7 January 2018)
Quote: §6.1 — "The setting of policy conditions, the resource owner-authorization server interface, and the resource owner-resource server interface are outside the scope of this specification." / §2 — "claims_interaction_endpoint: OPTIONAL. A static endpoint URI at which the authorization server declares that it interacts with end-user requesting parties to gather claims."

**dpv-27560-guide**
URL: https://w3c-cg.github.io/dpv/guides/consent-27560
Accessed: 2026-09-03 (Final Community Group Report, 15 February 2026; editor Harshvardhan J. Pandit)
Quote: §6.4 — "A Consent Record contains four sections ... 1. Header ... 2. Processing ... 3. Parties ... 4. Events" / §6.4 — "The Consent Receipt in [ISO-27560] contains only two required fields representing a unique identifier for the receipt and the schema version used for the structuring of information. The information and contents are undefined and left to each implementer to specify." / §6.3 — "According to [ISO-27560], records are generated and maintained by organisations (Controller, Third Party), and are utilised to provide receipts to a Data Subject. In contrast, the Kantara Consent Receipt Specification v1.1.0, upon which [ISO-27560] is based, defines Consent Receipts as being provided by a Data Subject to a Controller." / §8.2.1 — "This field MUST be present. Reference to the specific version of the notice (privacy_notice in [ISO-27560]) associated with consent, indicated using dpv:hasNotice"

**iso-27560-cat**
URL: https://www.iso.org/standard/80392.html
Accessed: 2026-09-03 (direct fetch returned HTTP 403; catalogue metadata via search cache)
Quote: "ISO/IEC TS 27560:2023 · Privacy technologies — Consent record information structure · Edition 1, 2023-08 · Technical Specification."

**dpv-p7012-ext**
URL: https://w3c-cg.github.io/dpv/2.1/standards/p7012/
Accessed: 2026-09-03 (Draft Community Group Report, 16 March 2025, v2.1)
Quote: §6.3.2 — "If the EntityAgent does not accept [the agreement], it can make a counter-offer to negotiate with an agreement of its choice." / "The PersonAgent and EntityAgent keep a record of the request, negotiation, and contract by logging each step."

**dpv-current**
URL: https://w3c-cg.github.io/dpv/ (canonical https://w3id.org/dpv)
Accessed: 2026-09-03
Quote: "Currently it provides the extension STANDARD-IEEE-7012 to support the implementation of IEEE 7012-2025."

**odrl-vocab**
URL: https://www.w3.org/TR/odrl-vocab/
Accessed: 2026-09-03 (W3C Recommendation, 15 February 2018; section numbers checked against the live table of contents)
Quote: §4.1.3 Request — "A Policy that proposes a Rule over an Asset from an assignee." / §4.1.2 Privacy Policy — "A Policy that expresses a Rule over an Asset containing personal information." / §4.3.5 Consenting Party — "The Party to obtain consent from." / §4.3.6 Consented Party — "The Party who obtains the consent." / §4.4.31 Obtain Consent — "To obtain verifiable consent to perform the requested action in relation to the Asset." / §4.5.19 Purpose — "A defined purpose for exercising the action of the Rule." / §4.5.31 Version — "The version of the target Asset." / §3.1.3 Profile — "The identifier(s) of an ODRL Profile that the Policy conforms to."

**odrl-model**
URL: https://www.w3.org/TR/odrl-model/
Accessed: 2026-09-03 (W3C Recommendation, 15 February 2018)
Quote: §2.1 — "The Policy class is the parent class to the Set, Offer, and Agreement subclasses." / §2.1 — "A Policy MUST have one uid property value (of type IRI) to identify the Policy." A search of this document for a "Request" section returns nothing.

**ieee-7012-page**
URL: https://standards.ieee.org/ieee/7012/7192/
Accessed: 2026-09-03 (free project page; full text offered at no cost through IEEE GET, but Xplore returned HTTP 418 here)
Quote: "chosen from a collection of standard-form agreements in a roster kept by an independent and neutral non-business entity" / "the chosen contract or agreement shall be signed electronically by both parties or their agents, and a matching record shall be kept by both sides in a form that can be retrieved, audited, or disputed"

**cc-agreements**
URL: https://customercommons.org/agreements/
Accessed: 2026-09-03
Quote: "Agreements can be recorded by both sides in ways that can be tracked and audited by both as well." Lists P2B1 v0.9 and SD-BY-AT v0.9; names JLINC Labs / JLINC.org as the recording example.

**kantara-groups**
URL: https://kantarainitiative.org/groups/
Accessed: 2026-09-03
Quote: Lists "Anchored Notice & Consent Receipts (ANCR)" and "User-Managed Access (UMA)" as Active work groups.

**kantara-ancr**
URL: https://kantarainitiative.org/work-groups/ancr/
Accessed: 2026-09-03
Quote: Group name "Anchored Notice & Consent Receipts"; scope to "address the technical gaps, and take advantage of recent legal and standards development, to update version 1.1 of the Consent Receipt Specification." / CR v1.1 "was included in ISO/IEC 29184 Online privacy notices and consent (released on 6 June 2020) as Appendix B where it is described as a Consent Receipt Notice." Published Kantara Recommendation listed: "Transparency Performance Indicators: PII Controller Identification for Valid Consent."

**aipref-vocab**
URL: https://datatracker.ietf.org/doc/draft-ietf-aipref-vocab/
Accessed: 2026-09-03
Quote: "draft-ietf-aipref-vocab-07", 19 August 2026, Intended status Proposed Standard, expires 20 February 2027, AI Preferences (aipref) WG, authors Paul Keller (Open Future) and Martin Thomson, Ed. (Mozilla). Abstract: "This document defines a vocabulary for expressing preferences regarding how digital assets are used by automated processing systems." Companion: draft-ietf-aipref-attach-05 (Content-Usage header + robots.txt directive).

**rsl**
URL: https://rslstandard.org/
Accessed: 2026-09-03
Quote: Namespace "https://rslstandard.org/rsl"; permit example `<permits type="usage">ai-train</permits>`; payment models subscription, attribution, inference, free. RSL 1.0 published as a Recommendation by the RSL Technical Steering Committee, December 2025.

**fhir-consent**
URL: https://hl7.org/fhir/consent.html
Accessed: 2026-09-03 (FHIR R5 / v5.0.0)
Quote: policyBasis — "A Reference or URL used to uniquely identify the policy the organization will enforce ... should be dereferencable to a computable policy." / policyText — "A Reference to the human readable policy explaining the basis for the Consent." / R4→R5: Consent.scope deleted ("Merged with Consent.category"), Consent.performer renamed to grantee, Consent.policy/policyRule deleted.

**solid-sai**
URL: https://solidproject.org/TR/sai
Accessed: 2026-09-03 (Draft Community Group Report)
Quote: §9.3 — "An Access Grant provides an Agent with a detailed description of access that has been granted to them. Access Grants are generated from Access Authorizations, and are stored in the Agent Registry of the Data Owner."

**gpc**
URL: https://globalprivacycontrol.org/
Accessed: 2026-09-03
Quote: "In November 2024, GPC was adopted as an official work item of the W3C Privacy Working Group."

**google-consent-mode**
URL: https://developers.google.com/tag-platform/security/guides/consent
Accessed: 2026-09-03
Quote: "Since consent mode doesn't save consent choices, update the consent status as soon as a user interacts with your consent management solution."

**tdmrep-cg**
URL: https://w3c-cg.github.io/tdm-reservation-protocol/spec/ and https://www.w3.org/community/tdmrep/
Accessed: 2026-09-03
Quote: "The 'opt-out' option specified by the Article 4 of the CDSM Directive is expressed by the use of tdm-reservation with value equal 1." / "Community Groups are proposed and run by the community ... the groups do not necessarily represent the views of the W3C Membership or staff."

## SYNTHESIS

The single most reusable finding is the RAR extensibility rule, because it inverts the instinct that governs most schema-evolution decisions. Everywhere else — JSON APIs, JWT claims per RFC 7519 §4, HTTP headers per RFC 9110 §5.1 — unknown members are ignored, so "define it later, let early adopters send it now" is free. RFC 9396 §5 is the opposite polarity: an object of *known* type carrying *unknown* fields MUST be rejected outright. So for any protocol profiling RAR, the question "should this field be in v0.1 or deferred?" has a different answer on the request side than on the grant side. Grant-side and introspection-side fields stay genuinely optional and reversible; request-side fields are all-or-nothing and arrive as breaking changes. Deferral is not the conservative choice there — it just relocates the cost. This is the same opposite-polarity-within-one-family trap the earlier six-stale-citations entry recorded for RFC 7515 §4.1.11 vs RFC 7519 §4, and it is worth checking the polarity explicitly rather than assuming additive semantics.

The second durable finding is a shape, not a citation: **publication and record-keeping are separable, and prior art supports only the first.** Everything that actually ships owner- or publisher-proffered machine-readable terms today — RSL, TDMRep, robots.txt, AIPREF, Cloudflare — publishes a unilateral offer and keeps no acceptance record. Everything that specifies a bilateral record — IEEE 7012, the DPV P7012 extension, Kantara's lineage — has near-zero deployment, no wire format, or draft status. And the two OAuth-family standards closest to the problem actively decline it: UMA §6.1 puts the resource owner's policy outside its scope, GNAP never mentions terms at all. So when someone proposes "align with MyTerms," the useful question is which half they mean. The publication half has precedent and is buildable; the dual-record flow would make the implementer the first mover in an OAuth-family protocol. Counter-offer is a DPV-extension design, not an IEEE 7012 requirement; IEEE explicitly puts party-to-party negotiation outside scope.

Third, the tier-and-status audit mattered more than expected: ISO/IEC 27560 is a **TS**, not an IS. Kantara's ANCR is a **work group**, not a spec, and is "Anchored" not "Advanced." TDMRep is a **CG Final Report**, not a Recommendation. Solid SAI and the DPV P7012 extension are **Drafts**. AIPREF is an active **Internet-Draft**. A direct re-check corrected the earlier claim that the DPV P7012 bridge was stranded: DPV 2.3 explicitly lists `STANDARD-IEEE-7012`. A relationship table that cites all of these at face value still reads as better-supported than it is. Check the deliverable tier and current index before writing a row.

Fourth, a cheap sanity check that paid off twice: **"27560-conformant receipt" is nearly vacuous** (two required fields, contents implementer-defined), and 27560 *reverses* Kantara's receipt direction (organisation-held record → receipt to the subject, where Kantara had subject → controller). Anyone claiming receipt conformance as evidence of rigour should be asked which of the two directions and which of the two artifacts they mean.

Finally, the unanimity result is worth carrying: **purpose and agreement are separate objects in every standard surveyed**, by four independent mechanisms (DPV's distinct classes, ODRL's purpose-as-constraint, 27560's purpose-inside-Processing, SMART's purpose-of-use decoupled from scopes). Any design tempted to route an agreement identifier through an existing open-URI purpose field — attractive because it needs no schema change — is going against a unanimous finding, and will usually also collide with whatever rule already switches on the purpose value.

Research hygiene, repeating a lesson: the two citation errors caught this session both came from fetch-and-summarize tool output, and both were deeply-nested section numbers (GNAP "§1.4.4.12"/"§2.5", and an ODRL subclass list that conflated two documents). Both were fixed by downloading the RFC text and grepping for the enclosing heading, and by reading the live TOC rather than a prose summary. For section-number-bearing claims in this domain, fetch the raw artifact.
