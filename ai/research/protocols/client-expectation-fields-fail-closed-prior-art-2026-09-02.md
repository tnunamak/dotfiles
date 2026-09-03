---
title: "Mature standards do carry optional request-side client-expectation fields that fail closed on mismatch, but only for a narrow set of security/session-continuity properties (sub, acr-as-essential, prompt=none, resource, If-Match) — general-purpose provenance/classification hints (login_hint, kc_idp_hint, authenticatorAttachment) are documented as best-effort/fail-open instead"
date: 2026-09-02
topic: protocols
tags: [oidc, oauth, saml, webauthn, http, fapi, plaid, smart-on-fhir, fail-closed, client-hints, provenance]
status: draft
sources: [oidc-core-claims, oidc-core-acr-values, oidc-core-prompt-none, rfc8707, oidc-core-hints, keycloak-idp-hint, webauthn-l3, rfc9110-if-match, plaid-institutions, smart-app-launch, fapi-acr-history]
source_session: 74b4f237-b402-4ba7-bd8d-3c3b5ef11ff7
---

## CLAIMS

- OIDC's `claims` parameter `essential: true` member is itself OPTIONAL, and the spec's *general* rule for essential claims is fail-**open**, not fail-closed: the AS "MUST NOT generate an error when Claims are not returned, whether they are Essential or Voluntary, unless otherwise specified." [oidc-core-claims]
- OIDC carves out exactly two named exceptions to that fail-open default, both narrow security/session-identity properties: `acr` as an essential claim ("the Authorization Server MUST treat that outcome as a failed authentication attempt") and `sub` ("a mismatch MUST cause the authentication to fail"). [oidc-core-claims]
- The plain `acr_values` request parameter (without `essential: true`) is explicitly voluntary and fail-open: "If the Claim is not Essential and a requested value cannot be provided... the Authorization Server is not required to provide this Claim in its response." [oidc-core-acr-values]
- FAPI's own history shows this exact fail-closed pattern was tried, then rolled back at the ecosystem level: FAPI ID2 required clients to request essential `acr`, but FAPI Final removed that requirement, and UK Open Banking's current guidance instructs ASPSPs to accept requests with no `acr` claim at all and pick authentication strength themselves. [fapi-acr-history]
- `prompt=none` is a clean, unambiguous fail-closed precedent: the AS "MUST NOT display any authentication or consent user interface pages. An error is returned if [conditions aren't met]," with specific typed errors (`login_required`, `interaction_required`, `consent_required`, `account_selection_required`) — request never silently degrades. [oidc-core-prompt-none]
- OAuth RFC 8707's `resource` parameter is client-optional by default, but the AS "MAY require clients to specify the resource(s)... and MAY fail requests that omit the parameter," and on an unacceptable value "should reject the request... using the error code 'invalid_target'." [rfc8707]
- `login_hint` in OIDC has zero normative consequence if ignored ("The use of this parameter is left to the OP's discretion"); `id_token_hint` has a soft, degradable rule ("SHOULD respond successfully when possible, even if it is not present"), not a hard contract. [oidc-core-hints]
- Keycloak's `kc_idp_hint` is documented as fail-**open**: if the named IdP alias doesn't exist, "the login form will be displayed" instead of an error. [keycloak-idp-hint]
- WebAuthn draws the sharpest line of any spec surveyed inside a single request object: `userVerification: "required"` fails the ceremony ("The client MUST return an error if user verification cannot be performed," raising `ConstraintError`), while the newer `hints` member is explicitly non-binding ("These hints are not requirements, and do not bind the user-agent"). `authenticatorAttachment` sits in between — spec-worded as a hard *filter*, not an ignorable hint, but real-world ambiguity under passkeys/hybrid transport motivated the WG to add the explicitly-non-binding `hints` mechanism alongside it. [webauthn-l3]
- HTTP RFC 9110 `If-Match` is the general-purpose version of this whole pattern: "the origin server MUST evaluate the If-Match condition... prior to performing the method" and "MUST NOT perform the requested method if the condition evaluates to false," normally communicated via 412 Precondition Failed. [rfc9110-if-match]
- On the response-assertion side: OIDC `acr`/`amr` in the ID Token are AS-asserted facts the RP checks *after* receipt ("the Client SHOULD check that the asserted Claim Value is appropriate"), not a pre-flight gate — this is the same `acr` value, used two different ways depending on whether `essential: true` was set. [oidc-core-acr-values]
- Plaid's `/institutions/get` returns a response-side `oauth` boolean per institution ("Indicates that the institution has an OAuth login flow..."), and separately exposes `oauth` as a *request-side filter* on the same field name — both directions exist for the identical concept, split cleanly by purpose (informational read vs. query filter), not layered as expectation-plus-fail-closed-check. [plaid-institutions]
- SMART App Launch is the strongest pure response-side-assertion precedent: "the token response will include any context data the app requested and any (potentially) unsolicited context data the EHR may decide to communicate" — the server can assert more than was requested, and `scope` in the response is explicitly allowed to diverge from what was requested. [smart-app-launch]
- Keycloak's brokered-login IdP identity was not confirmed as a standard out-of-the-box response claim in primary docs (would require a custom protocol mapper); FDX's provenance/source-type fields could not be verified — the spec is membership-gated and no field-level primary quote was obtainable. Both are flagged, not claimed. [keycloak-idp-hint]

## SOURCES

**oidc-core-claims**
URL: https://openid.net/specs/openid-connect-core-1_0.html
Accessed: 2026-09-02
Quote: "Note that even if the Claims are not available because the End-User did not authorize their release or they are not present, the Authorization Server MUST NOT generate an error when Claims are not returned, whether they are Essential or Voluntary, unless otherwise specified in the description of the specific claim." / "If this is an Essential Claim and the requirement cannot be met, then the Authorization Server MUST treat that outcome as a failed authentication attempt." (§5.5.1, §5.5.1.1)

**oidc-core-acr-values**
URL: https://openid.net/specs/openid-connect-core-1_0.html
Accessed: 2026-09-02
Quote: "The acr Claim is requested as a Voluntary Claim by this parameter." / "If the Claim is not Essential and a requested value cannot be provided, the Authorization Server SHOULD return the session's current acr as the value of the acr Claim." (§3.1.2.1) ID Token validation: "If the acr Claim was requested, the Client SHOULD check that the asserted Claim Value is appropriate." (§3.1.3.7)

**oidc-core-prompt-none**
URL: https://openid.net/specs/openid-connect-core-1_0.html
Accessed: 2026-09-02
Quote: "The Authorization Server MUST NOT display any authentication or consent user interface pages. An error is returned if an End-User is not already authenticated or the Client does not have pre-configured consent for the requested Claims or does not fulfill other conditions for processing the request. The error code will typically be login_required, interaction_required, or another code defined in Section 3.1.2.6." (§3.1.2.1, §3.1.2.6)

**rfc8707**
URL: https://www.rfc-editor.org/rfc/rfc8707
Accessed: 2026-09-02
Quote: "the authorization server MAY require clients to specify the resource(s) they intend to access and MAY fail requests that omit the parameter with an 'invalid_target' error." / "invalid_target — The requested resource is invalid, missing, unknown, or malformed." (§2, §2.1)

**oidc-core-hints**
URL: https://openid.net/specs/openid-connect-core-1_0.html
Accessed: 2026-09-02
Quote: "Hint to the Authorization Server about the login identifier the End-User might use to log in (if necessary)... The use of this parameter is left to the OP's discretion." (login_hint, §3.1.2.1) / id_token_hint: "When possible, an id_token_hint SHOULD be present when prompt=none is used and an invalid_request error MAY be returned if it is not; however, the server SHOULD respond successfully when possible, even if it is not present."

**keycloak-idp-hint**
URL: Keycloak / Red Hat build of Keycloak docs (via search-summarized rendering; direct doc fetch failed)
Accessed: 2026-09-02
Quote: "If this provider doesn't exist the login form will be displayed." (kc_idp_hint fallback behavior)
Notes: not independently verified via a direct primary-source fetch; treat as near-verbatim, not certified literal. Keycloak `identity_provider`-as-response-claim likewise unconfirmed as an out-of-the-box behavior.

**webauthn-l3**
URL: https://www.w3.org/TR/webauthn-3/
Accessed: 2026-09-02
Quote: "required — The Relying Party requires user verification for the operation and will fail the overall ceremony if the response does not have the UV flag set. The client MUST return an error if user verification cannot be performed." (§5.8.6) / "These hints are not requirements, and do not bind the user-agent, but may guide it in providing the best experience... Hints MAY contradict information contained in credential transports and authenticatorAttachment. When this occurs, the hints take precedence." (§5.8.8) / authenticatorAttachment: "If this member is present, eligible authenticators are filtered to be only those authenticators attached with the specified authenticator attachment modality." (§5.4.4)

**rfc9110-if-match**
URL: https://www.rfc-editor.org/rfc/rfc9110
Accessed: 2026-09-02
Quote: "the origin server MUST evaluate the If-Match condition... prior to performing the method... An origin server that evaluates an If-Match condition MUST NOT perform the requested method if the condition evaluates to false. Instead, the origin server MAY indicate that the conditional request failed by responding with a 412 (Precondition Failed) status code." (§13.1.1, §15.5.13)

**plaid-institutions**
URL: https://plaid.com/docs/api/institutions/
Accessed: 2026-09-02
Quote: "Indicates that the institution has an OAuth login flow. This will be true if OAuth is supported for any Items associated with the institution, even if the institution also supports non-OAuth connections." Also documented as a request-time filter option: "Limit results to institutions with or without OAuth login flows."

**smart-app-launch**
URL: https://build.fhir.org/ig/HL7/smart-app-launch/app-launch.html ; https://build.fhir.org/ig/HL7/smart-app-launch/scopes-and-launch-context.html
Accessed: 2026-09-02
Quote: "Once an app is authorized, the token response will include any context data the app requested and any (potentially) unsolicited context data the EHR may decide to communicate." / scope in token response: "Scope of access authorized. Note that this can be different from the scopes requested by the app."

**fapi-acr-history**
URL: secondary (Authlete/FinTechLabs conformance-testing commentary; openbanking.org.uk guidance), via search — no direct primary FAPI/OBIE spec PDF text obtained
Accessed: 2026-09-02
Quote: current UK Open Banking guidance is that ASPSPs "must accept requests without an acr claim, determining the appropriate level of authentication to use based on the activity being requested."
Notes: flagged as secondary-sourced; FAPI ID2's original essential-acr requirement and its removal in FAPI Final could not be quoted from primary spec text directly.

## SYNTHESIS

Precedent splits along a clear axis. Every fail-closed request-side field surveyed guards a **security or session-identity property** whose silent mismatch is a live vulnerability: `sub` (wrong-user binding), essential `acr` (auth-strength downgrade), `prompt=none` (silent re-auth/consent bypass), `resource` (token audience confusion), WebAuthn `userVerification: required` (UV bypass), `If-Match` (lost-update races). In each, the AS cannot safely proceed on mismatch.

Every field carrying **classification/routing/provenance information** instead — `login_hint`, `kc_idp_hint`, plain `acr_values`, `authenticatorAttachment` (increasingly, post-passkeys) — is documented fail-open, falling back gracefully rather than rejecting. OIDC's default rule for `claims` is fail-open; the framers hand-carved only two exceptions (`sub`, `acr`), signaling fail-closed is the expensive minority case, not the default posture. FAPI's retreat from essential `acr` (ID2 → Final) is a documented regret of doing exactly that for a classification-ish property.

`source.kind` is provenance metadata — closer in kind to `login_hint`/`kc_idp_hint`/plain `acr_values` (a classification a well-behaved client already believes true) than to `sub`/essential-`acr`/`resource` (properties whose mismatch is directly exploitable). The counter-argument: if a client's downstream trust logic depends on provenance (e.g. only accepting `provider_native` for compliance-sensitive use), a silent mismatch resembles `resource`'s audience-confusion risk. That argument has some force but is weaker than RFC 8707's, because a resource-indicator mismatch enables active token misuse; an unchecked source-kind mismatch is closer to a consumer bug the client could also catch by reading the grant.

PDPP's design is already response-side-strong — `source.kind` is separately recorded on the accepted grant (spec-core.md:851) as provenance metadata, so the response-side option already exists and is authoritative.

**Recommendation: keep as-is (option a), moderate confidence (~65%).** Strongest precedent for: RFC 8707's `resource`/`invalid_target` shape — optional by default, AS-enforceable, fail-closed with a specific typed error — which PDPP already mirrors (optional field, Source validation failure before consent, spec-core.md:738-741) rather than inventing a new mechanism. Strongest precedent against: OIDC's essential-claims default (fail-open unless specifically justified) plus FAPI's essential-`acr` regret, both arguing against defaulting a classification-shaped field to fail-closed without a sharp security argument — which PDPP's provenance field doesn't yet carry as clearly as audience confusion or UV bypass does. The cost of keeping it is small (optional; the AS-side check is one equality comparison already needed to populate the grant); the cost of every optional field is spec-reader and test surface, and WebAuthn's `authenticatorAttachment` shows even spec authors regret hard-filter lines that turn out to be soft classifications once usage diverges from the original model. If a realistic client actually depends on provenance for a trust decision, (a) is well-precedented by RFC 8707. If the only benefit is catching client bugs early, the OIDC/Keycloak fail-open pattern argues for softening the mismatch to a warning, or dropping the request-side field for AS-asserted-on-grant alone (option b) — which the grant recording already provides either way.
