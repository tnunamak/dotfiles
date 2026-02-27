#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update
sudo apt-get install -y neovim git ripgrep curl zsh fzf

# Starship
if ! command -v starship &>/dev/null; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# Set zsh as default shell
if [[ "$SHELL" != */zsh ]]; then
  chsh -s "$(which zsh)"
fi
