# ~/.claude.json stow management

## Problem

`~/.claude.json` holds user-scoped MCP server registrations (applies to all projects) but is not stow-managed. It's a plain file, not a symlink into dotfiles. This means new MCP servers added after a fresh machine setup aren't tracked in git.

## What we know

- **`~/.claude/settings.json`** is stow-managed (symlinked to `claude/.claude/settings.json`) — works fine
- **`~/.claude.json`** is NOT stow-managed — plain file written by `claude mcp add --scope user`
- `setup.sh:192` already registers `codex-cli` via `claude mcp add codex-cli --scope user -- npx -y codex-mcp-server`
- Current MCP servers and their secrets:
  - `gemini` — has `GEMINI_API_KEY` hardcoded (this key is also in `~/.shell_secrets`)
  - `searxng` — has `SEARXNG_URL: http://searxng.home` (not sensitive, fine to commit)
  - `playwright`, `kimi`, `context7`, `docker`, `playwright-headed`, `codex-cli`, `linear` — no secrets

## The tension

Two options:

**Option A: Keep `setup.sh` as source of truth (current approach)**
- `setup.sh` has `claude mcp add` calls that idempotently register servers
- `~/.claude.json` never touches git, secrets never at risk
- Downside: adding a new MCP server requires remembering to update `setup.sh`; easy to drift

**Option B: Stow-manage `~/.claude.json`**
- Commit the file with `GEMINI_API_KEY` scrubbed (empty string or placeholder)
- `setup.sh` sources `~/.shell_secrets` and patches the key in after stowing (e.g. via `claude mcp add gemini` with the real key, overwriting)
- Upside: full MCP config is versioned
- Downside: more moving parts, need to ensure the patch step runs after stow

## Decision pending

Not resolved. The question is whether Option A's drift risk is acceptable or Option B's complexity is worth it.
