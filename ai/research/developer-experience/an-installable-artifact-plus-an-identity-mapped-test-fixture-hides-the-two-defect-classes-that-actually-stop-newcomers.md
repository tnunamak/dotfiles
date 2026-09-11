---
title: "A green consumer test proves nothing if its fixtures are identity-mapped and its artifact is locally built — the two defect classes that stop newcomers hide exactly there"
date: 2026-09-07
topic: developer-experience
tags: [onboarding, test-selection, release-artifacts, canonicalization, acceptance-testing]
status: draft
sources: [pdpp-selfhost, pdpp-266, dc-40]
source_session: 6ecda586-fe64-480f-90e9-b502f18dc910
---

## CLAIMS

- A pack-install-run style consumer test can pass end-to-end while the published package on the
  registry is unusable, because the test packs a local tarball rather than resolving the artifact a
  newcomer would actually install. [pdpp-266]
- When a system canonicalizes identifiers (`claude_code` → `claude-code`), the connectors chosen as
  test fixtures determine whether a whole class of bug is reachable: an identity-mapped fixture
  (`codex` → `codex`) is *structurally incapable* of exercising a one-sided canonicalization guard,
  so the suite stays green while every renaming identifier is broken in production. [dc-40]
- Asymmetric canonicalization is the specific failure shape: one endpoint canonicalizes both sides
  before comparing, an adjacent endpoint canonicalizes only the server's side and demands an exact
  match. Bulk traffic passes and only the terminal/commit step fails, producing the deceptive
  signature "all N batches sent, run never completes". [dc-40]
- Self-host documentation for a server-plus-local-agent product tends to document only the server
  deployment (Docker/Railway/Fly.io) and omit the local agent entirely, even when the local agent is
  the only way to reach a large class of advertised data sources. [pdpp-selfhost]
- Docs can describe a feature that was never committed: a build-from-source section instructing users
  to "rebuild from a checkout that has the connector" for a connector with zero commits in
  `git log --all --diff-filter=A`. The failure mode is that users blame their own build. [pdpp-selfhost]

## SOURCES

**pdpp-selfhost**
URL: https://pdpp.dev/self-host
Accessed: 2026-09-07
Quote: "For local applications like Claude Code history, the page references 'the local collector' via GitHub documentation link, but does not mention npm packages like @pdpp/local-collector or provide specific integration steps for Slack, Signal, or other filesystem connectors."

**pdpp-266**
URL: https://github.com/PDP-Connect/pdpp/issues/266
Accessed: 2026-09-07
Quote: "Error [ERR_MODULE_NOT_FOUND]: Cannot find package '@pdpp/reference-contract' imported from .../node_modules/@pdpp/local-collector/dist/polyfill-connectors/src/local-device-client.js"

**dc-40**
URL: https://github.com/PDP-Connect/data-connect/issues/40
Accessed: 2026-09-07
Quote: "Data itself is NOT lost — in my test, 3164/3164 record batches were sent and (presumably) accepted individually. But the run/connection can never reach a 'drained'/complete state"

## SYNTHESIS

Two reusable lessons, both about where to point a test rather than how many to write.

**1. Test the artifact, not the source tree.** A consumer/smoke test that runs `npm pack` on the local
workspace answers "does this code work?" but not "can anyone get this code?" Those diverge silently the
moment release CI breaks — here the registry's `latest` was DOA for three weeks while the local suite
stayed green. The cheap fix is a second, separate check that resolves the *published* artifact and runs
one command against it; it fails loudly when release CI does, which is exactly when you want to know.
Keep it separate so a registry outage doesn't block the main suite.

**2. Choose fixtures adversarially against your own normalization.** Any codebase with a canonical-key
mapping has two fixture classes: identifiers that survive normalization unchanged, and identifiers that
change. They are not interchangeable as test data — only the second class can detect a one-sided
comparison. The general rule: when a system normalizes an identifier before comparing it, at least one
fixture must be one whose normalized form *differs* from its wire form. Grep for the mapping, list the
identity cases and the renaming cases, and check which class your fixtures fall into. In this instance
5 of 6 bundled connectors were covered and the guard still shipped broken, because the two chosen were
both identity-mapped.

A corollary worth generalizing: assert that work *completes*, not just that data *arrived*. Counting
persisted rows passed here while the run was permanently dead-lettered. Terminal state (`lifecycle_state`,
a completion event, a zero dead-letter count) is a distinct assertion from throughput, and it is the one
that maps to what a user perceives as "did it work".

For doc surfaces: an acceptance pass should verify that every command in a quickstart still resolves
(`pnpm run <script>` exists, linked paths exist, named features have commits). These rot independently of
code and are the first thing a newcomer touches. A CI link/command checker over README and operator docs
would have caught a deleted directory, four absent npm scripts, and a phantom connector section.
