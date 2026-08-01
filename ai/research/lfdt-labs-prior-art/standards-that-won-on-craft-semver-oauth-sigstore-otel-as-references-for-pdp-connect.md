---
title: "Semver, OAuth, Sigstore, and OpenTelemetry each show a different transferable craft pattern PDP-Connect should copy: semver's one-page prescriptive spec, OAuth's core-RFC-plus-IANA-registry extension model, Sigstore's IETF-draft-format architecture-docs repo kept separate from tool repos, and OpenTelemetry's explicit 'cross-language requirements for all implementations' framing"
date: 2026-07-21
topic: lfdt-labs-prior-art
tags: [standards, governance, spec-design, craft, sigstore, oauth, semver, opentelemetry, lfdt]
status: draft
sources: [semver-site, semver-repo, semver-contributing, oauth-net-site, oauth-rfc6749, oauth-iana-registry, sigstore-architecture-docs, sigstore-tsc-governance, sigstore-protobuf-specs, sigstore-repos, sigstore-docs-overview, otel-spec-site, otel-versioning-stability, otel-spec-repo, otel-contributing]
source_session: 019d920b-c543-7f81-87bd-46159d70bc99
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

### semver.org

- The entire specification is one page (`semver.md`), written in prescriptive RFC-2119-style ("MUST", "SHOULD", "MAY") prose, with no separate "framework" vs "profile" split — the whole standard fits in a single scroll [semver-site].
- semver.org explicitly instructs adopters that compliance requires no registration, approval, or membership: "If all of this sounds desirable, all you need to do to start using Semantic Versioning is to declare that you are doing so and then follow the rules" [semver-site].
- Adoption is driven by a self-propagating citation loop, not a mandate: the FAQ tells adopters to "Link to this website from your README so others know the rules and can benefit from them" [semver-site].
- Authorship is personal and named, not institutional: "The Semantic Versioning specification was originally authored by Tom Preston-Werner, inventor of Gravatar and cofounder of GitHub" — there is no foundation, working group, or corporate steward named on the site [semver-site].
- The spec versions itself under its own rules (stable releases 1.0.0 and 2.0.0, plus RC tags), demonstrating the standard by dogfooding it on its own document [semver-site].
- The repo (`semver/semver`) is minimal: `semver.md` (spec), `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `CITATION.cff`, and a GitHub Actions workflow that republishes to semver.org daily — no separate implementation code lives in the spec repo [semver-repo].
- Changes to the spec go through a formal RFC process modeled on Rust's: trivial fixes (typos, non-semantic wording, translations) merge directly with no RFC; substantive changes require an RFC-labeled PR, open consensus-building in PR comments, revision via new commits (no squashing/rebasing mid-review), a Final Comment Period (FCP) that "lasts ten calendar days, so that it is open for at least 5 business days," and sign-off from all subteam members before FCP opens [semver-contributing].
- The SemVer team that runs this RFC process is explicitly composed of "representatives from major package managers," i.e., governance seats are allocated to the standard's actual downstream implementers, not to a neutral foundation [semver-contributing].
- License is CC BY 3.0 — permissive, attribution-only, no copyleft friction for adopters [semver-site].

### OAuth (IETF RFCs + oauth.net)

- oauth.net is explicitly a community site layered on top of, not a replacement for, the IETF process: specifications "are being developed within the IETF OAuth Working Group," and oauth.net curates/explains rather than defines [oauth-net-site].
- oauth.net organizes specs into clear tiers: Core Framework (RFC 6749/6750), Grant Types & Flows, Token Management, Discovery & Registration, High-Security Extensions (PAR, DPoP, mTLS), Draft Specs (explicitly flagged as unstable — "still active working group items. They will likely change before they are finalized"), Legacy/deprecated (Implicit, Password Grant), and "Related Work from Other Communities" (FAPI, WebAuthn/passkeys) [oauth-net-site].
- Extension governance runs through IANA registries, not through the core RFC text: RFC 6749 establishes registries (e.g., the OAuth Extensions Error registry) with defined fields — error name, usage location, related extension, change controller, defining spec — so new extensions register machine-checkable additions without reopening the core spec [oauth-net-site / oauth-iana-registry].
- The core RFC (6749) was deliberately designed with named extension points, leaving many implementation choices unspecified so implementers and later RFCs (Bearer Tokens 6750, Device Grant 8628, JWT Profile 9068, Token Introspection 7662, Security BCP 9700) could fill them in independently [oauth-iana-registry].
- Community contribution to oauth.net itself is casual and low-friction: pages carry a literal "Missing something? Edit this page" call to action, while protocol-level "questions, suggestions and protocol changes should be discussed on the mailing list" — i.e., site content and protocol content have two different, appropriately-weighted contribution paths [oauth-net-site].
- The bureaucracy lesson: OAuth's core-plus-extension split has produced dozens of overlapping, sometimes contradictory extension RFCs over 15 years (implicit flow deprecated, password grant deprecated, multiple competing PKCE/device/mTLS profiles), which is why oauth.net's curatorial layer — explicitly separating "Draft," "Legacy," and "Related Work from Other Communities" — became necessary just to keep the ecosystem legible to newcomers [oauth-net-site].

### Sigstore

- Sigstore keeps its formal specification in a dedicated repo, `sigstore/architecture-docs`, whose stated purpose is "to store a community-edited, formal description of the architecture of Sigstore," separate from the tool repos (`cosign`, `fulcio`, `rekor`) [sigstore-architecture-docs].
- The architecture-docs repo is explicitly authored in IETF internet-draft format, forked from `martinthomson/i-d-template`, with the stated goal to "provide robust, comprehensive, standardized architecture documents suitable for submission to a standards body, such as the IETF, in the future" — i.e., Sigstore is writing its spec today in the format a future standards body would expect, without yet being ratified by one [sigstore-architecture-docs].
- Contribution to the spec is deliberately lightweight relative to code contribution: "Feedback and improvements are welcome. To participate, simply open an issue or suggest edits to the docs through a pull request," with a social norm (not a hard gate) to "check in on the #architecture-docs channel in the sigstore slack" before big changes [sigstore-architecture-docs].
- Wire-level interoperability is defined in a second, separate spec repo — `sigstore/protobuf-specs` — holding the Protocol Buffer message definitions (e.g., the Sigstore Bundle format) that all language clients (Go, Java, JS, Python, Ruby, Rust) implement against [sigstore-protobuf-specs].
- Extending the protocol itself (e.g., adding a new signing algorithm) requires community consensus recorded as an update to a registry-style spec document before implementation: "you must first get consensus with the community through an update to the algorithm registry specification, and tag client maintainers to make sure that the new algorithm can be supported" — this is the same registry-gated extension pattern as OAuth's IANA registries, but run inside GitHub instead of IANA [sigstore-protobuf-specs].
- Sigstore is governed by a Technical Steering Committee under a written technical charter, with public GitHub-based process: the TSC repo (`sigstore/TSC`) resolves cross-project technical matters, seeks consensus and votes when needed, and runs informally via Slack + GitHub Issues for agenda items [sigstore-tsc-governance].
- Sigstore is an OpenSSF **graduated** project under the Linux Foundation — OpenSSF graduation requires demonstrated "stability, a thriving community, well-defined governance, and adherence to security best practices," and as of graduation the project had grown to "over 1,400 unique contributors" from "91 unique organizations" [sigstore-tsc-governance].
- As an OpenSSF/LF project, Sigstore's governance imposes one non-negotiable constraint across all sub-projects: Apache-2.0 licensing is mandatory, "given that sigstore is a project within the OpenSSF and the charter of the OpenSSF requires that all software projects be Apache-2.0 licensed" [sigstore-tsc-governance].
- The public-facing docs site (docs.sigstore.dev) organizes navigation around the tools first (Cosign, Fulcio, Rekor, language clients, Policy Controller) with the architecture/spec material subordinated as a secondary "Specifications" link under a tool's config section, not surfaced as a top-level peer to the tools — i.e., in practice, day-to-day Sigstore docs IA is implementation-first even though the underlying spec repo is standards-first [sigstore-docs-overview].

### OpenTelemetry

- The specification repo's own README states its authoritative, cross-implementation role directly: "The OpenTelemetry specification describes the cross-language requirements and expectations for all OpenTelemetry implementations" [otel-spec-repo].
- The spec is explicitly structured to stay implementation-agnostic: it is organized into API Specification, SDK Specification, and Data Specification sections, preceded by Principles/Guidelines/Glossary, with no language-specific code in the spec repo itself [otel-spec-site].
- OpenTelemetry's stability policy is written as binding guarantees on the spec, not on any one SDK: "It MUST always be possible to upgrade to the latest minor version of the OpenTelemetry SDK, without creating compilation or runtime errors," and "Instrumentation APIs cannot create a version conflict, ever. Otherwise, the OpenTelemetry API cannot be embedded in widely shared libraries" [otel-versioning-stability].
- Versioning is deliberately decomposed: "The API, SDK, Semantic Conventions, and contrib components have independent version numbers," and each language implementation maintains its own version number independent of the spec's version — the spec version and a given language SDK's version are not expected to match [otel-versioning-stability].
- OpenTelemetry commits to long-term support on the spec itself: major API versions receive a minimum three-year support window following the next major release [otel-versioning-stability].
- Contribution to the spec is explicitly tiered by change size: trivial wording/formatting fixes go straight to PR with no issue; smaller changes require an issue first, acceptance, and (for new features) at least one working prototype, with multiple language implementations required before stabilization; significant changes (new signal types, cross-cutting systems) must go through the formal OTEP (OpenTelemetry Enhancement Proposal) process [otel-contributing].
- Merge bar for the spec is explicitly plural and cross-organizational: a PR needs "two or more approvals from code owners, with approvals from at least two companies," no open change requests, at least two working days elapsed since the last change, and an updated CHANGELOG for non-trivial changes [otel-contributing].
- All OTel spec contributors must sign a CLA before contributing [otel-contributing].

### CRITICAL: spec-repo-vs-implementation-repo separation (the pdpp monorepo split question)

- **semver**: spec and implementations are radically separated by construction. The `semver/semver` repo holds ONLY the spec document (`semver.md`) plus governance/publishing files — zero implementation code. The hundreds of `node-semver`, `python-semver`, etc. libraries that implement it live in entirely separate orgs owned by unrelated maintainers; semver does not ship a "reference implementation" at all [semver-repo].
- **semver spec-repo quietness**: a near-frozen spec repo is treated as the *success condition*, not a failure — the spec has had exactly two stable releases (1.0.0, 2.0.0) across its entire history, and the daily republish workflow is the only routine activity; stability of the document is the whole value proposition [semver-site / semver-repo].
- **OAuth**: maximal separation — the normative spec (RFCs) lives at the IETF/RFC Editor (`rfc-editor.org`, `datatracker.ietf.org`), the community explainer site is a separate property (`oauth.net`), and every implementation (libraries, IdPs) is a separate project owned by separate vendors. No single repo co-locates spec + reference impl; there is no canonical OAuth reference implementation [oauth-net-site / oauth-rfc6749].
- **Sigstore**: the spec is split across its OWN repos, separate from the tool repos. `sigstore/architecture-docs` (the IETF-draft architecture spec) and `sigstore/protobuf-specs` (the wire format) are distinct repositories from `sigstore/cosign` (6.1k stars), `sigstore/fulcio` (863 stars), `sigstore/rekor` (1.2k stars), and the per-language clients (`sigstore-go`, `sigstore-python`, `sigstore-js`, `sigstore-java`, `sigstore-rs`) [sigstore-architecture-docs / sigstore-protobuf-specs / sigstore-repos].
- **Sigstore spec-repo quietness**: the spec repos are much lower-traffic than the tool repos (protobuf-specs ~36 stars vs cosign ~6.1k), yet this is not treated as the spec being "dead" — the spec repos still show recent commits (protobuf-specs updated Jul 20 2026) but at a slower cadence, and the tools carry the day-to-day contributor energy while the spec changes only when the protocol changes [sigstore-repos].
- **OpenTelemetry**: `open-telemetry/opentelemetry-specification` is a standalone repo separate from every SDK repo (`opentelemetry-go`, `opentelemetry-java`, `opentelemetry-python`, `opentelemetry-javascript`, `opentelemetry-rust`); the SDK repos explicitly scope themselves to "components which implement concepts defined in the opentelemetry-specification" — the spec is upstream of, and separate from, all implementations [otel-spec-repo / otel-versioning-stability].
- **OTel spec-repo velocity relative to impls**: implementations version and release on their OWN cadence independent of the spec (each SDK "document[s] which specification version they follow"), so the spec repo naturally moves slower than any active SDK — this decoupling is the stated design goal, not an accident, and prevents the spec's slower pace from bottlenecking implementation velocity [otel-versioning-stability].
- **Naming discipline (all four)**: every one of the four keeps a clean four-way separation between (a) the standard's name, (b) the normative artifact, (c) the community/domain property, and (d) any reference tool. OAuth-the-standard / RFC-6749-the-artifact / oauth.net-the-site / (no canonical tool); SemVer-the-standard / semver.md-the-artifact / semver.org-the-site / (no canonical tool); Sigstore-the-project / architecture-docs+protobuf-specs-the-specs / sigstore.dev-the-site / cosign-the-flagship-tool; OpenTelemetry-the-project / opentelemetry-specification-the-spec / opentelemetry.io-the-site / the per-language SDKs-the-impls. In no case does the flagship TOOL share a name with the SPEC repo, and in no case does the reference/flagship implementation live in the same repo as the normative spec [semver-site / oauth-net-site / sigstore-docs-overview / otel-spec-repo].

## SOURCES

**semver-site**
URL: https://semver.org/
Accessed: 2026-07-21
Quote: "If all of this sounds desirable, all you need to do to start using Semantic Versioning is to declare that you are doing so and then follow the rules. Link to this website from your README so others know the rules and can benefit from them." / "The Semantic Versioning specification was originally authored by Tom Preston-Werner, inventor of Gravatar and cofounder of GitHub."

**semver-repo**
URL: https://github.com/semver/semver
Accessed: 2026-07-21
Quote: Repo contains `semver.md`, `semver.svg`, `README.md`, `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `CITATION.cff`, and `.github/workflows/` that republish to semver.org.

**semver-contributing**
URL: https://raw.githubusercontent.com/semver/semver/master/CONTRIBUTING.md
Accessed: 2026-07-21
Quote: "The FCP lasts ten calendar days, so that it is open for at least 5 business days." Non-RFC changes: "Typo fixes" and "Small wording clarifications that do not impact the semantics of the specification."

**oauth-net-site**
URL: https://oauth.net/2/
Accessed: 2026-07-21
Quote: "[specifications] are being developed within the IETF OAuth Working Group." Draft specs are "still active working group items. They will likely change before they are finalized." "Missing something? Edit this page."

**oauth-rfc6749**
URL: https://www.ietf.org/rfc/rfc6749.html
Accessed: 2026-07-21
Quote: RFC 6749 is a Standards Track document approved by the IESG, defining core OAuth 2.0 roles/flows and establishing IANA registries as extension points.

**oauth-iana-registry**
URL: https://www.iana.org/assignments/oauth-parameters/oauth-parameters.xhtml
Accessed: 2026-07-21
Quote: OAuth Extensions Error registry fields include error name, usage location, related protocol extension, change controller, and defining specification document.

**sigstore-architecture-docs**
URL: https://github.com/sigstore/architecture-docs (README) and https://github.com/sigstore/architecture-docs (repo description: "Specification of sigstore's architecture in an IETF internet-draft format")
Accessed: 2026-07-21
Quote: "The purpose of this repository is to store a community-edited, formal description of the architecture of Sigstore." / forked from "https://github.com/martinthomson/i-d-template/, which provides many features to help in publishing" to "provide robust, comprehensive, standardized architecture documents suitable for submission to a standards body, such as the IETF, in the future." / "Feedback and improvements are welcome. To participate, simply open an issue or suggest edits to the docs through a pull request."

**sigstore-protobuf-specs**
URL: https://github.com/sigstore/protobuf-specs
Accessed: 2026-07-21
Quote: "To add a new algorithm, you must first get consensus with the community through an update to the algorithm registry specification, and tag client maintainers to make sure that the new algorithm can be supported by their ecosystem."

**sigstore-tsc-governance**
URL: https://github.com/sigstore/TSC ; https://blog.sigstore.dev/sigstore-openssf-graduation/
Accessed: 2026-07-21
Quote: TSC "resolv[es] matters or concerns that may arise as set forth in Section 7 of the technical charter." OpenSSF graduation requires "a high level of stability, a thriving community, well-defined governance, and adherence to security best practices." "over 1,400 unique contributors" / "91 unique organizations." "all sigstore projects MUST be licensed under the Apache License, Version 2.0 ... given that sigstore is a project within the OpenSSF and the charter of the OpenSSF requires that all software projects be Apache-2.0 licensed."

**sigstore-repos**
URL: https://github.com/orgs/sigstore/repositories
Accessed: 2026-07-21
Quote: Spec repos are separate from tool repos — protobuf-specs ("Sigstore's Protocol Buffer specifications", 36 stars, last updated Jul 20 2026) vs cosign (6.1k stars, 771 forks), fulcio (863 stars), rekor (1.2k stars), plus per-language clients sigstore-go/-python/-java/-js/-rs.

**sigstore-docs-overview**
URL: https://docs.sigstore.dev/about/overview/
Accessed: 2026-07-21
Quote: Docs nav is organized by tool (Cosign, Certificate Authority/Fulcio, Transparency Log/Rekor, Language Clients, Policy Controller), with a "Specifications" link nested under Cosign's system configuration rather than surfaced as a top-level section.

**otel-spec-site**
URL: https://opentelemetry.io/docs/specs/otel/
Accessed: 2026-07-21
Quote: Spec organized into "API Specification, SDK Specification, and Data Specification," preceded by Overview/Glossary/Principles, using RFC 2119 keywords ("MUST", "MUST NOT", "REQUIRED", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", "OPTIONAL").

**otel-versioning-stability**
URL: https://opentelemetry.io/docs/specs/otel/versioning-and-stability/
Accessed: 2026-07-21
Quote: "It MUST always be possible to upgrade to the latest minor version of the OpenTelemetry SDK, without creating compilation or runtime errors." "Instrumentation APIs cannot create a version conflict, ever." "The API, SDK, Semantic Conventions, and contrib components have independent version numbers."

**otel-spec-repo**
URL: https://github.com/open-telemetry/opentelemetry-specification
Accessed: 2026-07-21
Quote: "The OpenTelemetry specification describes the cross-language requirements and expectations for all OpenTelemetry implementations."

**otel-contributing**
URL: https://github.com/open-telemetry/opentelemetry-specification/blob/main/CONTRIBUTING.md
Accessed: 2026-07-21
Quote: "Clarifications, wording, spelling/grammar, and formatting fixes can be made directly via pull request with no associated issue." Merge bar: "two or more approvals from code owners, with approvals from at least two companies."

## SYNTHESIS

**semver.org → copy the one-page prescriptive spec + zero-permission adoption model.** PDP-Connect's core spec document should be readable start-to-finish in under 10 minutes, written in RFC-2119 imperative prose, with no membership/registration/approval gate to claim conformance — just "declare it and follow the rules." semver's genius is that the *spec itself* is the marketing asset: it needs no separate brand campaign because reading it is the pitch. The named-single-author framing ("originally authored by Tom Preston-Werner") is worth noting but probably wrong for PDP-Connect given LF governance expectations — however, the RFC/FCP change process (borrowed from Rust, run by "representatives from major package managers") is directly transferable: PDP-Connect's spec governance should seat the actual implementers (connector authors, reference-impl maintainers), not an abstract neutral body, and should use the same trivial-vs-RFC-vs-FCP tiering to keep the common case (typo fixes) frictionless while substantive changes get a real consensus gate with a fixed, published timeout (10 calendar days).

**OAuth → copy the core-plus-registry split, and take the bureaucracy lesson as a warning.** The craft lesson: define a small, stable core (RFC 6749-equivalent) with explicit, named extension points, and gate extensions through a lightweight registry (IANA-equivalent — could be a GitHub-hosted registry file/PR process, as Sigstore already does for its algorithm registry) rather than reopening the core spec for every addition. The bureaucracy lesson: without active curation, an extension ecosystem sprawls into contradictory, half-deprecated RFCs that confuse newcomers — which is exactly why oauth.net had to invent a *second*, non-normative site whose entire job is triage (Core / Extensions / Draft / Legacy / Related-but-not-us). PDP-Connect should build that curatorial layer from day one — a living "spec map" page that sorts every extension by status — rather than retrofitting it after the RFC pile gets confusing.

**Sigstore → this is the closest living structural analog and should be studied hardest, but its docs-IA is a cautionary tale, not a model to copy wholesale.** The transferable pattern: keep the *architecture/protocol spec* in its own repo, written in IETF internet-draft format from day one (even pre-ratification) so it is standards-body-submission-ready the moment PDP-Connect wants to pursue formal ratification — this is precisely PDP-Connect's own trajectory as an LFDT lab. Separately, keep wire-format/interoperability definitions (protobuf-specs equivalent) in their own repo so implementers across languages have one canonical machine-checkable contract. Extension governance (new signing algorithms) runs as a lightweight "update the registry spec + tag maintainers for consensus" PR flow — cheap enough to not deter contribution, structured enough to prevent silent fragmentation. Governance itself (TSC + written charter + OpenSSF graduation tiers + mandatory Apache-2.0) is the right LF-project shape to point to when explaining PDP-Connect's own governance to outsiders. The catch: Sigstore's *public docs site* subordinates the spec to the tools (Cosign/Fulcio/Rekor get top billing; "Specifications" is a buried link) — because Sigstore's actual adoption driver is "run cosign," not "read the spec." PDP-Connect, being standard-first rather than tool-first, should invert this: the spec should be the top-level IA citizen, with reference implementations clearly marked as *implementations of* the spec, not the other way around.

**OpenTelemetry → copy the explicit "cross-language requirements for all implementations" framing and the plural-approval merge bar.** OTel's spec repo states its authority in the first sentence of its README — no ambiguity about what's canonical. PDP-Connect's spec repo should open the same way: one sentence stating the spec is the cross-implementation source of truth, with reference implementations declaring which spec version they conform to (OTel's per-language version independence is the right model — spec version and any given reference-impl version should never be forced to match). The merge-bar detail — "two or more approvals... from at least two companies" — is a governance-legitimacy device worth stealing directly: it structurally prevents single-org capture of the spec, which matters enormously for PDP-Connect given the Vana/steward-neutrality tension already on record in the PDPP steering corpus. OTel's tiered contribution process (trivial-PR / issue-first / OTEP-for-big-changes) maps cleanly onto what PDP-Connect needs anyway, and is closer to OTel's than to semver's heavier RFC process — appropriate for a spec that expects many implementers across an ecosystem, not a single-file 2-page doc.

**Overall closest model for PDP-Connect: Sigstore**, because it is the only one of the four that combines (a) a formal spec kept separate from implementations, (b) LF-family governance with a written charter and TSC, (c) a genuine reference-implementation ecosystem across languages, and (d) modern DX/branding on top. Use semver for spec *prose* craft, OAuth for extension-governance *structure* (with its curation lesson as an explicit anti-pattern to avoid), OpenTelemetry for spec-authority *framing* and merge-bar *legitimacy mechanics*, and Sigstore for the overall *repo/governance shape* — but deliberately correct Sigstore's tool-first docs IA into a spec-first one, since PDP-Connect's identity claim ("a standard first") is stronger than Sigstore's was at the same stage.

---

### DECISION: should the reference implementation move OUT of the `pdpp` monorepo? (the owner's #1 question)

**Verdict: YES — split. The evidence is unanimous and one-directional. All four standards keep the normative spec in its own repo, physically separate from every implementation, and not one of the four co-locates a reference implementation with the spec.** The current `pdpp` monorepo (spec-*.md + reference-implementation/ + console + site in one repo) is the *only* structure among the studied precedents that a standard-first project does NOT use. For a project whose entire identity claim is "a standard first," shipping the spec entangled with a fast-moving app is off-brand at the structural level — the repo layout contradicts the positioning.

**Why the four all split (the load-bearing reasons, not just convention):**
1. **The spec must move slower than the impl, on purpose.** OTel's whole versioning design exists so implementations release on their own cadence and the spec version and SDK version are decoupled [otel-versioning-stability]. In a monorepo, the impl's velocity drags the spec's git history and vice versa; you cannot honestly say "the spec is stable" when its repo shows 50 commits/week of app churn.
2. **A quiet spec repo is a FEATURE, not a bug — this directly answers the owner's fear.** semver's spec repo has had two releases ever and that IS the value proposition [semver-site / semver-repo]; Sigstore's protobuf-specs (36 stars, occasional commits) sits calmly next to cosign (6.1k stars, daily churn) and nobody reads the quiet spec repo as "dead" [sigstore-repos]. The correct mental model: **the spec repo looking calm is the standard signaling maturity; the implementation repos carry the day-to-day contributor energy.** The owner's worry ("the spec repo will look dead while all activity is in the impl") is exactly backwards — in every precedent, that asymmetry is the healthy steady state, and the fix for "looks quiet" is a good spec *site* (semver.org energy) plus visible governance activity (RFC/OTEP issues, TSC minutes), NOT dumping app commits into the spec repo to fake a pulse.
3. **Separation is what makes "reference implementation" an honest phrase.** If the spec and the impl live together, there is no observable boundary proving the impl *conforms to* rather than *defines* the spec. OTel's SDK repos scope themselves to "components which implement concepts defined in the opentelemetry-specification" [otel-spec-repo] — that upstream/downstream relationship is only legible when they are separate repos with the impl declaring which spec version it targets.

**Recommended target structure:**
- **`pdpp` (or renamed — see below) = spec-only.** Holds the normative `spec-*.md`, a CONTRIBUTING with an RFC/OTEP-style change process, governance docs (charter/TSC once LFDT-graduated), and the extension registry. This is the "star" repo — the one the .org domain points at. Model: `semver/semver` + `open-telemetry/opentelemetry-specification`.
- **A separate impl repo (e.g. `pdp-connect-reference` or `<name>-reference`)** for the console + reference collector/connector runtime + site. Model: `sigstore/cosign`. It declares the spec version it conforms to. It can move as fast as it wants without touching the spec's history.
- **Optionally a third `*-schemas` / `*-protocol` repo** for the machine-checkable wire contract (manifest schema, connector manifest format) — the `sigstore/protobuf-specs` role — if the wire format wants an independent version from the prose spec. For PDP-Connect this may be premature; fold it into the spec repo until the schema needs its own release cadence.

**Cost of splitting (be honest):** the real cost is sync friction — a spec change that requires a coordinated impl change now spans two repos/PRs instead of one atomic commit. The four precedents accept this deliberately and manage it with *conformance versioning* (impl pins a spec version) rather than atomic monorepo commits. Given PDP-Connect is early and most recent work is in the impl, the migration cost is low NOW and rises the longer the monorepo persists — split sooner rather than later. Do it before the LFDT-lab neutralization/graduation work, so the clean spec repo is what enters governance.

**Naming (the owner's second question):** the precedents enforce a strict rule — **the standard, the spec artifact, the domain, and the flagship tool must be four distinct names, and the flagship implementation must NEVER share its name with the spec repo** [semver-site / oauth-net-site / sigstore-docs-overview / otel-spec-repo]. The current `pdpp` name fails this on two counts: it is simultaneously the spec repo, the app, and the informal project name, and "pdpp" (Personal Data Polyfill Project) is an implementation-flavored, acronym-opaque name — a "polyfill" is by definition a temporary implementation shim, which is the opposite of the permanent-standard energy of "semver"/"OAuth"/"OpenTelemetry." Recommendation: pick a standard name that reads like a protocol, not a project (the `PDP-Connect` direction already in play is far better than `pdpp` — it names a *connection standard*, echoing OAuth/OpenID Connect). Then allocate cleanly, e.g.: **standard = "PDP-Connect"; spec repo = `pdp-connect` (spec-only, at pdp-connect.org or similar); reference impl = `pdp-connect-reference` (or a distinct product name the way `cosign` ≠ Sigstore); domain/community site = the standard's .org rendering the spec as the top-level IA citizen.** Retire "pdpp"/"polyfill" from the outward-facing standard name; a polyfill framing can survive internally as *why* the reference impl exists, but it should not be the name of the standard.
