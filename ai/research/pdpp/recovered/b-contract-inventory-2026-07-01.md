---
title: "PDPP Reference Implementation — Public-Contract Inventory (B-minimum)"
date: 2026-07-01
topic: code-quality
tags: [code-quality, b-machine, public-contract, mcp, error-model, grant-model, read-only]
status: B-minimum inventory (READ-ONLY; no source changed) — feeds the B evaluator/proposal generator
doctrine: THE-PROJECT-QUALITY-PORTFOLIO-MACHINE.md §6 step 4 (B-minimum) + §2 B row
machine_readable: b-contract-inventory-2026-07-01.json (alongside)
scope: reference-implementation/ + packages/mcp-server/ + packages/reference-contract/
---

# Public-contract inventory — the B-minimum catalogue

This is the **read-only** public-contract inventory for the PDPP reference implementation (RI). It is the
foundation of the **B machine** (public-contract / product-surface quality) per
`THE-PROJECT-QUALITY-PORTFOLIO-MACHINE.md`. **B is behavior-CHANGING territory** (the contract a caller
experiences), so this file only **inventories and proposes** — nothing here is a landed edit and nothing
proposes an auto-land. A future B pass ratifies changes with a human.

The machine-readable twin is `b-contract-inventory-2026-07-01.json` (same directory): every route row, MCP
tool shape, error code, and grant touchpoint as structured data.

## 0. How this was built + the honesty caveats

- **Routes** were derived from the two committed OpenAPI specs
  (`reference-implementation/openapi/reference-public.openapi.json` = 30 public ops;
  `reference-full.openapi.json` = 100 ops incl. the `/_ref` control plane) joined to their handlers via the
  **`{ contract: "<operationId>" }` route marker** — every `app.get/post/...` registration carries a
  `contract:` tag naming its OpenAPI operationId, validated at startup by `transport.registerRoute`. All 100
  operations resolve to a contract-marked handler. This marker IS the machine-checkable route↔contract seam.
- **MCP tools** were read from `packages/mcp-server/src/tools.js` (the `buildTools` factory; exported
  `PDPP_MCP_TOOL_NAMES`). Descriptions are static — never interpolated from data.
- **Error model** was read from `server/request-helpers.js` (`pdppError` envelope builder) +
  `server/routes/ref-error-status.ts` (the `codeToStatus`/`typeFor` single source of truth) +
  `packages/reference-contract/src/public/index.ts` (typed error schemas).
- **Grant model** was read from `packages/reference-contract/src/public/index.ts` (`GrantSchema`,
  `AuthorizationDetailSchema`) + the enforcement touchpoints in `operations/rs-records-list`,
  `operations/rs-schema-get/compact-view.ts`, `server/schema-capabilities.js`.

**COVERAGE CAVEAT (read before trusting any "tests" number):** the per-route `tests(by-opId-name)` column is a
**weak by-name signal** — it counts `test/` files that literally contain the operationId string. It is
routinely **0 for surfaces that are heavily tested**, because the suite builds URLs dynamically and calls the
pure `operations/*` modules directly rather than by operationId. Trust the **behavioral counts** below over the
by-name column:

| behavioral probe | test files |
|---|---|
| `aggregate` | 31 |
| `blob` | 49 |
| `/v1/search*` (semantic/hybrid/lexical) | 35 |
| `field_not_granted` | 10 |
| `ambiguous_connection` | 10 |
| `invalid_cursor` | 10 |
| `read_record_field` | 4 |
| `insufficient_scope` | 3 |
| `invalid_expand` | 3 |
| `related_stream_not_granted` | 1 |
| **`content_ladder`** | **0** ← highest-value gap (see §6) |

Where I could not find a test or doc for a surface, it is marked **UNKNOWN** rather than invented.

---

## 1. HTTP routes — public surface (30 operations)

Columns: `surface | operationId | declared response codes | handler (host adapter) | operation module (impl concept) | tests(by-opId-name)`.
The **handler** is a thin host adapter (owns auth, HTTP shaping, spine emission); the **operation module**
under `operations/` is the pure implementation concept it delegates to. That route→operation split IS the
primary seam this inventory exposes.

| surface | operationId | resp codes | handler | operation module | tests(by-name) |
|---|---|---|---|---|---|
| `GET /` | getRsDiscoveryIndex | 200 | root-and-discovery.ts:194 | rs-discovery-index | 1 |
| `GET /.well-known/oauth-authorization-server` | getAuthorizationServerMetadata | 200 | root-and-discovery.ts:132 | as-authorization-server-metadata | 0 |
| `GET /.well-known/oauth-protected-resource` | getProtectedResourceMetadata | 200 | root-and-discovery.ts:294 | rs-protected-resource-metadata | 0 |
| `GET /.well-known/oauth-protected-resource/mcp` | getMcpProtectedResourceMetadata | 200 | root-and-discovery.ts:385 | rs-protected-resource-metadata | 0 |
| `POST /oauth/register` | registerDynamicClient | 201,400,401,404 | as-dcr.ts:212 | as-dcr-register | 8 |
| `POST /oauth/par` | createPushedAuthorizationRequest | 201,400,403 | as-par.ts:86 | as-par-create | 1 |
| `POST /consent/approve` | approveConsent | 200,400,403,404 | as-consent.ts:567 | as-consent-decision | 0 |
| `POST /consent/exchange` | exchangeConsentCode | 200,400,404,410 | as-consent.ts:690 | as-consent-exchange | 0 |
| `POST /oauth/device_authorization` | startOwnerDeviceAuthorization | 200,400 | as-oauth.ts:218 | as-device-authorization-init | 0 |
| `POST /oauth/token` | exchangeOwnerDeviceToken | 200,400,500 | as-oauth.ts:372 | as-device-token-exchange | 0 |
| `POST /introspect` | introspectToken | 200,400 | as-oauth.ts:402 | as-introspect | 1 |
| `POST /grants/{grantId}/revoke` | revokeGrant | 200,403 | as-grant-revoke.ts:164 | as-grant-revoke | 6 |
| `GET /v1/connectors` | listConnectors | 200,400,401,403,404 | rs-read.ts:629 | rs-connectors-list | 3 |
| `GET /v1/schema` | getSchema | 200,400,401,403,404 | rs-read.ts:984 | rs-schema-get (+ compact-view.ts) | 0† |
| `GET /v1/streams` | listStreams | 200,400,401,403,404 | rs-read.ts:1348 | rs-streams-list | 5 |
| `GET /v1/streams/{stream}` | getStreamMetadata | 200,400,401,403,404 | rs-read.ts:1428 | rs-streams-detail | 0† |
| `GET /v1/streams/{stream}/records` | listRecords | 200,400,401,403,404,410 | rs-read.ts:1737 | rs-records-list | 1† |
| `GET /v1/streams/{stream}/aggregate` | aggregateStream | 200,400,401,403,404 | rs-read.ts:1593 | rs-streams-aggregate | 0† (31 by behavior) |
| `GET /v1/streams/{stream}/records/{id}` | getRecord | 200,400,401,403,404,409 | rs-read.ts:1852 | rs-records-detail | 12 |
| `GET /v1/search` | searchRecordsLexical | 200,400,401,403,410 | rs-read.ts:2250 | rs-search-lexical | 0† (35 by behavior) |
| `GET /v1/search/semantic` | searchRecordsSemantic | 200,400,401,403,410 | rs-read.ts:2275 | rs-search-semantic | 0† |
| `GET /v1/search/hybrid` | searchRecordsHybrid | 200,400,401,403,404 | rs-read.ts:2302 | rs-search-hybrid | 0† |
| `POST /v1/blobs` | uploadBlob | 200,400,401,403,404 | rs-mutation.ts:412 | rs-blobs-upload | 2† (49 by behavior) |
| `GET /v1/blobs/{blob_id}` | getBlob | 200,400,401,403,404,409 | rs-read.ts:2561 | rs-blobs-read | 4 |
| `POST /v1/event-subscriptions` | createEventSubscription | 201,400,401,403 | rs-mutation.ts:587 | as-client-event-subscriptions | 0† (12 by behavior) |
| `GET /v1/event-subscriptions` | listEventSubscriptions | 200,401,403 | rs-mutation.ts:633 | as-client-event-subscriptions | 0† |
| `GET /v1/event-subscriptions/{subscription_id}` | getEventSubscription | 200,401,403,404 | rs-mutation.ts:655 | as-client-event-subscriptions | 0† |
| `PATCH /v1/event-subscriptions/{subscription_id}` | updateEventSubscription | 200,400,401,403,404,409 | rs-mutation.ts:678 | as-client-event-subscriptions | 0† |
| `DELETE /v1/event-subscriptions/{subscription_id}` | deleteEventSubscription | 204,401,403,404 | rs-mutation.ts:706 | as-client-event-subscriptions | 0† |
| `POST /v1/event-subscriptions/{subscription_id}/test-event` | sendTestEvent | 202,401,403,404,409 | rs-mutation.ts:729 | rs-client-event-deliver | 0† |

`†` = by-name is 0/low but the surface is exercised behaviorally (see §0 caveat). Handler paths are relative to
`reference-implementation/server/routes/`. All handlers carry `{ contract: "<operationId>" }`.

## 1b. HTTP routes — `/_ref` + `/v1/owner` control plane (70 additional operations)

These are in `reference-full.openapi.json` but **NOT** `reference-public.openapi.json` — they are the
owner/operator control plane (session-guarded via `ctx.requireOwnerSession` / `ctx.requireOwner`), not part of
the scoped-grant caller contract. They are catalogued in full in the JSON twin (`http_routes[]` with
`public:false`). Grouped by concern:

- **`/v1/owner/*` (owner-agent, 24 ops)** — connections list/rename/delete, connector-templates,
  control-capabilities, connection intents, schedule pause/resume/delete (connection & connector), run,
  revoke, reactivate, diagnostics. Handlers: `server/routes/owner-*.ts`.
- **`/_ref/connectors|connections|connector-instances` (13 ops)** — reference admin CRUD +
  run/schedule/revoke/reactivate mirrors of the owner surface. Handlers: `server/routes/ref-admin.ts`,
  `ref-static-secret-*`, `ref-provider-auth.ts`.
- **`/_ref/device-exporters/*` (11 ops)** — local-device exporter enrollment, heartbeat, ingest-batches,
  source-instance state get/put, revoke, diagnostics. Handler: `server/routes/ref-device-exporters.ts`;
  operation modules: `ref-source-webhook-ingest`, `collector-protocol`.
- **`/_ref/dataset/* + /_ref/records/* + /_ref/explore/*` (16 ops)** — dataset summary/size/top,
  records timeline/version-stats, explore record buckets/records (the Explore substrate). Operation modules:
  `ref-dataset-summary`, `ref-dataset-summary-streams`, `ref-records-timeline`, `rs-explore-record-buckets`,
  `rs-explore-timeline`.
- **`/_ref/schedules|runs|grants|approvals|search|event-subscriptions` (6 ops)** — schedule list,
  run interaction, grant approvals list, reference spine search, reference event-subscription list/get/disable.

**B-relevant note:** the `/_ref` plane and the `/v1/owner` plane are two names for overlapping capabilities
(e.g. `refRunConnection` vs `ownerRunConnection`, `refPauseConnectorSchedule` vs
`ownerPauseConnectorSchedule`). That duplication is a **public-noun-conflation candidate** for a future B
proposal — see §7.

---

## 2. MCP tool contract (6 tools)

Source: `packages/mcp-server/src/tools.js` (`buildTools({ rs, providerUrl })`). Exported tool-name set:
`PDPP_MCP_TOOL_NAMES`. All 6 tools are `READ_ONLY_ANNOTATIONS`, `.strict()` input schemas (unknown args
rejected), and forward to the RS REST surface. Each maps 1:1 to REST per the mcp-server README table.

| tool | REST backing | input shape (Zod, `.strict()`) | key semantics |
|---|---|---|---|
| **`schema`** (tools.js:450) | `GET /v1/schema` | `{ detail?: compact\|full, stream?, connection_id? }` | Grant-scoped capability doc. `compact` default; `full` allowed only with `stream`. Discovery ladder: `schema → schema(stream) → schema(stream, connection_id) → query_records`. Advertises `connector_key`, `field_capabilities`, `expand_capabilities`, granted `connection_id`+`display_name`. |
| **`query_records`** (tools.js:500) | `GET /v1/streams/{stream}/records` | `{ stream, limit?(≤100), cursor?, order?, sort?, count?(none\|estimated\|exact), filter?(typed obj), fields?, view?, expand?, expand_limit?, changes_since?, connection_id? }` | Default 25 records; `limit>100` → `limit_clamped` in `meta.warnings[]` (REST) / capped at input (MCP). `fields` projects. `content[]` previews first 5; long fields carry `content_ladder`. |
| **`aggregate`** (tools.js:548) | `GET /v1/streams/{stream}/aggregate` | `{ stream, metric(count\|sum\|min\|max\|count_distinct), field?, group_by? ⊻ group_by_time?, granularity?, time_zone?, limit?(≤100), filter?, connection_id? }` | Never returns record bodies. `field` required for all metrics but `count`. Grouped responses carry `other_count` (top-N truncation detection). |
| **`search`** (tools.js:607) | `GET /v1/search` \| `/semantic` \| `/hybrid` (by `mode`) | `{ q, streams?, limit?(≤100), cursor?, mode?(lexical\|semantic\|hybrid), filter?, connection_id? }` | Hit ids are **self-contained fetch handles** (`connection_id/stream:record_id`). `hybrid` does not page. `content[]` renders bounded match-window evidence **before** wrappers. |
| **`fetch`** (tools.js:641) | `GET /v1/streams/{stream}/records/{record_id}` | `{ id, expand?, expand_limit?, fields?, connection_id? }` | OpenAI-compatible doc `{id,title,text,url,metadata}`. Accepts self-contained / legacy `stream:record_id` / `pdpp://record/...` ids. On `ambiguous_connection` (409) → retry with a `connection_id` from `available_connections`. |
| **`read_record_field`** (tools.js:685) | `GET /v1/streams/{stream}/records/{record_id}/field-window` | `oneOf({id, field_path} \| {connection_id, stream, record_id, field_path})` + **one** window selector: `cursor` ⊻ `offset_chars`/`limit_chars` ⊻ `q`/`before_chars`/`after_chars` | The **Tier-2 progressive-disclosure tool**. `limit_chars` default 4096 / cap 16384; `before_chars`/`after_chars` default 2048 / cap 8192. Never unbounded. Returns `next_cursor`/`previous_cursor`. Cursors bound to record id + field path + revision/digest + active grant. |

### 2b. The content_ladder progressive-disclosure design (5 tiers)

Design: `openspec/changes/archive/2026-06-29-add-mcp-content-ladder/design.md`.
Spec: `openspec/changes/archive/2026-06-29-complete-mcp-read-evidence-ladder/specs/mcp-adapter/spec.md`.
Impl constants: `tools.js:1447+` (`CONTENT_LADDER_RECORD_LIMIT=5`, `FIELD_LIMIT=5`, `WINDOW_LIMIT_CHARS=4096`,
`BINARY_FIELD_LIMIT=5`).

- **Tier 0 — compact tool text.** `query_records`/`search`/`fetch` return bounded `content[]` text; when a
  field preview is incomplete it includes record handle/result-id, field path, preview range/snippet coords,
  a `read_record_field` hint **with required arguments**, and a resource URI when available.
- **Tier 1 — canonical structured metadata.** `structuredContent.content_ladder` block per previewed long
  field: record identity (self-contained id + discrete `connection_id`/`stream`/`record_id`), field identity
  (path, type, MIME, size grade, text/binary class), preview status
  (complete/truncated/snippet-only/binary-only/unavailable), continuation handles (tool cursor + resource
  URI), digest/revision for staleness detection.
- **Tier 2 — bounded field-window tool.** `read_record_field` (the only progressive-disclosure TOOL; see
  above).
- **Tier 3 — MCP resources.** `pdpp://record/...` and `pdpp://field-window/...` for resource-aware hosts.
  Ordinary model-visible output prefers **self-contained result ids** and does not expose raw
  `pdpp://record/...` URIs; the raw URI remains a compatibility INPUT.
- **Tier 4 — binary & export.** `resource_link` / file materialization reserved for bulk/large/binary; small
  text stays inline.

**Load-bearing invariant:** *every visible incomplete text preview MUST have a MODEL-CALLABLE continuation*
(not resource-only), so content-only hosts never dead-end. Search evidence appears **before** generic wrappers
in `content[]`.

---

## 3. Public error model

**Envelope** (built by `server/request-helpers.js` → `pdppError(res, status, code, message, param, extras)`):

```json
{ "error": {
  "type": "<by status>", "code": "<domain code>", "message": "...",
  "param": "<optional>",
  "available_connections": ["...optional (409 ambiguous)..."],
  "retry_with": "<optional>",
  "resource_metadata": "<optional, only on 401>",
  "next_step": "<optional, only on 401>",
  "request_id": "<always>"
} }
```

**`type` by HTTP status** (`typeFor`, `ref-error-status.ts`): 400→`invalid_request_error`,
401→`authentication_error`, 403→`permission_error`, 404→`not_found_error`, 410→`gone_error`,
429→`rate_limit_error`, else→`api_error`.

**`code` → HTTP status** — the single source of truth is `codeToStatus` in `server/routes/ref-error-status.ts`
(**47 codes**, extracted verbatim into the JSON twin). Grouped:

- **400 invalid_request_error (20):** `invalid_field_path`, `invalid_window`, `invalid_argument`,
  `invalid_cursor`, `invalid_request`, `invalid_client`, `invalid_client_metadata`, `connector_invalid`,
  `invalid_record`, `invalid_record_identity`, `invalid_expand`, `invalid_sort`,
  `ambiguous_connector_instance`, `connector_instance_connector_mismatch`, `connector_instance_inactive`,
  `connector_instance_selector_required`, `owner_subject_required`, `unknown_field`, `unsupported_version`,
  `invalid_status`.
- **401 authentication_error (1):** `authentication_error`.
- **403 permission_error (8):** `grant_stream_not_allowed`, `grant_expired`, `grant_revoked`,
  `grant_consumed`, `grant_invalid`, **`field_not_granted`**, **`insufficient_scope`**,
  `connector_instance_owner_mismatch`.
- **404 not_found_error (6):** `connection_not_found`, `field_not_found`, `query_not_found`, `blob_not_found`,
  `connector_instance_not_found`, `not_found`.
- **409 conflict (8):** **`ambiguous_connection`**, `ambiguous_schema_detail`, `connection_run_active`,
  `default_account_delete_unsupported`, `connector_instance_not_revoked`, `run_already_active`,
  `no_pending_interaction`, `interaction_id_mismatch`.
- **410 gone_error (1):** `cursor_expired`.
- **422 (1):** `field_not_text`.
- **425 (1):** `provider_pressure_cooldown` (provider cooldown; retry after `next_eligible_at`).
- **500 (1):** `connector_instance_store_required`.

**Typed error schemas (reference-contract):**
- `AmbiguousConnectionErrorSchema` (`packages/reference-contract/src/public/index.ts:1409`) — 409; required
  `[type, code, message, request_id, available_connections, retry_with]`. Emitted by `getRecord` and `getBlob`
  when an id resolves to >1 granted connection and `connection_id` is omitted. **Search/query fan in instead
  of raising this.**
- `OAuthErrorSchema` — the **distinct** OAuth-shaped envelope used for `/oauth/*`, `/consent/*`, and DCR
  responses (400/401/404/500), NOT the PDPP `{ error: {...} }` shape. **Two error envelopes coexist on the
  public surface** — a B-proposal candidate (§7).

**Notable soft signal (NOT an error code):** `related_stream_not_granted` appears **only** as a
`expand_capabilities` entry `reason` in `server/schema-capabilities.js:216` (schema advertises an expand
relation as *inert* with `reason: related_stream_not_granted` / `related_stream_unknown`). It is **not** in
`codeToStatus` and is **not** thrown — a caller learns it by reading schema, not by getting an error. This is a
public-noun/internal-concept nuance worth a B note (the sibling `field_not_granted` IS a thrown 403).

---

## 4. Grant / scoping model as EXPERIENCED by a caller

Not the enforcement internals — what a scoped-grant consumer (external Claude / Daisy / ChatGPT) actually sees.

**Grant shape** (`packages/reference-contract/src/public/index.ts` `GrantSchema`):
`{ version, grant_id, issued_at, subject.id, client.client_id, source, manifest_version, purpose_code,
purpose_description, access_mode(single_use|continuous), streams[], retention, expires_at }`.
Issued via the RFC-9396 rich-authorization-request `AuthorizationDetailSchema`
(`type: "https://pdpp.org/data-access"`, `source`, `purpose_code`, `access_mode`, `retention`, `streams[]`).

**What the caller experiences:**
1. **Capability discovery is grant-scoped.** `GET /v1/schema` returns ONLY granted streams/fields/connections
   (`scopeConnectors` in `rs-schema-get/compact-view.ts`). Ungranted fields are never advertised — the schema
   IS the grant surface. Compact-by-default keeps the discovery ladder cheap (a real grant-scoped `/v1/schema`
   body can exceed 2 MB).
2. **Connections are identities, not internals.** Granted connections surface as `connection_id` +
   `display_name`. Stream names are **not globally unique**; a caller disambiguates a shared stream by adding
   `connection_id`. `schema(stream)` advertises `connector.granted_connections`.
3. **Field-level scope.** Projecting an ungranted field (e.g. via `fields=`/`view`) → **`field_not_granted`
   (403)**.
4. **Relation-level scope.** Expanding to a non-granted related stream is advertised as **inert in schema**
   (`expand_capabilities[].reason = related_stream_not_granted`) rather than thrown — the caller sees it
   BEFORE issuing the expand.
5. **Ambiguity is explicit, never silent.** An id resolving to >1 granted connection with `connection_id`
   omitted → **`ambiguous_connection` (409)** + `available_connections` + `retry_with` (for `getRecord` /
   `getBlob`). Search & query **fan in** across granted connections instead.
6. **Grant lifecycle is legible.** `grant_expired` / `grant_revoked` / `grant_consumed` / `grant_invalid` /
   `grant_stream_not_allowed` (all 403), `insufficient_scope` (403). `access_mode: single_use` grants are
   consumable (→ `grant_consumed`).
7. **Cold-start pointers.** Unauthenticated `GET /` (RS root) and the `/.well-known/*` metadata name the next
   hop (schema surface, query base, OAuth AS metadata) so a probe learns the path without trial-and-error. A
   401 carries `resource_metadata` + `next_step`.

---

## 5. Docs & spec cross-reference

- **mcp-server README** (`packages/mcp-server/README.md`) — canonical MCP↔REST mapping table (lines 66-71),
  the `read_record_field`-vs-`fetch` rationale, content-ladder client-compatibility matrix, self-contained-id
  contract. **This is the best-documented public surface.**
- **RI README** (`reference-implementation/README.md`, 30 KB) — references `/v1/streams`, `/v1/search`,
  `/v1/blobs/{blob_id}`, `/consent/approve`, `/oauth/*`, `/.well-known/*`. Does **not** enumerate the MCP tools
  (those live in the mcp-server README).
- **OpenAPI** — `reference-public.openapi.json` (30 ops, the caller contract) +
  `reference-full.openapi.json` (100 ops incl. control plane). Generated/checked (reference-contract has
  `scripts/check-generated.js`).
- **openspec archive** — content-ladder design + mcp-adapter spec (see §2b); `unify-read-evidence-surface`.
- **docs/research** — `mcp-read-evidence-*` review/plan series (2026-06-22..24).

## 6. Biggest surprises / highest-value B findings (honest)

1. **`content_ladder` has ZERO by-keyword test coverage** despite being the crown-jewel progressive-disclosure
   design and a MODIFIED openspec requirement with explicit "must not dead-end content-only hosts" scenarios.
   It is exercised indirectly through `read_record_field` (4 files) and `query_records` preview tests, but
   there is no test that asserts the `structuredContent.content_ladder` block shape/tiers directly by that
   name. **Highest-value gap** — the invariant is spec'd, the assertion is thin.
2. **Two error envelopes coexist on the public surface** — the PDPP `{ error: { type, code, message, ... } }`
   shape (records/MCP surface) and the OAuth `OAuthErrorSchema` shape (`/oauth/*`, `/consent/*`, DCR). A caller
   crossing from the OAuth handshake into the data surface sees the error shape change. Legitimate (OAuth is
   RFC-shaped) but under-documented as a deliberate boundary.
3. **`related_stream_not_granted` is a public noun that is NOT an error code** — it is only a schema
   `expand_capabilities[].reason`. Its sibling `field_not_granted` IS a thrown 403. A caller could reasonably
   expect symmetry (both throw, or both advertise). Public-noun/internal-concept **mismatch candidate**.
4. **The `/_ref` and `/v1/owner` planes are near-duplicate control surfaces** (run/schedule/revoke/reactivate
   exist under both prefixes with different auth guards). 70 of 100 operations are control plane. This is the
   clearest **noun-conflation candidate**: "reference admin" and "owner agent" are two names likely serving
   overlapping concepts. A future B pass should decide whether these are genuinely two audiences or one concept
   with two skins.
5. **OAuth/consent/discovery routes show 0 by-name tests** (`getSchema`, `getStreamMetadata`,
   `aggregateStream`, all three `/v1/search*`, all 6 `event-subscription` ops, `approveConsent`,
   `exchangeConsentCode`, the device-flow pair). Per §0 many ARE tested behaviorally, but I **could not verify**
   direct contract-shape assertions for: `getStreamMetadata`, `getMcpProtectedResourceMetadata`,
   `sendTestEvent`. Marked UNKNOWN pending a targeted read.

## 7. Seam-hypothesis collector (stub — format definition)

Per `THE-PROJECT-QUALITY-PORTFOLIO-MACHINE.md` §7 (Seam Hypothesis Packet) and
`MEMO-6-IDEAL-MACHINE-EXPERT-CONVERGENCE.md`. This section is the **collector** that a future B pass fills as
the A/T1b refactoring work extracts implementation seams. **Purpose:** when A/T1b turns an implicit
implementation concept into an explicit named seam (context object, pure module, named intermediate fact),
that new internal noun is a candidate signal that the **public surface conflates two concepts**. This collector
is where those candidates queue for human-ratified B proposals.

**Seam Hypothesis Packet format** (one entry per hypothesis; do not auto-land — B is behavior-changing):

```yaml
- id: SHP-<n>
  emitted_by: <A2 | T1a | T1b | discovery-scan | manual>   # what surfaced it
  extracted_seam:                       # the internal concept the refactor made explicit
    name: <new named function/module/context-object>
    location: <file:line>
    was_implicit_in: <prior blob/closure/inline site>
  public_contract_touchpoints:          # which B nouns this seam maps onto
    routes: [<operationId>, ...]
    mcp_tools: [<tool>, ...]
    error_codes: [<code>, ...]
    grant_concepts: [<field_not_granted | connection_id | purpose_code | ...>]
  conflation_hypothesis: >              # the actual B claim
    <e.g. "public noun X (one route param) is served by two distinct internal
     concepts A and B; a caller cannot tell them apart, so error/permission
     semantics differ silently.">
  evidence:
    - <test/doc/code ref that supports the mismatch>
  proposed_class: <B-proposal | A-only (internal, no contract change) | not-a-seam>
  confidence: <low | med | high>
  status: <collected | triaged | proposed | ratified | rejected>
```

**Pre-seeded candidates from THIS inventory pass** (from §6 — not yet full packets, listed so a B pass has a
starting backlog):

```yaml
- id: SHP-001
  emitted_by: manual
  conflation_hypothesis: >
    /_ref/* and /v1/owner/* are two public prefixes for overlapping control
    capabilities (run/schedule/revoke/reactivate). Likely one concept, two skins.
  public_contract_touchpoints: { routes: [refRunConnection, ownerRunConnection, refPauseConnectorSchedule, ownerPauseConnectorSchedule] }
  proposed_class: B-proposal
  confidence: med
  status: collected

- id: SHP-002
  emitted_by: manual
  conflation_hypothesis: >
    field_not_granted (thrown 403) and related_stream_not_granted (schema-only
    inert reason) are asymmetric names for the same "not granted" concept at two
    granularities (field vs relation). A caller expects symmetry.
  public_contract_touchpoints: { error_codes: [field_not_granted], grant_concepts: [related_stream_not_granted] }
  proposed_class: B-proposal
  confidence: med
  status: collected

- id: SHP-003
  emitted_by: manual
  conflation_hypothesis: >
    Two error envelopes (PDPP {error:{type,code,message}} vs OAuthErrorSchema)
    on one public surface. Boundary is legitimate but the seam is undocumented;
    verify the crossover point is the only place shape changes.
  public_contract_touchpoints: { error_codes: [invalid_client, invalid_grant, field_not_granted] }
  proposed_class: B-proposal
  confidence: low
  status: collected
```

---

*Read-only inventory. Source of every claim is cited to file/line. No source file was modified to produce
this catalogue. The JSON twin (`b-contract-inventory-2026-07-01.json`) carries all 100 route rows (public +
control plane), the 47-code error table, and the 6 MCP tool shapes as structured data.*
