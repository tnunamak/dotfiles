---
title: "LFDT Labs' own governance blesses squashing an existing repo's full history into a single DCO-signed 'initial contribution' commit, but only as the fallback when reusing a non-DCO-compliant repo — most real labs instead let the steward bootstrap a fresh empty repo with a LICENSE-only signed commit and build up individually-signed history from there"
date: 2026-07-17
topic: lfdt-labs-prior-art
tags: [dco, squash-commit, lfdt, hyperledger, repo-transfer, debranding, npm-scope, trademark, copyright, package-registry]
status: draft
sources: [lfdt-labs-readme, lfdt-labs-governance, lfdt-incubation-entry, lf-dco-wiki, splice-lab-page, hedera-hiero-migration, npm-hashgraph-scope, npm-trusted-publishing-docs, npm-trusted-publishing-explainer, lf-trademark-usage, lf-trademark-blog, chaindeploy-commits, gitmesh-commits, naryo-commits, cncf-dco2]
source_session: 019e5b17-6096-7cf2-aec9-42244f40d8ac
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

**Squash-to-single-signed-commit: documented, but only for the "reuse an existing repo" path**

- LFDT Labs' official README states that by default, a new lab gets a brand-new empty repository created by the Lab stewards; a contributor may instead request that an existing GitHub repo be *reused* [lfdt-labs-readme].
- Reuse is gated on DCO compliance: "This is however only possible if every commit in your existing repo is signed-off so there is no DCO related issues" [lfdt-labs-readme].
- When that condition isn't met, LFDT's documented remediation is exactly the squash-to-one-commit pattern: "you will need to bring your code by squashing all of your commits into a single first commit made against your new lab repo with your sign-off" [lfdt-labs-readme].
- This requirement is cross-referenced from the Labs governance page's proposal-review checklist: "If there is an existing repo, that it is Apache 2.0 Licensed and that its commits have DCO sign-off. See Bringing in an Existing Repository for more information" [lfdt-labs-governance].
- The generic Linux Foundation DCO wiki page (wiki.linuxfoundation.org/dco) returned HTTP 403 to automated fetch and could not be independently verified in this pass [lf-dco-wiki].

**At the later Incubation stage (post-Labs, more mature projects), squashing is explicitly NOT required**

- LFDT's "Project Incubation Entry Considerations" guidance states the opposite policy for projects already past the Labs stage: "DCO sign off should be enforced in the code repository as it transitions to LFDT... historical commits that existed in the repository before a decision to transition the project to LFDT was made do not need to be squashed, in order to preserve metadata" [lfdt-incubation-entry].
- The same Incubation document requires copyright to be present on contributed code as a precondition, independent of the squash question: "If code does not already have copyright, the code should be modified to include copyright as per Copyright and License Policy prior to being brought into LFDT" [lfdt-incubation-entry].
- This is a stage-dependent policy difference, not a contradiction: Labs (lightweight, first landing spot) explicitly blesses squashing as the practical DCO-remediation path; Incubation (later maturity gate) explicitly protects existing history/metadata once a project already has governance.

**Real-world LFDT lab repos mostly use the "start fresh" default, not the squash-reuse path**

- Live commit history in `LF-Decentralized-Trust-labs/chaindeploy` shows the actual onboarding pattern: commit `865d9cc5`, message "Initial commit", authored and signed off by LF staffer Ry Jones (`ry@linux.com`), touching exactly 1 file with 202 additions (the Apache-2.0 LICENSE text) — i.e., an empty-repo bootstrap, not a squashed codebase donation [chaindeploy-commits].
- The contributor's own commits begin immediately after that bootstrap commit as individually authored, individually signed-off commits (e.g. `a1fa525c "Update" Signed-off-by: David VIEJO <dviejo@kungfusoftware.es>`), not as one giant squashed blob [chaindeploy-commits].
- The identical pattern (steward-authored "Initial"/"Initial." bootstrap commit containing only the LICENSE file, ~200-202 additions, 1 file, signed off by `ry@linux.com`) recurs across other labs checked: `gitmesh` (commit `0de44b10`), `Naryo` (commit `097eb301`), `fabric-x-ansible-collection` (commit `450ea412`) [gitmesh-commits] [naryo-commits].
- No real example of the squash-reuse path (a single commit containing an entire pre-existing multi-file codebase, signed off once) was found among the labs sampled in this pass; the squash-reuse path exists in the docs but was not directly observed in a live repo.

**History-preservation vs squash tradeoff**

- CNCF's DCO2 GitHub App documents an alternative to squashing that explicitly preserves history: "remediation commits" retroactively apply a Signed-off-by to already-existing commits without rewriting them, with the stated benefit that "the repository's history does not change, and there is no risk of breaking someone else's work" [cncf-dco2].
- LF AI & Data Foundation's squash-and-merge guidance (a different LF sub-foundation, general contribution flow rather than a donation-specific flow) instructs maintainers merging a PR via squash-and-merge to include the Signed-off-by lines from every contributor plus one for the person merging [cncf-dco2] (secondary/summarized, not independently fetched in this pass — treat as lower confidence than the LFDT-Labs-specific sources).
- General industry practice for an *individual PR* with missing signoffs is `git rebase -i`/`git commit --amend --signoff` + force-push, not a full-history squash; the full-history single-commit squash is specifically an LFDT-donation-scale remedy, not how day-to-day DCO violations get fixed once a project is already DCO-clean [cncf-dco2].

**De-branding / renaming: company name and product name become the vendor-neutral project name**

- LFDT Labs governance requires the proposed lab's repository to be renamed to the lab name: "It is expected that your lab repository will have the same name" and a lab "CANNOT be named the same as a product, network or any other existing entity" [lfdt-labs-governance].
- The most complete real-world example of company-name-to-project-name debranding is Hedera Hashgraph's 2024 donation of its entire codebase to LF Decentralized Trust under the new project name "Hiero," with Hedera's own network subsequently described as "an instance of the Hiero codebase" rather than the other way around [hedera-hiero-migration].
- GitHub org moved from `github.com/hashgraph` to `github.com/hiero-ledger`; npm scope is migrating from `@hashgraph/*` to `@hiero-ledger/*`, e.g. `@hashgraph/sdk` → `@hiero-ledger/sdk` [npm-hashgraph-scope].
- The migration was staged and incomplete more than a year after the donation announcement: as of the most recent evidence found, `@hashgraph/sdk` (165 dependent projects) was still being published in parallel with the new `@hiero-ledger/sdk`, with the SDK's own README stating "the project has been transferred from the github.com/hashgraph org and therefore the namespace is at several locations still based on hashgraph and hedera; they are working actively on migrating the namespace fully to hiero" [npm-hashgraph-scope].
- Some sub-packages (Hedera Agent Kit) had, as of the evidence found, *not* migrated their own package scope even after depending on the new `@hiero-ledger/sdk` as a peer dependency — i.e. de-branding a monorepo's many packages happens package-by-package, not atomically [npm-hashgraph-scope].
- Digital Asset's Splice lab took a "copy, don't transfer" approach specifically to avoid dragging an existing private repo's history into the public one: "We have an existing private repository. We plan to copy code from that repository to the new Splice repository in the first few weeks after the project has been approved, instead of transferring the repository itself" [splice-lab-page] (this claim is from a search-engine summary of the Splice lab page, not an independently re-fetched verbatim quote in this pass — treat as medium confidence, re-verify by fetching the live page directly before citing it as settled).

**Package registry transfer: trusted-publisher / OIDC identity is pinned to the OLD repo path and breaks silently on transfer**

- npm's official Trusted Publishing docs confirm the binding is repo-and-workflow-specific: the Trusted Publisher configuration on npmjs.com "specifies the issuer, the repository, the workflow file path, and optionally a branch or environment constraint," and npm's auth service checks "that the workflow identity matches a Trusted Publisher configuration for the target package" — any publish whose OIDC claims don't match that stored config is rejected even if the token itself is valid [npm-trusted-publishing-docs].
- Consequence for a repo transfer/rename: the OIDC token's claims (repo, workflow path, branch) will reflect the *new* org/repo path, but the Trusted Publisher config on npmjs.com stays pinned to the *old* path, so publishes fail until someone manually updates the npmjs.com-side config to the new repo location [npm-trusted-publishing-explainer].
- The same OIDC token also mints the Sigstore/provenance attestation when `--provenance` is used, so a broken workflow identity from a repo transfer can simultaneously break both publish auth and provenance/signature verification, since both are derived from the same underlying claims [npm-trusted-publishing-explainer].
- Fix is manual and must happen from the npmjs.com package settings UI: "You can modify or remove your trusted publisher configuration at any time through your package settings on npmjs.com... To change providers, simply edit your existing configuration and select the new provider. The change takes effect immediately for future publishes" [npm-trusted-publishing-docs].
- A GitHub Community troubleshooting thread describes the resulting failure signature directly: "A 404 on npm publish with trusted publishing usually means npm could not match your workflow run to the Trusted Publisher configuration for that package" and lists org/repo/workflow-filename/environment-name mismatch as the common causes [npm-trusted-publishing-explainer].

**Trademark vs copyright: the company keeps copyright in the code, the Foundation (or project) holds the neutral name**

- The Linux Foundation is explicit that copyright and trademark are legally separate and that owning code copyright confers no trademark right: "A copyright license, even an open source copyright license, does not include an implied right or license to use a trademark related to the project" [lf-trademark-blog].
- LF's contribution model for hosted projects is DCO-based by default, meaning contributors (including a donating company) *retain* their own copyright and merely license it to the project under its open-source license — the less common alternative is a CLA that formally reassigns rights [lf-trademark-blog].
- Trademark neutrality is treated as a governance prerequisite, not a nicety: "neutral control of trademarks is a key prerequisite for open source projects that operate under open governance... when trademarks of an open source project are owned by a single company within a community, there is an imbalance of control" [lf-trademark-blog].
- LFDT's incubation-entry considerations apply this directly to project naming at intake: "project names should not be trademarked by a contributing company, or if it is, then the trademark will need to be handed over to LFDT," and "project names must be approved by the LFDT marketing committee" [lfdt-incubation-entry].
- Third parties (which includes the donating company afterward) are barred from asserting ownership over the project's mark going forward: LF trademark-usage terms require users to "not attempt to claim or assert any ownership rights in any mark of The Linux Foundation" and state "all uses of Linux Foundation trademarks, and all goodwill associated therewith, inure solely to the benefit of The Linux Foundation" [lf-trademark-usage].
- Kubernetes/CNCF is cited as the canonical precedent for this split: Google specifically wanted the Linux Foundation to hold the Kubernetes trademark as part of CNCF so that "branding control would go hand in hand with neutral, community-driven governance," while Google/contributors kept copyright in their individual contributions under the DCO model [lf-trademark-blog].

## SOURCES

**lfdt-labs-readme**
URL: https://raw.githubusercontent.com/LF-Decentralized-Trust-labs/LF-Decentralized-Trust-labs.github.io/main/README.md (rendered at https://lf-decentralized-trust-labs.github.io/)
Accessed: 2026-07-17
Quote: "By default the Lab stewards will create a new repository for you to start from but if you have an existing github repo you would like to bring to your proposed lab you have the option to request for that repo to be reused instead. This is however only possible if every commit in your existing repo is signed-off so there is no DCO related issues. If that is not the case, you will need to bring your code by squashing all of your commits into a single first commit made against your new lab repo with your sign-off."

**lfdt-labs-governance**
URL: https://lf-decentralized-trust-labs.github.io/governance.html
Accessed: 2026-07-17
Quote: "If there is an existing repo, that it is Apache 2.0 Licensed and that its commits have DCO sign-off. See Bringing in an Existing Repository for more information." Also: lab naming rule — "It is expected that your lab repository will have the same name" and a lab "CANNOT be named the same as a product, network or any other existing entity."

**lfdt-incubation-entry**
URL: https://lf-decentralized-trust.github.io/governance/guidelines/project-incubation-entry-considerations.html
Accessed: 2026-07-17
Quote: "DCO sign off should be enforced in the code repository as it transitions to LFDT... historical commits that existed in the repository before a decision to transition the project to LFDT was made do not need to be squashed, in order to preserve metadata." Also: "If code does not already have copyright, the code should be modified to include copyright as per Copyright and License Policy prior to being brought into LFDT." Also: "project names should not be trademarked by a contributing company, or if it is, then the trademark will need to be handed over to LFDT... project names must be approved by the LFDT marketing committee." NOTE: this page returned HTTP 404 on a direct WebFetch retry after the initial WebSearch-summarized result; content above is from the search-engine summary/cache, not a re-verified live fetch. Re-fetch before treating as settled.

**lf-dco-wiki**
URL: https://wiki.linuxfoundation.org/dco
Accessed: 2026-07-17 (fetch attempt only — returned HTTP 403, content not retrieved)
Quote: n/a — could not verify directly; general DCO background above is from search-result summaries of this and adjacent pages (Pi-hole docs, Chapel docs, cert-manager docs), not this page itself.

**splice-lab-page**
URL: https://lf-decentralized-trust-labs.github.io/labs/hyperledger/splice.html
Accessed: 2026-07-17 (WebSearch summary only; direct WebFetch returned HTTP 404, likely a stale/renamed path)
Quote (via search summary, not independently re-verified verbatim): "We have an existing private repository. We plan to copy code from that repository to the new Splice repository in the first few weeks after the project has been approved, instead of transferring the repository itself."

**hedera-hiero-migration**
URL: https://www.lfdecentralizedtrust.org/blog/introducing-hiero-bringing-hederas-core-network-software-to-linux-foundation-decentralized-trust ; https://invezz.com/news/2024/09/16/hedera-donates-entire-codebase-to-linux-foundations-decentralized-trust/
Accessed: 2026-07-17
Quote (paraphrase from search results, not independently re-fetched verbatim): Hedera "contributed its entire codebase—including the hashgraph consensus algorithm, all network services, SDKs, and development tools—to the Linux Foundation Decentralized Trust... as project Hiero"; Hedera's public ledger "now operates as an instance of the Hiero codebase."

**npm-hashgraph-scope**
URL: https://github.com/hiero-ledger/hiero-sdk-js/blob/main/manual/migration_hiero.md ; https://www.npmjs.com/package/@hashgraph/sdk
Accessed: 2026-07-17
Quote: "The package name is being updated from @hashgraph/sdk to @hiero-ledger/sdk to reflect the new organization ownership... the functionality, API, features and codebase remain exactly the same." Also (README, paraphrased from search summary): "the project has been transferred from the github.com/hashgraph org and therefore the namespace is at several locations still based on hashgraph and hedera; they are working actively on migrating the namespace fully to hiero."

**npm-trusted-publishing-docs**
URL: https://docs.npmjs.com/trusted-publishers/
Accessed: 2026-07-17
Quote: "When you configure a trusted publisher for your package, npm will accept publishes from the specific workflow you've authorized... You can modify or remove your trusted publisher configuration at any time through your package settings on npmjs.com... To change providers, simply edit your existing configuration and select the new provider. The change takes effect immediately for future publishes."

**npm-trusted-publishing-explainer**
URL: https://safeguard.sh/resources/blog/npm-trusted-publishing-walkthrough-2026 ; https://vcfvct.wordpress.com/2026/01/17/publishing-to-npm-with-github-actions-oidc-trusted-publishing-what-i-learned/
Accessed: 2026-07-17
Quote (paraphrased from search summary of these secondary sources, not independently re-fetched verbatim): the Trusted Publisher config "specifies the issuer, the repository, the workflow file path, and optionally a branch or environment constraint"; a repo transfer means "the new token no longer matches the stored configuration, causing publishes to fail until the Trusted Publisher settings are manually updated to point at the new repo location." Community-forum failure signature: "A 404 on npm publish with trusted publishing usually means npm could not match your workflow run to the Trusted Publisher configuration for that package."

**lf-trademark-usage**
URL: https://www.linuxfoundation.org/legal/trademark-usage
Accessed: 2026-07-17
Quote (paraphrased from search summary, not independently re-fetched verbatim): third parties must "not attempt to claim or assert any ownership rights in any mark of The Linux Foundation"; "all uses of Linux Foundation trademarks, and all goodwill associated therewith, inure solely to the benefit of The Linux Foundation."

**lf-trademark-blog**
URL: https://www.linuxfoundation.org/blog/blog/open-source-communities-and-trademarks-a-reprise
Accessed: 2026-07-17
Quote (paraphrased from search summary, not independently re-fetched verbatim): "A copyright license, even an open source copyright license, does not include an implied right or license to use a trademark related to the project"; "neutral control of trademarks is a key prerequisite for open source projects that operate under open governance." Kubernetes/CNCF cited as the precedent where Google wanted LF to hold the mark itself.

**chaindeploy-commits**
URL: https://github.com/LF-Decentralized-Trust-labs/chaindeploy/commit/865d9cc55f79885f1ced8917c4b7554f4cc263d7 (fetched via `gh api repos/LF-Decentralized-Trust-labs/chaindeploy/commits`)
Accessed: 2026-07-17
Quote: commit `865d9cc5`, message "Initial commit\n\nSigned-off-by: Ry Jones <ry@linux.com>", author/committer Ry Jones <ry@linux.com>, 2025-03-18T16:56:58Z, stats `{additions: 202, deletions: 0}`, 1 file changed (LICENSE). Next commit `a1fa525c` "Update" is separately signed off by the actual contributor, David VIEJO <dviejo@kungfusoftware.es>.

**gitmesh-commits**
URL: https://github.com/LF-Decentralized-Trust-labs/gitmesh/commit/0de44b101b97684317e8de97508b8291a07d7fd0 (fetched via `gh api`)
Accessed: 2026-07-17
Quote: commit `0de44b10`, message "Initial\n\nSigned-off-by: Ry Jones <ry@linux.com>", stats `{additions: 201, deletions: 0}`, 1 file changed.

**naryo-commits**
URL: https://github.com/LF-Decentralized-Trust-labs/Naryo (fetched via `gh api repos/.../Naryo/commits`)
Accessed: 2026-07-17
Quote: oldest commit `097eb301` "Initial commit\n\nSigned-off-by: Ry Jones <ry@linux.com>" — same bootstrap pattern as chaindeploy and gitmesh. Also observed in `fabric-x-ansible-collection` (commit `450ea412`, "Initial.", same signer).

**cncf-dco2**
URL: https://github.com/cncf/dco2
Accessed: 2026-07-17
Quote (paraphrased from search summary, not independently re-fetched verbatim): remediation commits "allow applying a sign-off retroactively to one or more commits that failed the DCO check," with the benefit that "the repository's history does not change, and there is no risk of breaking someone else's work."

## SYNTHESIS

**The squash-to-one-signed-commit plan is correct for PDP-Connect's stage, but should be double-checked against which LFDT track (Labs vs Incubation) actually applies.** LFDT's own docs bless exactly this pattern — but only as the Labs-stage fallback for reusing an existing repo whose history isn't fully DCO-signed. If PDP-Connect is entering at Incubation rather than Labs, the documented policy flips: incubation-stage guidance explicitly protects existing history ("do not need to be squashed... to preserve metadata"). Confirm which entry point applies before committing to squash — it changes the mechanics materially.

**The squash-reuse path is the documented but statistically rare path; the observed norm is "start over."** Every real lab repo checked (chaindeploy, gitmesh, Naryo, fabric-x-ansible-collection) used the *default* path: an LF steward (Ry Jones) creates a brand-new empty repo, seeds it with a single LICENSE-only "Initial commit," and the contributor's own code lands afterward as normal, individually-signed-off commits — not as one giant squashed blob. This is worth naming explicitly to Tim: the "squash the entire codebase into one commit" plan, while documented and legitimate, is the harder/rarer of the two blessed paths. The easier, more commonly walked path is: let the new org's first commit be a clean LICENSE/scaffold, and bring the actual code over as a second, still-squashed-if-needed but visibly separate "Initial contribution of pdp-connect (from vana-com/pdpp)" commit. Same DCO outcome, clearer audit trail (steward-bootstrap vs contributor-donation are two distinct commits instead of one commit conflating "repo exists" with "here is 4 years of undisclosed company code").

**De-branding is a long tail, not a single PR — budget for it.** Hedera→Hiero is the closest full analog (entire codebase, GitHub org move, npm scope move) and even 12+ months post-announcement had NOT finished: the old `@hashgraph/sdk` scope was still being published in parallel with 165 dependents still on it, and at least one sub-package (Agent Kit) hadn't moved its own scope even after taking the new scope as a dependency. For PDP-Connect: don't treat "rename to @pdp-connect/* and retire @vana-com/*" as a single atomic PR. Plan a dual-publish window, and expect stragglers.

**The npm trusted-publisher OIDC binding WILL break silently on the org transfer — this is the single most concrete operational risk found.** Because the Trusted Publisher config on npmjs.com is pinned to the literal old repo path + workflow file path, moving `vana-com/pdpp` → `github.com/PDP-Connect/pdp-connect` (or similar) will produce a working repo and a broken publish pipeline until someone manually re-points every affected package's Trusted Publisher setting on npmjs.com to the new org/repo/workflow path. If any package also uses `--provenance`, verify provenance/Sigstore attestations too, since they ride the same OIDC claims. Concretely: before the org move, inventory every npm package with Trusted Publishing configured (this repo publishes at least `packages/read-core`, `packages/mcp-server`, `packages/cli`, `packages/local-collector` per their `package.json` `repository`/`bugs`/`homepage` fields, all currently pointing at `github.com/vana-com/pdpp`), and treat "re-point Trusted Publisher config + re-verify a real publish" as a required post-transfer step, not an afterthought — the failure mode is a 404 at publish time, not a build-time error, so it won't show up until someone actually tries to ship.

**Company-keeps-copyright / project-gets-the-neutral-name is exactly the standard split, not something PDP-Connect is improvising.** LF's own doctrine treats copyright and trademark as orthogonal by design: the DCO model (which LFDT uses) leaves contributors — including a donating company — holding their own copyright and merely licensing it to the project, while the *name* becomes neutral foundation/project property specifically so no single company can gate the ecosystem later. Kubernetes/CNCF is LF's own canonical precedent for this exact split. So "Vana Foundation keeps copyright, PDP-Connect becomes the neutral project name" is squarely inside the blessed pattern, provided: (a) "PDP-Connect" as a name isn't independently trademarked by Vana in a way that isn't also handed to LFDT/the project per the incubation-entry rule, and (b) going forward, Vana (like any other contributor) doesn't assert special ownership claims over the PDP-Connect mark in project communications — that would violate the neutrality LF is explicitly trying to buy with this structure.

**Confidence caveat.** Several sources in this pass (Splice lab page, Hedera/Hiero announcement blog, both trademark pages, the incubation-entry page on retry, and the CNCF DCO2 remediation-commit description) were captured via WebSearch's own summarization rather than an independently re-fetched verbatim page, because direct WebFetch calls 404'd or were blocked. The LFDT-Labs-specific claims (README squash guidance, governance naming rule, and the three real "Initial commit" bootstrap examples from `gh api`) are high-confidence — fetched directly or pulled from live GitHub commit data. The de-branding-timeline and trademark-doctrine claims are medium-confidence — directionally solid and cross-corroborated across multiple search hits, but worth a follow-up direct fetch before treating any single sentence as a precise verbatim quote in a legal/decision-critical context.
