---
title: "Postgres full-text search uses GIN as its preferred tsvector index, and btree_gin lets a single multicolumn GIN combine B-tree equality columns with a tsvector column"
date: 2026-06-17
topic: search-infrastructure
tags: [postgres, full-text-search, gin, btree-gin, shared-memory]
status: draft
sources: [pg-textsearch-indexes, pg-btree-gin, pg-gin, crunchy-shmem]
---

## CLAIMS

- PostgreSQL's documented preferred index type for full-text `tsvector` search is GIN. [pg-textsearch-indexes]
- The `btree_gin` extension provides GIN operator classes with B-tree behavior, enabling a single multicolumn GIN index that combines a GIN-indexable column (e.g. a `tsvector`) with B-tree-style equality columns. [pg-btree-gin]
- GIN is designed for indexing composite values where searches look for element values within those composite items. [pg-gin]
- A PostgreSQL `53100` error is a dynamic shared-memory allocation failure during query execution; in a container this can occur even when disk is not full (e.g. constrained `/dev/shm`). [crunchy-shmem]
- Setting `max_parallel_workers_per_gather = 0` transaction-locally is a narrow operational mitigation to avoid dynamic-shared-memory allocation failures during parallel query execution. [crunchy-shmem]

## SOURCES

**pg-textsearch-indexes**
URL: https://www.postgresql.org/docs/current/textsearch-indexes.html
Accessed: 2026-06-17
Quote: "12.9. Preferred Index Types for Text Search"

**pg-btree-gin**
URL: https://www.postgresql.org/docs/current/btree-gin.html
Accessed: 2026-06-17
Quote: "F.7. btree_gin — GIN operator classes with B-tree behavior"

**pg-gin**
URL: https://www.postgresql.org/docs/current/gin.html
Accessed: 2026-06-17
Quote: "65.4. GIN Indexes"

**crunchy-shmem**
URL: https://www.crunchydata.com/blog/postgres-troubleshooting-diskfull-error-could-not-resize-shared-memory-segment
Accessed: 2026-06-17
Quote: "Postgres Troubleshooting: DiskFull ERROR: could not resize shared memory segment"

## SYNTHESIS

For a full-text search query that always combines an equality-scoped predicate (e.g. tenant/instance/stream identity) with a `tsvector @@ query` match, a scoped multicolumn GIN index over `(equality_col_a, equality_col_b, tsvector_col)` built with `btree_gin` matches the query shape better than a global GIN index on the tsvector alone plus a bitmap combination — the planner can satisfy both the equality scope and the FTS match from one index. Keeping a global tsvector GIN index alongside gives rollback/compatibility safety. When containerized Postgres throws `53100` under parallel execution, disabling parallel workers inside the read transaction is a targeted mitigation that avoids fixed wall-clock sleeps and does not require reaching for an external search engine.
