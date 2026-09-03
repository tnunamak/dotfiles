---
title: "Consumer products DO show raw condition lists to non-developer owners (1Password Watchtower, Nextcloud's 71 setup checks, Bitwarden), PDPP's conditions are a clock-and-sweep-driven materialized view rather than a fetch so the TanStack/GitHub two-axis analogy does not fit, and the grant-scoped leak the redesign was partly justified by does not exist in production code"
date: 2026-08-19
topic: product-design
tags: [red-team, status-ux, connector-health, condition-lists, staleness, refutation, two-axis, materialized-view]
status: draft
sources: [1password-watchtower, nextcloud-setup-checks, nextcloud-setupchecks-src, bitwarden-reports, ha-repair-issues-raw, truenas-alert-sources, pdpp-connection-health, pdpp-freshness, pdpp-rendered-verdict, pdpp-ref-control, pdpp-evidence-engine, pdpp-mcp-mirror, pdpp-detail-gap-store, pdpp-openapi, pdpp-selfhost-quickstart]
source_session: af82d1f3-1838-4307-a3a9-6bbf07e77c6f
---

<!--
ADVERSARIAL entry. Written to REFUTE two same-day entries:
- product-design/data-possession-and-work-in-flight-are-orthogonal-axes-and-the-owner-maintainer-message-split-is-by-actor-not-tone.md
- api-contract-design/health-vocabularies-separate-a-lifecycle-axis-from-a-verdict-axis-and-kubernetes-explicitly-refuses-to-recommend-positive-condition-polarity.md
Both have been corrected in place where refuted. This entry holds the counter-evidence
and the cost argument. It does NOT dispute the Kubernetes/TanStack/Plaid source readings,
which re-verified clean — it disputes the NEGATIVE survey claim and the APPLICATION to PDPP.
-->

## CLAIMS

### The negative claim is false — three consumer products ship raw condition lists to non-developers

- 1Password Watchtower's dashboard IS the condition list: "Any Watchtower category that has items in it will appear on your dashboard." The named categories are Compromised websites and vulnerable passwords, Reused and weak passwords, Unsecured websites, Two-factor authentication, Passkeys available, Expiring items, Items with duplicates, Items in another account, Developer secrets on disk, and Imported from LastPass. No single synthesized state precedes the list; the multi-row list is the primary Watchtower surface, and the audience is consumer password-manager users, not developers. [1password-watchtower]
- Nextcloud's `ISetupCheck` API defines a per-check user-visible name plus a four-state result, and the states are named exactly like a condition: success = "Test succeeded no action needed."; info = "No action required but it can not be guaranteed that the check passed (e.g. missing precondition for running the test)."; warning = "The test failed but the result is not fatal, yet the administrator should be warned about this."; error = "The test failed and some functionality is not available or might be broken." Results are "reported to the administrator, either on the web interface (admin setting), or when running the `occ setupchecks` command." [nextcloud-setup-checks]
- Nextcloud ships **71** distinct named setup-check classes in `apps/settings/lib/SetupChecks` (verified by directory listing), including `DatabaseHasMissingIndices`, `MemcacheConfigured`, `DebugMode`, `CodeIntegrity`, `DataDirectoryProtected`, `BruteForceThrottler`, `HttpsUrlGeneration`, `CronErrors`, `FileLocking`. These render on the normal admin "Security & setup warnings" panel, not a hidden debug page. [nextcloud-setupchecks-src]
- Nextcloud's `info` state is semantically PDPP's `unknown` — "cannot be guaranteed that the check passed (e.g. missing precondition for running the test)" — and it is rendered to the admin as a distinct, non-failing tier rather than hidden. A four-state per-condition vocabulary shown to an owner is shipped product, not a hypothetical. [nextcloud-setup-checks]
- Bitwarden ships a named-report list (Exposed Passwords, Reused Passwords, Weak Passwords, Unsecured Websites, Inactive 2FA, Data Breach, and Member Access for orgs) with no rolled-up health score anywhere. It is one navigation step from the landing screen (Tools → Reports), native and consumer-facing. [bitwarden-reports]
- Home Assistant — the product cited as the source of the actionability rule — surfaces a LIST to owners in normal Settings, not a single state: "Navigate to Settings > System > Repairs to see the list of issues that need your attention." The HA rule therefore constrains WHICH conditions may be shown (actionable ones) and caps neither their NUMBER nor their list form. [ha-repair-issues-raw]
- TrueNAS ships ~80+ independent alert-source classes in `middlewared/alert/source`, each independently evaluated and surfaced simultaneously in the admin alerts panel. [truenas-alert-sources]
- The surviving true form of the negative claim is much narrower than stated: no surveyed product renders the PASSING conditions as its primary surface. Every counterexample found (Watchtower, Repairs, TrueNAS alerts) filters to non-passing rows; Nextcloud is the partial exception because its `info` tier is a non-passing-but-non-failing row that is shown. [1password-watchtower][nextcloud-setup-checks][ha-repair-issues-raw][truenas-alert-sources]

> **[CROSS-LINK ADDED 2026-08-19 — CORROBORATING EVIDENCE ALREADY IN THE CORPUS.]** Two pre-existing entries independently support the refutation above and were not cited by either same-day entry:
> - `data-explorer-ux/connection-inventory-ux-strict-noun-hierarchy-worded-status-legends-predicate-bound-counts.md` documents **Airbyte shipping a connection-level status legend as an explicit icon+label+description table** ("Healthy = the most recent sync for this connection succeeded", plus Failed/Running/Pending) *and* a second stream-level legend — i.e. a named, worded, per-condition legend rendered as part of the product surface. Its rule "every status color is paired with a word AND a one-line predicate definition... No leading tool ships a bare colored dot; the legend is part of the product surface" is direct support for showing named conditions rather than one opaque pill, and it independently supports the per-condition rollup ("health is computed per-capability, not as one blob, then rolled up by a stated precedence").
> - `feedback-systems/mature-integrations-only-interrupt-the-owner-when-no-held-credential-can-resolve-it-and-route-everything-else-to-a-dashboard.md` had already landed the same two-layer resolution this entry argues for: "an attention layer that shows only what the human can act on, and a full-fidelity inspection/detail layer one click down that never lies and never withholds." That is the filter-plus-expander shape, reached independently and before this dispute.
>
> Both are persona-independent (derived from Airbyte/Plaid/Datadog/Stripe behaviour), so they survive the consumer reclassification intact.

### PDPP's conditions are not a fetch — they are a clock-and-sweep-driven projection, so the TanStack/GitHub analogy misfits

- PDPP's `Fresh` condition flips from `current` to `stale` on wall-clock advance with no run occurring: `deriveReferenceFreshness` computes `nowTime = timeOrNull(input.now ?? new Date()) ?? Date.now()` and sets `status = capturedTime !== null && nowTime - capturedTime <= maxStalenessMs ? "current" : "stale"`. A "settled" verdict decays untouched. [pdpp-freshness]
- Of PDPP's 13 conditions, only `CollectionSucceeded` is primarily run-scoped. The other 12 read durable stores (credential store, attention store, backoff/schedule rows, browser-surface lease store, device heartbeats, the asynchronously repaired `connector_summary_evidence` cache), live environment probes (runtime/remote-surface allocators), or wall-clock expiry comparisons (`Fresh`, `RetryPolicyClear`, `AttentionClear` via `conditionExpired`). None require a new run to change. [pdpp-connection-health]
- There is no single "as of" moment for a PDPP verdict. `ConnectionHealthSnapshot` and `RenderedVerdict` carry no top-level timestamp; instead EACH condition carries its own `observed_at`, defaulted per-condition and overridden by its own evidence source (`Fresh` from `run.lastSuccessAt`, `RuntimeAvailable` from `runtime.allocator_observation.observed_at`). The verdict is a projection over evidence with heterogeneous as-of times. [pdpp-connection-health]
- The read model is explicitly computed-on-read against the current clock, not cached: coverage/freshness/connection_health/rendered_verdict/next_action are "computed on read against the current `now`... so a cached verdict can never say a source is healthy after its evidence has gone stale." [pdpp-ref-control]
- PDPP encodes permanently uncollectable state that no future run will change: `connector_detail_gaps` has a durable per-row status enum `["pending", "in_progress", "recovered", "terminal"]`; terminal rows "are never blanket-reset" and are only cleared by an operator-approved scoped requeue. `ForwardDisposition = "terminal"` means "an outstanding gap that no future ordinary run is expected to fill without a connector or source change." [pdpp-detail-gap-store][pdpp-connection-health]
- PDPP supports connectors that will never run again. `google_takeout` and `twitter_archive` declare `"recommended_mode": "manual"`, `"background_safe": false`, `"coverage_strategy": "snapshot_import_receipt"`, `"freshness_strategy": "manual_as_of"`, and declare NO `maximum_staleness_seconds` — so a completed one-time import is pinned `current` forever by an explicit special case, never lapsing by clock. For these, `never_run`/`checking`/`collecting` are vacuous and `settled` is permanent. [pdpp-ref-control][pdpp-connection-health]

### PDPP already separates activity from verdict — the two-axis split is substantially already implemented

- PDPP's health projection states the orthogonal-axis design as an explicit, already-shipped decision, in its own module docstring: "`syncing` (active work) and `stale` (freshness violation) are NOT headline states. They are exposed as orthogonal axes/badges so the dashboard can render activity/freshness without inventing a new pill every time we add an evidence source." The cited design decision is named "Connection Health Uses Ordered Projection Plus Orthogonal Axes". [pdpp-connection-health]
- The axes are a first-class typed interface, not an ad-hoc boolean: `ConnectionAxes` = `{ attention, coverage, freshness, outbox, remote_surface }`, with a separate `ConnectionBadges` = `{ stale, syncing }` documented as "Activity badges; never replace the headline pill." [pdpp-connection-health]
- PDPP already implements the RFC 5861 labeled-and-bounded staleness contract as an enforced invariant, not a convention: `missingFreshnessAnnotationViolation` returns a violation whenever `snapshot.axes.freshness !== "fresh"` and no `freshness`-kind annotation is present — "off-fresh verdict is missing its co-required freshness annotation (inv 1)". A stale verdict cannot render without its staleness label. [pdpp-rendered-verdict]
- PDPP already renders last-known-good WITH an in-flight label: `freshnessAnnotationText` returns "Refreshing now." when `snapshot.badges.syncing` is set on an off-fresh connection, and otherwise emits policy-keyed age text ("Last refreshed {age}. Refreshes on schedule.", "Stale — this connector refreshes when you run it."). [pdpp-rendered-verdict]
- The verdict synthesizer enforces 11 invariants over the whole verdict (honesty 1-7, silence S1-S4) and throws `VerdictInvariantError` in production on any violation, falling back to a `safeGreyVerdict` otherwise. Invariant 6 (`toneLabelViolation`) asserts `pill.label` equals the recomputed `labelForPill(...)` — the label is server-recomputed and pinned. [pdpp-rendered-verdict]

### The grant-scoped maintainer-text leak does not exist in production code

- `toGrantScopedVerdict` has ZERO production callers. A repo-wide grep excluding tests returns exactly two hits: the function's own definition at `rendered-verdict.ts:2127`, and a doc comment at `ref-control.ts:787` saying "use `toGrantScopedVerdict` before forwarding to grant-scoped clients." Its own docstring says "Dispatch C wires this at the wire seam" — Dispatch C is not wired. [pdpp-rendered-verdict][pdpp-ref-control]
- The two production sites that emit `rendered_verdict` are `ref_connector_detail` and `owner_connection_diagnostics`, both owner-authenticated. The diagnostics route is mounted "under a separate owner-bearer auth adapter (`requireToken` + `requireOwner`)". [pdpp-ref-control]
- The MCP grant-scoped surface cannot leak the verdict because it never carries it: a canonical-mirror test asserts the serialized MCP tool result contains none of `rendered_verdict`, `required_actions`' companions `satisfied_when`, `tone_cause`, `channel_cause`, or `suppressed_evidence` — "must not appear in MCP grant-scoped reads". [pdpp-mcp-mirror]
- The public/grant-scoped OpenAPI contract exposes no health state at all: `reference-public.openapi.json` has no `health` or `state` field. The 7-value `ConnectionHealthState` enum is pinned only in `reference-full.openapi.json` (the owner surface). [pdpp-openapi]
- The `VerdictLabel` union is NOT pinned in any OpenAPI or contract package — `rendered_verdict` is declared `{"additionalProperties": true, "type": "object"}`. The label exists only as a TypeScript union and as literal strings in tests. [pdpp-openapi][pdpp-rendered-verdict]

### The `ProjectionReliable` defect is real and independently confirmed

- `projectionReliableCondition` sets `status: "false"` with `severity: "blocked"` whenever `unreliableSources.length > 0` — it has no `unknown` branch, so it is a pure binary. Its remediation is already `{ action: "wait", label: "Wait for the reference read model to refresh", retryable: true }`, i.e. the code already knows this is a wait, not a fault. [pdpp-connection-health]
- The in-flight route is confirmed: an active run in `controller_active_runs` forces the evidence row to `deferred = true` / `state: "stale"`; `evidenceUnreliableSources` then pushes `evidence.record_snapshot.reason_code || "record_checkpoint_lag"` when `record_snapshot.state !== "current"`. [pdpp-evidence-engine][pdpp-ref-control]
- `classifyUnreliableProjection` is the FIRST entry in `HEALTH_CLASSIFICATION_STEPS` and returns `state: "unknown"` when `ProjectionReliable.status === "false"`; `baseStateTone` maps `unknown` to grey. So an actively-running connection can render "Not measured". [pdpp-connection-health]

### Cost of the redesign

- The `VerdictLabel` union has 7 members: `Can't collect`, `Checking`, `Degraded`, `Healthy`, `Needs refresh`, `Not measured`, `Syncing`. [pdpp-rendered-verdict]
- Label literals appear 265 times across 31 files: 12 in `reference-implementation/test`, 12 in `apps/console`, 5 in `packages/polyfill-connectors`, 1 each in `reference-implementation/server` and `runtime`. Within the RI test tree alone the count is ~112 assertions. [pdpp-rendered-verdict]
- PDPP is self-hosted and its own docs fuse the owner and operator roles: the spec says "The owner starts a run from the operator console", and the self-host quickstart distinguishes the hosted MCP surface from the console by saying the MCP surface "does not expose owner-mode administration" — i.e. the console IS owner-mode. [pdpp-selfhost-quickstart]

> **[CORRECTION 2026-08-19 — THE PERSONA INFERENCE DRAWN FROM THIS EVIDENCE IS VOID. The product owner states the requirement has changed: PDPP is a CONSUMER product.]** This entry read the evidence above as establishing that PDPP's user is a technical operator, and used that to justify keeping the full condition list (see SYNTHESIS step 2 and the closing paragraph, both corrected below). Two things are wrong with that inference, independent of the requirement change:
>
> 1. **The evidence never supported a persona claim.** What it actually shows is a directory NAME (`docs/operator/`), a directory description, and one sentence about *who starts a run*. A re-check of the repo on 2026-08-19 found **no written audience statement anywhere** — `README.md`, `spec-core.md`, and `spec-architecture.md` were all checked and none states a target user. The only occurrence of "consumer" in the spec (`spec-core.md:69`) describes a *data source* ("a consumer platform"), not PDPP's user. Naming a directory `operator/` is not a persona requirement.
> 2. **The requirement is now explicitly consumer.** Whatever the naming implied, the product owner has stated PDPP is a consumer product. Every recommendation in this entry that reads "PDPP's owner is its operator, therefore X" is void and must be re-derived.
>
> **What this does NOT change:** the counterexamples in the first CLAIMS section get *stronger*, not weaker. 1Password Watchtower, Bitwarden, and Home Assistant Repairs are consumer products showing condition lists to consumers. Under a technical persona those counterexamples were merely permissive ("even consumers get a list, so an operator certainly may"); under a consumer persona they are directly on-point precedent. The surviving filter rule ("nobody renders the passing rows") is likewise persona-independent — it was derived from the products' behaviour, not from PDPP's audience.

## SOURCES

**1password-watchtower**
URL: https://support.1password.com/watchtower/
Accessed: 2026-08-19
Quote: "Any Watchtower category that has items in it will appear on your dashboard."
Note: Categories enumerated on the page: Imported from LastPass; Compromised websites and vulnerable passwords; Passkeys available; Items in another account; Reused and weak passwords; Unsecured websites; Two-factor authentication; Expiring items; Items with duplicates; Developer secrets on disk. Fetched directly (not via search summary).

**nextcloud-setup-checks**
URL: https://raw.githubusercontent.com/nextcloud/documentation/master/developer_manual/digging_deeper/setup_checks.rst
Accessed: 2026-08-19
Quote: "success: Test succeeded no action needed." / "info: No action required but it can not be guaranteed that the check passed (e.g. missing precondition for running the test)." / "warning: The test failed but the result is not fatal, yet the administrator should be warned about this." / "error: The test failed and some functionality is not available or might be broken."
Quote: setup checks are "reported to the administrator, either on the web interface (admin setting), or when running the `occ setupchecks` command."
Note: `ISetupCheck::getName()` returns a user-visible translated string; `getCategory()` returns security/accounts/system or a custom category. Raw RST fetched from the official docs repo.

**nextcloud-setupchecks-src**
URL: https://api.github.com/repos/nextcloud/server/contents/apps/settings/lib/SetupChecks
Accessed: 2026-08-19
Note: Directory listing returns 71 PHP files, each one named setup check. Sample: AllowedAdminRanges, AppDirsWithDifferentOwner, BruteForceThrottler, CheckUserCertificates, CodeIntegrity, CronErrors, CronInfo, DataDirectoryProtected, DatabaseHasMissingColumns, DatabaseHasMissingIndices, DebugMode, EmailTestSuccessful, FileLocking, HttpsUrlGeneration, MemcacheConfigured.

**bitwarden-reports**
URL: https://bitwarden.com/help/reports/
Accessed: 2026-08-19
Note: Named reports — Exposed Passwords, Reused Passwords, Weak Passwords, Unsecured Websites, Inactive 2FA, Data Breach, Member Access (organizations). No aggregate health score. Reached via Tools → Reports, one step from the landing screen. Retrieved via delegated agent fetch; the category list is corroborated across the vendor help centre but was not raw-fetched by me.

**ha-repair-issues-raw**
URL: https://github.com/home-assistant/home-assistant.io — `source/_docs/repairs.markdown`
Accessed: 2026-08-19
Quote: "Navigate to Settings > System > Repairs to see the list of issues that need your attention."
Note: Raw markdown source fetched by delegated agent. Complements (does not contradict) the actionability rule at developers.home-assistant.io quoted in the entry under attack.

**truenas-alert-sources**
URL: https://github.com/truenas/middleware/tree/master/src/middlewared/middlewared/alert/source
Accessed: 2026-08-19
Note: ~80+ independent alert-source classes (disk SMART/temp, pool health, NFS/SMB/iSCSI, replication, certificates, UPS, quotas, failover). Directory listing verified by delegated agent; the rendering behaviour of the live alerts panel was NOT quote-verified from official docs.

**pdpp-connection-health**
URL: /home/tnunamak/code/pdpp/reference-implementation/runtime/connection-health.ts
Accessed: 2026-08-19
Quote (module docstring, :22-25): "`syncing` (active work) and `stale` (freshness violation) are NOT headline states. They are exposed as orthogonal axes/badges so the dashboard can render activity/freshness without inventing a new pill every time we add an evidence source."
Quote (:27-28): "Precedence (from `openspec/.../design.md` Decision: Connection Health Uses Ordered Projection Plus Orthogonal Axes)"
Quote (:725-740): `interface ConnectionAxes { attention; coverage; freshness; outbox; remote_surface }` and `/** Activity badges; never replace the headline pill. */ interface ConnectionBadges { stale; syncing }`
Note: 13 condition types at :65-78; `projectConditions` :1754-1784 with per-condition `observed_at` at :1776-1783; `projectionReliableCondition` :1838-1871 (binary false/true, `severity: "blocked"`, remediation `action: "wait"`); `classifyUnreliableProjection` first in `HEALTH_CLASSIFICATION_STEPS` :1226-1241, body :1303-1319; `conditionExpired` clock comparisons :1820-1836; `ForwardDisposition = "terminal"` :328-329.

**pdpp-freshness**
URL: /home/tnunamak/code/pdpp/reference-implementation/server/freshness.ts
Accessed: 2026-08-19
Quote (:44): `const nowTime = timeOrNull(input.now ?? new Date()) ?? Date.now();`
Quote (:59-61): `status = capturedTime !== null && nowTime - capturedTime <= maxStalenessMs ? "current" : "stale";`

**pdpp-rendered-verdict**
URL: /home/tnunamak/code/pdpp/reference-implementation/runtime/rendered-verdict.ts
Accessed: 2026-08-19
Quote (:75-82): `VerdictLabel = "Can't collect" | "Checking" | "Degraded" | "Healthy" | "Needs refresh" | "Not measured" | "Syncing"`
Quote (:1917, inv 1): "off-fresh verdict is missing its co-required freshness annotation (inv 1)"
Quote (:1381): freshness annotation returns `"Refreshing now."` when `snapshot.badges.syncing`
Quote (:2121-2124): "Project the inspection-layer `detail` and calibration `trace` OFF a verdict for a grant-scoped client... Dispatch C wires this at the wire seam; exported here so the grant-scope regression can pin the contract at the type level."
Note: `GrantScopedVerdict` :2125; `toGrantScopedVerdict` :2127-2130; `assertInvariants` :1982-1984; `VerdictInvariantError` :1833-1838 thrown at :2097; `safeGreyVerdict` :1986-2008; `honestyViolations` :1913-1925; `silenceViolations` :1940-1976. Label-literal census: 265 occurrences across 31 files (12 RI test, 12 apps/console, 5 polyfill-connectors, 1 server, 1 runtime).

**pdpp-ref-control**
URL: /home/tnunamak/code/pdpp/reference-implementation/server/ref-control.ts
Accessed: 2026-08-19
Quote (:787-788): "`detail` and `trace` are owner-only; use `toGrantScopedVerdict` before forwarding to grant-scoped clients."
Quote (:3878-3880): `if (evidence.record_snapshot.state !== "current") { sources.push(evidence.record_snapshot.reason_code || "record_checkpoint_lag"); }`
Quote (:4686-4693): manual-refresh connectors with `maximumStalenessSeconds === null` are forced `status: "current"`.
Note: `rendered_verdict` emitted at :7172 (`ref_connector_detail`) and :7404 (`owner_connection_diagnostics`) only. Computed-on-read comment in `server/connector-summary-read-model.ts:15-18`. Owner-bearer mount (`requireToken` + `requireOwner`) at `server/index.ts:6807-6840`.

**pdpp-evidence-engine**
URL: /home/tnunamak/code/pdpp/reference-implementation/server/connector-summary-evidence-engine.ts
Accessed: 2026-08-19
Note: :1326-1331 (SQLite) and :1480-1486/:1593 (Postgres) — an active row in `controller_active_runs` sets `deferred = true` and `built = { dirty: 1, state: "stale" }`.

**pdpp-mcp-mirror**
URL: /home/tnunamak/code/pdpp/packages/mcp-server/test/canonical-mirror.test.ts
Accessed: 2026-08-19
Quote (:343-356): forbidden list includes `"rendered_verdict"`, `"tone_cause"`, `"channel_cause"`, `"suppressed_evidence"`, `"satisfied_when"`, asserted with `${forbidden} must not appear in MCP grant-scoped reads`.

**pdpp-detail-gap-store**
URL: /home/tnunamak/code/pdpp/reference-implementation/server/stores/connector-detail-gap-store.ts
Accessed: 2026-08-19
Quote (:177): `VALID_STATUSES = new Set(["pending", "in_progress", "recovered", "terminal"])`
Note: :833-835, :894 — "terminal rows are never blanket-reset"; scoped requeue at :856-871.

**pdpp-openapi**
URL: /home/tnunamak/code/pdpp/reference-implementation/openapi/reference-full.openapi.json and reference-public.openapi.json
Accessed: 2026-08-19
Note: `ConnectionHealthState` 7-value enum pinned in reference-full at ~:21659-21670 and ~:22273-22280. `rendered_verdict` declared `{"additionalProperties": true, "type": "object"}` at ~:21879-21882 and ~:22493-22496 — the VerdictLabel enum is pinned nowhere. reference-public has no `health`/`state` field. Verified by delegated agent grep.

**pdpp-selfhost-quickstart**
URL: /home/tnunamak/code/pdpp/docs/operator/selfhost-quickstart.md and /home/tnunamak/code/pdpp/spec-architecture.md
Accessed: 2026-08-19
Quote (spec-architecture.md:102): "The owner starts a run from the operator console, or the scheduler starts one on the configured cadence"
Quote (selfhost-quickstart.md:311-314): "event-subscription management stays in the operator console and REST/control-plane docs. It does not expose owner-mode administration."

## SYNTHESIS

I attacked five claims. Two broke, one broke partially, two survived. The recommendation as a package does not survive; a much smaller fix does.

**Refuted: the negative survey claim.** "No consumer product shows a raw condition list to a non-developer owner" is false, and the falsifying case is the most consumer-facing product in the whole survey. 1Password Watchtower's dashboard is not a rollup with a drill-down — the list of named categories IS the dashboard, and the audience is people who bought a password manager. Nextcloud ships 71 named checks with a documented four-state per-check vocabulary on a normal admin settings panel, and its `info` state ("cannot be guaranteed that the check passed") is precisely the `unknown` tier the original entry assumed no product would ever show an owner. Bitwarden ships the same shape one click from the landing screen with no aggregate score anywhere. And the product cited as the *source* of the rule, Home Assistant, tells owners to "see the list of issues" in Settings — so the HA rule constrains *which* conditions may appear, not *how many*, and not the list form.

What survives is a narrower and more useful rule, and the original entry's authors would have found it if they had searched for the counterexample instead of the confirmation: **nobody renders the passing conditions.** Watchtower shows categories "that have items in it". Repairs shows issues needing attention. TrueNAS shows firing alerts. The failure mode PDPP should avoid is not "a list" — it is "a list of thirteen rows, ten of which say everything is fine." That is a filtering rule, and filtering is a one-line predicate, not an enum redesign.

**Refuted: the two-axis redesign, on two independent grounds.**

First, the analogy misfits. TanStack and GitHub check-runs both govern a bounded unit of work with a beginning and an end, and their whole design turns on the moment the work finishes. PDPP's conditions do not work like that. Only one of thirteen (`CollectionSucceeded`) is settled by a run finishing. `Fresh` flips to stale on `Date.now()` alone with no run at all. `RetryPolicyClear` and `AttentionClear` expire on the clock. `ProjectionReliable` is repaired by a background sweep. `RuntimeAvailable` and `RemoteSurfaceAvailable` are live environment probes that change when an allocator has a capacity event on the other side of the deployment. There is no single as-of moment to settle *to* — every condition carries its own `observed_at`, and the whole read model is recomputed against the current clock on every request. The right analogy is a materialized view with per-row staleness, or a filesystem carrying fsck state; the accounting-ledger framing is the closest of the three the brief offered, because PDPP's terminal gaps are exactly unreconcilable entries that are proven, durable, and will never clear. `verdict = null until settled` would mean, for a `google_takeout` connection that imported once in March and will never run again, either a permanent null or a permanent settled — and the code already pins it `current` forever by special case. A lifecycle axis of `never_run / checking / collecting / settled` is vacuous for a whole class of PDPP connectors.

Second, and this is the part that should have been checked before recommending a redesign: **PDPP already did this.** The module docstring for the health projection states it as a shipped decision — "`syncing` (active work) and `stale` (freshness violation) are NOT headline states. They are exposed as orthogonal axes/badges" — under a named design decision, "Ordered Projection Plus Orthogonal Axes". `ConnectionAxes` is a typed five-field interface and `ConnectionBadges` is documented as "never replace the headline pill." The recommendation's core insight is the existing architecture, restated. What is actually wrong is narrower: two of the axes leak back into the headline through the `ProjectionReliable` binary. That is a bug in one condition, not a missing axis.

**Refuted: the grant-scoped leak.** The companion entry's most alarming finding — that "Connector code needs a fix" reaches owners because `GrantScopedVerdict` strips only `detail`/`trace` and not `required_actions` — describes a function with zero production callers. The type exists; the redaction exists; nothing calls it, because (per its own docstring) "Dispatch C wires this at the wire seam" and Dispatch C was never wired. Both production emitters of `rendered_verdict` are owner-authenticated (`requireToken` + `requireOwner`). The MCP grant-scoped path cannot leak it because a test asserts `rendered_verdict` never appears in an MCP result at all, and the public OpenAPI contract has no health field whatsoever. The type-level fix proposed (a discriminated union with no `cta` on maintainer actions) is still *good hygiene* for the day someone wires Dispatch C, but it was sold as closing a live leak to owners and there is no live leak. This matters beyond the one claim: it is the difference between a security finding and a latent design note, and the original entry graded it as the former.

**Survived: the last-known-good discipline — and PDPP already exceeds the bar.** I attacked this by looking for the silently-stale-green class the brief predicted, and could not produce it, because PDPP enforces the RFC 5861 contract more strictly than the proposal describes. `missingFreshnessAnnotationViolation` makes it an *invariant* — a verdict whose freshness axis is off-fresh and which carries no freshness annotation is a violation that throws `VerdictInvariantError` in production. There is no code path that shows a stale value without its age label, which is exactly the Age-header requirement, enforced rather than intended. The in-flight case is already handled and already honest: `freshnessAnnotationText` returns "Refreshing now." when a run is active on a stale connection, precisely so stale copy telling the owner to run a refresh is not "contradicted by the run already in flight" (the code's own comment). The dead-credential-90-minutes-ago failure mode the brief predicted does not arise, because credential evidence is durable and read independently of run outcome — the code comments that it "SHALL still project that repair need rather than healing merely because the run reason aged out." The one real residual is that a hung run (the YNAB 20-minute case) keeps `badges.syncing` true and so keeps showing "Refreshing now." indefinitely; there is no bound on that annotation. That is a genuine gap and it is a *timeout*, not an axis.

**Survived: the `ProjectionReliable` defect.** I tried to break this one and could not. It is a pure binary with no `unknown` branch, it fires first in precedence, and it forces grey "Not measured" on a connection that is actively running. The tell that this is unambiguously a bug rather than a modeling choice is in the condition's own remediation: `{ action: "wait", label: "Wait for the reference read model to refresh", retryable: true }`. The code already knows this is a wait. It just encodes the wait as `status: "false"` with `severity: "blocked"`, which is the one thing Kubernetes says explicitly not to do.

**Verdict: minimal fix, decisively.** The redesign costs 265 label literals across 31 files spanning the RI, the console, and the connector package, plus rework of an 11-invariant honesty gate whose invariant 6 recomputes and pins `pill.label`. It buys an axis separation that already exists under a different name. Against that, the minimal fix is three changes, in descending value:

1. Give `ProjectionReliable` an `unknown` branch when the only unreliable source is the active-run deferral (`record_checkpoint_lag`). One condition, one branch. This is the entire "Not measured while running" bug, and it is the change both source entries correctly identified as highest-value.
2. Filter passing conditions out of the owner surface. This is the *real* prior-art rule — Watchtower, Repairs, and TrueNAS all filter to non-passing — and it is a predicate, not a redesign. ~~Keep the full list behind a details affordance, because PDPP's owner is its operator.~~ **[PERSONA-DEPENDENT CLAUSE CORRECTED 2026-08-19: the "because PDPP's owner is its operator" justification is VOID — the requirement is now consumer.]** The *filter* survives unchanged and is in fact the stronger half, since it was derived from consumer products (Watchtower, Repairs). What must be re-derived is the disposition of the hidden rows: keeping the full list behind a details affordance can no longer be justified by "the owner is an operator." Re-decide it on consumer grounds — note that the counterexamples support a details affordance anyway (Watchtower categories expand to their items; HA Repairs rows open a flow), so the conclusion may well survive, but it needs a consumer-grounded reason, not the operator one.
3. Bound the "Refreshing now." annotation with a timeout so a hung run degrades instead of asserting forever.

Do not delete the condition list, and do not hide it by default from the *expanded* view. ~~That is the third attack and it lands: PDPP's owner installed Docker, generated an encryption key, and is called "the operator" by the spec ("The owner starts a run from the operator console"). The self-host quickstart calls the console "owner-mode administration." Owner and operator are one person, and the consumer-product prior art was being imported for a persona this product does not have.~~ The Watchtower counterexample cuts the same way from the other side: even a genuinely consumer audience gets the list. Reserve the audience split for the day PDPP has a real second audience — a grant-scoped client rendering health — which, per the OpenAPI contract, it does not have yet.

> **[CORRECTION 2026-08-19 — THE STRUCK PASSAGE IS VOID; THE CONCLUSION SURVIVES ON DIFFERENT GROUNDS.]** The third attack was argued from a technical-operator persona that the product owner has now declared void: **PDPP is a consumer product.** The struck sentences are also weak on their own terms — see the correction in CLAIMS above — because the cited evidence is a directory name and a sentence about who starts a run, and the repo contains no written audience statement at all.
>
> Crucially, **the conclusion "do not delete the condition list" does not depend on the struck premise.** It was over-determined, and the surviving leg is the stronger one: the Watchtower/Bitwarden/Home-Assistant counterexamples are *consumer* products that show condition lists to *consumers*. Under the old technical persona those cases were a permissive floor; under the consumer requirement they are direct precedent. So the list survives — but it now survives *because* consumers get lists in shipped products, not because PDPP's user is an operator.
>
> What genuinely changes under the consumer requirement:
> - **The filter (fix 2) is promoted from good practice to the load-bearing requirement.** Its whole prior-art basis is consumer products, and "thirteen rows, ten of them green" is a worse failure for a consumer than for an operator.
> - **Condition NAMES become a live problem.** The naming verdict in the companion `api-contract-design` entry (`ProjectionReliable` → `DataQueryable`, `RemoteSurfaceAvailable` → `BrowserSessionAvailable`, `LocalExporterAvailable` → `ExportToolAvailable`) was graded there as taxonomy hygiene. Under a consumer persona it is a *product* requirement: an owner-visible row reading `ProjectionReliable` is internal event-sourcing vocabulary shown to a consumer. This entry's cost argument (265 label literals) applies to the LABEL union, not to condition names, so it does not weigh against the renames.
> - **The "hide behind details" disposition needs a consumer-grounded reason** (see fix 2 above).
>
> Unchanged: every PDPP code finding, the materialized-view refutation, the grant-leak refutation, the `ProjectionReliable` defect, and the cost census. None of those were persona-dependent.

**What would make me wrong.** If PDPP's target user is not Tim but a future non-technical installer on a one-click host, the persona argument inverts and the consumer prior art applies. If `rendered_verdict` is about to be exposed on the public/grant-scoped contract, the leak analysis becomes a live pre-emptive finding rather than a refutation. And if a fourth axis is coming that genuinely cannot be expressed as a badge, the enum pressure the redesign anticipates is real and paying it early is cheaper. ~~None of those are true today.~~

> **[UPDATE 2026-08-19 — THE FIRST CONDITION HAS FIRED.]** The first sentence of this paragraph was the correct self-invalidation trigger, and it triggered the same day: the product owner states PDPP is a **consumer** product. So "the persona argument inverts and the consumer prior art applies" is now the operative reading — treat the persona leg of this entry as void and the consumer prior art as directly applicable. See the corrections in CLAIMS and in the closing SYNTHESIS paragraph for what flips (the filter is promoted to load-bearing; the condition RENAMES become a product requirement) and what survives (the condition list itself, on the strengthened Watchtower/Bitwarden/HA precedent, and every code-level finding). The second and third conditions remain untrue as of this date.

**Confidence.** High on the counterexamples (1Password and Nextcloud raw-fetched by me, including the 71-file directory listing). High on every PDPP code claim (read directly, file:line). High that `toGrantScopedVerdict` has no production caller (exhaustive repo grep). Medium on Bitwarden and TrueNAS, which came via delegated fetch and were not raw-verified by me. Not verified: I did not execute the suite or render any UI, so the "Not measured while running" race is proven by construction, not observed; and I did not view the Nextcloud or Watchtower panels live, only their documented APIs and category lists.
