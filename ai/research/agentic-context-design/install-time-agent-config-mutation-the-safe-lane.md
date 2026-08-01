---
title: Install-time mutation of agent-harness configs — the safe lane (drop-in > CLI-guarded-append > never hand-edit co-owned JSON)
date: 2026-06-30
tags: [install, packaging, mcp, claude-code, codex, config, idempotency, minnows]
sources: primary (Anthropic Desktop Extensions post; Simon Willison TIL; Claude Code settings docs)
source_session: 019e5b17-6096-7cf2-aec9-42244f40d8ac
---

# Install-time agent-config mutation: what's safe, what's the anti-pattern

**Context.** Recurring question when adding a minnow (or any agent tool): is it OK for an
installer to edit agent-harness config files (`~/.claude.json`, `settings.json`,
`~/.codex/config.toml`, `claude_desktop_config.json`)? Which tools do it, and is it wise?

## Verdict — three tiers, safest first

1. **DROP-IN (safest, no config mutation at all).** Symlink/copy skill *directories* into
   `~/.{claude,codex,gemini}/skills/` and binaries onto PATH. No shared-config file is touched
   → nothing to merge, nothing to corrupt, no OAuth/trust/cache state at risk, fully reversible.
   **This is what minnows does.** Strictly better than the MCP-install pattern below.
2. **CLI- or grep-GUARDED ADDITIVE WRITE (fine when unavoidable).** When a tool genuinely needs
   a config key (an MCP server, a settings flag): use the harness's own CLI (`claude mcp add`,
   `claude plugin install`) OR an idempotent append guarded by `grep -qF` so re-runs are no-ops.
   Target the DECLARATIVE file you own (`settings.json`), never the stateful parts of
   `~/.claude.json` (OAuth session, per-project trust, caches). Read-modify-write, never
   overwrite; check-before-append on arrays. (This is exactly how dotfiles' `setup.sh` does
   `[tui]`/`[features]` in config.toml and `claude plugin marketplace add/install`.)
3. **HAND-EDIT / OVERWRITE A CO-OWNED JSON (the anti-pattern).** Blindly editing or replacing a
   config file the harness also writes to. This is the friction Anthropic built a whole feature
   to kill — avoid.

## Why (primary sources)

- **Anthropic, "Desktop Extensions" (Jun 26 2025).** Names manual config editing as THE problem.
  "Before": `npm install -g …` → "Edit ~/.claude/claude_desktop_config.json manually" → "Restart"
  → "Hope it works". Listed friction: *"Manual configuration: Each server requires editing JSON
  configuration files."* Fix = `.mcpb` bundles: a DECLARATIVE manifest (`user_config`) where the
  HOST owns the write (validates inputs, securely stores secrets, passes via env/args). Stance:
  don't make the user/installer hand-edit; declare needs, let the harness apply them.
  https://www.anthropic.com/engineering/desktop-extensions
- **Simon Willison, "Using Playwright MCP with Claude Code."** Doesn't hand-edit — uses the CLI:
  `claude mcp add playwright npx '@playwright/mcp@latest'`. Notes the gotcha: it silently mutates
  `~/.claude.json` under a `"projects"` key, per-directory; "took me a while to figure out…where
  the state went." CLI-doing-the-write is fine; the surprise is config OPACITY (where it lands).
  https://til.simonwillison.net/claude-code/playwright-mcp-claude-code
- **Idempotency rules (Claude Code settings docs + community).** Read-modify-write not overwrite;
  dedupe array entries (note the `$defaults` sentinel that preserves built-in lists); target the
  right scope file; most keys hot-reload (a re-run won't need a restart); Claude keeps timestamped
  backups (5 most recent) of settings.json/.claude.json as a fallback; `claude doctor` validates.
  https://code.claude.com/docs/en/settings

## Application to minnows

minnows stays in **Tier 1** (drop-in symlinks; zero config-file edits) — keep it there. A future
minnow needing an MCP server or a settings key should use **Tier 2** (CLI/grep-guarded additive
write to the declarative file, à la dotfiles `setup.sh`), or ship a declarative `.mcpb`-style
manifest. Never **Tier 3**. See [[monorepo-layout-for-cli-tools-that-ship-agent-skills]] for the
companion packaging decision (shared lib in dev, vendor-on-ship at the skill boundary).
