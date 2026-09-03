---
title: "Path-filtering a required GitHub Actions workflow deadlocks unrelated PRs, but job-level if: skips report Success and do not"
date: 2026-08-18
topic: github-actions
tags: [github-actions, branch-protection, required-status-checks, ci, path-filters]
status: draft
sources: [troubleshooting-required-status-checks, status-checks-reference, github-docs-issue-4823]
source_session: 7d2ba1eb-8a88-48d2-8824-df423ebf07f2
---

## CLAIMS

- If a required status check comes from a workflow with a `pull_request.paths` (or
  `branches`) filter, and a PR doesn't touch those paths, the workflow never triggers and
  the associated check stays "Pending" forever — this permanently blocks merging that PR,
  even though the check is unrelated to what the PR changed. [troubleshooting-required-status-checks]
- The documented fix is to not require workflows that can be skipped this way — i.e. remove
  the path/branch filter from the trigger entirely and compute relevance INSIDE the
  workflow (a `changes` job + downstream `needs`+`if` gating) instead of via the trigger.
  [troubleshooting-required-status-checks]
- A job that is skipped via a job-level `if:` condition reports its status as "Success" for
  required-check purposes and does not block merging, even if that job's name is a required
  context. [status-checks-reference]
- This "skip == Success" behavior is the mechanism that makes the `changes`-job pattern
  work at all: the expensive jobs skip cleanly (reporting Success) on irrelevant PRs instead
  of the whole workflow silently not running. [status-checks-reference]
- GitHub Actions adds an IMPLICIT `success()` to any job-level `if:` expression that does
  not already call one of the status-check functions (`success()`, `failure()`,
  `cancelled()`, `always()`) — the engine effectively evaluates `success() && <your
  condition>`. [github-docs-issue-4823]
- The practical consequence of that implicit `success()`: if a job that computes relevance
  (e.g. a `changes` job) itself fails outright (script bug, checkout failure), every
  downstream job gated with a bare `if: needs.changes.outputs.x == 'true'` gets SKIPPED
  (not failed) — and per the skip-== -Success rule above, that reports as green. A broken
  relevance-computation job can therefore make an entire required-check surface silently
  pass with nothing having actually run, unless something else in the workflow explicitly
  checks that the relevance job itself succeeded. [github-docs-issue-4823] [status-checks-reference]

## SOURCES

**troubleshooting-required-status-checks**
URL: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks
Accessed: 2026-08-18
Quote: "Associated checks stay in a 'Pending' state and block merging" (workflow skipped via path/branch filtering or commit message) — "Avoid requiring workflows that can be skipped."

**status-checks-reference**
URL: https://docs.github.com/en/pull-requests/reference/status-checks
Accessed: 2026-08-18
Quote: "A job that is skipped will report its status as 'Success'. It will not prevent a pull request from merging, even if it is a required check."

**github-docs-issue-4823**
URL: https://github.com/github/docs/issues/4823
Accessed: 2026-08-18
Quote: "If your if expression does not contain any of the status functions, the success function will be ANDed with your condition" (i.e. GitHub Actions job-level `if:` implicitly becomes `success() && <condition>` unless a status function is already present).

## SYNTHESIS

Two GitHub Actions primitives combine into a trap that is easy to half-fix: fixing the
path-filter deadlock (finding B1-shaped: "required workflow with a paths filter can leave a
PR stuck Pending forever") by adding an internal `changes` job + job-level `if:` gating is
the textbook correct move, but it is NOT safe to then require the individual downstream job
names directly as the branch-protection contexts. Because a bare job-level `if:` silently
gets `success()` ANDed in, a failure in the `changes` job itself (not a "this PR is
irrelevant" skip, but a genuine bug/failure) makes every downstream job SKIP rather than
fail — and skip reports as Success for required-check purposes. The net effect: a broken
relevance-computation job can make an entire required-check gate report all-green while
nothing behind it actually ran, which is strictly worse than the original path-filter
deadlock (that one at least failed loud/visibly-pending; this one fails silently green).

The correct pattern is three-layered: (1) no workflow-level path filter on the trigger, (2)
an always-run `changes` job with job-level `if:` gating on the expensive jobs, (3) one
additional ALWAYS-run (`if: always()`) aggregate/gate job that explicitly inspects
`needs.<job>.result` for every job including `changes` itself, and is the ONLY job name
listed in branch protection's required contexts. This gate job is what actually
distinguishes "irrelevant PR, correctly skipped" from "something that should have run
didn't," which none of the individual leaf jobs can do on their own once the implicit
`success()` is accounted for. Applicable any time a required-check surface needs to be both
(a) always-triggered (to avoid the Pending-forever deadlock) and (b) conditionally
expensive (to avoid wasting CI on irrelevant PRs) — i.e. essentially every "gate a monorepo
subsystem's cross-repo integrity checks behind path relevance" design.
