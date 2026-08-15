---
title: "Agentic mutation testing should be a risk falsification service, not a runner or score"
date: 2026-08-11
topic: testing
tags: [mutation-testing, ai-agents, test-quality, falsification, ci]
status: draft
sources: [google-state, google-long-term, google-industrial, meta-ach-paper, meta-ach-blog, jest-cli, pdpp-mutation-oracle, pdpp-falsifiability, pdpp-groupme-frontier, pdpp-test-accounting, pdpp-existing-corpus]
source_session: unknown
---

## CLAIMS

- Google describes mutation testing as seeding small faults and measuring whether the test suite detects them; it also says traditional mutation analysis is computationally prohibitive. [google-state]
- Google's production approach is diff-based, omits uncovered lines, suppresses uninteresting "arid" lines, selects interesting mutants, and surfaces results in code review while accounting for developer attention. [google-state]
- Google's long-term study analyzed about 15 million mutants and reports that mutation testing exposure led developers to write more tests, improve test suites, and that live mutants were coupled with historical real faults. [google-long-term]
- Google's industrial follow-up says many mutants are redundant, equivalent, or uninteresting, and that mutation adequacy is neither practical nor desirable in industrial use. [google-industrial]
- Meta ACH generates fewer, issue-specific mutants than traditional mutation testing and uses uncaught mutants as prompts for LLM-generated tests that kill those mutants. [meta-ach-paper]
- Meta ACH was applied to 10,795 Android Kotlin classes across 7 platforms, generated 9,095 mutants and 571 privacy-hardening tests, and used an LLM-based equivalent-mutant detector. [meta-ach-paper]
- Meta describes ACH as a workflow where engineers provide plain-text risk descriptions and the system generates both problem-specific mutants and tests that catch them. [meta-ach-blog]
- Jest exposes `--findRelatedTests` to run tests covering specified source files, showing the mainstream shape of test-impact selection, but PDPP currently uses `node:test` plus manifest accounting rather than Jest. [jest-cli] [pdpp-test-accounting]
- PDPP has a bespoke mutation/rollback oracle for test-migration tooling that builds named broken cases, runs the production oracle, requires each named mutation to be caught, and proves rollback to a byte-identical tree. [pdpp-mutation-oracle]
- PDPP has conformance falsifiability tests that run a harness against a deliberately broken driver and fail if no invariant violation is caught. [pdpp-falsifiability]
- PDPP has connector-specific "mutation-killing" style tests, including GroupMe pagination/frontier tests that exercise real exported collection code and reject page-count ceilings and non-progress. [pdpp-groupme-frontier]
- Existing corpus research already concluded that mutation testing should be sampled, diff-aware, and risk-specific feedback rather than a global adequacy gate, and that StrykerJS is viable for PDPP only as a narrow pilot because Node `node:test` plus `tsx` loses runner intelligence. [pdpp-existing-corpus]

## SOURCES

**google-state**
URL: https://research.google/pubs/state-of-mutation-testing-at-google/
Accessed: 2026-08-11
Quote: "we present a diff-based probabilistic approach to mutation analysis"

**google-long-term**
URL: https://research.google/pubs/long-term-effects-of-mutation-testing/
Accessed: 2026-08-11
Quote: "We analyze a large dataset of 15 million mutants"

**google-industrial**
URL: https://research.google/pubs/an-industrial-application-of-mutation-testing-lessons-challenges-and-research-directions/
Accessed: 2026-08-11
Quote: "redundant, equivalent, or simply uninteresting"

**meta-ach-paper**
URL: https://arxiv.org/html/2501.12862v1
Accessed: 2026-08-11
Quote: "generating currently undetected faults that are specific to an issue of concern"

**meta-ach-blog**
URL: https://engineering.fb.com/2025/09/30/security/llms-are-the-key-to-mutation-testing-and-better-compliance/
Accessed: 2026-08-11
Quote: "generate both problem-specific mutants and the tests that can catch them"

**jest-cli**
URL: https://jestjs.io/docs/cli
Accessed: 2026-08-11
Quote: "Find and run the tests that cover"

**pdpp-mutation-oracle**
URL: file:///home/tnunamak/code/pdpp/scripts/test-migration/mutation-oracle.ts
Accessed: 2026-08-11

**pdpp-falsifiability**
URL: file:///home/tnunamak/code/pdpp/reference-implementation/test/consent-device-auth-conformance-falsifiability.test.ts
Accessed: 2026-08-11

**pdpp-groupme-frontier**
URL: file:///home/tnunamak/code/pdpp/packages/polyfill-connectors/connectors/groupme/incremental-frontier.test.ts
Accessed: 2026-08-11

**pdpp-test-accounting**
URL: file:///home/tnunamak/code/pdpp/test-accounting.manifest.json
Accessed: 2026-08-11

**pdpp-existing-corpus**
URL: file:///home/tnunamak/code/dotfiles/ai/research/testing/mutation-testing-should-be-sampled-diff-aware-risk-specific-feedback-not-a-global-adequacy-gate.md
Accessed: 2026-08-11

URL: file:///home/tnunamak/code/dotfiles/ai/research/testing/strykerjs-is-viable-for-pdpp-only-as-a-narrow-pilot-because-node-test-plus-tsx-loses-runner-intelligence.md
Accessed: 2026-08-11

## SYNTHESIS

The platonic target is not "install Stryker and raise mutation score." It is a falsification service for AI-authored software. Its job is to answer a narrower and stronger question for consequential changes: "Which plausible faults, tied to the changed code or declared risk, would still escape our tests, and what evidence proves the answer?"

Terminal ideal:

1. Risk input. The service accepts changed lines, historical bug classes, manifest/contract invariants, security/privacy/compliance concerns, and human plain-text risk prompts.
2. Mutant planning. It generates a small portfolio of mutants: conventional operator mutants, domain-specific mutants, historical-fault analogues, and LLM-generated problem-specific mutants. Selection is sampled and diff-aware by default, but can also target hotspots independent of the current diff.
3. Mutant filtering. It suppresses uncovered, arid, generated, compile-invalid, subsumed, low-interest, and likely-equivalent mutants before spending reviewer attention. Equivalent-mutant detection is advisory unless backed by deterministic proof.
4. Test-impact routing. It maps each mutant to a minimal candidate test set using coverage, import graph, manifest/test-accounting authority, historical kill data, and declared integration boundaries. It periodically runs a full backstop to measure miss rate.
5. Execution. It runs mutants in isolated workers with budgeted concurrency, deterministic environment receipts, timeouts, cache keys, and persisted artifacts.
6. Agent loop. An agent must either add or strengthen a test that kills the relevant mutant, classify the mutant as equivalent/uninteresting with evidence, or record a real gap. The system checks the claim by rerunning the mutant, not by trusting the agent.
7. Evidence model. Each packet records original diff, mutant diff, risk source, operator/generator, selected tests, result class, runtime, logs, coverage relation, triage decision, author/agent provenance, commit SHA, and whether a full-suite backstop later confirmed the selected-test result.
8. Feedback learning. The service learns which operators, prompt templates, code regions, and test selectors yield productive mutants. It optimizes for productive falsification per reviewer-minute and per compute-minute, not global mutation percentage.
9. Governance. Security/privacy/authz/consent/data-loss mutants can fail closed once calibrated. Broad score drift, low-risk survivors, equivalent classifications, and experimental generators fail open with receipts.

Attainable PDPP target architecture:

- Keep `test-accounting.manifest.json` as the suite authority. Add a mutation manifest beside it only when ready, with explicit targets, risk classes, budgets, owners, and admissible test selectors.
- Start with a `mutation-packet` JSON schema rather than a dashboard. PDPP already likes receipts and manifests; mutation evidence should be first-class, reviewable data.
- Use StrykerJS only as one execution adapter for conventional TS mutants. Do not let its runner model define the architecture. PDPP's stronger near-term primitives are bespoke risk mutators for connector coverage, cursor/checkpoint behavior, projection/authz leakage, manifest honesty, receipt laundering, and conformance harness soundness.
- Build a small selector layer over existing accounting suites: changed file -> owned package tests; domain tag -> conformance suite; risky unknown -> full relevant package. Measure selector miss rate with periodic full package runs.
- Add LLM-assisted mutant generation only after packets exist. The LLM should propose domain mutants from a risk prompt or prior bug, but deterministic code/test execution must judge the result.
- Store historical results so later agents can see whether a surviving mutant later coupled to a real bug, whether a supposedly equivalent mutant was wrong, and which test additions actually killed unique faults.

Smallest falsification pilot:

1. Pick one narrow domain where PDPP already has a hand-built oracle: test-migration mutation oracle, consent/device-auth conformance falsifiability, or GroupMe cursor/frontier behavior.
2. Convert the existing bespoke result into a durable mutation packet: named mutation, risk class, selected tests, expected kill, observed kill, rollback/cleanup proof, and triage status.
3. Add two or three new domain-specific mutants by hand, not a framework: e.g. drop terminal-state enforcement, add a page-count ceiling, invert coverage completeness, or allow projection of an undeclared field.
4. Run only the focused tests plus one backstop package suite in shadow.
5. Report zero score. Report counts of relevant killed mutants, relevant survivors, equivalent/uninteresting classifications, runtime, and one concrete test gap if found.

Metrics:

- Productive mutant rate.
- Relevant survivor count.
- Time to triage.
- Selected-test miss rate versus full backstop.
- Unique mutant kills per added/changed test.
- Historical fault coupling observed later.
- Equivalent/uninteresting classification reversal rate.
- Compute minutes per useful finding.
- Agent correction rate: how often an AI-authored test initially fails to kill its target mutant and needs revision.

Anti-metrics:

- Global mutation score.
- 100% adequacy.
- Mutants generated.
- Tests added.
- Coverage increase alone.
- Surviving mutants closed without evidence.
- LLM judge confidence without execution.
- CI minutes spent without productive findings.

Confidence:

High: the terminal shape is a falsification service, not a runner; Google and Meta both point away from exhaustive adequacy and toward selected, useful, risk-specific mutants. High: PDPP's current bespoke mutation/falsifiability checks are aligned with the ideal's evidence philosophy. Medium: Stryker should be an adapter, not the center, because no local runtime spike has measured its usefulness under PDPP's `node:test` plus `tsx` setup. Low/unknown: the best selector for PDPP's real dependency graph, the likely equivalent-mutant rate for PDPP-specific mutants, and the runtime budget needed for useful signal.
