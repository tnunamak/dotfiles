---
title: "Personal-data import tools (Immich, Timelinize, Dawarich, Apple Health, WhatsApp) scope deduplication per acquisition method, never merge across methods automatically, treat partial coverage and missing media as expected inputs, and never use ingestion time as event time"
date: 2026-06-13
topic: agentic-context-design
tags: [data-import, deduplication, provenance, coverage, ingestion, personal-data, import-ux]
status: draft
sources: [immich-libraries, immich-mobile-backup, immich-15009, immich-1130, timelinize, timelinize-google-loc, timeliner-pkg, dawarich-imports, dawarich-2468, dawarich-merger, google-takeout-incremental, immich-24917, takeout-duplicates, apple-health-export, health-data-importer, rungap, whatsapp-export, importcsv-ux, bulk-ux, csvbox-patterns]
---

## CLAIMS

- Immich separates two acquisition channels with distinct identity anchors — mobile backup (app-authenticated device upload, dedup by file hash + device ID) and external library (filesystem path on server, dedup by file path) — and they are not interchangeable at the data-model level nor auto-deduplicated against each other (open request: Discussion #15009). [immich-libraries][immich-mobile-backup][immich-15009]
- Immich 1.130 (March 2025) rewrote external-library scan for a 10-100x speedup via SQL batching, and its scan stores a path→asset mapping re-run against current filesystem state, marking missing files as offline rather than deleting them. [immich-1130]
- Timelinize defines an explicit `DataSource` type per provider/format, each declaring which acquisition method it supports (API pull via OAuth+poll, export-file import with format auto-detection, or rescan/incremental via ETag/checksum comparison — full re-parse if no checksum is available). [timelinize][timeliner-pkg]
- Timelinize ingests "partial items" (e.g. Google Photos Takeout splits content from metadata across archives) and merges them by a stable key as it progresses; cross-source deduplication is a user-confirmed entity-merge step, not silent; differential reprocessing requires an ETag and its absence is a documented deliberate gap. [timelinize][timelinize-google-loc]
- Dawarich imports asynchronously (upload → format detect → background job → Point records), enforces a `(user_id, latitude, longitude, timestamp)` uniqueness constraint so re-importing the same file is safe, preserves source format as an import-level provenance fact, and polls a watched directory every 60 minutes for auto-ingest. [dawarich-imports][dawarich-merger]
- Dawarich has no server-side cross-source dedup: overlapping-but-non-identical points from a Garmin device and the Dawarich app coexist, and the project frames cross-source dedup as a hard problem without a clean solution (Discussion #2468). [dawarich-2468]
- Google launched Incremental Takeout for Photos in June 2026 (after an initial full export, scheduled exports include only photos added/edited since the last export; Photos must be the only selected product; cadence every two months for one year). [google-takeout-incremental]
- Google Takeout structurally creates duplicate copies of a photo for each album it appears in (by design, not a bug), so any importer must deduplicate by content hash or stable ID, never by filename or path. [takeout-duplicates]
- Immich groups assets by import-execution date rather than EXIF date in some code paths even after EXIF correction, causing thousands of old photos to appear under "today" on incremental Takeout imports (Issue #24917, open as of 2026-06). [immich-24917]
- Apple Health's built-in export is all-or-nothing (full XML, no date-range or metric selection); historical imports via third-party tools (RunGap, Health CSV Importer) are accepted but treated as second-class — they do not retroactively close activity rings or affect trend comparisons — and importers merge by data type + timestamp. [apple-health-export][rungap][health-data-importer]
- WhatsApp's native export separates messages (`.txt`) from media in the same ZIP, correlated by an embedded message ID, and caps at 10,000 messages with media / 40,000 without — so large chats require multiple partial, potentially-overlapping exports, and media is frequently missing by default. [whatsapp-export]
- Data-import UX has a five-stage framework (Pre-upload → Upload → Parse/Map → Validate → Confirm); the most-cited failure mode is investing only in stages 2 and 5 (upload button + success toast) and neglecting parse feedback, duplicate surfacing, and a pre-commit coverage summary. [importcsv-ux][bulk-ux][csvbox-patterns]

## SOURCES

**immich-libraries**
URL: https://docs.immich.app/features/libraries/
Accessed: 2026-06-13

**immich-mobile-backup**
URL: https://docs.immich.app/features/mobile-backup/
Accessed: 2026-06-13

**immich-15009**
URL: https://github.com/immich-app/immich/discussions/15009
Accessed: 2026-06-13

**immich-1130**
URL: https://alternativeto.net/news/2025/3/immich-1-130-enhanced-photo-and-video-management-with-faster-scans-and-smarter-search
Accessed: 2026-06-13

**timelinize**
URL: https://timelinize.com/
Accessed: 2026-06-13

**timelinize-google-loc**
URL: https://timelinize.com/docs/data-sources/google-location-history
Accessed: 2026-06-13

**timeliner-pkg**
URL: https://pkg.go.dev/github.com/mholt/timeliner
Accessed: 2026-06-13

**dawarich-imports**
URL: https://dawarich.app/docs/features/imports/
Accessed: 2026-06-13

**dawarich-2468**
URL: https://github.com/Freika/dawarich/discussions/2468
Accessed: 2026-06-13

**dawarich-merger**
URL: https://dawarich.app/tools/timeline-merger/
Accessed: 2026-06-13

**google-takeout-incremental**
URL: https://www.ghacks.net/2026/06/02/google-photos-adds-incremental-exports-to-takeout-to-avoid-re-downloading-entire-libraries/
Accessed: 2026-06-13

**immich-24917**
URL: https://github.com/immich-app/immich/issues/24917
Accessed: 2026-06-13

**takeout-duplicates**
URL: https://metadatafixer.com/learn/google-takeout-duplicate-photos-explained
Accessed: 2026-06-13

**apple-health-export**
URL: https://www.igeeksblog.com/how-to-import-and-export-health-app-data-on-iphone/
Accessed: 2026-06-13

**health-data-importer**
URL: https://apps.apple.com/us/app/health-data-importer/id1158733998
Accessed: 2026-06-13

**rungap**
URL: https://rungap.zendesk.com/hc/en-us/articles/222528287-Using-Apple-Health-with-RunGap
Accessed: 2026-06-13

**whatsapp-export**
URL: https://waexport.wadesk.io/blog/whatsapp-chat-history-export
Accessed: 2026-06-13

**importcsv-ux**
URL: https://www.importcsv.com/blog/data-import-ux
Accessed: 2026-06-13

**bulk-ux**
URL: https://smart-interface-design-patterns.com/articles/bulk-ux/
Accessed: 2026-06-13

**csvbox-patterns**
URL: https://blog.csvbox.io/file-upload-patterns/
Accessed: 2026-06-13

## SYNTHESIS

Convergent design rules for a generalized personal-data acquisition/coverage model: (1) the dedup unit must be defined per acquisition method — content hash for media, coordinate+timestamp for GPS tracks, message ID for chat — never a single universal key; (2) do not attempt automatic cross-method merge (no prior-art tool does it cleanly); surface overlaps as an informational fact and preserve both ingestion events, letting the owner decide; (3) partial coverage and missing media are expected inputs, not error states, so ingest must be idempotent (re-uploading the same export is safe and reports new-vs-known); (4) never use ingestion time as the record's event time — the canonical time is what was in the source file. Four distinct acquisition methods recur with different identity semantics: provider_api (stable resource ID), owner_export_upload (content hash / embedded stable ID), device_sync (device ID + path/UUID), and assisted_manual (= owner_export_upload with a requires-human-trigger flag — not a fifth method, since parse/dedup/coverage mechanics are identical). Essential provenance facts for an export upload: source_format, source_format_version, an idempotent upload_id, content_hash, record_count_in_source vs record_count_ingested, media_declared_count vs media_attached_count, time_range_covered, parsed_at, and parser_version. The confirmation/receipt step is where coverage reporting belongs ("73 new, 12 already known, 8 without media"), and non-OAuth sources should show what you have, when it is from, and how to refresh — never a fake OAuth button or "syncing" language for a manual re-export.
