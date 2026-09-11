---
title: "Six commonly-cited OAuth/consent precedents carry stale or wrong section numbers and term names (crit is not in RFC 7519, OpenID Federation renamed trust-mark `id` to `trust_mark_type`, DPV has no hasRetentionPeriod, P3P's value is legal-requirement, OAuth incremental-authz expired without publication, PSD2 register status is entity-level not per-role)"
date: 2026-09-03
topic: protocols
tags: [oauth, rfc-citation-hygiene, openid-federation, dpv, p3p, psd2]
status: draft
sources: [rfc7519, rfc7515, rfc6749, oidfed, dpv21, p3p10, incremental-authz, rfc9110, fhir-binding, eba410]
source_session: 8bf5512a-c721-443b-a326-33eeaf80edad
---

## CLAIMS

- `crit` does not appear anywhere in RFC 7519 (JWT); it is defined only in RFC 7515 (JWS) §4.1.11. RFC 7519 §5.2 is `cty`, not `crit`. [rfc7519] [rfc7515]
- The open-vs-closed extensibility contrast is best cited as RFC 7519 §4 ("all claims that are not understood by implementations MUST be ignored") against RFC 7515 §4.1.11 ("If any of the listed extension Header Parameters are not understood and supported by the recipient, then the JWS is invalid"). Note the spec's term is "invalid," not "reject." [rfc7519] [rfc7515]
- RFC 6749 §8.4 is "Defining New Authorization Endpoint Response Types," NOT extension parameters. For new endpoint parameters cite §8.2, and the OAuth Parameters Registry at §11.2. [rfc6749]
- RFC 6749's unknown-parameter rule — "The authorization server MUST ignore unrecognized request parameters" — appears in BOTH §3.1 (authorization endpoint) and §3.2 (token endpoint). Client-side mirrors: §4.1.2, §4.2.2, §5.1. [rfc6749]
- OpenID Federation 1.0 renamed the trust-mark `id` claim to `trust_mark_type` (was `id` through roughly draft-33). Current §7.1 REQUIRED set: `iss`, `sub`, `trust_mark_type`, `iat`. OPTIONAL: `exp`, `logo_uri`, `ref`, `delegation`. [oidfed]
- Because OpenID Federation trust-mark `exp` is OPTIONAL ("If not present, it means that the Trust Mark does not expire"), any system modeling trust marks must treat validity-end as nullable rather than mandatory. [oidfed]
- W3C DPV 2.1 has no `hasRetentionPeriod`, no `RetentionPeriod`, and no `hasStorageDuration`. The real terms are `StorageCondition`, `hasStorageCondition`, and `StorageDuration` (`https://w3id.org/dpv#StorageDuration`). [dpv21]
- DPV is a Community Group report: "It is not a W3C Standard nor is it on the W3C Standards Track." Canonical URL moved from `w3c.github.io/dpv` to `w3c-cg.github.io/dpv`. [dpv21]
- P3P 1.0's RETENTION value is `legal-requirement`, not "legally-required." The five values are `no-retention`, `stated-purpose`, `legal-requirement`, `business-practices`, `indefinitely`. There is no `archive` value. [p3p10]
- P3P 1.0 makes retention structurally a sibling of purpose: RETENTION (§3.3.6), PURPOSE (§3.3.4) and RECIPIENT (§3.3.5) are all required sub-elements of STATEMENT — so "retention is duration plus purpose, not a standalone value" is well-precedented. [p3p10]
- `draft-ietf-oauth-incremental-authz` ("OAuth 2.0 Incremental Authorization") was IETF OAuth WG-adopted but **expired** at revision -04 (2020-05-03), never published as an RFC. Datatracker: "This Internet-Draft is no longer active." Cite RFC 9470 (Step Up Authentication Challenge, Standards Track, 2023) instead for step-up. [incremental-authz]
- Commission Implementing Regulation (EU) 2019/410 carries the PSD2 register field tables (2019/411 is the Delegated Regulation on register operation). Its Annex records services as a per-entity checkbox list with AISPs in a separate category (Table 3), but authorisation **status is entity-level** (Table 1 Row 8, one status + one date pair) — per-service granularity exists only for host-state passporting (Row 11). So PSD2 supports role-scoped permission, NOT per-role validity windows. [eba410]
- RFC 9110's unknown-header rule is SHOULD-strength, not MUST: §5.1 "Other recipients SHOULD ignore unrecognized header and trailer fields"; §16.3 "Most fields are designed with the expectation that a recipient can safely ignore (but forward downstream) any field not recognized." (§16.3.2 is a different topic — "Considerations for New Field Names.") [rfc9110]
- FHIR's closed-vs-open-with-escape-hatch pair is §4.1.4.2 Binding Strengths: `required` = "the concept in this element SHALL be from the specified value set"; `extensible` = the same "if any of the codes within the value set can apply to the concept being communicated," otherwise alternate codings or text are allowed. [fhir-binding]
- UK Open Banking defines a namespaced-enumeration extensibility pattern (`UK.OBIE.` prefix; ASPSP-specific values under a two-letter country-code namespace) but **no rule for how a client treats an unrecognized error code**; codes are delegated to the external `OpenBankingUK/External_internal_CodeSets` repo. Do not cite OB for unknown-error-code handling. [rfc9110]

## SOURCES

**rfc7519**
URL: https://www.rfc-editor.org/rfc/rfc7519.txt
Accessed: 2026-09-03
Quote: "However, in the absence of such requirements, all claims that are not understood by implementations MUST be ignored."

**rfc7515**
URL: https://www.rfc-editor.org/rfc/rfc7515.txt
Accessed: 2026-09-03
Quote: "If any of the listed extension Header Parameters are not understood and supported by the recipient, then the JWS is invalid."

**rfc6749**
URL: https://www.rfc-editor.org/rfc/rfc6749.txt
Accessed: 2026-09-03
Quote: "The authorization server MUST ignore unrecognized request parameters."

**oidfed**
URL: https://openid.net/specs/openid-federation-1_0.html
Accessed: 2026-09-03
Quote: "trust_mark_type ... used in Trust Marks to provide the identifier of the type of the Trust Mark. The Trust Mark type identifier MUST be collision-resistant across multiple federations"

**dpv21**
URL: https://w3c-cg.github.io/dpv/2.1/dpv/
Accessed: 2026-09-03
Quote: "The concept StorageCondition and the relation hasStorageCondition represent the general or abstract conditions associated with storage of data. This is specialised to indicate StorageDuration, StorageDeletion, StorageRestoration, and StorageLocation."

**p3p10**
URL: https://www.w3.org/TR/P3P/
Accessed: 2026-09-03
Quote: "Each STATEMENT element that does not include a NON-IDENTIFIABLE element MUST contain a RETENTION element that indicates the kind of retention policy that applies to the data referenced in that statement."

**incremental-authz**
URL: https://datatracker.ietf.org/doc/draft-ietf-oauth-incremental-authz/
Accessed: 2026-09-03
Quote: "This Internet-Draft is no longer active."

**rfc9110**
URL: https://www.rfc-editor.org/rfc/rfc9110.txt
Accessed: 2026-09-03
Quote: "Other recipients SHOULD ignore unrecognized header and trailer fields. Adhering to these requirements allows HTTP's functionality to be extended without updating or removing deployed intermediaries."

**fhir-binding**
URL: https://www.hl7.org/fhir/terminologies.html
Accessed: 2026-09-03
Quote: "To be conformant, the concept in this element SHALL be from the specified value set."

**eba410**
URL: https://www.legislation.gov.uk/eur/2019/410/data.xht?view=snippet&wrap=true
Accessed: 2026-09-03
Quote: "Current authorisation status of the payment institution ... 1. ☐ Authorised 2. ☐ Withdrawn"

## SYNTHESIS

These six errors share a shape worth recognizing: each is a *plausible* citation that a careful
person would produce from memory, and each is wrong in a way that only a primary-source fetch
catches. Four are drift (a spec renamed a term or a draft died); two are section-number confusion
between sibling documents in the same family (RFC 7519/7515, EU 2019/410-411). None would be caught
by a reviewer who trusted the citing author, because the surrounding argument is sound — it is only
the pointer that rots.

Practical rule for future protocol review: when a claim rests on a *named field or section number*
rather than on a concept, fetch the primary text. Concepts are stable; identifiers drift. The highest-risk
categories observed here are (a) IETF drafts, which expire silently while remaining citable-looking
in search results, (b) OpenID Foundation specs, which rename claims between drafts without
redirects, and (c) W3C Community Group work, which is easy to mistake for a Recommendation.

The substantive design conclusion, independent of the citation hygiene: the open-vs-closed
extensibility axis ("descriptive vocabularies open, processing/security selectors closed") is
genuinely well-precedented, and the strongest single citation for it is the RFC 7519 §4 / RFC 7515
§4.1.11 pair — two rules with opposite polarity in the same document family, split on exactly that
axis. FHIR's `required`/`extensible` binding strengths are the second-best, and they usefully supply
the middle option (closed-with-escape-hatch) that the JOSE pair lacks. Use those two; RFC 6749 §3.1
and RFC 9110 §5.1 are supporting rather than load-bearing, and RFC 9110's is only SHOULD-strength.
