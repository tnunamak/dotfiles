---
title: "Google's Data Portability API can export Maps resources (starred/labeled places, reviews, activity) via OAuth, but does NOT expose raw Timeline location points/segments, which live device-locally"
date: 2026-06-11
topic: data-portability
tags: [google, data-portability, oauth, google-maps, timeline, location-history]
status: draft
sources: [dpapi-intro, dpapi-oauth, dpapi-time-based, dpapi-scopes, dpapi-methods, dpapi-rest, dpapi-initiate, dpapi-archive-state, dpapi-access-check, dpapi-maps-schema, dpapi-local-actions, gmaps-timeline-help]
---

## CLAIMS

- Google exposes a Data Portability API with OAuth consent and time-based exports; its documented flow is OAuth consent, optionally check access type, initiate a portability archive, poll archive state on Google's 5-to-60-minute cadence, then download signed archive URLs when Google returns `COMPLETE`. [dpapi-intro] [dpapi-methods]
- The concrete Data Portability REST endpoints are `POST https://dataportability.googleapis.com/v1/accessType:check`, `POST https://dataportability.googleapis.com/v1/portabilityArchive:initiate`, and `GET https://dataportability.googleapis.com/v1/archiveJobs/{job}/portabilityArchiveState`. [dpapi-rest] [dpapi-initiate] [dpapi-archive-state] [dpapi-access-check]
- The Data Portability API's Maps scopes cover resources such as starred places, labeled places, commute routes/settings, vehicle profiles, reviews, photos/videos, Q&A, Maps activity, and My Maps; the Maps schema reference was current as of a 2026-03-16 update. [dpapi-maps-schema] [dpapi-local-actions]
- The Data Portability Maps schema does NOT document raw Timeline point or Timeline segment resources (i.e. no equivalent to `timeline_points`/`timeline_segments`). [dpapi-maps-schema]
- Time-based Data Portability access can support repeated exports but Google documents a 24-hour cadence floor and requires a refresh token for later exports. [dpapi-time-based]
- Data Portability scopes carry platform constraints: the app must be approved before release, DPAPI scopes cannot be mixed with non-DPAPI scopes such as userinfo email, the app must handle partial scope consent, and the OAuth token is opaque so the app does not learn which Google Account was used from the OAuth flow alone. [dpapi-scopes] [dpapi-oauth]
- Google's Timeline help documents that Timeline data is saved on signed-in devices, that backup is an encrypted server copy for device restore/import, that desktop Timeline is not available because Timeline comes from the device, and that the documented export path is a mobile export action. [gmaps-timeline-help]

## SOURCES

**dpapi-intro**
URL: https://developers.google.com/data-portability/user-guide/introduction
Accessed: 2026-06-11

**dpapi-oauth**
URL: https://developers.google.com/data-portability/user-guide/configure-oauth
Accessed: 2026-06-11

**dpapi-time-based**
URL: https://developers.google.com/data-portability/user-guide/time-based
Accessed: 2026-06-11

**dpapi-scopes**
URL: https://developers.google.com/data-portability/user-guide/scopes
Accessed: 2026-06-11

**dpapi-methods**
URL: https://developers.google.com/data-portability/user-guide/methods
Accessed: 2026-06-11

**dpapi-rest**
URL: https://developers.google.com/data-portability/reference/rest
Accessed: 2026-06-11

**dpapi-initiate**
URL: https://developers.google.com/data-portability/reference/rest/v1/portabilityArchive/initiate
Accessed: 2026-06-11

**dpapi-archive-state**
URL: https://developers.google.com/data-portability/reference/rest/v1/archiveJobs/getPortabilityArchiveState
Accessed: 2026-06-11

**dpapi-access-check**
URL: https://developers.google.com/data-portability/reference/rest/v1/accessType/check
Accessed: 2026-06-11

**dpapi-maps-schema**
URL: https://developers.google.com/data-portability/schema-reference/maps
Accessed: 2026-06-11

**dpapi-local-actions**
URL: https://developers.google.com/data-portability/schema-reference/local_actions
Accessed: 2026-06-11

**gmaps-timeline-help**
URL: https://support.google.com/maps/answer/6258979
Accessed: 2026-06-11

## SYNTHESIS

Google offers two distinct Google-Maps data surfaces that are easy to conflate. The Data Portability API is a real OAuth-backed, time-based export mechanism (initiate archive → poll → download signed URLs) but only for the Maps resource groups Google documents — starred/labeled places, commute routes, reviews, photos, Q&A, Maps activity, My Maps — and it explicitly does NOT expose raw Timeline location points/segments. Timeline location history is a separate, device-local product: current Google docs say Timeline lives on signed-in devices, its backup is an encrypted server copy for device restore only, and the sole documented export path is a mobile export action. Consequently, any Maps *Timeline* location-history ingestion must be modeled as an owner-provided export/import flow, not a Gmail/IMAP-style background API connection — and an API-backed Maps connector (if built on the Data Portability API) is a genuinely different data product, not a substitute for Timeline. Operationally, the Data Portability API also imposes app approval, no scope-mixing with userinfo, partial-consent handling, an opaque token that hides account identity, and a 24-hour repeat-export cadence floor.
