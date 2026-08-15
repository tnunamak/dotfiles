---
title: "Prysm terminal deposit contracts require canonical transition, current state, and replay-boundary proofs"
date: 2026-08-12
topic: distributed-systems
tags: [prysm, consensus, deposits, terminal-contract, vana, fail-closed]
status: verified-live
sources: [prysm-v5-source, vana-canonical-rpc, vana-live-canary]
source_session: "claude-odl 0e6bb946-8816-4af7-b245-105863408163 / Codex continuation"
---

# CLAIMS

- A post-genesis deposit proxy can become terminal while Prysm still needs the previously finalized deposit count. A safe exception must be explicit and chain-specific. The default client path must remain unchanged.
- The proof needs three independent parts: the exact canonical transition that made the proxy terminal; the current proxy and implementation state; and the finalized consensus deposit count/root plus local replay-cache consistency.
- A pruned execution node cannot prove historical runtime bytecode with `eth_getCode` at an old block. Exact terminal block, transaction, receipt, and `Upgraded(address)` linkage prove the transition; current proxy bytecode, implementation slot, and implementation bytecode prove current semantics.
- Local deposit caches can be valid but incomplete before `processPastLogs`. Require bounded internal consistency before replay, then require the exact count, index, root, and contiguous containers after normal log replay. A failed strict postcheck must restore `LastRequestedBlock`.
- `finalizedStateAtStartup` can be stale if the beacon starts before it catches up. A canary must begin from a healthy canonical state, and mismatch errors must report the non-sensitive slot, index, count, and root.
- Live rollout must be non-signing and beacon-only. Preserve a stopped, checksum-verified beacon DB; pin an immutable image digest; prove Geth identity/start/restart invariants; require no validator; and soak beyond the old error cadence while matching a trusted finalized root.

# SOURCES

- `prysm-v5-source`: OffchainLabs/Prysm v5.1.0 source and tests, including `processPastLogs`, `processBlockInBatch`, deposit cache initialization, and commit `ab60c21f7123ab6c8973a6efba20a412a113da3f` on `tnunamak/prysm:vana-terminal-deposit`.
- `vana-canonical-rpc`: `https://rpc.vana.org` and legacy `vana-archive-3`, used to cross-check chain ID, terminal block/transaction/receipt, proxy and implementation code, EIP-1967 slot, deposit state, and finalized roots.
- `vana-live-canary`: Serial beacon-only canaries on `vana-node-1` and `vana-node-2` on 2026-08-12. The first two node-1 builds failed closed on archive-state and replay-boundary assumptions; the revised build passed. Node 2 exposed stale startup-state timing, then passed after a healthy-start retry with diagnostics.

# SYNTHESIS

The durable pattern is not “hard-code a deposit count.” It is a small proof system at the client boundary. Pin the terminal transition and current executable state, bind the fixed count to finalized consensus and the local deposit data structure, allow only the normal replay mechanism to repair partial caches, and verify the strict postcondition before committing the replay cursor. Deploy the exception only where it is needed and keep rollback independent of the execution client.
