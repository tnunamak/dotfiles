---
title: "Privy classes WebAuthn passkeys as authorization keys rather than users, so a quorum of passkey P-256 public keys gives device-bound m-of-n approval that signs the canonicalized request as the WebAuthn challenge — avoiding user JWTs, the backend-owned-HPKE-keypair weakness, and any custom signing CLI"
date: 2026-08-14
topic: validator-key-custody
tags: [privy, key-quorum, custody, p256, authorization-signatures, threshold-approval, facilitator, escrow, hpke, tee]
status: draft
sources: [privy-passkey-sw, privy-owner-types, privy-kq-create, privy-kq-sign, privy-user-key-request, privy-authz-sig, privy-kq-overview, privy-pricing, privy-auth-signers, privy-mfa]
source_session: 4c9ad3f0-cb00-40cc-8bb9-baad3a7f16e5
---

## CLAIMS

- A Privy key quorum is "a set of authorization keys and/or users that control a resource (such as a wallet or policy)" and supports m-of-n thresholds. [privy-kq-overview]

- To sign a request with an m-of-n key quorum, the signer must "Collect the private keys for a threshold of authorization keys in the key quorum." For user members specifically, the instruction is to "request the user key" via the user-key request flow. [privy-kq-sign]

- The user key is obtained by POSTing the user's JWT to `https://api.privy.io/v1/wallets/authenticate`. Privy returns either a raw `authorization_key` (unencrypted mode) or an `encrypted_authorization_key` (HPKE mode) plus an `expires_at` timestamp. The key is time-bound, not per-request. [privy-user-key-request]

- The HPKE recipient keypair is supplied by the caller as `recipient_public_key`, described as "The public key of your ECDH keypair ... whose private key will be able to decrypt the session key." Whoever holds that private half receives the decrypted authorization key. [privy-user-key-request]

- The `/v1/wallets/authenticate` API "can be called from either your app's frontend or backend," so the recipient keypair may belong to the client device or to the application server, depending on the integration. [privy-auth-signers]

- **In the default client-side SDK integration, the key goes to the client, not the application.** "The returned time-bound authorization key is encrypted from the TEE to the client using HPKE." Privy states that "All Privy client-side SDKs enable **fully user non-custodial wallets by default**" and that issuing time-bound keys to JWT-authenticated users "results in cryptographically-enforced user custody of wallets." Authorization keys are issued "from within trusted execution environments (TEEs)." [privy-auth-signers]

- **In the documented server-side integration, the application backend holds the recipient private key** and therefore obtains the decrypted authorization key by presenting only the user's JWT. Privy labels direct API management of user authorization keys "an advanced setting" and recommends its SDKs instead. Privy's server SDKs accept `user_jwts` directly in the `AuthorizationContext` and mint/sign under the hood. [privy-auth-signers, privy-user-key-request, privy-kq-sign]

- Privy supports MFA "for access to user authorization keys" — TOTP, passkeys, SMS, and hardware security keys — so "your app can require additional user verification for sensitive wallet operations." [privy-auth-signers]

- Wallet MFA gates **use of the wallet's private key**, not issuance of an authorization key: "the user must complete MFA verification for actions that use the embedded wallet's private key... This includes signing messages, sending transactions, exporting the wallet, and recovering the wallet on new devices." It is also cached, "subject to the MFA verification duration," so it is not a per-request challenge. Nothing in the MFA docs gates `/v1/wallets/authenticate`. [privy-mfa]

- Docs remain silent on rate limits, audit events, or user notifications that would make server-side key minting detectable. [privy-auth-signers, privy-user-key-request]

- **A passkey is an authorization key, not a user.** Privy classes "a biometric key or passkey, following the WebAuthn standard" as a type of authorization key — "P256 cryptographic keys that allow any party that controls the key to take actions with associated wallets." [privy-owner-types]

- A passkey's P-256 public key (PEM/SPKI, base64) can be set directly as a wallet's `owner` at creation: `privy.wallets().create({owner: {public_key: passkeyP256PublicKey}, chain_type: 'ethereum'})`. [privy-passkey-sw]

- The approver signs the **canonicalized request payload** (`version`, `method`, `url`, `body`, `headers`) in the browser via WebAuthn `startAuthentication`, passing the base64url-encoded payload as the WebAuthn *challenge*. The resulting signature is submitted as `privy-authorization-signature` in the form `webauthn:<authenticatorData>:<clientDataJSON>:<signature>`. [privy-passkey-sw]

- The key-quorum create API accepts `public_keys` as a first-class member array alongside `user_ids` and `key_quorum_ids`: "At least one of `user_ids`, `public_keys`, or `key_quorum_ids` is required," with an `authorization_threshold` that must be "less than or equal to total number of key quorum members." So N passkey public keys form an m-of-N quorum with no user members involved. [privy-kq-create]

- Multiple quorum signatures are transmitted as "a comma-delimited string in the `privy-authorization-signature` header." Privy validates that the required number of signatures are provided, that all are valid for the request payload, and that all come from keys in the quorum. [privy-kq-sign]

- The signed canonical payload covers `version`, `method`, `url`, `body`, and Privy-prefixed `headers` (including `privy-app-id`, `privy-idempotency-key`, `privy-request-expiry`). [privy-authz-sig]

- Replay protection is a caller-chosen expiry, not a server nonce: `privy-request-expiry` is "A Unix timestamp in milliseconds ... indicating when the request expires. Privy rejects requests where this value is in the past," and it "must match the value used when computing the authorization signature." [privy-authz-sig]

- Nested key quorums are supported: members of a nested quorum sign the same way, and once the nested quorum's own threshold is met it "counts as one approval toward the parent's threshold. No special signing flow is needed." [privy-kq-sign]

- On the public pricing comparison table (Developer and Enterprise columns), the rows `Policy engine` and `Key quorum approvals` each carry two checkmarks and no add-on annotation; the adjacent `Advanced SSO` row is the one carrying "Available as add-on." Verified by parsing the raw page DOM: each row is a discrete `Frame 21472295xx` container holding its label plus its cells, so the add-on text belongs to Advanced SSO, not to key quorum approvals. [privy-pricing]

- A flattened markdown/text rendering of that same pricing page misattributes "Available as add-on" to the policy engine and key-quorum rows, because flattening collapses the row-container boundary and leaves the annotation textually adjacent to the preceding row label. [privy-pricing]

## CLAIMS VERIFIED EMPIRICALLY

Executed 2026-08-14 against a throwaway Developer-plan Privy app. [spike-evidence]

- A 3-of-5 key quorum of five P-256 authorization keys was created via `POST /v1/key_quorums` on a **Developer-plan** tenant, returning 200 with `authorization_threshold: 3` and `user_ids: []`. Key quorums are therefore not Enterprise-gated in practice, confirming the DOM reading of the pricing table. [spike-evidence]

- Threshold is enforced server-side: 1 and 2 signatures were rejected 401 ("Number of signatures ... does not match the wallet's authorization threshold"); 3 signatures executed. [spike-evidence]

- **App ID + app secret alone cannot take governed actions.** Reassigning the wallet owner with zero signatures returned 401 "Missing `privy-authorization-signature` header." Lowering the quorum threshold 3→1 with a single signature returned 401. A compromised backend holding full API credentials is stopped by Privy. [spike-evidence]

- Signature binding holds across every signed field: mutating the body after signing (signing "pay 1 USDC", sending "pay 1000000 USDC"), the URL, the HTTP method, the `privy-app-id` header, or adding an unsigned `privy-request-expiry` header each returned 401. [spike-evidence]

- **Authorization signatures are replayable within their validity window — they are expiry-bounded, not single-use.** An identical valid 3-signature request submitted twice executed **both times** (200/200). With no `privy-request-expiry` header at all, the same signatures replay indefinitely. A past expiry is rejected 401 ("The request has expired"). [spike-evidence]

- The documented canonical payload spec is exact and interoperable: sorted-key, whitespace-free JSON over `{version, method, url, body, headers}`, signed ECDSA P-256/SHA-256, DER, base64. An independent implementation interoperated with Privy on first attempt. [spike-evidence]

## SOURCES

**privy-kq-sign**
URL: https://docs.privy.io/controls/key-quorum/sign (fetched as .md source)
Accessed: 2026-08-14
Quote: "Collect the private keys for a threshold of authorization keys in the key quorum. For example, if your key quorum is configured with an *m*-of-*n* authorization threshold, you must have the private keys for at least *m* of the authorization keys in the key quorum. For users in your key quorum, request the user key per this guide."
Quote: "If the parent quorum contains a nested key quorum, members of the nested quorum sign the same way via `privy-authorization-signature`. Once enough nested quorum members sign to meet its authorization threshold, the nested quorum counts as one approval toward the parent's threshold. No special signing flow is needed."

**privy-user-key-request**
URL: https://docs.privy.io/controls/authorization-keys/keys/create/user/request (fetched as .md source)
Accessed: 2026-08-14
Quote: "Make a request to the Privy API with the user's access token to request a user key. If the token is valid per your configured authentication settings, Privy will return a time-bound user key that can be used to sign requests."
Quote: "For security, Privy encrypts user authorization keys under a public key you provide to ensure that only your app can decrypt them."
Quote: "The encrypted authorization key, once decrypted, can be used to sign transactions on the wallet, acting as a temporary AuthorizationPrivateKey."

**privy-authz-sig**
URL: https://docs.privy.io/api-reference/authorization-signatures
Accessed: 2026-08-14
Quote: "A Unix timestamp in milliseconds (e.g., `1773679531000`) indicating when the request expires. Privy rejects requests where this value is in the past, helping prevent replay attacks."
Quote (multi-sig header): "include them as a comma-delimited string"

**privy-auth-signers**
URL: https://docs.privy.io/security/authentication/authenticated-signers (fetched as .md source)
Accessed: 2026-08-14
Quote: "Privy enables users to fully control their wallets by issuing time-bound authorization keys to users who authenticate via a verified JWT. Once users retrieve a time-bound authorization key, they can make requests with the key. This configuration results in cryptographically-enforced user custody of wallets."
Quote: "All Privy client-side SDKs enable **fully user non-custodial wallets by default**."
Quote: "Directly managing user authorization keys via the API is an advanced setting. We recommend using Privy's SDKs, which internally manage user authorization keys."
Quote: "Privy enables users to retrieve a **time-bound authorization key directly via a REST API**. This API can be called from either your app's frontend or backend."
Quote: "The returned time-bound authorization key is encrypted from the TEE to the client using HPKE (Hybrid Public Key Encryption), using the same method used by the wallet export API."
Quote: "Privy also enables multi-factor authentication for access to user authorization keys. Supported additional factors include: Authenticator apps (TOTP), Biometric verification (passkeys), SMS confirmation, Hardware security keys."

**spike-evidence**
URL: local — `vana-com/security` worktree, `privy-facilitator-spike-evidence.md` (branch `tim/privy-kms-signer-0813`)
Accessed: 2026-08-14
Quote: Live API probes against a throwaway Developer-plan app. Quorum `icl9je517wri9aub287ilhxc` (3-of-5), wallet `o2o6t5w562eb3qsdojm1w11b`. Full result table in that file.

**privy-mfa**
URL: https://docs.privy.io/authentication/user-authentication/mfa/overview (fetched as .md source)
Accessed: 2026-08-14
Quote: "Once a user enrolls in wallet MFA, **the user must complete MFA verification for actions that use the embedded wallet's private key**, subject to the MFA verification duration. This includes signing messages, sending transactions, exporting the wallet, and recovering the wallet on new devices."
Quote: "Passkeys (recommended): users verify with a previously registered passkey through biometric authentication on their device. Phishing-resistant, device-bound, and independent of third-party carriers or apps."

**privy-owner-types**
URL: https://docs.privy.io/controls/authorization-keys/owners/types (fetched as .md source)
Accessed: 2026-08-14
Quote: "**Authorization keys** are P256 cryptographic keys that allow any party that controls the key to take actions with associated wallets."
Quote: "Common examples of authorization keys include: app keys, which are controlled by your app's server... a biometric key or passkey, following the WebAuthn standard, which allow users to easily sign and execute requests with a P256 key"

**privy-passkey-sw**
URL: https://docs.privy.io/recipes/passkey-server-wallets (fetched as .md source)
Accessed: 2026-08-14
Quote: "Authorization keys provide a way to ensure that actions taken by your app's wallets can only be authorized by an explicit user request. When you specify an `owner` of a resource, all requests to update that resource **must be signed** with this key."
Quote (wallet creation): "const wallet = await privy.wallets().create({owner: {public_key: passkeyP256PublicKey}, chain_type: 'ethereum'});"
Quote (signature format): "const authorizationSignature = `webauthn:${authenticatorData}:${clientDataJSON}:${signature}`;"
Quote (challenge binding): the canonicalized `{version, method, url, body, headers}` payload is base64url-encoded and passed as the WebAuthn `challenge` to `startAuthentication`.

**privy-kq-create**
URL: https://docs.privy.io/api-reference/key-quorums/create (fetched as .md source)
Accessed: 2026-08-14
Quote: "At least one of `user_ids`, `public_keys`, or `key_quorum_ids` is required."
Quote: `authorization_threshold` must be "less than or equal to total number of key quorum members."

**privy-kq-overview**
URL: https://docs.privy.io/controls/key-quorum/overview
Accessed: 2026-08-14
Quote: "A quorum is a set of authorization keys and/or users that control a resource (such as a wallet or policy)."

**privy-pricing**
URL: https://www.privy.io/pricing
Accessed: 2026-08-14
Quote (DOM row containers, in document order): `Frame 2147229584` → "Policy engine" → check, check; `Frame 2147229585` → "Key quorum approvals" → check, check; `Frame 2147229586` → "Advanced SSO" → check + "Available as add-on".

## SYNTHESIS

The load-bearing variable is not the member *type* but **who owns the HPKE recipient keypair**.

An **authorization-key member** is a P-256 keypair whose private half can live in an HSM/KMS that the application cannot read. Signing is a remote `sign` call; the application never possesses the key. That is a genuine cryptographic boundary — a compromised backend can request signatures but cannot manufacture them.

A **user member** can be either as strong or materially weaker, and the docs describe both:

- **Client-side SDK (Privy's default and recommendation).** The TEE encrypts the time-bound key to the *client*. The application backend never sees plaintext. Privy calls this "cryptographically-enforced user custody," and it preserves the threshold property. MFA can additionally gate access to the key.
- **Backend-owned recipient keypair (documented, labeled "advanced").** The server supplies its own `recipient_public_key`, so the server decrypts the authorization key having presented only the user's JWT. A backend able to obtain three users' JWTs can produce three valid signatures with no human present.

An earlier version of this entry stated the weak case as an inherent property of user-member quorums. That was wrong: it is a property of the integration pattern chosen. The corrected claim is conditional, and the condition is the thing to verify.

The practical consequence for an internal approval UI: "Privy, not our application, enforces the 3-of-5 threshold" is true only in the client-side configuration, and only if the server is never positioned to hold a threshold of live user keys at once. The dangerous property is that both configurations behave identically in normal operation — the difference only appears when the backend is compromised. So this must be established by construction and tested, not assumed from the fact that a quorum exists. Note also that a server-side `user_jwts` convenience path in Privy's own server SDKs is exactly the weak pattern, and it is the easiest thing to reach for.

**Empirically settled (2026-08-14): the threshold is real, and signatures replay.** Live probes confirmed that full API credentials — app ID plus app secret — cannot lower the threshold, reassign the wallet, or take any governed action without the required signatures. That is the load-bearing property, and it survives a fully compromised backend. But an identical valid 3-signature request executed *twice*: Privy does not burn a signature, so authorization signatures are expiry-bounded bearer credentials, not single-use tokens. Any design must set a short `privy-request-expiry`, send the (signature-bound) `privy-idempotency-key`, close proposals in its own store on first execution, and treat the signature header as a secret in transit. Replay is the sharp edge of this API and it is not called out in the docs.

MFA does not rescue the weak pattern. It gates *use of the wallet's private key* — signing, sending, exporting, recovering — not issuance of an authorization key at `/v1/wallets/authenticate`, and it is cached for a configurable duration rather than challenged per request. So MFA is not a second factor at the point where a backend would mint keys.

**The clean answer is to avoid user members entirely: use passkeys.** Privy classes a WebAuthn passkey as an *authorization key*, not a user — the same category as an HSM-held app key. A passkey's P-256 public key is registered directly as a wallet owner or, per the key-quorum create API's `public_keys` array, as a quorum member. Five passkeys form a 3-of-5 quorum with no `user_ids` at all, so `/v1/wallets/authenticate` never enters the flow and there is no time-bound key for a server to hold.

The binding is exactly what an approval UI needs: the canonicalized `{version, method, url, body, headers}` payload is base64url-encoded and passed as the **WebAuthn challenge**, so the hardware signs the request itself rather than a server-supplied description. The private key is device-bound and non-extractable by construction, and the signature arrives as `webauthn:<authenticatorData>:<clientDataJSON>:<signature>`.

This also resolves a rejected option from the design thread. The conclusion there was that ordinary crypto hardware wallets (Ledger/Trezol, secp256k1) can't sign Privy authorization requests, and that five human GCP KMS keys plus a custom CLI was too much machinery. Passkeys are the missing third option: hardware-backed, phishing-resistant, per-person, no custom cryptography, no CLI, and no shared GCP super-admin who could reach all five keys. A YubiKey or platform authenticator is a better independence boundary than five KMS keys in one GCP org.

Because the signed payload covers method, URL, body, and Privy-prefixed headers, binding a proposal to an exact request hash is straightforward and mutation of any covered field invalidates signatures. But replay protection is a caller-chosen expiry timestamp with no server-side nonce or single-use guarantee, so within an unexpired window an identical signed request is, by the documented mechanism, resubmittable — idempotency must come from `privy-idempotency-key` (which is inside the signed header set) plus the application's own proposal-closure state, not from assuming Privy burns the signature.

Nested quorums are the underrated find: a nested quorum counting as one parent approval, with no special signing flow, allows mixed topologies — e.g. a parent quorum of HSM-backed authorization keys where one member is a nested user quorum — without building a bridge.

On entitlement: the pricing table does list policy engine and key-quorum approvals for Developer. This is worth noting as a research-method caution rather than a settled fact — the same page yields opposite answers depending on whether it is read as flattened text or as DOM structure, and a pricing table is marketing collateral, not a tenant entitlement check. Confirm against the live tenant or in writing from Privy before relying on it.
