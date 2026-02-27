#!/usr/bin/env bash
set -euo pipefail

if ! command -v brew &>/dev/null; then
  echo "Homebrew not found. Install it from https://brew.sh"
  exit 1
fi

brew install neovim git ripgrep fzf starship zoxide stow
