---
title: "OIDC identity brokering and Solid-OIDC are direct prior art for one client-facing protocol fronting multiple fulfillment topologies with provenance recorded on the issued artifact; PDPP's actual novelty is applying that pattern to data-access grants rather than identity assertions; PSD2/UK Open Banking is the clearest case of a regulator deliberately refusing to unify the two paths"
date: 2026-09-02
topic: protocols
tags: [pdpp, oauth, oidc, amr, identity-brokering, fdx, plaid, smart-on-fhir, solid, mcp, x402, fulfillment-topology, provenance, psd2, open-banking]
status: draft
sources: [rfc8176, keycloak-broker, solid-oidc, fdx-api5, plaid-oauth-field, smart-fhir-1uphealth, openid-federation, mcp-rfc9728, x402-facilitator, dtp-github, gmail-api-vs-imap, psd2-rts-fallback, cfpb-1033-status]
source_session: 74b4f237-b402-4ba7-bd8d-3c3b5ef11ff7
---

## CLAIMS

- RFC 8176 defines the OIDC `amr` (Authentication Methods References) claim explicitly for identity-broker scenarios: "The 'amr' value lets the identity provider signal to the relying party additional information about what it did, for the cases in which that information is useful to the relying party," and grounds this in a trust argument: "the relying party is depending upon the identity provider to do reasonable things. If it does not trust the identity provider to do so, it has no business using it." [rfc8176]
- Keycloak's broker architecture lets an app authenticate against one OIDC Provider (Keycloak) regardless of whether Keycloak authenticates the user natively or federates to an upstream IdP (Google, SAML, another OP); the app "never sees the external IdP's assertion; it only ever receives Keycloak's token, in the one format it already understands." Provenance is recoverable but not pushed by default — retrieving the upstream token requires a separate broker endpoint (`GET /realms/{realm}/broker/{provider_alias}/token`) with an explicit `read-token` role grant. [keycloak-broker]
- Solid's WebID profile document carries a `solid:oidcIssuer` predicate naming which Identity Provider is authoritative for that WebID, and Pod Provider and Identity Provider are explicitly separable, swappable services under one WebID-OIDC protocol: "A Solid user can rely on an Identity Provider and a Pod Provider instead [of self-hosting]... they remain distinct, separable services that are compatible with other Pod Providers and Identity Providers." [solid-oidc]
- SMART App Launch (HL7/FHIR) is topology-invisible: the identical OAuth2/FHIR flow is used whether the resource server is a native EHR (Epic, Cerner) or an aggregator (1upHealth) that itself acts as a SMART client to many EHRs behind a re-exposed FHIR facade — "developers write one integration against 1upHealth's SMART/FHIR interface rather than many against each institution's native SMART/FHIR interface," with no wire field distinguishing native from aggregated. [smart-fhir-1uphealth]
- FDX's own documentation states data recipients "may leverage Data Access Platforms or Data aggregators to connect to thousands of financial institutions... or can connect directly to financial institutions" — but in practice, and architecturally, the fintech app integrates the aggregator's own proprietary API (e.g., Plaid's), not FDX directly; FDX itself is the bank-to-aggregator wire format, not the client-facing one. [fdx-api5]
- Plaid exposes topology on the wire at the institution level: each institution object returned by `/institutions/get` carries an `oauth` boolean, and institutions "will have oauth set to true if some Items associated with that institution are required to use OAuth flows" — a client-visible signal of which connection mechanism underlies a given institution, though this is OAuth-vs-credential connection type, not provider-native-vs-personal-server collection. [plaid-oauth-field]
- OpenID Federation 1.0 is a different mechanism from brokering, not an instance of it: it establishes a cryptographically verifiable Trust Chain from a Relying Party to a disclosed OpenID Provider via a Trust Anchor, so the RP ends up knowing exactly which OP it trusts — the opposite move from brokering, which hides the upstream. "This specification describes how two Entities that would like to interact can establish trust between them by means of a trusted third party called a Trust Anchor." [openid-federation]
- MCP's authorization spec adopted RFC 9728 (OAuth 2.0 Protected Resource Metadata) so an MCP Resource Server can advertise which Authorization Server(s) protect it, letting AS and RS be operated by different parties; this decouples authorization-server identity from resource-server identity, but is federation of *authorization*, not a statement about how the Resource Server's underlying data got populated — a materially different axis from PDPP's fulfillment-topology claim. [mcp-rfc9728]
- x402's facilitator role abstracts blockchain settlement complexity behind one client-facing HTTP 402 challenge/response flow — "abstracting as many details of crypto as possible away from the client and resource server, and into the facilitator" — but this is a payment-settlement backend choice, not a data-collection-topology choice, and the facilitator identity is visible in the request/response payload rather than hidden. [x402-facilitator]
- The Data Transfer Project's adapter architecture is service-to-service (platform-to-platform data migration, e.g. Facebook Photos to Google Photos), not a client-facing user-authorization protocol; its "client-facing" layer is a UI for triggering transfer jobs, not an analog to a third-party client requesting ongoing data access under a grant. This is a false positive for PDPP's claim. [dtp-github]
- Gmail API and IMAP are documented by Google as intentionally non-interchangeable: "the Gmail API should not be used to replace IMAP for full-fledged email client access," and they carry different authorization models (OAuth-scoped REST vs full-mailbox socket access); real multi-provider email clients build a custom adapter layer rather than treating them as one protocol, and users/developers must explicitly choose. This is a genuine case of a spec author (Google) refusing to unify. [gmail-api-vs-imap]
- PSD2's Regulatory Technical Standards require a bank (ASPSP) that offers a "dedicated interface" (API) to also offer a fallback — commonly a "modified customer interface" (MCI), effectively supervised screen-scraping — unless it earns a performance/testing exemption; in practice this obligated most banks to maintain two structurally distinct interfaces rather than unify direct and intermediated access into one. [psd2-rts-fallback]
- Under PSD2/UK Open Banking, third-party providers have two integration paths that are architecturally and legally separate, not two topologies behind one authorization server: direct integration with each bank's own developer-portal API, or integration with a regulated aggregator (Plaid, TrueLayer, Tink) that itself runs its own client-facing API on top of each bank's individually-operated interface. Each bank operates its own OBIE-conformant authorization server; there is no single AS issuing one token type across both paths, and PSD2's Strong Customer Authentication and TPP-identification (eIDAS certificate) requirements are built around the client/TPP knowing exactly which ASPSP it is individually authorized against. [psd2-rts-fallback]
- The US analog — CFPB's Section 1033 Personal Financial Data Rights rule, finalized November 2024 — is the regulatory push that could have forced a comparable single compliance-grade flow in the US; as of this research it remains on the books but enjoined and unenforceable pending CFPB-initiated reconsideration, with a federal court in the Eastern District of Kentucky "preserv[ing] the status quo" while the rule is substantially rewritten. [cfpb-1033-status]

## SOURCES

**rfc8176**
URL: https://www.rfc-editor.org/rfc/rfc8176.html
Accessed: 2026-09-02
Quote: "The 'amr' value lets the identity provider signal to the relying party additional information about what it did, for the cases in which that information is useful to the relying party... Ultimately, the relying party is depending upon the identity provider to do reasonable things. If it does not trust the identity provider to do so, it has no business using it."

**keycloak-broker**
URL: https://wjw465150.gitbooks.io/keycloak-documentation/content/server_admin/topics/identity-broker/tokens.html
Accessed: 2026-09-02
Quote: "your app never sees the external IdP's assertion; it only ever receives Keycloak's token, in the one format it already understands."

**solid-oidc**
URL: https://solidproject.org/faq
Accessed: 2026-09-02
Quote: "A Solid user can rely on an Identity Provider and a Pod Provider instead... they remain distinct, separable services that are compatible with other Pod Providers and Identity Providers, giving users freedom to choose whichever provider suits them best."

**smart-fhir-1uphealth**
URL: https://docs.1up.health/help-center/Content/en-US/get-started/fhir-1up.html ; https://hl7.org/fhir/smart-app-launch/
Accessed: 2026-09-02
Quote: "developers write one integration against 1upHealth's SMART/FHIR interface rather than many against each institution's native SMART/FHIR interface" — the underlying OAuth2/FHIR flow is identical to a direct native-EHR SMART integration, with no wire-level topology field.

**fdx-api5**
URL: https://financialdataexchange.org/fdx-feed/financial-data-exchange-fdx-releases-fdx-api-5-0/
Accessed: 2026-09-02
Quote: "data recipients may leverage Data Access Platforms or Data aggregators to connect to thousands of financial institutions (Data Providers) or can connect directly to financial institutions (Data Providers)."

**plaid-oauth-field**
URL: https://plaid.com/docs/api/institutions/
Accessed: 2026-09-02
Quote: "institutions will have oauth set to true if some Items associated with that institution are required to use OAuth flows."

**openid-federation**
URL: https://openid.net/specs/openid-federation-1_0.html
Accessed: 2026-09-02
Quote: "This specification describes how two Entities that would like to interact can establish trust between them by means of a trusted third party called a Trust Anchor."

**mcp-rfc9728**
URL: https://datatracker.ietf.org/doc/html/rfc9728 ; https://modelcontextprotocol.io/specification/draft/basic/authorization
Accessed: 2026-09-02
Quote: RFC 9728 "defines a metadata format that an OAuth 2.0 client or authorization server can use to obtain the information needed to interact with an OAuth 2.0 protected resource," including which Authorization Server(s) protect it — the June 2025 MCP revision uses this "to clearly separate the MCP server (resource server) from the authorization server."

**x402-facilitator**
URL: https://github.com/coinbase/x402/blob/main/specs/x402-specification-v2.md
Accessed: 2026-09-02
Quote: the design "means abstracting as many details of crypto as possible away from the client and resource server, and into the facilitator, so the client/server should not need to think about gas, rpc, etc."

**dtp-github**
URL: https://github.com/dtinit/data-transfer-project/blob/master/Documentation/Overview.md
Accessed: 2026-09-02
Quote: "Adapters handle the authentication of a user to a service (normally OAuth) and the transformation of data to and from the shared data models" — a service-to-service transfer framework, not a client-facing consent/authorization protocol.

**gmail-api-vs-imap**
URL: https://developers.google.com/gmail/api/guides/migrate-from-email-settings
Accessed: 2026-09-02
Quote: "the Gmail API should not be used to replace IMAP for full-fledged email client access."

**psd2-rts-fallback**
URL: https://developer.sgmarkets.com/rtd/psd2/apis/fallback.html ; https://www.out-law.com/en/articles/2017/november/psd2-screen-scraping-ban-confirmed-in-finalised-standards/
Accessed: 2026-09-02
Quote: "In practice, PSD2 included the obligation for most ASPSPs to effectively maintain two separate interfaces — usually an API as the dedicated interface and a fallback interface, often a modified customer interface (MCI) based on screen scraping."

**cfpb-1033-status**
URL: https://www.consumerfinancialserviceslawmonitor.com/2025/07/cfpb-section-1033-open-banking-rule-stayed-as-cfpb-initiates-new-rulemaking/ ; https://www.federalregister.gov/documents/2025/08/22/2025-16139/personal-financial-data-rights-reconsideration
Accessed: 2026-09-02
Quote: "The Court granted a preliminary injunction to 'preserve the status quo' while the CFPB completes its rulemaking process, ordering that the CFPB 'is enjoined from enforcing the Rule until it has completed its reconsideration of the Rule.'"

## SYNTHESIS

The claim that no existing protocol lets a client face both provider-native and personal-server fulfillment behind one request is too strong. OIDC identity brokering is the closest, cleanest precedent for PDPP's exact shape: one client-facing interface, two fulfillment paths at authentication time (native check vs. federated upstream IdP), and a standardized wire claim (`amr`, RFC 8176) that exists specifically so the relying party can learn which path was taken without needing to know in advance. Solid-OIDC does the same thing one layer over for storage: `solid:oidcIssuer` names the authoritative party without forcing the app to hardcode it. SMART on FHIR plus 1upHealth is the closest data-access analog to PDPP's actual two topologies, and tellingly it does *not* record provenance on the wire — the aggregator's facade is total. That's the interesting data point: the field PDPP wants to add is not yet standard practice even in the systems structurally closest to it. FDX and Plaid look like matches on a skim but are partial — FDX is bank-to-aggregator infrastructure, not what the fintech app itself speaks, and Plaid's `oauth` field marks connection mechanism, not who collected the data.

The refused-to-unify side has one genuinely strong precedent: PSD2/UK Open Banking. Regulators had the exact opportunity to unify "direct bank API" and "aggregator-fulfilled" behind one authorization server and explicitly did not — the RTS requires a dedicated interface plus, in most cases, a structurally separate fallback (the "modified customer interface," effectively supervised screen-scraping). Aggregators like Plaid and TrueLayer are themselves regulated third-party providers running their own client-facing APIs on top of each bank's individually-operated authorization server; there is no single AS issuing one token type across both paths, because PSD2's liability model (Strong Customer Authentication, TPP identification via eIDAS certificates, per-bank consent) depends on the client knowing exactly which bank it is individually authorized against. This is the closest thing to a standards body arguing, through design rather than an essay, that hiding fulfillment topology creates an unacceptable liability gap. Gmail-API-vs-IMAP is weaker corroboration — it splits by authorization model, not data-sourcing topology.

Verdict, moderate-to-high confidence: PDPP's overall move — one authorization server, two fulfillment topologies, same client request — is not new; identity brokering is this pattern one layer removed, and OIDC's authors would plausibly recognize a grant's provenance field as "the `amr` claim for data-access grants," since RFC 8176 was written for exactly this trust-transparency problem. What's more novel is (a) applying brokering to *authorization-for-data-access grants* rather than *authentication assertions* — nobody found this done cleanly at the resource-server-population layer, with SMART/1upHealth choosing invisibility instead — and (b) making provenance a mandatory grant field rather than an optional claim. But this isn't uncontested: PSD2 regulators, facing the identical fork for a domain with real liability stakes, chose the opposite of unification, and PDPP needs an explicit answer to the question that choice encodes — who is authenticated and who is liable — not an assumption that recording provenance resolves it. Three strongest citations: RFC 8176 (`amr`, direct precedent for a provenance claim on a brokered artifact), SMART App Launch / 1upHealth (nearest topology-shape match, choosing to hide rather than record provenance — PDPP's delta), and the PSD2 RTS dedicated-interface-plus-fallback requirement (sharpest case of a standards body declining to unify, for liability reasons PDPP should rebut explicitly). PDPP's real novelty is narrower than "no one lets a client face two topologies" — it's "no one records topology provenance as a mandatory grant field, though the identical move is standard for identity assertions, and the domain's closest regulated analog rejected unification outright."
