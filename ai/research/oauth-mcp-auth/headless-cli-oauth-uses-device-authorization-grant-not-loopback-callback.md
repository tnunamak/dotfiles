---
title: "For headless/sandbox clients that cannot complete a loopback callback, the standards-aligned OAuth path is the RFC 8628 Device Authorization Grant, not silent browser-launch-and-wait"
date: 2026-06-12
topic: oauth-mcp-auth
tags: [oauth, device-flow, rfc8628, rfc8252, mcp-authorization, cli-auth, pkce]
status: draft
sources: [mcp-auth, cimd-draft, rfc8252, rfc8628, ms-device-code, mcp-auth-extensions, mcp-device-discussion, claude-code-issue, gh-cli, gcloud-cli, stripe-cli, vercel-changelog, linear-oauth, plaid-oauth]
---

## CLAIMS

- The MCP authorization spec (2025-11-25) bases auth on OAuth 2.1 plus OAuth Authorization Server Metadata, Dynamic Client Registration, Protected Resource Metadata, and OAuth Client ID Metadata Documents; authorization is defined for HTTP transports, while STDIO transports should take credentials from the environment. [mcp-auth]
- Per the MCP spec: MCP servers act as OAuth resource servers and must implement Protected Resource Metadata; MCP clients must use it for AS discovery, must support both OAuth AS Metadata and OpenID Connect Discovery, must use Resource Indicators (the `resource` parameter) on authorization and token requests, must send bearer tokens in the Authorization header (never in query strings), and must implement PKCE with `S256` when capable; servers must validate token audience and reject token passthrough. [mcp-auth]
- In the latest MCP spec, OAuth Client ID Metadata Documents (CIMD) are the preferred no-prior-relationship registration mechanism, and Dynamic Client Registration is only a MAY retained for backwards compatibility. [mcp-auth]
- CIMD makes an HTTPS URL the `client_id`, where the document at that URL contains client metadata (name, redirect URIs); it is a client-registration mechanism (for clients with no prior AS relationship), not a redirect mechanism. [cimd-draft]
- RFC 8252 (BCP for native apps) says native apps should authorize through the external user agent (system browser), public native clients should use Authorization Code with PKCE, and implicit flow is not recommended; it recognizes three redirect patterns — private-use URI scheme, claimed HTTPS, and loopback — and says loopback HTTP without TLS is acceptable, clients should prefer loopback IP literals over `localhost`, and authorization servers should allow any port for loopback redirects. [rfc8252]
- RFC 8628 (Device Authorization Grant) is for browserless/input-constrained devices: the client requests `device_code`, `user_code`, `verification_uri`, optional `verification_uri_complete`, `expires_in`, and optional polling `interval`; the user approves on a separate browser-capable device; the client polls the token endpoint with `grant_type=urn:ietf:params:oauth:grant-type:device_code` handling `authorization_pending`, `slow_down`, `access_denied`, and `expired_token`, waiting at least 5 seconds if `interval` is absent. [rfc8628][ms-device-code]
- Core MCP does NOT standardize RFC 8628 device authorization; MCP's listed authorization extensions are OAuth Client Credentials and Enterprise-Managed Authorization, and device authorization is not among them. [mcp-auth-extensions]
- There is community pressure for headless/device-flow MCP auth: a modelcontextprotocol discussion proposes Device Authorization Grant + CIBA, and a Claude Code issue requests OAuth device authorization for MCP servers in SSH/containers/remote dev — but these are adoption signals, not normative requirements. [mcp-device-discussion][claude-code-issue]
- GitHub CLI `gh auth login` defaults to browser auth, stores credentials securely when possible, offers `--web`, `--clipboard`, `--with-token`, and environment-token paths, and its docs say environment variables are most suitable for headless automation. [gh-cli]
- Google Cloud CLI supports `gcloud auth login --no-browser` (authorize via a trusted second machine that has browser + gcloud), `--launch-browser` (prints a URL if it can't launch), and `--no-launch-browser` (prints the auth URL for another machine and asks the user to paste the resulting authorization code back). [gcloud-cli]
- Stripe CLI `stripe login` prints a pairing code confirmed in the Dashboard, and offers `stripe login --interactive` for environments that cannot open a browser and need manual API key entry. [stripe-cli]
- Vercel moved `vercel login` to OAuth 2.0 Device Flow in 2025, letting users sign in from any browser-capable device (advising verification of location/IP/request time before approval) and deprecating older email/OOB/provider-specific login flags. [vercel-changelog]
- Linear's OAuth docs use standard Authorization Code parameters (`client_id`, `redirect_uri`, `response_type=code`, scopes). [linear-oauth]
- Plaid Link's OAuth docs are redirect-URI precise: they distinguish received-redirect-URI handling and mobile app-to-app cases, recommend Universal Links / Android App Links for hosted-link app-to-app auth, and allow localhost redirect URIs for sandbox testing when registered. [plaid-oauth]

## SOURCES

**mcp-auth**
URL: https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization
Accessed: 2026-06-12

**cimd-draft**
URL: https://datatracker.ietf.org/doc/html/draft-ietf-oauth-client-id-metadata-document-00
Accessed: 2026-06-12

**rfc8252**
URL: https://datatracker.ietf.org/doc/html/rfc8252
Accessed: 2026-06-12

**rfc8628**
URL: https://datatracker.ietf.org/doc/html/rfc8628
Accessed: 2026-06-12

**ms-device-code**
URL: https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-device-code
Accessed: 2026-06-12

**mcp-auth-extensions**
URL: https://modelcontextprotocol.io/extensions/auth/overview
Accessed: 2026-06-12

**mcp-device-discussion**
URL: https://github.com/modelcontextprotocol/modelcontextprotocol/discussions/298
Accessed: 2026-06-12

**claude-code-issue**
URL: https://github.com/anthropics/claude-code/issues/20215
Accessed: 2026-06-12

**gh-cli**
URL: https://cli.github.com/manual/gh_auth_login
Accessed: 2026-06-12

**gcloud-cli**
URL: https://docs.cloud.google.com/sdk/gcloud/reference/auth/login
Accessed: 2026-06-12

**stripe-cli**
URL: https://docs.stripe.com/cli
Accessed: 2026-06-12

**vercel-changelog**
URL: https://vercel.com/changelog/new-vercel-cli-login-flow
Accessed: 2026-06-12

**linear-oauth**
URL: https://linear.app/developers/oauth-2-0-authentication
Accessed: 2026-06-12

**plaid-oauth**
URL: https://plaid.com/docs/link/oauth/
Accessed: 2026-06-12
Additional: https://plaid.com/docs/link/hosted-link/ ; https://github.com/plaid/quickstart/blob/master/README.md

## SYNTHESIS

The developer-quality bar (Stripe/Linear/Vercel/Plaid/gh/gcloud) for OAuth setup: flows should be explicit, recoverable, copyable, bounded by timeouts, and precise about which token is being issued.

Recommended shape for an MCP/CLI OAuth surface that must also work headless:
1. Keep the normal Authorization-Code-with-PKCE path for browser-capable local clients; prefer loopback IP literal redirects over `localhost` where a loopback listener is actually reachable.
2. Provide an explicit no-loopback path for headless/sandbox clients rather than silently opening a browser and waiting forever for an unreachable callback.
3. Prefer RFC 8628 Device Authorization Grant for the no-loopback path: user approves on another device, client polls with bounded intervals, token is delivered directly to the waiting client.
4. If device authorization is unavailable, at minimum print the authorization URL, expiry, and fallback instructions and fail fast with a clear timeout.
5. Provide explicit copy affordances: verification URI, user code, `verification_uri_complete` when available, expiry, polling status, retry command.

Out-of-band manual copy/paste of authorization codes is legacy and weaker than device authorization; good CLIs still offer a copyable URL when browser launch fails, but the durable modern pattern is an explicit browser-capable-device flow with a code, an expiry, and polling semantics. Note that device authorization is not (yet) a standardized MCP extension, so a device-flow MCP login is standards-aligned at the OAuth layer but is a local extension at the MCP layer.
