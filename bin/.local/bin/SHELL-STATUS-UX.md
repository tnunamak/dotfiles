# shell-status-refresh UX Design

## Principle

Every line in the glance answers "do I need to do something, and what?"

## Hierarchy

### Level 1: Alerts (0-2 lines, conditional)

Problems, not updates. Only shown when thresholds are exceeded.

**Disk alert** — one line when disk >= 75% OR > 5GB reclaimable:
```
Disk 67%  ~42G reclaimable           cleanup-check --clean
```

**Workstation issues** — 0-1 lines from `workstation-issues --check-upstream`.

### Level 2: Updates (0-1 lines)

Three segments, each omitted when zero:
```
Updates: 3 outdated tools  5 managers (40 pkgs)  14 repos behind
```

| Segment | Source | Action implied |
|---------|--------|----------------|
| N outdated tools | individual_tools checks | Run N different upgrade commands |
| N managers (M pkgs) | simple_bulk_managers + python_managers + cargo | Run N bulk upgrade commands |
| N repos behind | ~/applications git repos | FYI, no action needed |

## Detail view (`shell-status-refresh details`)

Full categorized breakdown:

```
Disk: 67%
  Reclaimable (~42G):
    docker system prune -af: 41.8G
  Manual:
    Conda envs: 27.7G              conda env list

Outdated tools:
  bun 1.2.19 → 1.3.10              bun upgrade
  rustc 1.93.1 → 1.94.0            rustup update

Package managers:
  flatpak 15 package(s)            flatpak update
  npm globals 4 package(s)         npm outdated -g && npm update -g

  npm globals:
    @devcontainers/cli 0.83.3 → 0.84.0
  pip --user:
    fastmcp 2.12.5 → 3.1.0

~/applications (14 repos behind):
  ai-toolkit (11 commits behind)
  ComfyUI v0.15.0 → v0.16.4 (97 commits)
```
