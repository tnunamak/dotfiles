# Lexical search: relevance + recency ranking & honest truncation — prior art

Date: 2026-06-15
Status: captured (informative; supports an SLVP-ideal fix to PDPP lexical search
ranking + per-source truncation)

Companion note: `lexical-search-freshness-prior-art-2026-06-15.md` covers a
*different* problem — index lag / read-your-writes / eventual consistency. This
note is about **ranking** (recent matches buried under a dense old corpus) and
**truncation honesty** (a per-source cap silently hiding an entire date range).
The two are complementary and must not be conflated: PDPP's data here is current
and indexed; the failure is ordering + capping, not freshness.

---

## 0. The confirmed PDPP failure, grounded in the live code

Diagnosed empirically against live Postgres; not re-litigated here. The code that
produces it:

- **Per-connector ranking** — `reference-implementation/server/postgres-search.js`
  `postgresLexicalSearch()`:
  ```sql
  ts_rank_cd(document, plainto_tsquery('simple', $3)) AS score
  ...
  ORDER BY score DESC, record_key ASC
  LIMIT $4
  ```
  Pure cover-density relevance. No recency term. Ties break on `record_key`
  (arbitrary), never on recency.

- **Per-connector hard cap** — `reference-implementation/server/search.js`
  `buildSnapshot()` → adapter calls `postgresLexicalSearch({ ..., limit: 200 })`
  (search.js:1165). Each connector contributes at most its top **200** rows by
  relevance.

- **Cross-connector merge** — `roundRobinMerge(perConnectorHits)` (search.js:1110,
  1327) interleaves the per-connector top-200 lists so no single connector
  dominates the *merged* page.

- **Operation slice** — `operations/rs-search-lexical/index.ts` then paginates
  the merged snapshot with `has_more` / `next_cursor` (index.ts:1024–1027) and
  emits a `limit_clamped` warning when the caller's `limit` exceeds 100.

**Why "nothing newer than April" happens.** Slack had 185,840 of 201,333 messages
stamped with one identical bulk `emitted_at` (2026-04-20). Those messages are
denser/longer → highest `ts_rank_cd` → they occupy the entire top-200 for that
connector. Recent messages *do* match and *are* indexed, but rank past position
200 and are dropped **before the snapshot exists**. So:

1. The recency blend is missing (relevance-only order), AND
2. the per-source cap truncates **before** `has_more`/`next_cursor` can help —
   the operation layer paginates a snapshot that already excised everything past
   rank 200 for that source. Paging forward never reaches the dropped rows
   because they were never candidates. This is the crux: **PDPP's existing
   `has_more` is honest about the *merged page* but blind to the *per-source
   truncation* upstream of it.**

The fix therefore has two independent axes. Axis 1 stops recent matches from
being buried. Axis 2 makes any remaining truncation legible to the caller. Both
are needed: even a perfect recency blend leaves a source with millions of matches
truncated at 200, so the cap must signal itself.

---

## AXIS 1 — Relevance + recency ranking blend

### 1.1 Elasticsearch `function_score` + `gauss` decay (the reference recipe)

Source: https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-function-score-query.html

The industry-standard "boost recent but keep relevance primary" recipe is a
**decay function** multiplied into the relevance score. ES exposes `linear`,
`exp`, and `gauss` decay over a numeric/date/geo field, each parameterized by
`origin`, `scale`, `offset`, `decay`:

```js
"gauss": {
  "@timestamp": { "origin": "now", "scale": "10d", "offset": "5d", "decay": 0.5 }
}
```

Semantics (verbatim from the docs):
- `origin` — the point from which distance is measured (for recency, `now`).
- `offset` — a flat zone of no decay around the origin (everything within
  `offset` of `now` is treated as equally fresh; e.g. "last 5 days all count as
  current").
- `scale` + `decay` — together fix the curve: a document at distance `scale` from
  `origin±offset` gets multiplier `decay`. So `scale=10d, decay=0.5` means "a
  doc 10 days older than the fresh zone keeps 50% of its score."

Gauss multiplier:

```
S(doc) = exp( -( max(0, |t_doc - origin| - offset) )^2 / (2σ²) ),
         σ² = -scale² / (2·ln(decay))
```

**The load-bearing detail is `boost_mode` / `score_mode`.** ES combines the decay
with the text relevance via `boost_mode`:
- `boost_mode: multiply` (default) — `final = relevance × decay`. Relevance stays
  primary: a strong textual match that's old can still outrank a weak match
  that's recent. This is what "boost recent, keep relevance primary" *means*.
- `boost_mode: sum` — `final = relevance + decay·weight`. Recency can override
  relevance; appropriate only for feed-like surfaces.

The default `multiply` with a gentle `gauss` is the canonical search default. The
choice of `gauss` (vs `exp`) matters: gauss has a *flat top* (the `offset` zone +
the rounded peak) so near-current documents are not over-discriminated, then
falls off smoothly — which is exactly right for "treat everything in the last
N days as fresh, then taper."

### 1.2 Algolia — "relevance first, recency as a tie-break"

Sources:
- https://www.algolia.com/doc/guides/managing-results/relevance-overview/in-depth/ranking-criteria/
- https://www.algolia.com/doc/guides/managing-results/must-do/custom-ranking/

Algolia takes the opposite-but-instructive stance: recency is **not blended into
the relevance score at all**. Its eight textual criteria (Typo, Geo, Words,
Filters, Proximity, Attribute, Exact) run first as a strict lexicographic
tie-break ladder. Only when records are *still tied* does **custom ranking**
(e.g. `release_date desc`, popularity) break the tie. Verbatim:

> "After Algolia applies its default relevance criteria, custom ranking breaks
> ties using attributes you define, such as popularity, rating, or release date."

This is the **tie-break model**: recency never demotes a clearly-better textual
match; it only orders matches the text scorer can't distinguish. It is the
*conservative* end of the spectrum — strong honesty (a keyword search stays a
keyword search) but it does nothing for the PDPP failure, because PDPP's old
messages are *not* tied with the recent ones — `ts_rank_cd` genuinely scores the
old dense ones higher. Pure tie-break would not surface the recent matches.

**Synthesis of ES vs Algolia.** The two define a spectrum:
- Algolia = recency only on **exact ties** (safest; insufficient alone here).
- ES `gauss × multiply` = recency as a **continuous gentle multiplier** on the
  relevance score (surfaces near-ties toward recent without letting recency
  dominate).

The SLVP-correct default for a general keyword search is **closer to ES**: a
gentle multiplicative recency decay, tuned so it reorders *near*-ties but cannot
flip a strong textual match under a weak one — plus a deterministic recency
tie-break for genuine ties (the Algolia move) so identical-score rows order
newest-first instead of by `record_key`.

### 1.3 Postgres FTS specifically — the principled blend

Source: https://www.postgresql.org/docs/current/textsearch-controls.html

Postgres docs explicitly invite this — and warn about the trap:

> "Different applications might require additional information for ranking, e.g.,
> document modification time. The built-in ranking functions are only examples.
> You can write your own ranking functions and/or combine their results with
> additional factors to fit your specific needs."

Two pitfalls that make a naive `score * exp(-lambda*age)` hacky:

1. **`ts_rank_cd` is unbounded and query-dependent.** Its magnitude depends on
   query length, term frequency, and document length; scores from query A are not
   comparable to query B, and within one query the scale is arbitrary. Multiplying
   a raw unbounded relevance by a raw recency factor lets whichever has the bigger
   dynamic range dominate unpredictably — the blend is not stable across queries.

2. **No fixed ceiling to normalize against.** You cannot divide by a known max.

**The principled fix is Postgres's own `normalization` argument**, which bounds the
score before blending. `ts_rank`/`ts_rank_cd` take an integer bitmask:
- `1` / `2` — divide by (or by the log of) document length (corrects the
  "old messages win because they're longer/denser" bias *directly* — this is the
  exact PDPP pathology).
- `32` — `rank / (rank + 1)` — squashes the unbounded rank into **(0, 1)**,
  giving a stable, comparable relevance on a fixed scale.

So compute a **bounded relevance** `rel ∈ (0,1)` via `normalization = 32`
(optionally `|2` to also discount length), then combine with a **bounded recency**
`rec ∈ (0,1)` from a gauss/exp decay over `emitted_at`. Two principled
combination forms, both expressible in one `ORDER BY`:

**(a) Multiplicative (ES `boost_mode: multiply` analog) — recommended default:**

```sql
-- bounded relevance in (0,1): cover-density, length-discounted, squashed
ts_rank_cd(document, plainto_tsquery('simple', $q), 2|32) AS rel,
-- bounded recency in (0,1): exponential decay over age in days
exp( -extract(epoch from (now() - r.emitted_at)) / $tau_seconds ) AS rec
...
ORDER BY (rel * (1 - $alpha + $alpha * rec)) DESC, r.emitted_at DESC, lsi.record_key ASC
```
Here `$alpha ∈ [0,1]` is the recency weight (e.g. 0.3): at `alpha=0` it is pure
relevance; the factor `(1 - alpha + alpha*rec)` keeps relevance primary while
letting recency reorder near-ties, never zeroing an old strong match. `$tau`
(the decay time-constant, e.g. 30 days) controls how fast freshness tapers. The
trailing `r.emitted_at DESC` is the **deterministic recency tie-break** for true
ties (the Algolia move), replacing the arbitrary `record_key` ordering.

**(b) Weighted sum of two bounded scores (ES `boost_mode: sum` analog):**

```sql
ORDER BY ($w_rel * rel + $w_rec * rec) DESC, r.emitted_at DESC, lsi.record_key ASC
```
Valid *only because both terms are pre-bounded to (0,1)* — summing the raw
unbounded `ts_rank_cd` with a decay would be the hacky version the pitfalls warn
against. Sum lets recency override relevance more aggressively; prefer (a) for a
search surface, reserve (b) for feed-like surfaces.

**Why (a) is the SLVP default:** it mirrors the most battle-tested recipe
(ES default), it is monotonic and explainable ("relevance, gently freshened"),
both inputs are normalized so the blend is stable across queries, and the
tie-break is deterministic.

> Implementation note for PDPP: `document` is a generated `tsvector`; adding the
> `2|32` normalization arg and the `emitted_at`-based `rec` term is a localized
> change to the `SELECT`/`ORDER BY` in `postgresLexicalSearch`. `emitted_at` is
> already JOINed in (`r.emitted_at`, postgres-search.js:206). No schema change is
> required for the blend itself.

### 1.4 Search vs feed — when recency should matter, and the SLVP default

The distinction the literature converges on:

- **Specific-term keyword search** ("invoice #4021", "kubernetes OOMKilled") is
  **relevance-first**: the user wants *the* matching record, not the newest
  thing. Aggressive recency here is wrong — it would bury the exact answer.
- **Ties / near-ties** should break **toward recent**: when the scorer genuinely
  cannot distinguish two matches, newer is the better default (the Algolia
  tie-break, and the gentle tail of the ES gauss).
- **Browse / feed / "latest" surfaces** are **recency-first**: here a `sum`/large
  `alpha`, or an explicit `sort=emitted_at desc`, is correct.

**SLVP-correct default for PDPP's lexical search:** relevance-primary with a
**gentle multiplicative recency blend** (form (a), modest `alpha`), so:
- a strong textual match always beats a weak one regardless of age (honest
  keyword search), but
- among comparable matches, recent wins, and
- genuine ties are ordered newest-first deterministically.

And — critically — expose an explicit **`sort` override** (`relevance` default vs
`recency`) so a caller who *wants* "newest matching messages" gets a
recency-first order without the blend having to guess. This is the move that most
directly answers the user's mental model ("why is there nothing from this month?")
— it lets them ask for recency explicitly instead of inferring it.

### 1.5 The cap × ranking interaction — deep results behind a cap

The user's sharpest point: **a perfect recency blend does not fix a 200-cap when
one source has millions of matches.** Even reordered, only 200 per source survive
into the snapshot; a different 200 are surfaced, but a date range can still fall
off the bottom. How mature systems handle "more results exist behind the cap":

- **Per-source cursoring (deep pagination).** Elasticsearch `search_after` +
  PIT (point-in-time), and OpenSearch equivalent, let you page *past* any cap by
  carrying the last sort-tuple forward — there is no fixed wall at N. The PDPP
  analog: make the **per-connector** fetch cursorable (carry the last
  `(score, emitted_at, record_key)` tuple per connector), not just the merged
  page. PDPP already cursors the *merged* snapshot; the gap is that the
  per-source slice is a fixed `LIMIT 200` with no continuation.

- **Per-facet / per-source results + counts** (Algolia facet model, ES
  aggregations): return *how many* a source has and let the client drill into one
  source. The UI affordance is **"and N more from <source>"** — instead of one
  flat 200-cap, the source advertises its true match count and offers a
  source-scoped continuation.

- **Two-phase widen-then-trim.** Keep a generous per-source candidate cap for the
  *merge*, but let a caller re-run scoped to a single source (`streams=` /
  connector filter already exist in the op's allowlist) with its own deep
  pagination — so the cap on the cross-source page never hides a source's tail;
  it just defers it to a scoped query.

**Recommended PDPP shape:** keep the round-robin merge cap for the *default
cross-source page* (it correctly prevents one noisy source from drowning others),
but (i) make the per-connector fetch **cursorable** so paging forward can pull a
source's next 200 by the blended order, and (ii) when a source's cap is hit,
**signal it** (Axis 2) so the caller can scope-and-deepen rather than wrongly
conclude the data ends in April.

---

## AXIS 2 — Honest result-capping / truncation signals

The canonical principle, stated once: **a result set truncated by a cap MUST be
distinguishable from a result set that is genuinely complete.** Every mature
search API encodes this; only the field names differ.

### 2.1 Elasticsearch / OpenSearch — `total.relation` + `terminated_early`

Sources:
- https://www.elastic.co/guide/en/elasticsearch/reference/current/paginate-search-results.html
- https://opensearch.org/docs/latest/api-reference/search-apis/search/

The honesty pattern is built into the hit-count itself. `hits.total` is an
**object, not a number**:

```json
"hits": { "total": { "value": 10000, "relation": "gte" }, "hits": [ ... ] }
```

- `relation: "eq"` — `value` is the **exact** total.
- `relation: "gte"` — `value` is a **lower bound**: "there are *at least* this
  many; the real total was not counted." By default ES stops counting at 10,000
  (`track_total_hits: 10000`) precisely so a huge corpus doesn't pay for an exact
  count. `track_total_hits: true` forces an exact count (`eq`) at a cost.

This `eq` vs `gte` distinction is the **single most important pattern** for PDPP:
it is exactly "this set is complete" vs "this set is a truncated lower bound."

`terminated_early: true` is the second signal — set when a query stopped early
(e.g. `terminate_after` reached), telling the caller the scan did not exhaust the
matches. It is the per-query "I was capped" boolean.

### 2.2 Stripe — `has_more` + opt-in, bounded `total_count`

Source: https://stripe.com/docs/api/pagination

Stripe's search response:
```json
{ "object": "search_result", "has_more": false, "next_page": "...", "data": [...] }
```
- `has_more: boolean` — the minimal, always-present "more exist beyond this page"
  signal. PDPP already has this at the merged-page level.
- `total_count` — **opt-in** (must `expand`) and **"only accurate up to 10,000."**
  Stripe deliberately makes the exact total expensive/optional and bounds its
  accuracy — the same honesty as ES `gte`, expressed as a documented ceiling.

Lesson: don't promise an exact grand total you can't cheaply compute; promise
`has_more` always, and bound any count you do return.

### 2.3 Algolia — `nbHits` + `exhaustiveNbHits` / `exhaustive`

Sources:
- https://www.algolia.com/doc/api-reference/api-methods/search/
- https://www.algolia.com/doc/api-reference/api-parameters/getRankingInfo/

Algolia returns `nbHits` (matches found) alongside an **`exhaustiveNbHits`** /
`exhaustive.nbHits` boolean: `true` = the count is exact; `false` = approximate
(Algolia stopped counting for performance). Same eq/gte idea as a boolean. Algolia
also caps retrievable hits at 1,000 and directs callers to a separate `browse`
operation for deep traversal — i.e. *the cap is documented and a deep-traversal
escape hatch is named*, never silent.

### 2.4 The canonical shape for PDPP

PDPP's failure is specifically a **per-source** cap, so the honesty signal must be
**per-source**, not only on the overall page. Recommended response additions
(naming consistent with PDPP's existing `has_more` / `warnings` / `disclosure`
envelope):

**(a) Per-source truncation metadata** in the disclosure/meta block:
```json
"sources": [
  {
    "connection_id": "...",
    "connector_key": "slack",
    "returned": 200,
    "capped": true,                 // this source hit its per-source cap
    "match_count_relation": "gte",  // ES-style: "at least"
    "match_count": 200,             // lower bound when capped; exact when not
    "next": "<source-scoped cursor>" // deep-paginate THIS source (Axis 1.5)
  }
]
```
- `capped: true` + `match_count_relation: "gte"` is the load-bearing pair — it is
  the eq/gte / `exhaustiveNbHits` / `terminated_early` honesty, scoped per source.
  A complete source emits `capped: false`, `match_count_relation: "eq"`.

**(b) A structured warning** (PDPP already has a `warnings[]` array with codes like
`limit_clamped` and a source-skipped code — this slots in beside them):
```json
{
  "code": "source_results_capped",
  "connection_id": "...",
  "detail": { "returned": 200, "cap": 200, "relation": "gte" },
  "message": "Showing the top 200 matches from Slack by relevance; more matches exist (including more recent ones). Re-run scoped to this source, or sort by recency, to see them."
}
```
This is the signal that would have prevented the entire "nothing newer than April"
misread: instead of silently dropping the recent tail, the response says *out
loud* that Slack's results were capped and that more (incl. recent) exist.

**Minimum bar vs ideal:**
- *Minimum* (cheap, high-value): add `capped: true` + `source_results_capped`
  warning whenever a per-source fetch returns exactly its cap. No count query, no
  cursor — just stop lying by omission. This alone closes the trust gap.
- *Ideal*: add the per-source `match_count` (bounded, ES `gte` style) and a
  source-scoped deep cursor (Axis 1.5) so the caller can actually retrieve the
  tail, plus the explicit `sort=recency` override (Axis 1.4).

---

## 3. Top recommendation per axis (the SLVP call)

**Axis 1 — ranking blend:** Adopt the **Elasticsearch `gauss × multiply`
pattern, realized in Postgres** as a *bounded* relevance × bounded recency
product in `ORDER BY`:
1. Bound `ts_rank_cd` with `normalization = 2|32` (length-discount + `rank/(rank+1)`
   squash) → `rel ∈ (0,1)`. This *directly* neutralizes the "old dense messages
   win because they're longer" bias and makes scores comparable.
2. Multiply by a gentle recency factor `(1 - α + α·rec)` where `rec` is an
   exponential decay over `now() - emitted_at` (modest `α≈0.3`, `τ≈30d`), so
   relevance stays primary and recency reorders near-ties only.
3. Replace the arbitrary `record_key` tie-break with `emitted_at DESC` (the
   Algolia deterministic-recency tie-break).
4. Expose an explicit `sort=relevance|recency` override for the "newest matching"
   intent.

This is localized to `postgresLexicalSearch`'s `SELECT`/`ORDER BY`; `emitted_at`
is already in scope. It is principled (both factors normalized, stable across
queries), not the hacky raw `score·exp(-λ·age)`.

**Axis 2 — truncation honesty:** Adopt the **ES `total.relation` eq/gte pattern,
scoped per source**. The canonical shape is a per-source `capped: boolean` +
`match_count_relation: "eq"|"gte"` in the result meta, backed by a structured
`source_results_capped` warning. The non-negotiable invariant: **a per-source
result set truncated by the cap must be distinguishable from a complete one** —
PDPP currently violates this, which is the entire reason "the data looks like it
ends in April." Minimum viable fix is the `capped`/warning pair; the ideal adds a
bounded per-source count and a source-scoped deep cursor so the hidden tail is
actually retrievable.

Together: Axis 1 stops recent matches from being buried in the common case; Axis 2
guarantees that whenever the cap *does* still hide results, the caller is told —
so "nothing newer than April" can never again be silently false.

---

## EVIDENCE: ParadeDB does NOT fix this bug; recency-blend alone is insufficient (live-data measurement, 2026-06-15)

Measured the candidate fixes against the REAL live Slack "block" data (cin_f565a96cb0a114b0a27e9606), not theory:

**Feasibility of pg_search (ParadeDB):** CONFIRMED installable — live container is Debian-12-bookworm / PG 16.13 / has apt; pg_search ships prebuilt bookworm pg16 binaries and is officially pgvector-compatible (hybrid BM25+vector). BUT pg16 REQUIRES pg_search in `shared_preload_libraries` + restart (it spawns a bg worker) — a non-trivial live-data-plane + image change, and a dependency every PDPP forker would inherit.

**Recipe-fix measurement (ts_rank_cd normalization 2|32 + recency blend):**
- Current (broken) `ts_rank_cd` DESC: top 8 all 2026-04-20.
- `2|32` length-discount normalization: top 8 STILL all 2026-04-20.
- + recency blend (0.7 rel + 0.3 recency, 30d τ): top 8 STILL all 2026-04-20.
- The recency multiplier short of destroying relevance for normal queries cannot lift recent hits over the dense old corpus.

**The decisive scale numbers:** for "block" in Slack — **1,829 old (≤04-21) matches vs only 5 recent (>05-01) matches.** The 5 recent matches are CLEAN matches ("yes block the additional promo", "this is what it will block"). So:

**ROOT NATURE: this is a VOLUME + RECENCY-INTENT problem, NOT a relevance-scoring-quality problem.** The old bulk-load (185,840 messages at one 04-20 timestamp) simply CONTAINS far more genuine "block" matches than recent data. Relevance ranking correctly surfaces them; there are just ~1829 of them vs 5 recent. Better relevance scoring (ParadeDB BM25/IDF — its entire value proposition) changes the SCORES but not the OUTCOME: the old messages legitimately contain the term and still fill the cap. **ParadeDB does not address this bug.**

**THE ACTUAL SLVP FIX (evidence-driven):**
1. **Honest truncation signal** — per-source `capped: true` + `has_more` + `match_count_relation: gte` so a caller KNOWS recent/more hits exist beyond the returned page. (The agent's real, surviving P1 — reframed from "stale index" to "results truncated, silently".) This is the load-bearing fix.
2. **A `sort=recency` mode** — so "show me recent messages mentioning X" is directly expressible; relevance-only ranking is the wrong default for a recency-intent query. Stripe/Algolia both expose sort overrides for exactly this.
3. **Recency-into-relevance tie-break** (normalized `2|32` + `emitted_at DESC` tie-break) — a genuine but MARGINAL improvement; helps near-ties, does not fix the volume case. Worth doing (cheap, both backends) but not sufficient alone.
4. **ParadeDB: REJECTED for this bug** on evidence — it's a relevance-quality upgrade for a non-relevance-quality problem. Note it as a future option IF a real relevance-quality gap (IDF, multi-term) is later measured, but do not adopt it to fix this.

**Meta:** the user leaned toward ParadeDB ("quality is critical, paradedb sounds right") and authorized proceeding on my confidence; the live measurement showed it doesn't fix the actual bug, so proceeding would have been mis-targeted. Evidence over principle, again.

---

## MEASURED: BM25 (pg_search 0.24.0) vs ts_rank_cd on REAL data — quantified quality gap (2026-06-15)

Stood up paradedb/paradedb:latest (pg16, pg_search 0.24.0 + pgvector 0.8.2) on :55433, loaded a REAL slice of live data (156,517 Slack + 80,590 ChatGPT message texts from the live lexical_search_index, 04-19..06-16), built both a tsvector GIN and a pg_search BM25 index on identical data, and compared.

**Retrieval (recall) difference is large:** query "validator block sync" — ts_rank_cd via `plainto_tsquery` (AND semantics) matched **44** rows; BM25 (default OR + term weighting) matched **6,606**. ts_rank_cd's AND requirement drops partial matches; BM25 scores by how many/how-rare terms match. Real recall win for BM25.

**Ranking-quality difference is real and measurable — distinct-bodies-in-top-10 (higher = less duplicate-domination, more useful):**
| query | ts_rank_cd | BM25 |
|---|---|---|
| rate limit error | 4/10 | 5/10 |
| validator block sync | 10/10 | 10/10 |
| deployment failed rollback | 5/5 | 9/10 |
| data validation error | 4/10 | 5/10 |
| **github pull request review** | **1/10** | **5/10** |
| token refresh expired | 6/10 | 10/10 |

The "github pull request review" case is the headline: ts_rank_cd returns the SAME message 10× (it over-rewards term DENSITY, so one message repeating common words dominates), while BM25 returns 5 distinct relevant messages. BM25's TF saturation (k1) + IDF prevents density-domination and down-weights common terms. ts_rank_cd has neither.

**REVISED VERDICT on ParadeDB — the earlier "ParadeDB doesn't help" was too strong:**
- ParadeDB does NOT fix the Slack RECENCY bug (that's sort-mode + cap-honesty — confirmed unchanged).
- ParadeDB DOES deliver materially better GENERAL search quality: better recall (OR + partial match), better diversity (no density-domination), real IDF (rare discriminating terms weighted). On a personal-data corpus full of repeated/templated content (Slack bot messages, "X commented on APP-444", log dumps), ts_rank_cd's density-domination is a recurring real defect, not an edge case.
- Since lexical search over personal data is a CORE value prop, the quality gap is meaningful "left on the table." This re-opens ParadeDB as a genuine candidate on QUALITY grounds — to be weighed against: (a) the reference-impl dependency cost (shared_preload_libraries, image rebuild, every forker inherits pg_search), and (b) the SQLite backend has NO pg_search equivalent, so adopting BM25 on PG would create a relevance ASYMMETRY between backends (SQLite FTS5 bm25() IS real BM25 though — so SQLite is already ahead; adopting pg_search would bring PG to PARITY with SQLite, not ahead). 

**Key reframe:** SQLite already uses real BM25 (FTS5 bm25()). Postgres uses the weaker ts_rank_cd. So pg_search would bring the PRODUCTION backend up to the quality the DEV backend already has — that's a parity argument, not a novel-dependency argument. The asymmetry currently runs the WRONG way (prod weaker than dev).

---

## DEEPEST ROOT CAUSE (confirmed live, 2026-06-15): search ranks by INGEST time, not AUTHORED time — SYSTEMIC

The red-team lens "is 04-20 ingest-time vs authored-time?" hit the real foundational defect. CONFIRMED against live PG:

- The 185,840 Slack messages sharing `emitted_at = 2026-04-20T14:23:13` (one ingest moment) have `sent_at` (authored time, in payload + declared cursor_field) spanning **2020-07-12 to 2026-04-20 — 185,632 DISTINCT authored times.** `emitted_at` is INGEST time; `sent_at` is real authorship.
- **PROOF:** ordering "block" matches by `sent_at DESC` returns 2026-06-16, 06-15, 06-14, 05-07… — the exact "missing" recent messages, immediately. The data was never missing; search ranks/sorts by the WRONG clock.
- **SYSTEMIC, not Slack-only:** `emitted_at` clusters at backfill moments for EVERY connector — records-per-distinct-emitted_at: claude-code 1,873, chatgpt 2,699, whatsapp 43,482, codex 1,078, slack 607, gmail 496. So `emitted_at` is meaningless as a recency signal across the board; it only looks fine for connectors whose backfill happened to spread ingest over time.

**This reframes the SLVP fix — recency must use manifest-declared AUTHORED time:**
- Each stream declares `cursor_field` / `consent_time_field` (slack messages: `sent_at`). That is the authored-time field. Search recency ranking + any recency blend + a sort=recency mode MUST order by the declared authored-time field, NOT `emitted_at`.
- The lexical search currently SELECTs `r.emitted_at` (postgres-search.js:205, search.js:1239) and the snapshot/results carry `emittedAt` + `authoredAt` (authored_at was null in the snapshot I examined — confirming the recency signal in use is the ingest one).
- This is a DATA-MODEL / projection fix (surface + rank by authored time), largely INDEPENDENT of the BM25-vs-ts_rank_cd quality question. The two are separable wins:
  - (A) authored-time recency → fixes the "recent messages missing" bug correctly and systemically.
  - (B) BM25 (pg_search, PG→SQLite parity) → fixes density-domination + recall (general quality).
- Doing (A) alone likely RESOLVES the reported bug. (B) is the quality elevation. The recency blend only makes sense ONCE recency = authored time.

**Reframed confidence:** the reported bug's true root cause is (A) ingest-vs-authored time, ~95% (proven by the sent_at ordering). (B) BM25 adoption is a real but SEPARATE quality decision. The earlier escalating designs (watermark, instance-split, cap-only, ParadeDB-as-bugfix) all missed (A) because they reasoned about ranking/freshness without questioning which TIMESTAMP recency was computed on.
