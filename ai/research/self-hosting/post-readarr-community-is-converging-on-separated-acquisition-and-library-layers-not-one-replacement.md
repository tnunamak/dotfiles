---
title: "The post-Readarr community is converging on separate acquisition and library layers, not one settled replacement"
date: 2026-08-10
topic: self-hosting
tags: [readarr, bookshelf, shelfarr, shelfmark, chaptarr, calibre, audiobookshelf]
status: draft
sources: [current-state-thread, homelab-ebook-thread, family-library-thread, alternative-thread, bookshelf-repo, shelfarr-repo, shelfarr-telegram, chaptarr-repo, chaptarr-releases, chaptarr-calibre, chaptarr-audiobookshelf, chaptarr-readarr-facade, searcharr-release-3-4, searcharr-restore-readarr-issue, rreading-glasses-fork-comparison]
source_session: unknown
---

## CLAIMS

- An August 2026 r/selfhosted thread asking whether ebook acquisition had settled on a stable standard received competing recommendations for Shelfmark, Shelfarr, and Chaptarr; commenters described Shelfmark as useful but no longer actively developed, Shelfarr as active but still buggy for some users, and Chaptarr as immature. [current-state-thread]
- A June 2026 r/homelab thread documents a working pipeline of Shelfarr to Prowlarr to a download client to a watched directory to Calibre, with Audiobookshelf handling audiobooks; other commenters still used Bookshelf or Readarr-style management. [homelab-ebook-thread]
- A January 2026 r/selfhosted family-library thread explicitly remained uncertain about long-term project survival and described the established two-instance Readarr pattern with Calibre for ebooks and Audiobookshelf for audio. [family-library-thread]
- A January 2026 r/selfhosted alternatives thread includes both positive reports about pennydreadful/Bookshelf and reports of unpredictable wanted-list behavior, alongside recommendations for request/acquisition tools that deliver directly to Audiobookshelf. [alternative-thread]
- pennydreadful/Bookshelf is a Readarr revival that retains ebook/audiobook collection management, but its GitHub repository had no commits in the 30 days ending 2026-08-10 and was last pushed on 2026-02-04. [bookshelf-repo]
- Pedro-Revez-Silva/Shelfarr is an actively developed request and acquisition system; its documented library integrations are Audiobookshelf, BookOrbit, and Grimmory rather than Bookshelf or Calibre. [shelfarr-repo]
- Pedro-Revez-Silva/Shelfarr includes a command-based Telegram integration for authorized groups with search and ebook/audiobook/both request flows. [shelfarr-telegram]
- Shelfarr does not expose a native Bookshelf or Calibre integration. It owns request, acquisition, processing, and delivery, then optionally asks Audiobookshelf, BookOrbit, or Grimmory to scan the delivered files. [shelfarr-repo]
- Chaptarr is a Readarr fork and collection manager rather than only a request application. It supports ebooks and audiobooks in one instance, multiple editions, narrator-aware matching, series management, standard arr indexer/download-client protocols, automatic upgrades, and separate or colocated media roots. [chaptarr-repo]
- Chaptarr contains a real Calibre connection model with host, port, URL base, credentials, library, output format, and conversion profile, plus an Audiobookshelf connector with API authentication and per-root-folder ebook/audiobook library mappings. [chaptarr-calibre] [chaptarr-audiobookshelf]
- Chaptarr's public repository was created on 2026-06-29 and had 237 stars, 11 forks, 24 commits from eight identifiable authors in the 30 days ending 2026-08-10, and two public prereleases. This is unusually high early velocity, but it is not evidence of production stability. [chaptarr-repo] [chaptarr-releases]
- Chaptarr labels itself beta, warns against using an irreplaceable library without backups, and relies on its own new centralized metadata and matching service at `api2.chaptarr.com`. [chaptarr-repo]
- Chaptarr provides media-scoped Readarr compatibility paths such as `/readarr/hc/ebook` and `/readarr/hc/audiobook`. The middleware rewrites scoped API requests, injects the selected media type, and preserves a Readarr-compatible provider-ID dialect for third-party clients. [chaptarr-readarr-facade]
- Searcharr 3.4 removed its Readarr commands and API client. Integrating current Searcharr with Chaptarr therefore requires restoring a book command against Chaptarr's compatibility API or maintaining an adapter; changing only the URL cannot work with the current upstream image. [searcharr-release-3-4]
- Searcharr issue 106 asks the maintainer to restore Readarr support and has a second supporting user, but had no maintainer response as of 2026-08-10. It does not mention Chaptarr. Searches of the public Searcharr and Chaptarr issue/PR trackers found no Chaptarr-specific Searcharr proposal or implementation, so upstream ownership should not be assumed. [searcharr-restore-readarr-issue]
- A historical 2025 import comparison by the rreading-glasses maintainer found substantially worse matching and multiple UI/statistics failures in an early Chaptarr build. The result predates Chaptarr's public repository and current releases, so it is a risk signal rather than a valid current benchmark. [rreading-glasses-fork-comparison]

## SOURCES

**current-state-thread**
URL: https://www.reddit.com/r/selfhosted/comments/1vi5maw/current_state_of_ebook_downloading_aug_2026/
Accessed: 2026-08-10

**homelab-ebook-thread**
URL: https://www.reddit.com/r/homelab/comments/1u7iycz/self_hosting_ebooks/
Accessed: 2026-08-10

**family-library-thread**
URL: https://www.reddit.com/r/selfhosted/comments/1qabmn9/any_advices_for_a_family_library_readarr_setup/
Accessed: 2026-08-10

**alternative-thread**
URL: https://www.reddit.com/r/selfhosted/comments/1q9dvlz/alternative_to_listenarrreadarrshelfarr/
Accessed: 2026-08-10

**bookshelf-repo**
URL: https://github.com/pennydreadful/bookshelf
Accessed: 2026-08-10

**shelfarr-repo**
URL: https://github.com/Pedro-Revez-Silva/shelfarr
Accessed: 2026-08-10

**shelfarr-telegram**
URL: https://github.com/Pedro-Revez-Silva/shelfarr/blob/main/docs/telegram.md
Accessed: 2026-08-10

**chaptarr-repo**
URL: https://github.com/Chaptarr/chaptarr
Accessed: 2026-08-10

**chaptarr-releases**
URL: https://github.com/Chaptarr/chaptarr/releases
Accessed: 2026-08-10

**chaptarr-calibre**
URL: https://github.com/Chaptarr/chaptarr/tree/develop/src/NzbDrone.Core/Books/Calibre
Accessed: 2026-08-10

**chaptarr-audiobookshelf**
URL: https://github.com/Chaptarr/chaptarr/tree/develop/src/NzbDrone.Core/Notifications/AudioBookShelf
Accessed: 2026-08-10

**chaptarr-readarr-facade**
URL: https://github.com/Chaptarr/chaptarr/blob/develop/src/Chaptarr.Http/Middleware/ServarrMediaTypeScopeMiddleware.cs
Accessed: 2026-08-10

**searcharr-release-3-4**
URL: https://github.com/toddrob99/searcharr/releases/tag/v3.4.0
Accessed: 2026-08-10

**searcharr-restore-readarr-issue**
URL: https://github.com/toddrob99/searcharr/issues/106
Accessed: 2026-08-10

**rreading-glasses-fork-comparison**
URL: https://github.com/blampe/rreading-glasses/blob/main/FORKS.md
Accessed: 2026-08-10

## SYNTHESIS

There is no community-selected successor that combines Readarr's monitored catalog, acquisition automation, Calibre integration, and a family-friendly request UI. The emerging architecture separates concerns: Shelfarr or Shelfmark handles discovery and acquisition, while Calibre-family software handles the ebook catalog and Audiobookshelf handles the audio catalog. Bookshelf remains the closest operational match for users who value Readarr-style monitoring, but current community momentum is moving toward watched-folder handoffs rather than a single manager owning the whole pipeline.

For an existing Calibre and Audiobookshelf installation, migration should be additive and reversible. Shelfarr should not share acquisition ownership with Bookshelf: either pilot it with isolated categories and output paths or use it to replace the acquisition layer while Calibre and Audiobookshelf remain the durable libraries.

Chaptarr is the closest architectural successor for users who want to preserve Readarr-style monitoring, import, renaming, quality upgrades, Calibre integration, and audiobook handling. Its development velocity makes it a credible strategic bet, but its age and beta status make a direct production cutover premature. The appropriate bet is a canary deployment with separate download categories and test roots, followed by explicit ebook-to-Calibre, audiobook-to-Audiobookshelf, dual-format, matching, hardlink, and restore tests before any migration of live ownership.
