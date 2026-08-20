---
name: callumify
description: Clean up an app the way the org's reference design engineer (default Callum) would — composition, taxonomy, type-system unification, dead-flag removal — delivered as one PR he'd approve without spending his own 1-2 weeks. Use when the user says "callumify this", "clean this up like Callum would", "make this pass Callum's bar", or wants a reference-engineer-grade consistency pass on an app/site. Works from a cached engineer profile; do NOT just hand agents his skills and hope.
---

# Callumify

Emulate a specific engineer's cleanup of a specific codebase, well enough that
they review the PR and have nothing left to do. Built from a real engagement
(PDPP site, 2026-08-18) where three runs of "apply his skills" failed before a
calibrated pipeline succeeded.

## The core insight — read this before anything else

**Stated skills describe how to make decisions an agent is not allowed to make.**
Handing an agent the engineer's skills plus "preserve behaviour, prove every
pixel" caps output at tidying. Two things unlock real work:

1. **Ground truth** — the engineer's measured behaviour (commit-size
   distribution, one real archetype diff read in full, mechanically checkable
   rules), fetched from `profiles/<engineer>/PROFILE.md`, not re-derived.
2. **Authority** — an explicit grant to make visible changes, decide, and
   disclose. Without it, agents pick the safe non-answer every time.

Prefer, in order: **scripts (0 tokens) → cheap agents → smart agents.** The
maker is never the judge.

## Phases and agent routing

| # | Phase | Runs on | Claude tier | Codex tier |
|---|-------|---------|-------------|------------|
| 0 | Load profile | file read | orchestrator | orchestrator |
| 1 | Measure target gap | scripts + 1 cheap agent | haiku | gpt-5.6-luna |
| 2 | Plan (the one smart read) | 1 strong agent, fresh context | opus/fable | gpt-5.6-sol |
| 3 | Execute slices | mid agents, worktree | sonnet | gpt-5.6-terra |
| 4 | Verify | oracle script + judge ≠ maker | different model than maker | — |
| 5 | Calibrate | human review → ledger | orchestrator | orchestrator |

### Phase 0 — Load the profile (no tokens)

Read `profiles/<engineer>/PROFILE.md` (default: `profiles/callum/`). It holds
the size distribution, grep-able CRITICAL rules, archetype diff path, taxonomy,
and trap list. If no profile exists for the engineer, build one first with
`scripts/` (see "Building a profile" below) — never skip to Phase 2 without it.

### Phase 1 — Measure the target repo's gap (cheap)

Mechanical: run `scripts/gap-scan.sh <target-dir>` first — it reads the
profile's `rules.json` and emits a JSON report (CRITICAL-rule violations with
samples, taxonomy/wrapper-dir smells, blessed-vs-legacy conformance counts by
path). Known limits are documented in rules.json; a cheap agent only
interprets the report. Then:
- Violations found by the scan are guaranteed slices.
- Count conformance per route/surface (which pages use the blessed modules,
  which opted out). Split counts by **public vs internal** exposure — repo-wide
  numbers lie (PDPP: "186 BEM sites" repo-wide was 14 on the public site, all
  on one page).
- Compare repo structure to the profile's taxonomy. Note every mismatch.

### Phase 2 — The one smart read (never skip, never do cheap)

One strong agent, fresh context, given the profile + Phase 1 numbers. It must:
0. **Fingerprint the cleanup genre first.** Composition is only ~39% of the
   reference engineer's cleanup work (measured; see profile "Cleanup genres").
   Apply the profile's high-lift screens (GENRE-FINGERPRINTS.md) to rule
   peripheral genres in or out cheaply — but the core call (composition vs
   narrow-fix vs reuse-swap) is measured to be undecidable from mess metadata
   alone; decide it here, with the repo open, by checking defect narrowness
   and the existing shared-component inventory.
1. **Read the archetype diff in full** — not its stats. Sizing from a headline
   number without reading cost three failed runs.
2. Answer: **"Would this engineer even have this structure?"** Challenge every
   split/wrapper/duplication the plan is about to treat as given. Their repo
   layout answers questions their prose does not.
3. Produce a slice plan sized against the profile's distribution ("their median
   is X, p90 is Y — this job is Z because…"). Both "near median" and "small,
   with a measured reason" are legitimate; only the distribution tells you which.
4. Mark which slices are mechanical vs which need a real design decision.
   Slices needing the engineer's actual taste get **refused with evidence**,
   not forced. Refusals-with-measurements are a feature: they're what the
   engineer acts on in 5 minutes instead of 2 weeks.

### Phase 3 — Execute (mid-tier, one PR)

**Slice 0 is always the oracle**: a computed-style differ (or the target
stack's equivalent) that compares two running builds. Without it, "preserve
behaviour" degrades into "change nothing". Reference implementation:
`references/style-differ.mjs`.

Dispatch each slice with this frame (the exact correction that unlocked run 3):

> Depth per COMMIT. Breadth across the PR. Many commits, one PR.
> You MAY change the design system: add/remove type rungs, restructure CSS
> layers, delete classes, move files. A visible change is a legitimate outcome
> if you DECIDE and DISCLOSE it. Do not auto-revert correct work.
> Their median cleanup is {median} lines, p90 {p90}.
> Archetype for quality bar: {archetype path}.
> CRITICAL rules, verbatim: {rules}.
> Known traps: {trap list from profile}.
> If a slice proves wrong, say so with evidence rather than forcing it.

Check call sites before designing a variant — a flag with zero live callers is
a deletion, not a composition problem. Check the existing shared-component
library before extracting anything new — his cleanups reuse before they
create. Never name a file path you have not verified exists in the tree.

### Phase 4 — Verify independently

- Re-run the oracle **from outside the maker agent**, including a
  **baseline-vs-itself control** — a differ with no control cannot tell a
  regression from a flake.
- Real build gate (`next build`-grade), not just typecheck.
- One judge agent, **different model than the maker**, grades the branch
  against the profile. It hunts overclaiming specifically.
- PR body: use the `pr-writing` skill's grade-then-revise loop. The engineer
  should understand the PR in minutes, not an hour.
- Cleanup is part of the harvest: reap every lane and `git worktree remove`
  every worktree the engagement created, same turn as reading its output.

### Phase 5 — Calibrate (the only true oracle)

When the engineer actually reviews, append every delta — each thing they
changed, questioned, or praised — to `profiles/<engineer>/CALIBRATION.md`.
This ledger is the highest-signal data in the whole system and starts empty.
Fold repeated deltas back into PROFILE.md.

## Building a profile (once per engineer, cached forever)

All mechanical, scripts vendored in `scripts/`:
1. `extract.sh <repo>` per top repo — every commit + files (bare clone,
   blob:none).
2. `pair.py` — co-edit pairs; filter by cleanup-subject keywords.
3. `fetch-diffs.sh` — full diff text of every cleanup commit. Compute the size
   distribution from these.
4. `capture-reviews.sh <repo>` — their PR review comments: rules they tell
   people but never wrote down.
5. Find their **stated rules**: `.agents/`, `.claude/`, `.cursorrules`,
   `AGENTS.md`, `docs/design-system/`. Rules the author marks CRITICAL are
   gold — they're mechanically checkable.
6. One smart pass distills all of it into PROFILE.md. Diffs are the TEST SET
   for stated rules, not the theory generator — where a stated rule fails to
   predict the actual diff, that gap is the finding.

## Anti-patterns (each one cost us a run)

- Sizing to a diff you never opened.
- Letting the countable (CSS classes) crowd out the important (composition).
- Relaying an agent's scope reduction as fact without verifying it.
- Handing the owner "your call" instead of a verdict with measurements.
- "Preserve behaviour" without an oracle → agent reverts correct work it
  cannot cheaply check.
- `git push origin HEAD` on a local-named branch silently missing the PR —
  push `HEAD:<pr-branch>` explicitly.

Full engagement history: `references/RECIPE.md` (the 9-step recipe with
rationale), `references/FINDINGS-phase0.md` (corpus strategy),
`references/RIGHT-SIZING-EXAMPLE.md` (what a calibrated plan reads like).
