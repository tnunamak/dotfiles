---
title: "Privy's ethereum_calldata policy condition selects the called method with the literal field 'function_name' (arguments use '<function>.<input>'), and because the engine defaults to DENY a wrong field string silently bricks the wallet rather than opening a hole — while the SDK types leave field as an unconstrained string that cannot catch the mistake"
date: 2026-08-21
topic: validator-key-custody
tags: [privy, wallet-policy, key-custody, calldata, fail-closed, sdk-types]
status: draft
sources: [privy-policies-overview, privy-ethereum-examples, privy-node-sdk-types]
source_session: c38ae589-2454-42dd-a8cd-423297d21f4f
---

## CLAIMS

- To restrict an EVM wallet to one contract method, the `ethereum_calldata` condition's `field` must be the literal string `function_name` — not the name of your function, and not `method_name`/`method`/`functionName`, none of which appear in Privy's docs. [privy-ethereum-examples]
- A decoded argument is addressed as `<functionName>.<inputName>` — the actual Solidity function name, then the ABI input `name` (e.g. `depositNative.account`, `transfer.amount`). Only the bare, standalone `function_name` is a magic literal. [privy-policies-overview] [privy-ethereum-examples]
- The policy engine defaults to DENY when no rule resolves, and a policy that lacks a rule for the RPC method being called denies that method outright. So a wrong `field` string fails closed: the ALLOW rule never matches and every call is rejected. The failure mode is a bricked wallet, not a permissive one. [privy-policies-overview]
- The `abi` parameter is mandatory on every `ethereum_calldata` condition — including for zero-argument functions like `deposit()` — because it only tells Privy how to decode. The method match is NOT implied by supplying a one-function ABI; the explicit `function_name` condition is still required. [privy-policies-overview]
- `@privy-io/node@0.18.0` types `EthereumCalldataCondition.field` as a bare `string` with no enum, so neither TypeScript nor the OpenAPI schema can catch a wrong key. The sibling `EthereumTypedDataDomainConditionField` *is* enumerated, making this an inconsistency rather than a general limitation. [privy-node-sdk-types]
- `EthereumTransactionCondition.field` is a closed union of exactly `'to' | 'value' | 'chain_id'` — there is no condition type keyed on a raw 4-byte selector, so ABI-aware decoding is the only route to method-level restriction. [privy-node-sdk-types]
- `function_name` alone would permit that selector on *any* contract exposing it, so it must always be paired with a `to` condition. [privy-ethereum-examples]
- Values are compared exactly as submitted with no unit conversion (wei for native amounts), and the docs' own examples use hex. [privy-policies-overview]
- Transaction simulation runs *before* policy evaluation for sign-and-broadcast operations, so a revert or insufficient-funds condition surfaces as a simulation error and the policy is never evaluated — which makes policy misconfiguration harder to diagnose from error text alone. [privy-policies-overview]
- Privy supports at most one policy per wallet: `policy_ids` is typed `Array<string>` but documented as "up to one policy ID", and `WalletUpdateParams.policy_ids` says "Currently, only one policy is supported per wallet." All constraints must therefore live in a single policy's ruleset. [privy-node-sdk-types]

## SOURCES

**privy-policies-overview**
URL: https://docs.privy.io/controls/policies/overview
Accessed: 2026-08-21
Quote: "The value of `field` can be just the function name (e.g., `function_name`) to match any call to a given function, or the function name plus argument (e.g., `function_name.param_name`) to match a specific parameter."
Quote: "must always include an `abi` parameter with the contract's JSON ABI—even for functions with no input parameters (such as `deposit()`)."
Quote: "If no rules resolve, the policy will default to `DENY`."

**privy-ethereum-examples**
URL: https://docs.privy.io/controls/policies/example-policies/ethereum
Accessed: 2026-08-21
Quote: "Use `field: \"function_name\"` to match specific functions being called, regardless of their parameters."
Quote: "// 'transfer' must match the function name, 'amount' must match an input name."

**privy-node-sdk-types**
URL: node_modules/@privy-io/node@0.18.0/resources/policies.d.ts:354-392, resources/wallets/wallets.d.ts:2607-2610
Accessed: 2026-08-21
Quote: "export interface EthereumCalldataCondition { abi: AbiSchema; field: string; field_source: 'ethereum_calldata'; operator: ConditionOperator; value: ConditionValue; }"
Quote: "field: 'to' | 'value' | 'chain_id'; field_source: 'ethereum_transaction';"
Quote: "Body param: An optional list of up to one policy ID to enforce on the wallet."

## SYNTHESIS

This is the concrete mechanism for the cap that [vana-escrow-facilitator-role-can-pay-arbitrary-recipients...] concluded was mandatory. That entry established *what* the policy must express (a per-transaction value cap, because a destination allowlist cannot bound the facilitator key); this one establishes *how* to express it in Privy without silently getting it wrong.

The trap is worth internalizing because it inverts the usual security-misconfiguration intuition. Most policy-engine mistakes fail open — you think you're constrained and you aren't. Privy's defaults mean a typo'd `field` fails *closed*: the wallet signs nothing at all. That's the safe direction, but it means a policy bug looks like an outage, not a breach, and the error surface is muddied further because simulation runs before policy evaluation. Debugging "my wallet rejects everything" should start at the condition keys, not the funds or the auth key.

The deeper lesson for agent-written integrations: the SDK's `field: string` is a type that lies by omission. It typechecks any string while only a handful are meaningful, and the adjacent typed-data condition *is* enumerated — so the looseness reads as an oversight rather than a deliberate extension point. Wherever an SDK types a semantically-closed set as a bare `string`, compile-time cleanliness proves nothing and the value must be confirmed against docs or a live call. I shipped `method_name` from plausible inference and it typechecked cleanly; only a documentation sweep caught it. Related: the paired finding on double-spend is that this same SDK defaults to `maxRetries: 2` and retries on pre-response connection errors, so a money-moving call needs `maxRetries: 0` plus `privy-idempotency-key`.

Practical shape for a deposit-only funding wallet: one ALLOW rule on `eth_sendTransaction` with four conditions — `to` (lowercased; Privy compares as a string), `chain_id`, `value lte` cap, and `function_name eq <method>` with the ABI. Add a fifth on `<method>.<recipientArg>` if the recipient set is known at policy-creation time; without it the cap bounds a single transaction but does not prevent an attacker who holds the authorization key from looping in-policy calls to a recipient they control.
