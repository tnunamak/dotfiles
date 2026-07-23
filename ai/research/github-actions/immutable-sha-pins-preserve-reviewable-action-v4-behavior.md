---
title: "Immutable SHAs preserve reviewable GitHub Action v4 behavior while mutable major tags can move"
date: 2026-07-16
topic: github-actions
tags: [github-actions, supply-chain, action-pinning, ci]
status: draft
sources: [checkout-v4-3-1, pnpm-setup-v4-3-0, setup-node-v4-4-0, upload-artifact-v4-6-2]
---

## CLAIMS

- `actions/checkout` v4.3.1 is commit `34e114876b0b11c390a56381ad16ebd13914f8d5`. [checkout-v4-3-1]
- `pnpm/action-setup` v4.3.0 is commit `b906affcce14559ad1aafd4ab0e942779e9f58b1`. [pnpm-setup-v4-3-0]
- `actions/setup-node` v4.4.0 is commit `49933ea5288caeca8642d1e84afbd3f7d6820020`. [setup-node-v4-4-0]
- `actions/upload-artifact` v4.6.2 is commit `ea165f8d65b6e75b540449e92b4886f43607fa02`. [upload-artifact-v4-6-2]

## SOURCES

**checkout-v4-3-1**
URL: https://github.com/actions/checkout/tree/34e114876b0b11c390a56381ad16ebd13914f8d5
Accessed: 2026-07-16

**pnpm-setup-v4-3-0**
URL: https://github.com/pnpm/action-setup/tree/b906affcce14559ad1aafd4ab0e942779e9f58b1
Accessed: 2026-07-16

**setup-node-v4-4-0**
URL: https://github.com/actions/setup-node/tree/49933ea5288caeca8642d1e84afbd3f7d6820020
Accessed: 2026-07-16

**upload-artifact-v4-6-2**
URL: https://github.com/actions/upload-artifact/tree/ea165f8d65b6e75b540449e92b4886f43607fa02
Accessed: 2026-07-16

## SYNTHESIS

For an existing workflow that intentionally uses v4 action APIs, pin the reviewed v4 commit and
retain a nearby readable release comment. This removes a mutable-reference supply-chain input without
silently changing the action major or the workflow's runtime behavior. Add a static test that allows
exactly the reviewed SHA for each required action, so a future major/tag substitution fails locally.
