---
title: "Test-suite audits should optimize marginal behavioral and fault-detection value per cost, not test count, test LOC, or coverage percentage"
date: 2026-08-11
topic: code-quality
tags: [testing, mutation-testing, coverage, test-selection, flakiness, mocks, fixtures, ai-generated-code]
status: draft
sources: [google-coverage, swe-tests, swe-test-doubles, google-mutation-state, google-mutation-long-term, google-mutation-lessons, google-test-selection, vitest-selection, testgen-llm, meta-ach, minimization-harms]
source_session: unknown
---

## CLAIMS

- Coverage proves that code executed, not that behavior was checked or that assertions can detect faults; Google calls coverage an indirect and lossy metric and rejects a universal target. [google-coverage]
- Test size and test scope are separate dimensions. Small tests avoid I/O, sleeps, and network access; larger tests can supply confidence that doubles and component boundaries cannot. [swe-tests]
- Google recommends behavior-focused tests and deliberately permits some duplication when it keeps the scenario and oracle obvious; shared helpers should hide irrelevant construction, not the behavior under test. [swe-tests]
- Test doubles can encode the same mistaken dependency model as the implementation. Google prefers real implementations when practical, state testing over interaction testing, and larger tests that check double fidelity. [swe-test-doubles]
- Google's production mutation system is diff-based and sampled. It suppresses uncovered or arid lines and selects interesting mutants instead of mutating the entire repository. [google-mutation-state]
- A longitudinal Google study covering 15 million mutants found evidence that mutation-driven tests improve suites and that live mutants couple to historical faults. [google-mutation-long-term]
- Google's industrial follow-up says full mutation adequacy is neither practical nor desirable because equivalent, redundant, and uninteresting mutants consume compute and reviewer attention. [google-mutation-lessons]
- Google's transition-history study found plausible recent-history test-selection heuristics underperformed expectations and describes regression-test selection as an open problem requiring empirical miss-rate evaluation. [google-test-selection]
- Vitest's related/changed selection uses a static import graph and explicitly misses dynamic imports; non-imported runtime inputs require explicit trigger patterns. [vitest-selection]
- Meta's TestGen-LLM filters generated tests through build, reliable-pass, and coverage-increase gates before human review; in its reported deployment, 75% built, 57% passed reliably, and 25% increased coverage. [testgen-llm]
- Meta's Automated Compliance Hardening uses LLM-generated risk-specific mutants and accepts generated tests only after they kill those mutants. [meta-ach]
- Coverage-preserving test-suite minimization can materially reduce fault detection, so structural coverage or textual duplication alone does not license deletion. [minimization-harms]

## SOURCES

**google-coverage**
URL: https://testing.googleblog.com/2020/08/code-coverage-best-practices.html
Accessed: 2026-08-11

**swe-tests**
URL: https://abseil.io/resources/swe-book/html/ch11.html
Accessed: 2026-08-11

URL: https://abseil.io/resources/swe-book/html/ch12.html
Accessed: 2026-08-11

**swe-test-doubles**
URL: https://abseil.io/resources/swe-book/html/ch13.html
Accessed: 2026-08-11

URL: https://abseil.io/resources/swe-book/html/ch14.html
Accessed: 2026-08-11

**google-mutation-state**
URL: https://research.google/pubs/state-of-mutation-testing-at-google/
Accessed: 2026-08-11

**google-mutation-long-term**
URL: https://research.google/pubs/long-term-effects-of-mutation-testing/
Accessed: 2026-08-11

**google-mutation-lessons**
URL: https://research.google/pubs/an-industrial-application-of-mutation-testing-lessons-challenges-and-research-directions/
Accessed: 2026-08-11

**google-test-selection**
URL: https://research.google/pubs/assessing-transition-based-test-selection-algorithms-at-google/
Accessed: 2026-08-11

**vitest-selection**
URL: https://main.vitest.dev/guide/cli
Accessed: 2026-08-11

URL: https://main.vitest.dev/guide/recipes/watch-templates.html
Accessed: 2026-08-11

**testgen-llm**
URL: https://arxiv.org/abs/2402.09171
Accessed: 2026-08-11

**meta-ach**
URL: https://engineering.fb.com/2025/02/05/security/revolutionizing-software-testing-llm-powered-bug-catchers-meta-ach/
Accessed: 2026-08-11

**minimization-harms**
URL: https://digitalcommons.unl.edu/csearticles/11/
Accessed: 2026-08-11

## SYNTHESIS

A useful test is evidence about an observable behavior, boundary, fault class, or operational risk that is not supplied more cheaply and reliably elsewhere. Audit marginal contribution, not surface area. Coverage locates unexecuted code; sampled mutation testing probes oracle sensitivity; runtime and flake measurements expose cost. None is a deletion oracle alone.

Delete or consolidate only after identifying the observable property preserved, checking that the candidate has no unique regression history, boundary role, relevant mutant kill, or dependency-truth source, and validating the removal in a small reversible experiment. Preserve intentional redundancy at security, privacy, data-loss, persistence, concurrency, and public-contract boundaries.

For AI-authored and AI-maintained code, implementation, tests, fixtures, and mocks can share one mistaken model. Raise confidence with an independent truth source: a pre-fix test that fails on the real defect, risk-specific mutation or fault injection, captured real-service fixtures with provenance, real-backend checks, deterministic tools, and a different-model reviewer.

Use two execution lanes until measured evidence supports stronger selection: a fast affected-test lane with explicit non-import inputs and a complete merge/nightly/release backstop. Measure selection miss rate, per-target runtime, setup cost, flakiness on identical revisions, and cache validity before reducing the backstop.
