---
title: "pnpm 11 relocates configuration and build approvals, and pnpm 12 rejects unknown workspace settings"
date: 2026-09-09
topic: monorepo-tooling
tags: [pnpm, migration, dependencies]
status: draft
sources: [pnpm11, pnpm12, imapflow2]
source_session: unknown
---

## CLAIMS

- pnpm11 requires Node22+, reads only auth and registry configuration from .npmrc, and removes onlyBuiltDependencies in favor of the allowBuilds boolean map. [pnpm11]
- pnpm11 defaults strictDepBuilds to true and minimumReleaseAge to1440 minutes; pnpm peers check reads peer problems from the lockfile. [pnpm11]
- pnpm12 rejects unknown workspace settings when the running version satisfies the project pin. Existing frozen lockfiles remain usable; dependency resolution canonicalizes cyclic peer keys. [pnpm12]
- ImapFlow2 requires Node20+, adds TypeScript ESM/CJS builds, and no longer publishes the lib directory; package root and exported lib paths remain supported. [imapflow2]

## SOURCES

**pnpm11**
URL: https://github.com/pnpm/pnpm/releases/tag/v11.0.0
Accessed: 2026-09-09

**pnpm12**
URL: https://github.com/pnpm/pnpm/releases/tag/v12.0.0
Accessed: 2026-09-09

**imapflow2**
URL: https://github.com/postalsys/imapflow/releases/tag/v2.0.0
Accessed: 2026-09-09

## SYNTHESIS

A pnpm10→12 migration needs a configuration audit before installation. Translate build approvals and non-registry .npmrc settings first, then regenerate the lockfile and check native build approvals and peer diagnostics. ImapFlow2 root-import consumers on supported Node versions mainly need type and behavior verification.
