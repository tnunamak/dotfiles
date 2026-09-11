---
title: "semantic-release maintainers deliberately refuse to auto-recover a silently-skipped release (tag exists, nothing published); the documented fix is deleting the orphan tag and re-running with a corrected commit, not retagging or an empty-commit hack"
date: 2026-09-11
topic: semantic-release-monorepo-scoping
tags: [semantic-release, recovery, silent-failure, tagging, ci-cd, npm-publish]
status: draft
sources: [sr-issue-1654, sr-issue-3178, sr-issue-1105, sr-troubleshooting-org]
source_session: c20a7f10-6f85-471f-a804-a84d994c221e
---

## CLAIMS

- The failure shape "a git tag exists but the corresponding npm release never
  published" is a long-standing, named semantic-release issue, not a novel
  situation: `semantic-release/semantic-release#1654` (opened 2020, still
  open) and `#3178` (2024) both describe it, and both were closed/left open
  with the same maintainer answer. [sr-issue-1654, sr-issue-3178]
- Maintainers explicitly refuse to have semantic-release auto-detect or
  auto-repair this state, on the record, because npm publishes are
  irreversible and a tool can't safely tell which side of "did this actually
  ship" it's on without a human checking the registry. `travi` (core
  maintainer), `#1654`: "trying to automatically recover runs the risk of
  hiding a problem silently that should have been investigated by a human...
  it is unrealistic for semantic-release to be able to handle releases in a
  fully atomic way." On `#3178`: "i do not consider this to be a bug. this is
  intended behavior... to expect human intervention in failure scenarios."
  [sr-issue-1654, sr-issue-3178]
- The maintainer-endorsed recovery procedure, accepted explicitly as the fix
  on `#1654` ("Solve 1" out of three proposals — the other two, an opt-in
  post-publish tagging flag and automatic tag deletion on failure, were both
  rejected as too dangerous/complex): delete the orphan tag, fix whatever
  caused the release to not land (bad commit message, missing scope, failed
  auth, etc.), then re-run the ordinary pipeline so commit-analyzer redecides
  the version normally. `travi`: "the best course of action is to delete the
  tag after fixing the problem that resulted in the partial release and
  re-run the release pipeline again." [sr-issue-1654]
- This procedure is codified in the official troubleshooting doc
  (semantic-release.org) under "`reference already exists` error when
  pushing tag": "If an actual release with that version number was published
  you need to merge all the commits up to that release into your release
  branch. If there is no published release with that version number, the tag
  must be deleted." — with exact commands: `git rev-list -1 <tag>` to confirm
  the tag's commit exists, `git branch --contains <tag>` to see which
  branches have it, then `git tag -d <tag>` and
  `git push origin :refs/tags/<tag>` to delete. The registry (not the git
  tag) is the source of truth for whether a release "really happened."
  [sr-troubleshooting-org]
- **Retagging** (force-moving an existing tag with `git tag -f` + force-push)
  is maintainer-guidance for a *different, narrower* failure than a silent
  skip: history was rewritten (rebase/force-push) so a tag that *does*
  correspond to a real, already-published release now points at the wrong
  commit. It is not the guidance for an orphan tag with nothing published
  behind it — that case is "delete," not "retag." Conflating the two is an
  easy wrong-fix trap when triaging a "tag exists, no release" incident.
  [sr-troubleshooting-org]
- **Empty commits used to "force" a release are never maintainer-recommended**
  and are only ever something users resort to, not something maintainers
  suggest. On `#1105`, when a user's real commit got silently skipped by CI
  and asked how to force a release, `pvdlg` (core maintainer) offered three
  alternatives — rerun the last commit's CI job, wait for the next real
  commit, or stop using `[skip CI]` — and did not mention an empty commit at
  all; the user, not the maintainer, called the situation "dumb." The
  technique is also empirically fragile: independent testing shows
  `fix:`/`feat:`/`perf:` empty commits reliably trigger a release, but a
  `BREAKING CHANGE:` footer alone (without a paired valid type) triggers
  nothing — an inconsistency that makes it a poor choice specifically for a
  "we skipped a release, now fix it cleanly" incident. [sr-issue-1105]
- No primary semantic-release source recommends a `workflow_dispatch` manual
  version-number input as the way to recover a silently-skipped release.
  Where projects wire up `workflow_dispatch` alongside semantic-release, it
  re-runs the *same* commit-analysis pipeline on demand (an emergency lever
  to retry), not a way to inject an arbitrary version that bypasses commit
  analysis — that pattern exists only in hand-rolled release scripts that
  replace semantic-release entirely for that run, never as a documented
  semantic-release recovery feature.

## SOURCES

**sr-issue-1654**
URL: https://github.com/semantic-release/semantic-release/issues/1654
Accessed: 2026-09-11
Quote: "it is the current opinion of the maintainers of this project that it is unrealistic for semantic-release to be able to handle releases in a fully atomic way... if there is a failure during the process, we believe a human is needed to understand the point at which the release failed to understand what steps should be rolled back and how." — and, on the endorsed fix: "the best course of action is to delete the tag after fixing the problem that resulted in the partial release and re-run the release pipeline again."

**sr-issue-3178**
URL: https://github.com/semantic-release/semantic-release/issues/3178
Accessed: 2026-09-11
Quote: "i do not consider this to be a bug. this is intended behavior with the current state of the project to expect human intervention in failure scenarios."

**sr-issue-1105**
URL: https://github.com/semantic-release/semantic-release/issues/1105
Accessed: 2026-09-11
Quote: "In your case you have multiple solution: - Run a job from the last commit on master - Wait for pushing another commit which will trigger a new CI run so semantic-release can make the release - Do not use [skip CI] in the first place"

**sr-troubleshooting-org**
URL: https://semantic-release.org/support/troubleshooting/
Accessed: 2026-09-11
Quote: "If an actual release with that version number was published you need to merge all the commits up to that release into your release branch. If there is no published release with that version number, the tag must be deleted." Plus commands: `git rev-list -1 <tag name>`, `git branch --contains <tag name>`, `git tag -d <tag name>`, `git push origin :refs/tags/<tag name>`.

## SYNTHESIS

The semantic-release maintainers' position is consistent across a 2020 issue
and a 2024 issue and the current official docs: a tag without a matching
published release is treated as an expected, human-triage-required failure
mode, not a bug to be engineered away. They rejected both an automatic
tag-deletion-on-failure feature and an opt-in post-publish-tagging mode as
too dangerous, precisely because npm publishes can't be undone and the tool
can't always tell from git alone whether the irreversible step happened. This
means for any repo hitting "tag exists, nothing published" (e.g., a scope
gate silently swallowing a real fix commit), the correct move is boring on
purpose: confirm against the registry, delete the orphan tag if nothing
published, fix the root cause, let the pipeline redecide the version on
re-run. Retagging is for a different failure (rewritten history moving an
already-real release's tag) and empty commits are a discouraged, fragile
workaround with no maintainer endorsement anywhere in the searched corpus.
A `workflow_dispatch` manual-retry lever is reasonable to add as a faster
mitigation, but it doesn't appear as a documented substitute for this
procedure — the actual gap maintainers keep pointing at is missing
"did this really publish?" verification, not slow recovery mechanics.
