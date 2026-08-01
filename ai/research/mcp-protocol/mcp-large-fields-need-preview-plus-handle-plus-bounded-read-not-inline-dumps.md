---
title: "MCP large fields should be returned as a bounded preview plus a navigable handle plus an explicit bounded read, never as inline full-body dumps"
date: 2026-06-22
topic: mcp-protocol
tags: [mcp, resource-link, structured-content, pagination, content-ladder, tool-results]
status: draft
sources: [mcp-tools, mcp-resources, mcp-pagination, mcp-schema, openai-apps-sdk]
source_session: 80feb421-6d05-45fb-a555-63b91bab8f4f
---

## CLAIMS

- The MCP tools specification (2025-06-18) defines a tool result as `content[]` (model-visible blocks) plus optional `structuredContent`, and supports resource links, embedded resources, output schemas, and tool-result error handling. [mcp-tools]
- MCP defines `ResourceLink`, `EmbeddedResource`, `TextResourceContents`, and `BlobResourceContents` as distinct result content types; a tool may return a `resource_link` block pointing at addressable content. [mcp-schema]
- MCP resources are application-driven and URI-addressed, discoverable/readable via `resources/list` and `resources/read`, with templates, metadata, and annotations; resource links returned by tools are not guaranteed to also appear in `resources/list`. [mcp-resources]
- MCP pagination uses opaque, server-selected cursors returned as `nextCursor`; clients must treat cursors as opaque and page numbers are not a durable contract. [mcp-pagination]
- The MCP spec says clients should validate structured tool results against the tool's output schema when one is present. [mcp-tools]
- The OpenAI Apps SDK pattern pairs a model-visible structured tool payload with resource-backed UI/files, and supports downloadable MCP `resource_link` entries — i.e., a split between model-visible structured data and resource-backed full content. [openai-apps-sdk]

## SOURCES

**mcp-tools**
URL: https://modelcontextprotocol.io/specification/2025-06-18/server/tools
Accessed: 2026-06-22
Quote: "content[], structuredContent, resource links, embedded resources, output schemas, and tool-result error handling."

**mcp-resources**
URL: https://modelcontextprotocol.io/specification/2025-06-18/server/resources
Accessed: 2026-06-22
Quote: "resource URIs, resources/list, resources/read, templates, resource metadata, annotations, and URI-scheme guidance."

**mcp-pagination**
URL: https://modelcontextprotocol.io/specification/2025-06-18/server/utilities/pagination
Accessed: 2026-06-22
Quote: "opaque cursors, server-selected page size, nextCursor, and client cursor constraints."

**mcp-schema**
URL: https://modelcontextprotocol.io/specification/2025-06-18/schema
Accessed: 2026-06-22
Quote: "ResourceLink, EmbeddedResource, TextResourceContents, BlobResourceContents, Result._meta, and JSON-RPC error shape."

**openai-apps-sdk**
URL: https://developers.openai.com/apps-sdk/build/mcp-server
Accessed: 2026-06-22
Quote: "structured tool payloads paired with resource-backed UI/files, plus downloadable MCP resource_link support."
Additional: https://github.com/openai/openai-apps-sdk-examples

## SYNTHESIS

A general content ladder for returning large records/fields over MCP without spending model context on unrequested bytes:

`compact summary -> typed preview with handle -> bounded read window -> resource read/export`

1. Discovery/list responses return compact structured summaries in `structuredContent` plus bounded text in `content[]`; every visible row/field/attachment carries a stable handle (a `resource_link` or a handle accepted by an explicit read tool).
2. Default record payloads include previews, not arbitrary full bodies: for text, a bounded window with byte/char offsets, total size, MIME type, digest/revision marker, and truncation metadata; for binary, metadata + `resource_link`, never base64 in default results.
3. Full content is reachable by an explicit read primitive (offset/limit or cursor windows for text, path projection for JSON, resource-read/export for full documents or blobs) — not hidden behind the default result.
4. Bulk/full extraction uses an export job/result with a manifest and `resource_link` entries, not chat-transcript payloads.

Design invariants worth testing generically: no preview may be a dead end (every truncation/snippet/hit/blob placeholder has a working read path); truncation must be honest (`truncated=true` + total size + served range + `next` or terminal reason); one canonical machine-payload location; a resource-link fallback tool-read path for clients that don't expose `resources/read`; binary defaults to metadata not base64; and a round-trip test that follows a preview's handle and recovers the preview bytes as a prefix/window of the full content per declared coordinates.

Option tradeoffs observed: inline-full is simplest but unbounded and risks base64 blowups (allow only under strict size thresholds); snippets-only are cheap but dead-end without handles; opaque handles are compact but need typed metadata and a guaranteed read path; resource links are MCP-native but client support varies; bounded text windows are lossless-by-iteration but need snapshot/revision semantics; export fits bulk/binary but needs lifecycle and access checks. Note byte offsets can split Unicode — define whether coordinates are bytes, UTF-8 code points, or lines, and return the actual range served.
