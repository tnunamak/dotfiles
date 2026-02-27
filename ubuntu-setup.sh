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

# Node.js (via nvm)
if ! command -v node &>/dev/null; then
  if ! command -v nvm &>/dev/null && [[ ! -d "$HOME/.nvm" ]]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    # shellcheck source=/dev/null
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  fi
  nvm install --lts
fi

# uv (Python package manager)
if ! command -v uv &>/dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Claude Code
if ! command -v claude &>/dev/null; then
  npm install -g @anthropic-ai/claude-code
fi

# Gemini CLI
if ! command -v gemini &>/dev/null; then
  npm install -g @google/gemini-cli
fi

# Codex CLI
if ! command -v codex &>/dev/null; then
  npm install -g @openai/codex
fi

# Kimi Code CLI
if ! command -v kimi &>/dev/null; then
  uv tool install --python 3.13 kimi-cli
fi

# git-filter-repo (for sync-devcontainer.sh)
if ! command -v git-filter-repo &>/dev/null; then
  sudo apt-get install -y git-filter-repo
fi

# Set zsh as default shell
if [[ "$SHELL" != */zsh ]]; then
  chsh -s "$(which zsh)"
fi
