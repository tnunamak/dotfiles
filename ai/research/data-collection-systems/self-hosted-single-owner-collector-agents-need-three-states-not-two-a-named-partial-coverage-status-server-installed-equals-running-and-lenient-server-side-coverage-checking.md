---
title: "A self-hosted single-owner collector-agent fleet should use a lenient server-side coverage table (not strict set equality), a three-state stale/unknown/broken health vocabulary instead of two, a named partial-coverage status instead of binary complete/incomplete, and an installer that leaves the agent already running on a schedule"
date: 2026-08-16
topic: data-collection-systems
tags: [version-skew, capability-negotiation, coverage-proof, agent-scheduling, health-vocabulary, self-hosted]
status: draft
sources: [k8s-version-skew, k8s-field-validation, k8s-deprecation-policy, k8s-api-conventions, k8s-node-lifecycle, otel-component-stability, elastic-fleet-versioning, chef-rfc041, sentry-auth-header, protobuf-unknown-fields, restic-backup-docs, restic-check-docs, borg-exit-codes, rclone-check, filebeat-how-it-works, fluentbit-tail, time-machine-internals, datadog-agent-systemd, osquery-deployment, node-exporter-guide, restic-systemd-archwiki, tailscale-install-script, prometheus-staleness, prometheus-jobs-instances, nagios-plugin-guidelines, healthchecks-io-docs, tailscale-last-seen, dropbox-sync-status, connector-fleet-health-ux-corpus]
source_session: af82d1f3-1838-4307-a3a9-6bbf07e77c6f
---

## CLAIMS

- Kubernetes enforces version skew as a documented support boundary, not a live-rejected handshake: kubelet may run up to 3 minor versions older than kube-apiserver (2 for kubelet <1.25) and never newer; kubectl works within 1 minor version either direction; the docs describe no active version-reject mechanism for out-of-window kubelet. [k8s-version-skew]
- Kubernetes' server-side unknown-field validation (since v1.25) is opt-in via `?fieldValidation=Ignore|Warn|Strict`, defaulting to `Warn` (accept the request, return a per-field `Warning:` response header) rather than silently dropping or hard-rejecting; KEP-2885 states explicitly this must stay opt-in "to maintain compatibility with all existing clients." [k8s-field-validation]
- Kubernetes API deprecation policy guarantees GA APIs ≥12 months/3 releases notice before removal and forbids deprecating an API in favor of a less-stable one; a stronger guarantee than "ignore unknown fields" is the round-trip rule — an object written as version N and read back as version M must reconvert losslessly. [k8s-deprecation-policy]
- Kubernetes Conditions (the `status` field on e.g. `Ready`) take three values — `True`, `False`, `Unknown` — and the API conventions state the absence of a condition should be read the same as `Unknown`, typically meaning reconciliation hasn't finished or the resource state isn't yet observable. [k8s-api-conventions]
- Kubernetes node health is explicitly three-staged in time: the kubelet renews a Lease roughly every 10s; after `--node-monitor-grace-period` (default 40s) of silence the node controller sets `Ready` to `Unknown` (reason `NodeStatusUnknown`, message "Kubelet stopped posting node status"); only after a further `--pod-eviction-timeout` (default 5 min) does eviction begin. `False` means "kubelet is alive and actively reporting a problem"; `Unknown` means "we haven't heard from it." [k8s-node-lifecycle]
- OpenTelemetry Collector components self-declare a per-component, per-signal stability level (In Development → Alpha → Beta → Stable, plus Deprecated/Unmaintained) as static metadata inspectable via a CLI subcommand; this is declared capability information, not a runtime negotiation with a control plane. [otel-component-stability]
- Elastic Fleet enforces a strict monotonic version chain at enrollment — Elasticsearch ≥ Fleet Server ≥ Elastic Agent (by minor version) — and rejects an agent that is newer than the Fleet Server it's enrolling against, rather than allowing any skew window. [elastic-fleet-versioning]
- Chef Server implements true bilateral protocol-version negotiation: the client sends an `X-Ops-Server-API-Version` integer header; a missing header defaults to the server's minimum supported version; an out-of-range or non-numeric value gets HTTP 406 with a JSON body naming `min_api_version`/`max_api_version`; every response carries `response_version` telling the client which version was actually used. [chef-rfc041]
- Sentry's ingest protocol has the client self-declare a protocol version (`sentry_version=7` in the `X-Sentry-Auth` header on every event) which the server validates against a fixed accepted set, rejecting malformed/out-of-range values with 400 — closer to "client asserts, server validates against a floor" than negotiation. [sentry-auth-header]
- protobuf's wire format is tag-based (field number + wire type), so a parser built against an older schema skips fields it doesn't recognize into an unknown-field set instead of erroring; the official proto3 guide states "old binaries simply ignore the new field when parsing." This guarantee is weaker than it sounds because wire types are reused/ambiguous (wire type 2 covers string/bytes/submessage) so unknown-field round-tripping works for pass-through but not for canonical reinterpretation. [protobuf-unknown-fields]
- restic's `backup` command has a documented three-way exit-code split: `0` full success, `1` fatal error with no snapshot created, `3` "some source files could not be read" — an incomplete-but-usable snapshot is still created and the error count is reported in the run summary. [restic-backup-docs]
- `restic check` verifies repository/pack-file structural integrity (and, with `--read-data`, that stored bytes are intact) — it cannot and does not verify that a backup run captured everything it was supposed to; that is exclusively the exit-code/error-count signal from the backup run itself. [restic-check-docs]
- BorgBackup documents a three-tier exit-code convention: `0` success, `1` warning ("operation reached its normal end, but there were warnings — you should check the log"), `2` error (operation did not reach normal end); this is the most explicit ok/warning/error vocabulary found among the surveyed backup tools. [borg-exit-codes]
- `rclone check` is a separate, explicit two-sided verification command (not embedded in the copy/sync run) that reports `--missing-on-dst`, `--missing-on-src`, `--differ`, `--match`, and `--error` as distinct categories, and offers `--one-way` to narrow verification to source-coverage only. [rclone-check]
- Filebeat's registry tracks a unique per-file identifier plus a read offset (not path alone, because files rotate/rename), and Filebeat's own docs state plainly that if files are rotated faster than they can be processed, or deleted while the output is unavailable, "data might be lost" — a named, documented failure mode with no machine-readable partial-coverage signal; Filebeat has no mechanism to detect, after the fact, that it missed a rotated-and-deleted file while stopped. [filebeat-how-it-works]
- Fluent Bit's tail input uses the same inode-keyed offset-tracking pattern as Filebeat but is more actively self-healing against inotify queue overflow: on `IN_Q_OVERFLOW` it reconciles all monitored files (comparing inodes/names to detect rotation, resetting offsets for truncated files) specifically to avoid silently skipping lines — though it shares Filebeat's blind spot for files that rotate away entirely while the process is fully stopped. [fluentbit-tail]
- Time Machine's backup pipeline runs copy, then a verification phase that matches the resulting backup against the reference snapshot and logs discrepancies, then rotation/housekeeping, and only marks the backup complete after all phases finish; an interrupted run leaves a visible `.inProgress` bundle on the backup volume distinct from a completed dated backup — this mechanism is inferred from a detailed third-party technical breakdown, not confirmed in Apple's own engineering docs. [time-machine-internals]
- The Datadog Agent's systemd unit is `Type=simple`/`Restart=on-failure` (a persistent process, not a timer-triggered oneshot), and the package installer's own Go code calls `EnableStable` then `RestartStable` during install — the installer itself runs the equivalent of `systemctl enable` and starts the service, so "installed" already means "running." [datadog-agent-systemd]
- osquery's package installer pre-installs a systemd unit for `osqueryd`, but the daemon will not start until a config file exists at `/etc/osquery/osquery.conf`, and the docs direct the user to manually run `systemctl start osqueryd` — systemd integration is pre-wired but installation alone does not make the agent run. [osquery-deployment]
- Prometheus's `node_exporter` is architecturally exempt from the self-scheduling question: it is a long-lived HTTP daemon with a `/metrics` endpoint and does zero internal scheduling; the scrape cadence lives entirely in Prometheus's own `scrape_interval` config, not in the agent. [node-exporter-guide]
- restic ships with no built-in scheduler of any kind; the ecosystem convention (per ArchWiki and multiple community wrapper tools — resticprofile, restic-scheduler) is to hand-assemble a systemd oneshot+timer pair, and wrapper tools exist specifically to auto-generate those unit files because the restic project itself ships none. [restic-systemd-archwiki]
- Tailscale's official install script (`tailscale.com/install.sh`) runs `systemctl enable --now tailscaled` (or the per-distro/init-system equivalent) as part of installation itself, so enabling-at-boot and starting-immediately happen in one step with zero separate user action — the strongest "installed IS running" precedent found among the surveyed agents. [tailscale-install-script]
- No established cross-system name exists for the "one timer wakes the package, the package decides what to run" pattern beyond the descriptive phrase "systemd timer + oneshot service" — the pattern is real and precedented (also structurally mirrored by Kubernetes CronJob→Job) but no source uses a distinct term like "wake-and-dispatch." [restic-systemd-archwiki]
- Prometheus's `up{job,instance}` metric is strictly binary (1 scrape-succeeded / 0 scrape-failed), not tri-state; staleness is a separate mechanism — when a series stops appearing, Prometheus writes an internal, PromQL-invisible "stale NaN" marker roughly one scrape-interval-plus-10%-slack after the series vanishes, after which queries simply return no value rather than holding the last reading forever. The commonly-cited "5 minutes" is a different setting (`--query.lookback-delta`), a fallback window used only when no staleness marker exists yet (e.g., after a Prometheus restart). [prometheus-staleness] [prometheus-jobs-instances]
- The Nagios/Monitoring-Plugins exit-code guideline explicitly distinguishes UNKNOWN ("the check itself could not run" — bad arguments, internal fork/socket failure) from CRITICAL ("the check ran and found a bad state"), but this can't-tell-vs-know-it's-bad distinction is inconsistently honored in practice: Nagios Core's own `service_check_timeout_state` defaults to Critical (not Unknown) on a hung check, and several official plugins hard-code CRITICAL on their own internal timeout. [nagios-plugin-guidelines]
- Healthchecks.io uses an explicit named third state between healthy and confirmed-down: New → Up → Late (grace period elapsed but still within tolerance) → Down (grace period fully elapsed, alerts fire) → Paused; "Late" is a deliberate, user-facing label for "expected but not yet confirmed broken." [healthchecks-io-docs]
- Consumer/prosumer device-sync UIs avoid alarming words for the ambiguous stopped-reporting state and instead use neutral, timestamp-anchored copy: Tailscale's admin console shows connected devices as "Connected" and disconnected devices as "Last seen: Sep 19, 10:03 AM PDT" with no "offline"/"error"/"failed" language at all. [tailscale-last-seen]
- Dropbox reserves alarming copy ("[x] files are unable to sync") only for confirmed, actionable failure, and uses neutral phrasing ("Your files are up to date," "Syncing paused until [x]") for healthy and deliberately-paused states respectively. [dropbox-sync-status]
- Prior corpus finding (connector-fleet health UX, 2026-05-15): the surveyed connector/integration products (Stripe, Plaid, Linear, Vercel, Fivetran, Zapier, Segment) converge on splitting auth-failure from runtime-failure, giving every state exactly one named affordance, and treating recovery as an automatically-detected state transition rather than a manual "I fixed it" button — directly reusable for a collector connection's health surface, but none of those sources address the specific stale/unknown-vs-broken distinction this research targeted. [connector-fleet-health-ux-corpus]

## SOURCES

**k8s-version-skew**
URL: https://kubernetes.io/releases/version-skew-policy/
Accessed: 2026-08-16

**k8s-field-validation**
URL: https://github.com/kubernetes/enhancements/blob/master/keps/sig-api-machinery/2885-server-side-unknown-field-validation/README.md
Accessed: 2026-08-16
Quote: "We must maintain compatibility with all existing clients, thus server side unknown field validation should be opt-in."

**k8s-deprecation-policy**
URL: https://github.com/kubernetes/website/blob/main/content/en/docs/reference/using-api/deprecation-policy.md
Accessed: 2026-08-16

**k8s-api-conventions**
URL: https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md
Accessed: 2026-08-16
Quote: "Condition `status` values may be `True`, `False`, or `Unknown`. The absence of a condition should be interpreted the same as `Unknown`."

**k8s-node-lifecycle**
URL: https://kubernetes.io/docs/concepts/architecture/nodes/
Accessed: 2026-08-16

**otel-component-stability**
URL: https://github.com/open-telemetry/opentelemetry-collector/blob/main/docs/component-stability.md
Accessed: 2026-08-16

**elastic-fleet-versioning**
URL: https://www.elastic.co/guide/en/fleet/8.19/add-fleet-server-mixed.html
Accessed: 2026-08-16

**chef-rfc041**
URL: https://github.com/chef/chef-rfc/blob/master/rfc041-server-api-versioning.md
Accessed: 2026-08-16

**sentry-auth-header**
URL: https://github.com/getsentry/raven-csharp/issues/133
Accessed: 2026-08-16

**protobuf-unknown-fields**
URL: https://protobuf.dev/programming-guides/proto3/
Accessed: 2026-08-16
Quote: "old binaries simply ignore the new field when parsing"

**restic-backup-docs**
URL: https://restic.readthedocs.io/en/latest/040_backup.html
Accessed: 2026-08-16
Quote: "some source files could not be read (incomplete snapshot with remaining files created)"

**restic-check-docs**
URL: https://restic.readthedocs.io/en/latest/045_working_with_repos.html
Accessed: 2026-08-16

**borg-exit-codes**
URL: https://borgbackup.readthedocs.io/en/stable/usage/general.html
Accessed: 2026-08-16
Quote: "operation reached its normal end, but there were warnings — you should check the log"

**rclone-check**
URL: https://rclone.org/commands/rclone_check/
Accessed: 2026-08-16

**filebeat-how-it-works**
URL: https://www.elastic.co/docs/reference/beats/filebeat/how-filebeat-works
Accessed: 2026-08-16
Quote: "if log files are written to disk and rotated faster than they can be processed, or if files are deleted while the output is unavailable, data might be lost"

**fluentbit-tail**
URL: https://docs.fluentbit.io/manual/data-pipeline/inputs/tail
Accessed: 2026-08-16

**time-machine-internals**
URL: https://eclecticlight.co/2022/02/15/understanding-and-managing-time-machine-snapshots/
Accessed: 2026-08-16

**datadog-agent-systemd**
URL: https://github.com/DataDog/datadog-agent/blob/main/packages/agent/iot/systemd.service.in
Accessed: 2026-08-16

**osquery-deployment**
URL: https://osquery.readthedocs.io/en/stable/deployment/configuration/
Accessed: 2026-08-16

**node-exporter-guide**
URL: https://prometheus.io/docs/guides/node-exporter/
Accessed: 2026-08-16

**restic-systemd-archwiki**
URL: https://wiki.archlinux.org/title/Restic
Accessed: 2026-08-16

**tailscale-install-script**
URL: https://tailscale.com/install.sh
Accessed: 2026-08-16

**prometheus-staleness**
URL: https://prometheus.io/docs/prometheus/latest/querying/basics/#staleness
Accessed: 2026-08-16

**prometheus-jobs-instances**
URL: https://prometheus.io/docs/concepts/jobs_instances/
Accessed: 2026-08-16

**nagios-plugin-guidelines**
URL: https://www.monitoring-plugins.org/doc/guidelines.html
Accessed: 2026-08-16

**healthchecks-io-docs**
URL: https://healthchecks.io/docs/
Accessed: 2026-08-16

**tailscale-last-seen**
URL: https://github.com/tailscale/tailscale/issues/13540
Accessed: 2026-08-16

**dropbox-sync-status**
URL: https://help.dropbox.com/sync/check-sync-status
Accessed: 2026-08-16

**connector-fleet-health-ux-corpus**
URL: /home/tnunamak/code/dotfiles/ai/research/feedback-systems/connector-fleet-health-state-ux-patterns-across-stripe-plaid-linear-vercel.md
Accessed: 2026-08-16

## SYNTHESIS

> **[PERSONA CORRECTION 2026-08-19 — THE "TECHNICAL SELF-HOSTER" PREMISE OF THIS SECTION IS VOID.]** This SYNTHESIS opens by assuming a single owner who is also the technical operator of both sides ("a handful of devices you personally upgrade", rec 2). The product owner has since stated that **PDPP is a consumer product**. The earlier technical-operator reading — argued from the repo calling its surface an "operator console" — was checked on 2026-08-19 and does not hold: the cited evidence is a directory NAME (`docs/operator/`) plus one sentence about who starts a run, and the repo contains **no written audience statement at all** (README, spec-core, spec-architecture all checked). See `product-design/consumer-products-do-show-raw-condition-lists-to-owners-...md` for the full persona correction.
>
> What this changes, recommendation by recommendation:
> - **Rec 1 (lenient coverage) — SURVIVES unchanged.** It argues from restic/borg/rclone/Kubernetes about not discarding usable data. Persona-independent.
> - **Rec 2 (version field, not negotiation) — RE-EXAMINE. This is the one that flips.** Its justification is explicitly "a handful of devices *you personally upgrade*." A consumer does not personally upgrade the collector, so version skew becomes MORE likely and longer-lived, not less. The conclusion (record `collector_protocol_version` and branch the coverage path on it) still stands and is if anything more necessary; but the dismissal of enrollment-time version checks is no longer supported by this reasoning and should be re-derived rather than relied on.
> - **Rec 3 (three tiers, neutral middle-tier language) — SURVIVES and STRENGTHENS.** Its evidence is already consumer prior art (Tailscale's bare "Last seen: <timestamp>", Dropbox's "up to date"/"unable to sync"), and the rule against "error"/"broken"/"failed" in the middle tier matters more for a consumer than for an operator. This is the entry's most transferable finding under the new requirement.
> - **Rec 4 ("setup" means "running") — CONCLUSION SURVIVES, JUSTIFICATION WEAKENS.** The conclusion is stronger for a consumer (who cannot be asked to run `systemctl start`), but the evidence base — systemd units, npm `setup`, ArchWiki — is developer-tooling prior art describing a surface a consumer never touches. Keep the rule; re-source the justification before citing it in a consumer design.
>
> The title and the `self-hosted` tag still frame this entry as self-hoster-scoped. That framing is now narrower than the product; read the recommendations through the corrections above.

For a single-owner self-hosted app with a handful of devices, reject every pattern that only pays off at fleet scale — Chef's bilateral `X-Ops-Server-API-Version` negotiation, Elastic Fleet's strict monotonic version-chain rejection, and Kubernetes' N-minor-version skew policy are all designed to keep thousands of independently-operated clients compatible with a control plane whose upgrade cadence the operator doesn't fully control. A single owner controls both sides, upgrades them close together, and cares more about never losing already-collected data than about protocol purity. The two design moves this changes are:

1. **Server-side coverage checking should be lenient, not strict-set-equality.** Every credible completeness-proving system found (restic exit 3, borg exit 1, rclone's `--missing-on-dst`/`--differ` categories) treats a coverage gap as a *named, non-fatal* status attached to still-usable data, never as grounds to discard or blank out the whole result. The current PDPP design's strict set-equality check (any unexpected OR any missing store invalidates the entire snapshot) has no precedent among the systems surveyed — nothing found treats "you saw one thing you weren't expected to see" as equivalent to "you saw nothing." Kubernetes' own default posture on unrecognized data is `Warn` (accept + flag), not reject, specifically because rejecting breaks existing clients. The fix pattern: the server should union the declared-authority set with what the collector actually reported, mark stores in the authority set but absent from the report as `missing` (named, not fatal), mark stores in the report but absent from the authority set as `unexpected-but-recorded` (log for schema evolution, don't invalidate), and only withhold "fully covered" status — never the underlying 1.29M+ records — when required stores are missing.

2. **A protocol-version field is cheap insurance, not a negotiation protocol.** ⚠️ **[PERSONA-DEPENDENT — RE-EXAMINE, see the correction at the top of this SYNTHESIS. The clause "devices you personally upgrade" assumed a technical self-hoster; PDPP is now a consumer product, so skew is likelier and longer-lived.]** None of the fleet-scale negotiation machinery (Chef's 406-with-min/max, Elastic's enrollment-time rejection) is warranted for a handful of devices you personally upgrade. But recording `collector_protocol_version` (the column already exists but is unused) and having the coverage path branch on it — interpreting an old collector's coverage report against the authority table *that was current when that collector's build shipped*, not today's table — directly fixes the observed failure (a slightly-older build reporting a retired store and omitting two new ones). This is Kubernetes' round-trip guarantee in miniature: don't require the old client to know about new fields, and don't punish it for reporting old ones you've since renamed.

3. **Health state needs three tiers, not two, and the middle tier must use neutral, not alarming, language.** The convergence across Prometheus (stale-NaN vs. bare 0), Kubernetes Conditions (`Unknown` vs. `False`), Nagios's own written intent (UNKNOWN vs. CRITICAL, even though real implementations blur it), and Healthchecks.io's explicit "Late" state is real: distinguish *"we haven't heard from it"* from *"we heard from it and it's broken."* The user-facing-copy evidence (Tailscale's bare "Last seen: <timestamp>", Dropbox's "up to date"/"unable to sync" split) says the middle tier should never use words like "error," "broken," or "failed" — a timestamp alone ("last scan: 6 days ago") does the job better than any status word, because it lets the owner judge severity themselves (a laptop that's been closed for a weekend vs. a service that's been down for a month look identical as a bare "Unknown" but very different as a timestamp).

4. **"Setup" should mean "running," full stop.** Tailscale's install script (`systemctl enable --now`) and the Datadog Agent installer (calling `EnableStable`+`RestartStable` from the installer's own code) both make installation and activation the same event, with zero manual assembly required — this is the strongest, most directly transferable finding for the collector npm package's `setup` command, which currently enrolls the device but installs no scheduler. osquery's partial version (unit pre-installed but requiring a manual `systemctl start` after config exists) is the cautionary middle case: "pre-wired but still manual" reads to the user as broken, not as "almost done." restic's total punt (no scheduler at all, ecosystem wrapper tools exist purely to paper over the gap) is the pattern to actively avoid copying, even though restic is otherwise a strong analog for the coverage-proof question. There is no fancier established name for "installer auto-enables a continuous daemon via systemd" beyond that description — don't invent one for the design doc.

**Genuine conflicts / caveats:** Sentry's exact current protocol-version enforcement page could not be verified from a live official doc (relied on SDK source + forum evidence, flagged accordingly by the fork). Time Machine's phase-based completeness pipeline is inferred from a respected third-party technical teardown, not Apple's own engineering documentation — treat as plausible, not confirmed. Kubernetes' version-skew *enforcement* mechanism (as opposed to the policy itself) could not be confirmed as an active reject; it may be purely a documented support boundary that misbehaves silently outside its window, which is itself a useful negative finding: even Kubernetes, the most rigorous system surveyed, doesn't universally hard-enforce version compatibility at the wire level. Nagios is the one system where documented intent and shipped behavior genuinely diverge (UNKNOWN vs. CRITICAL on timeout) — cited as a caution against assuming a system's docs describe its actual runtime behavior.
