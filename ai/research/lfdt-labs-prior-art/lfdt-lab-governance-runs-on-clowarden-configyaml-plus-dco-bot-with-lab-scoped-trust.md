---
title: "LFDT lab governance runs on CLOWarden's config.yaml for GitHub ACLs plus a DCO bot for sign-off, with day-to-day trust decisions delegated to each lab/project rather than centralized by the Foundation"
date: 2026-07-17
topic: lfdt-labs-prior-art
tags: [lfdt, hyperledger-labs, clowarden, dco, github-governance, cncf, openwallet-foundation, npm-trusted-publishing]
status: draft
sources: [clowarden-cncf-readme, clowarden-lfdt-labs-config, clowarden-openwallet-governance, clowarden-io-site, dco2-cncf-readme, dco-app-original, developercertificate-org, lf-wiki-dco, lfdt-labs-governance-page, lfdt-labs-proposal-md, lfdt-labs-codeowners, lfx-security-onboarding, npm-trusted-publishing-docs, openjsf-trusted-publishing-blog, github-security-manager-role, github-org-owner-guidance, google-oss-github-owners]
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

### CLOWarden: what it is, who owns it, how config.yaml drives ACLs

- CLOWarden is a tool that manages access to resources across multiple services (initial focus: GitHub org repositories); it was built and is maintained by **CNCF** (`github.com/cncf/clowarden`), not by LF Decentralized Trust — LFDT's labs org and at least one other LF-adjacent foundation (OpenWallet Foundation) have adopted the same CNCF tool rather than LFDT authoring its own. [clowarden-cncf-readme][clowarden-openwallet-governance]
- CLOWarden replaced an earlier CNCF tool called Sheriff. [clowarden-cncf-readme]
- CLOWarden's core model: a config repo holds a `config.yaml` (or split files) that is the single source of desired-state truth for **teams** (with `maintainers` and `members`) and **repositories** (with per-team permission levels and `visibility`); a reconciler applies diffs to the live GitHub org, and it also runs periodic reconciliation to catch manual out-of-band changes made via the GitHub UI. [clowarden-cncf-readme]
- Proposed changes to `config.yaml` go through normal GitHub pull requests; CLOWarden validates the diff (schema errors, invalid roles, etc.) and posts feedback as PR comments, so config changes are peer-reviewed the same way code changes are. [clowarden-cncf-readme]
- CLOWarden's config.yaml schema (canonical form, confirmed both from the CNCF docs and from two real deployments — LFDT Labs and OpenWallet Foundation):
  ```yaml
  teams:
    - name: <github_team_slug>
      maintainers:
        - <github_username>
      members:
        - <github_username>

  repositories:
    - name: <github_repository_name>
      teams:
        <github_team_slug>: maintain   # read | triage | write | maintain | admin
      external_collaborators:
        <github_username>: write        # same role vocabulary
      visibility: public                # public | private | internal
  ```
  Constraints: GitHub usernames are case-sensitive; team slugs must be lowercase/numbers/hyphens; a team's `maintainers` must already be org members. [clowarden-cncf-readme]
- The real LFDT Labs governance config (`github.com/LF-Decentralized-Trust-labs/governance`, file `config.yaml`) instantiates this schema at scale: 31 teams and 44 repositories as of access date. Concrete examples pulled from that file: [clowarden-lfdt-labs-config]
  ```yaml
  # team example
  - name: cbweb3-maintainers
    maintainers:
      - carolacnet
    members:
      - BernardoPaniaguaCEMLA
      - JulioRodB
      - MaxMitre
      # ... (39 members total)

  - name: lab-stewards
    maintainers:
      - mbrandenburger
    members:
      - alvaropicazo
      - arsulegai
      - dmueller2001
      # ... (12 members total)

  # repository examples
  - name: cbweb3
    teams:
      cbweb3-maintainers: maintain
      security-managers: read
    visibility: public

  - name: proof-of-process
    teams:
      bots: maintain
      lab-stewards: maintain
      proof-of-process-admins: admin
      proof-of-process-maintainers: maintain
      security-managers: read
    visibility: public
  ```
  Pattern observed: a per-lab `<lab>-maintainers` team gets `maintain` (not `admin`) on its own repo; a global `lab-stewards` team also gets `maintain` on every repo (Foundation-level oversight/rescue capability); a global `security-managers` team gets `read` everywhere (security/compliance visibility without write power); a `bots` team gets elevated (`maintain`/`admin`) access for automation accounts; and some repos define their own `<repo>-admins` team distinct from `<repo>-maintainers`, i.e. admin is a narrower, separately-granted tier even within one lab. [clowarden-lfdt-labs-config]
- The OpenWallet Foundation (a peer LF-adjacent foundation) runs the identical CLOWarden pattern with an explicit, documented naming convention that LFDT's config also follows informally: project-level teams `<project>-admins` (Admin), `<project>-committers` (Maintain), `<project>-contributors` (Triage); repo-level teams `<repo>-admins` (Admin), `<repo>-committers` (Maintain), `<repo>-contributors` (Triage). OWF's governance repo README states the config "can be modified by any maintainer of any OpenWallet Foundation Growth or Impact projects" — i.e., editing the shared ACL config is itself delegated to project maintainers, gated only by normal PR review (which, per the CLOWarden model above, includes CLOWarden's own validation bot). [clowarden-openwallet-governance]
- The public marketing site clowarden.io does not itself list adopting organizations; adoption evidence instead comes from finding real `governance` repos in the wild (LFDT Labs, OpenWallet Foundation) that use it. [clowarden-io-site]

### DCO / DCO Bot enforcement

- The Developer Certificate of Origin (developercertificate.org) is a four-clause certification a contributor makes by adding a `Signed-off-by` line to a commit, asserting: (a) the contribution is original work they have rights to submit under the project's license, OR (b) it is a modification of prior work they have rights to submit under the same (or a permitted different) license, OR (c) it was provided to them by someone who already made certification (a)/(b)/(c) and they haven't modified it, AND (d) they understand and consent that the contribution and a record of the certification are public and maintained indefinitely and may be redistributed consistent with the project/license. [developercertificate-org]
- The DCO originated as the outcome of the SCO v. IBM lawsuit and is git-native: `git commit -s` appends the sign-off line automatically; it requires no CLA paperwork or signup, only that the commit message carries `Signed-off-by: Name <email>` matching the commit author. [dco2-cncf-readme]
- Enforcement mechanism: a GitHub App (originally `dcoapp/app`, CNCF's fork/successor is `cncf/dco2`) posts a GitHub commit status/check on every PR indicating whether **all** commits in the PR carry a valid `Signed-off-by` line matching the author. This is a soft gate by default — GitHub lets the PR exist with a failing check — and only becomes a hard merge-block once the repo's branch protection rules mark that check as a **required status check**. [dco2-cncf-readme][dco-app-original]
- Gerrit-based LF repos are stricter than GitHub: Gerrit will refuse to accept a changeset at all if its commits fail DCO, vs. GitHub which accepts the PR but marks it red. [lf-wiki-dco]
- Remediation paths for a contributor with missing/incorrect sign-off: (1) `git commit --amend -s` for the most recent commit, (2) interactive rebase (`git rebase -i` + `git commit --amend -s` per commit, or `git rebase --exec 'git commit --amend --no-edit -s'`) to sign off multiple commits, or a squash-merge that lets a maintainer/bot rewrite the final merge commit's message. cncf/dco2 additionally offers a **"remediation commit"** feature not present in the original dcoapp/app: it applies sign-off retroactively via a *new* commit rather than rewriting history, so the PR passes without force-pushing over collaborators' work; it supports both individual remediation (author signs off their own past commits) and third-party remediation (an authorized rep signs off on someone else's behalf), both opt-in via `.github/dco.yml`. dco2's config file format is backward-compatible with the original dcoapp/app's config. [dco2-cncf-readme]
- The Linux Foundation's own wiki setup instructions for the DCO app confirm the GitHub-side mechanics: install the DCO GitHub App as an org owner, target all repos (or specific ones), then per-repo enable branch protection on the default branch with "Require status checks to pass before merging" and check the DCO status check. [lf-wiki-dco]
- DCO (lightweight, git-native, no paperwork) is the deliberate alternative to a CLA (heavier: requires an upfront signed agreement, and the project must maintain a roster of signed contributors) — LF-family projects overwhelmingly default to DCO over CLA for exactly this reduced-friction reason. [lf-wiki-dco]

### LF/LFDT posture on admin ACLs: "stingy centrally, trust delegated locally" — partially confirmed, partially inferred

- Confirmed, LFDT-Labs-specific: the Labs program keeps a *separate*, narrowly-scoped `lab-stewards` team that has org-level administrative control over the labs GitHub org, but the proposal document is explicit that stewards "have no oversight of the labs themselves" — their role is strictly to gate entry (approve new lab proposals) and curate for dormancy, not to run day-to-day lab governance. New `<lab>-committers` team members must be added by a `lab-stewards` member (a friction point: individual labs cannot unilaterally add committers without steward action), but each lab is free to determine its own internal contribution/review norms once created — "Labs need not necessarily adopt a strict or formal governance model," except labs aiming to graduate to full-project status, which are advised to formalize. [lfdt-labs-proposal-md][lfdt-labs-governance-page]
- Confirmed generic GitHub/industry guidance, echoed informally by LF ecosystem practice: organization Owner/Admin (the most destructive tier — can delete the org, manage billing, etc.) should be held by very few people (GitHub's own docs say "limited, but to no less than two"; Google's OSS office recommends 2-3 human owners max and explicitly says not to use owner access as a stand-in for team-wide repo access). LFDT's CLOWarden configs operationalize this by almost never granting the `admin` repo-permission tier to a lab's own maintainer team — labs get `maintain` (manage issues/PRs/some settings, no destructive actions) while `admin` is reserved for a distinct, more tightly held `<repo>-admins` team, `bots`, or Foundation-level oversight teams. [github-org-owner-guidance][google-oss-github-owners][clowarden-lfdt-labs-config]
- Not found verbatim as an official LF policy statement: the exact framing "LF is stingy with admin ACLs and leaves it up to each lab to determine who to trust" does not appear as a direct quote in any LFDT/LF governance document surfaced by this research. It is a reasonable **synthesis** of (a) the steward-gatekeeping-only model, (b) the observed CLOWarden permission tiers (maintain, not admin, for lab teams), and (c) general LF/GitHub least-privilege guidance — but should be presented to PDP-Connect stakeholders as an inference from practice, not a cited rule. [lfdt-labs-proposal-md][clowarden-lfdt-labs-config] — CONFIDENCE: medium (pattern is consistent across two independent LF-family orgs — LFDT Labs and OpenWallet Foundation — but no single canonical doc states the principle in those words).
- LFX (the Linux Foundation's own SaaS tooling, distinct from CLOWarden) requires **org-owner** access when onboarding a project to LFX Security or LFX Community Data Platform, and requires the org add `thelinuxfoundation` as an org-level owner for EasyCLA — i.e., the Foundation's own automation tooling is one of the few actors that does get standing org-owner access, separate from and in addition to whatever ACL bot (CLOWarden or manual) a given project uses for human team management. [lfx-security-onboarding][github-org-owner-guidance]

### Governance files present in a healthy LFDT lab repo

- Per the Labs proposal/governance docs, every lab repo is expected to ship at minimum: a `LICENSE` file (Apache-2.0, required), DCO-BOT enabled on the repo (enforced at creation time by stewards, not optional), and a `MAINTAINERS` file listing current maintainers with contact info (contributors are told to reach maintainers via this list). [lfdt-labs-proposal-md]
- The LFDT-labs top-level `.github.io` site repo demonstrates the CODEOWNERS pattern used to gate merges to shared governance content: `* @lf-decentralized-trust-labs/lab-stewards @mbrandenburger @tkuhrt @nidhi-singh02 @alvaropicazo` — i.e. review/merge rights for the whole repo are pinned to the `lab-stewards` team plus a short named allowlist of individuals, not open to all org members. [lfdt-labs-codeowners]
- The `governance` repo itself (the CLOWarden config repo) additionally carries a `CODEOWNERS` file and its own `MAINTAINERS.md`, i.e., the ACL-config repo is governed by the same MAINTAINERS/CODEOWNERS convention as any other lab repo — it is not a black-box the Foundation edits unilaterally; changes flow through normal PR review by whoever CODEOWNERS names. [lfdt-labs-governance-page]
- CONTRIBUTING mechanics observed across LFDT labs: commit sign-off via `-s`/`--amend -s`, submit a PR; to *propose a new lab* specifically, fill out the lab Proposal Template and save it under the labs subdirectory, named after the intended repo name, then get review from ≥2 stewards within about a week. [lfdt-labs-proposal-md]

### npm / package registry ownership when a repo transfers or is adopted by a foundation

- No LF- or LFDT-specific documented pattern for "add an LF bot account as npm/PyPI owner, then re-establish trusted publishing" was found in this research pass — this appears to be an open/undocumented gap in LF tooling rather than an established convention. [npm-trusted-publishing-docs] — CONFIDENCE: low/negative-result; searched directly and found no LF-authored guidance page for this exact scenario.
- General (non-LF-specific) facts that are relevant background: npm Trusted Publishing uses OIDC from a CI provider (e.g., GitHub Actions) so no long-lived `NPM_TOKEN` secret is needed; each package can have only one trusted publisher configured at a time; **transferring package ownership does NOT automatically update the Trusted Publisher configuration** — the new owning account must independently verify it has write access and that the Trusted Publisher's repo/workflow binding is repointed to the new GitHub org/repo. [npm-trusted-publishing-docs]
- The OpenJS Foundation (a Linux Foundation-hosted sibling foundation, JS-ecosystem analogue to LFDT) has published the most concrete cross-foundation guidance available: for small/critical packages, prefer local publishing with 2FA and decommission long-lived tokens once done; for multi-maintainer teams needing CI publishing, harden CI and tightly scope bot-account privileges (a shared bot account trades individual traceability for release-automation convenience); and OpenJS explicitly recommends **deferring** npm Trusted Publishing adoption for security-sensitive/critical packages until the ecosystem's surrounding controls (e.g., enforced 2FA on trusted-publisher-eligible accounts) mature further, citing it would not by itself have stopped attacks like Shai-Hulud. [openjsf-trusted-publishing-blog]

## SOURCES

**clowarden-cncf-readme**
URL: https://github.com/cncf/clowarden
Accessed: 2026-07-17
Quote: "CLOWarden is a tool that manages access to resources across multiple services, with an initial focus on repositories in a GitHub organization... The CNCF initially used Sheriff to manage access to resources... CLOWarden has replaced Sheriff with a system that suits better the needs of the CNCF."

**clowarden-lfdt-labs-config**
URL: https://github.com/LF-Decentralized-Trust-labs/governance/blob/main/config.yaml (also https://raw.githubusercontent.com/LF-Decentralized-Trust-labs/governance/main/config.yaml)
Accessed: 2026-07-17
Quote: "- name: proof-of-process\n  teams:\n    bots: maintain\n    lab-stewards: maintain\n    proof-of-process-admins: admin\n    proof-of-process-maintainers: maintain\n    security-managers: read\n  visibility: public"

**clowarden-openwallet-governance**
URL: https://github.com/openwallet-foundation/governance
Accessed: 2026-07-17
Quote: "This repository utilizes CloWarden to manage the teams and repositories that are part of the OpenWallet Foundation organization." Naming convention: "_project_-admins (Admin), _project_-committers (Maintain), _project_-contributors (Triage)... _repo_-admins (Admin), _repo_-committers (Maintain), _repo_-contributors (Triage)." "This repository can be modified by any maintainer of any OpenWallet Foundation Growth or Impact projects."

**clowarden-io-site**
URL: https://clowarden.io/
Accessed: 2026-07-17
Quote: "CLOWarden is a tool that manages access to resources across multiple services." (no adopter list published on the marketing site)

**dco2-cncf-readme**
URL: https://github.com/cncf/dco2
Accessed: 2026-07-17
Quote: "Once installed, this application will create a check indicating whether or not all commits in a Pull Request contain a valid Signed-off-by line." "Remediation commits... allow applying a sign-off retroactively to one or more commits that failed the DCO check... the repository's history does not change, and there is no risk of breaking someone else's work." "The DCO2 configuration file is backwards compatible with the dcoapp/app configuration file."

**dco-app-original**
URL: https://github.com/dcoapp/app
Accessed: 2026-07-17
Quote: "GitHub App that enforces the Developer Certificate of Origin (DCO) on Pull Requests" — creates a status check; provides an override button for users with write access.

**developercertificate-org**
URL: https://developercertificate.org/
Accessed: 2026-07-17
Quote: "(a) The contribution was created in whole or in part by me and I have the right to submit it under the open source license indicated in the file... (d) I understand and agree that this project and the contribution are public and that a record of the contribution (including all personal information I submit with it, including my sign-off) is maintained indefinitely and may be redistributed consistent with this project or the open source license(s) involved."

**lf-wiki-dco**
URL: https://wiki.linuxfoundation.org/dco
Accessed: 2026-07-17
Quote: "GitHub uses status checks... to ensure that contributions which fail DCO validation will not be merged into a DCO-protected branch (usually 'master')." Setup: "log in as a user with Owner rights to a GitHub organization, browse to https://github.com/apps/dco and hit Install... select All repositories... enable 'Protect this branch' and 'Require status checks to pass before merging,' checking the DCO status check."

**lfdt-labs-governance-page**
URL: https://lf-decentralized-trust-labs.github.io/governance.html
Accessed: 2026-07-17
Quote: "Upon approval by at least 2 stewards, any steward can effectively launch the proposed lab by accepting the Pull Request." "Any permissions to approve pull requests or commit code and any other such privileges associated with labs stewards status will be removed" upon a steward moving to emeritus.

**lfdt-labs-proposal-md**
URL: https://github.com/LF-Decentralized-Trust-labs/LF-Decentralized-Trust-labs.github.io/blob/main/proposal.md
Accessed: 2026-07-17
Quote: "A separate GitHub org 'hyperledger-labs' will be created with the 'labs-stewards' team which will have control over the administrative functions pertaining to the repos created within the org... the Stewards will have no oversight of the labs themselves. Their role is strictly to approve entrance into the program." "...initially created with a LICENSE (ASL 2.0) file within the 'hyperledger-labs' org and that has DCO-BOT enabled to enforce DCO signature." "new -committers team members will need to be added by a member of labs-stewards." "Labs need not necessarily adopt a strict or formal governance model... some minimal and non-zero responsiveness from the lab committers is expected."

**lfdt-labs-codeowners**
URL: https://github.com/LF-Decentralized-Trust-labs/LF-Decentralized-Trust-labs.github.io/blob/main/CODEOWNERS
Accessed: 2026-07-17
Quote: "* @lf-decentralized-trust-labs/lab-stewards @mbrandenburger @tkuhrt @nidhi-singh02 @alvaropicazo"

**lfx-security-onboarding**
URL: https://docs.linuxfoundation.org/lfx/project-control-center/v1-prior-version/tools/security/onboarding-projects-from-github
Accessed: 2026-07-17
Quote: "LFX Security requests read access to administer, code, check commit status, lookup members, and other metadata, plus read and write access to organization hooks, pull requests, and repository hooks." Related EasyCLA doc: "you must be the owner of the GitHub organization which you want to connect."

**npm-trusted-publishing-docs**
URL: https://docs.npmjs.com/trusted-publishers/
Accessed: 2026-07-17
Quote: "Each package can only have one trusted publisher configured at a time" (config can be updated); transferring ownership requires separately verifying the new account has write access and that the Trusted Publisher points to the current GitHub owner/repository.

**openjsf-trusted-publishing-blog**
URL: https://openjsf.org/blog/publishing-securely-on-npm
Accessed: 2026-07-17
Quote: "For security-sensitive packages, [OpenJS recommends] deferring Trusted Publishing until key controls mature." npm's Trusted Publishing is "promising but not ready for critical packages just yet... in its current state would not prevent attacks such as Shai-Hulud."

**github-security-manager-role**
URL: https://docs.github.com/en/organizations/managing-peoples-access-to-your-organization-with-roles/managing-security-managers-in-your-organization
Accessed: 2026-07-17
Quote: "The security manager role... gives permission to view security alerts and manage settings for security features across the organization, as well as read permission for all repositories in the organization."

**github-org-owner-guidance**
URL: https://docs.github.com/en/organizations/managing-peoples-access-to-your-organization-with-roles/roles-in-an-organization
Accessed: 2026-07-17
Quote: "Organization owners have complete administrative access to your organization... this role should be limited, but to no less than two people, in your organization."

**google-oss-github-owners**
URL: https://opensource.google/documentation/reference/github/owners
Accessed: 2026-07-17
Quote: "Organization owners have full access to the organization... we are very cautious about giving more people this access than really need it... GitHub organizations should contain at most 2-3 human owners from the product team."

## SYNTHESIS

For PDP-Connect's onboarding into LFDT, the practical governance stack to replicate is now well-evidenced and mechanical, not bespoke: (1) stand up (or request LFDT staff stand up) a `governance` repo using CLOWarden's `config.yaml` convention — teams named `pdp-connect-maintainers`/`pdp-connect-admins` (or per-repo equivalents), granting the working maintainer team `maintain` (never `admin`) on the actual PDP-Connect repo(s), with `bots`, `lab-stewards`/TAC-equivalent, and `security-managers` teams layered in at `maintain`/`read` for oversight — this is now the default LF-family pattern (seen identically in LFDT Labs and OpenWallet Foundation, both CLOWarden consumers). (2) Enable the DCO app (cncf/dco2 preferred over the older dcoapp/app for its non-destructive remediation-commit feature) on day one, with branch protection marking the DCO check as required — this is table stakes and near-universal across LF repos, cheaper than a CLA, and the "amend -s / rebase --signoff / remediation commit" playbook should go straight into PDP-Connect's CONTRIBUTING doc so first-time contributors aren't stuck. (3) Ship the four baseline governance files LFDT expects by convention (not by hard technical gate, but by steward review expectation): `LICENSE` (Apache-2.0), `MAINTAINERS.md`, a `CODEOWNERS` pinning merge rights to the maintainer team plus a short named list (mirrors the labs.github.io pattern), and a CONTRIBUTING doc covering DCO sign-off. (4) On admin ACLs: do not expect or request org-owner/repo-admin access for PDP-Connect's own maintainers as a matter of course — the evidenced LF pattern reserves `admin` for a narrower, separately-granted tier (often a `<repo>-admins` team distinct even from `<repo>-maintainers`, plus bots and Foundation-level rescue teams), while day-to-day maintainer work runs on `maintain`. This should be presented to the PDP-Connect team as inferred-from-practice (two independent confirmed deployments) rather than as a quoted LF policy, since no single canonical doc states "stingy centrally, trust delegated locally" in those words. (5) The npm/package-registry-ownership-on-transfer question is a genuine gap — there is no LF- or LFDT-authored playbook for repointing Trusted Publishing after a foundation-hosted repo transfer. If PDP-Connect ships an npm package under an LF-owned repo, budget explicit engineering time to (a) verify npm Trusted Publisher OIDC bindings after any GitHub org/repo move, since transfer does not auto-update them, and (b) follow OpenJS's more conservative sibling-foundation guidance (2FA + short-lived tokens over Trusted Publishing) until the ecosystem's supply-chain controls mature further, rather than assuming LF has already solved this for us.
