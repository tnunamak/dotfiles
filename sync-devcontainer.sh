#!/usr/bin/env bash
set -euo pipefail

# Merge upstream .devcontainer changes from anthropics/claude-code into dotfiles/devcontainer/
#
# Uses git-filter-repo to extract .devcontainer/ with full history, re-nested
# under devcontainer/, then merges into dotfiles. Local customizations are
# preserved via normal three-way merge.
#
# Requires: git-filter-repo (pip install git-filter-repo)

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMP_DIR="/tmp/claude-code-devcontainer-$$"
REMOTE_URL="https://github.com/anthropics/claude-code.git"
REMOTE_NAME="cc-devcontainer-$$"

trap 'cd "$DOTFILES_DIR"; git remote remove "$REMOTE_NAME" 2>/dev/null; rm -rf "$TEMP_DIR"' EXIT

echo "Cloning upstream (this may take a moment)..."
git clone -q "$REMOTE_URL" "$TEMP_DIR"

echo "Extracting .devcontainer/ history..."
cd "$TEMP_DIR"
git filter-repo --subdirectory-filter .devcontainer \
    --to-subdirectory-filter devcontainer --force --quiet

echo "Merging into dotfiles..."
cd "$DOTFILES_DIR"
git remote add "$REMOTE_NAME" "$TEMP_DIR"
git fetch -q "$REMOTE_NAME" main

if [[ ! -d "$DOTFILES_DIR/devcontainer" ]]; then
  git merge --allow-unrelated-histories "$REMOTE_NAME/main" \
    -m "Add devcontainer from anthropics/claude-code"
else
  git merge "$REMOTE_NAME/main" --no-edit \
    -m "Merge upstream devcontainer changes" || {
    echo ""
    echo "Merge conflicts detected. Resolve them, then:"
    echo "  git add devcontainer/"
    echo "  git commit"
    exit 1
  }
fi

echo ""
echo "Done. Review with: git log --oneline -5"
