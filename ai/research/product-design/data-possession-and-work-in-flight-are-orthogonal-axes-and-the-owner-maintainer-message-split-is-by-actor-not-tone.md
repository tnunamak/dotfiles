---
title: "Data-possession and work-in-flight are orthogonal status axes that every mature system separates, mixed-polarity condition lists are provably not summarizable, and the owner/maintainer message split is by ACTOR (is there a user action?) not by tone — NOTE: this entry's 'no consumer product shows a raw condition list to a non-developer owner' claim was REFUTED 2026-08-19 (1Password Watchtower, Nextcloud, Bitwarden); the surviving rule is that nobody renders the PASSING conditions"
date: 2026-08-19
topic: product-design
tags: [status-ux, connector-health, in-flight, staleness, conditions, owner-vs-maintainer, progressive-disclosure]
status: draft
sources: [k8s-pod-lifecycle, rfc-5861, tanstack-queries, tanstack-placeholder, tanstack-paginated, swr-v2, swr-understanding, prometheus-staleness, robustperception-staleness, grafana-nodata-error, grafana-stale-instances, datadog-monitor-openapi, datadog-on-missing-data, nagios-plugin-return-codes, ha-repair-issues, ha-entity-unavailable, ha-log-when-unavailable, ha-diagnostics, zfs-zpool-status, synology-storage-health, plaid-errors, plaid-item-errors, plaid-transactions, plaid-items, aip-193, nserror-header, apple-error-objects, stripe-api-errors, stripe-decline-codes, stripe-api-verification, twilio-message-resource, twilio-errors, eslint-i18next-no-literal-string, govuk-error-message, rfc-9457, chrome-net-export, chromium-net-export, apple-sysdiagnose, google-takeout]
source_session: af82d1f3-1838-4307-a3a9-6bbf07e77c6f
---

<!--
RENAMED 2026-08-19. Previous filename:
  data-possession-and-work-in-flight-are-orthogonal-axes-and-no-consumer-product-shows-a-raw-condition-list-to-a-non-developer-owner.md
The old filename asserted a claim that was refuted the same day (1Password Watchtower,
Nextcloud's 71 setup checks, Bitwarden, and Home Assistant's own Repairs list). Per this
corpus's convention that "the filename IS the finding", a filename asserting a refuted
claim is itself a defect, so the refuted clause was dropped from the name. The refutation
history is preserved in the title, in CLAIMS, and in SYNTHESIS finding 2.

Builds on, does not repeat:
- api-contract-design/health-vocabularies-separate-a-lifecycle-axis-from-a-verdict-axis-and-kubernetes-explicitly-refuses-to-recommend-positive-condition-polarity.md
  (SAME DAY, same session lineage — owns the Kubernetes condition-schema layer: polarity,
  reason-vs-message, absent≡Unknown, phase deprecation, GitHub/systemd two-axis models,
  and the applied file:line verdict on PDPP's 13 conditions. Read that one FIRST.)
- feedback-systems/connector-fleet-health-state-ux-patterns-across-stripe-plaid-linear-vercel.md
- feedback-systems/integration-health-ui-converges-on-one-synthesized-verdict-...md
- ux-writing/product-status-and-error-copy-uses-a-closed-owner-adjective-vocabulary-...md
- data-collection-systems/self-hosted-single-owner-collector-agents-need-three-states-not-two-...md
  (three-state stale/unknown/broken vocabulary, Healthchecks.io "Late")

This entry adds four things none of those cover: the orthogonal data-possession ×
work-in-flight axes (TanStack/SWR), the labeled-and-bounded last-known-good rule,
the cross-product NEGATIVE evidence that no consumer product renders a condition
list to a non-developer, and the actor-not-tone rule plus enforcement mechanisms.
-->

## CLAIMS

### Condition lists are not summarizable — and are never shown to owners

<!-- The Kubernetes basis for this (polarity refusal, "not possible to compute a generic
     summary", reason-vs-render-surface split, kubectl's synthesized STATUS column) is
     documented in the api-contract-design companion entry. Only the consumer-product
     negative evidence is claimed here. -->

- Home Assistant's Repairs quality-scale rule gates owner-facing issues on actionability with no exceptions: "Repair issues and repair flows should be actionable and informative about the problem. Thus, we should not raise repair issues for just letting users know that something is wrong, which they can't fix themselves." The rule's exceptions section reads "There are no exceptions to this rule." The repair-issue schema's `data` field is documented as "Arbitrary data, not shown to the user." [ha-repair-issues]
- ZFS collapses pool health to three states — "online, degraded, or faulted" — and shows progress *alongside* state rather than replacing it: "If a scrub or resilver is in progress, this command reports the percentage done and the estimated time to completion." [zfs-zpool-status]
- Synology collapses storage health to Healthy/Warning/Critical and drills down only on the bad ones: "If the system is in Warning or Critical status, the storage pools with potential issues will be shown." [synology-storage-health]
- **[CORRECTED 2026-08-19 — THIS CLAIM WAS REFUTED. See `product-design/consumer-products-do-show-raw-condition-lists-to-owners-...md`.]** The original claim read: "no surveyed consumer or prosumer product exposes a list of named boolean conditions as its primary owner-facing surface; each shows one synthesized state plus, at most, one action." That is FALSE. Counterexamples verified from primary sources: **1Password Watchtower**, whose dashboard IS the condition list ("Any Watchtower category that has items in it will appear on your dashboard") for a consumer, non-developer audience; **Nextcloud**, which ships 71 named `SetupCheck` classes with a documented four-state per-check vocabulary (success/info/warning/error) on the normal admin "Security & setup warnings" panel — its `info` state ("cannot be guaranteed that the check passed") is exactly the `unknown` tier this entry assumed no product shows an owner; and **Bitwarden**'s Vault Health Reports, six named reports with no aggregate score. **Home Assistant itself, the product cited as the source of this rule, tells owners to "see the list of issues that need your attention" in Settings** — so the HA actionability rule constrains WHICH conditions may be shown, not how many, and not the list form. The narrower claim that DOES survive the survey: no surveyed product renders the *passing* conditions — every counterexample filters to non-passing rows. The rule is a filtering predicate, not a prohibition on lists. Kubernetes' synthesized `kubectl get` STATUS string remains correctly reported. [k8s-pod-lifecycle][ha-repair-issues][zfs-zpool-status][synology-storage-health]

### Data-possession and work-in-flight are two orthogonal axes

- TanStack Query splits `status` from `fetchStatus` under an explicit "Why two different states?" heading, with the rule of thumb: "The `status` gives information about the `data`: Do we have any or not?" and "The `fetchStatus` gives information about the `queryFn`: Is it running or not?" The stated cause is refresh semantics: "Background refetches and stale-while-revalidate logic make all combinations for `status` and `fetchStatus` possible." [tanstack-queries]
- TanStack documents the full cross-product as reachable, including "a query in `success` status will usually be in `idle` fetchStatus, but it could also be in `fetching` if a background refetch is happening" and "a query can be in `pending` state without actually fetching data." Every boolean is derived from the two enums: `isLoading` is "the same as `isFetching && isPending`", `isRefetching` is "the same as `isFetching && !isPending`". [tanstack-queries]
- TanStack splits error by whether data already exists: `isLoadingError` ("failed while fetching for the first time") vs `isRefetchError` ("failed while refetching"). [tanstack-queries]
- SWR added `isLoading` in v2 specifically because one flag conflated the two axes: "Previously, the `isValidating` state represents both the initial loading state and revalidating state so we had to check if both `data` and `error` are `undefined` to determine if it was the initial loading state." [swr-v2]
- SWR's resulting definitions are explicitly possession-aware: "`isValidating` becomes `true` whenever there is an ongoing request **whether the data is loaded or not**"; "`isLoading` becomes `true` when there is an ongoing request and **data is not loaded yet**." The prescribed UI mapping is skeleton vs spinner: use "`isValidating` for indicating everytime there is an ongoing revalidation, and `isLoading` for indicating that SWR is revalidating but there is no data yet to display." [swr-understanding]

### Last-known-good is legitimate, but must be labeled and time-bounded

- RFC 5861 separates two extensions by purpose: `stale-while-revalidate` "allows a cache to immediately return a stale response while it revalidates it in the background, thereby hiding latency (both in the network and on the server) from clients", while `stale-if-error` "allows a cache to return a stale response when an error... is encountered, rather than returning a \"hard\" error." [rfc-5861]
- RFC 5861 requires staleness to remain labeled and bounded: "Note that \"stale\" implies that the response will have a non-zero Age header and a warning header, as per HTTP's requirements", and "If delta-seconds passes without the cached entity being revalidated, it SHOULD NOT continue to be served stale, absent other information." [rfc-5861]
- TanStack's `placeholderData` overrides status to success but flags provenance: "our Query will not be in a `pending` state - it will start out as being in `success` state, because we have `data` to display - even if that data is just \"placeholder\" data. To distinguish it from \"real\" data, we will also have the `isPlaceholderData` flag set to `true`." [tanstack-placeholder]
- The problem placeholder data solves is named as status thrash: "The UI jumps in and out of the `success` and `pending` states because each new page is treated like a brand new query." TanStack's own example both dims the stale view and gates interaction on it (`disabled={isPlaceholderData || !data?.hasMore}`) while showing a separate in-flight indicator. [tanstack-paginated]
- Prometheus writes an explicit stale marker rather than inferring staleness from sample age: "If a target scrape or rule evaluation no longer returns a sample for a time series that was previously present, this time series will be marked as stale", and "If a query is evaluated at a sampling timestamp after a time series is marked as stale, then no value is returned for that time series." Series disappear at their latest collected sample rather than flatlining; the markers are "special samples... which are not exposed to users"; the 5-minute lookback is only the fallback when markers are missing (e.g. after a restart). [prometheus-staleness]
- A Prometheus core developer frames the mechanism as exactly the can't-tell-vs-broken distinction: "One of the advantages of pull-based monitoring is that you can tell when a scrape fails, as against some data not appearing for what could be a number of reasons." [robustperception-staleness]
- Grafana separates three concepts by cause: "No Data state occurs when the alert rule query runs successfully but returns no data points" vs "Error state occurs when the alert rule fails to evaluate its query or queries successfully." [grafana-nodata-error]
- Grafana adds Stale as a distinct fourth concept: "An alert instance is considered **stale** if the alert rule query returns data but its dimension (or series) has disappeared for a number of consecutive evaluation intervals (2 by default). This is different from the **No Data** state, which occurs when the alert rule query runs successfully but returns no dimensions (or series) at all." Grafana warns against unbounded hold-last-state: "in situations where strict monitoring is critical, relying solely on the \"Keep Last State\" option may not be appropriate." [grafana-stale-instances]
- Datadog's monitor status enum contains both `No Data` and `Unknown` as separate members (`Alert, Ignored, No Data, OK, Skipped, Unknown, Warn`); `Unknown` renders in No-Data grey while "the overall status of the monitor stays in `OK`." [datadog-monitor-openapi]
- Datadog's `on_missing_data` default differs by metric semantics: a missing count is treated as a real zero, while a missing gauge shows the last known status — the choice is made per data type, not globally. [datadog-on-missing-data]
- Nagios' `UNKNOWN` is a *checker* failure ("Invalid command line arguments... or low-level failures internal to the plugin"), not a staleness signal; freshness is a separate mechanism whose response is to force a re-check rather than change the displayed state. [nagios-plugin-return-codes]
- Home Assistant splits unavailable from unknown by whether any data arrived: "If we can't fetch data from a device or service, we should mark it as unavailable. We do this to reflect a better state, than just showing the last known state. If we can successfully fetch data but are temporarily missing a few pieces of data, we should mark the entity state as unknown instead." The *reason* goes to logs, not the UI, and is rate-limited: "the integration should log when this happens. Be sure to log only **once** in total to avoid spamming the logs." [ha-entity-unavailable][ha-log-when-unavailable]

### The owner/maintainer split is by ACTOR, not by tone

- Plaid documents `display_message` as "A user-friendly representation of the error code. `null` if the error is not related to user action." The nullability is semantic: the user-facing slot is empty precisely when the user is not the actor who can fix it. [plaid-errors]
- Plaid documents `error_message` as "A developer-friendly representation of the error code. This may change over time and is not safe for programmatic use", and marks `error_type`/`error_code` as "Safe for programmatic use." Plaid never uses the phrase "safe to show to end users", and provides no guidance on what to render when `display_message` is null. [plaid-errors]
- Plaid's flagship user-actionable error `ITEM_LOGIN_REQUIRED` ships `display_message: null`, with the developer text "the login details of this item have changed (credentials, MFA, or required user action) and a user login is required to update this information. use Link's update mode to restore the item to a good state" — so even the canonical re-auth case leaves the owner-facing copy to the consuming app. [plaid-item-errors]
- Google's AIP-193 codifies the same split at protocol level: "The `message` field is a developer-facing, human-readable \"debug message\" which **should** be in English", while "`google.rpc.LocalizedMessage` is used to provide an error message which **should** be localized to a user-specified locale where possible." It also mandates machine-readable identity ("All error responses **must** include an `ErrorInfo` within `details`") and forbids leaking internals ("error messages **must not** assume that the user will know anything about its underlying implementation"). `https://cloud.google.com/apis/design/errors` now 301-redirects to AIP-193. [aip-193]
- Foundation's `NSError.h` makes the boundary structural rather than advisory. `NSDebugDescriptionErrorKey` is documented as "NSString. This provides a string which will be shown when constructing the debugDescription of the NSError... This string will never be used in localizedDescription, so will not be shown to the user." The user-facing keys are separately specified: `NSLocalizedDescriptionKey` "a complete sentence (or more) describing ideally both what failed and why it failed"; `NSLocalizedFailureReasonErrorKey` "describing why the operation failed"; `NSLocalizedRecoverySuggestionErrorKey` "describing what the user can do to fix the problem." [nserror-header]
- Apple specifies the presentation hierarchy too: the description appears "in a larger, bold type face", the recovery suggestion "beneath the error description in a lighter type face", and `presentError:` deliberately omits the failure reason "because it is already included in the error description." Cocoa-domain errors "are always localized and ready to present to users." [apple-error-objects]
- Stripe scopes display permission per error class: `message` is "A human-readable message providing more details about the error. For card errors, these messages can be shown to your users." [stripe-api-errors]
- Stripe adds a third category beyond user/developer — text deliberately degraded because accuracy would be harmful. For `fraudulent`, `merchant_blacklist`, and `stolen_card`: "Don't report more detailed information to your customer. Instead, present it in the same manner as `generic_decline`"; for `lost_card`: "The specific reason for the decline shouldn't be reported to the customer." The decline docs ship two literal columns, "Seller message" and "API error message". [stripe-decline-codes]
- Stripe pushes localization to the consumer via the code, not the string: "The `description` is a non-localized plain language message, such as \"The image supplied isn't readable,\" that you can present to your account user. The `code` value is a string, such as `verification_document_not_readable`, that you can use to localize error messages for your account users." [stripe-api-verification]
- Twilio is the counterexample: `error_message` is "The description of the `error_code`" with no audience split, and Twilio explicitly warns "Users should not use the `error_code` and `error_message` fields programmatically" because values "subject to change as Twilio improves errors." A large, mature messaging API that never made the distinction. [twilio-message-resource][twilio-errors]

### Enforcement is type-level or lint-level; documentation alone is not enforcement

- The only *mechanical* enforcement found is type/field separation: AIP-193's distinct `LocalizedMessage` proto in `details` versus `Status.message`, and NSError's runtime guarantee that the debug key never reaches `localizedDescription`. [aip-193][nserror-header]
- i18n extraction is a real, documented leak gate: `eslint-plugin-i18next`'s `no-literal-string` rule states its purpose as "This rule aims to avoid developers to display literal string directly to users without translating them" — because every user-visible string must pass through `t()`, a raw developer string in a render path fails lint. [eslint-i18next-no-literal-string]
- GOV.UK's error-message guidance bans developer vocabulary by example rather than by mechanism: avoid "technical jargon like 'form post error', 'unspecified error' and 'error 0x0000000643'"; avoid "'forbidden', 'illegal', 'you forgot' and 'prohibited'"; reject vague errors like "'An error occurred'"; and positively, "Describe what has happened and tell them how to fix it. The message must be in plain English, use positive language and get to the point." The page mandates no review process. [govuk-error-message]

### Incompleteness is a named state; waiting states assert no-action and are structurally checkable

- Plaid models "not broken, not complete" as a first-class enum on the data endpoint rather than as an error: `/transactions/sync` returns `transactions_update_status` with `NOT_READY` ("The Item is pending transaction pull"), `INITIAL_UPDATE_COMPLETE` ("Initial pull for the Item is complete, historical pull is pending"), and `HISTORICAL_UPDATE_COMPLETE` ("Both initial and historical pull for Item are complete"). [plaid-transactions]
- Plaid's Item `status` object carries only completed-outcome timestamps — `last_successful_update` and `last_failed_update` — with no in-progress field, so "data is currently arriving" is not derivable from Item status and must come from the sync endpoint or webhooks. [plaid-items]
- Stripe's wait state asserts no-action and is machine-checkable against that claim: `requirements.pending_verification` means "Stripe is currently verifying information on the connected account. No action is required." while `currently_due` is empty — the prose claim is backed by structure, not just wording. [stripe-api-verification]
- Stripe gives a range plus its cause of variance rather than a fake ETA: "Stripe can take anywhere from a few minutes to a few business days to verify an image, depending on its readability." [stripe-api-verification]
- Google Takeout combines a wide honest bound, a typical case, and a promise to notify: "Depending on the amount of information in your account, this process could take from a few minutes to a few days"; "Most people get the link to their archive the same day that they request it"; "we'll email you a link to its location." [google-takeout]
- No primary source was found mandating that a wait state must carry a time expectation; Stripe and Google both supply one, but the practice is a well-supported convention rather than a documented requirement. [stripe-api-verification][google-takeout]

### Diagnostics: short human summary inline, machine blob exported, redacted by default

- RFC 9457 separates advisory prose from machine-parseable extensions: "The 'detail' string, if present, ought to focus on helping the client correct the problem, rather than giving debugging information", and "Consumers SHOULD NOT parse the 'detail' member for information; extensions are more suitable and less error-prone ways to obtain such information." `title` is "advisory and is included only for users who are unaware of and cannot discover the semantics of the type URI"; `instance` is a handle "useful for support or forensic purposes". §5 discourages exposing stack dumps through the HTTP interface. (The "ought to" phrasing is 9457's; the older RFC 7807 used SHOULD.) [rfc-9457]
- Chrome's net-export redacts by default, with opt-in escalation: "If you don't change the level of log detail, private information is stripped." Chromium warns of the escalated modes that "Captures with this level of detail may include personal information and should generally be emailed rather than posted on public forums or public bugs", and instructs "Provide the entire log file. Snippets are rarely sufficient to diagnose problems." [chrome-net-export][chromium-net-export]
- Home Assistant's diagnostics platform states "It is critical to ensure that no sensitive data is exposed" and ships an `async_redact_data` helper. [ha-diagnostics]
- Apple's sysdiagnose is framed with an explicit maintainer audience: "Your IT team or AppleCare can then read the file to understand software or network issues." No Apple page documenting a redaction stance was found (per-platform PDFs are auth-gated). [apple-sysdiagnose]

## SOURCES

**k8s-pod-lifecycle**
URL: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/
Accessed: 2026-08-19
Quote: "Make sure not to confuse _Status_, a kubectl display field for user intuition, with the pod's `phase`."
Note: the fuller Kubernetes condition-schema claims live in the api-contract-design companion entry.

**rfc-5861**
URL: https://www.rfc-editor.org/rfc/rfc5861.txt
Accessed: 2026-08-19
Quote: "allows a cache to immediately return a stale response while it revalidates it in the background, thereby hiding latency (both in the network and on the server) from clients" / "If delta-seconds passes without the cached entity being revalidated, it SHOULD NOT continue to be served stale, absent other information."

**tanstack-queries**
URL: https://tanstack.com/query/latest/docs/framework/react/guides/queries
Accessed: 2026-08-19
Quote: "The `status` gives information about the `data`: Do we have any or not?" / "The `fetchStatus` gives information about the `queryFn`: Is it running or not?" / "Background refetches and stale-while-revalidate logic make all combinations for `status` and `fetchStatus` possible."

**tanstack-placeholder**
URL: https://tanstack.com/query/latest/docs/framework/react/guides/placeholder-query-data
Accessed: 2026-08-19
Quote: "To distinguish it from \"real\" data, we will also have the `isPlaceholderData` flag set to `true` on the Query result."

**tanstack-paginated**
URL: https://tanstack.com/query/latest/docs/framework/react/guides/paginated-queries
Accessed: 2026-08-19
Quote: "The UI jumps in and out of the `success` and `pending` states because each new page is treated like a brand new query."

**swr-v2**
URL: https://swr.vercel.app/blog/swr-v2
Accessed: 2026-08-19
Quote: "Previously, the `isValidating` state represents both the initial loading state and revalidating state so we had to check if both `data` and `error` are `undefined` to determine if it was the initial loading state."

**swr-understanding**
URL: https://swr.vercel.app/docs/advanced/understanding
Accessed: 2026-08-19
Quote: "`isValidating` becomes `true` whenever there is an ongoing request whether the data is loaded or not" / "`isLoading` becomes `true` when there is an ongoing request and data is not loaded yet."

**prometheus-staleness**
URL: https://prometheus.io/docs/prometheus/latest/querying/basics/#staleness
Accessed: 2026-08-19
Quote: "If a target scrape or rule evaluation no longer returns a sample for a time series that was previously present, this time series will be marked as stale."

**robustperception-staleness**
URL: https://www.robustperception.io/staleness-and-promql/
Accessed: 2026-08-19
Quote: "One of the advantages of pull-based monitoring is that you can tell when a scrape fails, as against some data not appearing for what could be a number of reasons."

**grafana-nodata-error**
URL: https://grafana.com/docs/grafana/latest/alerting/fundamentals/alert-rules/state-and-health/nodata-and-error-states/
Accessed: 2026-08-19
Quote: "No Data state occurs when the alert rule query runs successfully but returns no data points." / "Error state occurs when the alert rule fails to evaluate its query or queries successfully."
Note: the older `.../state-and-health/` URL 301-redirects here.

**grafana-stale-instances**
URL: https://grafana.com/docs/grafana/latest/alerting/fundamentals/alert-rules/stale-alert-instances/
Accessed: 2026-08-19
Quote: "This is different from the **No Data** state, which occurs when the alert rule query runs successfully but returns no dimensions (or series) at all."

**datadog-monitor-openapi**
URL: https://docs.datadoghq.com/api/latest/monitors/
Accessed: 2026-08-19
Quote: monitor overall_state enum `Alert, Ignored, No Data, OK, Skipped, Unknown, Warn`

**datadog-on-missing-data**
URL: https://docs.datadoghq.com/monitors/configuration/
Accessed: 2026-08-19
Quote: `on_missing_data` — missing count evaluated as zero; missing gauge shows last known status

**nagios-plugin-return-codes**
URL: https://nagios-plugins.org/doc/guidelines.html
Accessed: 2026-08-19
Quote: "Invalid command line arguments were supplied to the plugin or low-level failures internal to the plugin"

**ha-repair-issues**
URL: https://developers.home-assistant.io/docs/core/integration-quality-scale/rules/repair-issues
Accessed: 2026-08-19
Quote: "we should not raise repair issues for just letting users know that something is wrong, which they can't fix themselves." / "There are no exceptions to this rule." / `data`: "Arbitrary data, not shown to the user."

**ha-entity-unavailable**
URL: https://developers.home-assistant.io/docs/core/integration-quality-scale/rules/entity-unavailable
Accessed: 2026-08-19
Quote: "If we can't fetch data from a device or service, we should mark it as unavailable... If we can successfully fetch data but are temporarily missing a few pieces of data, we should mark the entity state as unknown instead."

**ha-log-when-unavailable**
URL: https://developers.home-assistant.io/docs/core/integration-quality-scale/rules/log-when-unavailable
Accessed: 2026-08-19
Quote: "Be sure to log only once in total to avoid spamming the logs."

**ha-diagnostics**
URL: https://developers.home-assistant.io/docs/core/platform/diagnostics
Accessed: 2026-08-19
Quote: "It is critical to ensure that no sensitive data is exposed"

**zfs-zpool-status**
URL: https://openzfs.github.io/openzfs-docs/man/master/8/zpool-status.8.html
Accessed: 2026-08-19
Quote: "If a scrub or resilver is in progress, this command reports the percentage done and the estimated time to completion."

**synology-storage-health**
URL: https://kb.synology.com/en-global/DSM/help/DSM/StorageManager/storage_pool_overview
Accessed: 2026-08-19
Quote: "If the system is in Warning or Critical status, the storage pools with potential issues will be shown."

**plaid-errors**
URL: https://plaid.com/docs/errors/
Accessed: 2026-08-19
Quote: "`display_message`: A user-friendly representation of the error code. `null` if the error is not related to user action." / "`error_message`: A developer-friendly representation of the error code. This may change over time and is not safe for programmatic use."

**plaid-item-errors**
URL: https://plaid.com/docs/errors/item/
Accessed: 2026-08-19
Quote: ITEM_LOGIN_REQUIRED ships `display_message: null`

**plaid-transactions**
URL: https://plaid.com/docs/api/products/transactions/
Accessed: 2026-08-19
Quote: "`NOT_READY`: The Item is pending transaction pull" / "`INITIAL_UPDATE_COMPLETE`: Initial pull for the Item is complete, historical pull is pending"

**plaid-items**
URL: https://plaid.com/docs/api/items/
Accessed: 2026-08-19
Quote: "ISO 8601 timestamp of the last successful transactions update for the Item"

**aip-193**
URL: https://google.aip.dev/193
Accessed: 2026-08-19
Quote: "The `message` field is a developer-facing, human-readable \"debug message\" which should be in English." / "`google.rpc.LocalizedMessage` is used to provide an error message which should be localized to a user-specified locale where possible." / "error messages must not assume that the user will know anything about its underlying implementation."

**nserror-header**
URL: https://raw.githubusercontent.com/xybp888/iOS-SDKs/master/iPhoneOS13.0.sdk/System/Library/Frameworks/Foundation.framework/Headers/NSError.h
Accessed: 2026-08-19
Quote: "This string will never be used in localizedDescription, so will not be shown to the user."
Note: used because developer.apple.com documentation pages are JS-rendered and returned title-only.

**apple-error-objects**
URL: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ErrorHandlingCocoa/ErrorObjectsDomains/ErrorObjectsDomains.html
Accessed: 2026-08-19
Quote: "Methods such as `presentError:` do not automatically display the failure reason because it is already included in the error description."

**stripe-api-errors**
URL: https://docs.stripe.com/api/errors
Accessed: 2026-08-19
Quote: "A human-readable message providing more details about the error. For card errors, these messages can be shown to your users."

**stripe-decline-codes**
URL: https://docs.stripe.com/declines/codes
Accessed: 2026-08-19
Quote: "Don't report more detailed information to your customer. Instead, present it in the same manner as `generic_decline`"

**stripe-api-verification**
URL: https://docs.stripe.com/connect/handling-api-verification
Accessed: 2026-08-19
Quote: "Stripe is currently verifying information on the connected account. No action is required." / "The `description` is a non-localized plain language message... The `code` value is a string... that you can use to localize error messages for your account users."

**twilio-message-resource**
URL: https://www.twilio.com/docs/messaging/api/message-resource
Accessed: 2026-08-19
Quote: "Users should not use the `error_code` and `error_message` fields programmatically."

**twilio-errors**
URL: https://www.twilio.com/docs/api/errors
Accessed: 2026-08-19
Note: code + short-description dictionary with no audience metadata.

**eslint-i18next-no-literal-string**
URL: https://github.com/edvardchen/eslint-plugin-i18next/blob/main/docs/rules/no-literal-string.md
Accessed: 2026-08-19
Quote: "This rule aims to avoid developers to display literal string directly to users without translating them."

**govuk-error-message**
URL: https://design-system.service.gov.uk/components/error-message/
Accessed: 2026-08-19
Quote: "technical jargon like 'form post error', 'unspecified error' and 'error 0x0000000643'" / "Describe what has happened and tell them how to fix it."

**rfc-9457**
URL: https://www.rfc-editor.org/rfc/rfc9457.html
Accessed: 2026-08-19
Quote: "The 'detail' string, if present, ought to focus on helping the client correct the problem, rather than giving debugging information." / "Consumers SHOULD NOT parse the 'detail' member for information"

**chrome-net-export**
URL: https://support.google.com/chrome/a/answer/64481
Accessed: 2026-08-19
Quote: "If you don't change the level of log detail, private information is stripped."

**chromium-net-export**
URL: https://www.chromium.org/for-testers/providing-network-details/
Accessed: 2026-08-19
Quote: "Captures with this level of detail may include personal information and should generally be emailed rather than posted on public forums or public bugs." / "Provide the entire log file. Snippets are rarely sufficient to diagnose problems."

**apple-sysdiagnose**
URL: https://support.apple.com/guide/deployment/collect-diagnostics-dep8b4d3d/web
Accessed: 2026-08-19
Quote: "Your IT team or AppleCare can then read the file to understand software or network issues."

**google-takeout**
URL: https://support.google.com/accounts/answer/3024190
Accessed: 2026-08-19
Quote: "Depending on the amount of information in your account, this process could take from a few minutes to a few days." / "Most people get the link to their archive the same day that they request it."

## SYNTHESIS

> **[PERSONA NOTE 2026-08-19.]** The product owner has stated PDPP is a **consumer** product. (The technical-operator reading argued in the red-team companion entry is void; its cited evidence was a directory name, not an audience statement, and the repo contains no written audience statement at all.) This entry's recommendations are persona-NEUTRAL in derivation — they come from TanStack/SWR/RFC-5861/Plaid/Stripe source readings, not from an assumption about who PDPP's user is — so none of them flip. Two are *strengthened* by the consumer requirement: the GOV.UK plain-English rule against developer jargon, and the actor-not-tone split (a consumer is even less able to act on a maintainer string than an operator would be). The one claim that WAS refuted, and independently of persona, is the "no consumer product shows a condition list" negative survey — corrected below and in CLAIMS.

Three findings do the real work here, and ~~all three cut against~~ **two of the three cut against** the "show the owner the conditions" instinct — finding 2 was refuted and now cuts the other way.

**1. Data-possession and work-in-flight are orthogonal, and collapsing them is a known, twice-corrected bug.** TanStack Query designed the split in from the start (`status` = do we have data, `fetchStatus` = is the query function running) and says plainly that stale-while-revalidate makes the whole cross-product reachable. SWR shipped the collapsed version first, discovered `isValidating` was ambiguous in practice, and added `isLoading` in v2 to fix it. Two independent libraries, one converged answer: you need two axes because "we're refreshing" and "we have nothing" are different facts, and a refresh is exactly the case that forces them apart. Any status model with a single enum will produce a wrong answer during a refresh. The corollary for display is that a stale-but-present value beats a blank: RFC 5861 serves stale while revalidating, TanStack shows placeholder data in `success` status with an `isPlaceholderData` provenance flag, Datadog holds last-known-good for gauges. But nobody holds it silently or forever — 5861 mandates an Age and Warning header plus an expiry, Grafana defaults to two intervals and warns against relying on hold-last-state in strict-monitoring settings, TanStack dims the view and gates interaction. Last-known-good is legitimate *labeled and bounded*, never asserted.

**2. ~~Nobody shows a condition list to a non-developer — the negative evidence is uniform.~~ REFUTED 2026-08-19; corrected below.** The original conclusion here was that the negative evidence is uniform and the universal shape is "one synthesized state, at most one action." A dedicated adversarial search (which this survey did not run — it searched for confirmation, not for a counterexample) broke it on the first try. 1Password Watchtower's dashboard IS a list of named categories, shown to consumers. Nextcloud ships 71 named setup checks with a four-state per-check vocabulary on the standard admin panel. Bitwarden ships six named reports with no rollup at all. And Home Assistant — cited here as the strongest source of the rule — directs owners to "see the list of issues that need your attention." See `product-design/consumer-products-do-show-raw-condition-lists-to-owners-...md` for the primary-source citations.

What remains true, and is the finding worth keeping: the Kubernetes *why* is untouched (polarity is deliberately unstandardized, so "it is not possible to compute a generic summary"), Kubernetes really does route conditions to `kubectl describe` and synthesize a display string for `kubectl get`, and HA really does gate owner-facing Repairs on actionability with a no-exceptions clause. The corrected product rule is a **filter, not a prohibition**: every counterexample renders only the *non-passing* rows. Nobody shows an owner ten green rows to find the one red one. Detail-behind-an-export, redacted by default, also survives intact (Chrome net-export strips private information unless you opt in, and warns you to email rather than post the escalated version).

**3. The owner/maintainer message split is by ACTOR, not by tone.** This is the most transferable and most commonly misread finding. Plaid's `display_message` is null "if the error is not related to user action" — the user-facing slot is *empty* precisely when the user cannot act, and Plaid ships null even for `ITEM_LOGIN_REQUIRED`, its flagship re-auth error. The design question is therefore never "how do I phrase this gently for the owner"; it is "is the owner the actor?" If not, emit no owner string rather than a softened developer string. Stripe adds a third bucket beyond user/developer: text deliberately *degraded* because accuracy would be harmful (`fraudulent`/`stolen_card` must be presented as `generic_decline`), and ships its decline docs with two literal audience columns. Stripe's wait state is the model for the honest-answer-is-wait case, because it is structurally checkable rather than merely worded: `pending_verification` says "No action is required" *and* `currently_due` is empty, so the prose claim is backed by the data shape. Where a time expectation exists, the good pattern is a wide honest bound plus its cause of variance plus a typical case plus a promise to notify (Google Takeout's "few minutes to a few days" / "depending on the amount of information" / "most people... same day" / "we'll email you"); no primary source *mandates* a time expectation, so treat it as strong convention.

On enforcement, documentation is not enforcement. Only two mechanisms actually prevent leakage: type-level separation (AIP-193's separate `LocalizedMessage` proto; NSError's runtime guarantee that `NSDebugDescriptionErrorKey` "will never be used in localizedDescription") and lint-level gating (`eslint-plugin-i18next`'s `no-literal-string`, whose stated purpose is exactly "avoid developers to display literal string directly to users without translating them" — every user-visible string must route through `t()`, so a raw developer string in a render path fails CI). GOV.UK bans jargon by example but mandates no review process. Twilio is the cautionary counterexample: a large, mature API with one message field, no audience split, and an explicit warning that its own values are unstable.

Two gaps worth naming. Nobody documents the *fallback* — Plaid tells you `display_message` will be null and offers zero guidance on what to render instead, so that copy and the rule that a null owner-message must never fall back to the developer string are yours to specify. And the "in flight" case has a shape prior art supplies but rarely names: Plaid models incompleteness as a first-class enum on the data endpoint (`NOT_READY` / `INITIAL_UPDATE_COMPLETE` / `HISTORICAL_UPDATE_COMPLETE`), not as an error and not as silence — and Kubernetes' matching rule (a long transition "should not be transient" and should itself be signalled as a condition) is documented in the companion entry. Not-broken-and-not-done is a positive state that deserves a name.
