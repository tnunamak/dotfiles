---
title: "Agent-experience shaping (field selection, bounded previews, detail-level control) belongs in REST API parameters so it is defined once, not duplicated per MCP/CLI client adapter — only response-format packaging (JSON envelope vs text-with-handles vs terminal table) stays client-specific"
date: 2026-08-14
topic: api-contract-design
tags: [mcp, cli, agent-experience, token-efficiency, field-selection, api-design, clig, gh-cli, expand-pattern]
status: draft
sources: [anthropic-writing-tools, anthropic-advanced-tools, anthropic-code-exec-mcp, openapi-mcp-strawgate, openapi-mcp-hackteam, openapi-mcp-fastmcp, aws-mcp-tool-design, atlassian-mcp-compression, workos-mcp-rest, stripe-expand, stripe-expand-usecases, google-aip157, google-drive-fields, jsonapi-sparse-fieldsets, clig-dev, gh-formatting-docs, arcjet-cli-agents, mindstudio-mcp-cli-tokens, sourcegraph-mcp]
source_session: unknown
---

<!-- Builds on api-contract-design/mcp-tool-surface-minimized-by-host-native-search-server-toolsets-and-grant-scope.md,
     which covers tool-COUNT/discovery shaping (toolsets, deferred loading, search/fetch). This entry covers
     PER-RESPONSE shaping (field selection, bounded previews, detail escalation) for a thin-client MCP+CLI pair
     over one REST API — a distinct axis from tool surface size. -->

## CLAIMS

### (a) Anthropic guidance + why naive API→tool conversion fails

- Anthropic's tool-writing guidance states LLM agents have limited context, unlike cheap/abundant computer memory, and recommends "implementing some combination of pagination, range selection, filtering, and/or truncation with sensible default parameter values"; Claude Code caps tool responses at 25,000 tokens by default, and truncated responses should carry steering instructions toward more targeted follow-up calls. [anthropic-writing-tools]
- Anthropic recommends tool responses "eschew low-level technical identifiers (for example: `uuid`, `256px_image_url`, `mime_type`)" in favor of names/fields that "directly inform agents' downstream actions" (e.g. `name`, `image_url`, `file_type`). [anthropic-writing-tools]
- Anthropic recommends a `response_format` enum parameter (e.g. `concise` / `detailed`) so the calling agent controls verbosity per call; their Slack example shows `concise` responses at roughly ⅓ the tokens of `detailed`. [anthropic-writing-tools]
- Anthropic's "Code execution with MCP" post argues agents should process large intermediate tool results in a code-execution sandbox rather than round-tripping everything through the model context, using a progressive-disclosure file-tree of tool definitions the agent explores on demand; the flagship example reduces a Google-Drive-to-Salesforce workflow from ~150,000 to ~2,000 tokens (98.7% reduction). [anthropic-code-exec-mcp]
- Anthropic's "advanced tool use" post extends the same on-demand-loading philosophy to tool *definitions* (not just responses), citing setups where 5 servers / 58 tools cost ~55K tokens before any work starts, motivating deferred schema loading and tool search. [anthropic-advanced-tools]
- Practitioners converting OpenAPI specs into MCP servers 1:1 (one tool per endpoint) consistently report the result is unusable for agents: one engineer's rewrite went from 1,200 auto-converted tools to 8 curated ones; the FastMCP OpenAPI-converter author wrote "your auto-generated MCP is bad, and you should feel bad" and that "an API built for a human will poison your AI agent"; Hackteam and others attribute the failure to the agent burning context reading tool descriptions, picking wrong-but-plausible tools, and chasing pagination loops across dozens/hundreds of atomic endpoints. [openapi-mcp-strawgate][openapi-mcp-fastmcp][openapi-mcp-hackteam]
- Root cause as framed by these practitioners: REST and MCP serve different consumers — a human developer reads docs once and is willing to chain calls forever, while an LLM agent re-reasons about tool choice on every call and has no persistent integration code, so raw endpoint-for-endpoint mirroring multiplies tool calls; one cited study of 1,899 MCP servers found API-wrapper-pattern servers averaged 5.3x more tool invocations per completed task than domain-optimized ones (unverified: single secondary citation, original study not independently located). [workos-mcp-rest][openapi-mcp-hackteam]

### (b) Concrete shipped token-efficiency techniques

- Atlassian ships four configurable **tool-description** compression levels — `full` (names + arguments + fuller descriptions), `brief` (names + arguments + one-line descriptions), `minimal` (names + argument names only), `none` (no embedded list; agent must call `list_tools()`) — measured on a 94-tool GitHub MCP scenario from 17,600 tokens (no compression) down to ~500 tokens (max compression); this compression targets tool *descriptions/discovery*, not response payloads — "the model still needs exact schemas before invocation." [atlassian-mcp-compression]
- AWS's MCP tool-design guidance recommends defaulting search/list tool responses to a small field subset sufficient for a decision (e.g. 5 of 50 available fields) and exposing a separate `get_resource_detail`-style tool for drill-down, reporting this on-demand-detail restructuring cuts response tokens by roughly two-thirds (citing Anthropic's research); it places this filtering logic explicitly "in your MCP server's tool definitions and response handlers, not downstream in client SDKs," reasoning that servers can validate/guarantee behavior in a way client-side conventions cannot. [aws-mcp-tool-design]
- GitHub's official MCP server ships server-owned `--toolsets` and `--tools` allow-lists and a read-only mode (documented in the prior corpus entry: `mcp-tool-surface-minimized-by-host-native-search-server-toolsets-and-grant-scope.md`) — this is tool-*surface* shaping, complementary to but distinct from per-response field shaping.
- Sourcegraph's MCP server ships an agentic "Code Finder" tool that runs its own search loop server-side and returns only matching file paths + line ranges + a short note, explicitly to avoid the calling agent spending its own context window on a manual search loop — an example of moving multi-step work behind one summarizing tool rather than exposing raw low-level search primitives. [sourcegraph-mcp]
- No shipped MCP server was found using a protocol-level standardized parameter literally named `detail_level`/`verbosity`; where it exists (AWS pattern, Anthropic's `response_format`), it is a bespoke per-tool parameter convention, not an MCP spec feature.

### (c) Shaping moving server-side (REST parameters) vs staying in adapters

- Stripe's `expand` request parameter is available on all API requests (list/create/update), lets a client replace a linked object's ID with the full nested object (e.g. `expand=payment_intent.customer`), supports multiple expansions and up to 4 levels of nesting, and by default some properties are omitted entirely unless expanded (e.g. Checkout Session `line_items`) — i.e. Stripe ships bounded-by-default responses with an explicit client-controlled escalation parameter, at the REST layer, shared by every client (dashboard, SDKs, CLI). [stripe-expand][stripe-expand-usecases]
- Google's `fields` partial-response parameter (legacy REST APIs) and its successor `FieldMask` (AIP-157, current Google Cloud/gRPC APIs) both let a client request a sub-tree of a response by an XPath-like or field-mask string; AIP-157 specifies the mask as a side-channel parameter (query param, header, or gRPC metadata) rather than an API-specific per-field flag, and specifies omission must default to `"*"` (full response) unless otherwise documented. [google-aip157][google-drive-fields]
- JSON:API's sparse-fieldsets convention (`?fields[type]=a,b,c`) and GraphQL's mandatory field selection solve the identical over-fetch problem at the protocol level; sparse fieldsets preserve HTTP cacheability that GraphQL's POST-based query bodies typically lose. One cited academic comparison (Brito et al. 2019) found GraphQL-style client-specified field selection cut response payload size 94% vs. equivalent REST, though this predates widespread JSON:API sparse-fieldset adoption in comparable REST services (comparison may be dated). [jsonapi-sparse-fieldsets]
- Direct disagreement exists on where MCP-specific shaping (summarization, enrichment, "friendly" natural-language recaps) belongs: WorkOS's MCP-from-REST guide places response *enrichment and summarization* explicitly in the MCP adapter layer ("this is also where you often want to enrich the response... your tool can return a friendly summary"), treating the MCP server as "a user-interface layer for AI agents" distinct from the REST API's developer-oriented shape — i.e. some shaping is agent-audience-specific packaging that a shared REST parameter cannot fully replace (a natural-language summary is not a field-selection problem). [workos-mcp-rest]
- Synthesizing (b)+(c): the field-selection/bounded-preview/pagination-default axis (what data comes back, how much) has strong precedent for living in the REST layer as a parameter, shared by every client (Stripe `expand`, Google `fields`/`FieldMask`, JSON:API sparse fieldsets); the audience-specific-packaging axis (natural-language summaries, escalation-handle framing, MCP-idiomatic response envelopes) has precedent for staying in the adapter, because it encodes what a *tool call* looks like to an LLM caller, which a generic REST client (curl, another service) should not be forced to receive.

### (d) CLI agent-experience prior art

- clig.dev (Command Line Interface Guidelines) predates the AI-agent era and frames its machine-readability guidance around scripts/pipelines, not LLM agents specifically, but its "Output" chapter already prescribes the exact mechanism this research question needs: "Have machine-readable output where it does not impact usability," "Display output as formatted JSON if `--json` is passed," and "If human-readable output breaks machine-readable output, use `--plain`" (one-record-per-line for `grep`/`awk`) — i.e. TTY-vs-piped detection as the switch between human and machine shaping, with human-first as the stated default philosophy ("Humans come first, machines second"). [clig-dev]
- GitHub CLI's `--json <fields>` flag requires an explicit comma-separated field list per command, and running a command with an empty `--json` value returns an error listing every valid field name for that command — a discovery mechanism functionally equivalent to GraphQL introspection or Stripe's "Expandable"-labeled docs, implemented as a CLI convention rather than a protocol feature. `--jq '<expr>'` (bundled jq implementation, no system jq required) and `--template` (Go template syntax with helpers like `truncate`, `tablerow`, `pluck`) let a caller reduce/reshape the selected fields further, entirely client-side after the server response returns full field data for the requested set only. [gh-formatting-docs]
- Arcjet's 2026 CLI-for-agents design post argues the core difference from human-facing CLI design is that agents lack judgment to route around bad output the way a human scans a table or notices a wrong suggestion, so agent-facing commands need API-grade rigor: stable command/flag contracts ("add a new command, but do not remove an old one"), distinct machine-parseable exit codes (e.g. 0 success / 2 auth error / 3 validation error / 4 confirmation-required), automatic format switching (TTY→text, non-TTY→JSON, with no flag required), local input validation before network calls, and explicit re-invocation commands embedded in confirmation-required responses rather than interactive prompts. [arcjet-cli-agents]
- Multiple 2026 vendor-benchmark blog posts (MindStudio, unverified vendor-authored benchmarks, methodology not independently confirmed) report CLI tool calls costing roughly 4–35x fewer tokens than equivalent MCP tool calls for the same task on GitHub-shaped workloads, attributing the gap to per-call MCP schema/description overhead vs. a CLI agent's zero-schema-cost invocation (the agent already "knows" `git`/`gh`/`curl`-shaped commands from pretraining) — cited figures (e.g. "35x", "72% vs 100% reliability") come from vendor blog benchmarks, not peer-reviewed or independently reproduced studies; treat magnitudes as directional, not exact. [mindstudio-mcp-cli-tokens]
- The same sources converge on "build a good CLI first, then wrap it as an MCP server," reasoning that a CLI that is pipeable, shell-testable, and stable already has the shape (structured stdout, exit codes, flags) an MCP tool needs, whereas the reverse (retrofitting agent-friendliness onto an ad hoc CLI) is harder; MCP is favored specifically for centralized auth/governance across many callers/users, which a bare CLI (inheriting the invoking session's credentials) does not provide by default. [mindstudio-mcp-cli-tokens][arcjet-cli-agents]
- No CLI-specific analog was found to MCP's `response_format: concise|detailed` enum or Atlassian's four-tier description-compression levels; the closest functional equivalents are (i) `--json <fields>` as a per-invocation bounded-preview mechanism (caller explicitly asks for less), and (ii) TTY-vs-piped default switching (Arcjet's proposal to default non-TTY output to JSON) as an implicit "agent mode" detector — neither is a documented, named "agent verbosity level" convention the way MCP compression levels are.

## SOURCES

**anthropic-writing-tools**
URL: https://www.anthropic.com/engineering/writing-tools-for-agents
Accessed: 2026-08-14
Quote: "implementing some combination of pagination, range selection, filtering, and/or truncation with sensible default parameter values"; "eschew low-level technical identifiers (for example: uuid, 256px_image_url, mime_type)"

**anthropic-advanced-tools**
URL: https://www.anthropic.com/engineering/advanced-tool-use
Accessed: 2026-08-14

**anthropic-code-exec-mcp**
URL: https://www.anthropic.com/engineering/code-execution-with-mcp
Accessed: 2026-08-14
Quote: "agents can load only the tools they need and process data in the execution environment before passing results back to the model"

**openapi-mcp-strawgate**
URL: https://strawgate.com/writing/openapi-tool-transformation/
Accessed: 2026-08-14
Quote: "one MCP tool per endpoint per verb... is not a tool surface... it's a phone book"

**openapi-mcp-hackteam**
URL: https://hackteam.io/blog/stop-converting-openapi-specs-mcp-servers/
Accessed: 2026-08-14

**openapi-mcp-fastmcp**
URL: https://jlowin.dev/blog/stop-converting-rest-apis-to-mcp
Accessed: 2026-08-14
Quote: "your auto-generated MCP is bad, and you should feel bad"; "an API built for a human will poison your AI agent"

**aws-mcp-tool-design**
URL: https://aws.amazon.com/blogs/machine-learning/mcp-tool-design-practical-approaches-and-tradeoffs/
Accessed: 2026-08-14
Quote: "A tool that returns 50 fields per result fills context quickly. If 5 are sufficient for a decision, default the response to those fields and provide a separate option to request a detailed view."

**atlassian-mcp-compression**
URL: https://www.atlassian.com/blog/development/mcp-compression-preventing-tool-bloat-in-ai-agents
Accessed: 2026-08-14

**workos-mcp-rest**
URL: https://workos.com/blog/designing-mcp-server-from-rest-api
Accessed: 2026-08-14
Quote: "This is also where you often want to enrich the response... Your tool can return a friendly summary"; "The MCP server is a user-interface layer for AI agents"

**stripe-expand**
URL: https://docs.stripe.com/expand
Accessed: 2026-08-14

**stripe-expand-usecases**
URL: https://docs.stripe.com/expand/use-cases
Accessed: 2026-08-14

**google-aip157**
URL: https://google.aip.dev/157
Accessed: 2026-08-14

**google-drive-fields**
URL: https://developers.google.com/workspace/drive/api/guides/fields-parameter
Accessed: 2026-08-14

**jsonapi-sparse-fieldsets**
URL: https://nordicapis.com/how-does-jsonapi-compare-to-rest-and-graphql/
Accessed: 2026-08-14

**clig-dev**
URL: https://clig.dev/
Accessed: 2026-08-14
Quote: "Have machine-readable output where it does not impact usability"; "If human-readable output breaks machine-readable output, use --plain"; "Humans come first, machines second"

**gh-formatting-docs**
URL: https://cli.github.com/manual/gh_help_formatting
Accessed: 2026-08-14
Quote: "The --json flag requires a comma separated list of fields to fetch. To view the possible JSON field names for a command omit the string argument to the --json flag when you run the command."

**arcjet-cli-agents**
URL: https://blog.arcjet.com/designing-a-cli-for-ai-agents/
Accessed: 2026-08-14
Quote: "Add a new command, but do not remove an old one. Add a new flag, but do not change the meaning of an existing flag."; "When stdout is a TTY, text output is the default. When stdout is not a TTY, JSON output is the default."

**mindstudio-mcp-cli-tokens**
URL: https://www.mindstudio.ai/blog/mcp-vs-cli-agentic-workflows-token-overhead-reliability
Accessed: 2026-08-14
Quote: "35x more tokens than equivalent CLI tools on identical tasks, with reliability dropping from 100% to 72%" (vendor-authored benchmark, unverified methodology)

**sourcegraph-mcp**
URL: https://sourcegraph.com/mcp
Accessed: 2026-08-14

## SYNTHESIS

This corpus entry extends `mcp-tool-surface-minimized-by-host-native-search-server-toolsets-and-grant-scope.md` (which covers *how many tools* an agent sees) into *what one tool call returns*. The two axes compose independently and PDPP already has both: toolset/grant-scope shaping (out of scope here) and per-response shaping (bounded previews, content ladders, escalation handles — in scope here).

**The load-bearing distinction for PDPP's decision is: does the shaping decide WHAT DATA comes back, or HOW IT'S PACKAGED for a specific calling convention?**

- **What-data-comes-back is a REST API concern, and belongs there once.** Stripe (`expand`), Google (`fields`/`FieldMask`), and JSON:API (sparse fieldsets) are all mature, load-bearing precedent for shipping field selection, default-bounded payloads, and explicit escalation as REST parameters consumed identically by every client — dashboard, SDK, CLI, and (today, retrofitted) MCP. Anthropic's and AWS's tool-design guidance is compatible with this: their examples ("default to 5 of 50 fields," "eschew `uuid`/`mime_type`," "sensible truncation defaults") describe response *shapes* a REST endpoint could just as easily produce via a `fields=` or `detail=summary|full` query parameter as an MCP adapter could produce by post-filtering a full REST response. For PDPP specifically: a bounded preview of a 2MB record is fundamentally "return N fields / M bytes of this resource, plus a way to ask for more" — that is exactly what `expand`/`fields`/`FieldMask` solve, and solving it once in the REST API means the CLI's "rawer output" stops being a maintenance liability (it becomes "CLI defaults to `detail=full`, agent tooling defaults to `detail=preview`" — one code path, two default parameter values) instead of a second, silently-drifting shaping implementation.
- **How-it's-packaged is a client-adapter concern, and should stay there.** An MCP tool result is not just "smaller JSON" — it is JSON-RPC-shaped, carries an escalation *handle* the calling LLM can quote back in a follow-up tool call, and (per Anthropic's `response_format` and WorkOS's "friendly summary" pattern) sometimes needs a natural-language recap that a REST client has no protocol to request. A CLI has a parallel but different packaging concern: TTY-vs-piped detection (clig.dev, Arcjet), `--json <fields>`-style caller-driven reduction, and stable machine-parseable exit codes — none of which a REST API can express, because they're properties of a terminal invocation, not an HTTP response. Trying to push "emit a JSON-RPC content block with an escalation handle" or "detect whether stdout is a TTY" down into the REST API would be a category error; those aren't data-shaping decisions, they're calling-convention decisions.

**Recommendation for PDPP**, mapped to the owner's stated goal (minimal duplicate/competing code, maximally effective agent tools):

1. **Move bounded-preview/content-ladder field selection into REST API parameters** (e.g. `?detail=preview|full` or a Google-style `fields=` mask on read endpoints), with `preview` as the default and `full` opt-in. This is the one change with the highest leverage: every client (MCP, CLI, any future client) gets bounded-by-default responses for free, and the "2MB record becomes a safe snippet" behavior stops being MCP-only — today the CLI's "rawer output" is arguably a bug from an agent-experience standpoint (a CLI-driving agent hits the same 2MB-into-context problem the MCP shaping library exists to prevent), and this fix is the one that fixes it at the root rather than duplicating the shaping library into a second (CLI) adapter.
2. **Keep the escalation-handle mechanism (the ability to name a bounded preview and fetch more of it later) in the shared adapter library, not duplicated per-client** — but change what it wraps: once the REST API returns bounded previews natively, the adapter's job shrinks to "mint a handle referencing the request that produced this preview" and "given a handle, replay that request with `detail=full`" — the same library can back both the MCP tool (returning a JSON-RPC content block with the handle) and a CLI flag (`--handle <id>` or `--full`) without re-implementing bounding logic twice, because the bounding already happened server-side.
3. **Let MCP and CLI diverge only in packaging, not in data shape**: MCP tools should default to `preview` and communicate `response_format`-style detail control per Anthropic's guidance (a `detail` tool parameter mapped straight through to the REST `detail=` parameter — no adapter-side re-implementation of truncation); the CLI should default to `full` for a human at a terminal (clig.dev's human-first default) but detect non-TTY invocation and default to `preview` + a `--json <fields>` / `--detail full` escalation path for agent callers, mirroring `gh`'s field-selection convention and Arcjet's TTY-detection proposal. This gives agent-driven CLI usage the same bounded-by-default behavior the MCP tool has, without writing a second shaping engine — the CLI's flag parsing just calls the same REST `detail=`/`fields=` parameters the MCP adapter calls.
4. **Do not move natural-language summarization or MCP-envelope framing into the REST API.** Those remain adapter/CLI-formatting responsibilities respectively, because they are audience-specific packaging (an LLM tool result vs. a terminal table vs. a generic REST JSON body), not data-quantity decisions — pushing them into the API would burden every non-agent REST consumer (webhooks, internal services, third-party integrators) with agent-shaped response conventions they don't want.

**Unverified / treat with caution:** the specific "35x tokens" / "5.3x tool calls" / "72% vs 100% reliability" figures cited above come from vendor blog posts (MindStudio, a Medium citation of an unnamed "Queen's University" study) without located primary sources or reproduced methodology — use them only as directional evidence that naive MCP wrapping and CLI-vs-MCP overhead are real, not as precise benchmarks. The CLI agent-experience research area (d) is thinner in named vendor engineering practice than areas (a)-(c); Arcjet's post is the strongest single primary source found and should be treated as one team's opinionated design, not settled consensus — clig.dev itself never addresses LLM agents (it predates them) and its relevance here is an extrapolation (TTY/plain-output detection generalizes to "agent output mode" detection), not a stated purpose of the document.
