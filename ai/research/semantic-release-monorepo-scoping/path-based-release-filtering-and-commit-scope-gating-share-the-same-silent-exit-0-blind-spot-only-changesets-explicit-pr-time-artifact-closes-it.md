---
title: "Path-based release filtering and commit-scope gating share the same silent exit-0 blind spot; only Changesets' explicit PR-time artifact closes it"
date: 2026-09-11
topic: semantic-release-monorepo-scoping
tags: [semantic-release, changesets, github-actions, monorepo, required-checks, path-filter]
status: draft
sources: [gh-required-check-docs, gh-discussion-26092, mcpm-pr262, psr-path-filters, rimac-monorepo, changesets-automating, changesets-action-281, tauri-discussion-14674, turborepo-design-system]
source_session: dd7bc202-9041-4de2-a1a4-06fdabb7313e
---

## CLAIMS

- GitHub's own troubleshooting docs state that filtering a workflow's trigger by `paths:` must not be combined with marking that workflow a required status check: a PR that doesn't touch the filtered paths never triggers the workflow, which never reports any status, permanently blocking merge ("Waiting for status to be reported"). [gh-required-check-docs]
- This is confirmed as unsupported-by-design in GitHub Community discussion #26092 ("Status checks 'required if run'") — a required checkrun must complete and return a status; there is no "required only if triggered" mode. The only escape is a repo admin manually overriding the block. [gh-discussion-26092]
- A real repo (mcpm.sh) added `paths: ['src/mcpm/**', 'pyproject.toml']` to a semantic-release workflow trigger specifically to cut CI cost on a single-package repo, not to solve an app+library cross-contamination problem — and review flagged that including `pyproject.toml` broadly risks the opposite failure (over-triggering on unrelated config edits). [mcpm-pr262]
- `python-semantic-release`'s `path_filters` config performs diff-path scoping inside the tool (not at the CI-trigger level), avoiding the required-check-hang failure mode, but inherits semantic-release's exit-0-when-nothing-to-release behavior — so it still silently produces zero releases when a real change's diff doesn't match the filter. [psr-path-filters]
- `semantic-release-monorepo` (and forks like RimacTechnology's) filter `context.commits` inside `analyzeCommits` by which package's files a commit touched, namespacing tags per package — same category as `path_filters`: safe against the required-check hang, but still silently exits 0 on a no-match commit. [rimac-monorepo]
- Changesets structurally differs: release intent is captured as an explicit file added at PR time, and the official Changesets bot comments on every PR stating whether a changeset is present (default-on, non-blocking). Docs describe the blocking variant: `changeset status --since=<baseBranch>` exits 1 if changed packages lack a new changeset; `changeset --empty` documents an intentional no-release. This converts "silently published nothing" into "PR merged without a changeset" — a decision visible before merge, not discovered later from a stale tag. [changesets-automating]
- Changesets is not failure-proof either: `changesets/action` can silently no-op when a squash-merge leaves no diff between `main` and the release branch ("No commits between main and changeset-release/main"), and `changeset version`/`publish` warn-and-exit-0 when no changesets are queued. The difference from scope/path gating is where the blind spot sits — after an earlier, human-visible checkpoint (the changeset file / bot comment), not as the only checkpoint. [changesets-action-281]
- Two independent real-world references for "app + published packages in one monorepo" both separate concerns rather than reusing one diff-path signal for both jobs: Tauri's own polyglot monorepo uses Covector, gating releases on explicit `.changes/*.md` files (Changesets-equivalent), not commit scope or path filters; Vercel's official Turborepo+library template uses Turborepo `--affected`/`--filter` only for build/test scoping and Changesets for the actual publish gate. [tauri-discussion-14674, turborepo-design-system]

## SOURCES

**gh-required-check-docs**
URL: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks
Accessed: 2026-09-11
Quote: "You should not use path or branch filtering to skip workflow runs if the workflow is required to pass before merging."

**gh-discussion-26092**
URL: https://github.com/orgs/community/discussions/26092
Accessed: 2026-09-11
Quote: "if the checkrun is required, it has to be completed and return a status value"

**mcpm-pr262**
URL: https://github.com/pathintegral-institute/mcpm.sh/pull/262
Accessed: 2026-09-11
Quote: "Restrict semantic release to only trigger on mcpm package changes"

**psr-path-filters**
URL: https://python-semantic-release.readthedocs.io/en/latest/configuration/configuration-guides/monorepos.html
Accessed: 2026-09-11

**rimac-monorepo**
URL: https://github.com/RimacTechnology/semantic-release-monorepo
Accessed: 2026-09-11

**changesets-automating**
URL: https://github.com/changesets/changesets/blob/main/docs/automating-changesets.md
Accessed: 2026-09-11
Quote: "this will exit with exit code 1 if there are changed packages but no new changesets since main, but it will not fail if there are no changed packages"

**changesets-action-281**
URL: https://github.com/changesets/action/issues/281
Accessed: 2026-09-11
Quote: "No commits between main and changeset-release/main"

**tauri-discussion-14674**
URL: https://github.com/orgs/tauri-apps/discussions/14674
Accessed: 2026-09-11

**turborepo-design-system**
URL: https://vercel.com/templates/react/turborepo-design-system
Accessed: 2026-09-11

## SYNTHESIS

For PDP-Connect/data-connect's actual incident — a real `fix:` commit merged unscoped, semantic-release's commit-analyzer found no matching scope, exited 0, published nothing, and nobody noticed for weeks — switching the release gate from commit-scope regex to path-based diff filtering (workflow-level `paths:`, `path_filters`, or a `semantic-release-monorepo`-style plugin) does not fix the root cause. Every one of those is a different predicate feeding the same exit-0-on-no-match design in semantic-release; none adds a human-visible checkpoint. Worse, if the retargeted workflow is ever wired as a required PR check, workflow-level `paths:` filtering introduces GitHub's own documented failure mode: PRs that don't touch the watched paths get permanently stuck at "Waiting for status to be reported," which GitHub explicitly does not support making conditional.

The one pattern in these primary sources that closes the actual gap is Changesets' (and Tauri's own Covector, which follows the same shape): make release intent an explicit artifact created and reviewed at PR time, and give CI something to assert against (`changeset status --since`) before merge, rather than inferring intent from commit prose or diff paths after merge. Two independent official references (Tauri's own monorepo tooling, Vercel's Turborepo+library template) converge on the same division of labor: diff-path signals are fine for CI build/test scoping (what to build), but the actual release/publish gate should be an explicit, checkable artifact, not a diff-path or commit-message inference. A minimal non-migration fix for the current `.releaserc`-based setup: keep the scope gate, but add a path-detection step that asserts a release *was* determined whenever a commit touches the tracked library paths — turning silent non-release into a loud CI failure — rather than treating path-filtering as a drop-in replacement for scope-filtering.
