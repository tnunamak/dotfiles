---
title: "Certification-grade test evidence can be sped up with content-hash caching, test-impact analysis, and database-template cloning, but every documented incident where a defect escaped traces to a cache key or selection graph missing an input that was actually read, so provenance-attested reuse plus a periodic full-run cadence is what keeps cached evidence defensible under adversarial review"
date: 2026-09-01
topic: testing
tags: [caching, bazel, turborepo, nx, test-impact-analysis, do-178c, iec-62304, slsa, in-toto, postgres, certification, provenance]
status: draft
sources: [bazel-hermeticity, bazel-cache-debug, bazel-issue-26657, turborepo-env-modes, turborepo-issue-11216, nx-creep-cve, google-tap-paper, google-flaky-tests-blog, ms-tia-docs, do178c-vector-whitepaper, do178c-tool-qualification, iec62304-soup-wikipedia, iec62304-edition2-intuitionlabs, slsa-in-toto-blog, in-toto-test-result-predicate, pgtestdb-brandur, integresql-github, qaskills-testcontainers, github-actions-cache-poisoning-hive, related-test-selection-corpus-entry]
source_session: d1754033-110f-4764-bd50-3030d665289f
---

<!--
Companion / do-not-duplicate map:
- testing/related-test-selection-for-pdpp-2026-08-29.md already establishes, in depth, that Jest/Vitest/
  Playwright/node:test test-impact selection is all STATIC-import-graph-based (not execution-observed),
  documents the exact blind spots (dynamic import(), readFileSync of fixtures, reflection), and cites the
  Playwright #34339 fixture-collapse bug. THIS entry does not re-derive any of that. It answers a different,
  broader question: build/task-level content-hash caching (Bazel/Nx/Turborepo/Gradle-class tools, not test
  runners), and the certification-standards question of whether reused/cached evidence is acceptable at all.
- testing/hermetic-test-scratch-needs-invocation-ownership-immediate-teardown-and-bounded-orphan-recovery.md
  covers filesystem-scratch hermeticity for test *execution*, not cache-key hermeticity for task *caching*.
  Related but orthogonal — that entry is about not leaking test scratch into a shared /tmp; this entry is
  about not silently reusing a stale cached PASS.
-->

## CLAIMS

### Content-hash task caching — what forms the key, and how non-hermetic inputs break it

- Bazel's own hermeticity docs identify the root cause of remote-cache discrepancies as "something non-hermetic in the build causing the actions to receive different action keys across the two runs," and name specific non-hermeticity sources: actions that create files non-deterministically (build IDs, timestamps), system binaries that differ across hosts, and actions that write into the source tree during the build. [bazel-hermeticity] [bazel-cache-debug]
- Bazel's official remote-cache debugging guide states the action cache key covers "both the inputs (not only files, but also command line arguments, environment variables, etc) and the outputs of the action," and recommends comparing `--execution_log_compact_file` output between a hit and a miss run as the diagnostic method when a cache key mismatch is suspected. [bazel-cache-debug]
- A filed and still-referenced Bazel issue (#26657) documents that Bazel's local, persistent "compact action cache" in `--output_base` is reused across builds even when the *remote* cache endpoint is switched (e.g. from Buildbarn to Buildfarm backend), producing "Missing digest" errors — a real case of a cache key that does not fully capture which remote store the recorded digest is actually valid against. [bazel-issue-26657]
- Turborepo computes two separate hashes per run — a global hash and a per-task hash — and a task misses cache if either changes; it explicitly folds in the source files of every internal workspace package that a root-level `package.json` depends on into the *global* hash, so editing a shared root-dependency file invalidates every cacheable task repo-wide, not just tasks that actually import the changed file. [turborepo-env-modes]
- Turborepo's Environment Modes give a binary choice for env-var handling: "strict" mode hashes only the vars explicitly declared in `env`/`globalEnv` in `turbo.json`; "loose" mode makes the entire process environment available to the task without it being part of the cache key at all — meaning an undeclared env var can silently change task output without invalidating the cache under loose mode. [turborepo-env-modes]
- A documented, now-fixed Turborepo bug: in older 1.x-era releases, adding a newly-declared env var to hashing caused a correct cache miss, but *removing* a declared var caused the task to incorrectly hit the wrong (stale) cached artifact — an asymmetry where "unset" was not itself a distinct hashable state. Current 2.x treats "unset" as its own hashable value, closing this specific gap. [turborepo-env-modes]
- A still-open 2026 Turborepo GitHub issue (#11216) reports Next.js's `output: "standalone"` build mode producing symlinks with paths too long for `tar`/Windows to archive, causing cache *writes* to fail silently (IO warning only, non-fatal) — every subsequent build on that machine then reports a cache miss despite an identical hash, because the artifact was never actually persisted. This is a cache-write-integrity failure, not a cache-key failure, and it fails in the safe direction (extra work, not a false pass). [turborepo-issue-11216]
- CVE-2025-36852 ("CREEP"), filed against Nx cache configurations but architecturally applicable to any bucket-style shared remote cache (Turborepo included): when a cache store has no branch/trust isolation and operates first-write-wins per content-hash key, a contributor with only pull-request access can pre-populate a cache entry for a hash that a later, trusted (e.g. main-branch or release) build will also compute, causing the trusted build to silently reuse the attacker's poisoned artifact instead of rebuilding. This is a cache-key-correctness attack, not a bug — the hash matched exactly as designed; the vulnerability is that "matching hash" was treated as sufficient trust, with no binding to *who* produced the cached bytes. [nx-creep-cve]
- Nx documents that it sandboxes each cacheable task and can surface (in strict/opt-in mode) undeclared filesystem reads/writes that fall outside the declared `namedInputs`, whereas Turborepo by default has no task sandboxing and permits a task to read or write anywhere on the filesystem — an unsandboxed cache system cannot detect an undeclared input that should have been part of the cache key. [turborepo-env-modes]

### Test-impact analysis at scale — skip rates and paired safety nets

- Google's published research on its Test Automation Platform ("Taming Google-Scale Continuous Testing") reports 7.4% of tests were skipped by their distance-based selection heuristic in the measured dataset, with under 0.5% of tests failing overall; at more aggressive selection settings (MinDist=6 / MinDist=10), only 50%–61% of test targets were executed at all. [google-tap-paper]
- The same Google research line reports that under 1% of test targets ever actually detect a real breakage across the measured corpus — the empirical justification Google gives internally for why heavy selection/skipping is acceptable: the signal is concentrated in a small fraction of tests regardless of whether selection is applied. [google-tap-paper]
- Google separately reports that roughly 1.5% of all test runs at Google are "flaky" (non-deterministic pass/fail unrelated to the code under test), and that flakiness affects close to 16% of all distinct tests at least once — meaning any TIA-style skip decision must be paired with flake detection, or a "skip" and a "flaky-therefore-ignored" result become indistinguishable to a human auditor. [google-flaky-tests-blog]
- Microsoft's Azure DevOps Test Impact Analysis (VSTest-based) documents three concrete, paired safety mechanisms rather than trusting selection alone: (1) a "safe fallback" — when TIA encounters a file type it cannot reason about (its docs give HTML/CSS as the example), it falls back to running the *entire* suite for that commit rather than guessing; (2) a configurable periodicity setting to force a full-suite run on a schedule regardless of selection outcome — Microsoft's own docs call this "recommended"; (3) a manual `DisableTestImpactAnalysis` build-variable override to force a full run for any single build. [ms-tia-docs]
- Microsoft's TIA docs also give an explicit auditor-facing verification recipe for trusting a selection scheme in the first place: run TIA-selected tests (T1) and the full suite (T2) in parallel in the same pipeline, and require that "if T1 passes, check that T2 passes as well. If there was a failing test in T1, check that T2 reports the same set of failures" — i.e. the vendor's own documented method for establishing that a selection algorithm is trustworthy is to run the full suite anyway and diff the two outcomes, not to take the selection algorithm's soundness on faith. [ms-tia-docs]
- Community bug reports against the same Azure DevOps VSTest task document real accuracy failures in the wild: a multi-targeting misconfiguration silently caused zero tests to execute while the build still reported success (no test-count-zero-is-an-error guard existed), and multiple independent 2026 reports describe the TIA/code-coverage data collector silently emitting "will not work" warnings with no underlying code or pipeline change — i.e., the tool's own selection/coverage infrastructure degraded without the change that broke it being visible in the diff under review. [ms-tia-docs]

### Certification/regulated contexts — is cached/skipped test evidence acceptable?

- DO-178C (airborne software) requires that a released, DO-178C-compliant software version "be able to be recreated and retested in its entirety" for **30 years** after delivery, which forces long-term custody not just of test *results* but of the full recreation environment: source, build scripts, compiler/toolchain versions, and test data — i.e. certification-grade "cached" evidence is defensible only if the artifact hash it was generated against, and every tool used to generate it, remains reproducible on demand, not merely archived as a pass/fail log. [do178c-vector-whitepaper]
- DO-178C's own evidentiary standard is explicitly an adequacy test, not a presence test: "the existence of evidence does not make it sufficient — evidence is sufficient when it demonstrates the property it is claimed to demonstrate under the conditions under which the claim applies." Applied to reuse: prior test evidence remains creditable only if the conditions that made it valid (same compiler, same target processor, same integration context) still hold for the artifact being certified now — a changed compiler or target invalidates the credit even if the source hash is unchanged. [do178c-vector-whitepaper]
- DO-178C Section 12.2.1 requires that any tool which "eliminates, reduces, or automates" a DO-178C process step without its output being independently verified per Section 6 must itself undergo tool qualification. This directly implicates any caching/selection system used to decide "this evidence may be reused, this test may be skipped" for a DO-178C submission: the selector itself becomes a qualified tool subject to the same rigor as the code it is gating, not an off-the-shelf CI convenience. [do178c-tool-qualification]
- IEC 62304 (medical device software) explicitly requires, in its clause 9.8, that regression-test documentation cover a defined set of elements after any change, and separately requires that Software of Unknown Provenance (SOUP — "software of unknown provenance," clarified as the modern reading of the historical "pedigree" term) be risk-assessed for any gap in available evidence, with a documented remediation decision — there is no blanket exemption for SOUP-adjacent (e.g., third-party CI cache) components; missing evidence must be an explicit, risk-assessed decision, not a silent default. [iec62304-soup-wikipedia]
- IEC 62304 Edition 2 (in development, targeted ~2027) is moving toward explicitly distinguishing "development revision" changes from "routine maintenance" changes in change-control SOPs specifically so that retest scope and documentation burden can scale down for minor/maintenance changes — this is regulatory acknowledgment that today's Edition 1 text does not yet give manufacturers a clean, standards-sanctioned methodology for reduced-retest-scope credit; current practice in this area is evolving, not settled. **Evidence here is comparatively thin** — no source found gives a citable Edition-1 clause that authorizes skipping regression tests based on a change-classification or cache argument; risk-based retest-scope reduction under Edition 1 appears to be a practitioner convention layered on top of the standard, not standard text itself. [iec62304-edition2-intuitionlabs]
- SLSA provenance is expressed as a signed in-toto attestation (a "Statement") binding a build's outputs to its inputs/recipe/builder identity; in-toto's predicate system is explicitly extensible beyond SLSA's build-provenance predicate to a dedicated **test-result predicate**, which a downstream "office of compliance" can verify against a quality gate — the framework's own stated use case is asserting "that all automated tests passed and none were skipped," i.e. the reuse-safety property (was anything silently skipped) is meant to be a first-class, machine-checkable claim inside the attestation itself, not an out-of-band assumption. [slsa-in-toto-blog] [in-toto-test-result-predicate]
- The in-toto/SLSA model's mechanism for making cached evidence *reusable without re-verification-by-trust* is cryptographic signing plus a verification policy evaluated against the full attestation chain at consumption time — a downstream consumer (e.g. a release gate) checks the signed test-result attestation against the exact artifact digest it names, rather than re-running the tests or trusting an unsigned CI log. This is the direct structural answer to "what must cached evidence STATE": the artifact hash it was generated against, the identity of the entity that generated it, and (via the predicate schema) whether any tests were skipped — all inside a signed, independently-verifiable document. [slsa-in-toto-blog] [in-toto-test-result-predicate]

### Database-heavy suites — avoiding per-test PostgreSQL re-provisioning

- Postgres's native `CREATE DATABASE ... TEMPLATE <name>` mechanism copies a fully-migrated/seeded template database's heap, index, and catalog files (in 8 kB page chunks) to create a new database, rather than re-running migrations — this is the primitive underlying every fast-per-test-database tool surveyed. [pgtestdb-brandur]
- `pgtestdb` (Go tooling) benchmarks template-clone setup at a mean of 98.4ms per test across 466 tests (p90 247.4ms, p95 299.5ms, max 465.1ms) — "remarkably quick," comparable to a schema-based (not database-based) isolation approach on setup time alone, though a separate schema-based benchmark in the same source achieved 3.5x faster *overall suite* wall-clock via connection pooling/reuse on top of the schema approach. [pgtestdb-brandur]
- `IntegreSQL` (Go tooling) runs a warm pool of already-cloned template databases and reports the pool hand-off ("switching to a new replica") at avg=11ms, min=1ms, max=445ms per test — confirming that once the template is prepared, the marginal per-test cost of a full isolated database is on the order of tens of milliseconds, not the seconds a fresh `migrate`-then-seed cycle would cost. [integresql-github]
- Isolation-strategy tradeoffs documented across sources: transaction-rollback wrapping (`BEGIN`/test/`ROLLBACK`) is fastest but breaks if the code under test opens a second connection or issues an explicit `COMMIT` independent of the test harness's transaction; schema-per-test namespaces objects within one database but requires every query/tool/ORM in the path to honor `search_path` consistently; database-per-test (template-clone) gives the strongest isolation boundary (separate catalog, separate connection-visible state) while sharing one running Postgres server process, at the ~10–100ms marginal cost measured above. [qaskills-testcontainers]

### Documented anti-patterns — caching/selection letting a defect through

- CVE-2025-36852 ("CREEP") is a concretely documented case of cache-key correctness itself being the vulnerability: a PR-scoped, untrusted build populates a shared cache under a content-hash key that a later trusted/protected-branch build will independently compute and therefore trust, letting an attacker-controlled artifact ride through a trusted gate purely because the hash matched — the exact "cached pass is not adversarially defensible" failure mode the task's framing worries about, now with a CVE and named victims (this is a security-supply-chain incident, not a test-evidence incident specifically, but it is the identical trust-boundary defect: hash equality was treated as a proxy for provenance equality, and it was not one). [nx-creep-cve]
- The TanStack npm-publish incident (dated in coverage as 2026, 42 `@tanstack/*` packages, 84 malicious versions published) chained a `pull_request_target` workflow trust-boundary bug with cache poisoning across the fork↔base boundary and in-memory OIDC token extraction — cache poisoning was one link in a multi-stage chain, not by itself the full root cause, so this should be read as corroborating evidence for the CREEP-class failure mode at higher severity, not as an independent second incident. [github-actions-cache-poisoning-hive]
- No source found in this pass documents a *test-impact-analysis* (as opposed to build-cache) case where a shipped defect is directly, publicly attributed to a skipped-test decision at a named company with a public postmortem — the Microsoft/Google material found describes the documented *failure modes* (silent zero-test-execution passing a build, TIA/coverage collector silently degrading) rather than a named production incident with a root-cause writeup. **This is a real evidence gap**: the mechanism for TIA-caused escapes is well-documented (silent selection-infrastructure failure while the pipeline still reports green), but a citable "TIA skipped the test that would have caught this shipped bug" postmortem was not found in this search pass.

## SOURCES

**bazel-hermeticity**
URL: https://bazel.build/basics/hermeticity (site/docs/hermeticity.md)
Accessed: 2026-09-01
Quote: "Common sources of non-hermeticity include actions or tooling that create files non-deterministically, usually involving build IDs or timestamps, system binaries that differ across hosts, and writing to the source tree during the build."

**bazel-cache-debug**
URL: https://bazel.build/remote/cache-remote
Accessed: 2026-09-01
Quote: "something non-hermetic in the build causing the actions to receive different action keys across the two runs" / execution logs cover "both the inputs (not only files, but also command line arguments, environment variables, etc) and the outputs of the action"

**bazel-issue-26657**
URL: https://github.com/bazelbuild/bazel/issues/26657
Accessed: 2026-09-01
Quote: "changing remote_cache should invalidate remote files in action cache" — Bazel's persistent local compact action cache is reused across a remote-cache-endpoint switch, producing "Missing digest" errors.

**turborepo-env-modes**
URL: https://turbo.build/repo/docs/crafting-your-repository/caching ; https://computingforgeeks.com/turborepo-cache-misses-environment-variables/
Accessed: 2026-09-01
Quote: "'strict' filters env vars to only those specified in the env and globalEnv keys in turbo.json, while 'loose' allows all environment variables for the process to be available."

**turborepo-issue-11216**
URL: https://github.com/vercel/turborepo/issues/11216
Accessed: 2026-09-01
Quote: "Turbo Cache hit miss even though same code same hash for builds when given output standalone in next.config.ts" — cache writes fail silently on long symlink paths under Next.js `output: "standalone"`.

**nx-creep-cve**
URL: (CVE-2025-36852, "CREEP") — coverage via Turborepo/Nx cache-security search results, 2026
Accessed: 2026-09-01
Quote: "CVE-2025-36852 (CREEP) showed how remote caches without branch isolation, where the first run to populate a key wins, let a contributor with PR access poison artifacts that protected branches later reuse."

**google-tap-paper**
URL: https://research.google.com/pubs/archive/45861.pdf ("Taming Google-Scale Continuous Testing", Memon & Gao)
Accessed: 2026-09-01
Quote: "7.4% of tests were SKIPPED, and less than 0.5% FAILED" / "executed only 61% and 50% of test targets with MinDist=10 and MinDist=6, respectively"

**google-flaky-tests-blog**
URL: https://testing.googleblog.com/2016/05/flaky-tests-at-google-and-how-we.html
Accessed: 2026-09-01
Quote: "about 1.5% of test runs produce inconsistent or 'flaky' results" / affecting "nearly 16% of their tests."

**ms-tia-docs**
URL: https://learn.microsoft.com/en-us/azure/devops/pipelines/test/test-impact-analysis?view=azure-devops
Accessed: 2026-09-01
Quote: "Safe fallback. For commits and scenarios that TIA can't understand, it falls back to running all tests." / "Run TIA selected tests and then all tests in sequence... If T1 passes, check that T2 passes as well."

**do178c-vector-whitepaper**
URL: https://cdn.vector.com/cms/content/know-how/aerospace/Documents/Complete_Verification_and_Validation_for_DO-178C.pdf
Accessed: 2026-09-01
Quote: "any version of released DO-178C-compliant software must be able to be recreated and retested in its entirety for 30 years after delivery."

**do178c-tool-qualification**
URL: RTCA DO-178C Section 12.2.1 (via search-result summary of practitioner guidance)
Accessed: 2026-09-01
Quote: "any tool that eliminates, reduces or automates any of the processes outlined within RTCA DO-178C without its output being verified as specified in RTCA DO-178C Section 6, must be qualified."

**iec62304-soup-wikipedia**
URL: https://en.wikipedia.org/wiki/Software_of_unknown_pedigree
Accessed: 2026-09-01
Quote: "a risk assessment must be made about any missing evidence from the development of the software, with a decision made about remediation."

**iec62304-edition2-intuitionlabs**
URL: https://intuitionlabs.ai/articles/iec-62304-edition-2-medical-software-changes
Accessed: 2026-09-01
Quote: "manufacturers should review their change-control SOPs to ensure software change control identifies whether a change is a development revision or routine maintenance, since test cases, retesting scope, and documentation checklists may differ accordingly."

**slsa-in-toto-blog**
URL: https://slsa.dev/blog/2023/05/in-toto-and-slsa
Accessed: 2026-09-01
Quote: "SLSA provenance is expressed as an in-toto attestation."

**in-toto-test-result-predicate**
URL: https://www.legitsecurity.com/blog/slsa-provenance-blog-series-part-2-deeper-dive-into-slsa-provenance
Accessed: 2026-09-01
Quote: "the test-result predicate can be used to verify the compliance of the artifact against a company Quality Gate — for example, that all automated tests passed and none were skipped."

**pgtestdb-brandur**
URL: https://brandur.org/fragments/pgtestdb
Accessed: 2026-09-01
Quote: "pgtestdb clone: 466 tests, 98.4ms mean, 247.4ms p90, 299.5ms p95, 465.1ms max"

**integresql-github**
URL: https://github.com/allaboutapps/integresql
Accessed: 2026-09-01
Quote: template warm-up (truncate/migrate/seed) is the slow part; pool hand-off measured "avg=11ms min=1ms max=445ms."

**qaskills-testcontainers**
URL: https://qaskills.sh/blog/testcontainers-postgres-per-test-database
Accessed: 2026-09-01
Quote: "transaction rollback is fast but fails when application code opens another connection or commits independently; schema-per-test separates object names but requires every query and tool to honor search_path; database-per-test provides a broad boundary while sharing one server process."

**github-actions-cache-poisoning-hive**
URL: https://hivesecurity.gitlab.io/blog/github-actions-cache-poisoning-supply-chain/
Accessed: 2026-09-01
Quote: "GitHub Actions caches are shared between pull request workflows and release workflows, creating an exploitable trust boundary" — TanStack incident, 42 packages, 84 malicious versions published.

**related-test-selection-corpus-entry**
URL: file:///home/tnunamak/code/dotfiles/ai/research/testing/related-test-selection-for-pdpp-2026-08-29.md
Accessed: 2026-09-01

## SYNTHESIS

### ANSWER — what's safe for a certification gate, what needs a paired full-run cadence, what's unsafe

**Safe to rely on directly, evidence is solid:**

- **Content-addressed database-template cloning** (Postgres `CREATE DATABASE ... TEMPLATE`, via `pgtestdb`/`IntegreSQL`-style pooling) for eliminating per-test provisioning cost. This is not really "caching a test result" — it's caching *setup*, not *verdict* — so it carries none of the certification risk of the other techniques here. Measured marginal cost is 10–100ms/test once the template is warm. Use freely; there is no adversarial-review exposure because the actual test logic still executes fresh against a real, isolated database every time.
- **SLSA/in-toto signed test-result attestations** as the *format* for stating reuse. The framework already has the right shape for the crux question: bind the result to the exact artifact digest, sign it, and let the predicate schema declare explicitly whether anything was skipped. If cached test evidence is going to be presented for certification, present it as a signed attestation naming the artifact hash and the skip/no-skip state — not as a green checkmark in a CI UI. This is the one piece of infrastructure in this survey purpose-built for exactly the "defensible under adversarial review" bar the task asks about.

**Usable, but only paired with a periodic full-run cadence and an explicit conservative fallback:**

- **Content-hash build/task caching (Bazel, Turborepo, Nx, Gradle-class).** The cache key mechanism is sound in principle — Bazel's is the most rigorous (declared inputs + env + flags, with tooling to diff two action logs when a mismatch is suspected) — but every real-world failure found in this pass is the same shape: an input that actually affected output was not part of the declared key (Turborepo loose-mode env vars, Bazel's local action-cache surviving a remote-backend switch), or the cache store itself had no identity/trust binding (CREEP/CVE-2025-36852, first-write-wins). None of these are "the hashing math is wrong" — they are all "the key didn't cover everything that mattered," which is undetectable from inside the caching system itself. Certification use requires: (a) a sandboxed or strict-mode runner (Nx's model, not Turborepo's default) that can prove no undeclared read/write occurred, and (b) a genuinely periodic (not "eventually," a scheduled) full uncached run whose result is diffed against the cached-path result, mirroring exactly what Microsoft's TIA docs recommend as the trust-establishment method for test selection.
- **Test-impact analysis (Google TAP-style, Microsoft TIA).** Both vendors' own published practice already assumes a full-run safety net is mandatory, not optional: Google pairs selection with heavy flake-detection investment (1.5% of runs, 16% of tests affected — without addressing that, "skipped vs. flaky-and-ignored" are indistinguishable); Microsoft's docs literally recommend running the full suite in parallel and diffing against the selected-subset result as the way to *establish trust* in the selector, and name a "safe fallback to full run on unrecognized file type" as core to the design, not a defensive add-on. Google's ~7.4% skip rate with <0.5% overall failure rate is the empirical case *for* selection at that scale — but note this is Google's own risk tolerance for its own product surface, not a certification standard's risk tolerance; nothing in DO-178C or IEC 62304 text found in this pass endorses that trade at face value.

**Unsafe outright, or evidence says "don't claim this":**

- **Treating a static-import-graph test selector's "no related tests found" as proof of no impact**, in any codebase with dynamic imports, reflection, or fixture-file reads — already established in the companion entry [related-test-selection-corpus-entry], and directly corroborated here by the Playwright-class fixture-collapse failure mode: a static graph is a *strictly weaker* guarantee than an execution-observed read-set, and none of the tools surveyed there or here (Jest, Vitest, Playwright, Bazel, Turborepo, Nx) actually track execution-observed reads by default — only Nx's opt-in sandboxed strict mode gets close.
- **Presenting a cached CI green as certification evidence without stating what it was cached against.** DO-178C's own text is explicit that presence of evidence isn't sufficiency of evidence — a cached pass from a build against a different compiler/target/toolchain version is not creditable evidence for the artifact under certification now, full stop, regardless of hash match. Any certification packet that reuses cached evidence must state the exact artifact digest, environment/toolchain identity, and reuse justification per that specific standard's change-classification rules — which is precisely what an in-toto test-result attestation is structured to carry and a bare "cache hit ✓" in a CI log is not.
- **Trusting a shared, unauthenticated remote cache across a trust boundary** (PR-triggered builds writing to the same cache namespace a protected-branch/release build reads from) is a proven, CVE'd vulnerability class (CREEP), not a theoretical risk — this is the sharpest concrete "don't" in this survey.

**Where the evidence is genuinely thin (don't overstate):**

- **IEC 62304's current (Edition 1) text does not, as far as this search found, contain a citable clause authorizing reduced-retest-scope credit for a cached/selected result** — the practitioner literature describes Edition 2 (targeted ~2027) as *introducing* change-classification-based retest-scope reduction, which reads as an implicit admission that Edition 1 doesn't yet formally sanction it. Treat risk-based retest-scope reduction under current IEC 62304 as a practitioner convention riding on top of the standard, defensible via a documented risk assessment, not as standard-mandated practice.
- **No named-company, public-postmortem case was found in this pass of a test-impact-analysis (as distinct from build-cache) decision directly causing a shipped defect.** The failure *mechanisms* are well-documented (TIA/coverage collector silently degrading while the pipeline still reports green; zero-tests-executed passing silently) — but a citable "here is the CVE/incident where TIA skipped exactly the test that would have caught this" writeup was not found. This is worth flagging honestly rather than asserting a stronger anti-pattern claim than the sources support.
