# Skills dedup: dotfiles vs plugins

**Date:** 2026-04-18
**Context:** Session that installed pbakaus/impeccable, reorganized skills into dotfiles, added Gemini MCP sync, and moved general-purpose skills out of pdpp.

## Problem

There are two skill delivery mechanisms:

1. **Dotfiles** (`ai/skills/local/` + `ai/skills/impeccable/`) — symlinked into `~/.claude/skills`, `~/.codex/skills`, `~/.gemini/skills` by `setup.sh`. Works for all three agents.
2. **Claude Code plugins** (compound-engineering, vercel) — managed by Claude's plugin system, cached in `~/.claude/plugins/cache/`. Claude-only. Auto-updated.

Several skills exist in both places:

| Dotfiles (`ai/skills/local/`) | Plugin equivalent | Identical? |
|---|---|---|
| `nextjs` | `vercel:nextjs` | Yes (at time of copy) |
| `shadcn` | `vercel:shadcn` | No (differ) |
| `vercel-react-best-practices` | `vercel:react-best-practices` | No (differ) |
| `vercel-composition-patterns` | No plugin match | N/A |
| `web-design-guidelines` | No plugin match | N/A |

## Decision needed

You want "everything managed through dotfiles" and "no duplicates." Those are in tension because:

- **Keeping dotfiles versions** = single source of truth, all 3 agents see them, but no auto-updates. You'd manually refresh from upstream.
- **Keeping plugin versions** = auto-updated for Claude, but Codex and Gemini don't see them at all (plugins are Claude-only).

### Recommended path: keep dotfiles, remove plugin duplicates

Since `setup.sh` already changed to use `npx skills add -g` for upstream suites (impeccable, karpathy), and locally-authored skills are direct symlinks:

1. **Delete `nextjs`, `shadcn`, `vercel-react-best-practices` from `ai/skills/local/`** — these came from pdpp's `.agents/skills/` which got them from an earlier `npx skills add`. They're stale copies of the Vercel plugin skills. Since `setup.sh` now runs `npx skills add` for upstream suites, the right move is to add `vercel-labs/agent-skills` (the source repo for those Vercel skills) to the `UPSTREAM_SKILLS` array in `setup.sh` — then `npx skills` manages the install/update lifecycle, and all three agents get them.

2. **Keep `vercel-composition-patterns` and `web-design-guidelines` in `ai/skills/local/`** — no plugin equivalent exists, so these are only available via dotfiles.

3. **Check if `vercel-labs/agent-skills` is the right source** — verify by running:
   ```bash
   npx skills add vercel-labs/agent-skills -l
   ```
   This should list `nextjs`, `shadcn`, `react-best-practices`, etc. If it does, add it to `UPSTREAM_SKILLS` in `setup.sh` and delete the local copies.

4. **Plugin-side cleanup** — the Vercel plugin will still load its built-in copies. Claude will then see two versions: the `npx skills`-installed global one and the plugin one. This is unavoidable unless you uninstall the plugin or the plugin has a way to exclude specific skills. Check if this causes actual UX issues (duplicate `/nextjs` commands) before worrying about it — it might just silently prefer one.

## What changed in this session

### Files modified
- `setup.sh` — added shared skills section (upstream via `npx skills`, local via symlinks), Gemini MCP sync
- `sync-mcps.sh` — added Gemini block (uses `gemini mcp add --scope user`)
- `ai/mcp-servers.json` — added `gemini` section (codex-cli + linear)
- `ai/AGENTS.md` — added Skills section documenting the two mechanisms

### Files created/moved
- `ai/skills/impeccable/` — 21 skills moved here from `~/.agents/skills/` (originally installed by `npx skills add pbakaus/impeccable`)
- `ai/skills/local/` — 13 skills:
  - `autoresearch-tasks`, `skill-creator`, `skill-to-evals` (moved from `claude/` stow package)
  - `cognitive-load` (moved from pdpp, added missing YAML frontmatter)
  - `css-clamp-calculation`, `karpathy-guidelines`, `tailwind-merge-recipe`, `tailwind-sort` (moved from pdpp)
  - `nextjs`, `shadcn`, `vercel-composition-patterns`, `vercel-react-best-practices`, `web-design-guidelines` (moved from pdpp — **these are the ones that need dedup resolution**)

### pdpp cleanup
- Deleted 21 impeccable skills + 10 general-purpose skills from `~/code/pdpp/.agents/skills/`
- Deleted `~/code/pdpp/skills-lock.json`
- Left 3 pdpp-specific skills: `shadcn-primitives-wrappers`, `tailwind-shadcn-adaptation`, `ui-text`

### Current state
- `setup.sh` installs upstream suites via `npx skills add -g` (impeccable + karpathy) and symlinks `ai/skills/local/*` into all three agents
- `ai/skills/impeccable/` still has the old copies from the initial manual install — these are now redundant with `npx skills add -g pbakaus/impeccable` in setup.sh. They could be deleted (npx skills manages the install), or kept as a fallback if npx skills is unavailable. Clarify intent.
- 34 skills visible per agent (Claude, Codex, Gemini)

## Open questions

1. Should `ai/skills/impeccable/` be deleted now that `setup.sh` runs `npx skills add -g pbakaus/impeccable`? If yes, the setup.sh symlink loop only needs to cover `ai/skills/local/`.
2. Should `vercel-labs/agent-skills` be added to `UPSTREAM_SKILLS` in setup.sh to replace the 5 Vercel-sourced skills currently in `ai/skills/local/`?
3. The `npx skills add -g` in setup.sh installs to `~/.agents/skills/` AND symlinks into agent dirs. The local-skills loop ALSO symlinks into agent dirs. If an upstream skill and a local skill share a name, the last `ln -sfn` wins (local, since it runs second). Is that the right precedence?
