---
title: "Full-stack web slowness on Next.js/RSC + Postgres + SQLite + Node maps to documented, fixable anti-patterns, not stack ceilings"
date: 2026-06-17
topic: web-performance
tags: [nextjs, rsc, postgres, sqlite, nodejs, performance, prior-art]
status: draft
sources: [nextjs-rsc, postgres, sqlite, node-api]
---

## CLAIMS

- Next.js App Router / RSC done right yields 50-70% less client JS and better LCP; its performance problems come from complexity, not framework instability ("high ceiling, high expertise floor"). [nextjs-rsc]
- The canonical RSC anti-pattern is block-on-slowest-read: a layout/page awaits all data (e.g. a `Promise.all` of many reads) before sending a byte, so even a static heading hangs on the slowest fetch; the fix is Suspense streaming — send the shell immediately, stream slow sections. [nextjs-rsc]
- Next.js has four cache layers (request memoization, data cache, full route cache, router cache); not using them causes repeat RSC fetches to re-run expensive server work; the `"use client"` boundary is contagious — a client-marked layout ships its whole subtree as JS (a frequently-cited killer). [nextjs-rsc]
- For Postgres, roughly 80% of issues are missing indexes, 15% poor query design (including N+1/fan-out), 5% connection management; `EXPLAIN ANALYZE` commonly cuts p95 50-80%; new connections cost 2-10MB RAM each and PgBouncer transaction mode is the standard pooling answer. [postgres]
- SQLite server tuning is distinct and non-obvious: WAL mode is non-negotiable for concurrent read-heavy use (readers don't block writers); `PRAGMA synchronous = NORMAL` is the single most impactful pragma in WAL; the default ~2MB `cache_size` is tiny (raise to e.g. 64MB); `mmap_size` cut scan latency ~40% in one report; use `busy_timeout`, `BEGIN IMMEDIATE` for known writes, and separate read/write connection pools. [sqlite]
- The same N+1 can be invisible on SQLite (microsecond reads absorb it) but expensive on Postgres (ms × N), so diagnosis and fixes are store-specific — measure against the store the instance actually runs. [sqlite]
- For a Node API/read-surface, `Promise.all` for independent I/O is ~50% faster than serial awaits; caching hot reads is high-value (one study: 30s→1.66s); watch payload size and scope middleware (e.g. auth) only where needed. [node-api]

## SOURCES

**nextjs-rsc**
URL: https://usuallycorrect.com/blog/nextjs-performance-optimization-2026 ; https://blog.logrocket.com/react-server-components-performance-mistakes ; https://www.meisteritsystems.com/news/next-js-app-router-in-2026-is-it-ready-for-production/ ; https://www.developerway.com/posts/react-server-components-performance
Accessed: 2026-06-17

**postgres**
URL: https://www.instaclustr.com/education/postgresql/top-10-postgresql-best-practices-for-2025/ ; https://last9.io/blog/postgresql-performance/ ; https://tusharagrawal.in/blog/database-connection-pooling-performance-guide
Accessed: 2026-06-17

**sqlite**
URL: https://kerkour.com/sqlite-for-servers ; https://cj.rs/blog/sqlite-pragma-cheatsheet-for-performance-and-consistency/ ; https://github.com/WiseLibs/better-sqlite3/blob/master/docs/performance.md
Accessed: 2026-06-17

**node-api**
URL: https://www.ksolves.com/blog/node-js/performance-optimization-tips-for-scalable-apis ; https://www.sciencedirect.com/science/article/pii/S1877050925026158
Accessed: 2026-06-17

## SYNTHESIS

Next.js/RSC + Postgres + SQLite + Node is a fast path; when a real page reaches multi-second load, the cause is almost always a stack of documented anti-patterns that compound rather than a single ceiling. A common compounding pattern: an expensive N+1 projection is fetched uncached and re-fetched several times per page render, those fetches run sequentially, and server load multiplies it — so a single curl of one call ("sub-2s") badly under-measures the real browser cost. The fix that collapses such multipliers is cache/memoize the repeated projection (repeat fetches become nearly free) + batch the N+1 into a couple of grouped queries + trim the payload + stream the shell with Suspense so it stops blocking on the slowest read. The load-bearing methodology lesson: measure in a real browser, cold, with Web Vitals + RSC-fetch-count + sequential timing + backend latency — otherwise "faster" claims are unprovable and the optimization loop never closes.
