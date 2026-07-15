---
title: "In pgvector, a metadata-filtered ANN query applies the filter AFTER the index scan, so selective filters silently under-return unless you give the planner an exact filter-first (B-tree) path or raise ef_search"
date: 2026-06-17
topic: search-infrastructure
tags: [pgvector, postgres, ann, hnsw, ivfflat, vector-search, filtered-search]
status: draft
sources: [pgvector-readme, pg-partial-indexes, pg-partitioning, pg-index-types, pg-multicolumn-indexes]
---

## CLAIMS

- pgvector offers two ANN index types: HNSW (multilayer proximity graph — best speed/recall, slower builds, more memory, can be built on an empty table) and IVFFlat (partitions vectors into `lists` and probes the closest `n` — faster builds, less memory, worse speed/recall). [pgvector-readme]
- IVFFlat recall depends on building the index after the table has data, `lists ≈ rows/1000` for ≤1M rows (or `sqrt(rows)` for >1M), and querying with `probes ≈ sqrt(lists)`. [pgvector-readme]
- For a single-precision `vector` you build one index per distance function (e.g. `vector_cosine_ops` for cosine). [pgvector-readme]
- With an approximate index, a `WHERE` filter is applied AFTER the index scan: the graph walk returns up to `hnsw.ef_search` (default 40) candidates and the filter then discards non-matching ones, so a filter matching ~10% of rows yields ~4 rows on average — a silent under-return, not an error. [pgvector-readme]
- pgvector's docs give a preference-ordered ladder for filtered search: (1) a B-tree index on the filter column(s), described as "a good place to start," giving fast exact nearest-neighbor for low-selectivity filters; (2) approximate index + raise `ef_search`/overscan when filters match more rows; (3) iterative index scans (pgvector ≥ 0.8.0) that auto-rescan until `LIMIT` is met or a cap is hit (`hnsw.max_scan_tuples` default 20000, `ivfflat.max_probes`), with `strict_order` vs `relaxed_order`; (4) partial index (`... USING hnsw (...) WHERE (col = value)`) when filtering by only a few distinct values; (5) partitioning (`PARTITION BY LIST/HASH/RANGE`) when filtering by many different values. [pgvector-readme]
- For the query to use the ANN index, it must have `ORDER BY <distance-operator> ... ASC` plus a `LIMIT`, and the `ORDER BY` must be the bare distance operator, not an expression; an expression index (e.g. on `embedding::vector(384)`) only matches when the query uses the identical expression. [pgvector-readme]
- NULL vectors are never indexed; zero vectors are not indexed for cosine, and cosine distance to a zero vector is `NaN`. [pgvector-readme]
- `hnsw.ef_search` (default 40) is a per-query dynamic candidate-list size set via `SET LOCAL`; higher values improve recall at the cost of latency. `hnsw.scan_mem_multiplier` (default 1) scales `work_mem` for iterative scans. [pgvector-readme]
- HNSW builds much faster when the graph fits in `maintenance_work_mem` (a NOTICE fires when it spills); build the index after bulk load; parallel HNSW builds require Docker `--shm-size ≥ maintenance_work_mem`; HNSW vacuum is slow (prefer `REINDEX INDEX CONCURRENTLY` then `VACUUM`); `halfvec` or binary quantization shrink the index. [pgvector-readme]
- A partial index applies to a subset of a table defined by a `WHERE` predicate. [pg-partial-indexes]
- Table partitioning (LIST/HASH/RANGE) lets the planner prune to relevant partitions before scanning, and each partition can carry its own indexes. [pg-partitioning]
- In a multicolumn B-tree index, the leading column(s) can serve queries that constrain a prefix of the indexed columns. [pg-multicolumn-indexes]

## SOURCES

**pgvector-readme**
URL: https://github.com/pgvector/pgvector/blob/master/README.md
Accessed: 2026-06-17
Quote: "With approximate indexes, filtering is applied after the index is scanned."

**pg-partial-indexes**
URL: https://www.postgresql.org/docs/current/indexes-partial.html
Accessed: 2026-06-17

**pg-partitioning**
URL: https://www.postgresql.org/docs/current/ddl-partitioning.html
Accessed: 2026-06-17

**pg-index-types**
URL: https://www.postgresql.org/docs/current/indexes-types.html
Accessed: 2026-06-17

**pg-multicolumn-indexes**
URL: https://www.postgresql.org/docs/current/indexes-multicolumn.html
Accessed: 2026-06-17

## SYNTHESIS

The dominant failure mode for metadata-filtered vector search is silent under-return: a global HNSW graph returns fewer than `k` rows when the `WHERE` filter is selective, because filtering happens after the ANN scan discards all but its ~40 candidates. The remedy depends on filter selectivity, and pgvector's own ladder is the guide:

- For high-cardinality, highly selective identity filters (a filter matching a low percentage of rows), a plain B-tree index on the filter columns is often both faster and 100%-recall: the planner filters to the small matching set first, then does an exact ordered distance scan — no `ef_search` risk, exact order. This is rung 1 and is nearly always worth adding regardless.
- Keep an HNSW index with a per-query `ef_search` clamp and iterative scan (`strict_order`) as the safety net for large slices; let cost-based planning arbitrate between the exact B-tree path and the approximate HNSW path per query.
- Partial indexes (rung 4) and partitioning (rung 5) structurally solve post-filter shrinkage but are only worth it for a small fixed set of dominant filter values (partial) or at large scale with many distinct values (partitioning); both add operational cost (per-value DDL, or a table-rewrite migration with per-partition HNSW builds).

Two operational cautions carry across any deployment: (a) expression-index matching is brittle — the query's `ORDER BY` must use the identical cast/operator the index was built on, `ASC`, with a `LIMIT`, or the planner silently falls back to a sequential scan; pin this with an `EXPLAIN` assertion. (b) There is no built-in alarm for under-return, so add recall/truncation telemetry (did we return `k` when ≥`k` matching rows exist?). A field-observed nuance: building a partial HNSW index over a very large source can exceed `maintenance_work_mem` and fail; for dominant huge partitions, a bounded candidate window is a safer fallback than a per-value partial HNSW index.
