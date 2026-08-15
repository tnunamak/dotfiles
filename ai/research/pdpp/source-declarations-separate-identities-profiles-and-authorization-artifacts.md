---
title: "PDPP Source Declarations should separate stable identities, Core conformance, profile extensions, and authorization artifacts"
date: 2026-08-11
topic: pdpp
tags: [source-declaration, profiles, authorization, consent, extensibility]
status: draft
sources: [oauth-resource-identifiers, fhir-capability-identities, fhir-profile-safety, oauth-rar, json-schema-vocabularies, openapi-odata-extensions, vc-consent-artifacts]
source_session: unknown
---

## CLAIMS

- OAuth resource identifiers are absolute URIs that can identify a resource without being its locator, and protected-resource metadata defines a separate human-readable resource name. [oauth-resource-identifiers]
- FHIR CapabilityStatement distinguishes canonical capability identity, business version, software identity, and implementation identity. [fhir-capability-identities]
- FHIR profiling requires that a resource be safe to process without knowledge of a profile, and says profile knowledge must be explicit in the instance rather than implicit in the profile. [fhir-profile-safety]
- OAuth Rich Authorization Requests use the authorization-detail `type` to determine allowable object contents and interpretation; an authorization server must refuse an unknown authorization-detail type. [oauth-rar]
- OAuth Rich Authorization Requests return granted authorization details in the token response and allow an introspection response to expose the token's authorization details; the specification also discusses storing consented authorization details as part of a grant. [oauth-rar]
- JSON Schema declares vocabularies as required or optional, and an implementation that does not recognize a required vocabulary must refuse to process the schema. [json-schema-vocabularies]
- OpenAPI defines a reserved extension pattern for specification extensions, and OData uses qualified annotations and permits forward-compatible clients to ignore unknown terms. [openapi-odata-extensions]
- OAuth defines an authorization grant and access token, but does not define a portable consent receipt; W3C Verifiable Credentials separates issuer, holder, subject, and verifier roles and leaves reliance on claims to verifier policy. [vc-consent-artifacts]

## SOURCES

**oauth-resource-identifiers**
URL: https://www.rfc-editor.org/rfc/rfc8707.html#section-2
Accessed: 2026-08-11

**fhir-capability-identities**
URL: https://hl7.org/fhir/capabilitystatement.html
Accessed: 2026-08-11

**fhir-profile-safety**
URL: https://hl7.org/fhir/R4/profiling.html#5.1.0.5
Accessed: 2026-08-11

**oauth-rar**
URL: https://www.rfc-editor.org/rfc/rfc9396.html
Accessed: 2026-08-11

**json-schema-vocabularies**
URL: https://json-schema.org/draft/2020-12/json-schema-core#section-8.1
Accessed: 2026-08-11

**openapi-odata-extensions**
URL: https://spec.openapis.org/oas/v3.1.0.html#specification-extensions
Accessed: 2026-08-11
Also: https://docs.oasis-open.org/odata/odata-csdl-json/v4.01/cs02/odata-csdl-json-v4.01-cs02.html

**vc-consent-artifacts**
URL: https://www.w3.org/TR/vc-data-model-2.0/#ecosystem-overview
Accessed: 2026-08-11
Also: https://www.rfc-editor.org/rfc/rfc6749.html#section-1.3

## SYNTHESIS

### PDPP v0.1 policy choices

- Use a stable, registry-controlled absolute URI for the logical source or data surface. Keep human labels, provider names, connector identities, software versions, installations, and package or artifact identities in separate fields or records. These are PDPP policy choices informed by the identity separations above, not requirements imposed by one universal standard.
- Keep Core conformance independent from the Collection Profile. A low-complexity v0.1 shape is one Source Declaration with one explicitly namespaced, opaque optional profile subtree. Core must remain valid and implementable after that subtree is removed. Collection support is a separate profile claim.
- Treat RAR as precedent for carrying approved authorization details in token responses and introspection, not as a consent-receipt standard. Keep the grant, the declaration snapshot used during consent, retained consent evidence, and any future portable signed credential as distinct artifacts with distinct purposes.
- Handle unknown additive metadata differently from unknown authorization semantics. Core may ignore an unknown additive profile entry while preserving non-interference. An operation that requires an unknown profile or authorization meaning must fail safely. A generic universal criticality flag is not required for PDPP v0.1; profile-specific processing rules should determine when recognition is necessary.
