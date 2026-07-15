---
title: "Pi custom compaction can preserve Pi boundaries and metadata while using a bounded direct completion with reasoning off"
date: 2026-07-13
topic: llm-integration
tags: [pi, compaction, context-window, reasoning, extensions]
status: draft
sources: [pi-compaction-docs, pi-custom-compaction-example, pi-issue-92]
---

## CLAIMS

- Pi exposes `session_before_compact`; an extension can return a custom summary while retaining `firstKeptEntryId`, `tokensBefore`, and custom `details`. [pi-compaction-docs]
- Pi's supplied custom-compaction extension example resolves auth through the model registry, passes the hook abort signal to the completion, caps output tokens, and falls back when no usable summary is returned. [pi-custom-compaction-example]
- Pi documents the default trigger as `contextTokens > contextWindow - reserveTokens`, with defaults of 16,384 reserve tokens and 20,000 recent tokens retained. [pi-compaction-docs]
- Pi's compaction design calls for direct `pi-ai` summarization with no tools and reasoning disabled; it recommends a finite output budget under the reservation. [pi-issue-92]

## SOURCES

**pi-compaction-docs**
URL: https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/compaction.md
Accessed: 2026-07-13

**pi-custom-compaction-example**
URL: https://github.com/earendil-works/pi/blob/main/packages/coding-agent/examples/extensions/custom-compaction.ts
Accessed: 2026-07-13

**pi-issue-92**
URL: https://github.com/earendil-works/pi/issues/92
Accessed: 2026-07-13

## SYNTHESIS

For a reasoning-capable local model, use the hook instead of patching Pi: preserve Pi's cut point and file-operation details, make one direct no-tools completion with reasoning omitted/off and a finite cap, and make abort/error behavior explicit. An earlier trigger must be derived from the advertised context window and actual response/summary headroom, not the default alone.
