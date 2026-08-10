---
title: "Next.js version skew (stale build manifest after rebuild) is fixed by one-process-per-immutable-build-directory + atomic process/front-door cutover, not by deploymentId alone"
date: 2026-08-05
topic: nextjs-deployment
tags: [nextjs, version-skew, standalone-output, atomic-deploy, self-hosting, blue-green]
status: draft
sources: [nextjs-self-hosting-docs, nextjs-deploymentid-docs, nextjs-generatebuildid-docs, github-49283-standalone-static-404, vercel-skew-protection-docs, deployer-atomic-symlinks]
source_session: c5f07dea-ade5-484b-bc8d-3c54bda3de7c
---

## CLAIMS

- Next.js officially documents "version skew" (stale asset/manifest references after a rebuild while the old server is still running) in its self-hosting guide; it causes missing assets, Server Function mismatches, and navigation failures. [nextjs-self-hosting-docs]
- `deploymentId` (`experimental.deploymentId` before Next 14.1.4, stable after) is a **detect-and-recover** mechanism for browser tabs that already loaded the old HTML — it appends `?dpl=<id>` to asset URLs and forces a hard reload on mismatch. It does **not** prevent a fresh request from hitting a half-rebuilt `.next` directory, and the docs frame it for multi-server rolling deployments, not single-instance safety. [nextjs-deploymentid-docs]
- `generateBuildId` is build-time only (writes `.next/BUILD_ID`); it is not read at runtime for skew detection — that's `deploymentId`'s separate job. If both are set, `deploymentId` takes precedence. [nextjs-generatebuildid-docs]
- `output: "standalone"` deliberately omits `.next/static` and `public/` from its output — these must be copied in manually as a build step. This is the most-cited standalone gotcha (assets 404 in standalone mode). [github-49283-standalone-static-404]
- A running Next.js process reads its BUILD_ID and static-asset expectations once at process boot (module-scope, cached for process lifetime) and never re-reads them — there is no supported hot-reload contract for mutating a live process's build directory in production mode. [nextjs-self-hosting-docs]
- The correct atomicity unit for a single self-hosted instance is: one process = one immutable, fully-independent build output directory (server + its own `.next/static` + its own `public/`). Cutover means swapping which *process* holds the listening port/socket, never patching files under a live process. [nextjs-self-hosting-docs] [github-49283-standalone-static-404]
- Vercel's own hosted product uses **Skew Protection**, which keeps *old* deployments alive and independently routable by deployment ID for a bounded window rather than patching them in place — i.e., even Vercel's own infra treats "old build stays fully running until clients age out" as the safe pattern, not in-place mutation. [vercel-skew-protection-docs]
- This is not Next-specific: Capistrano/Deployer-style atomic deploys use a `releases/<sha>/` directory per build plus a `current` symlink; cutover is a single `rename()`-based swap (plain `ln -sf` is unlink+symlink, not atomic; use a temp-link-then-rename pattern instead). [deployer-atomic-symlinks]

## SOURCES

**nextjs-self-hosting-docs**
URL: https://nextjs.org/docs/app/guides/self-hosting
Accessed: 2026-08-05
Quote: "Version skew... can cause missing assets, Server Function mismatches, and navigation failures."

**nextjs-deploymentid-docs**
URL: https://nextjs.org/docs/app/api-reference/config/next-config-js/deploymentId
Accessed: 2026-08-05
Quote: "deploymentId... for rolling deployments and multi-server environments."

**nextjs-generatebuildid-docs**
URL: https://nextjs.org/docs/app/api-reference/config/next-config-js/generateBuildId
Accessed: 2026-08-05
Quote: "Next.js generates an ID during next build to identify which version of your application is being served... If you are rebuilding for each stage of your environment, you will need to generate a consistent build ID."

**github-49283-standalone-static-404**
URL: https://github.com/vercel/next.js/issues/49283
Accessed: 2026-08-05
Quote: "All static assets become 404 in standalone mode" — .next/static and public/ are not included in output:"standalone" and must be copied in manually.

**vercel-skew-protection-docs**
URL: https://vercel.com/docs/skew-protection
Accessed: 2026-08-05
Quote: Skew Protection keeps prior deployments routable rather than replacing them in place.

**deployer-atomic-symlinks**
URL: https://deployer.org/blog/atomic-symlinks
Accessed: 2026-08-05
Quote: Atomic release cutover via a `releases/<id>/` directory plus a rename-based `current` symlink swap.

## SYNTHESIS

The practical takeaway for any self-hosted (non-Vercel) Next.js deploy or
local dev-server-that-must-survive-a-rebuild setup: don't reach for
`deploymentId` expecting it to solve staleness — it only papers over
already-open browser tabs, and does nothing for the server-side race. The
actual fix is structural and boring: treat each `next build` as producing a
throwaway, fully self-contained directory (standalone server + explicitly
copied `.next/static` + explicitly copied `public/`), boot a **new process**
from that directory on a free port, health-check it, and only then flip
whatever is acting as the front door (reverse proxy upstream, PID file +
manual kill of the old process, systemd socket activation, or a symlink
rename) to point at the new process. Never rebuild in place under a server
that's currently answering requests, and never assume copying new static
assets into a running standalone server's directory is safe — it isn't
documented as supported and the live process won't pick up manifest changes
anyway.

A second, independent gotcha worth keeping: once a Next.js standalone server
is running, its process title in `ps`/`/proc/<pid>/cmdline` becomes
`next-server (v...)`, not the original `node server.js` invocation — so any
cleanup/kill logic that tries to reidentify "the server I started" by
matching against its command line will fail silently after boot. Use
`/proc/<pid>/cwd` (stable, points at the build directory) or a PID file
instead.

Applies beyond Next.js: this is the general "immutable release directory +
atomic front-door swap" pattern used by Capistrano, Deployer, and blue-green
container deploys — worth reaching for by default whenever a task involves
"rebuild an app while a dev/preview instance of it must keep serving,"
regardless of framework.
