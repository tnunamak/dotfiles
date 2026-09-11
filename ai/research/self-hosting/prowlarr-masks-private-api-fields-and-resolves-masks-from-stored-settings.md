---
title: "Prowlarr masks private API fields and resolves masks from stored settings"
date: 2026-09-09
topic: self-hosting
tags: [prowlarr, api, credentials]
status: verified
sources: [schema, controller, mapper, tables]
source_session: unknown
---

## CLAIMS

- Prowlarr v2.5.2.5491 emits eight asterisks for nonempty private API-key and password fields. When reading an incoming schema with that exact value and an existing model, it reuses the model's stored value. [schema]
- Provider GET maps settings through SchemaBuilder; the provider model mapper passes existing settings when processing incoming fields. [mapper]
- The native POST test action resolves an existing provider by resource ID and validates and tests that provider. GET-all has no option to return unmasked secrets in this version. [controller]
- ApplicationDefinition maps to the Applications database table. [tables]

## SOURCES

**schema**
URL: https://github.com/Prowlarr/Prowlarr/blob/v2.5.2.5491/src/Prowlarr.Http/ClientSchema/SchemaBuilder.cs
Accessed: 2026-09-09

**controller**
URL: https://github.com/Prowlarr/Prowlarr/blob/v2.5.2.5491/src/Prowlarr.Api.V1/ProviderControllerBase.cs
Accessed: 2026-09-09

**mapper**
URL: https://github.com/Prowlarr/Prowlarr/blob/v2.5.2.5491/src/Prowlarr.Api.V1/ProviderResource.cs
Accessed: 2026-09-09

**tables**
URL: https://github.com/Prowlarr/Prowlarr/blob/v2.5.2.5491/src/NzbDrone.Core/Datastore/TableMapping.cs
Accessed: 2026-09-09

## SYNTHESIS

Do not compare a mask to a credential or infer equality from a mask. A native test can validate a reachable application's stored credential, but cannot prove the stored value of a retired unreachable application. Administrative cleanup requiring exact persisted equality needs a separately authorized config read. A tightly scoped SQLite read-only query can provide this evidence while preserving authenticated API writes and connection tests. Read committed WAL contents; an immutable snapshot flag is unsuitable for a running database.
