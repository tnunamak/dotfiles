---
title: "Apple Health's export.xml has no official schema, is only documented by an embedded DTD that has changed across iOS versions, and carries far more structure than flat Record/Workout attributes"
date: 2026-09-01
topic: apple-health-export-format
tags: [apple-health, healthkit, xml, connectors, pdpp]
status: draft
sources: [apple-discussions-dtd-thread, rostrum-blog, tdda-xml-post, artxgj-github, aihealthexport-guide, gist-hoffa]
source_session: 25ae4b3c-e3d1-4ba0-abf7-2b19d7f42ef3
---

## CLAIMS

- The root element is `HealthData`, containing `ExportDate` (single, `value` attr timestamp), `Me` (single, HKCharacteristicTypeIdentifier* attrs: DateOfBirth, BiologicalSex, BloodType, FitzpatrickSkinType), then any number of `Record`, `Correlation`, `Workout`, `ActivitySummary`, and `ClinicalRecord` elements. [apple-discussions-dtd-thread] [gist-hoffa]
- `Record` attributes per the DTD: `type` (required), `unit` (optional), `value` (optional), `sourceName` (required), `sourceVersion` (optional), `device` (optional, a descriptor string like `<<HKDevice: ...>, name:iPhone, manufacturer:Apple, model:iPhone8,1, software:9.3.2>`), `creationDate` (optional), `startDate`/`endDate` (required). [gist-hoffa] [artxgj-github]
- `Record` elements can have nested `MetadataEntry` children (key/value pairs) and, for heart-rate-variability records, a `HeartRateVariabilityMetadataList` child — not just flat attributes. [gist-hoffa]
- There is no single, stable `Workout` schema — the DTD changed across iOS versions. Older DTD: `<!ELEMENT Workout ((MetadataEntry|WorkoutEvent)*)>`. Newer (~iOS 16+) DTD added `WorkoutRoute` and `WorkoutStatistics` as valid children, and `WorkoutEvent` gained optional `duration`/`durationUnit` attributes and an optional nested `MetadataEntry` (older `WorkoutEvent` was `EMPTY` with just `type`+`date`). [apple-discussions-dtd-thread]
- `Workout` attributes: `workoutActivityType` (required), `duration`/`durationUnit`, `totalDistance`/`totalDistanceUnit`, `totalEnergyBurned`/`totalEnergyBurnedUnit` (all optional/IMPLIED), `sourceName` (required), `sourceVersion`, `device`, `creationDate`, `startDate`/`endDate` (required). [apple-discussions-dtd-thread]
- Real-world `Workout` elements carry rich `MetadataEntry` children beyond the DTD-required attrs: e.g. `HKWeatherTemperature`, `HKWeatherHumidity`, `HKIndoorWorkout`, `HKElevationAscended`, `HKAverageMETs`, `HKTimeZone` — all as `key`/`value` string pairs, units embedded in the value string (e.g. `"58.0164 degF"`, `"4989 cm"`). [rostrum-blog]
- Modern multi-file exports also include a `workout-routes/` directory of one GPX file per outdoor workout (GPS route), an `electrocardiograms/` directory (one CSV per ECG reading), and an `export_cda.xml` companion file (FHIR/CDA-style clinical records) — none of these live inside `export.xml` itself. [apple-discussions-dtd-thread]
- Apple has never published a formal schema for the export; every parser (including this research) relies on the embedded DTD comment block plus empirical examples, and both have drifted release to release. [tdda-xml-post] [artxgj-github]

## SOURCES

**apple-discussions-dtd-thread**
URL: https://discussions.apple.com/thread/254202523?page=2
Accessed: 2026-09-01
Quote: "<!ELEMENT Workout ((MetadataEntry|WorkoutEvent|WorkoutRoute|WorkoutStatistics)*)>"

**rostrum-blog**
URL: https://www.rostrum.blog/posts/2021-03-23-xml-health/
Accessed: 2026-09-01
Quote: "<MetadataEntry key=\"HKWeatherTemperature\" value=\"58.0164 degF\"/>"

**tdda-xml-post**
URL: https://www.tdda.info/in-defence-of-xml-exporting-and-analysing-apple-health-data
Accessed: 2026-09-01

**artxgj-github**
URL: https://github.com/artxgj/apple_health
Accessed: 2026-09-01

**aihealthexport-guide**
URL: https://www.aihealthexport.com/guides/apple-health-xml-format
Accessed: 2026-09-01

**gist-hoffa**
URL: https://gist.github.com/hoffa/936db2bb85e134709cd263dd358ca309
Accessed: 2026-09-01
Quote: "<Record type=\"HKQuantityTypeIdentifierHeight\" ... value=\"194\"><MetadataEntry key=\"HKWasUserEntered\" value=\"1\"/></Record>"

## SYNTHESIS

For a connector, the practical implication is: (1) a regex/attribute-only parser (self-closing `<Record .../>` and `<Workout .../>`) silently drops nested `MetadataEntry`, `WorkoutEvent`, and `WorkoutStatistics` children whenever they exist, and will also mis-scan any `Workout` that is NOT self-closing (has children) if the tag regex assumes `/?>` self-closure; (2) `workout-routes/*.gpx`, ECG CSVs, and `export_cda.xml` are separate files the export.xml parser cannot see at all — these are legitimately out of scope for an XML-only parser and should be reported as a structural gap, not silently ignored; (3) because there's no official schema, "coverage" claims should always be phrased as "handles the common real-world surface observed across iOS 15-18 exports," never "fully spec-compliant," and any unrecognized record `type` or unexpected child element should increment an explicit, reported gap counter rather than being dropped silently.
