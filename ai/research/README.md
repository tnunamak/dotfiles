# Research corpus

Durable home for findings from expensive research (web prior-art sweeps, library
evaluations, design investigations). Research costs a lot of tokens to produce and
nothing to store — capture it here so it survives the session that produced it and
agents don't redo it.

**This file is the convention. It is NOT always-on context** — the always-on rule
lives in `ai/AGENTS.md` (`# Research corpus`) and points here. Read this when you're
about to write or substantially reorganize an entry.

## What belongs here — the worthiness test

Not all research is corpus research. Before writing an entry (or recovering one from a
session log), apply this test. It is the definition; don't adjudicate it case-by-case.

**KEEP if the finding is durable and reusable across future work:**
- Prior-art sweeps (how do others solve X — Stripe, Plaid, standards bodies, OSS projects).
- Library / tool / approach evaluations with a verdict ("X beats Y for Z because…").
- Design investigations that resolve a real question ("how should we structure X").
- A non-obvious fact about an external system/API/protocol that cost real search to find
  and will be true next month.

**SKIP (real research, but not corpus material):**
- One-off ops / config for a personal or single-machine setup (my Jellyfin library layout,
  my Radarr quality profiles, a specific proxmox error on my box). Reusable *only* to me,
  *only* now — belongs in a runbook or scratch note, not the shared corpus.
- Debugging a specific incident whose answer is the fix, not a transferable finding.
- Anything already covered by an existing INDEX.md entry (link/update it instead).

**The one-line test:** *Would a different engineer, on a different task next month, be glad
this was written down instead of re-searched?* Yes → keep. "Only useful to me, only right
now" → skip. When genuinely unsure, keep it as `status: draft` — a thin draft is cheaper
than losing the finding.

## The one rule that makes this work

A corpus that gets written but never read is wasted tokens. So:

- **Before web-researching a technical topic, check `INDEX.md` first.** If a relevant
  entry exists, read it instead of (or before) going to the web.
- **After researching, capture it** as a new entry and add one line to `INDEX.md`.

This is a standing procedure, not a judgment call — the prior art (Cline Memory Bank,
Aider conventions, Anthropic CLAUDE.md, Letta core memory) is unanimous that always-on
"check first" instructions are the only reliable defense against write-only rot. See
`agentic-context-design/agents-retrieve-knowledge-via-always-on-instruction-not-model-judgment.md`.

## Layout

```
ai/research/
  README.md      ← this file (the convention)
  INDEX.md       ← one line per entry, newest first. The thing agents read first.
  _template.md   ← copy this to start a new entry
  <topic>/<claim-as-filename>.md
```

- **`<topic>/`** — a broad area (e.g. `agentic-context-design`, `feedback-systems`).
  Matches the entry's `topic:` frontmatter. Create a new one when nothing fits.
- **`<claim-as-filename>.md`** — the filename IS the finding, as a kebab-case
  declarative claim, NOT a topic label. `grep-beats-embeddings-for-small-structured-corpora.md`,
  not `search-notes.md`. This makes filenames greppable and the index scannable.

## Entry format — facts separated from interpretation

Every entry has three sections, in this order. The separation is the point: a reader
(human or agent) can consume `## CLAIMS` + `## SOURCES` alone and ignore the agent's
opinion in `## SYNTHESIS` entirely.

- **`## CLAIMS`** — only verifiable statements, one per bullet, each tagged with a
  `[source-slug]`. No narrative, no hedging, no conclusions. This is the fact layer.
- **`## SOURCES`** — one entry per slug: full URL + access date + (optional) a verbatim
  quote that grounds the claim. This is what keeps a claim re-checkable after the
  source changes or dies. Minimum to be trustworthy: URL + accessed date.
- **`## SYNTHESIS`** — the agent's interpretation, conclusions, recommendations.
  Skippable by design. No inline citations here — that's what CLAIMS is for. This
  section can be rewritten without touching the facts.

Why sections, not separate files: at this scale (dozens of files) two files per entry
is friction with no payoff. FTS5/grep can target a single section by header. The
zettelkasten literature-note/permanent-note split is honored *within* the file.

## Frontmatter — 6 fields, all of them earn their place

```yaml
title: "Full declarative sentence stating the finding"  # the claim, not a topic
date: YYYY-MM-DD          # when the research was done (staleness signal)
topic: agentic-context-design   # = the subdirectory
tags: [retrieval, grep, embeddings]   # 2-6 free-form retrieval keywords
status: draft             # draft | settled | superseded
sources: [slug-1, slug-2] # cross-links to the SOURCES section
```

`status`: `draft` = agent-written, not re-verified. `settled` = cross-confirmed or
human-checked. `superseded` = contradicted by newer research; keep the file (provenance)
and point to what replaced it.

## Deliberately NOT here (would be over-engineering)

No embeddings / vector DB, no graph DB, no generated index, no per-source files, no
external memory engine (Mem0/Letta/Zep/Basic Memory). For a small structured markdown
corpus, grep + FTS5 + an always-on instruction beats all of it — this is the empirical
finding, not a shortcut. `context-mode`'s FTS5 is a *supplement* for recall of terms
not in filenames; it is not a dependency. Revisit only past ~100 entries.
