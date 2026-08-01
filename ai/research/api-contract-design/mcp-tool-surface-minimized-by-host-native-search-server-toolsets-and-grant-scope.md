---
title: "MCP tool-surface size is reduced by host-native tool search, server-owned toolsets/allow-lists, and grant-scoped tool availability — not by hidden profile taxonomies"
date: 2026-06-08
topic: api-contract-design
tags: [mcp, tool-surface, token-footprint, toolsets, deferred-loading, search-fetch]
status: draft
sources: [mcp-tools, mcp-pagination, openai-mcp, openai-mcp-data, openai-tool-search, codex-mcp, claude-mcp, anthropic-tool-ref, anthropic-advanced-tools, claude-tool-search, github-mcp, github-toolsets, stripe-mcp, notion-mcp, linear-mcp, linear-changelog, sentry-mcp]
source_session: 019d77bf-c440-7ea3-a715-a8a2cb29d7e9
---

<!-- Reusable per-provider MCP prior-art extracted from a pdpp design note. pdpp-specific
     decisions (its five-tool /mcp surface, profile rejection, confidence gates) were dropped. -->

## CLAIMS

- The MCP tools spec defines `tools/list`, deterministic tool-list expectations, authorization-shaped tool availability, and list-change notification, and `tools/list` supports pagination; but hosts can still fetch every page and load all returned tools, so pagination and `listChanged` are not a complete answer to model-loaded context. [mcp-tools][mcp-pagination]
- The MCP spec explicitly allows tool availability to vary by the authorization presented on the request. [mcp-tools]
- OpenAI's Responses API imports remote MCP tools through an `mcp_list_tools` output item, can filter imported tools with `allowed_tools`, and supports `defer_loading` when using tool search; its data-only MCP guide treats `search` and `fetch` as the required read-only compatibility shape for deep research. [openai-mcp][openai-mcp-data][openai-tool-search]
- Codex supports stdio and streamable HTTP MCP servers, reads server `instructions`, and exposes `enabled_tools`/`disabled_tools` client-side in `config.toml`, shared across CLI and IDE extension. [codex-mcp]
- Claude Code enables MCP tool search by default in supported environments (schemas deferred and discovered on demand), supports always-loaded server/tool exceptions, and Anthropic documents `defer_loading` and argues for on-demand discovery as tool libraries grow. [claude-mcp][anthropic-tool-ref][anthropic-advanced-tools][claude-tool-search]
- GitHub's official MCP server supports server-owned `--toolsets`, individual `--tools`, read-only mode, a tool-search CLI helper, and remote toolset configuration via URL parameters or headers — strong prior art for server-owned toolsets and allow-lists (though not for any specific profile-name taxonomy). [github-mcp][github-toolsets]
- Stripe's MCP pattern is less about tool profiles and more about authorization/permission scoping: a hosted OAuth MCP server, local setup, a tool catalog, dashboard MCP session management, and restricted API-key guidance for agentic software. [stripe-mcp]
- Notion exposes a broad hosted MCP catalog (search/fetch, content creation, page updates, database/view ops, comments, user/team lookups) and maps its `notion-search`/`notion-fetch` to `search`/`fetch` for OpenAI deep-research compatibility. [notion-mcp]
- Linear documents a centrally hosted streamable HTTP MCP endpoint with OAuth/DCR, client-specific setup commands for Claude Code and Codex, Bearer/API-key support for advanced cases, and reports reducing token usage through better tool documentation. [linear-mcp][linear-changelog]
- Sentry states its MCP tool selection is focused on human-in-the-loop coding/debugging workflows rather than general-purpose coverage, offers a Claude Code plugin/subagent lane, and distinguishes AI-powered search tools from other tools — evidence that workflow-specialized surfaces and skills/subagents are legitimate alternatives to broad generic tool catalogs. [sentry-mcp]
- Setup UX for MCP is one command per host for command-shaped clients (`claude mcp add --transport http <name> <url>`, `codex mcp add <name> --url <url>`) and URL-shaped for ChatGPT/Claude.ai-style clients (paste the remote MCP endpoint, use OAuth, let the host inspect tools). [claude-mcp][codex-mcp]
- Anthropic's tool-writing guidance: return only high-signal information, eschew low-level technical identifiers (`uuid`, `mime_type`), implement pagination/range/filter/truncation with sane defaults (Claude Code caps tool responses at 25k tokens), and offer a `response_format` enum (`concise`/`detailed`) so the agent controls verbosity. [anthropic-advanced-tools]

## SOURCES

**mcp-tools**
URL: https://modelcontextprotocol.io/specification/draft/server/tools
Accessed: 2026-06-08

**mcp-pagination**
URL: https://modelcontextprotocol.io/specification/draft/server/utilities/pagination
Accessed: 2026-06-08

**openai-mcp**
URL: https://developers.openai.com/api/docs/guides/tools-connectors-mcp
Accessed: 2026-06-08

**openai-mcp-data**
URL: https://developers.openai.com/api/docs/mcp
Accessed: 2026-06-08

**openai-tool-search**
URL: https://developers.openai.com/api/docs/guides/tools-tool-search
Accessed: 2026-06-08

**codex-mcp**
URL: https://developers.openai.com/codex/mcp
Accessed: 2026-06-08

**claude-mcp**
URL: https://code.claude.com/docs/en/mcp
Accessed: 2026-06-08

**anthropic-tool-ref**
URL: https://platform.claude.com/docs/en/agents-and-tools/tool-use/tool-reference
Accessed: 2026-06-08

**anthropic-advanced-tools**
URL: https://www.anthropic.com/engineering/advanced-tool-use
Accessed: 2026-06-08

**claude-tool-search**
URL: https://code.claude.com/docs/en/agent-sdk/tool-search
Accessed: 2026-06-08

**github-mcp**
URL: https://github.com/github/github-mcp-server
Accessed: 2026-06-08

**github-toolsets**
URL: https://docs.github.com/en/copilot/how-tos/provide-context/use-mcp-in-your-ide/configure-toolsets
Accessed: 2026-06-08

**stripe-mcp**
URL: https://docs.stripe.com/mcp
Accessed: 2026-06-08

**notion-mcp**
URL: https://developers.notion.com/guides/mcp/mcp-supported-tools
Accessed: 2026-06-08

**linear-mcp**
URL: https://linear.app/docs/mcp
Accessed: 2026-06-08

**linear-changelog**
URL: https://linear.app/changelog/2026-02-05-linear-mcp-for-product-management
Accessed: 2026-06-08

**sentry-mcp**
URL: https://github.com/getsentry/sentry-mcp
Accessed: 2026-06-08

## SYNTHESIS

Provider prior art gives multiple distinct levers for reducing model-loaded and user-facing MCP tool surface, and they compose rather than compete: (1) compact read-only tool shapes (`search`/`fetch`); (2) shorter descriptions + server `instructions`; (3) server-owned toolsets/allow-lists (GitHub is the strongest example); (4) client-owned allow/deny lists (`allowed_tools`, `enabled_tools`/`disabled_tools`); (5) host-native tool search and deferred loading (Claude Code, OpenAI Responses); (6) grant-/authorization-shaped `tools/list`; and (7) representing some workflows as agent skills/CLI/subagents instead of more tools (Sentry). The ideal design should not fight host-native deferral — it should make tool names, descriptions, and server instructions read well when tools are deferred — and should keep setup to one recommended command/URL per client. A single broad operation-enum tool is generally poor: it hides semantics in a large schema and weakens host routing.
