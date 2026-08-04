---
title: "The current MCP specification (2026-07-28, unchanged from 2025-11-25) mandates both client-side RFC 8707 `resource` parameter usage AND server-side audience validation on token receipt — RFC 8707 itself only mandates the former"
date: 2026-08-02
topic: oauth-mcp-auth
tags: [rfc8707, resource-indicators, audience-validation, mcp-authorization, confused-deputy, aud-claim]
status: draft
sources: [rfc8707, mcp-2026-07-28-authorization, mcp-2025-11-25-authorization]
source_session: unknown
---

## CLAIMS

- RFC 8707 defines the `resource` parameter as an absolute URI (no fragment, SHOULD NOT have query) that a client MAY send at the authorization endpoint and/or token endpoint to indicate the target resource for the requested token. [rfc8707]
- RFC 8707 permits multiple `resource` parameters in one request, to request a token valid at multiple resources, but explicitly discourages this practice ("using only a single `resource` parameter is encouraged") because a multi-audience token "can be used by any one of those resources to access any of the others," requiring a high degree of mutual trust. [rfc8707]
- RFC 8707's only normative requirement on the authorization server is a SHOULD: "The authorization server SHOULD audience-restrict issued access tokens to the resource(s) indicated by the `resource` parameter." It does not mandate `aud`-claim population, and it explicitly permits the AS to map the raw `resource` value to a different/abstract audience identifier. [rfc8707]
- RFC 8707 defines the `invalid_target` error for when the AS rejects or cannot parse a requested resource. [rfc8707]
- RFC 8707 contains **no normative requirement on the resource server** to verify the audience restriction on token receipt — that half of the contract is left entirely to the deploying system. [rfc8707]
- The MCP specification closes that gap itself, independent of RFC 8707: MCP clients "MUST implement Resource Indicators for OAuth 2.0 as defined in RFC 8707," MUST send `resource` in both the authorization request and the token request, and MUST use the canonical URI of the MCP server as the value — clients MUST send this parameter "regardless of whether authorization servers support it." [mcp-2026-07-28-authorization]
- The MCP specification separately and unconditionally requires the server side: "MCP servers MUST validate that access tokens were issued specifically for them as the intended audience, according to RFC 8707 Section 2" and "MCP servers MUST only accept tokens that are valid for use with their own resources" and "MUST NOT accept or transit any other tokens." Failure MUST produce an HTTP 401. [mcp-2026-07-28-authorization]
- The MCP "Access Token Privilege Restriction" security-considerations section names the systemic risk directly: "When an MCP server doesn't verify that tokens were specifically intended for it (for example, via the audience claim...), it may accept tokens originally issued for other services. This breaks a fundamental OAuth security boundary." It further requires: "MCP servers MUST only accept tokens specifically intended for themselves and MUST reject tokens that do not include them in the audience claim or otherwise verify that they are the intended recipient of the token." [mcp-2026-07-28-authorization]
- This client-MUST-send / server-MUST-validate pairing is identical, word-for-word in the load-bearing clauses, between the 2025-11-25 revision and the current 2026-07-28 revision — the resource-indicator and audience-validation requirements have been stable for at least that span; the 2026-07-28 revision's changes in this area are additive (RFC 9207 `iss` validation, refresh-token guidance) and do not touch the resource/audience clauses. [mcp-2026-07-28-authorization] [mcp-2025-11-25-authorization]
- MCP 2026-07-28 also newly requires `iss`-parameter validation per RFC 9207 as a related but distinct anti-mix-up control (client records the AS's `issuer` and compares it against the authorization response) — this is not part of RFC 8707 but sits in the same "don't accept/redirect-to the wrong party" security family. [mcp-2026-07-28-authorization]

## SOURCES

**rfc8707**
URL: https://www.rfc-editor.org/rfc/rfc8707.html
Accessed: 2026-08-02
Quote: "The authorization server SHOULD audience-restrict issued access tokens to the resource(s) indicated by the `resource` parameter." / "using only a single `resource` parameter is encouraged"

**mcp-2026-07-28-authorization**
URL: https://modelcontextprotocol.io/specification/2026-07-28/basic/authorization
Accessed: 2026-08-02
Quote: "MCP servers MUST validate that access tokens were issued specifically for them as the intended audience, according to RFC 8707 Section 2... MCP servers MUST only accept tokens that are valid for use with their own resources. MCP servers MUST NOT accept or transit any other tokens."

**mcp-2025-11-25-authorization**
URL: https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization
Accessed: 2026-08-02
Quote: "MCP clients MUST include the `resource` parameter in authorization and token requests... MCP servers MUST validate that tokens presented to them were specifically issued for their use."

## SYNTHESIS

RFC 8707 alone would not obligate a resource server to do anything — it's an
issuance-side convention with a permissive SHOULD. The teeth are entirely in the
MCP specification, which converts the client-side send into a hard MUST and adds
an independent, unconditional server-side MUST to validate audience on every
request and reject non-matching tokens with 401. This means "we parse and require
`resource` at the authorization/device endpoint" (issuance-side plumbing) is not
equivalent to "we implement RFC 8707 for MCP" — the second half (audience
enforcement at the resource server, on every `/mcp` request, independent of AS
behavior) is where the actual confused-deputy protection lives, and it requires:
(a) a place to store the bound audience on the issued token/grant, and (b) a check
at the token-info/introspection path that runs before request handling, comparable
in shape to the existing `pdpp_token_kind` gate. Neither RFC 8707 nor the MCP spec
prescribes the storage mechanism (column vs. embedded claim vs. side table) — that
part is legitimately an implementation decision for the deploying system, which is
where a project-specific spec must fill the gap RFC 8707 leaves open.
