---
title: "Proxying Next.js dev HMR WebSocket (/_next/webpack-hmr) through Traefik requires a dedicated higher-priority router with no auth middleware and an HTTP/1.1-only transport; the 'malformed HTTP response \"Unauthorized\"' error is auth-middleware bytes left on a reused keep-alive connection"
date: 2026-01-01
topic: self-hosting
tags: [traefik, nextjs, websocket, hmr, reverse-proxy, http2, dev-environment]
status: draft
sources: [traefik-serverstransport, traefik-pr-11408, traefik-issue-11405, next-alloweddevorigins, next-v12-upgrade, cve-2026-27977]
---

<!--
Date is the article's own frame (Traefik 3.6 / Next.js 16); exact research date not recorded in the source file. Adjust if known.
-->

## CLAIMS

- The error `malformed HTTP response "Unauthorized"` from a Traefik→Next.js dev HMR proxy is Go `net/http` reading a response line and finding the literal bytes `Unauthorized` first on the wire — not what Next's dev server emits (it emits `HTTP/1.1 101 Switching Protocols`) — meaning the bytes come from Traefik's pipeline: an auth/forward-auth middleware that wrote a body and returned the connection to the pool, or an HTTP/2→1.1 upgrade quirk against a pooled idle connection. [traefik-pr-11408]
- The fix on the Traefik side is a dedicated router matching `Host(...) && PathPrefix(\`/_next/webpack-hmr\`)` with higher `priority` than the main app router, attached to no auth/forward-auth/headers middleware, and using a dedicated `serversTransport` with `disableHTTP2: true` and a small (or `0`) `maxIdleConnsPerHost` so every WS upgrade dials a fresh HTTP/1.1 socket. A dedicated higher-priority router is Traefik's canonical way to bypass middlewares for one path. [traefik-serverstransport] [traefik-pr-11408]
- Traefik disables the Go HTTP/2 server's CONNECT-style WebSocket upgrade via `GODEBUG=http2xconnect=0` because the HTTP/2 CONNECT WS upgrade is incompatible with the net/http HTTP/1 reverse proxy (PR #11408); a separate WS regression in Traefik 3.2.4 (issue #11405) was patched. [traefik-pr-11408] [traefik-issue-11405]
- On the Next.js side, the reverse-proxy hostname must be added to `allowedDevOrigins` in `next.config.js` (required since Next 13.5+, enforced in 16), and the app should be pinned to Next.js >= 16.1.7 for the CVE-2026-27977 fix to the dev-HMR Origin check. [next-alloweddevorigins] [cve-2026-27977]
- There is no `webSocketUrl` option in `next.config.js` — that key is a webpack-dev-server option Next does not expose; the HMR path is fixed at `/_next/webpack-hmr` for both webpack and Turbopack (`next dev --turbopack`, default in 16), so the proxy requirements are identical. [next-v12-upgrade]
- The same shape (separate router, no auth, dedicated HTTP/1.1-only transport) applies to Vite (`/@vite/client`, `/__vite_hmr`), Storybook (`/storybook-server-channel`), and Remix dev. [traefik-pr-11408]

## SOURCES

**traefik-serverstransport**
URL: https://doc.traefik.io/traefik/reference/routing-configuration/http/load-balancing/serverstransport/
Accessed: 2026-01-01

**traefik-pr-11408**
URL: https://github.com/traefik/traefik/pull/11408
Accessed: 2026-01-01
Quote: "Disable http2 connect setting for websocket by default."

**traefik-issue-11405**
URL: https://github.com/traefik/traefik/issues/11405
Accessed: 2026-01-01

**next-alloweddevorigins**
URL: https://nextjs.org/docs/app/api-reference/config/next-config-js/allowedDevOrigins
Accessed: 2026-01-01

**next-v12-upgrade**
URL: https://nextjs.org/docs/pages/guides/upgrading/version-12
Accessed: 2026-01-01

**cve-2026-27977**
URL: https://advisories.gitlab.com/pkg/npm/next/CVE-2026-27977/
Accessed: 2026-01-01

## SYNTHESIS

When a dev HMR WebSocket (Next.js `/_next/webpack-hmr`, Vite `/@vite/client`, Storybook, Remix) breaks behind Traefik with `malformed HTTP response "Unauthorized"`, the root cause is almost always not a Traefik bug but a config interaction: an auth/forward-auth middleware short-circuits with a `401` body whose bytes get left on a reused keep-alive connection, and/or an HTTP/2↔HTTP/1 reverse-proxy upgrade quirk. The sustainable, idiomatic fix isolates the HMR path onto its own higher-priority router carrying no middleware and a dedicated `serversTransport` that forces fresh HTTP/1.1 sockets (`disableHTTP2: true`, `maxIdleConnsPerHost` low or `0`) — which is what the WebSocket RFC actually requires for the upgrade — rather than globally disabling HTTP/2 (which pollutes prod traffic) or relying on non-existent Next options like `webSocketUrl`. On the framework side, the proxy hostname must be whitelisted (`allowedDevOrigins`) and the version pinned past the relevant dev-HMR Origin-check CVE. Turbopack does not change any of this — the HMR endpoint path is identical.