---
title: "A standing code-quality discovery layer ranks an open-ended defect inventory by ACTIONABILITY and CHANGE-WEIGHTED IMPACT (churn×complexity), not by raw finding count; the system lives or dies on its effective-false-positive rate (<10–30% trust cliff) and on reporting findings at diff/change time rather than as a batch dashboard"
date: 2026-06-29
topic: code-quality
tags: [static-analysis, defect-discovery, prioritization, false-positives, hotspots, churn-complexity, mutation-testing, dead-code, dependency-cycles, scanner, diff-time, quality-gate]
status: draft
sources: [google-tricorder-icse2015, google-cacm-2018, coverity-bessey-cacm2010, meta-infer-cacm2019, meta-zoncolan, meta-pysa, meta-getafix, meta-sapfix, sonar-cleancode, sonar-waterleak, sonar-metric-defs, campbell-cognitive-complexity, codeclimate-10point, codeclimate-churn-complexity, qlty-metrics, codescene-prioritize-impact, codescene-code-health, codescene-hotspots-defects, tornhill-crime-scene, knip, ts-prune-archived, dependency-cruiser, madge, jscpd, pmd-cpd, eslint-complexity, sonarjs-cognitive, type-coverage, ts-eslint-no-unsafe, stryker-docs, stryker-incremental, biome, kremenek-zranking, ruthruff-actionable, heckman-williams-review, ml-actionable-survey, scaife-sei]
source_session: 019d4ec9-773e-7c41-9f15-4f1c30e6fb2b
---

<!--
Format reminder (see README.md): CLAIMS = verifiable, each tagged [slug]. SOURCES = URL + accessed + quote. SYNTHESIS = interpretation, no citations.
Some CACM article HTML pages (Meta 2019, Google 2018) are paywalled / 403 to the fetcher; verified text came from first-party PDF mirrors (MIT/UMD course pages) and the abseil.io SWE-book, which carry the same material. Provenance noted per source.
-->

## CLAIMS

### False-positive control is THE central design constraint (the trust cliff)

- Google's Tricorder enforces a hard ceiling of **<10% effective false positives** for analyses surfaced at code-review time; an analyzer above this is put "on probation," and above 25% "we may decide to turn the analyzer off immediately." [google-tricorder-icse2015]
- The operative definition is the developer's, not the tool author's: "We define an effective false positive as any report from the tool where a user chooses not to take action to resolve the report." A technically-correct finding nobody acts on is, for trust purposes, a false positive. [google-tricorder-icse2015]
- Tricorder measures the live "not-useful rate" = `NOTUSEFUL / (NOTUSEFUL + PLEASEFIX + APPLYFIX)` from per-finding feedback buttons; across all analyzers it ran ~5% in recent months, ~4% with probationary analyzers removed. A spike from one analyzer bug was visible week-over-week and forced a fix. [google-tricorder-icse2015]
- Tricorder's compile-time/build-breaking checks are a stricter tier: their "effective false positive rate must be essentially zero" — only correctness checks, never style, get to break the build. [google-tricorder-icse2015]
- The Coverity team independently found the trust cliff at a higher number: "False positives do matter. In our experience, more than 30% easily cause problems," triggering a "vicious cycle" where "low trust causes complex bugs to be labeled false positives, leading to yet lower trust." Tricorder's footnote explicitly notes its 10% threshold "matches that used by other analysis platforms such as Coverity." [coverity-bessey-cacm2010] [google-tricorder-icse2015]
- Google's earlier FindBugs deployments failed on delivery model, not analysis quality: a central dashboard "few of them actually" visited; a bug-filing approach where "84% of bugs were not fixed"; per-developer warning customization that "killed it off." [google-cacm-2018]

### Delivery timing/scope (diff-time, new-code-only) dominates analyzer cleverness

- Meta's central finding: the *same* Infer analysis at the *same* false-positive rate got a "0% fix rate" deployed as a nightly batch bug-list, and "over 70%" deployed at diff (code-review) time. "The same program analysis, with same false positive rate, had much greater impact when deployed at diff time." [meta-infer-cacm2019]
- The batch failure was not precision: "We had worked hard to get the false positive rate down to what we thought was less than 20%, and yet the fix rate... was near zero." Diff-time deployment solves the "context switch" problem (the bot comments in code review) and the "relevance" problem. [meta-infer-cacm2019]
- Infer at diff time "in the default mode used most often... reports only regressions: new issues introduced by a diff," with a 15–20 min turnaround target (whole-program runs over an hour are "too slow for diff-time"). [meta-infer-cacm2019]
- Meta downgrades the false-positive *rate* itself as a hard-to-measure metric for a large, fast-changing codebase, tracking observed *action rate* and missed bugs instead. [meta-infer-cacm2019]
- Tricorder reaches the same conclusion from the other direction: "when developers have to navigate to a dashboard or run a standalone command line tool, analysis usage drops off"; its "primary use is to provide analysis results at code review time," with peer accountability, and it displays results "on changed lines by default." [google-tricorder-icse2015]
- SonarQube institutionalizes the pattern as "Clean as You Code" / the "water leak" model: "Plug the leak, or mop the floor?" — gate quality on NEW code only so debt stops growing, rather than trying to remediate the whole legacy backlog. Adding overall/legacy conditions to the gate "will shift your focus away from new code to old code." [sonar-waterleak] [sonar-cleancode]
- This is the convergent, cross-org principle: report findings at diff/change time, scoped to new or changed code, with a low effective-FP rate and fast turnaround — never as a batch dashboard or whole-repo bug queue. Google (review-time, changed-lines), Meta (diff-time regressions only), Sonar (gate new code) all land here independently. [google-tricorder-icse2015] [meta-infer-cacm2019] [sonar-cleancode]

### Prioritization by change-weighted impact (hotspots = churn × complexity)

- CodeScene's behavioral code analysis ranks refactoring targets by combining a complexity/code-health metric with change frequency mined from version control ("number of commits"): "Hotspots are complicated code that we have to work with often." [codescene-prioritize-impact]
- Change frequency is power-law / Pareto distributed: "most development activity is in a small part of the codebase." This is what makes prioritization tractable — a small set of files absorbs most edits. [codescene-prioritize-impact]
- The method directly counters the naive "god-files are bad" view: low-code-health code that is rarely edited is low priority. CodeScene's PowerShell example: two low-health modules "had one or two commits... over the past year. Hence, it's technical debt (low code health) but also with low interest (change frequency)" — "we don't need to pay down all technical debt." Refactoring untouched bad code is "a wasted opportunity." [codescene-prioritize-impact]
- Hotspots concentrate defects: a CodeScene case study reports "23% of all bugs that we detect and fix are in that small part of the code" (hotspots = 5.5% of the codebase), and "In most codebases, the top hotspots will be responsible for an even larger percentage of all fixed defects." [codescene-hotspots-defects]
- "There's a strong correlation between Hotspots, maintenance costs and software defects" — the summary of the research in Tornhill's *Your Code as a Crime Scene* (2015). [codescene-hotspots-defects] [tornhill-crime-scene]
- CodeScene's Code Health metric is scored 10 (healthy) → 1 (severe issues) from code properties (Brain Methods, DRY violations) plus organizational factors (Developer Congestion, Knowledge Distribution), normalized against real-world baselines, "chosen based on research, and known to correlate with increased maintenance costs and the risk for defects." Combining hotspots with code health "limits false positives to what's actionable." [codescene-code-health]
- Code Climate (now Qlty) shipped the same churn-vs-complexity quadrant: high-complexity + high-churn classes are "good top priorities for refactoring because their maintainability issues are impacting the developers on a regular basis." The lineage is Michael Feathers' "Getting Empirical about Refactoring" and the `turbulence` tool. [codeclimate-churn-complexity]

### Technical-debt scoring models (how findings roll up to a gate)

- SonarQube's Technical Debt Ratio (SQALE) = remediation cost / development cost, where development cost = `0.06 days` per line; the Maintainability Rating maps the ratio to letters: "A=0-0.05, B=0.06-0.1, C=0.11-0.20, D=0.21-0.5, E=0.51-1" (A ≤5%, E >50%). Maintainability is ratio-based; Reliability and Security ratings are driven by the single worst issue (one Blocker ⇒ E). [sonar-metric-defs]
- Code Climate / Qlty estimates per-issue "remediation time," sums it to a debt ratio, and maps to A–F: "A <5%, B 5–10%, C 10–20%, D 20–50%, F ≥50%." Its ten maintainability checks (argument count, complex boolean logic, file length, duplication, method count/length, nested control flow, return statements, similar blocks, method complexity) are deliberately paired (duplication vs complexity) to resist gaming. [codeclimate-10point] [qlty-metrics]
- Both Sonar and Code Climate/Qlty use **cognitive** complexity (read-difficulty), not just cyclomatic (test-difficulty), as the per-unit complexity signal. [qlty-metrics] [sonar-metric-defs]

### Cognitive complexity is a better readability signal than cyclomatic

- Cyclomatic complexity "excels at measuring [testability]" but "its underlying mathematical model is unsatisfactory at producing a value that measures the [understandability]": every method gets a mandatory +1 baseline, and it over-counts `switch` (+1 per case). [campbell-cognitive-complexity]
- Concrete proof: a nested-loop method and a flat 4-case `switch` both score cyclomatic 4 despite being "strikingly different in terms of understandability"; under Cognitive Complexity they score 7 vs 1. [campbell-cognitive-complexity]
- Cognitive Complexity's three rules: (1) ignore structures that shorthand multiple statements into one; (2) increment for each break in linear flow; (3) increment (extra) when flow-breaking structures are nested. A whole `switch` is one increment; runs of like `&&`/`||` count once. [campbell-cognitive-complexity]

### The inventory: which scanners are cheap-deterministic vs expensive

- **Dead code / unused exports — knip** is the current canonical tool; both predecessors are retired and redirect to it: ts-prune is a "Public archive" in "maintenance mode" recommending knip; unimported is "no longer maintained." Knip seeds the import graph from entry files + framework plugins; FP risk MEDIUM from anything reachable only dynamically (dynamic `import()`, framework entrypoints, DI, reflection), suppressed via `@public`/entry config. Cheap-deterministic, run every CI run. [knip] [ts-prune-archived]
- **Dependency cycles — dependency-cruiser** for the CI gate (LOW FP): its `no-circular` rule is `{ to: { circular: true } }`, type-only (`import type`) cycles are excluded by default, and `dynamic-import` is a distinguishable dependency type. **madge** is HIGH FP on TypeScript because `import type` phantom cycles are counted by default (`skipTypeImports` fails on namespace imports). Both cheap-deterministic. [dependency-cruiser] [madge]
- **Duplication — jscpd** (Rabin-Karp token clones; defaults `minTokens: 50`, suppress with `jscpd:ignore-start/end`) and **PMD CPD** (Karp-Rabin, `CPD-OFF/CPD-ON` markers). MEDIUM FP: token-identity ≠ semantic duplication (generated code, boilerplate). Cheap-deterministic. [jscpd] [pmd-cpd]
- **Complexity — `sonarjs/cognitive-complexity`** ESLint rule (default max 15) is preferred over ESLint's cyclomatic `complexity` rule (default max 20) and the stale standalone libs (typhonjs-escomplex, ts-complex). LOW–MED FP for cognitive, MED–HIGH for cyclomatic. Cheap-deterministic, runs in the existing ESLint pipeline. [sonarjs-cognitive] [eslint-complexity] [campbell-cognitive-complexity]
- **Type-safety holes — TS `strict` + type-coverage** (`coverage = non-any identifiers / total`, `--at-least N` gate) **+ typescript-eslint `no-unsafe-*`** family (catches `any` leakage at assignment/call/member/return/argument; `ban-ts-comment` governs `@ts-ignore`/`@ts-expect-error`). LOW FP (type-aware). Cheap-deterministic (one type-check pass; slower than syntactic lint). [type-coverage] [ts-eslint-no-unsafe]
- **Test quality — StrykerJS mutation testing** is the sole EXPENSIVE / sample-and-triage tool and the highest-value blind spot. Default `coverageAnalysis: "off"` runs *all tests per mutant* (cost ≈ #mutants × suite runtime); `perTest` + `--incremental` (re-run only changed code) are the cost controls. A *survived* mutant means a line is covered yet the suite fails to catch an injected defect — the only signal that measures assertion strength, which line coverage cannot. Default thresholds `{high: 80, low: 60, break: null}`. FP risk MED–HIGH from equivalent mutants (no test can ever kill them); requires human/judge triage. [stryker-docs] [stryker-incremental]
- **Lint / correctness baseline — ESLint / typescript-eslint / Biome** (Biome is Rust, ~35× faster than Prettier). LOW FP for correctness rules. Cheap-deterministic, every run. [biome]

### Prefilter → judge: reserve expensive adjudication for genuine ambiguity

- The actionable-alert-identification literature is decades deep: Kremenek & Engler's Z-ranking (SAS 2003) used statistics to rank alerts and counter analysis approximations; Ruthruff et al. (ICSE 2008, at Google) built a model "more than 70% accurate in identifying actionable alerts"; Heckman & Williams (2011) systematically reviewed actionable-alert-identification techniques. [kremenek-zranking] [ruthruff-actionable] [heckman-williams-review]
- The modern framing: classify each finding actionable vs unactionable from code-pattern features, then "strategically prioritiz[e] alerts for examination" using classifier confidence; an ML survey (2023) catalogs the full "actionable warning identification" space. CMU SEI's SCAIFE architecture fuses multiple tools' alerts + code metrics + archived human audit determinations to classify and rank, targeting a 50% reduction in alerts needing human adjudication. [ml-actionable-survey] [scaife-sei]

### Automated repair sits behind a human/test gate (the discovery-layer endgame)

- Meta's Getafix "learns fix patterns from past, human-written fixes to produce human-like fixes" via hierarchical clustering of fix patterns + context-aware ranking, feeding Infer and SapFix. [meta-getafix]
- SapFix was "the first such use of AI-powered testing and debugging tools in production at this scale," yet kept a human gate: "SapFix can't implement its own proposed fixes. Engineers are always in the loop." [meta-sapfix]
- Meta's taint analyzers route by signal-to-noise: Zoncolan (Hack/PHP, whole codebase <30 min, "43.3% of the severe security bugs" found via it, ~80% action rate) and Pysa (Python, ~1 hr) send results "either directly to the developer or to security engineers, depending on... the signal-to-noise ratio." Security tolerates higher FP rates than crash/perf analyses. [meta-zoncolan] [meta-pysa]

## SOURCES

**google-tricorder-icse2015**
URL: https://www.cs.umd.edu/class/spring2019/cmsc414/papers/tricorder-building-a-program-analysis-ecosystem.pdf (UMD course mirror of Sadowski, van Gogh, Jaspan, Söderberg, Winter, "Tricorder: Building a Program Analysis Ecosystem," ICSE 2015, pp. 598–608)
Accessed: 2026-06-29
Quote: "We define an effective false positive as any report from the tool where a user chooses not to take action to resolve the report." / "We still enforce a very low effective false positive rate here (< 10%). Additionally, we only display results for most analyses on changed lines by default." / "5 This 10% false positive threshold matches that used by other analysis platforms such as Coverity [13]." / "the not-useful rate of an analyzer as: NOTUSEFUL/(NOTUSEFUL + PLEASEFIX + APPLYFIX)" / "...lyzer on probation, and the analysis writer must show progress... If the rate goes above 25%, we may decide to turn the analyzer off immediately." / "when developers have to navigate to a dashboard or run a standalone command line tool, analysis usage drops off." / "TRICORDER... generates some 93,000 analysis results each day. A small team of 2-3 people maintain TRICORDER."
Note: Verified verbatim via pdftotext on the fetched PDF. The cacm.acm.org / dl.acm.org HTML pages 403 to the fetcher.

**google-cacm-2018**
URL: https://cacm.acm.org/research/lessons-from-building-static-analysis-tools-at-google/ (Sadowski, Aftandilian, Eagle, Miller-Cushon, Jaspan, CACM 61(4), Apr 2018, pp. 58–66; also DOI 10.1145/3188720)
Accessed: 2026-06-29
Quote (via web search summary + abseil.io SWE-book ch.20 corroboration): "to a tool user, a false positive report is any report that they did not want to see" / dashboard "few of them actually" visited / "84% of bugs were not fixed" (bug-filing approach) / "Not useful" button, ~250 clicks/day, false-positive rate continuously monitored / "Breaking the build is a warning that is not possible to ignore."
Note: CACM HTML 403 to the fetcher; the load-bearing identical material (<10% rule, not-useful loop, definition) is verified verbatim from the Tricorder ICSE 2015 PDF above. The 84% figure is from the CACM paper via secondary summary (moderate confidence). SWE-book ch.20: https://abseil.io/resources/swe-book/html/ch20.html

**coverity-bessey-cacm2010**
URL: https://cacm.acm.org/research/a-few-billion-lines-of-code-later/ (Bessey et al., "A Few Billion Lines of Code Later," CACM 53(2), 2010; DOI 10.1145/1646353.1646374)
Accessed: 2026-06-29
Quote (via web search summary): "False positives do matter. In our experience, more than 30% easily cause problems." / "a vicious cycle starts where low trust causes complex bugs to be labeled false positives, leading to yet lower trust."
Note: Quotes from search-engine extraction of the CACM page; HTML 403 to the fetcher. The 30% figure is widely cited and corroborated by CMU SEI commentary.

**meta-infer-cacm2019**
URL: https://6826.csail.mit.edu/2020/papers/facebook-infer-cacm.pdf (MIT course mirror of Distefano, Fähndrich, Logozzo, O'Hearn, "Scaling Static Analyses at Facebook," CACM 62(8), Aug 2019, pp. 62–70; DOI 10.1145/3338112)
Accessed: 2026-06-29
Quote: "we recount a striking situation where the diff time deployment saw a 70% fix rate, where a more traditional 'offline' or 'batch' deployment... saw a 0% fix rate." / "We had worked hard to get the false positive rate down to what we thought was less than 20%, and yet the fix rate... was near zero... we switched Infer on at diff time... the fix rate rocketed to over 70%. The same program analysis, with same false positive rate, had much greater impact when deployed at diff time." / "In the default mode used most often it reports only regressions: new issues introduced by a diff."
Note: Verified from the MIT course PDF mirror; CACM/dl.acm.org HTML 403. Verified by a delegated research agent this session.

**meta-zoncolan**
URL: https://engineering.fb.com/2019/08/15/security/zoncolan/
Accessed: 2026-06-29
Quote: whole codebase (>100M LOC Hack) analyzed in <30 min; in 2018 "helped find and triage more than 1,100 security issues"; new rules vetted then "promoted to the main rule list... run on every code change." CACM Infer paper: "43.3% of the severe security bugs are detected via Zoncolan."

**meta-pysa**
URL: https://engineering.fb.com/2020/08/07/security/pysa/
Accessed: 2026-06-29
Quote: source/sink taint model; "results go either directly to the developer or to security engineers, depending on... the signal-to-noise ratio." Detected 44% of issues engineers found in the Instagram server codebase in H1 2020; results in ~1 hour.

**meta-getafix**
URL: https://engineering.fb.com/2018/11/06/developer-tools/getafix-how-facebook-tools-learn-to-fix-bugs-automatically/ (+ arXiv:1902.06111, OOPSLA 2019)
Accessed: 2026-06-29
Quote: "Getafix is the first industrially-deployed automated bug-fixing tool that learns fix patterns from past, human-written fixes to produce human-like fixes." / "a novel hierarchical clustering algorithm that summarizes fix patterns into a hierarchy ranging from general to specific patterns."

**meta-sapfix**
URL: https://engineering.fb.com/2018/09/13/developer-tools/finding-and-fixing-software-bugs-automatically-with-sapfix-and-sapienz/
Accessed: 2026-06-29
Quote: "the first such use of AI-powered testing and debugging tools in production at this scale." / "SapFix can't implement its own proposed fixes. Engineers are always in the loop."

**sonar-waterleak**
URL: https://www.sonarsource.com/blog/water-leak-changes-the-game-for-technical-debt-management/ (Olivier Gaudin, 2015-07-03)
Accessed: 2026-06-29
Quote: "When you have water leak at home, what do you do first? Plug the leak, or mop the floor?" / "Fixing the leak means putting the focus on the 'new' code, i.e. the code that was added or changed."

**sonar-cleancode**
URL: https://docs.sonarsource.com/sonarqube-server/9.9/user-guide/clean-as-you-code
Accessed: 2026-06-29
Quote: "By focusing on new code, you aren't responsible for anyone else's code. You own the quality and security of the code you are working on today." / adding overall-code conditions "will shift your focus away from new code to old code."

**sonar-metric-defs**
URL: https://docs.sonarsource.com/sonarqube-server/9.9/user-guide/metric-definitions
Accessed: 2026-06-29
Quote: Debt ratio = "Remediation cost / (Cost to develop 1 line of code * Number of lines of code)"; cost-to-develop constant "0.06 days"; Maintainability Rating "A=0-0.05, B=0.06-0.1, C=0.11-0.20, D=0.21-0.5, E=0.51-1." Reliability/Security ratings driven by the single worst issue.

**campbell-cognitive-complexity**
URL: https://www.sonarsource.com/docs/CognitiveComplexity.pdf (G. Ann Campbell, "Cognitive Complexity: a new way of measuring understandability," SonarSource, v1.7, 2023-08-29; peer-reviewed: TechDebt '18, ACM DOI 10.1145/3194164.3194186)
Accessed: 2026-06-29
Quote: "Cyclomatic Complexity... excels at measuring the [testability]... its underlying mathematical model is unsatisfactory at producing a value that measures the [understandability]." Three rules: "1. Ignore structures that allow multiple statements to be readably shorthanded into one 2. Increment (add one) for each break in the linear flow of the code 3. Increment when flow-breaking structures are nested." sumOfPrimes vs getWords: cyclomatic 4=4, cognitive 7 vs 1.

**codeclimate-10point**
URL: https://codeclimate.com/blog/10-point-technical-debt-assessment
Accessed: 2026-06-29
Quote: "For each issue, we estimate the amount of time it may take an engineer to resolve the problem. We call this remediation time... we simply map it onto a letter grade scale." / "applies the cognitive complexity algorithm." Ten maintainability checks listed (argument count, complex boolean logic, file length, identical/similar blocks, method count/length, nested control flow, return statements, method complexity).

**codeclimate-churn-complexity**
URL: https://codeclimate.com/blog/deciphering-ruby-code-metrics
Accessed: 2026-06-29
Quote: high-complexity + high-churn classes are "good top priorities for refactoring because their maintainability issues are impacting the developers on a regular basis." Lineage: Michael Feathers "Getting Empirical about Refactoring" + the `turbulence` tool.

**qlty-metrics**
URL: https://docs.qlty.sh/cloud/maintainability/metrics (+ https://docs.qlty.sh/complexity)
Accessed: 2026-06-29
Quote: project debt-ratio grades "A <5%, B 5–10%, C 10–20%, D 20–50%, F ≥50%." "Complexity (or cognitive complexity) is a measure of how difficult a unit of code is to intuitively understand."
Note: Code Climate Quality rebranded to Qlty Software (announced 2024-11-11); docs.codeclimate.com 301-redirects to docs.qlty.sh. Grades are A–F here (vs Sonar A–E).

**codescene-prioritize-impact**
URL: https://codescene.com/blog/prioritize-technical-debt-by-impact/
Accessed: 2026-06-29
Quote: "Hotspots are complicated code that we have to work with often." / "most development activity is in a small part of the codebase." / PowerShell cimSupport example: low-health modules with "one or two commits... over the past year. Hence, it's technical debt (low code health) but also with low interest (change frequency)." / "we don't need to pay down all technical debt."

**codescene-code-health**
URL: https://codescene.com/blog/measure-code-health-of-your-codebase
Accessed: 2026-06-29
Quote: "Code Health scale goes from 10, healthy code... down to 1, which indicates code with severe quality issues." / factors "Brain Methods, DRY violations, Developer Congestion, Knowledge Distribution" "known to correlate with increased maintenance costs and the risk for defects." / hotspots+health "limits false positives to what's actionable."

**codescene-hotspots-defects**
URL: https://docs.enterprise.codescene.io/versions/4.2.2/guides/technical/hotspots.html
Accessed: 2026-06-29
Quote: "There's a strong correlation between Hotspots, maintenance costs and software defects." / "23% of all bugs that we detect and fix are in that small part of the code" (hotspots = 5.5% of the codebase). / "In most codebases, the top hotspots will be responsible for an even larger percentage of all fixed defects."
Note: The widely-quoted "25–70% of defects" range is from Tornhill's books / research talks, not this doc; the verified concrete figure here is 23% of bugs in 5.5% of code.

**tornhill-crime-scene**
URL: https://pragprog.com/titles/atcrime2/your-code-as-a-crime-scene-second-edition/ (Adam Tornhill, *Your Code as a Crime Scene*, 2015 / 2nd ed.)
Accessed: 2026-06-29
Quote: (book) basis for behavioral code analysis; "Hotspots" = complexity × change-frequency from version control. Cited as the research source by CodeScene docs.
Note: Book itself not fetched; attribution corroborated by codescene docs above.

**knip**
URL: https://knip.dev/overview/getting-started (+ /explanations/plugins, /reference/jsdoc-tsdoc-tags)
Accessed: 2026-06-29
Quote: seeds from entry files + framework plugins; reports unreached files/exports/deps; suppress via `@public`/`@internal` JSDoc + entry config; docs warn "Avoid `ignore` patterns."

**ts-prune-archived**
URL: https://github.com/nadeesha/ts-prune (also https://github.com/smeijer/unimported)
Accessed: 2026-06-29
Quote: "Public archive" (archived 2025-09-19), "ts-prune is now in maintenance mode... For new projects, we recommend knip." unimported: "This project is no longer maintained. There's a project called knip which has more features."

**dependency-cruiser**
URL: https://github.com/sverweij/dependency-cruiser (+ doc/rules-reference.md, doc/options-reference.md)
Accessed: 2026-06-29
Quote: `no-circular` = `{ to: { circular: true } }`; type-only deps excluded by default (opt in `tsPreCompilationDeps: true`); `dynamic-import` is a distinguishable `dependencyType`.

**madge**
URL: https://github.com/pahen/madge (+ issue #232)
Accessed: 2026-06-29
Quote: `--circular` returns every module in a cycle; `import type` phantom cycles counted by default; `skipTypeImports` fails on `import * as X` namespace imports (issue #232).

**jscpd**
URL: https://github.com/kucherenko/jscpd
Accessed: 2026-06-29
Quote: Rabin-Karp token clones; defaults `minTokens: 50`, `minLines: 5`; suppress `jscpd:ignore-start`/`jscpd:ignore-end`.

**pmd-cpd**
URL: https://docs.pmd-code.org/latest/pmd_userdocs_cpd.html
Accessed: 2026-06-29
Quote: Karp-Rabin token comparison, language-agnostic (JS+TS one entry); `CPD-OFF`/`CPD-ON` markers; `--minimum-tokens` required, no core default (100 is the Maven-plugin default).

**eslint-complexity**
URL: https://eslint.org/docs/latest/rules/complexity
Accessed: 2026-06-29
Quote: measures cyclomatic complexity per function ("number of linearly independent paths"), errors above `max` (default 20).

**sonarjs-cognitive**
URL: https://github.com/SonarSource/eslint-plugin-sonarjs (docs/rules/cognitive-complexity.md)
Accessed: 2026-06-29
Quote: ESLint rule implementing SonarSource Cognitive Complexity; flags functions over configured max (default 15).

**type-coverage**
URL: https://github.com/plantain-00/type-coverage
Accessed: 2026-06-29
Quote: `coverage = (identifiers whose type is not any) / (total identifiers)`; `--at-least N` exits non-zero below threshold.

**ts-eslint-no-unsafe**
URL: https://typescript-eslint.io/rules/no-unsafe-assignment (+ no-unsafe-call/-member-access/-return/-argument, no-explicit-any, ban-ts-comment)
Accessed: 2026-06-29
Quote: type-aware rules catching `any` leakage at assignment/call/member-access/return/argument; `ban-ts-comment` governs `@ts-ignore`/`@ts-expect-error`.

**stryker-docs**
URL: https://stryker-mutator.io/docs/stryker-js/configuration/ (+ /docs/mutation-testing-elements/mutant-states-and-metrics/)
Accessed: 2026-06-29
Quote: default `coverageAnalysis: "off"` ⇒ "All tests are executed for each mutant"; `perTest` runs only covering tests; thresholds default `{ high: 80, low: 60, break: null }`; mutation score = detected/valid×100; a survived covered mutant = test gap.

**stryker-incremental**
URL: https://stryker-mutator.io/docs/stryker-js/incremental/
Accessed: 2026-06-29
Quote: `--incremental` re-runs mutation testing only on changed code, reusing prior results (docs example: reuse 3,731 of 3,965).

**biome**
URL: https://biomejs.dev
Accessed: 2026-06-29
Quote: Rust-based unified formatter+linter (JS/TS/JSX/JSON/CSS/GraphQL); benchmarked ~35× faster than Prettier.

**kremenek-zranking**
URL: https://web.stanford.edu/~engler/ (T. Kremenek & D. Engler, "Z-ranking: Using statistical analysis to counter the impact of static analysis approximations," SAS 2003)
Accessed: 2026-06-29
Quote: statistical ranking of alerts to counter static-analysis approximations; foundational actionable-alert ranking.
Note: Cited via web-search summary; canonical paper, not fetched first-party.

**ruthruff-actionable**
URL: https://dl.acm.org/doi/10.1145/1368088.1368135 (Ruthruff, Penix, Morgenthaler, Elbaum, Rothermel, "Predicting accurate and actionable static analysis warnings: an experimental approach," ICSE 2008)
Accessed: 2026-06-29
Quote: model "more than 70% accurate in identifying actionable alerts," in a case study at Google.
Note: Via web-search / SEI summary.

**heckman-williams-review**
URL: https://www.sciencedirect.com/science/article/abs/pii/S0950584910002235 (Heckman & Williams, "A systematic literature review of actionable alert identification techniques for automated static code analysis," IST 2011)
Accessed: 2026-06-29
Quote: systematic review of techniques for identifying actionable static-analysis alerts.
Note: Via web-search summary.

**ml-actionable-survey**
URL: https://arxiv.org/pdf/2312.00324 ("Machine Learning for Actionable Warning Identification: A Comprehensive Survey," 2023)
Accessed: 2026-06-29
Quote: catalogs ML approaches to distinguishing actionable vs unactionable static-analysis alerts and prioritizing by classifier confidence.

**scaife-sei**
URL: https://www.sei.cmu.edu/blog/prioritizing-alerts-from-static-analysis-to-find-and-fix-code-flaws/ (CMU SEI SCAIFE)
Accessed: 2026-06-29
Quote: SCAIFE = "an architecture for classifying and prioritizing static analysis alerts," fusing multiple tools' alerts + features + code metrics + archived human audit determinations; CI/CD project targets a 50% reduction in alerts needing human adjudication.

## SYNTHESIS

### The problem this answers

This entry is the DISCOVERY layer; it pairs with `code-quality/ungameable-quality-budget-and-prioritization-for-agent-pipelines.md` (the BUDGET layer) and does not overlap it. That entry settles *who* sets the budget and proves the agent must NOT derive it from its own discovery scoring (doing so relocates Goodhart into the scoring functions) — the budget must be fixed, human-anchored, outcome-based gates the agent cannot re-weight. This entry settles *how the scanner finds and ranks candidates within those fixed gates*: ranking here orders work, it does not author the budget. The ranked output of this pipeline is the input the budget layer constrains.

The system has a strong VERIFIER (gated maker → deterministic-oracle → different-model-judge that proves a fix is behavior-preserving and right-shaped). It lacks a SCANNER. Today discovery is a human pointing agents at a subsystem — lossy and forgetful. The question is how serious orgs run a *standing* discovery layer that regenerates the defect list every run without drowning in false positives. The literature gives a surprisingly unanimous answer, and it inverts the naive intuition: the hard problem is not running scanners, it is *delivery and ranking*. The same finding at the same precision is worthless or high-leverage depending entirely on *when/where* it surfaces and whether it's *ranked by who-will-act*.

### Three load-bearing findings (cross-org, convergent)

1. **The effective-false-positive rate is the master constraint, and "false positive" is defined by the developer, not the tool.** Google: <10% effective-FP or the analyzer goes on probation (>25% = killed), where an effective FP is *any finding nobody acts on* — even a technically-true one. Coverity: >30% triggers a trust death-spiral. This means our discovery layer must measure its *own* not-useful rate (the equivalent of Tricorder's NOTUSEFUL/(NOTUSEFUL+PLEASEFIX+APPLYFIX)) and treat a scanner that produces unactioned findings as broken, regardless of correctness.

2. **Delivery timing/scope dominates analyzer cleverness.** Meta's 0%→70% diff-time result is the single most important data point in this entire corpus: *the analysis didn't change, the deployment did.* Batch whole-repo bug-lists get ignored; findings scoped to *new/changed* code at review time get fixed. Google ("changed lines by default," review-time), Meta ("regressions only"), and Sonar ("Clean as You Code," gate new code) all converge. For us: the discovery layer should default to scoping findings to *what changed* and only periodically do a full-repo sweep — and the full-repo sweep's output must be *ranked*, never dumped.

3. **Rank by change-weighted impact, not raw count.** Tornhill/CodeScene's churn×complexity hotspot model is the answer to "what is worth fixing": a bad file nobody touches is low priority; a medium file edited daily is high. Codebases are power-law in change frequency, so a small hotspot set absorbs most edits and most defects (CodeScene: 23% of bugs in 5.5% of code). This directly refutes the "god-files are bad → list all god-files" naive scan. The ranking key is `severity × actionability × change-frequency`, with complexity measured *cognitively* (read-difficulty) not *cyclomatically* (test-difficulty).

### How the standing discovery layer SHOULD be designed for this system

A four-stage pipeline, regenerated every run:

**Stage 0 — CHEAP DETERMINISTIC SWEEP (run every time, all of it).** Six of the seven inventory classes are cheap and deterministic; run them unconditionally and cache: ESLint/typescript-eslint/Biome (correctness baseline), knip (dead code), dependency-cruiser (cycles — *not* madge; its TS phantom-cycle FP rate disqualifies it as a gate, consistent with this corpus's earlier "measure static cycles only" entry), jscpd (duplication), `sonarjs/cognitive-complexity` + churn (the hotspot inputs), and type-coverage + `no-unsafe-*` (type holes). These emit a raw findings list with deterministic locations and counts. This is the "objective facts from a deterministic script" principle the loop already uses for verification — applied to discovery.

**Stage 1 — CHANGE-WEIGHT & RANK (deterministic, no LLM).** Join every finding to git change-frequency for its file (the hotspot multiplier) and to a cognitive-complexity score. Rank by `actionability-prior × severity × change-frequency`. Default-scope to changed code (the diff-time lesson); the full-repo list is *ranked and truncated*, never enumerated. This stage is pure arithmetic — no model needed, and it's where most "noise" dies: a true-but-untouched-file finding sinks to the bottom on its own.

**Stage 2 — EXPENSIVE SAMPLE (mutation testing, triaged).** StrykerJS is the one expensive tool and the highest-value blind spot — line coverage proves a line *ran*, a survived mutant proves the test *wouldn't catch a regression*. Run it incrementally (`--incremental` + `perTest`) on *changed/hotspot* code only, never the whole repo every run. Surviving mutants are *nominations*, not verdicts (equivalent-mutant FP risk is real).

**Stage 3 — PREFILTER → JUDGE HANDOFF (reserve the model for ambiguity).** This is the bridge to the existing verifier. The cheap+ranked signals (Stages 0–2) *nominate*; the expensive different-model judge *adjudicates only the ambiguous top-of-rank*. The actionable-alert literature (Z-ranking → Ruthruff's 70%-accurate Google classifier → SCAIFE) is explicit that a confidence-ranked prefilter is what makes human/expensive adjudication affordable. The gate: the LLM judge is for *genuine ambiguity at the top of the ranked list* (is this hotspot's complexity incidental or essential? is this duplication semantic or coincidental? is this surviving mutant a real test gap or an equivalent mutant?), **never for enumeration**. Deterministic findings that are unambiguous (a static import cycle, a knip-confirmed unreachable export with no dynamic-import escape hatch) go straight to the maker without burning a judge call. Target ratio: the vast majority of findings resolved by deterministic rank + suppression; the model adjudicates only the small ambiguous head — the same economics SCAIFE targets (≈50% adjudication reduction is their *floor*; a deterministic prefilter should beat it).

### The false-positive budget as an explicit, self-monitored constraint

Borrow Tricorder's mechanism wholesale: the discovery layer must track its *own* effective-FP rate and treat a noisy scanner as disabled-by-default. Concretely — every nominated finding that the maker/judge declines (or that a human marks not-useful) increments a per-scanner not-useful counter; a scanner over the budget (Google's 10%; be stricter given we have no human warning-blindness to exploit) is auto-demoted to *advisory* (logged, not acted on) until its rule is tightened. This is the discovery-side analogue of the verifier's fail-closed gate: a scanner doesn't get to keep nominating work it can't justify. It also means new scanners are added on probation, exactly as Tricorder onboards analyzers — earn trust before gating.

### What this inverts vs the naive approach

The naive scanner enumerates every smell in the repo and hands over a 3,000-item list (Tornhill: "getting a list of 3,000 major issues won't help anyone"). The designed layer does the opposite: it *suppresses by default*, scopes to change, ranks by who-will-act-and-where-it-hurts, runs the one expensive high-value tool (mutation) only on hotspots, and spends model adjudication only on the ambiguous head. The maker's attention — the scarce resource per this corpus's OWN/RENT/DELETE objective — is steered to the churn×complexity hotspots where fixing pays the highest interest, not to the worst code nobody touches.

### Confidence / caveats

- The cross-org convergence (Google/Meta/Sonar on diff-time + FP-budget; CodeScene/Code Climate on churn×complexity) is strong and primary-source-verified. HIGH confidence.
- The exact FP-budget number for *our* system (10% vs 30% vs stricter) is a design choice, not a derived constant — the literature brackets it (Google 10%, Coverity 30%) but our context (no human warning-blindness, an LLM judge in the loop) likely warrants stricter. MEDIUM confidence on the specific number.
- The tool inventory's cost ratings (cheap vs expensive) are well-grounded for Stryker (verified all-tests-per-mutant default) but the static analyzers' "cheap" rating is reasoned from their algorithmic class, not benchmarked on PDPP specifically. Verify empirically before wiring into every-run CI.
- The "25–70% of defects in hotspots" figure attributed to Tornhill is from his books/talks; the verified primary CodeScene figure is 23% of bugs in 5.5% of code. Use the verified figure; treat the wider range as directional.
