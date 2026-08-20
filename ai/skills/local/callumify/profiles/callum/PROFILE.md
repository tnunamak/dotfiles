# Profile: Callum Flack (callumflack, vana-com)

Built 2026-08-18 from 5,325 commits across 11 repos, 254 cleanup diffs read as
a corpus, and his 74-skill tree. Corpus (durable, do not re-fetch):
`~/.tmp/callumify-0818/` — rebuild with this skill's `scripts/` if lost.

## Size distribution (cleanup commits, n=254)

| median | p75 | p90 | max |
|--------|-----|-----|-----|
| 186 | 886 | 2,108 | 28,781 |

Judge every plan against this. Near-median is normal; small needs a measured
reason; sizing to the max invents work.

## CRITICAL rules — mechanically checkable (grep first, always)

From `unity-surfaces/.agents/skills/vercel-composition-patterns/rules/`:

| Rule | Grep |
|------|------|
| `architecture-avoid-boolean-props` (CRITICAL) | `\?: boolean` in component props |
| `react19-no-forwardref` | `forwardRef` |
| `patterns-explicit-variants` | bare JSX flags like `<X home>` |

On PDPP these found 2 real violations in minutes; three runs of "apply his
skills as judgment" found one clipboard hook. Prefer rules that fail loudly.

Addendum earned on PDPP: a flag with **zero live callers is a deletion**, not a
variant — his `patterns-explicit-variants` has no example for the
never-built-mode case, so agents over-design there.

## The archetype diff (quality bar — READ it, don't just cite it)

`odl-website` commit `33a332f5d` — 9,342 lines / 187 files. What it actually
is: **composition** — 104 of 187 files under `src/components/`, repeated markup
shapes lifted into named modules with typed interfaces (`sections/section-heading.tsx`,
`layout/page-shell.tsx`, `page-<route>/`). ~4,700 of its lines are skill
markdown + font binaries; the real restructuring is ~3,000–3,500 lines and it
built the composition model *from nothing*. A repo that already has the model
needs the last 15%, not a rewrite.

## The structural tell (his single most predictive habit)

`odl-website/src/components/mdx/mdx-components.tsx`: `createMdxComponents()`
maps EVERY MDX element back onto the site's one `Text` module
(`h1 → intent="display"`, `h2 → intent="subtitle"`). **Prose gets a different
SOURCE, never a different type system.** Any plan that treats a second type
system as "by construction" (third-party docs framework, etc.) is wrong until
proven otherwise — components maps exist for exactly this.

## Taxonomy

`src/components/` is **flat**: `elements/ · layout/ · sections/ · typography/ ·
mdx/ · page-<route>/`. No wrapper directories — a name like `pdpp-concept/`
is indicted by the layout itself. No stated file-count threshold: scaling his
104-file structure down needs judgment; single-purpose files don't get
one-file folders.

## Stated rules (the skills tree)

`vana-com/unity-surfaces` `.agents/skills/` — 74 skills, 339 files, 116/120
commits his. The design/cleanup core (~8 of 74):
`codebase-design` (+DEEPENING, DESIGN-IT-TWICE) · `vercel-composition-patterns` ·
`emil-design-eng` · `react-build-lens` · `make-interfaces-feel-better` ·
`improve-codebase-architecture` · `unity-design-extraction` ·
`unity-settings-grammar`. Local mirror: `~/.tmp/callumify-0818/callum-skills/`.

His glossary is enforced vocabulary — module / interface / implementation /
depth / seam / adapter / leverage / locality. Write commit messages and PR
bodies in it.

Known gap: his skills say what he believes, not what he does to other people's
messes. The 254 diffs are the test set. His PR review comments (rules he tells
people but never wrote down) were **never captured** — run
`scripts/capture-reviews.sh` to close this.

## Cleanup genres (backtest-earned, 2026-08-19)

Composition is only ONE of his cleanup genres. Observed across held-out
commits (see BACKTEST.md):

1. **Composition** — extract/deepen modules (the archetype; best understood).
2. **Token/semantic-naming normalization** — ad-hoc CSS vars and bespoke class
   names renamed onto canonical design-system tokens; zero new modules.
3. **Copy-pass continuation** — a word-level substitution spread outward to
   sibling surfaces still using the old term.
4. **Rebrand/rename finishing** — mechanical, wide, tiny per-file diffs across
   manifests/config/nav/CLI banners.
5. **Reuse-swap** — bespoke JSX (hand-rolled spinners, headers, forms)
   replaced with shared components that ALREADY EXIST in the repo.

**Fingerprint the genre from the mess diff before planning.** And he does not
always generalize: when the defect is narrow, his fix is deliberately narrow
(two-call-site surgical change over a DRY extraction). Predicting extraction
where he'd patch is a characteristic miss.

Measured base rates (245 labeled cleanups, train n=182): composition 39%,
narrow-fix 16%, copy-continuation 8%, config-chore 8%, reuse-swap 8%,
token-normalization 7%, rename-finishing 7%, rest mixed/scaffold/docs.
Measured limit (holdout n=63): mess-side metadata alone predicts genre WORSE
than always guessing composition (27% vs 37%) — his three biggest genres are
not separable without repo-state inspection. Use `GENRE-FINGERPRINTS.md` only
for its high-lift screens (no-antecedent → scaffold 17×, ≥8 files →
mixed/config 7×, small+CSS → token-normalization 5×); leave
composition-vs-narrow-fix-vs-reuse-swap to the Phase 2 smart read with the
repo open.

Rules earned from the backtest:
- **Reuse before extraction.** Check the existing shared-component/hook
  library before proposing any new module.
- **Extractions absorb behavior differences**, not just duplicated lines — the
  real shared module owns the call sites' edge cases too.
- **Never name a file path unverified against the actual tree.**

Companion files: `REVIEW-VOICE.md` (rules he states in reviews/Slack + how he
phrases feedback — use it for PR bodies), `BACKTEST.md` (measured predictive
power and its limits).

## Trap list (carry into every dispatch)

- Unlayered CSS beats layered CSS regardless of specificity — two same-named
  classes in different files can look 1:1 in source and differ at runtime.
- Duplicate utility emission from two build entrypoints silently beats
  media-scoped utilities (a class losing to a duplicate of itself).
- Component libraries that don't set `font-family` inherit it from a surface
  wrapper — a "clean rung match" can swap the typeface invisibly.
- Same-named rungs can have unrelated metrics (PDPP: `.pdpp-title` 15px
  semibold vs `Text` rung `title` 23–27px). A name match proves nothing.
- `pnpm typecheck` is weaker than `next build`'s typecheck — the build is the
  real gate.
- Stale dev servers produce false blank-page diffs; verify the port rebound.

## Open human decisions from the PDPP engagement (do not force)

1. `/self-host/coverage` type migration — blocked on the `title` rung metric
   mismatch above; needs his call on the ladder.
2. Collapsing the dual Tailwind build (two entrypoints, 435 duplicated
   selectors, one real bug already) — architectural, one-way door.

## Calibration status

**No real Callum review captured yet** (checked 2026-08-19: PRs #165/#167 on
PDP-Connect/pdpp still unreviewed by him). His actual review of #167 will be
the first ground-truth entry in `CALIBRATION.md`. Until then, this profile is
inference from his history, verified only by agent judges.

Measured (2026-08-19): blind prediction of 8 held-out cleanups scored
1.12/5 mean, direction 1/8 — the composition method transfers (the one true
composition case scored highest, with module-name match); genre selection
does not transfer yet. Details and caveats: BACKTEST.md.
