#!/bin/bash
set -euo pipefail

case "${1:-}" in
    "on")
        echo "Enabling research mode - allowing all outbound traffic"
        iptables -P OUTPUT ACCEPT
        iptables -P INPUT ACCEPT
        echo "Research mode: ON"
        ;;
    "off")
        echo "Disabling research mode - restoring firewall"
        /workspace/.devcontainer/init-firewall.sh
        echo "Research mode: OFF"
        ;;
    "status")
        if iptables -L OUTPUT | grep -q "policy ACCEPT"; then
            echo "Research mode: ON"
        else
            echo "Research mode: OFF"
        fi
        ;;
    *)
        echo "Usage: $0 [on|off|status]"
        exit 1
        ;;
esac