---
name: refactor-loop
description: Run a behavior-preserving refactoring as a gated engineering loop. Use when asked to refactor / clean up / decomplect / reduce complexity / improve code quality, especially open-ended asks ("audit for the most impactful refactoring and get it done to our standards"). This is the REFACTORING TASK PROFILE that plugs into the general `engineering-loop` skill — it fills that skill's evidence-contract slots with refactoring-specific measurement, methodology, and gates. Read `engineering-loop` first; this only adds the refactoring specifics.
---

# Refactor Loop (the refactoring task profile)

Plugs into **`engineering-loop`** (read it first — it owns the loop machinery, invariants, and the universal evidence contract). This file FILLS the contract slots for behavior-preserving refactoring. Grounded in:
- `ai/research/code-quality/decomplecting-and-cognitive-load-beat-loc-and-dry-as-refactoring-targets.md` (the methodology)
- `ai/research/code-quality/ai-generated-code-smells-and-when-agents-act-contrary-to-refactoring-goals.md` (the AI-slop checklist = the checker's tool)

## Methodology (priority order; ANTI-goals are LOC-reduction and DRY-maximization as TARGETS)
1. Decomplect (separate braided concerns) — highest value.
2. Reduce cognitive load (named intermediates, early returns, ~4 chunks/fn).
3. Make implicit explicit (name magic conditions/states).
4. Delete > abstract (inline wrong abstractions; leave honest duplication).
5. Extract ONLY deep modules (interface hides more than it adds).
6. Prepare-before-change; refactor and feature work are separate commits.

## Evidence-contract slots (filled)

**stop_condition (VERIFIABLE):** behavior-preserving (touched tests green before+after) AND the targeted complexity actually drops (e.g. biome `noExcessiveCognitiveComplexity` no longer trips, or a stated proxy improves) AND a different-model checker confirms the change is methodology-aligned (decomplect/name/delete, not laundering) with no surface-area change.

**oracle (the real judge — exact commands):**
- `node --test <touched test files>` (or the package's test runner) — green before AND after, same pass count.
- `npx biome lint <touched file>` — BASELINE-RELATIVE: the targeted complexity diagnostic for the symbol must be GONE, and ZERO NEW diagnostics vs the pre-change baseline. Do NOT require the whole (often legacy) file to become clean — pre-existing unrelated diagnostics are out of scope (this exact trap hit PR #81's review).
- `npx tsc --noEmit` (touched package) — 0 source errors (`.next/` stale-route errors are not real).
- `git diff --check` — clean.

**checker (independent, evidence-artifact required):** a separate GPT-5.6 Sol session that READS THE DIFF (never the maker's summary) and confirms, citing the diff. Use Terra for bounded making and Luna only for mechanical/light checks; never fall back to GPT-5.5, 5.4, or 5.3:
- behavior-preserving (no logic/string/order change unless an added characterization test proves an existing string wrong AND it's flagged a behavior change);
- methodology-aligned, not slop. Apply the AI-slop checklist: net-positive prod LOC is suspect; a NEW 1-caller wrapper is reject-by-default; a NAMED+COMMENTED helper inlined = REJECT (deep module destroyed); a "clarity fix" that changes behavior (e.g. altering a set membership) = REJECT, reclassify as a possible bug for separate handling; tautological/mock-only tests = REJECT; scope-creep / out-of-theme files = REVERT;
- **machine-verified claims:** any "N-caller" claim must be confirmed by `grep -rn <name>` minus the definition — agents systematically MISCOUNT callers; never trust the count.
Verdict: PASS / REVISE / REJECT with the specific diff evidence.

**acceptance_level:** CODE-LEVEL — behavior is intentionally unchanged, so tests + diff review by the independent checker suffice. (No journey/live/owner-retest needed unless the change is found NOT to be behavior-preserving — then it stops, it's not a refactor.)

**discovery (find + rank + CLASSIFY — run the REAL tools, not proxies):**
- Run the real complexity linter repo-wide (`biome lint ... | grep noExcessiveCognitiveComplexity`) — DON'T conclude "clean" from a nesting/size proxy.
- Rank by value × difficulty × impact × safety × reviewability. Value scales with how OFTEN the code is read/changed, not just the linter score.
- INSPECT hard/large/auth-adjacent files enough to CLASSIFY: essential-complexity / protocol-sensitive / high-value-but-owner-gated. Never exclude-then-conclude "nothing impactful exists" — that's the under-reach failure.
- NO-GO zones (essential complexity — do not "simplify"; classify + flag, don't refactor). **This list is a repo INPUT** — load the project's no-go zones if it declares them; otherwise use the **PDPP default profile**: auth/grant/consent/token/bearer; owner-session/csrf/exposure; rs-read/records/db/storage scoping+grant; search/mcp/read-core bounded-read; scheduler/controller/recovery; manifest role/schema semantics; connector selectors/waits/checkpoint/pagination.

**memory:** rejected-approaches ledger entry = {target, proposed move, evidence it was wrong (e.g. "5 callers per grep, not 1"; "inline made the switch a 38-line wall"; "would change terminal-set membership"), when-to-reconsider}.

**owner_gate:** any change that is NOT behavior-preserving (incl. a suspected bug surfaced during refactoring); any no-go-zone change; anything touching exports/routes/manifest/DB/OpenSpec surface area.

**cleanup:** fresh worktree off origin/main; strip node_modules symlinks before PR (they'd leak on `git add -A`); discovery notes → durable workstream dir not the worktree; one tight themed PR per coherent change; reject ledger + verified non-findings recorded.

**fail_output:** ONE sharp question (smallest decision that unlocks the real target, with evidence+tradeoffs) — OR a verified non-finding ("no safe target cleared the bar — here's the ranked map + why") — OR a PR + a truth-cheap evidence packet (commits, before/after oracle output, diff stat, what burden was removed in words).

## Run-learned traps (the checker enforces these — from the 2026-06-26 run)
- Caller counts: machine-verify, never trust the agent.
- "Inline the 1-caller wrapper" is frequently WRONG — only pure pass-through wrappers (no name-value, no comment, no logic) are safe inlines.
- A clarity fix can be a behavior change in disguise → stop the target.
- Net-zero LOC ≠ value, but net-POSITIVE prod LOC is presumptively suspect.
- Ambition: don't ship a safe-small PR when the ask was "most impactful" — surface the no-go tension instead.
