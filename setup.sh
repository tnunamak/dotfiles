#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# Stow packages (each mirrors ~ directory structure)
PACKAGES=(nvim zsh bash shell kitty starship git claude bin)

if ! command -v stow &>/dev/null; then
  echo "Error: GNU Stow not found. Run the platform setup script first."
  exit 1
fi

echo "Stowing packages: ${PACKAGES[*]}"
for pkg in "${PACKAGES[@]}"; do
  stow -d "$DOTFILES_DIR" -t "$HOME" --restow "$pkg"
done

# Zsh plugins
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

# Ensure local config files exist (not tracked)
touch ~/.shell_local
touch ~/.shell_secrets
touch ~/.claude/CLAUDE.local.md
[[ -f ~/.gitconfig.local ]] || cp "$DOTFILES_DIR/git/.gitconfig.local.example" ~/.gitconfig.local

# Linux: set up devcontainer bind mount
if [[ "$(uname)" == "Linux" && -d "$DOTFILES_DIR/devcontainer" ]]; then
  if [[ ! -d /mnt/devcontainer-ro ]]; then
    echo "Setting up devcontainer bind mount (requires sudo)..."
    sudo mkdir -p /mnt/devcontainer-ro
    sudo mount --bind "$DOTFILES_DIR/devcontainer" /mnt/devcontainer-ro
    sudo mount -o remount,bind,ro /mnt/devcontainer-ro

    # Add to fstab if not already there
    FSTAB_LINE="$DOTFILES_DIR/devcontainer /mnt/devcontainer-ro none bind,ro,nofail,x-systemd.automount 0 0"
    if ! grep -qF "/mnt/devcontainer-ro" /etc/fstab; then
      echo "Adding bind mount to /etc/fstab (requires sudo)..."
      echo "$FSTAB_LINE" | sudo tee -a /etc/fstab > /dev/null
    fi
  fi
fi

echo "Done. Restart your shell or run: exec zsh"
