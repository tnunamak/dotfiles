---
title: "Credible standards/protocol sites split a neutral org shell from a separate, austere, dated-and-permalinked normative spec surface — and earn authority by conspicuous restraint, not marketing"
date: 2026-07-09
topic: standards-body-sites
tags: [standards-body, protocol-site, information-architecture, neutrality, spec-presentation, governance, design-restraint]
status: draft
sources: [w3c-home, w3c-activitypub, dtinit, solid, oauthnet, jsonschema, openapis-org, openapis-spec, oas-latest, mcp-home, mcp-spec, openid-specs, rfc9110]
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = interpretation/conclusions. Skippable. No citations here.
-->

## CLAIMS

### The two-surface split (org shell vs spec surface)

- The OpenAPI Initiative deliberately runs two separate web surfaces: `openapis.org` is the organizational/governance/community/membership face, and `spec.openapis.org` hosts the specifications; the org site links OUT to the spec site and users seeking the standard bypass governance entirely [openapis-org].
- `spec.openapis.org` self-describes as containing "the authoritative HTML renderings of the OpenAPI Initiative's specifications and extension registries" and defers educational/learning content to a separate "Learn OpenAPI" surface and tooling to a separate "OpenAPI Tooling" site [openapis-spec].
- `spec.openapis.org` uses `/[specification]/latest.html` permalink structure (e.g. `/oas/latest.html`, `/arazzo/latest.html`, `/overlay/latest.html`) as stable "latest" pointers, with dated/versioned permalinks living on the individual spec pages [openapis-spec][oas-latest].
- MCP splits `modelcontextprotocol.io/` (docs, quickstart, SDK cards, "USB-C for AI" explainer) from `/specification/<date>` (the normative protocol document); the docs homepage points to build-server/build-client/concepts cards while the spec page carries the normative requirements [mcp-home][mcp-spec].
- oauth.net uses a two-tiered linking model: introductory topic pages ("Access Tokens", "Grant Types") act as gateways that funnel newcomers to the normative RFCs (RFC 6749, RFC 6750) hosted at the IETF; oauth.net itself is a reference/index surface, not the normative authority [oauthnet].
- Solid keeps specifications "backstage": the homepage is user/developer-facing and the specs are reached via a single `/TR` "Specifications" link in the footer [solid].

### How the normative spec itself is presented (the header contract)

- W3C TR spec pages open with a maturity status banner naming the document class and date (ActivityPub shows "W3C Recommendation 23 January 2018") [w3c-activitypub].
- W3C TR pages carry a header metadata block with "This version" (dated URI, e.g. `/TR/2018/REC-activitypub-20180123/`), "Latest published version" (undated canonical URI), "Latest editor's draft" (GitHub-hosted), and "Previous version" [w3c-activitypub].
- W3C TR pages list named editors and authors with personal homepage links, and link to a GitHub issues tracker, an Implementation Report, an Errata page, and a Translations page [w3c-activitypub].
- IETF RFC HTML opens with a standardized administrative header block: stream ("Internet Engineering Task Force (IETF)"), RFC number, STD number, obsoletes/updates chains, category ("Standards Track"), publication date, "ISSN: 2070-1721", and authors with organizational affiliations [rfc9110].
- The RFC "Status of This Memo" section states the document is an Internet Standards Track document representing "consensus of the IETF community" with "approval for publication by the Internet Engineering Steering Group (IESG)", and the copyright notice invokes "BCP 78 and the IETF Trust's Legal Provisions" [rfc9110].
- The OpenAPI spec document (v3.2.0) opens with title + "Version 3.2.0" + a date ("19 September 2025"), three persistent links (This version / Latest published / Editor's draft), a list of prior versions (v2.0 through v3.1.2), nine current editors plus five former editors, and an "Appendix A: Revision History" [oas-latest].
- MCP versions its spec by date string (`2025-06-18`); the spec text states it "defines the authoritative protocol requirements, based on the TypeScript schema in schema.ts" hosted on GitHub, making a machine-readable schema the source of truth [mcp-spec].
- Normative language across all these specs is signaled with RFC 2119 / BCP 14 keywords ("MUST", "SHOULD", "MAY") in ALL CAPS, with an explicit boilerplate stating the keywords apply "when, and only when, they appear in all capitals" [w3c-activitypub][rfc9110][oas-latest][mcp-spec].
- RFC/spec pages use hierarchical numbered ToCs with per-heading and per-paragraph anchors (RFC 9110 uses pilcrow ¶ markers for granular paragraph-level citation) [rfc9110].

### Spec status taxonomy / maturity ladders

- OpenID's Foundation site presents a three-tier maturity system: Final Specifications ("OpenID Foundation standards" with IP protections), Implementer's Drafts (active development toward finalization), and Active Drafts (organized by working group), with dedicated sections for errata and obsolete specs [openid-specs].
- OpenID groups specs by originating working group (AB/Connect, FAPI, eKYC & IDA) rather than as a flat list, and cross-references "most recent Implementer's Draft" [openid-specs].
- W3C's document taxonomy ("Types of documents W3C publishes", maturity levels) is a first-class navigable concept on the org site [w3c-home].

### Governance / neutrality signaling

- W3C signals neutrality by rotating member logos to avoid favoritism, stating "Members, full-time staff, and the public work together", surfacing the Technical Architecture Group, and giving the standards process and Code of Conduct prominence; "No single organization dominates the visual hierarchy" [w3c-home].
- The OpenAPI Initiative signals institutional legitimacy via prominent "within The Linux Foundation" placement and dedicated menu links to Technical Steering Committee, Technical Oversight Board, Project Charter, Code of Conduct, and membership tiers — while UNDER-emphasizing member logos on the homepage (a "Current Members" link but no sponsor showcase) [openapis-org].
- oauth.net signals neutrality through pluralism: authority is dispersed across IETF OAuth WG, OpenID Foundation, Kantara Initiative, and W3C, with no single entity claiming ownership [oauthnet].
- json-schema.org signals governance via sponsorship tiers (Gold/Silver/Bronze) with transparent contribution links, "monthly Office Hours and Open Community Working Meetings", a Code of Conduct, and adoption metrics ("60 million weekly downloads", "5000+ practitioners") framed as organic adoption rather than top-down mandate [jsonschema].
- MCP signals it is an "open-source standard" / "open protocol supported across a wide range of clients and servers" and lists cross-vendor support (Claude, ChatGPT, VS Code, Cursor) — "build once and integrate everywhere" — to demonstrate it is not a single-vendor format [mcp-home].
- DTI (dtinit.org) frames itself as "a nonprofit organization dedicated to empowering technology users" and credits partners (Google, Meta, Apple) as "translating principle to practice", but the homepage lacks a visible board roster, membership structure, or funding-transparency / conflict-of-interest disclosure [dtinit].
- Solid anchors credibility on Tim Berners-Lee (named with full title "Sir Tim Berners-Lee") but leaves governance structure, W3C affiliation, and editorial boards off the homepage [solid].

### Register / tone / conspicuous absences

- W3C's homepage conspicuously omits signup CTAs, freemium offers, product launches, urgency language ("Limited time", "Act now"), social-proof metrics (user counts, testimonials), and stock photography [w3c-home].
- oauth.net conspicuously avoids marketing language, vendor promotion, interactive tooling/wizards, comparative protocol analysis, implementation tutorials, and editorial advocacy for specific grant types — "academic-leaning documentation prioritizing reference completeness over persuasion" [oauthnet].
- json-schema.org conspicuously omits pricing/commercialization, competitive positioning against other schema languages, and vertical use-case specificity (banking/healthcare) — "pure open infrastructure" [jsonschema].
- The registers cluster as "formal yet inclusive" (W3C), "professional yet mission-driven" (DTI), "aspirational yet measured" (Solid), and "professional and educational" without marketing flourish (OpenID, OpenAPI); functional verb framing ("defines a mechanism", "enables sharing") replaces promotional language [w3c-home][dtinit][solid][openid-specs][openapis-org].

### Typography / design restraint

- The spec surfaces exhibit extreme typographic restraint: monospace for code/ABNF, bold for field names, italics sparingly, hierarchical numbered headings, no colored text or decorative elements — "readability and reference accuracy over visual sophistication" [rfc9110][oas-latest][w3c-activitypub].
- The org/marketing surfaces are minimal but slightly warmer: ample whitespace, restrained/monochromatic palette (json-schema.org blues-and-whites), icon-led nav, content hierarchy over embellishment [w3c-home][jsonschema][solid].

### Participation funnel

- Participation funnels are consistently multi-tier and escalating: json-schema.org routes Awareness (blog) → low-friction community (Slack) → contribution (GitHub, office hours) → sponsorship (OpenCollective) [jsonschema].
- Standard participation destinations recur across sites: GitHub repo + issues tracker, a chat/forum (Slack, Matrix, Discourse), working-group/community-group pages, mailing lists, and a "Join the Foundation"/membership path; W3C additionally exposes an Invited Expert track for individuals [w3c-home][jsonschema][solid][openid-specs][mcp-spec].
- MCP routes contribution through a "/community/contributing" page linked directly from the spec's "Learn More" cards, keeping the contribution door adjacent to the normative document [mcp-spec].

### Implementations listing

- Implementations are consistently delegated to a separate registry/landscape surface rather than listed inline: oauth.net delegates to a "/code/" section; json-schema.org delegates to a dedicated "Landscape" page and searchable Tools section ("Validators, Generators, Linters") to prevent homepage bloat [oauthnet][jsonschema].
- W3C TR pages link a dedicated Implementation Report demonstrating real-world adoption as evidence of interoperability (part of the Recommendation-track process) [w3c-activitypub].

## SOURCES

**w3c-home**
URL: https://www.w3.org/
Accessed: 2026-07-09
Quote: "No single organization dominates the visual hierarchy." / Nav: Standards & groups, Get involved, Resources, News & events, About. Conspicuously omits signup CTAs, urgency language, social-proof metrics.

**w3c-activitypub**
URL: https://www.w3.org/TR/activitypub/
Accessed: 2026-07-09
Quote: "W3C Recommendation 23 January 2018" with header block This version (dated URI) / Latest published version / Latest editor's draft (GitHub) / Previous version; editors + authors with homepage links; GitHub issues, Implementation Report, Errata, Translations.

**dtinit**
URL: https://dtinit.org/
Accessed: 2026-07-09
Quote: "a nonprofit organization dedicated to empowering technology users"; partners (Google, Meta, Apple) "translating principle to practice"; homepage lacks board roster / funding disclosure.

**solid**
URL: https://solidproject.org/
Accessed: 2026-07-09
Quote: Dual "For Users" / "For Developers" doors; specs reached via a single footer "/TR" link; anchored on "Sir Tim Berners-Lee"; governance/W3C-affiliation off the homepage.

**oauthnet**
URL: https://oauth.net/2/
Accessed: 2026-07-09
Quote: "the industry-standard protocol for authorization"; two-tier linking (topic pages → normative RFC 6749/6750); authority dispersed across IETF OAuth WG, OpenID Foundation, Kantara, W3C; delegates implementations to "/code/".

**jsonschema**
URL: https://json-schema.org/
Accessed: 2026-07-09
Quote: Nav Specification / Docs / Tools / Community / Blog; sponsorship tiers Gold/Silver/Bronze; "monthly Office Hours and Open Community Working Meetings"; "60 million weekly downloads", "5000+ practitioners"; tools delegated to a "Landscape" page.

**openapis-org**
URL: https://www.openapis.org/
Accessed: 2026-07-09
Quote: "The world's most widely used API description standard"; "within The Linux Foundation"; menu links to Technical Steering Committee, Technical Oversight Board, Code of Conduct; under-emphasizes member logos; points out to spec.openapis.org.

**openapis-spec**
URL: https://spec.openapis.org/
Accessed: 2026-07-09
Quote: "This site contains the authoritative HTML renderings of the OpenAPI Initiative's specifications and extension registries." Permalinks `/oas/latest.html`, `/arazzo/latest.html`, `/overlay/latest.html`; defers to "Learn OpenAPI" + "OpenAPI Tooling".

**oas-latest**
URL: https://spec.openapis.org/oas/latest.html
Accessed: 2026-07-09
Quote: "OpenAPI Specification v3.2.0", "Version 3.2.0", "19 September 2025"; This version / Latest published / Editor's draft; prior versions v2.0–v3.1.2; nine current + five former editors; "Appendix A: Revision History"; RFC 2119 / BCP 14 keywords.

**mcp-home**
URL: https://modelcontextprotocol.io/
Accessed: 2026-07-09
Quote: "MCP (Model Context Protocol) is an open-source standard for connecting AI applications to external systems." "Think of MCP like a USB-C port for AI applications." Cross-vendor support list (Claude, ChatGPT, VS Code, Cursor); build-server/build-client/apps cards.

**mcp-spec**
URL: https://modelcontextprotocol.io/specification/2025-06-18
Accessed: 2026-07-09
Quote: "This specification defines the authoritative protocol requirements, based on the TypeScript schema in schema.ts." Date-string versioning (2025-06-18); RFC2119/BCP14 keyword boilerplate; Contributing card → /community/contributing.

**openid-specs**
URL: https://openid.net/developers/specs/
Accessed: 2026-07-09
Quote: Three tiers — Final Specifications ("OpenID Foundation standards" with IP protections), Implementer's Drafts, Active Drafts; grouped by working group (AB/Connect, FAPI, eKYC & IDA); dedicated errata/obsolete sections; "Join the OpenID Foundation" path.

**rfc9110**
URL: https://www.rfc-editor.org/rfc/rfc9110.html
Accessed: 2026-07-09
Quote: Header block — stream "Internet Engineering Task Force (IETF)", RFC 9110, STD 97, obsoletes chain, "Standards Track", "June 2022", "ISSN: 2070-1721", editors with affiliations. "Status of This Memo": "consensus of the IETF community" + IESG approval; "BCP 78 and the IETF Trust's Legal Provisions"; RFC 2119 ALL-CAPS keywords; ¶ paragraph anchors.

## SYNTHESIS

### The canonical anatomy of a credible young-protocol site

There is a single repeatable pattern. A credible standards/protocol site is **two surfaces with one seam between them**, plus a fixed set of trust primitives on each.

**Surface 1 — the neutral org shell** (`example.org`, `openapis.org`, `modelcontextprotocol.io`, `oauth.net`). Its job is *legitimacy and onboarding*, not persuasion. Anatomy:
- **Entry doors by audience, not by feature.** Almost every site splits "user/newcomer" from "developer/implementer" (Solid's For-Users/For-Developers; MCP's explainer vs build-cards; oauth.net's topic-pages-as-gateways). The homepage answers "what is this and who's behind it," then routes.
- **A short, unhyped one-liner** in functional register ("the industry-standard protocol for authorization", "an open-source standard for connecting AI applications", "the world's most widely used API description standard"). No urgency, no CTA-to-signup, no testimonials, no pricing.
- **Governance made navigable.** A dedicated menu to charter / steering committee / oversight board / code of conduct (OpenAPI is the exemplar), OR neutrality-by-pluralism (oauth.net dispersing authority across four bodies), OR neutrality-by-anti-favoritism (W3C rotating member logos, "no single org dominates").
- **A foundation/neutral-home affiliation** stated plainly ("within The Linux Foundation", "OpenID Foundation standards", W3C process) — this is the single strongest credibility signal a *young* protocol can buy, because it transfers an existing institution's neutrality.
- **An escalating participation funnel**: awareness (blog) → low-friction chat (Slack/Matrix/Discourse) → GitHub (issues + contributing guide) → working/community group → membership. The contribution door sits close to both the spec and the docs.
- **Implementations delegated to a registry/landscape**, never listed inline — this both keeps the homepage clean and signals "we don't pick winners."

**Surface 2 — the austere normative spec** (`spec.example.org`, `/TR/...`, `/specification/<date>`, an RFC). Its job is *authority and citability*. It is visually plainer than the org site on purpose. Anatomy — the **header contract** every credible spec shares:
1. **A status/maturity banner** ("W3C Recommendation", "Standards Track", "Final Specification", or a dated MCP version) — the reader must know in one glance how load-bearing the document is.
2. **A version metadata block**: *This version* (immutable dated permalink) + *Latest version* (moving pointer) + *Editor's draft* (GitHub) + *Previous version*. The dated-permalink/latest-pointer pair is non-negotiable — it's what makes a citation survive the next revision.
3. **Named editors/authors** (with affiliations or homepages) — accountability has a face.
4. **A provenance/legal footer**: consensus process + IP/trust terms (IETF Trust, OpenID IP protections, W3C process).
5. **RFC 2119 / BCP 14 normative keywords** in ALL CAPS with the standard boilerplate — this is the universal "we are a real spec" tell.
6. **A changelog / revision history / errata** surface.
7. **Deep-linkable structure**: numbered hierarchical ToC + per-section (ideally per-paragraph, à la RFC ¶) anchors.
8. Increasingly, **a machine-readable source of truth** cited as authoritative (MCP's `schema.ts`, OpenAPI's schema) — the prose renders the schema, not vice versa.

### Variants (the pattern flexes on two axes)

- **Formal ↔ approachable.** RFC/W3C sit at the austere pole (monospace, no color, legal boilerplate). MCP and json-schema.org sit at the approachable pole (USB-C metaphor, "Build more. Break less.", Slack-first). The *spec surface* stays austere in both; only the *org shell* warms up. A young protocol can be friendly at the front door but must be austere at the spec.
- **Institution-backed ↔ figurehead-backed.** OpenAPI/OpenID/W3C derive neutrality from a foundation + visible governance bodies. Solid and (partly) DTI lean on a named authority (Berners-Lee) or marquee partners instead — and both pay for it with the **conspicuous credibility gap** the fetches flagged: no board roster, no funding/COI disclosure, governance off the homepage. This is the anti-pattern to avoid: partner logos are not governance, and a famous name is not a process.

### What credibility actually reduces to

Restraint IS the signal. Every site earns authority by what it refuses to do — no marketing, no urgency, no vanity metrics-as-persuasion (adoption numbers appear only as evidence of interoperability, never as hype), no inline vendor promotion. The trust stack, in priority order: (1) a real neutral home + navigable governance; (2) a citable spec with the full header contract; (3) an open, escalating participation path; (4) delegated, non-favoring implementation listings; (5) visual restraint that matches the seriousness. A young protocol that wants to read as credible should copy this stack literally — and should treat the org/spec split as the first architectural decision, not an afterthought.
