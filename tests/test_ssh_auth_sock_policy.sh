#!/usr/bin/env bash
# Static regression gate for the configuration that selects plain ssh-agent
# over gcr-ssh-agent as this host's SSH_AUTH_SOCK provider.
#
# Sibling policy: tests/test_peregrine_secret_service_policy.sh picks KWallet
# over GNOME Keyring for org.freedesktop.secrets. Same fight, other half.
#
# NOT covered: whether environment.d actually wins the login-time election
# against gcr-ssh-agent.socket's ExecStartPost. That needs a Plasma session
# with gcr installed and PAM login; the Docker harness has systemd but no
# display manager. Verify by hand after a real logout/login.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_CONF="$ROOT/shell/.config/environment.d/10-ssh-auth-sock.conf"
GCR_DROPIN="$ROOT/shell/.config/systemd/user/gcr-ssh-agent.socket.d/10-no-ssh-auth-sock.conf"
SHELL_CONFIG="$ROOT/shell/.shell_config"
SETUP="$ROOT/setup.sh"
STATUS_REFRESH="$ROOT/bin/.local/bin/shell-status-refresh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# The agent is pinned to plain OpenSSH, not gcr. Three user socket units race
# to set SSH_AUTH_SOCK (ssh-agent -> gcr -> gpg-agent-ssh, last writer wins);
# gcr beats ssh-agent by default even on KDE, so the choice must be explicit.
grep -Fqx 'SSH_AUTH_SOCK=${XDG_RUNTIME_DIR}/openssh_agent' "$ENV_CONF" \
  || fail "environment.d must pin SSH_AUTH_SOCK to \${XDG_RUNTIME_DIR}/openssh_agent"
! grep -Eq '^SSH_AUTH_SOCK=.*gcr' "$ENV_CONF" \
  || fail "environment.d must not point SSH_AUTH_SOCK at gcr"

# environment.d alone loses: the generator runs at user-manager start, but
# gcr-ssh-agent.socket's ExecStartPost fires later at socket activation and
# overwrites SSH_AUTH_SOCK. The drop-in must clear it. Verified live —
# without this, restarting the socket flips openssh_agent back to gcr/ssh.
grep -Fqx '[Socket]' "$GCR_DROPIN" \
  || fail "gcr drop-in must carry a [Socket] section"
grep -Fqx 'ExecStartPost=' "$GCR_DROPIN" \
  || fail "gcr drop-in must clear ExecStartPost (bare 'ExecStartPost=')"
! grep -Eq '^ExecStartPost=.+' "$GCR_DROPIN" \
  || fail "gcr drop-in must not re-add an ExecStartPost command"

# The shell must not spawn or elect an agent. Doing so makes it a fourth
# competitor to the socket units: interactive shells see a different agent
# (holding a different key set) than everything else, which surfaces as an
# intermittent "Git SSH signing key is unavailable" warning.
! grep -Eq '^[^#]*ssh-agent -s' "$SHELL_CONFIG" \
  || fail "shell config must not spawn its own ssh-agent"
! grep -Eq '^[^#]*(export )?SSH_AUTH_SOCK=' "$SHELL_CONFIG" \
  || fail "shell config must not assign SSH_AUTH_SOCK (environment.d owns it)"

# Stow must not fold ~/.config/environment.d. Folding symlinks the whole
# directory into the repo and orphans untracked local files (e.g. kwin-drm.conf).
grep -Eq '^NO_FOLD_PKGS=\(.*[( ]shell[) ]' "$SETUP" \
  || fail "setup.sh must list 'shell' in NO_FOLD_PKGS"

# The signing check must test the PRIVATE KEY FILE, not ssh-agent membership.
# ssh-keygen -Y sign reads ~/.ssh/id_ed25519 directly, so an agent-membership
# test both fires spuriously on a fresh boot (agent starts empty) and misses
# the real failure (key gone or passphrased).
! grep -q 'ssh-add -l .*git_signing_fingerprint' "$STATUS_REFRESH" \
  || fail "signing check must not test ssh-agent membership"
grep -Fq 'git_signing_key="$HOME/.ssh/id_ed25519"' "$STATUS_REFRESH" \
  || fail "signing check must reference the private key file"

# Every signing alert must carry a runnable command after the '|' — an empty
# right-hand field prints a warning with no way to act on it.
while IFS= read -r line; do
  case "$line" in
    *'|'*) ;;
    *) fail "signing alert has no '|' separator: $line" ;;
  esac
  rhs="${line##*|}"
  rhs="${rhs%\"*}"
  [[ -n "${rhs// }" ]] || fail "signing alert has an empty command field: $line"
done < <(grep -F 'lines+=("Git SSH signing key' "$STATUS_REFRESH")

grep -cF 'lines+=("Git SSH signing key' "$STATUS_REFRESH" | grep -qE '^[1-9]' \
  || fail "shell-status-refresh lost its signing-key check"

bash -n "$STATUS_REFRESH"
bash -n "$SHELL_CONFIG"

echo 'PASS: SSH_AUTH_SOCK policy selects plain ssh-agent and the shell does not compete'
