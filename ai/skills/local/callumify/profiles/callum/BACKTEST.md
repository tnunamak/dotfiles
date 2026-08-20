# Backtest — blind prediction of 8 held-out cleanups (2026-08-19)

Task: given a mess commit + repo state at the parent of Callum's cleanup,
predict his cleanup blind (sonnet predictors), judged against his actual diff
(separate sonnet judges). Packets + verdicts: `~/.tmp/callumify-0818/backtest/`.

## Scoreboard

| item | commit | actual work | dir | ops | score/5 |
|------|--------|-------------|-----|-----|---------|
| 0 | odl-website 08c12616f | semantic token normalization | ✗ | none | 0.5 |
| 1 | odl-website 4366d1ca5 | copy/CTA polish | ✗ | partial | 2 |
| 2 | unity-surfaces 36dc877ea | mechanical rebrand rename | ✗ | none | 1 |
| 3 | vana-app b475165ba | narrow surgical bug fix | ✗ | none | 1 |
| 4 | unity-surfaces 22826df2d | user-facing copy pass | ✗ | none | 1 |
| 5 | vana-app 1bed890d5 | (harness bug: predates mess) | ✗ | none | 1 |
| 6 | vana-connect 4df5c81fd | extract handoff-contract.ts | ✓ | partial | 2 |
| 7 | vana-connect 86a63918c | swap bespoke JSX for existing shared components | ✗ | none | 0.5 |

**Mean 1.12/5, direction 1/8.**

## The three-layer read (do not collapse these)

**Layer 1 — harness defects (fix before re-running):**
- item5: pair.py uses date-only granularity with `delta >= 0`, so a same-day
  scaffold commit that *predates* the mess passed as its "cleanup". v2 must
  order by committer timestamp and verify `--- /dev/null` shape.
- items 2/3/4: the lexical cleanup filter (refactor|rename|token|…) admits
  rebrands, copy passes, and plain bug fixes. The test set needs genre labels.
- item1: the predictor invented file paths not in the tree. Prompt must ban
  naming any path unverified against tree.txt.

**Layer 2 — real profile gaps (folded into PROFILE.md):**
- The profile encodes ONE genre (composition) because it was built during a
  composition engagement. His actual cleanup work spans at least five genres —
  see PROFILE.md "Cleanup genres". Genre selection was the dominant miss.
- Reuse-before-extraction: item7's cleanup replaced bespoke JSX with shared
  components that ALREADY EXISTED. Predictors invented new modules instead of
  checking the existing library first.
- Extraction scope: item6's real module absorbed the call sites' behavior
  *differences* (OAuth edge case, URL construction), not just the duplicated
  lines.
- He does not always generalize: item3's fix was deliberately narrow
  (window.location.href at two call sites) where the profile predicted a DRY
  extraction. Narrow-when-the-defect-is-narrow is part of his method.

**Layer 3 — what the score does and does not mean:**
The backtest task (predict a specific person's next commit, blind, genre
included) is strictly harder than what the skill does in production, where
Phase 1 measures the actual target and the owner has already named the genre
("the site needs a consistent approach"). The one genuine composition case
(item6) scored highest with direction + module match — the composition method
transfers. What does NOT transfer yet is knowing *which* cleanup he'd reach
for unprompted. n=8, noisy test set: treat the number as a floor and a gap
map, not a verdict.

## Genre-classifier experiment (2026-08-19, second run)

245/254 cleanup diffs genre-labeled (haiku), fingerprint rules distilled from
182 train items (sonnet, → GENRE-FINGERPRINTS.md), tested on 63 leak-free
holdout items (mess-side evidence only). Raw data:
`~/.tmp/callumify-0818/genre/results.json`.

**Result: 17/63 exact (27%), 28/63 compatible (44%) — BELOW the
always-predict-composition baseline of 23/63 (37%).** The decision procedure
over-fired config-chore/mixed. Negative result, informative cause: the
distiller's own analysis shows composition/narrow-fix/reuse-swap (63% of his
work) carry no mess-side signal — they are decided by repo state (defect
narrowness, whether a shared component already exists). What DOES work:
no-antecedent → scaffold (17× lift), ≥8 files → mixed/config-chore (7×),
small+CSS → token-normalization (5×; 4/7 on holdout).

Conclusion folded into the skill: genre selection is a Phase 2 repo-open
judgment, screened (not decided) by fingerprints. Do not spend more tokens
trying to classify genre from mess metadata; the ceiling is measured.

## Re-run

Fix Layer-1 items in the packet builder, then rerun the workflow script
(`callumify-backtest-*.js` under the session workflows dir) — cached agents
replay free if packets are unchanged.
