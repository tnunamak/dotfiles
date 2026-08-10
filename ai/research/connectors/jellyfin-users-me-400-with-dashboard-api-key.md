---
title: "Jellyfin's /Users/Me endpoint returns HTTP 400 when authenticated with a dashboard-issued API key instead of a user session token"
date: 2026-08-08
topic: jellyfin
tags: [jellyfin, api, auth, 400-bad-request]
status: draft
sources: [jellyfin-issue-14559, nielsvanvelzen-gist]
source_session: eb296077-b612-4e49-8dc0-db9e6d5418b8
---

## CLAIMS

- Jellyfin's `/Users/Me` REST endpoint returns HTTP 400 (RFC 9110 §15.5.1 Bad Request) when the request is authenticated with a static API key generated from Dashboard > API Keys, sent via `X-Emby-Token` or `Authorization: MediaBrowser Token="..."`. [jellyfin-issue-14559]
- `/System/Info` (and other non-user-scoped endpoints) succeed with the same dashboard API key that fails on `/Users/Me` — the 400 is specific to endpoints that require a resolved "current user" context, which a dashboard API key does not carry. [jellyfin-issue-14559]
- The documented `Authorization` header format is stricter/different than commonly assumed: `Authorization: MediaBrowser Client="Jellyfin Web", Device="Firefox", DeviceId="...", Version="10.10.1", Token="..."` was found to work where a bare token did not; of these, `Client` and `Token` appear to be the load-bearing fields, `Device`/`DeviceId`/`Version` appear optional. [nielsvanvelzen-gist]
- Practical workaround: don't call `/Users/Me` with a dashboard API key. Either (a) look up the user by a known/configured user ID via `/Users/{userId}` instead of resolving "me", or (b) authenticate via `/Users/AuthenticateByName` to obtain a real user-session access token instead of a static API key. [jellyfin-issue-14559]

## SOURCES

**jellyfin-issue-14559**
URL: https://github.com/jellyfin/jellyfin/issues/14559
Accessed: 2026-08-08
Quote: "/Users/Me returns a 400 when querying with an API key" — reporter used `Authorization: MediaBrowser Token="..."` with a dashboard-generated key; `/System/Info` worked, `/Users/Me` returned 400 Bad Request (RFC 9110 15.5.1).

**nielsvanvelzen-gist**
URL: https://gist.github.com/nielsvanvelzen/ea047d9028f676185832e51ffaf12a6f
Accessed: 2026-08-08
Quote: Confirms bare-token auth against user-scoped endpoints fails; a full `Authorization: MediaBrowser Client="Jellyfin Web", Device=..., DeviceId=..., Version=..., Token=...` header succeeded where a bare token did not.

## SYNTHESIS

This directly explains a PDPP Jellyfin connector failure (packages/polyfill-connectors/connectors/jellyfin/index.ts, `resolveUserId()`) against a real Jellyfin 10.11.11 server: the connector authenticates with a static `JELLYFIN_API_KEY` (a dashboard API key, matching the manifest's setup field) via `X-Emby-Token`, then calls `GET Users/Me` to resolve a user ID for the subsequent `Users/{userId}/Views` and `Users/{userId}/Items` calls. `System/Info` succeeds (proving the key itself is valid/accepted), but `Users/Me` 400s — matching this bug exactly, not a connector bug in the traditional sense but an upstream Jellyfin API/auth-model mismatch between "API key" (app-scoped, no user) and "user session token" (user-scoped).

The durable fix is to stop asking Jellyfin "who am I" via a mechanism that doesn't support API-key auth. Two real options: expose a `JELLYFIN_USER_ID` setup field (owner looks it up once via Dashboard > Users, or the connector resolves it via `/Users` — the *list* endpoint — which may work with an API key since it's not "me"-scoped and typically requires admin API key privileges) rather than depending on `/Users/Me`. Untested here whether `/Users` (list) works with a dashboard API key; that would need live verification before it's assumed safe.
