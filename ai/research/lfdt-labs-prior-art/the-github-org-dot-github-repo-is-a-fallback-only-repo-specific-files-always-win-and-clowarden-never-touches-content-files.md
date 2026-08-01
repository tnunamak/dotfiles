---
title: "GitHub's org-level .github repo is a pure fallback (repo-specific files always win, never merged/overridden), and CLOWarden never manages content files (CONTRIBUTING/CODEOWNERS/templates/branch protection) — only teams and repo ACLs/visibility — so for PDP-Connect the LFDT-owned governance+.github repos and the lab's own per-repo files occupy fully disjoint territory"
date: 2026-07-21
topic: lfdt-labs-prior-art
tags: [lfdt, pdp-connect, clowarden, dot-github-repo, codeowners, community-health-files, dco, github-governance]
status: draft
sources: [pdp-connect-governance-config, pdp-connect-dot-github-repo, clowarden-cncf-readme-2, github-community-health-docs, github-issue-template-precedence, lfdt-labs-governance-config-2, lfdt-labs-fabric-x-codeowners, lf-decentralized-trust-dot-github, lfdt-labs-governance-repo-files]
source_session: 019f863a-dad6-7783-b8fb-bfbbdde85a11
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

### What PDP-Connect's actual LFDT-owned repos currently contain (ground truth, not a template)

- `github.com/PDP-Connect/governance` currently contains exactly two files: `LICENSE` (Apache-2.0) and `config.yaml`. The full `config.yaml` as of access date: two teams (`lf-staff` — maintainers `jwagantall`, `ryjones`; `pdp-connect-maintainers` — maintainer `ryjones`, members `annakaz`, `artvana`, `tnunamak`) and two repositories declared (`.github` and `governance` itself), each granting both teams `maintain` and setting `visibility: public`. Notably, PDP-Connect's actual product repos (`pdpp`, `data-connect`, `data-connectors`) are **not yet listed** in this config.yaml at all. [pdp-connect-governance-config]
- `github.com/PDP-Connect/.github` currently contains exactly one file: `LICENSE` (Apache-2.0). No README, no CONTRIBUTING.md, no CODE_OF_CONDUCT.md, no issue/PR templates, no `profile/README.md` have been added yet — the org-wide community-health fallback is present as an empty shell, not populated. [pdp-connect-dot-github-repo]
- The PDP-Connect GitHub org has five repos total: `.github`, `governance`, `pdpp`, `data-connect`, `data-connectors`. Only `.github` and `governance` are currently declared in CLOWarden's config.yaml; the three product repos have no CLOWarden-managed ACLs yet. [pdp-connect-governance-config]

### CLOWarden's scope is narrow and does not touch any content file

- CLOWarden's declared config schema (confirmed directly from the maintained README, cross-checked against the real PDP-Connect and LF-Decentralized-Trust-labs config.yaml files) has exactly two top-level keys: `teams` (name/maintainers/members/formation) and `repositories` (name/teams→role/external_collaborators→role/visibility). There is no field anywhere in the schema for file content, branch protection rules, required status checks, labels, Discussions/wiki toggles, issue/PR templates, CODEOWNERS content, or CONTRIBUTING/CODE_OF_CONDUCT text. [clowarden-cncf-readme-2]
- CLOWarden's own warning is explicit about the boundary of what it reconciles: "CLOWarden will remove resources that are not defined in the configuration file (i.e. teams and permissions, but not repositories)" — i.e. even for the two resource types it does manage, it will never delete a *repository*, only team/permission grants on it. Repo creation is one-way (add-only via config); nothing about repo *content* is in scope at all. [clowarden-cncf-readme-2]
- Corollary confirmed by inspecting a real, mature LFDT lab (`fabric-x-block-explorer`): that repo's own `.github/CODEOWNERS` names a GitHub team (`@LF-Decentralized-Trust-labs/fabric-x-block-explorer-maintainers`) that is presumably itself created/populated by CLOWarden's `config.yaml`, but the CODEOWNERS *file content* (which paths map to which team) lives in the product repo's own git history, authored and merged by the lab like any other file — CLOWarden supplies the team as a directory primitive; the lab decides how to wire that team into file-level review routing. [lfdt-labs-fabric-x-codeowners]

### The org .github repo is a fallback, not an override — and this generalizes across two levels at LFDT

- GitHub's own docs are unambiguous on precedence: a repo-specific community health file (CONTRIBUTING.md, CODE_OF_CONDUCT.md, SUPPORT.md, etc.) always wins over the org-level `.github` repo's default; GitHub only serves the org-level default when the individual repo has no file of that type at all, checking `.github/`, then repo root, then `docs/`, in that order, within the individual repo first before ever falling back to the org `.github` repo. [github-community-health-docs]
- This is a strict fallback, never a merge: adding a repo-specific file makes GitHub stop looking at the org default for that file type entirely — there is no partial inheritance. [github-community-health-docs]
- Issue templates have a stricter all-or-nothing variant of the same rule: "if a repository has any files in its own `.github/ISSUE_TEMPLATE` folder... none of the contents of the default `.github/ISSUE_TEMPLATE` folder will be used" — a repo that ships even one custom issue template opts out of the entire org-default template set, not just the one type it customized. [github-issue-template-precedence]
- The org `.github` repo must be public (or internal) for the community-health fallback and PR/issue-template defaults to apply org-wide at all; a private `.github` repo does not populate this mechanism, and PDP-Connect's `.github` repo is already correctly set to public in CLOWarden's config, so the mechanism is live and ready to receive content whenever LFDT or the lab adds it. [github-community-health-docs][pdp-connect-governance-config]
- This same two-tier pattern recurs one level up in the LFDT hierarchy, independent of PDP-Connect: the parent `LF-Decentralized-Trust` org (not `-labs`) has its own `.github` repo containing `logos/` and a `profile/README.md` (used only for the org's public profile page, pointing to the projects/labs directories) but **no** CONTRIBUTING.md or CODE_OF_CONDUCT.md at that level — those Foundation-wide policy documents are referenced externally (e.g. the CNCF/LF-style Code of Conduct doc, DCO, LFX legal docs) rather than being served through the GitHub community-health-file mechanism. The `LF-Decentralized-Trust-labs` org (the labs program, one level below the parent, one level above individual labs like PDP-Connect) has **no `.github` repo at all** (404) — confirming the community-health-file fallback is opt-in per org and LFDT has not enabled it at the labs-program level; each lab is on its own for CONTRIBUTING/CODE_OF_CONDUCT content unless the lab (PDP-Connect) populates its own `.github` repo. [lf-decentralized-trust-dot-github]

### What real LFDT labs actually put where (governance repo vs. product repo vs. nothing)

- The `LF-Decentralized-Trust-labs/governance` repo (the labs-program-wide CLOWarden config repo, one level above any individual lab's own `governance` repo like PDP-Connect's) contains exactly four files: `CODEOWNERS`, `LICENSE`, `MAINTAINERS.md`, `config.yaml` — no README, no CONTRIBUTING.md. Its `CODEOWNERS` gates the whole repo to `@LF-Decentralized-Trust-labs/lab-stewards`, with `config.yaml` itself additionally protected by `@ryjones @LF-Decentralized-Trust-labs/lab-stewards`. This is a config-only, automation-consumed repo with no human-facing documentation — the pattern PDP-Connect's own `governance` repo (LICENSE + config.yaml only) already mirrors exactly. [lfdt-labs-governance-config-2][lfdt-labs-governance-repo-files]
- A real, mature product repo inside the labs program (`fabric-x-block-explorer`) has **no CONTRIBUTING.md and no CODE_OF_CONDUCT.md at all** (both confirmed 404 at repo root) — it relies entirely on whatever org-level `.github` fallback exists (none, per above) or the general LFDT Labs proposal-doc expectations (LICENSE + MAINTAINERS + DCO enforcement) rather than a written CONTRIBUTING doc. Its `.github/` folder contains only `CODEOWNERS` and `workflows/` (CI) — no PR/issue templates either. This shows CONTRIBUTING.md/CODE_OF_CONDUCT.md/templates are conventionally-expected-but-not-universally-present in this ecosystem; LFDT does not appear to hard-gate on their existence. [lfdt-labs-fabric-x-codeowners]
- CODEOWNERS, by contrast, **is** consistently present at the individual-lab-repo level in every example inspected (fabric-x-block-explorer, the labs.github.io meta-repo, the labs-program governance repo, PDP-Connect's own two repos do not yet have one but the pattern is set). CODEOWNERS is a per-repo, lab-authored file every time — it is never templated down from `.github` or `governance`; each lab writes its own path→team mapping referencing whatever team CLOWarden created for it. [lfdt-labs-fabric-x-codeowners][lfdt-labs-governance-repo-files]

## SOURCES

**pdp-connect-governance-config**
URL: https://raw.githubusercontent.com/PDP-Connect/governance/main/config.yaml (repo: https://github.com/PDP-Connect/governance)
Accessed: 2026-07-21
Quote: "teams:\n  - name: lf-staff\n    maintainers:\n      - jwagantall\n      - ryjones\n    members: []\n  - name: pdp-connect-maintainers\n    maintainers:\n      - ryjones\n    members:\n      - annakaz\n      - artvana\n      - tnunamak\nrepositories:\n  - name: .github\n    teams:\n      lf-staff: maintain\n      pdp-connect-maintainers: maintain\n    visibility: public\n  - name: governance\n    teams:\n      lf-staff: maintain\n      pdp-connect-maintainers: maintain\n    visibility: public"

**pdp-connect-dot-github-repo**
URL: https://github.com/PDP-Connect/.github
Accessed: 2026-07-21
Quote: Repo contains only `LICENSE` (Apache 2.0); no README.md, CONTRIBUTING.md, CODE_OF_CONDUCT.md, issue/PR templates, or profile/README.md present (confirmed via GitHub Contents API, single file returned).

**clowarden-cncf-readme-2**
URL: https://github.com/cncf/clowarden
Accessed: 2026-07-21
Quote: "CLOWarden will remove resources that are not defined in the configuration file (i.e. teams and permissions, but not repositories)." Schema: `teams: [{name, maintainers, members, formation}]`, `repositories: [{name, teams: {slug: role}, external_collaborators: {user: role}, visibility}]`, roles `read | triage | write | maintain | admin`.

**github-community-health-docs**
URL: https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file
Accessed: 2026-07-21
Quote: "Default files will be used for any repository owned by the account that does not contain its own file of that type... GitHub checks for the following types of file first in the .github folder, then in the repository's root folder, and finally in the docs folder."

**github-issue-template-precedence**
URL: https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file
Accessed: 2026-07-21
Quote: "If a repository has any files in its own .github/ISSUE_TEMPLATE folder, such as issue templates or a config.yml file, none of the contents of the default .github/ISSUE_TEMPLATE folder will be used."

**lfdt-labs-governance-config-2**
URL: https://raw.githubusercontent.com/LF-Decentralized-Trust-labs/governance/main/config.yaml
Accessed: 2026-07-21
Quote: teams/repositories schema instance with 30+ per-lab `<lab>-maintainers` teams (e.g. `cbweb3-maintainers`, `fabric-x-block-explorer-committers`) each scoped to that lab's own repo.

**lfdt-labs-fabric-x-codeowners**
URL: https://raw.githubusercontent.com/LF-Decentralized-Trust-labs/fabric-x-block-explorer/main/.github/CODEOWNERS (repo: https://github.com/LF-Decentralized-Trust-labs/fabric-x-block-explorer)
Accessed: 2026-07-21
Quote: "# Default owner for everything\n* @LF-Decentralized-Trust-labs/fabric-x-block-explorer-maintainers" — repo root has no CONTRIBUTING.md or CODE_OF_CONDUCT.md (both 404 via Contents API); `.github/` contains only `CODEOWNERS` and `workflows/`.

**lf-decentralized-trust-dot-github**
URL: https://github.com/LF-Decentralized-Trust/.github and https://api.github.com/repos/LF-Decentralized-Trust-labs/.github/contents/ (404)
Accessed: 2026-07-21
Quote: Parent org `.github` repo contents: `.gitignore`, `logos/`, `profile/README.md` (profile README: "Take a look at our approved labs" linking to lf-decentralized-trust-labs.github.io); no CONTRIBUTING/CODE_OF_CONDUCT at that level. The `LF-Decentralized-Trust-labs` (labs program) org has no `.github` repo at all — API returns 404 Not Found.

**lfdt-labs-governance-repo-files**
URL: https://github.com/LF-Decentralized-Trust-labs/governance
Accessed: 2026-07-21
Quote: Repo contents: `CODEOWNERS`, `LICENSE`, `MAINTAINERS.md`, `config.yaml` — no README.md (raw fetch of README.md returns 404). CODEOWNERS: "* @LF-Decentralized-Trust-labs/lab-stewards\nconfig.yaml @ryjones @LF-Decentralized-Trust-labs/lab-stewards"

## SYNTHESIS

For PDP-Connect the boundary is clean and almost entirely non-overlapping, because CLOWarden and the `.github` community-health mechanism solve two unrelated problems with zero shared surface area:

**LFDT/CLOWarden owns (via `PDP-Connect/governance/config.yaml`, PR-gated, Ry-and-lab-stewards-reviewed):** GitHub team existence and membership (who is a maintainer/member of `pdp-connect-maintainers`, `lf-staff`), and which teams get which permission role (`read`/`triage`/`write`/`maintain`/`admin`) on which repos, plus repo visibility (public/private/internal) and repo *existence* (add-only, never auto-deleted). Nothing else. It does not — cannot, by schema — touch branch protection rules, required status checks, CODEOWNERS content, labels, Discussions/wiki toggles, CI workflows, or any file content whatsoever.

**The lab (PDP-Connect) owns per-repo, entirely independently:** CONTRIBUTING.md, CODE_OF_CONDUCT.md, PR/issue templates, CODEOWNERS (content — though it references CLOWarden-created team *names*), branch protection/rulesets (including marking the DCO check required — a GitHub Apps + branch-protection concern, wholly separate from CLOWarden), labels, CI workflows, Discussions/wiki enablement. All of this is normal git content in each product repo (`pdpp`, `data-connect`, `data-connectors`) or, if PDP-Connect chooses to populate it, in `PDP-Connect/.github` as an org-wide fallback default. Real LFDT precedent (fabric-x-block-explorer) shows this is not even mandatory — plenty of mature labs ship no CONTRIBUTING.md/CODE_OF_CONDUCT.md and rely on CODEOWNERS + DCO enforcement alone — so PDP-Connect should feel free to populate `.github` at whatever pace makes sense rather than treating it as a blocking prerequisite.

**Currently live gap, action needed regardless of Ry:** PDP-Connect's three actual product repos (`pdpp`, `data-connect`, `data-connectors`) are not yet declared in `governance/config.yaml` at all — only `.github` and `governance` are. Until that PR lands, `pdp-connect-maintainers` has no CLOWarden-managed access grant on the product repos (access may currently exist only via whatever was set up manually/at repo-creation time, which CLOWarden's periodic reconciliation could eventually revert if it were switched to fully manage those repos without a matching config entry — a real risk to flag).

**CODEOWNERS vs. CLOWarden coexistence, confirmed by direct example (fabric-x-block-explorer):** they operate at different layers with a one-way dependency, not a conflict. CLOWarden creates the team as an org-level primitive (`config.yaml` → `<lab>-maintainers` team with members). CODEOWNERS then references that team by `@org/team-slug` to route file-level PR review. The lab authors CODEOWNERS itself, in its own product repo, same as any code file — it is never templated or synced from `governance`/`.github`. Best practice distilled from the pattern: keep team membership changes in `governance/config.yaml` (PR-reviewed by lab-stewards) and keep path-ownership routing in each repo's own `.github/CODEOWNERS` (PR-reviewed by the repo's own maintainers) — never hardcode individual usernames in CODEOWNERS when a CLOWarden-managed team will do, since that keeps the two files from drifting out of sync when membership changes.

**What to ask Ry vs. what PDP-Connect can just do:**
- Ask Ry: (1) add `pdpp`, `data-connect`, `data-connectors` to `governance/config.yaml` (or confirm PDP-Connect can open that PR itself — CODEOWNERS on the LFDT-labs-program-level `governance` repo suggests `lab-stewards`/Ry review is required for that repo, but PDP-Connect's *own* `governance` repo's CODEOWNERS is currently unset, so it's worth confirming whether PDP-Connect's own maintainers can self-serve edits to their own config.yaml going forward). (2) Confirm DCO app installation status/scope for the PDP-Connect org (org-level GitHub App install requires org-owner rights — likely only LF staff have that) and whether branch protection + required-DCO-check setup on product repos is something the lab can do itself (repo admin, not org-owner, is normally sufficient for that part) or needs LF assistance. (3) Confirm whether LFDT expects/requires PDP-Connect to populate its own `.github` repo with CONTRIBUTING/CODE_OF_CONDUCT/templates, or whether there's a Foundation-wide default PDP-Connect should link to instead (mirroring how the parent `LF-Decentralized-Trust` org's own `.github` has no CoC/CONTRIBUTING and instead points out to Foundation policy pages).
- PDP-Connect can just do, no LFDT involvement needed: author and merge CODEOWNERS in each product repo referencing `@PDP-Connect/pdp-connect-maintainers`; write and merge CONTRIBUTING.md/CODE_OF_CONDUCT.md/issue-PR-templates either per-repo or once in `PDP-Connect/.github` as the org default (repo-specific always wins if both exist later); set up repo-level labels, CI workflows, Discussions/wiki toggles — all standard repo-admin-level settings that don't touch org-level teams or ACLs and are outside CLOWarden's schema entirely.
