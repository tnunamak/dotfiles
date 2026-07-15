---
title: "Self-hosted OSS projects mostly ship Docker/compose, not one-click deploy buttons, and curl|bash installs carry known security tradeoffs"
date: 2026-06-10
topic: data-explorer-ux
tags: [self-hosting, deploy, docker, fly-io, security, onboarding]
status: draft
sources: [fly-launch, fly-launch-create, fly-flyctl-launch, n8n-docker, plausible-ce, umami-install, outline-readme, coolify-install, curl-pipe-shell]
---

<!-- Extracted from a pdpp deploy-button-parity doc; pdpp-specific fly.toml paths and internal design notes discarded. -->

## CLAIMS

- Fly.io does not provide a Railway-style hosted one-click "Launch on Fly.io" button for arbitrary repos; the docs URL that would host it returns 404 and the Fly Launch product is CLI-only (`fly launch`, `fly deploy`, `fly.toml`). [fly-launch]
- `fly launch` defaults to `fly.toml` at the repo root but accepts `--config <path>` for a subdirectory, and `--from <GitHub-URL>` clones a repo and can combine with `--config`. [fly-launch-create]
- `fly launch --db` auto-provisions a Fly Postgres app and injects `DATABASE_URL` into the app's secrets; secrets can be passed inline with `--secret "KEY=VALUE"` and env vars with `--env`. [fly-flyctl-launch]
- Fly trial organizations (no card on file) succeed at app creation, Postgres provisioning, and IP allocation but are blocked at the final release step with `status 422: This functionality is disabled for trial organizations`. [fly-flyctl-launch]
- n8n's self-host install page recommends a two-step Docker pattern (`docker volume create` then a multiline `docker run`), defaults to SQLite (Postgres opt-in), and shows no Railway/Render/Fly/DigitalOcean deploy buttons. [n8n-docker]
- Plausible Community Edition self-hosting is a multi-step Docker Compose flow (git clone a pinned tag, edit `.env`, port override, `docker compose up -d`) with no single-command deploy and no platform buttons; the friction is intentional ("a real commitment"). [plausible-ce]
- Umami ships a docker-compose bundling app + Postgres so `docker compose up -d` is the whole install (default creds admin/umami), with no platform buttons and no SQLite path. [umami-install]
- Outline's README links a `docker-compose.yml` but presents no one-liner Docker command and no platform deploy buttons; self-host lives in a separate wiki. [outline-readme]
- Coolify's canonical install is `curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash` (optionally `| sudo bash`); the manual path pulls a CDN-hosted docker-compose + env + upgrade script. [coolify-install]
- The documented risks of `curl | sh` installs are: no integrity check (MITM/CDN compromise silently runs arbitrary code unless a checksum is verified), no review step before execution, and full root escalation with `curl | sudo bash`; mitigations are sha256 verification, commit-pinned URLs, and signing. [curl-pipe-shell]

## SOURCES

**fly-launch**
URL: https://fly.io/docs/launch/
Accessed: 2026-06-10
Quote: "The entire 'Fly Launch' product is CLI-only: fly launch, fly deploy, fly.toml. https://fly.io/docs/launch/launch-button/ returned HTTP 404."

**fly-launch-create**
URL: https://fly.io/docs/launch/create/
Accessed: 2026-06-10
Quote: "You can provide your own fly.toml and fly launch will offer to copy that configuration to a new app."

**fly-flyctl-launch**
URL: https://fly.io/docs/flyctl/launch/
Accessed: 2026-06-10
Quote: "failed to create release (status 422): This functionality is disabled for trial organizations"

**n8n-docker**
URL: https://docs.n8n.io/hosting/installation/docker/
Accessed: 2026-06-10

**plausible-ce**
URL: https://github.com/plausible/community-edition
Accessed: 2026-06-10
Quote: (plausible.io/self-hosted-web-analytics calls self-hosting "a real commitment")

**umami-install**
URL: https://umami.is/docs/install
Accessed: 2026-06-10

**outline-readme**
URL: https://github.com/outline/outline#readme
Accessed: 2026-06-10

**coolify-install**
URL: https://coolify.io/docs/installation
Accessed: 2026-06-10

**curl-pipe-shell**
URL: https://0x46.net/thoughts/2019/04/27/piping-curl-to-shell/
Accessed: 2026-06-10

## SYNTHESIS

For a self-hosted OSS product, a Railway/Fly one-click deploy button is above the industry norm, not below it — among n8n, Plausible CE, Umami, Outline, and Coolify none offer one. The realistic "lowest cognitive load" install options are: a single `docker run` with named volume + ENV defaults (works for SQLite-backed single-image apps), `curl -o docker-compose.yml && docker compose up -d` (keeps the compose file at a stable inspectable URL, safer than piping to a shell), or an interactive bootstrap script (highest capability, highest attack surface). `curl | bash` is broadly accepted for dev/ops tooling aimed at technical users but the reviewer-friendly `curl -o file` split is the safer default for a broader self-hosting audience.
