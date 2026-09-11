---
title: "Calibre-Web historical bundle tags and CouchDB packaging rebuilds need different update handling"
date: 2026-09-09
topic: self-hosting
tags: [renovate, docker, calibre-web, couchdb]
status: draft
---

## CLAIMS

- Calibre-Web upstream latest is 0.6.27, published 2026-08-08. Historical LinuxServer tags such as v5.7.2-ls1 were published in 2020 and describe bundled Calibre, not a current Calibre-Web major release. A broad LinuxServer semver regex can incorrectly promote them. Exclude exact historical versions, not all future majors.
- Apache CouchDB Docker commit 4f2bee2facf7daf27c57aa192af25fc37c24c526 describes 3.5.2.1 as the same 3.5.2 source with Erlang/OTP 26.2.5.21 and a Nouveau packaging correction. The image index digest observed 2026-09-09 is sha256:9ea24cbd76522fe845d1c32c7fd1dcfc8a3ba73dcc4817d62f8a7f7f1dfaffe3.

## SOURCES

- https://api.github.com/repos/janeczku/calibre-web/releases/latest — tag and date checked 2026-09-09.
- https://hub.docker.com/v2/repositories/linuxserver/calibre-web/tags/v5.7.2-ls1 — published 2020-12-12.
- Hub tag queries name=v3., name=v4., and both pages of name=v5. enumerate the historical ls1 set (2019–2020); later calibre-prefixed bundles do not match the three-part application regex.
- https://github.com/apache/couchdb-docker/commit/4f2bee2facf7daf27c57aa192af25fc37c24c526 — packaging release rationale.
- https://hub.docker.com/v2/repositories/library/couchdb/tags/3.5.2.1 — immutable image index digest, updated 2026-08-25.

## SYNTHESIS

Tag ordering is not proof of an application upgrade. Verify distributor tag history and upstream release identity before excluding or promoting versions. Negative exact-tag filtering preserves visibility of future major releases. Database packaging rebuilds still warrant consistent backups and authenticated data checks before and after container replacement.
