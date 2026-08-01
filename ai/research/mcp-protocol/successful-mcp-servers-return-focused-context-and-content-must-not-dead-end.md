---
title: "Successful MCP servers return focused context, treat content[] as the compatibility floor, and never let a compact result dead-end into an opaque handle"
date: 2026-06-22
topic: mcp-protocol
tags: [mcp, content-vs-structuredcontent, resources, client-divergence, github-mcp, playwright-mcp, context7]
status: draft
sources: [mcp-tools, mcp-resources, mcp-structured-divergence, claude-code-custom-tools, github-mcp, playwright-mcp, context7, firecrawl, filesystem-mcp]
source_session: c23135d0-5af1-45c0-962d-1f0242e51abf
---

## CLAIMS

- MCP supports `structuredContent`, but clients treat it non-uniformly: the linked MCP issue records Cursor leaning toward `content`, VS Code preferring `structuredContent`, and other clients ignoring `structuredContent` for model context. [mcp-structured-divergence]
- Claude Code's custom-tools docs make `content` the required result block and `structuredContent` optional machine-readable data. [claude-code-custom-tools]
- Context7 returns task-relevant documentation directly into agent context after resolving a library, rather than dumping raw content. [context7]
- Firecrawl recommends structured JSON extraction for most scraping and reserves markdown/full content for when it is genuinely needed. [firecrawl]
- Microsoft Playwright MCP uses accessibility snapshots (text-structured) instead of screenshots to keep browser state agent-usable, and explicitly distinguishes MCP (persistent state, interactive introspection) from a CLI+Skills path that can be more token-efficient for coding agents. [playwright-mcp]
- The GitHub MCP server splits work across API-shaped list/get/search tools and ships install guidance for many clients (Codex, Claude, Cursor, Gemini CLI, OpenCode, Windsurf, and others). [github-mcp]
- MCP `resource_link` + `resources/read` is the standard full-body escape hatch, but client support varies; the filesystem MCP server history shows that claiming/implying resource support is insufficient if the runtime path is not implemented and visible to the client. [filesystem-mcp]

## SOURCES

**mcp-tools**
URL: https://modelcontextprotocol.io/specification/2025-06-18/server/tools
Accessed: 2026-06-22

**mcp-resources**
URL: https://modelcontextprotocol.io/specification/2025-06-18/server/resources
Accessed: 2026-06-22

**mcp-structured-divergence**
URL: https://github.com/modelcontextprotocol/modelcontextprotocol/issues/1624
Accessed: 2026-06-22
Quote: "client divergence: Cursor leaning toward content, VS Code preferring structuredContent, other clients ignoring structuredContent for model context."

**claude-code-custom-tools**
URL: https://code.claude.com/docs/en/agent-sdk/custom-tools
Accessed: 2026-06-22

**github-mcp**
URL: https://github.com/github/github-mcp-server
Accessed: 2026-06-22
Additional (install guides): https://github.com/github/github-mcp-server/blob/main/README.md

**playwright-mcp**
URL: https://github.com/microsoft/playwright-mcp
Accessed: 2026-06-22

**context7**
URL: https://github.com/upstash/context7
Accessed: 2026-06-22

**firecrawl**
URL: https://raw.githubusercontent.com/mendableai/firecrawl-mcp-server/main/README.md
Accessed: 2026-06-22

**filesystem-mcp**
URL: https://github.com/modelcontextprotocol/servers/blob/main/src/filesystem/README.md
Accessed: 2026-06-22
Additional (resource-support issue): https://github.com/modelcontextprotocol/servers/issues/399

## SYNTHESIS

Field lessons for exposing large, navigable records over MCP:

1. `content[]` is the compatibility floor. Because clients treat `structuredContent` inconsistently, every important read path must carry enough model-visible `content[]` text for an agent to know what happened and what to call next. `structuredContent` can be canonical for machines but cannot be the only usable surface.
2. Opaque compression handles are not a universal read surface. Internal transcript/storage markers are fine only if the agent has a standard next step to expand them; if a client can't dereference the marker, the record is not navigable even though the backend has the bytes.
3. Token efficiency should come from focused operations, projections, windows, cursors, and capability metadata — as GitHub MCP, Playwright MCP, Context7, and Firecrawl demonstrate — not from hiding the next readable content behind non-standard handles.
4. Resources are necessary but not sufficient: keep `resource_link`/`resources/read` for full-body provenance, but make the normal agent path a bounded text-window tool that works in tool-only clients.
5. CLI+Skills may beat MCP for high-throughput local coding-agent workflows (Playwright and Context7 both support both); MCP is best for grant-scoped, remote, protocol-mediated access.

Progressive content ladder: compact model-visible hit cards in `content[]` (result ID, source identity, stream, timestamp, matched fields, bounded match windows) → canonical machine hit list in `structuredContent.results[]` → `fetch(id)` for record metadata + small inline fields + explicit long-body references → a first-class bounded text-window tool (id, field, query/offset, before/after, prev/next cursors) → real MCP resources with `resource_link`/`resources/read` → chunked full-read/export for exhaustive/audit workflows → schema/capability metadata advertising which fields are searchable, previewable, inline-complete, blob-backed, or window-readable. The invariant: every compact result must have an obvious, standard, model-usable next read path; token efficiency may defer content but never dead-end it.
