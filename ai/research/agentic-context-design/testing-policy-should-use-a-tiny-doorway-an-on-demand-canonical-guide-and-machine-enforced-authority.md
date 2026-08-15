---
title: "Testing policy should use a tiny contributor and agent doorway, an on-demand canonical guide, and machine-enforced execution authority"
date: 2026-08-11
topic: agentic-context-design
tags: [testing-policy, agents-md, contributor-docs, test-manifest, context-engineering]
status: draft
sources: [rust-contributing, rust-testing, node-test-readme, node-writing-tests, django-test-readme, django-unit-tests, llvm-testing, git-testing, kubernetes-testing, kubernetes-test-infra, anthropic-memory, anthropic-context, devin-agents]
source_session: unknown
---

## CLAIMS

- Rust's short root `CONTRIBUTING.md` sends compiler and tooling contributors to the rustc development guide; that guide's testing hub classifies test kinds, exposes `./x test` as the common orchestrator, and links detailed running and authoring chapters. [rust-contributing, rust-testing]
- Node's `test/README.md` is a compact directory map that records each suite's purpose and CI status, then routes readers to a detailed test-writing guide and the pull-request testing step; the detailed guide owns authoring conventions, helpers, fixtures, anti-flake advice, naming, coverage, and runner guidance. [node-test-readme, node-writing-tests]
- Django's ten-line `tests/README.rst` contains setup, one runner command, and a link to its full contributor testing guide; the full guide owns test selection, optional backends, Selenium, dependencies, coverage, and CI behavior. [django-test-readme, django-unit-tests]
- LLVM calls its Testing Infrastructure Guide the reference manual for test organization, tools, authoring, and execution, while `lit` configuration and per-test directives encode discovery, platform constraints, expected failures, and commands; a test without a `RUN` directive is a runner error. [llvm-testing]
- Git keeps the comprehensive test manual beside its harness in `t/README`; the harness supports focused selection and stress runs and can enforce command failure propagation with `--chain-lint`. [git-testing]
- Kubernetes uses a central testing guide that links separate integration, end-to-end, flaky-test, and testing-strategy documents; executable Prow jobs and Testgrid configuration live separately with validation tests for that configuration. [kubernetes-testing, kubernetes-test-infra]
- Anthropic documents that project instruction files consume startup context, recommends keeping them concise and under 200 lines, and says multi-step or path-specific procedures should move to skills or scoped rules; imported files still enter startup context. [anthropic-memory]
- Anthropic's context-engineering guidance recommends the smallest high-signal token set because additional context consumes a finite attention budget and can reduce recall precision. [anthropic-context]
- Devin's AGENTS documentation says root `AGENTS.md` content is always on, subdirectory files apply conditionally by path, and nested files should avoid repeating inherited global instructions. [devin-agents]

## SOURCES

**rust-contributing**
URL: https://github.com/rust-lang/rust/blob/main/CONTRIBUTING.md
Accessed: 2026-08-11

**rust-testing**
URL: https://rustc-dev-guide.rust-lang.org/tests/intro.html
Accessed: 2026-08-11

**node-test-readme**
URL: https://github.com/nodejs/node/blob/main/test/README.md
Accessed: 2026-08-11

**node-writing-tests**
URL: https://github.com/nodejs/node/blob/main/doc/contributing/writing-tests.md
Accessed: 2026-08-11

**django-test-readme**
URL: https://github.com/django/django/blob/main/tests/README.rst
Accessed: 2026-08-11

**django-unit-tests**
URL: https://docs.djangoproject.com/en/dev/internals/contributing/writing-code/unit-tests/
Accessed: 2026-08-11

**llvm-testing**
URL: https://llvm.org/docs/TestingGuide.html
Accessed: 2026-08-11

**git-testing**
URL: https://github.com/git/git/blob/master/t/README
Accessed: 2026-08-11

**kubernetes-testing**
URL: https://github.com/kubernetes/community/blob/main/contributors/devel/sig-testing/testing.md
Accessed: 2026-08-11

**kubernetes-test-infra**
URL: https://github.com/kubernetes/test-infra/tree/master/config
Accessed: 2026-08-11

**anthropic-memory**
URL: https://code.claude.com/docs/en/memory
Accessed: 2026-08-11

**anthropic-context**
URL: https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
Accessed: 2026-08-11

**devin-agents**
URL: https://docs.devin.ai/desktop/cascade/agents-md
Accessed: 2026-08-11

## SYNTHESIS

Mature projects converge on three layers:

1. A tiny, highly discoverable doorway in `AGENTS.md`, `CONTRIBUTING.md`, or a test-directory README says when to consult the testing policy and where it lives.
2. One canonical, on-demand testing guide owns strategy, test-tier semantics, authoring policy, supported workflows, and links to subsystem exceptions.
3. Manifests, runner configuration, test directives, and CI own executable truth: discovery, suite membership, required profiles, constraints, skips, and merge gates.

This split avoids two failure modes. Duplicating detailed policy in always-on agent context consumes attention on unrelated work and increases drift. Leaving execution requirements only in prose makes them advisory and unverifiable. The doorway should therefore contain a trigger and a precise path, not a compressed copy of the policy. An eager `@` import is not on-demand retrieval because it still enters startup context.

For PDPP, put the canonical policy at `docs/reference/testing-strategy.md`, matching the repository's existing home for durable guides and contracts. Link it from `docs/README.md` and the testing section of `CONTRIBUTING.md`. Keep one root-agent instruction:

> For any test addition, deletion, consolidation, runner or fixture change, or testing-strategy decision, first read `docs/reference/testing-strategy.md`. Treat `test-accounting.manifest.json` and CI configuration as the execution and suite-accounting authority.

The canonical guide should own the risk model, test tiers and cadence, hermetic-versus-live policy, test-quality and deletion gates, coverage/mutation/flake semantics, and a concise command map. `test-accounting.manifest.json`, runners, and CI should own exhaustive membership, profiles, predicates, skip reasons, exact commands, and merge-required jobs. Generate any inventory table from the manifest instead of maintaining a prose copy. Use nested `AGENTS.md` files only for true subsystem-specific deltas.
