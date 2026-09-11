---
title: "DPV 2.3 DOES list the IEEE 7012 extension and RFC 9396 §5 constrains only the request side — two same-day corrections that each reversed a spec recommendation, plus the finding that no deployed OAuth system carries a terms artifact in a grant"
date: 2026-09-03
topic: protocols
tags: [dpv, ieee-7012, myterms, rfc-9396, rfc-7662, rfc-9068, oauth, uma, consent, iso-27560, kantara, pdpp, verification]
status: draft
sources: [dpv-23, ieee-7012-page, ieee-xplore-7012, cc-agreements, cc-p2b1, iso-obp-27560, kantara-ancr, keycloak-uma, pingam-uma, rfc9396, rfc9068, rfc7662, pdpp-pr-317, pdpp-spec-core]
source_session: da53c1ca-0fcc-46b4-9b1a-3e44d3b7159c
---

<!--
Produced during an owner-commissioned deep survey of user-side terms in
personal-data exchange. Two claims made the same morning by a prior-art report
were load-bearing for its recommendation; both were checked here and both
failed. The durable value is the two corrections and the verification method,
not the survey.
-->

## CLAIMS

### The two corrections

- The current DPV release is **2.3, dated 25 February 2026**, and its STANDARDS extension family **does** include the IEEE 7012 extension. Verbatim: "The STANDARDS extensions model the core terminologies defined and used within specific forums such as ISO, CEN/CENELEC, NIST, and IEEE so that they can be used with DPV. Currently it provides the extension [STANDARD-IEEE-7012] to support the implementation of IEEE 7012-2025: Standard for Machine Readable Personal Privacy Terms." [dpv-23]
- A same-day report claimed the DPV P7012 extension was "stranded at v2.1 (Mar 2025)" and "absent from DPV 2.3's specification list," and treated that absence as an adoption signal weakening the case for citing DPV as a future mapping target. **That claim is false.** `https://w3id.org/dpv/` redirects to the live DPV 2.3 page carrying the extension. [dpv-23]
- The extension *artifact* does carry its own drafting caveat — its status page describes it as "currently in draft form, and may undergo major changes." That caveat is about the extension document, not about whether DPV 2.3 lists it. Both facts must be stated together; stating either alone misleads. [dpv-23]
- **RFC 9396 §5's unknown-fields rejection rule governs only what a client sends in an authorization request.** Verbatim §5: "The AS MUST refuse to process any unknown authorization details type or authorization details not conforming to the respective type definition. The AS MUST abort processing and respond with an error invalid_authorization_details to the client if any of the following are true of the objects in the authorization_details structure: * contains an unknown authorization details type value, * is an object of known type but containing unknown fields, ..." The subject is the `authorization_details` structure in the client's request. [rfc9396]
- RFC 9396 **§14.3** registers `authorization_details` as a member of the RFC 7662 token introspection *response*, describing its contents as "the rights of the access token." Verbatim: "The member authorization_details contains a JSON array of JSON objects representing the rights of the access token." So the response side already has registered room for structured per-grant data, and §5 imposes no constraint on it. [rfc9396]
- Therefore: a same-day report's argument that §5 makes deferring a **grant-side** optional field costly does not follow. §5 is a real and sharp constraint on any future **client-side** terms field — such a field must be in the type definition to be legal on the wire, so it can never be introduced as an additive change — and it is silent about grant-side and introspection-side fields. [rfc9396]
- RFC 9396 §6.1: "Since the semantics of the fields in the authorization_details will be implementation specific to a given API or set of APIs, there is no standardized mechanism to compare two arbitrary authorization detail requests." This is a second, independent reason to keep terms off the request side. [rfc9396]

### Absence findings (each a negative from targeted search, not an exhaustive audit)

- **No deployed OAuth-family system was found carrying a policy, terms, or data-handling-commitment artifact inside an issued grant or a token introspection response.** RFC 9068 (JWT access tokens) defines only authorization/identity claims (`iss, exp, aud, sub, client_id, iat, jti, auth_time, acr, amr, scope, groups, roles, entitlements`) and states "This profile does not introduce any mechanism for a client to directly request the presence of specific claims in JWT access tokens." RFC 7662's response members are likewise authorization-only. The closest analogue anywhere is RFC 7591 `policy_uri`/`tos_uri`, which live on the **client**, not on the grant. [rfc9068] [rfc7662]
- **Zero implementers of Customer Commons' P2B1 were found** by targeted search (site, app, demo, library, or repository). The only string matches were unrelated collisions. [cc-p2b1]
- The Customer Commons roster carries **three** named terms as of 2026-09-03: #NoStalking, P2B1 v0.9, and SD-BY-AT v0.9. The P2B1 v0.9 page itself flags that it is superseded and recommends "Your Agreements Matter – Version 1.0" instead. No governance or submission process for adding a term to the roster was described on the fetched pages. [cc-agreements] [cc-p2b1]

### Status corrections worth carrying

- **UMA 2.0 is not deprecated.** Keycloak documents itself as "a UMA 2.0 compliant authorization server that provides most UMA capabilities" with an active Protection API, and a 2026 CVE fix against `UserManagedPermissionService (UMA Protection API)` shows continued maintenance. PingAM states it "supports the User-Managed Access (UMA) 2.0 Grant." What Keycloak deprecated in 2026 was unrelated (Fine-Grained Admin Permissions v1; Identity Brokering API v1). [keycloak-uma] [pingam-uma]
- No large-scale, publicized production UMA case study surfaced beyond vendor documentation and how-to posts. The accurate characterisation is **supported but niche, and enterprise-only** — the "user-managed access" idea was realised in enterprise API authorization, never in a consumer-facing data-control product. [keycloak-uma] [pingam-uma]
- **Kantara's ANCR work group has published no ratified schema.** The most recent artifacts found are ANCR Notice Record v0.8.9 (a wiki page) and a Transparency Performance Reporting document that entered a 45-day Draft Recommendation review opening 2025-03-21. No "Consent Receipt v2" or final notice-record schema exists. [kantara-ancr]
- IEEE 7012-2025 is an **Active Standard**, published 2026-01-20, ~50 pages. [ieee-7012-page]

### Could not verify

- **IEEE 7012-2025's normative text.** IEEE Xplore (document 11360682) did not return fetchable content; the GET-program path did not yield a PDF. The widely quoted "the chosen contract or agreement shall be signed electronically by both parties or their agents, and a matching record shall be kept by both sides in a form that can be retrieved, audited, or disputed" is consistent across multiple independent secondary sources and reads as scope/abstract language, but **it was not confirmed against the normative body.** Do not make a conformance claim on it. [ieee-xplore-7012] [ieee-7012-page]
- **ISO/IEC TS 27560:2023 clause-level content.** The ISO Online Browsing Platform preview returned **HTTP 403**; no free national-adoption preview (INCITS/ANSI/DS) was located. Everything mapped about 27560 remains read through W3C DPV's published mapping guide, not the ISO document. [iso-obp-27560]

### The PDPP facts these corrections bear on

- PDPP's grant carries exactly **two** recipient-side commitment fields today: `retention.max_duration` and `retention.on_expiry` (`delete` | `anonymize`; `archive` unsupported in v0.1), both classed "Structured policy declaration." [pdpp-spec-core]
- PDPP `spec-core.md` §7 states the enforcement position verbatim: "PDPP does not technically enforce retention. Enforcement is through legal agreements or contractual obligations ... the protocol makes the commitment legible and machine-readable; external mechanisms enforce it." [pdpp-spec-core]
- PDPP already has a class for un-adjudicable free text, in the client direction: `client_claims.commitments` is "self-asserted and unverifiable by the server," MUST be rendered separately with client attribution, and "remain[s] outside authorization equality, the resolved grant, introspection rights, and RS enforcement." [pdpp-spec-core]
- `grant.version` is pinned to exactly `0.1.0` and the RS MUST reject grants with unsupported major versions (400 `unsupported_version`). `GrantSchema` and `ClientDisplaySchema` in `packages/reference-contract/src/public/index.ts` both set `additionalProperties: false`. Together these are the actual cost of deferring a grant-side optional field — not RFC 9396 §5. [pdpp-spec-core]
- PDP-Connect PR #317 was **open and unmerged** as of 2026-09-03, and its own text contains a self-correction of the DPV error: the extension "is **live**, shipping in DPV 2.3 as `STANDARD-IEEE-7012`; I verified this against the specification directly, because an earlier draft of this work described that extension as stranded at an old version, and that was wrong." [pdpp-pr-317]

## SOURCES

**dpv-23**
URL: https://w3id.org/dpv/ → https://w3c-cg.github.io/dpv/2.3/dpv
Accessed: 2026-09-03
Quote: "The STANDARDS extensions model the core terminologies defined and used within specific forums such as ISO, CEN/CENELEC, NIST, and IEEE so that they can be used with DPV. Currently it provides the extension [STANDARD-IEEE-7012] to support the implementation of [IEEE 7012-2025: Standard for Machine Readable Personal Privacy Terms]." Version 2.3, dated 25 February 2026.

**ieee-7012-page**
URL: https://standards.ieee.org/ieee/7012/7192/
Accessed: 2026-09-03
Quote: Status "Active Standard," publication date "2026-01-20."

**ieee-xplore-7012**
URL: IEEE Xplore document 11360682, "7012-2025 - IEEE Standard for Machine Readable Personal Privacy Terms"
Accessed: 2026-09-03
Quote: Fetch returned no content (JS-gated / paywalled). Normative body NOT obtained.

**cc-agreements**
URL: https://customercommons.org/agreements/
Accessed: 2026-09-03
Quote: Lists #NoStalking, P2B1 v0.9, SD-BY-AT v0.9. No submission or vetting process described.

**cc-p2b1**
URL: https://customercommons.org/agreements/p2b1/0.9/
Accessed: 2026-09-03
Quote: The page flags v0.9 as an older version and recommends "Your Agreements Matter – Version 1.0" instead. Targeted search for implementers returned zero matches.

**iso-obp-27560**
URL: https://www.iso.org/obp/ui/#iso:std:iso-iec:ts:27560:ed-1:v1:en
Accessed: 2026-09-03
Quote: HTTP 403 Forbidden. No free Terms & Definitions content obtained.

**kantara-ancr**
URL: https://kantarainitiative.org/work-groups/ancr/ ; https://kantara.atlassian.net/wiki/spaces/WA/pages/42008577
Accessed: 2026-09-03
Quote: Charter mission is to "address technical gaps... to update version 1.1 of the Consent Receipt Specification." Latest artifacts: ANCR Notice Record v0.8.9; a Transparency Performance Reporting document in 45-day Draft Recommendation review from 2025-03-21.

**keycloak-uma**
URL: Red Hat build of Keycloak Authorization Services Guide (26.0)
Accessed: 2026-09-03
Quote: "Red Hat build of Keycloak is a UMA 2.0 compliant authorization server that provides most UMA capabilities." CVE-2025-14778 patched against `UserManagedPermissionService (UMA Protection API)` in 2026.

**pingam-uma**
URL: https://docs.pingidentity.com/pingam/8/uma/preface.html
Accessed: 2026-09-03
Quote: "PingAM supports the User-Managed Access (UMA) 2.0 Grant for OAuth 2.0 Authorization and Federated Authorization for User-Managed Access (UMA) 2.0." No deprecation notice found.

**rfc9396**
URL: https://www.rfc-editor.org/rfc/rfc9396.txt (fetched and grepped directly)
Accessed: 2026-09-03
Quote: §5 — "The AS MUST refuse to process any unknown authorization details type or authorization details not conforming to the respective type definition. The AS MUST abort processing and respond with an error invalid_authorization_details to the client if any of the following are true of the objects in the authorization_details structure: * contains an unknown authorization details type value, * is an object of known type but containing unknown fields, ..." §6.1 — "there is no standardized mechanism to compare two arbitrary authorization detail requests." §14.3 — "The member authorization_details contains a JSON array of JSON objects representing the rights of the access token."

**rfc9068**
URL: https://www.rfc-editor.org/rfc/rfc9068
Accessed: 2026-09-03
Quote: "This profile does not introduce any mechanism for a client to directly request the presence of specific claims in JWT access tokens." No policy/terms/retention claim defined.

**rfc7662**
URL: https://www.rfc-editor.org/rfc/rfc7662
Accessed: 2026-09-03
Quote: Response members are `active, scope, client_id, username, token_type, exp, iat, nbf, sub, aud, iss, jti`. No policy or terms member.

**pdpp-pr-317**
URL: PDP-Connect PR #317 (`gh pr view 317` — state OPEN, mergedAt null)
Accessed: 2026-09-03
Quote: "Its extension for IEEE 7012 is live, shipping in DPV 2.3 as `STANDARD-IEEE-7012`; I verified this against the specification directly, because an earlier draft of this work described that extension as stranded at an old version, and that was wrong."

**pdpp-spec-core**
URL: `git show origin/main:spec-core.md` (PDPP repo), Sections 6, 7, 9
Accessed: 2026-09-03
Quote: §7 Retention — "PDPP does not technically enforce retention. Enforcement is through legal agreements or contractual obligations... the protocol makes the commitment legible and machine-readable; external mechanisms enforce it." §6 Client claims — "Client claims are self-asserted and unverifiable by the server... They remain outside authorization equality, the resolved grant, introspection rights, and RS enforcement." §7 Version layering — "RS MUST reject grants with unsupported major versions, returning 400 `unsupported_version`."

## SYNTHESIS

Two errors, made the same morning by a careful report, each of which flipped a recommendation. Both share a failure mode worth naming: **a claim about a document's *status* was inferred from a stale copy or from a plausible reading, and then load-bearing weight was hung on it.**

The DPV error is the cleaner one. "Extension X is absent from the current spec list" is a claim you can only make by fetching the current spec list. The report had read the 2.1 extension page — which is real, and dated March 2025 — and inferred stranding from the version gap. But an extension's own version number moving more slowly than the core spec's is normal, not evidence of abandonment; the only dispositive check is the current index, and it takes one fetch. **When a research claim is of the form "this is no longer listed / no longer maintained / has been dropped," fetch the index that would list it, not the artifact.** Absence claims need the container, not the contents.

The RFC 9396 error is subtler and more instructive, because the *quote* was right and the *scoping* was wrong. §5 says the AS must reject an object of known type carrying unknown fields — a genuinely unusual, fail-closed rule that inverts the usual "ignore unknown members" convention, and worth knowing. But it governs the `authorization_details` structure **in the client's request**. The report generalised it into a claim about extending the protocol at all, and used it to argue that deferring a grant-side field was expensive. The correction does not weaken the underlying insight; it sharpens where it bites: **a future client-side terms field is genuinely all-or-nothing and must be designed into the type before anything ships, while grant-side and introspection-side fields remain ordinary optional additions.** §14.3 makes the latter explicit by registering `authorization_details` in the introspection response. Read the subject of the sentence, not just the rule.

Two habits follow. First, when a section number is doing decisive work in an argument, grep the RFC text file rather than trusting a fetch summary — the same failure mode a prior corpus entry recorded about stale section numbers, and it recurred here. Second, and more general: **a report's own recommendation is the place to look for its most-motivated reasoning.** Both errors ran in the direction of the report's conclusion. Neither was sloppy in isolation; both were unchecked because they were convenient.

The absence findings are worth keeping for their own sake, because they are hard to establish and easy to assume away. Nobody ships a terms artifact inside an OAuth grant. Nobody implements P2B1. Kantara's ANCR has no ratified schema after years. UMA is alive but only in enterprise IAM, never where its name suggests. Each of these is the kind of thing a design document will assert optimistically unless someone has actually looked; each was looked for here and not found. Record negative results with the same care as positive ones — and label them honestly as negatives from targeted search rather than exhaustive audits, because that is what they are.
