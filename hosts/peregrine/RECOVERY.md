# peregrine — bare-metal recovery runbook

Workstation: Kubuntu 25.10, KDE Plasma 6 / Wayland, 124 GB RAM, NVMe (Samsung
980 PRO 2TB), dual RTX 3090, local AI stack (LLMs, image gen, STT/TTS).

This is the "disk exploded, rebuild faithfully" procedure. It assumes your data
is on the NAS and this repo is intact.

## Tiers of state (what's captured where)

| Tier | What | Where it's restored from |
|------|------|--------------------------|
| 1 | Universal dotfiles (shell, nvim, git, …) | this repo via stow (`setup.sh`) |
| 1 | Declared packages (apt/brew base lists) | `setup.sh` |
| 2 | Per-host extras (OOM daemon, sysctls) | `hosts/peregrine/host.sh` (run by `setup.sh`) |
| 3 | Big non-dotfiles assets (models, VMs) | **NAS** — see Inventory below |
| 3 | Secrets/tokens | out-of-band store — see Secrets below |
| 3 | App service repos under `~/applications` | git remotes / NAS — see Inventory |

## Procedure

1. **Install base OS:** Kubuntu 25.10 (KDE/Wayland). Match the family so
   `host.sh`'s apt/systemd assumptions hold.
2. **Clone + run dotfiles:**
   ```bash
   git clone <this-repo> ~/code/dotfiles && cd ~/code/dotfiles && ./setup.sh
   ```
   This stows universal config and runs `hosts/peregrine/host.sh` (installs
   earlyoom + the OOM safety net + `vm.swappiness=80`). If sudo can't auth during
   `setup.sh`, run the privileged steps directly:
   `sudo bash hosts/peregrine/host.sh --sudo-steps`.
3. **GPU drivers:** install the NVIDIA driver for the dual 3090s (not handled by
   dotfiles). Confirm `nvidia-smi` sees both cards.
4. **Restore secrets** (see below).
5. **Restore large assets from NAS** (see Inventory) — do this before starting
   the AI services, or they'll fail to load models.
6. **Re-enable the AI stack** — the systemd --user services below.

## Inventory — large non-dotfiles assets (the 200GB+ recovery hole)

These are NOT in the repo. Confirm they are on the NAS (or have a re-download
plan) BEFORE trusting this recovery:

- **`/media/windows/AI Models` — ~385 GB.** The bulk of the LLM/image models.
  This is the single biggest recovery dependency. **TODO: confirm this is backed
  up to NAS** — if it's only on local disk, a disk failure loses it.
- **`~/applications` — ~113 GB.** App service repos + their venvs/build trees +
  per-app `models/` (parakeet-stt ~640M, beellama/llama-* ~75M each). Most are
  git clones (re-cloneable) but venvs/built engines and any pinned model weights
  are not. Note: `llama-tq-mtp` is pinned at a specific ref (see global memory) —
  don't bump on rebuild.

## systemd --user services to re-enable (the AI stack)

```
comfyui.service          openai-proxy.service     llama-bee.service
llama-turbo.service      playwright-mcp.service   daisy.service
tabbyapi-watchdog.timer  tmux.service             tmux-restore.service
```
(`tmux*` are handled by the `tmux` stow package + setup.sh. The AI services live
under `~/applications/*/` and need their repos + models restored first.)

## Secrets (referenced, never committed)

Restore these from your out-of-band store / NAS — values are NOT in this repo:
- `~/.shell_secrets` (PDPP owner token, etc.)
- `~/sandbox/.coolify-token`
- `~/sandbox/garage-credentials.txt`

## Known per-host workarounds

Tracked in `~/.workstation-issues.json` (seeded from this dir on first run). The
shell startup status surfaces them and flags when their upstream bug is fixed.
Current: OOM safety net (earlyoom) + `vm.swappiness=80` (revisit ~2026-07-13
against `~/.cache/swap-tuning-baseline/`); Brave webcam/Wayland white-screen.

## Drift detection

Per-host state drifts as you `apt install` things ad-hoc or hand-edit `/etc`.
`setup.sh`'s package lists + this `host.sh` are the source of truth; to find
what's installed-but-untracked, compare `apt-mark showmanual` against the lists.
(A `host-snapshot` helper to automate this is a planned follow-up.)
