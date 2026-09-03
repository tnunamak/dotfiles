---
title: "Geth v1.17.5 fast-forwards a newly added empty freezer table but truncates all non-empty freezer tables to the shortest head"
date: 2026-08-23
topic: blockchain-storage
tags: [geth, freezer, ancient, bals, database-recovery]
status: draft
sources: [geth-freezer, geth-ancient-scheme, geth-accessors, geth-release]
source_session: 2026-08-11T09-41-16-019ff145-437b-7360-8693-8adb853b5410
---

## CLAIMS

- Geth v1.17.5 computes the common freezer head as the minimum item count among non-empty tables; empty tables do not lower that head. [geth-freezer]
- Geth v1.17.5 advances a newly added empty freezer table to the common head with `truncateTail(head)`, then truncates every table to the computed common head. [geth-freezer]
- The chain freezer contains a separate `bals` table for EIP-7928 block-level access lists. [geth-ancient-scheme]
- For ancient blocks whose BAL is unavailable, Geth stores a nil placeholder in the BAL table. [geth-accessors]
- Geth v1.17.5 release notes include a fix for freezer truncation on newly added empty tables after an unclean shutdown. [geth-release]

## SOURCES

**geth-freezer**
URL: https://github.com/ethereum/go-ethereum/blob/9621c6ad10934a01b5514886fb6fbd87640b6c05/core/rawdb/freezer.go
Accessed: 2026-08-23

**geth-ancient-scheme**
URL: https://github.com/ethereum/go-ethereum/blob/9621c6ad10934a01b5514886fb6fbd87640b6c05/core/rawdb/ancient_scheme.go
Accessed: 2026-08-23

**geth-accessors**
URL: https://github.com/ethereum/go-ethereum/blob/9621c6ad10934a01b5514886fb6fbd87640b6c05/core/rawdb/accessors_chain.go
Accessed: 2026-08-23

**geth-release**
URL: https://github.com/ethereum/go-ethereum/releases/tag/v1.17.5
Accessed: 2026-08-23

## SYNTHESIS

A zero-item extension table is excluded from Geth's minimum-head calculation. Geth then advances that table's virtual tail to the common head of the non-empty freezer tables. A short but non-empty extension table instead becomes the truncation boundary. The safest recovery experiment is therefore an untouched disposable-clone cold-open with exact stock v1.17.5, after proving that the BAL table has zero items and recording all non-BAL controls. Direct freezer-file editing, synthesizing millions of nil entries, or any production repair is not justified. Exact provenance, non-BAL byte/count equality, clean restarts, and canonical history checks remain mandatory.
