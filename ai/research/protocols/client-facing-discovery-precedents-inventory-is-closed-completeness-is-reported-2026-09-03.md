---
title: "Client-facing discovery splits three ways in prior art: per-user inventory is universally closed (SMART, RFC 7662, RFC 9396), result-completeness is reported to the consumer (FHIR Bulk `outcome`, Plaid, Graph 410), and out-of-scope field evolution is silent (Graph `$select` delta) — with MCP `listChanged` the one deliberate counterexample"
date: 2026-09-03
topic: protocols
tags: [oauth, discovery, capability-negotiation, privacy, smart-on-fhir, mcp, graph-delta, fhir-bulk-data, webdav-sync, pdpp]
status: draft
sources: [rfc9396, rfc7662, rfc9728, oidcdiscovery, smartscopes, mcptools, graphdelta, rfc6578, fhirbulkexport, rfc8126]
source_session: 9d4e0032-f47f-4147-8bf7-fae87a03b7fa
---

## CLAIMS

### Per-user inventory: nobody exposes it

- SMART on FHIR defines **no mechanism** for a client to discover which resource types or data a specific patient has, before or after authorization. A wildcard scope is "asking for all data for all available FHIR resources, both now and in the future," and the guidance is that clients "should examine the granted scopes by the authorization server and respond accordingly." The client is never told what exists — only what it got. [smartscopes]
- RFC 9396 §7: "the AS MUST also return the `authorization_details` as granted by the resource owner and assigned to the respective access token," and "The AS MAY omit values in the `authorization_details` to the client." §13: the AS "should share this data with those parties on a 'need to know' basis as determined by local policy." The disclosure is of the *grant*, never of the candidate set. [rfc9396]
- RFC 7662 makes non-existence and non-authorization deliberately indistinguishable: §2.2 an inactive token returns `active: false` and the AS "SHOULD NOT include any additional information about an inactive token, including why the token is inactive"; §4 gives the reason — "To avoid disclosing the internal state of the authorization server." §5: "Omitting privacy-sensitive information from an introspection response is the simplest way of minimizing privacy issues." [rfc7662]
- RFC 6578 §3.5.2 conflates deletion with access loss on purpose: a member "MAY be reported as removed if the user issuing the request no longer has access to this member, due to access control changes," surfaced as `404 Not Found`. The client cannot distinguish the two. Its security section claims the extension "does not introduce any new security concerns beyond those already described in HTTP and WebDAV" — i.e. the disclosure question is left unanalysed, so this is weak authority despite the convenient behaviour. [rfc6578]
- OIDC Discovery and RFC 9728 are both **server-level** capability documents, never per-user. `claims_supported` is the claims the OP "MAY be able to supply values for. Note that for privacy or other reasons, this might not be an exhaustive list." RFC 9728 §2 lists `scopes_supported` / `bearer_methods_supported` / `authorization_servers`; §7.5 warns "Publishing information about the protected resource in a standard format makes it easier for both legitimate clients and attackers to use the protected resource." [oidcdiscovery] [rfc9728]
- The one real counterexample is Solid, where container listing is itself a granted right — but the authorization unit *is* the container, so listing is the grant rather than a precursor to it. Not evidence that pre-consent inventory is safe.

### Out-of-scope field evolution: silent, by design

- Microsoft Graph delta with `$select` is the closest operating analogue to a frozen field set: "If a change occurs to a property that isn't selected, the resource for which that property changed doesn't appear in the delta response after a subsequent request." Unselected fields are **invisible to change tracking**, not merely unreadable. [graphdelta]
- Graph delta also does not support `$expand` for users and groups at all, and `$top`/`$orderby` are unsupported there — a reminder that large-scale delta surfaces shed relational features rather than solve cross-resource authorization. [graphdelta]
- MCP is the deliberate counterexample and the one worth arguing with: "Servers that support tools **MUST** declare the `tools` capability" with a `listChanged` flag, and "When the list of available tools changes, servers that declared the `listChanged` capability **SHOULD** send a notification" (`notifications/tools/list_changed`). The agent-native protocol makes surface-change notification first-class. Weakened as a privacy precedent because an MCP tool list is server capability with no per-user content. [mcptools]

### Result completeness: reported to the consumer, not just the subject

- FHIR Bulk Data is the strongest citation for telling the *requesting party* about partial results: "Even if some of the requested resources cannot successfully be exported, the overall export operation MAY still succeed. In this case, the `Response.outcome` array of the completion response body SHALL be populated with one or more files in NDJSON format containing FHIR `OperationOutcome` resources to indicate what went wrong." Note the array is `outcome`, **not** `error` — a commonly mis-cited name. Also carries a separate `deleted` array, and "Resources that appear in `deleted` SHALL NOT also appear in `output`." [fhirbulkexport]
- Graph delta signals view inconsistency to the client directly: `410 Gone` with a `Location` header carrying an empty `$deltatoken`, meaning "restart with a full synchronization." Delta tokens expire (7 days for directory objects); Outlook entities have no fixed limit, bounded by cache capacity instead. [graphdelta]
- SMART on FHIR is the cautionary case on the other side: a client may get "a 200 OK response to a search interaction that appears to be allowed by the granted scopes, but where results have been omitted from the response Bundle." Silent omission is the acknowledged hazard clients must defend against — which argues *for* a completeness signal, not against one.

### Capability discovery: extension-then-promote is the IETF sequence

- RFC 8414 (AS metadata) postdates RFC 6749 by years; RFC 9728 (protected-resource metadata) is later still. Capability discovery has repeatedly shipped as a separate document after the core spec, not inside it.
- RFC 8126 §4 on registry policy: "it is important to think specifically about the registration policy, and not just pick one arbitrarily nor copy text from another document," choosing "the least strict policy that suits a registry's needs." §4.6 Specification Required requires detail "in sufficient detail so that interoperability between independent implementations is possible" — the bar is independent implementations, which is what an extension phase produces. RFC 8126 does **not** contain an explicit "defer registries pending implementation experience" statement; do not cite it for that. [rfc8126]
- Against: FHIR `CapabilityStatement` and MCP `tools/list` both put capability declaration in core. Both describe server capability with no per-user privacy content, so neither transfers cleanly to a spec where capability must cross a per-grant projection boundary.

## SOURCES

**rfc9396**
URL: https://www.rfc-editor.org/rfc/rfc9396.txt
Accessed: 2026-09-03
Quote: "the AS MUST also return the authorization_details as granted by the resource owner and assigned to the respective access token." (§7); "The AS needs to take into consideration the privacy implications when sharing authorization_details with the client or RSs." (§13)

**rfc7662**
URL: https://www.rfc-editor.org/rfc/rfc7662.txt
Accessed: 2026-09-03
Quote: "the authorization server SHOULD NOT include any additional information about an inactive token, including why the token is inactive." (§2.2); "To avoid disclosing the internal state of the authorization server..." (§4)

**rfc9728**
URL: https://www.rfc-editor.org/rfc/rfc9728.txt
Accessed: 2026-09-03
Quote: "Publishing information about the protected resource in a standard format makes it easier for both legitimate clients and attackers to use the protected resource." (§7.5)

**oidcdiscovery**
URL: https://openid.net/specs/openid-connect-discovery-1_0.html
Accessed: 2026-09-03
Quote: "JSON array containing a list of the Claim Names of the Claims that the OpenID Provider MAY be able to supply values for. Note that for privacy or other reasons, this might not be an exhaustive list."

**smartscopes**
URL: https://hl7.org/fhir/smart-app-launch/scopes-and-launch-context.html
Accessed: 2026-09-03
Quote: "200 OK response to a search interaction that appears to be allowed by the granted scopes, but where results have been omitted from the response Bundle"; "When a wildcard is requested for the FHIR resource, the client is asking for all data for all available FHIR resources, both now and in the future."

**mcptools**
URL: https://modelcontextprotocol.io/specification/2025-06-18/server/tools
Accessed: 2026-09-03
Quote: "Servers that support tools MUST declare the `tools` capability"; "When the list of available tools changes, servers that declared the `listChanged` capability SHOULD send a notification."

**graphdelta**
URL: https://learn.microsoft.com/en-us/graph/delta-query-overview
Accessed: 2026-09-03
Quote: "If a change occurs to a property that isn't selected, the resource for which that property changed doesn't appear in the delta response after a subsequent request."

**rfc6578**
URL: https://www.rfc-editor.org/rfc/rfc6578.txt
Accessed: 2026-09-03
Quote: "MAY be reported as removed if the user issuing the request no longer has access to this member, due to access control changes." (§3.5.2)

**fhirbulkexport**
URL: http://build.fhir.org/ig/HL7/bulk-data/en/export.html
Accessed: 2026-09-03
Quote: "Even if some of the requested resources cannot successfully be exported, the overall export operation MAY still succeed. In this case, the Response.outcome array ... SHALL be populated with one or more files in NDJSON format containing FHIR OperationOutcome resources to indicate what went wrong."

**rfc8126**
URL: https://www.rfc-editor.org/rfc/rfc8126.txt
Accessed: 2026-09-03
Quote: "it is important to think specifically about the registration policy, and not just pick one arbitrarily nor copy text from another document." (§4)

## SYNTHESIS

The useful result is that "what may a client learn" is not one question. Prior art splits it three ways and answers each differently, so a spec that treats it as a single privacy dial will get at least one of the three wrong.

*What exists* is closed everywhere that matters. SMART, RFC 7662, RFC 9396 and the OAuth metadata RFCs converge on the same shape without citing each other: the client learns the contents of its grant, and the surface deliberately cannot distinguish "you weren't granted this" from "this doesn't exist." RFC 7662 §4 is the one that says the quiet part out loud, which makes it the citation to reach for rather than the more obvious RFC 9396.

*Whether a response is complete* goes the other way, and the intuition that completeness is the subject's business rather than the consumer's does not survive the evidence. FHIR Bulk Data makes partial-success reporting a SHALL to the requesting party, Graph tells the client outright to resynchronize, and Plaid surfaces item status to the developer. SMART is the system that omits silently, and its own documentation treats that as a hazard apps must code around. Completeness metadata describes the response, not additional content, so it clears the RFC 9396 §13 need-to-know test that inventory listing fails.

*Field evolution outside the grant* follows the inventory rule, not the completeness rule — Graph's `$select` delta makes unselected properties invisible to change tracking, which is the same design under the same pressure at far larger scale. MCP's `listChanged` is the genuine counterexample and should be engaged rather than waved off, but its tool list carries no per-user content, so it is evidence about capability surfaces rather than about personal-data surfaces.

Two citation traps worth recording. The FHIR Bulk manifest array is `outcome`, not `error`. And RFC 8126 is frequently invoked for "don't create registries prematurely" — it does not say that; its §4 argument is about choosing the *least strict* policy, and the usable line for an extension-then-promote sequence is §4.6's "interoperability between independent implementations is possible."
