---
title: "Mature npm ecosystems name a shared package after the durable concept it owns — <concept>-core for shared semantics, -runtime for executable behavior, <domain>-util-to-<output> for a pure transform, a domain noun for a durable data model, toolkit only when deliberately broad — not after a constraint"
date: 2026-06-24
topic: code-quality
tags: [package-naming, api-design, monorepo, npm, prior-art]
status: draft
sources: [tanstack-query-core, urql-core, relay-runtime, apollo-client, redux-toolkit, sentry-core, otel-core, smithy-core, smithy-types, aws-sdk-core, mcp-sdk, unified, vfile, vfile-reporter, mdast-util-to-markdown, hast-util-to-html, mdast-util-to-string, unist-util-visit, to-vfile]
source_session: 80feb421-6d05-45fb-a555-63b91bab8f4f
---

## CLAIMS

- `<concept>-core` / `core` names a framework-agnostic shared core that powers multiple adapters: `@tanstack/query-core` (powers TanStack Query adapters), `@urql/core` (shared GraphQL-client core), `@sentry/core` (base SDK interfaces used by platform SDKs), `@opentelemetry/core` (constants/utilities shared across OTel SDK packages), `@smithy/core` (common functionality for generated Smithy clients), `@aws-sdk/core` (shared functions/classes across AWS SDK clients). [tanstack-query-core] [urql-core] [sentry-core] [otel-core] [smithy-core] [aws-sdk-core]
- `-runtime` names a package that executes durable runtime behavior: `relay-runtime` owns Relay's data fetching, reading, normalization, and store runtime. [relay-runtime]
- `<domain>-util-to-<output>` (or `<domain>-util-<verb>`) names a precise pure transformation: `mdast-util-to-markdown`, `hast-util-to-html`, `mdast-util-to-string`, `hast-util-to-string` (serialize/extract from one shape to another), `unist-util-visit` (verb-specific tree traversal); `to-<model>` (`to-vfile`) names a functional transform whose target model is the package concept. [mdast-util-to-markdown] [hast-util-to-html] [mdast-util-to-string] [unist-util-visit] [to-vfile]
- A domain/data-model noun names a package that owns a durable concept or data model: `unified` (interface for processing content with syntax trees), `vfile` (virtual-file data model with metadata/messages), `vfile-reporter` (`<thing>-reporter` names the output role). [unified] [vfile] [vfile-reporter]
- `types` names a package that is mostly contracts (`@smithy/types` — shared client types, mostly internal to generated clients); `sdk` names a broad distribution package (`@modelcontextprotocol/sdk`); a product noun (`@apollo/client`) names one broad public package with cache/state/integrations; `toolkit` (`@reduxjs/toolkit`) names a deliberately broad, batteries-included utility package. [smithy-types] [mcp-sdk] [apollo-client] [redux-toolkit]

## SOURCES

**tanstack-query-core**
URL: https://www.npmjs.com/package/@tanstack/query-core
Accessed: 2026-06-24

**urql-core**
URL: https://www.npmjs.com/package/@urql/core
Accessed: 2026-06-24

**relay-runtime**
URL: https://www.npmjs.com/package/relay-runtime
Accessed: 2026-06-24

**apollo-client**
URL: https://www.npmjs.com/package/@apollo/client
Accessed: 2026-06-24

**redux-toolkit**
URL: https://www.npmjs.com/package/@reduxjs/toolkit
Accessed: 2026-06-24

**sentry-core**
URL: https://www.npmjs.com/package/@sentry/core
Accessed: 2026-06-24

**otel-core**
URL: https://www.npmjs.com/package/@opentelemetry/core
Accessed: 2026-06-24

**smithy-core**
URL: https://www.npmjs.com/package/@smithy/core
Accessed: 2026-06-24

**smithy-types**
URL: https://www.npmjs.com/package/@smithy/types
Accessed: 2026-06-24

**aws-sdk-core**
URL: https://www.npmjs.com/package/@aws-sdk/core
Accessed: 2026-06-24

**mcp-sdk**
URL: https://www.npmjs.com/package/@modelcontextprotocol/sdk
Accessed: 2026-06-24

**unified**
URL: https://www.npmjs.com/package/unified
Accessed: 2026-06-24

**vfile**
URL: https://www.npmjs.com/package/vfile
Accessed: 2026-06-24

**vfile-reporter**
URL: https://www.npmjs.com/package/vfile-reporter
Accessed: 2026-06-24

**mdast-util-to-markdown**
URL: https://www.npmjs.com/package/mdast-util-to-markdown
Accessed: 2026-06-24

**hast-util-to-html**
URL: https://www.npmjs.com/package/hast-util-to-html
Accessed: 2026-06-24

**mdast-util-to-string**
URL: https://www.npmjs.com/package/mdast-util-to-string
Accessed: 2026-06-24

**unist-util-visit**
URL: https://www.npmjs.com/package/unist-util-visit
Accessed: 2026-06-24

**to-vfile**
URL: https://www.npmjs.com/package/to-vfile
Accessed: 2026-06-24

## SYNTHESIS

Across mature JS/TS ecosystems, a shared package is named after the durable *thing it owns*, not after a constraint or invariant it enforces. The families: `<concept>-core`/`core` when shared semantics power multiple adapters (the most common choice for modular SDKs — TanStack, urql, Sentry, OTel, Smithy, AWS SDK); `-runtime` when the package executes durable runtime behavior (relay-runtime); `<domain>-util-to-<output>` / `<domain>-util-<verb>` for a precise pure transformation (the unified/remark ecosystem); a domain or data-model noun when the package owns an established concept (unified, vfile); `types` for a mostly-contracts package; `sdk`/product-noun for a broad distribution package (too broad an altitude for a scoped seam); and `toolkit` only when the package is intentionally batteries-included (risky for a narrow concept). The transferable rule: a name that describes a safety *constraint* (e.g. "bounded-read") reads as an invariant rather than a package-shaped thing and is weakly supported by prior art — use such phrasing as a documented invariant, not the package name; decide the name only after identifying which noun is genuinely durable in the domain's vocabulary. Keep the package boundary pure regardless of name (its input/output data shapes fixed, no auth/HTTP/filesystem/UI/host-specific concerns leaking in).
