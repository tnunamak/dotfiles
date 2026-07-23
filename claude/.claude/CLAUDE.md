# Claude Code onboarding

@~/code/dotfiles/ai/AGENTS.md

## Model Policy

- **Claude Code**: use `fable` for the top-level orchestrator and final judgment; delegate bounded implementation and mechanical work to cheaper agents. The global `model` setting enforces this default.
- **External Gemini via MCP**: prefer `gemini-3.1-pro-preview` (latest and most capable; `gemini-3-pro-preview` was deprecated March 9 2026)
- **External OpenAI / Codex**: use GPT-5.6 only. Use `gpt-5.6-sol` for orchestration and judged review, `gpt-5.6-terra` for bounded implementation, and `gpt-5.6-luna` for light/mechanical work. Do not use GPT-5.5, GPT-5.4, or older models. Prefer higher reasoning effort only when task complexity warrants it, and update these exact IDs when a newer GA family is verified locally.

## Private config

@~/.claude/CLAUDE.local.md

<!-- rtk disabled 2026-06-29 — re-enable: @RTK.md (binary/stow/setup.sh wiring left intact) -->

## Local-only skills of note

- `pdpp-local-data-access` — query Tim's PDPP instance (https://pdpp.vivid.fish) via `PDPP_OWNER_TOKEN` from the Infisical-hydrated environment. Local-machine bypass of the upstream scoped-grant flow. Source: `~/code/dotfiles/ai/skills/local/pdpp-local-data-access/SKILL.md`.
