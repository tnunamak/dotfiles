---
title: "OIDC/UK-OpenBanking/FHIR/JSON:API converge on optional-absent (not required-nullable) for 'no expiry'; pagination limits are server-advertised not spec-fixed; RFC/FHIR prose does not caption JSON examples as numbered figures"
date: 2026-08-19
topic: api-contract-design
tags: [json-schema, oauth, oidc, open-banking, fhir, json-api, pagination, spec-editorial, nullability]
status: draft
sources:
  - https://openid.net/specs/openid-connect-core-1_0.html
  - https://openbankinguk.github.io/read-write-api-site3/v4.0/resources-and-data-models/aisp/account-access-consents.html
  - https://jsonapi.org/format/
  - https://build.fhir.org/datatypes.html
  - https://build.fhir.org/search.html
  - https://build.fhir.org/http.html
  - https://www.rfc-editor.org/rfc/rfc7322
  - https://hl7.org/fhir/smart-app-launch/scopes-and-launch-context.html
source_session: 8b2c8ac0-a286-48e1-b140-253d6b93668c
---

## CLAIMS

- OpenID Connect Core makes the ID Token `exp` claim REQUIRED — a JSON number (NumericDate), never absent and never `null`. There is no "no expiry" state for `exp`; OIDC tokens always expire. [oidc-core]
- UK Open Banking's `account-access-consents` `ExpirationDateTime` field has cardinality `0..1` (optional/absent), both on the request object (`OBReadConsent1`) and the response object (`OBReadConsentResponse1`). The spec text states: "If this is not populated, the permissions will be open ended." — absence, not `null`, is the "no expiry" encoding. [ob-consent]
- JSON:API's document-structure spec does not define a dedicated "field-is-optional vs field-is-null" convention section; its governing rule is additive-evolution via omission (unknown/absent members are ignored, not required-with-null-default) and `null` is reserved for primary `data` specifically meaning "no matching resource," not a general absent-value marker on attributes. [jsonapi-doc]
- FHIR's primitive-type model treats every element as cardinality-bound (e.g. `0..1`, `1..1`); an optional element that has no value is simply omitted from the resource — FHIR does not use a `null` value in JSON at the primitive-value level for "no value," it omits the field (and can carry a matching `_field` sibling for extensions/id on a null primitive in edge cases, but plain omission is the default "no value" story). [fhir-datatypes]
- FHIR's search/paging model (`_count` in `http.html`/`search.html`) is entirely server-discretionary: "Servers SHALL NOT return more resources in a single page than requested... but MAY return less." No spec-fixed default or maximum page size is defined anywhere in core FHIR; page-size behavior is left to server policy, and continuation is via server-controlled opaque links, not a client-computed formula. [fhir-paging] [fhir-count]
- UK Open Banking analogously does not fix a spec-mandated numeric page-size default/max in the core Read/Write API spec body; pagination there is likewise handled via `Meta`/`Links` (`Self`/`First`/`Next`/`Last`) with server-determined page composition (not independently re-verified with a primary numeric citation in this pass — treat as directionally consistent with the FHIR pattern, lower confidence). [ob-general]
- RFC 7322 (RFC Style Guide) governs document structure (headers, title, abbreviations, references, Author's Address) and contains no section mandating numbered "Figure N" captions or a "non-normative example" label convention for inline JSON/code artwork; RFC body text conventionally introduces code/artwork with plain prose ("as follows:", "for example:") and no caption requirement is present in 7322 itself. [rfc7322]
- OIDC Core's own JSON example in the ID Token section is introduced with the bare prose lead-in "The following is a non-normative example of the set of Claims (the JWT Claims Set) in an ID Token:" — i.e., OIDC uses a prose sentence labeling the block as non-normative, not a numbered/captioned figure. [oidc-core]
- SMART on FHIR's scopes documentation (`scopes-and-launch-context.html`) presents its scope table as a plain two-column table (`Scope` | `Grants`) with no separate "defined by base OAuth vs SMART extension" provenance column; base-vs-extension distinction is carried in prose/section structure, not a dedicated table column. [smart-scopes]

## SOURCES

**oidc-core**
URL: https://openid.net/specs/openid-connect-core-1_0.html
Accessed: 2026-08-19
Quote: "exp — REQUIRED. Expiration time on or after which the ID Token MUST NOT be accepted... Its value is a JSON number representing the number of seconds from 1970-01-01T00:00:00Z..." / "The following is a non-normative example of the set of Claims (the JWT Claims Set) in an ID Token:"

**ob-consent**
URL: https://openbankinguk.github.io/read-write-api-site3/v4.0/resources-and-data-models/aisp/account-access-consents.html
Accessed: 2026-08-19
Quote: "ExpirationDateTime | 0..1 | OBReadConsent1/Data/ExpirationDateTime | Specified date and time the permissions will expire. If this is not populated, the permissions will be open ended. | ISODateTime"

**jsonapi-doc**
URL: https://jsonapi.org/format/
Accessed: 2026-08-19
Quote: "Unless otherwise noted, objects defined by this specification or any applied extensions MUST NOT contain any additional members. Client and server implementations MUST ignore non-compliant members." (Document Structure §); primary data "MUST be either: a single resource object... or null, for requests that target single resources"

**fhir-datatypes**
URL: https://build.fhir.org/datatypes.html
Accessed: 2026-08-19
Quote: "Primitive types are those that specialize PrimitiveType, with a value, and no additional elements as children (though, like all types, they have `id` and extensions)."

**fhir-paging**
URL: https://build.fhir.org/http.html
Accessed: 2026-08-19
Quote: "Servers SHOULD support paging for the results of a search or history interaction... The links in the search are opaque to the client, have no dictated structure, and only the server understands them."

**fhir-count**
URL: https://build.fhir.org/search.html
Accessed: 2026-08-19
Quote: "The parameter `_count` is defined as an instruction to the server regarding the maximum number of resources that can be returned in a single page. Servers SHALL NOT return more resources in a single page than requested, even if they don't support paging, but MAY return less than the client requested."

**rfc7322**
URL: https://www.rfc-editor.org/rfc/rfc7322
Accessed: 2026-08-19
Quote: "4. Structure of an RFC — A published RFC will largely contain the elements in the following list..." (no Figures/Artwork captioning section present in the document body)

**smart-scopes**
URL: https://hl7.org/fhir/smart-app-launch/scopes-and-launch-context.html
Accessed: 2026-08-19
Quote: "Here is a quick overview of the most commonly used scopes... | Scope | Grants |"

**ob-general**
URL: https://openbankinguk.github.io/read-write-api-site3/v4.0/profiles/read-write-data-api-profile.html
Accessed: 2026-08-19 (not independently re-fetched in this pass; carried from prior search context — lower confidence)

## SYNTHESIS

Dominant practice across OIDC/FHIR/Open Banking is **optional-absent** for "no expiry / no value," not "required field that can be null." OIDC makes `exp` required only because OIDC tokens are *designed to always expire* (no "no expiry" state exists at all) — that's a different domain shape than PDPP's grant, which genuinely supports non-expiring continuous access. UK Open Banking is the closest analog to PDPP's grant (a consent artifact with an optional expiry) and it lands on `0..1` optional-absent, with the spec prose explicitly stating that absence means open-ended. FHIR's whole primitive-type model treats "no value" as an omitted element, not a null value, reinforcing the same convention. JSON:API reserves `null` for a narrower, structurally distinct meaning (the primary-data slot pointing at nothing) rather than as a general-purpose "field present but empty" marker on ordinary attributes.

On pagination, both FHIR and (directionally) Open Banking refuse to hardcode numeric defaults/maxima in the spec text itself — they push the number to server policy and surface it operationally (continuation links, `_count` semantics) rather than a spec-mandated ceiling. A spec-fixed default/max (like PDPP's 25/100) is more prescriptive than the FHIR/OB norm, though not unprecedented — it trades server flexibility for interoperability predictability, which is a legitimate but more opinionated design choice than what these two reference standards make.

On example/figure conventions: RFC 7322 and OIDC Core show that IETF/OpenID-family specs use plain prose lead-ins (often literally "non-normative example") rather than numbered/captioned figures — PDPP's bare "Example:" lead-in is squarely within that convention, not against it. FHIR's ecosystem is more visually structured (dedicated "Examples" pages, tabs) but even there JSON snippets in body text aren't individually numbered-captioned the way an ISO/engineering document would do it.

On provenance columns: SMART's scope tables don't carry a "which base spec this came from" column — that distinction lives in prose. This is weak evidence that PDPP's field-table "Status" column (Protocol-enforced / Structured policy declaration / Identity binding / etc.) is already more disciplined than typical practice, though it answers a different question (semantic class, not RFC-of-origin) than a literal "sourced from RFC 7662 vs 9396 vs this spec" column would.
