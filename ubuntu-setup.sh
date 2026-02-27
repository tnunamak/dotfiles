#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update
sudo apt-get install -y neovim git ripgrep curl zsh fzf stow xclip

# Starship
if ! command -v starship &>/dev/null; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# zoxide
if ! command -v zoxide &>/dev/null; then
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi

# Set zsh as default shell
if [[ "$SHELL" != */zsh ]]; then
  chsh -s "$(which zsh)"
fi
