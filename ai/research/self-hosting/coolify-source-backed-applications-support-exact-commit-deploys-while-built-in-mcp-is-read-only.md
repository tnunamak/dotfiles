---
title: "Coolify source-backed applications support exact-commit deploys while the built-in MCP is read-only"
date: 2026-07-13
topic: self-hosting
tags: [coolify, deployments, git, mcp, api]
status: draft
sources: [coolify-applications, coolify-public-api, coolify-mcp]
---

## CLAIMS

- Coolify models Git repositories, Dockerfiles, Compose files, and pre-built images as application deployment types; a source build produces a Docker image and runs it as a container. [coolify-applications]
- The public-repository application API accepts `git_repository`, `git_branch`, `build_pack`, optional `git_commit_sha`, `dockerfile_location`, and `instant_deploy`, so an API client can create a source-backed application pinned to an exact commit. [coolify-public-api]
- Coolify detects domain conflicts by default; `force_domain_override` bypasses the check, and the documented conflict response warns that duplicate domains can cause routing conflicts and unpredictable behavior. [coolify-public-api]
- Coolify's built-in MCP server is currently read-only; its ten tools inspect infrastructure, and a read-scoped team token is sufficient. [coolify-mcp]

## SOURCES

**coolify-applications**
URL: https://coolify.io/docs/applications/index
Accessed: 2026-07-13

**coolify-public-api**
URL: https://next.coolify.io/docs/api-reference/api/applications/create-public-application
Accessed: 2026-07-13

**coolify-mcp**
URL: https://coolify.io/docs/integrations/mcp
Accessed: 2026-07-13

## SYNTHESIS

Treat the source-backed application UUID as the durable production identity. Push first, pin and deploy the exact commit, and verify both deployment state and the public artifact. Recreating an application for an ordinary release adds routing and rollback state without benefit. If replacement is genuinely required, use a temporary route and explicit cutover instead of overriding a live domain conflict. Use Coolify MCP for discovery only; deployment automation still belongs on the authenticated API.
