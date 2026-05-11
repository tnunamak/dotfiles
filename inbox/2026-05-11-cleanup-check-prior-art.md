# Disk Cleanup Checker: Prior Art Research

**Date:** May 11, 2026  
**Research focus:** UX patterns, safety models, and categorization from world-class Linux cleanup tools

---

## Executive Summary

Three primary improvements emerge from analysis of industry tools:

1. **Dry-run + explicit confirmation** is the universal safety pattern. Docker, HuggingFace, and interactive tools (npkill, dust) all preview deletions before execution.
2. **Tiered deletion** for risky categories (Docker: dangling → containers → images, not `-af` all-in-one) reduces user error and aligns with how experienced DevOps engineers actually work.
3. **Recency metadata** (last modified time, age thresholds) outperforms simple cache-expiry. npkill shows workspace age; Docker/HF support `--filter "until=Xh"` patterns; recommended for node_modules, pip cache.

---

## By Category: Prior Art & Recommendations

### Docker (`docker system prune` behavior)

**Current tool approach:** Uses `docker system prune -af` (force-deletes everything in one command).

**Prior art findings:**

- **Official Docker recommendation** ([Docker Docs](https://docs.docker.com/config/pruning/)): All `prune` commands default to **interactive confirmation**. The `-f` flag exists to bypass prompts in CI, not for developer workstations.
- **Tiered strategy in practice:**
  - `docker image prune` (dangling images only) — safest entry point
  - `docker container prune` (stopped containers) — common, safe
  - `docker buildx prune` (build cache) — moderate risk
  - `docker system prune --volumes` (everything + volumes) — highest risk; rarely recommended without `--filter`
- **Safety model:** Each command prompts with explicit list of what will be deleted. Users can review before confirming.
- **Filtering:** All commands support `--filter "until=24h"` to exclude recent items.

**Assessment:** `-af` is inappropriate for a monitoring tool. This is an automation flag for CI pipelines, not developer UX.

**Recommendation for cleanup-check (P0):** Split Docker into multiple tiers with confirmation:
```
Tier 1: docker image prune (dangling only) — auto-executable after confirmation
Tier 2: docker container prune (stopped) — requires interactive review
Tier 3: docker buildx prune (builder cache) — off by default, requires explicit opt-in
Tier 4: docker system prune --volumes — never auto-execute; report only
```

---

### Node Modules (`npkill` behavior)

**Current approach:** Reports old node_modules (>6mo by fixed timestamp).

**Prior art findings:**

- **npkill** ([GitHub](https://github.com/voidcosmos/npkill)): Displays **last_mod** column showing when files were last modified in the workspace. Multi-select mode allows manual curation before deletion.
- **Recency heuristic:** Last modification time > age of directory itself. More accurate than "created 6 months ago."
- **UX model:** Interactive listing with selection, then `Enter` to confirm batch delete (no implicit deletion).

**Assessment:** 6-month threshold is arbitrary; file recency in the workspace is a better signal.

**Recommendation for cleanup-check (P1):**
- Report `node_modules` with both age AND last modification timestamp (find `-mtime +180 -printf '%T@ %p\n'` sorted)
- In `--clean` mode, require explicit opt-in per directory (or a `--force-node-modules` flag)
- Consider excluding `node_modules` from automatic `--clean` execution; show warning instead

---

### HuggingFace Cache (`scan-cache` / `hf cache prune` behavior)

**Prior art findings:**

- **Official HF approach** ([HuggingFace Cache Guide](https://huggingface.co/docs/huggingface_hub/en/guides/manage-cache)):
  - `hf cache scan` lists all cached revisions with metadata (repo, size, revision ID, status like "detached" or "refs/pr/1")
  - `hf cache prune` identifies **unreferenced revisions** (detached or PR refs) and shows them before deletion
  - All commands support `--dry-run` and `--yes` for automation
  - CLI shows: "About to delete 3 unreferenced revision(s) (2.4G total)" with explicit list, then "Proceed? [y/N]:"
- **Safety model:** Detached revisions are semantically safe to delete (no active symlinks); other revisions require explicit listing
- **No TTL in CLI**, but Python API supports `delete_revisions()` with strategy planning

**Assessment:** HF's pattern is excellent: identify semantic safety (unreferenced), preview, confirm.

**Recommendation for cleanup-check (P0):**
- Implement separate detection: "unreferenced revisions" (true candidates for deletion) vs. "cached revisions" (candidates with conditions)
- Show: `hf cache scan | grep -E "detached|\[(unused)\]"` with size breakdown
- Require explicit `--clean` confirmation with `--yes` override for automation
- Store scan results for 1h cache (current behavior is good)

---

### Pip / Conda / Npm Caches

**Prior art findings:**

- **Pip cache** (`~/.cache/pip`): Generally safe to delete. `pip cache purge` (PEP 600+) removes all; no age filtering in CLI.
- **Conda cache** (`~/miniconda3/pkgs`): Also safe; `conda clean --all` removes; caches don't persist package state.
- **Npm cache** (`~/.npm`): Safe to delete; `npm cache clean --force` is standard.
- **Cargo cache** (`~/.cargo/registry`): Safe to delete; crates will be re-downloaded if needed.
- **Yarn cache** (`~/.yarn/cache`): Safe to delete; `yarn cache clean` available.

**Common pattern:** Package manager caches are **safe** because package managers re-download transparently. No "detached" or "stale" detection needed; full purge is acceptable after user confirmation.

**Assessment:** No sophisticated heuristics needed here. User concern is disk space, not data loss.

**Recommendation for cleanup-check (P0):**
- Report total cache size per manager (pip, conda, npm, cargo, yarn if present)
- Group under "Safe Caches" — confirmation per cache, not per file
- Example: "Pip cache: 1.2GB. Clear? [y/N]"

---

### Old `node_modules` Directories (>6mo)

**Prior art findings:**

- **npkill** shows modification time, not just directory creation
- **Community practice** (from various dotfiles): Heuristics vary; some repos track "last_mod" in version control
- **No standard tool** does automatic cleanup of old node_modules without user review

**Assessment:** Fixed 6-month threshold is reasonable as a starting heuristic, but showing modification time adds context.

**Recommendation for cleanup-check (P1):**
- Show: `find . -type d -name node_modules -mtime +180 -printf '%TY-%Tm-%Td %p %s\n'` (date + path + size)
- Display human-readable "Last modified: N days ago"
- Require confirmation per directory or a blanket `--force-node-modules` flag

---

### Docker Volumes & Devcontainer Homes

**Current approach:** Manual-only suggestions (correct for safety).

**Prior art findings:**

- **Docker volumes:** No first-party cleanup guidance beyond `docker volume prune` (removes unused volumes). No age detection in Docker.
- **Devcontainer homes:** Not a standard cleanup target; environment-specific. No community standard.

**Assessment:** Correct to keep as manual-only. These are not reclaimable without understanding user intent.

**Recommendation for cleanup-check (P2):**
- Keep as report-only
- Improve prompt: "Docker volumes not used in past 30 days: X.XGB (estimate)."
- Devcontainer suggestion stays informational only

---

### Steam Games

**Current approach:** Manual-only suggestions.

**Prior art findings:**

- No integration in system cleanup tools
- Outside the scope of developer workstation tooling

**Assessment:** Appropriate to exclude or keep minimal.

**Recommendation for cleanup-check (P2):**
- Remove from cleanup-check scope, or demote to optional flag `--include-games`

---

## Dry-Run & Auto-Execution UX Patterns

All industry tools follow a consistent model:

1. **Default mode (interactive):** Show what will be deleted, require confirmation
2. **Dry-run flag (`--dry-run`):** Preview without execution
3. **Force flag (`--yes` or `-f`):** Skip confirmation (for CI/automation only)

Examples:

```bash
# Docker
$ docker image prune -a --filter "until=24h"
WARNING! This will remove all images without at least one container...
Are you sure you want to continue? [y/N]

# HuggingFace
$ hf cache prune --dry-run          # Preview only
$ hf cache prune --yes              # Skip confirmation
$ hf cache prune                    # Interactive

# npkill
# Interactive mode only; selection = intentional deletion
```

**Current cleanup-check approach:** `--clean` executes all with no per-category prompts.

**Recommendation (P0):** Introduce `--preview` (dry-run equivalent) as default for `--clean`:
```bash
cleanup-check --clean --preview     # Show what would be deleted (1h cache)
cleanup-check --clean --yes         # Execute all (no prompts)
cleanup-check --clean --docker-tier-1  # Execute only safe category
```

---

## Cache TTL & Polling

**Current cleanup-check:** 1h cache with `--clean` action. No background rescan.

**Prior art findings:**

- **Docker:** No background rescan; user-driven `prune` commands
- **HuggingFace:** CLI is user-driven; Python SDK supports programmatic deletion
- **npkill:** On-demand scan; no daemon
- **Dust/ncdu:** On-demand interactive scan

**Assessment:** On-demand model is dominant. No industry tool implements background monitoring of disk usage.

**Recommendation for cleanup-check (P1):**
- Keep 1h cache for reports shown during shell initialization
- Optional: Add `cleanup-check --daemon` for continuous monitoring (writes to syslog), but keep manual execution the default

---

## Ranked Recommendations

### P0 (Do Now)

1. **Split Docker into safety tiers.** Remove `-af` automatic execution. Require confirmation for each tier (dangling → containers → builder cache).
2. **Introduce dry-run mode.** Add `--preview` flag to show deletion plan without execution. Keep `--yes` for automation.
3. **HuggingFace cache:** Use `hf cache scan` to identify unreferenced revisions, display in preview, require confirmation.
4. **Pip/Conda/Npm/Cargo/Yarn:** Add per-cache confirmation prompts instead of batch deletion.

### P1 (Worth Doing)

1. **Node_modules recency metadata:** Show last modification time alongside age. Reduce auto-deletion, require confirmation per directory.
2. **Improve heuristics:** Use `find -mtime`, `-mmin` for true recency instead of fixed 6-month threshold.
3. **Category-level opt-in:** Allow `cleanup-check --clean --skip-node-modules` to exclude high-impact categories.

### P2 (Nice to Have)

1. **Color-coded risk levels:** Green (safe: caches) → Yellow (moderate: old node_modules) → Red (risky: docker volumes).
2. **Statistical summary:** "Last run: 2 hours ago. Reclaimed: 3.2GB. Categories: pip, npm, docker images."
3. **Integration with shell prompt:** Display warning badge if >50GB reclaimable.

---

## Citations

- [Docker Pruning Docs](https://docs.docker.com/config/pruning/) — Official tiered prune strategy and confirmation patterns
- [HuggingFace Cache Management](https://huggingface.co/docs/huggingface_hub/en/guides/manage-cache) — Scan/prune with dry-run, delete strategies
- [npkill GitHub](https://github.com/voidcosmos/npkill) — Interactive node_modules cleanup with last_mod metadata
- [Dust GitHub](https://github.com/bootandy/dust) — Recursive disk usage visualization, interactive deletion
- Mathias Bynens Dotfiles — Standard dotfiles patterns (bootstrap, no cleanup-specific guidance)

---

## Conclusion

The industry converges on **preview + confirmation** as the safety default, with tiered deletion for risky operations. `cleanup-check --clean` should mirror this pattern: show what will be deleted, allow per-category opt-in, and require confirmation unless `--yes` is explicitly provided. HuggingFace's semantic detection (unreferenced revisions) and Docker's tier-based approach are the most sophisticated models and worth adopting.
