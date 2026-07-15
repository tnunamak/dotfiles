# Skill metadata budget: the ~16k-char index cliff, and how to stay under it

**Date:** 2026-06-29
**Trigger:** Codex warned "Skill descriptions were shortened to fit the 2% skills context budget."
Tim asked why suites like `impeccable` cost one index line *per skill* instead of collapsing to a
single "for UI, look here" entry point.

## The mechanism (verified)

- Claude Code / Codex load only `name:` + `description:` from each SKILL.md frontmatter at session
  start — **a lean index**, NOT the bodies. Bodies (this machine: ~1 MB across 112 SKILL.md) load
  on-demand when a skill is invoked. So body size is ~free; **index length is the cost.**
- The index has a budget: **~16,000 chars (undocumented), ~1% of context, scales with model.**
  Claude exposes `skillListingBudgetFraction` (e.g. `0.02` = 2%) and
  `SLASH_COMMAND_TOOL_CHAR_BUDGET` to raise it.
- Past the budget: **descriptions are shortened, then skills are dropped entirely** (least-used
  first). Documented case: 63 skills → "Showing 42 of 63 due to token limits", 21 skills (33%)
  invisible/un-invokable. Typical 263-char descriptions → only ~42 skills fit.
- **`defer_loading` (the Tool Search deferral that lazily loads MCP tools) does NOT apply to
  skills.** This is the architectural gap behind "why can't the suite be one deferred entry" —
  skills have no native lazy-index mechanism.

## This machine's state (2026-06-29)

- ~112 SKILL.md files, ~27,800 chars of descriptions = **~2× over the ~16k budget.** Both Codex and
  Claude are compressing. Dominated by **plugins that bundle many sub-skills** (compound-engineering
  alone ≈ 40 index entries: 20 skills + 5 agent categories + 18 commands), NOT by local skills.

## The levers (in order of leverage)

1. **`skillOverrides` → "name-only"** for low-priority skills: they list by name only (no
   description), cost ≈0 index chars, **still invokable.** This is the closest thing to Tim's
   "collapse the suite" intuition — keep `impeccable` installed, make its ~21 skills name-only.
2. **Raise `skillListingBudgetFraction` to 0.02** — headroom instead of trimming.
3. **Disable whole plugins/suites you don't use** — biggest cut, but all-or-nothing (no per-sub-skill
   disable in config; selective trim requires *forking/vendoring* the plugin).
4. **Compress descriptions to ≤130 chars**, front-load trigger keywords in first ~50 chars, push
   detail to the body. Template: "[Verb] [domain]. Use when: [trigger1], [trigger2]."
5. **`/doctor`** reports how many descriptions are being shortened/dropped and which.

## Sharp caveat — skills trigger unreliably

Vercel agent evals: **skills never invoked in 56% of cases** (fuzzy triggering); a **compressed docs
index embedded directly in AGENTS.md hit 100%** vs skills' 79% even with explicit instructions. So
Tim's "one line in a doc pointing to where the detail lives" instinct isn't just budget-efficient —
there's evidence it *triggers more reliably* than the skill mechanism. For always-relevant domains,
an AGENTS.md index line may beat a skill outright. Skills win for genuinely on-demand, rarely-needed
capability where you don't want the index line always present. See
[[effective-agents-md-structure-and-what-belongs-always-on]].

## Redundancy found on this machine

`frontend-design` and `skill-creator` were enabled BOTH as standalone plugins AND bundled inside
compound-engineering — disabling the standalone copies loses nothing. Always check for plugin overlap
before counting index cost.

## Sources

- https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- https://code.claude.com/docs/en/skills
- https://gist.github.com/alexey-pelykh/faa3c304f731d6a962efc5fa2a43abe1 (skill-budget research: ~16k char limit, 42-skill cap)
- https://docs.claude-mem.ai/progressive-disclosure
- https://alexop.dev/posts/stop-bloating-your-claude-md-progressive-disclosure-ai-coding-tools/
- Vercel agent evals (skills 56% never-invoked; AGENTS.md index 100%) — via alexop.dev / community write-ups
