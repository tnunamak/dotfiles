---
title: "ParadeDB's pg_search adds a Postgres-native BM25 top-k retrieval primitive, whereas built-in Postgres FTS ranks only after a candidate set has been found"
date: 2026-06-17
topic: search-infrastructure
tags: [postgres, bm25, full-text-search, paradedb, pg_search, lexical-search]
status: draft
sources: [paradedb-intro, paradedb-topk, paradedb-create-index, paradedb-self-hosted, paradedb-third-party, paradedb-github, neon-pg-search, pg-textsearch-indexes, pg-btree-gin]
source_session: 6591a019-4e8b-445c-bde7-b8a31c8851a1
---

## CLAIMS

- Postgres built-in full-text search with a `GIN(tsvector)` index is the documented baseline substrate for text search. [pg-textsearch-indexes]
- Built-in Postgres `ts_rank_cd` ranks results only after a candidate set has already been found; it does not by itself provide a Lucene-style global top-k BM25 retrieval primitive. [pg-textsearch-indexes]
- ParadeDB's `pg_search` is an extension-backed BM25 index with top-k query support that runs inside Postgres, obtaining the best-ranked hits without first selecting an arbitrary candidate window. [paradedb-intro] [paradedb-topk]
- `pg_search` is installed via `CREATE EXTENSION pg_search` on self-hosted Postgres, and ParadeDB also ships a Docker image with `pg_search` pre-installed. [paradedb-self-hosted] [paradedb-third-party]
- Neon documents `pg_search` availability for hosted Postgres. [neon-pg-search]
- ParadeDB Community is licensed AGPL-3.0. [paradedb-github]
- SQLite FTS5 provides a native `bm25()` ranking function. [paradedb-intro]

## SOURCES

**paradedb-intro**
URL: https://docs.paradedb.com/welcome/introduction
Accessed: 2026-06-17

**paradedb-topk**
URL: https://docs.paradedb.com/documentation/sorting/topk
Accessed: 2026-06-17

**paradedb-create-index**
URL: https://docs.paradedb.com/documentation/indexing/create-index
Accessed: 2026-06-17

**paradedb-self-hosted**
URL: https://docs.paradedb.com/deploy/self-hosted/extension
Accessed: 2026-06-17

**paradedb-third-party**
URL: https://docs.paradedb.com/deploy/third-party-extensions
Accessed: 2026-06-17

**paradedb-github**
URL: https://github.com/paradedb/paradedb
Accessed: 2026-06-17

**neon-pg-search**
URL: https://neon.com/docs/extensions/pg_search
Accessed: 2026-06-17

**pg-textsearch-indexes**
URL: https://www.postgresql.org/docs/current/textsearch-indexes.html
Accessed: 2026-06-17

**pg-btree-gin**
URL: https://www.postgresql.org/docs/current/btree-gin.html
Accessed: 2026-06-17

## SYNTHESIS

Built-in Postgres FTS (scoped GIN + `btree_gin` composite equality/FTS predicates) is the correct, dependency-free baseline, but its ranking runs only over an already-selected candidate window — a bounded window can miss a better match outside it, forcing an honest "candidate_window" recall disclosure for broad queries. ParadeDB's `pg_search` is the relevant prior-art direction for closing that gap inside Postgres with global BM25 top-k. Deployment posture is the catch: it is an extension (`CREATE EXTENSION pg_search`) or a dedicated Docker image, and the Community edition is AGPL-3.0, so adopting it is an explicit licensing/image decision rather than a silent vendor. A pragmatic design keeps `pg_search` optional: fall back to scoped Postgres FTS with honest recall disclosure when the extension is absent, advertise the actual backend capability in metadata (do not claim global BM25/top-k when unavailable), and treat cross-backend parity as API-contract parity (SQLite's native `bm25()`, Postgres's `pg_search` when present) rather than identical internals.
