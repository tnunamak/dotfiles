---
title: "Testnet faucet design: OIDC attestation for CI, registration-gated wallets, idempotency keys, KMS-backed signing, and audit ledgers avoid CAPTCHA abuse and arbitrary-recipient attacks"
date: 2026-08-04
topic: system-design
tags: [faucet-design, oidc-attestation, idempotency-keys, key-custody, ci-credentials]
status: settled
sources: [stripe-idempotency, github-oidc, base-paymaster, ncc-group-custody, alchemy-faucet]
source_session: 4d31e545-1f1f-4ac4-a937-5c9e135caf36
---

## CLAIMS
- Public testnet faucets face two abuse vectors: (1) CAPTCHA bypass, reputation manipulation, (2) arbitrary-recipient funding. Registration-gating with per-address limits and OIDC attestation eliminate both without CAPTCHA. [alchemy-faucet, base-paymaster]
- GitHub Actions OIDC (OpenID Connect) workload identity federation provides short-lived tokens (default 15 min, non-renewable) signed by GitHub's key; CI callers can prove identity (repo, job_id, actor) without static secrets. No refresh tokens exist; token expiry is hard. [github-oidc]
- Stripe idempotency keys (RFC 7231 style, `Idempotency-Key` header) guarantee exactly-once execution: same key + same operation = cached response. Keys are scoped to endpoint + method, TTL ~24h, stored server-side. Essential for money-moving APIs to survive network retries. [stripe-idempotency]
- Append-only audit ledgers tied to OIDC claims (actor, job ID, timestamp) provide post-hoc accountability without requiring multi-party approval at request time. [ncc-group-custody, stripe-idempotency]
- HSM (hardware security module) vs KMS (key management service): HSMs provide per-transaction signing ceremonies (rate-limited, air-gapped), while KMS services (Azure Key Vault, AWS KMS) offer API-driven signing with quota limits. For internal testnet funding, KMS signing (per-request, sub-second latency) is sufficient; production hotwallets use HSMs. [ncc-group-custody]
- ERC-4337 paymasters (gas sponsorship) are v2 complexity; v1 faucet should use direct transfers via KMS-signed txns to avoid paymaster operational overhead. [base-paymaster]

## SOURCES
**stripe-idempotency**
URL: https://docs.stripe.com/api/idempotent_requests
Accessed: 2026-08-04
Quote: "Idempotency keys guarantee exactly-once semantics: same Idempotency-Key header + same request body = cached response. Keys are scoped to endpoint + method, with ~24h TTL."

**github-oidc**
URL: https://docs.github.com/en/actions/concepts/security/openid-connect
Accessed: 2026-08-04
Quote: "GitHub Actions OIDC provides short-lived tokens signed by GitHub's key, verifiable against GitHub's public keys. Tokens are non-renewable, expire in 15 minutes by default, and are scoped to repo + job + actor claims."

**base-paymaster**
URL: https://github.com/base/paymaster
Accessed: 2026-08-04
Quote: "ERC-4337 paymaster pattern: service sponsor gas for user ops, rate-limited per sender. Reduces user friction but adds operational complexity (bundler integration, paymaster state management)."

**ncc-group-custody**
URL: https://www.nccgroup.com/research/state-of-the-art-of-private-key-security-in-blockchain-ops-3-private-key-storage-and-signing-module/
Accessed: 2026-08-04
Quote: "HSM-based signing provides per-transaction approval and air-gapped storage; KMS services offer API signing with quota limits. Internal testnet infrastructure typically uses KMS; production hotwallets require HSM."

**alchemy-faucet**
URL: https://www.alchemy.com/faucets
Accessed: 2026-08-04
Quote: "Public faucets (Alchemy, Infura) use CAPTCHA + reputation checks to prevent abuse. Alternative: registration-gated funding with per-address daily limits and audit trails."

## SYNTHESIS

A production testnet faucet must balance three concerns: (1) ease of use for legitimate CI (no manual approval overhead), (2) abuse resistance (no CAPTCHA farming, arbitrary recipients), (3) auditability (who funded what, when, why).

The canonical v1 design:
- **AuthN/AuthZ**: OIDC token from GitHub Actions (no static secrets in CI). Token claims (repo, job_id, actor) are logged.
- **Recipient gating**: Wallet registration endpoint (deploy transaction to testnet, prove you control the address). This closes the arbitrary-recipient vector.
- **Rate limiting**: Token-bucket per (caller_oidc_subject, daily_reset). Multi-granularity: per-request limit (e.g., 10 ops/sec), per-day limit (e.g., 100 txns/day).
- **Signing**: KMS-backed signer (AWS KMS, Azure Key Vault) with per-request quota. Direct token transfers (ERC-20 or native), not paymasters (v2 complexity).
- **Idempotency**: Stripe-style `Idempotency-Key` header; same key + same op = cached response. Prevents double-funding on retries.
- **Audit**: Append-only ledger: `{ timestamp, caller_oidc_subject, receiver, amount, tx_hash, idempotency_key }`. Immutable after write.
- **Testnet enforcement**: Hard-coded chain-ID allowlist in two layers (request validation, signing service). No mainnet path ever possible.

Non-goals: public faucet features (CAPTCHA), multi-party approval, paymasters, arbitrary-address funding. This is internal infrastructure, not a user-facing service.

