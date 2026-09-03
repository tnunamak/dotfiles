---
title: "OAuth CIMD (draft-ietf-oauth-client-id-metadata-document) is the MCP-recommended, general-purpose client-identity mechanism; GNAP (RFC 9635) identifies clients by cryptographic key instead and is not compatible with OAuth's model"
date: 2026-09-02
topic: protocols
tags: [oauth, gnap, mcp, cimd, dynamic-client-registration, client-identity, rfc9635, rfc7591]
status: draft
sources: [cimd-02, mcp-auth-2025-11-25, mcp-auth-2025-06-18, rfc9635, rfc7591, indieauth-bg]
source_session: c194c586-d08d-4242-8ba5-3bb13586be8a
---

## ANSWER

**(1) What standard defines "client ID metadata documents"?**
`draft-ietf-oauth-client-id-metadata-document`, currently at **revision -02** (Aaron Parecki, Okta, and Emelia Smith; posted 6 July 2026, expires 7 January 2027). It is an active IETF OAuth Working Group Internet-Draft — the "-ietf-" in the name confirms WG adoption; it succeeded an earlier individual submission, `draft-parecki-oauth-client-id-metadata-document`. [cimd-02]

Lineage: CIMD's core idea — using a fetchable `https://` URL as the client identifier itself — is the same trust model IndieAuth pioneered for its own client-identifier mechanism (a client's home page URL doubles as its identifier, fetched by the AS for `h-app`/`h-x-app` metadata). CIMD generalizes that pattern into a standalone OAuth client-metadata document format decoupled from IndieAuth. [indieauth-bg]

Validation rules the draft states (Section 4–6, per the -00 text incorporated into the MCP spec, materially unchanged in -02):
- `client_id` **MUST** be an `https` URL, **MUST** contain a path component, **MUST NOT** contain dot-segments or a fragment, **MUST NOT** carry userinfo, **SHOULD NOT** carry a query string, **MAY** contain a port.
- The AS **SHOULD** fetch the document at the `client_id` URL; a successful fetch **MUST** return `200 OK`, parsed as client metadata (`client_id`, `client_name`, `redirect_uris`, optionally `jwks`/`jwks_uri`, `logo_uri`, `client_uri`).
- The AS **MUST** validate the fetched document's `client_id` field matches the request URL exactly (echo check).
- `redirect_uris` in the authorization request **MUST** validate against the fetched document's list.
- The AS **SHOULD** cache the document respecting HTTP cache headers.
- Fetch constraints: restrict schemes to `https`, block internal/loopback/link-local targets (SSRF defense), disallow credentialed URLs, cap response size.
- No prior registration handshake — this is the entire point of the mechanism relative to RFC 7591 DCR. [cimd-02]

**(2) Where does MCP's authorization spec reference it, and how does it rank CIMD vs. DCR?**
- The **2025-06-18** MCP spec revision does **not** mention CIMD at all — it only lists RFC 7591 DCR as a client-registration mechanism ("Authorization servers and MCP clients **SHOULD** support the OAuth 2.0 Dynamic Client Registration Protocol [RFC7591]"). [mcp-auth-2025-06-18]
- CIMD was added in the **2025-11-25** MCP spec revision (via SEP-991), which is the current published stable revision. Its "Standards Compliance" list now cites `draft-ietf-oauth-client-id-metadata-document-00`, and its normative ranking (Overview, item 2–3) states:
  > "Authorization servers and MCP clients **SHOULD** support OAuth Client ID Metadata Documents ([draft-ietf-oauth-client-id-metadata-document-00])."
  > "Authorization servers and MCP clients **MAY** support the OAuth 2.0 Dynamic Client Registration Protocol ([RFC7591])."
  The "Dynamic Client Registration" subsection adds: "This option is included for backwards compatibility with earlier versions of the MCP authorization spec." [mcp-auth-2025-11-25]
- The spec defines a **priority order** for clients across all three mechanisms it supports (pre-registration, CIMD, DCR): (1) pre-registered client info if available, (2) CIMD if the AS advertises `client_id_metadata_document_supported: true`, (3) DCR as fallback if the AS advertises `registration_endpoint`, (4) prompt the user. [mcp-auth-2025-11-25]
- So relative to RFC 7591: MCP flipped CIMD to **recommended (SHOULD)** and DCR to **optional/legacy (MAY, backwards-compat only)** — the opposite of the 2025-06-18 ranking, where DCR was the sole SHOULD-level mechanism.

**(3) Is the mechanism MCP-specific or general OAuth?**
General OAuth. CIMD is an IETF OAuth WG draft with no dependency on MCP; MCP is simply an early, prominent adopter that reuses it verbatim (its "Standards Compliance" list cites the draft directly, and its own field requirements — e.g., document **MUST** include at least `client_id`, `client_name`, `redirect_uris` — are MCP-specific *tightening* of the general spec, not a fork of it). [cimd-02][mcp-auth-2025-11-25]

**(4) How does GNAP (RFC 9635) identify/display clients instead?**
GNAP explicitly states it is **not** an OAuth extension and is not intended to be OAuth-compatible (Introduction, RFC 9635): "GNAP is not an extension of OAuth 2.0 and is not intended to be directly compatible with OAuth 2.0." [rfc9635]

- **Identity mechanism**: GNAP identifies a *client instance* — one running copy of client software — by the **public key it presents in the request**, not by a static registered identifier like `client_id`. Section 2.3 defines the request's `client` field as "the public key of the client instance to be used in this request … or a reference to a key." The spec distinguishes the *client instance* (identified by its unique key) from the *client software* (the general application) — Section 1.6. [rfc9635]
- **Key proofing**: the client **MUST** prove possession of any presented key using the proofing mechanism bound to that key (Section 7.3), with four registered methods: HTTP Message Signatures (7.3.1), Mutual TLS (7.3.2), Detached JWS (7.3.3), Attached JWS (7.3.4), tracked in the extensible "GNAP Key Proofing Methods" registry (Section 10.16). [rfc9635]
- **Display object** (Section 2.3.2, `display` field on the client instance, itself OPTIONAL): three fields, extensible via the "GNAP Client Instance Display Fields" registry (Section 10.8):
  - `name` (string) — display name of the client software. **RECOMMENDED**.
  - `uri` (string) — user-facing page about the client software; **MUST** be an absolute URI. **OPTIONAL**.
  - `logo_uri` (string) — display image for the client software; **MUST** be an absolute URI (a `data:` URI per RFC 2397 is allowed for pass-by-value). **OPTIONAL**.
  [rfc9635]

**Protocol-neutral mapping — "requester identity + trust signal":**

| Concern | OAuth (CIMD) | OAuth (DCR, RFC 7591) | GNAP (RFC 9635) |
|---|---|---|---|
| Identity primitive | `https://` URL, fetched, self-describing | Opaque `client_id` issued at registration time | Public key (or key reference) presented per-request |
| Trust root | DNS + HTTPS (control of the URL's domain) | AS's own registration record | Possession of the private key, proven per-request |
| Human-facing metadata | Same document, fields borrowed from RFC 7591 (`client_name`, `logo_uri`, `redirect_uris`, …) | Registration-time metadata (`client_name`, `logo_uri`, `policy_uri`, `tos_uri`, …) | Separate optional `display` object (`name`, `uri`, `logo_uri`) sent with the request |
| Re-verification over time | Re-fetch on each use (subject to caching) | None — trusts the stored registration record until revoked | Re-proof of key possession on every request; a key rotation can be detected and used to force re-consent |
| Software statements / attestation | Not defined in CIMD itself; would layer on top | `software_statement` JWT, signed by a trusted issuer | Not used; trust is the key itself, with optional external attestation extensions |

A protocol-neutral model would separate two axes: **(a) requester identity** — what long-lived, verifiable thing identifies "this software/client" (a domain-bound URL for CIMD, a registration record for DCR, a public key for GNAP) — and **(b) trust signal** — what the AS/RO checks at authorization time to decide whether to believe that identity and how much friction to apply (freshness of a fetched document + domain reputation for CIMD; static registration trust for DCR; live proof-of-possession for GNAP, which is strictly stronger against credential replay because the key itself must sign each request). CIMD and DCR both put the trust signal into a *document* consumed once (DCR) or refreshed (CIMD); GNAP puts it into a *cryptographic proof* verified on every call. The `display` metadata (name/uri/logo) is a separable, cosmetic layer in all three — GNAP keeps it explicitly optional and small; OAuth's document-based mechanisms (both DCR and CIMD) reuse the larger RFC 7591 vocabulary because the document already needs to carry `redirect_uris` and other functional fields alongside the cosmetic ones.

**(5) Is reusing RFC 7591 vocabulary (client_name, logo_uri, policy_uri, tos_uri) good practice elsewhere, and is dropping the `client_` prefix meaningful?**
- Reuse is standard practice: RFC 7591 itself designed these fields to be shared — it explicitly supports **software statements** (Section 2.3), signed JWTs that "assert metadata values about the client software as a bundle, using the same set of claims defined for client metadata," specifically so downstream registration flows and other specs can carry the identical vocabulary with an attestation layer on top. CIMD's own example metadata document reuses the fields unprefixed and unchanged (`client_name`, `client_uri`, `logo_uri`, `redirect_uris`, `grant_types`, `response_types`, `token_endpoint_auth_method`) — this is why MCP's implementation guidance for CIMD points straight back at RFC 7591-shaped fields with no remapping. [rfc7591][cimd-02][mcp-auth-2025-11-25]
- On the `client_` prefix specifically: RFC 7591's registered field names are inconsistent about the prefix already — `client_name`, `client_uri` keep it; `logo_uri`, `policy_uri`, `tos_uri`, `redirect_uris` drop it. So CIMD dropping the prefix on `redirect_uris`/`logo_uri` while keeping it on `client_id`/`client_name` is not a new divergence — it's continuity with RFC 7591's own naming, not a break from it. Nothing in the CIMD draft or the MCP spec renames or reprefixes any RFC 7591 field. The only field CIMD adds that RFC 7591 didn't define as MUST-have is treating `client_id` itself as data *inside* the document (a self-referential echo check) — RFC 7591's `client_id` is server-issued and appears only in the *response*, never something the client asserts inside its own request payload. [rfc7591][cimd-02]

## SOURCES

**cimd-02**
URL: https://datatracker.ietf.org/doc/draft-ietf-oauth-client-id-metadata-document/
Accessed: 2026-09-02
Quote: "This specification enables OAuth clients to identify themselves to authorization servers without pre-registration by using URLs as client identifiers. These URLs reference documents containing client metadata that authorization servers can fetch as needed."
Notes: current revision -02, posted 2026-07-06, expires 2027-01-07; supersedes draft-parecki-oauth-client-id-metadata-document (individual submission → WG document). Corpus entry `oauth-mcp-auth/cimd-replaces-dynamic-client-registration-for-mcp-oauth.md` (2026-06-08) cited the then-current -01 revision and the pre-2025-11-25 MCP draft spec; this entry supersedes it with -02 and the published 2025-11-25 MCP revision.

**mcp-auth-2025-11-25**
URL: https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization
Accessed: 2026-09-02
Quote: "Authorization servers and MCP clients SHOULD support OAuth Client ID Metadata Documents (draft-ietf-oauth-client-id-metadata-document-00). Authorization servers and MCP clients MAY support the OAuth 2.0 Dynamic Client Registration Protocol (RFC7591)."

**mcp-auth-2025-06-18**
URL: https://modelcontextprotocol.io/specification/2025-06-18/basic/authorization
Accessed: 2026-09-02
Quote: "Authorization servers and MCP clients SHOULD support the OAuth 2.0 Dynamic Client Registration Protocol (RFC7591)." (No mention of CIMD anywhere in this revision.)

**rfc9635**
URL: https://www.rfc-editor.org/rfc/rfc9635.html
Accessed: 2026-09-02
Quote: "GNAP is not an extension of OAuth 2.0 and is not intended to be directly compatible with OAuth 2.0."

**rfc7591**
URL: https://datatracker.ietf.org/doc/html/rfc7591
Accessed: 2026-09-02
Quote: "A software statement is a JSON Web Token (JWT) that asserts metadata values about the client software as a bundle... The metadata values are the same set defined for client metadata."

**indieauth-bg**
URL: https://indieauth.spec.indieweb.org/
Accessed: 2026-09-02
Notes: background/lineage source for CIMD's URL-as-client-id trust model (IndieAuth uses the client's own home-page URL as its client identifier, fetched by the AS for app metadata); cited for lineage context, not directly quoted.

## SYNTHESIS

CIMD is squarely general OAuth machinery, not an MCP invention — MCP is simply the highest-profile early consumer, and it moved fast: the 2025-06-18 MCP revision didn't mention CIMD at all (only DCR, SHOULD-level), and by 2025-11-25 CIMD had become the SHOULD-level mechanism with DCR demoted to MAY/backwards-compat. The June 2026 corpus entry (`cimd-replaces-dynamic-client-registration-for-mcp-oauth.md`) was accurate for its moment but is now stale on two fronts: it cites CIMD-01 (current is -02) and the pre-2025-11-25 MCP "draft" spec revision (current stable is 2025-11-25, which is the first revision to actually reference CIMD). That corpus entry's closing trigger — "reasonable trigger is IETF stability beyond an early draft or a target MCP client shipping CIMD support" — has now fired on the MCP-spec side (2025-11-25 ships CIMD as SHOULD-level with full implementation requirements and its own Security Considerations subsection); WG adoption (`-ietf-` prefix) also already happened. IETF "stability" in the sense of a Proposed Standard has not yet occurred — it remains an active WG draft.

GNAP made a clean, deliberate break from the OAuth client-identity model rather than reusing or extending it: static bearer identifiers (DCR's `client_id`, CIMD's fetchable URL) are replaced by live proof-of-possession of a key, which is stronger against replay but requires proofing infrastructure (HTTP Message Signatures, mTLS, JWS) on every request rather than once at registration or fetch time. The cosmetic `display` object in GNAP is a strict subset of the OAuth vocabulary (3 fields vs. RFC 7591's larger set) and is explicitly separated from the identity mechanism — in OAuth's document-based approaches the cosmetic and functional fields (redirect_uris, jwks) live in the same document, which is precisely the property CIMD's phishing/localhost-impersonation security considerations have to defend against (Section 6 of the CIMD draft, echoed in MCP's "Client ID Metadata Document Security" subsection).
