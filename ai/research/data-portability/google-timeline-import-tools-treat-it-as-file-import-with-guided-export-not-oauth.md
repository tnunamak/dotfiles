---
title: "Every Google Timeline ingestion tool treats it as a guided file import (not OAuth), and the best setup UX pairs one drop zone with in-place, platform-specific export instructions"
date: 2026-06-11
topic: data-portability
tags: [google-maps, timeline, location-history, import-ux, web-share-target, google-takeout, dawarich]
status: draft
sources: [gmaps-timeline-help, google-download-data, web-share-target-chrome, web-share-target-mdn, android-receive-data, dpapi-intro, dawarich-home, dawarich-vs-timeline, dawarich-alternatives, timelinize-google, timelinize-import, hpi-readme, takeout-parser, owntracks, google-takeout]
source_session: 019e3c96-4e66-7611-9c00-c7498d13dfa7
---

## CLAIMS

- Google's current official Timeline export path is not OAuth: Timeline data is exported from Android settings under Location services > Timeline > Export Timeline data, plus a device-to-device backup/import, but there is no server-side API returning raw Timeline points/segments. [gmaps-timeline-help]
- The Google Data Portability API's Maps schema lists Maps resource groups (commute routes, settings, reviews, photos/videos, Q&A, pinned/aliased places) but does not document the raw Timeline point/segment data that file-import connectors emit. [dpapi-intro]
- Timelinize treats Google Location History as a file import with explicit device-export steps, and its general model is a "+ Import" flow (choose/import the file), with the caveat that large imports copy data into the timeline folder. [timelinize-google] [timelinize-import]
- Dawarich treats Google Timeline as an import surface and its public visualizer pairs a drop zone with a "Don't have your data yet?" affordance, explicit supported formats, and local-processing reassurance; its migration guide distinguishes Semantic Location History files, `Records.json`, and phone exports with different paths for heavy files. [dawarich-home] [dawarich-vs-timeline] [dawarich-alternatives]
- HPI and google_takeout_parser are developer-oriented parsing/caching libraries for Takeout data, not consumer-grade setup UX; their reusable lesson is to hide parsing/locating behind a stable data interface once the export is supplied. [hpi-readme] [takeout-parser]
- Continuous-tracking products (Dawarich mobile, OwnTracks, Overland, GPSLogger, Traccar) do not import historical Google Timeline by OAuth; they collect location "from now on" via a mobile app or device protocol, and their setup lesson is QR/config handoff to a device rather than archive import. [owntracks] [dawarich-alternatives]
- On Android, an installed PWA can register as a system share target via the Web Share Target manifest member, and native Android apps can receive files via standard sharing intents; on iOS, ordinary web upload is the reliable baseline because cross-browser PWA share-target support is not strong enough to assume receipt of arbitrary files from the iOS share sheet. [web-share-target-chrome][web-share-target-mdn][android-receive-data]
- Google Takeout is a separate partially-automatable historical-export lane: it supports delivery by emailed download link or into Google Drive/Dropbox/OneDrive/Box, scheduled exports every two months for one year (first archive created immediately), archive expiry/download limits, and URL parameters that can preselect products, cloud destination, and `frequency=2_months`. [google-takeout]
- After Google's device-local Timeline migration, some Takeout exports contain only encrypted-backup metadata (e.g. `Encrypted Backups.txt`, `Settings.json`, `Tombstones.csv`) rather than usable Timeline records. [gmaps-timeline-help]

## SOURCES

**gmaps-timeline-help**
URL: https://support.google.com/maps/answer/6258979?co=GENIE.Platform%3DAndroid&hl=en
Accessed: 2026-06-11

**google-download-data**
URL: https://support.google.com/accounts/answer/3024190
Accessed: 2026-06-11

**web-share-target-chrome**
URL: https://developer.chrome.com/docs/capabilities/web-apis/web-share-target
Accessed: 2026-06-11

**web-share-target-mdn**
URL: https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Manifest/Reference/share_target
Accessed: 2026-06-11

**android-receive-data**
URL: https://developer.android.com/training/sharing/receive
Accessed: 2026-06-11

**dpapi-intro**
URL: https://developers.google.com/data-portability/user-guide/introduction
Accessed: 2026-06-11

**dawarich-home**
URL: https://dawarich.app/
Accessed: 2026-06-11

**dawarich-vs-timeline**
URL: https://dawarich.app/docs/comparisons/vs-google-timeline/
Accessed: 2026-06-11

**dawarich-alternatives**
URL: https://dawarich.app/blog/best-google-timeline-alternatives-in-2026-ranked/
Accessed: 2026-06-11

**timelinize-google**
URL: https://timelinize.com/docs/data-sources/google-location-history
Accessed: 2026-06-11

**timelinize-import**
URL: https://timelinize.com/docs/importing-data
Accessed: 2026-06-11

**hpi-readme**
URL: https://github.com/karlicoss/HPI
Accessed: 2026-06-11

**takeout-parser**
URL: https://github.com/purarue/google_takeout_parser
Accessed: 2026-06-11

**owntracks**
URL: https://owntracks.org/
Accessed: 2026-06-11

**google-takeout**
URL: https://support.google.com/accounts/answer/3024190
Accessed: 2026-06-11

## SYNTHESIS

Across the whole ecosystem, Google Timeline location history is treated as a file-import problem, never an OAuth connection: Google's own only-documented export is an on-device action, and every ingestion tool (Dawarich, Timelinize, Google Maps Timeline Viewer, GoogleTimelineMapper, MileageWise, plus generic converters) assumes a file already exists. The tools split into four buckets — history import/viewers, continuous-tracking apps (OwnTracks/Overland/Traccar, whose setup lesson is QR/config device handoff), developer parsing libraries (HPI, google_takeout_parser: hide parsing behind a stable interface), and adjacent travel apps (weak prior art). The best observed setup UX patterns are reusable for any file-import connector: one obvious drop zone rather than a status taxonomy; a "Don't have your data yet?" export-instructions affordance placed right next to the drop zone; platform-specific (Android vs iOS) exact settings paths; format empathy (list accepted file names, auto-detect after upload); immediate local validation with estimated record counts and a concrete next action on the wrong file; privacy reassurance at the action point; a large-file off-ramp (server import folder rather than a normal web upload); and an immediate post-import payoff (map/stat/timeline, not just a run log). Two acquisition enhancements are worth modeling as optional capabilities rather than the default: on Android, a PWA/native share-target handoff (`web_upload` works everywhere but is least delightful; an Android share target is a good low-friction path; iOS is upload-first until a native helper/Shortcut is proven); and scheduled Google Takeout-to-Drive as a best-effort recurring backup (with the caveat that after the device-local migration, Takeout may return only encrypted-backup metadata, so a phone-export fallback is still required).
