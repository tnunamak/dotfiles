# Recipe: Callumify a codebase

How to hand an agent fleet a mess and get back something the org's design
engineer would accept. Derived from three failed-then-corrected runs on the PDPP
site, 2026-08-18. Every rule below exists because we broke it first.

## The core insight

**His skills describe how to make decisions an agent is not allowed to make.**
Handing an agent his skills while telling it to preserve behaviour and prove
every pixel caps it at tidying. The bottleneck is authority, not knowledge.

## Step 1 — Get the ground truth BEFORE dispatching anything

Do not infer what "clean this up" means. Measure what the person actually does.

```
gh api "search/commits?q=org:<ORG>+author:<HANDLE>" --jq .total_count
```

Then clone the top repos bare (`--filter=blob:none`, fast) and extract:
- every commit (all authors) with files touched → `raw/commits/<repo>.jsonl`
- their cleanup commits, filtered by subject keywords
  (`refactor|cleanup|polish|align|unify|consolidat|token|extract|simplif`)
- the **full diff text** of each → `raw/diffs/<repo>__<sha9>.diff`

**Size distribution is the single most useful artifact.** For Callum:
median 186 lines, p75 886, p90 2108, max 28781. Without this you cannot tell a
right-sized result from a timid one.

## Step 2 — READ their biggest analogous diff. Do not just measure it.

This is the step we skipped for three runs, and it cost the most.

We sized against his 9342-line marketing-site cleanup but never opened it. When
we finally did: **104 of 187 files were `src/components/`**, and the new modules
were `sections/section-heading.tsx`, `layout/page-shell.tsx`, `page-<route>/`.
His cleanup was COMPOSITION — repeated markup shapes lifted into named modules
with typed interfaces. Our agents had spent three runs on CSS class archaeology
because class counts are easy to count and composition quality is not.

Extract from the diff:
- the **taxonomy** they impose (`ls` the component dirs after their change)
- one **archetype module** to use as the quality bar
- what they DELETED (often more informative than what they added)

## Step 3 — Find their WRITTEN rules, then test the code against them

Check for `.agents/`, `.claude/`, `.cursorrules`, `AGENTS.md`, `docs/design-system/`.
Callum had 74 skills / 339 files in `unity-surfaces`, 116 of 120 commits his.

Rules marked CRITICAL by their author are the highest-value grep targets, because
they are **mechanically checkable**:

```
architecture-avoid-boolean-props (CRITICAL) → grep for `?: boolean` props
react19-no-forwardref                       → grep forwardRef
patterns-explicit-variants                  → grep bare JSX flags <X home>
```

On PDPP this found 2 real violations in minutes. Contrast: three runs of
"apply his skills" judgment produced one clipboard hook.

**Prefer rules that fail loudly over principles that require taste.**

## Step 4 — Dispatch with authority, not just knowledge

The instruction that produced trivial output:
> "depth over breadth, one provable slice" + "prove behaviour preservation"

The correction:
> **Depth per COMMIT. Breadth across the PR.** Many commits, one PR.
> You MAY change the design system: add/remove type rungs, restructure CSS
> layers, delete classes, move files. A visible change is a legitimate outcome
> if you DECIDE and DISCLOSE it. Do not auto-revert correct work.

Also required in the prompt:
- the size distribution from Step 1 ("their median is X; p90 is Y")
- the archetype from Step 2, by file path
- the CRITICAL rules from Step 3, quoted
- known traps, named (see Step 6)
- "if a slice proves wrong, say so with evidence rather than forcing it"

## Step 5 — Build the oracle FIRST

Slice 0 is always: a computed-style differ (bounding boxes + resolved
`font-family`/`font-size`/`color`/`display`/spacing) that runs against two
servers and diffs them.

Justification: our best agent reverted a CORRECT migration because it could see
the CSS text but not the computed result. It had no cheap way to check, so it
chose the safe wrong answer. In this repo, 2050 of 3630 test lines guarded mock
data and **zero tests rendered a public page**.

Without the oracle, "preserve behaviour" degrades into "change nothing."

## Step 6 — Trap list (carry these into every dispatch)

- **Unlayered CSS beats layered CSS** regardless of specificity. Two same-named
  classes in different files can look 1:1 in source and differ at runtime.
- **Duplicate utility emission from two build entrypoints** silently beats
  media-scoped utilities (a correct class losing to a duplicate of itself).
- **Component libraries that don't set `font-family`** inherit it from a surface
  wrapper, so a "clean rung match" can swap the typeface invisibly.
- **`pnpm typecheck` can be weaker than `next build`'s own typecheck.** The build
  is the real gate.
- **Stale dev servers** produce false blank-page diffs. Verify the port rebound.
- `git push origin HEAD` on a local-named branch creates a NEW remote branch and
  silently leaves the PR untouched. Push explicitly: `HEAD:<pr-branch>`.

## Step 7 — Judge the result against Step 1's distribution

Ask: does the diff sit near their median, or has the agent found a sophisticated
reason to be small? Both answers are legitimate; you can only tell with Step 1.

Note the inverse failure too: sizing against their MAX invents work. Their
9342-line commit CREATED a composition model across 15 routes; a repo that
already has one needs the last 15%, not a rewrite. Read the diff (Step 2) to
know which situation you are in.

## Step 8 — Verify the agent's proof yourself

Re-run the oracle from outside the agent. On the run that produced PR #165 the
agent reported "0 diffs"; the orchestrator's own run found 1 of 1,995 elements —
a colour reported `oklab(...)` vs `oklch(...)`. Re-running three times gave
1, 0, 0, and a **control of baseline against itself** reproduced it. So the
agent's claim was right and its method was sound, but only the independent
control proved it.

Always run baseline-vs-itself. A differ with no control cannot distinguish a
regression from a flake.

## What the recipe produced (first full pass)

PR #165: 9 commits, +597/−186 across 37 files — between Callum's median (186)
and p75 (886), on a codebase already 4/5 migrated. Contents:

- a committed computed-style differ (the missing oracle)
- both boolean-prop violations of his CRITICAL rule removed
- `pdpp-concept/` split into his taxonomy: `layout/` (5) · `sections/` (11) ·
  `elements/` (6), with type/data files at root
- two duplicated implementations deepened into shared modules

Two items correctly refused as human decisions: the coverage-page migration
(`.pdpp-title` is 15px semibold while the `Text` rung *named* `title` is 23-27px
— same name, unrelated metrics) and the dual Tailwind build.

**The refusals are the strongest evidence the recipe works.** Run 1 stopped early
from timidity. Run 3 stopped at exactly two places, both with measured reasons a
human can act on.

## Step 9 — Ask "would they even have this structure?"

The highest-leverage question of the whole engagement was the owner asking
"would he even have two UI surfaces?" — not a request to tidy something, but a
challenge to a premise every prior plan had treated as given.

PDPP had two type systems: a `Text` module on marketing routes, and raw-element
CSS on the fumadocs docs route. Every plan called that split "by construction"
because a third-party docs framework owned the route.

His code says otherwise. `odl-website/src/components/mdx/mdx-components.tsx`:
`createMdxComponents()` maps EVERY MDX element back onto the site's one `Text`
module (`h1 → intent="display"`, `h2 → intent="subtitle"`). Prose gets a
different SOURCE, never a different type system. Fumadocs accepts a components
map exactly like MDX does — PDPP already passed one for `table` and had simply
never mapped type.

Generalization: **before planning work inside a structure, check whether the
reference engineer would have that structure at all.** Their repo layout answers
questions their prose does not. His `src/components/` is flat
(`elements/ layout/ sections/ typography/ mdx/ page-<route>/`) — there is no
wrapper directory, which also indicts a name like `pdpp-concept/`.

This one question produced a bigger, better-targeted slice than three prior runs
of "apply his skills."

## Rule addenda earned this run

- **Check call sites before designing a variant.** `compact?: boolean` had zero
  live callers; the fix was deletion, not composition. His
  `patterns-explicit-variants` has no example for the never-built-mode case.
- **Same-named rungs can have unrelated metrics.** A class named `title` and a
  component rung named `title` differing 15px vs 23-27px is a trap no rule covers.
- **Cross-package same-named class collisions** (unlayered beats layered) sit
  outside both CRITICAL rules — a CSS-architecture problem, not a composition one.
- **Taxonomy has no stated file-count threshold.** Scaling his 104-file structure
  down to 20 required judgment: single-purpose files don't get one-file folders.

## Anti-patterns we hit

1. **Relaying an agent's scope reduction as a finding.** When an agent concludes
   the work is smaller than the person who owns the work says it is, verify
   before believing. (Ours was right — but only checking proved that.)
2. **Letting the measurable capture the investigation.** Class counts crowded out
   module composition for three runs.
3. **Promoting a taste question to the headline** of a job whose author said it
   was "less design than agreeing on method."
4. **Handing the owner a "your call" instead of a verdict.**
