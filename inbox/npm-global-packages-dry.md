# DRY npm global packages: shared list for host + devcontainer

## What was done

### Created `npm-global-packages.txt` (repo root)
- Single source of truth for npm packages installed on both host and devcontainers
- One package per line, comments/blanks ignored
- Currently 15 packages: openspec, gemini-cli, gws, codex, playwright/mcp, posthog, sentry, neonctl, pnpm, prisma, pyright, typescript, ts-language-server, vercel, wrangler

### Updated `setup.sh`
- `~/.nvm/default-packages` now generated from the shared file + `@devcontainers/cli` (host-only)
- Individual `npm install -g` blocks replaced with a loop over the shared file
- `vercel`, `prisma`, `@sentry/cli` added (were previously container-only)
- `@devcontainers/cli` stays inline as host-only

### Updated `devcontainer/Dockerfile`
- ~15 individual `RUN npm install -g` lines replaced with a single `COPY` + `RUN xargs npm install -g`
- Dropped the `rm` of the temp file (root-owned file can't be removed by non-root user; harmless to leave)

### Updated `devcontainer/devcontainer.json`
- Build context changed from implicit `.` (devcontainer/) to `".."` (repo root) so Dockerfile can `COPY npm-global-packages.txt`
- `dockerfile` path updated to `devcontainer/Dockerfile` (relative to new context)

### Updated `devcontainer/Dockerfile` COPY paths
- `COPY init-firewall.sh` changed to `COPY devcontainer/init-firewall.sh` (relative to new context)

## What was validated

- setup.sh grep pipeline produces correct default-packages output
- setup.sh install loop correctly skips comments, blanks, and already-installed packages
- Docker test build succeeded: all 15 packages installed via xargs in a single layer
- All COPY source paths verified to exist relative to the new build context
- Caught and fixed: `rm /tmp/npm-global-packages.txt` failed because COPY creates root-owned file but npm install runs as non-root user

## What was also done (separate from DRY)

- Added `sudo -v` to `updates --apply` (in `bin/.local/bin/updates`) so sudo password is prompted once upfront, matching setup.sh's pattern
- OpenSpec (`@fission-ai/openspec`) was the original trigger — added to the shared list

## Still open

- Haven't done a full `devc --rebuild` end-to-end test with the real Dockerfile (only tested the npm layer in isolation)
- The context change in devcontainer.json may affect `.dockerignore` behavior if one is added later — the ignore file would need to be at repo root instead of devcontainer/
