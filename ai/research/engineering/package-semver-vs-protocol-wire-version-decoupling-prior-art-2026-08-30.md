---
title: "Every mature ecosystem studied (protobuf, Kubernetes client-go, OpenAPI, Stripe, Plaid) decouples the package/SDK semver from the wire/spec/protocol version identifier, and semantic-release's own maintainers explicitly recommend against publishing 0.x releases at all in favor of a 1.0.0-prerelease channel"
date: 2026-08-30
topic: engineering
tags: [semver, protocol-versioning, semantic-release, protobuf, kubernetes, openapi, stripe, plaid, pdp-connect]
status: draft
sources: [protobuf-version-support, protobuf-editions-overview, k8s-client-go-readme, k8s-client-go-pkgdoc, openapi-spec-3-1-0, openapi-version-discussion-2645, stripe-sdk-versioning-policy, stripe-api-versioning-blog, plaid-api-versioning-docs, plaid-node-readme, semrel-issue-919, semrel-issue-837, semrel-discussion-1916, semver-org-site]
source_session: 714989e4-d512-421b-8ec9-cc514a81eac5
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

### Protocol Buffers / gRPC

- Protobuf maintains a hard separation between the release/runtime library version (SemVer, e.g. `34.1`) and the language "edition" (proto2, proto3, `edition = "2024"`, `edition = "2026"`) that governs `.proto` file syntax and generator behavior — these are two independent version axes on the same artifact [protobuf-version-support].
- The binary wire format is a stability invariant that does not change across editions or releases: "using Editions won't alter or modify any existing wire formats or encodings" [protobuf-editions-overview].
- Protobuf explicitly decoupled release versioning from edition/language versioning starting with the 21.x release in 2022, and treats enforcement of documented support-policy drops (e.g. dropping an EOL language version) as *not* a breaking change requiring a major bump [protobuf-version-support].

### Kubernetes client-go

- client-go's own README states its version numbers are unrelated to Kubernetes cluster version numbers: users should consult a separate compatibility matrix, not infer compatibility from the client-go semver number itself [k8s-client-go-readme].
- client-go nonetheless follows real semver for its own public Go API surface: "backwards-incompatible changes won't be made without incrementing the major version number," where incompatibility is defined either as a change to client-go's own public interface OR a change that breaks compatibility with otherwise-supported Kubernetes cluster versions [k8s-client-go-readme].
- Since Kubernetes v1.17.0, client-go publishes a second, parallel tag scheme (`kubernetes-1.17.0`) synced to the Kubernetes release purely so users can find the matching commit — this is explicitly a lookup convenience, not a compatibility claim, and coexists with client-go's independent `v0.x.y` semver tags on the exact same commits [k8s-client-go-pkgdoc].

### OpenAPI Specification

- The `openapi` field's `major.minor.patch` string is a semver-shaped value, but the maintainers explicitly weakened its semantics starting at 3.1.0: "we did drop semver in v3.1.0... We still subscribe to the definitions of major, minor, and patch versions/releases, but we class some theoretically-breaking changes as minor, because of their limited impact" [openapi-version-discussion-2645].
- The spec itself instructs tooling to ignore the patch component entirely and treat all patch values within a minor as equivalent: "tooling which supports OAS 3.1 SHOULD be compatible with all OAS 3.1.* versions" [openapi-spec-3-1-0].
- This version number lives inside the spec document (`openapi: 3.1.0`) and has no defined relationship whatsoever to the semver version of any tool that parses or generates against it (openapi-generator, Swagger, etc.) — tools declare their own independent package version and separately declare which spec version(s) they support [openapi-spec-3-1-0].

### Stripe SDKs

- Stripe runs two fully independent versioning schemes on the same SDK package: the npm/gem/etc. package follows ordinary SemVer for library code changes, while the API itself is versioned by a date-plus-codename string (e.g. `2026-07-29.dahlia`), sent via request headers, not by the package's own version [stripe-sdk-versioning-policy].
- The API version identifier is NOT read from the SDK's package.json — server-side SDKs pin to "the API version that was current when the SDK was released," implying a hardcoded default baked into SDK source at release time, and organization-level/`/v2` API keys explicitly require sending this identifier as an explicit `Stripe-Version` HTTP header on every request [stripe-sdk-versioning-policy].
- Stripe's own guidance explicitly discourages using the SDK's semver to reason about API compatibility in typed languages: "do not set a different API version for strongly-typed languages because response objects might not match the strong types in the SDK — instead, update the SDK to target a new API version" [stripe-sdk-versioning-policy].
- The one place Stripe *does* couple SDK version to API version tightly is Stripe.js (frontend): "major npm versions correspond to specific Stripe.js versions... you can't override this association" — but this is the frontend exception, not the general server-SDK pattern [stripe-sdk-versioning-policy].

### Plaid SDKs

- Plaid runs the identical two-axis pattern as Stripe: the `Plaid-Version` HTTP header carries a date-based API version string (e.g. `2020-09-14`), fully independent of the SDK package's own SemVer number (e.g. Go SDK `v1.0.0`) [plaid-api-versioning-docs].
- Plaid's own docs state the intended coupling mechanism explicitly: "If you're using one of the Plaid client libraries, they should all be pinned to the latest version of the API at the time when they were released... Plaid added templating to force this value to the latest API version for all libraries" — i.e., the API version constant is templated into SDK source at release time, not derived from package.json [plaid-api-versioning-docs].
- Each Plaid SDK release supports exactly one pinned API version, and upgrading to a new API version means shipping a new SDK release — the API version is not user-settable independently of which SDK release you install, for the officially supported path [plaid-node-readme].

### semantic-release: 0.x / initial-version philosophy

- semantic-release hardcodes the very first release of any repo to `1.0.0` regardless of commit history — "There is no previous release, the next release version is 1.0.0" — this is confirmed, longstanding, and explicitly not configurable via a `firstVersion` option despite repeated feature requests [semrel-issue-919, semrel-issue-837].
- Multiple users have filed complaints that this contradicts semver.org's own stated FAQ guidance to start initial development at `0.1.0`, and semantic-release maintainers have not changed this default despite the friction [semrel-issue-837].
- semantic-release core maintainer gr2m's stated recommendation for teams uncomfortable with 0.x churn is not "let breaking changes stay within 0.x" but rather to skip 0.x releases entirely: "I wouldn't publish any 0.x releases. I'd instead use a `beta` release channel to release `1.0.0-beta.x` until you are happy with the result" [semrel-discussion-1916].
- Once a real prior release/tag exists in the 0.x series, subsequent breaking-change commits are processed by normal commit-analyzer rules, which is where the observed jump straight from `0.x.y` to `1.0.0`/`1.0.0-rc.x` on a breaking-change commit originates in practice — this matches semver.org's own text that 0.y.z is officially unstable and "anything MAY change at any time," so semver.org places no spec-level obligation on tooling to keep breaking changes inside the 0.x range [semver-org-site].

## SOURCES

**protobuf-version-support**
URL: https://protobuf.dev/support/version-support/
Accessed: 2026-08-30
Quote: "Protobuf uses SemVer conventions... a decoupled versioning model introduced in the 21.x release."

**protobuf-editions-overview**
URL: https://protobuf.dev/editions/overview/
Accessed: 2026-08-30
Quote: "Using Editions won't alter or modify any existing wire formats or encodings."

**k8s-client-go-readme**
URL: https://github.com/kubernetes/client-go
Accessed: 2026-08-30
Quote: "client-go version numbers are unrelated to Kubernetes version numbers... backwards-incompatible changes won't be made without incrementing the major version number."

**k8s-client-go-pkgdoc**
URL: https://pkg.go.dev/k8s.io/client-go
Accessed: 2026-08-30
Quote: "Since Kubernetes v1.17.0, ... matching semver v0.x.y tags are created for each v1.x.y Kubernetes release."

**openapi-spec-3-1-0**
URL: https://spec.openapis.org/oas/v3.1.0.html
Accessed: 2026-08-30
Quote: "tooling which supports OAS 3.1 SHOULD be compatible with all OAS 3.1.* versions."

**openapi-version-discussion-2645**
URL: https://github.com/OAI/OpenAPI-Specification/discussions/2645
Accessed: 2026-08-30
Quote: "we did drop semver in v3.1.0... we class some theoretically-breaking changes as minor, because of their limited impact."

**stripe-sdk-versioning-policy**
URL: https://docs.stripe.com/sdks/versioning
Accessed: 2026-08-30
Quote: "When using our server-side SDKs, your API calls to Stripe use the API version that was current when the SDK was released." / "do not set a different API version for strongly-typed languages."

**stripe-api-versioning-blog**
URL: https://averagedevs.com/blog/stripe-api-versioning-explained
Accessed: 2026-08-30
Quote: "SDK SemVer for code, API epochs for server behavior."

**plaid-api-versioning-docs**
URL: https://plaid.com/docs/api/versioning/
Accessed: 2026-08-30
Quote: "Plaid added templating to force this value to the latest API version for all libraries."

**plaid-node-readme**
URL: https://github.com/plaid/plaid-node
Accessed: 2026-08-30
Quote: Library versions follow SemVer; each release is pinned to a specific Plaid API version.

**semrel-issue-919**
URL: https://github.com/semantic-release/semantic-release/issues/919
Accessed: 2026-08-30
Quote: "There is no previous release, the next release version is 1.0.0."

**semrel-issue-837**
URL: https://github.com/semantic-release/semantic-release/issues/837
Accessed: 2026-08-30
Quote: Users note semver.org's FAQ recommends starting at 0.1.0; semantic-release hardcodes 1.0.0 and has no `firstVersion` option.

**semrel-discussion-1916**
URL: https://github.com/semantic-release/semantic-release/discussions/1916
Accessed: 2026-08-30
Quote: "I wouldn't publish any 0.x releases. I'd instead use a `beta` release channel to release `1.0.0-beta.x` until you are happy with the result."

**semver-org-site**
URL: https://semver.org/
Accessed: 2026-08-30
Quote: "Major version zero (0.y.z) is for initial development. Anything MAY change at any time. The public API SHOULD NOT be considered stable."

## SYNTHESIS

**The pattern is unanimous across every mature ecosystem studied: package/SDK semver and protocol/wire/spec version are always two independent identifiers, never one number wearing two hats.** Protobuf keeps wire format stable across both release versions and editions. client-go's semver is explicitly declared unrelated to the Kubernetes server version it targets, with a separate compatibility matrix as the source of truth. OpenAPI's own maintainers admit they don't even enforce real semver semantics on the `openapi:` field itself — patch is ignored by design, and even some "minor" bumps are actually breaking. Stripe and Plaid are the closest structural analogs to PDP-Connect's connector-protocol/local-collector pairing (a spec-shaped wire contract distributed via an SDK-shaped npm package) and both run the identical two-axis design: a date-coded API/protocol version traveling as a request header or SDK-internal constant, fully decoupled from the npm package's ordinary SemVer number, which tracks library code changes only. In no case examined does a real production system gate wire-level compatibility on `package.json`'s `version` field.

**The mechanism that actually enforces compatibility, in every case, is a constant baked into the SDK/client at build/release time (Plaid's "templating," Stripe's SDK-release-time pin, protobuf's wire-format invariant), not the npm/pip/go module's own semver number.** This is exactly the shape of `@pdpp/collector-runtime`'s existing `COLLECTOR_PROTOCOL_VERSION = "1"` constant found in the PDP-Connect data-connect repo this session — PDP-Connect has already independently arrived at the industry-standard pattern for one of its two protocol packages (collector-runtime↔local-collector), it just hasn't yet applied the same pattern to the other (connector-protocol).

**semantic-release's own maintainers do not endorse "let breaking-change commits march a 0.x package to 1.0.0 automatically" as a first-class supported workflow — their explicit recommendation is the opposite: skip 0.x entirely and use a `1.0.0-rc.x`/`1.0.0-beta.x` prerelease channel from the start.** This means the tool computing `1.0.0-rc.1` when it saw a real `!`-marked breaking-change commit on a 0.0.1-published package is semantic-release doing exactly what its own maintainers say is correct practice for a pre-stable package under active breaking change — it is not a bug or a surprising edge case, it is the tool's designed behavior once real commit history exists (the "hardcoded 1.0.0" quirk only fires on a repo's very first-ever release with zero prior tags, which does not apply here since `0.0.1` is already published). Fighting that computed version by hand-editing `package.json` to `0.0.2` is fighting the tool's own designed semantics, not correcting a defect in it — and is exactly what produced the `ETARGET`/version-drift failure observed directly in PDP-Connect's own release pipeline this session (package.json said `0.0.2`, npm registry's actual last-published version was `0.0.1`, and `npm version --allow-same-version` could not resolve the gap).

**Bottom line for the PDP-Connect connector-protocol/0.0.2 question this research was commissioned to answer:** every precedent studied — plus PDP-Connect's own already-shipped collector-runtime pattern, plus today's own pipeline failure — points to the same conclusion. Let semantic-release own the package version uncontested (even if that means crossing into `1.0.0-rc.x`), and give the wire/protocol compatibility boundary its own explicit constant (mirroring `COLLECTOR_PROTOCOL_VERSION`), asserted at runtime, independent of `package.json`'s version field. Manually pinning the npm package version to `0.0.2` to "mean" protocol version 2 is the one design no mature ecosystem studied actually uses in production, and it is already empirically broken in this exact repo.
