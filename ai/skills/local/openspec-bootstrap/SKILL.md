---
name: openspec-bootstrap
description: Use when the user mentions OpenSpec or asks for spec-driven development in a project that hasn't been initialized. OpenSpec is a per-project tool — check if `openspec/` exists in the repo; if not, offer to run `openspec init --tools <detected agents>`. Once initialized, OpenSpec's own skills and commands (`/opsx:propose`, `/opsx:apply`, etc.) take over.
---

# OpenSpec bootstrap

OpenSpec (https://openspec.dev, Fission-AI/OpenSpec) is a spec-driven development framework installed per-project, not globally.

When the user mentions OpenSpec or wants spec-driven workflow in a project:

1. Check for `openspec/` at the repo root. If present, OpenSpec is already initialized — use its slash commands (`/opsx:propose`, `/opsx:explore`, `/opsx:apply`, `/opsx:archive`) directly.
2. If absent, offer to run `openspec init` with the agents in use (e.g. `openspec init --tools claude,codex,gemini`). This creates `openspec/` and installs OpenSpec's workflow skills and commands into each agent's project-scoped dirs.
3. After init, OpenSpec's own skills load and drive the workflow. This skill is only needed before that.
