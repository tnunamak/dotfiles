#!/bin/bash
# Check all host paths required by devcontainer.json mounts

echo "Checking devcontainer mount sources..."
echo ""

check_path() {
    local path="$1"
    local type="$2"

    if [ "$type" = "dir" ]; then
        if [ -d "$path" ]; then
            echo "✓ $path (directory exists)"
        else
            echo "✗ $path (MISSING directory)"
        fi
    elif [ "$type" = "file" ]; then
        if [ -f "$path" ]; then
            echo "✓ $path (file exists)"
        else
            echo "✗ $path (MISSING file)"
        fi
    elif [ "$type" = "socket" ]; then
        if [ -S "$path" ]; then
            echo "✓ $path (socket exists)"
        elif [ -e "$path" ]; then
            echo "? $path (exists but not a socket)"
        else
            echo "✗ $path (MISSING socket)"
        fi
    fi
}

# Get the workspace folder basename (adjust if different)
WORKSPACE_BASENAME="vana-smart-contracts"

echo "=== Required Files ==="
check_path "$HOME/.claude/.credentials.json" "file"
check_path "$HOME/.claude/CLAUDE.md" "file"
check_path "$HOME/.gitconfig" "file"
check_path "$HOME/.sentryclirc" "file"

echo ""
echo "=== Required Directories ==="
check_path "$HOME/.devcontainer-homes/$WORKSPACE_BASENAME" "dir"
check_path "$HOME/.config/git" "dir"
check_path "$HOME/.config/gh" "dir"
check_path "$HOME/.config/gcloud" "dir"
check_path "$HOME/.config/posthog" "dir"
check_path "$HOME/.ssh" "dir"

echo ""
echo "=== SSH Auth Socket ==="
if [ -n "$SSH_AUTH_SOCK" ]; then
    check_path "$SSH_AUTH_SOCK" "socket"
else
    echo "✗ SSH_AUTH_SOCK environment variable not set"
fi

echo ""
echo "=== Parent Directory Mount ==="
# This checks the parent of your workspace for the /projects mount
WORKSPACE_DIR="$HOME/code/$WORKSPACE_BASENAME"
PARENT_DIR="$(dirname "$WORKSPACE_DIR")"
check_path "$PARENT_DIR" "dir"

echo ""
echo "To create missing directories, run:"
echo "  mkdir -p ~/.devcontainer-homes/$WORKSPACE_BASENAME"
echo "  mkdir -p ~/.config/{git,gh,gcloud,posthog}"
echo "  mkdir -p ~/.claude"
echo "  touch ~/.claude/.credentials.json ~/.claude/CLAUDE.md ~/.sentryclirc"
