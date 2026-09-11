---
title: "GliaNet's Net Fiduciary certification ladder defines legal duties for AI agents but has no protocol, spec, or enforcement mechanism of its own, and its own convenings name 'map existing protocols to loyalty definitions' as an open gap"
date: 2026-09-10
topic: consent-regimes
tags: [fiduciary, ai-agents, certification, trust-frameworks, glianet, information-fiduciaries]
status: draft
sources: [glianet-pledge, whitt-old-school, khan-pozen, cr-glianet, kwaainet, stanford-hcp, utah-sb275]
source_session: d2141e7d-8e99-4ad0-bc09-f089e4597605
---

## CLAIMS

- GliaNet Alliance is a 501(c)(3) (Richard Whitt president; Estefanie Govea Director of Community Engagement & Outreach, previously Circl.es), ~25 members incl. Consumer Reports, Personal.ai, JLINC, Kwaai; initial Omidyar Network backing. [glianet-pledge]
- Its **PEP model** maps three duties to three roles: Protect/Guardian/care, Enhance/Mediator/fidelity ("the Fidelity Gap"), Promote/Advocate/loyalty. [glianet-pledge]
- The **Net Fiduciary certification ladder** has five tiers: Pledge → Caretaker → Partner → Advocate → Steward. Tier 1 is free and self-executed — the company writes PEP duties into its own ToS; GliaNet does not certify or monitor and "recourse lies solely with the company." Tiers 2-5 and the Standards Board are explicitly "in development." [glianet-pledge]
- **GliaNet publishes no spec, protocol, schema, or reference code of its own.** The only running code in the ecosystem is a member project, Kwaai's KwaaiNet, which implements the pledge as a revocable W3C Verifiable Credential on a ToIP/DIF trust graph — a member's independent build, not a GliaNet deliverable. [kwaainet]
- A joint Consumer Reports/GliaNet convening recorded next-steps including **"map existing protocols to loyalty definitions"** — i.e. they publicly acknowledge PEP floats without mechanism. [cr-glianet]
- Whitt's theory (Santa Clara High Tech L.J. 2020) builds on Balkin/Zittrain information fiduciaries and **engages the Khan/Pozen rebuttal by sidestepping it**: rather than imposing duties on structurally conflicted incumbents, he proposes a new *voluntary opt-in intermediary class* ("Net Fiduciary", formerly "digital trustmediary") that contracts into the duties. This is a different theory of change from Balkin's, and naming that distinction is the tell that someone has actually read him. [whitt-old-school, khan-pozen]
- Whitt's coinages: **SEAMS cycle** (Surveillance→Extraction→Analysis→Manipulation), **agenticity vs agentiality** (raw capability vs authorized-to-represent), **"double agents"** (an agent claiming to serve you while serving its builder). [whitt-old-school]
- **Utah SB 275 (May 2026)** is their strongest legal hook — described as the first US statute imposing a duty of loyalty on digital-identity intermediaries. One statute, not a body of law. [utah-sb275]
- **Name collision:** the active Stanford-affiliated "Human Context Protocol" is Stanford HAI / Digital Economy Lab's **Loyal Agents** project at hcp.loyalagents.org (SSRN #5403981, July 2025, co-authors across Stanford HAI, Google DeepMind, Microsoft Research, Plurality Institute) — an MCP-style protocol with schema-definition/preference-search/preference-update tools. The site **humancontextprotocol.com is unaffiliated and stale** ("Coming Summer 2025", copyright 2026, no spec or repo). [stanford-hcp]

## SOURCES

**glianet-pledge**
URL: https://glianetalliance.org/#pledge
Accessed: 2026-09-10
Quote: "recourse lies solely with the company" (tier-1 pledge; no independent verification or monitoring by GliaNet)

**whitt-old-school**
URL: https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3427479
Accessed: 2026-09-10
Quote: "Old School Goes Online: Exploring Fiduciary Obligations of Care and Loyalty in the Platforms Era", 36 Santa Clara High Tech. L.J. 75 (2020)

**khan-pozen**
URL: https://harvardlawreview.org/print/vol-133/a-skeptical-view-of-information-fiduciaries/
Accessed: 2026-09-10
Quote: "A Skeptical View of Information Fiduciaries" — the standard rebuttal, arguing the concept is incoherent for platforms whose business model structurally conflicts with the user's interest

**cr-glianet**
URL: https://innovation.consumerreports.org/
Accessed: 2026-09-10
Quote: "map existing protocols to loyalty definitions" (recorded convening next-step)

**kwaainet**
URL: https://github.com/Kwaai-AI-Lab/KwaaiNet
Accessed: 2026-09-10
Quote: GliaNet pledge implemented as a revocable W3C Verifiable Credential in a ToIP/DIF-style decentralized trust graph

**stanford-hcp**
URL: https://hcp.loyalagents.org/
Accessed: 2026-09-10
Quote: Stanford HAI / Digital Economy Lab "Loyal Agents" — HCP server exposing schema-definition, preference-search and preference-update tools to any LLM client

**utah-sb275**
URL: https://glianetalliance.org/
Accessed: 2026-09-10
Quote: Utah SB 275 (May 2026), characterised by GliaNet as the first US statute imposing a duty of loyalty on digital-identity intermediaries

## SYNTHESIS

This is the fiduciary-layer counterpart to [[india-account-aggregator-proves-machine-readable-consent-objects-can-operate-at-national-scale]]. That entry establishes what makes machine-readable consent work at scale (closed taxonomy, recipient drafts, user narrows/accepts/revokes). This entry establishes the layer *above* it: who owes the user a duty once access is granted — and that this layer currently has **no mechanism at all**.

The load-bearing asymmetry for PDPP: a fiduciary duty is mechanically empty on its own. Nothing in fiduciary law specifies how an agent knows what it may touch, what it touched, or how the user cuts it off. Scoped, time-bound, revocable, machine-checkable grants are exactly that missing substrate — and they are the direct technical answer to Whitt's own "double agent" fear (GliaNet's current answer to a rogue agent is "the pledge says don't"; a grant expires or is revoked and the resource server enforces it).

**But the fit has a hard limit worth stating in any engagement: scope-compliance is not loyalty.** A protocol can prove an agent stayed inside its grant; it cannot prove that acting inside the grant served the user's interest. An agent can honour every constraint and still steer the user toward a worse option because of an undisclosed conflict. GliaNet's Enhance/Promote tiers are about conduct and disclosure — business logic a consent protocol does not and should not try to solve. Nor does a grant carry any first-class representation of the fiduciary relationship itself; that attestation problem is trust-registry territory (Drummond Reed's First Person Project / ToIP Decentralized Trust Graph WG), not authorization territory.

The non-obvious inversion, and the most useful line to carry forward: **running your own personal data server makes you want fiduciary agents more, not less.** The naive expectation is the opposite — own the store, remove the intermediary, shrink the trust problem. It doesn't shrink; it changes shape. Owning the server makes granting cheap, so you delegate to *more* agents, not fewer (the same dynamic that made "Sign in with X" viral). Once granting is cheap, friction — the old protection — is gone, and what remains is a judgment problem. Solving authorization cleanly is precisely what makes the residual loyalty gap visible.

**Unverified, do not assert:** any joint Whitt/Drummond Reed GDC26 session (Reed spoke at GDC26, but on a separate DIF/IEEE/LF decentralized-identity panel); Whitt calling Project Liberty "unfortunate" — the public record points the *other* way, as he is a credited contributor to a Project Liberty Institute publication on data cooperatives (2025); the text of *Reweaving the Web* beyond publisher copy; any signatory list showing who has cleared tiers above the entry pledge.
