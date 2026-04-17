---
name: dotfiles-strategy
description: Load the dotfiles strategy doc before proposing changes to setup.sh, skill/MCP management, package installers, stow packages, or the install flow. Covers source-of-truth rules, multi-agent parity, one-mechanism-per-concern, and the rationale behind choices that might otherwise seem inconsistent.
---

# Dotfiles strategy

Before recommending changes to how this repo installs, manages, or distributes anything, read `STRATEGY.md` at the repo root. It captures the values behind decisions that aren't obvious from the code: why some things are symlinked and others managed by external tools, when to adopt new tooling vs wait for upstream solutions, and how to evaluate tradeoffs consistently with prior calls.

Apply the principles there to any change touching `setup.sh`, `sync-mcps.sh`, `ai/mcp-servers.json`, `ai/skills/`, stow package layout, `npm-global-packages.txt`, or the bootstrap flow.
