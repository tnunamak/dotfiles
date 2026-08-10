---
title: "Jellyfin API keys are admin-only server credentials, so a personal-data connector must use per-user AuthenticateByName access tokens instead"
date: 2026-08-07
topic: connectors
tags: [jellyfin, self-hosted, auth, access-tokens, api-keys, personal-data]
status: draft
sources: [jellyfin-auth-gist, jellyfin-kotlin-sdk, jellyfin-apiclient-python, jellyfin-issue-5210]
source_session: 073acd59-50b7-4bf4-81a9-bfb5e652202b
---

## CLAIMS

- Jellyfin offers three authentication modes: no authorization, user authorization with
  an access token, or authorization with an API key. [jellyfin-auth-gist]
- API keys are SERVER-level credentials created only in the admin dashboard
  (`/web/#/dashboard/keys`). A non-admin user cannot generate one, because the key
  management page sits behind the admin dashboard. [jellyfin-auth-gist]
- An API key authenticates to the server but identifies NO user. Endpoints shaped
  `/Users/{userId}/Views` and `/Users/{userId}/Items` therefore cannot be resolved from
  an API key alone on a multi-user server. [jellyfin-auth-gist]
- `POST /Users/AuthenticateByName` is the per-user equivalent and is available to ANY
  user, admin or not. It takes `{"Username": "...", "Pw": "..."}` plus a
  `MediaBrowser Client=..., Device=..., DeviceId=..., Version=...` Authorization header,
  and returns an `AccessToken` field. [jellyfin-kotlin-sdk] [jellyfin-apiclient-python]
- The authentication response also carries `User.Id`, which is exactly the userId the
  user-scoped endpoints require — so one call yields both the credential and the
  identity. [jellyfin-kotlin-sdk]
- The returned access token is long-lived (tied to a device/session entry) and is passed
  the same way an API key is, via the `Token=` field of the MediaBrowser Authorization
  header. [jellyfin-auth-gist] [jellyfin-kotlin-sdk]
- Permissions still apply to a user token: Jellyfin enforces `RequiresElevation` and
  `LocalAccessOrRequiresElevation`, so a non-admin token receives 403 on admin-only
  endpoints. A user token is not a privilege escalation. [jellyfin-auth-gist]
- Passwordless accounts work through the same call with an empty password string.
  [jellyfin-apiclient-python]
- Header auth is recommended over the `ApiKey=`/`api_key=` query parameter, which risks
  leaking the secret through server logs, browser history, and copy-paste.
  [jellyfin-auth-gist]
- A known defect: calling `/Users/AuthenticateByName` with a valid payload but a
  MALFORMED Authorization header wipes the server's entire Devices table, and a
  non-admin can trigger it. Always send a well-formed MediaBrowser header.
  [jellyfin-issue-5210]
- Verified live 2026-08-07 against a real instance: `POST /Users/AuthenticateByName`
  with a well-formed MediaBrowser header and bogus credentials returns **401**, not 404
  — the endpoint exists and rejects cleanly. `/Users/Me`, `/UserViews`, and `/Items`
  likewise return 401 unauthenticated.

## SOURCES

**jellyfin-auth-gist**
URL: https://gist.github.com/nielsvanvelzen/ea047d9028f676185832e51ffaf12a6f
Accessed: 2026-08-07
Quote: "Jellyfin generally offers three ways to authenticate: no authorization, user
authorization with an access token, or authorization with an API key."

**jellyfin-kotlin-sdk**
URL: https://kotlin-sdk.jellyfin.org/guide/authentication.html
Accessed: 2026-08-07
Quote: "The access token comes back in the `AccessToken` field of the response JSON."

**jellyfin-apiclient-python**
URL: https://deepwiki.com/jellyfin/jellyfin-apiclient-python/3.4-authentication-and-login
Accessed: 2026-08-07
Quote: "The server responds with HTTP 401 when credentials are invalid; otherwise the
response contains the authentication result with user information."

**jellyfin-issue-5210**
URL: https://github.com/jellyfin/jellyfin/issues/11484
Accessed: 2026-08-07
Quote: "Calling /Users/AuthenticateByName with valid auth but invalid Authorization
header appears to wipe the entire Devices table even as non-admin"

## SYNTHESIS

For a personal-data tool this inverts the obvious choice. An API key looks like the
"proper" machine credential and is what most Jellyfin integration guides reach for, but
it is the WRONG credential for this use case on two counts.

First, it is admin-only. Requiring an API key means only a server administrator can
connect their Jellyfin data — every other user on the server is locked out of their own
library history. For a product whose premise is that an owner can extract their own
data, that is a disqualifying constraint, not a minor friction.

Second, it does not identify a user. On a real multi-user server (28 users, in the
instance that surfaced this) the connector holds a credential that authenticates but
cannot answer "whose library?" That forces either an extra owner-supplied user field, or
worse, a guess. A connector that guesses an identity is the failure mode that produced
the original bug here: it substituted a fabricated all-zeros user id inside a bare
`catch`, and every downstream call 400'd while reporting the provider's rejection of
that fiction as the error.

`AuthenticateByName` solves both at once and is strictly better for this shape: any
user can obtain it, and the same response carries `User.Id`, so identity resolution
stops being a separate problem. The cost is that the connector handles a username and
password rather than an opaque key — which is the same credential class this codebase
already handles for other providers, and which should be sealed the same way.

Generalizable lesson: when a self-hosted provider offers both a server-level API key and
a per-user token, a personal-data connector should default to the per-user token even
when the API key is more prominently documented. The API key is designed for
server-to-server automation (Sonarr/Radarr-style), where "which user" is irrelevant.
Personal-data extraction is the opposite: the user IS the subject, and a credential that
cannot name them is missing the thing that matters. Check for this shape in any
self-hosted connector (Nextcloud, Immich, Plex) before defaulting to the admin key.

Implementation caution: send a well-formed `MediaBrowser Client/Device/DeviceId/Version`
Authorization header. A malformed one on this endpoint is a known destructive bug that
wipes the server's Devices table, and it does not require admin rights to trigger.
