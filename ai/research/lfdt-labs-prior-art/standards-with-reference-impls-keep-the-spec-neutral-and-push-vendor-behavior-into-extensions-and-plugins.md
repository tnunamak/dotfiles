---
title: "Foundations that host a spec, a reference implementation, and a vendor ecosystem keep the core neutral by putting vendor behavior in separately-licensed extension/profile namespaces, not in the core document, and by requiring IP/trademark transfer away from any single company"
date: 2026-07-17
topic: lfdt-labs-prior-art
tags: [standards-governance, neutral-core, foundation-model, spec-vs-implementation, extension-mechanism, trademark-policy]
status: draft
sources: [toip-whitepaper-structure, toip-techarch, toip-dtgwg, owf-governance, owf-labs-lifecycle, smart-fhir-conformance, fhir-license, fhir-trademark-policy, hapi-fhir-relationship, oauth-rfc6749-interop, oauth-rfc6749-iana]
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

- Trust over IP (ToIP) Foundation's charter is explicitly to specify a four-layer architecture (governance stack + technology stack) that lets multiple independent implementations interoperate, not to build or bless one implementation: "the starting definition of the ToIP stack was published as Hyperledger Aries RFC 0289," and the Foundation's mission is to "define an overall architecture for Internet-scale digital trust," not to develop all the standards or components in the stack itself [toip-whitepaper-structure].
- ToIP's Technical Architecture Specification (TechArch) makes multi-vendor interoperability an explicit design goal at the layer where vendor implementations plug in: "Diversity of implementations of Layer 1 trust support functions is intentional and a key goal of the ToIP stack design," and "implementations from multiple vendors can and should be interoperable, and customers should be able to switch between them while maintaining standardized functionality" [toip-techarch].
- ToIP's architecture spec treats vendor/company systems (e.g., Hyperledger Indy, KERI) as pluggable "supporting systems" referenced by example, not embedded in the neutral spec: "The ToIP protocol stack in an [endpoint system] MAY use the services of a [supporting system] at any layer," and "standardization across different services is not required" [toip-techarch].
- ToIP's specification deliverables are produced by dedicated Working Groups (Technical Stack WG, Governance Stack WG) under a formal "TSS" (ToIP Standard Specification) document track, separate from any implementation's own repos; contribution to Draft Deliverables requires current Foundation + Working Group membership specifically "to maintain IP protections" [toip-whitepaper-structure].
- ToIP formed a Decentralized Trust Graph Working Group (DTGWG) jointly with the Decentralized Identity Foundation (DIF) in 2025, focused on standardizing verifiable-identifier/verifiable-credential building blocks (personhood credential, verifiable relationship credential) for decentralized trust graphs — a working-group-scoped neutral spec effort distinct from any single company's product [toip-dtgwg].
- OpenWallet Foundation (OWF), a Linux Foundation Europe project, states explicitly that it does not intend to publish a wallet itself or create new standards, positioning itself as a neutral reference-implementation venue rather than a product vendor or standards body: "the OWF does not intend to publish a wallet itself, nor offer credentials or create any new standards" [owf-governance].
- OWF requires every project entering its ecosystem (at minimum the "Labs" maturity stage) to document an IP policy using Apache 2.0 or another Governing-Board-approved open license, AND — for projects that previously belonged to one company — to transfer "the project name, trademarks, and electronic account assets (github repo, social media accounts, domain names, etc.) to Linux Foundation Europe for the benefit of the OpenWallet Foundation" [owf-labs-lifecycle].
- OWF's Labs stage explicitly does not confer endorsement or production-readiness: "this stage doesn't set requirements for community size, governance, or production readiness, and Labs projects receive minimal support from the Foundation," and projects are reviewed annually by the Technical Advisory Council [owf-labs-lifecycle].
- SMART App Launch (the OAuth-based profile that lets apps connect to FHIR servers) is published by HL7 International / FHIR Infrastructure under a discovery mechanism (`.well-known/smart-configuration`) that lists a server's supported "capabilities" as an open, growable set [smart-fhir-conformance].
- SMART's conformance spec draws an explicit editorial line between core-namespace and vendor-namespace extensions by publisher identity: "IGs published by HL7 MAY use simple strings to represent additional capabilities... IGs published by other organizations SHALL use full URIs to represent additional capabilities," and "Simple, non-URI capability strings are reserved for definition in SMART App Launch" [smart-fhir-conformance].
- The core FHIR specification content is released under CC0 ("No Rights Reserved"), decoupling the neutral technical content from any implementation, while the FHIR name/logo are separately protected as registered trademarks (US Reg No 4,272,380) that cannot be used to brand a product or claim HL7 endorsement without a written trademark license: "You can't claim that HL7 or any of its members endorses your derived [thing] because it uses content from this specification" [fhir-license] [fhir-trademark-policy].
- HL7's trademark policy is the enforcement mechanism that keeps vendor products from appropriating the neutral brand: use of HL7 trademarks "in URL domains or to brand your product or service... without the express written consent of Health Level Seven International is strictly prohibited," while fair-use/nominative references to "the HL7® FHIR® standard" remain unrestricted [fhir-trademark-policy].
- HAPI FHIR — the most widely deployed Java implementation of FHIR — is an independent, community-originated (University Health Network), Apache 2.0-licensed open-source project, commercially stewarded by Smile Digital Health/Smile CDR; it is not an HL7-owned reference implementation, though its project lead also holds an HL7 Co-Chair/FHIR Core Team editor role, illustrating personnel overlap without organizational merger between the standards body and the reference-implementation vendor [hapi-fhir-relationship].
- IETF's OAuth 2.0 core (RFC 6749) explicitly defers vendor/use-case-specific behavior to future "prescriptive profiles and extensions," calling out in Section 1.8 that the framework "was designed with the clear expectation that future work will define prescriptive profiles and extensions necessary to achieve full web-scale interoperability," and that without those extensions "clients must be manually and specifically configured against a specific authorization server and resource server in order to interoperate" [oauth-rfc6749-interop].
- RFC 6749 enforces the core/extension boundary structurally via IANA registries (Section 11): OAuth Parameters, Access Token Types, Authorization Endpoint Response Types, and Extension Error Codes are each a named registry that new extension RFCs populate without modifying RFC 6749 itself — the mechanism that lets OAuth 2.1 and companion RFCs (PKCE, RFC 8414 Authorization Server Metadata, RFC 7591 Dynamic Client Registration, RFC 8707 Resource Indicators) add vendor/use-case behavior editorially outside the core document [oauth-rfc6749-iana].

## SOURCES

**toip-whitepaper-structure**
URL: https://trustoverip.github.io/WP0010-toip-foundation-whitepaper/organization/structure/
Accessed: 2026-07-17
Quote: "The work of the Foundation will proceed in four initial Working Groups: 1. The Technical Stack Working Group will define the specifications and interoperability testing requirements for the ToIP Technology Stack. 2. The Governance Stack Working Group will define the models, templates, guidelines, and recommended best practices for the ToIP Governance Stack."

**toip-techarch**
URL: https://trustoverip.github.io/TechArch/
Accessed: 2026-07-17
Quote: "Diversity of implementations of Layer 1 trust support functions is intentional and a key goal of the ToIP stack design." / "The ToIP protocol stack in an [endpoint system] MAY use the services of a [supporting system] at any layer." / "standardization across different services is not required."

**toip-dtgwg**
URL: https://www.lfdecentralizedtrust.org/blog/toip-and-dif-announce-three-new-working-groups-for-trust-in-the-age-of-ai
Accessed: 2026-07-17
Quote: "Trust Over IP (ToIP), an LF Decentralized Trust (LFDT) project, and the Decentralized Identity Foundation (DIF) have launched three new Working Groups focused on digital trust for agentic AI: The Joint ToIP/DIF Decentralized Trust Graph Working Group, along with an AI & Human Trust Working Group and a Trusted AI Agent Working Group." (Note: web search did not surface a direct, citable link between Vana's Art Abal and this working group — flagging as unverified rather than asserting it.)

**owf-governance**
URL: https://openwallet.foundation/
Accessed: 2026-07-17
Quote: "the OWF does not intend to publish a wallet itself, nor offer credentials or create any new standards" (per WebSearch synthesis of foundation overview materials at openwallet.foundation and tac.openwallet.foundation/governance/).

**owf-labs-lifecycle**
URL: https://github.com/openwallet-foundation-labs ; https://tac.openwallet.foundation/governance/
Accessed: 2026-07-17
Quote: "Document an intellectual property policy that leverages the Apache 2.0 license or an open license approved by the OpenWallet Foundation's Governing Board... agree to transfer the project name, trademarks, and electronic account assets (github repo, social media accounts, domain names, etc.) to Linux Foundation Europe for the benefit of the OpenWallet Foundation." / "this stage doesn't set requirements for community size, governance, or production readiness, and Labs projects receive minimal support from the Foundation."

**smart-fhir-conformance**
URL: https://build.fhir.org/ig/HL7/smart-app-launch/conformance.html
Accessed: 2026-07-17
Quote: "External implementation guides MAY define additional capabilities to be discovered through this same mechanism." / "IGs published by HL7 MAY use simple strings to represent additional capabilities (e.g., example-new-capability); IGs published by other organizations SHALL use full URIs to represent additional capabilities (e.g., http://sdo.example.org/example-new-capability)." / "Simple, non-URI capability strings are reserved for definition in SMART App Launch."

**fhir-license**
URL: https://build.fhir.org/license.html
Accessed: 2026-07-17
Quote: "This specification is licensed under Creative Commons \"No Rights Reserved\" (CC0)." / "You can't claim that HL7 or any of its members endorses your derived [thing] because it uses content from this specification."

**fhir-trademark-policy**
URL: https://www.hl7.org/documentcenter/public/legal/FHIR_Trademark_Policy.pdf ; https://confluence.hl7.org/display/FHIR/FHIR+Trademark+Policy
Accessed: 2026-07-17
Quote: "Use of Health Level Seven International trademarks in URL domains or to brand your product or service (e.g., as part of the product name) without the express written consent of Health Level Seven International is strictly prohibited." / FHIR trademarks registered with USPTO (Reg No 4,272,380) and WIPO.

**hapi-fhir-relationship**
URL: https://hapifhir.io/ ; https://github.com/hapifhir/hapi-fhir
Accessed: 2026-07-17
Quote: "HAPI FHIR is a complete implementation of the HL7 FHIR standard for healthcare interoperability in Java, developed by an open community and licensed under... Apache Software License 2.0." Commercial steward: Smile Digital Health/Smile CDR. Project lead James Agnew is separately an "HL7 Co-Chair/FHIR Core Team member" — personnel overlap, not organizational merger.

**oauth-rfc6749-interop**
URL: https://www.rfc-editor.org/rfc/rfc6749.html
Accessed: 2026-07-17
Quote: (Section 1.8) "this framework was designed with the clear expectation that future work will define prescriptive profiles and extensions necessary to achieve full web-scale interoperability."

**oauth-rfc6749-iana**
URL: https://www.rfc-editor.org/rfc/rfc6749.html
Accessed: 2026-07-17
Quote: (Section 11) RFC 6749 establishes the OAuth Access Token Types Registry, OAuth Parameters Registry, OAuth Authorization Endpoint Response Types Registry, and OAuth Extensions Error Registry — IANA-administered registries that let later RFCs (PKCE, RFC 8414, RFC 7591, RFC 8707) register new values without amending RFC 6749 itself.

## SYNTHESIS

Every analog uses the same three-part mechanism to keep a neutral core from being captured by whichever vendor ships the best implementation, and PDP-Connect (pdpp = standard, data-connect = reference client, data-connectors = connector ecosystem, Vana = one network implementation) should copy all three, not just one:

1. **Organizational separation of spec-authorship from implementation-shipping.** ToIP's Working Groups write TSS documents; they don't ship a product. OWF explicitly disclaims publishing its own wallet. HL7 writes FHIR; HAPI FHIR is written by a different organization (originally a hospital IT group, now commercially stewarded by Smile Digital Health) that happens to have personnel overlap with HL7's core team — overlap in people is fine and even healthy (expertise transfer), but the *legal entity* that owns the spec must stay distinct from the *legal entity* that owns any one implementation. For PDP-Connect: the pdpp spec repo/working-group process should not be governed by the same decision body that ships data-connect or that Vana uses to ship its network — Vana's people can (and should) contribute to the spec, exactly as HAPI's lead co-chairs HL7, but spec ratification authority must not sit inside Vana.

2. **A structural extension mechanism with an editorial rule that is enforced by namespace, not by promise.** OAuth's IANA registries and SMART's HL7-string-vs-other-org-URI split are the sharpest examples: the rule "vendor stuff SHALL use a namespaced identifier, core stuff MAY use a bare one" is mechanically checkable (a linter or spec-conformance test can reject a bare string from a non-core submitter) rather than relying on reviewer vigilance. PDP-Connect should give `data-connectors` an explicit namespace/registry pattern (e.g., connector manifests declare a vendor-scoped capability/extension URI for anything Vana-specific, while only pdpp-ratified fields get bare/short keys) so that "is this vendor-specific or core" is answered by the identifier's shape, not by a judgment call at review time.

3. **IP/trademark stewardship divorced from any single company, with an explicit non-endorsement disclaimer.** HL7 separates CC0-licensed spec *content* from a tightly-controlled *trademark*, and forbids using the trademark to brand a product without a license — this is what stops "FHIR-branded" vendor lock-in language from ever appearing to be the standard's own voice. OWF goes further and requires incoming projects to transfer trademark/domain/repo ownership to the neutral foundation entity, not just license the code permissively. PDP-Connect's analogous move: keep the pdpp spec name/mark (and any "PDPP-compliant" certification language) owned by a neutral entity (per the existing PDPP steering-corpus finding that Vana should be "best implementation, not certification body" — see `project_pdpp_lfdt_strategy_art_meeting_2026_07_09` in project memory), and require that neither `data-connect` nor Vana's docs/marketing can imply pdpp-endorsement of a Vana-specific feature without it having gone through the same namespaced-extension path as any other vendor.

The one place these analogs *don't* converge — worth flagging rather than picking for Tim — is how much the reference implementation (data-connect) itself should be owned by the same neutral entity as the spec. OWF explicitly hosts reference code itself (neutral-owned reference implementations are core to its model), while HL7 deliberately does NOT own a reference implementation (HAPI is a separate vendor). ToIP sits in between: it writes specs and explicitly does not build production systems, but individual working groups do sometimes produce reference/example code. Given PDP-Connect already has `data-connect` positioned as *the* reference client, the OWF model (neutral entity owns the reference implementation, keeps it deliberately un-endorsing of any one commercial wallet) is the closer fit — but this should be a deliberate choice, not a default, since it's the one axis with real disagreement among the leading analogs.
