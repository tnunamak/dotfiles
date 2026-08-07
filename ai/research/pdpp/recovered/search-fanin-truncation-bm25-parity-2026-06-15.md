# Fan-in truncation honesty & BM25 cross-engine parity — prior art

Date: 2026-06-15
Status: captured (informative; resolves two questions the prior lexical-search
notes left open — the **per-source truncation envelope** under fan-in, and
**BM25 ranking parity** across the SQLite and Postgres backends)

## Why this note

Two earlier notes
(`lexical-search-ranking-recency-prior-art-2026-06-15.md`,
`lexical-search-freshness-prior-art-2026-06-15.md`) established that PDPP lexical
search fans in across N connectors, caps each at **200 hits** by relevance,
merges round-robin, and exposes only an envelope-level `has_more`/`next_cursor`.
They recommended a per-source `capped`/`match_count_relation` signal and named
ParadeDB/pg_search as a Postgres BM25 upgrade — but two things stayed unresolved:

1. **Fan-in truncation honesty.** A single top-level `capped: true` or one
   `has_more` *lies under fan-in*: it cannot say **which** source was capped or
   **how many** it really had. What exact envelope shape do mature
   multi-index/federated APIs use to signal **per-source** truncation + counts in
   one response?
2. **BM25 parity across backends.** PDPP runs lexical search on **two engines** —
   SQLite `FTS5 bm25()` and (proposed) Postgres `pg_search` (Tantivy BM25). Are
   they "the same algorithm" closely enough that the same query gives a forker
   *comparable* ordering on both, or do their formula variants / tokenization
   diverge enough to be a spec-conformance problem?

This note answers both from primary sources, grounded in the live code
(`reference-implementation/server/search.js`,
`reference-implementation/server/postgres-search.js`). Verified against the
implementation: per-connector `LIMIT 200` at search.js:1165 (Postgres) and
search.js:1254 (SQLite FTS5 `bm25()` at :1238, `ORDER BY score ASC`),
`roundRobinMerge` at :1327, envelope `has_more` at :866.

---

# PART 1 — Fan-in per-source truncation honesty

## 1.0 The core defect, precisely

Under fan-in, the response carries **one** completeness signal for **N**
independent truncations. That single bit is *structurally incapable* of being
honest:

- `has_more: false` on the merged page is true ("no more *merged* rows queued")
  while each of N sources silently dropped everything past its own rank-200 — the
  "nothing newer than April" misread.
- `capped: true` (if added at top level) tells you *something* was capped but not
  **which** source or **how much**, so a caller cannot decide where to deepen.

The canonical principle, stated once and shared by every mature engine below:
**a result set truncated by a cap MUST be distinguishable from a complete one —
and when results come from N sources, that distinction MUST be per source.** The
honesty signal has to have the same cardinality as the truncation.

## 1.1 Elasticsearch `_msearch` — N full sub-responses, each with its own `hits.total.{value,relation}`

`_msearch` is the closest structural analog to PDPP fan-in: N independent queries,
**one** HTTP envelope. The shape:

```jsonc
{ "responses": [
  { "took": 1, "_shards": {...},
    "hits": { "total": { "value": 8,     "relation": "eq"  }, "max_score": 4.76, "hits": [...] } },
  { "took": 3, "_shards": {...},
    "hits": { "total": { "value": 10000, "relation": "gte" }, "max_score": 1.0,  "hits": [...] } }
] }
```

Two load-bearing moves:

- **The envelope is an *array of full sub-responses***, one per query — not a
  flattened list with one shared meta. Each sub-response owns its `hits`, its
  count, and its own `_shards` health. This is the structural answer to "which
  source": the source's metadata never leaves the source's sub-object.
- **`hits.total` is an OBJECT, not a number** — `{ "value": N, "relation":
  "eq" | "gte" }`. `relation: "eq"` = exact total. `relation: "gte"` = a **lower
  bound**: "there are at least this many; we stopped counting." ES stops counting
  at `track_total_hits` (default 10,000) so a huge corpus doesn't pay for an exact
  count. **This `eq`/`gte` distinction is exactly "complete" vs "truncated lower
  bound"** — the single most directly transplantable pattern for PDPP.

`terminated_early: true` is the secondary per-query boolean ("the scan stopped
before exhausting matches", e.g. `terminate_after`). It is the per-query "I was
capped" flag — distinct from `gte`, which is about the *count*, not the *scan*.

## 1.2 Cross-cluster search — the `_clusters` object is the per-source meta ARRAY done right

CCS is the *purest* prior art for PDPP, because it is literally one logical search
fanned across N independently-failing backends. It adds a dedicated top-level
`_clusters` object that is exactly the "per-source meta array" the task asks about:

```jsonc
"_clusters": {
  "total": 3, "successful": 2, "running": 0, "skipped": 1, "partial": 0, "failed": 0,
  "details": {
    "(local)": { "status": "successful", "indices": "...", "took": 12, "_shards": {...} },
    "remote1": { "status": "skipped", "indices": "web*",
                 "failures": [ { "shard": -1, "reason": { "type": "connect_transport_exception", ... } } ] }
  }
}
```

The design lessons that map 1:1 onto PDPP fan-in:

- **Roll-up counters + a per-source `details` map.** A caller gets an at-a-glance
  summary (`successful/skipped/partial`) AND a drill-down keyed by source id. PDPP
  wants both: a small top-level summary and a `sources[]` (or `sources{}` keyed by
  `connection_id`) array with the real per-source numbers.
- **A per-source `status` enum, not a lone boolean.** CCS sources are
  `successful | partial | skipped | failed | running`. The richer enum lets one
  source be honestly "I returned everything" while another is "I was interrupted /
  capped / unreachable" — a single top-level boolean cannot express this mix. PDPP's
  analog statuses: `complete` (returned all matches), `capped` (hit the 200 cap,
  more exist), `skipped` (not applicable / not in grant), and — if a backend
  errors mid-fan-in — `failed`/`partial`.
- **`partial`/`is_partial` is the explicit "this fan-in is incomplete" flag.** In
  async/ES|QL CCS, `is_partial: true` signals the *aggregate* result is not whole.
  PDPP's top-level summary should carry the same one-bit roll-up so a caller can
  branch without parsing every source entry.
- **Honesty by construction:** a `skip_unavailable: true` source that is down still
  returns HTTP 200 with the data *omitted* — but the omission is **named** in
  `_clusters.skipped` + `details[src].status = skipped`. The lesson: it is fine to
  drop a source's contribution, **never** fine to drop it silently.

## 1.3 Algolia `multipleQueries` — `results[]` array, each with `nbHits` + `exhaustiveNbHits`

Algolia's multi-index search returns a `results[]` array **in query order**, each
element a standalone per-index response — and explicitly **does not merge** across
indices ("each index returns its own separate array of results/hits"). Each entry
carries:

- `nbHits` — matches found for *that* index.
- **`exhaustiveNbHits` (and the newer `exhaustive.nbHits`)** — boolean: `true` =
  the count is exact, `false` = approximate (Algolia stopped counting for
  performance). This is the **boolean form of ES `eq`/`gte`**, per index.
- A documented hard cap (1,000 retrievable hits) with a *named deep-traversal
  escape hatch* (`browse`). The cap is never silent and the way past it is named.

Lesson: the per-source completeness signal is so universal that Algolia, ES, and
CCS each ship it; they differ only in spelling (`relation:"gte"` vs
`exhaustiveNbHits:false` vs `status:"partial"`). PDPP should pick one spelling and
apply it **per source**.

## 1.4 Stripe & Splunk — the bounds and the provenance field

- **Stripe search**: `has_more` is always present (cheap, minimal); `total_count`
  is **opt-in** (must `expand`) and **only accurate up to 10,000**. Lesson:
  *always* give `has_more`/`capped`; never promise an exact grand total you can't
  cheaply compute — bound any count you do return (the same honesty as `gte`).
- **Splunk federated search** (transparent mode): every result carries a
  `splunk_federated_provider` field and the engine "breaks out result counts by
  provider." Lesson: the per-source **provenance key is mandatory** — without a
  stable source id on each hit and each count, "which source was capped" is
  unanswerable. PDPP already has this id (`connection_id` / `connector_instance_id`
  on every hit); the meta array just has to key on it.

## 1.5 The canonical PDPP shape (synthesis)

Every mature fan-in/federated API converges on the **same two-part envelope**:
(a) a small top-level roll-up, and (b) a **per-source array/map** whose cardinality
equals the number of sources, each entry carrying provenance + a completeness
signal (`eq`/`gte` ↔ `exhaustive` ↔ `status`). Transplanted to PDPP's existing
envelope (which already has `has_more`, `warnings[]`, `disclosure`, and a
`connection_id` on every hit):

```jsonc
{
  "results": [ /* round-robin-merged hits, unchanged */ ],
  "has_more": true,                 // unchanged: more MERGED rows queued in snapshot
  "next_cursor": "…",
  "meta": {
    "truncated": true,              // CCS-style top-level roll-up: at least one source was capped
    "sources": [                    // per-source meta ARRAY — the load-bearing addition
      {
        "connection_id": "cin_f565…",
        "connector_key": "slack",
        "returned": 200,            // hits this source contributed to the snapshot
        "capped": true,             // hit its per-source 200 cap (ES terminated_early / Algolia non-exhaustive)
        "match_count": 200,         // bounded count; lower bound when capped, exact when not
        "match_count_relation": "gte", // ES eq/gte: "gte" = at least this many (more, incl. recent, exist)
        "next": "<source-scoped cursor>" // OPTIONAL deep-paginate THIS source past the cap
      },
      {
        "connection_id": "cin_11de…",
        "connector_key": "chatgpt",
        "returned": 37,
        "capped": false,
        "match_count": 37,
        "match_count_relation": "eq"  // exact: this source is complete
      }
    ]
  },
  "warnings": [                     // existing warnings[] channel; slots in beside limit_clamped
    {
      "code": "source_results_capped",
      "connection_id": "cin_f565…",
      "detail": { "returned": 200, "cap": 200, "relation": "gte" },
      "message": "Showing the top 200 Slack matches by relevance; more matches exist (including more recent). Re-run scoped to this source, or sort by recency, to see them."
    }
  ]
}
```

**The non-negotiable invariants** (each backed above):

1. **Per-source cardinality.** The completeness signal lives in a `sources[]`
   entry keyed by `connection_id`, NOT as one top-level bit. (ES `responses[]` /
   CCS `_clusters.details` / Algolia `results[]`.)
2. **`eq` vs `gte` (complete vs lower-bound).** `capped:false`+`relation:"eq"` =
   "this source returned everything"; `capped:true`+`relation:"gte"` = "lower
   bound, more exist." (ES `hits.total.relation`; Algolia `exhaustiveNbHits`.)
   This is the single most important pattern.
3. **Bound any count.** `match_count` is exact only when `eq`; when capped it is a
   declared lower bound (= the cap). Never compute an exact grand total you can't
   afford. (Stripe `total_count` ≤10k; ES `track_total_hits`.)
4. **Provenance on everything.** Every hit and every meta entry carries the source
   id, so "which source was capped" is always answerable. (Splunk
   `splunk_federated_provider`.)
5. **A top-level roll-up bit** (`meta.truncated` / CCS `partial`) so a caller can
   branch without scanning all N entries.

**Minimum vs ideal** (matches the prior note's tiering):

- **Minimum** (cheap, closes the trust gap): emit `sources[].capped:true` +
  `match_count_relation:"gte"` + a `source_results_capped` warning **whenever a
  per-source fetch returns exactly its 200 cap**. No count query, no cursor — just
  stop lying by omission. `returned` is free (you already have the list length).
- **Ideal**: add the bounded per-source `match_count` (a cheap `COUNT` capped at a
  ceiling, ES-style) and a **source-scoped deep cursor** (`sources[].next`) so the
  hidden tail is actually retrievable, plus the `sort=recency` override from the
  ranking note so a recency-intent query doesn't need the cursor at all.

> Implementation locus: the per-source cap is known *at the point of truncation* —
> `runFtsQueryForConnector` returns each connector's hit list before
> `roundRobinMerge`. `capped = (hits.length === 200)` is computable there for free;
> the per-source meta should be assembled from the **pre-merge** per-connector
> lists (search.js:1096–1110), not reconstructed after the merge (which has already
> lost the per-source boundaries). This is the key code insight: **the honesty
> signal must be captured before the round-robin merge erases source identity.**

---

# PART 2 — BM25 parity across SQLite FTS5 and Postgres pg_search/Tantivy

## 2.0 The question, sharpened

PDPP today runs SQLite `FTS5 bm25()` (real BM25) on the dev/SQLite backend and
`ts_rank_cd` (cover-density, **not** BM25) on Postgres. The proposal is to move
Postgres to `pg_search` (Tantivy BM25) to reach parity. The real question is
whether "BM25 on FTS5" and "BM25 on Tantivy" produce **consistent ranking** —
because a forker who runs the same instance on SQLite vs Postgres must not get
materially different result *orders* for the same query, or the
`lexical-retrieval` capability is not spec-conformant across backends.

Verdict up front: **the two are the same *family* and will rank most queries
similarly, but they are NOT bit-identical and three concrete differences can flip
order on real corpora. Score values are NOT comparable across engines (different
sign, different magnitude). The spec must therefore conform on *ordering
properties and tokenization*, never on score values — and ideally pin
tokenization so the two engines see the same tokens.**

## 2.1 The TF-saturation core is identical (good news)

Both implement the textbook Okapi TF-saturation with **the same hardcoded
constants k1 = 1.2, b = 0.75**:

- **FTS5** (sqlite.org/fts5.html, §5.1.1): the documented per-phrase score is the
  standard `IDF · tf·(k1+1) / (tf + k1·(1 − b + b·|D|/avgdl))`, summed over query
  phrases. `k1` and `b` are "hard-coded at 1.2 and 0.75 respectively." `|D|` =
  tokens in the document, `avgdl` = average over the table.
- **Tantivy** (`src/query/bm25.rs`): `const K1: Score = 1.2; const B: Score =
  0.75;`. `weight = idf · (1 + K1)`; `score = weight · [tf / (tf + norm)]` where
  `norm = K1·(1 − B + B·dl/avgdl)`. Algebraically `weight · tf/(tf+norm) =
  idf · tf·(k1+1) / (tf + k1·(1−b+b·dl/avgdl))` — **the same closed form** as FTS5.

So the term-frequency-saturation and length-normalization *shape* is identical.
For most multi-term keyword queries over a normal corpus, the two will rank the
top results in **substantially the same order**. This is why "same algorithm" is a
fair first-order description.

## 2.2 Three real divergences (the news that matters)

**(A) IDF variant differs — and one can go NEGATIVE.**
- **FTS5** uses the classic Robertson/Spärck-Jones **unsmoothed** probabilistic
  IDF: `log( (N − n(qi) + 0.5) / (n(qi) + 0.5) )`. When a term appears in **>half**
  the rows (`n > N/2`), the ratio < 1 and **IDF goes negative** — a very common
  term can *subtract* from a document's score. FTS5 does **not** clamp this.
- **Tantivy/Lucene** uses the **smoothed** IDF: `ln( 1 + (N − df + 0.5)/(df + 0.5) )`.
  The `1 +` guarantees IDF is **always ≥ 0** — a common term never goes negative,
  it just contributes near-zero.

Consequence: on a personal-data corpus full of boilerplate/common tokens (Slack
bot text, templated log lines — exactly PDPP's data), a query mixing a common term
with a rare term can rank **differently** between engines: FTS5 may *penalize*
docs heavy in the common term (negative IDF), Tantivy will not. This is a genuine,
corpus-dependent order flip, not a rounding difference.

**(B) Document-length is EXACT in FTS5, QUANTIZED (lossy) in Tantivy.**
- FTS5's `|D|` is the **exact token count** of the document.
- Tantivy replicates **Lucene's lossy fieldnorm**: `dl` is decoded from a
  **single-byte (`u8`) quantized fieldnorm** (`FieldNormReader::id_to_fieldnorm`,
  `cache[fieldnorm_id]` lookup in `bm25.rs`). Document lengths are bucketed into
  256 levels, so two documents of slightly different length can get the **same**
  length-normalization, and the length penalty is coarse.

Consequence: near-ties separated only by small length differences can order
differently. Usually minor, but it means scores are **not** reproducible to full
precision across engines even with identical tokens.

**(C) Scores have OPPOSITE SIGN and INCOMPARABLE MAGNITUDE.**
- **FTS5 `bm25()` returns a NEGATIVE number** (it multiplies by −1 so that
  *smaller = better* and `ORDER BY bm25(ft)` ascending puts best first). PDPP's
  SQLite path relies on exactly this: `ORDER BY score ASC, LIMIT 200`
  (search.js:1253–1254), and stores `score: Number(row.score)` (negative).
- **pg_search/`pdb.score()` returns a POSITIVE, unbounded number** where
  *higher = better*; you `ORDER BY pdb.score(id) DESC`. (Note: the *different*
  `pg_textsearch` extension flips this to negative-ASC — do **not** conflate them;
  PDPP's proposal is pg_search.)

Consequence: **score values cannot be passed through, compared, or thresholded
across backends.** The current PDPP Postgres path negates ts_rank_cd
(`const score = -Number(row.score || 0)`, search.js:1176) to fake FTS5's
sign convention; a pg_search migration must re-establish "smaller = better"
adaptering (negate pg_search's positive score, or invert the sort) so the merged
snapshot's cross-source ordering stays consistent with the SQLite path. This is an
**adapter-level normalization obligation**, and it is load-bearing for the
round-robin merge to be meaningful.

## 2.3 Tokenization is the bigger parity risk than the formula

The scoring formula differences (A/B) are second-order; **tokenization
differences are first-order** because they change *which documents match at all*,
not just their order. Defaults differ materially:

| Aspect | SQLite FTS5 `unicode61` (default) | Tantivy/pg_search `default`/`unicode_words` |
|---|---|---|
| Splitting | Unicode 6.1 token-char runs | Unicode word boundaries (UAX #29) / punctuation+whitespace |
| Case fold | Yes (Unicode 6.1) | Yes (lowercase) |
| **Diacritics** | **Folds by default** (`déjà`≈`deja`) | **No** accent folding by default |
| **Token length cap** | None | **Drops tokens > 40 chars** |
| Stemming | None (needs `porter`) | None (needs `en_stem`/stemmer filter) |
| Stopwords | None | None (needs StopWordFilter) |

The two **diacritic** and **token-length** default mismatches mean the same query
can match a *different set* of documents on the two backends before ranking even
starts. That is a recall difference, which is more visible to a user than a subtle
score difference.

Also note the **query-operator semantics** PDPP currently uses differ by backend:
the SQLite path builds a quoted phrase-AND FTS5 MATCH query
(`buildFtsUserTextQuery`, search.js:1318–1325), while the prior note measured
pg_search default as OR-with-term-weighting (44 vs 6,606 matches for the same
query). **AND vs OR is a massive recall divergence** and must be pinned explicitly,
independent of BM25.

## 2.4 The reference-implementation-correct way to handle "same algorithm, two engines"

The SLVP-conformant posture is **conform on observable contract, not on
implementation internals** — and shrink the divergence surface by pinning what is
pinnable:

1. **Spec the ORDERING CONTRACT and TOKENIZATION, never the score value.** The
   `lexical-retrieval` capability should require:
   (a) relevance ordering is BM25-family (TF-saturated, length-normalized, IDF-
   weighted) with k1=1.2/b=0.75; (b) a **declared, deterministic tie-break**
   (`emitted_at DESC, record_key ASC`) so equal-relevance rows order identically on
   both engines; (c) the **same tokenization pipeline** (folding, token-length,
   stemming on/off) on both backends; (d) the **same boolean operator semantics**
   (AND vs OR) on both. Conformance tests assert *relative order* and *match set*
   on a fixture corpus, **not** numeric scores.

2. **Normalize the score sign/scale at the adapter boundary.** Both adapters must
   emit a single internal convention (PDPP's existing "smaller = better"). FTS5 is
   already negative-better; pg_search is positive-better → the Postgres adapter
   must negate (or sort-invert). This keeps `roundRobinMerge` and any cross-source
   comparison correct. **Never** leak a raw engine score to the public envelope as
   a comparable number across backends; if a score is exposed, document it as
   "implementation-relative ordering hint, not comparable across deployments"
   (which is what the SQLite path already says in its comment at search.js:1223–
   1225).

3. **Pin tokenization to close the recall gap.** Configure pg_search's tokenizer to
   match FTS5's effective pipeline (or vice-versa): same case-folding, decide
   diacritic-folding **once** and apply on both (FTS5 folds by default; configure
   pg_search ascii_folding=true to match, OR disable FTS5 diacritic folding via
   `remove_diacritics=0` — pick one and pin it), and align the token-length policy.
   This matters more than the IDF nuance because it changes the match set.

4. **Accept the residual, document it, test it.** Even fully pinned, (A) negative
   vs smoothed IDF and (B) exact vs quantized length cannot be made bit-identical
   without forking an engine. The honest spec stance: **"BM25-family ranking;
   top-results order is stable across backends; exact scores and deep-tail order
   are engine-specific."** Back it with a cross-backend conformance fixture that
   asserts the **top-K set and their relative order** agree within a tolerance
   (e.g. top-10 set identical, Kendall-tau above a floor), run on BOTH engines in
   CI. This is the test that catches a forker-visible divergence before it ships.

5. **Weigh the asymmetry direction.** Today the asymmetry runs the WRONG way:
   SQLite (dev) already has real BM25; Postgres (prod) has weaker `ts_rank_cd`. So
   pg_search is a **parity-restoring** move (prod → up to dev's quality), not a
   novel-dependency gamble — but it imports a hard `shared_preload_libraries` +
   image rebuild dependency every forker inherits, and it does **not** fix the
   Slack recency/volume bug (that is Part 1's truncation honesty + a `sort=recency`
   mode, per the prior note's live measurement). Adopt pg_search for **general
   relevance quality** (real IDF, TF saturation, no density-domination — measured
   better recall and top-10 diversity), not to fix truncation.

## 2.5 Bottom line for Part 2

- **Same family, k1/b identical, TF-saturation core algebraically identical** →
  most queries rank comparably; "two engines, one algorithm" is a defensible
  contract **at the ordering level**.
- **Three real divergences** (unsmoothed-negative vs smoothed IDF; exact vs
  single-byte-quantized length; opposite sign + incomparable magnitude) mean
  ranking is **not** bit-identical and can flip on common-term-heavy queries and
  near-ties.
- **Tokenization defaults diverge more than the formula** (diacritics,
  token-length, and AND/OR operator semantics) and that changes the match set, not
  just order — so it is the higher-priority thing to pin.
- **RI-correct handling**: spec & test the **ordering contract + tokenization +
  operator semantics**, normalize **score sign/scale at the adapter**, pin
  tokenization across engines, and ship a **cross-backend top-K conformance
  fixture** in CI. Treat exact scores as engine-private and never comparable across
  deployments.

---

## References

**Fan-in / per-source truncation honesty:**

- Elasticsearch — Multi-search (`_msearch`) response shape (`responses[]`, each a
  full search response with `hits.total.{value,relation}`):
  https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-msearch
- OpenSearch — Multi-search API (same envelope):
  https://docs.opensearch.org/latest/api-reference/search-apis/multi-search/
- Elasticsearch — Paginate search results (`hits.total.relation` eq/gte,
  `track_total_hits`, `terminated_early`):
  https://www.elastic.co/guide/en/elasticsearch/reference/current/paginate-search-results.html
- Elasticsearch — Cross-cluster search (`_clusters` roll-up + per-cluster
  `details`/`status` = successful|partial|skipped|failed|running; `is_partial`):
  https://www.elastic.co/docs/explore-analyze/cross-cluster-search
- Algolia — Search multiple indices / `multipleQueries` (`results[]` in order, no
  cross-index merge; per-result `nbHits` + `exhaustiveNbHits`):
  https://www.algolia.com/doc/libraries/sdk/v1/methods/multiple-queries
- Algolia — getRankingInfo / `exhaustive` (exact vs approximate count boolean):
  https://www.algolia.com/doc/api-reference/api-parameters/getRankingInfo/
- Stripe — pagination / search (`has_more` always; `total_count` opt-in, ≤10k):
  https://stripe.com/docs/api/pagination
- Splunk — federated search (`splunk_federated_provider` provenance, per-provider
  count breakout):
  https://help.splunk.com/en/splunk-cloud-platform/search/federated-search/

**BM25 cross-engine parity:**

- SQLite FTS5 — `bm25()` auxiliary function (formula, k1=1.2/b=0.75 hardcoded,
  unsmoothed Robertson IDF `log((N−n+0.5)/(n+0.5))`, ×−1 negative-better,
  per-column weight args, exact `|D|` token count):
  https://sqlite.org/fts5.html
- Tantivy — `src/query/bm25.rs` (`const K1=1.2; const B=0.75`;
  `weight = idf·(1+K1)`; `score = weight·tf/(tf+norm)`; smoothed Lucene IDF
  `ln(1+(N−df+0.5)/(df+0.5))`; single-byte quantized fieldnorm via
  `FieldNormReader::id_to_fieldnorm`, "explain format copied from Lucene"):
  https://github.com/quickwit-oss/tantivy/blob/main/src/query/bm25.rs
- ParadeDB pg_search — BM25 scoring (`pdb.score()`/`paradedb.score()` POSITIVE
  unbounded, higher=better, `ORDER BY … DESC`; default tokenizer `unicode_words`):
  https://docs.paradedb.com/documentation/sorting/score
- ParadeDB — tokenizers (default unicode word splitting + lowercase; stemmer /
  stopwords / ascii_folding are opt-in filters):
  https://docs.paradedb.com/legacy/indexing/tokenizers
- Neon — pg_search extension overview (Tantivy under the hood, BM25):
  https://neon.com/docs/extensions/pg_search
- Tiger Data `pg_textsearch` — CONTRAST: `<@>` returns NEGATIVE BM25 (lower=better)
  — do not conflate with pg_search's positive convention:
  https://github.com/timescale/pg_textsearch
- Elastic — Practical BM25 Part 2 (k1/b semantics, IDF, length normalization):
  https://www.elastic.co/blog/practical-bm25-part-2-the-bm25-algorithm-and-its-variables

**PDPP implementation (grounding):**

- `reference-implementation/server/search.js` — per-connector FTS5 `bm25()` query
  (`ORDER BY score ASC LIMIT 200`, :1234–1254), per-connector `LIMIT 200` Postgres
  call (:1165), score-sign negation for Postgres (:1176), `roundRobinMerge`
  (:1327), `buildFtsUserTextQuery` phrase-AND (:1318), envelope `has_more` (:866).
- `reference-implementation/server/postgres-search.js` — current `ts_rank_cd`
  ranking (:207), the path a pg_search migration replaces.
- `openspec/changes/add-lexical-retrieval-extension/specs/lexical-retrieval/spec.md`
  — the public `lexical-retrieval` capability contract that must conform across
  both backends.

**Companion notes:**
- `lexical-search-ranking-recency-prior-art-2026-06-15.md` — Axis 1 (recency
  blend) + Axis 2 (truncation honesty, minimum/ideal tiers); live measurement that
  pg_search does NOT fix the Slack recency bug but DOES improve general quality.
- `lexical-search-freshness-prior-art-2026-06-15.md` — index lag / `as_of`
  (distinct problem; the index is current, not stale — the defect is rank+cap).
