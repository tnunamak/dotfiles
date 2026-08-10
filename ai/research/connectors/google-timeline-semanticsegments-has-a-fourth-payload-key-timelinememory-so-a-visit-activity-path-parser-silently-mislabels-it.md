---
title: "Google Timeline's semanticSegments carries a fourth payload key, timelineMemory, so a visit/activity/timelinePath parser that falls back to 'path' silently mislabels real segments instead of failing"
date: 2026-08-08
topic: connectors
tags: [google-maps, timeline, takeout, location-history, schema-drift, parser-fallback]
status: draft
sources: [lohi-schema, qiita-timeline-spec, locationhistoryformat, dawarich-export-anatomy]
source_session: faa1035b-c89f-4090-9964-5918351b5fb9
---

## CLAIMS

- A `semanticSegments[]` entry in the post-2024 on-device Google Timeline format carries exactly one of four payload keys: `visit`, `activity`, `timelinePath`, or `timelineMemory` — not three. [lohi-schema] [qiita-timeline-spec]
- `timelineMemory` contains either `trip` (`{destinations: IdentifiedPlace[], distanceFromOriginKms}`) or `note` (`{note: String}`) — trip groupings and user-authored text, not GPS fixes. [lohi-schema] [qiita-timeline-spec]
- The older `timelineObjects[]` format has only two entry types, `placeVisit` and `activitySegment`. Keys often mistaken for siblings — `transitPath`, `waypointPath`, `simplifiedRawPath`, `parkingEvent`, `childVisits` — are all nested one level deeper. [locationhistoryformat]
- There is no `transitPath` or `flight` key at segment level in either format. `transitPath` is nested inside `activitySegment` in the old format; flights appear as an `activityType`/`topCandidate.type` value (`FLYING`), not a distinct key. [locationhistoryformat]
- Google publishes no official schema for `semanticSegments`; every available reference is community reverse-engineering, and the 2024 cloud→on-device migration was a hard format break with continued drift reports through 2025. [dawarich-export-anatomy] [locationhistoryformat]
- iOS exports can be a bare top-level JSON array rather than `{semanticSegments: [...]}`, so code indexing the container key directly breaks on iOS files. [dawarich-export-anatomy]
- Coordinates appear in at least three encodings across format generations: degree-suffixed strings (`"50.0506312°, 14.3439906°"`), `geo:lat,lng` URIs, and legacy E7 integers. [dawarich-export-anatomy] [locationhistoryformat]

## SOURCES

**lohi-schema**
URL: https://raw.githubusercontent.com/bobg/lohi/main/schema/schema.go
Accessed: 2026-08-08
Quote: The `SemanticSegment` struct declares exactly `activity`, `timelineMemory`, `timelinePath`, and `visit` alongside the time/offset scalars — read from source rather than from a docs page.

**qiita-timeline-spec**
URL: https://qiita.com/nabemax/items/3be12071d7ecd809aaa0
Accessed: 2026-08-08
Quote: "visit/activity/timelinePath/timelineMemory のいずれか必須" (one of visit/activity/timelinePath/timelineMemory is required), and within timelineMemory: "trip/note のいずれか必須".

**locationhistoryformat**
URL: https://locationhistoryformat.com/reference/semantic/
Accessed: 2026-08-08
Quote: The Semantic Location History reference documents `placeVisit` and `activitySegment` as the only two `timelineObjects` entry types, with `transitPath`/`waypointPath`/`simplifiedRawPath` documented as children of `activitySegment`.

**dawarich-export-anatomy**
URL: https://dawarich.app/blog/whats-inside-your-google-timeline-export/
Accessed: 2026-08-08
Quote: Field-by-field breakdown of the current export, noting the iOS bare-array top level and the divergent coordinate encodings across format generations.

## SYNTHESIS

The reusable lesson is about **fallback shape, not about Google**. A parser that classifies a
record by which sub-object it finds, and uses one of the *real* kinds as its `else` branch, converts
an unknown shape into a confident false claim. In the PDPP `google_maps` connector this was literal:
`semanticSegmentKind()` returned `"path"` for anything that was neither `visit` nor `activity`, so a
`timelineMemory` trip was emitted as `segment_kind: "path"` with latitude, longitude, place_id,
semantic_type, activity_type and probability all null — because the field extractors only read
inside `visit`/`activity`. No skip, no counter, no diagnostic. Reproduced against the real parser
before fixing.

This is strictly worse than a validation failure. A closed enum that rejects an unknown value at
least produces a visible skip; a catch-all fallback produces a plausible-looking record that lies.
Any downstream consumer grouping by segment kind silently gets contaminated buckets.

The fix that generalizes: make the catch-all an explicit `unrecognized` branch that (a) retains the
record, (b) preserves the provider's own key verbatim in a dedicated field, and (c) emits a count as
a diagnostic. Retain-and-label beats skip here because the data is the owner's — dropping it to
protect schema tidiness is the failure mode personal-data tooling most needs to avoid. Claiming
`path` only when a `timelinePath` is actually present is the one-line version of the rule.

Because the format is undocumented and changes without notice, the durable defense is the
**unrecognized-key counter**, not an enumeration of keys. Enumerating keys is a snapshot that
expires; the counter is what tells you when the next break lands. Add `timelineMemory` handling if
its trip/note payload is wanted (note is free-form user text — a PII decision, not just a parsing
one), but treat the counter as the permanent instrument.

Worth checking the same catch-all-fallback pattern in any connector that discriminates on provider
shape: the defect is invisible to schema validation by construction, so a passing test suite says
nothing about it.
