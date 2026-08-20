# Genre fingerprints (mess-side only)

Built 2026-08-19 from 182 labeled train items (188 train rows in manifest.json,
6 unlabeled — excluded) in `~/.tmp/callumify-0818/genre/manifest.json`. Rules
use ONLY mess-side observables (`their_subject`, `their_author`,
`their_files` — path/extension/count) as an agent would see them from a
messy diff + file tree, never genre-adjacent hindsight from the cleanup side.

## (a) Base rates (train, n=182)

| genre | n | % |
|---|---|---|
| composition | 71 | 39.0% |
| narrow-fix | 29 | 15.9% |
| copy-continuation | 15 | 8.2% |
| config-chore | 14 | 7.7% |
| reuse-swap | 14 | 7.7% |
| token-normalization | 12 | 6.6% |
| rename-finishing | 12 | 6.6% |
| mixed | 9 | 4.9% |
| scaffold-creation | 5 | 2.7% |
| docs-content | 1 | 0.5% |

**Contamination:** 11/182 (6.0%) are `is_cleanup_of_prior_work: false` — not a
cleanup of someone else's mess, but Callum's own greenfield work swept into
the corpus (scaffold-creation 5, composition 3, mixed 2, config-chore 1).
~1 in 17 flagged items may have no antecedent mess at all — check for
`/dev/null` origin before assuming any cleanup genre applies.

## (b) Fingerprint rules, ordered by reliability

1. **IF `their_files` has ≥8 entries THEN `mixed` or `config-chore`** (5/6 =
   83% vs 12.6% combined base — ~6.6x lift; support: 6, e.g.
   `odl-website__52f606ca9`, `odl-website__64d972a5d`,
   `unity-surfaces__511e51b14`). Wide messy commits rarely resolve to one
   clean genre.
2. **IF any file is `.css` AND total files ≤3 THEN `token-normalization`**
   (5/14 = 36% vs 6.6% base — ~5.5x lift; support: 14 firing, 5 correct,
   e.g. `odl-website__1026a5b51`, `odl-website__16de48f0f`,
   `odl-website__1ad8ee9ec`). Misses land in `config-chore`/`narrow-fix`,
   never composition/reuse-swap/rename.
3. **IF any file matches `package.json`, `pnpm-lock.yaml`, `*.yaml/.yml`,
   `tsconfig*`, `biome*`, `eslint*`, `.nvmrc`, `Cargo.{toml,lock}`, `*.md`,
   `*.mjs`, `/hooks/`, or `docs/checks/` THEN `config-chore`** (11/33 = 33%
   vs 7.7% base — ~4.3x lift; support: 33 firing, 11 correct, e.g.
   `odl-website__44f05444e`, `unity-surfaces__2ece37320`,
   `unity-surfaces__ae278716a`). Best recall for config-chore (79% of all
   config-chore items fire it).
4. **IF `their_subject` starts with `Revert "Merge main into dev` THEN
   `config-chore` or `mixed`** (6/10 = 60% vs 12.6% combined — ~4.8x lift;
   support: 10, e.g. `unity-surfaces__209747dbb`,
   `unity-surfaces__2ece37320`, `unity-surfaces__31bed50f3`). Same
   mechanism as rule 1, caught via subject when the file list is truncated.
5. **IF any file path contains `/content/` or ends `.mdx` THEN
   `copy-continuation`** (1/1; support: 1, `odl-website__1cdfac97d`). Only
   one example — directionally right, too thin to trust alone.
6. **IF the file has NO antecedent commit (`git log --follow` on the path
   before `their_sha` returns nothing) THEN `scaffold-creation`** (5/11 =
   45% vs 2.7% base — ~17x lift; support: 11 firing, 5 correct, e.g.
   `odl-data-connect__786a12296`, `unity-surfaces__7cfb2594e`,
   `unity-surfaces__ab2fd59f0`). Strongest single lift, but needs a git
   history check, not just the file tree.
7. **IF the mess touches exactly one non-test `.tsx`/`.ts` file (no CSS, no
   config, no `.mdx`) THEN `composition` or `narrow-fix`** (60/90 = 67%
   combined vs 54.9% combined base — mild ~1.2x lift; support: 90 firing).
   Modal case (49% of train). The two genres are not separable from
   mess-side evidence alone — see limits.

## (c) Decision procedure

Check in order; stop at first match:

1. Confirm the file pre-exists (`git log --follow -- <path>` before the
   messy sha). If not → **scaffold-creation** (rule 6); flag possible
   `is_cleanup_of_prior_work: false`.
2. Count `their_files`. If ≥8 → **mixed or config-chore** (rule 1); pick
   `config-chore` if every file matches the glob in step 4, else `mixed`.
3. If `their_subject` matches an auto-sync/merge-revert phrasing → **mixed
   or config-chore** (rule 4); same tie-break.
4. If any file matches the config/docs/infra glob (rule 3) → **config-chore**.
5. If any file is `.css` and total files ≤3 → **token-normalization**
   (rule 2); on miss, treat as narrow-fix/config-chore candidate.
6. If any file path has `/content/` or is `.mdx` → **copy-continuation**
   (rule 5, corroborate — thin evidence).
7. **Default: composition** (plurality class, 39%). Demote to **narrow-fix**
   only on judgment (subject verbs like "fix"/"align"/"tighten" plus your
   own read that the eventual patch will be a 1-2-line/2-call-site fix, not
   an extraction) — Callum's fix is deliberately narrow when the defect is
   narrow (see PROFILE.md).

## (d) Honest limits

- **composition vs narrow-fix** (55% of corpus combined): identical mess
  shape (single-file TSX, same subject verbs). Genre depends on how deep
  the defect turns out to be once the cleanup exists — not mess-observable.
  Rule 7 caps at 67% combined precision, can't split the pair.
- **reuse-swap vs composition**: both delete bespoke code; whether the
  replacement already exists in-repo (reuse-swap) or gets built fresh
  (composition) needs the shared-component inventory, not in the mess
  diff. No tested signal (subject/path keywords, test-pairing) beat ~1.3x.
- **rename-finishing vs copy-continuation**: both are mechanical wide
  substitutions; separating "identifier/route/env rename" from "user-facing
  prose rewrite" needs the actual string, not the file list. The same
  messy subject line recurs across both genres in this corpus.
- **mixed** is a residual bucket by construction; only file-count/subject-
  vagueness (rules 1/4) predict it, expect false negatives vs composition
  and config-chore.
- **docs-content** has 1 train example — no rule reaches usable precision.
- `their_files` is sometimes only the ONE file Callum's cleanup touched, not
  the full messy commit's file list — the same subject line (e.g. "Oshin
  feedback pass") recurs across 8+ genre labels here. Don't trust the
  subject alone except for the merge-revert case (rule 4).
