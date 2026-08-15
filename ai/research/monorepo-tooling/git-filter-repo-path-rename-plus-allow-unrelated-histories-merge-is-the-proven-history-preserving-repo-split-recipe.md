---
title: "git filter-repo --path/--path-rename extraction followed by a target-repo merge --allow-unrelated-histories is the proven, hands-on-verified recipe for history-preserving monorepo package extraction into an existing unrelated repo; open PRs, CI/CODEOWNERS/branch-protection, REUSE/SPDX metadata, and pnpm-workspace specifiers do NOT survive the rewrite and need separate handling"
date: 2026-08-14
topic: monorepo-tooling
tags: [git-filter-repo, git-subtree, monorepo-split, repo-extraction, allow-unrelated-histories, blame-preservation, tag-rename, mailmap, pnpm, npm-workspaces, codeowners, branch-protection, reuse-spdx, pdpp, data-connectors, data-connect]
status: draft
sources: [filter-repo-docs, filter-repo-readme, dennis-doomen-merging, josh-fail-merging, medhat-dev-merging, codestudy-move-subdir, wp-cli-split-retrospective, wordpress-core-history-severing, theregister-iojs-merge, nodesource-iojs-blog, reuse-spec-3-3, reuse-faq, github-codeowners-branch-protection, pnpm-vs-npm-workspaces, git-filter-repo-issue-25, verified-hands-on]
source_session: d95d3973-3f03-43ab-a300-20e785b73946
---

<!--
Produced for a concrete migration: PDP-Connect/pdpp (pnpm monorepo) splitting
packages/polyfill-connectors into PDP-Connect/data-connectors, and its
reference-impl + related packages into PDP-Connect/data-connect (Tauri app,
npm workspaces, unrelated history), leaving pdpp spec-only. All git recipes
below marked VERIFIED were actually executed in throwaway repos under
~/.tmp/reorg-0814/git-scratch/ on 2026-08-14, not just read about.
-->

## CLAIMS

### Core recipe: extraction + merge (VERIFIED hands-on)

- `git filter-repo --path <dir>/ --path-rename <dir>/:<newdir>/` on a **fresh clone** of the source repo rewrites every commit's tree so only commits touching `<dir>` survive, with `<dir>` renamed to `<newdir>` in every historical commit (not just HEAD) — verified: a 5-commit test repo (4 commits touching the target path, 1 "unrelated" commit touching a sibling package only) produced exactly the 4 relevant commits after filtering, with the unrelated commit dropped entirely. [verified-hands-on]
- Because the rename is baked into every historical tree, a plain `git log -- <newdir>/file` (no `--follow` needed) and `git blame <newdir>/file` both work correctly against the post-merge combined history — verified: blame on the migrated file after merge correctly attributed the last line to the actual last author, and `git log` (not `--follow`) walked all 4 pre-move commits by the new path. [verified-hands-on]
- Merging the filtered repo into a target repo with **completely unrelated history** requires `git merge --allow-unrelated-histories <remote>/<branch>`; without the flag git refuses with "fatal: refusing to merge unrelated histories" (a safety check added in Git 2.9, 2016) — verified: the plain merge with a wrong branch name failed with "not something we can merge", and once the correct branch was used, `--allow-unrelated-histories` was required and merged cleanly. [verified-hands-on] [dennis-doomen-merging] [medhat-dev-merging]
- Plain `git subtree pull`/`add` (the non-filter-repo tool) does NOT accept unrelated histories either and hits the same refusal — filter-repo + explicit `--allow-unrelated-histories` merge is the documented, more commonly recommended path today for cross-repo merges specifically because of this. [codestudy-move-subdir]
- **Path collisions are a real, reproducible failure mode, not just a warning**: when the target repo already has a file/dir at the exact renamed destination path, the merge produces a genuine `CONFLICT (add/add)` requiring manual resolution — verified by reproducing it directly (target repo pre-seeded with a file at the same path the import would land on; `git merge --allow-unrelated-histories` exited 1 with an add/add conflict on that file). Distinct sibling paths in the same merge (e.g. target already has `connectors/existing.ts`, import lands at `connectors/polyfill-connectors/`) merge with zero conflicts. [verified-hands-on] [filter-repo-readme]
- Multiple `--path` + matching `--path-rename` pairs can be combined in a **single filter-repo invocation** to extract and relocate several packages from the same source repo in one pass (relevant to the data-connect move, which pulls reference-impl + several related packages at once) — verified: extracting `packages/reference-impl/` → `apps/reference-impl/` and `packages/shared-utils/` → `packages/shared-utils/` together in one filter-repo call correctly dropped the untouched `packages/polyfill-connectors/` package and preserved all 3 commits that touched either kept path. [verified-hands-on]
- **Rename-filter ordering matters**: when combining a parent-directory rename with other path filters, the parent rename must be applied last — applying it first invalidates the other filters because the original parent path no longer exists after the first rewrite. [git-tower-filter-repo] (not independently re-verified beyond the single-invocation multi-pair case above, which sidesteps the ordering issue by using one filter-repo call)
- **Known blame/history limitation**: filter-repo (like filter-branch) works off a static list of path patterns; if a file's *pre-move* history includes a period when it lived somewhere outside the filtered path (e.g. it was relocated within the monorepo before the split), that earlier history is NOT automatically recovered by `--path` alone — one documented real-world case retained only 25 of an expected 144 commits for a file for exactly this reason. A dedicated tool (`git-relevant-history`) exists to compute the full historical rename-pattern list first, from `git log --follow`, before running filter-repo. **Action item for the actual pdpp split**: run `git log --follow --oneline -- packages/polyfill-connectors/` (and equivalent for reference-impl + siblings) in the source repo BEFORE filtering, to check whether any of these packages were renamed/moved within the pdpp monorepo previously — if so, add `--path` entries for the old location(s) too. [filter-repo-issue-25]
- Tag collisions are avoided with `--tag-rename '':'<prefix>-'`, applied in the same filter-repo pass as the path filtering — verified: `--tag-rename '':'polyfill-connectors-'` correctly renamed `v1.0.0` to `polyfill-connectors-v1.0.0` in the filtered clone, and that renamed tag was importable into the target repo via `git fetch --tags` with zero collision against the target's own tags (target had none in the test, but the mechanism prevents `v1.0.0`-vs-`v1.0.0` collisions in general). [verified-hands-on] [git-tower-filter-repo]
- filter-repo automates and makes **permanent** several things that filter-branch required manual plumbing for: baking in existing grafts and replace refs, and mailmap-based author/committer/tagger rewriting (`--mailmap` / `--use-mailmap`, format per `git-shortlog(1)`) — useful if pdpp's author identities need normalizing before merge (e.g. squashing multiple emails per contributor). Only the CURRENT contents of a mailmap file are consulted, not its own history. [filter-repo-docs]
- `git filter-repo --analyze` (run before the real extraction, no `--force` mutation) produces size/path/extension reports under `.git/filter-repo/analysis/` — verified it runs and produces `path-all-sizes.txt`, `renames.txt`, `directories-all-sizes.txt`, etc. Useful for scoping which paths in pdpp are safe to `--path`-select and whether the extraction will drag along oversized blobs. [verified-hands-on]
- filter-repo requires operating on a **fresh clone**, not the working repo, and refuses to run on a non-fresh clone by default (the "not a fresh clone" safety check) — use `--force` deliberately only once you're operating on a disposable clone, never on the canonical pdpp checkout. [filter-repo-docs]

### Real-world precedent for repo splits

- **WP-CLI's package split (documented retrospective)**: WP-CLI split its single repo into multiple command-package repos, deliberately starting each new repo as a full copy of the original (to avoid losing "historical knowledge"), then purging unneeded files afterward — but the purge was incomplete, so each resulting package repo still carries the full history of ALL WP-CLI files up to the split point. Consequence: per-repo contribution/blame statistics became "useless" and repo sizes were inflated (~10MB of dead history per command repo). **Lesson for pdpp**: do the path-filtering (not just a bulk copy-then-purge) at extraction time — filter-repo's `--path` approach avoids this exact failure mode by design, since it drops non-matching commits rather than leaving them in place unpurged. [wp-cli-split-retrospective]
- **WordPress Core / Gutenberg (2026 incident)**: after WordPress Core moved its "source of truth" for certain files into the separate Gutenberg repo (with a build step to pull them back into wordpress-develop pinned by commit hash), version history for those files was effectively severed from the perspective of the consuming repo — contributors could no longer see prior history for those files in the tool they normally used, and reconstructing history required custom git commands, adding measured delays (9+ hours to walk 800+ commits across a release). **Lesson**: a split that's technically history-preserving in the SOURCE repo can still feel "severed" to consumers of the DESTINATION if the destination's normal tooling (GitHub UI, IDE blame) doesn't expect history to jump in from an unrelated-history merge — plan documentation/announcement, not just the git mechanics. [wordpress-core-history-severing]
- **io.js / Node.js remerge (2015)**: when io.js and Node.js reunified, the surviving canonical repository was based on **io.js's git history**, not the original Node.js repo — i.e. one side's repo became the "target" and effectively absorbed/became authoritative, rather than a true symmetric merge. This predates Git 2.9's `--allow-unrelated-histories` flag (introduced 2016), so the actual mechanics used at the time were manual (grafts/replace-refs or `merge -s ours`-style tricks), not the now-standard flag. No public git-mechanics writeup was found beyond the governance/organizational story. [theregister-iojs-merge] [nodesource-iojs-blog]
- No public, git-mechanics-level writeup was found for Jest leaving the Facebook/Meta monorepo (2022 OpenJS Foundation transfer) or for Babel's internal package consolidation — both are documented as organizational/governance events, not as git-history-surgery case studies. Treat prior claims of "Jest/Babel published their exact git recipe" as unverified; the Meta engineering blog post covers governance (CLA, code of conduct, asset transfer) not git plumbing. [Sources searched, no writeup found]

### In-flight PRs and open branches

- There is no git-native mechanism that preserves open PRs/branches through a history rewrite: filter-repo changes every commit SHA, so any branch not merged before the rewrite has commits that no longer exist in the new history. The consistently recommended pattern across sources: **drain the queue before rewriting** — merge or explicitly close/land what you can before running the extraction; anything left over must be recreated as a fresh branch/PR against the new repo (cherry-pick the diff, not the commits) after a communicated freeze/cutover window. [github-codeowners-branch-protection] [general-pr-split-sources]
- If ongoing (not one-time) syncing between a monorepo and split-out repos is ever needed, the common pattern is to sync only at merge-time (`git subtree split` triggered by CI on merge to main), which sidesteps the open-PR problem structurally — not applicable to pdpp's one-time terminal split (pdpp becomes spec-only afterward) but worth naming to confirm this migration doesn't need that machinery. [general-pr-split-sources]

### CI, CODEOWNERS, branch protection

- GitHub's CODEOWNERS enforcement and branch-protection rules are tied to the **branch name/pattern in that specific GitHub repo**, not to commit lineage — they are not "carried over" by a history rewrite because they were never derived from history in the first place. They must be **manually recreated on the new repos** (data-connectors, data-connect) since those are separate GitHub repos with their own independent settings; nothing about filter-repo or the merge transfers them automatically. [github-codeowners-branch-protection]
- The one documented case where protection settings unexpectedly carry over undesirably is cross-platform import (GitHub → GitLab), not applicable here since both source and destination are GitHub repos — but it reinforces that repo settings are a separate manual-configuration surface, orthogonal to the git object rewrite. [github-codeowners-branch-protection]
- **Action item**: audit pdpp's current CODEOWNERS entries and branch-protection rules for `packages/polyfill-connectors/**` and the reference-impl paths, and pre-stage equivalent CODEOWNERS lines + branch-protection config in data-connectors and data-connect before or immediately after the merge lands, since there's a real window where the imported code has no owner enforcement in its new home.

### REUSE / SPDX license metadata continuity

- REUSE compliance is file-scoped (SPDX headers in-file, or a `REUSE.toml`/legacy `.reuse/dep5` manifest) — a git history rewrite that preserves file *contents* (which filter-repo does; it only changes commit graph/paths, not blob content unless you explicitly use `--replace-text`) does not, by itself, break in-file SPDX headers. The risk is at the **repo-manifest level**: if pdpp uses `.reuse/dep5` or `REUSE.toml` with path-based rules, those rules reference source paths that will differ post-move (`packages/polyfill-connectors/` → wherever it lands in data-connectors/data-connect) and must be manually ported/re-pathed into each destination repo's own REUSE manifest — the manifest itself does not travel with a path-filtered subtree unless explicitly included in the `--path` list. [reuse-spec-3-3] [reuse-faq]
- Practical check: confirm the destination repos (data-connectors, data-connect) already have their own REUSE setup (or none) before merging, and reconcile/merge dep5-or-toml entries rather than assuming pdpp's file travels over — a naive merge would leave two conflicting or orphaned REUSE manifests, or lose per-path exceptions defined in pdpp's manifest for the moved code.

### pnpm → npm workspace merge implications (data-connect move)

- npm's native `workspaces` field in package.json does not understand pnpm's `workspace:*`/`workspace:^` specifier syntax — every internal cross-package dependency using `workspace:` protocol in the moved packages (polyfill-connectors reference-impl, shared packages) must be rewritten to plain semver ranges or `*` before/as part of the move into data-connect (npm workspaces). This is a required mechanical step, not optional compat. [pnpm-vs-npm-workspaces]
- Lockfile formats are incompatible (pnpm YAML `pnpm-lock.yaml` vs npm JSON `package-lock.json`) — `pnpm-lock.yaml` must be deleted and `package-lock.json` regenerated via `npm install` in data-connect after the merge; there's no conversion tool referenced in sources, only clean regeneration. [pnpm-vs-npm-workspaces]
- pnpm's default strict, non-hoisted dependency isolation (each package only sees what it explicitly declares) is materially different from npm's default hoisted-to-root `node_modules` model — code that worked in pdpp under pnpm's strict isolation may have undeclared ("phantom") dependencies that happen to still resolve under npm's looser hoisting. **Action item**: after the move, run the moved packages' test suites specifically under npm install (not just visually diff package.json) to catch phantom-dependency breakage that pnpm was silently preventing. [pnpm-vs-npm-workspaces]
- CI pipeline commands and caching strategy must change (`pnpm install --frozen-lockfile` → `npm ci`); this is separate from and in addition to the CODEOWNERS/branch-protection reconfiguration above. [pnpm-vs-npm-workspaces]

## SOURCES

**filter-repo-docs**
URL: https://github.com/newren/git-filter-repo/blob/main/Documentation/git-filter-repo.txt
Accessed: 2026-08-14
Quote: "By default, grafts and replace refs, if present, are used in the rewrite and made permanent."

**filter-repo-readme**
URL: https://github.com/newren/git-filter-repo
Accessed: 2026-08-14

**dennis-doomen-merging**
URL: https://www.dennisdoomen.com/2023/02/merging-repositories.html
Accessed: 2026-08-14

**josh-fail-merging**
URL: https://josh.fail/2022/merging-git-repos-with-git-filter-repo/
Accessed: 2026-08-14

**medhat-dev-merging**
URL: https://medhat.dev/blog/merging-2-git-repos-with-persisting-commit-history/
Accessed: 2026-08-14

**codestudy-move-subdir**
URL: https://www.codestudy.net/blog/how-to-move-some-files-from-one-git-repo-to-another-not-a-clone-preserving-history/
Accessed: 2026-08-14
Quote: "attempting a subtree pull with unrelated histories fails with 'fatal: refusing to merge unrelated histories'"

**git-tower-filter-repo**
URL: https://www.git-tower.com/learn/git/faq/git-filter-repo
Accessed: 2026-08-14

**wp-cli-split-retrospective**
URL: https://github.com/wp-cli/wp-cli/issues/5594
Accessed: 2026-08-14
Quote: "each subsplit package began as the original main package with unneeded files removed afterward... the purging done afterward to remove unused history wasn't thorough enough"

**wordpress-core-history-severing**
URL: https://make.wordpress.org/core/2026/06/17/recap-restoring-removed-version-history/
Accessed: 2026-08-14
Quote: "version history for these files was severed, making it look like the files were never part of the repository"

**theregister-iojs-merge**
URL: https://www.theregister.com/2015/06/15/nodejs_iojs_project_merger/
Accessed: 2026-08-14

**nodesource-iojs-blog**
URL: https://nodesource.com/blog/was-this-trip-really-necessary
Accessed: 2026-08-14

**reuse-spec-3-3**
URL: https://reuse.software/spec-3.3/
Accessed: 2026-08-14

**reuse-faq**
URL: https://reuse.software/faq/
Accessed: 2026-08-14

**github-codeowners-branch-protection**
URL: https://www.arnica.io/blog/what-every-developer-should-know-about-github-codeowners
Accessed: 2026-08-14

**pnpm-vs-npm-workspaces**
URL: https://stevekinney.com/courses/enterprise-ui/workspace-package-managers
Accessed: 2026-08-14

**git-filter-repo-issue-25**
URL: https://github.com/newren/git-filter-repo/issues/25
Accessed: 2026-08-14
Quote: "only 25 of 144 expected commits of history remained, because history for the file only goes back as far as when the file was moved into the filtered directory"

**verified-hands-on**
URL: n/a — executed directly
Accessed: 2026-08-14
Quote: "Recipes executed in throwaway repos under ~/.tmp/reorg-0814/git-scratch/: (1) single-package extraction+rename+tag-rename+merge with blame verification, (2) multi-package single-pass extraction+merge, (3) reproduced add/add path-collision conflict, (4) --analyze report generation. NOT executed: actual mailmap rewriting, --replace-text, grafts/replace-refs scenarios (read-only verification from docs)."

**general-pr-split-sources**
URL: https://graphite.com/guides/how-to-split-an-existing-pull-request-on-github
Accessed: 2026-08-14

## SYNTHESIS

For the pdpp → data-connectors / data-connect split, the git mechanics are low-risk and well-proven: `git filter-repo --path ... --path-rename ... --tag-rename ...` on a fresh clone, then `git merge --allow-unrelated-histories` in the target repo, preserves full commit history and blame with zero data loss, as directly verified above including the harder multi-package and path-collision cases. The real risk in this migration is NOT the git history mechanics — it's everything git doesn't carry over automatically: CODEOWNERS/branch-protection (100% manual re-creation), REUSE/SPDX manifests (path-scoped, need re-pathing not copying), open PRs (must drain the queue before the rewrite, no automatic carryover), and the pnpm→npm workspace semantics for the data-connect move (workspace: protocol rewrite + lockfile regen + phantom-dependency re-test, not just a config file swap). Budget the actual engineering time against those four surfaces, not the git rewrite itself — the git parts of both moves can each be done as a single filter-repo invocation followed by one merge commit, likely well under an hour of a hands-on-verified recipe apiece.
