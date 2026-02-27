#!/usr/bin/env bash
set -euo pipefail

if ! command -v brew &>/dev/null; then
  echo "Homebrew not found. Install it from https://brew.sh"
  exit 1
fi

brew install neovim git ripgrep fzf starship zoxide stow uv git-filter-repo

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
