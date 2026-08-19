---
title: "Central git-hook policy is distributed by runtime reference plus an immutable per-repo pin — the pin is the only thing that must be duplicated, and Renovate customManagers can bump it across repos"
date: 2026-08-18
topic: repo-hygiene-and-secret-scanning
tags: [git-hooks, pre-commit, supply-chain, sha-pinning, renovate, dot-github]
status: draft
sources: [pre-commit-rev-immutable, pre-commit-cache-stub, lefthook-remotes, dependabot-precommit, renovate-regex-manager, scorecard-pinned-deps, scorecard-mitigation, cisa-tj-actions, wiz-tj-actions, sha-pinning-no-provenance, gh-docs-community-health, gh-docs-reusable-workflows, gh-required-workflows-deprecated, gh-no-native-sync]
source_session: c99c735d-8829-49d4-b527-afd219c27d82
---

## CLAIMS

- pre-commit treats `rev:` as an immutable ref and explicitly does not support branch names: "pre-commit assumes that the value of `rev` is an immutable ref (such as a tag or SHA) and will cache based on that" and "Using a branch name (or `HEAD`) for the value of `rev` is not supported and will only represent the state of that mutable ref at the time of hook installation (and will _NOT_ update automatically)." [pre-commit-rev-immutable]

- pre-commit clones hook repositories into a cache (`~/.cache/pre-commit`, or `$PRE_COMMIT_HOME`) and installs a stub into `.git/hooks/` that references the cached clone at runtime, so hook logic is never copied into the consuming repo. [pre-commit-cache-stub]

- Lefthook supports a `remotes:` config section referencing a central config repo by `git_url` and `ref`, merged into local config on `lefthook install`; updates require re-running install rather than arriving automatically. [lefthook-remotes]

- GitHub Dependabot added native `.pre-commit-config.yaml` support in March 2026, auto-generating PRs to bump `rev:` pins. [dependabot-precommit]

- Renovate's `customManagers` with `customType: "regex"` are file-type agnostic — "With `customManagers` using `regex` you can configure Renovate so it finds dependencies that are not detected by its other built-in package managers" — using `managerFilePatterns` to select files and `matchStrings` with named capture groups to extract the dependency; `currentDigest` is a documented optional capture group. This makes an arbitrary pinned constant in a shell script (e.g. `CENTRAL_POLICY_SHA='<40-hex>'`) bumpable by bot across many repos. [renovate-regex-manager]

- The Renovate docs list `currentDigest` among optional capture groups but do not specifically document 40-hex commit-SHA format requirements or validation. [renovate-regex-manager]

- OpenSSF Scorecard defines a pinned dependency as "a dependency that is explicitly set to a specific hash instead of allowing a mutable version or range of versions", and states the downside directly: "However, pinning dependencies can inhibit software updates, either because of a security vulnerability or because the pinned version is compromised." [scorecard-pinned-deps]

- Scorecard's own prescribed mitigation for that downside is automation, not abandoning pinning: "using automated tools to notify applications when their dependencies are outdated; quickly updating applications that do pin dependencies." [scorecard-mitigation]

- In the tj-actions/changed-files compromise (CVE-2025-30066), hash-pinned consumers were largely protected: "Customers who were using a hash-pinned version of tj-actions/changed-files would not be impacted, unless they had updated to an impacted hash during the exploitation timeframe." [wiz-tj-actions]

- CISA's post-incident guidance recommended pinning actions to immutable commit SHAs rather than version tags. [cisa-tj-actions]

- SHA pinning provides content immutability but NOT provenance: GitHub does not validate that a referenced commit SHA originates from the named repository, because forks share an object graph — so a PR can swap a pinned SHA for one from an attacker-controlled fork while `owner/repo` appears unchanged. GitHub's own docs place the burden on the user: "you should verify it is from the action's repository and not a repository fork." GitHub's Aug-2025 SHA-pinning policy enforcement checks only that a full SHA is present, not its origin. [sha-pinning-no-provenance]

- The org `.github` repo propagates community health files (CODE_OF_CONDUCT, CONTRIBUTING, SECURITY, SUPPORT, GOVERNANCE, FUNDING, issue/PR templates) as read-time fallbacks only; the repo must be public, and the files "are not included in clones, packages, or downloads" of member repos. [gh-docs-community-health]

- Reusable workflows are referenced at runtime as `{owner}/{repo}/.github/workflows/{filename}@{ref}` where ref may be a SHA, tag, or branch — a genuine reference, not a copy. [gh-docs-reusable-workflows]

- GitHub's org-level "required workflows" feature was deprecated and folded into repository rulesets. [gh-required-workflows-deprecated]

- `.github` has no native mechanism to push or sync arbitrary files into member repositories; doing so requires third-party Actions plus a bot token. [gh-no-native-sync]

- The documented list of ruleset rule types contains no "required workflows" rule. The 16 available rules are: restrict creations/updates/deletions, require linear history, require deployments to succeed, require signed commits, require a pull request before merging, require status checks to pass, block force pushes, require code scanning results, require code quality results, restrict code coverage, and restrict file paths / path length / extensions / size. Rulesets VALIDATE that a named check passed; they do not cause a workflow to execute on the target repo. [gh-ruleset-rules]

- GitHub secret scanning push protection can be enabled across every repo in an org from a single org-level security configuration, with no per-repo file and nothing committed to member repos; it is enabled by default for public repositories. [gh-push-protection-orgwide]

- Custom secret-scanning patterns are defined at enterprise, org, or repo level (up to 500 per org/enterprise, 100 per repo), support dry-runs across all org repos, and can each be individually enabled for push protection after publishing. [gh-custom-patterns]

- Which secret-scanning patterns participate in push protection became configurable at enterprise/org level in GA August 2025; these pattern configurations "apply globally — they cannot be scoped to individual repositories or repo subsets." [gh-pattern-config-ga]

- Push protection is bypassable by design: "By default, anyone with write access to the repository can bypass push protection by specifying a bypass reason", which creates an alert and logs the event. [gh-push-protection-bypass]

## SOURCES

**pre-commit-rev-immutable**
URL: https://pre-commit.com/
Accessed: 2026-08-18
Quote: "pre-commit assumes that the value of `rev` is an immutable ref (such as a tag or SHA) and will cache based on that." / "Using a branch name (or `HEAD`) for the value of `rev` is not supported and will only represent the state of that mutable ref at the time of hook installation (and will _NOT_ update automatically)."

**pre-commit-cache-stub**
URL: https://pre-commit.com/
Accessed: 2026-08-18
Quote: Hook repositories are cloned into `~/.cache/pre-commit` (overridable via `PRE_COMMIT_HOME`) and `.git/hooks/` receives a stub referencing the cached clone.

**lefthook-remotes**
URL: https://lefthook.dev/configuration/remotes.html
Accessed: 2026-08-18
Quote: Remote configs are referenced by `git_url` + `ref` + `configs:` and merged with local config on `lefthook install`.

**dependabot-precommit**
URL: https://github.blog/changelog/2026-03-10-dependabot-now-supports-pre-commit-hooks/
Accessed: 2026-08-18
Quote: Dependabot natively parses `.pre-commit-config.yaml` and opens PRs to update `rev:` values.

**renovate-regex-manager**
URL: https://docs.renovatebot.com/modules/manager/regex/
Accessed: 2026-08-18
Quote: "With `customManagers` using `regex` you can configure Renovate so it finds dependencies that are not detected by its other built-in package managers." / matchStrings is "used for configuring a regular expression with named capture groups"; `currentDigest` is listed as an optional capture group.

**scorecard-pinned-deps**
URL: https://github.com/ossf/scorecard/blob/main/docs/checks.md
Accessed: 2026-08-18
Quote: "A 'pinned dependency' is a dependency that is explicitly set to a specific hash instead of allowing a mutable version or range of versions." / "However, pinning dependencies can inhibit software updates, either because of a security vulnerability or because the pinned version is compromised."

**scorecard-mitigation**
URL: https://github.com/ossf/scorecard/blob/main/docs/checks.md
Accessed: 2026-08-18
Quote: "Mitigate this risk by: using automated tools to notify applications when their dependencies are outdated; quickly updating applications that do pin dependencies."

**wiz-tj-actions**
URL: https://www.wiz.io/blog/github-action-tj-actions-changed-files-supply-chain-attack-cve-2025-30066
Accessed: 2026-08-18
Quote: "Customers who were using a hash-pinned version of tj-actions/changed-files would not be impacted, unless they had updated to an impacted hash during the exploitation timeframe."

**cisa-tj-actions**
URL: https://www.cisa.gov/news-events/alerts/2025/03/18/supply-chain-compromise-third-party-tj-actionschanged-files-cve-2025-30066-and-reviewdogaction
Accessed: 2026-08-18
Quote: CISA recommends pinning GitHub Actions to immutable commit SHAs instead of version tags.

**sha-pinning-no-provenance**
URL: https://www.vaines.org/posts/2026-03-24-the-comforting-lie-of-sha-pinning/ (corroborated: https://rosesecurity.dev/2026/03/24/sha-pinning-is-not-enough.html, https://docs.github.com/en/actions/reference/security/secure-use)
Accessed: 2026-08-18
Quote: "GitHub does not validate that a commit SHA belongs to the referenced repository"; GitHub docs: "you should verify it is from the action's repository and not a repository fork."

**gh-docs-community-health**
URL: https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file
Accessed: 2026-08-18
Quote: "The `.github` repository must be public for defaults to apply organization-wide." / Default files "are not included in clones, packages, or downloads."

**gh-docs-reusable-workflows**
URL: https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows
Accessed: 2026-08-18
Quote: "{owner}/{repo}/.github/workflows/{filename}@{ref}" where ref "can be a SHA, a release tag, or a branch name. Using the commit SHA is the safest option."

**gh-required-workflows-deprecated**
URL: https://docs.github.com/en/enterprise-server@3.11/actions/using-workflows/required-workflows
Accessed: 2026-08-18
Quote: "GitHub no longer supports required workflows for GitHub Actions." Organizations are directed to repository rulesets.

**gh-no-native-sync**
URL: https://github.com/Redocly/repo-file-sync-action
Accessed: 2026-08-18
Quote: Third-party Actions exist specifically to sync files from a central repo to member repos, which `.github` does not do natively.

**gh-ruleset-rules**
URL: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets
Accessed: 2026-08-18
Quote: Rule list contains "Require status checks to pass before merging" and 15 others; no "required workflows" rule type is present.

**gh-push-protection-orgwide**
URL: https://docs.github.com/en/code-security/concepts/secret-security/push-protection (+ https://github.blog/changelog/2025-08-19-secret-scanning-configuring-patterns-in-push-protection-is-now-generally-available/)
Accessed: 2026-08-18
Quote: An org-level security configuration "enables secret scanning and push protection across all your repos in a few clicks, with no need to touch individual repository settings"; push protection "is enabled by default for all public repositories."

**gh-custom-patterns**
URL: https://docs.github.com/en/code-security/secret-scanning/using-advanced-secret-scanning-and-push-protection-features/custom-patterns/defining-custom-patterns-for-secret-scanning
Accessed: 2026-08-18
Quote: "up to 500 custom patterns per organization or enterprise account and up to 100 per repository"; dry runs may run "across all repositories in the organization"; "The push protection option is visible for published patterns only."

**gh-pattern-config-ga**
URL: https://github.blog/changelog/2025-08-19-secret-scanning-configuring-patterns-in-push-protection-is-now-generally-available/
Accessed: 2026-08-18
Quote: "pattern configurations apply globally — they cannot be scoped to individual repositories or repo subsets."

**gh-push-protection-bypass**
URL: https://docs.github.com/en/code-security/concepts/secret-security/push-protection
Accessed: 2026-08-18
Quote: "By default, anyone with write access to the repository can bypass push protection by specifying a bypass reason."

## SYNTHESIS

The question "can member repos refer back to a central definition at runtime instead of copying it" has a settled answer in the prior art: **yes, and the mature tools all do it the same way.** pre-commit is the canonical case — hook logic lives in a central repo, is cloned into a machine-local cache, and each consuming repo gets only a stub plus a pinned `rev:`. Lefthook's `remotes:` is the same shape with a different merge model. This is inversion of control, and it is standard.

What none of them eliminate is **the pin**. pre-commit is emphatic that a mutable ref is unsupported, not merely discouraged — which reframes the local trade: the per-repo constant is not an artifact of a bad design, it is the design. Scorecard states the cost of pinning plainly (it inhibits updates) and prescribes automation rather than mutability as the fix. So the target state is *pin + bot*, not *drop the pin*.

The tj-actions incident supports pinning empirically (hash-pinned consumers were largely spared) while the provenance gap complicates the story: a SHA guarantees content immutability but not that the content came from the repo you named, because forks share an object graph. For a *local* checkout validated by remote-URL inspection this matters less than for GitHub Actions resolution — but it does mean "we pinned a SHA" is not by itself a complete integrity argument. Origin verification has to be a separate, explicit check.

For `.github` specifically, the boundary is sharp and worth internalizing: it is a **read-time fallback and reference library, not a control plane.** Community health files fall back at read time and never enter clones. Reusable workflows are referenced by `uses:` at runtime. But nothing in `.github` pushes files into member repos, and the org-level "required workflows" feature was deprecated into rulesets — so a centrally-defined pre-push hook cannot be *mandated* from `.github`; each repo must opt in by carrying something.

The practical synthesis for a centrally-defined git hook: keep hook logic central and referenced at runtime (already the correct pattern), shrink the per-repo footprint to the pin alone, and automate pin bumps with Renovate `customManagers` — which the docs confirm can match an arbitrary constant in an arbitrary file type, making a `CENTRAL_POLICY_SHA='<40-hex>'` in a bash script a legitimate bot-managed dependency. That converts "hand-edit N repos on every policy change" into "review N bot PRs", which is the same friction the rest of the ecosystem accepted deliberately. Unverified for this case: whether `currentDigest` + a `git-refs` datasource behaves well against a plain commit SHA in practice — the docs list the capture group but do not document SHA-format handling, so it needs a trial before being relied on.

One caveat the corpus should carry: client-side hooks are bypassable (`--no-verify`) and therefore a guardrail, not an enforcement boundary. Any check that actually matters must also run in CI, where the reusable-workflow half of this design already applies.

**The cut that actually organizes this space is settings vs. content, not central vs. copied.**

*Settings* (team membership, permissions, visibility, branch protection, security features) are GitHub-API-owned and can be reconciled from one declarative file with zero footprint in member repos — CLOWarden (`config.yaml` in a `governance` repo, PR-gated, bot reconciles), safe-settings, Terraform, or native org rulesets. LFDT's PDP-Connect runs exactly this: a 915-byte `config.yaml` governing five repos, where "add a maintainer" is a reviewed PR against one file. This is a genuine control plane.

*Content* (a hook script, a pinned SHA, a workflow file) is NOT reachable by settings reconciliation. It gets into a repo by exactly three routes: (a) the repo references it at runtime (`uses:` a reusable workflow; a hook stub that execs a central checkout), (b) a bot copies it in via PR, or (c) the platform provides the behavior natively so no file is needed at all.

Route (c) is the one most often missed and is frequently the 2026 answer: GitHub's own secret-scanning push protection is enabled org-wide from one security configuration, needs no file in any repo, supports up to 500 org-level custom patterns with org-wide dry-runs, and is free/default-on for public repos. Its limits are equally concrete — it is bypassable by anyone with write access (logged, but permitted), and pattern configuration "cannot be scoped to individual repositories."

Also worth recording as a negative result: org rulesets cannot force a workflow to RUN. The rule list has no "required workflows" entry (that feature was deprecated into rulesets and did not survive as a rule type); "require status checks to pass" only validates that a named check reported success. So a repo that never runs the workflow simply never produces the check — enforcement comes from the merge being blocked, not from central execution. Any "define it once centrally and it executes everywhere" claim about rulesets is false as of 2026-08.
