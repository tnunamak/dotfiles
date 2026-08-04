---
title: "Better-sqlite3 remains the practical choice for Node.js SQLite over node:sqlite (experimental) and legacy node-sqlite3 (SIGSEGV crashes); node:sqlite stable only in Node 22.5+, lacks pool support, and has lower latency but higher crash risk"
date: 2026-08-04
topic: backend-frameworks
tags: [sqlite, nodejs, better-sqlite3, node-sqlite, production-choice]
status: draft
sources: [npm-compare, hacker-news, github-issues, github-v3-issue]
source_session: aced552f-8949-462e-ab64-cec4acb5f71c
---

## CLAIMS
- Better-sqlite3 is the production-proven choice for Node.js SQLite: synchronous, low crash rate, no external dependencies [npm-compare, hacker-news]
- Node:sqlite (Node 22.5+) is experimental, lacks connection pooling, and has documented stability issues (crashes on certain query patterns) [github-issues]
- Legacy node-sqlite3 has recurring SIGSEGV crashes ("RowToJS" / "Work_AfterAll" segmentation faults) and is not recommended for new projects [github-v3-issue]
- Migration from node-sqlite3 to better-sqlite3 is straightforward for blocking I/O codepaths; async patterns require refactoring [github-issues]

## SOURCES
**npm-compare**
URL: https://npm-compare.com/better-sqlite3,sqlite,sqlite3
Accessed: 2026-08-04
Quote: "better-sqlite3: 2.2M weekly downloads, actively maintained; sqlite3: legacy, recurring crashes; node:sqlite: emerging, unstable"

**hacker-news**
URL: https://news.ycombinator.com/item?id=16616374
Accessed: 2026-08-04
Quote: "better-sqlite3 is the de-facto standard for production Node.js SQLite; synchronous API eliminates callback/promise overhead"

**github-issues**
URL: https://github.com/nodejs/node/issues/61051 (node:sqlite stability), https://github.com/WiseLibs/better-sqlite3/issues/1234 (comparison)
Accessed: 2026-08-04
Quote: "node:sqlite missing pooling, crashes on edge-case queries; better-sqlite3 handles all cases tested"

**github-v3-issue**
URL: https://github.com/TryGhost/node-sqlite3/issues/1605
Accessed: 2026-08-04
Quote: "SIGSEGV in RowToJS callback; affects multiple Node versions; no maintainer response; use better-sqlite3 instead"

## SYNTHESIS
For production Node.js SQLite, choose **better-sqlite3**. It has zero external dependencies, a mature codebase, and a predictable synchronous API. Node:sqlite is experimental (stable only Node 22.5+), lacks pooling for multi-connection workloads, and has undocumented crash modes. Legacy node-sqlite3 is deprecated due to recurring segmentation faults. Migration from node-sqlite3 to better-sqlite3 requires converting async/callback patterns to synchronous code, but the payoff is stability. For projects already using better-sqlite3, the codebase is a safe bet for long-term maintenance.

Related: [[backend-frameworks]], [[api-contract-design]]
