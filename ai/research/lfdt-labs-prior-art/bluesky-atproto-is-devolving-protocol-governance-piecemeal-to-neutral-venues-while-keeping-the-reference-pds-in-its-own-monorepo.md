---
title: "Bluesky AT Protocol is the closest structural analog to PDP-Connect (spec plus PDS reference implementation plus app), and it is devolving protocol governance to neutral venues piecemeal (IETF for core sync, a Swiss Association for identity) rather than via one all-encompassing foundation, while keeping the reference PDS in the same monorepo as the spec's lexicons; Home Assistant shows the connector-ecosystem side with a nonprofit-owned core and a tiered, machine-checked integration quality scale"
date: 2026-08-14
topic: lfdt-labs-prior-art
tags: [bluesky, atproto, lexicon, xrpc, pds, federation, ietf, home-assistant, integration-quality-scale, manifest-versioning, hacs, foundation-governance]
status: draft
sources: [atproto-checkin-2025, atproto-plc-org, atproto-ietf-wg-kickoff, atproto-ietf-charter, atproto-lexicon-spec, atproto-lexicon-versioning-example, atproto-pds-repo-structure, atproto-pds-standalone-repo, atproto-self-hosting-guide, atproto-pds-interop-discussion, atproto-federation-architecture, atproto-proxy-header-discussion, atproto-rkey-ambiguity, ha-open-home-foundation, ha-manifest-docs, ha-quality-scale-adr, ha-quality-scale-docs, ha-hacs-blog, ha-changelog-example]
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

### Bluesky AT Protocol (atproto)

- Bluesky is a Public Benefit Corporation (PBC), not a nonprofit, and its own Fall 2025 protocol check-in explicitly frames protocol governance as needing to survive shifts in Bluesky's own commercial incentives: "The governance of the protocol should outlive Bluesky and be resilient to shifts in the incentive structure that could compromise a future Bluesky PBC." [atproto-checkin-2025]
- Bluesky ties the need for neutral governance directly to third-party ecosystem investment: "As the Atmosphere matures and more devs are putting time and resources into building companies/projects in the ecosystem, we believe it's our responsibility to ensure that the protocol has a neutral long-term governance structure around it." [atproto-checkin-2025]
- As of the Fall 2025 check-in, there is no single all-encompassing foundation covering the whole protocol; governance is being devolved piecemeal to different neutral venues per sub-system (identity infrastructure to a Swiss Association; the core sync/repo protocol to the IETF) rather than transferred to one steward at once. [atproto-checkin-2025] [atproto-plc-org] [atproto-ietf-wg-kickoff]
- Bluesky announced a Patent Non-Aggression Pledge in October 2025 as a concrete legal step layered on top of already-permissive licensing: "Our SDKs and reference implementations are all open source and licensed under permissive software licenses," with the pledge providing "additional assurance around patent rights." [atproto-checkin-2025]
- Identity governance has a concrete, named legal vehicle in progress: an independent Swiss Association is being formed to own and operate the PLC (Public Ledger of Credentials) DID directory, separating that piece of core infrastructure from Bluesky PBC: "the new entity will form as a Swiss Association," which "will set policies and rate-limits, hold any related intellectual property, and coordinate future evolution of the system." [atproto-plc-org]
- The PLC entity is explicitly scoped as a general-purpose, vendor-neutral public good and explicitly NOT presented as the final governance answer: "it will be developed and operated as a vendor- and application-neutral public good," and "this organization is not expected to be the final governance structure for PLC — nor is a single global directory expected to be the final technical architecture for the system." [atproto-plc-org]
- Core protocol standardization (the sync/repo layer) has moved to a chartered IETF working group, a genuine transfer of spec authorship to a venue outside Bluesky's own repo and governance: "an Authenticated Transfer Protocol (ATP) working group has been created at the IETF," and "we're proud that the core protocol will have a home outside of and independent from Bluesky PBC," providing "a neutral venue where anybody with time and interest can participate in the standardization process for ATP." [atproto-ietf-wg-kickoff]
- The IETF working group's scope is deliberately narrow, covering only the wire-format/sync layer and explicitly excluding Bluesky's own application semantics: in-scope is "the public repository data structure, mechanism for synchronizing public repositories (e.g., the firehose), the AT URI scheme, requirements for account identifier resolution systems"; explicitly out of scope is "non-public data, application-specific data schemas or APIs, lexicon publication, the labeling moderation system." [atproto-ietf-wg-kickoff] [atproto-ietf-charter]
- Lexicon schema versioning has a formal, published compatibility rule set requiring bidirectional validity across a schema change: "all old data must still be valid under the updated Lexicon, and new data must be valid under the old Lexicon." Disallowed changes include "Non-optional fields can not be removed," "Types can not change," and "Fields can not be renamed"; allowed changes include "Any new fields must be optional." [atproto-lexicon-spec]
- Breaking Lexicon changes require minting an entirely new schema name (NSID) rather than an in-place version bump — the spec states "a new Lexicon name must be used," and the ecosystem convention observed in practice is appending a version suffix, e.g. `app.bsky.actor.defs#savedFeedsPrefV2`. [atproto-lexicon-spec] [atproto-lexicon-versioning-example]
- Lexicon deprecation is a social/best-practice norm, not a hard formal policy enforced by tooling: "Public adoption and implementation by a third party, even without explicit permission, indicates that the Lexicon has been released and should not break compatibility" — fields are marked deprecated and retained rather than removed on any fixed timeline. [atproto-lexicon-spec]
- The reference PDS implementation lives in the same monorepo as the spec's canonical lexicon definitions (`bluesky-social/atproto`, under `packages/pds` and `./lexicons/`), while self-hosting deployment tooling for that same reference PDS is split into a separate, thin wrapper repo (`bluesky-social/pds`) containing just a Docker Compose file and docs. [atproto-pds-repo-structure] [atproto-pds-standalone-repo]
- Third-party PDS implementations exist in other languages (e.g., a Go implementation and at least one Rust implementation) and are officially listed by Bluesky in its own self-hosting guide alongside the TypeScript reference implementation, but there is no formal cross-implementation conformance test suite; compatibility is validated informally, e.g. via shared CAR-file round-trip tests that check a re-exported repository's content hash matches the original. [atproto-self-hosting-guide] [atproto-pds-interop-discussion]
- Federation architecture separates three roles with different write/read authority: the PDS is sole write authority for a user's data ("the PDS is the sole write source; clients never write to a relay or AppView"), the Relay is an optional fan-in/fan-out aggregator of the firehose, and the AppView is a product-specific read/index layer — clients never write directly to a Relay or AppView. [atproto-federation-architecture]
- Service/version negotiation across the federation graph happens via explicit HTTP headers rather than embedded protocol version numbers — an "Atproto-Proxy"-style header lets a client "control which service should be used for a given request... specifying a DID and service fragment identifier," and a separate labeler-selection mechanism works "somewhat similar to HTTP content negotiation for language or encoding." [atproto-proxy-header-discussion]
- No named, well-documented fragmentation incident (e.g., a breaking Lexicon change causing mass AppView/feed-generator breakage) was found despite deliberate search. The closest evidence of divergence pressure is (a) an acknowledged spec ambiguity around an undocumented rkey length limit not actually enforced in code but assumed by some clients, and (b) the existence of a distinct community fork of the atproto repo ("Blacksky") built around AppView performance/community features — neither confirmed as a "break." This absence is reported as an unconfirmed-negative finding, not a positive claim that no incident exists. [atproto-rkey-ambiguity]

### Home Assistant (core vs. integrations)

- Home Assistant Core and the Home Assistant brand are owned by a Swiss nonprofit, the Open Home Foundation, not by a company; governance was deliberately separated from the commercial entity in April 2024. The Foundation "owns and governs over 250 open-source projects" including Home Assistant and ESPHome. [ha-open-home-foundation]
- Nabu Casa (the commercial entity historically most associated with Home Assistant) is explicitly a funding partner of the Foundation, not its owner: "Nabu Casa is a commercial partner of the Open Home Foundation... it contributes a majority of its profits from selling official Home Assistant products to supporting the foundation." [ha-open-home-foundation]
- Per-integration compatibility is managed through a `manifest.json` file, including a `requirements` field that pins exact Python dependency versions (e.g. `"requirements": ["aiohue==1.9.1"]`) and a `quality_scale` field declaring the integration's certified tier (e.g. `"quality_scale": "platinum"`). [ha-manifest-docs]
- The Integration Quality Scale (Bronze/Silver/Gold/Platinum, revised November 2024) is a formal tiered certification with a stated purpose: "We have established the integration quality scale to ensure a high-quality and consistent user and contributor experience for our open-source project." [ha-quality-scale-adr]
- Quality Scale compliance is file-tracked and CI-checked, not purely aspirational: each integration ships a `quality_scale.yaml` listing implemented/exempt rules, its manifest declares the achieved tier, and rules are validated by `hassfest`, Home Assistant's own manifest/metadata linter run in CI. [ha-quality-scale-docs]
- Quality Scale tiers are not permanent: an integration can be automatically downgraded if it stops meeting a tier's rules — e.g., losing an active code owner is cited as a trigger for demotion to Bronze. [ha-quality-scale-docs]
- Gold tier is a stated gate for the separate "Works with Home Assistant" hardware certification program, giving the internal quality scale an external commercial consequence beyond code review. [ha-quality-scale-docs]
- HACS (Home Assistant Community Store), the third-party/community integration channel, is explicitly outside Home Assistant Core's review regime despite being an Open Home Foundation collaboration partner: listed integrations are "maintained by the community members that upload them, not HACS or Home Assistant," and "These are community-made projects that do not receive the same rigorous reviews required of projects submitted to Home Assistant." [ha-hacs-blog]
- Home Assistant's monthly release process has documented process guardrails against ecosystem-wide breakage — a public beta before every stable release, automatic pre-update backups, and a mandatory "Backward-incompatible changes" section in every release's changelog — but this is a process/documentation discipline, not a hard technical compatibility contract comparable to atproto's bidirectional Lexicon-validity rule. [ha-changelog-example]

## SOURCES

**atproto-checkin-2025**
URL: https://atproto.com/blog/protocol-check-in-fall-2025 (mirrored at https://docs.bsky.app/blog/protocol-checkin-fall-2025)
Accessed: 2026-08-14
Quote: "The governance of the protocol should outlive Bluesky and be resilient to shifts in the incentive structure that could compromise a future Bluesky PBC." / "As the Atmosphere matures and more devs are putting time and resources into building companies/projects in the ecosystem, we believe it's our responsibility to ensure that the protocol has a neutral long-term governance structure around it." / "Our SDKs and reference implementations are all open source and licensed under permissive software licenses."

**atproto-plc-org**
URL: https://atproto.com/blog/plc-directory-org
Accessed: 2026-08-14
Quote: "the new entity will form as a Swiss Association... will set policies and rate-limits, hold any related intellectual property, and coordinate future evolution of the system." / "it will be developed and operated as a vendor- and application-neutral public good." / "this organization is not expected to be the final governance structure for PLC — nor is a single global directory expected to be the final technical architecture for the system."

**atproto-ietf-wg-kickoff**
URL: https://atproto.com/blog/kicking-off-the-atp-working-group
Accessed: 2026-08-14
Quote: "an Authenticated Transfer Protocol (ATP) working group has been created at the IETF." / "we're proud that the core protocol will have a home outside of and independent from Bluesky PBC." / "provides a neutral venue where anybody with time and interest can participate in the standardization process for ATP." Scope: in — "the public repository data structure, mechanism for synchronizing public repositories (e.g., the firehose), the AT URI scheme, requirements for account identifier resolution systems"; out — "non-public data, application-specific data schemas or APIs, lexicon publication, the labeling moderation system."

**atproto-ietf-charter**
URL: https://datatracker.ietf.org/doc/charter-ietf-atp/
Accessed: 2026-08-14
Quote: IETF ATP working group charter, corroborating scope boundaries described in atproto-ietf-wg-kickoff.

**atproto-lexicon-spec**
URL: https://atproto.com/specs/lexicon
Accessed: 2026-08-14
Quote: "all old data must still be valid under the updated Lexicon, and new data must be valid under the old Lexicon." / "Non-optional fields can not be removed." / "Types can not change." / "Fields can not be renamed." / "Any new fields must be optional." / "a new Lexicon name must be used" (for breaking changes). / "Public adoption and implementation by a third party, even without explicit permission, indicates that the Lexicon has been released and should not break compatibility."

**atproto-lexicon-versioning-example**
URL: https://github.com/orgs/lexicon-community/discussions/30
Accessed: 2026-08-14
Quote: Community discussion citing real production example of versioned-name convention, `app.bsky.actor.defs#savedFeedsPrefV2`.

**atproto-pds-repo-structure**
URL: https://github.com/bluesky-social/atproto/tree/main/packages/pds
Accessed: 2026-08-14
Quote: Reference PDS implementation lives under `packages/pds` in the same monorepo (`bluesky-social/atproto`) that holds the canonical lexicon JSON definitions under `./lexicons/`.

**atproto-pds-standalone-repo**
URL: https://github.com/bluesky-social/pds
Accessed: 2026-08-14
Quote: Separate, thin repo providing Docker Compose deployment tooling and docs for self-hosting the reference PDS, distinct from the monorepo holding its source and the spec.

**atproto-self-hosting-guide**
URL: https://atproto.com/guides/self-hosting
Accessed: 2026-08-14
Quote: Lists third-party PDS implementations including a Rust implementation ("Tranquil PDS") and a Go implementation ("Cocoon") alongside the official TypeScript reference implementation.

**atproto-pds-interop-discussion**
URL: https://github.com/bluesky-social/atproto/discussions/2644
Accessed: 2026-08-14
Quote: Community discussion describing informal interop validation approach: "read in the repo (from CAR file or description) into an array or some other simple data structure, then re-produce/re-export the repo and validate the sha matches."

**atproto-federation-architecture**
URL: https://docs.bsky.app/docs/advanced-guides/federation-architecture
Accessed: 2026-08-14
Quote: "the PDS is the sole write source; clients never write to a relay or AppView."

**atproto-proxy-header-discussion**
URL: https://github.com/bluesky-social/atproto/discussions/2293
Accessed: 2026-08-14
Quote: An "Atproto-Proxy"-style header lets a client "control which service should be used for a given request... specifying a DID and service fragment identifier"; a separate labeler-selection mechanism is described as working "somewhat similar to HTTP content negotiation for language or encoding."

**atproto-rkey-ambiguity**
URL: https://github.com/bluesky-social/atproto/discussions/4611
Accessed: 2026-08-14
Quote: Discussion of an undocumented/ambiguous rkey length limit assumed by clients but not actually enforced in the reference implementation's code — cited as the closest found evidence of spec-vs-implementation ambiguity, not a confirmed fragmentation incident. (Related: a community fork, https://github.com/blacksky-algorithms/atproto, exists around AppView performance/community features, cited as separate weak evidence of divergence pressure.)

**ha-open-home-foundation**
URL: https://apolloautomation.com/blogs/news/who-owns-home-assistant-the-open-home-foundation-nabu-casa-and-apollo-automation-explained ; https://www.howtogeek.com/whats-the-deal-with-the-open-home-foundation-owner-of-home-assistant/
Accessed: 2026-08-14
Quote: "we are a non-profit and can't be sold or acquired." The Open Home Foundation "owns and governs over 250 open-source projects" including Home Assistant and ESPHome. "Nabu Casa is a commercial partner of the Open Home Foundation... it contributes a majority of its profits from selling official Home Assistant products to supporting the foundation."

**ha-manifest-docs**
URL: https://developers.home-assistant.io/docs/creating_integration_manifest/
Accessed: 2026-08-14
Quote: Example manifest fields: `"requirements": ["aiohue==1.9.1"]`, `"quality_scale": "platinum"`.

**ha-quality-scale-adr**
URL: https://github.com/home-assistant/architecture/blob/master/adr/0022-integration-quality-scale.md
Accessed: 2026-08-14
Quote: "We have established the integration quality scale to ensure a high-quality and consistent user and contributor experience for our open-source project."

**ha-quality-scale-docs**
URL: https://developers.home-assistant.io/docs/core/integration-quality-scale/
Accessed: 2026-08-14
Quote: Describes per-integration `quality_scale.yaml` rule tracking, `hassfest` CI validation, automatic downgrade ("it is also possible for an integration to be downgraded to a lower tier," citing loss of an active code owner as a trigger for demotion to Bronze), and Gold tier as a gate for the "Works with Home Assistant" hardware program.

**ha-hacs-blog**
URL: https://www.home-assistant.io/blog/2024/08/21/hacs-the-best-way-to-share-community-made-projects/
Accessed: 2026-08-14
Quote: "This means these are maintained by the community members that upload them, not HACS or Home Assistant." / "These are community-made projects that do not receive the same rigorous reviews required of projects submitted to Home Assistant."

**ha-changelog-example**
URL: https://www.home-assistant.io/changelogs/core-2026.8/ ; https://www.home-assistant.io/changelogs/core-2026.7/ ; https://www.home-assistant.io/faq/do-updates-break-things/
Accessed: 2026-08-14
Quote: Release changelogs carry a mandatory "Backward-incompatible changes" section; FAQ page describes public beta before every stable release and automatic pre-update backups as the process guardrails against ecosystem-wide breakage.

## SYNTHESIS

Bluesky/atproto is the best-shaped analog PDP-Connect has, and its ANSWER to "how much should the neutral entity own the reference implementation" is genuinely instructive: don't try to solve it in one move. Bluesky is explicitly NOT waiting for a single perfect foundation before it starts devolving governance — it is peeling off pieces as they become ready (identity infra to a purpose-built Swiss Association because that's the piece with the clearest "public good, needs neutral rate-limiting and IP holding" shape; core sync/repo protocol to the IETF because that's the piece that most resembles a classical wire-format standard) while leaving the reference PDS implementation and lexicon publication process inside Bluesky PBC for now, with an explicit public statement that governance work is ongoing and incomplete. For PDP-Connect, this suggests: don't block the pdpp/data-connectors/data-connect split on deciding the FINAL neutral-ownership model for data-connect. Split the repos now (structural/legal separation of concerns), and treat "does a neutral foundation eventually own data-connect the way OWF owns reference wallets" as a separate, later decision — exactly as Bluesky treats "does a neutral foundation eventually own the whole protocol" as unresolved while still shipping concrete, scoped governance moves today.

The Lexicon versioning rule (`old data must validate under new schema AND new data must validate under old schema`, breaking changes require a wholly new schema name rather than a version bump) is the single most directly transferable mechanism to `data-connectors` pinning against `pdpp`/`data-connect`. It sidesteps semver-style compatibility promises entirely: instead of "v2 of this field is backward compatible with v1," the rule is "if it isn't bidirectionally valid, it isn't the same schema — give it a new name." Applied to connector manifests: rather than connectors declaring "compatible with pdpp >=1.2, <2.0," a `data-connectors` manifest could declare which NAMED schema versions of each PDPP object type it reads/writes (e.g. `com.pdpp.order#v1` vs `com.pdpp.order#v2`), and `data-connect` could dispatch on that name rather than doing semver range matching. This trades version-range flexibility for hard clarity about exactly what shape of data is being exchanged — a good fit for a personal-data protocol where silent, partially-compatible schema drift is a correctness bug, not just an inconvenience.

The one negative finding worth flagging honestly: despite real search effort, no documented fragmentation/breakage INCIDENT was found for atproto (unlike Matrix, which has a citable federation-break issue). This could mean atproto's mechanisms are working, or it could mean the ecosystem is still too young/small (few independent PDS implementations, most traffic still through Bluesky's own infrastructure) for drift to have surfaced yet — the corpus should not claim atproto's approach is proven at scale, only that it is well-specified.

Home Assistant answers the OTHER PDP-Connect question directly: how does a rapid-release core stay usable with thousands of independently-maintained plugins. Two mechanisms transfer cleanly: (1) manifest-level exact-version pinning of dependencies (not the core itself, but each integration's OWN third-party library dependencies) combined with a machine-checked, CI-enforced quality tier that can be lost automatically (not just gained once) — `data-connectors` could adopt a similar per-connector `quality_scale.yaml` + `hassfest`-style linter, gating things like "has an active maintainer," "has tests," "handles errors per the connector contract," with automatic downgrade if the bar stops being met; (2) an explicit two-tier trust model (core-bundled/reviewed integrations vs HACS community integrations with a real, named lower bar and no pretense of equal rigor) — PDP-Connect should decide up front whether ALL `data-connectors` entries get the same review bar or whether there's a "core-blessed" vs "community-contributed, lower bar, clearly labeled" split, rather than letting that distinction emerge accidentally. Home Assistant's core/brand ownership by a nonprofit (Open Home Foundation) funded by, but not controlled by, a commercial partner (Nabu Casa) is structurally the cleanest of all the precedents surveyed across this whole research effort — cleaner than Matrix's foundation (which stayed financially dependent) and closer to OWF's model than to HL7/HAPI's. It is a strong second data point (after OWF) for "the neutral entity should own the core/reference-implementation brand outright, with the commercial company as an explicitly subordinate funding partner, not the other way around."
