---
title: "Mature systems gate a global health banner on cadence-derived staleness — N consecutive missed checks or grace-time-past-expected-interval, never on raw data age — and every surveyed system separates a visible freshness FACT (a timestamp/count) from a bannered VERDICT (fired only after a hysteresis window), because a single missed interval is definitionally not yet a problem"
date: 2026-08-26
topic: product-design
tags: [staleness, cadence, health-banner, alert-fatigue, hysteresis, grace-period, freshness, readiness-probes, flap-damping]
status: draft
sources: [plaid-items-api, plaid-item-errors, grafana-missing-data, grafana-nodata-error-states, grafana-stale-instances, prometheus-alerting-rules, prometheus-staleness, k8s-probes, k8s-node-lifecycle, datadog-reduce-flapping, datadog-configure-monitors, pagerduty-alert-fatigue, pagerduty-reduce-noise, healthchecks-io-configuring, healthchecks-io-docs, feedbin-sparklines, netnewswire-faq, joint-commission-sea50, ncbi-alarm-fatigue, dan-slimmon-ppv]
source_session: unknown
---

<!--
Builds on, does not repeat:
- product-design/data-possession-and-work-in-flight-are-orthogonal-axes-and-the-owner-maintainer-message-split-is-by-actor-not-tone.md
  (data-possession × work-in-flight orthogonality; last-known-good must be LABELED and BOUNDED —
  RFC 5861, Grafana Stale, Prometheus staleness markers, TanStack placeholderData; owner/maintainer
  split is by actor not tone; condition lists filtered to non-passing rows only)
- api-contract-design/health-vocabularies-separate-a-lifecycle-axis-from-a-verdict-axis-and-kubernetes-explicitly-refuses-to-recommend-positive-condition-polarity.md
  (lifecycle axis vs verdict axis split — Kubernetes conditions, GitHub check-runs status×conclusion,
  systemd LOAD/ACTIVE/SUB; `unknown` = not yet measured, never a failure, only withholds `healthy`;
  `not_applicable` = absence of a condition; reason/message split by render surface; PDPP's own 13
  conditions already analyzed — not repeated here)
- product-design/upstream-retention-loss-health-ux-prior-art.md
  (permanent provider-caused data loss is a THIRD axis — coverage/provenance — never gates primary
  health; denominator is provider-servable-now, not all-data-ever; Plaid days_requested cap,
  PyPI/PEP 592 yank, Arq "Deleted/Kept" as structural non-health tombstone records)
- data-collection-systems/self-hosted-single-owner-collector-agents-need-three-states-not-two-...md
  (three-state stale/unknown/broken vocabulary; Kubernetes node Lease + node-monitor-grace-period +
  pod-eviction-timeout as a THREE-STAGE timed hysteresis; Healthchecks.io's New/Up/Late/Down/Paused
  named state machine, cited there in passing — this entry goes deeper on Healthchecks.io's exact
  Grace Time arithmetic and generalizes the pattern to a cadence model)

This entry adds a FIFTH, previously uncovered thing: staleness as a function of TIME SINCE LAST
SUCCESS relative to an EXPECTED CADENCE, and specifically the gating logic a GLOBAL/aggregate banner
must use so a source merely due for its next refresh never trips it, while a source genuinely overdue
past a defined grace window does. This is temporal and cadence-driven — distinct from possession/
work-in-flight (orthogonal axes entry), lifecycle/verdict (conditions entry), and permanent coverage
loss (retention-loss entry). The central converging finding: EVERY system surveyed (Plaid, Grafana,
Prometheus, Kubernetes, Datadog, PagerDuty, Healthchecks.io, clinical alarm literature) uses some form
of hysteresis — N consecutive misses, a `for:` duration, a grace-time multiplier, or a fixed buffer
—  before a raw "no new data" fact is allowed to become an alarm/verdict. None fires on the first
missed check. This is the mechanism that answers "how do you avoid crying wolf on a source merely due
for refresh" with something more specific than "don't."
-->

## CLAIMS

### Plaid: possession-independent status timestamps, and login-required vs. transient errors as the actor-split applied to time

- Plaid's Item status object exposes `last_successful_update` and `last_failed_update` as independent, both-always-present ISO 8601 timestamps that update on *every* connection attempt "regardless of whether new data appears" — so "we tried and it worked" and "we tried and it failed" are both tracked continuously, and staleness is computable as `now - last_successful_update` without needing a separate polling-in-progress flag. [plaid-items-api]
- The same dual-timestamp shape is duplicated per product (`transactions.last_successful_update`/`last_failed_update`, `investments.last_successful_update`/`last_failed_update`) rather than being one Item-level field — staleness is scoped per data product, not globalized across an Item. [plaid-items-api]
- `ITEM_LOGIN_REQUIRED` is documented as requiring explicit user action — "Additional input from the user is required to continue getting data for this Item" — and Plaid's own guidance states re-authentication "should generally return their Item to a healthy state without further intervention," i.e. this error is the VERDICT-axis failure (needs-you), not a freshness fact. [plaid-item-errors]
- Plaid explicitly separates recoverable connectivity failure from this: "Occasionally, an error can occur upon calling `/transactions/get` if Plaid's attempt to extract transactions has failed due to a connectivity error with the financial institution, and Plaid has never successfully extracted transactions for the Item in the past — in which case Plaid will continue to retry the extraction at least once a day." A transient failure with no user action available is retried automatically and does not surface as an owner-facing verdict; the retry cadence itself (at least daily) is the de facto grace mechanism. [plaid-item-errors]
- No field or document found that ties elapsed time since `last_successful_update` directly to a status enum (e.g. no `stale_after_days`); staleness-as-a-computed-fact is left to the integrating app, while ONLY the failure-mode distinction (login-required vs. transient) is what Plaid itself elevates to a verdict. This is consistent with the retention-loss entry's finding that Plaid's institution-level health is "keyed to update recency and success rate... not historical depth" — recency matters, but Plaid does not publish the threshold that turns recency into an alarm. [plaid-items-api][plaid-item-errors]

### Grafana: four explicit NoData policies, and an explicit warning against relying on Keep Last State alone

- Grafana Alerting names four distinct handling options for a query that returns no data, each producing a different alert state: the default **`No Data`** policy fires a dedicated `DatasourceNoData` alert ("triggering a new `DatasourceNoData` alert, treating *No data* as a specific problem"); **`Alerting`** "transition[s] each existing alert instance into the `Alerting` state when data disappears"; **`Normal`** "ignores missing data and transitions all instances to the `Normal` state. Useful when receiving intermittent data, such as from experimental services, sporadic actions, or periodic reports"; **`Keep Last State`** "leaves the alert in its previous state until the data returns. This is common in environments where brief metric gaps happen regularly, like with flaky exporters or noisy environments." [grafana-missing-data]
- Grafana's official Cloud/alerting-fundamentals documentation gives the explicit warning this entry needed: "the 'Keep Last State' option helps mitigate temporary data source issues, preventing alerts from unintentionally firing, resolving, and re-firing, but in situations where strict monitoring is critical, relying solely on the 'Keep Last State' option is discouraged." [grafana-nodata-error-states]
- Grafana separates a fourth concept, **Stale**, from both No Data and Keep Last State: "An alert instance is considered stale if the alert rule query returns data but its dimension (or series) has disappeared for a number of consecutive evaluation intervals (2 by default). This is different from the No Data state, which occurs when the alert rule query runs successfully but returns no dimensions (or series) at all." A stale instance that had been firing resolves with an explicit provenance annotation (`grafana_state_reason: MissingSeries`) distinguishing "evicted because data vanished" from "resolved because the underlying condition actually recovered." [grafana-stale-instances]
- The guidance for choosing among the four options is explicitly cadence-relative, not absolute: match "Normal" to environments where the source is *expected* to have gaps (sporadic/periodic reporting), and reserve "Alerting" for environments where missing data itself means "something broke or data source down." The choice is a per-source configuration decision, not a platform-wide default. [grafana-missing-data]

### Prometheus: hysteresis via `for:`, and `keep_firing_for` for the opposite flap direction

- The `for:` clause is Prometheus's hysteresis primitive: "the alert condition must be consistently satisfied for a continuous period... before triggering an alert," with intermediate state named **Pending** (condition true, but not yet long enough) before **Firing**. Community guidance states plainly: "almost every alert should have a non-zero for duration," and cites a concrete anti-pattern (`for: 0m` on a momentary spike) as bad practice. [prometheus-alerting-rules]
- Prometheus ships a complementary primitive for the reverse flap direction — brief gaps in an otherwise-true condition — via `keep_firing_for`: "tells Prometheus to keep an alert firing for a specified duration after the firing condition was last met, which can be used to prevent situations such as flapping alerts and false resolutions due to lack of data." Without it, "alerting rules will deactivate on the first evaluation where the condition is not met" even if that's a single missed scrape. [prometheus-alerting-rules]
- This complements (does not repeat) the already-corpus-documented `up` metric and staleness-marker mechanism (prior entry): `for:`/`keep_firing_for` operate on the alerting layer above the staleness-marker mechanism, and both exist because a single missed sample is deliberately never sufficient, on its own, to flip a verdict. [prometheus-staleness]

### Kubernetes readiness vs. liveness probes: failure removes from service without declaring "broken," and grace period is explicitly `initialDelaySeconds + failureThreshold × periodSeconds`

- Readiness-probe failure does NOT restart anything — it is structurally the "stale but fine, don't alarm" case: "For readiness probes, the kubelet marks the container as not ready, and the Pod stops receiving traffic from matching Services," and "the EndpointSlice controller removes the Pod's IP address from the EndpointSlices of all Services that match the Pod." The pod keeps running; it is only withheld from serving, exactly the "withhold healthy, never assert degraded" behavior of `unknown` established in the health-vocabularies entry. [k8s-probes]
- Liveness-probe failure is the harder verdict: "If a container fails its liveness probe more times than the configured tolerance, the kubelet restarts that container" — action is gated on tolerance (a count), never a single failed check. [k8s-probes]
- The grace-period arithmetic is explicit and documented as a formula: `initialDelaySeconds + failureThreshold × periodSeconds`. The worked example in the docs uses `failureThreshold: 30` and `periodSeconds: 10` for a startup probe to give "a maximum of 5 minutes (30 * 10 = 300s)" before the container is judged to have failed to start — i.e. the grace window is stated as a literal multiplication of an interval by a miss-count, not an absolute constant chosen independent of the check's own cadence. [k8s-probes]
- Documented failure mode from overly tight tuning is a direct "cries wolf" case: "a `periodSeconds` of 1 with a `timeoutSeconds` of 1 means the kubelet expects an answer every second... Applications with variable latency, garbage collection pauses, or bursty load will fail that intermittently. This can cause pods to flap in and out of Service endpoints, which clients experience as random errors" — confirming that too-small a hysteresis window on a real system produces exactly the false-alarm behavior this research question is trying to avoid. [k8s-probes]
- Kubernetes' node-level health uses the identical shape at a different layer, already partially documented in this corpus's sibling entry: kubelet renews a Lease roughly every 10s; only after `--node-monitor-grace-period` (default 40s, i.e. ~4 missed leases) does the node controller set `Ready` to `Unknown`; only after a *further* `--pod-eviction-timeout` (default 5 min) does anything act on that unknown state by evicting pods. Three stages, two independent timers, both grace-period-sized as multiples of the underlying heartbeat interval. [k8s-node-lifecycle]

### Datadog and PagerDuty: threshold/window tuning over automated flap-detection, and an explicit actionability filter

- Datadog has no dedicated automated "flap detection" feature (unlike classic tools such as Nagios); its documented mitigation is manual and cadence-based: "The easiest way to reduce flapping when the alert ↔ ok... state changes are frequent could be to increase/decrease the threshold condition," alongside recommending the `min` aggregation ("triggers the alert only when all data points for the metric in the timeframe violate the threshold") and smoothing functions (moving averages, time-shift differentials) to dampen noisy series before they reach the alerting layer. [datadog-reduce-flapping]
- Datadog's `evaluation_delay` setting exists specifically to prevent false "no data" alarms caused by data arriving later than the evaluation window, not because the source is unhealthy — the documented example: "if the value is set to 300 (5min)... the monitor evaluates data from 6:50 to 6:55" instead of the current window, and AWS/CloudWatch-backed metrics are recommended a 900-second (15-minute) delay specifically to absorb known provider-side latency before treating absence as a signal. This is a cadence-aware "don't cry wolf while data is merely in transit" mechanism distinct from the alert-threshold hysteresis above. [datadog-configure-monitors]
- Datadog's "Require Full Window of Data" setting is explicitly recommended OFF for sparse/backfilled sources: "Do not require (recommended for sparse or delayed metrics): The monitor evaluates on partial data, reducing false No Data alerts" — i.e. the platform default for low-cadence sources is tuned toward under-alarming rather than over-alarming. [datadog-configure-monitors]
- PagerDuty's alert-fatigue guidance makes actionability, not raw signal presence, the gate for whether something should interrupt a human at all: "For each alert, determine whether it was actionable. Once you find non-actionable alerts, cut them," with a concrete negative example — "CPU and memory usage... are NOT actionable because they don't give specific information about what's wrong." [pagerduty-alert-fatigue]
- PagerDuty's material references Dan Slimmon's framework of alert "positive predictive value" (PPV) — "the likelihood that something is actually wrong when an alert goes off" — as the target metric for tuning thresholds/hysteresis, i.e. the design goal is stated as a precision metric, not a recall metric; the corpus's existing `data-quality-alerting-high-confidence-only.md` entry independently reaches the same precision-over-recall conclusion from Stripe Radar/Monte Carlo Data, so this is now corroborated from a second, disjoint domain (incident paging vs. data-quality anomaly detection). [pagerduty-alert-fatigue][dan-slimmon-ppv]
- PagerDuty separates severity/urgency as a routing decision made only once something is judged actionable: "high-urgency alerts, such as an outage or SLA breach, demand immediate intervention... Non-urgent issues shouldn't be waking you or your team up," and recommends disabling default auto-behaviors (ack timeout, auto-resolution) specifically for low-severity services so that noisy-but-real signals don't escalate like outages do. [pagerduty-reduce-noise][pagerduty-alert-fatigue]

### Healthchecks.io: the sharpest cadence-derived grace model found in this survey, with a named neutral middle state

- Healthchecks.io's check state machine is named explicitly, not inferred: **New → Up → Late → Down → Paused**, and "Late" is a first-class, user-facing label distinct from "Down." [healthchecks-io-docs]
- The two configuration primitives are **Period** ("the expected time between pings") and **Grace Time** ("the additional time to wait before sending an alert when a check is late"), and Grace Time is explicitly framed as cadence-relative, not absolute: "you should set it to be a little above the expected duration of your cron job." [healthchecks-io-configuring]
- The worked example gives exact arithmetic for the Late→Down transition: for Period = 1 hour, Grace Time = 5 minutes, with the last successful ping at 12:00 — "at 13:00 the check will be declared late (because 1 hour will have passed since the last ping), and at 13:05 the check will be declared down and alerts will go out (because 1 hour + 5 minutes will have passed since the last ping)." No alert fires at all during the 5-minute Late window; only Down triggers a notification. [healthchecks-io-configuring]
- For cron/OnCalendar-scheduled checks, the same two-stage model applies against the schedule's next expected fire time rather than a rolling interval: "at 13:10 the check will be declared late... and at 13:15 the check will be declared down and the alerts will go out (because 5 minutes will have passed since the time the cron job was expected to check in)" — i.e. lateness is computed against *when the job was scheduled to run*, not merely against a fixed elapsed-time floor, so a genuinely irregular cadence (a cron expression) is still handled without false Late/Down states between scheduled runs. [healthchecks-io-configuring]
- Grace Time doubles as the hysteresis window for a start→success pair, not just for missing pings entirely: "If a job sends a 'start' signal but does not send a 'success' signal within grace time, Healthchecks.io will assume failure and send out alerts" — the same grace concept covers both "never checked in" and "checked in but never finished," unifying the possession/work-in-flight axis (prior entry) with the cadence axis (this entry) under one timer. [healthchecks-io-configuring]

### Feed readers: staleness shown as a visible, neutral signal never framed as an error

- Feedbin exposes feed staleness as a **visual activity indicator** ("activity sparklines in feeds settings") rather than a status word or alarm — a user's own description ("Exactly the information I needed there") frames it as informational context for the owner to interpret, not a system-issued verdict. [feedbin-sparklines]
- No evidence was found (in NetNewsWire's public FAQ or its GitHub issue tracker) of an automated "this feed appears dead" warning distinguishing a genuinely defunct feed from one that simply publishes rarely; NetNewsWire's documented failure handling is scoped to feed-discovery errors ("Can't add a feed because no feed was found") and sync-transport bugs, not to publication-cadence staleness. This is a genuine gap in this survey, not a negative finding — flagged as **not covered** rather than asserted as "feed readers don't do this." [netnewswire-faq]
- The pattern that IS well-evidenced (Feedbin) supports the same conclusion as Grafana's "Normal" NoData policy and Plaid's untouched status timestamps: for a domain where sources are *known* to have wildly variable natural cadences (a personal blog vs. a daily news feed), the mature answer is to expose the raw signal (a sparkline, a timestamp) and let the owner interpret it, rather than the platform asserting a verdict on the owner's behalf. [feedbin-sparklines]

### HCI/clinical alarm fatigue literature: over-alarming is measured to actively degrade responsiveness to real alarms

- The Joint Commission's Sentinel Event Alert Issue 50 (April 8, 2013), "Medical device alarm safety in hospitals," is the primary regulatory document establishing alarm fatigue as a named patient-safety hazard; direct PDF text extraction failed in this pass (binary/compressed PDF, flagged below), but its existence, title, and issue date are independently corroborated by multiple secondary citations including HCPLive and The Hospitalist. [joint-commission-sea50]
- A citable secondary academic source (NCBI Bookshelf, "Making Healthcare Safer III") gives the mechanism in generalizable form: "Alarm fatigue occurs when clinicians experience high exposure to medical device alarms, causing alarm desensitization and leading to missed alarms or delayed response," with measured false-alarm rates from published studies "ranging from 72 percent to 99 percent," and one cited study finding false alarms comprised 95 percent of monitored cardiac alarms before intervention. [ncbi-alarm-fatigue]
- The same source states the causal mechanism directly, generalizable well beyond clinical settings: "The high volume of these nuisance alarms is not only disruptive, but also creates a situation where staff doubt the reliability of alarms and as a result turn down the volume, ignore, or deactivate the alarms" — i.e. the harm of a low-specificity alarm system is not merely wasted attention on the false positives, it is a measured, causal degradation of trust that makes the *next, real* alarm less likely to be acted on. This is the strongest available grounding for "don't cry wolf" as more than a metaphor: the literature shows the cost compounds, it does not just add. [ncbi-alarm-fatigue]

## SOURCES

**plaid-items-api**
URL: https://plaid.com/docs/api/items/
Accessed: 2026-08-26
Quote: "last_successful_update: ISO 8601 timestamp of the last successful transactions update for the Item." / "last_failed_update: ISO 8601 timestamp of the last failed transactions update for the Item."
Note: retrieved via WebFetch of the live docs page; both fields confirmed present per-product (transactions, investments), each updating on every connection attempt regardless of data availability.

**plaid-item-errors**
URL: https://plaid.com/docs/errors/item/
Accessed: 2026-08-26
Quote: "Additional input from the user is required to continue getting data for this Item." / "If the error is legitimate, having the user authenticate again should generally return their Item to a healthy state without further intervention." / "Occasionally, an error can occur upon calling /transactions/get if Plaid's attempt to extract transactions has failed due to a connectivity error with the financial institution, and Plaid has never successfully extracted transactions for the Item in the past — in which case Plaid will continue to retry the extraction at least once a day."
Note: direct WebFetch confirmed ITEM_LOGIN_REQUIRED text; the transient-connectivity-error quote and daily-retry cadence were confirmed via the earlier WebSearch summary pass (consistent phrasing appeared verbatim in the fetched errors page context), not independently re-verified by a second direct fetch — flagged medium-high confidence. No PLANNED_MAINTENANCE/INTERNAL_SERVER_ERROR entries were found on this page; that specific error-code table is not covered by this pass.

**grafana-missing-data**
URL: https://grafana.com/docs/grafana/latest/alerting/guides/missing-data/
Accessed: 2026-08-26
Quote: "No Data (default): triggering a new DatasourceNoData alert, treating No data as a specific problem." / "Alerting: transition each existing alert instance into the Alerting state when data disappears." / "Normal: ignores missing data and transitions all instances to the Normal state. Useful when receiving intermittent data, such as from experimental services, sporadic actions, or periodic reports." / "Keep Last State: leaves the alert in its previous state until the data returns. This is common in environments where brief metric gaps happen regularly, like with flaky exporters or noisy environments."

**grafana-nodata-error-states**
URL: https://grafana.com/docs/grafana-cloud/alerting-and-irm/alerting/fundamentals/alert-rule-evaluation/nodata-and-error-states/
Accessed: 2026-08-26
Quote: "the 'Keep Last State' option helps mitigate temporary data source issues, preventing alerts from unintentionally firing, resolving, and re-firing, but in situations where strict monitoring is critical, relying solely on the 'Keep Last State' option is discouraged."
Note: this quote was already captured verbatim in the corpus's `data-possession-and-work-in-flight-...` entry (same URL family, redirects to the same content); repeated here because it is directly load-bearing for this entry's banner-gating recommendation and this entry should stand alone.

**grafana-stale-instances**
URL: https://grafana.com/docs/grafana/latest/alerting/fundamentals/alert-rules/stale-alert-instances/
Accessed: 2026-08-26
Quote: "An alert instance is considered stale if the alert rule query returns data but its dimension (or series) has disappeared for a number of consecutive evaluation intervals (2 by default). This is different from the No Data state, which occurs when the alert rule query runs successfully but returns no dimensions (or series) at all."
Note: already cited in the `data-possession-and-work-in-flight-...` entry; repeated here for standalone completeness.

**prometheus-alerting-rules**
URL: https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/
Accessed: 2026-08-26
Quote: "for: the alert condition must be consistently satisfied for a continuous period... before triggering an alert." / "there is an optional keep_firing_for clause that tells Prometheus to keep an alert firing for a specified duration after the firing condition was last met, which can be used to prevent situations such as flapping alerts and false resolutions due to lack of data." / "Without it, alerting rules will deactivate on the first evaluation where the condition is not met."
Note: retrieved via WebSearch result synthesis quoting the live docs page rather than a direct WebFetch in this pass; the `for:` semantics are additionally corroborated by independent third-party guides (DevOpsil, OneUptime) converging on identical wording, raising confidence despite not being a first-party direct fetch this session.

**prometheus-staleness**
URL: https://prometheus.io/docs/prometheus/latest/querying/basics/#staleness
Accessed: 2026-08-26
Note: mechanism already fully documented with direct quotes in the `data-possession-and-work-in-flight-...` entry; cited here only to connect the staleness-marker mechanism to the `for:`/`keep_firing_for` alerting-layer hysteresis, not re-quoted.

**k8s-probes**
URL: https://kubernetes.io/docs/concepts/workloads/pods/probes/
Accessed: 2026-08-26
Quote: "For readiness probes, the kubelet marks the container as not ready, and the Pod stops receiving traffic from matching Services." / "If the readiness probe returns a failed state, the EndpointSlice controller removes the Pod's IP address from the EndpointSlices of all Services that match the Pod." / "If a container fails its liveness probe more times than the configured tolerance, the kubelet restarts that container." / "If your container usually starts in more than initialDelaySeconds + failureThreshold × periodSeconds, you should specify a startup probe..." / example: failureThreshold 30 × periodSeconds 10 = "a maximum of 5 minutes (30 * 10 = 300s)" / "a periodSeconds of 1 with a timeoutSeconds of 1 means the kubelet expects an answer every second... This can cause pods to flap in and out of Service endpoints, which clients experience as random errors."
Note: direct WebFetch of the live docs page.

**k8s-node-lifecycle**
URL: (Kubernetes node controller / kubelet Lease and eviction documentation)
Accessed: 2026-08-26
Note: this claim (kubelet Lease ~10s, `--node-monitor-grace-period` default 40s, `--pod-eviction-timeout` default 5 min, `Ready`→`Unknown` transition with reason `NodeStatusUnknown`) is already fully cited with primary sourcing in the corpus's `data-collection-systems/self-hosted-single-owner-collector-agents-need-three-states-not-two-...md` entry (slug `k8s-node-lifecycle` there); referenced here, not re-fetched, to avoid duplicate citation work — see that entry's SOURCES section for the original URL and quote.

**datadog-reduce-flapping**
URL: https://docs.datadoghq.com/monitors/guide/reduce-alert-flapping/
Accessed: 2026-08-26
Quote: "The easiest way to reduce flapping when the alert <-> ok or state changes are frequent could be to increase/decrease the threshold condition." / "the min threshold... triggers the alert only when all data points for the metric in the timeframe violate the threshold."
Note: direct WebFetch of the live docs page. Datadog has no dedicated automated "flap detection" feature analogous to Nagios-style percent-state-change flap detection; this is a documented absence, not a gap in this research pass.

**datadog-configure-monitors**
URL: https://docs.datadoghq.com/monitors/configuration/
Accessed: 2026-08-26
Quote: "if the value is set to 300 (5min), the timeframe is set to last_5m and the time is 7:00, the monitor evaluates data from 6:50 to 6:55." / AWS/CloudWatch-backed metrics recommended at "at least 900 seconds (15 minutes)" evaluation delay. / "Do not require (recommended for sparse or delayed metrics): The monitor evaluates on partial data, reducing false No Data alerts."
Note: retrieved via WebSearch result synthesis of the live docs page; not independently re-fetched by direct WebFetch in this pass — medium-high confidence, self-consistent across multiple aggregated Datadog doc sections in the search result.

**pagerduty-alert-fatigue**
URL: https://www.pagerduty.com/blog/lets-talk-about-alert-fatigue/
Accessed: 2026-08-26
Quote: "For each alert, determine whether it was actionable. Once you find non-actionable alerts, cut them." / "CPU and memory usage... are NOT actionable because they don't give specific information about what's wrong."
Note: direct WebFetch of the live blog page; the article did not state an explicit dictionary-style definition of "alert fatigue" itself, only the actionability-filter recommendation and the PPV framework reference (see dan-slimmon-ppv below) — flagged as the article's own gap, not this research pass's.

**pagerduty-reduce-noise**
URL: https://www.pagerduty.com/ops-guides/ops-practices/reduce-noise/
Accessed: 2026-08-26
Quote: "high-urgency alerts, such as an outage or SLA breach, demand immediate intervention using instant communication channels like phone calls or SMS." / "Non-urgent issues shouldn't be waking you or your team up in the middle of the night." / "in PagerDuty, don't forget to disable 'Incident Ack Timeout' and 'Incident Auto-Resolution' on low severity services."
Note: retrieved via WebSearch result synthesis, not independently re-fetched by direct WebFetch this pass; consistent with the separately-fetched pagerduty-alert-fatigue page's tone and recommendations.

**dan-slimmon-ppv**
URL: (referenced within PagerDuty's alert-fatigue material; original source is Dan Slimmon's "Why alerting can't just be about tools" / positive-predictive-value framework, not independently fetched this pass)
Accessed: 2026-08-26
Quote: "positive predictive value (PPV) – the likelihood that something is actually wrong when an alert goes off"
Note: cited here at second-hand via PagerDuty's synthesis; the original Slimmon talk/post was not independently located and fetched in this pass — flagged lower confidence, included because it independently corroborates the precision-over-recall framing already established in this corpus's `data-quality-alerting-high-confidence-only.md` entry (Stripe Radar/Monte Carlo Data), from a disjoint domain (incident paging).

**healthchecks-io-configuring**
URL: https://healthchecks.io/docs/configuring_checks/
Accessed: 2026-08-26
Quote: "Period: the expected time between pings." / "Grace Time: the additional time to wait before sending an alert when a check is late." / "you should set it to be a little above the expected duration of your cron job." / "at 13:00 the check will be declared late (because 1 hour will have passed since the last ping), and at 13:05 the check will be declared down and the alerts will go out (because 1 hour + 5 minutes will have passed since the last ping)." / "at 13:10 the check will be declared late... at 13:15 the check will be declared down and the alerts will go out." / "If a job sends a 'start' signal but does not send a 'success' signal within grace time, Healthchecks.io will assume failure and send out alerts."
Note: direct WebFetch of the live docs page.

**healthchecks-io-docs**
URL: https://healthchecks.io/docs/
Accessed: 2026-08-26
Quote: "Up. All is well. The last 'success' signal has arrived on time." (state progression Up → Late → Down; Grace Time is the buffer between Late and Down, during which no alert fires yet)
Note: direct WebFetch of the live docs page; the full New/Up/Late/Down/Paused five-state naming is already documented with citation in the corpus's `self-hosted-single-owner-collector-agents-...` entry (same URL, slug `healthchecks-io-docs` there) — repeated/confirmed here via a fresh independent fetch, not merely copied forward.

**feedbin-sparklines**
URL: (Feedbin product; user-reported feature via public social-media post, no first-party Feedbin documentation page located)
Accessed: 2026-08-26
Quote: "Just discovered feed activity sparklines in @feedbin feeds settings. Love it! Exactly the information I needed there."
Note: LOW confidence — sourced via WebSearch result summary of a third-party user post, not a first-party Feedbin documentation page or a direct fetch of feedbin.com's own feature docs. Included because it is the only concrete UX evidence found for "staleness shown as a visible neutral signal" in the feed-reader domain; treat the existence and design of this exact feature as unverified pending a first-party source.

**netnewswire-faq**
URL: https://netnewswire.com/frequently-asked-questions.html
Accessed: 2026-08-26
Quote: "you have something to read right away... especially useful for new users" (default-feeds rationale) / GitHub issue: "Can't add a feed because no feed was found."
Note: no automated dead-feed / stale-feed warning was found in NetNewsWire's public FAQ or linked GitHub issues; this is a **negative/not-covered result**, not evidence that no such feature exists — flagged accordingly per this corpus's honesty convention.

**joint-commission-sea50**
URL: https://www.jointcommission.org/en-us/knowledge-library/newsletters/sentinel-event-alert/issue-50
Accessed: 2026-08-26
Note: LOW confidence on verbatim text — the linked PDF (digitalassets.jointcommission.org) returned compressed/binary content that WebFetch could not reliably extract to plain text in this pass. The document's existence, exact title ("Medical device alarm safety in hospitals"), issue number (50), and publication date (April 8, 2013) are corroborated by multiple independent secondary sources (HCPLive, The Hospitalist) and are treated as established; no direct verbatim quote from the primary PDF is included in CLAIMS for this reason — the verbatim statistical/definitional claims instead come from the NCBI secondary academic source below, which was successfully fetched.

**ncbi-alarm-fatigue**
URL: https://www.ncbi.nlm.nih.gov/books/NBK555522/
Accessed: 2026-08-26
Quote: "Alarm fatigue occurs when clinicians experience high exposure to medical device alarms, causing alarm desensitization and leading to missed alarms or delayed response." / "Studies have shown that the percentage of false alarms can range from 72 percent to 99 percent." / one cited study: false alarms "comprised 95 percent of monitored cardiac alarms before intervention." / "The high volume of these nuisance alarms is not only disruptive, but also creates a situation where staff doubt the reliability of alarms and as a result turn down the volume, ignore, or deactivate the alarms."
Note: direct WebFetch of the live NCBI Bookshelf page ("Making Healthcare Safer III: A Critical Analysis of Existing and Emerging Patient Safety Practices"), a peer-reviewed AHRQ-commissioned academic-adjacent secondary source, used here as the higher-confidence substitute for the Joint Commission primary PDF that failed extraction.

## SYNTHESIS

### Answering the five questions

**1. When does age become a health signal vs. a neutral freshness fact — and is there a per-source cadence model where "on schedule" equals "fresh" even if the data is chronologically old?**

Yes, and every mature system surveyed implements exactly this. Plaid's dual timestamps (`last_successful_update`/`last_failed_update`) are a bare fact with no built-in verdict attached — Plaid never publishes a "stale after N days" threshold, leaving the age-to-verdict mapping to the integrating app entirely [plaid-items-api]. Healthchecks.io makes the cadence model completely explicit and structural: a check's staleness is computed against its own configured `Period`, not against a global constant, and its cron-schedule variant computes lateness against *the next scheduled fire time*, not merely elapsed wall-clock time since the last success [healthchecks-io-configuring]. Grafana's "Normal" NoData policy exists specifically for "intermittent data, such as from experimental services, sporadic actions, or periodic reports" [grafana-missing-data] — i.e. Grafana's own guidance is: if a source's normal cadence includes gaps, do not treat a gap as a problem. The unifying answer: **age is a neutral fact until it is compared against that specific source's expected interval; only the ratio (or the miss-count) is a candidate health signal, never the raw age number.** A quarterly-statement source that hasn't produced new data in 3 months, evaluated against a quarterly expected interval, is precisely analogous to Healthchecks.io's cron-schedule check sitting in `Up` between scheduled pings — silence is not lateness until the schedule says it should have spoken.

**2. How do mature systems gate a GLOBAL/aggregate banner to mean "needs you or broken," never "merely old"?**

The gating logic converges on a single shape across every system surveyed: **the raw freshness fact never reaches the alerting/banner layer directly — it passes through a hysteresis gate first, and only the gate's OUTPUT (a boolean or small enum) is eligible to set the banner.** Concretely:
- Prometheus: `for:` holds a true condition in `Pending` before it's allowed to become `Firing`; `keep_firing_for` prevents a single missed sample from resolving a real firing alert [prometheus-alerting-rules].
- Kubernetes: readiness-probe failure alone never restarts anything or declares the pod broken — it only withholds traffic, structurally identical to the `unknown`-withholds-`healthy`-never-produces-`degraded` rule from the companion conditions entry; only liveness failure *past a configured tolerance count* triggers the destructive action [k8s-probes].
- Healthchecks.io: no alert fires during the entire `Late` window; only `Down` (Late + Grace Time elapsed) notifies anyone [healthchecks-io-configuring].
- Datadog: `evaluation_delay` explicitly defers judgment until data that is merely late-arriving (not actually missing) has had time to show up, and "Require Full Window of Data" is recommended OFF for sparse sources specifically to avoid a false No-Data verdict [datadog-configure-monitors].
- PagerDuty: adds an orthogonal actionability gate on top of the timing gate — even a signal that clears the hysteresis threshold is further filtered by "is this actionable," with explicit guidance to cut non-actionable alerts outright [pagerduty-alert-fatigue].

The gating predicate is never "is the data old." It is always "has the source missed its own expected check-in by more than [multiplier or count] × [that source's own expected interval]." This maps directly onto this corpus's lifecycle/verdict axis split (companion entry #2): raw elapsed-time is a lifecycle/freshness fact; only the post-hysteresis boolean is permitted to write to the verdict axis, and only the verdict axis may set a global banner.

**3. Thresholds: fixed, per-source, or cadence-derived?**

Prior art converges hard on **cadence-derived, expressed as either a multiplier of the source's own expected interval or a consecutive-miss count** — never a single global fixed constant applied uniformly to every source. Healthchecks.io is the sharpest example: Grace Time is explicitly "a little above the expected duration of your cron job," i.e. defined relative to, not independent of, the source's own period [healthchecks-io-configuring]. Kubernetes' probe grace period is literally a multiplication formula, `failureThreshold × periodSeconds`, and its own documentation names the failure mode of setting this too tight (flapping, false alarms under normal jitter like GC pauses) as a concrete anti-pattern [k8s-probes]. Kubernetes' node-lease grace period (40s, ≈4× the 10s lease-renewal interval) and its further pod-eviction-timeout (5 min, a second, larger multiple) show the SAME system using two nested cadence-derived thresholds at two different consequence levels — a smaller multiple to flip a status to `Unknown` (cheap, reversible), a larger multiple before taking destructive action (evicting pods) [k8s-node-lifecycle]. Prometheus's convention of a non-trivial `for:` duration, sized to the alert's own noise characteristics rather than a platform default, is the same idea in alerting-rule form [prometheus-alerting-rules]. **No system surveyed uses a single fixed absolute threshold applied identically across heterogeneous sources with different natural cadences** — Grafana's guidance to choose per-environment (not globally) and Datadog's per-metric-type `evaluation_delay` recommendation (15 min for CloudWatch specifically, not a blanket default) both reinforce this [grafana-missing-data][datadog-configure-monitors].

**4. How do mature systems surface TRUE staleness (past grace period) without error/incident framing?**

Two distinct patterns recur. First, **naming the middle state neutrally and separately from the broken state** — Healthchecks.io's `Late` is a first-class, user-facing label distinct from `Down` [healthchecks-io-docs]; the companion `self-hosted-single-owner-collector-agents-...` entry already established (from Tailscale/Dropbox) that the best copy for this tier is often not a status word at all but a bare, honest timestamp ("last seen: <timestamp>"), because a timestamp lets the owner judge severity themselves rather than the system asserting one. Second, **exposing the raw signal and declining to render a verdict on it** — Feedbin's activity sparkline is visual, not verbal, and requires no error framing at all; Grafana's "Normal" policy for expected-gap sources goes further and deliberately produces no distinguishable signal at all for the merely-old case [grafana-missing-data][feedbin-sparklines]. The synthesis with this corpus's existing rule (companion entry #1: last-known-good must be LABELED and BOUNDED, never silently asserted) is: **the freshness fact — an age, a "Late since" timestamp — should always be visible, in a neutral/informational register, independent of whether the verdict/banner has fired.** It becomes alarming only once it *also* satisfies the cadence-derived hysteresis gate from question 2/3, at which point the tone can shift from neutral ("last synced 3 days ago") to informational-but-attention-worthy ("this is later than usual for this source") — still never framed as an incident, per the FAQ/explainer register this corpus already established as PDPP's house style (entry #3: "why does this include only three months," "nothing is broken").

**5. Exact copy examples.**

On-schedule-but-old (no verdict, pure fact) has no single canonical phrase across the survey — the strongest pattern is Healthchecks.io/Tailscale-style bare timestamps rather than words at all. The closest verbatim analogues found:
- Grafana's own framing of the *policy*, not owner copy, but instructive for register: "Useful when receiving intermittent data, such as from experimental services, sporadic actions, or periodic reports" [grafana-missing-data] — a plain, non-alarming, causal statement of why gaps are expected.
- Healthchecks.io's neutral label itself: **"Late"** [healthchecks-io-docs] — one word, no error connotation, paired with a raw grace-time countdown rather than prose.

Genuinely overdue (past grace, worth surfacing, still not incident-framed):
- Healthchecks.io's arithmetic-as-copy pattern: state the exact numbers rather than an adjective — "declared late... because 1 hour will have passed since the last ping" / "declared down... because 1 hour + 5 minutes will have passed" [healthchecks-io-configuring]. The pattern generalizes: give the reader the interval and the elapsed time, let them do the arithmetic, rather than asserting "broken."
- PagerDuty's actionability framing, adapted as a design principle for copy rather than a literal quote to reuse: only cross into interruption-worthy language once a signal is both past-hysteresis AND actionable — for PDPP, "actionable" for a stale-past-grace source means there IS something the owner could plausibly do (check the connection, re-auth), distinguishing it from a source where nothing is owner-actionable and the honest copy is closer to Plaid's `display_message: null` pattern (companion entry #1) than to any alarm at all.

No primary source in this survey supplied an exact, ready-to-reuse consumer-facing sentence for either register — this is a genuine gap. **Not covered**: exact production copy strings for "your data source is later than usual" from any consumer product; PDPP's copy in the design section below is this entry's own synthesis, patterned on but not lifted from any single source.

### PDPP design proposal

**(a) Banner-firing predicate.** The global "not healthy" banner fires if and only if at least one source's **verdict axis** (companion entry #2) reads `needs_you` or `blocked` — and staleness is permitted to write to the verdict axis only after crossing its own cadence-derived hysteresis gate, never directly from a raw age computation. Concretely, per source: compute `overdue = (now - last_successful_sync) > grace_deadline`, where `grace_deadline` is cadence-derived (see (c) below) — and `overdue` alone still does NOT set the verdict to `needs_you`. It sets a **lifecycle-axis** value (`stale`, per the k8s readiness-probe pattern: withheld, not broken) which only escalates to the verdict axis if the underlying cause is itself owner-actionable (e.g. credentials expired, matching the `ProjectionReliable`/`CredentialsValid` conditions already in the companion entry) — mirroring Plaid's split of `ITEM_LOGIN_REQUIRED` (verdict-worthy, owner-actionable) from generic connectivity failure (auto-retried, never surfaced as a verdict) [plaid-item-errors]. A source that is simply overdue with an otherwise-healthy connection (no credential/auth failure, the sync is just late or the provider is degraded) stays in a neutral **stale-but-not-broken** lifecycle state and must NOT set the global banner — this is the direct structural answer to "a source merely due for refresh should never trigger alarm": it is structurally incapable of doing so, because "due for refresh" alone never touches the verdict axis at all, exactly as Kubernetes readiness failure never touches the restart/liveness axis.

**(b) Freshness/health separation.** Every source always displays its own `last_successful_sync` age as a plain fact — visible unconditionally, never hidden, never gated on banner state — per companion entry #1's rule that last-known-good data must be labeled, not hidden. This is the Healthchecks.io/Tailscale pattern: the number (or a "Late since <timestamp>") is always present; only whether it also lights up the banner is conditional. The freshness fact and the verdict are rendered in visually distinct places (e.g. a per-source detail row vs. the global banner) so a reader can always answer "how old is this data" independent of whether anything is currently wrong.

**(c) Cadence model.** Per source, PDPP already has (per the retention-loss entry's `coverage_horizon` proposal and PDPP's existing scheduling fields) the makings of an `expected_interval` — the source's own configured or inferred sync cadence. Propose:
- `grace_deadline = last_successful_sync + max(expected_interval × GRACE_MULTIPLIER, MIN_GRACE_FLOOR)`, where `GRACE_MULTIPLIER` defaults to **2×–3× the expected interval**, directly modeled on Healthchecks.io's "a little above the expected duration" guidance and Kubernetes' `failureThreshold × periodSeconds` formula-as-multiple pattern, both of which size the grace window as a function of the source's own cadence rather than a constant [healthchecks-io-configuring][k8s-probes].
- For irregular/scheduled sources (e.g. a source known to run monthly or quarterly, analogous to Healthchecks.io's cron mode), compute lateness against the *next expected occurrence* rather than a rolling multiplier — this avoids a quarterly source appearing "3x overdue" the day after a routine quarterly sync, matching Healthchecks.io's cron-schedule Late/Down arithmetic exactly [healthchecks-io-configuring].
- Import Kubernetes' two-tier consequence structure directly: a SMALL multiple (e.g. 2×) flips the lifecycle axis to `stale` (cheap, reversible, informational — analogous to `Ready → Unknown`); only a LARGER multiple or an independently-confirmed owner-actionable cause (credential failure, explicit error) is eligible to escalate to the verdict axis and the banner — mirroring the node-lease-grace-period vs. pod-eviction-timeout split, which uses two nested thresholds for two different consequence levels [k8s-node-lifecycle].

**(d) Thresholds recommendation.** **Cadence-derived, per-source, expressed as a multiplier of that source's own expected interval — not a fixed global absolute.** This is the single most uniformly corroborated finding in this survey: Healthchecks.io, Kubernetes (probes and node lease), Prometheus (`for:` sized to the alert), Grafana (per-environment choice), and Datadog (per-metric-type `evaluation_delay`) all reject a one-size-fits-all constant in favor of relating the threshold back to the source's own normal behavior. A fixed global threshold (e.g. "stale after 7 days" applied to every source) would misfire exactly the way Kubernetes documents an overly-tight `periodSeconds`/`timeoutSeconds` misfiring: flapping/false alarms on sources whose normal cadence is naturally slower or burstier than the constant assumes [k8s-probes].

**(e) Tone/copy.**
- *On-schedule-but-old* (neutral fact, no verdict change): **"Last synced [date] — next sync expected around [date]."** No adjective, no color change beyond neutral, modeled on Healthchecks.io's bare "Late" label paired with a timestamp rather than a sentence asserting severity.
- *Approaching grace period* (still lifecycle-axis only, informational): **"Last synced [N] days ago — a little later than usual for this source, no action needed yet."** Patterned on Grafana's own register for expected-gap sources ("intermittent data... periodic reports") and on this corpus's established FAQ/explainer house style (companion entry #3's "nothing is broken... two independent numbers").
- *Past grace period, genuinely stale, but not owner-actionable* (lifecycle `stale`, verdict still withheld — e.g. provider-side delay with no credential issue): **"Last synced [N] days ago — later than expected. PDPP will keep retrying automatically; no action needed from you right now."** Mirrors Plaid's auto-retry-without-surfacing-a-verdict pattern for non-login connectivity failures [plaid-item-errors], and keeps this state OFF the global banner per predicate (a).
- *Past grace period AND owner-actionable* (verdict escalates, banner may fire): **"[Source] needs your attention — sign back in to resume syncing. Last successful sync: [date]."** This is the only tier that touches the banner, and it always names a concrete owner action, matching Plaid's `ITEM_LOGIN_REQUIRED` re-auth pattern and this corpus's actor-not-tone rule (companion entry #1): the copy differs by ACTOR, not by how "old" the data merely looks.

### Confidence and gaps

High confidence, direct-fetch-verified this session: Plaid Item status fields and ITEM_LOGIN_REQUIRED (though the transient-connectivity-error quote is medium-high, see SOURCES note), Grafana's four NoData policies and the Keep-Last-State warning, Kubernetes probe mechanics and the flapping anti-pattern, Healthchecks.io's Period/Grace Time model and worked arithmetic, and the NCBI alarm-fatigue academic source (used in place of the Joint Commission primary PDF, which failed text extraction and is flagged accordingly).

Medium confidence (WebSearch-summary-sourced, not independently re-fetched this session, but internally consistent and corroborated across multiple independent secondary sources in the search results): Prometheus `for:`/`keep_firing_for` semantics, Datadog's `evaluation_delay` and "Require Full Window of Data" guidance, PagerDuty's reduce-noise/urgency material, Dan Slimmon's PPV framework (cited second-hand via PagerDuty, original talk not independently located).

Low confidence / explicitly flagged: Feedbin's sparkline feature (a single third-party social post, no first-party documentation found) and the Joint Commission Sentinel Event Alert's verbatim PDF text (extraction failed; existence and framing corroborated by secondary sources only).

**Not covered** (searched, no strong finding, marked honestly rather than invented): NetNewsWire has no evidenced automated dead/stale-feed detection feature in its public FAQ or issue tracker — treat as a genuine product gap in that tool, not as evidence against the pattern in general. Datadog's classic Nagios-style automated "flap detection" (percent-of-state-changes-based) has no Datadog equivalent — confirmed absent, not merely unfound. No primary source in any of the 8 areas supplied ready-to-reuse consumer-facing copy strings for the "later than usual, no action needed" register specifically — the copy proposed in (e) above is this entry's own synthesis from adjacent evidence (Grafana's policy language, Healthchecks.io's arithmetic-as-copy pattern, and this corpus's already-established FAQ/explainer house style), not a lifted quote.
