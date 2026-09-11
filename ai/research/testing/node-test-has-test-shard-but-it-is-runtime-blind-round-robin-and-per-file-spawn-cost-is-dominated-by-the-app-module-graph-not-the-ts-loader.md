---
title: "node:test does ship --test-shard (contradicting the common claim it lacks one) but its implementation is a runtime-blind index-modulo round robin that balances file counts not durations, mock.timers supports two APIs its own docs never mention, and per-file spawn cost in a large TS suite is dominated by the application module graph rather than by the TypeScript loader — so NODE_COMPILE_CACHE and a tsx-to-native-type-stripping swap are only worth adopting as a pair, and neither beat simply raising the file-concurrency cap"
date: 2026-09-09
topic: testing
tags: [node-test, test-shard, mock-timers, fake-timers, node-compile-cache, tsx, type-stripping, amaro, test-isolation, spawn-cost, sharding, github-actions, pdpp]
status: draft
sources: [node-cli-md, node-test-md, node-runner-src, node-mock-timers-src, node-module-md, tsx-npm, staffa-benchmark, ts-native-limits, sinon-fake-timers, circleci-timing-split, tuist-sharding, node-24-release, node-v25-changelog, snapshot-esm-pr, pdpp-ri-measurement, related-test-selection-corpus-entry, certification-grade-corpus-entry]
source_session: f76d8df0-4ad4-4a86-a773-4c8bf70a9286
---

<!--
Companion / do-not-duplicate map:
- testing/related-test-selection-for-pdpp-2026-08-29.md already establishes, in depth, that Jest/Vitest/
  Playwright related-test selection is STATIC-import-graph-based, documents the dynamic-import/fixture
  blind spots, and records that nodejs/node #42992 (--findRelatedTests for node:test) is stale and
  unimplemented. THIS entry does NOT re-derive any of that, and does not revisit the selection
  recommendation. It answers a DIFFERENT question that entry explicitly deferred: that entry's
  recommendation ends "until the runtime problem is measured and shown to be real, status quo remains
  correct." This entry is that measurement, plus the runner-level (not selector-level) speed facts.
  NOTE the one correction this entry makes to the companion's framing: the companion is about
  *related-test selection*, which node:test indeed lacks; it never claimed node:test lacks *sharding*.
  The "node:test has no --shard" belief is common in the wild and is FALSE — see CLAIMS below.
- testing/certification-grade-test-matrix-speed-2026-09-01.md covers build/task-level content-hash
  caching (Bazel/Nx/Turborepo) and whether cached/skipped evidence is defensible. NODE_COMPILE_CACHE
  here is a V8 *code cache*, not a task-result cache: it caches compiled bytecode and never skips
  executing a test, so it carries none of that entry's evidence-reuse risk. Different mechanism,
  different risk class — do not conflate.
- testing/strykerjs-is-viable-for-pdpp-only-as-a-narrow-pilot... establishes node:test's weak
  "runner intelligence" (no per-test coverage location API). The undocumented mock.timers surface
  found here is a second, independent instance of node:test's docs lagging its implementation.
-->

## CLAIMS

### node:test sharding — it exists, and its algorithm is not what the docs imply

- `node --test` ships `--test-shard=<index>/<total>`, added in v20.5.0 and v18.19.0. The widely-repeated claim that node:test has no built-in sharding equivalent to Vitest's/Jest's `--shard` is false. [node-cli-md]
- The CLI docs describe it as dividing "all tests files into `total` equal parts." The implementation is `ArrayPrototypeFilter(testFiles, (_, index) => index % shard.total === shard.index - 1)` — a strict **index-modulo round robin**, not contiguous blocks, and with **no reference to any timing or duration data**. It balances file *counts*; it cannot balance file *durations*. [node-runner-src] [node-cli-md]
- Consequence: for a suite with a heavy duration tail, `--test-shard` wall-clock equals the slowest shard, and node:test offers no built-in remedy. Duration-balanced sharding requires bypassing `--test-shard` and passing an explicit precomputed per-job file list (the standard approach elsewhere being greedy LPT bin-packing against historical durations). [node-runner-src] [circleci-timing-split] [tuist-sharding]
- `--test-shard` is rejected outright in watch mode: `throw new ERR_INVALID_ARG_VALUE('options.shard', watch, 'shards not supported with watch mode')`. [node-runner-src]
- node:test emits a `'test:summary'` reporter event **per file, and only when process isolation is used** — i.e. the per-file duration data needed to build a duration-balanced shard plan is available from the runner itself, but only in the isolated (default) mode. [node-test-md]
- node:test ships a built-in `junit` reporter and supports `--test-reporter-destination`, which together give the per-shard-artifact-then-merge pattern without third-party reporters. [node-test-md]

### node:test process isolation — the default already is one process per file

- Process-level isolation is node:test's default: "When process-level test isolation is enabled, each matching test file is executed in a separate child process." `--test-isolation=none` runs all files in one process. The flag was renamed from `--experimental-test-isolation` in v23.6.0. [node-test-md] [node-cli-md]
- `--test-concurrency` "defaults to `os.availableParallelism() - 1`", and is **ignored entirely when `--test-isolation=none`, where concurrency is forced to one**. This makes whole-suite consolidation a strict trade of parallelism for load savings, not a free win. [node-cli-md]

### node:test mock.timers — stable, and broader than its own documentation

- MockTimers was added in v20.4.0/v18.19.0 and became **stable in v23.1.0**; it is no longer experimental. [node-test-md]
- The docs state the supported timer values are `'setInterval'`, `'setTimeout'`, `'setImmediate'`, and `'Date'`. The implementation's `SUPPORTED_APIS` array contains **six** entries: those four plus **`'scheduler.wait'` and `'AbortSignal.timeout'`**. The string `scheduler` does not appear in `doc/api/test.md` at all, and `AbortSignal.timeout` mocking appears undocumented. [node-mock-timers-src] [node-test-md]
- This matters for retry/backoff/timeout code specifically: `AbortSignal.timeout` is the idiomatic modern way to bound an async operation, and the ability to fake it is not discoverable from the documentation.
- Enabling an API mocks it simultaneously in `node:timers`, `node:timers/promises`, and the global context — so promise-based timer code is covered. [node-test-md]
- The documented hard limitation that most often forces real sleeps: **destructured imports are not intercepted**. "Destructuring functions such as `import { setTimeout } from 'node:timers'` is currently not supported by this API." Any module under test that destructures its timer import gets real timers regardless of `tick()`. [node-test-md]
- Correct ordering when advancing a timer is mandatory and non-obvious: start the promise, call `tick()` synchronously, then `await`. Awaiting first deadlocks because nothing advances the clock. `runAll()` fires all pending timers and advances a mocked `Date` to the furthest timer's time. [node-test-md]
- `tick()` "accepts only positive numbers," which the docs flag as a deliberate divergence from real `setTimeout`. [node-test-md]
- `@sinonjs/fake-timers` covers a strictly larger surface (`process.nextTick`, `process.hrtime`) and is runner-agnostic; no rigorous head-to-head performance comparison against node:test's built-in was found. [sinon-fake-timers]

### Per-file spawn cost — the TS loader is not the dominant term

- Measured on the PDPP reference-implementation suite (1,034 files, `memory-default` profile, Node v24.14.1, 24-core Linux): bare `node -e ""` = 0.01 s; `node --test --import tsx` on an empty test file = 0.10 s; plus the suite's hermetic preload and accounting reporter = ~0.20 s. **Harness and loader overhead together are ~0.2 s per file.** [pdpp-ri-measurement]
- On the same suite, `await import('./server/index.ts')` — the application entry module — costs **1.37–1.47 s** on its own, roughly 7x the entire harness+loader overhead. 815 of 1,017 test files import from `server/` or `runtime/`; 177 import `server/index.ts` directly. **The dominant per-file cost is re-evaluating the application module graph, not the TypeScript loader.** [pdpp-ri-measurement]
- `NODE_COMPILE_CACHE` (added v22.1.0; no longer experimental as of v25.4.0/v24.15.0) measured on that suite in a paired, interleaved A/B at file-concurrency 8 produced 254.7 s mean without vs 241.9 s mean with, but with **overlapping ranges and one of three trials reversing the sign** (245.1 s without vs 252.2 s with). The ~5 % mean difference was not distinguishable from run-to-run noise on a loaded machine. [pdpp-ri-measurement] [node-cli-md]
- Single-module probes on the same codebase indicate why: importing `server/index.ts` cost ~1.25 s under `tsx` with or without a warm compile cache, versus ~1.03–1.13 s under Node's native type stripping with a warm cache. **`tsx` largely cancels the compile-cache benefit**, because tsx's per-spawn cost is worker-thread startup plus an esbuild transform, neither of which a V8 code cache can eliminate. An independent synthetic-file benchmark measured the same asymmetry: compile cache saved 40.4 ms/file under native stripping but −1.6 ms (nothing) under tsx. [pdpp-ri-measurement]
- The corollary is that `NODE_COMPILE_CACHE` and a tsx→native-type-stripping migration are **only worth adopting as a pair**; either alone underperforms. [pdpp-ri-measurement]
- tsx confirmed to run its transform in a worker thread (`node:worker_threads` imported in `dist/esm/api/index.mjs` of tsx@4.23.13; its only dependency is `esbuild ~0.28.0`). [tsx-npm]
- The widely-cited claim that tsx is slower than native stripping "by orders of magnitude" derives from a hello-world microbenchmark (48.39 ms vs 319.80 ms means). On a realistic file with a real module graph the measured gap collapses to +12.2 ms/file (1.12x), and on a trivial file to a tie. **Do not budget a large win from the loader swap alone.** [staffa-benchmark] [pdpp-ri-measurement]
- Known blockers for native type stripping: no enums/namespaces without `--experimental-transform-types`, no legacy decorators, `ERR_UNSUPPORTED_NODE_MODULES_TYPE_STRIPPING` under `node_modules`, and amaro ignoring `compilerOptions.paths` (so TS path aliases break). *Evidence for the `paths` limitation is secondary (blog/issue summaries), not verified against amaro's source; it is also the blocker most likely to bite a real monorepo, so verify it first.* [ts-native-limits]
- `NODE_COMPILE_CACHE` is version-keyed (caches from different Node versions coexist but are not interchangeable), is written only at process exit, and `NODE_COMPILE_CACHE_PORTABLE=1` allows reuse across directory locations — the latter being what makes CI cache restore viable when runner and developer paths differ. `module.enableCompileCache()` (v22.8.0) enables it programmatically rather than via env var. [node-module-md] [node-cli-md]
- Node's docs explicitly warn that the compile cache degrades V8 coverage precision and recommend turning it off when generating coverage — so it cannot simply be set globally in a pipeline that also produces coverage. [node-module-md]
- `node --build-snapshot` is not applicable to a large ESM TypeScript test suite: user-land ESM is unsupported (requiring pre-bundling to a single CJS file) and `ERR_NOT_SUPPORTED_IN_SNAPSHOT` is thrown in the `Worker` constructor, despite snapshot building becoming non-experimental in v25.4.0/v24.13.1. [snapshot-esm-pr] [node-cli-md]

### The lever that actually dominated, measured

- On the same 1,034-file suite, file-concurrency was worth far more than any loader or cache change: **cap 2 → 793.8 s; cap 8 → 245–272 s (3 runs); cap 16 → 197–221 s (3 runs)**, all completing 1,034/1,034 files with zero failures. [pdpp-ri-measurement]
- The suite's per-file duration distribution was measured as **flat**, not tailed: median 2.00 s, p99 6.48 s, max 13.47 s, and the top 30 files of 1,034 accounted for only **8.1 %** of total file-seconds (top 10 = 3.2 %). 10,253 tests across 1,034 files is a median of 6 tests per file, with 130 files containing ≤1 test. **A flat distribution is the signature of fixed per-file cost, and it is also the case where `--test-shard`'s runtime-blind round robin is near-optimal rather than harmful.** [pdpp-ri-measurement]
- Consolidating a *family* of related test files into one process (via `--test-isolation=none` on that group only) was measured at 64.7 s → 19.4 s for a 49-file family (70 % reduction) and 49.8 s → 22.8 s for a 13-file family (54 %), with **exact accounting parity in both cases** (49-file family: pass=247/skip=30/fail=0 in both modes; 13-file family: 180 passes, 0 failures in both). [pdpp-ri-measurement]
- Raising file concurrency has a measured correctness cost in suites containing absolute wall-clock budget assertions: at concurrency 12 on a loaded machine, a test asserting a 300 ms latency budget failed at 315.9 ms, while the same suite was green at concurrency 8 and at 16 in other runs. In that suite 43 files assert an explicit ms budget and 120 reference measured wall-clock durations. **Absolute-millisecond assertions measure the machine as much as the code, and are the first thing a concurrency increase breaks.** [pdpp-ri-measurement]

### Node 2025–26 test-speed developments

- Node 24: the test runner "now automatically waits for subtests to finish, eliminating the need to manually await test promises" (PR #56664); V8 updated to 13.6. [node-24-release]
- Node 25.x test-runner changes: expected-failure support (25.5.0, #60669), an `env` option for `run()` (25.6.0, #61367), interrupted-test display on SIGINT (25.7.0, #61676), and module-mocking options consolidated under `exports` (25.9.0). [node-v25-changelog]
- No dedicated Node-core test-runner *performance* initiative with published benchmarks was found for the 2025–26 window; gains in that period are indirect (V8 version bumps, compile cache graduating from experimental). *This is an absence-of-evidence finding from one search pass, not a proof of absence.* [node-v25-changelog] [node-24-release]

## SOURCES

**node-cli-md**
URL: https://raw.githubusercontent.com/nodejs/node/main/doc/api/cli.md
Accessed: 2026-09-09
Quote: `--test-shard` (added v20.5.0, v18.19.0): "Test suite shard to execute in a format of `<index>/<total>`" / "This command will divide all tests files into `total` equal parts, and will run only those that happen to be in an `index` part." — `--test-concurrency`: "If `--test-isolation` is set to `'none'`, this flag is ignored and concurrency is one. Otherwise, concurrency defaults to `os.availableParallelism() - 1`." — `--test-isolation=mode`: "When `mode` is `'process'`, each test file is run in a separate child process. ... The default isolation mode is `'process'`." (v23.6.0: "This flag was renamed from `--experimental-test-isolation` to `--test-isolation`.") — `NODE_COMPILE_CACHE=dir` added v22.1.0; v25.4.0/v24.15.0 "This feature is no longer experimental."

**node-test-md**
URL: https://raw.githubusercontent.com/nodejs/node/main/doc/api/test.md
Accessed: 2026-09-09
Quote: "When process-level test isolation is enabled, each matching test file is executed in a separate child process." / "The currently supported timer values are `'setInterval'`, `'setTimeout'`, `'setImmediate'`, and `'Date'`." / "**Note:** Destructuring functions such as `import { setTimeout } from 'node:timers'` is currently not supported by this API." / "it will mock the `setTimeout` functions in the node:timers and node:timers/promises modules, as well as from the Node.js global context." / "**Note:** This diverges from how `setTimeout` in Node.js behaves and accepts only positive numbers." / MockTimers YAML: "added: - v20.4.0 - v18.19.0 / changes: - version: v23.1.0 ... description: The Mock Timers is now stable." / "| [`'test:summary'`][] | Per file, only when process isolation is used. |" / "* `junit` The junit reporter outputs test results in a jUnit XML format"

**node-runner-src**
URL: https://raw.githubusercontent.com/nodejs/node/main/lib/internal/test_runner/runner.js
Accessed: 2026-09-09
Quote: (L~1005) `if (shard) { testFiles = ArrayPrototypeFilter(testFiles, (_, index) => index % shard.total === shard.index - 1);` / (L~856) `throw new ERR_INVALID_ARG_VALUE('options.shard', watch, 'shards not supported with watch mode');`

**node-mock-timers-src**
URL: https://raw.githubusercontent.com/nodejs/node/main/lib/internal/test_runner/mock/mock_timers.js
Accessed: 2026-09-09
Quote: `const SUPPORTED_APIS = [ 'setTimeout', 'setInterval', 'setImmediate', 'Date', 'scheduler.wait', 'AbortSignal.timeout', ];`

**node-module-md**
URL: https://nodejs.org/api/module.html#module-compile-cache
Accessed: 2026-09-09
Quote: "Compilation cache generated by one version of Node.js can not be reused by a different version of Node.js." / "Currently when using the compile cache with V8 JavaScript code coverage, the coverage being collected by V8 may be less precise in functions that are deserialized from the code cache. It's recommended to turn this off when running tests to generate precise coverage." / "loading of `test/fixtures/snapshot/typescript.js` went from ~130ms to ~80ms"

**tsx-npm**
URL: https://registry.npmjs.org/tsx (v4.23.13 tarball inspected)
Accessed: 2026-09-09
Quote: dependencies `{"esbuild":"~0.28.0"}`; description "TypeScript Execute (tsx): Node.js enhanced with esbuild to run TypeScript & ESM files"; `node:worker_threads` imported in `package/dist/esm/api/index.mjs`

**staffa-benchmark**
URL: https://sebastian-staffa.eu/posts/nodejs-native-ts-benchmark/
Accessed: 2026-09-09
Quote: Node.js 23.06 mean "48.39 ms"; tsx mean "319.80 ms"; "The two tools that are written in javascript themselves, ts-node and tsx, are slower by orders of magnitude." — NOTE: hello-world microbenchmark; contradicted for realistic module graphs by [pdpp-ri-measurement].

**ts-native-limits**
URL: https://blog.logrocket.com/running-typescript-node-js-tsx-vs-ts-node-vs-native/ ; https://github.com/nodejs/node/issues/57215
Accessed: 2026-09-09
Quote: "Error [ERR_UNSUPPORTED_NODE_MODULES_TYPE_STRIPPING]: Stripping types is currently unsupported for files under node_modules"; "amaro ignores `compilerOptions.paths`". Secondary sources; not verified against amaro's source.

**sinon-fake-timers**
URL: https://sinonjs.org/concepts/fake-timers/ ; https://www.npmjs.com/package/@sinonjs/fake-timers
Accessed: 2026-09-09
Quote: "FakeTimers provides a `nextTick` implementation synchronized with the clock, plus a `process.hrtime` shim"

**circleci-timing-split**
URL: https://circleci.com/docs/guides/optimize/parallelism-faster-jobs/
Accessed: 2026-09-09
Quote: "Timing data from the previous run is used to split a suite as evenly as possible over a specified number of environments" (`--split-by=timings`)

**tuist-sharding**
URL: https://tuist.dev/blog/2026/03/25/test-sharding
Accessed: 2026-09-09
Quote: "greedy LPT (Longest Processing Time first) — sort all test units by average duration descending, then assign each to whichever shard currently has the lowest total duration"

**node-24-release**
URL: https://nodejs.org/en/blog/release/v24.0.0
Accessed: 2026-09-09
Quote: "the test runner module now automatically waits for subtests to finish, eliminating the need to manually await test promises" (PR #56664)

**node-v25-changelog**
URL: https://github.com/nodejs/node/blob/main/doc/changelogs/CHANGELOG_V25.md
Accessed: 2026-09-09
Quote: 25.5.0 expected-failure support (#60669); 25.6.0 `env` option for `run` (#61367); 25.7.0 show interrupted tests on SIGINT (#61676); 25.9.0 module mocking options consolidated into `exports`

**snapshot-esm-pr**
URL: https://github.com/nodejs/node/pull/38905 ; https://github.com/nodejs/node/pull/47887
Accessed: 2026-09-09
Quote: "for the initial iteration, user land CJS modules and ESM are not yet supported in the snapshot, so only one single file can be snapshotted"; `ERR_NOT_SUPPORTED_IN_SNAPSHOT` thrown in the Worker constructor

**pdpp-ri-measurement**
URL: file:///home/tnunamak/code/pdpp/local/TEST-SPEED-ANALYSIS-0909.md
Accessed: 2026-09-09
Quote: First-party measurement, PDP-Connect `data-connect` @ 234547d6c, `reference-implementation` suite, 1,034 files, `memory-default` profile, Node v24.14.1, 24-core Linux under load average ~39–47. Concurrency: cap 2 = 793.8 s, cap 8 = 245–272 s (n=3), cap 16 = 197–221 s (n=3), all 1,034/1,034 files, 0 failures. Compile-cache paired A/B at cap 8: no-cache {247.0, 272.0, 245.1}, warm-cache {226.0, 247.5, 252.2}. Distribution: median 2.00 s, p99 6.48 s, max 13.47 s, top-30 = 8.1 % of file-seconds. Family consolidation: 49 files 64.7 s → 19.4 s (pass=247/skip=30/fail=0 both modes); 13 files 49.8 s → 22.8 s (180 passes both modes). Module graph: `import('./server/index.ts')` = 1.37–1.47 s vs ~0.20 s total harness overhead.

**related-test-selection-corpus-entry**
URL: file:///home/tnunamak/code/dotfiles/ai/research/testing/related-test-selection-for-pdpp-2026-08-29.md
Accessed: 2026-09-09
Quote: "Until the runtime problem is measured and shown to be real, Option C (status quo) remains the correct choice"

**certification-grade-corpus-entry**
URL: file:///home/tnunamak/code/dotfiles/ai/research/testing/certification-grade-test-matrix-speed-2026-09-01.md
Accessed: 2026-09-09

## SYNTHESIS

### The reframing this measurement forces

The instinct when a 1,000-file suite is slow is to hunt the slow tail: rank by duration, read the top 30, fix the sleeps. That instinct is wrong for suites of this shape, and the diagnostic that tells you so is cheap — **compute the share of total time held by the top N files before reading any of them.** Here the top 30 of 1,034 held 8.1 % and the top 10 held 3.2 %. When the tail is that thin, per-test optimisation has no headroom by construction, and the entire cost is a fixed per-file toll paid a thousand times.

This distinguishes two failure modes that look identical from the outside ("the suite is slow") but have disjoint fixes:
- **Tailed distribution** → a few tests do genuinely expensive work → fake the expensive boundary, or accept it. Duration-balanced sharding matters a lot; `--test-shard`'s round robin actively hurts.
- **Flat distribution** → fixed per-file cost dominates → raise concurrency, amortise the module graph across files, shrink the graph. Duration-balanced sharding is unnecessary, and `--test-shard`'s runtime-blind round robin happens to be near-optimal.

The flat case is the one where the loud, popular levers (fake timers, test selection, TIA) all have near-zero headroom, and the quiet ones (a concurrency env var, process consolidation per family) are worth multiples.

### Why the loader swap is the wrong first move, and the module graph is the right diagnosis

The tsx-vs-native-type-stripping question attracts attention because a published benchmark shows an order-of-magnitude gap. That benchmark measures loader boot on a hello-world file. Once a real application module graph is in the picture the loader is a rounding error: measured here, harness + loader = ~0.2 s per file, application graph = ~1.4 s per file, a 7:1 ratio in favour of the thing nobody was proposing to change. **Measure the import cost of your application entry module before optimising your TypeScript loader** — it is a two-line probe and it reorders the whole backlog.

The `NODE_COMPILE_CACHE` result is the same lesson in a different key. It is a genuinely good feature with a Node-blessed benchmark behind it, and it produced no distinguishable effect here — because `tsx` cancels it. Two independent measurements (a synthetic-file benchmark: +40.4 ms/file saved under native stripping, −1.6 ms under tsx; and this suite's paired A/B: overlapping distributions with one trial reversing sign) agree on the mechanism. A V8 *code* cache cannot amortise worker-thread startup or an esbuild *transform*. The practical rule: **compile cache and native type stripping are one change, not two.** Shipping either alone is how a well-founded optimisation ends up producing nothing and discrediting the idea.

There is also a methodological trap worth recording, because it nearly produced a wrong answer here. The first compile-cache measurement showed 301 s → 226 s, a 25 % win, and it was an artefact: the 301 s "baseline" was the first full run on the machine and included a cold OS page cache. Only a *paired, interleaved* A/B — alternating configurations back to back, three times — revealed the true effect was inside the noise. On a shared or loaded machine, a single before/after pair on a multi-minute suite is not evidence; anything under ~10 % needs interleaving and n≥3, and the honest report of a null result is more valuable than the tempting first number.

### The isolation trade is real and should be priced per-family, not per-suite

Per-file process isolation is not overhead to be eliminated; it is a purchased correctness property — cross-file state leakage is impossible by construction. Consolidation buys 54–70 % on a family and sells that property. Two things make the trade defensible at family granularity and indefensible at suite granularity:

1. `--test-isolation=none` forces intra-process concurrency to 1 [node-cli-md], so whole-suite consolidation trades *all* parallelism for load savings — strictly worse at 1,000 files.
2. The verification obligation is mechanical and cheap at family scale: require exact pass/skip/fail parity against the pre-change receipt (achieved here: 247/30/0 identical in both modes), plus an order-shuffle run, since order sensitivity is the signature of leaked state. That check does not scale to "consolidate everything" — you would be verifying one enormous claim instead of many small independent ones.

The general principle: when trading an isolation guarantee for speed, the unit of the trade should be the unit at which you can *prove* nothing changed.

### node:test's documentation lags its implementation, twice, in ways that change decisions

Two independent instances surfaced in one pass: `--test-shard` is documented as producing "equal parts" when it is an index-modulo round robin (the difference decides whether you can use it for a tailed suite at all), and `mock.timers` documents four supported APIs when the source supports six — the two undocumented ones, `scheduler.wait` and `AbortSignal.timeout`, being precisely what modern timeout/retry code uses. Both were found by reading `lib/internal/test_runner/*` directly against the docs. For a runner that has repeatedly been shown to trail Jest/Vitest in "runner intelligence," **reading the implementation rather than the docs is not paranoia; it changed the answer both times it was tried here.**

### Where absolute-millisecond assertions fit

The one thing that broke when concurrency rose was a test asserting a 300 ms absolute latency budget, which failed at 315.9 ms under load. Such an assertion is a machine measurement wearing the costume of a code assertion: it is coupled to every other process on the box, which means it is coupled to the concurrency setting, which means it silently caps how fast the suite is permitted to run. The right response is not to lower the concurrency cap to keep the test green — that lets a test's incidental machine-sensitivity set the whole gate's latency. It is to re-express the budget relative to a control measurement taken in the same run, after which the concurrency question becomes free of it. Suites that intend to scale concurrency should treat absolute-ms assertions as a known blocker class and audit them up front (43 of 1,017 files here).
