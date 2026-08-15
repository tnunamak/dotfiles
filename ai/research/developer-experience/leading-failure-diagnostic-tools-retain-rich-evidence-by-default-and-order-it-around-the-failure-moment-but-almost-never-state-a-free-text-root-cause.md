---
title: "Leading failure-diagnostic tools retain rich evidence by default and order it around the failure moment, but almost never state a free-text root cause"
date: 2026-08-14
topic: developer-experience
tags: [error-ux, playwright, cypress, sentry, ci, diagnostics, connectors]
status: draft
sources: [playwright-trace-config, playwright-trace-viewer, playwright-retry-issue, cypress-screenshot-docs, ytdlp-issue-template, gallery-dl-troubleshooting, sentry-fingerprinting, sentry-grouping-critique, sentry-seer-ga, sentry-seer-limits, github-problem-matchers, gradle-build-scan, buildkite-test-engine, circleci-insights, mitmproxy-charles-gap, elm-error-design, rust-diagnostics-guide]
source_session: 1f934c1f-19c7-4d9d-9b1d-52f5e457e91e
---

## CLAIMS

- Playwright's scaffolded CI config sets `trace: 'on-first-retry'`, which records a trace only starting at retry 1 (not the original failing run), paired with `retries: 2` on CI / `0` locally — so trace capture requires retries to be enabled, and the most common reason teams see no trace in CI is retries left at 0. [playwright-trace-config][playwright-retry-issue]
- The community has an open feature request for an `on-first-failure` trace mode, distinct from `on-first-retry`, specifically because `on-first-retry` captures a reproduction of the retry, not a recording of the original failure. [playwright-retry-issue]
- Playwright's Trace Viewer shows, per action: an Errors tab with a red timeline marker at the failure point, before/action/after DOM snapshots per action (not just at failure), a Call tab (locator used, timing, strict-mode status, key used), and a Network tab filterable by type/status/method — all without needing to reproduce the failure locally. [playwright-trace-viewer]
- Playwright 1.60+ added `errorContext`, which attaches an aria (accessibility-tree) snapshot at the exact moment an `expect()` assertion fails, tying the assertion failure directly to DOM state rather than leaving the reader to cross-reference timestamps. [playwright-trace-viewer]
- `retain-on-failure` is Playwright's alternate default-config option cited for suites where "on-first-retry" is undesired: it discards traces for passing runs and keeps only the ones that actually failed, without requiring a retry to trigger capture. [playwright-trace-viewer]
- Cypress takes a screenshot automatically on failure by default during `cypress run` (CI mode), named with a `(failed)` suffix; this is opt-out (`screenshotOnRunFailure: false`), not opt-in. `cypress open` (interactive) does not auto-screenshot on failure. [cypress-screenshot-docs]
- Cypress records video by default for every `cypress run`, not just failures — coverage is broader than screenshots (video: all runs; screenshots: failed tests only) — and auto-compresses video afterward (default CRF 32). [cypress-screenshot-docs]
- Cypress's Command Log (time-travel DOM snapshots per command) is a separate mechanism from the screenshot/video capture, and there is a known timing race where the failure screenshot can be taken before the Command Log's async React render completes, so the screenshot alone can miss the visible error — video exists partly to cover this gap. [cypress-screenshot-docs]
- yt-dlp's issue template for "broken site" reports mandates verbose output via `yt-dlp -vU <command>` (or `verbose: True` for API users), pasted starting from `[debug] Command-line config`, and explicitly says this is required "unless absolutely impossible," with an explanation demanded if omitted. [ytdlp-issue-template]
- yt-dlp's template also requires reporters to have confirmed, as checklist items, that the URL plays in a browser with the same IP/login and that the tool was updated to nightly/master first — pre-filtering the two most common non-bug causes (stale extractor, geo/auth mismatch) before a human ever reads the report. [ytdlp-issue-template]
- gallery-dl's troubleshooting/report convention likewise centers on `--verbose` debug output plus the smallest reproducing command/URL, updating first (`gallery-dl -U`) since that alone resolves a reported majority of issues, and mandates redaction of cookies/tokens/private URLs/usernames before sharing logs. [gallery-dl-troubleshooting]
- Neither yt-dlp's nor gallery-dl's templates were found to include an automated classifier that states a probable cause (e.g., "this looks like a geo-block") in the tool's own output — the mandatory-verbose-log convention front-loads facts for a human triager rather than having the tool interpret them. [ytdlp-issue-template][gallery-dl-troubleshooting]
- Sentry's default error grouping/fingerprint is computed by hashing stack trace content (frames from node_modules/known libraries excluded), falling back to the raw message string when no stack trace exists — a mechanism Sentry's own docs describe as "a good out-of-the-box fingerprint for most errors, but not all of them." [sentry-fingerprinting]
- Real-world critiques document Sentry's default stack-trace grouping both over-merging (different HTTP error codes producing the same frontend stack trace, wrongly grouped as one issue) and over-splitting (the same logical error thrown from two call sites, wrongly split into two issues) — i.e., default grouping is evidence-correlation, not semantic understanding of "same root cause." [sentry-grouping-critique]
- Sentry's breadcrumb system auto-captures, by default, an ordered trail of navigation, fetch/XHR requests, DOM clicks, and console messages leading up to an error — explicitly framed by Sentry as the "what was the app doing before this" complement to the stack trace's "where in code." [sentry-fingerprinting via breadcrumb description]
- Sentry ships an explicit free-text root-cause feature (Seer/Autofix): as of its GA announcement it claims 94.5% accuracy identifying root causes and cites aggregate time saved, but Sentry's own blog documents a known failure mode (backend 500s reported from the frontend, where Autofix "wouldn't be able to figure out the issue on the backend") that was later mitigated only by adding distributed-tracing context, not by the model alone. [sentry-seer-ga][sentry-seer-limits]
- Sentry's public materials cite a Microsoft study finding that AI agents "excel at localizing, but fail to root cause, resulting in partial or flawed solutions," and position Seer's added runtime/trace context as addressing that specific gap rather than claiming immunity to it. [sentry-seer-limits]
- GitHub Actions "problem matchers" are declared regex-to-annotation mappings (JSON, registered via `::add-matcher::`) that a workflow author must supply per-tool (e.g., ESLint compact format); GitHub does not infer failure meaning — it only re-renders text a human already decided is important into the Annotations UI, capped at 10 errors/10 warnings/10 notices per step and 50 per run. [github-problem-matchers]
- Gradle Build Scan / Develocity's core "root cause" feature is a diff/comparison tool — comparing a failed build's task inputs, dependency tree, cache keys, and JDK version/vendor against the last green build — surfacing correlated deltas rather than asserting a cause in prose; a cited example is discovering two builds used different JDK vendors purely via the comparison view. [gradle-build-scan]
- Develocity's newer agent-facing materials describe an "unattended investigation loop" (pull a failing build, diff against last green, read the exact input that broke it) that is explicitly framed as consuming typed structured events (outcomes, cache keys, failure causes) rather than free text logs — a machine-consumable evidence layer, not a prose verdict for a human. [gradle-build-scan]
- Buildkite Test Engine's "flaky" classification is a single deterministic rule (same test, same commit SHA, both pass and fail results observed) — not inference — and drives further automated actions (auto-label, auto-notify, auto-quarantine, auto-unlabel once reliability recovers), i.e., automation is gated on an objective repeated-observation signal, not a guessed cause. [buildkite-test-engine]
- CircleCI's Test Insights uses the identical deterministic definition (pass+fail on the same commit within a 14-day window) to label tests FLAKY throughout its UI. [circleci-insights]
- mitmproxy has a documented gap versus Charles Proxy: when a TLS/TCP handshake fails before the HTTP layer completes (e.g., certificate pinning, network-level blocking), mitmproxy creates no "flow" object at all and the failure is invisible in its UI/log, whereas Charles surfaces such failed connection attempts as visible entries — i.e., a proxy's per-request evidence model can go completely silent exactly when the failure happens before the unit of capture (the "request") is considered to have started. [mitmproxy-charles-gap]
- Elm's compiler error design explicitly optimizes for a first-person, dialogic tone ("I see an error"), pairs a specific location/pinpoint with a concrete suggested fix, and includes short in-message language-concept explanations — described by its authors' own commentary as deliberately breaking the fourth wall to reduce the feeling of being alone with the error. [elm-error-design]
- Rust's compiler team treats "confusing error message" as a filable bug category and its dev-guide diagnostic conventions mandate: smallest-possible span highlighting, no duplicate messages for one underlying error, matter-of-fact tone, and an error-code system that links to long-form docs only when the extra explanation would add real information beyond the short message. [rust-diagnostics-guide]
- Rust's own documentation acknowledges a deliberate completeness tradeoff for trait-bound errors: including every contributing bound and its source location could stretch a single diagnostic past 100 lines, so heuristics selectively omit likely-irrelevant detail rather than dumping full provenance — i.e., even the most-cited "good error messages" precedent chooses curated brevity over exhaustive evidence. [rust-diagnostics-guide]

## SOURCES

**playwright-trace-config**
URL: https://playwright.dev/docs/test-configuration
Accessed: 2026-08-14
Quote: "Collect trace when retrying the failed test. trace: 'on-first-retry'"

**playwright-trace-viewer**
URL: https://playwright.dev/docs/trace-viewer
Accessed: 2026-08-14
Quote: "If your test fails you will see the error messages for each test in the Errors tab. The timeline will also show a red line highlighting where the error occurred." / "Traces are a great way for debugging your tests when they fail on CI."

**playwright-retry-issue**
URL: https://github.com/microsoft/playwright/issues/29531
Accessed: 2026-08-14
Quote: Paraphrase — feature request to "retain trace for first failure only, not including retries," on the grounds that on-first-retry traces a controlled reproduction (retry 1), not the original failing run.

**cypress-screenshot-docs**
URL: https://docs.cypress.io/api/commands/screenshot
Accessed: 2026-08-14
Quote: "Cypress automatically takes a screenshot when a test fails" (cypress run / CI mode); "the screenshot will be stored in the cypress/screenshots folder by default"; video "enabled by default... for all the test runs on CLI using cypress run."

**ytdlp-issue-template**
URL: https://github.com/yt-dlp/yt-dlp (broken-site issue template, referenced via commit 517ddf3 "Improve Issue/PR templates")
Accessed: 2026-08-14
Quote: "run the command with -vU flag added (yt-dlp -vU <your command line>) ... copy the WHOLE output" — mandatory unless "absolutely impossible to provide."

**gallery-dl-troubleshooting**
URL: https://gallery-dl.wiki/troubleshooting/
Accessed: 2026-08-14
Quote: Paraphrase — troubleshooting flow: update first (`gallery-dl -U`), reproduce with `--verbose` and smallest URL, redact cookies/tokens/private URLs/usernames before sharing.

**sentry-fingerprinting**
URL: https://docs.sentry.io/platforms/javascript/enriching-events/fingerprinting/
Accessed: 2026-08-14
Quote: "Sentry derives this fingerprint by concatenating and hashing the event's stack trace content" and "this strategy provides a good out-of-the-box fingerprint for most errors, but not all of them."

**sentry-grouping-critique**
URL: https://getdecipher.com/blog/the-hidden-costs-of-sentry-s-poor-error-grouping
Accessed: 2026-08-14
Quote: Paraphrase — API responses of 400 and 500 both resulting in the same frontend exception stack trace were grouped together incorrectly; a single exception raised from two different code locations was not grouped together.

**sentry-seer-ga**
URL: https://sentry.io/changelog/seer-sentrys-ai-debugger-is-generally-available
Accessed: 2026-08-14
Quote: "Seer identified root causes with 94.5% accuracy and saved development teams over 2 years in aggregate."

**sentry-seer-limits**
URL: https://blog.sentry.io/sentry-ai-debugger-autofix-superpower-traces/
Accessed: 2026-08-14
Quote: Paraphrase — Autofix "wouldn't be able to figure out the issue" for backend 500s reported from the frontend prior to adding distributed-tracing context; cites Microsoft study that AI agents "excel at localizing, but fail to root cause."

**github-problem-matchers**
URL: https://github.com/actions/toolkit/blob/main/docs/problem-matchers.md
Accessed: 2026-08-14
Quote: "Problem Matchers are a way to scan the output of actions for a specified regex pattern and surface that information prominently in the UI."

**gradle-build-scan**
URL: https://gradle.com/gradle-enterprise-solution-overview/build-scan-root-cause-analysis-data/
Accessed: 2026-08-14
Quote: Paraphrase — Build Scan Comparison shows differences in task inputs and dependency trees between a failed and a last-known-good build; example cited: comparison revealed the two builds used different JDK versions/vendors.

**buildkite-test-engine**
URL: https://buildkite.com/platform/test-engine/
Accessed: 2026-08-14
Quote: "tests are detected as flaky if they report both passed and failed results" on the same commit SHA.

**circleci-insights**
URL: https://circleci.com/docs/guides/insights/insights-tests/
Accessed: 2026-08-14
Quote: "flaky tests... are identified as tests that failed and passed on the same commit in a 14-day window."

**mitmproxy-charles-gap**
URL: https://github.com/mitmproxy/mitmproxy/issues/2843
Accessed: 2026-08-14
Quote: Paraphrase — a network failure visible in Charles produced no traffic/flow at all in mitmproxy, suspected certificate-pinning/handshake failure before the HTTP layer; reporter requested Charles-like visibility into failed (pre-HTTP) connections.

**elm-error-design**
URL: https://calebmer.com/2019/07/01/writing-good-compiler-error-messages.html
Accessed: 2026-08-14
Quote: Paraphrase — Elm's errors use first-person ("I see an error"), pair location with concrete fix suggestions, and deliberately break the fourth wall (e.g., "staring at this... is usually not helpful").

**rust-diagnostics-guide**
URL: https://rustc-dev-guide.rust-lang.org/diagnostics.html
Accessed: 2026-08-14
Quote: "Keep in mind that Rust's learning curve is rather steep, and that the compiler messages are an important learning tool." Also (paraphrase, RFC/dev-guide): spans should be reduced "to the smallest amount possible that still signifies the issue"; trait-bound detail is heuristically trimmed because full provenance "could easily stretch a diagnostic over 100 lines."

## SYNTHESIS

Cross-tool pattern: every mature tool surveyed retains rich, timeline-ordered evidence around the moment of failure BY DEFAULT in its primary CI/automation mode (Playwright: trace on-first-retry or retain-on-failure; Cypress: screenshot+video on `cypress run`; yt-dlp/gallery-dl: mandate verbose logs as a submission gate, not a courtesy). The single common failure mode across ecosystems is a tool designed around "requests/actions that started" going silent exactly when the failure happens *before* that unit of capture begins — Playwright needs the DOM to exist to snapshot it, mitmproxy needs an HTTP flow to exist to log it. This is structurally identical to the venmo case: the probe never got past `about:blank`, so any evidence model keyed on "the interesting event" (a completed page load, a completed request) has nothing to attach evidence to, and the failure surfaces as an undifferentiated transport error instead. The fix precedent (Playwright's `errorContext` aria-snapshot-at-assertion-failure, Charles's visibility into pre-HTTP failed connections) is: capture unconditionally at the failure instant, not only around completed units of work.

On interpretation: the field is split, and the split is informative. Tools with a CLOSED, deterministic taxonomy interpret confidently and are trusted (Buildkite/CircleCI flaky = pass+fail on same commit, a boolean fact, not a guess). Tools attempting OPEN-ENDED free-text root-cause (Sentry Seer) publish a specific accuracy number (94.5%) and openly document classes of miss (cross-service causes) rather than presenting output as certain — and even then needed additional structured context (traces) to close the gap, not more model capability alone. Everything in between (GitHub problem matchers, Gradle Build Scan, Sentry breadcrumbs/fingerprint) explicitly stops at SURFACING correlated evidence and lets a human draw the conclusion — none of these claim to state a cause.

For PDPP's connector-dev, in priority order:

1. **Cheapest, highest value — capture unconditionally, not opt-in.** The reported failure ("first failure produced no artifacts") is exactly the gap every leading tool closed years ago as table stakes: Cypress/Playwright/yt-dlp/gallery-dl all make evidence retention default-on in their primary run mode; PDPP's connector runner should capture DOM size, viewport, URL, and a screenshot on every probe failure unconditionally, with no flag required. This is a config default change, not new instrumentation.
2. **Cheap — snapshot at the failure instant, not just at "the last completed action."** Follow Playwright's `errorContext` precedent: when a probe throws, immediately capture page URL + DOM byte size + viewport dims alongside the error, in the SAME log line/artifact as the error message, so a human doesn't have to cross-reference a separate stderr warning against a separate artifact by timestamp. The root cause in the motivating case (39-byte DOM, 0-width viewport, about:blank) was already being captured — the defect was that it lived in a different place than the error, exactly the mitmproxy-vs-Charles "wrong unit of capture" problem.
3. **Cheap — add closed-taxonomy checks before any free-text message.** Following Buildkite/CircleCI's deterministic-rule model (not Seer's open-ended one): a small, explicit set of pre-flight assertions — "did navigation actually complete," "is DOM size above a sane floor," "is viewport non-zero" — each becomes its own labeled error class (e.g. `navigation_incomplete`) instead of falling through to a generic transport error. This is the single highest-leverage fix for the motivating case: it would have turned "Failed to fetch" into "page never navigated (DOM 39 bytes, viewport 0x0)" without any model call.
4. **Speculative — do not build open-ended free-text root-cause statements yet.** Sentry's own experience shows this needs a large accuracy-tracked feedback loop and still misses cross-boundary causes; a closed-taxonomy classifier (#3) captures most of the value here for a fraction of the engineering and false-confidence risk. If pursued later, follow Sentry's model: publish/track an accuracy number, and always attach the raw evidence next to any stated cause so a human can override it — never replace the evidence with the interpretation.
