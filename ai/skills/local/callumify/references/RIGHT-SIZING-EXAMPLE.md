# Right-sizing `apps/site` without Callum

**Branch:** `callumify/site-consistency-0818` (worktree `/home/tnunamak/.tmp/callumify-run1`), building on PR #165.
**Written:** 2026-08-18. All counts verified against the worktree, not inherited from prior reports.

---

## Honest magnitude, up front

**This is not a 9000-line job on the public surface. It is roughly 1,500–2,500 lines across 25–40 files
for everything that a visitor can see, plus an optional 4,000–5,500-line deletion/quarantine of internal
tooling that carries most of the raw line count and none of the risk.**

The odl-website analogue (`33a332f5d`, 9,342 lines / 187 files) is *not* a like-for-like template for the
volume here, and it is important to say why before planning to its size:

| | odl-website at 33a332f5d | pdpp `apps/site` today |
|---|---|---|
| Public marketing routes | 15 | **5** concept routes + `/specification` + 404 |
| Shared page shell | did not exist — created by the commit | **exists** (`PdppConceptShell` / `PdppConceptPage` / `PdppConceptSection`) |
| Type ladder | `text.tsx` existed, ad-hoc `@utility text-*` blocks | **exists**, 8 rungs, declared once in brand `@theme`, with a rung-enforcement test |
| Naming law in repo | **written by the commit** (`ui-component-naming.md`, `ui-route-and-component-composition-guide.md`, `260417-route-shell-map.md`) | **written already** (`docs/design-system/styling-in-apps.md` + `apps/site/AGENTS.md`) |
| Ownership enforcement | none | `scripts/site-surface-ownership.test.ts` pins CSS imports + shell per route |

Of the 9,342 lines in his commit, ~4,700 were *new skill/doc markdown* and font binaries. The actual
`src/` restructuring was on the order of 3,000–3,500 lines — and it was building the composition model
from nothing. **Here, the composition model already exists and is already applied to 4 of 5 concept
routes.** Sizing this job to 9,000 lines would mean inventing work.

The honest framing: **this is the last 15% of a migration that is ~85% done on the public surface, plus a
large quarantine decision about internal tooling that has never been in the migration at all.**

---

## 1. Diagnosis

Using his glossary — module / interface / implementation / depth / seam / adapter / leverage / locality.

### 1.1 What the previous agents got RIGHT (say so, with evidence)

Both prior scope-reductions were **correct**, and I can prove it:

- **Excluding `/design`, `/palette`, `/sandbox`, `reference-app.tsx` from the styling migration was right.**
  `src/app/design/layout.tsx:13` and `src/app/palette/layout.tsx:13` set `robots: "noindex, nofollow"`;
  `src/app/sandbox/layout.tsx:13` sets `robots: {follow:false,index:false}` for the whole subtree;
  `src/app/robots.ts:33-34` disallows `/design` and `/palette`. None is linked from `publicSiteNav`.
  These are not marketing surfaces.
- **The 92% inline-style figure holds.** 536 total `style={{`; 495 (92.4%) in `design/page.tsx` (321),
  `reference-app.tsx` (127), `palette/page.tsx` (46), `sandbox/**` (1). Of the 41 remaining, 13 are in
  `opengraph-image.tsx` + `apple-icon.tsx`, where Satori **requires** inline styles (it does not support
  CSS classes). Genuine marketing-route inline-style debt is **28 occurrences in 6 files**, and
  `reference-hero-proof.tsx` (14) + `hero.tsx` (6) are reachable only from `/design`. Real public
  exposure: **~8 occurrences.** This category is essentially closed. Do not open it.
- **The revert (`9336fba7f`) was correct on the evidence available to that agent, and its root-cause
  diagnosis was excellent.** It identified both real defects: `pdpp-display`/`pdpp-body-lg` hardcode
  `font-family: var(--font-sans)` (`packages/pdpp-brand/styles/typography.css:31-86`) while `Text`'s
  display/lede rungs set no family and therefore inherit the concept surface's
  `@apply … font-serif` default (`concept/components.css:65`); and `.pdpp-eyebrow` is shadowed. That is
  a correct, browser-verified finding, not timidity.

**Where the revert was wrong is the conclusion, not the analysis.** It called the fix "a design decision,
not a same-PR mechanical fix." But brand `Text` **already has a `family` axis**
(`packages/pdpp-brand-react/src/text-variants.ts:68-73`: `inherit | sans | mono | serif`) with **no
default**, so it inherits. The fix is `family="sans"` at the call site, or a default. That is a one-line
decision, not a ladder redesign. It stalled for want of *authority*, exactly as diagnosed.

### 1.2 The real defects

**D1 — One route opted out of the method entirely. This is the whole public-surface job.**

Conformance to `PdppConceptPage`/`PdppConceptSection`, counted:

| Route | `PdppConceptPage`/`Section` refs | Container | Type method |
|---|---|---|---|
| `/` | 3 | `max-w-page` | `Text` |
| `/self-host` | 12 | `max-w-page` | `Text` |
| `/participate` | 10 | `max-w-page` | `Text` |
| `/maintainers` | 10 | `max-w-page` | `Text` |
| **`/self-host/coverage`** | **0** | **`max-w-7xl`** (its own) | **14 legacy BEM type classes** |

`app/(concept)/self-host/coverage/page.tsx` (210 lines) imports no concept module, builds its own
container (`max-w-7xl px-4 py-10`), uses shadcn `buttonVariants` instead of the concept `button.tsx`, and
hand-writes `pdpp-eyebrow`/`pdpp-display`/`pdpp-body-lg`/`pdpp-title`/`pdpp-caption`. It is the single
non-conforming public page.

**Public-route legacy-BEM type usage, split:**

| | occurrences |
|---|---|
| `/self-host/coverage` | **14** |
| `components/docs/source-link.tsx` + `artifact-link.tsx` | 5 — **but both have zero importers outside `/design`** |
| every other public route/component | **0** |
| internal tooling (`design`, `sandbox`, `palette`, `dashboard`, `reference-app`, `hero`, `reference-hero-proof`) | **167** |

So the widely-quoted "~186 BEM sites vs 44 `Text` sites, the disciplined system is the smallest one" is
true **repo-wide and false for the public site**. On the public site it is 14 vs 44, all 14 on one page.
This is the most important correction in this document: **the marketing surface is already consistent;
one page is not, and the internal tooling never joined.**

**D2 — Two Tailwind entrypoints. This is the one genuine architectural defect, and it is measurable.**

`src/styles/site.css` (root, via `app/layout.tsx`) and `src/styles/surfaces/concept/index.css` (via
`(concept)/layout.tsx`, `not-found.tsx`, `specification/layout.tsx`) are **two independent Tailwind v4
builds**. Measured on the existing build output in `.next/static/css/`:

- `966ae1a0ccf137cb.css`: 515 unique selectors. `b6bd26f8f94e82e2.css`: 795.
- **435 selectors (84% of the smaller bundle) appear in both.**
- `.flex{display:flex}` is emitted **twice**, in both bundles.

That duplication is not merely bytes — it has already cost correctness, and the codebase documents it
itself at `src/styles/surfaces/specification.css:90-98`: the concept build's unconditional
`.flex{display:flex}` loads *after* Fumadocs' preset at equal specificity, silently defeating
`max-xl:hidden`, so `#nd-toc` never collapses below 1280px. The workaround is a hand-written
`@media (max-width: 1279.98px)` rule. **A duplicated utility silently beat a media-scoped utility.** That
is a seam defect: two adapters emitting the same interface into one cascade with no declared ordering.

Compounding it: **layer order is never declared.** There is no `@layer a, b, c;` statement anywhere in
`apps/site`. Ordering is implicit in Tailwind's own import. The only `@layer` the site declares is
`@layer base` at `concept/components.css:166`.

**D3 — `.pdpp-eyebrow` / `.pdpp-caption` shadowing: real, scoped, and half-fixed.**

`.pdpp-eyebrow` is defined in four files: `apps/site/src/styles/surfaces/concept/components.css:272`
(unlayered, 13px, `--pdpp-concept-ink-faint`), `packages/pdpp-brand/styles/typography.css:95` (inside
`@layer components`), `packages/pdpp-brand-react/src/components.css:5234`, and
`packages/operator-ui/src/components/status-badge.css`. **Unlayered CSS beats any layered rule regardless
of specificity**, so the site's copy silently wins wherever both load. Same for `.pdpp-caption`.

Two things temper this:

1. **It is route-scoped.** Concept CSS is imported by only three files (`(concept)/layout.tsx`,
   `not-found.tsx`, `specification/layout.tsx`). `/sandbox` and `/dashboard` never load it, so their
   `.pdpp-eyebrow` resolves to brand's — correctly.
2. **The codebase already found and fixed the identical trap once, deliberately.**
   `concept/components.css:150-166` wraps the bare `[data-surface="concept"] h2/h3` element selectors in
   `@layer base` with a written rationale: unlayered, they "silently overrode the whole `Text` ladder —
   a `<Text size="title" as="h2">` resolved 28px serif 600 from this block, not from the rung."

That comment is decisive for the verdict in §6: this is **not** a codebase that is naive about the
cascade. It is one that has already fought this exact bug, documented it, and left two classes unfinished.

**D4 — Shallow modules: BEM implementation split from the JSX that owns it.**

`command-tabs.tsx` is 232 lines of JSX whose entire visual implementation is ~300 lines of `.pdpp-cmd__*`
in `concept/components.css` (67 references). The module's **interface** is a React component; its
**implementation** is split across two files in two languages with no compiler link. Nothing prevents a
class rename from silently unbinding it — and `src/lib/use-copy-to-clipboard.ts`'s own header records
that this already happened once. Same shape, smaller: `.pdpp-channels`/`.pdpp-updates`/`.pdpp-impl-table`
(participate + self-host), `.pdpp-terminal` (terminal.tsx).

This is the residue the file's own header calls `REMAINING BEM` (`components.css:22-31`) — an explicit,
correct migration list. **The right method here is already written down; it just has not been finished.**

**D5 — Dead modules reachable only from `/design`.**

`components/hero.tsx` (162 lines, doc-comment claims "the PDPP canonical hero component" — it is not;
`front-door.tsx` is), `components/docs/source-link.tsx`, `components/docs/artifact-link.tsx`,
`components/docs/prose-page.tsx` + `prose-page.css` (119 lines — a *seventh* heading scale in `rem`,
serving exactly one demo tile at `design/page.tsx:3608`). `app/dashboard/components/shell.tsx`
(259 lines) has **no `page.tsx` anywhere under `app/dashboard/`** — an orphan route shell.
Dead className: `pdpp-docs-shell` (`specification/shell.tsx:18`) is defined in no CSS.

**D6 — Duplication that is flat markup, not architecture.**

~40 hand-written `<div className="pdpp-eyebrow text-muted-foreground">` and ~33
`rounded-xl border bg-…​ p-4` card wrappers, while `ui/card.tsx` re-exports a real `Card` nobody uses.
**But 17 of the eyebrows and 12 of the cards are in one internal file** (`sandbox-walkthrough.tsx`), and
essentially all the rest are internal too. On public routes this cluster barely exists.

### 1.3 What is NOT debt (do not touch)

- **`specification.css`'s 28 `!important` are legitimate.** All 28 are in that one file; every other CSS
  file in `apps/site/src` has zero. Every one targets a third-party selector — Fumadocs `#nd-page`,
  `#nd-sidebar`, `.prose :where(table)` (note: `:where()` is zero-specificity, so `!important` is doing
  all the work and is the *only* available tool), Shiki `figure.shiki`, Radix
  `[data-radix-scroll-area-viewport]`. This is integration debt against a vendored DOM, not a
  self-inflicted specificity war. **Verdict: not an excuse.** The brittleness worth noting is different:
  `#nd-sidebar > div.flex.flex-col.gap-3` couples to Fumadocs' internal Tailwind class strings.
- **The two rails are not duplicates.** `pdpp-concept/rail.tsx` (41 lines) is a sticky `<aside>` +
  in-page scroll-spy TOC. `specification/rail.tsx` (90 lines) is a Fumadocs *slot adapter* exporting
  `specRailSlots` overriding `sidebar.root`/`searchTrigger`. Different content models, zero overlapping
  logic — and they **already share leaves**: `specification/rail.tsx:17-18` imports
  `PdppRailFrontMatter` and `PdppRailSectionLabel` from `pdpp-concept/`. Likewise
  `specification/shell.tsx:18` **composes** `PdppConceptShell` rather than forking it. In his vocabulary:
  the seam is correctly placed and there are genuinely two adapters. **Leave both alone.**
- **`docs/design-system/styling-in-apps.md` is the right plan, not a rationalization.** It names the
  target ("off `pdpp-*` BEM → Tailwind + JSX composition"), names what stays BEM and why
  (specificity/cascade hooks), and orders the work correctly ("componentize before deleting the BEM, not
  after"). PR #165's `PdppRuledList` commit follows it exactly. Its one weakness is §"Specification ↔
  concept theme parity (TODO)", which is a wish-list without a decision.

---

## 2. The method

**Port the site to the method it already documents, and make the documentation enforceable rather than
aspirational.** There is no case for importing odl-website's `Shell/Layout/Page/Route/View/Section`
vocabulary wholesale: this site has 5 static marketing routes with no client orchestration, so `Route`
and `Presenter` would be empty layers — shallow modules by his own deletion test.

The method, stated as five laws:

1. **One Tailwind build.** Utilities are emitted once. Route-scoped *tokens* stay route-scoped;
   route-scoped *utility builds* are abolished. Layer order is declared explicitly, once.
2. **Token owns metrics · CVA owns voice · packaging never re-emits the rung.** Already written in
   `apps/site/AGENTS.md`; make it true for `family` too by giving the concept surface a resolved answer
   rather than an inherited one.
3. **Type on public routes goes through `Text`.** One method, not six. Where a rung does not exist for a
   design (`.pdpp-caption`'s 15px italic serif), **add the rung or change the design** — do not keep a
   parallel class.
4. **A widget's implementation lives with its interface.** BEM survives only where it is a genuine
   cascade hook against a DOM we do not own (`.pdpp-doc` prose scoping, `.pdpp-note` MDX asides,
   `.pdpp-cta*` beating `.pdpp-concept a`, Fumadocs bridges). Everything else becomes a component with
   Tailwind, then its BEM block is deleted **in the same commit**.
5. **Internal tooling is out of the design system, explicitly and in writing** — not by silent neglect.

Enforcement is what converts this from a style guide into a method. Extend
`scripts/site-surface-ownership.test.ts` (the existing, correct guard) with: no legacy type BEM in
`app/(concept)/**`; no second `@import "tailwindcss…"`; `@layer` order declared; no class defined in both
a surface stylesheet and a brand package.

---

## 3. Sequenced work plan

Slices are ordered so each is independently landable and reviewable, per his `atomic-commit-slicing`
skill (one purpose per commit, stage explicit paths, run the narrowest real oracle).

### Slice 0 — Build the oracle first *(blocking; no product change)*
**Changes:** a computed-style differ: boot the built site on two ports (base vs HEAD), walk
`/`, `/self-host`, `/self-host/coverage`, `/participate`, `/maintainers`, `/specification/spec-core`, 404
at 3 widths × light/dark, snapshot `getComputedStyle` for `font-family/size/weight/line-height/color/
letter-spacing/margin` on every text node, and diff. Playwright is available via the host MCP; there is
**no browser harness in the repo today** (`apps/site/scripts/` has none), which is precisely why the
revert had to be done by hand.
**Size:** ~250–400 lines, 1–2 new files under `apps/site/scripts/`.
**Breaks:** nothing.
**Proof:** run it against HEAD vs HEAD → zero diffs.
**Decision needed:** none. **Do this first — every later slice's proof depends on it.**

### Slice 1 — Collapse to one Tailwind build *(the architectural fix)*
**Changes:** stop `concept/index.css` from emitting a second utilities pass; move concept **tokens** to
load under the root build while keeping `[data-surface="concept"]` scoping; declare
`@layer theme, base, components, utilities;` explicitly once in `site.css`; delete the `#nd-toc`
`@media` workaround (`specification.css:90-104`) and verify the TOC now collapses **because the
duplication is gone**, not because it is forced.
**Size:** ~150–300 lines across 4–8 CSS files + 3 layouts.
**What could break:** the highest-risk slice. Concept tokens leaking into `/sandbox` (brand surface), or
brand tokens winning on concept. The `@reference "@pdpp/brand/styles.css"` in `concept/index.css:18`
exists precisely because it is a separate entrypoint and must be re-examined, not deleted blindly.
**Proof:** Slice 0 differ across **all** routes including `/sandbox/**` and `/design` (which must be
*unchanged*); assert `.flex{display:flex}` now appears once; assert shared-selector count drops from 435
toward 0; manually verify `#nd-toc` collapses at 1279px with the workaround removed.
**Decision needed:** **yes — Tim must accept that this is a real refactor with real risk**, and that its
payoff (correctness + ~80KB of duplicate CSS) is worth it. If he declines, keep two builds but *declare
layer order anyway* (~20 lines) and keep the `#nd-toc` workaround with a comment pointing at the cause.

### Slice 2 — Resolve the `family` question, then land the reverted migration
**Changes:** decide the concept surface's family default (§4, D-1), apply it, then re-land `680a87bc2`
with `family=` and `color="subtle"` corrections. Bring `/self-host/coverage` onto `PdppConceptPage` /
`PdppConceptSection` / concept `button.tsx`, dropping its private `max-w-7xl` container. Add the
`.pdpp-caption` rung decision (§4, D-2).
**Size:** ~200–350 lines, 3–6 files (`coverage/page.tsx` 210 lines is most of it; possibly
`brand-react/text-variants.ts` or `concept/tokens/semantic.css` for the default).
**What could break:** the exact two regressions the revert caught — serif/sans swap on `<h1>` and lede,
and eyebrow size/shade. Also container width: `max-w-7xl` (1280px) vs `max-w-page` (1280px) happen to
match, but padding and the `:has([data-slot=pdpp-concept-rail])` figure cap do not.
**Proof:** Slice 0 differ on `/self-host/coverage`. Every remaining diff must be a line item on the
disclosed-change list, not a surprise.
**Decision needed:** **yes, two** — D-1 and D-2 below. This slice cannot start without them.

### Slice 3 — Deepen `command-tabs` (and the small widgets) into their own modules
**Changes:** move `.pdpp-cmd__*` (~300 CSS lines, 67 refs) into `command-tabs.tsx` as Tailwind, delete
the CSS block in the same commit. Then the same for `.pdpp-channels` / `.pdpp-updates` /
`.pdpp-ruled-list--plain` (participate) and `.pdpp-impl-table` (self-host + footer) — each becomes a
concept component, following the `PdppRuledList` precedent already in PR #165. Keep `.pdpp-terminal`
(shared with `/specification` via Shiki metric mirroring) and `.pdpp-doc` / `.pdpp-note` / `.pdpp-cta*`
(genuine cascade hooks).
**Size:** ~600–900 lines net across ~8 files; `components.css` should fall from 972 to ~450–550.
**What could break:** `.pdpp-cmd__*` has interactive state (`aria-selected`, `aria-pressed`,
`.is-shown`), responsive breakpoints, and `:focus-visible` rings. Tailwind translation of
`aria-`/`data-` variants is where regressions hide.
**Proof:** Slice 0 differ on `/self-host` and `/participate` **plus interaction states** — the differ must
be extended to click each tab and re-snapshot. `.pdpp-cmd` must have zero CSS *and* zero TSX references
when done.
**Decision needed:** none — this is the documented plan. **Highest-value slice for "smoothness" per unit
of risk.**

### Slice 4 — Delete the dead surface
**Changes:** delete `components/hero.tsx`, `docs/source-link.tsx`, `docs/artifact-link.tsx`,
`docs/prose-page.tsx` + `prose-page.css` (119 lines, the seventh heading scale), and
`app/dashboard/components/shell.tsx` (259 lines, orphan). All are reachable only from `/design` (or
nothing). Remove the corresponding `/design` tiles. Remove the dead `pdpp-docs-shell` className.
**Size:** ~700–900 deletions across ~8 files, plus `design/page.tsx` edits.
**What could break:** almost nothing public. `/design` loses tiles.
**Proof:** `pnpm types:check`; Slice 0 differ shows zero change on all public routes.
**Decision needed:** **yes — D-4.** `/design` is Tim's own reference surface; deleting tiles is his call.

### Slice 5 — Quarantine internal tooling, in writing
**Changes:** do **not** restyle `/design` (4,572 lines), `/palette`, `/sandbox`, `reference-app.tsx`.
Instead write the boundary into `docs/design-system/styling-in-apps.md` and `apps/site/AGENTS.md`: these
are `noindex` internal instruments, exempt from the concept method, permitted to use brand BEM +
inline styles. Then extend `site-surface-ownership.test.ts` with the §2 enforcement assertions so the
boundary is checked, not just stated.
**Size:** ~150–250 lines (docs + test).
**What could break:** nothing.
**Proof:** the new assertions fail on a deliberately introduced violation.
**Decision needed:** **yes — D-5.** This is the "agree on method" half of Callum's sentence, and it is
the slice most likely to be skipped and most likely to determine whether round N+1 creates more debt.

### Slice 6 (optional, only if D-3 says yes) — `/specification` prose onto concept rungs
**Changes:** the `styling-in-apps.md` §"parity (TODO)" table — replace `specification.css`'s ~30
hardcoded `font-size` declarations with concept rungs; share one code-block treatment between
`.pdpp-terminal` and `figure.shiki`.
**Size:** ~300–500 lines in `specification.css` (943 lines today).
**What could break:** every spec page's reading rhythm; Fumadocs upgrades.
**Proof:** Slice 0 differ across ≥6 spec pages including tables, code blocks, asides.
**Decision needed:** **yes — D-3.** This is a visible typographic redesign of the docs, not a cleanup.

### Totals

| | files | lines |
|---|---|---|
| Slices 0–5 (recommended) | ~30–40 | **~2,000–3,000** |
| + Slice 6 (optional) | +2–4 | +300–500 |
| of which pure deletion | ~10 | ~1,200–1,500 |

---

## 4. Explicit decision list — Tim's, not an agent's

**D-1 · The concept surface's font-family default.** `[data-surface="concept"]` applies `font-serif`
(`components.css:65`). Brand `Text` has a `family` axis with **no default**, so every `Text` on concept
inherits serif unless told otherwise — while the legacy classes it replaces hardcode `font-sans`. Pick
one:
 (a) set `family="sans"` per call site — explicit, verbose, no blast radius;
 (b) give the concept `Text` facade a sans default — concise, but silently changes any current concept
 `Text` that is *deliberately* serif;
 (c) change the surface default off serif — largest visible change, arguably the most honest.
*This one decision blocks Slice 2 and is the direct cause of the revert.* **Recommend (a) now, (b) or (c)
as a separate, deliberate design pass.**

**D-2 · `.pdpp-caption` has no rung.** On concept it resolves to 15px italic serif; the nearest rungs are
`small` (14px sans) and `body` (15px/1.6 sans). Options: add a ninth rung; accept a visible change to
`small`; or keep the class as a documented exception. **An agent must not pick this silently** — it is a
visible change to 7 call sites on the coverage page.

**D-3 · Does `/specification` adopt concept prose rungs?** (Slice 6.) The repo's own doc says it
"should"; nobody has decided. This is a visible redesign of every spec page.

**D-4 · Can `/design` lose tiles?** Slice 4 deletes 4–6 modules reachable only from it.

**D-5 · Is internal tooling permanently exempt, or is this a deferral?** Determines whether Slice 5 writes
"exempt" or "not yet migrated — see backlog." Affects every future round.

**D-6 · Is Slice 1 (one Tailwind build) in scope?** It is the only genuine architectural fix and the only
slice with broad regression risk. Declining is defensible; doing it half-way is not.

**D-7 · Accepted visible changes must be listed before merge.** Per the brief's own standard: "the h1
changed from serif to sans because the ladder was wrong" is legitimate **if decided and disclosed**. The
PR description must carry an explicit before/after list of every intentional visual change.

---

## 5. Risk register

| # | Risk | Why it bites | Mitigation |
|---|---|---|---|
| R1 | **Unlayered CSS beats layered CSS regardless of specificity** | Killed the last attempt. `.pdpp-eyebrow` in `concept/components.css:272` is unlayered; brand's is in `@layer components`. Reading both files makes them look 1:1 — they are not. | Never reason about the cascade from source. Slice 0's computed-style differ is mandatory *before* touching any type class. |
| R2 | **Duplicate utility emission silently beats media-scoped utilities** | `.flex{display:flex}` in both bundles defeated `max-xl:hidden` — a *correct* Tailwind class lost to a duplicate of itself. Documented at `specification.css:90-98`. Any two-build change can reintroduce this anywhere. | Slice 1. Until then, assert the shared-selector count (435) as a regression baseline. |
| R3 | **`Text` inherits font-family** | Not visible in the variant table; only visible in a browser. Caused one of the two revert regressions. | D-1 before Slice 2; differ must assert `font-family` explicitly. |
| R4 | **Dead-CSS sweeps will delete live rules** | `.pdpp-note` has **zero** TSX/MDX references — it is injected at runtime by `src/lib/remark-legacy-heading-ids.ts` / `remark-note-asides.ts:69`. A naive "unused class" pass breaks every MDX aside. | Never delete a class on grep evidence alone. Check remark/rehype plugins and Fumadocs-generated DOM. |
| R5 | **`!important` removal in `specification.css`** | All 28 fight third-party CSS; several depend on Fumadocs' internal Tailwind class strings (`#nd-sidebar > div.flex.flex-col.gap-3`). Removing them looks like cleanup and is a regression. | Out of scope. Treat as vendored-integration debt. Only revisit on a Fumadocs upgrade. |
| R6 | **`/specification` shares the concept stylesheet** | `specification/layout.tsx:6` imports `concept/index.css`. Any concept CSS edit hits the docs too — a fact easy to forget because the file is named "concept". | Every concept CSS slice must diff a spec page as well. |
| R7 | **The repo's tests protect the wrong things** | 2,050 of 3,630 test lines guard `/sandbox` mock data. **Zero tests render any public marketing page.** | Slice 0 *is* the missing net. Do not start slices 1–3 without it. |
| R8 | **Agent momentum: "finish the category"** | Prior instructions to "finish a category or don't open it" pushed toward sweeping all 186 BEM sites. 167 are internal and out of scope. Category-completionism here manufactures risk. | Scope is per-slice and route-scoped, never per-class-name. |

---

## 6. Honest verdict

**Can an agent fleet do this to a standard Callum would accept? For slices 0, 2, 3, 4, 5 — yes, with
high confidence. For slice 1 — yes but with real risk. For slice 6 — no.**

The reason is more favourable than the brief assumes. This codebase is **not** the just-in-time mess the
framing implies. It already has: a written method (`styling-in-apps.md`, `AGENTS.md`), a shell/section
composition model applied to 4 of 5 public routes, an 8-rung ladder declared once in `@theme` with a
rung-enforcement test, an ownership test pinning CSS imports per route, a migration list in
`components.css`'s own header naming exactly which BEM blocks remain and in what order, and — decisively
— **a prior fix for the exact cascade-shadowing bug**, with a written rationale
(`components.css:150-166`), plus a written diagnosis of the duplicate-utility bug
(`specification.css:90-98`). Those comments are the work of someone who already found what the previous
agents found. Callum's "agree on method and consistently apply it" is right, but the method is largely
agreed; **what is missing is enforcement and the last 15% of application.**

**Where a fleet falls short of him, specifically:**

1. **Deciding what the site should look like.** D-1, D-2, D-3 are typographic taste, not derivation. An
   agent can enumerate options and their blast radius; it cannot decide that the concept surface should
   read serif, or that a 15px italic serif caption deserves a ninth rung. Callum would decide these in
   minutes from taste. **This is the human-designer core of the job, and it is small but blocking.**
2. **Knowing which inconsistencies are invisible.** Six typography systems is a bad number; it is not
   automatically a bad *page*. A designer looks at a rendered page and says "this eyebrow is wrong" — an
   agent can only say "this eyebrow uses a different method." The correlation is imperfect, and
   optimizing the metric instead of the page is exactly the failure his own guidance warns about.
3. **`/specification` (Slice 6).** Aligning Fumadocs prose to concept rungs means choosing reading
   rhythm, table treatment, and code-block colour against a DOM we don't own. That is design work with a
   third-party constraint. **Leave to a human.**
4. **Knowing when to stop.** He would likely delete more than a fleet dares (`prose-page.css`,
   `/design` tiles, `hero.tsx`) and refactor less (the rails, `specification.css`'s `!important`). A
   fleet's bias runs the other way.

**What I would leave to a human:** D-1 through D-7 (roughly one hour of decisions with a rendered page in
front of him), Slice 6 entirely, and final visual sign-off on Slices 2 and 3 at three widths in both
themes.

**What I am not certain of:** (a) whether Slice 1 can be done without any concept-token leakage into
`/sandbox` — I have measured the duplication (435 shared selectors, `.flex` twice) but have not
prototyped the merge, so my confidence there is moderate, not high; (b) whether `.pdpp-cmd__*`'s
interactive states translate to Tailwind without a visible focus/selected-state regression — likely, but
the current CSS has hand-tuned `:focus-visible` rings I have read but not rendered; (c) the exact line
counts in §3, which are estimates from file sizes and reference-commit ratios, not from a prototype.

**The single highest-value thing to do first, if only one slice is done:** Slice 0. The previous attempt
failed not from lack of skill but because it had no cheap way to see the truth, so it reverted correct
work. A computed-style differ converts every remaining decision from an argument into a measurement —
and it is the artifact this repo is missing that Callum's own workflow (`web-browser-qa`,
`surface-captures`, "prove done with the narrowest real oracle") assumes exists.
