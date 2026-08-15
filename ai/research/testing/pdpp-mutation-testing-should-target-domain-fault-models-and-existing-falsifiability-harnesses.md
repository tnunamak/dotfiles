---
title: "PDPP mutation testing should target domain fault models and existing falsifiability harnesses before any generic mutation score"
date: 2026-08-11
topic: testing
tags: [pdpp, mutation-testing, connectors, falsifiability, node-test, sqlite-postgres]
status: draft
sources: [pdpp-scale-measurement, pdpp-root-package, pdpp-ri-package, pdpp-polyfill-package, pdpp-test-accounting-authority, pdpp-ri-runner, pdpp-connector-state-falsifiability, pdpp-broken-connector-state-driver, pdpp-groupme-frontier, pdpp-jellyfin-mutation, pdpp-record-filter-mutants, pdpp-falsifiability-files, pdpp-polyfill-test-list, corpus-general-mutation, corpus-stryker-pdpp]
source_session: unknown
---

## CLAIMS

- PDPP's current scale makes repository-wide mutation testing a poor first move: a local file-count measurement found 809 top-level reference-implementation `.test.ts` files, 214 reference-implementation server TypeScript files, and 571 polyfill-connector TypeScript files. [pdpp-scale-measurement]
- PDPP root scripts route most test execution through `node --test` with `tsx` or package-specific wrappers, and the root package does not declare Jest or Vitest. [pdpp-root-package]
- The reference implementation package runs tests through `node scripts/run-tests.ts`; its package scripts include `test`, storage-profile tests, live CDP/Neko tests, `typecheck`, and `verify`, but no mutation-testing script. [pdpp-ri-package]
- The polyfill-connectors package runs tests with `node --test --import tsx --test-concurrency=2 --test-timeout=120000` over `bin/**/*.test.ts`, `connectors/**/*.test.ts`, and `src/**/*.test.ts`; it has no mutation-testing script. [pdpp-polyfill-package]
- The test-accounting authority runner binds suite/profile/files, records transcripts, distinguishes stalled leaves from slow leaves with a 300-second no-output budget, and treats receipts as digest-bound accounting artifacts. [pdpp-test-accounting-authority]
- The reference-implementation test runner creates isolated per-file PostgreSQL databases when `PDPP_TEST_POSTGRES_URL` is set and falls back safely if allocation fails; this is already a real backend-parity test substrate for storage mutants. [pdpp-ri-runner]
- PDPP already has broken-driver falsifiability tests for blob store, connector state scheduler, consent device auth, disclosure spine, lexical retrieval, record mutation, and record read conformance. [pdpp-falsifiability-files]
- The connector-state scheduler falsifiability test runs a conformance harness against a deliberately broken in-memory driver and requires at least one state, schedule, and active-run invariant violation to be detected; its failure message names green-only conformance as "coverage may be theater." [pdpp-connector-state-falsifiability]
- The broken connector-state scheduler driver intentionally collapses grant scope, appends schedules instead of upserting, permits duplicate active runs, and implements restart simulation as a no-op. [pdpp-broken-connector-state-driver]
- GroupMe's incremental frontier tests explicitly target cursor/pagination mutants, including arbitrary page-count caps and non-progressing cursors, by exercising real exported collection paths rather than reimplementing the logic in tests. [pdpp-groupme-frontier]
- Jellyfin has a local file named `mutation.test.ts` that removes or weakens guards such as streaming byte cap, repeated-page detection, and max-pages behavior, then drives production collection paths against a real local HTTP server. [pdpp-jellyfin-mutation]
- Record-filter predicate tests explicitly target boundary mutants for inclusive/exclusive range operators, grant resource constraints, time ranges, JSON-path escaping, candidate scans, and malformed record JSON tolerance. [pdpp-record-filter-mutants]
- Polyfill connector tests already include many domain surfaces named around cursor, checkpoint, coverage, considered counts, detail gaps, fingerprints, integration fixtures, schemas, and auth probes. [pdpp-polyfill-test-list]
- The existing general mutation-testing corpus entry concludes mutation testing should be sampled, diff-aware, and risk-specific feedback rather than a global adequacy gate. [corpus-general-mutation]
- The existing StrykerJS-for-PDPP corpus entry concludes StrykerJS is viable only as a narrow pilot because PDPP's `node:test` plus `tsx` workflow loses runner intelligence compared with first-class runner plugins. [corpus-stryker-pdpp]

## SOURCES

**pdpp-scale-measurement**
URL: /home/tnunamak/code/pdpp
Accessed: 2026-08-11
Quote: "Measured with `find reference-implementation/test -maxdepth 1 -name '*.test.ts' | wc -l`, `find reference-implementation/server -type f ... | wc -l`, and `find packages/polyfill-connectors -type f ... | wc -l`: 809, 214, 571."

**pdpp-root-package**
URL: /home/tnunamak/code/pdpp/package.json
Accessed: 2026-08-11

**pdpp-ri-package**
URL: /home/tnunamak/code/pdpp/reference-implementation/package.json
Accessed: 2026-08-11

**pdpp-polyfill-package**
URL: /home/tnunamak/code/pdpp/packages/polyfill-connectors/package.json
Accessed: 2026-08-11

**pdpp-test-accounting-authority**
URL: /home/tnunamak/code/pdpp/scripts/test-accounting/authority.ts
Accessed: 2026-08-11

**pdpp-ri-runner**
URL: /home/tnunamak/code/pdpp/reference-implementation/scripts/run-tests.ts
Accessed: 2026-08-11

**pdpp-connector-state-falsifiability**
URL: /home/tnunamak/code/pdpp/reference-implementation/test/connector-state-scheduler-conformance-falsifiability.test.ts
Accessed: 2026-08-11

**pdpp-broken-connector-state-driver**
URL: /home/tnunamak/code/pdpp/reference-implementation/test/helpers/broken-connector-state-scheduler-driver.ts
Accessed: 2026-08-11

**pdpp-groupme-frontier**
URL: /home/tnunamak/code/pdpp/packages/polyfill-connectors/connectors/groupme/incremental-frontier.test.ts
Accessed: 2026-08-11

**pdpp-jellyfin-mutation**
URL: /home/tnunamak/code/pdpp/packages/polyfill-connectors/connectors/jellyfin/mutation.test.ts
Accessed: 2026-08-11

**pdpp-record-filter-mutants**
URL: /home/tnunamak/code/pdpp/reference-implementation/test/record-filters-predicates.test.ts
Accessed: 2026-08-11

**pdpp-falsifiability-files**
URL: /home/tnunamak/code/pdpp/reference-implementation/test
Accessed: 2026-08-11
Quote: "The falsifiability file inventory found seven `*-falsifiability.test.ts` files plus broken drivers for blob store, connector-state scheduler, consent device auth, disclosure spine, lexical retrieval, record mutation, and record read."

**pdpp-polyfill-test-list**
URL: /home/tnunamak/code/pdpp/packages/polyfill-connectors
Accessed: 2026-08-11

**corpus-general-mutation**
URL: /home/tnunamak/code/dotfiles/ai/research/testing/mutation-testing-should-be-sampled-diff-aware-risk-specific-feedback-not-a-global-adequacy-gate.md
Accessed: 2026-08-11

**corpus-stryker-pdpp**
URL: /home/tnunamak/code/dotfiles/ai/research/testing/strykerjs-is-viable-for-pdpp-only-as-a-narrow-pilot-because-node-test-plus-tsx-loses-runner-intelligence.md
Accessed: 2026-08-11

## SYNTHESIS

PDPP should treat mutation testing as a domain falsification layer that extends the project's existing negative-proof culture. The repo already has named "mutation-killing" tests and deliberately broken conformance drivers. That local pattern is stronger than a generic score because it asks a PDPP-specific question: if a connector, grant, cursor, storage, or projection implementation were wrong in a plausible way, would the current tests notice?

The first pilot should target risk surfaces where AI-authored code, tests, fixtures, and mocks can share one mistaken model:

- Connector cursor, checkpoint, coverage, and detail-gap decisions. Mutants should flip pagination direction, impose or remove arbitrary page caps, advance cursors past unparsed rows, convert unknown denominators to zero, mark failed detail hydration as covered, or lose per-stream/per-key accounting.
- Auth, grants, and source-binding enforcement. Mutants should drop fail-closed checks, weaken grant/source matching, conflate owner and grant scope, skip revocation lineage, or treat connection identity metadata as authority.
- Pagination, filtering, projection, and read windows. Mutants should flip inclusive/exclusive boundaries, remove candidate scans, mis-escape JSON paths, loosen field-window bounds, or ignore grant resource/time constraints.
- SQLite/Postgres parity. Mutants should target dialect-specific branches, transaction boundaries, row-lock/upsert semantics, cursor ordering, and JSON coercion where the RI runner can use per-file PostgreSQL databases as a real backend oracle.
- Async, concurrency, and process boundaries. Mutants should remove active-run exclusivity, lease abandonment recovery, schedule upsert idempotency, process-group cleanup, pipe resilience, or non-progress guards.
- Remote-service fixtures and mocks. Mutants should falsify captured fixture assumptions, repeated-page handling, byte caps, credential probe outcomes, setup modality, and manifest honesty rather than only mutating parser syntax.

Run this in stages:

1. Inventory lane: no mutation runner. Generate a map of existing mutation-killing/falsifiability files, candidate source files, associated tests, runtime class, and backend requirements.
2. Manual domain-mutant lane: add a small external script or branch-local patch generator for 10-20 known PDPP fault models. Do not commit mutants. Run selected existing tests and record killed/survived/no-coverage/timeout/equivalent classifications.
3. Stryker compatibility lane: run Stryker only on one fast pure-helper island, likely record filters, cursor codecs, or connector rollup/projection helpers. Keep thresholds at zero and use results as diagnostic output only.
4. Changed-lines lane: for consequential PRs, sample one interesting domain mutant per changed line or helper, capped by runtime and reviewer budget. Require the agent to kill it, classify it, or record a real test gap.
5. Promotion lane: only after measured signal, add a non-blocking CI job for selected hotspots. Merge gates should be limited to "the mutation pilot completed and triage was recorded," not a mutation percentage.

Suggested cost caps:

- Local shadow run: 10 minutes total, 20 mutants max, 50% CPU max, no live browser or live third-party network.
- CI shadow run: 30 minutes total, changed-lines or named hotspot only, no more than two storage profiles unless the mutant is storage-specific.
- Triage budget: five minutes per survivor before marking "needs human/domain review."
- Operator budget: prefer one high-quality survivor over a full report of equivalent or uninteresting mutants.

Metrics to capture:

- Mutants generated, skipped, killed, survived, no-coverage, timeout/error, and equivalent/uninteresting.
- Runtime per mutant and per selected test set.
- Test-selection misses discovered by a complete backstop.
- Number of survivors that became a better test, a product bug, an equivalent-mutant suppression, or a rejected/uninteresting case.
- Whether an AI agent could explain the mutant and produce an independent oracle without copying the implementation's assumptions.

Stop/go criteria:

- Continue if at least 30% of relevant survivors lead to improved tests or real defect discoveries, median triage stays under five minutes, and the run stays inside the local/CI caps.
- Narrow the operator set if most survivors are equivalent, syntactic, or style-only.
- Stop or redesign if command-runner Stryker loses too much test-selection precision, if mutants mostly hit generated/adapter glue, or if the pilot encourages score chasing.
- Promote only after a complete backstop shows the selected-test lane has an acceptable miss rate for the chosen hotspot.

Non-goals:

- No repository-wide mutation score.
- No 100% mutation adequacy target.
- No PR blocking on raw survived-mutant count during the pilot.
- No browser/live-service mutation runs until pure/backend lanes prove signal.
- No test deletion based only on shared mutant kills.
- No hiding equivalent mutants without a reason recorded near the triage result.

Open gaps:

- No Stryker spike has been run against PDPP's actual `node:test` plus `tsx` suites.
- No changed-file to minimum trustworthy test-accounting suite map exists yet.
- No canonical PDPP mutation-operator list exists for cursor, grant, storage, and coverage fault classes.
- No storage-profile cost model exists for SQLite-only versus SQLite-plus-Postgres mutation runs.
- No standard triage artifact exists for agents to attach killed/survived/equivalent evidence to a PR.
