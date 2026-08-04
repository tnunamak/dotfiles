---
title: "Presidio's LOCATION entity type detects full addresses, not street/city/state separately; granular redaction requires custom recognizers or post-processing"
date: 2026-08-04
topic: pii-detection
tags: [presidio, pii, location, entity-types, address-redaction, custom-recognizers]
status: draft
sources: [presidio-docs, presidio-supported-entities, presidio-customizing]
source_session: e01918eb-bc2a-4e83-88c1-6c0f26f27a91
---

## CLAIMS

- Presidio's built-in entity types include `LOCATION`, which detects geographical references including full addresses, city names, and state names as a single entity type [presidio-supported-entities]
- Presidio does NOT provide separate entity types for street address vs. city vs. state; all are flagged as `LOCATION` [presidio-supported-entities]
- Granular redaction policies (e.g., "keep city/state, redact street number/name") require custom recognizers or post-processing of detected entities, not a built-in policy distinction [presidio-customizing]
- Custom recognizers can be added to Presidio's analyzer to detect and classify domain-specific patterns (e.g., a separate recognizer for "street addresses" vs. "cities"), enabling finer-grained redaction [presidio-customizing]

## SOURCES

**presidio-supported-entities**
URL: https://microsoft.github.io/presidio/supported_entities/
Accessed: 2026-08-04
Quote: "LOCATION — Geographical location entities such as cities, countries, state, street names, zip codes, and addresses"

**presidio-customizing**
URL: https://microsoft.github.io/presidio/samples/python/customizing_presidio_analyzer/
Accessed: 2026-08-04
Note: Demonstrates how to add custom recognizers to the analyzer for domain-specific entity detection

**presidio-docs**
URL: https://microsoft.github.io/presidio/analyzer/
Accessed: 2026-08-04
Note: Primary documentation for Presidio's analyzer architecture and entity types

## SYNTHESIS

Presidio's `LOCATION` entity is coarse-grained by design — it conflates street addresses, city names, state abbreviations, and ZIP codes under a single entity type. This is intentional for simplicity but makes it unsuitable for policies that require partial redaction (e.g., "mask street, keep city/state").

To implement granular address redaction with Presidio, teams typically:
1. Use Presidio's custom-recognizer API to write domain-specific recognizers that subdivide address components
2. Post-process Presidio's LOCATION detections (regex or NER on the detected text) to extract subcomponents
3. Combine Presidio's coarse detection with an LLM-based secondary classifier for context-aware decisions (the anka-redactor pattern)

For address redaction policies distinguishing street vs. city/state, Presidio alone is insufficient — plan for supplementary logic at the architecture level.
