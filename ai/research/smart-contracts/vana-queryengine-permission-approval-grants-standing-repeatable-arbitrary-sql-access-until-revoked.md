---
title: "Vana QueryEngine data-access permissions are standing, repeatable grants for arbitrary SQL against a refiner's schema, not one-time or query-scoped approvals"
date: 2026-08-06
topic: smart-contracts
tags: [vana, query-engine, data-access-layer, permissions, DLP, refiner, TEE]
status: draft
sources: [vana-data-access-dlps-docs, vana-general-search]
source_session: e1661421-2620-467d-8caa-3a04066b1984
---

## CLAIMS

- A Vana QueryEngine data-access permission authorizes the grantee to write and submit **arbitrary SQL** against the refined dataset's schema — it is not limited to pre-approved query templates. [vana-data-access-dlps-docs]
- Two separate permission types exist and are both checked on-chain before a job runs: data access (scoped to a `refinerId`) and compute access (scoped to a `computeInstructionId`), verified via `getPermissions(uint256 refinerId, address grantee)`. [vana-general-search]
- Approval is a **standing grant, not single-use**: once `updatePermissionApproval` sets a permission to approved, the grantee can submit new query jobs repeatedly at any future time with no further per-query authorization, until the owner explicitly revokes it. [vana-data-access-dlps-docs]
- Query execution happens inside a TEE, so the grantee receives processed results/artifacts rather than a raw data dump — but the result content is bounded only by what the refiner's schema exposes and what SQL the grantee chooses to run, so schema-exposed PII-level fields remain exfiltratable field-by-field via repeated queries. [vana-data-access-dlps-docs]
- The blast radius of *not* revoking an approved permission is: the grantee retains an open-ended query interface to that refiner's data indefinitely, not a closed/expired one-time access window. [vana-data-access-dlps-docs]

## SOURCES

**vana-data-access-dlps-docs**
URL: https://docs.vana.org/data-applications/data-access-dlps
Accessed: 2026-08-06
Quote: "The schema defines the queryable structure (e.g. SQLite tables); use it to write valid SQL for your job."

**vana-general-search**
URL: (aggregated from web search — docs.vana.org/docs/data-access-layer, docs.vana.org/docs/the-data-access-layer, vana-com/vana-refinement-service on GitHub)
Accessed: 2026-08-06
Quote: "the owner grants you data access (for a specific refinerId) and compute access (for a specific computeInstructionId), and you verify both onchain before submitting jobs"

## SYNTHESIS

The key non-obvious fact for anyone operating a DLP/refiner owner wallet: `updatePermissionApproval(id, false)` is the only thing that closes an open query channel — there's no natural expiry, no per-query re-approval, and no query-count/quota ceiling documented anywhere in the protocol docs. Treat any approved permission exactly like a standing API key scoped to a dataset's SQL surface: if the grantee address is unknown, stale, or no longer trusted, revoking is not precautionary cleanup, it's closing an active door. The actual sensitivity of leaving it open depends on what fields the specific refiner's schema exposes (aggregate stats vs. PII-level rows) — that's refiner-specific and has to be checked per refiner, not assumed from the permission mechanism alone.
