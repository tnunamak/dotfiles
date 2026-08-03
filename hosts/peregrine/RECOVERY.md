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
- Infisical `personal-dev/dev` (global shell secrets). **Both steps:**
  1. Create a per-host machine identity in the Infisical UI (`personal-dev` →
     Access Control → Identities), role Viewer, auth method Universal Auth.
     Write its credentials to `~/.config/infisical/machine-identity.env`,
     chmod 600:
     ```
     INFISICAL_UNIVERSAL_AUTH_CLIENT_ID=<uuid>
     INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET=<secret, shown once>
     ```
     This is the fast path; without it every shell falls back to the ~20s
     keyring retry loop.
  2. `infisical login` — populates the KWallet session. Required even with a
     machine identity, because only the user-login path writes the CLI's
     encrypted outage cache (see the Infisical offline-cache research note).
     Expires ~14d and does not refresh on use; the shell nags when it lapses.
- `~/sandbox/.coolify-token`
- `~/sandbox/garage-credentials.txt`

## Known per-host workarounds

Tracked in `~/.workstation-issues.json` (seeded from this dir on first run). The
shell startup status surfaces them and flags when their upstream bug is fixed.
Current: OOM safety net (earlyoom `-M 6291456,4194304 -s 100,100`) +
`vm.swappiness=80` (revisit ~2026-07-13 against
`~/.cache/swap-tuning-baseline/`); Brave webcam/Wayland white-screen.

`host.sh` also configures the deliberate headless-wallet login policy:

- SDDM autologin leaves KWallet locked.
- TTY password login unlocks KWallet through PAM.
- SSH for `tnunamak` requires an authorized key and the account password via
  `AuthenticationMethods publickey,password`; PAM unlocks KWallet with
  `force_run`, and `.shell_config` completes the handoff before tmux attaches.
- The `bin` Stow package makes KDE's `ksecretd` the standard Secret Service
  provider in three complementary places: its per-user D-Bus activation
  override, a systemd drop-in that retains GNOME Keyring's independent PKCS#11
  component but removes its `secrets` component, and a user autostart override
  that hides GNOME's separate Secret Service entry. The D-Bus override alone
  cannot beat an already-running GNOME Keyring process. This prevents
  applications such as Infisical from silently creating a second credential
  store in GNOME Keyring.
- After `./setup.sh`, start a new user session (log out/in or reboot) before
  testing. `secret-service-provider` performs a value-blind D-Bus Ping and
  confirms that `/usr/bin/ksecretd` owns `org.freedesktop.secrets`.
- Infisical uses its `auto` vault backend, so its login credential lives behind
  KWallet while its encrypted project-secret cache remains available offline.
  `auto` is not fail-closed: Infisical can recreate its encrypted file vault
  after a system-keyring write failure. Strict KWallet-only behavior requires
  upstream support; see the Infisical offline-cache research note.
- Since 2026-08-02 the shell's *primary* secret path is a machine identity,
  which talks to Infisical directly and never touches the Secret Service. So a
  wedged or locked KWallet no longer costs a shell its secrets — it only stops
  the user-login session from refreshing, which in turn stops the offline cache
  from being updated. The KWallet apparatus above still matters, but it is now
  a durability concern (outage cache freshness) rather than an availability one
  (shell startup).

The SSH rule lives in `/etc/ssh/sshd_config.d/10-tnunamak-kwallet.conf`.
The installer keeps one-time pre-change backups at
`/etc/pam.d/{sshd,login}.dotfiles-pre-kwallet`. To roll back, remove the SSH
drop-in, restore those two backups, validate with `sudo sshd -t`, and reload
`ssh.service`.

## Tuning the OOM floor when your workload changes

The earlyoom floor (`-M 6291456,4194304` = 6GiB SIGTERM / 4GiB SIGKILL in
`host.sh`) is the one value tied to a *workload assumption*, not a fixed fact.
It was raised from 2GiB/1GiB after the 2026-06-28 pressure/OOM incidents showed
this workstation could already be in severe reclaim/PSI trouble above 4GiB
available memory. See `MEMORY-OOM-2026-06-28.md` for the incident evidence and
recheck commands.

This host intentionally uses `-s 100,100`: full swap by itself is normal here
when it is mostly cold anonymous pages. Treat memory pressure and kernel OOMs as
the signal, not "swap is full".

**Raise the floor** (e.g. `-M 8388608,6291456` = 8GiB/6GiB) if:
- you load much larger / multiple-simultaneous models, or a newer inference
  engine commits weights faster,
- you add RAM / faster RAM / more memory channels,
- you add a new fast-allocating workload (big in-memory DB, large tensor/video
  buffers, ballooning VMs).

**The concrete trigger to act:** a memory freeze *and* a kernel OOM-killer entry
(`journalctl -k -b | grep -i "Out of memory"`). That means earlyoom was outrun.
The shell startup status surfaces this automatically ("Kernel OOM-killer fired …").
When you see it: bump the two numbers in `host.sh`, re-run
`sudo bash hosts/peregrine/host.sh --sudo-steps`. You do NOT pre-tune; you react
to that one signal.

## Drift detection

Per-host state drifts as you `apt install` things ad-hoc or hand-edit `/etc`.
`setup.sh`'s package lists + this `host.sh` are the source of truth; to find
what's installed-but-untracked, compare `apt-mark showmanual` against the lists.
(A `host-snapshot` helper to automate this is a planned follow-up.)
