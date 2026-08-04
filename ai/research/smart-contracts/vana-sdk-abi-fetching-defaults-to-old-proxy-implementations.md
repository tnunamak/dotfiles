---
title: "Vana SDK ABI fetching defaults to the oldest proxy implementation, missing new role/function definitions deployed on mainnet"
date: 2026-08-04
topic: smart-contracts
tags: [blockchain, proxy-pattern, versioning, abi, vana-sdk]
status: draft
sources: [vana-github, vanascan-moksha, vanascan-mainnet, github-fetch-script]
source_session: 1fe92e40-f585-49e1-9fb7-cc88341d86e1
---

## CLAIMS

- **Vana SDK `fetch-abis` script fetches from `implementations[0].address`** — the FIRST (oldest) implementation in the proxy array, not the latest [vana-github]. This is problematic when a proxy has multiple implementations and the newest is deployed on a different network or a later block.

- **Moksha testnet has an old implementation (0x1fc31e06e14C9A23AeAB7701fFc4327f624eE45b) without DLP_REWARD_DEPLOYER_ROLE** [moksha-scan]. The mainnet implementation (0x4642bB0ae9A11c2aFBd858cCEFd3b60C59Efca11) added new role definitions and bonus-system functions that never reached Moksha.

- **DLP_REWARD_DEPLOYER_ROLE is real and defined on mainnet but absent from the generated ABI when fetching from Moksha's older implementation** [vanascan-mainnet]. The block explorer shows the role when viewing the proxy contract but the SDK's typed bindings (in `src/generated/abi/`) omit it entirely.

- **Moksha testnet lags mainnet in features** — new epoch-rewards, staker-enumeration, and DLP-bonus functions exist only on mainnet [vana-github]. This inverts typical dev-to-prod deployment order.

- **The fix is one-line: use `implementations[contractInfo.implementations.length - 1].address`** instead of `[0]` to fetch from the latest implementation [vana-github].

## SOURCES

- **vana-github** — https://github.com/vana-com/vana-sdk.git
  - Accessed: 2026-08-04
  - Fetch script line 78 uses `implementations[0].address` to select which contract to fetch the ABI from
  - Quote: "The problem is in the fetch-abis script at line 78 — it takes implementations[0].address, which grabs the first (oldest) implementation instead of the latest one"

- **moksha-scan** — https://moksha.vanascan.io/api/v2/smart-contracts/0x1fc31e06e14C9A23AeAB7701fFc4327f624eE45b
  - Accessed: 2026-08-04
  - Confirms the Moksha testnet implementation lacks DLP_REWARD_DEPLOYER_ROLE and newer functions
  - Quote: "Confirmed! Moksha testnet is actually behind mainnet. The Moksha implementation only has [older functions, missing bonus/epoch functions]"

- **vanascan-mainnet** — https://vanascan.io/api/v2/smart-contracts/0x4642bB0ae9A11c2aFBd858cCEFd3b60C59Efca11
  - Accessed: 2026-08-04
  - Shows the mainnet implementation WITH DLP_REWARD_DEPLOYER_ROLE at line 553 in the generated ABI
  - Quote: "Perfect! DLP_REWARD_DEPLOYER_ROLE is now in the generated ABI at line 553! Mainnet has a newer implementation (0x4642...) with DLP_REWARD_DEPLOYER_ROLE while Moksha testnet has an older one (0x1fc3...)"

## SYNTHESIS

The Vana SDK's ABI generation pipeline has a subtle but real bug: it defaults to **the oldest proxy implementation instead of the newest**. This causes teams developing against Moksha testnet to ship ABIs and typed bindings that are out-of-date relative to mainnet production.

**Why this matters:** Role constants like `DLP_REWARD_DEPLOYER_ROLE` and bonus-system functions are real, auditable, deployed code — but they vanish from the SDK's type definitions unless you explicitly target mainnet. A developer following the default workflow would believe those functions don't exist, or would get runtime errors when trying to use `DLP_REWARD_DEPLOYER_ROLE`.

**Structural lesson:** Proxy patterns store implementation addresses in an array, but `[0]` is rarely the right pick — it's either "the original" (often the buggiest) or "the current" (usually the right choice for contracts). The script should either:
- Default to the **latest** (`implementations[-1]`), or
- Provide a **flag** to select by network or by index, or
- **Document** that the first implementation is fetched and why

Current state makes the default wrong, silently.

The finding about Moksha lagging mainnet is also reusable: when syncing testnet state with production, verify implementation arrays are in sync; version mismatches indicate missed backports.
