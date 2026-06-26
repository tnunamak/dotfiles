---
name: editing-agent-instructions
description: "Apply evidence-based rules when adding to or editing an agent instruction file — AGENTS.md, CLAUDE.md, GEMINI.md, .cursorrules, a system prompt, or any always-on agent context. Use BEFORE writing changes to these files so contributions stay lean and don't re-bloat the file: enforces the <200-line adherence cliff, critical-rules-first ordering, and the procedure→skill / always-do→hook / reference→file relocation rules. Triggers on 'edit AGENTS.md', 'add to CLAUDE.md', 'update the system prompt', 'add an instruction/rule for the agent', 'modify agent instructions', or any change to always-on agent context."
---

# Editing agent instructions

Always-on agent instruction files (AGENTS.md / CLAUDE.md / GEMINI.md / system prompts)
degrade as they grow — every line competes for the model's finite attention, and shared
files bloat because everyone appends and nothing gets deleted. Before you add or edit one,
apply these rules. Evidence + sources: `ai/research/agentic-context-design/effective-agents-md-structure-and-what-belongs-always-on.md`.

## Before adding anything: does it belong always-on at all?

Route by content type — most additions should NOT go in the instruction file:

- **A procedure / multi-step workflow** → a **skill** (`ai/skills/local/<name>/`), not prose here.
- **"Every time X, always do Y"** → a **hook** in `settings.json` (deterministic). Prose is unreliable for this; a hook enforces it. (If a hook already does it, don't also write the prose — that's redundant.)
- **"Never do X" / a hard guardrail** → a **hook or permission**, not an instruction.
- **Reference material / command cheatsheets / API tables** → a **skill or an `@`-imported file** the agent reads on demand. It costs attention every turn even when unused.
- **Personal preferences** ("how I like you to work") → user scope (`~/.claude/CLAUDE.md`), not a shared/project `AGENTS.md`.
- **Temporary / experimental / trial content** → a hook (auto-expires), an `@`-imported file (delete cleanly), or `CLAUDE.local.md` (gitignored). Never inline — always-on files have no expiry, so stale instructions linger as false premises.
- **A durable fact true on EVERY task** (build command, repo layout, a real convention) → keep it here, compressed to one line.

If it's none of the "keep" cases, relocate it. Adding to the always-on file is the last resort, not the default.

## If it does belong here, write it well

1. **Stay under ~200 lines total** (Anthropic's documented adherence cliff). If the edit pushes the file over, something must move out first.
2. **Critical behavioral rules go in the first ~10 lines.** Models over-attend to the start and end of long context and underuse the middle ("Lost in the Middle"). Don't bury a must-follow rule mid-file.
3. **Order: identity/role → behavioral rules → workflow → reference.** Reference material goes last or out.
4. **Positive imperatives, not negatives.** "Run `npm test` before committing" beats "don't commit untested." "Use `rtk git`" beats "don't run bare git."
5. **Concrete, not abstract.** "Use 2-space indent" beats "format properly." A single concrete counterexample beats three abstract rules. Cut philosophy that isn't actionable.
6. **Dedup.** Contradictory or repeated rules resolve arbitrarily and read as noise, not emphasis. Search the file for the concept before adding it; edit the existing rule rather than adding a parallel one.
7. **Separate instructions from reference** with headers or XML (`## Rules` vs `## Reference`, or `<reference>…</reference>`) so the model knows what to follow vs consult.

## After editing — verify (don't just append)

- Re-check the **line count**; if you added, consider what you can remove.
- **Grep for duplicates** of any concept you touched.
- Confirm the change reaches the intended agents (for this repo: `ai/AGENTS.md` is the source; Claude/Gemini `@`-include it, Codex symlinks it).
- If you moved content out, leave at most a one-line pointer to where it went.

## The one-line test

Would a new engineer, shown only this file with no other context, know exactly what to do
differently? If a line fails that test, make it concrete, relocate it, or cut it.
