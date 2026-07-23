#!/usr/bin/env bash
# Per-host setup for peregrine — Kubuntu 25.10, KDE Plasma 6 / Wayland,
# 124GB RAM, NVMe disk swapfile, local LLM workloads.
#
# Idempotent: safe to re-run (called by setup.sh on every run). Each step checks
# "already done?" before acting. Root-owned changes use sudo; if sudo can't
# authenticate non-interactively the step is skipped with a notice rather than
# failing the whole run.
#
# Scope: the per-machine extras that are NOT universal — an OOM safety net,
# hardware-tuned sysctl, and headless KWallet unlock through password-authenticated
# SSH/TTY sessions. See RECOVERY.md for the bare-metal rebuild runbook and
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
  echo "  Run these once to apply the OOM/sysctl and SSH/KWallet policy:"
  echo "    sudo bash '$HOST_DIR/host.sh' --sudo-steps"
  # Still do the userspace bits below (none currently), then exit cleanly.
fi

# --- The privileged steps, factored so they can run via sudo re-exec too ---
apply_sudo_steps() {
  echo "  [earlyoom] install"
  apt-get install -y earlyoom libpam-kwallet5 >/dev/null || return 1

  echo "  [earlyoom] /etc/default/earlyoom"
  # -M 6291456,4194304 : SIGTERM at 6GiB, SIGKILL at 4GiB free. The earlier
  #   2GiB/1GiB floor was too late for the 2026-06-28 pressure/OOM incidents:
  #   this workstation was already in severe reclaim/PSI trouble above 4GiB
  #   available memory. Keep this as an absolute host-sized floor, not a broad
  #   percentage threshold.
  # -s 100,100         : ignore swap for both TERM and KILL decisions. Full swap
  #   is normal here when it is mostly cold anonymous pages; memory pressure is
  #   the signal we want earlyoom to act on.
  # -r 60              : log enough state for postmortems without being noisy.
  # --prefer only, NO --avoid (kernel oom_score already protects the KDE session)
  cat > /etc/default/earlyoom <<'EOF'
# OOM safety net for this KDE/Wayland workstation (124GB RAM, NVMe disk swap).
# Tracked in dotfiles hosts/peregrine/host.sh. -M 6291456,4194304 = SIGTERM at
# 6GiB / SIGKILL at 4GiB free; -s 100,100 ignores swap for both TERM and KILL
# because full swap is expected on this box; --prefer only, no avoid-list
# (oom_score protects the desktop session).
EARLYOOM_ARGS="-r 60 -M 6291456,4194304 -s 100,100 --prefer '^(brave|chrome|chromium|firefox|electron|node|node-MainThread|claude|codex|npm exec codex-|llama-server|python|python3|Discord)$'"
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

  ensure_pam_line_after() {
    local pam_file="$1"
    local anchor="$2"
    local line="$3"
    local backup="${pam_file}.dotfiles-pre-kwallet"
    local staged

    grep -Fqx -- "$line" "$pam_file" && return 0
    grep -Fqx -- "$anchor" "$pam_file" || {
      echo "  [kwallet] expected anchor missing in $pam_file: $anchor" >&2
      return 1
    }

    if [[ ! -e "$backup" ]]; then
      cp -a -- "$pam_file" "$backup" || return 1
    fi
    staged="$(mktemp)"
    awk -v anchor="$anchor" -v line="$line" '
      { print }
      $0 == anchor { print line }
    ' "$pam_file" > "$staged"
    grep -Fqx -- "$line" "$staged" || {
      rm -f -- "$staged"
      echo "  [kwallet] failed to stage $pam_file" >&2
      return 1
    }
    install -m 0644 "$staged" "$pam_file"
    rm -f -- "$staged"
  }

  echo "  [kwallet] enable password handoff for SSH and TTY"
  ensure_pam_line_after \
    /etc/pam.d/sshd \
    '@include common-auth' \
    '-auth   optional        pam_kwallet5.so' || return 1
  ensure_pam_line_after \
    /etc/pam.d/sshd \
    '@include common-session' \
    '-session optional       pam_kwallet5.so auto_start force_run' || return 1
  ensure_pam_line_after \
    /etc/pam.d/login \
    '@include common-auth' \
    '-auth   optional        pam_kwallet5.so' || return 1
  ensure_pam_line_after \
    /etc/pam.d/login \
    '@include common-session' \
    '-session optional       pam_kwallet5.so auto_start force_run' || return 1

  echo "  [sshd] require authorized key + PAM password for tnunamak"
  local sshd_dropin=/etc/ssh/sshd_config.d/10-tnunamak-kwallet.conf
  local sshd_rollback
  sshd_rollback="$(mktemp)"
  if [[ -f "$sshd_dropin" ]]; then
    cp -- "$sshd_dropin" "$sshd_rollback"
  else
    : > "$sshd_rollback"
  fi
  install -D -m 0644 "$HOST_DIR/10-tnunamak-kwallet.conf" "$sshd_dropin" || {
    rm -f -- "$sshd_rollback"
    return 1
  }
  if ! /usr/sbin/sshd -t; then
    if [[ -s "$sshd_rollback" ]]; then
      install -m 0644 "$sshd_rollback" "$sshd_dropin"
    else
      rm -f -- "$sshd_dropin"
    fi
    rm -f -- "$sshd_rollback"
    echo "  [sshd] invalid configuration; restored previous state" >&2
    return 1
  fi
  rm -f -- "$sshd_rollback"
  if systemctl is-active --quiet ssh.service; then
    systemctl reload ssh.service || return 1
  fi

  echo "  done: earlyoom=$(systemctl is-active earlyoom) swappiness=$(cat /proc/sys/vm/swappiness) ssh=$(systemctl is-active ssh.service)"
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
  echo "  host.sh(peregrine): applying OOM/sysctl and SSH/KWallet policy"
  sudo bash "${BASH_SOURCE[0]}" --sudo-steps
fi

exit 0
