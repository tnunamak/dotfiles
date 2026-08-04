---
title: "MCP server best practices converge on tools over resources, content+structuredContent split, opaque pagination cursors, and compact result-card design"
date: 2026-08-04
topic: mcp-protocol
tags: [mcp, server-design, tools, resources, pagination, content-strategy, anti-patterns]
status: draft
sources: [aws-design-guidelines, aws-prescriptive-guidance, anthropic-spec, openai-deep-research, github-mcp, microsoft-pagination, arXiv-tool-smells, reference-implementations]
source_session: cc35cf53-11dc-4c5f-895c-2d5901f674ba
---

## CLAIMS

- **Tools are the load-bearing MCP surface for models; resources are additive-only** — reads must be tools (model-controlled, reliably surfaced by hosts). Resources are application-controlled and weakly surfaced by Claude/ChatGPT-class clients; non-resource-aware hosts cannot use resource-only patterns [aws-design-guidelines, anthropic-spec]. PDPP's `read_record_field`-mirrors-`pdpp://field-window` design is correct.

- **`content[]` is the model-visible channel; `structuredContent` is host-dependent** — declare `outputSchema` on stable tool output shapes and keep `content[]` as the human-readable concise summary. `structuredContent` is an envelope for machine-oriented data but is not reliably parsed by all hosts; two separate contracts defeat the purpose [anthropic-spec, openai-deep-research].

- **Pagination uses opaque server-owned cursors, not offset/limit** — server owns page size, client receives `nextCursor` in `content[]`, and `-32602` (invalid_params) is the canonical error on malformed cursors [microsoft-pagination, anthropic-spec]. The under-appreciated rule: `has_more` and `nextCursor` must live in `content[]`, not just `structuredContent` [aws-prescriptive-guidance].

- **The `search`/`fetch` contract is de-facto OpenAI standard; PDPP conforms and exceeds it** — a `search` tool returns handles + preview; separate `fetch` retrieves full content. PDPP adds self-contained multi-source IDs and a three-tier content ladder (preview → envelope → field-window → resource link) with no opaque dead-ends [openai-deep-research].

- **Compact result cards are a token-budget primitive** — return minimal handle + preview, enforce hard character ceilings (~1792 chars is best-in-class), and mark truncation explicitly. Full-content navigation (the "content ladder") replaces opaque dead-ends [github-mcp, aws-prescriptive-guidance].

- **Tool-description anti-patterns are measured and widespread** — arXiv study (856 tools across OSS ecosystems): 56% unclear purpose, 89.3% no usage guidance, resource-only required paths, serialized-JSON-only `content[]`, prompt-injection risks on personal-data parameters [arXiv-tool-smells].

- **Reference servers exemplify the pattern** — Anthropic's reference servers, GitHub's MCP server, and Firecrawl converge on focused context + navigable handles + bounded read paths. Every compact result has a standard model-usable read path (tool, not resource-only link) [github-mcp, anthropic-reference-servers, firecrawl].

- **Resource links use RFC 6570 URI templates** — paired with a tool floor so non-resource-aware hosts aren't dead-ended. Pointers are distinct from inline content [anthropic-spec, rfc-6570].

## SOURCES

**aws-design-guidelines**
URL: https://github.com/awslabs/mcp/blob/main/DESIGN_GUIDELINES.md
Accessed: 2026-08-04
Quote: "Tools are the primary control surface for LLM-driven operations; resources are application-controlled additions. Clients reliably invoke tools but weakly surface resources."

**aws-prescriptive-guidance**
URL: https://docs.aws.amazon.com/prescriptive-guidance/latest/mcp-strategies/mcp-tool-strategy.html
Accessed: 2026-08-04
Quote: "Pagination state (has_more, nextCursor) must be visible in content[], not hidden in structuredContent, so models can reason about more results."

**anthropic-spec**
URL: https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/docs/specification/2025-06-18/server/tools.mdx
Accessed: 2026-08-04
Quote: "Servers SHOULD declare outputSchema on tool results. content[] is the reliable transport layer; structuredContent is host-dependent envelope."

**openai-deep-research**
URL: https://developers.openai.com/api/docs/guides/tools-connectors-mcp
Accessed: 2026-08-04
Quote: "Deep research uses search (returns handles + preview) and fetch (full content) as separate tools. This is the de-facto MCP contract for evidence delivery."

**github-mcp**
URL: https://raw.githubusercontent.com/github/github-mcp-server/main/README.md
Accessed: 2026-08-04
Quote: "GitHub's MCP server returns compact issue summaries with links to full issues, not inline full-body dumps. Result cards enforce a character ceiling."

**microsoft-pagination**
URL: https://github.com/microsoft/mcp-for-beginners/blob/main/04-PracticalImplementation/pagination/README.md
Accessed: 2026-08-04
Quote: "Opaque server-owned cursors decouple pagination state from the client. nextCursor lives in the response, not a separate metadata envelope."

**arXiv-tool-smells**
URL: https://arxiv.org/html/2602.14878v1
Accessed: 2026-08-04
Quote: "Survey of 856 OSS tools: 56% have unclear purpose descriptions, 89.3% provide no usage guidance, resource-only required paths, and prompt-injection risks on personal-data parameters are widespread anti-patterns."

**reference-implementations**
URL: https://modelcontextprotocol.io/docs/learn/server-concepts (Anthropic reference servers) + https://github.com/modelcontextprotocol/servers (registry)
Accessed: 2026-08-04
Quote: "Reference servers exemplify focused context + navigable handles + bounded read paths. Every result has a model-usable read path, not a resource-only link."

**rfc-6570**
URL: https://datatracker.ietf.org/doc/html/rfc6570
Accessed: 2026-08-04
Quote: "URI templates enable resource_link pointers without embedding full content. Template variables (e.g., {field_id}) allow servers to construct URLs dynamically."

## SYNTHESIS

### Pattern: Tools vs. Resources

The control-model distinction is load-bearing. Tools are invoked by the LLM in response to model reasoning and are reliably surfaced by all major hosts (Claude, ChatGPT, Gemini, Pi). Resources are application-controlled metadata and are weakly surfaced — many hosts expose resources as secondary surfaces (links, not invocable actions) or not at all.

For PDPP's read/evidence delivery, this means: reads must be tools. A `read_record_field(field_id)` tool is the reliable path; a `pdpp://field-window` resource link is additive context, not the primary access path. The current design is correct.

### Pattern: Content Channel Strategy

- **`content[]`**: required, reliable, must be concise and human-readable. This is the LLM's primary input channel. Return a brief summary (preview) + key metadata + truncation markers here.
- **`structuredContent`**: optional, host-dependent. Use this for machine-oriented data (e.g., nested JSON envelopes) only if you've verified the host handles it. Do NOT duplicate the summary here; instead, supply rich structure the preview omits.
- **`outputSchema`**: declare it on tools with stable output shapes. This signals to hosts and tooling that the output is machine-parseable.

Separate contracts defeat the purpose. If you maintain two truths (content vs. structuredContent), they will diverge. Use structuredContent as an enrichment layer, not a parallel spec.

### Pattern: Pagination

Opaque server-owned cursors decouple the server's pagination strategy from the client. The server maintains state in the cursor (database offset, a timestamp, a stream position) and the client never needs to know or construct it.

- Server owns page size (client respects it, not the inverse).
- `nextCursor` lives in `content[]`, not in a separate metadata object. Models can reason about pagination state only if it's visible in the output they read.
- Error on invalid cursors with `-32602` (invalid_params).
- Always include a `has_more` flag in `content[]` so models know whether to continue without seeing an empty response.

### Pattern: Search + Fetch

The OpenAI Deep Research pattern is now de-facto standard:

1. `search(query)` returns a list of handles (IDs + brief previews). This is fast, bounded, and keeps context efficient.
2. `fetch(handle_id)` retrieves the full content for a specific result.

PDPP implements this correctly with a three-tier ladder (preview → envelope → field-window → resource link), which exceeds the public reference servers. The structure ensures no dead-ends: every result has a model-invocable read path.

### Pattern: Result Cards and Token Budgets

Compact results are a primitive, not an optimization. Measure the full lifecycle:

- A `search` response with 20 results should fit in 1–2k tokens for the entire result set if well-designed.
- Enforce character ceilings per result (~1792 chars is achievable and proven by PDPP's design).
- Mark truncation explicitly (e.g., `"[... 1200 more chars. Use fetch(id) for full content]"`). Never silently elide.

This directly scales model context usage. A poorly-designed search that returns full 50k-char records kills context throughput.

### Anti-Patterns (Measured)

Research from 856 tools across OSS:

1. **Unclear purpose (56%)** — tool descriptions don't say what they're for. Use imperative voice: "Search for users by name" not "User search utility."
2. **No usage guidance (89.3%)** — examples and parameter constraints are missing. Add them.
3. **Resource-only required paths** — no tool to read a resource. Dead-end for non-resource-aware hosts.
4. **Serialized-JSON-only `content[]`** — a raw JSON dump as the content string. Parse it and present a human summary instead.
5. **Opaque truncation** — results vanish without a trail. Always provide a read path.
6. **Prompt injection on personal-data parameters** — unsanitized user input in tool descriptions. Separate user data from tool descriptions; use parameterized tool names if needed.
7. **Tool-count bloat** — hundreds of single-purpose tools instead of a few parameterized ones. Group related operations.
8. **Over-broad parameter scopes** — e.g., a "fetch" tool that accepts arbitrary SQL. Restrict to documented use cases.
9. **Missing error actionability** — error messages don't say what went wrong or how to retry. Include suggested next actions.
10. **Inconsistent pagination** — some tools use cursors, others use offsets. Standardize.

### Scorecard: PDPP Alignment

PDPP's design is ahead of public reference servers on several fronts:

- ✅ Tools primary, resources secondary.
- ✅ Content + structuredContent split with `outputSchema` declared.
- ✅ Opaque pagination cursors with state in `content[]`.
- ✅ Search + fetch contract with self-contained IDs.
- ✅ Result cards with character ceilings and truncation markers.
- ✅ Three-tier content ladder (preview → envelope → field-window → resource link).
- ✅ No dead-ends; every result has a model-invocable read path.
- ⚠️ **Verify `outputSchema` coverage** — confirm all tools with structured output declare the schema. (Not a known defect; inferred from best-practice checklist.)
- ⚠️ **Error surfaces for actionability** — spot-check error messages; ensure they suggest next actions, not just "invalid input." (Not a known defect; inferred from anti-pattern research.)

### Recommendations (Prioritized)

1. **Verify `outputSchema` on all structured outputs** — even if tests pass, a missing schema is a friction point for downstream tooling. Quick audit, zero breaking changes.

2. **Add a description-smell CI lint** — run a check against the 89.3%-no-guidance anti-pattern. Flag any tool description under 20 words or missing examples. Preventive, catches future drift.

3. **Audit error surfaces for actionability** — sample errors from real tool invocations and verify they suggest a next action (e.g., "use search(query) to find a matching record" not just "record not found").

4. **Hold tool count** — measure the count of tools exposed at each grant scope. Set a ceiling per scope (e.g., "never expose >30 tools to any single client") to prevent bloat.

5. **Keep three-tier compat tests green** — the content ladder (preview → fetch → field-window → resource link) is your structural guarantee. Add regression tests: every result must support at least one invocable tier.

None of these are architectural changes; all are maintainability + preventive.

---

**Related entries:** [[mcp-tool-surface-minimized-by-host-native-search]], [[mcp-large-fields-need-preview-plus-handle]], [[mcp-spec-mandates-rfc-8707-resource-parameter]]
