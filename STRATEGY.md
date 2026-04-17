# Dotfiles strategy

How I want this repo maintained. Read before proposing changes to `setup.sh`, skill/MCP management, or the install flow.

## Source of truth

- **This repo bootstraps a fresh machine.** `setup.sh` must be sufficient — nothing landed by hand that isn't reproducible from a clean clone.
- **Stow owns `$HOME` layout.** New config files belong in a stow package under `dotfiles/<pkg>/` so they symlink into place. Don't write to `$HOME` directly from `setup.sh` unless the file is runtime state (e.g. `~/.shell_local`, generated lockfiles) that shouldn't live in the repo.

## Reproducibility over ergonomics, except when ergonomics is load-bearing

- Prefer declarative manifests (`npm-global-packages.txt`, `ai/mcp-servers.json`, `setup.sh` lists) over imperative one-offs.
- Prefer upstream-managed packages over vendored copies. Pin versions via the tool's native lockfile when possible.
- **Exception: live editing.** Files I actively tweak (locally-authored skills under `ai/skills/local/`, stow-managed configs) stay as direct symlinks so edits propagate without a re-install step.

## One mechanism per concern

When a job has an established tool, use it. Don't run two parallel systems unless the tools genuinely cover non-overlapping cases.

- Skills: `npx skills` for upstream suites + symlinks for locally-authored (`ai/skills/local/`). Two mechanisms, orthogonal cases — see `ai/AGENTS.md#skills`.
- MCPs: `sync-mcps.sh` driven by `ai/mcp-servers.json`. One declarative manifest, one install script.
- Packages: `npm-global-packages.txt` for npm, `uv tool install` for Python, native installers where they exist (Claude Code, rtk).
- Plugins that bundle multiple concerns (Claude Code plugins, OpenSpec): evaluate case-by-case. Don't adopt one just because it's shiny.

## Multi-agent parity

Claude Code, Codex, and Gemini CLI should see the same skills and MCPs. If a tool only supports Claude, that's a reason for skepticism, not a reason to go Claude-only.

## Forward compatibility

- Track upstream feature work (e.g. [vercel-labs/skills#729](https://github.com/vercel-labs/skills/issues/729) for declarative Skillfile) and migrate when the native solution lands.
- Don't adopt experimental flags as load-bearing infrastructure. Use them when they genuinely help, but keep `setup.sh` itself stable and standard.

## Minimal edits

Per `ai/AGENTS.md`: no speculative refactors, no dead code, no drive-by improvements. Bug fixes don't need surrounding cleanup. When investigating, commit the diagnostic wrappers; when done, remove them.

## Investigation discipline

Active investigations (see `CLAUDE.md`) get a section documenting symptom, evidence, hypotheses tried and rejected with reasons, hypotheses still open, and diagnostic instrumentation installed. Don't ship a "fix" without reproducing the failure. Subagent research is not a substitute for end-to-end testing.
