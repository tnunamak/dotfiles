# skill-to-evals install: what happened and where it landed

**Date:** 2026-04-18
**Prior sessions:** 2026-04-10 (initial install), 2026-04-18 (validation)

## What was requested

Install the `skill-to-evals` skill from `vana-com/data-connect` (pinned at `9ff0cd7`) into dotfiles so it's available via `setup.sh`.

Source: https://github.com/vana-com/data-connect/blob/9ff0cd73e1723060239591177e4154662e0397fa/.agents/skills/skill-to-evals/SKILL.md

The skill has two files: `SKILL.md` and `PROJECT_NOTES.md`.

## Approach evolution

### Attempt 1: fetch at setup time (rejected by user)

Added an `install_external_skill` function to `setup.sh` that downloaded the tarball from GitHub at the pinned ref, extracted the subdirectory, and wrote an `.installed-ref` marker for idempotency. Worked correctly but user pointed out the remote could vanish — vendor it instead.

### Attempt 2: stow via `claude/.claude/skills/` (superseded)

Vendored the files into `claude/.claude/skills/skill-to-evals/` and let stow symlink them. This worked at the time but was superseded when skills management was reorganized (between 2026-04-10 and 2026-04-18).

### Current state: `ai/skills/local/` (working)

The skill now lives at `ai/skills/local/skill-to-evals/` and is symlinked into `~/.claude/skills/skill-to-evals` by setup.sh's local-skills loop. The old stow copy was cleaned up.

Validated 2026-04-18:
- `~/.claude/skills/skill-to-evals` → symlink to `~/code/dotfiles/ai/skills/local/skill-to-evals`
- Both `SKILL.md` and `PROJECT_NOTES.md` present
- Claude Code discovers and lists the skill

## Key lesson

Vendor skills into the repo rather than fetching at setup time. Remotes can disappear. This aligns with the broader decision in `skills-dedup-and-ownership.md` to keep locally-authored/vendored skills in `ai/skills/local/` with direct symlinks.
