---
title: "Privy custom signers match GCP KMS cryptographically, but KMS-only wallet ownership does not constrain a compromised runtime"
date: 2026-08-11
topic: web-security
tags: [privy, gcp-kms, oidc, workload-identity, wallet-custody, least-privilege]
status: settled
sources: [privy-server-signing, privy-signature-utilities, privy-node-sdk, privy-owner-signer-model, privy-policy-model, privy-policy-current, gcp-kms-algorithms, gcp-kms-node, gcp-kms-signature-validation, gcp-wif, vercel-oidc-gcp, cg-wallet-creation]
source_session: 2026-07-29T11-27-57-019faeb4-43df-75e1-9607-294f65e61bdf
---

## CLAIMS

- Privy's Node authorization context accepts a custom function that receives the already-formatted request bytes, performs ECDSA P-256 signing, and returns a base64 signature. [privy-server-signing]
- Privy documents KMS as a use case for that function and provides request-formatting utilities, but does not publish a GCP KMS adapter in the reviewed SDK or examples. A targeted npm and GitHub search on 2026-08-13 found no credible production-hardened community adapter. This is evidence of a gap, not proof that none exists. [privy-server-signing] [privy-signature-utilities]
- CG's installed `@privy-io/node` version exposes that function as `sign_fns`. [privy-node-sdk]
- GCP KMS supports `EC_SIGN_P256_SHA256`, the same curve and digest combination required by Privy. [gcp-kms-algorithms]
- The Node KMS client accepts an exact `CryptoKeyVersion` resource for both
  `GetCryptoKeyVersion`/`GetPublicKey` and `AsymmetricSign`, with a per-call
  timeout; its asymmetric-sign request accepts a SHA-256 digest and returns a
  signature that is verifiable with that version's public key. [gcp-kms-node]
- KMS grants `cloudkms.cryptoKeyVersions.viewPublicKey` and
  `cloudkms.cryptoKeyVersions.useToSign` separately. An application can prove
  it reached the intended KMS key, but it cannot truthfully introspect the ADC
  workload principal; the workload-identity/IAM binding and audit principal
  remain deployment evidence. [gcp-kms-signature-validation] [gcp-wif]
- Vercel can exchange environment-scoped OIDC identity for short-lived GCP credentials through Workload Identity Federation, avoiding a persisted GCP service-account key. [vercel-oidc-gcp] [gcp-wif]
- Privy owners can change wallet policies, owners, and additional signers; additional signers can sign only within their assigned policies and cannot change those controls. [privy-owner-signer-model]
- Privy policies default to deny and can constrain `personal_sign` and `eth_signTypedData_v4`, including typed-data chain ID, verifying contract, and message fields. [privy-policy-model]
- Privy's current policy reference explicitly lists `personal_sign` and the
  `message` source, whose `content` and `byte_length` fields support string and
  numeric conditions. CG's installed `@privy-io/node` PolicyMethod union does
  not yet list `personal_sign`, so SDK typing is not evidence that the live
  tenant lacks the capability; upgrade or REST/live-tenant proof is required.
  [privy-policy-current] [privy-node-sdk]
- CG currently creates every managed wallet with the same authorization public key as its Privy owner and uses the matching raw private key for `personal_sign` and `eth_signTypedData_v4`. [cg-wallet-creation]

## SOURCES

**privy-server-signing**
URL: https://docs.privy.io/controls/authorization-keys/using-owners/sign/signing-on-the-server
Accessed: 2026-08-11

**privy-signature-utilities**
URL: https://docs.privy.io/controls/authorization-keys/using-owners/sign/utility-functions
Accessed: 2026-08-13

**privy-node-sdk**
URL: https://unpkg.com/@privy-io/node@0.18.0/lib/authorization.d.mts
Accessed: 2026-08-11

**privy-owner-signer-model**
URL: https://docs.privy.io/controls/authorization-keys/owners/overview
Accessed: 2026-08-11

**privy-policy-model**
URL: https://docs.privy.io/controls/policies/overview
Accessed: 2026-08-11

**privy-policy-current**
URL: https://docs.privy.io/controls/policies/overview
Accessed: 2026-08-12

**gcp-kms-algorithms**
URL: https://docs.cloud.google.com/kms/docs/algorithms
Accessed: 2026-08-11

**gcp-kms-node**
URL: https://docs.cloud.google.com/nodejs/docs/reference/kms/latest/kms/v1.keymanagementserviceclient
Accessed: 2026-08-11

**gcp-kms-signature-validation**
URL: https://docs.cloud.google.com/kms/docs/create-validate-signatures
Accessed: 2026-08-11

**gcp-wif**
URL: https://docs.cloud.google.com/iam/docs/workload-identity-federation
Accessed: 2026-08-11

**vercel-oidc-gcp**
URL: https://vercel.com/docs/oidc/gcp
Accessed: 2026-08-11

**cg-wallet-creation**
URL: https://github.com/vana-com/context-gateway/blob/c55a130be38270a3659483aa516f1849fbe84f9e/apps/api/src/lib/grantee-wallets.ts
Accessed: 2026-08-11

## SYNTHESIS

- An ephemeral local P-256 probe against CG's installed SDK invoked `sign_fns`, produced a base64 DER signature, and verified it with P-256/SHA-256; the command and output are preserved in the source session.
- Moving the current shared owner key into KMS removes extractable key material but does not by itself prevent a compromised API runtime from authorizing malicious Privy requests or changing wallet controls.
- The least-privilege topology is a separately controlled administrative owner plus a KMS-backed runtime additional signer with deny-by-default policies. The normal API should not be able to update owners, signers, or policies.
- CG's base64url-encoded `personal_sign` payload is less policy-inspectable than
  its structured EIP-712 payment, but Privy's current reference exposes message
  prefix and byte-length conditions. Prefer a policy-bound additional signer
  after upgrading the SDK and proving the exact live policy. Use a validating
  signing broker only if the tenant cannot enforce the required bounds.
- The cryptographic integration risk is low. The remaining material risks are wallet migration, policy expressiveness, workload-identity configuration, and the availability/latency of the signing boundary.
- Pinning a key *version* instead of a rotating key alias makes the Privy public
  key association verifiable at process startup and prevents an unnoticed key
  version change from changing request authorization. It does not prove which
  workload obtained ADC, so that identity must be proved from restricted WIF
  configuration, exact-version IAM, and KMS audit logs during production setup.
