# Claude Code onboarding

@~/code/dotfiles/ai/AGENTS.md

## Claude-specific tooling

### rstring

`rstring` (pypi.org/project/rstring) is available to summarize code with rsync-style include/exclude patterns and respects `.gitignore` by default.

Use it to:
- Inspect only the parts of the codebase relevant to the current task.
- Generate concise context (e.g., key modules and their interfaces) instead of pasting large trees.

Example commands:

- `rstring` -- all files (gitignore-filtered)
- `rstring --include='*.py'` -- only Python files
- `rstring -C /path/to/project` -- run from a different directory
- `rstring --include='*/' --include='*.js' --exclude='test*'` -- more complex filters

When preparing context for an LLM, prefer `--no-clipboard` for direct output to the terminal and `--preview-length` / `--summary` for concise summaries.

### Devcontainer workflow

Launch devcontainers with `devc`:
```bash
devc ~/code/my-project        # start devcontainer + claude code
devc --rebuild ~/code/my-project  # rebuild from scratch
```

Or link manually: `link-devcontainer` / `unlink-devcontainer`.

### AI / context hygiene

- Respect `.gitignore` and `.aiignore` (if present) when gathering context for the model.
- If there is no `.aiignore` and the repo is large, suggest one that excludes:
  - Large tracked artifacts (builds, bundles, assets)
  - Lock files (`package-lock.json`, `bun.lockb`, etc.)
  - Generated types and metadata (`next-env.d.ts`, `*.tsbuildinfo`, etc.)
- Default rule: if a file helps understand the code, include it; if it is large, generated, or noisy, exclude it.

## MCP Model Preferences

When using external AI models via MCP:
- **Gemini**: prefer `gemini-3-pro-preview` (latest and most capable)
- **OpenAI**: prefer `gpt-5.1` with thinking for complex tasks, `gpt-4o` for faster/cheaper tasks

## AI-generated slop cleanup (`/deslop`)

- Before you consider work "ready", run `/deslop` on the current branch (diffed against the base branch, usually `main`).
- Check the diff against the base branch and remove any AI-generated slop introduced in this branch, including:
  - Extra comments a human wouldn't add or that are inconsistent with the rest of the file.
  - Extra defensive checks or try/catch blocks that are abnormal for this area of the codebase, especially when callers already validate inputs.
  - Casts to `any` (or similar escape hatches) added just to get around type issues.
  - Any style, naming, or structure that doesn't match the surrounding code.
- Keep changes minimal and focused on cleanup only; don't add features or refactors as part of `/deslop`. When done, summarize what changed in 1-3 sentences.

## Private config

@~/.claude/CLAUDE.local.md
