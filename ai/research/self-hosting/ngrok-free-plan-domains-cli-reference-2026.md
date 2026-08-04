---
title: "ngrok free plan assigns one stable dev domain (no purchase or custom domain required) with --url flag syntax, zero account-required Quick Tunnel fallback"
date: 2026-08-04
topic: self-hosting
tags: [ngrok, domain, cli, quickstart, free-tier]
status: draft
sources: [ngrok-docs-domains, ngrok-docs-free-limits, ngrok-docs-quickstart]
source_session: c51acbbd-22bd-4d38-94ce-2100850ff9e3
---

## CLAIMS

- ngrok free plan automatically assigns one persistent "Dev Domain" (e.g. `my-assigned-domain.ngrok-free.app`) reusable across tunnel restarts without domain purchase or custom domain requirement [ngrok-docs-domains]
- Dev Domain is claimed and stored in the ngrok dashboard; to reuse in CLI, pass `--url <dev-domain>` flag to `ngrok http <port>` (flag name is `--url`, not `--domain`) [ngrok-docs-domains]
- Free plan also supports zero-account "Quick Tunnel" (`ngrok http --url-scheme https <port>` style) that generates ephemeral `*.trycloudflare.com` domains but explicitly documented as "for testing and development only" with 200 in-flight request cap and no SLA [ngrok-docs-free-limits]
- CLI authentication flow: (1) `ngrok config add-authtoken <token>` to persist credentials (2) `ngrok http --url=<dev-domain> <port>` to start tunnel with assigned domain [ngrok-docs-quickstart]
- Browser interstitial page (warning on non-API traffic) appears once per session or on first visit, can be bypassed with `ngrok-skip-browser-warning` header on requests [ngrok-docs-http-headers]

## SOURCES

**ngrok-docs-domains**
URL: https://ngrok.com/docs/universal-gateway/domains/
Accessed: 2026-08-04
Quote: "Free plan users get one automatically-assigned Dev Domain that persists across tunnels"

**ngrok-docs-free-limits**
URL: https://ngrok.com/docs/pricing-limits/free-plan-limits
Accessed: 2026-08-04
Quote: "Quick Tunnel caps at 200 in-flight requests, is for testing and development only, no SLA"

**ngrok-docs-quickstart**
URL: https://ngrok.com/docs/guides/share-localhost/quickstart/
Accessed: 2026-08-04
Quote: "Authenticate with `ngrok config add-authtoken`, start tunnel with `ngrok http --url=<domain> <port>`"

**ngrok-docs-http-headers**
URL: https://ngrok.com/docs/universal-gateway/http-request-headers/
Accessed: 2026-08-04
Quote: "Browser interstitial can be bypassed with `ngrok-skip-browser-warning: true` header"

## SYNTHESIS

ngrok's free tier provides two paths for persistent public HTTPS: (1) **Dev Domain** (recommended for self-hosted MCP/local-dev-sharing): one automatically-assigned, reusable domain per account, CLI flag is `--url`, no setup cost beyond authtoken; (2) **Quick Tunnel** (zero-account fallback): ephemeral `*.trycloudflare.com` domains, caps at 200 concurrent, explicitly not for production. For hosted services (e.g., PDPP MCP or self-hosted apps needing stable URLs for AI clients), Dev Domain is the intended free path. Quick Tunnel's 200-connection cap and "testing only" disclaimer make it unsuitable for unattended production (e.g., CloudFlare Tunnel or self-hosted reverse-proxy is the right choice for production; ngrok free is for local development sharing only).
