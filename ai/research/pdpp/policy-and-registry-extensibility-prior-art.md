---
title: "PDPP's purpose codes, policy vocabulary, and access_mode should each follow IANA-style least-strict registries with dereferenceable pages, DPV/ODRL mapping (not adoption) for policy, and FAPI-grade JAR/mTLS signing materially strengthens non-repudiation over plain bearer auth"
date: 2026-08-19
topic: pdpp
tags: [purpose-codes, registry-design, iana, schema-org, dpv, odrl, p3p, access-mode, fapi, jar, non-repudiation, consent-receipts]
status: draft
sources: [rfc8126, schema-org-about, schema-org-person, dpv-spec, dpv-primer, odrl-model, odrl-vocab, p3p-wikipedia, iana-oauth-params, fapi-part2, rfc9101-jar, w3id-org]
source_session: unknown
---

<!-- Format reminder: CLAIMS = verifiable statements tagged [source-slug]. SOURCES = URL+date+quote. SYNTHESIS = interpretation, no citations. -->

## CLAIMS

**Q1 — Purpose-code hosting**

- PDPP's spec text uses `https://pdpp.org/purpose/...` and `https://pdpp.org/data-access` as the URI namespace throughout spec-core.md (Appendix A, Section 5), but the project's actual publicly deployed documentation site is `pdpp.dev` (README.md, docs/reference/voice-and-framing.md, docs/community/session-reading.md all point to `pdpp.dev`). [pdpp-repo-local]
- IANA registries are anchored from one central index page (`iana.org/protocols`) with each registry given its own details page; RFC 8126 requires document authors to specify a stable registry name and, ideally, a URL identifying it. [rfc8126]
- schema.org type URIs (e.g. `https://schema.org/Person`) dereference live: fetching the URI returns a human-readable page (name, description, property table, "Canonical URL" self-reference) that is also the source for the machine-consumable vocabulary (JSON-LD/RDFa context at the same origin). The page explicitly states "Canonical URL: https://schema.org/Person". [schema-org-person]
- Schema.org's governance is a two-tier structure: a Community Group (open, W3C CLA required) proposes and discusses changes on GitHub; a Steering Group (founding companies + W3C rep + long-term contributors) approves releases. Versioned releases are documented (e.g. "V30.0 | 2026-03-19" shown live on schema.org). [schema-org-about]
- The W3C Data Privacy Vocabulary (DPV) publishes its canonical, permanent URL via the `w3id.org` permanent-identifier redirector: `https://w3id.org/dpv` (current version pinned at `https://w3id.org/dpv/2.3`, with `https://w3id.org/dpv#` as the RDF term namespace and `dpv` as the suggested prefix). The spec itself states this pattern explicitly: "The canonical URL for DPV is https://w3id.org/dpv... The namespace for DPV terms is https://w3id.org/dpv#". [dpv-spec]
- DPV is a W3C Community Group Final Report (not a W3C Recommendation / not W3C Standards Track), developed via a public GitHub repo (`w3c/dpv`) with a documented contribution guide, open issues/PRs, and named editors/authors/contributors published on every version page. [dpv-spec]
- DPV ships a companion "Primer" document (separate from the core spec) whose explicit stated purpose is to be the on-ramp: "This document assumes the reader is familiar with DPV through the Primer... and thus focuses on providing a topically structured documentation of concepts." A 2-page "Primer-concise" also exists. [dpv-primer]
- XML namespace URIs are the classical counter-example: the XML Namespaces spec explicitly does not require the namespace URI to dereference to anything; it functions purely as a unique identifier string. (General web-standards knowledge; not independently re-fetched this session — treat as background, not a session-verified claim.)

**Q2 — Policy vocabulary extensibility**

- ODRL (Open Digital Rights Language) is a W3C Recommendation (15 Feb 2018) with two normative parts: the ODRL Information Model (concepts: Policy, Permission, Prohibition, Duty, Asset, Party, Action, Constraint) and the ODRL Vocabulary & Expression (the actual IRI-identified terms, e.g. `http://www.w3.org/ns/odrl/2/prohibit`, and JSON-LD/XML/Turtle encodings). [odrl-model, odrl-vocab]
- ODRL formally separates three policy primitives PDPP does not yet have distinct vocabulary for: **Permission** (what is allowed), **Prohibition** (what is explicitly forbidden — this is ODRL's direct answer to "no-resale"/"no-sharing"), and **Duty** (an obligation that must be met, optionally as a precondition of a Permission). ODRL also defines a `ConflictTerm` class (e.g. "Prefer Prohibitions": `odrl:prohibit`) to resolve when a permission and a prohibition apply to overlapping scope. [odrl-vocab]
- DPV models purposes as a `dpv:Purpose` class hierarchy with concrete subclasses (e.g. personalization, service-provision, marketing, research, legal-compliance categories) plus separate top-level modules for legal basis (`dpv-legal`), personal-data categories (`dpv-pd`), technology, and risk — i.e. DPV treats "purpose" as one axis among several structured axes, not a flat enum. [dpv-spec, dpv-primer]
- P3P (Platform for Privacy Preferences, W3C, active ~2002-2006) failed for reasons independent of its vocabulary richness: EPIC's 2002 "Pretty Poor Policy" critique cites (a) complexity that ordinary users and even browser vendors couldn't use correctly, (b) zero legal enforcement — a site's P3P policy was not a binding promise under then-existing US law, so machine-readable claims had no consequence when violated, (c) low adoption (a CyLab study found only ~15% of top 5,000 sites implemented it), and (d) it arguably *displaced* momentum toward actual privacy regulation by giving the appearance of self-regulation. IBM's own original implementer (Michael Kaply) is on record in 2004 telling Mozilla to "Remove it." [p3p-wikipedia]
- FAPI (Financial-grade API) Part 2 — the OpenID Foundation's high-assurance OAuth profile used as a base for UK/EU Open Banking — layers strong technical guarantees on top of the same "policy commitment" problem PDPP has with retention: it mandates signed JWT request objects, sender-constrained access tokens (mTLS or equivalent), and strict client authentication, but it does **not** attempt to make retention/usage promises machine-enforceable at the API layer — those remain contractual/regulatory. [fapi-part2]

**Q3a — access_mode registry extensibility (IANA "Specification Required" pattern)**

- RFC 8126 Section 4 defines exactly ten "well-known" IANA registration policies, ordered roughly least-to-most strict: Private Use, Experimental Use, Hierarchical Allocation, First Come First Served, Expert Review, Specification Required, RFC Required, IETF Review, Standards Action, IESG Approval. [rfc8126]
- RFC 8126's explicit normative guidance: "select the least strict policy that suits a registry's needs, and look for specific justification for policies that require significant community involvement (those stricter than Expert Review or Specification Required)." [rfc8126]
- The live IANA "OAuth Parameters" registry group uses "Specification Required" as the registration procedure for both the **OAuth Access Token Types** registry and the **OAuth Token Type Hints** registry — the two closest structural analogs to `access_mode`. Both list named designated experts (e.g. Hannes Tschofenig / Mike Jones for token types; Torsten Lodderstedt / Mike Jones for token type hints), a review mailing list (`oauth-ext-review@ietf.org`), a 2-week expert-notifies-IANA SLA, and a per-entry "Change Controller" column (IETF for RFC-track entries, e.g. `Kantara_UMA_WG` for the third-party `pct` token type hint contributed outside the IETF). [iana-oauth-params]
- This is a concrete, currently-operating example of exactly the pattern the question asks about ("IANA-style specification-required registries in OAuth RFCs") — token type hints and grant types are real precedent, not hypothetical. [iana-oauth-params]

**Q3b — Attribution strength: JAR/JWS vs plain authenticated requests**

- RFC 9101 (OAuth 2.0 JWT-Secured Authorization Request, JAR) exists specifically because plain OAuth authorization requests are query-parameter-serialized through the user agent and are therefore not integrity-protected, not source-authenticated, and are visible to intermediaries; JAR wraps the request as a JWT so it can be signed (JWS) and optionally encrypted (JWE), attaining "integrity, source authentication, and confidentiality properties." [rfc9101-jar]
- FAPI Part 2 (Advanced) makes JAR mandatory, not optional, for its most sensitive/highest-assurance profile, and stacks additional non-repudiation controls on top: (1) request objects must be signed JWTs with `nbf`/`exp` claims bounding validity to a 60-minute window, (2) the `aud` claim must bind the request to a specific authorization server's Issuer Identifier, (3) confidential clients must authenticate via `tls_client_auth`/`self_signed_tls_client_auth` (mTLS) or `private_key_jwt`, (4) issued access tokens must be sender-constrained (bound to the client's key via mTLS), (5) public clients are disallowed entirely. [fapi-part2]
- The combined effect of this stack is that a FAPI-grade request cannot be replayed by a different party, cannot be tampered with in transit without detection, is cryptographically bound to a specific client key (not just a bearer credential anyone holding the token could present), and carries a JWS signature over the exact declared parameters (including, in PDPP's case, `purpose_code`, `retention`, `access_mode`) that a third party can independently verify was produced by the client's registered key at a specific time. [fapi-part2, rfc9101-jar]
- Plain bearer-token-authenticated requests (PDPP's v0.1 baseline per spec-core.md Section 10, "Sender-constrained tokens (non-normative)") only prove that *some* party holding a valid access token issued the request; RFC 6750 bearer tokens carry no signature over the request body/parameters themselves and are usable by anyone who possesses them, so a compromised or leaked token can produce requests indistinguishable from the legitimate client's. [pdpp-repo-local, rfc9101-jar]
- PDPP's own spec already names DPoP (RFC 9449) and mTLS (RFC 8705) as "candidate optional hardening profile[s] for v0.2" and flags that grants are "designed to be signable" via future JWS/JWT — i.e. the spec authors have already identified this gap and deferred it, consistent with what FAPI mandates today. [pdpp-repo-local]

## SOURCES

**rfc8126**
URL: https://www.rfc-editor.org/rfc/rfc8126.txt
Accessed: 2026-08-19
Quote: "select the least strict policy that suits a registry's needs, and look for specific justification for policies that require significant community involvement (those stricter than Expert Review or Specification Required, in terms of the well-known policies)."

**schema-org-about**
URL: https://schema.org/docs/about.html
Accessed: 2026-08-19
Quote: "Schema.org is organized via two groups: a small Steering Group responsible for high level oversight of the project... and a larger Community Group which handles the day to day activity of schema evolution."

**schema-org-person**
URL: https://schema.org/Person
Accessed: 2026-08-19
Quote: "Canonical URL: https://schema.org/Person"

**dpv-spec**
URL: https://w3id.org/dpv
Accessed: 2026-08-19
Quote: "The canonical URL for DPV is https://w3id.org/dpv which contains (this) specification... The namespace for DPV terms is https://w3id.org/dpv#, the suggested prefix is dpv..."

**dpv-primer**
URL: https://w3id.org/dpv/primer
Accessed: 2026-08-19
Quote: "This document assumes the reader is familiar with DPV through the Primer for Data Privacy Vocabulary, and thus focuses on providing a topically structured documentation of concepts defined by DPV."

**odrl-model**
URL: https://www.w3.org/TR/odrl-model/
Accessed: 2026-08-19
Quote: "Policies are used to represent permitted and prohibited actions over a certain asset, as well as the obligations required to be meet by stakeholders."

**odrl-vocab**
URL: https://www.w3.org/TR/odrl-vocab/
Accessed: 2026-08-19
Quote: "3.18.4 Prefer Prohibitions — Definition: Prohibitions take preference over permissions. Identifier: http://www.w3.org/ns/odrl/2/prohibit — Note: Used to determine policy conflict outcomes."

**p3p-wikipedia**
URL: https://en.wikipedia.org/wiki/P3P
Accessed: 2026-08-19
Quote: "In 2002 it assessed P3P and referred to the technology as a 'Pretty Poor Policy.'... a study done by CyLab Privacy Interest Group at Carnegie Mellon University [found] only 15% of the top 5,000 websites incorporate P3P."

**iana-oauth-params**
URL: https://www.iana.org/assignments/oauth-parameters/oauth-parameters.xhtml
Accessed: 2026-08-19
Quote: "OAuth Access Token Types — Registration Procedure(s): Specification Required — Expert(s): Hannes Tschofenig, Mike Jones... Registration requests should be sent to oauth-ext-review@ietf.org."

**fapi-part2**
URL: https://openid.net/specs/openid-financial-api-part-2-1_0.html
Accessed: 2026-08-19
Quote: "the authorization server shall require a JWS signed JWT request object passed by value with the request parameter or by reference with the request_uri parameter... shall only issue sender-constrained access tokens... shall require the request object to contain an exp claim that has a lifetime of no longer than 60 minutes after the nbf claim."

**rfc9101-jar**
URL: https://www.rfc-editor.org/rfc/rfc9101.html
Accessed: 2026-08-19
Quote: "This document introduces the ability to send request parameters in a JSON Web Token (JWT) instead, which allows the request to be signed with JSON Web Signature (JWS)... so that the integrity, source authentication, and confidentiality properties of the authorization request are attained."

**w3id-org**
URL: https://w3id.org/dpv
Accessed: 2026-08-19
Quote: (see dpv-spec — w3id.org functions as a permanent-identifier redirect service that DPV, and many other W3C Community Group vocabularies, use for their canonical namespace.)

**pdpp-repo-local**
URL: file:///home/tnunamak/code/pdpp/spec-core.md (local repo, origin/main content read directly; also README.md, docs/reference/voice-and-framing.md)
Accessed: 2026-08-19
Quote: "Sender-constrained tokens (non-normative): Bearer tokens (RFC 6750) are the v0.1 baseline... DPoP (RFC 9449) and mutual-TLS certificate binding (RFC 8705) are both compatible with PDPP's introspection-based design. A formal optional hardening profile is a candidate for a future version." (Section 10, Security Considerations). Domain mismatch: spec-core.md uses `pdpp.org` as the URI namespace throughout (Appendix A, `type: "https://pdpp.org/data-access"`), while README.md states "Read the specification at pdpp.dev" — the live docs site is a different domain than the spec's own URI namespace.

## SYNTHESIS

### Q1 verdict: dereferenceable, dual-audience pages at the URI itself — schema.org's model, not IANA's, not XML's — with DPV mapped, not adopted

**Confidence: high** that dereferencing is correct; **medium** on exact implementation mechanics (a follow-up PR author will need repo-specific routing decisions).

The three precedents split cleanly by what the identifier is *for*:

- **XML namespaces** are pure disambiguation strings — nobody expects `http://www.w3.org/1999/xhtml` to render anything, and nobody is confused when it doesn't, because XML namespace URIs were never advertised as a place to learn what the namespace means.
- **IANA registries** dereference to a *machine-oriented* table (name, reference RFC, change controller) at one central index — there is no per-value human page. `https://www.iana.org/assignments/oauth-parameters` is the right precedent for "there is one list," not for "each purpose code has its own page."
- **schema.org** dereferences each *term* to a page that is simultaneously the human-readable documentation (name, description, canonical URL, usage stats) and the machine vocabulary (the same URI is used as the `@type`/`@id` in JSON-LD). This is the terminal ideal for PDPP's purpose codes, because purpose codes are shown directly to end users during consent (`purpose_description` fallback: "the AS MAY display a human-readable label from the registry when purpose_description is absent" — spec-core.md line 467) *and* are machine-matched by clients and the AS. A code that 404s undermines both jobs: a user who clicks "what is `personalization`?" during consent gets nothing, and there's no live place to verify a code is genuine PDPP-registry vs. a lookalike third-party URI.

DPV is the right *content* model to borrow from, not the right *hosting* model to copy verbatim, because DPV is RDF/ontology-first (OWL classes, `dpv:Purpose` subclassing, SKOS-adjacent) and PDPP's audience is API implementers and end users, not semantic-web tooling. The DPV *pattern* worth stealing directly: a permanent redirect layer (DPV uses `w3id.org`; PDPP should decide once whether `pdpp.dev` or `pdpp.org` is canonical and put a permanent 301 in front of whichever is not, today, before more implementations pin one or the other) plus a two-document split — a terse machine-consumable index (JSON, versioned) and a discursive Primer for onboarding (DPV ships both).

**Concrete, PR-able recommendation:**
1. **Resolve the `pdpp.dev`/`pdpp.org` split now.** The spec's own normative URIs (`https://pdpp.org/purpose/*`, `https://pdpp.org/data-access`) don't match the deployed docs domain (`pdpp.dev`). This is exactly the kind of drift IANA's Section 2.2 warns about ("providing a URL to precisely identify the registry helps... understand the request") — pick one, register the other as a permanent redirect, and say so explicitly in the spec (a one-paragraph "Registry Hosting" note near Appendix A).
2. **Per-code human+machine page** at `{canonical-domain}/purpose/{code}` — e.g. `https://pdpp.org/purpose/personalization` returns content-negotiated HTML (short description, example consent copy, which protocol behaviors it triggers, e.g. `ai_training`'s mandatory-consent rule) or JSON-LD (`{ "@id": ..., "label": ..., "description": ... }`) depending on `Accept` header, matching schema.org's dual-serve pattern.
3. **One machine-readable index** at `https://pdpp.org/purpose/index.json` (or `.well-known/pdpp-purpose-registry`) listing all registered codes with version/date-added metadata, so implementers don't have to scrape N pages — this is the IANA-table half of the model, layered under the schema.org per-term half.
4. **Version policy:** codes are additive-only and immutable once published (never redefine a code's meaning — this mirrors PDPP's own manifest versioning philosophy already stated in Section 7: "never remove existing fields"). A new meaning requires a new URI, not an edit.
5. **Registration posture:** keep the current stance — "MUST treat unrecognized purpose URIs as opaque identifiers" (already normative, Appendix A) — but publish the actual process (who reviews PRs against the registry repo, expected turnaround) the way DPV publishes its GitHub contribution guide. This does not need to be IANA-strict; Section 4's "select the least strict policy" guidance argues for something close to First-Come-First-Served-with-review (a public GitHub PR that a maintainer merges), not Expert Review or stricter, since PDPP already treats unrecognized codes as harmless (no protocol behavior depends on registry membership except the single `ai_training` special case).

### Q2 verdict: (c) stay retention-only with a declared extension point in v0.1, but the extension point should be explicitly modeled on ODRL's Prohibition/Duty split, and DPV/ODRL should be cited as mapping targets, not adopted wholesale

**Confidence: medium-high.** The "don't build your own vocabulary from scratch" half is well-supported; the exact shape of the v0.2 extension is a judgment call the corpus can't settle for a follow-up agent.

P3P's failure is not evidence against structured vocabulary — P3P's vocabulary was arguably not even its primary problem. EPIC's critique and the historical record point to **enforcement and adoption friction**, not semantic over-engineering: nobody could act on a P3P promise, ordinary users couldn't operate the tooling, and browser vendors eventually ripped it out because implementing it cost more than the ecosystem got back. PDPP's spec already independently arrived at the right lesson without needing to learn it from P3P: `retention` and `purpose_code` are explicitly designated **structured policy declarations**, not protocol-enforced constraints (spec-core.md Section 5, "Semantic classes and consent-surface rendering"), and the spec is explicit that this is "consistent with how OAuth 2.0 treats scope compliance: the protocol makes the commitment legible and machine-readable; external mechanisms enforce it" (Section 6, Retention). That is the correct posture and it is also FAPI's posture — even the highest-assurance OAuth profile in production (UK/EU Open Banking) does not attempt to make retention/usage promises API-enforceable; it makes the *channel* tamper-evident (JAR/mTLS) and leaves the *promise* to contract/regulation. P3P tried to make the promise itself feel technical without any enforcement backing it, and that gap is what got mocked as "Pretty Poor Policy," not the fact that it had a taxonomy.

Given that, growing PDPP's own bespoke vocabulary for "no-resale"/"no-sharing" (option b) repeats P3P's structural mistake in miniature: a homegrown enum that nobody outside PDPP recognizes, that carries no independent semantic weight, and that will need constant expansion as new commitment types get requested (no-resale today, no-third-party-model-training tomorrow, no-cross-border-transfer after that). Full ODRL/DPV adoption (option a) is also wrong for v0.1: ODRL is a general rights-expression language (documents, media licensing, IoT) with a JSON-LD/RDF processing model that is heavier than anything else in PDPP's wire format, and DPV is explicitly a W3C Community Group report (not a Recommendation) still under active semantic revision (v2.3 as of Feb 2026) — binding v0.1 to it risks importing DPV's own churn into PDPP's stability guarantees.

**Concrete, PR-able recommendation:** (c) with teeth — add a `policy` extension point to the grant/selection-request schema now, even before it has more than `retention` in it, structured so that a no-resale/no-sharing addition later is a **new named field under `policy`, mappable 1:1 to an ODRL Prohibition** rather than a new ad hoc top-level grant field:

```json
"policy": {
  "retention": { "max_duration": "P1Y", "on_expiry": "delete" },
  "prohibitions": ["no_resale", "no_third_party_sharing"]
}
```

Each value in `prohibitions` should be a registered code following the exact same URI-registry pattern as `purpose_code` (Q1's answer) — e.g. `https://pdpp.org/policy/no_resale` — so the two extensibility problems (purpose registry, policy registry) share one mechanism instead of inventing two. In the spec text, add one informative sentence mapping each prohibition code to its ODRL equivalent (e.g. "`no_resale` corresponds to an ODRL Prohibition with action `odrl:sell`") — this buys future interoperability with any ODRL-based enforcement tooling without requiring PDPP implementations to speak ODRL/RDF themselves. Do not adopt DPV's purpose taxonomy as a hard dependency, but add one non-normative table mapping PDPP's existing 6 purpose codes to their nearest DPV `dpv:Purpose` subclass, the same way the spec already does informative-only mapping tables for GDPR and DMA (Section 1 relationship table) — this is cheap, adds cross-recognition, and doesn't create a maintenance dependency.

### Q3a verdict: yes — access_mode should become a Specification-Required-style registry exactly like OAuth Token Type Hints, once a second value ships

**Confidence: high** on the pattern fit; **medium** on timing (whether v0.1 needs this now vs. at the first actual second/third `access_mode` value).

The fit is unusually clean because PDPP's spec-deferred.md already anticipates the exact extension (`event_driven` alongside `single_use`/`continuous`) and the grant schema is already designed not to break on new values. The IANA OAuth Token Type Hints registry is a working, live example of the identical shape: a small enum, defined by one core RFC, extended later by an unrelated spec (Kantara's UMA 2.0 contributed `pct` with `Kantara_UMA_WG` as its own Change Controller) via the "Specification Required" tier — meaning a public, stable specification document plus a named designated-expert sign-off, not a vote, not an RFC-track submission. That is exactly the right strictness level per RFC 8126's own guidance to prefer the least strict policy that fits: `access_mode` values have real protocol-enforcement consequences (RS behavior differs materially — grant consumption timing, STATE persistence) so First-Come-First-Served is too loose (a collision or a poorly-specified value could break RS conformance across implementations), but requiring full spec-body ratification (IETF-Review-equivalent) for every new access pattern is too slow for a young protocol that needs to learn from real deployments.

**Concrete, PR-able recommendation:** Don't build the registry machinery yet — defer it exactly as spec-deferred.md already does — but when `event_driven` (or any second value) is ready to ship, structure its introduction as: (1) a short companion spec section (a few paragraphs, not a new document) defining the value's RS/AS behavior precisely, matching the level of detail Section 6's `single_use`/`continuous` table already has; (2) a named reviewer/maintainer sign-off recorded in the PR, not a full spec-wide vote; (3) a `Change Controller` notion — even informally, "PDPP maintainers" vs. "contributed by X profile" — recorded next to the value the way IANA's table does, since PDPP already anticipates non-core profiles extending things (see `pdpp_token_kind` extensibility clause in Section 8, which already uses almost this exact "MUST treat unrecognized as unauthorized" pattern for token kinds — apply the same posture to unrecognized `access_mode` values for forward compatibility: an RS encountering an unknown `access_mode` should fail closed, not guess).

### Q3b verdict: yes, JAR/JWS materially strengthens the user's technical-legal position, and it is a well-defined future hardening step PDPP has already scoped correctly — but it's a channel-integrity improvement, not proof of intent, and that distinction matters for what claims can be made

**Confidence: high** on the technical mechanism; **explicitly not legal advice**, per the task's own scoping — this describes what the cryptography proves, not what a court would conclude from it.

Plain bearer-token authentication (PDPP v0.1's baseline) proves only "a request arrived carrying a token that was valid at introspection time." It says nothing about who actually constructed the request's *content* — if a token leaks, is proxied, or a client library mishandles it, a third party can generate requests with attacker-chosen `purpose_code`/`retention`/`client_claims` that are indistinguishable, from the RS's point of view, from ones the legitimate client intended. This matters specifically for PDPP because Section 5 makes `client_claims` and structured policy declarations part of what the AS displays to the user as coming from "[client name]" — the attribution is a *display* attribution today, not a *cryptographic* one.

JAR (RFC 9101) plus FAPI's mandatory profile (JWS-signed request object, `nbf`/`exp`-bounded validity, `aud` binding to the specific AS, sender-constrained tokens via mTLS or `private_key_jwt` client auth) closes exactly this gap: after JAR, the AS holds a JWS-signed artifact whose signature was produced by the client's private key over the *exact* declared parameters, at a specific, narrow time window, addressed to a specific AS. That is a materially stronger technical-legal position than today's plain-bearer baseline for three concrete reasons: (1) **non-repudiation of content** — the client cannot later plausibly claim "we didn't request that `purpose_code`" the way they could when the request was an unsigned, mutable-in-transit query string; (2) **temporal bounding** — the 60-minute `nbf`/`exp` window forecloses replay-based deniability ("that request could have been forged days later"); (3) **key-bound authentication** — sender-constrained tokens mean possession of a bearer token alone is insufficient, so a leaked-token scenario doesn't implicate the client the same way. PDPP's spec has already identified this correctly and deferred it as a v0.2 hardening profile (Section 10's DPoP/mTLS note, and the "grant is designed to be signable" language) — that is the right call for v0.1 scope, not a gap in judgment.

The important caveat, kept technical-not-legal: signing the *request* proves the client's authorization-server-facing intent at request time. It does not, by itself, prove what the client's backend *did* with the data afterward — retention/no-resale compliance still lives entirely in the "structured policy declaration, not protocol-enforced" bucket (Q2's finding) regardless of how strongly the request itself is signed. JAR/FAPI strengthens "the client asked for X under these declared terms and cannot deny having asked," which is valuable evidentiary material for a dispute about consent scope, but it does not extend to "the client complied with X," which remains outside what any request-signing mechanism can prove.

**Concrete, PR-able recommendation:** No spec change needed now — Section 10 already scopes this correctly as a deferred hardening profile. When that profile is written, the deliverable should explicitly state the non-repudiation property in these terms (content-signed, time-bounded, AS-audience-bound) so implementers and, if it ever comes up, legal reviewers understand precisely what the signature does and does not attest to — mirroring the precision FAPI's own spec uses (13/15/17 in FAPI Part 2's Section 5.2.2's explicit shall-clauses) rather than a vague "stronger security" gloss.
