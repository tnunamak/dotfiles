---
title: "Media application updates include security fixes and need consistent config backups"
date: 2026-09-09
topic: self-hosting
tags: [homelab, media, upgrades]
status: draft
sources: [sab, bazarr, calibre-web, hydra, qui, qbittorrent, arr]
source_session: unknown
---

## CLAIMS

- SABnzbd 5.1.3 fixes authentication bypass and malicious-download processing vulnerabilities. Its release supports direct upgrades from 3.0.0 or newer. [sab]
- Bazarr 1.6.0 includes subtitle database migration changes and fixes command invocation safety in subtitle post-processing. [bazarr]
- Calibre-Web 0.6.27 includes fixes for unauthorized book access, injections, account relinking and credential exposure. [calibre-web]
- NZBHydra 8.9.0 adds OIDC support without requiring existing installations to adopt it. [hydra]
- Qui 1.28.0 documents its versioned container image and changes torrent automation, cross-seeding and UI behavior. [qui]
- qBittorrent 5.2.3 includes fixes for migration procedures and database transaction deadlocks. [qbittorrent]
- Radarr and Prowlarr release notes direct Docker users to replace the container image rather than use the in-app updater. [arr]

## SOURCES

**sab**
URL: https://github.com/sabnzbd/sabnzbd/releases/tag/5.1.3
Accessed: 2026-09-09

**bazarr**
URL: https://github.com/morpheus65535/bazarr/releases/tag/v1.6.0
Accessed: 2026-09-09

**calibre-web**
URL: https://github.com/janeczku/calibre-web/releases/tag/0.6.27
Accessed: 2026-09-09

**hydra**
URL: https://github.com/theotherp/nzbhydra2/releases/tag/v8.9.0
Accessed: 2026-09-09

**qui**
URL: https://github.com/autobrr/qui/releases/tag/v1.28.0
Accessed: 2026-09-09

**qbittorrent**
URL: https://github.com/qbittorrent/qBittorrent/releases/tag/release-5.2.3
Accessed: 2026-09-09

**arr**
URL: https://github.com/Sonarr/Sonarr/releases/tag/v4.0.19.2979
URL: https://github.com/Radarr/Radarr/releases/tag/v6.3.0.10514
URL: https://github.com/Prowlarr/Prowlarr/releases/tag/v2.5.2.5491
Accessed: 2026-09-09

## SYNTHESIS

These are same-major upgrades, but database changes still require recovery evidence. Request native Arr Backup commands, then stop each individual service gracefully and archive its config before replacing it. Check SAB and qBittorrent active transfers immediately before their cutovers. Preserve old images and configs; startup success alone does not prove client/indexer integrations or authenticated UI behavior. The homelab's current workflow deploys whole stacks, so manually scoped changes use an explicit skip-CI merge commit and then fast-forward the host checkout without rerunning Compose.

Exact distributor tags successfully pulled on the homelab: linuxserver/sonarr:4.0.19.2979-ls323, radarr:6.3.0.10514-ls315, prowlarr:2.5.2.5491-ls159, bazarr:v1.6.0-ls363, sabnzbd:5.1.3-ls272, nzbhydra2:v8.9.0-ls103, calibre-web:0.6.27-ls400; ghcr.io/autobrr/qui:v1.28.0; ghcr.io/hotio/qbittorrent:release-5.2.3. Registry availability is an observation on September 9, not a permanent guarantee.
