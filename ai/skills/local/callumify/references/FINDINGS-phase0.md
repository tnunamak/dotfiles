# Callumify — Phase 0 scouting result (2026-08-18)

Status: **scouting complete, strategy needs a decision before Phase 1.**
Cost so far: mechanical extraction only, no analysis-model tokens.

## The headline: he already wrote most of it down

`vana-com/unity-surfaces` carries a `.agents/skills/` tree of **339 files / 2.7 MB
across 74 skills**, and **116 of 120 commits to that path are Callum's**.

The ones that are directly the thing we planned to reverse-engineer:

| Skill | What it is |
|---|---|
| `codebase-design` (+ `DEEPENING.md`, `DESIGN-IT-TWICE.md`) | His explicit theory of deep modules, seams, leverage, locality — with an enforced glossary |
| `vercel-composition-patterns` | A per-rule directory (`rules/architecture-avoid-boolean-props.md`, `architecture-compound-components.md`, …) |
| `emil-design-eng` | Design-engineering lens |
| `react-build-lens`, `make-interfaces-feel-better`, `improve-codebase-architecture` | The cleanup lenses |
| `unity-design-extraction`, `unity-settings-grammar` | Design-system extraction |
| `writing-great-skills`, `write-a-skill` | How he thinks skills should be built |

This is **stated rules**, not inferred ones. It is strictly higher-signal per token
than diff archaeology, and it was going to be our Phase 2 output.

### What this does NOT give us

His skills say what he believes. They do not say **what he actually does to our
messes** — the gap between stated rule and applied judgment is exactly what we
wanted to learn, and it only lives in the diffs. Also unknown: which rules he
applies universally vs. contextually, and which he has silently abandoned.

So the diffs are still needed, but their job changes: from *generating* a theory
to *testing and completing* one that already exists.

## Corpus captured (durable, do not re-fetch)

| Artifact | Size | Notes |
|---|---|---|
| `raw/commits/*.jsonl` | 5,325 commits, 11 repos | every commit, all authors: sha/author/date/subject/files |
| `raw/diffs/*.diff` | 254 files, 12 MB | full diff text of every Callum cleanup commit |
| `raw/artifacts/` | 593 files, 4.9 MB | `.agents`, `.claude`, AGENTS.md, DESIGN.md from 5 repos |
| `pairs/pairs.jsonl` | 10,546 | all co-edit pairs (21-day window) |
| `pairs/cleanup-pairs.jsonl` | 254 | filtered to cleanup-signal subjects |
| `clones/*.git` | 11 bare repos | blob:none; re-fetch is cheap but unnecessary |

Volume by repo (callum / other commits):
unity-surfaces 956/1436 · vana-app 425/487 · odl-website 246/134 ·
vana-connect 203/664 · vana-cli 103/252 · team-chom 42/18

## Known weaknesses in the pairing

1. **Co-edit ≠ cleanup.** Sharing a file within 21 days is weak evidence. The
   subject-keyword filter (refactor|polish|align|token|…) cuts 10,546 → 254 but
   is a lexical proxy for intent.
2. **Merge/revert noise.** "Revert 'Merge main into dev (auto-sync)'" appears as a
   frequent `their_commit`; it is a bot-ish artifact, not an engineer's mess.
3. **Squash-merge collapses authorship.** Where PRs squash-merge, the "engineer
   shipped / Callum cleaned" boundary can vanish into one commit.
4. **No PR-review data yet.** His review COMMENTS may be higher-signal than his
   commits and are not captured.

## The strategy question

Original plan: fan out cheap agents over diffs → infer rules → test.
Given the skills tree, the better shape is likely:

- **Read his stated rules first** (74 skills, but ~8 are the design/cleanup core).
- **Then use the 254 diffs as a TEST SET**: does the stated rule predict the
  actual change? Where it does not, that gap is the real finding — either an
  unstated rule, or a rule he has outgrown.
- **Then check PR review comments** for rules he states to people but never wrote down.

That inverts generate-then-test into test-then-complete, and it is much cheaper.
