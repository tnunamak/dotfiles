---
title: "StrykerJS is viable for PDPP only as a narrow pilot because node:test plus tsx loses runner intelligence"
date: 2026-08-11
topic: testing
tags: [mutation-testing, strykerjs, node-test, typescript, pnpm, vitest]
status: draft
sources: [pdpp-package-root, pdpp-workspace, pdpp-polyfill-connectors, pdpp-reference-implementation, pdpp-console, stryker-nodejs, stryker-configuration, stryker-incremental, stryker-typescript-checker, stryker-vitest, stryker-disable-mutants, stryker-mutators, stryker-node-test-issue]
source_session: unknown
---

## CLAIMS

- PDPP is a pnpm workspace containing `apps/*`, `packages/*`, and `reference-implementation`. [pdpp-workspace]
- PDPP root scripts and dev dependencies use Node, TypeScript, `tsx`, and pnpm; no root Vitest or Jest dependency is declared. [pdpp-package-root]
- PDPP's package test scripts primarily use Node's built-in test runner with `--import tsx`; examples include package-level tests, console view-model tests, and reference-implementation tests. [pdpp-package-root] [pdpp-polyfill-connectors] [pdpp-reference-implementation] [pdpp-console]
- StrykerJS documents NodeJS project support through supported runner plugins or the command test runner. [stryker-nodejs]
- StrykerJS documents ahead-of-time and just-in-time transpilation as supported, but says just-in-time transpilation with tools such as `tsx` is not recommended during mutation testing because it can run the compiler many times; compiling once is preferred. [stryker-nodejs]
- Stryker's `buildCommand` runs after mutation and before testing, and is intended for transpiling, bundling, or other build steps when the runner does not handle compilation. [stryker-configuration]
- Stryker's default temp directory is `.stryker-tmp` inside the current working directory, and `cleanTempDir` controls whether it is deleted. [stryker-configuration]
- Stryker's default worker concurrency is all logical CPU cores for machines with four or fewer cores, otherwise core count minus one; a numeric value or percentage string can override it. [stryker-configuration]
- Stryker's `mutate` option selects production files to mutate and supports line and column ranges for focused runs. [stryker-configuration]
- Stryker's mutator configuration can exclude named mutation operators through `mutator.excludedMutations`. [stryker-configuration]
- StrykerJS incremental mode stores prior results in `reports/stryker-incremental.json`, reuses compatible results, and still performs a dry run. [stryker-incremental]
- StrykerJS incremental mode does not detect changes outside mutated files and test files, does not detect environment, dependency, snapshot, or README changes, and static mutants have no test coverage for detecting test changes. [stryker-incremental]
- StrykerJS incremental test-change precision depends on the runner: Jest and CucumberJS report full test locations; Mocha, Tap, and Vitest report tests per file without location; command runner reports no test details. [stryker-incremental]
- StrykerJS supports forcing reruns with `--force` and can combine `--incremental`, `--force`, and a focused `--mutate` file or range. [stryker-incremental]
- The Stryker TypeScript checker plugin type-checks mutants, marks invalid mutants as `CompileError`, runs in memory, and supports single TypeScript projects and project references. [stryker-typescript-checker]
- The Stryker TypeScript checker automatically enables build mode when project references are present and overrides `allowUnreachableCode`, `noUnusedLocals`, and `noUnusedParameters` to reduce false positives. [stryker-typescript-checker]
- The TypeScript checker defaults `prioritizePerformanceOverAccuracy` to `true`, which is faster but can leave some mutants with a status other than `CompileError` when they should be compile errors; setting it to `false` is more accurate and slower. [stryker-typescript-checker]
- Stryker's Vitest runner exists since Stryker v7, requires the project to provide its own Vitest dependency, accepts `configFile`, `dir`, and `related` options, and defaults `vitest.related` to true. [stryker-vitest]
- Stryker's Vitest runner says `vitest.related: true` uses Vitest related-test selection and should be disabled when tests do not directly import source files, such as tests that call server code through API calls. [stryker-vitest]
- Stryker's Vitest runner sets non-overridable Vitest options including `singleThread: true`, `watch: false`, `coverage.enabled: false`, and `bail` behavior; it uses Stryker's own workers and coverage analysis. [stryker-vitest]
- Stryker's Vitest runner limitations include no Browser Mode support, only `threads: true` support, and ignoring the `coverageAnalysis` property because it always uses `perTest`. [stryker-vitest]
- StrykerJS can disable mutants by excluding a mutator, using `// Stryker disable` comments with optional reasons, or using an ignore plugin; ignored mutants remain visible but do not affect the mutation score. [stryker-disable-mutants]
- StrykerJS supports JavaScript/TypeScript mutation operators including arithmetic, array declaration, block statement, boolean literal, conditional expression, equality operator, logical operator, method expression, object literal, optional chaining, regex, string literal, unary operator, and update operator mutations. [stryker-mutators]
- An open StrykerJS issue requests native Node test runner support with proper `perTest` coverage; it describes command/tap workarounds failing for a TypeScript project. [stryker-node-test-issue]

## SOURCES

**pdpp-package-root**
URL: file:///home/tnunamak/code/pdpp/package.json
Accessed: 2026-08-11

**pdpp-workspace**
URL: file:///home/tnunamak/code/pdpp/pnpm-workspace.yaml
Accessed: 2026-08-11

**pdpp-polyfill-connectors**
URL: file:///home/tnunamak/code/pdpp/packages/polyfill-connectors/package.json
Accessed: 2026-08-11

**pdpp-reference-implementation**
URL: file:///home/tnunamak/code/pdpp/reference-implementation/package.json
Accessed: 2026-08-11

**pdpp-console**
URL: file:///home/tnunamak/code/pdpp/apps/console/package.json
Accessed: 2026-08-11

**stryker-nodejs**
URL: https://stryker-mutator.io/docs/stryker-js/guides/nodejs/
Accessed: 2026-08-11

**stryker-configuration**
URL: https://stryker-mutator.io/docs/stryker-js/configuration/
Accessed: 2026-08-11

**stryker-incremental**
URL: https://stryker-mutator.io/docs/stryker-js/incremental/
Accessed: 2026-08-11

**stryker-typescript-checker**
URL: https://stryker-mutator.io/docs/stryker-js/typescript-checker/
Accessed: 2026-08-11

**stryker-vitest**
URL: https://stryker-mutator.io/docs/stryker-js/vitest-runner/
Accessed: 2026-08-11

**stryker-disable-mutants**
URL: https://stryker-mutator.io/docs/stryker-js/disable-mutants/
Accessed: 2026-08-11

**stryker-mutators**
URL: https://stryker-mutator.io/docs/mutation-testing-elements/supported-mutators/
Accessed: 2026-08-11

**stryker-node-test-issue**
URL: https://github.com/stryker-mutator/stryker-js/issues/5421
Accessed: 2026-08-11

## SYNTHESIS

StrykerJS is the right mutation-testing candidate for PDPP's TypeScript/Node stack, but PDPP's current `node:test` plus `tsx` workflow is not Stryker's strongest integration path. The generic command runner should work as a compatibility pilot, but it gives up the runner intelligence that makes mutation testing practical at scale: no per-test reporting, weak incremental reuse when tests change, and no first-class `node:test` plugin behavior.

The first pilot should therefore be narrow and diagnostic, not a CI gate. Pick one fast, mostly pure hotspot package or module, run Stryker through the command runner, capture survived/no-coverage mutants, and measure runtime, false-positive/equivalent-mutant rate, and setup friction before changing the repo's test runner strategy.

Conservative pilot shape:

```js
export default {
  packageManager: "pnpm",
  testRunner: "command",
  commandRunner: {
    command: "pnpm --dir packages/polyfill-connectors test"
  },
  mutate: [
    "packages/polyfill-connectors/src/**/*.ts",
    "!**/*.test.ts"
  ],
  reporters: ["clear-text", "json", "html"],
  thresholds: { high: 0, low: 0, break: 0 },
  concurrency: "50%",
  timeoutMS: 120000,
  incremental: true
};
```

If this pilot finds enough signal, the next performance path is not global command-runner mutation; it is creating a small Vitest-backed island for selected pure unit targets, or compiling those targets ahead of time and running Stryker against emitted JavaScript. Vitest gives Stryker `perTest` coverage and better incremental behavior, but `vitest.related` should default to false for PDPP unless a target's tests directly import the mutated source. Many PDPP tests exercise behavior through server/API/runtime paths, where import-graph-related selection can silently miss relevant tests.

The TypeScript checker should be added only after the first compatibility smoke. It can filter type-invalid mutants, but its default performance-over-accuracy mode can misclassify some compile-error mutants, and its accurate mode may be much slower. Treat checker configuration as part of the measurement, not as an assumed default.

Do not gate PRs on mutation score at first. Use Stryker output as an evidence packet for agents and reviewers: each relevant survivor should either be killed by a better oracle, classified as equivalent/uninteresting with a reason, or recorded as a real test gap. Keep thresholds at zero in shadow mode until runtime and triage quality are known.
