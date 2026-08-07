# Prior art: how credible protocol/standards sites structure public docs

Research date: 2026-06-24 (conducted 2026-07-06). Purpose: inform restructuring pdpp.dev
ahead of Linux Foundation Decentralized Trust review. Access dates noted per source.

## 1. Model Context Protocol — modelcontextprotocol.io

Sources: https://modelcontextprotocol.io (accessed 2026-07-06),
https://modelcontextprotocol.io/specification/2025-06-18 (accessed 2026-07-06),
https://modelcontextprotocol.io/specification/versioning (accessed 2026-07-06),
https://modelcontextprotocol.io/llms.txt (accessed 2026-07-06),
https://blog.modelcontextprotocol.io/posts/2026-07-28-release-candidate/ (search result, 2026-07-06).

### Spec vs docs vs SDK split

MCP hard-separates three concerns into three nav trees under one domain:

- **Getting Started & Learning** — conceptual ("What is MCP", "Architecture overview",
  "Understanding MCP clients/servers", "Versioning", "SDKs", "Debugging", "MCP Inspector").
- **Development** — task-oriented guides ("Build an MCP client", "Build an MCP server",
  "Build with Agent Skills", "Client Best Practices", "Connect to local/remote MCP
  servers", "Roadmap").
- **Specification (dated, e.g. "2025-11-25")** — the normative document, itself split into
  Architecture / Basic (Authorization, Overview, Lifecycle, Transports) / Utilities
  (Cancellation, Ping, Progress, Tasks) / Client (Elicitation, Roots, Sampling) / Server
  (Overview, Prompts, Resources, Tools) / Server Utilities / Key Changes / Schema
  Reference.

Two more first-class trees sit alongside: **Extensions** (MCP Apps, Authorization
Extensions, Extension Support Matrix — explicitly labeled additive/non-breaking) and
**Registry** (publishing mechanics — clearly ops docs, not spec). **Community** carries
governance artifacts (Governance and Stewardship, SEP Guidelines, Feature Lifecycle and
Deprecation Policy, charters per working group, Contributor Ladder, Antitrust Policy).
**SEPs** (Specification Enhancement Proposals) is its own top-level index — the RFC-style
change-proposal trail, separate from both docs and spec.

The spec page itself states its authority explicitly: *"This specification defines the
authoritative protocol requirements, based on the TypeScript schema in schema.ts... For
implementation guides and examples, visit modelcontextprotocol.io."* — i.e. the spec
names its own machine-readable source of truth (a `schema.ts` file) and explicitly
disclaims that guides live elsewhere.

### Status/versioning taxonomy

Verbatim from `/specification/versioning`:

> The Model Context Protocol uses string-based version identifiers following the format
> `YYYY-MM-DD`, to indicate the last date backwards incompatible changes were made.
>
> Revisions may be marked as:
> - **Draft**: in-progress specifications, not yet ready for consumption.
> - **Current**: the current protocol version, which is ready for use and may continue to
>   receive backwards compatible changes.
> - **Final**: past, complete specifications that will not be changed.
>
> The **current** protocol version is **2025-11-25**.

Below the revision-level taxonomy sits a **feature-level** lifecycle: individual features
can be marked **Deprecated** (with a documented migration path, minimum 12-month grace
period, or 90 days under an "expedited-removal exception"), tracked in a public
**deprecated features registry**, before becoming eligible for **Removed** in a future
revision. This decouples spec-version status from feature status — a feature can be
deprecated inside an otherwise-Current spec.

Version negotiation is a protocol-level concern documented on the same page (clients/
servers MAY support multiple versions, MUST agree on one per session) — i.e. the
versioning page doubles as both docs-site metadata *and* normative behavior.

A **Key Changes / changelog** page exists per version (e.g. `/specification/2025-06-18/changelog`
in the historical `spec.modelcontextprotocol.io` mirror), and a separate **blog**
(blog.modelcontextprotocol.io) carries prose announcements ("One Year of MCP",
"The 2026-07-28 MCP Specification Release Candidate") distinct from the reference site.

### Superseded content handling

Old dated spec versions (e.g. `/specification/2024-11-05`) remain live at their own URL
with identical structure — the content itself doesn't carry a big "SUPERSEDED" banner in
the page body (at least not in the text-extracted DOM); status is communicated via the
`/specification/versioning` taxonomy page and (per site convention) a version switcher in
the UI chrome. Nothing is deleted; every dated version is a permanent, addressable
artifact.

## 2. SMART on FHIR — docs.smarthealthit.org + hl7.org/fhir/smart-app-launch

Sources: https://docs.smarthealthit.org (accessed 2026-07-06),
https://hl7.org/fhir/smart-app-launch/ (accessed 2026-07-06),
https://hl7.org/fhir/smart-app-launch/versions.html (404 at access time, 2026-07-06).

### Three-tier separation: docs site vs normative IG vs sandboxes

`docs.smarthealthit.org` is explicitly a curated **implementer-guide/tutorial layer**, not
the spec itself. Its top nav: **Standards and Specifications, Tutorials, Software
Libraries, Test Environments, Vendor Sandboxes, Data, Sample Apps, Support, In
Progress/Bleeding Edge Projects**. It links *out* to the normative spec rather than
restating it, and it foregrounds runnable tools: "SMART App Launcher (no registration
required)," "SMART Bulk Data Server (no registration required)," plus named vendor
sandboxes (Cerner, Epic, Allscripts, Logica Health). The "no registration required" framing
is a deliberate friction-reduction signal for a first-time implementer.

The **normative spec** lives on hl7.org as an HL7 FHIR Implementation Guide (IG) — a
different publishing pipeline with its own strict status boilerplate. From
`hl7.org/fhir/smart-app-launch/`:

- Title: "SMART App Launch v2.2.0"
- Status: **"STU 2.2"** (Standard for Trial Use) with an international-standard flag icon
- "Active as of 2023-03-01"
- Official canonical URL:
  `http://hl7.org/fhir/smart-app-launch/ImplementationGuide/hl7.fhir.uv.smart-app-launch`
- Computable Name: "SmartAppLaunch"
- Base standard dependency stated explicitly: built on "FHIR (HL7® FHIR® Standard) R4"
- Explicit "current published version" framing with a pointer to the **directory of
  published versions**.

IG top nav (distinct from the docs-site nav): **Overview, Apps, Backend Services,
Authentication, Conformance, "Brands" (branding/user-access endpoints), See Also**
(artifacts, best practices, examples, references).

### STU (Standard for Trial Use) as the maturity taxonomy

FHIR's status vocabulary is HL7-wide, not per-IG: **Draft → STU (Standard for Trial
Use, numbered e.g. STU1/STU2) → Normative**. Every FHIR/IG page carries this in its header
plus a canonical URL, a computable machine-readable name, and a base-standard dependency
declaration — four fields PDPP doesn't currently surface anywhere.

### Superseded/historical handling

HL7 publishes a durable, permanent **"Directory of published versions"** for every spec —
every dated/numbered version stays addressable forever at a stable URL; nothing is
deleted. (The specific `versions.html` URL attempted 404'd at access time — HL7 restructured
URLs; the *directory-of-versions* convention itself is well-documented HL7 practice and
visible on the current IG's status block, which explicitly links to it.)

## 3. OpenID Foundation / FAPI — openid.net/specs

Sources: https://openid.net/specs/ (accessed 2026-07-06),
https://openid.net/specs/openid-financial-api-part-2-1_0.html (accessed 2026-07-06).

### Status taxonomy: filename-encoded draft numbers → Final Specification

OpenID's index page is a near-bare directory listing; status is encoded in the **filename**
itself rather than a rendered badge:

- Working drafts: sequential suffixes `-00`, `-01`, `-02`, ...
- Implementer's Drafts: `-ID1`, `-ID2`, ...
- Stable release: version number with no suffix, e.g. `fapi-security-profile-2_0.html`
- Terminal state: `-final`, e.g. `fapi-security-profile-2_0-final.html`
- Errata: `-errata1`, `-errata2`, ... appended to a final spec's filename, e.g.
  `oauth-v2-jarm-errata1.html`

The actual spec document (`openid-financial-api-part-2-1_0.html`, i.e. FAPI Part 2) carries
this header block:

- Title: "Financial-grade API Security Profile 1.0 - Part 2: Advanced"
- **Status: "Final Specification"**
- Publication date: "March 12, 2021"
- Editors: named individuals with affiliations (N. Sakimura/Nat Consulting, J.
  Bradley/Yubico, E. Jay/Illumila)
- Copyright/IPR notice granting a royalty-free copyright license for
  implementation/derivative-spec purposes, explicitly scoped to "this Implementers Draft
  or Final Specification"
- A patent-rights disclaimer: "There is a possibility that some of the elements of this
  document may be the subject to patent rights. OIDF shall not be held responsible for
  identifying any or all such patent rights."

Notably terse compared to W3C — no explicit "previous versions" link or changelog inline
on the doc itself; version history lives in the filename convention on the index page
instead. This is a lighter-weight, more IETF-RFC-like convention than W3C's heavier
Process-Document-driven banner.

## 4. W3C — Verifiable Credentials Data Model (TR page convention)

Sources: https://www.w3.org/TR/vc-data-model-2.0/ (accessed 2026-07-06),
web search for the W3C Process "Status of This Document" boilerplate (accessed 2026-07-06).

### The "Status of This Document" banner — the most rigorous of the five

Every W3C TR page opens with a mandated, Process-Document-governed section. Verbatim
fields present on the VC Data Model 2.0 page:

1. Opening disclaimer: *"This section describes the status of this document at the time
   of its publication. Other documents may supersede this document."*
2. Link to **the W3C standards and drafts index** (`w3.org/TR/`) as the canonical "what's
   current" list — i.e. every TR page points back to one master index rather than trying
   to be self-describing about freshness.
3. **Comment/feedback venue**, explicitly dual-channel: primary = GitHub issues
   (`github.com/w3c/vc-data-model/issues/`); fallback = a mailing list
   (`public-vc-comments@w3.org`) with subscribe/archive links.
4. **Publishing group** named explicitly: "Verifiable Credentials Working Group."
5. **Process track** declaration: "Recommendation track" + the governing Process Document
   version ("03 November 2023 W3C Process Document") — i.e. the page cites which version
   of the meta-process rules it was produced under.
6. **Formal endorsement language** at Recommendation status: "W3C recommends the wide
   deployment of this specification as a standard," with the definition of what a
   Recommendation legally/organizationally means (Member consensus + royalty-free
   licensing commitments).
7. **Patent policy compliance block**: reference to the W3C Patent Policy, a link to the
   public list of patent disclosures, and an explicit obligation statement for individuals
   aware of Essential Claims to disclose them.
8. **Errata / translations / commit-history / implementation-report links** bundled in an
   "Additional Resources" cluster.

The maturity ladder itself (from the W3C Process Document, confirmed via search): **Working
Draft → Candidate Recommendation → Proposed Recommendation → Recommendation**, plus a
non-track **Note** classification for informative/abandoned work. Pre-Recommendation
statuses carry a mandatory disclaimer that the document "may be updated, replaced or
obsoleted... at any time" and "it is inappropriate to cite this document as other than
work in progress" — i.e. W3C bakes the "don't cite drafts as authoritative" warning
directly into the document rather than relying on a nav-level label.

This is the heaviest-weight convention of the five — appropriate for a Recommendation-
track, patent-policy-bearing standard, and closest in kind to what an LF Decentralized
Trust review will expect to see modeled.

## 5. UK Open Banking — standards.openbanking.org.uk

Source: https://standards.openbanking.org.uk (accessed 2026-07-06).

### Nav split for a mixed technical/policy audience

Top-level sections (verbatim): **Get Started, Specifications, Security Profiles,
Guidelines, Good Practice, Reference, FAQs**, plus a distinct **"Get Certified"** call to
action.

The site cleanly separates three audiences into three trees:

- **Normative technical specs** — "Read/Write API Specifications," "Open Data API
  Specifications," "Directory Specifications" (all under Specifications), plus dedicated
  **Security Profiles** (auth/onboarding flows — kept separate from the API specs
  themselves, mirroring FAPI's own security-profile-as-separate-artifact convention it's
  built on).
- **Policy/UX guidance for a non-engineering audience** — "Customer Experience
  Guidelines" and "Operational Guidelines" under **Guidelines**, addressing regulatory and
  UX requirements distinct from wire-format specs.
- **Conformance/certification** — surfaced both inline (FAQs link to functional/security
  conformance tools) and as its own top-level **"Get Certified"** CTA, positioned as
  clearly distinct from both the specs and the guidelines: certification is a *service*,
  not a document.

**Good Practice** is notable as its own top-level bucket — implementation guidance and
third-party-provider (TPP) resources that are explicitly *not* normative but also not just
marketing ("Get Started"). This third bucket (normative / informative-but-endorsed /
onboarding-marketing) is a nuance the other four sites fold into fewer categories.

---

## Synthesis

### (a) Common status-banner fields across all five

Every serious spec/IG page carries some superset of:

1. **Maturity/status label** from a named, finite taxonomy (Draft/Current/Final;
   STU/Normative; Implementer's Draft/Final; WD/CR/PR/REC) — never a bare version number
   alone.
2. **Publication/effective date** ("Active as of...", "Publication Date").
3. **Canonical/permanent URL** distinct from any "latest" alias — so citations don't rot
   when a newer version ships.
4. **Editors/authors with affiliation** (named individuals, not just "the working group").
5. **Governing body / working group name** — who is accountable for this text.
6. **Feedback/comment venue**, explicitly named (GitHub issues, mailing list, or both) —
   never "open an issue somewhere."
7. **Link to version history / directory of all versions** — the page never claims to be
   the only copy of the truth.
8. **IPR/patent or licensing notice** — even lightweight specs (OpenID) carry this;
   W3C's is the most elaborate.
9. **A dependency declaration** — what base standard/protocol this builds on (FHIR→R4,
   FAPI→OAuth 2.1/OIDC, MCP→JSON-RPC 2.0).

### (b) Audience-based top-level nav patterns (verbatim section names)

| Site | Sections |
|---|---|
| MCP | Getting Started & Learning · Development · Tutorials · Examples · Extensions · Registry · Specification · Community · SEPs |
| SMART on FHIR (docs site) | Standards and Specifications · Tutorials · Software Libraries · Test Environments · Vendor Sandboxes · Data · Sample Apps · Support |
| SMART on FHIR (IG itself) | Overview · Apps · Backend Services · Authentication · Conformance · See Also |
| OpenID/FAPI | (bare index; status lives in filenames, not nav) |
| W3C TR page | Abstract · Status of This Document · (body) · References — nav is per-doc, not sitewide |
| UK Open Banking | Get Started · Specifications · Security Profiles · Guidelines · Good Practice · Reference · FAQs · Get Certified |

Cross-cutting pattern: **normative spec**, **implementer/how-to docs**, **runnable
sandbox/playground**, and **governance/process** are consistently four *separate* nav
branches, never blended into one "Docs" catch-all. Certification/conformance, where it
exists (Open Banking, FHIR's Conformance section), is also its own branch, not a subsection
of the spec.

### (c) Superseded/historical content handling

None of the five delete old versions. All keep every dated/numbered revision at a
permanent URL. The differentiator is *how prominently* the "this is not current" fact is
surfaced:

- **MCP**: taxonomy page (Draft/Current/Final) is the single source of truth for what's
  current; old versions stay live at their own URL, discoverable via a version switcher,
  not via a loud per-page banner in the rendered content.
- **FHIR**: heaviest — every IG page's status block explicitly links to a **directory of
  published versions**; STU-numbered versions are the norm, so "which STU am I reading" is
  always in the title itself ("SMART App Launch v2.2.0" / "STU 2.2").
  norm.
- **OpenID/FAPI**: version state is baked into the **filename** — `-01`, `-ID1`, `-final`,
  `-errata1` — so a stale bookmark is self-describing without needing a banner at all.
- **W3C**: most explicit in-body warning ("may be updated, replaced or obsoleted... at any
  time... inappropriate to cite this document as other than work in progress") for
  everything pre-Recommendation; post-Recommendation carries errata/translation links
  instead.
- **Open Banking**: least visible on this axis from the homepage; version state is mostly
  handled per-spec-page (not verified in this pass — would need a specific spec page, not
  just the landing page).

### (d) Sandboxes/playgrounds vs the normative spec

Only SMART on FHIR and UK Open Banking foreground runnable tooling as a first-class nav
item ("Test Environments," "Vendor Sandboxes" / "Get Certified"). Neither claims strict
byte-for-byte sync with the spec — the framing is looser: "developer tool for SMART apps,"
"no registration required," i.e. sandboxes are pitched as *convenience for trying it out*,
not as an alternate normative source. No site examined claims an explicit machine-checked
conformance guarantee between the playground and spec text; conformance is instead handled
by a **separate certification program** (Open Banking's "Get Certified," FHIR's
"Conformance" nav item) — a distinct, harder-edged claim than "we have a sandbox." MCP has
no public sandbox at all; it relies on the Inspector (a debugging tool, explicitly
positioned under Development, not as a spec-adjacent playground).

**Implication for pdpp**: if PDPP ships an interactive playground/demo, don't imply it's
spec-equivalent — frame it the way FHIR/Open Banking do ("try it, no registration
required") and route any real conformance claim through a separate, explicitly-named
conformance/certification track instead of overloading the playground with that claim.

### (e) Five cheap "serious standard" signals PDPP could adopt

1. **A finite, named status taxonomy with one current pointer.** Adopt MCP's
   Draft/Current/Final (or FHIR's Draft/STU/Normative) verbatim — pick one, put it on every
   spec page, and make "the current version is X" a single sentence linking to one
   directory-of-versions page. Cheapest, highest-leverage change available.
2. **Dated, permanent version URLs that never get overwritten.** `pdpp.dev/spec/2026-06-24/`
   pattern (MCP's exact convention) — old links keep working forever, which is table stakes
   for anyone citing PDPP in another spec or in the LF review packet.
3. **A "Status of This Document" preamble on the spec itself**, even a short one: status
   label, effective date, editors, canonical URL, feedback venue (GitHub issues link, named
   explicitly). This is a few paragraphs, not an engineering project, and it's the single
   most recognizable "someone serious wrote this" signal across all five sites.
4. **Explicit dependency declaration.** State up front what PDPP builds on (OAuth
   2.1/OIDC, specific RFCs) the way FHIR states "built on FHIR R4" and FAPI states "based
   on OAuth 2.1" — this is one paragraph and immediately reads as protocol-literate rather
   than reinvented-from-scratch.
5. **Separate the spec from the guides from the SDK docs from the sandbox into four
   distinct nav branches**, even if all four currently have only one page each. The *shape*
   of the nav (not the volume of content) is what reads as "young-but-serious protocol"
   vs. "single README stretched into a site."

### Five anti-patterns to avoid

1. **A single flat "Docs" nav mixing spec text, tutorials, and marketing copy** — none of
   the five credible sites do this; it's the strongest tell of an unstructured/AI-generated
   project site.
2. **No dates, no version numbers, no "current as of" anywhere** — every credible site
   answers "when was this written and is it still true" in the first screen.
3. **Silently editing/deleting old spec text in place** — all five treat every past
   revision as a permanent, citable artifact. Editing history away breaks anyone who cited
   you.
4. **Claiming a sandbox/demo *is* the spec, or is guaranteed conformant, without a named
   conformance program behind that claim** — none of the five make an unqualified sync
   claim between playground and normative text.
5. **No named accountable editor/group and no named feedback channel** — "contributions
   welcome" with no GitHub-issues-or-mailing-list link, and no named working group/editor,
   reads as unowned. Every one of the five names who's responsible and exactly where to
   send objections.

---

## Recommended pdpp.dev docs IA

### Nav tree (top-level, four branches + governance)

```
pdpp.dev
├── Learn                      (concepts, "what is PDPP", architecture, why OAuth-profile)
│   ├── What is PDPP?
│   ├── Architecture overview
│   ├── Understanding grants/scopes
│   └── Glossary
├── Guides                     (task-oriented, audience-split)
│   ├── Build a connector
│   ├── Build a client (consume PDPP data)
│   ├── Build an MCP/agent integration
│   └── Best practices / security guidance
├── Specification              (normative, dated + statused)
│   ├── /spec/<YYYY-MM-DD>/     ← permanent per-revision URL, MCP-style
│   │   ├── Status of This Document (banner, see template below)
│   │   ├── Overview & terminology
│   │   ├── Grant & scope model
│   │   ├── Connector protocol
│   │   ├── Auth flows (OAuth profile detail)
│   │   ├── Errors & conformance requirements
│   │   └── Schema reference (machine-readable source of truth, linked)
│   ├── Versioning & status taxonomy   (the one page defining Draft/Current/Final)
│   ├── Directory of published versions (permanent list, never pruned)
│   └── Changelog / Key Changes per revision
├── Playground                 (explicitly NOT normative)
│   └── "Try PDPP — no registration required" (sandbox/demo, framed as convenience only)
├── Governance                 (mirrors MCP Community + W3C Status-of-Document rigor)
│   ├── Working group / maintainers (named individuals + affiliations)
│   ├── Change proposal process (PDPP's SEP-equivalent)
│   ├── Feature lifecycle & deprecation policy
│   ├── Feedback / issue tracker (one primary venue, named explicitly)
│   └── IPR / licensing notice
└── Conformance                (separate from Playground — a program, not a demo)
    └── Conformance test suite / certification (even if v0 is just a checklist)
```

### Status taxonomy (adopt directly, minimal invention)

- **Draft** — in-progress, not for production implementation.
- **Current** — the in-force revision; may still receive backwards-compatible changes.
- **Final** — a past, complete, frozen revision (once PDPP has enough history to freeze
  one).

One sentence, one page (`/spec/versioning`), one pointer: *"The current version is
`<date>`."* Every dated spec page links back to this page, never restates it.

### Status-banner template (put this at the top of every `/spec/<date>/` page)

```
Status: <Draft | Current | Final>
Published: <YYYY-MM-DD>
Canonical URL: https://pdpp.dev/spec/<YYYY-MM-DD>/
Editors: <name (affiliation)>, ...
Built on: OAuth 2.1, <other named base RFCs>
Previous versions: https://pdpp.dev/spec/versions/
Feedback: https://github.com/<org>/pdpp/issues (primary) — <mailing list/email, if any> (fallback)
Schema source of truth: <link to machine-readable schema file>

This section describes the status of this document at the time of its publication.
Other documents may supersede this document. A list of current PDPP publications and
the latest revision of this specification can be found at https://pdpp.dev/spec/versions/.
```

This is deliberately a hybrid: MCP's date-based versioning + three-state taxonomy, FHIR's
"built on X" dependency line and permanent-directory pointer, W3C's explicit
supersession/feedback-venue disclaimer, OpenID's terse editors/IPR block — sized down to
what a young protocol can credibly claim (no patent-policy machinery yet; no ballot
process yet) without overclaiming maturity it doesn't have.
