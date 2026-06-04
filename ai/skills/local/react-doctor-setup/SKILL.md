---
name: react-doctor-setup
description: Wire React Doctor into a React project — agent rule files, CI workflow, optional pre-commit gate, and a sane initial config. Use when the user wants to add React linting/health-score checks, set up CI gating for React code quality, install agent best-practice rules for a React/Next/Vite/React Native codebase, or asks about react-doctor. Trigger phrases "react doctor", "set up react linting", "agent rules for react", "react health score", "CI for react quality".
---

# React Doctor setup

React Doctor (https://github.com/millionco/react-doctor, https://react.doctor) scans React/Next/Vite/RN codebases, emits diagnostics across state & effects, performance, architecture, security, accessibility, and produces a 0–100 health score. It detects 50+ coding agents and writes per-agent rule files so the agent stops generating bad React in the first place.

Use this skill to wire it into a project end-to-end: agent rules + CI + (optional) pre-commit + baseline config.

## Decide what the user actually wants

Three independent install surfaces. Confirm with the user which they want — don't do all three by default:

1. **Agent rules only** — the lightest touch. Just teaches the agent. No CI, no gate.
2. **Agent rules + CI** — recommended default. Sticky PR comments and a regression-only gate.
3. **Full** — adds a pre-commit hook on top.

Default recommendation if the user says "just set it up": option 2 in **regression-only mode** (fail only on new diagnostics in changed files). It won't block on baseline backlog.

## Pre-flight

Confirm it's actually a React project before doing anything:

```bash
jq -r '.dependencies.react // .devDependencies.react // .peerDependencies.react // "none"' package.json
```

Note framework (`next`, `vite`, `react-native`/`expo`, `@remix-run/*`, etc.) and whether it's a monorepo. React Doctor auto-detects all of this — you just need it for the conversation.

## Step 1 — Install agent rules

```bash
npx react-doctor@latest install --yes
```

Writes per-agent rule files (SKILL.md for Claude Code, AGENTS.md for Codex/OpenCode, .cursorrules for Cursor, etc.) into the project. `--yes` skips the agent-picker prompt and installs for every detected agent. Drop `--yes` if the user wants to choose.

Commit the generated files.

## Step 2 — Run a baseline scan

```bash
npx react-doctor@latest --score
```

Get the number. Then a verbose scan to understand the shape of the findings:

```bash
npx react-doctor@latest --verbose
```

Score labels: 75+ Great, 50–74 Needs work, <50 Critical. **Don't auto-fix anything** — surface the top categories to the user and let them decide.

## Step 3 — CI workflow

Write `.github/workflows/react-doctor.yml`. Default template (regression-only, sticky PR comment):

```yaml
name: React Doctor

on:
  pull_request:
  push:
    branches: [main]

permissions:
  contents: read
  pull-requests: write

jobs:
  react-doctor:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
        with:
          fetch-depth: 0
      - uses: millionco/react-doctor@main
        with:
          diff: main
          fail-on: warning
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

Non-obvious requirements (get these wrong and CI silently misbehaves):

- **`fetch-depth: 0`** is required for `diff` to work. With shallow clone, the diff base isn't in the local repo and the action falls back to a full scan or errors.
- **`permissions: pull-requests: write`** is required for sticky PR comments. Without it the action runs but the comment never posts and the failure is buried.
- **`fail-on` + `diff` is the built-in "fail on new regressions only"** — there's no separate `--fail-on-new` flag. This is the right default for adding the tool to an existing codebase.
- **`--offline` is implied in CI** — no score appears in the PR comment, only diagnostics. This is by design, not a bug. Don't tell the user "the score will show up in the PR" — it won't.
- If the project's default branch is `master` (or anything non-`main`), change `diff: main` AND the `branches:` filter.

### Score-floor variant (opt-in only)

Only use this if the user explicitly wants to enforce a minimum score. Pin the react-doctor version — new rule releases lower scores on unchanged code:

```yaml
- id: doctor
  uses: millionco/react-doctor@main
  with:
    fail-on: error
    github-token: ${{ secrets.GITHUB_TOKEN }}
- env:
    SCORE: ${{ steps.doctor.outputs.score }}
    FLOOR: "80"
  run: |
    if [ -n "$SCORE" ] && [ "$SCORE" -lt "$FLOOR" ]; then
      echo "::error::React Doctor score $SCORE is below floor $FLOOR"
      exit 1
    fi
```

## Step 4 — Pre-commit (only if asked)

Use the existing hook manager — don't install one. If Husky:

```bash
echo 'npx react-doctor --staged --fail-on error' >> .husky/pre-commit
```

If lefthook, add a `pre-commit` command running the same thing. `--staged` materializes the index into a temp dir so it scans exactly what will be committed.

`--staged` and `--diff` are mutually exclusive — don't combine them.

## Step 5 — Config (only if needed)

Don't pre-create an empty `react-doctor.config.json`. Only create one if the baseline scan reveals legitimate exemptions. Use the narrowest scope that fits:

- `ignore.overrides` — silence specific rules on specific files. **Use this most of the time.**
- `ignore.rules` — silence a rule everywhere. Use sparingly.
- `ignore.files` — silence ALL rules on matched files. Use very sparingly — loses coverage for unrelated rules.

```json
{
  "ignore": {
    "overrides": [
      { "files": ["src/generated/**"], "rules": ["react-doctor/no-array-index-as-key"] }
    ]
  }
}
```

For known-noisy categories (e.g. user doesn't care about opinionated design rules):

```json
{ "ignore": { "tags": ["design"] } }
```

Available tags include `"design"`.

## Common gotchas

- **Monorepos:** React Doctor auto-detects per-package framework and applies `rn-*` rules only to React Native packages. Don't add manual project filters unless the auto-detection is wrong.
- **The `design` tag is excluded from PR comments, score, and `--fail-on` by default** but visible in local CLI. If the user is confused why their local scan shows more issues than the PR comment, this is why.
- **Score may drop across react-doctor releases** as new rules ship. Pin the version in CI if stable scores matter.
- **Companion plugins** (`eslint-plugin-react-hooks`, `eslint-plugin-react-you-might-not-need-an-effect`) are folded in automatically if installed. Mention them as optional adds if the user wants deeper hooks coverage.
- **Don't bundle knip** — it was removed from react-doctor in v0.2. If the user wants dead-code detection, suggest a separate `npx knip` step.

## Verify before reporting done

After wiring everything:

1. Run `npx react-doctor@latest --score` locally and report the number.
2. Confirm agent rule files were generated (check for `AGENTS.md`, `SKILL.md`, `.cursorrules` etc. in repo root — exact set depends on detected agents).
3. If CI was added, confirm the workflow file is syntactically valid (`gh workflow view react-doctor.yml --yaml` after pushing, or just visually check the YAML).
4. Tell the user what mode is active (advisory / regression-only / strict floor) so they're not surprised by the first PR.
