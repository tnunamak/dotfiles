---
title: "Privy user-owned embedded wallets can only gain a server signer through client-side user consent, so the security control is the signer's override policy — not where the authorization key is stored"
date: 2026-08-13
topic: web-security
tags: [privy, gcp-kms, wallet-custody, least-privilege, authorization-keys, policies]
status: settled
sources: [privy-owners-overview, privy-user-owner-config, privy-user-and-server-signers, privy-policy-overview, privy-signers-overview, account-login-attach-signer, account-constrained-silent-signing, cg-app-wallet-custody, cg-privy-authorization-signer]
source_session: fd983bb9-8962-43a5-a0cf-84d2db489dee
---

## CLAIMS

- Privy resources are controlled by a user, an authorization key, or a key quorum.
  Owners can sign, update policies, update owners, and export the private key;
  signers can only sign and "cannot update a wallet's owner, signers, or
  policies." [privy-owners-overview]
- Wallets created via Privy's client-side SDKs are automatically created with
  **user** owners, and are configured so that users are the only entity that can
  update policies, update owners, add signers, and export the wallet.
  [privy-user-owner-config]
- A server cannot unilaterally add itself as a signer on a user-owned wallet. The
  signer relationship is established client-side: after the user logs in, the app
  calls the `addSigners` method of the `useSigners` hook to add the app's
  authorization key as a signer. Possessing the authorization key authorizes API
  calls but does not by itself confer signer status.
  [privy-user-and-server-signers]
- Each additional signer carries `override_policy_ids`; Privy evaluates only the
  submitting signer's policy and does not fall back to another signer's policy.
  [privy-signers-overview]
- Policies are default-deny ("If no rules resolve, the policy will default to
  `DENY`"), and a wallet with a policy must include a rule for every RPC method it
  intends to use. Policies can constrain `personal_sign` (via the `message` field
  source, supporting `content` string operators and `byte_length` numeric
  operators) and `eth_signTypedData_v4` (via `ethereum_typed_data_domain` fields
  `chainId`/`verifyingContract` and `ethereum_typed_data_message` fields).
  [privy-policy-overview]
- If the server must also modify the wallet, Privy recommends a 1-of-k key quorum
  containing both the user owner and the server authorization key; as a satisfying
  quorum member the server can then unilaterally update policies and signers.
  An m-of-k quorum with m>=2 yields dual consent. [privy-user-and-server-signers]
- unity-surfaces Account already enrolls its key quorum as an **additional signer**
  on the user's embedded wallet at login, via `addSigners({address, signers:
  [{signerId, policyIds: []}]})`, where `signerId` comes from
  `NEXT_PUBLIC_PRIVY_KEY_QUORUM_ID`. The enrollment is best-effort: it is skipped
  when the quorum id is unset, skipped when the address does not appear in
  `user.linkedAccounts` within a 2500 ms wait, and a thrown error is swallowed with
  `console.warn`. [account-login-attach-signer]
- Account's runtime passes the raw key to Privy as
  `authorization_context.authorization_private_keys` and reads it from
  `ACCOUNT_PRIVY_WALLET_AUTHORIZATION_PRIVATE_KEY` or the legacy
  `PRIVY_SIGNER_PRIVATE_KEY`. It signs `eth_signTypedData_v4` (server
  registration) and `personal_sign` of the fixed reusable string
  `vana-master-key-v1` (owner binding). [account-constrained-silent-signing]
- Context Gateway's custody-v2 asserts a topology that is stricter than key
  storage alone: wallet `owner_id` equals a separate owner quorum and must not
  equal the runtime signer, wallet-level `policy_ids` must be empty, exactly one
  additional signer must exist bound to exactly one override policy, the runtime
  signer quorum must be 1-of-1 with no user members and a public-key fingerprint
  matching config, and the policy must contain exactly one ALLOW rule for
  `eth_signTypedData_v4` bounded by `primary_type`, domain `chain_id`,
  `verifying_contract`, message `asset`, and an `lte` bound on `amount`.
  [cg-app-wallet-custody]
- CG's KMS adapter verifies the pinned `CryptoKeyVersion` name, that its algorithm
  is `EC_SIGN_P256_SHA256` and state is ENABLED, and that the fetched SPKI equals
  the configured `PRIVY_AUTH_PUBLIC_KEY`, before signing; it then locally verifies
  each returned DER signature against that public key. It refuses to start in
  production if `PRIVY_AUTH_PRIVATE_KEY` is set, and caches verification in a
  promise that is cleared on failure so a transient error can be retried.
  [cg-privy-authorization-signer]

## SOURCES

**privy-owners-overview**
URL: https://docs.privy.io/controls/authorization-keys/owners/overview
Accessed: 2026-08-13
Quote: "Signers on a wallet ... cannot update a wallet's owner, signers, or policies."

**privy-user-owner-config**
URL: https://docs.privy.io/controls/authorization-keys/owners/configuration/user
Accessed: 2026-08-13
Quote: "If you create wallets via one of Privy's client-side SDKs, your app's wallets are automatically created with user owners."

**privy-user-and-server-signers**
URL: https://docs.privy.io/recipes/wallets/user-and-server-signers
Accessed: 2026-08-13
Quote: "Once a user logs in, you can use the `addSigners` method of `useSigners` hook to add your app's authorization key as a signer on the wallet."

**privy-policy-overview**
URL: https://docs.privy.io/controls/policies/overview
Accessed: 2026-08-13
Quote: "If no rules resolve, the policy will default to `DENY`."

**privy-signers-overview**
URL: https://docs.privy.io/wallets/using-wallets/signers/overview
Accessed: 2026-08-13

**account-login-attach-signer**
URL: unity-surfaces apps/account/src/app/login/_components/privy-login.tsx (attachSignerForNewWallet, readPrivyKeyQuorumId)
Accessed: 2026-08-13

**account-constrained-silent-signing**
URL: unity-surfaces apps/account/src/lib/signing/constrained-silent-signing.ts
Accessed: 2026-08-13

**cg-app-wallet-custody**
URL: context-gateway apps/api/src/lib/app-wallet-custody.ts (assertAppWalletCustodyTopology, assertGenericPaymentPolicy)
Accessed: 2026-08-13

**cg-privy-authorization-signer**
URL: context-gateway apps/api/src/lib/privy-authorization-signer.ts
Accessed: 2026-08-13

## SYNTHESIS

- The two workloads have structurally different custody models. CG signs
  **app-owned** wallets it creates itself, so it can choose the owner quorum at
  creation time and re-assert topology at will. Account signs **user-owned**
  embedded wallets it does not and cannot own; the only lever it has over a given
  wallet is the override policy attached to its already-consented signer. Code
  reusable across the two is therefore the KMS/`sign_fns` adapter, not the custody
  assertion, which depends on being the wallet's creator.
- Because Account's key is a signer and not an owner, the migration hazard usually
  associated with this work (moving ownership) does not apply, and rollback is
  cheap: both a raw-key signer and a KMS signer can be registered on the same
  1-of-1 quorum, so the same `signerId` keeps working while only the key material's
  location changes. This makes KMS adoption low-risk but also low-value on its own.
- The actual authorization gap is `policyIds: []` at enrollment. A default-deny
  policy only exists if a policy is attached; an empty override policy list means
  the signer is unconstrained within Privy, so a compromised runtime can request
  any `personal_sign` or typed-data signature from every enrolled user's wallet.
  Non-exportability of the key changes who can steal the key, not what the runtime
  can ask for. Policy scoping is the control that bounds blast radius; KMS is the
  control that bounds key theft. They are not substitutes, and the policy one is
  strictly more urgent here.
- `vana-master-key-v1` is a fixed, reusable, non-session-bound message whose
  signature is treated elsewhere as a possession credential. A policy can bound it
  by exact `content`, but any signature the runtime obtains remains replayable
  forever, so policy scoping caps the damage without eliminating it; that argues
  for retiring the reusable-message pattern rather than only fencing it.
- Best-effort signer enrollment at login (silent skip on unset quorum id, on a
  2500 ms `linkedAccounts` race, and on any thrown error) means the enrolled
  population is unknown and partial. Any policy rollout must be measured against
  actual enrollment rather than assumed universal, and enrollment failures should
  be observable rather than `console.warn`-only.
