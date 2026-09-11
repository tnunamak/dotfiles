---
title: "NeutArr is a maintained Newtarr successor but community consensus is limited"
date: 2026-09-09
topic: self-hosting
tags: [newtarr, neutarr, media, registry]
status: draft
sources: [project, release, community, upstream, registry]
source_session: unknown
---

## CLAIMS

- NeutArr documents its lineage through ElfHosted Newtarr and keeps the missing-media/quality-search helper role. Its stable README documents trusted-proxy authentication. [project]
- Stable release1.11.1 was published July29,2026; Docker Hub tag metadata for iampuid0/neutarr:1.11.1 returned200 on September9. [release]
- A TrueNAS community participant recommended NeutArr after reporting Newtarr maintenance/image trouble. This is an individual recommendation, not a community vote. [community]
- ElfHosted's February announcement called its rolling image public but explicitly offered no expectation of ongoing support. [upstream]
- ElfHosted's own dependency dashboard reports authentication warnings and lookup failures for several of its base images. [registry]

## SOURCES

**project**
URL: https://github.com/I-am-PUID-0/NeutArr/blob/1.11.1/README.md
Accessed: 2026-09-09

**release**
URL: https://github.com/I-am-PUID-0/NeutArr/releases/tag/1.11.1
URL: https://hub.docker.com/v2/repositories/iampuid0/neutarr/tags/1.11.1
Accessed: 2026-09-09

**community**
URL: https://forums.truenas.com/t/notice-to-huntarr-users/63950
Accessed: 2026-09-09

**upstream**
URL: https://store.elfhosted.com/blog/2026/02/24/huntarr-ends-its-hunt-newtarr-takes-it-up/
Accessed: 2026-09-09

**registry**
URL: https://github.com/elfhosted/containers/issues/567
Accessed: 2026-09-09

## SYNTHESIS

NeutArr is a credible successor candidate, not a proven drop-in replacement or unanimous community choice. Test a copied configuration with searches disabled and verify SSO boundaries before cutover. Preserve the existing image and data until rollback is verified. Current ElfHosted anonymous-access failures affect several images; public evidence does not identify who changed visibility or prove whether Newtarr was deleted. Do not confuse the historical missing latest tag with package-wide authorization failure.

Cleanuparr is a more widely adopted alternative: its [Seeker documentation](https://cleanuparr.github.io/docs/configuration/seeker/) covers scheduled missing-media and upgrade searches for Radarr and Sonarr. It does not establish equivalent Readarr coverage. [Community discussion](https://www.reddit.com/r/selfhosted/comments/1rw0tja/help_me_decide_on_a_huntarr_replacement/) names several competing successors, not a single consensus. Accessed September 9, 2026.

Local read-only inspection on September 9 found enabled Newtarr instance records for Radarr, Sonarr, and Readarr. These records do not prove that all endpoints remain live. NeutArr is the closer feature match if Readarr remains required; Cleanuparr deserves consideration if only Radarr and Sonarr are actually used.

### Adoption and momentum snapshot — September 9, 2026

Live GitHub API metadata: NeutArr has 91 stars and 3 forks (repository created March 2, 2026); Cleanuparr has 2,532 stars and 53 forks (created November 5, 2024). These measure attention and participation, not installed users or security. Latest stable releases are NeutArr 1.11.1 on July 29 and Cleanuparr v2.10.5 on August 12. NeutArr's latest default-branch commit is July 29 despite an August 31 repository push timestamp. Cleanuparr's September 8 commits include substantive Seeker episode-grab reporting and dead-torrent fixes, not only bot maintenance. Sources: each repository's GitHub REST repository, releases, and commits endpoints. Cleanuparr is the stronger momentum choice; NeutArr's advantage is feature continuity, not ecosystem size.

### Corrected deployment findings and decision — September 9, 2026

The enabled Readarr entries are stale, not evidence of current Readarr use. Host Compose records Bookshelf retirement on August 11 and migration to Chaptarr. Both old names fail DNS in current Newtarr logs. Chaptarr and two custom Searcharr bots are running; the existing read-only book-stack verifier passes Telegram, lookup, root and profile checks. Searcharr explicitly submits initial BookSearch requests after adding a book. Chaptarr RSS logs show successful approximately 15-minute polling. Its scheduler has no recurring missing/cutoff sweep. That absence alone is not a fault: [Servarr's Readarr FAQ](https://github.com/Servarr/Wiki/blob/master/readarr/faq.md#how-does-readarr-work) explains initial search plus RSS as the baseline architecture. This is inherited architectural guidance, not a Chaptarr endorsement of any helper.

NeutArr 1.11.1 API functions were exercised in memory against live authenticated Chaptarr GETs, with every POST intercepted. Two base URLs, `http://chaptarr:8789/readarr/hc/ebook` and `http://chaptarr:8789/readarr/hc/audiobook`, passed status, queue, missing, cutoff and author schema checks. Missing returned 3 ebook and 1 audiobook records respectively. Cutoff lists were empty, so nonempty cutoff behavior remains untested. Constructed BookSearch payloads use scoped IDs; deployed Chaptarr resolves each ID to its intrinsic media type. This verifies discovery and request construction, not an end-to-end download or complete NeutArr scheduler cycle. Source: [API](https://github.com/I-am-PUID-0/NeutArr/blob/1.11.1/src/primary/apps/readarr/api.py), [missing](https://github.com/I-am-PUID-0/NeutArr/blob/1.11.1/src/primary/apps/readarr/missing.py), [upgrade](https://github.com/I-am-PUID-0/NeutArr/blob/1.11.1/src/primary/apps/readarr/upgrade.py).

Known limitations: cutoff fetching lacks pagination; processed state is recorded before submission; command acceptance is not completed-download success; missing hunt counts are author groups rather than strict book counts. Avoid aggressive settings or claiming complete large-backlog coverage.

Cleanuparr's stable v2.10.5 and current main Seeker implementation explicitly filters to Sonarr/Radarr. Its broader advertised Readarr support does not extend to periodic book searches. [Source](https://github.com/Cleanuparr/Cleanuparr/blob/v2.10.5/code/backend/Cleanuparr.Infrastructure/Features/Jobs/Seeker.cs). Searches across public Chaptarr issues/PRs and discussions did not establish endorsement of either helper; unindexed/private Discord guidance was not audited.

Decision: NeutArr is the best-fit one-for-one replacement if retaining the intended all-media helper scope, including books, is the priority Tim stated. Cleanuparr wins ecosystem momentum but narrows proactive search coverage. Do not reinterpret the correction from Readarr to Chaptarr as withdrawal of book coverage. No migration or downloads were performed. Deployment acceptance still requires copied configuration, SSO verification and a bounded search-cycle test; no undefined external wait is required.
