---
title: "CFPB 1033.421(f) permits onward transfer with recursive contractual flow-down (so a flat protocol-level prohibition conflicts with US financial-data law), and FHIR Bulk Data is a separate IG with an async protocol shape rather than paginated query"
date: 2026-09-03
topic: protocols
tags: [oauth, onward-transfer, delegation, bulk-export, cfpb-1033, fhir-bulk-data, gnap, smart-on-fhir, pdpp]
status: draft
sources: [rfc9635, rfc8693, rfc6750, rfc6749, cfr1033421, fdx, fhirbulk, fhirbulkexport, smartscopes, fhirprovenance]
source_session: 212f1cf5-e03d-4685-817f-1587df9e8bca
---

## CLAIMS

### Onward transfer / subgrants

- RFC 6750 §5.3 carries the client-side prohibition: "Client implementations MUST ensure that bearer tokens are not leaked to unintended parties, as they will be able to use them to gain access to protected resources." §1.2 defines a bearer token as one where "any party in possession of the token ... can use the token in any way that any other party in possession of it can." [rfc6750]
- RFC 6749 contains **no** explicit client-side MUST-NOT-disclose clause. §1.4 defines the access token as issued to the client, and §10.3 addresses AS/RS duties. Cite RFC 6750 §5.3, not RFC 6749, for "a client must not hand its token to someone else." [rfc6749] [rfc6750]
- RFC 8693 §4.1 standardizes a delegation chain: "A chain of delegation can be expressed by nesting one `act` claim within another. The outermost `act` claim represents the current actor while nested `act` claims represent prior actors." §4.4 `may_act` "makes a statement that one party is authorized to become the actor and act on behalf of another party." So the IETF does define chained delegation — a spec claiming "no delegation construct is needed" is making a scoping choice, not stating an ecosystem consensus. [rfc8693]
- RFC 8693 §1.1 separates delegation from impersonation: under impersonation "A is given all the rights that B has ... and is indistinguishable from B"; under delegation "principal A still has its own identity separate from B, and it is explicitly understood that while B may have delegated some of its rights to A, any actions taken are being taken by A representing B." [rfc8693]
- **12 CFR 1033.421(f) permits onward transfer and governs it rather than prohibiting it**: before providing covered data to another third party, the third party "will require the other third party by contract to comply with the third party obligations in paragraphs (a) through (f)". Because the flow-down includes (f) itself, the obligation recurses down the chain. [cfr1033421]
- 12 CFR 1033.421(c) makes onward transfer a species of "use": "use of covered data ... includes both the third party's own use of covered data and provision of covered data by that third party to other third parties" — so a transfer that is not reasonably necessary is prohibited by the necessity limit regardless of contract terms. [cfr1033421]
- FDX's three-role model (data provider, data recipient, data aggregator) makes the aggregator the onward-transfer node and handles it by certification (§1033.401(c) requires the aggregator to certify to the consumer) rather than by a subgrant construct. FDX 5.0+ added a Consent API for consent traceability across the chain. [fdx]
- GNAP RFC 9635 §1.2 notes an RS "can act as a client instance for a downstream secondary RS in order to fulfill the original request" — chaining as an architectural possibility, not a delegation mechanism in the protocol. [rfc9635]

### GNAP vs OAuth as a foundation

- GNAP RFC 9635 §1 states: "GNAP is not an extension of OAuth 2.0 and is not intended to be directly compatible with OAuth 2.0," and "GNAP seeks to provide functionality and solve use cases that OAuth 2.0 cannot easily or cleanly address." The two "will likely exist in parallel for many deployments." Adopting GNAP is therefore a rewrite of the authorization layer, not a migration. [rfc9635]
- GNAP makes key-binding the **default** rather than an add-on: §2.1.1's bearer flag — "If this flag is omitted, the access token is bound to the key used by the client instance in this request." §11.10 is "Key-Bound Access Tokens." This is the strongest argument against an OAuth-bearer foundation for standing personal-data access; DPoP (RFC 9449) is the OAuth-native answer. [rfc9635]

### Bulk export as a distinct access path

- FHIR Bulk Data Access is a **separate Implementation Guide** (v3.0.0, STU 3 on FHIR R4), not part of FHIR core, and defines `$export` at system, `Patient/`, and `Group/[id]/` levels. [fhirbulk] [fhirbulkexport]
- Bulk export differs from paginated search in **protocol shape**, not merely convenience: kick-off requires `Prefer: respond-async` (per RFC 7240), the server returns 202 Accepted with a `Content-Location` status URL that "is not necessarily a FHIR endpoint, and is not a true FHIR resource," the client polls that URL, and completion returns a JSON manifest with `output`/`error` arrays plus `requiresAccessToken`. Files are NDJSON (`application/fhir+ndjson`), each containing exactly one resource type, and may be served by a separate Output File Server. Cleanup is DELETE on the status URL. [fhirbulkexport]
- The IG splits four roles — FHIR Authorization Server, FHIR Resource Server, Output File Server, Bulk Data Client — which is why bulk export does not fold into a query endpoint. [fhirbulkexport]

### Sector-regime layering

- SMART on FHIR states that granted scopes are ceilinged by the layer beneath: "such rights are always limited by underlying system policies and permissions," and requests "may be rejected, or results may be omitted from responses" depending on the permissions of the approving user. This is the health ecosystem's own statement of floor-not-ceiling, and supports a non-interference claim (the protocol does not weaken the regime) rather than an enforcement claim (the protocol upholds it). [smartscopes]

### Provenance placement

- FHIR puts authorship in a **separate `Provenance` resource** that references the target, with a typed `Provenance.agent`, rather than in the resource being described. Precedent that "was this authored by software or a person" belongs in an adjacent, addable class, not in the record envelope. [fhirprovenance]

## SOURCES

**rfc9635**
URL: https://www.rfc-editor.org/rfc/rfc9635.txt
Accessed: 2026-09-03
Quote: "GNAP is not an extension of OAuth 2.0 and is not intended to be directly compatible with OAuth 2.0."

**rfc8693**
URL: https://www.rfc-editor.org/rfc/rfc8693.txt
Accessed: 2026-09-03
Quote: "A chain of delegation can be expressed by nesting one 'act' claim within another. The outermost 'act' claim represents the current actor while nested 'act' claims represent prior actors."

**rfc6750**
URL: https://www.rfc-editor.org/rfc/rfc6750.txt
Accessed: 2026-09-03
Quote: "Client implementations MUST ensure that bearer tokens are not leaked to unintended parties, as they will be able to use them to gain access to protected resources."

**rfc6749**
URL: https://www.rfc-editor.org/rfc/rfc6749.txt
Accessed: 2026-09-03
Quote: "Access tokens are credentials used to access protected resources. An access token is a string representing an authorization issued to the client." (§1.4; no client-side non-disclosure MUST NOT appears in §10.3)

**cfr1033421**
URL: https://www.law.cornell.edu/cfr/text/12/1033.421
Accessed: 2026-09-03
Quote: "Use of covered data for purposes of paragraph (a) of this section includes both the third party's own use of covered data and provision of covered data by that third party to other third parties."

**fdx**
URL: https://financialdataexchange.org/fdx-feed/financial-data-exchange-fdx-releases-fdx-api-5-0/
Accessed: 2026-09-03
Quote: "standardize user consent throughout the data sharing process" via a Consent API allowing consent traceability across entities.

**fhirbulk**
URL: https://hl7.org/fhir/uv/bulkdata/
Accessed: 2026-09-03
Quote: "FHIR Bulk Data Access (Flat FHIR)" — published as a separate Implementation Guide, v3.0.0, STU 3 based on FHIR R4.

**fhirbulkexport**
URL: http://build.fhir.org/ig/HL7/bulk-data/en/export.html
Accessed: 2026-09-03
Quote: "the server returns HTTP status code 202 Accepted with a Content-Location header containing an absolute URI for subsequent status requests"; the status URL "is not necessarily a FHIR endpoint, and is not a true FHIR resource."

**smartscopes**
URL: https://hl7.org/fhir/smart-app-launch/scopes-and-launch-context.html
Accessed: 2026-09-03
Quote: "such rights are always limited by underlying system policies and permissions"

**fhirprovenance**
URL: https://hl7.org/fhir/provenance.html
Accessed: 2026-09-03
Quote: Provenance is a distinct resource referencing the target resource, with a typed `agent` element, rather than provenance fields on the target itself.

## SYNTHESIS

Two of these findings cut against positions that feel obviously right.

First, "a client must not pass its access to anyone else" reads as a security truism, and RFC 6750
§5.3 does back the narrow token-transfer form of it. But the broader claim — that no delegation or
onward-transfer construct is *needed* — is contradicted by the nearest regulated analogue. CFPB 1033
looked at the same problem in consumer financial data and concluded that onward transfer must be
governed (necessity limit, recursive contractual flow-down, revocation propagation, prohibited
secondary uses) rather than banned, because the aggregator pattern exists whether or not a protocol
blesses it. A protocol that prohibits what a binding regulation permits and regulates should say it
is scoping, not say the need does not exist.

Second, the intuition that bulk export is "just pagination run to the end" does not survive contact
with the one ecosystem that shipped it at scale. FHIR needed an async kick-off, an out-of-band status
resource that is deliberately not a FHIR resource, a manifest, a distinct content type, and often a
separate file server. That is a different protocol, and it landed in a separate IG. Anyone deciding
whether bulk export belongs in a core spec should treat "separate companion profile" as the
precedented answer and "fold into the query surface" as the novel one.

The GNAP finding is the reverse — it makes the conservative choice easier to defend. Because RFC 9635
§1 disclaims OAuth compatibility outright, "evaluate GNAP later" is the only coherent posture; there
is no incremental migration to plan for. The part worth taking seriously is not the framework
question but the default: GNAP binds tokens to keys unless told otherwise, and DPoP is how an
OAuth-based spec gets the same property without the rewrite.
