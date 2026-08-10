---
title: "As of August 2026, several consumer-data-platform acquisition paths diverged from common assumptions: Google Photos lost broad library-read access for all apps (not just new ones), Jellyfin ships SQLite-only with no session-level history in core API, Steam's rtime_last_played is undocumented and self-key-scoped, and several claimed API/rate-limit facts for Google Contacts, Google Messages, GroupMe, and Apple CardDAV do not exist in official docs"
date: 2026-08-07
topic: connectors
tags: [google-photos, google-calendar, google-contacts, apple-carddav, steam-web-api, jellyfin, netflix, groupme, google-messages, oauth-scopes]
status: draft
sources: [google-photos-picker-launch, google-takeout-faq, google-calendar-quota, google-people-api, google-contacts-v3-turndown, google-messages-backup-help, google-takeout-product-list, apple-app-specific-passwords, apple-carddav-mdm-schema, apple-photokit, apple-contacts-framework, apple-signin-scopes, osxphotos-release, steam-webapi-auth, steam-iplayerservice, jellyfin-latest-release, jellyfin-playbackreporting, netflix-getmyinfo, groupme-api-v3, groupme-oauth]
source_session: 7e594ca7-d465-4c20-90cf-a54ed0dc6872
---

## CLAIMS

- Google Photos' broad library-read OAuth scopes (`photoslibrary.readonly`, `photoslibrary`, `photoslibrary.sharing`) were removed for ALL apps, not merely new ones, effective March 31, 2025 — remaining scopes cover only app-created content, and new apps must use the per-item, user-driven Photos Picker API instead of any bulk/background-sync mechanism. [google-photos-picker-launch]
- Google Takeout's automatic-recurring-export cadence is documented at exactly "every 2 months for one year," with generated archives expiring after ~7 days and limited to 5 downloads. [google-takeout-faq]
- Neither Google Calendar nor Google Photos has a Data Portability API resource group (`dataportability.*` scopes) — that mechanism, which PDPP already uses for Google Maps, covers Maps, YouTube, Chrome, Fitbit, Play Store, and Search/Shopping/Discover activity only. [google-photos-picker-launch]
- Google Calendar API quotas were restructured effective May 1, 2026: new Cloud projects get 10,000 requests/minute per project and 600 requests/minute per user per project, plus a 1,000,000 requests/day-per-project billing threshold — this supersedes older per-second/per-user-per-day figures often cited from pre-2026 sources. [google-calendar-quota]
- The legacy Google "Contacts API v3" (GData/Atom, `gd:email`/`gd:phonenumber` field style) was turned down on January 19, 2022; the current API is People API v1 (JSON/REST, `people.connections.list`). Citing v3 field names alongside current rate limits is a conflation of a dead API with a live one. [google-contacts-v3-turndown]
- People API v1's incremental mechanism is a `syncToken` (obtained via `requestSyncToken=true` on an initial full sync, returned as `nextSyncToken`), not a `updated-min` timestamp filter — `updated-min` was a Contacts API v3 (dead) parameter. Deleted contacts surface via `PersonMetadata.deleted: true` when a syncToken is supplied. Sync tokens expire 7 days after the full sync that produced them. [google-people-api]
- No official People API v1 page publishes fixed numeric quota values (e.g. "1,000 requests/user/day, 100 req/sec") — the real quota page (`developers.google.com/people/legacy/limits`) points to Google Cloud Console's per-project Quotas tab for live, project-configurable numbers; a commonly-cited fixed-quota URL (`.../people/v1/how-tos/quota`) 404s. [google-people-api]
- Google Messages has no official consumer data export or API. Its "Back up & sync messages" feature routes through Google One / general Android device backup (bundled into the ~15GB free tier), restorable only via the Messages app on a new/restored device — there is no Gmail-API-queryable path for SMS/RCS content. [google-messages-backup-help]
- Google Takeout's official exportable-product list does not include Messages, Google Messages, SMS, or RCS as of 2026-08-07 (Gmail, Drive, Photos, Calendar, Contacts, YouTube, etc. are listed). [google-takeout-product-list]
- Apple's own support docs (support.apple.com/en-us/102654 and /en-us/121539) explicitly name "mail, contacts, and calendars" as supported use cases for app-specific-password authentication to third-party apps — Contacts is an Apple-documented use case for this auth mechanism. [apple-app-specific-passwords]
- No Apple-published page (developer.apple.com or support.apple.com) documents the iCloud CardDAV hostname (commonly `contacts.icloud.com` or regional variants like `pXX-contacts.icloud.com`) or its wire-protocol operations. Apple's only public CardDAV documentation is a generic MDM device-management payload schema that takes an admin-supplied hostname and never names iCloud's own server; the hostname is known only through third-party client documentation (DAVx5) and community reverse engineering. [apple-carddav-mdm-schema]
- PhotoKit (developer.apple.com/documentation/photokit) is Apple's sanctioned API for local Photos library access (assets, EXIF, albums, Moments/Memories, People/face groupings), gated by `NSPhotoLibraryUsageDescription` — it is native Swift/Objective-C only, not reachable from a plain Node/TypeScript process without a compiled native bridge. [apple-photokit]
- The Contacts framework (`CNContactStore`, developer.apple.com/documentation/contacts) is Apple's sanctioned local-contacts API, also native-only, and exposes only the local on-device contacts database — it is not a path to direct iCloud-hosted contact access (that requires CardDAV or on-device sync). [apple-contacts-framework]
- No Apple documentation anywhere describes the iMessage `~/Library/Messages/chat.db` SQLite schema (tables like `message`, `handle`, `chat`, `attachment`) — all such schema knowledge is reverse-engineered by open-source forensics/backup projects, not Apple-published. The Contacts framework and Messages app-extension framework are unrelated to this file format. [apple-contacts-framework]
- osxphotos (reads `Photos.sqlite` directly inside `.photoslibrary`, bypassing PhotoKit) was actively maintained as of release v0.76.1 (2026-06-14), with the maintainer explicitly documenting the schema as brittle across macOS versions (broke on a 14.6 update; not fully supported on macOS 26/Tahoe as of mid-2026). [osxphotos-release]
- Sign In with Apple exposes only `.fullName` and `.email` as requestable OAuth scopes — no photos or contacts scope exists via this mechanism. [apple-signin-scopes]
- Steam Web API keys are free, self-service, and tied to the requesting user's own Steam account (no developer registration/review process) via steamcommunity.com/dev/apikey. [steam-webapi-auth]
- Steam's official `IPlayerService/GetOwnedGames` documentation does not state that an authenticated request bypasses the target profile's "Game details" privacy setting for the key owner's own library — only that it returns games "visible to you." Community reports on this bypass are mixed, not confirmed. [steam-iplayerservice]
- Steam's `rtime_last_played` field is absent from Valve's official `IPlayerService` documentation entirely (undocumented, community-observed only) and is reported by the community to be populated only when the request uses the API key belonging to the very user whose data is being fetched — for other users' data it is dropped, leaving only `appid` and `playtime_forever`. [steam-iplayerservice]
- Jellyfin does not officially support PostgreSQL as of August 2026 — the shipped backend since v10.11.0 is a single consolidated SQLite `jellyfin.db` file; PostgreSQL exists only as a third-party plugin explicitly labeled "highly experimental, not meant for a production server," with Jellyfin's own release notes framing the underlying EF Core migration as merely opening future possibilities, not delivering Postgres support now. [jellyfin-latest-release]
- The latest stable Jellyfin release as of August 2026 is v10.11.11 (released 2026-06-06) — a commonly-cited "v10.9.x" figure is outdated. A next-generation 12.0 release was in release-candidate status, not yet stable. [jellyfin-latest-release]
- Jellyfin's core REST API (`UserItemDataDto`) exposes only `LastPlayedDate` (single most-recent timestamp, not a history list), `PlayCount` (aggregate integer), and `Played` (boolean) per item — genuine session-level watch history with multiple past-play timestamps requires the separate, optional PlaybackReporting plugin, which maintains its own database of individual playback events. Direct SQLite/Postgres database access is not an officially documented or endorsed integration path. [jellyfin-playbackreporting]
- Netflix provides two distinct self-service export mechanisms that are easily conflated: `netflix.com/account/getmyinfo` ("Download your personal information") is the full/rich export (up to 30-day turnaround, 7-day download-link validity, includes device type and percent-watched via `ViewingActivity.csv`), while `netflix.com/viewingactivity` is an instant but minimal export (title + watched date only, no device/duration/percent fields). [netflix-getmyinfo]
- Netflix's internal `/api/shakti/<build_number>/viewingactivity` GraphQL-style endpoint is corroborated as real and currently reverse-engineerable by multiple independent third-party technical sources (a detailed captured-live-request writeup, a GitHub extraction tool specifying the exact path and required session cookies, an independent technical blog, and an unofficial .NET client) — it is genuinely undocumented/unofficial/session-cookie-dependent, not a fabricated claim. [netflix-getmyinfo]
- GroupMe's official API v3 documentation (dev.groupme.com/docs/v3) publishes no exact numeric rate limits at all — no per-second, per-minute, burst, or Retry-After specification exists in the docs, despite commonly-repeated specific numbers (e.g. "10 req/sec, 600/min burst") circulating without a documented source. [groupme-api-v3]
- GroupMe's documented, standard third-party app-auth model is OAuth 2.0 implicit grant (redirect to `oauth.groupme.com/oauth/authorize`); a separate manual personal-access-token copy from the developer portal is a self-only developer convenience, not a replacement for OAuth2 as the general auth model. [groupme-oauth]

## SOURCES

**google-photos-picker-launch**
URL: https://developers.googleblog.com/en/google-photos-picker-api-launch-and-library-api-updates/
Accessed: 2026-08-07
Quote: "changes take effect on March 31, 2025"

**google-takeout-faq**
URL: https://support.google.com/accounts/answer/3024190
Accessed: 2026-08-07
Quote: "Automatically create an archive of your selected data every 2 months for one year"

**google-calendar-quota**
URL: https://developers.google.com/workspace/calendar/api/guides/quota
Accessed: 2026-08-07
Quote: "as of May 1, 2026, new Cloud projects get 10,000 requests/minute per project and 600 requests/minute per user per project, plus a 1,000,000 requests/day per project billing threshold"

**google-contacts-v3-turndown**
URL: https://developers.google.com/contacts/v3/reference
Accessed: 2026-08-07
Quote: "The Contacts API was turned down on January 19, 2022."

**google-people-api**
URL: https://developers.google.com/people/api/rest/v1/people.connections/list
Accessed: 2026-08-07
Quote: "A sync token, received from a previous response nextSyncToken. Provide this to retrieve only the resources changed since the last request." / "When the syncToken is specified, resources deleted since the last sync will be returned as a person with PersonMetadata.deleted set to true." / sync tokens expire 7 days after the full sync

**google-messages-backup-help**
URL: https://support.google.com/messages/answer/2819582
Accessed: 2026-08-07
Quote: backup/restore documented as routing through Google One / Android device backup, no mention of Gmail or any Gmail-API-accessible path

**google-takeout-product-list**
URL: https://support.google.com/accounts/answer/3024190
Accessed: 2026-08-07
Quote: Messages/SMS/RCS absent from the enumerated list of exportable Takeout products

**apple-app-specific-passwords**
URL: https://support.apple.com/en-us/102654 ; https://support.apple.com/en-us/121539
Accessed: 2026-08-07
Quote: "Some apps made by developers other than Apple ask you to sign in to your Apple Account, so that the app can access information like mail, contacts, and calendars that you store in iCloud"

**apple-carddav-mdm-schema**
URL: https://developer.apple.com/documentation/devicemanagement/carddav
Accessed: 2026-08-07
Quote: generic CardDAV MDM payload schema (Hostname, Port, Principal URL fields) with no iCloud-specific hostname named; zero search hits for "contacts.icloud.com" across support.apple.com

**apple-photokit**
URL: https://developer.apple.com/documentation/photokit
Accessed: 2026-08-07
Quote: native Swift/Objective-C framework for asset/album/People access, gated by NSPhotoLibraryUsageDescription

**apple-contacts-framework**
URL: https://developer.apple.com/documentation/contacts
Accessed: 2026-08-07
Quote: CNContactStore documented as local on-device contacts access, no chat.db or Messages schema content

**apple-signin-scopes**
URL: https://developer.apple.com/documentation/authenticationservices/asauthorization/scope
Accessed: 2026-08-07
Quote: only `.fullName` and `.email` scope cases documented

**osxphotos-release**
URL: PyPI osxphotos release history
Accessed: 2026-08-07
Quote: latest release v0.76.1, 2026-06-14; maintainer notes on macOS 14.6 schema breakage and macOS 26 support gaps

**steam-webapi-auth**
URL: https://partner.steamgames.com/doc/webapi_overview/auth
Accessed: 2026-08-07
Quote: "The standard user keys are available to everyone, all that is required is a Steam account and the domain name that will be associated with this key."

**steam-iplayerservice**
URL: https://partner.steamgames.com/doc/webapi/iplayerservice
Accessed: 2026-08-07
Quote: "Returns a list of games owned by the player if their owned games/game details are visible to you." — no `rtime_last_played` field documented on this page at all

**jellyfin-latest-release**
URL: https://github.com/jellyfin/jellyfin/releases/tag/v10.11.11
Accessed: 2026-08-07
Quote: v10.11.11 released 2026-06-06; 10.11.0 release notes frame EF Core migration as opening "new possibilities—not officially yet, but soon" for external DBs like PostgreSQL

**jellyfin-playbackreporting**
URL: https://github.com/jellyfin/jellyfin-plugin-playbackreporting
Accessed: 2026-08-07
Quote: separate plugin maintaining its own database of individual playback session events, distinct from core UserItemDataDto's LastPlayedDate/PlayCount fields

**netflix-getmyinfo**
URL: https://www.netflix.com/account/getmyinfo ; corroborating third-party Shakti API writeups found via search
Accessed: 2026-08-07
Quote: getmyinfo export includes ViewingActivity.csv under CONTENT_INTERACTION with device type and watch-depth fields; viewingactivity page is instant but title+date only

**groupme-api-v3**
URL: https://dev.groupme.com/docs/v3
Accessed: 2026-08-07
Quote: no rate-limit section with numeric per-second/per-minute/burst/Retry-After values present in the documentation

**groupme-oauth**
URL: https://dev.groupme.com/tutorials/oauth
Accessed: 2026-08-07
Quote: OAuth 2.0 implicit grant flow documented as the standard third-party app authorization mechanism

## SYNTHESIS

The consistent failure pattern across all four preliminary reports this research corrected was **conflating a dead or different API's parameters/limits with a live one's** — Contacts API v3's `updated-min` presented as if it were People API's incremental mechanism, Calendar's pre-2026 quota figures presented as current, and in one case a rate-limit figure (GroupMe) that doesn't exist in any version of the docs. The tell was always a suspiciously precise-sounding number or field name attached to a page that, when actually fetched, either 404s, doesn't mention the number, or describes a different (often deprecated) system. The corrective habit worth carrying forward: when a report cites "[OFFICIAL]" next to a specific number, fetch the exact cited URL and grep for the literal figure before trusting it — several of these numbers were plausible-sounding fabrications, not stale-but-real data.

Second pattern: several platforms have a real, sanctioned-but-narrow official path plus a broader, undocumented-but-functional community path (Apple PhotoKit vs. osxphotos' raw SQLite reads; Apple CardDAV auth being official while its hostname is not; Netflix's slow rich export vs. the unofficial-but-real Shakti GraphQL capture). Treating "auth mechanism is documented" and "protocol endpoint/hostname is documented" as the same claim is a common and costly conflation — they should always be adjudicated separately, since one often survives scrutiny while the other doesn't.

Third, Google's 2025-2026 restructuring of Photos access (broad reads removed for everyone, not just new apps) and the general move toward the Data Portability API for some-but-not-all Google products (Maps yes, Calendar/Photos/Contacts no) means any assumption "Google always has an OAuth scope for X" needs a fresh per-product check — the OAuth surface is actively shrinking and fragmenting by product, not stable.
