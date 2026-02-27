#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# Neovim
mkdir -p ~/.config/nvim
ln -sf "$DOTFILES_DIR/nvim/init.lua" ~/.config/nvim/init.lua

# Zsh
ln -sf "$DOTFILES_DIR/zsh/.zshrc" ~/.zshrc

# Starship
mkdir -p ~/.config
ln -sf "$DOTFILES_DIR/starship.toml" ~/.config/starship.toml

# Zsh plugins
ZSH_PLUGINS=~/.zsh/plugins
mkdir -p "$ZSH_PLUGINS"
clone_if_missing() {
  local repo=$1 dest=$2
  if [[ ! -d "$dest" ]]; then
    git clone --depth 1 "$repo" "$dest"
  fi
}
clone_if_missing https://github.com/zsh-users/zsh-autosuggestions "$ZSH_PLUGINS/zsh-autosuggestions"
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_PLUGINS/zsh-syntax-highlighting"

echo "Done. Open nvim to install plugins, restart your shell to pick up zsh config."
