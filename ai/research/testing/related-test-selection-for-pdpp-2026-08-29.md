---
title: "As of August 2026, Jest, Vitest, and Playwright all ship changed/related-test selection built on static import-graph analysis that explicitly excludes dynamic imports, node:test has no native equivalent (the 2022 feature request is stale), and PDPP's polyfill-connectors package has confirmed fixture-driven and dynamic-import test coupling that any static-graph selector would miss"
date: 2026-08-29
topic: testing
tags: [test-impact-analysis, related-tests, jest, vitest, playwright, node-test, tsx, module-graph, madge, dependency-cruiser, esbuild-metafile, fine-grained-invalidation, pdpp, polyfill-connectors]
status: draft
sources: [jest-cli-docs, vitest-cli-docs, vitest-related-command, playwright-only-changed-issue-34339, playwright-only-changed-dev-post, node-findrelatedtests-issue-42992, madge-npm, dependency-cruiser-npm, esbuild-dependency-graph-npm, pdpp-polyfill-connectors-package-json, stryker-corpus-entry, fine-grained-invalidation-corpus-entry, tia-playbook-entry]
source_session: unknown
---

<!--
Companion / do-not-duplicate map:
- testing/strykerjs-is-viable-for-pdpp-only-as-a-narrow-pilot-because-node-test-plus-tsx-loses-runner-intelligence.md
  already establishes: node:test + tsx loses per-test location/coverage reporting relative to Jest/CucumberJS,
  which is what makes Stryker's incremental mode weak on this stack. THIS entry does not re-derive that; it
  applies the same underlying fact (node:test has no first-class "which test covers which source line" API)
  to a different question: not mutation-testing incrementality, but changed-file -> related-test selection.
- distributed-systems/fine-grained-invalidation-tracks-which-inputs-a-derived-value-actually-read-generation-fences-cannot.md
  already establishes the general theory (Salsa/Bazel-Skyframe: dependency tracking answers "is THIS specific
  derived value stale" with zero false positives BY CONSTRUCTION against a computation's ACTUAL read-set,
  vs. a coarse checkpoint that only answers "could anything be stale"). THIS entry applies that theory,
  unmodified, to test selection, and adds the one thing that entry's domain (Salsa/Bazel) does not have:
  a read-set that is *itself* only partially observable (dynamic imports, fixture path reads) even when the
  tool claims to do "dependency tracking" — see SYNTHESIS.
- agentic-cli-design/pdpp-working-smarter-playbook.md already frames TIA as "the mechanical version of
  cheap-probe-before-heavy-work" and names its known failure mode (dynamic/reflective code paths, incomplete
  dependency maps silently under-test) via CloudBees/gauge.sh. THIS entry is the concrete tool-level
  verification of that abstract failure mode for PDPP's actual stack, done via live web search, not recall.
-->

## CLAIMS

### PDPP's current state (verified against the repo, 2026-08-29)

- `packages/polyfill-connectors/package.json` runs tests via `node --test --import tsx --test-concurrency=2 --test-timeout=120000 "bin/**/*.test.ts" "connectors/**/*.test.ts" "src/**/*.test.ts"` — plain Node built-in test runner with `tsx` for on-the-fly TypeScript transpilation, no Jest, no Vitest, no bundler. [pdpp-polyfill-connectors-package-json]
- `find packages/polyfill-connectors -name "*.test.ts" | wc -l` returns 316 test files; `find packages/polyfill-connectors -name "*.ts" | wc -l` returns 608 total TypeScript files. [pdpp-polyfill-connectors-package-json]
- `grep -rhoE "^\s*(test|it)\(" packages/polyfill-connectors --include="*.test.ts" | wc -l` returns 4,146 top-level `test(`/`it(` call sites — close to, but distinct from, the task's stated "4,713 tests" figure; the difference is consistent with nested `describe`/`it` subtests or `t.test()` subtests not captured by a flat top-level grep. **The 4,713 figure is a test-case/assertion count, not a file count** — the file count (316) is the unit any changed-file-based selector would actually operate on. [pdpp-polyfill-connectors-package-json]
- Tests are colocated with source (`*.test.ts` files sit next to their corresponding `*.ts` implementation files inside `src/`, and per-connector inside `connectors/<name>/`), not segregated into a separate test tree. [pdpp-polyfill-connectors-package-json]
- 14 files under `packages/polyfill-connectors` reference a `fixtures/` path, and 71 files call `readFileSync`; separately, 51 call sites outside `*.test.ts` files use `await import(` or `require(`. This confirms, for this specific package, that both the fixture-file-read blind spot and the dynamic-import blind spot (see below) are live risks, not hypothetical ones. [pdpp-polyfill-connectors-package-json]

### Jest: `--findRelatedTests`, `--changedSince`, `--onlyChanged` (verified against jestjs.io/docs/cli, Jest 30.5)

- `--findRelatedTests <spaceSeparatedListOfSourceFiles>`: "Find and run the tests that cover a space separated list of source files that were passed in as arguments. Useful for pre-commit hook integration to run the minimal amount of tests necessary. Can be used together with `--coverage` to include a test coverage for the source files, no duplicate `--collectCoverageFrom` arguments needed." [jest-cli-docs]
- `--changedSince`: "Runs tests related to the changes since the provided branch or commit hash. If the current branch has diverged from the given branch, then only changes made locally will be tested. Behaves similarly to `--onlyChanged`." [jest-cli-docs]
- `--onlyChanged` (alias `-o`): "Attempts to identify which tests to run based on which files have changed in the current repository. Only works if you're running tests in a git/hg repository at the moment and **requires a static dependency graph (ie. no dynamic requires)**." [jest-cli-docs]
- All three flags require Jest itself as the runner; PDPP's polyfill-connectors package has no Jest dependency (per the companion Stryker corpus entry, which already established the pdpp root has no root Vitest/Jest dependency declared). [jest-cli-docs] [stryker-corpus-entry]

### Vitest: `--changed` and the `related` selection mode (verified against vitest.dev/guide/cli and main.vitest.dev/config/changed)

- `--changed` runs tests only against files that have changed; with no value it diffs uncommitted (staged + unstaged) changes, or accepts a ref (`--changed HEAD~1`, a commit hash, or a branch name like `--changed origin/develop`). [vitest-cli-docs]
- `--changed` can be paired with `forceRerunTriggers`: if any file in that list changes, Vitest reruns the whole suite; changes to the Vitest config file and `package.json` always force a full rerun by default. [vitest-cli-docs]
- The `related` selection mode "runs only tests that cover specific source files: it runs only tests that cover a list of source files. **Works with static imports (e.g., `import('./index.js')` or `import index from './index.js`), but not the dynamic ones.**" [vitest-related-command]
- Vitest's programmatic API exposes `getRelevantTestSpecifications`, which filters a test list to only files affected by `--changed`, but does not itself execute tests and is documented as potentially slow. [vitest-cli-docs]
- Vitest is a Vite-based runner requiring its own dependency and execution model; PDPP's polyfill-connectors currently has zero Vitest dependency and 316 files written against `node:test`'s API (`test()`, `describe()`, `t.test()`, assertion style via `node:assert`), not Vitest's `expect`-based API. [vitest-cli-docs] [pdpp-polyfill-connectors-package-json]

### Playwright: `--only-changed` (verified against GitHub issues #34339, #32070, #32561 and the official dev.to announcement post; shipped in Playwright v1.46)

- `--only-changed`, added in Playwright Test v1.46, runs test files changed since the last commit (or a specified git ref) plus every test file that imports any changed file, by analyzing the suite's dependency graph. [playwright-only-changed-dev-post]
- A filed and still-open bug (#34339, reported by a user named Vadim Nechaev) states verbatim: **"Imagine you have a fixture for logging or adding some annotation per each test. Thus, all the tests are executed with the flag `--only-changed`."** The reporter's own assessment: "It could be a feature if the Test Automation Framework is quite new and small, but if you have dozens of tests, it takes hours to get it done." Their workaround is a hand-rolled bash script parsing `git diff` directly instead of trusting `--only-changed`. [playwright-only-changed-issue-34339]
- This is the exact mechanism this corpus predicted from the fine-grained-invalidation theory: a shared fixture/base file sits at the root of nearly every test's dependency chain, so any edit to it is (correctly, by the graph) seen as touching every test — the tool is not wrong, but the resulting selection degenerates to "run everything," which is the same output as no selection at all. [playwright-only-changed-issue-34339] [fine-grained-invalidation-corpus-entry]
- Separately filed issues document `--only-changed` interacting badly with Playwright's `project` dependency feature (#32070) and a standing feature request to add a mode that only compares test files themselves, ignoring their imported dependencies (#32561) — i.e. users are actively requesting the coarser, cheaper mode because the fine-grained one is too conservative in fixture-heavy suites. [playwright-only-changed-issue-34339]
- Playwright is not applicable to PDPP's polyfill-connectors package regardless of this behavior: it is an end-to-end browser-test runner, not a unit-test runner for `node:test`-based source-level tests.

### node:test native selection (verified against nodejs/node GitHub issues, 2026-08-29)

- A feature request titled "`--findRelatedTests` for node:test" (nodejs/node issue #42992) exists, in which the author explicitly asks for the same capability as Jest's flag ("I use lintstaged to run only the unit tests related to changed source files on each commit. I currently use jest with their CLI flag: `--findRelatedTests`... Could something similar be added to node:test?"). [node-findrelatedtests-issue-42992]
- As of this search (2026-08-29), issue #42992 is unimplemented and carries a "stale" label; no shipped `node:test` flag or documented Node.js roadmap item provides changed-file or related-test selection. [node-findrelatedtests-issue-42992]
- This directly confirms and extends the companion Stryker corpus entry's "runner intelligence" gap: node:test lacks not only per-test coverage reporting (the Stryker finding) but also any native module-graph-aware test selection (this entry's finding) — both stem from the same root cause, that node:test intentionally ships as a minimal, dependency-free test harness rather than a build-graph-aware tool like Jest or Vitest. [node-findrelatedtests-issue-42992] [stryker-corpus-entry]

### Static import-graph scripting tools (verified against npm registry, 2026-08-29)

- `madge` (pahen/madge): latest published version 8.0.0, published roughly 2 years before this search (i.e., circa 2024); described by its own maintainer as worked on "in free time"; still has meaningful reverse-dependents (264 packages) but shows no recent release activity. Builds a module dependency graph for CommonJS/AMD/ES6 and can report dependents of a given file, which is the primitive a "changed file -> transitive importers -> test files" script needs. [madge-npm]
- `dependency-cruiser` (sverweij/dependency-cruiser): latest version 18.2.0 as of this search, with a release (18.1.1) as recently as 2026-08-02 and a repository push on 2026-08-08 — actively maintained, "Healthy" maintenance signal, 2.6M+ weekly downloads, requires Node 22/24/26+, ESM-first with a promise-based API. This is materially more current than madge for a 2026 scripting choice. [dependency-cruiser-npm]
- `esbuild-dependency-graph` (community package layered on esbuild's `--metafile` output) exposes `dependenciesOf`, `dependentsOf`, and `inverseDependenciesOf` methods against an esbuild metafile, and supports incremental registration/update/removal of modules in the graph — usable for a custom selector if PDPP were willing to run an esbuild build step (with `metafile: true`) purely to harvest the dependency graph, without using esbuild as the actual test transpiler. [esbuild-dependency-graph-npm]
- None of these three tools (madge, dependency-cruiser, esbuild-metafile-based graphs) claim to resolve dynamic `import()` calls, `require()` with computed paths, or non-import file reads (`fs.readFileSync` of a fixture) into their dependency graphs — all three are static-AST or static-bundler graphs by construction, the same category of tool as Vitest's `related` command and Jest's `--onlyChanged`, and inherit the identical blind spot documented above for those tools.

## SOURCES

**jest-cli-docs**
URL: https://jestjs.io/docs/cli
Accessed: 2026-08-29
Quote: "Attempts to identify which tests to run based on which files have changed in the current repository. Only works if you're running tests in a git/hg repository at the moment and requires a static dependency graph (ie. no dynamic requires)." (documented against Jest 30.5)

**vitest-cli-docs**
URL: https://vitest.dev/guide/cli ; https://main.vitest.dev/config/changed
Accessed: 2026-08-29
Quote: "This runs tests only against changed files. If no value is provided, it will run tests against uncommitted changes (staged and unstaged)."

**vitest-related-command**
URL: https://vitest.dev/guide/cli
Accessed: 2026-08-29
Quote: "Works with static imports (e.g., `import('./index.js')` or `import index from './index.js`), but not the dynamic ones."

**playwright-only-changed-dev-post**
URL: https://dev.to/playwright/iterate-quickly-using-the-new-only-changed-option-55m2
Accessed: 2026-08-29
Quote: "To detect test files affected by your changeset, --only-changed analyses your suites' dependency graph." (feature shipped in Playwright v1.46)

**playwright-only-changed-issue-34339**
URL: https://github.com/microsoft/playwright/issues/34339
Accessed: 2026-08-29
Quote: "Imagine you have a fixture for logging or adding some annotation per each test. Thus, all the tests are executed with the flag --only-changed."

**node-findrelatedtests-issue-42992**
URL: https://github.com/nodejs/node/issues/42992
Accessed: 2026-08-29
Quote: "I use lintstaged to run only the unit tests related to changed source files on each commit. I currently use jest with their CLI flag: --findRelatedTests... Could something similar be added to node:test?" (issue open, stale-labeled, unimplemented as of access date)

**madge-npm**
URL: https://www.npmjs.com/package/madge
Accessed: 2026-08-29
Quote: "latest version is 8.0.0, last published 2 years ago"

**dependency-cruiser-npm**
URL: https://www.npmjs.com/package/dependency-cruiser
Accessed: 2026-08-29
Quote: "Current version: 18.2.0 ... Version 18.1.1 was published on August 2, 2026, the repository was pushed on August 8, 2026"

**esbuild-dependency-graph-npm**
URL: https://socket.dev/npm/package/esbuild-dependency-graph
Accessed: 2026-08-29

**pdpp-polyfill-connectors-package-json**
URL: file:///home/tnunamak/code/pdpp/packages/polyfill-connectors/package.json
Accessed: 2026-08-29

**stryker-corpus-entry**
URL: file:///home/tnunamak/code/dotfiles/ai/research/testing/strykerjs-is-viable-for-pdpp-only-as-a-narrow-pilot-because-node-test-plus-tsx-loses-runner-intelligence.md
Accessed: 2026-08-29

**fine-grained-invalidation-corpus-entry**
URL: file:///home/tnunamak/code/dotfiles/ai/research/distributed-systems/fine-grained-invalidation-tracks-which-inputs-a-derived-value-actually-read-generation-fences-cannot.md
Accessed: 2026-08-29

**tia-playbook-entry**
URL: file:///home/tnunamak/code/dotfiles/ai/research/agentic-cli-design/pdpp-working-smarter-playbook.md
Accessed: 2026-08-29
Quote: "The known failure mode of TIA — dynamic/reflective code paths and incomplete dependency maps silently under-test — is the same failure class the steering audit found in 'evidence exists' checks: a cheap probe is only trustworthy if its coverage claim is itself verified, not assumed."

## SYNTHESIS

### Framing: which option does fine-grained invalidation, and which does a generation fence

The companion fine-grained-invalidation entry draws one hard line: a dependency-tracked system (Salsa, Bazel/Skyframe) achieves zero false positives *by construction*, because its recorded dependency edges are exactly the edges a computation *actually read* during execution. Every tool surveyed here — Jest's `--onlyChanged`, Vitest's `related`, Playwright's `--only-changed`, and any madge/dependency-cruiser/esbuild-metafile script — claims to be doing that, but is not, in the strict sense. All of them build a **static** import graph (parsed from `import`/`require` syntax, or a bundler's resolved graph) rather than an **execution-observed** read-set. Jest's own docs concede this outright ("requires a static dependency graph, ie. no dynamic requires"); Vitest's docs concede it in the same sentence they advertise the feature ("works with static imports... but not the dynamic ones"); Playwright's open bug #34339 is a live demonstration of the failure this causes in a fixture-heavy suite. **None of these tools is Salsa or Skyframe.** They are all, at best, a *better-than-nothing static approximation* of fine-grained invalidation — closer to it than a coarse "run everything" fence, but still capable of both false negatives (a test that reads a fixture via `readFileSync` and is never linked to the fixture in the graph) and, per Playwright's bug, degenerate false-positive collapse back to "run everything" when a shared file sits upstream of most tests.

For PDPP's polyfill-connectors specifically, this is not a theoretical concern: the repo scan found 14 files referencing `fixtures/`, 71 calling `readFileSync`, and 51 non-test call sites using dynamic `import()`/`require()`. Any static-graph selector applied to this package will silently under-select for at least some fraction of these files, exactly the failure mode the TIA playbook entry already named ("a cheap probe is only trustworthy if its coverage claim is itself verified, not assumed").

### Option A: thin selection script (madge/dependency-cruiser/esbuild-metafile + custom mapping to node:test)

- **Capability**: Can compute "changed file → transitive importers → test files that import a transitive importer" without changing the test runner. `dependency-cruiser` (actively maintained, 18.2.0, Aug 2026 release) is the better primitive than `madge` (stale since ~2024) for this in 2026. Output feeds directly into `node --test <matched-file-list>`, which already accepts an explicit file list.
- **Risk**: Inherits the full static-graph blind spot described above — the confirmed fixture/dynamic-import surface in this exact package means a naive version of this script will under-select. It is also new, unproven code PDPP would own and maintain, with no upstream fixing its edge cases (unlike Jest/Vitest, where the blind spot is at least documented and stable). A safe version requires an explicit conservative fallback: treat any change under a `fixtures/` directory, or any file that is `require()`'d/`import()`'d dynamically anywhere, as "always run full suite" rather than attempting to resolve those edges — i.e., encode the theory's own remediation (from the fine-grained-invalidation entry: "diff the manifest edit... and record which sections actually changed," generalized here to "classify each changed file as staticaly-resolvable or not, and fully fence on the latter").
- **Migration cost**: Low-to-moderate. No change to the 316 existing test files or the `node:test` runner; the script is additive tooling (a pre-CI or pre-commit step that narrows the file glob passed to the existing `node --test` invocation). Estimated as a single-file script plus a conservative-fallback allowlist, testable in isolation before it gates anything.
- **Confidence**: Medium. The primitive (dependency-cruiser's dependents-of query) is well-documented and actively maintained; the risk is entirely in whether PDPP builds and maintains the conservative fallback correctly, which is a judgment call, not a library gap.

### Option B: Vitest island (migrate polyfill-connectors, or a subset, to Vitest for native `related`/`--changed`)

- **Capability**: Gets a maintained, upstream-supported implementation of the same static-graph selection (Option A's capability) without PDPP owning the graph-walking code, plus Vitest's broader ecosystem (watch mode, coverage-aware related-test computation via `getRelevantTestSpecifications`).
- **Risk**: Same static-graph blind spot as Option A and as documented in Vitest's own docs — migrating to Vitest does not solve the fixture/dynamic-import problem, it only moves who maintains the (still-incomplete) graph-walking code from PDPP to the Vitest project. `forceRerunTriggers` is Vitest's own built-in escape hatch for exactly this case (config/package.json changes always force full reruns, and the option is user-extensible), so the same conservative-fallback list from Option A would still need to be authored, just placed in Vitest config instead of a custom script.
- **Migration cost**: High, and this is the point most likely to be underweighted. All 316 test files in polyfill-connectors are written against `node:test`'s API (`test()`, `describe()`, `node:assert`-based assertions per the package.json test script), not Vitest's `expect`/`vi` API. This is a full runner migration for the entire package — not a config toggle — including verifying that `tsx`-based fixtures, patchright/Playwright-driven connector tests, and the existing `--test-concurrency=2`/`--test-timeout=120000` tuning all have Vitest equivalents that behave the same way under load. The companion Stryker entry already flagged that PDPP's root has zero Vitest dependency declared; this would be a net-new, package-wide dependency and idiom shift with 316 files to touch or dual-support during transition.
- **Confidence**: Medium-high on capability (Vitest's `related`/`--changed` are mature, documented features), low confidence that the migration cost is worth it given Option A gets ~80% of the same capability without touching any of the 316 existing test files.

### Option C: status quo (run the full 316-file / ~4,146–4,713-test-case suite every time)

- **Capability**: None — this is the coarse generation-fence equivalent by definition: it always answers "could anything be stale" with "yes, everything," which has zero false negatives (nothing is ever wrongly skipped) at the cost of zero selectivity.
- **Risk**: The only risk is cost/latency, not correctness — this is the safe default the fine-grained-invalidation entry itself endorses for the "could be stale" question when precision isn't needed. Given `--test-concurrency=2` is already conservative (likely tuned for resource-constrained CI or flake avoidance around Playwright/patchright-driven connector tests), the real lever available today without new tooling is raising concurrency or sharding by directory in CI, not selection.
- **Migration cost**: Zero.
- **Confidence**: High — this is already what PDPP does today and is well understood.

### Recommendation

Do not pursue Option B. The migration cost (316 files off a `node:test`-native API onto Vitest, package-wide) is disproportionate to the marginal capability gained over Option A, since both options hit the identical static-graph ceiling documented across Jest/Vitest/Playwright's own docs and bug trackers — Vitest does not solve the fixture/dynamic-import blind spot, it just relocates who maintains the (still incomplete) graph code.

If test suite runtime becomes an actual bottleneck (evidence, not assumption — measure current full-suite wall-clock time first, per the TIA playbook's "a cheap probe is only trustworthy if its coverage claim is itself verified" standard), Option A is the right shape: a thin `dependency-cruiser`-backed script mapping changed files to their transitive test importers, gated by an explicit, conservative fallback list (any change under a `fixtures/` directory, or to any of the 51 dynamically-imported modules identified in this scan, forces a full-suite run rather than attempting static resolution). This gets most of the wall-clock benefit of related-test selection for local/pre-commit iteration while treating CI's merge-gate run as the full 316-file suite unconditionally — i.e., use selection as a fast local probe (per the "cheap probe before heavy work" doctrine already in the corpus), never as the actual correctness gate. Until the runtime problem is measured and shown to be real, Option C (status quo) remains the correct choice: it is the only option with zero risk of a silently-skipped test, which matters more for a personal-data connector suite than shaving a few minutes off a local test run.
