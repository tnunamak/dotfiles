---
title: "Both Claude Code and Gemini CLI `mcp add` resolve ${ENV_VAR} placeholders and write the literal secret back into the config file — a known bug class; guard with a post-sync placeholder restore"
date: 2026-08-03
topic: oauth-mcp-auth
tags: [mcp, gemini-cli, claude-code, secrets, env-vars, settings-json]
status: settled
sources: [cc-18692, gemini-7840, gemini-5828, gemini-5282]
source_session: c0dad57d-f029-4f28-bf9e-46c646d26c11
---

## CLAIMS

- `claude mcp add` reads the MCP config, resolves `${VAR}` placeholders during parsing, and writes the RESOLVED literal values back to the file — leaking the secret into the on-disk config. Documented workaround: `git checkout -- <file>` after the add. [cc-18692]
- Gemini CLI has a sibling defect: `gemini mcp add` overwrites `~/.gemini/settings.json` (priority p2), and env-var substitution behaves inconsistently between the `env` block and HTTP `headers`. [gemini-7840] [gemini-5828]
- Gemini CLI env-var expansion supports `$VAR` / `${VAR}`; an undefined var resolves to empty string. Header substitution was a later-added feature (was literal-only originally). [gemini-5282]
- Net effect for a stow/sync flow that calls `gemini mcp add` (e.g. `sync-mcps.sh`): the CLI can re-materialize real tokens into the working tree on every sync, and nothing restores the `${VAR}` form — so the file must be re-scrubbed after each sync, or the secret drifts back in and risks a commit.

## SOURCES

**cc-18692**
URL: https://github.com/anthropics/claude-code/issues/18692
Accessed: 2026-08-03
Quote: "`claude mcp add` expands environment variable placeholders and writes resolved values to .mcp.json"

**gemini-7840**
URL: https://github.com/google-gemini/gemini-cli/issues/7840
Accessed: 2026-08-03
Quote: "Adding mcp server from command line overwrites user level settings.json"

**gemini-5828**
URL: https://github.com/google-gemini/gemini-cli/issues/5828
Accessed: 2026-08-03
Quote: "Gemini CLI is not performing environment variable substitution for MCP Servers"

**gemini-5282**
URL: https://github.com/google-gemini/gemini-cli/issues/5282
Accessed: 2026-08-03
Quote: "Support environment variable substitution in MCP server headers"

## SYNTHESIS

This is expected (a recognized upstream bug), not a local misconfiguration, and not permanently fixable from our side. The durable mitigation is defensive: after any `mcp add` / sync that touches a per-agent config, re-substitute the known `${VAR}` placeholders back over any materialized literals. Best home for that is a post-sync step in `sync-mcps.sh` (one source of truth), turning "remember to check the file before committing" into an automatic scrub. Secret-scanning push protection is the backstop, but a pre-commit/post-sync scrub prevents the working tree from ever holding the literal.
