# PDPP observations from an agent session — 2026-06-25

Author: Claude (agent operating on Tim's machine, owner-token / local bypass).
Context: I was using PDPP to reconstruct a Slack discussion (engineering e2e
blockers) and cross-check coverage. Along the way I hit several PDPP behaviors
worth a maintainer's attention. Reporting them verbatim with evidence; failures
and rough edges are the useful signal.

## Auth context (so the rest is interpretable)

- I authenticated with `PDPP_OWNER_TOKEN` (the owner self-export bearer, local
  bypass), **not** a scoped third-party grant.
- `GET /v1/schema` confirms this: `bearer.scope = "owner"`. There is **no
  `grant_id` field anywhere** in the owner-token response — which is correct, but
  worth noting: an agent asking "what's my grant id?" under the owner token has no
  answer to surface. The owner bearer is identified by `scope: "owner"`, not a
  `grt_…` id. (Schema top-level keys: `object, bearer, connectors, links, meta`.)

## P0 — Search index is STALE relative to the records store

This is the highest-impact issue and it caused me to give a wrong intermediate
conclusion before I caught it.

- `POST /v1/search` (and the `search`/`hybrid`/`semantic` MCP variants) returned
  **only results from ~April 2026 or earlier**, for queries whose exact terms
  appear verbatim in messages I then retrieved directly. Example: a query for
  "audit zip aggregate audits" returned April hits and missed a thread from the
  same day that contained those words.
- Meanwhile `query_records` (and the raw `/v1/streams/messages/records` endpoint)
  returned data **current to within hours** (newest message I saw: a timestamp
  from earlier the same day).
- So: **records ingestion is live; the search index is lagging by ~2 months.**
- Impact on agents: the obvious first tool (keyword/semantic search) silently
  returns a months-old view with **no staleness signal**, so an agent concludes
  "this channel/topic isn't here" when it actually is. I made exactly that error
  and only recovered by falling back to record-level paging.
- Suggested fixes, in priority order:
  1. Fix/refresh the search index so it tracks ingestion.
  2. Until then, **surface index freshness** — add an `index_as_of` /
     `as_of` timestamp (or a `warnings: ["stale_index"]`) to search responses so a
     caller can detect the gap instead of trusting empty/old results.

## P1 — Connector channel coverage is narrower than it looks (Slack)

- The Slack connector (`cin_f565a96cb0a114b0a27e9606`) is connected, but under the
  owner token it only surfaced messages from a **small set of channels**
  (general/security/token chat — e.g. `C01SQU6GGH2`, `C016X99931T`). Paging back
  ~9 days / ~1200 messages, the engineering channel where the relevant work lived
  (`C07JYF0U8BY`) **never appeared at all**.
- So the Slack connector appears to ingest only a subset of channels (whichever it
  was scoped/joined to), not the workspace. That's a reasonable design, but it's
  **invisible to a consumer** — there's no way to ask "which channels does this
  connection cover?" before relying on it. An agent searching for a topic that
  lives in an un-ingested channel gets clean-but-incomplete empty results.
- Suggested fix: expose a **coverage manifest** per connector/connection — e.g.
  the list of channel ids (and ingestion high-water marks) the Slack connection
  actually indexes — so a caller can tell "absent because not covered" from
  "absent because it doesn't exist." (This pairs naturally with the P0 freshness
  field: cover *what* and *as-of when*.)

## P2 — `fetch` dead-ends on a not-yet-ingested message permalink

- Given a Slack permalink, the natural move is `fetch` with the id derived from the
  URL (`…p1781566527056169` → `messages:C…:1781566527.056169`). For a **recent**
  message not yet ingested, this returns `not_found` — even when the rest of that
  message's **thread** is fully present.
- Recovery that worked: `query_records` filtered by the parent `thread_ts` (also
  derivable from the permalink) returned the whole surrounding thread.
- Suggested fix: either (a) have `fetch` on a missing-but-recent id return a hint
  ("not found; try thread_ts=<parent>"), or (b) document the
  permalink → `thread_ts` recovery path. Right now it's a silent dead-end.

## Minor / positive

- `query_records` with `filter` by `channel_id` + `thread_ts` worked perfectly and
  was the reliable path throughout — deterministic, current, paginates cleanly via
  `next_cursor`. It's the workhorse; the issues above are all on the
  search/fetch/coverage-introspection side, not the core record store.
- The owner-token full view (`scope: owner`) behaved correctly and consistently.

## One self-critical note (for calibration, not a bug)

Twice this session I trusted an empty/stale **search** result as evidence of
absence and stated a conclusion before verifying against `query_records`. That's
partly my error — but the lack of any freshness/coverage signal (P0/P1) is what
made the wrong conclusion *reachable*. Surfacing those two facts would let agents
self-correct instead of confidently reporting a stale view.
