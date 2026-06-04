# Claude Code onboarding

@~/code/dotfiles/ai/AGENTS.md

## MCP Model Preferences

When using external AI models via MCP:
- **Gemini**: prefer `gemini-3.1-pro-preview` (latest and most capable; `gemini-3-pro-preview` was deprecated March 9 2026)
- **OpenAI**: prefer `gpt-5.4` with high reasoning effort for complex tasks, low reasoning effort for simple tasks

## Private config

@~/.claude/CLAUDE.local.md

@RTK.md

## Local-only skills of note

- `pdpp-local-data-access` — query Tim's PDPP instance (https://pdpp.vivid.fish) via the owner token in `~/.shell_secrets`. Local-machine bypass of the upstream scoped-grant flow. Source: `~/code/dotfiles/ai/skills/local/pdpp-local-data-access/SKILL.md`.
