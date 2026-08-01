---
title: "OAuth Client ID Metadata Documents (CIMD) are the post-DCR client-identity mechanism the MCP auth spec now recommends"
date: 2026-06-08
topic: oauth-mcp-auth
tags: [oauth, mcp, cimd, dynamic-client-registration, ssrf, consent]
status: draft
sources: [mcp-auth-2025-06-18, mcp-auth-draft, cimd-01, rfc9728, rfc8414, rfc7591, obsidian-2025, speakeasy-2026, linear-mcp, sentry-mcp, notion-mcp, stripe-mcp]
source_session: 019d3bc3-1259-7d73-b066-22b0aed3b3cd
---

<!-- Reusable industry/standards findings extracted from a pdpp design note. pdpp-specific
     recommendations (its /mcp behavior, promotion triggers, discovery vocabulary) were dropped. -->

## CLAIMS

- The MCP authorization mechanism is built on OAuth 2.1; authorization is OPTIONAL overall, but HTTP-based transports SHOULD conform while STDIO transports SHOULD NOT and instead read credentials from the environment. [mcp-auth-2025-06-18]
- The two server-side MUSTs of the current MCP authorization spec are: serve RFC 9728 Protected Resource Metadata at `/.well-known/oauth-protected-resource`, and serve an RFC 8414 / OIDC discovery document (`/.well-known/oauth-authorization-server`). [mcp-auth-2025-06-18][rfc9728][rfc8414]
- A conformant protected resource returns `401` with `WWW-Authenticate: Bearer resource_metadata="…/.well-known/oauth-protected-resource"` when no token is presented, and the PRM document names its `authorization_servers`. [rfc9728]
- The MCP draft auth spec ranks client-registration mechanisms: authorization servers and MCP clients SHOULD support OAuth Client ID Metadata Documents (CIMD), MAY support OAuth 2.0 Dynamic Client Registration (RFC 7591), and states DCR "is deprecated and retained for backwards compatibility with authorization servers that do not support Client ID Metadata Documents." [mcp-auth-draft][rfc7591]
- CIMD is specified in `draft-ietf-oauth-client-id-metadata-document-01` (Parecki & Smith, 2 March 2026, expires 3 September 2026); it is an active IETF Internet-Draft. [cimd-01]
- Under CIMD the `client_id` is itself an `https` URL that MUST contain a path component, MUST NOT contain dot-segments or a fragment, MUST NOT carry userinfo, SHOULD NOT carry a query string, and MAY contain a port; a short stable URL is RECOMMENDED because it may be shown to the user. [cimd-01]
- The authorization server SHOULD fetch the document at the `client_id` URL; a successful response MUST be `200 OK` and is parsed as the client's metadata (`client_name`, `logo_uri`, `redirect_uris`, optionally `jwks`/`jwks_uri`). There is no prior registration handshake. [cimd-01]
- CIMD supports confidential clients without shared secrets: a client MAY publish a public key (`jwks`/`jwks_uri`) and authenticate with the matching private key; if the published keys change the AS MAY revoke that client's tokens or the user's consent. [cimd-01]
- A server that fetches a URL supplied in an authorization request is exposed to SSRF; CIMD directs the AS to restrict schemes to `https`, block internal/loopback/link-local targets, and disallow credentialed URLs. [cimd-01]
- CIMD directs the AS to cap the fetched document size to avoid resource exhaustion. [cimd-01]
- CIMD suggests restricting a client's `redirect_uris` to the same origin as the `client_id` to prevent a client impersonating a better-known one, with a development exemption path for localhost. [cimd-01]
- The AS SHOULD display the `client_id` hostname on the consent interface regardless of whether the document fetch succeeded. [cimd-01]
- An AS that also generates its own opaque client_ids SHOULD ensure those generated ids do not start with `https://`, so the CIMD and generated namespaces cannot collide. [cimd-01]
- DCR required the AS to accept registrations from arbitrary clients; few authorization servers implemented it, which pushed many remote MCP servers toward proxy patterns that produced one-click account-takeover vulnerabilities. [obsidian-2025]
- The 2026 ecosystem consensus is that OAuth is the right fit for MCP but DCR-era implementation friction was the problem; CIMD is the direct response. [speakeasy-2026]
- Leading remote-MCP providers converge on "one hosted HTTP MCP endpoint URL, then client-driven OAuth in the browser," not a pasted bearer token, as the normal setup: Linear (hosted Streamable HTTP + client-initiated OAuth), Sentry (add one hosted HTTP MCP URL, client drives OAuth), Notion (hosted MCP endpoint with OAuth owner authorization, separate token option for automation), Stripe (OAuth for normal MCP clients, bearer/API-key only for explicit agentic/headless use). [linear-mcp][sentry-mcp][notion-mcp][stripe-mcp]

## SOURCES

**mcp-auth-2025-06-18**
URL: https://modelcontextprotocol.io/specification/2025-06-18/basic/authorization
Accessed: 2026-06-08

**mcp-auth-draft**
URL: https://modelcontextprotocol.io/specification/draft/basic/authorization
Accessed: 2026-06-08
Quote: "Dynamic Client Registration is deprecated and retained for backwards compatibility with authorization servers that do not support Client ID Metadata Documents."

**cimd-01**
URL: https://datatracker.ietf.org/doc/draft-ietf-oauth-client-id-metadata-document/
Accessed: 2026-06-08
Quote: "an OAuth client can identify itself to authorization servers, without prior dynamic client registration or other existing registration"

**rfc9728**
URL: https://datatracker.ietf.org/doc/html/rfc9728
Accessed: 2026-06-08

**rfc8414**
URL: https://datatracker.ietf.org/doc/html/rfc8414
Accessed: 2026-06-08

**rfc7591**
URL: https://datatracker.ietf.org/doc/html/rfc7591
Accessed: 2026-06-08

**obsidian-2025**
URL: https://www.obsidiansecurity.com/blog/when-mcp-meets-oauth-common-pitfalls-leading-to-one-click-account-takeover
Accessed: 2026-06-08

**speakeasy-2026**
URL: https://www.speakeasy.com/mcp/securing-mcp-servers/authenticating-mcp-servers
Accessed: 2026-06-08

**linear-mcp**
URL: https://linear.app/docs/mcp
Accessed: 2026-06-08

**sentry-mcp**
URL: https://mcp.sentry.dev/
Accessed: 2026-06-08

**notion-mcp**
URL: https://developers.notion.com/docs/get-started-with-mcp
Accessed: 2026-06-08

**stripe-mcp**
URL: https://docs.stripe.com/mcp
Accessed: 2026-06-08

## SYNTHESIS

For any OAuth authorization server that wants to be first-class for MCP clients in the post-DCR world, the additive move is server-side CIMD consumption at the authorize endpoint: accept `https://`-URL client_ids, fetch+validate the metadata document, drive consent (name, logo, hostname) from it, and advertise the capability in discovery — while keeping DCR and pre-registered public clients for backwards compatibility. The security burden is real and specific (SSRF, response-size bound, redirect_uri origin trust, jwks-change revocation) because the AS is now making an outbound fetch to an attacker-influenced URL. Because CIMD is still an early Internet-Draft referencing `-00` in MCP and no major MCP client had shipped CIMD support as of mid-2026, implementing early tracks a moving target; a reasonable trigger is IETF stability beyond an early draft or a target MCP client shipping CIMD support.
