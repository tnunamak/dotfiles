#!/usr/bin/env bash
# Per-host setup for peregrine — Kubuntu 25.10, KDE Plasma 6 / Wayland,
# 124GB RAM, NVMe disk swapfile, local LLM workloads.
#
# Idempotent: safe to re-run (called by setup.sh on every run). Each step checks
# "already done?" before acting. Root-owned changes use sudo; if sudo can't
# authenticate non-interactively the step is skipped with a notice rather than
# failing the whole run.
#
# Scope: the per-machine extras that are NOT universal — an OOM safety net and a
# hardware-tuned sysctl. See RECOVERY.md for the bare-metal rebuild runbook and
# ~/.workstation-issues.json (seeded from this dir) for the workaround ledger.
set -uo pipefail

HOST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Only meaningful on Linux with apt + systemd. Bail cleanly elsewhere.
if [[ "$(uname)" != "Linux" ]] || ! command -v apt-get &>/dev/null; then
  echo "  host.sh(peregrine): not an apt/Linux host — skipping OOM/sysctl steps"
  exit 0
fi

# Helper: run a sudo command, but skip (don't fail) if we can't get root
# non-interactively. Returns 0 if it ran or was already satisfied.
have_sudo() { sudo -n true 2>/dev/null; }

if ! have_sudo; then
  echo "  host.sh(peregrine): sudo not available non-interactively."
  echo "  Run these once to apply the OOM safety net + sysctl:"
  echo "    sudo bash '$HOST_DIR/host.sh' --sudo-steps"
  # Still do the userspace bits below (none currently), then exit cleanly.
fi

# --- The privileged steps, factored so they can run via sudo re-exec too ---
apply_sudo_steps() {
  echo "  [earlyoom] install"
  apt-get install -y earlyoom >/dev/null

  echo "  [earlyoom] /etc/default/earlyoom"
  # -M 2097152,1048576 : SIGTERM at 2GiB, SIGKILL at 1GiB free. On 124GB the
  #   absolute floors govern (lower-of -m/-M wins, per manpage). The 1GiB SIGKILL
  #   floor is sized from earlyoom's 100ms poll + 6 GiB/s measured fill rate:
  #   break-even 10.2 GiB/s, above any single-process committed rate, covers the
  #   mmap(MAP_POPULATE) burst of loading large LLM weights. 512MiB (the -M/2
  #   default of a 1GiB floor) would be outrun by earlyoom's own benchmark.
  # -m 4               : percentage backstop if RAM ever grows (absolute dominates now)
  # -s 100             : ignore swap trigger (swap chronically ~full of cold pages)
  # --prefer only, NO --avoid (kernel oom_score already protects the KDE session)
  cat > /etc/default/earlyoom <<'EOF'
# OOM safety net for this KDE/Wayland workstation (124GB RAM, NVMe disk swap).
# Tracked in dotfiles hosts/peregrine/host.sh. -M 2097152,1048576 = SIGTERM at
# 2GiB / SIGKILL at 1GiB free (1GiB floor beats earlyoom's 100ms-poll x 6GiB/s
# fill rate, covers LLM-weight mmap bursts); -s 100 ignores full swap; -m 4 is a
# percentage backstop; --prefer only, no avoid-list (oom_score protects session).
EARLYOOM_ARGS="-r 3600 -m 4 -M 2097152,1048576 -s 100 --prefer '(brave|chrome|chromium|firefox|electron|node|llama-server|python|Discord)$'"
EOF

  echo "  [sysctl] vm.swappiness=80"
  # This host: ~67x more file-cache refaults than anon swaps; swap+FS on the same
  # NVMe (equal IO cost -> kernel formula favors ~100). Baseline in
  # ~/.cache/swap-tuning-baseline/. Revisit ~2026-07-13.
  cat > /etc/sysctl.d/99-vm-swappiness.conf <<'EOF'
vm.swappiness=80
EOF
  sysctl -p /etc/sysctl.d/99-vm-swappiness.conf >/dev/null

  echo "  [earlyoom] enable + (re)start to pick up config"
  systemctl enable earlyoom >/dev/null 2>&1
  # restart (not just `enable --now`): apt may have started the unit with default
  # args before our config landed; `enable --now` won't restart a running unit.
  systemctl restart earlyoom >/dev/null 2>&1

  echo "  done: earlyoom=$(systemctl is-active earlyoom) swappiness=$(cat /proc/sys/vm/swappiness)"
}

# Allow `sudo bash host.sh --sudo-steps` to run just the privileged part.
if [[ "${1:-}" == "--sudo-steps" ]]; then
  if [[ $EUID -ne 0 ]]; then echo "  --sudo-steps requires root" >&2; exit 1; fi
  apply_sudo_steps
  exit 0
fi

# Seed this host's workstation-issues ledger on a fresh machine. The live file
# (~/.workstation-issues.json) is machine-local/untracked; this tracked copy is
# the recovery seed. Only seed if the live file is missing or empty (don't
# clobber entries added since the last commit).
LEDGER_SRC="$HOST_DIR/workstation-issues.json"
LEDGER_DST="$HOME/.workstation-issues.json"
if [[ -f "$LEDGER_SRC" ]]; then
  if [[ ! -f "$LEDGER_DST" ]] || [[ "$(jq '.issues | length' "$LEDGER_DST" 2>/dev/null || echo 0)" == "0" ]]; then
    cp "$LEDGER_SRC" "$LEDGER_DST"
    echo "  host.sh(peregrine): seeded ~/.workstation-issues.json from tracked copy"
  fi
fi

if have_sudo; then
  echo "  host.sh(peregrine): applying OOM safety net + sysctl"
  sudo bash "${BASH_SOURCE[0]}" --sudo-steps
fi

exit 0
