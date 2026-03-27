# Devcontainer Architecture Notes

Notes for any agent working on the devcontainer setup. Read this before making changes.

## Key Design Decisions

### Home directory bind mount
The container user is `node` (HOME=/home/node), but we bind-mount a per-workspace host directory to `/home/node`. This means anything the Dockerfile puts under `/home/node/` gets shadowed at runtime. Workaround: install to system paths (`/usr/local/bin`, `/opt/`) during build, or use named volumes for caches.

### Host path preservation
`workspaceFolder` is set to `${localWorkspaceFolder}` so the container CWD matches the host path (e.g., `/home/tnunamak/code/myproject`). This is critical because Claude Code stores project-scoped config keyed by absolute path. A `HOST_HOME` env var and symlink (`~/code -> $HOST_HOME/code`) bridge the gap between `/home/node` and the host home.

### No CLAUDE_CONFIG_DIR
We deliberately do NOT set `CLAUDE_CONFIG_DIR`. When set, Claude Code reads `.claude.json` from `$CLAUDE_CONFIG_DIR/.claude.json` (inside the dir) instead of `$HOME/.claude.json` (the top-level file). The top-level `~/.claude.json` is where user MCP servers are configured. Setting `CLAUDE_CONFIG_DIR` causes all user MCPs to silently disappear.

## Known Issues

### Plugins don't fully work in containers
Claude Code stores absolute host paths in `installed_plugins.json` and `known_marketplaces.json` (e.g., `/home/tnunamak/.claude/plugins/cache/...`). The `init-firewall.sh` creates a symlink (`/home/tnunamak/.claude -> /home/node/.claude`) which helps, but the plugin system still doesn't reliably discover/load plugins. This is a known upstream bug (anthropics/claude-code #15717, #10379). No clean workaround exists.

### SearXNG MCP not accessible
SearXNG is behind Traefik on 192.168.1.4 (hostname `searxng.home`). Can't firewall by hostname — allowlisting :80/:443 would expose all Traefik services. Fix: expose SearXNG on a dedicated port on vivid-fish, then allowlist just that port in `init-firewall.sh`.

### settings.json is volatile
Claude Code actively manages `~/.claude/settings.json` and will overwrite it at runtime. Don't rely on manually adding keys like `enabledPlugins` — they get stripped. Plugins are managed through Claude Code's own UI (`/install`, `/plugin`). The file IS stow-managed (symlinked to dotfiles), which means Claude Code writes through to the dotfiles source. This is fine — review the git diff before committing.

## File Layout

| File | Purpose | Managed by |
|------|---------|-----------|
| `Dockerfile` | Image build (system deps, tools, Playwright, etc.) | dotfiles |
| `devcontainer.json` | Mounts, env vars, build args | dotfiles |
| `init-firewall.sh` | DNS, firewall rules, host-path symlinks, dockerd | dotfiles (COPY'd into image) |
| `test-path-preservation.sh` | Smoke tests for paths, MCPs, plugins, signing | dotfiles |
| `check-mounts.sh` | Validates bind mounts are correct | dotfiles |

## Testing

Run inside a devcontainer after rebuild:
```bash
bash /usr/local/bin/init-firewall.sh  # already runs via postStartCommand
bash test-path-preservation.sh        # from the devcontainer/ dir
```

## Firewall Rules

Order matters — ACCEPT rules must come before the blanket DROP.

1. Loopback (always)
2. Host gateway port 3100 (Playwright MCP headed browser)
3. DROP 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 169.254.0.0/16
4. Everything else allowed (public internet)

DNS is forced to 1.1.1.1 / 8.8.8.8 so we don't need LAN DNS access.
