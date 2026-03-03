#!/bin/bash
# Host-side helper script for controlling research mode in the Claude Code devcontainer
# Add this to your shell profile with: source /path/to/research-mode-host-commands.sh

CONTAINER_NAME="claude-code-dev"

research-on() {
    docker exec $CONTAINER_NAME /workspace/.devcontainer/research-mode-toggle.sh on
}

research-off() {
    docker exec $CONTAINER_NAME /workspace/.devcontainer/research-mode-toggle.sh off
}

research-status() {
    docker exec $CONTAINER_NAME /workspace/.devcontainer/research-mode-toggle.sh status
}

echo "Research mode commands loaded: research-on, research-off, research-status"