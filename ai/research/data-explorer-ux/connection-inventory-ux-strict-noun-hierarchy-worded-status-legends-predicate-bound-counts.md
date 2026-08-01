---
title: "Leading connection/source inventories use a strict source⊃connection⊃stream noun hierarchy named consistently at every zoom level, pair every status color with a word and a one-line predicate, bind the rollup count to the same predicate as its drilled list, compute health per-capability, label counts with a basis (which run/window), and enumerate multiple accounts/devices instead of hiding them"
date: 2026-06-18
topic: data-explorer-ux
tags: [connection-inventory, status-legend, health-rollup, master-detail, repair-flow, prior-art]
status: draft
sources: [airbyte-status, airbyte-connections, plaid-items, plaid-institutions, plaid-update-mode, sentry-issues, sentry-projects, datadog-config, datadog-status, github-apps, tailscale-machines, stripe-dashboard]
source_session: 019d3a01-db31-7f00-b048-715f05e09cb7
---

## CLAIMS

- Airbyte ships a connection-level status legend as an explicit icon+label+description table — "Healthy = the most recent sync for this connection succeeded," plus Failed/Running/Pending — and a second, distinct stream-level legend (Synced/Syncing/Queued/Pending), with a note that a connection queued for capacity renders its streams as Pending, not Queued. Drill path: connections list → one connection → per-stream breakdown. Each stream shows "time since Airbyte loaded the last record" (relative, with exact datetime one click away via "Last record loaded") and a last-8-syncs small-multiple of Streams status + Records loaded (count tied to a specific sync, not a lifetime total). A sync that fails repeatedly is auto-disabled — an honest terminal state rather than silent staleness. [airbyte-status]
- In Airbyte's noun model a connection is the configured source→destination pairing that owns a set of selected streams; the connection is the unit you name, schedule, and read status for, and streams are the detail. [airbyte-connections]
- Plaid's Item is "a Login at a financial institution" — the connection object, distinct from the institution (source) and from the accounts under it (one Item → many accounts). Named terminal states arrive via webhooks: `ITEM_LOGIN_REQUIRED` (send the user through update mode), region-split advance warnings `PENDING_EXPIRATION` (Europe/UK, consent expiring in 7 days) and `PENDING_DISCONNECT` (US/Canada), and `LOGIN_REPAIRED` — an explicit positive recovery event that instructs apps to silence reconnect messaging (recovery is a fired signal, not merely the absence of an error). An Item carries a non-null `error` object only when queried via `/item/get`, with `error_code` + `error_type` + human `display_message`. [plaid-items]
- Plaid's institution status legend is defined in words — `HEALTHY` ("the majority of requests are successful"), `DEGRADED` ("only some requests are successful"), `DOWN` ("all requests are failing") — computed per capability (Auth, Balance, Identity, Transactions, Item logins each have their own status object), with a `breakdown` of `success`/`error_plaid`/`error_institution` summing to 1 over a disclosed time window. [plaid-institutions]
- Plaid Link update mode is a dedicated repair flow for an Item in `ITEM_LOGIN_REQUIRED`: re-auth in place, same Item/access_token, accounts preserved — the repair CTA leads to a repair, not a fresh-setup picker. [plaid-update-mode]
- Sentry's Issues page uses tabs that are each a named saved filter with the literal query shown (`is:unresolved`, `is:unresolved is:for_review`, `is:regressed`, `is:archived`, `is:escalating`); the rollup and the drilled list are the same query, so a count can only drill to exactly the rows that satisfy that predicate. [sentry-issues]
- Sentry project pages roll up health (crash-free sessions/users, adoption, issue counts) at the project level, then drill project → issue → event — multi-level master-detail where each level shows its own health summary. [sentry-projects]
- Datadog defines alert vs warning as separate thresholds each with its own recovery threshold; the yellow (Warn) and red (Alert) states have explicit numeric predicates and recovery is a distinct condition, so a monitor flips back to OK by rule, not vibes. [datadog-config]
- Datadog's per-monitor status page decomposes an alerting monitor into exactly the offending groups (Evaluated Data / Source Data / Transitions graphs, scope-down template variables) — the rollup breaks down into the specific alerting members, with an OK→Warn→Alert→OK Transitions timeline. [datadog-status]
- GitHub's installed-Apps management enumerates each app's granted permissions and accessible repositories, and offers two distinct verbs: suspend (temporary block) vs delete (permanent removal). [github-apps]
- Tailscale auto-generates a machine name from the OS hostname on startup (e.g. `laptop-a4og4947`), renameable via the Machines / Machine Details page (ellipsis → Edit machine name; an "Auto-generate from OS hostname" checkbox, checked by default, that you uncheck to pin a custom name) — many physical devices as a flat, individually-named, addressable inventory under one owner. [tailscale-machines]
- Stripe's dashboard separates operational lists (Payments, Balance) for scan/triage from a reporting surface (Reports hub with filters + custom columns, Sigma SQL, Data management) — the bounded list view advertises where the full, filterable, exportable set lives. [stripe-dashboard]

## SOURCES

**airbyte-status**
URL: https://docs.airbyte.com/cloud/managing-airbyte-cloud/review-connection-status
Accessed: 2026-06-18

**airbyte-connections**
URL: https://docs.airbyte.com/using-airbyte/getting-started/set-up-a-connection
Accessed: 2026-06-18

**plaid-items**
URL: https://plaid.com/docs/api/items/
Accessed: 2026-06-18

**plaid-institutions**
URL: https://plaid.com/docs/api/institutions/
Accessed: 2026-06-18

**plaid-update-mode**
URL: https://plaid.com/docs/link/update-mode/
Accessed: 2026-06-18

**sentry-issues**
URL: https://docs.sentry.io/product/issues/
Accessed: 2026-06-18

**sentry-projects**
URL: https://docs.sentry.io/product/projects/project-details/
Accessed: 2026-06-18

**datadog-config**
URL: https://docs.datadoghq.com/monitors/configuration/
Accessed: 2026-06-18

**datadog-status**
URL: https://docs.datadoghq.com/monitors/status/
Accessed: 2026-06-18

**github-apps**
URL: https://docs.github.com/en/apps/using-github-apps/reviewing-and-modifying-installed-github-apps
Accessed: 2026-06-18

**tailscale-machines**
URL: https://tailscale.com/kb/1098/machine-names
Accessed: 2026-06-18
Quote: "When a new machine is added to a Tailscale network, we automatically generate its machine name from its OS hostname… This field gets reported to Tailscale on startup."

**stripe-dashboard**
URL: https://docs.stripe.com/dashboard
Accessed: 2026-06-18

## SYNTHESIS

Cross-tool patterns for any "inventory of upstream connections, each with health, freshness, sub-streams, and drill-through":

- **Every status color is paired with a word AND a one-line predicate definition** (Airbyte "Healthy = last sync succeeded"; Plaid "HEALTHY = majority of requests succeed"; Datadog Warn/Alert by numeric threshold). No leading tool ships a bare colored dot; the legend is part of the product surface.
- **The rollup count and the drilled list are bound to the same predicate** (Sentry "For Review" tab is `is:unresolved is:for_review`; Datadog decomposes into exactly the alerting groups). Never compute a summary number by a selector that has no matching filtered view.
- **A strict noun hierarchy, named consistently at every zoom level**: source/institution ⊃ connection/Item ⊃ account/stream ⊃ record/event (Plaid Institution⊃Item⊃Account; Airbyte Source⊃Connection⊃Stream⊃record). The words never swap between list and detail.
- **Health is computed per-capability, not as one blob**, then rolled up by a stated precedence (Plaid keeps Auth/Balance/Transactions/Item-login health separate; Airbyte separates connection- from stream-status). The scanned badge is a rollup; the detail shows the axes that produced it.
- **Counts always carry a basis** — which run, what window, success-vs-total (Airbyte ties "Records loaded" to a specific sync; Plaid states the window). Never a bare lifetime integer.
- **Repair leads to repair, and self-heal is signaled by an explicit positive recovery event, not the mere absence of an error** (Plaid `ITEM_LOGIN_REQUIRED` → update-mode re-auth in place with accounts preserved; `LOGIN_REPAIRED` fires to silence reconnect messaging).
- **Two distinct verbs for pause vs sever, with access enumerated per resource** (GitHub suspend vs delete, per-repo access listed).
- **Physical devices are a flat, individually-named inventory under one owner**, each with an OS-derived but renameable name (Tailscale Machines).
- **A scan list is not the full-set query; the full-set path is named and discoverable** (Stripe Payments list vs Reports/Sigma).

Anti-patterns the survey rules out: bare colored dot with no word/predicate (also an a11y failure); a count whose drill applies a different predicate (or has no drill); a bare integer labeled ambiguously (e.g. "Collected") with no basis; swapping nouns between list and detail; hiding multiple accounts/collectors behind one summary; stacking every internal axis as a sibling badge; a repair CTA that lands on a fresh-setup picker; leaving a warning up after a connection self-heals.
