#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# Detect interactive terminal
INTERACTIVE=false
[[ -t 0 ]] && INTERACTIVE=true

prompt() {
  local var=$1 prompt_text=$2 default=$3
  if $INTERACTIVE; then
    read -rp "$prompt_text [$default]: " input
    printf -v "$var" '%s' "${input:-$default}"
  else
    printf -v "$var" '%s' "$default"
  fi
}

# --- Stow ---

PACKAGES=(nvim zsh bash shell kitty starship git claude bin)

if ! command -v stow &>/dev/null; then
  echo "Error: GNU Stow not found. Run the platform setup script first."
  exit 1
fi

echo "Stowing packages: ${PACKAGES[*]}"
for pkg in "${PACKAGES[@]}"; do
  stow -d "$DOTFILES_DIR" -t "$HOME" --restow "$pkg"
done

# --- Zsh plugins ---

ZSH_PLUGINS=~/.zsh/plugins
mkdir -p "$ZSH_PLUGINS"
clone_if_missing() {
  local repo=$1 dest=$2
  if [[ ! -d "$dest" ]]; then
    echo "Cloning $repo"
    git clone --depth 1 "$repo" "$dest"
  fi
}
clone_if_missing https://github.com/zsh-users/zsh-autosuggestions "$ZSH_PLUGINS/zsh-autosuggestions"
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_PLUGINS/zsh-syntax-highlighting"

# --- Local config setup ---

touch ~/.shell_local
touch ~/.shell_secrets
mkdir -p ~/.claude
touch ~/.claude/CLAUDE.local.md

# Git local config (only on first run)
if [[ ! -f ~/.gitconfig.local ]]; then
  echo ""
  echo "Setting up git identity..."

  prompt GIT_NAME "Name" "$(git config --global user.name 2>/dev/null || echo "")"
  prompt GIT_EMAIL "Email" "$(git config --global user.email 2>/dev/null || echo "")"

  # Pick signing key
  SIGNING_KEY=""
  mapfile -t PUBKEYS < <(ls ~/.ssh/*.pub 2>/dev/null)
  if [[ ${#PUBKEYS[@]} -gt 0 ]]; then
    echo "Available SSH keys:"
    for i in "${!PUBKEYS[@]}"; do
      echo "  $((i+1))) ${PUBKEYS[$i]}"
    done
    if $INTERACTIVE; then
      read -rp "Signing key [1]: " key_choice
      key_idx=$(( ${key_choice:-1} - 1 ))
      if [[ $key_idx -ge 0 && $key_idx -lt ${#PUBKEYS[@]} ]]; then
        SIGNING_KEY="${PUBKEYS[$key_idx]}"
      else
        SIGNING_KEY="${PUBKEYS[0]}"
      fi
    else
      # Non-interactive: prefer ed25519, fall back to first key
      for k in "${PUBKEYS[@]}"; do
        [[ "$k" == *ed25519* ]] && SIGNING_KEY="$k" && break
      done
      [[ -z "$SIGNING_KEY" ]] && SIGNING_KEY="${PUBKEYS[0]}"
    fi
  fi

  cat > ~/.gitconfig.local <<GITEOF
[user]
	name = $GIT_NAME
	email = $GIT_EMAIL
	signingkey = $SIGNING_KEY
GITEOF
  echo "Wrote ~/.gitconfig.local"
fi

# --- Devcontainer bind mount (Linux only) ---

if [[ "$(uname)" == "Linux" && -d "$DOTFILES_DIR/devcontainer" ]]; then
  if [[ ! -d /mnt/devcontainer-ro ]]; then
    echo ""
    echo "Setting up devcontainer bind mount (requires sudo)..."
    sudo mkdir -p /mnt/devcontainer-ro
    sudo mount --bind "$DOTFILES_DIR/devcontainer" /mnt/devcontainer-ro
    sudo mount -o remount,bind,ro /mnt/devcontainer-ro

    FSTAB_LINE="$DOTFILES_DIR/devcontainer /mnt/devcontainer-ro none bind,ro,nofail,x-systemd.automount 0 0"
    if ! grep -qF "/mnt/devcontainer-ro" /etc/fstab; then
      echo "Adding bind mount to /etc/fstab..."
      echo "$FSTAB_LINE" | sudo tee -a /etc/fstab > /dev/null
    fi
  fi
fi

echo ""
echo "Done. Restart your shell or run: exec zsh"
