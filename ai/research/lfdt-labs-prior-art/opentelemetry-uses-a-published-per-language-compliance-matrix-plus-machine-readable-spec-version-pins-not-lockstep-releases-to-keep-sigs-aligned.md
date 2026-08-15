---
title: "OpenTelemetry keeps its specification and per-language SIG implementations aligned without lockstep releases through three concrete, checkable mechanisms: a published per-feature compliance matrix distinguishing not-implemented from not-applicable, a stricter multi-language-prototype bar for stabilizing (vs adding) a spec feature, and machine-readable spec-version pins inside SIG build tooling"
date: 2026-08-14
topic: lfdt-labs-prior-art
tags: [opentelemetry, conformance-matrix, spec-versioning, otlp, semantic-conventions, sig-alignment, drift-detection]
status: draft
sources: [otel-compliance-matrix, otel-status-summary, otel-contributing-prototype-bar, otel-go-changelog-spec-pin, otel-python-semconv-pin, otel-versioning-independence, otel-spec-readme-obligation, otel-collector-otlp-pin, otel-proto-maturity-table, otel-prometheus-drift-issue, otel-go-self-audit-issue]
source_session: unknown
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation/conclusions. Skippable. No citations here.
Filename = the claim in kebab-case (greppable), under the matching topic/ dir.
Add one line to INDEX.md when you create this.
-->

## CLAIMS

- OpenTelemetry publishes a standing, version-tagged specification compliance matrix whose stated purpose is cross-language feature tracking: "The following tables show which features are implemented by each OpenTelemetry language implementation," and the file is versioned per release tag (e.g. a `v1.54.0` snapshot exists alongside the `main` branch version). [otel-compliance-matrix]
- The matrix's structure is a per-feature-row, per-language-column table covering 12 language implementations (Go, Java, JS, Python, Ruby, Erlang, PHP, Rust, C++, .NET, Swift, Kotlin) across feature groups including Traces, Baggage, Metrics, Logs, Resource, Context Propagation, Environment Variables, Declarative Configuration, Exporters, SDK Self-Observability, and OpenCensus/OpenTracing compatibility. [otel-compliance-matrix]
- The matrix uses four distinct status symbols rather than a single pass/fail boolean, explicitly distinguishing "not yet implemented" from "not applicable" from "unknown": "`+` means the feature is supported, `-` means it is not supported, `N/A` means the feature is not applicable to the particular language, blank cell means the status of the feature is not known." [otel-compliance-matrix]
- The matrix tracks optionality as a separate dimension from support status, including a special "at-least-one-of" rule for exporter format families: "`X` means the feature is optional, blank means the feature is required, and columns marked with `*` mean that for each type of exporter (e.g. OTLP), implementing at least one of the supported formats is required. Implementing more than one format is optional." [otel-compliance-matrix]
- A separate, higher-level "Specification Status Summary" tracks maturity per-signal (Tracing, Metrics, Baggage, Logging, Profiles) and per-component-type (API, SDK, Protocol, with Collector status noted as matching Protocol status), using a four-stage lifecycle distinct from the matrix's feature-level +/-/N/A notation: Draft ("components are under design, and have not been added to the specification"), Experimental ("components are released and available for beta testing"), Stable ("components are backward compatible and covered under long term support"), Deprecated ("components are stable but may eventually be removed"). [otel-status-summary]
- Adding a new feature at Development/experimental maturity requires only a single working prototype: "For new features at Development maturity level, a prototype is required. It should be a working demonstration in a spec-bound implementation with that SIG's maintainers' support." [otel-contributing-prototype-bar]
- Stabilizing a feature carries a materially stricter, explicitly multi-implementation bar: "Before a feature can be stabilized, prototypes in multiple languages are required. The number is at the discretion of the spec maintainers, though three is typical." [otel-contributing-prototype-bar]
- The specification formally licenses version independence between any given SDK and the spec version it implements — an SDK's own semver is decoupled from the spec version it satisfies by design, not by accident: "Language implementations have version numbers which are independent of the specification they implement. For example, it is fine for v1.8.2 of `opentelemetry-python-api` to implement v1.1.1 of the specification." [otel-versioning-independence]
- The specification repo's own README obligates (not merely suggests) that implementations declare which spec version they satisfy, though it does not mandate a specific mechanism for doing so: "Specific implementations of the specification should specify which version they implement." [otel-spec-readme-obligation]
- opentelemetry-go has historically declared whole-spec-version pins directly in its changelog (e.g., "This release implements the v0.5.0 version of the OpenTelemetry specification") and currently declares semantic-conventions-scoped pins per generated package (e.g., the `go.opentelemetry.io/otel/semconv/v1.20.0` package "contains semantic conventions from the v1.20.0 version of the OpenTelemetry specification"). [otel-go-changelog-spec-pin]
- opentelemetry-python has an actual machine-readable, checked-into-source-control spec-version pin: a `SEMCONV_VERSION` variable inside its code-generation script that must be bumped and re-run to regenerate code against a newer spec release: "freeze the spec version to make SemanticAttributes generation reproducible · SEMCONV_VERSION=1.41.1 · SEMCONV_VERSION_TAG=v$SEMCONV_VERSION," with the package README instructing: "To build against a new release or specific commit of opentelemetry-specification, update the SPEC_VERSION variable in ../scripts/semconv/generate.sh." [otel-python-semconv-pin]
- The OpenTelemetry Collector pins to a specific OTLP protocol version explicitly and separately from both its own release version and the specification's overall version, including a stability designation for that pin: "This code base is currently built against using OTLP protocol v1.10.0, considered Stable." [otel-collector-otlp-pin]
- OTLP (the wire protocol) has its own internal maturity table that is granular per message-group and per-encoding rather than a single OTLP-wide stability flag — common/resource/metrics/trace/logs message groups are Stable for both Binary Protobuf and JSON, while newer groups (profiles, process-context) can sit at Development maturity for one encoding and be marked not-applicable for another, and the repo explicitly warns: "1.0.0 and newer releases from this repository may contain unstable (alpha or beta) components as indicated by the Maturity table." [otel-proto-maturity-table]
- A real drift-and-remediation case is documented in the specification issue tracker for Prometheus/OpenMetrics compatibility, where the compliance matrix was the explicit gating artifact cited to determine whether a spec section could stabilize, and only a minority of SDKs were compliant at the time of tracking: "There are currently three compliant SDK implementations, per the compliance matrix: Go, Java, Rust," with a specific tracked blocking issue: "the Prometheus WG agreed today that #3736 is the primary blocker." [otel-prometheus-drift-issue]
- At least one language SIG runs a standing, proactive self-audit process against the spec text itself rather than waiting for user bug reports — an opentelemetry-go issue opened specifically to check a component against a spec version reads: "Specification: [link to OpenTelemetry specification v1.25.0 for metrics SDK exporters stdout.md]. Create issues for anything not compliant." [otel-go-self-audit-issue]

## SOURCES

**otel-compliance-matrix**
URL: https://github.com/open-telemetry/opentelemetry-specification/blob/main/spec-compliance-matrix.md (versioned snapshots at e.g. .../blob/v1.54.0/spec-compliance-matrix.md)
Accessed: 2026-08-14
Quote: "The following tables show which features are implemented by each OpenTelemetry language implementation." / "`+` means the feature is supported, `-` means it is not supported, `N/A` means the feature is not applicable to the particular language, blank cell means the status of the feature is not known." / "`X` means the feature is optional, blank means the feature is required, and columns marked with `*` mean that for each type of exporter (e.g. OTLP), implementing at least one of the supported formats is required. Implementing more than one format is optional."

**otel-status-summary**
URL: https://opentelemetry.io/docs/specs/status/
Accessed: 2026-08-14
Quote: Draft = "components are under design, and have not been added to the specification." Experimental = "components are released and available for beta testing." Stable = "components are backward compatible and covered under long term support." Deprecated = "components are stable but may eventually be removed." Organized per-signal (Tracing, Metrics, Baggage, Logging, Profiles) tracking API/SDK/Protocol maturity separately, with Collector status noted as matching Protocol status.

**otel-contributing-prototype-bar**
URL: https://github.com/open-telemetry/opentelemetry-specification/blob/main/CONTRIBUTING.md
Accessed: 2026-08-14
Quote: "For new features at Development maturity level, a prototype is required. It should be a working demonstration in a spec-bound implementation with that SIG's maintainers' support." / "Before a feature can be stabilized, prototypes in multiple languages are required. The number is at the discretion of the spec maintainers, though three is typical."

**otel-go-changelog-spec-pin**
URL: https://github.com/open-telemetry/opentelemetry-go/blob/main/CHANGELOG.md
Accessed: 2026-08-14
Quote: "This release implements the v0.5.0 version of the OpenTelemetry specification" (historical whole-spec pin). Current semconv-scoped pin: the `go.opentelemetry.io/otel/semconv/v1.20.0` package "contains semantic conventions from the v1.20.0 version of the OpenTelemetry specification."
Confidence note: retrieved via web-search snippet extraction; a direct WebFetch of the full changelog file returned GitHub UI chrome rather than raw content, so exact current wording should be re-verified with a raw-content fetch before being treated as certain. The underlying mechanism (semconv package versioned to a spec release) is independently corroborated by the opentelemetry-python SEMCONV_VERSION pin (otel-python-semconv-pin).

**otel-python-semconv-pin**
URL: https://github.com/open-telemetry/opentelemetry-python/blob/main/scripts/semconv/generate.sh ; https://github.com/open-telemetry/opentelemetry-python/tree/main/opentelemetry-semantic-conventions
Accessed: 2026-08-14
Quote: "freeze the spec version to make SemanticAttributes generation reproducible · SEMCONV_VERSION=1.41.1 · SEMCONV_VERSION_TAG=v$SEMCONV_VERSION." README: "To build against a new release or specific commit of opentelemetry-specification, update the SPEC_VERSION variable in ../scripts/semconv/generate.sh."

**otel-versioning-independence**
URL: https://opentelemetry.io/docs/specs/otel/versioning-and-stability/
Accessed: 2026-08-14
Quote: "Language implementations have version numbers which are independent of the specification they implement. For example, it is fine for v1.8.2 of `opentelemetry-python-api` to implement v1.1.1 of the specification."

**otel-spec-readme-obligation**
URL: https://github.com/open-telemetry/opentelemetry-specification/blob/main/README.md
Accessed: 2026-08-14
Quote: "Specific implementations of the specification should specify which version they implement." / "Changes to the specification are versioned according to Semantic Versioning 2.0 and described in CHANGELOG.md."

**otel-collector-otlp-pin**
URL: https://github.com/open-telemetry/opentelemetry-collector
Accessed: 2026-08-14
Quote: "This code base is currently built against using OTLP protocol v1.10.0, considered Stable."
Confidence note: found via web search; a direct WebFetch of VERSIONING.md did not surface this exact line, suggesting it lives in README.md or CONTRIBUTING.md rather than VERSIONING.md — exact file location not independently re-confirmed.

**otel-proto-maturity-table**
URL: https://github.com/open-telemetry/opentelemetry-proto
Accessed: 2026-08-14
Quote: "1.0.0 and newer releases from this repository may contain unstable (alpha or beta) components as indicated by the Maturity table." Maturity table (paraphrased from tabular source): common/*, resource/*, metrics/*, trace/*, logs/* = Stable for both Binary Protobuf and JSON; profiles/*, collector/profiles/* = Development for both; processcontext/* = Development for Binary Protobuf, N/A for JSON.

**otel-prometheus-drift-issue**
URL: https://github.com/open-telemetry/opentelemetry-specification/issues/3737
Accessed: 2026-08-14
Quote: "There are currently three compliant SDK implementations, per the compliance matrix: Go, Java, Rust." / "the Prometheus WG agreed today that #3736 is the primary blocker."

**otel-go-self-audit-issue**
URL: https://github.com/open-telemetry/opentelemetry-go/issues/4513
Accessed: 2026-08-14
Quote: "Specification: [link to OpenTelemetry specification v1.25.0 for metrics SDK exporters stdout.md]. Create issues for anything not compliant." (opened September 14, 2023)
Confidence note: WebFetch returned only issue metadata, not the comment thread — cannot confirm the resolution or whether non-compliance was actually found. Cited as evidence of a proactive self-audit PROCESS/pattern existing, not as evidence of a specific resolved drift incident.

## SYNTHESIS

OpenTelemetry's answer to "how does a connector/plugin ecosystem pin against a core spec across versions without lockstep releases" is layered, and the layers matter more individually than as one combined "OTel does X" story:

1. **A published compliance matrix with four-state (not boolean) status per feature per implementation** is the cheapest, most directly transferable piece for `data-connectors`. The distinction between "not implemented," "not applicable," and "unknown" (rather than collapsing to a single yes/no) is exactly the right shape for a connector ecosystem where a connector legitimately may not need certain PDPP capabilities (not applicable) versus simply hasn't gotten to them yet (not implemented) versus nobody has audited it (unknown). PDP-Connect could publish a `data-connectors`-wide matrix (rows = PDPP capabilities/object types, columns = connectors) using the same four-symbol convention, generated from each connector's own capability declaration rather than hand-maintained.

2. **A two-tier bar — one prototype to add a feature as experimental, multiple independent-language prototypes to stabilize it** — is the mechanism that actually prevents the spec from ratifying things nobody can build. This is stricter than GraphQL's "one compliant implementation gates ratification" (see the Matrix/GraphQL/LSP entry) and looser than requiring lockstep releases. For PDP-Connect: a `pdpp` field/capability could go from Draft to Experimental with one prototype (could be `data-connect` itself), but Draft-to-Stable should require evidence from more than one independent `data-connectors` implementation (or, if the connector ecosystem is too young for that, at minimum from a connector NOT authored by the same team that authored `data-connect`) — this is a concrete anti-capture mechanism worth adopting explicitly, not just aspirationally.

3. **Machine-readable version pins living in generator/build scripts** (opentelemetry-python's `SEMCONV_VERSION` variable) are more durable than pins living only in prose (opentelemetry-go's changelog-line convention, which is harder to verify and — per this research — even harder to re-fetch reliably years later). If `data-connectors` needs each connector to declare which `pdpp` schema/capability version it targets, prefer a single checked-in machine-readable field (in the connector manifest, analogous to `SEMCONV_VERSION`) over a changelog sentence — it's greppable, diffable, and CI-checkable in a way prose isn't.

4. **Independent versioning of the wire protocol itself (OTLP) from the "specification" as a whole, with its own internal per-message-group maturity table**, is the most sophisticated piece and probably over-engineered for PDP-Connect's current stage — OTel needed this because OTLP has to stay stable across a much larger, more heterogeneous ecosystem (every observability vendor) than PDP-Connect currently has. Worth knowing it exists as a pattern to grow into (separate "the pdpp object-shape spec" from "the wire-format the connectors and data-connect actually speak"), not worth adopting on day one.

One real gap surfaced by this research, worth being honest about: I could not confirm that OTel has a hard CI rule requiring the compliance matrix to be updated in the same PR as a spec change — the matrix appears to be maintained as a related-but-separate artifact, updated by convention/review vigilance rather than mechanically enforced. This matters because it means even OTel's compliance matrix is not immune to going stale; if PDP-Connect builds an equivalent, it should budget for either a bot/lint check that flags PRs changing `pdpp` capabilities without a corresponding matrix update, or accept the matrix will need periodic manual reconciliation the way OTel's evidently does (the Prometheus drift issue shows the matrix WAS being actively used as a real gating reference at least in that case, so "goes stale forever" is not the failure mode observed — "needs active maintenance" is).
