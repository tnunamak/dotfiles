# Claude Code onboarding

@~/code/dotfiles/ai/AGENTS.md

## Model Policy

- **Claude Code**: use `fable` for the top-level orchestrator and final judgment; delegate bounded implementation and mechanical work to cheaper agents. The global `model` setting enforces this default.
- Exact model IDs and effort levels for external providers (Codex, Gemini) live in `ai/AGENTS.md` rule 1 and in the minnows `model-choice-policy` data pack (`waspflow ops list`) — don't duplicate them here. When a newer GA family ships, update AGENTS.md and the pack, then run `model-policy-check`.

## Private config

@~/.claude/CLAUDE.local.md

<!-- rtk disabled 2026-06-29 — re-enable: @RTK.md (binary/stow/setup.sh wiring left intact) -->

## Local-only skills of note

- `pdpp-local-data-access` — query Tim's PDPP instance (https://pdpp.vivid.fish) via `PDPP_OWNER_TOKEN` from the Infisical-hydrated environment. Local-machine bypass of the upstream scoped-grant flow. Source: `~/code/dotfiles/ai/skills/local/pdpp-local-data-access/SKILL.md`.
- `deck-building` — Tim's full slide-deck pipeline (author-then-translate, anti-slop register, slidetext.py loop, verification gates). Read it BEFORE building or editing any deck for Tim. Source: `~/code/dotfiles/ai/skills/local/deck-building/SKILL.md`.
