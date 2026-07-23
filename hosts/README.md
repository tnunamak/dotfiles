# Per-host configuration tier

Machine-specific config that is **not** universal — hardware-tuned sysctls,
host-only packages/services, desktop-environment-specific bits. Keyed by short
hostname (`hostname -s`) so a fresh machine reproduces *its* environment, not a
one-size-fits-all blob.

Universal config lives in the stow packages (`nvim`, `zsh`, `git`, …) and the
shared install lists in `setup.sh`. This tier is the **disaster-recovery path
for the per-machine extras** — the things that would otherwise live as untracked
local files (`~/.shell_local`, `~/.workstation-issues.json`, root-owned
`/etc/…` edits) and silently vanish on a rebuild.

## Layout

```
hosts/<hostname>/
  host.sh                  # idempotent installer/configurer for this box
  files/                   # host-specific config stowed into $HOME (optional)
  .workstation-issues.json # this box's known-workaround ledger (tracked data)
  RECOVERY.md              # bare-metal rebuild runbook for this machine
```

## How it runs

`setup.sh` runs `hosts/$(hostname -s)/host.sh` at the end, if present and
executable. `host.sh` must be **idempotent** (safe to re-run) — it's executed
on every `setup.sh`, not just first install.

## Disaster recovery

To rebuild a machine from bare OS:
1. Install the base OS (same distro/family the host expects).
2. Clone this repo, run `./setup.sh` (stows universal config + runs `host.sh`).
3. Restore secrets from their out-of-band store (NOT in this repo — see the
   host's `RECOVERY.md`).
4. Restore large non-dotfiles assets (LLM models, VM images) from the NAS — see
   `RECOVERY.md` for the inventory.

`host.sh` may need `sudo` for root-owned config; run `setup.sh` where you can
authenticate, or run `host.sh` directly.

## Secrets

Never commit tokens/keys here. Global shell secrets stay in Infisical; other
machine-local credentials stay in their documented out-of-band stores.
`RECOVERY.md` records *where to restore them from*, not the values.
