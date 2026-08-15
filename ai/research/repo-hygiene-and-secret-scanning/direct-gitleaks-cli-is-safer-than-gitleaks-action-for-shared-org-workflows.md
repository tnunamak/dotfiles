---
title: "A pinned Gitleaks CLI is safer than gitleaks-action for shared organization workflows because the action requires a commercial organization license and can under-scan large pull requests"
date: 2026-08-11
topic: repo-hygiene-and-secret-scanning
tags: [gitleaks, github-actions, reusable-workflows, supply-chain, secret-scanning]
status: settled
sources: [gitleaks-release, gitleaks-license, action-readme, action-source, github-pagination, github-contexts]
source_session: unknown
---

## CLAIMS

- Gitleaks CLI v8.30.1 is MIT-licensed, and the release publishes checksums for its binary assets. [gitleaks-release] [gitleaks-license]
- `gitleaks/gitleaks-action` requires an action license for organization repositories and is distributed under a source-available end-user license, not the Gitleaks CLI's MIT license. [action-readme]
- At the v3.0.0 action release, the action source defaults to Gitleaks 8.24.3 and obtains pull-request commits with a single `pulls/{number}/commits` REST request before building a first-parent scan range. [action-source]
- GitHub's list-pull-request-commits endpoint is paginated and defaults to 30 results per page. [github-pagination]
- In a reusable workflow, `job.workflow_repository` and `job.workflow_sha` identify the repository and immutable commit that define the called job; GitHub documents using them to check out files co-located with the reusable workflow. [github-contexts]

## SOURCES

**gitleaks-release**
URL: https://github.com/gitleaks/gitleaks/releases/tag/v8.30.1
Accessed: 2026-08-11

**gitleaks-license**
URL: https://github.com/gitleaks/gitleaks/blob/v8.30.1/LICENSE
Accessed: 2026-08-11

**action-readme**
URL: https://github.com/gitleaks/gitleaks-action/tree/v3.0.0
Accessed: 2026-08-11

**action-source**
URL: https://github.com/gitleaks/gitleaks-action/blob/v3.0.0/src/index.js
Accessed: 2026-08-11

**github-pagination**
URL: https://docs.github.com/en/rest/pulls/pulls#list-commits-on-a-pull-request
Accessed: 2026-08-11

**github-contexts**
URL: https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#job-context
Accessed: 2026-08-11

## SYNTHESIS

Use the MIT Gitleaks CLI directly in organization-wide reusable workflows. Pin the CLI version and binary checksum, and scan an explicit Git commit range. Avoid `gitleaks-action` when a direct invocation is simple: it adds a separate organization license and, at v3.0.0, its single unpaginated pull-request commit request can omit commits after the first page.

Keep the policy repository and callers immutable together. Callers should reference the reusable workflow by a full commit SHA. The reusable workflow can use `job.workflow_repository` and `job.workflow_sha` to check out its own configuration at that same commit, so a mutable default branch cannot change the policy beneath a pinned caller.
