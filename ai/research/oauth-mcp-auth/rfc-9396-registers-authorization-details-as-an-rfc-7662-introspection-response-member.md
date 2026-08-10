---
title: "RFC 9396 §9.2/§14.3 already standardizes and IANA-registers authorization_details as an RFC 7662 token-introspection response member, so RAR-based systems that carry approved authorization details from AS to RS do not need a proprietary extension"
date: 2026-08-04
topic: oauth-mcp-auth
tags: [oauth, rar, rfc-9396, rfc-7662, token-introspection, authorization-server, resource-server]
status: draft
sources: [rfc-9396]
source_session: 2aa592b5-aaa6-4714-95d6-21e0b48abf6b
---

## CLAIMS
- RFC 9396 §9.2 ("Token Introspection") requires that when an authorization server includes authorization-detail information in an RFC 7662 introspection response, it MUST be conveyed with a top-level `authorization_details` member (potentially filtered and extended for the specific resource server). [rfc-9396]
- RFC 9396 §14.3 IANA-registers `authorization_details` in the OAuth Token Introspection Response registry, making it a standardized (not proprietary) introspection field. [rfc-9396]
- Consequence: in a separated authorization-server / resource-server topology using RAR, the approved authorization details can be carried from AS to RS over standard RFC 7662 introspection with no custom extension — off-the-shelf RAR-capable ASs already emit this member. [rfc-9396]
- Boundary: §9.2 carries only the approved authorization *details*. It does NOT carry a full grant object (grant state, digest, consent evidence, supersession, cache bounds). A design that needs the complete grant at the RS still needs its own supplementary member for those non-RAR fields. [rfc-9396]

## SOURCES
**rfc-9396**
URL: https://www.rfc-editor.org/rfc/rfc9396
Accessed: 2026-08-04
Quote: "§9.2 Token Introspection — when an authorization server includes authorization detail information in a token introspection response, it MUST be conveyed with `authorization_details` as a top-level member." (§14.3 registers `authorization_details` in the OAuth Token Introspection Response registry.)

## SYNTHESIS
When designing an OAuth/RAR authorization protocol with a separated AS and RS, the "how does the RS learn the approved authorization details" question has a standards answer already: RFC 7662 introspection with the RFC-9396-registered `authorization_details` member. This matters two ways for design and for spec review: (1) don't reinvent this member as a proprietary field — a reviewer checking the IANA registry will flag it, and you lose the interop lever that RAR-capable ASs emit it for free; (2) it only partially closes the "complete grant at the RS" gap — anything beyond the approved authorization details (immutable grant id/digest, consent-evidence pointer, grant lifecycle state, supersession, positive-status cache bound) is legitimately your own supplementary extension, because RFC 9396 does not define those. Surfaced while red-teaming a PDPP authorization-architecture decision that framed the AS→RS grant transport as needing PDPP-proprietary introspection extensions; the standardized member covers the RAR half and narrows the genuinely-custom surface to the non-RAR grant metadata.
