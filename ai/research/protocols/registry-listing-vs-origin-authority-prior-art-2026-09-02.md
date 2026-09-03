---
title: "Registry-lists-but-own-domain-authenticates, with a kind-keyed acceptance rule, is a standard pattern across app-link verification, federation protocols, and PKI — not a made-up one"
date: 2026-09-02
topic: protocols
tags: [pdpp, registry-trust, well-known, rfc9728, openid-federation, digital-asset-links, acme, kind-discriminator]
status: draft
sources: [dal, aasa, rfc8555, npm-provenance, tf-registry, obie-eidas, fdx-cfpb, openid-fed, oidc-discovery, indieauth, smart-fhir, matrix-fed, activitypub-webfinger, solid-oidc, apple-dev-id, google-play-dev, cabf-br]
source_session: 74b4f237-b402-4ba7-bd8d-3c3b5ef11ff7
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation/conclusions. Skippable. No citations here.
-->

## CLAIMS

- Google Digital Asset Links defines a mutual own-origin statement protocol: the app declares the domain, and the domain (via `https://<domain>/.well-known/assetlinks.json`) declares the app; no third-party listing is the trust root. [dal]
- Apple's App Site Association file at `https://<domain>/.well-known/apple-app-site-association` is the sole verification artifact for universal links; Apple deprecated file-signing as unnecessary once HTTPS-hosting was treated as sufficient. [aasa]
- ACME (RFC 8555) domain validation is a two-party model — the CA is both the relying party and the entity that fetches the origin-hosted proof (`.well-known/acme-challenge/<token>` for HTTP-01) — with no separate public "listing" that a third relying party trusts instead of re-deriving the check. [rfc8555]
- npm provenance attestations bind a registry listing to a build identity (CI workflow + source repo) via Sigstore/Fulcio short-lived certs and the public Rekor transparency log; npm itself does not assert the truth of the claim, and packages without provenance are still listed and installable (opt-in, not an admission gate). [npm-provenance]
- Terraform Registry has an explicit three-tier "kind" discriminator — Official (HashiCorp-owned), Partner (validated via HashiCorp's Technology Partner Program), Community (self-published) — where acceptance/verification differs by tier, but Partner-tier trust is established through an out-of-band partnership process, not a live check against the vendor's own domain. [tf-registry]
- UK Open Banking: TPP identity is authenticated by an eIDAS QWAC/QSEAL certificate issued by a regulated QTSP and encoding PSD2 roles (AISP/PISP/CBPII) and the FCA-assigned FRN; the OBIE Directory cross-checks against national eIDAS Trust Lists rather than being the terminal trust root itself. [obie-eidas]
- FDX's public registry documentation describes self-designated member categories (Data Provider, Data Recipient, Data Access Platform) but does not publicly specify any per-entity, domain-bound cryptographic corroboration mechanism. [fdx-cfpb]
- OpenID Federation anchors trust in a Trust Chain of signed Entity Statements rooted at a Trust Anchor, starting from each entity's own self-signed Entity Configuration published at `/.well-known/openid-federation` on that entity's own Entity Identifier URL. [openid-fed]
- OpenID Federation's `metadata` object is keyed by an explicit Entity Type Identifier (`federation_entity`, `openid_relying_party`, `openid_provider`, `oauth_authorization_server`, `oauth_client`), and each type pulls a different metadata schema with different validation rules (e.g., `openid_provider` metadata's `issuer` must match the Federation Entity Identifier). [openid-fed]
- OIDC Discovery and WebFinger require no registry at all: the issuer's own `/.well-known/openid-configuration` document, served from the issuer's own origin, is the entire trust mechanism. [oidc-discovery]
- IndieAuth has no registry: a user's own profile URL, via `rel=indieauth-metadata` (formerly `rel=authorization_endpoint`), points to the OAuth 2.0 Authorization Server Metadata (RFC 8414) document that proves the binding, entirely on the user's own domain. [indieauth]
- SMART on FHIR's `.well-known/smart-configuration` document, served relative to a FHIR server's own base URL, is the technical trust mechanism for that server; EHR-vendor app galleries (Epic, Oracle Health) are a separate, manually reviewed marketplace layer that functions like an app store for app-identity vetting, not for server identity. [smart-fhir]
- Matrix federation requires no central directory: `https://<hostname>/.well-known/matrix/server` and the homeserver's own `/_matrix/key/v2/server` signing-key document are the sole trust mechanism; the spec explicitly designs optional notary servers to avoid a single trust root. [matrix-fed]
- ActivityPub/Fediverse protocol-level trust is pure own-domain WebFinger (RFC 7033) resolution with no registry; joinmastodon.org's curated server list is a separate promotional/moderation-policy layer gated by manual human review via email, not a technical trust mechanism, and non-listed servers federate identically. [activitypub-webfinger]
- Solid WebID has no registry: a user's own WebID Profile document, hosted at their own WebID URI, names its trusted OIDC issuer(s) via the `solid:oidcIssuer` predicate, and a verifier checks that the asserting issuer is the one named in that document. [solid-oidc]
- Apple App Store and Google Play developer identity verification is a true counterexample to the origin-corroboration pattern: the store itself is the terminal authority, verifying organizational identity via D-U-N-S numbers, notarized documents, and reference/binding-authority checks — no document served from the developer's own domain is the trust root. [apple-dev-id] [google-play-dev]
- Web PKI is a genuine hybrid: root-store programs vet and list Certificate Authorities much like an app store vets developers (registry-is-authority at that layer), but under CA/Browser Forum Baseline Requirements each individual certificate's domain binding is proven the same way as the candidate pattern — a token fetched from the applicant's own origin (ACME HTTP-01) — before the CA (acting as both registry and validator) issues the cert. [cabf-br] [rfc8555]

## SOURCES

**dal**
URL: https://github.com/google/digitalassetlinks/blob/master/well-known/details.md ; https://developer.android.com/training/app-links/verify-applinks
Accessed: 2026-09-02
Quote: "Asset Links is a protocol to securely capture statements made by digital assets such as web sites or mobile apps about their relationship with other digital assets... statements can reliably be attributed to the owners of the source assets."

**aasa**
URL: https://developer.apple.com/library/archive/documentation/General/Conceptual/AppSearch/UniversalLinks.html
Accessed: 2026-09-02
Quote: "This file should be located at HTTPS://your domain name/.well-known/apple-app-site-association... The file needs to be accessible via HTTPS—without any redirects."

**rfc8555**
URL: https://datatracker.ietf.org/doc/html/rfc8555
Accessed: 2026-09-02
Quote: "The only validation the CA is required to perform in the DV issuance process is to verify that the requester has effective control of the domain."

**npm-provenance**
URL: https://docs.npmjs.com/generating-provenance-statements/ ; https://github.blog/security/supply-chain-security/introducing-npm-package-provenance/
Accessed: 2026-09-02
Quote: "Sigstore runs a public certificate authority which accepts an OIDC token from any conforming CI/CD provider and issues a short-lived, X.509 signing certificate in response."

**tf-registry**
URL: https://developer.hashicorp.com/terraform/registry/providers
Accessed: 2026-09-02
Quote: "Official providers are owned and maintained by HashiCorp. ... Partner providers are written, maintained, validated and published by third-party companies against their own APIs. ... Community providers are published to the Terraform Registry by individual maintainers, groups of maintainers, or other members of the Terraform community."

**obie-eidas**
URL: https://www.openbanking.org.uk/wp-content/uploads/2021/04/OBIE-eIDAS-Consultation-Webinar-QA-Deck_COMPLETE.pdf
Accessed: 2026-09-02
Quote: "TPPs must identify themselves to ASPSPs using an eIDAS certificate... OBWACs and OBSeals meet and conform to the structure of QWACs and QSealCs, and as such they contain the PSD2 roles and the FRN, as required by the FCA."

**fdx-cfpb**
URL: https://files.consumerfinance.gov/f/documents/cfpb_application-standard-setting-body-financial-data-exchange.pdf
Accessed: 2026-09-02
Quote: "FDX requires member firms to choose one member category that reflects their primary role in the ecosystem... FDX is also creating a global registry of known entities, their capabilities and certification."

**openid-fed**
URL: https://openid.net/specs/openid-federation-1_0.html
Accessed: 2026-09-02
Quote: "A Trust Chain... represents a chain starting at an Entity Configuration that is the subject of the chain... and ending in a Trust Anchor."

**oidc-discovery**
URL: https://openid.net/specs/openid-connect-discovery-1_0.html
Accessed: 2026-09-02
Quote: "OpenID Connect uses WebFinger [RFC7033] to locate the OpenID Provider for an End-User."

**indieauth**
URL: https://indieauth.spec.indieweb.org/
Accessed: 2026-09-02
Quote: "IndieAuth builds upon the OAuth 2.0 framework by specifying a mechanism and format for identifying users via a resolvable URL, and a method of discovering the authorization and token endpoints given a profile URL."

**smart-fhir**
URL: https://build.fhir.org/ig/HL7/smart-app-launch/
Accessed: 2026-09-02
Quote: "SMART defines a discovery document, available at .well-known/smart-configuration relative to a FHIR Server Base URL, allowing clients to learn the authorization endpoint URLs and features a server supports."

**matrix-fed**
URL: https://spec.matrix.org/latest/server-server-api/
Accessed: 2026-09-02
Quote: "This approach... has the advantage of avoiding a single trust-root since each server is free to pick which notary servers they trust."

**activitypub-webfinger**
URL: https://docs.joinmastodon.org/spec/webfinger/ ; https://blog.joinmastodon.org/2019/05/introducing-the-mastodon-server-covenant/
Accessed: 2026-09-02
Quote: "Any server that Mastodon links to from joinmastodon.org commits to actively moderating against racism, sexism, homophobia and transphobia."

**solid-oidc**
URL: https://solid.github.io/solid-oidc/ ; https://solid.github.io/webid-profile/
Accessed: 2026-09-02
Quote: "A WebID Profile lists the OpenID Providers who are trusted to issue tokens on behalf of the agent who controls the WebID... an entity that verifies ID Tokens uses this mechanism to determine if the issuer is authoritative for the given WebID."

**apple-dev-id**
URL: https://developer.apple.com/help/account/membership/enrolling-in-the-app/
Accessed: 2026-09-02
Quote: "Your organization... must have a D-U-N-S Number so that Apple can verify your organization's identity, legal entity status, and address... [enrollees] must provide a reference who can confirm they are an employee with the legal authority to enroll the organization."

**google-play-dev**
URL: https://android-developers.googleblog.com/2023/07/boosting-trust-and-transparency-in-google-play.html
Accessed: 2026-09-02
Quote: "When you create a new Play Console developer account for an organization, you'll need to provide a D-U-N-S number... If Google can't verify your developer information... your developer presence and apps may be removed from Google Play."

**cabf-br**
URL: https://cabforum.org/uploads/CA-Browser-Forum-BR-1.6.0.pdf ; https://letsencrypt.org/docs/challenge-types/
Accessed: 2026-09-02
Quote: "the ACME client puts a file on the web server at http://<YOUR_DOMAIN>/.well-known/acme-challenge/<TOKEN>... The certificate authority then accesses this file using HTTP... to verify control of the domain."

## SYNTHESIS

**Verdict: this is a grounded, standard pattern, not a made-up one — with a genuine and well-known failure mode (registry-as-authority) that the design should defend against explicitly.** Confidence: high. The specific three-part shape PDPP proposes — (1) a registry is a listing/publisher, never itself the trust root; (2) the entity's own domain is the authority; (3) a document served from that domain corroborates the binding claimed in the listing — is exactly the mechanism behind Google Digital Asset Links and Apple App Site Association (both used precisely to stop a store listing or an app manifest from unilaterally claiming a domain), and it is the load-bearing mechanism inside OpenID Federation (Entity Configuration at the entity's own `/.well-known/openid-federation`, chained to a Trust Anchor) and inside Web PKI's per-certificate domain-validation step (ACME HTTP-01/DNS-01, RFC 8555). It is also the *only* mechanism in several registry-free protocols (Matrix, WebFinger/OIDC Discovery, IndieAuth, Solid WebID) — precedent that a registry is optional scaffolding around this core, not required by it. This matters for PDPP because RFC 9728 protected-resource metadata (already normative in spec-discovery-and-trust.md §2) plays exactly the role of Digital Asset Links / OpenID Federation's Entity Configuration: an own-origin document the AS fetches independently of any registry claim.

The three strongest citations: **(1) Google Digital Asset Links** [dal] — closest structural analogue, explicitly designed to stop a directory/app-store entry from unilaterally claiming a domain, using a mutual own-origin statement. **(2) OpenID Federation 1.0** [openid-fed] — the only precedent in this set with both an own-origin trust-chain root *and* a first-class, spec-normative "kind" discriminator (Entity Type Identifier) that changes which metadata schema and validation rules apply, which is the second half of PDPP's proposed position (acceptance rules differ by declared kind). **(3) RFC 8555 / CA/Browser Forum Baseline Requirements** [rfc8555][cabf-br] — the highest-stakes production deployment of "prove control of your own origin before a third party will vouch for you," at Web-PKI scale, though it is honestly a two-layer hybrid (see below).

Precedent for the "kind" discriminator specifically is real but uneven in strength. OpenID Federation's Entity Type Identifier [openid-fed] is the cleanest match: it is a normative field, in the trust document itself, that dispatches to different metadata schemas and different validation obligations per type — structurally identical to "acceptance rules differ by declared kind." UK Open Banking's PSD2 roles (AISP/PISP/CBPII/ASPSP) [obie-eidas] are also a kind discriminator with differing acceptance rules, but the roles live inside a regulator-issued certificate, not a self-declared field the relying party independently corroborates — a stronger, not weaker, form of the same idea, but not a free structural match. Terraform Registry's tiers [tf-registry] are the weakest fit: real differential trust by kind, but Partner-tier trust is established by HashiCorp's internal partnership process, not by checking anything on the vendor's own domain — it's a kind discriminator without the own-origin-corroboration leg, worth citing as what PDPP is choosing *not* to do (pure registry-side vetting) if it wants the stronger form.

The honest counter-cases, which the owner should see plainly: **Apple App Store / Google Play developer verification** [apple-dev-id][google-play-dev] is a true counterexample — the store is the terminal authority via D-U-N-S numbers and notarized business documents, and no domain-hosted document is the trust root at all. **Web PKI** is a hybrid, not a clean win: root-store inclusion of CAs is itself a registry-is-authority relationship (browsers vet and list CAs much like an app store vets developers), and only the *inner* per-certificate step (ACME) matches PDPP's proposed pattern — so citing PKI as precedent should be scoped to "the per-entity domain-validation step," not "the whole CA trust model." **FDX** [fdx-cfpb] is genuinely thin in public documentation — it has self-declared member categories but no publicly specified per-entity corroboration mechanism, and should be cited only as "categories exist," not as supporting the origin-corroboration leg. **SMART on FHIR** [smart-fhir] and **ActivityPub** [activitypub-webfinger] both show a two-layer split that PDPP's registry may end up mirroring: a technical, origin-corroborated trust mechanism for the *server/protocol* layer, plus a separate, manually-reviewed marketplace/directory layer (EHR app galleries; joinmastodon.org) for *listing curation and policy compliance*, where listing inclusion is a courtesy/moderation gate, not a security boundary. That split — registry curates for discoverability and policy, origin document proves the security-relevant binding — is probably the most directly transferable framing for PDPP's data-connectors registry decision.
