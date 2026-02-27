#!/usr/bin/env bash
set -euo pipefail

# Merge upstream .devcontainer changes from anthropics/claude-code into dotfiles/devcontainer/
#
# Extracts .devcontainer/ from upstream into a clean single-commit repo, then
# uses git subtree to three-way merge with local customizations.
# Resolve conflicts normally if any arise.
#
# Requires: git-filter-repo (pip install git-filter-repo)

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMP_DIR="/tmp/claude-code-devcontainer-$$"
REMOTE_URL="https://github.com/anthropics/claude-code.git"
REMOTE_NAME="cc-devcontainer-$$"

trap 'cd "$DOTFILES_DIR"; git remote remove "$REMOTE_NAME" 2>/dev/null; rm -rf "$TEMP_DIR"' EXIT

echo "Fetching upstream .devcontainer..."
mkdir "$TEMP_DIR" && cd "$TEMP_DIR"
git init -q
git remote add origin "$REMOTE_URL"
# Sparse fetch: only download .devcontainer/ blobs
git sparse-checkout init
git sparse-checkout set .devcontainer
git fetch --depth=1 origin main -q
git checkout -q FETCH_HEAD

# Create a clean orphan repo with just the devcontainer files at root
CLEAN_DIR="/tmp/claude-code-devcontainer-clean-$$"
trap 'cd "$DOTFILES_DIR"; git remote remove "$REMOTE_NAME" 2>/dev/null; rm -rf "$TEMP_DIR" "$CLEAN_DIR"' EXIT

mkdir "$CLEAN_DIR" && cd "$CLEAN_DIR"
git init -q
cp "$TEMP_DIR"/.devcontainer/* . 2>/dev/null || true
git add -A
git commit -q -m "upstream .devcontainer from anthropics/claude-code"

echo "Merging into dotfiles..."
cd "$DOTFILES_DIR"
git remote add "$REMOTE_NAME" "$CLEAN_DIR"
git fetch -q "$REMOTE_NAME" master

if [[ ! -d "$DOTFILES_DIR/devcontainer" ]]; then
  git subtree add --prefix=devcontainer "$REMOTE_NAME/master" --squash \
    -m "Add devcontainer from anthropics/claude-code"
else
  git subtree merge --prefix=devcontainer "$REMOTE_NAME/master" --squash \
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
