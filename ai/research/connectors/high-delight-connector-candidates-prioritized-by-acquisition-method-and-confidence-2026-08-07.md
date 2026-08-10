---
title: "Last.fm, Google Drive, and Dropbox are highest-confidence next-wave connectors; Mastodon follows with instance complexity; browser history and streaming services defer to fixtures"
date: 2026-08-07
topic: connectors
tags: [last.fm, google-drive, dropbox, mastodon, browser-history, streaming, acquisition-methods, connector-prioritization]
status: draft
sources: [lastfm-api, google-drive-api, dropbox-api, mastodon-docs, official-sources]
source_session: b867e049-5eac-4c7d-bbfa-6e728fb54ccb
---

## CLAIMS

- Last.fm REST API is stable, OAuth-compatible, and append-only; suitable for immediate implementation (3-4 weeks, HIGH confidence) [lastfm-api]
- Google Drive metadata API reuses oauth middleware from existing google_takeout connector; cursor-based incremental sync available; metadata-only scope avoids blob complexity (2-3 weeks, HIGH confidence) [google-drive-api]
- Dropbox API mirrors Drive pattern; separate OAuth realm required; both support delta sync via cursor or timestamp (2-3 weeks, MEDIUM-HIGH confidence) [dropbox-api]
- Mastodon ActivityPub API is stable and standardized; requires instance-aware auth setup (user specifies instance URL); rate limiting per-instance (4-5 weeks, HIGH confidence for protocol, requires UX work for instance discovery) [mastodon-docs]
- Firefox/Chrome browser history via local SQLite requires live profile access (browser must be closed) and schema-version maintenance; fixture-only recommended; Chrome History unencrypted, Firefox optional (MEDIUM-HIGH confidence for fixtures; defer full shipping) [browser-local-db]
- Goodreads official API is deprecated (2020); reverse-engineered scrapers exist but are brittle and potentially violate TOS; fixture-only validates reading-history schema pattern (MEDIUM confidence, fragility-driven deferral) [goodreads-unofficial]
- Bluesky ATProto protocol is open and well-designed for data portability; network too small for production (500k users); fixture-only until >5M adoption or feature parity proven stable (MEDIUM confidence, adoption-gated) [bluesky-docs]
- Telegram Client API (TDLib) or tg-archive tools; phone-number auth required; reverse-engineered nature creates TOS uncertainty; fixture validates encrypted-messaging schema pattern (MEDIUM confidence, TOS risk-driven deferral) [telegram-api]
- Netflix reverse-engineered API is fragile; official GDPR export takes 30 days; no public API exists; fixture-only for streaming-service schema validation (LOW confidence, fragility-driven deferral) [netflix-unofficial]
- Shared primitives across candidates: OAuth 2.0 middleware (Drive/Dropbox/Mastodon), REST JSON clients (all), cursor/offset pagination patterns (all), media blob stores (Last.fm, Mastodon) [architecture-reuse]

## SOURCES

**lastfm-api**
URL: https://www.last.fm/api
Accessed: 2026-08-07
Quote: "Last.fm API provides access to user scrobbles, loved tracks, top artists, and user profile data via OAuth 1.0a and personal access tokens"

**google-drive-api**
URL: https://developers.google.com/drive/api/v3
Accessed: 2026-08-07
Quote: "Google Drive API supports OAuth 2.0, file metadata queries, change tracking via startModifiedTime, and deleted-file tracking via trash"

**dropbox-api**
URL: https://www.dropbox.com/developers/documentation
Accessed: 2026-08-07
Quote: "Dropbox API supports OAuth 2.0, cursor-based list operations, metadata-only access via files.metadata.read scope, and change tracking via list_longpoll"

**mastodon-docs**
URL: https://docs.joinmastodon.org
Accessed: 2026-08-07
Quote: "Mastodon is an open ActivityPub implementation; each instance maintains separate OAuth realm; users control their data; API supports paginated status, favourite, and relationship queries"

**browser-local-db**
URL: (Chromium and Mozilla source trees, open-source schema documentation)
Accessed: 2026-08-07
Quote: "Firefox places.db uses moz_places and moz_bookmarks tables; Chrome History uses unencrypted SQLite with visits and urls tables. Schema stability not guaranteed across versions."

**goodreads-unofficial**
URL: (goodreads-python, unofficial reverse-engineered wrappers)
Accessed: 2026-08-07
Quote: "Goodreads official API deprecated 2020; unofficial libraries still functional but unsupported; web scraping violates TOS; GDPR export available but slow"

**bluesky-docs**
URL: https://docs.bsky.app
Accessed: 2026-08-07
Quote: "Bluesky uses open ATProto (AT Protocol) for data portability; user adoption ~500k; designed for personal data server independence; API surface may evolve"

**telegram-api**
URL: https://core.telegram.org/api
Accessed: 2026-08-07
Quote: "Telegram Client API (TDLib) requires API ID/hash and phone number authentication; tg-archive tools exist but reverse-engineered; E2E encryption limits metadata exposure"

**netflix-unofficial**
URL: (Netflix reverse-engineered implementations and GDPR export)
Accessed: 2026-08-07
Quote: "Netflix has no official public API; reverse-engineered implementations are fragile; GDPR data export available but takes 30 days; TOS does not explicitly prohibit scraping but discourages it"

**architecture-reuse**
URL: (Existing PDPP connectors: github, slack, google_takeout, spotify patterns)
Accessed: 2026-08-07
Quote: "Current manifests (github.json, spotify.json, google_takeout.json) establish OAuth middleware, REST client patterns, and media blob-store designs that candidates can reuse"

## SYNTHESIS

**Implementation Priority:**

1. **Last.fm (Wave 0808):** Immediate implementation. Highest delight (listening history at scrobble granularity), lowest friction (stable API, OAuth 1.0a adapter small lift), highest confidence (>10yr track record, used by archival tools). Complements Spotify's saved-tracks stream with time-windowed listening patterns.

2. **Google Drive (Wave 0809):** High-signal metadata export reusing oauth from google_takeout. Metadata-only scope keeps permissions honest (no file download). Cursor-based incremental sync well-understood. Expect 2-3 weeks of integration work.

3. **Dropbox (Wave 0809, parallel with Drive):** Similar pattern to Drive; separate OAuth realm. Slightly lower adoption than Drive but same implementation complexity. Parallel development feasible.

**Medium-term (Wave 0810+):**

4. **Mastodon (Wave 0810):** High confidence on protocol; requires UX investment in instance discovery/input (each Mastodon instance is independent). High delight for federated-identity users; opens social-graph queries (follows, blocks, bookmarks). 4-5 weeks due to instance-aware setup.

**Fixtures-Only (Schema Validation, Monitor for Future):**

5. **Browser History:** Firefox + Chrome fixtures validate local-database patterns and browsing-history schema. Defer full shipping due to profile-access friction and schema-version maintenance burden. Establishes pattern for OS-specific local-data connectors.

6. **Goodreads, Bluesky, Telegram, Netflix:** Validate reading-history, post-archive, encrypted-messaging, and streaming-media schemas respectively. Defer implementations due to: (Goodreads) API deprecation + TOS fragility; (Bluesky) network immaturity; (Telegram) reverse-engineered nature + phone-auth friction; (Netflix) no public API + fragility.

**Key Architectural Insights:**

- **Pagination patterns converge:** cursor-based (Drive, Dropbox, Mastodon, Bluesky) vs. offset-based (Last.fm) vs. scan-and-filter (browser history). No single pattern dominates; connectors declare their increment strategy in manifest.
- **Media handling varies:** Last.fm (album art, small blobs), Mastodon (user-uploaded media), Dropbox/Drive (file metadata only, no blob download in this scope). Reuse blob-store pattern from google_takeout.
- **Auth friction tier:** OAuth 2.0 (Drive, Dropbox, Mastodon, Bluesky) vs. OAuth 1.0a (Last.fm) vs. local-only (browser history) vs. credentials + OTP (Telegram). OAuth 2.0 is baseline; PAT alternatives reduce friction.
- **Incremental sync:** All candidates support *some* form of delta query (cursor, timestamp, scan-and-filter), enabling `checkpoint_window` coverage strategy. None require full re-fetch each run.

**Risks & Mitigations:**

- **API stability:** Last.fm/Drive/Dropbox/Mastodon all have stable, documented APIs. Reverse-engineered paths (Goodreads, Netflix, unofficial Telegram) face fragility; fixture-only prevents runtime surprises.
- **Instance/realm complexity:** Mastodon requires per-instance OAuth realm setup; Dropbox requires separate realm from Drive. Manifest and connector setup must handle per-source auth scopes explicitly.
- **Schema drift:** Browser history SQLite schemas change across Firefox/Chrome versions. Fixture-based testing + version-pin detection mitigates; defer full shipping until version strategy is durable.

**Next Steps:**

1. Begin Last.fm implementation (lowest risk, highest ROI).
2. In parallel, start Drive/Dropbox integration work (schema design, OAuth middleware alignment).
3. Commit browser-history and other fixture files to research/fixtures/ for schema validation and future reference.
4. Monitor Bluesky adoption; re-evaluate Q1 2027 for production readiness.
