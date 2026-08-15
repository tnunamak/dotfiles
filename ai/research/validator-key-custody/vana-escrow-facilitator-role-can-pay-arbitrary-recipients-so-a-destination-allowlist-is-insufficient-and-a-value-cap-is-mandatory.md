---
title: "Vana's DataPortabilityEscrow lets FACILITATOR_ROLE pay an arbitrary recipient from any account's in-escrow balance, so a destination allowlist cannot bound the facilitator key and a per-transaction value cap is mandatory — while the mainnet Safe can revoke the role but two Moksha deployments are still admin'd by the compromised PRO-807 key"
date: 2026-08-14
topic: validator-key-custody
tags: [vana, escrow, facilitator, access-control, key-custody, safe, incident-cleanup, on-chain-verification]
status: draft
sources: [escrow-impl, onchain-roles, moksha-roles, kms-design]
source_session: 4c9ad3f0-cb00-40cc-8bb9-baad3a7f16e5
---

## CLAIMS

- The escrow facilitator EOA `0x80534af0b80ae88d653cae0a8f5d2667439538a0` holds `FACILITATOR_ROLE` (`0x0424cf38c8834beebcaa33d45624a52f86494e75143c4aef2aafdb8bd68c732e`, verified as `keccak("FACILITATOR_ROLE")`) on `DataPortabilityEscrowProxy` at `0x07d7769081adc3a3DBe91f5E4B98E9A5a6B292e3`, Vana mainnet (chainId 1480). ERC-1967 proxy over verified implementation `0x0DE07F128B3a127Cae1AD6E8d44f2F6A6C3A9611`, Solidity 0.8.24. [onchain-roles]

- A full-history `RoleGranted` scan (block 0 → 9,688,663, chunked at 10k) found exactly one mainnet match, consistent with the key registry's "1 role" for this address. [onchain-roles]

- **`FACILITATOR_ROLE` can direct funds to an address that has never appeared in an escrow record.** The implementation's NatSpec states `settle` "pays an arbitrary external `to` from `from`'s in-escrow balance." All facilitator-gated payouts funnel through `_payout(from, to, asset, amount)`, which reverts only on zero amount, zero addresses, and insufficient balance *of the debited account*. The recipient is unchecked beyond being non-zero. [escrow-impl]

- Six functions are gated on `FACILITATOR_ROLE`: `settle`, `settleBatch`, `withdraw`, `registerAndSettle`, `recordAccessAndSettle`, `runOpAndSettle`. Selectors `0x77f2e878`, `0x39b57a05`, `0x4233e917`, `0xf4b23e03` each confirmed present in deployed mainnet bytecode. [onchain-roles, escrow-impl]

- The batch type is a flat array of independent structs: `struct SettleOp { address from; address to; address asset; uint256 amount; OpKind opKind; bytes32 ref; }`, consumed by `settleBatch(SettleOp[])` and looped identically by `registerAndSettle`, `recordAccessAndSettle`, and `runOpAndSettle`. Each element names its own arbitrary `from`/`to`/`asset`/`amount`. [escrow-impl]

- `runOpAndSettle(address target, bytes callData, SettleOp[])` dispatches an arbitrary target/calldata pair (gated by an admin allowlist of target+selector via `setOpAllowed`, forwarding zero value) before running the same settle loop. [escrow-impl]

- `getRoleAdmin(FACILITATOR_ROLE)` returns `0x00…00` (`DEFAULT_ADMIN_ROLE`) and the implementation never calls `_setRoleAdmin`. No `revokeRole`/`renounceRole` overrides exist, so standard OpenZeppelin `AccessControlUpgradeable` semantics apply. [escrow-impl, onchain-roles]

- On mainnet, Safe-A `0x5eca5208f29E32879a711467916965b2d753baf4` holds `DEFAULT_ADMIN_ROLE` (**true**); Safe-B `0xe6a285b0…bbb86` does not; the compromised PRO-807 key `0x2AC93684…792f` does not. The Safe can therefore unilaterally revoke the facilitator. [onchain-roles]

- Mainnet deployment history is a clean deploy-and-handoff: a CREATE2 factory granted both roles to bootstrap address `0x247f35279a32d2a5ad2f4ca5dd81fc150f2355b3`, which granted `FACILITATOR_ROLE` to the operational EOA (block 8,631,216) and `DEFAULT_ADMIN_ROLE` to Safe-A (block 8,631,228), then renounced both of its own roles (blocks 8,631,217 and 8,631,229). [onchain-roles]

- **On Moksha, two escrow deployments are still admin'd by the compromised key.** `0x47752a3278b55b71bfb1dffb5c202c169ca86dc8` and `0x987b6bb934e85f302ecb2e0cd0697557010eec26` return `hasRole(DEFAULT_ADMIN_ROLE, 0x2AC93684679a5bdA03C6160def908CdB8D46792f) == true`; neither Safe holds admin on either. Verified twice — via `cast` and via raw `eth_call` returning `0x…01`. A third Moksha proxy at the same address as mainnet (deterministic CREATE2 factory `0x4e59b44847b379578588920cA78FbF26c0B4956C`) does not have PRO-807 as admin. [moksha-roles]

- The Vana key registry independently lists `0x2AC93684…792f` as `COMPROMISED-STILL-LIVE` with 393 Moksha roles and 43 ownerships, so this is an instance of known outstanding cleanup rather than a new incident. [kms-design]

## SOURCES

**escrow-impl**
URL: verified source for `0x0DE07F128B3a127Cae1AD6E8d44f2F6A6C3A9611` (Vana mainnet)
Accessed: 2026-08-14
Quote (NatSpec): "`settle` pays an arbitrary external `to` from `from`'s in-escrow balance."
Quote (`_payout`): "if (amount == 0) revert ZeroAmount(); if (from == address(0) || to == address(0)) revert ZeroAddress(); uint256 fromBal = _balances[from][asset]; if (fromBal < amount) revert InsufficientBalance(...)" — then `safeTransfer(to, amount)`.

**onchain-roles**
URL: Vana mainnet RPC https://rpc.vana.org, chainId 1480
Accessed: 2026-08-14
Quote: `hasRole(FACILITATOR_ROLE, 0x80534af0…38a0)` → `0x…01`. `hasRole(DEFAULT_ADMIN_ROLE, 0x5eca5208…baf4)` → true. `hasRole(DEFAULT_ADMIN_ROLE, 0x2AC93684…792f)` → false. `getRoleAdmin(FACILITATOR_ROLE)` → `0x00…00`.

**moksha-roles**
URL: Moksha RPC https://rpc.moksha.vana.org, chainId 14800
Accessed: 2026-08-14
Quote: raw `eth_call` of `hasRole(0x00…00, 0x2AC93684…792f)` against `0x47752a3278…86dc8` and `0x987b6bb934…eec26` both returned `0x0000…0001`.

**kms-design**
URL: local — `vana-com/security`, `key-registry.md` and `kms-design.md` (branch `tim/privy-kms-signer-0813`)
Accessed: 2026-08-14
Quote (kms-design §7): "it stops arbitrary-destination drains, but calldata to the allowed escrow contract still goes through, so the real ceiling is whatever the contract lets `FACILITATOR_ROLE` do."
Quote (execution step 5): "read the escrow contract and answer *'can `FACILITATOR_ROLE` direct funds to an address not in an escrow record?'* If yes, enable the per-transaction value cap (§7) before migrating."

## SYNTHESIS

This resolves a conditional that Vana's KMS design left open, and it resolves it the expensive way. The design proposed a `to`-allowlist inside the signer library as the v1 control for the facilitator key, with a per-transaction value cap enabled only *if* the contract turned out to permit arbitrary recipients. It does. So the cap is mandatory, and the allowlist alone cannot bound this key — an attacker who compromises the facilitator runtime does not need a novel destination contract, only a `to` argument.

The deeper point is about where enforcement lives. An in-process allowlist and an in-process value cap both sit inside the application that holds the signing permission, which is precisely the component assumed compromised in the July-31 threat model. Any control the application enforces on itself is advisory against that threat. This is the strongest available argument for moving the facilitator behind an external policy boundary (a custody provider's policy engine, or an independent signing service) rather than putting the raw key in KMS with library-side checks — KMS closes key *exfiltration*, but it has no opinion about Ethereum destinations or amounts.

The batch shape sharpens the requirement on whatever external boundary is chosen. Because `SettleOp[]` elements each carry an independent recipient and amount, a policy engine that can only constrain a call as a whole is insufficient; it must decode and constrain array elements individually, or a single batch mixing one legitimate op with one malicious op passes. That is the concrete acceptance test for any candidate policy engine, and it is worth running before committing to a vendor.

Two secondary findings are worth carrying forward. First, the mainnet governance is in good shape and should be stated positively: the Safe can revoke the role immediately, the deploy-and-handoff renounced its bootstrap privileges properly, and there is no admin-role surprise. Recovery by role rotation is real, which is what makes any custody vendor replaceable. Second, the Moksha contracts still admin'd by the compromised PRO-807 key are a live cleanup item with an operational consequence beyond hygiene: they make Moksha unusable for rehearsing the revocation runbook on those deployments, so a testnet drill there would produce a false negative.

Method note worth repeating: `eth_getLogs` on Vana RPC is capped at a 10,000-block range, so historical role scans must be chunked, and a full-history sweep is slow but tractable. Where an explorer API is unavailable (vanascan returned 522 during this work), selector extraction from deployed bytecode plus targeted `eth_call` verification is a sufficient substitute — and 4byte.directory returns troll collisions for common selectors, so resolved names must be confirmed against the actual signature hash rather than trusted.
