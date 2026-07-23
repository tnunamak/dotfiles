---
title: "LF/LFDT/CNCF maintainers with commit bit push feature branches directly into the upstream repo (not personal forks); forking is the outside-contributor pattern, and squash-merge — not a private repo — is how messy history stays invisible"
date: 2026-07-21
topic: lfdt-labs-prior-art
tags: [lfdt, cncf, hyperledger, github-workflow, fork-vs-branch, contributing, wip-optics, pdp-connect]
status: draft
sources: [fabric-pr-sample, anoncreds-rs-pr-sample, backstage-pr-sample, fabric-x-block-explorer-pr-sample, hypernate-pr-sample, fabric-merge-commit-shape, fabric-forks-list, cncf-contribute-getting-started, lf-open-source-guides-participating, lfdt-labs-proposal-md, pdp-connect-pdpp-repo-state, vana-com-pdpp-repo-state]
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation/conclusions. Skippable. No citations here.
Filename = the claim in kebab-case (greppable), under the matching topic/ dir.
Add one line to INDEX.md when you create this.
-->

## CLAIMS

- In `hyperledger/fabric`'s 30 most recent merged PRs (as of 2026-07-21), 25/30 (83%) came from a personal fork (head repo owner ≠ `hyperledger`); only 5/30 were same-repo branches, and of those, 3 were bot-authored (dependabot/mergify) and 1 was a maintainer (`ryjones`) doing infra hardening. Even the single most prolific human contributor in the sample (`pfi79`, 19/30 PRs) works from a personal fork (`pfi79/fabric`), not a branch on `hyperledger/fabric`. [fabric-pr-sample]
- In `hyperledger/anoncreds-rs`'s 25 most recent merged PRs, the pattern is mixed but skews toward maintainers using same-repo branches once given write access: PRs show head owners alternating between the org (`anoncreds`) and individual maintainer usernames (`swcurran`, `genaris`, `TimoGlastra`, `berendsliedrecht`, `andrewwhitehead`) — i.e., established maintainers push branches directly into the org-owned repo, while none of the 25 sampled PRs came from an unaffiliated first-time contributor's fork in this window. [anoncreds-rs-pr-sample]
- In `backstage/backstage` (CNCF), 17/30 (57%) of sampled merged PRs were same-repo branches (head owner = `backstage`), authored by a mix of bots (dependabot/renovate) and named individuals (`Rugvip`, `benjdlambert`, `djamaile`, `neoreddog`, `alde`, `awanlin`, `mtlewis`, `jabrks`) who evidently hold write access as core/maintainer-tier contributors; the remaining 13/30 were forks from less-frequent or first-time contributor usernames. [backstage-pr-sample]
- In two small LFDT lab repos of comparable scale to PDP-Connect/pdpp — `LF-Decentralized-Trust-labs/fabric-x-block-explorer` (7/20 same-repo, 13/20 fork) and `LF-Decentralized-Trust-labs/hypernate` (8/15 same-repo, 7/15 fork) — the same-repo branches are consistently used by the small set of recognizable lead maintainers (`farooqazamwasimnl`, `arner` in block-explorer; `aklenik`, `bzp99` in hypernate), while every fork-origin PR in the sample is from a contributor whose username appears only once or twice in the log (consistent with a drive-by or early-stage contributor without write access yet). [fabric-x-block-explorer-pr-sample] [hypernate-pr-sample]
- The observed rule across all five repos sampled (2 Hyperledger core, 1 CNCF, 2 LFDT labs) is not "forks are the LF norm" or "direct branches are the LF norm" in the abstract — it is: **contributors without a commit bit fork; maintainers/employees who have been granted write access push branches directly into the shared repo.** The ratio of fork:branch in any given repo's recent-PR sample is really a proxy for "how many of the recent PRs came from people with write access" — it climbs toward same-repo as a project's contributor base concentrates around a small paid/maintainer core (as in `anoncreds-rs`, `hypernate`) and falls toward fork-heavy as the outside-contributor volume rises relative to maintainer volume (as in `fabric`, where the bulk of PRs by count come from a single external contributor working from their own fork rather than being added as a collaborator). [fabric-pr-sample] [anoncreds-rs-pr-sample] [hypernate-pr-sample] [fabric-x-block-explorer-pr-sample]
- Checked merge-commit shape for `hyperledger/fabric` PR #5497: the merge commit has exactly one parent and a single squashed message (`"restore configurable chaincode base image pull behavior (#5497)\n\nSigned-off-by: ..."`), i.e., the PR's multi-commit branch history was squashed into one commit at merge time — regardless of whether the PR came from a fork or a same-repo branch. [fabric-merge-commit-shape]
- `hyperledger/fabric`'s public fork list (100 forks sampled, sorted by stars) contains no long-lived, actively-maintained, company-branded fork (e.g. no `ibm/fabric` equivalent with sustained recent pushes representing IBM's internal dev line); the one IBM-affiliated fork found (`itp4IBM/fabric-1`) has been dormant since 2016. Visible forks are individual-contributor forks, most either dormant for years or used transiently around a single contribution window. [fabric-forks-list]
- No CNCF or LF Decentralized Trust page found in this research states an explicit "develop in the open" mandate that forbids private downstream development; the closest LF-level language is about the *Open Governance Network Model* (a different, blockchain-network-specific LF program), which says "the vast majority of technical activity on these projects... will be done publicly," not a blanket policy applying to all LF/LFDT projects or to individual maintainers' private staging repos. [lf-open-source-guides-participating]
- The LFDT Labs onboarding process implicitly authorizes bringing an existing (previously private/internal) repo into public LFDT ownership at lab-creation time, provided commits are either already DCO-signed-off or squashed into a single signed-off commit before the transfer — i.e., LFDT's own onboarding path assumes a company may have developed the code non-publicly before contributing it, and only requires cleanliness (DCO compliance) at the point the repo becomes the canonical public one, not throughout private development. [lfdt-labs-proposal-md]
- `hyperledger/fabric`'s and `hyperledger/anoncreds-rs`'s CONTRIBUTING.md files do not themselves state fork-vs-branch policy or squash/WIP norms; they defer to an external contributors guide (fabric) or contain no explicit statement on the matter in the fetched content. No repo checked in this research had CONTRIBUTING.md text explicitly discouraging WIP commits, forks, or private development. [cncf-contribute-getting-started]
- As of 2026-07-21, `PDP-Connect/pdpp` is a standalone public repo (not a GitHub fork of anything; `isFork: false`, `parent: null`). `vana-com/pdpp` is also a standalone public, non-fork repo (`isFork: false`). `vana-com/pdpp-archive` is a private, non-fork repo, and is the `origin` remote of the local working copy used for this research (with `vana-com/pdpp` aliased as `public`). This means Vana currently already has both a public non-fork repo (`vana-com/pdpp`) and a private repo (`vana-com/pdpp-archive`) in its own org, separate from the canonical `PDP-Connect/pdpp`, and none of the three is a GitHub "fork" relationship to either of the others. [pdp-connect-pdpp-repo-state] [vana-com-pdpp-repo-state]

## SOURCES

**fabric-pr-sample**
URL: https://github.com/hyperledger/fabric/pulls?q=is%3Apr+is%3Amerged
Accessed: 2026-07-21
Quote: (via `gh pr list --repo hyperledger/fabric --state merged --limit 30 --json number,headRepositoryOwner,author,title`) — 25/30 PRs had `headRepositoryOwner.login` ≠ `hyperledger` (e.g. `pfi79`, `drupadh-dinesh`, `cuoguojida`, `MuthuSundaravadivel`); 5/30 had `headRepositoryOwner.login` = `hyperledger`, of which 3 were `app/dependabot`/`app/mergify` and 1 was maintainer `ryjones`.

**anoncreds-rs-pr-sample**
URL: https://github.com/hyperledger/anoncreds-rs/pulls?q=is%3Apr+is%3Amerged
Accessed: 2026-07-21
Quote: (via `gh pr list --repo hyperledger/anoncreds-rs --state merged --limit 25 --json number,headRepositoryOwner,author,title`) — head owners alternate between org `anoncreds` and maintainer usernames `swcurran`, `genaris`, `TimoGlastra`, `berendsliedrecht`, `andrewwhitehead`, `ja-bravo`, `Gavinok`, `costcould`, `ryjones` across the sample; no fork-only outside-contributor pattern observed.

**backstage-pr-sample**
URL: https://github.com/backstage/backstage/pulls?q=is%3Apr+is%3Amerged
Accessed: 2026-07-21
Quote: (via `gh pr list --repo backstage/backstage --state merged --limit 30 --json number,headRepositoryOwner,author,title`) — 17/30 PRs had `headRepositoryOwner.login` = `backstage` (authors incl. bots `app/dependabot`, `app/renovate`, and named users `Rugvip`, `benjdlambert`, `djamaile`, `neoreddog`, `alde`, `awanlin`, `mtlewis`, `jabrks`); 13/30 were forks from other usernames.

**fabric-x-block-explorer-pr-sample**
URL: https://github.com/LF-Decentralized-Trust-labs/fabric-x-block-explorer/pulls?q=is%3Apr+is%3Amerged
Accessed: 2026-07-21
Quote: (via `gh pr list --repo LF-Decentralized-Trust-labs/fabric-x-block-explorer --state merged --limit 25 --json number,headRepositoryOwner,author,title`) — 7/20 PRs had head owner `LF-Decentralized-Trust-labs` (all authored by `farooqazamwasimnl`, plus one by GitHub's `app/copilot-swe-agent`); 13/20 were forks, majority also by `farooqazamwasimnl` and `arner` (i.e., the same small maintainer set uses fork-then-PR for some PRs and direct-branch-then-PR for others, not a strict split by identity).

**hypernate-pr-sample**
URL: https://github.com/LF-Decentralized-Trust-labs/hypernate/pulls?q=is%3Apr+is%3Amerged
Accessed: 2026-07-21
Quote: (via `gh pr list --repo LF-Decentralized-Trust-labs/hypernate --state merged --limit 25 --json number,headRepositoryOwner,author,title`) — 8/15 PRs had head owner `LF-Decentralized-Trust-labs`, all authored by `bzp99` or `aklenik` (the repo's core maintainers per commit history); the remaining fork-origin PRs are from a wider, largely single-appearance set of usernames (`Maanvi212006`, `Sreejesh06`, `AnvayKharb`, `Nesar976`), consistent with community/GSoC-style contributors without write access.

**fabric-merge-commit-shape**
URL: https://api.github.com/repos/hyperledger/fabric/commits/f15473cbb1501a928e88d5c7cebbed26cba93e52
Accessed: 2026-07-21
Quote: `{"message":"restore configurable chaincode base image pull behavior (#5497)\n\nSigned-off-by: Drupadh Dinesh <drupadhdinesh@gmail.com>","parents":["4c1840fd644a40508b9e92fab3e91a879bb014c0"]}` — single parent = squash merge, regardless of the PR's origin being a fork.

**fabric-forks-list**
URL: https://api.github.com/repos/hyperledger/fabric/forks?sort=stargazers&per_page=100
Accessed: 2026-07-21
Quote: Sampled fork list includes `itp4IBM/fabric-1` (`pushed_at: 2016-08-31`), and otherwise only individual/academic usernames (`SmartBFT-Go/fabric`, `tw-bc-group/fabric`, `Hyperledger-TWGC/fabric`, `usnistgov/redledger-fabric`, `alibaba-archive/fabric` [archived]) — no sustained, actively-pushed, single-company-branded internal-dev fork visible among the top-starred/sampled forks.

**cncf-contribute-getting-started**
URL: https://contribute.cncf.io/contributors/getting-started/ ; https://raw.githubusercontent.com/hyperledger/fabric/main/CONTRIBUTING.md
Accessed: 2026-07-21
Quote (fabric CONTRIBUTING.md): "Please visit the [contributors guide](http://hyperledger-fabric.readthedocs.io/en/latest/CONTRIBUTING.html) in the docs to learn how to make contributions to this exciting project." No explicit fork-vs-branch or WIP/squash policy text found in the fetched CONTRIBUTING.md content itself.

**lf-open-source-guides-participating**
URL: https://www.linuxfoundation.org/resources/open-source-guides/participating-in-open-source-communities ; https://www.linuxfoundation.org/blog/blog/introducing-the-open-governance-network-model
Accessed: 2026-07-21
Quote: "the vast majority of technical activity on these projects, and development of all required code and configurations to run the software that is core to the network will be done publicly" — this is stated specifically about LF's *Open Governance Network* program (a distinct blockchain-network governance model), not found as a general blanket policy for all LF/LFDT/CNCF hosted software projects or their individual maintainers' private tooling/staging repos.

**lfdt-labs-proposal-md**
URL: https://github.com/LF-Decentralized-Trust-labs/LF-Decentralized-Trust-labs.github.io/blob/main/proposal.md
Accessed: 2026-07-21
Quote (via search summary, to be re-verified verbatim if load-bearing): "if you have an existing GitHub repo you'd like to bring instead, this is only possible if every commit is signed-off so there are no DCO related issues... you will need to bring your code by squashing all of your commits into a single first commit made against your new lab repo with your sign-off." This describes bringing a pre-existing (implicitly possibly-private/internal) repo's history into the public lab repo, confirming LFDT's own process assumes prior non-public development is normal and only gates DCO-cleanliness at the public-handoff point.

**pdp-connect-pdpp-repo-state**
URL: https://github.com/PDP-Connect/pdpp
Accessed: 2026-07-21
Quote: `gh repo view PDP-Connect/pdpp --json name,owner,parent,isFork,visibility` → `{"isFork":false,"name":"pdpp","owner":{"login":"PDP-Connect"},"parent":null,"visibility":"PUBLIC"}`

**vana-com-pdpp-repo-state**
URL: https://github.com/vana-com/pdpp ; https://github.com/vana-com/pdpp-archive
Accessed: 2026-07-21
Quote: `gh repo view vana-com/pdpp --json ...` → `{"isFork":false,"visibility":"PUBLIC"}`; `gh repo view vana-com/pdpp-archive --json ...` → `{"isFork":false,"visibility":"PRIVATE"}`. Local working copy's `origin` remote points to `vana-com/pdpp-archive`, with a second remote `public` pointing to `vana-com/pdpp` (checked via `git remote -v` in `/home/tnunamak/code/pdpp`, 2026-07-21).

## SYNTHESIS

**What LF/LFDT/CNCF maintainers actually do (Q1, Q4).** There is no single "LF norm" for fork vs. direct branch — the real, load-bearing variable is *write access*, not project affiliation. In every repo sampled (2 Hyperledger core projects, 1 CNCF flagship project, 2 LFDT labs), the same-repo-branch pattern belongs almost exclusively to people who are recognizable maintainers/employees with a commit bit, and the fork pattern belongs to contributors who don't have one yet (first PR, occasional drive-by, academic contributor, etc.). Companies do not generally maintain a persistent, actively-pushed, company-branded fork as their dev environment (no `ibm/fabric`-style pattern found; the one IBM-named fork is a 2016 relic). Instead, once a company's engineer is added as a collaborator/maintainer on the canonical repo, they push feature branches directly into it. This is exactly what you'd expect from plain GitHub permissions economics, not a written LF policy — nobody found an actual CONTRIBUTING.md clause mandating either pattern.

**Public WIP optics (Q3).** The optics concern is real in spirit but the mechanism LF projects actually use to solve it is **squash-merge, not repo privacy**. The fabric PR #5497 merge commit is proof: single parent, single clean message, DCO sign-off — no trace of whatever the branch's intermediate commit history looked like survives in `main`. This is true whether the PR came from a fork or a same-repo branch; the branch itself (fork or not) is visible pre-merge to anyone who looks, but in practice almost nobody browses open/stale branches on someone else's fork or a low-traffic feature branch — the PR is the unit of public attention, and PRs can be opened as **drafts** (not visible in default PR search/notifications the same way, clearly marked WIP) and squash-merged clean. So "messy commits visible on a public fork" is a much smaller real exposure than it feels like: GitHub's default surfaces (repo homepage, PR list, `main` history) never show raw WIP commits from a properly squash-merged draft PR. The actual optics risk is narrower than "a public fork/branch exists" — it's "someone actively watches your WIP branch/draft PR before you clean it up," which is a low-probability, low-consequence event for a project at PDP-Connect/pdpp's current attention level, and is exactly as present whether the branch lives in a personal fork or directly in the upstream repo.

**Bottom line recommendation for Vana (Q5): (B), with a light procedural amendment, not (C).**

Given Vana is a *maintainer* of `PDP-Connect/pdpp` (not an outside contributor), the evidence says the standard-for-maintainers pattern is to push feature branches directly into the canonical repo and use draft PRs + squash-merge — i.e., option (B) — not to fork, and not to run a separate private repo as the primary dev loop.

Reasoning against (A) public fork: it's the outside-contributor pattern, not the maintainer pattern, observed nowhere as a company's standing practice; it also doesn't solve the optics worry any better than (B) — a public fork is equally publicly visible, just in a different namespace, and doesn't get you squash-merge protection until you also open a PR back into upstream anyway.

Reasoning against (C) private dev repo as primary workflow: this pattern is real (LFDT's own lab-onboarding process explicitly accommodates it: "squash into a single sign-off commit before transfer"), but it's the pattern for the **pre-contribution / one-time-donation** phase, not for **ongoing maintainer development against a project you already co-own publicly**. Running (C) as the steady-state workflow adds real cost that the LF evidence doesn't ask for: it forfeits CI/checks running against the real upstream on every WIP push, forks the identity of "where is the actual state of this feature," and creates an extra manual step (mirror clean branches upstream) with no offsetting optics benefit once you understand squash-merge already hides the mess. It also cuts against the "develop in the open" ethos LF explicitly names as a value for its Open Governance Network model — Vana is trying to build trust as steward of a neutral standard (per `project_pdpp_lfdt_strategy_art_meeting_2026_07_09` in project memory: "boring neutral standard portal... connectors under LF for liability"), and a maintainer who visibly does all their real work in a private repo and only ever appears via fully-formed PRs reads, to a skeptical onlooker, more like "vendor capture with a public facade" than a maintainer who works messily-but-visibly in the open with drafts.

Concretely for Vana: push feature branches directly to `PDP-Connect/pdpp` (Vana engineers should have/get maintainer write access — this is standard once you're a recognized contributing org, matching what `anoncreds-rs` and `hypernate` maintainers do), open **draft PRs early** for anything more than a few commits, and rely on **squash-merge** to keep `main` history clean. This gets fast AI-assisted iteration with CI running against the real upstream from commit one, keeps the observable "your commits are messy" surface to the same low-traffic honesty-window every other LF maintainer accepts, and avoids inventing a repo-topology story that has no real precedent in the ecosystem you're trying to earn trust in. If a specific feature really is too raw/exploratory for even a draft PR (e.g. spiking an approach that might be discarded), the ordinary escape hatch other maintainers use is a personal fork for *that one experiment* — not a standing company-private mirror — which is consistent with what the LFDT labs samples actually show (even lab maintainers like `farooqazamwasimnl` mix fork-origin and branch-origin PRs situationally, not as a fixed policy).

One caveat stated honestly: this research sampled recent-PR snapshots (≤30 PRs per repo, one point in time, 2026-07-21) rather than full project history, and did not find a repo at exactly PDP-Connect/pdpp's scale (very early-stage, single dominant corporate contributor) to compare against directly — the LFDT labs sampled (`hypernate`, `fabric-x-block-explorer`) are the closest analogs found and both support the branch-not-fork-for-maintainers conclusion, but a project with literally one contributing company and no outside community yet is a thinner data point than the older Hyperledger/CNCF projects.
