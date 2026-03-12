#!/bin/bash
set -euo pipefail

# Block LAN access, allow everything else
# This prevents the container from reaching local network devices
# while keeping full internet access for development tools

# Use public DNS so we don't need to allow LAN DNS servers
# Set this BEFORE starting dockerd so it picks up the right DNS
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

# Allow loopback
iptables -A OUTPUT -o lo -j ACCEPT

# Allow host-side MCP servers (Playwright on port 3100)
# The Docker bridge gateway (172.17.0.1) is the host from the container's POV
HOST_GW=$(ip route | awk '/default/ {print $3}')
iptables -A OUTPUT -d "$HOST_GW" -p tcp --dport 3100 -j ACCEPT

# TODO: Allow SearXNG MCP access from devcontainers.
# SearXNG is behind Traefik on 192.168.1.4 (searxng.home), so we can't
# firewall by hostname — allowlisting :80/:443 would expose all Traefik
# services. Fix: expose SearXNG on a dedicated port on vivid-fish, then
# allowlist just that port here.

# Block private networks and link-local
iptables -A OUTPUT -d 10.0.0.0/8 -j DROP
iptables -A OUTPUT -d 172.16.0.0/12 -j DROP
iptables -A OUTPUT -d 192.168.0.0/16 -j DROP
iptables -A OUTPUT -d 169.254.0.0/16 -j DROP

# Start Docker daemon for Docker-in-Docker support
# Runs in background; logs go to /var/log/docker.log
# Started after DNS/firewall so dockerd uses public DNS (1.1.1.1)
if command -v dockerd &> /dev/null; then
  dockerd > /var/log/docker.log 2>&1 &
  # Wait for Docker to be ready (up to 10 seconds)
  for i in {1..20}; do
    if docker info &> /dev/null; then
      echo "Docker daemon started"
      break
    fi
    sleep 0.5
  done
fi

# Fix ownership of dirs that Docker creates as root for volume mount points
# (e.g. pip-cache → .cache/pip, pnpm-store → .local/share/pnpm/store)
DEV_USER=$(stat -c '%U' /workspace 2>/dev/null || echo node)
DEV_HOME=$(eval echo "~$DEV_USER")
chown "$DEV_USER:$DEV_USER" "$DEV_HOME/.local" "$DEV_HOME/.local/share" "$DEV_HOME/.cache" 2>/dev/null || true

echo "Firewall configured: LAN blocked, internet allowed (DNS via 1.1.1.1/8.8.8.8)"

# Previous domain-allowlist firewall (default-deny internet, allow specific hosts):
#
# registry.npmjs.org, npmjs.com
# github.io, github.com, api.github.com, raw.githubusercontent.com
# vana-com.github.io, docs.vana.org, server.vana.com, test.server.vana.com
# vana.org, vana.com
# api.anthropic.com, sentry.io, statsig.anthropic.com, statsig.com
# cursor.sh, cursor.com
# marketplace.visualstudio.com, vscode.blob.core.windows.net, update.code.visualstudio.com
# pypi.org, files.pythonhosted.org
# openai.com, api.openai.com
# discord.com, gateway.discord.gg, api.telegram.org
# bun.sh
#
# See git history for the full implementation.
