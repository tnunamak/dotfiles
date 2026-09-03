---
title: "For a CLI whose consumers are shell-having coding agents, the evidence favors CLI + one Skill (+ an optional SessionStart push) over an MCP server — vendors including Microsoft steer agents away from their own MCP servers, every agent-supervisor competitor with an agent-driven design ships zero query-oriented MCP tools, and the query surface's two hard problems (graded evidence classes, absence vs non-coverage) are solved by making both structural and unconditional, as Elasticsearch `_shards` did and the obsoleted HTTP `Warning` header failed to"
date: 2026-08-21
topic: agentic-cli-design
tags: [mcp, cli-design, agent-skills, hooks, push-vs-pull, provenance, coverage-reporting, fleet-query, waspflow]
status: draft
sources: [mcp-usbc, mcp-scope, mcp-stateless, mcp-own-admission, mcp-threshold, mcp-cache-trap, anthropic-no-wrap, anthropic-consolidate, anthropic-98, anthropic-sandbox-cost, skills-vs-mcp, playwright-reversal, cloudflare-both, stripe-both, sentry-scope, sentry-oauth-why, neon-both, supabase-npx-pain, ronacher-flaws, ronacher-walkback, holmes-hn, cramer-rebuttal, willison-shift, zechner-wash, stripe-codemode, scalekit-caveat, per-tool-token, config-frag, glab-agent-info, skills-definition, skills-progressive-disclosure-3-level, skills-body-loads-lazily, skills-scripts-executed-not-loaded, skills-complement-mcp, skills-allowed-tools-preapproval, skills-content-lifecycle-sticky, skills-dynamic-context-injection, slash-commands-merged, hooks-stdout-injection, hooks-additionalcontext, codex-has-skills, codex-has-hooks, codex-agents-md, otel-env-carriers, w3c-tracecontext, agents-md-site, twelvefactor-config, gastown-verbs, gastown-prime-hook, gastown-polecat-safe, gastown-skills, gastown-json, vibekanban-mcp, vibekanban-mcp-modes, vibekanban-get-context, codex-mcp-two-tools, claude-squad-tui, agentapi-http, cmux-skills, systemd-orthogonal-columns, systemd-notfound-vs-inactive, systemd-default-hides-coverage, systemd-coverage-hint-footer, systemd-json-drops-coverage, systemd-output-stability, docker-json-truncates, docker-json-stringly-typed, docker-empty-vs-error, git-plumbing-porcelain, git-porcelain-guarantee, git-porcelain-v2-extensible, git-if-then, kubectl-field-selector-limits, kubectl-no-resources-stderr, kubectl-no-resources-on-error, kubectl-sortby-false-empty, k8s-remaining-item-count, es-shards-envelope, es-shards-field-defs, es-skipped-underdocumented, es-timed-out, es-allow-partial, thanos-partial-response, thanos-warning-not-partial, prom-warnings-with-success, prom-up-metric, prom-staleness, dns-nodata-vs-nxdomain, rfc8020-nxdomain-scope, http-404-hides-403, http-204, graphql-data-and-errors, graphql-request-vs-field-errors, graphql-path-disambiguates-null, graphql-null-propagation, trino-no-partial-state, bigquery-errors-nonfatal, bigquery-jobcomplete, http-warning-obsoleted, http-warning-rationale, http-warn-codes, http-age-header, http-age-absence-asymmetry, http-stale-if-error, http-content-location, dnssec-ad-bit, dnssec-ad-is-a-claim, dnssec-cd-bit, slsa-graded-levels, slsa-l1-incomplete, intoto-subject-predicate, otel-status-unset, w3c-sampled-flag, codd-a-marks-i-marks, codd-rejected-for-complexity, nulls-open-world, nist-uncertainty]
source_session: b9e12532-351b-43c0-a858-171dee902cb9
---

<!--
Written to inform a concrete waspflow decision: it records lane provenance with a graded
evidence class but has no fleet-scale reverse lookup. Question was "beyond CLI subcommands,
is there value in ALSO exposing this via MCP / skills / hooks?" Competitor claims are cited
file:line against repos cloned to ~/.tmp/wf-competitor-research/ on 2026-08-21 (HEAD of
default branch; the earlier sweep's clones were gone and were re-cloned for this entry).
-->

## CLAIMS

### Part 1a — what MCP claims to solve, and its documented costs

- MCP's own introduction frames the protocol as a standardization / M×N integration play ("a USB-C port for AI applications", "build once and integrate everywhere") and makes **no efficiency claim** relative to a CLI an agent can already shell out to. [mcp-usbc]
- The MCP architecture doc explicitly places context cost out of scope: "MCP focuses solely on the protocol for context exchange—it does not dictate how AI applications use LLMs or manage the provided context." [mcp-scope]
- As of protocol version `2026-07-28` MCP is specified as **stateless**: "Every request carries the protocol version and the capabilities relevant to that request in its `_meta` field", and `sampling` and `logging` are deprecated. This reverses the earlier stateful-session model and is a version-skew hazard for already-shipped servers. [mcp-stateless]
- MCP's own client best-practices doc concedes the central criticism: "Loading every tool definition into the model's context window upfront wastes tokens, increases latency, and degrades model performance", illustrated as ~150,000 tokens upfront vs ~2,000 with progressive discovery. [mcp-own-admission]
- The same doc gives a concrete switch-over threshold — implement one "as a percentage of the context window. For example, 1%-5%" — and states that below it "loading all tools is fine." [mcp-threshold]
- Progressive tool discovery can cost *more* than it saves: "Adding or removing tool definitions mid-conversation invalidates that cache, and the resulting miss can cost more tokens than the definitions you removed." [mcp-cache-trap]
- Anthropic's tool-authoring guidance is the closest thing to an official "when not to build one": "More tools don't always lead to better outcomes. A common error we've observed is tools that merely wrap existing software functionality or API endpoints—whether or not the tools are appropriate for agents." [anthropic-no-wrap]
- Anthropic recommends few deep tools over many shallow ones ("Instead of implementing a `list_users`, `list_events`, and `create_event` tools, consider implementing a `schedule_event` tool"), and notes Claude Code caps tool responses at 25,000 tokens by default. [anthropic-consolidate]
- Anthropic's code-execution-with-MCP post reports "a time and cost saving of 98.7%" (150,000 → 2,000 tokens) but states the offsetting cost plainly: "Running agent-generated code requires a secure execution environment with appropriate sandboxing, resource limits, and monitoring. These infrastructure requirements add operational overhead and security considerations that direct tool calls avoid." [anthropic-98] [anthropic-sandbox-cost]
- Anthropic positions Agent Skills as the low-context alternative: Level-1 metadata is ~100 tokens per skill, bodies (<5k) load only on trigger, bundled files "cost zero tokens" until read, so "you can install many Skills without context penalty." [skills-vs-mcp]
- Per-tool schema cost is reported by a third-party analysis at "550-1,400 tokens for its name, description, JSON schema, field descriptions, enums, and system instructions", with ~40 tools across GitHub/Slack/Sentry ≈ 55,000 tokens before the first user message. BLOG, not measured by a vendor. [per-tool-token]
- Per-harness MCP configuration is genuinely fragmented across vendors: Claude Code uses `~/.claude.json` + `.mcp.json`; Cursor `~/.cursor/mcp.json` with an `mcpServers` key; Codex uses **TOML** (`~/.codex/config.toml`, `[mcp_servers.<name>]`); Zed uses `context_servers`. Same server, four config shapes. [config-frag]
- Supabase documented the local-stdio operational failure modes first-hand: users needed Node "configured correctly so that the correct version was used by each client (if you used `nvm`)", "Every operating system also had slight differences that required modifying the `npx` command accordingly", and PATs were "easy to accidentally commit... to source control." [supabase-npx-pain]

### Part 1b — teams that shipped BOTH a CLI and an MCP server

- **Microsoft steers coding-agent users away from its own MCP server.** The `microsoft/playwright-mcp` README recommends the CLI+skills path for coding agents: "CLI invocations are more token-efficient: they avoid loading large tool schemas and verbose accessibility trees into the model context." The server itself defines 67 tools. Microsoft keeps MCP for shell-less/sandboxed hosts. [playwright-reversal]
- Cloudflare shipped the MCP server *first* and the CLI after, and states "agents love CLIs"; they treat CLI, bindings, SDKs, Terraform, docs and Agent Skills as deliberate redundancy rather than an either/or, noting "There's a lot more surface area to cover." Code Mode MCP exposes their whole API in "less than 1,000 tokens." [cloudflare-both]
- Stripe lists CLI, MCP, Skills and plugins as **peer** agent surfaces bundled behind one setup command: "The plugin configures MCP, includes Stripe-maintained skills and tools." [stripe-both]
- Sentry scopes its MCP deliberately rather than mirroring the API: "Sentry's MCP service is primarily designed for human-in-the-loop coding agents." It was built remote-first because local stdio "involves cloning repos, managing config file paths" and "Making people create API tokens and pass them around is… not great. Support for OAuth was necessary." [sentry-scope] [sentry-oauth-why]
- Neon ships both and documents them as alternatives: "Your AI agent can interact with Neon via MCP tools or by running Neon CLI commands directly." [neon-both]
- The strongest **pro-MCP** rebuttal comes from a vendor who shipped both: Sentry's co-founder argues "The ability to steer the LLM is the entire value prop of MCP tools" — responses shaped in Markdown/XML with embedded hints and minimized params — and argues *against* progressive disclosure because it hides that steering context: "We cannot prevent context rot, so you need to embrace consuming context." BLOG. [cramer-rebuttal]
- The best-known "just use the CLI" argument (Ronacher) rests on composability and context — MCP "isn't truly composable. Most composition happens through inference", "demands too much context", and "I can run and debug a script, I cannot even figure out how to reliably do MCP calls" — but its claim that `gh` "uses context far more efficiently" is **explicitly unquantified**. BLOG. [ronacher-flaws]
- **The same author walked it back six weeks later**, and the axis he lands on is statefulness, not protocol: CLI tools "are sometimes platform-dependent, version-dependent, and at times undocumented" and "doing multiple turns is very hard with CLI tools because you need to teach the agent how to manage sessions"; "What is stateful out of the box, however, is MCP." His fix is one stateful "ubertool" MCP server. BLOG. [ronacher-walkback]
- The pragmatic ordering rule, from a widely-read post: "If you're a company investing in an MCP server but you don't have an official CLI, stop and rethink what you're doing. Ship a good API, then ship a good CLI" — while conceding "If a tool genuinely has no CLI equivalent, MCP might be the right call." BLOG. [holmes-hn]
- Simon Willison reports building "small custom CLI tools specifically for Claude Code and Codex CLI to use" and that giving an agent `gh` "gains all of that functionality for a token cost close to zero." BLOG. [willison-shift]
- **Two controlled benchmarks contradict the "CLI always wins" narrative.** In a 120-run study (3 tasks × 4 tools × 10 reps) against a tool built with *both* interfaces, MCP was 2.5% cheaper and 23% faster (51 vs 66 min), with both at 100% success; the author's conclusion was "it doesn't matter as much as you'd think... The protocol is just plumbing." A mechanism is identified: Claude Code runs a Haiku malicious-command check on every bash call, which MCP bypasses. BLOG. [zechner-wash]
- In a 12-task Stripe suite (Claude Sonnet 4.6, 12/12 pass on all arms) the **CLI was the most expensive** modality: 711,555 tokens ($2.22) vs raw MCP 506,970 vs Code Mode MCP 294,924 ($0.98); `create_invoice` took 19 LLM turns via CLI vs 4 via Code Mode. CLI's per-call advantage erodes on chained multi-step writes. BLOG. [stripe-codemode]
- A third benchmark's headline figures are **not reproducible from its own published methodology**: the blog claims 4–32× and 72% MCP reliability, while the repo README says 1.3×–80× and "Both modalities achieve 100% task completion"; its pre-registered hypothesis (that MCP would use fewer tokens) was refuted by its own data. Treat as unsubstantiated. BLOG + repo. [scalekit-caveat]

### Part 1c — harness-native surfaces (skills, slash commands, hooks)

- Agent Skills are "Organized folders of instructions, scripts, and resources that agents can discover and load dynamically to perform better at specific tasks." OFFICIAL. [skills-definition]
- Loading is three-level: `name`+`description` of every installed skill enter the system prompt at startup; the full `SKILL.md` body loads only "If Claude thinks the skill is relevant to the current task"; bundled files are a third level Claude "can choose to navigate and discover only as needed." OFFICIAL. [skills-progressive-disclosure-3-level]
- "Unlike CLAUDE.md content, a skill's body loads only when it's used, so long reference material costs almost nothing until you need it." OFFICIAL. [skills-body-loads-lazily]
- **A skill is the documented vehicle for driving an existing CLI/script**: the canonical layout annotates `scripts/helper.py (utility script - executed, not loaded)`, with the rationale that "sorting a list via token generation is far more expensive than simply running a sorting algorithm" and "many applications require the deterministic reliability that only code can provide." OFFICIAL. [skills-scripts-executed-not-loaded]
- Anthropic states skills and MCP are complementary, not competing: "Skills can complement Model Context Protocol (MCP) servers by teaching agents more complex workflows that involve external tools and software." OFFICIAL. [skills-complement-mcp]
- A skill can pre-approve its own bundled command so it runs without a permission prompt: `allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/render.sh *)` — "The `allowed-tools` rule then matches the exact command the skill body tells Claude to run, so the script runs without prompting." OFFICIAL. [skills-allowed-tools-preapproval]
- Skill bodies are snapshot-at-invoke and sticky: "the rendered `SKILL.md` content enters the conversation as a single message and stays there for the rest of the session... Claude Code does not re-read the skill file on later turns." Re-invocation with changed arguments or changed dynamic-command output does append fresh content. OFFICIAL. [skills-content-lifecycle-sticky]
- Skills have a **built-in push channel**: the ``!`<command>` `` syntax "runs shell commands before the skill content is sent to Claude. The command output replaces the placeholder, so Claude receives actual data, not the command itself." It does not function in claude.ai chat or through the API. OFFICIAL. [skills-dynamic-context-injection]
- Slash commands are no longer a separate mechanism: "**Custom commands have been merged into skills.** A file at `.claude/commands/deploy.md` and a skill at `.claude/skills/deploy/SKILL.md` both create `/deploy` and work the same way." Docs state "Skills are recommended." OFFICIAL. [slash-commands-merged]
- **The premise "hooks are for reacting to events, not for querying" is REFUTED as stated.** Three events push hook stdout directly into model-visible context: "For most events, stdout is written to the debug log but not shown in the transcript. The exceptions are `UserPromptSubmit`, `UserPromptExpansion`, and `SessionStart`, where Claude Code adds plain-text stdout as context that Claude can see and act on." OFFICIAL. [hooks-stdout-injection]
- A structured push field exists across events: `additionalContext` — "Optional additional context to include in the session. Claude sees this context in the transcript and can act on it." OFFICIAL. [hooks-additionalcontext]
- What remains true of hooks: they are fired by the harness at lifecycle points, not called on demand by the model mid-reasoning. (Interpretation of [hooks-stdout-injection]; the docs do not phrase it this way.)
- Codex has skills on the **same agentskills.io standard** as Claude Code — "ChatGPT and Codex start with each skill's name and description, then load the full `SKILL.md` instructions when they decide to use that skill" — searched at `.agents/skills`, `$HOME/.agents/skills`, `/etc/codex/skills`. One SKILL.md can therefore serve both harnesses. OFFICIAL. [codex-has-skills]
- Codex also has hooks with context injection (`SessionStart`, `SubagentStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse` support `additionalContext`), configured in `hooks.json` or an inline `[hooks]` table in `config.toml`. OFFICIAL. [codex-has-hooks]
- Codex builds its AGENTS.md instruction chain "once per run; in the TUI this usually means once per launched session" — i.e. push-at-launch is snapshot-once. OFFICIAL. [codex-agents-md]

### Part 1d — the plain-CLI baseline and push-vs-pull

- **No controlled study measuring `--help` depth against agent task success or tokens-to-first-correct-invocation was found. NOT DETERMINED.** All located material is design advice or token accounting, not benchmarking. [glab-agent-info] is the closest primary evidence that vendors find plain `--help` insufficient: GitLab has an open proposal for `glab --agent-info` returning structured JSON (version, JSON-output support, interactive→non-interactive command mappings). Status: proposal, not shipped. [glab-agent-info]
- The closest real evidence points *away* from `--help` as the lever: in the 120-run study, clear inline instructions shipped with the tool achieved 100% success without a training-data advantage, and agents did not need `--help`. This supports "tell the agent the verbs in a skill/prompt." BLOG. [zechner-wash]
- Environment-variable context propagation across a process boundary is a real, official convention: OpenTelemetry specifies env carriers — "Environment variables provide a mechanism to propagate context and baggage information across process boundaries when network protocols are not applicable" — with normative key normalization (`traceparent` → `TRACEPARENT`) and "MUST treat values as opaque strings." Status: Release Candidate. OFFICIAL SPEC. [otel-env-carriers]
- **Precision matters here:** W3C Trace Context itself defines HTTP headers only and does *not* define env-var propagation; the env convention lives in the OTel spec. Do not conflate them. OFFICIAL SPEC. [w3c-tracecontext]
- The push-at-launch context-file pattern is standardized as AGENTS.md: "a README for agents: a dedicated, predictable place to provide the context and instructions to help AI coding agents work on your project", read automatically, "the nearest file in the directory tree" taking precedence. OFFICIAL. [agents-md-site]
- The general config-in-environment rationale predates agents: env vars are "easy to change between deploys without changing any code", carry "little chance of them being checked into the code repo accidentally", and are "a language- and OS-agnostic standard." OFFICIAL. [twelvefactor-config]
- **The staleness tradeoff of pushed-at-launch context vs a live query path is NOT DETERMINED** — no official source directly analyzes it. The documented mechanics that bear on it are: instruction chains build once per run [codex-agents-md]; skill bodies are never re-read within a session [skills-content-lifecycle-sticky]; and compaction erodes pushed context (re-attached skills keep "the first 5,000 tokens of each" under a combined 25,000-token budget, so "older skills can be dropped entirely after compaction") [skills-content-lifecycle-sticky].

### Part 2 — what the competitors actually expose to agents

Repos cloned to `~/.tmp/wf-competitor-research/` on 2026-08-21; line numbers are against that checkout.

- **Gas Town ships no MCP server.** A repo-wide grep for `mcp` across `*.go`/`*.md`/`*.ts`/`*.json` returns only test fixtures, a daemon pressure comment, and design/research prose — no server implementation, no `mcp` package, no MCP dependency. Its interface is a CLI plus tmux. [gastown-verbs]
- Gas Town's CLI is very large: 567 `cobra.Command{` literals and 292 distinct `Use:` verbs across `internal/` and `cmd/`. Verbs are organized into 7 help groups (`GroupWork`, `GroupAgents`, `GroupComm`, `GroupServices`, `GroupWorkspace`, `GroupConfig`, `GroupDiag`) at `internal/cmd/root.go:372-378`. [gastown-verbs]
- **Gas Town does not solve 292-verb discoverability by MCP; it solves it by role-scoped PUSH at session start.** `gt prime` "Detect[s] the agent role from the current directory and output[s] context" (`internal/cmd/prime.go:71-80`) and documents its own hook wiring: `"SessionStart": [{"hooks": [{"type": "command", "command": "gt prime --hook"}]}]` for Claude Code (`internal/cmd/prime.go:95-96`), with a Gemini CLI equivalent plus `PreCompress` at `:99-101`. Roles are a closed enum — Mayor, Deacon, Boot, Witness, Refinery, Polecat, Crew, Dog, Unknown (`internal/cmd/prime.go:55-65`). [gastown-prime-hook]
- **Gas Town publishes a machine-readable verb allowlist rather than relying on `--help`.** A cobra annotation `AnnotationPolecatSafe = "polecatSafe"` (`internal/cmd/proxy_subcmds.go:15`) marks agent-safe verbs; `gt proxy-subcmds` emits "the allowed subcommand allowlist for gt-proxy-server" (`internal/cmd/proxy_subcmds.go:22-33`), auto-discovered by scanning for the annotation (`:38`). Only 13 files carry it — i.e. the agent-facing subset is ~13 verbs out of 292. [gastown-polecat-safe]
- Gas Town ships harness-native skills and commands rather than MCP: `.claude/skills/{crew-commit,ghi-list,pr-sheriff,pr-list}/SKILL.md`, `.cursor/skills/gas-town-cursor/SKILL.md`, `docs/skills/convoy/SKILL.md`, and `.claude/commands/{backup,reaper,patrol}.md`. It also **generates** per-harness slash commands from one registry with per-agent frontmatter (`internal/templates/commands/provision.go:38-60`, with `AgentFields` keyed `"claude"`, `"opencode"`, …). [gastown-skills]
- Gas Town's machine surface is per-command `--json` flags (e.g. `internal/cmd/account.go:508`, `agents.go:141`, `agent_state.go:81`, `audit.go:57`, `boot.go:91`, `changelog.go:42`), and it consumes its sibling tool the same way (`bd show --json`, `internal/cmd/bead.go:120`). Its own AGENTS.md teaches agents the `--robot-*` flag family of `bv` and warns "**NEVER run bare `bv`** — it launches interactive TUI" (`AGENTS.md:41-49`). [gastown-json]
- **Vibe Kanban is the one competitor shipping a real, query-oriented MCP server** — a dedicated Rust crate `crates/mcp` with a stdio binary `crates/mcp/src/bin/vibe_kanban_mcp.rs` built on `rmcp`, exposing **34 `#[tool(...)]` methods** across repos, workspaces, sessions, task attempts, issues, organizations, tags and relationships. [vibekanban-mcp]
- Vibe Kanban's MCP server is **a thin stdio client over its own HTTP API, not the primary interface**: the binary resolves a `base_url` from a port file / `MCP_HOST`+`MCP_PORT` before serving (`crates/mcp/src/bin/vibe_kanban_mcp.rs:9-45`). The API/daemon is primary; MCP is additive. [vibekanban-mcp]
- Vibe Kanban ships **two scope-limited tool routers**, not one flat catalog: `McpMode::Global` and `McpMode::Orchestrator`, the latter "an orchestrator-scoped Vibe Kanban MCP server with tools limited to the configured workspace and orchestrator session context" (`crates/mcp/src/task_server/handler.rs:20-27`), with distinct routers (`mod.rs:63,73`) and tools removed from the router when context is absent (`mod.rs:91`). [vibekanban-mcp-modes]
- Vibe Kanban's server-level `instructions` string enumerates its own tool names and states an ordering rule — "Use list/read tools first when you need IDs or current state. TOOLS: {…}" (`crates/mcp/src/task_server/handler.rs:28-32`) — i.e. it pushes usage guidance in the handshake rather than relying on tool descriptions alone. [vibekanban-mcp-modes]
- Vibe Kanban exposes exactly the pull-side analogue of a provenance lookup: `get_context` — "Return project, issue, workspace, and orchestrator-session metadata for the current MCP context" (`crates/mcp/src/task_server/tools/context.rs:7-13`). [vibekanban-get-context]
- **Codex ships an MCP server that is an invocation surface, not a query surface.** `tools/list` returns exactly two tools — `codex` and `codex-reply` (`codex-rs/mcp-server/src/message_processor.rs:341-345`, dispatch at `:352-356`). There is no fleet/state query tool. [codex-mcp-two-tools]
- Claude Squad is a **human-driven TUI**: 4 cobra commands total in `main.go` (`root`, `reset`, `debug`, `version`, at `main.go:27,80,117,138`), no MCP, no skills dir, no JSON query surface. Its README describes "a terminal app that manages multiple [agents]... in one terminal window." Intended driver: a human at a keyboard. [claude-squad-tui]
- AgentAPI's interface is an **HTTP API with a published OpenAPI schema** (`openapi.json`; endpoints `/events`, `/message`, `/messages`, `/status`, `/upload`) plus a CLI (`agentapi server`, `agentapi attach`). It explicitly positions MCP as a **downstream consumer built by others**, not something it ships: one listed use is "as a backend in an MCP server that lets one agent control another coding agent" (`README.md:10`). [agentapi-http]
- cmux ships **20 agent skills** (`skills/cmux-architecture`, `-backend`, `-debugging`, `-socket-policy`, …), an `AGENTS.md`, a `CLAUDE.md`, and a Swift `CLI/` with an explicit agent-hook catalog (`CLI/CMUXCLI+AgentHookCatalog.swift`, `CMUXCLI+AgentHookDefinitions.swift`, `AgentHookNotificationPolicy.swift`). Repo-wide search for `modelcontextprotocol`/`McpServer` outside i18n message bundles returns nothing — **no MCP server**. [cmux-skills]
- Tally across the six re-cloned agent-supervisor repos: **1 of 6 ships a query-oriented MCP server** (vibe-kanban), 1 ships a 2-tool invocation MCP server (codex), 4 ship none. Skills are shipped by 3 of 6 (gastown, cmux, codex). Every one of them keeps a CLI or HTTP API as the primary surface.

### Part 3a — machine-friendly fleet-query output: what mature CLIs get right and wrong

- **systemd separates LOAD / ACTIVE / SUB as three orthogonal columns rather than one collapsed status.** Live host measurement produced 12 distinct real combinations, including `352 loaded/active/plugged`, `207 loaded/inactive/dead`, `35 not-found/inactive/dead`, `29 loaded/failed/failed`, `3 masked/inactive/dead`. "We couldn't find it" (`not-found`), "we found it and it's off" (`inactive`), and "deliberately excluded" (`masked`) are distinguishable **only** via the LOAD column. [systemd-orthogonal-columns]
- At single-unit level the collapse is visible and damaging: `systemctl is-active nosuchunit.service` prints `inactive` — textually identical to a real stopped unit — and only exit code 4 and `LoadState=not-found` reveal it was never found. [systemd-notfound-vs-inactive]
- **systemd's default list view hides a majority of what it knows.** "By default, only units which are active, have pending jobs, or have failed are shown; this can be changed with option --all." Measured on the same host: 444 units by default vs 906 with `--all` — the default hides 51%. [systemd-default-hides-coverage]
- **systemd is best-in-class at empty-result coverage disclosure**, and prints it on stdout: an empty match yields "0 loaded units listed. Pass --all to see loaded but inactive units, too." plus "To show all installed unit files use 'systemctl list-unit-files'." The empty answer names both what it did not search and the wider query. [systemd-coverage-hint-footer]
- **But that hint lives in the legend**, which every script disables: `--legend=BOOL` "Enable or disable printing of the legend, i.e. column headers and the footer with hints." So `--no-legend` silently discards the coverage caveat. [systemd-coverage-hint-footer]
- **And the JSON path is worse than the text path**: `systemctl list-units 'nosuchunit*' --output=json` returns a bare `[]` with exit 0 — no total, no scope, no hint. All coverage metadata is lost on the machine-readable path. [systemd-json-drops-coverage]
- systemd states the CLI-output-as-API contract precisely, and makes stability opt-in per command along the human/machine line: "the _output_ generated by these commands is generally not stable, except in cases documented in the man page. Example: the output of `systemctl status` is not stable, but that of `systemctl show` is, because the former is intended to be human-readable and the latter computer-readable." [systemd-output-stability]
- **`docker ps --format json` is corrupt by default**: values are silently truncated with a Unicode ellipsis unless `--no-trunc` is passed (measured: `/home/tnunamak…,pdpp_pdpp-home,pdpp_pdpp-tran…` vs the full string with `--no-trunc`). Display-layer truncation leaked into the serialization layer. [docker-json-truncates]
- `docker ps --format json` is also stringly-typed and NDJSON, not an array: `Ports`, `Labels`, `Mounts`, `Networks` are all `"string"` (comma-joined, unrecoverable if a value contains a comma), and an empty result is zero bytes — indistinguishable from a crashed command. [docker-json-stringly-typed]
- docker gets one thing right that kubectl does not: an unknown filter *key* is rejected rather than silently matching nothing — `--filter 'name=nonexistent-zzz'` gives header-only and exit 0, while `--filter 'bogusfilter=x'` gives "Error response from daemon: invalid filter 'bogusfilter'" and exit 1. [docker-empty-vs-error]
- git's plumbing/porcelain split is the canonical two-tier stability contract: low-level command interfaces "are meant to be a lot more stable than Porcelain level commands, because these commands are primarily for scripted use." [git-plumbing-porcelain]
- `git status --porcelain` carries an explicit guarantee including **independence from user configuration**: "guaranteed not to change in a backwards-incompatible way between Git versions or based on user configuration. This makes it ideal for parsing by scripts." [git-porcelain-guarantee]
- `--porcelain=v2` shows how to extend a machine format without breaking parsers: "Version 2 also defines an extensible set of easy to parse optional headers. Header lines start with `#`... Parsers should ignore headers they don't recognize." [git-porcelain-v2-extensible]
- **`git for-each-ref`'s `%(if)...%(then)...%(else)...%(end)` lets the caller decide how absence renders**, turning "no value here" into an explicit, caller-chosen state rather than an ambiguous empty field (live: `[NO UPSTREAM]` vs `[tracks origin/…]`). [git-if-then]
- Even so, `git for-each-ref` on a non-matching pattern prints nothing and exits 0 — no coverage signal at all. [git-if-then]
- kubectl's `--field-selector` support "vary[ies] by Kubernetes resource type. All resource types support the `metadata.name` and `metadata.namespace` fields. Using unsupported field selectors produces an error." [kubectl-field-selector-limits]
- **kubectl prints "No resources found" to stderr, not stdout** — verified in source: `fmt.Fprintf(o.ErrOut, "No resources found in %s namespace.\n", o.Namespace)`. Consequence reported by users: "the message being printed to `stdErr` and nothing being assigned to the variable." [kubectl-no-resources-stderr]
- **kubectl demonstrates the exact conflation this research targets**: "No resources found." is printed alongside a connection failure — "Unable to register third party resources: Get http://127.0.0.1:8888/api: read tcp ... connection reset by peer / No resources found. / Unable to connect to the server". "We looked and found nothing" and "we couldn't look" render identically. [kubectl-no-resources-on-error]
- kubectl also shows a *presentation* option silently changing the *result set*: sorting by a label absent from all pods reported "No resources found"; "Adding the label to a single pod caused the result to suddenly show all pods (including those without the label)." [kubectl-sortby-false-empty]
- kubectl's documented exit-code contract for empty-vs-error is **NOT DETERMINED** — no kubernetes.io page states it; only issue-tracker discussion requesting a change. [kubectl-no-resources-stderr]
- Kubernetes' `remainingItemCount` self-labels its own precision: "The intended use of the remainingItemCount is *estimating* the size of a collection. Clients should not rely on the remainingItemCount to be set or to be exact." [k8s-remaining-item-count]

### Part 3b — prior art: surfacing confidence/provenance with the answer (requirement 1)

- **DNSSEC's AD bit is a validation-status flag carried beside the answer**: "A security-aware name server MUST NOT set the AD bit in a response unless the name server considers all RRsets in the Answer and Authority sections of the response to be authentic." [dnssec-ad-bit]
- Critically, the spec frames it as a **claim, not proof**: a stub resolver examines the AD bit "in order to determine whether the security-aware recursive name server that sent the response **claims to have** cryptographically verified the data." A provenance flag asserts the asserter's state; trusting it is a separate decision. [dnssec-ad-is-a-claim]
- The CD bit lets a client opt out of upstream validation and take responsibility itself: "The CD bit exists in order to allow a security-aware resolver to disable signature validation in a security-aware name server's processing of a particular query." [dnssec-cd-bit]
- **The cautionary tale: HTTP's `Warning` header is formally obsoleted.** "This specification obsoletes it, as it is not widely generated or surfaced to users." [http-warning-obsoleted]
- The stated rationale is the design lesson for any confidence field: "Much of the information supported by Warning could be gleaned by examining the response, and the remaining information -- although potentially useful -- was **entirely advisory**. In practice, Warning was not added by caches or intermediaries." [http-warning-rationale]
- The obsoleted warn-code vocabulary was nonetheless a good degradation taxonomy: `110 Response is Stale`; `111 Revalidation Failed` — "sending a stale response because an attempt to validate the response failed, due to an inability to reach the server"; `112 Disconnected Operation` — "intentionally disconnected from the rest of the network." 111 and 112 map directly onto "we answered from cache because we couldn't reach the source." [http-warn-codes]
- The *quantitative* signal survived where the qualitative flags died: `Age` "conveys the sender's estimate of the time since the response was generated or successfully validated at the origin server." [http-age-header]
- **Absence of a confidence signal must not be read as confidence**: "the presence of an Age header field implies that the response was not generated or validated by the origin server for this request. However, lack of an Age header field does not imply the origin was contacted." [http-age-absence-asymmetry]
- `stale-if-error` is the explicit degraded-confidence-on-failure contract: "when an error is encountered, a cached stale response MAY be used to satisfy the request, regardless of other freshness information." [http-stale-if-error]
- `Content-Location` is a provenance pointer: it "references a URI that can be used as an identifier for a specific resource corresponding to the representation in this message's content." [http-content-location]
- **SLSA expresses provenance as graded classes named by adversary cost, not percentages**: L1 "Provenance exists... trivial to bypass or forge"; L2 "Forging the provenance or evading verification requires an explicit 'attack'"; L3 "requires exploiting a vulnerability that is beyond the capabilities of most adversaries." [slsa-graded-levels]
- SLSA explicitly permits weak provenance at low levels rather than omitting it: "Provenance may be incomplete and/or unsigned at L1. Higher levels require more complete and trustworthy provenance." [slsa-l1-incomplete]
- in-toto gives the general value+provenance envelope shape: a Statement "binds the attestation to a particular subject and unambiguously identifies the types of the predicate"; the Predicate carries "arbitrary metadata about a subject artifact, with a type-specific schema." [intoto-subject-predicate]
- **OpenTelemetry span status is tri-state with `Unset` as the default** — "nobody judged this" is a first-class state distinct from success — and `Ok` requires explicit assertion: "The operation has been validated by an Application developer or Operator to have completed successfully." Default to unknown, never to fine. [otel-status-unset]
- W3C Trace Context's sampled flag uses deliberately hedged language: "When set, the least significant bit (right-most), denotes that the caller **may have** recorded trace data." [w3c-sampled-flag]
- **Codd diagnosed the exact "absent vs not-applicable" conflation in 1990** and proposed two distinct null markers: "A-Values" and "I-Values", representing "Missing But Applicable" and "Missing But Inapplicable", which "would have required SQL's logic system be expanded to accommodate a four-valued logic system." REFERENCE (Wikipedia; underlying citation Codd 1990). [codd-a-marks-i-marks]
- **And his fix lost to simplicity** — the cautionary half: "Because of this additional complexity, the idea of multiple Nulls with different definitions has not gained widespread acceptance in the database practitioners' domain." [codd-rejected-for-complexity]
- The formal statement of the problem: "Nulls... operate under the open world assumption, in which some items stored in the database are considered unknown, making the database's stored knowledge of the world incomplete." A fleet query is inherently open-world; reporting it as closed-world is the category error. [nulls-open-world]
- The canonical "confidence must travel with the value" statement, phrased as a **completeness criterion rather than an option**: "A measurement result is complete only when accompanied by a quantitative statement of its uncertainty." [nist-uncertainty]

### Part 3c — prior art: coverage reporting in query results (requirement 2)

- **The strongest precedent is Elasticsearch's `_shards` block, present on every search response including complete successes**: `"_shards": { "total": 1, "successful": 1, "skipped": 0, "failed": 0 }`, alongside `"timed_out": false`. Coverage is structural and unconditional, not an error-only add-on. [es-shards-envelope]
- The counters are individually documented: `total` — "The number of shards the operation or search will run on overall"; `successful` — "the number of shards the operation or search succeeded on"; `failed` — "attempted to run on but failed"; plus a `failures` array "including index, node, reason, shard number, status". `total` vs `successful` is exactly "where we should have looked" vs "where we actually looked." [es-shards-field-defs]
- **Even the best precedent has a naming failure**: `skipped` "appears in the response but no description is provided in the documentation", and users have publicly asked what it means. Naming a coverage field is not enough — a reason must be documented. [es-skipped-underdocumented]
- `timed_out` is a *separate* boolean from the shard counters, because partial-by-timeout differs from partial-by-failure: "If `true`, the request timed out before completion; returned results may be **partial or empty**." An empty result may mean the timeout hit, not that nothing matched. [es-timed-out]
- **The fail-vs-degrade choice is an explicit caller-controlled policy**: `allow_partial_search_results` — "If `true` and there are shard request timeouts or shard failures, the request returns partial results. If `false`, it returns an error with no partial results." Default `true`. [es-allow-partial]
- Thanos exposes the same choice as named strategies `warn` and `abort` via `--query.partial-response`, which "controls tradeoff between accuracy and availability", returning "human readable warnings" containing "every error that occurred that is assumed non critical." [thanos-partial-response]
- **Thanos also draws the sharp distinction that prevents alarm fatigue**: "Having a warning does not necessarily mean partial response (e.g no store matched query warning)", and a partial response "doesn't necessarily mean data loss — the broken store may have had nothing for your query anyway." Coverage-incomplete ≠ answer-wrong; an honest system admits it often cannot know. [thanos-warning-not-partial]
- Prometheus returns annotations alongside a successful answer, in three tiers: `warnings` — "Only set if there were warnings while executing the request. **There will still be data in the data field**" — plus `infos`, within a `status`/`data`/`errorType`/`error` envelope. [prom-warnings-with-success]
- **Prometheus's `up` metric is the cleanest separation of coverage from value found in this survey**: "1 if the instance is healthy, i.e. reachable, or 0 if the scrape failed", stored as a separate series. A failed scrape produces `up=0` *and no samples*, so "no data" is never confused with "zero." [prom-up-metric]
- Prometheus also refuses to let stale data masquerade as current: "A time series will go stale when it is no longer exported, or the target no longer exists... they will not be returned in queries after they are marked stale." [prom-staleness]
- **DNS's three-way outcome split is the canonical "nothing" taxonomy** — NXDOMAIN ("the domain referred to by the QNAME does not exist"), NODATA ("RCODE set to NOERROR and no relevant answers in the answer section"), and SERVFAIL — and the telling detail is that NODATA has no RCODE of its own: "NODATA responses have to be algorithmically determined from the response's contents as there is no RCODE value to indicate NODATA." A naive client sees all three as "nothing." [dns-nodata-vs-nxdomain]
- RFC 8020 gives a negative answer an explicitly defined **scope of negation**: NXDOMAIN "means that the domain name which is thus denied AND ALL THE NAMES UNDER IT do not exist", and a resolver "SHOULD" treat all names at or below that node as unreachable. A rare case of "nothing found" stating exactly what territory it covers. [rfc8020-nxdomain-scope]
- **HTTP deliberately enshrines the conflation as a feature** — worth citing as the counter-example proving it is a *choice*: a server "that wishes to 'hide' the current existence of a forbidden target resource MAY instead respond with a 404", and 404 itself means the server "did not find a current representation for the target resource **or is not willing to disclose that one exists**." Correct for security; exactly the bug for a fleet query. [http-404-hides-403]
- HTTP nonetheless distinguishes four "nothing" outcomes — 404, 403, 204 ("successfully fulfilled the request and... no additional content to send"), and 200-with-empty-list. [http-204]
- GraphQL mandates that partial data and errors coexist: "A response may contain both a partial response as well as any field errors in the case that a field error was raised on a field and was replaced with null", and such errors are "'handled' by producing a partial response." [graphql-data-and-errors]
- GraphQL splits "we couldn't start looking" from "we looked and part failed" into structurally different response shapes: request errors are "raised before execution begins... execution does not begin and no data is returned", whereas with a field error "execution attempts to continue and a partial result is produced... The `data` entry in the response must be present." [graphql-request-vs-field-errors]
- **The single most directly applicable normative rule found**: GraphQL requires `errors[].path` "that details the path of the response field which experienced the error. This allows clients to identify whether a `null` result is intentional or caused by a runtime error." It solves "is this empty because there's nothing, or because we failed?" by pointing at the exact coordinate of the gap. [graphql-path-disambiguates-null]
- GraphQL's nullability declarations give a **tunable blast radius for uncertainty**: non-null field errors propagate to the parent, and "If all fields from the root of the request to the source of the field error return `Non-Null` types, then the 'data' entry in the response should be null." [graphql-null-propagation]
- BigQuery documents that errors may accompany a job that did **not** fail — "Errors here do not necessarily mean that the job has completed or was unsuccessful" — and notes the error list is itself truncated ("The **first** errors or warnings"), i.e. the error list has incomplete coverage. [bigquery-errors-nonfatal]
- BigQuery separates "the query finished" from "here are rows" via `jobComplete` ("Whether the query has completed or not... If this is false, totalRows will not be available"), with `cacheHit` as a provenance flag in the same envelope. [bigquery-jobcomplete]
- **The legitimate opposite design exists**: Trino has no partial-success state. "The `QueryResults` document contains an `error` field of type `QueryError` if the query has failed, and if that object is not present, the query succeeded." Split-level failures are handled by retry policy, not surfaced as partial coverage. A mature distributed engine that deliberately chose all-or-nothing. [trino-no-partial-state]

## SOURCES

**mcp-usbc**
URL: https://modelcontextprotocol.io/docs/getting-started/intro
Accessed: 2026-08-21
Quote: "Think of MCP like a USB-C port for AI applications." / "build once and integrate everywhere"

**mcp-scope**
URL: https://modelcontextprotocol.io/docs/learn/architecture
Accessed: 2026-08-21
Quote: "MCP focuses solely on the protocol for context exchange—it does not dictate how AI applications use LLMs or manage the provided context."

**mcp-stateless**
URL: https://modelcontextprotocol.io/docs/learn/architecture
Accessed: 2026-08-21
Quote: "MCP is a stateless protocol. Every request carries the protocol version and the capabilities relevant to that request in its `_meta` field." (protocol version 2026-07-28; `sampling` and `logging` deprecated)

**mcp-own-admission**
URL: https://modelcontextprotocol.io/docs/develop/clients/client-best-practices
Accessed: 2026-08-21
Quote: "Loading every tool definition into the model's context window upfront wastes tokens, increases latency, and degrades model performance."

**mcp-threshold**
URL: https://modelcontextprotocol.io/docs/develop/clients/client-best-practices
Accessed: 2026-08-21
Quote: "as a percentage of the context window. For example, 1%-5%"

**mcp-cache-trap**
URL: https://modelcontextprotocol.io/docs/develop/clients/client-best-practices
Accessed: 2026-08-21
Quote: "Adding or removing tool definitions mid-conversation invalidates that cache, and the resulting miss can cost more tokens than the definitions you removed."

**anthropic-no-wrap**
URL: https://www.anthropic.com/engineering/writing-tools-for-agents
Accessed: 2026-08-21
Quote: "More tools don't always lead to better outcomes. A common error we've observed is tools that merely wrap existing software functionality or API endpoints—whether or not the tools are appropriate for agents."

**anthropic-consolidate**
URL: https://www.anthropic.com/engineering/writing-tools-for-agents
Accessed: 2026-08-21
Quote: "Instead of implementing a `list_users`, `list_events`, and `create_event` tools, consider implementing a `schedule_event` tool."

**anthropic-98**
URL: https://www.anthropic.com/engineering/code-execution-with-mcp
Accessed: 2026-08-21
Quote: "This reduces the token usage from 150,000 tokens to 2,000 tokens—a time and cost saving of 98.7%."

**anthropic-sandbox-cost**
URL: https://www.anthropic.com/engineering/code-execution-with-mcp
Accessed: 2026-08-21
Quote: "code execution introduces its own complexity. Running agent-generated code requires a secure execution environment with appropriate sandboxing, resource limits, and monitoring. These infrastructure requirements add operational overhead and security considerations that direct tool calls avoid."

**skills-vs-mcp**
URL: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview
Accessed: 2026-08-21
Quote: "you can install many Skills without context penalty" (Level 1 metadata ~100 tokens per Skill; bundled files "cost zero tokens" until read)

**playwright-reversal**
URL: https://github.com/microsoft/playwright-mcp
Accessed: 2026-08-21
Quote: "CLI invocations are more token-efficient: they avoid loading large tool schemas and verbose accessibility trees into the model context."

**cloudflare-both**
URL: https://blog.cloudflare.com/cf-cli-local-explorer/
Accessed: 2026-08-21
Quote: "agents love CLIs" / "There's a lot more surface area to cover"

**stripe-both**
URL: https://docs.stripe.com/agents
Accessed: 2026-08-21
Quote: "The plugin configures MCP, includes Stripe-maintained skills and tools."

**sentry-scope**
URL: https://github.com/getsentry/sentry-mcp
Accessed: 2026-08-21
Quote: "Sentry's MCP service is primarily designed for human-in-the-loop coding agents"

**sentry-oauth-why**
URL: https://blog.sentry.io/yes-sentry-has-an-mcp-server-and-its-pretty-good/
Accessed: 2026-08-21
Quote: "Making people create API tokens and pass them around is… not great. Support for OAuth was necessary."

**neon-both**
URL: https://neon.com/docs/ai/neon-mcp-server
Accessed: 2026-08-21
Quote: "Your AI agent can interact with Neon via MCP tools or by running Neon CLI commands directly."

**supabase-npx-pain**
URL: https://supabase.com/blog/remote-mcp-server
Accessed: 2026-08-21
Quote: "configured correctly so that the correct version was used by each client (if you used `nvm`). Every operating system also had slight differences that required modifying the `npx` command accordingly."

**ronacher-flaws**
URL: https://lucumr.pocoo.org/2025/7/3/tools/
Accessed: 2026-08-21
Quote: "isn't truly composable. Most composition happens through inference" / "I can run and debug a script, I cannot even figure out how to reliably do MCP calls."

**ronacher-walkback**
URL: https://lucumr.pocoo.org/2025/8/18/code-mcps/
Accessed: 2026-08-21
Quote: "doing multiple turns is very hard with CLI tools because you need to teach the agent how to manage sessions" / "What is stateful out of the box, however, is MCP"

**holmes-hn**
URL: https://ejholmes.github.io/2026/02/28/mcp-is-dead-long-live-the-cli.html
Accessed: 2026-08-21
Quote: "If you're a company investing in an MCP server but you don't have an official CLI, stop and rethink what you're doing. Ship a good API, then ship a good CLI." / "Local MCP servers are processes. They need to start up, stay running, and not silently hang."

**cramer-rebuttal**
URL: https://cra.mr/context-management-and-mcp/
Accessed: 2026-08-21
Quote: "The ability to steer the LLM is the entire value prop of MCP tools" / "We cannot prevent context rot, so you need to embrace consuming context."

**willison-shift**
URL: https://simonwillison.net/2025/Aug/22/too-many-mcps/
Accessed: 2026-08-21
Quote: "If your coding agent can run terminal commands and you give it access to GitHub's gh tool it gains all of that functionality for a token cost close to zero."

**zechner-wash**
URL: https://mariozechner.at/posts/2025-08-15-mcp-vs-cli/
Accessed: 2026-08-21
Quote: "The answer is, at least for this specific case, it doesn't matter as much as you'd think." / "Maybe instead of arguing about MCP vs CLI, we should start building better tools. The protocol is just plumbing." (120 runs; MCP 2.5% cheaper, 23% faster; both 100% success)

**stripe-codemode**
URL: https://portofcontext.com/blog/cli-vs-mcp-vs-code-mode
Accessed: 2026-08-21
Quote: CLI 711,555 tokens ($2.22); raw MCP 506,970; Code Mode MCP 294,924 ($0.98); `create_invoice` 19 CLI turns vs 4 Code Mode turns

**scalekit-caveat**
URL: https://www.scalekit.com/blog/mcp-vs-cli-use — and https://github.com/scalekit-inc/mcp-vs-cli-benchmark
Accessed: 2026-08-21
Quote: repo README: "Both modalities achieve 100% task completion" (contradicts the blog's 72% MCP reliability and 4–32× headline). Pre-registered H1 "MCP agents will use fewer total tokens than CLI agents" was refuted by their own data.

**per-tool-token**
URL: https://www.apideck.com/blog/mcp-server-eating-context-window-cli-alternative
Accessed: 2026-08-21
Quote: "Each MCP tool costs 550-1,400 tokens for its name, description, JSON schema, field descriptions, enums, and system instructions."

**config-frag**
URL: https://modelcontextprotocol.io/docs/develop/connect-local-servers (corroborated against vendor docs for Cursor, Codex `~/.codex/config.toml`, Zed `context_servers`)
Accessed: 2026-08-21

**glab-agent-info**
URL: https://gitlab.com/gitlab-org/cli/-/issues/8177
Accessed: 2026-08-21
Quote: proposal for `glab --agent-info` returning structured JSON (version, JSON-output support, interactive→non-interactive command mappings). Status: proposal, not shipped.

**skills-definition**
URL: https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
Accessed: 2026-08-21
Quote: "Organized folders of instructions, scripts, and resources that agents can discover and load dynamically to perform better at specific tasks."

**skills-progressive-disclosure-3-level**
URL: https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
Accessed: 2026-08-21
Quote: "The `name` and `description` of every installed skill into its system prompt" / "If Claude thinks the skill is relevant to the current task, it will load the skill by reading its full `SKILL.md` into context." / "These additional linked files are the third level (and beyond) of detail, which Claude can choose to navigate and discover only as needed."

**skills-body-loads-lazily**
URL: https://code.claude.com/docs/en/skills
Accessed: 2026-08-21
Quote: "Unlike CLAUDE.md content, a skill's body loads only when it's used, so long reference material costs almost nothing until you need it."

**skills-scripts-executed-not-loaded**
URL: https://code.claude.com/docs/en/skills — rationale from https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
Accessed: 2026-08-21
Quote: canonical layout annotates `scripts/helper.py (utility script - executed, not loaded)`; "many applications require the deterministic reliability that only code can provide."

**skills-complement-mcp**
URL: https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
Accessed: 2026-08-21
Quote: "Skills can complement Model Context Protocol (MCP) servers by teaching agents more complex workflows that involve external tools and software."

**skills-allowed-tools-preapproval**
URL: https://code.claude.com/docs/en/skills
Accessed: 2026-08-21
Quote: "The `allowed-tools` rule then matches the exact command the skill body tells Claude to run, so the script runs without prompting."

**skills-content-lifecycle-sticky**
URL: https://code.claude.com/docs/en/skills
Accessed: 2026-08-21
Quote: "the rendered `SKILL.md` content enters the conversation as a single message and stays there for the rest of the session... Claude Code does not re-read the skill file on later turns." / after compaction, re-attached skills keep "the first 5,000 tokens of each" under a "combined budget of 25,000 tokens", so "older skills can be dropped entirely after compaction."

**skills-dynamic-context-injection**
URL: https://code.claude.com/docs/en/skills
Accessed: 2026-08-21
Quote: "The ``!`<command>`` syntax runs shell commands before the skill content is sent to Claude. The command output replaces the placeholder, so Claude receives actual data, not the command itself."

**slash-commands-merged**
URL: https://code.claude.com/docs/en/skills
Accessed: 2026-08-21
Quote: "Custom commands have been merged into skills. A file at `.claude/commands/deploy.md` and a skill at `.claude/skills/deploy/SKILL.md` both create `/deploy` and work the same way."

**hooks-stdout-injection**
URL: https://code.claude.com/docs/en/hooks
Accessed: 2026-08-21
Quote: "For most events, stdout is written to the debug log but not shown in the transcript. The exceptions are `UserPromptSubmit`, `UserPromptExpansion`, and `SessionStart`, where Claude Code adds plain-text stdout as context that Claude can see and act on."

**hooks-additionalcontext**
URL: https://code.claude.com/docs/en/hooks
Accessed: 2026-08-21
Quote: "`additionalContext` | Optional additional context to include in the session. Claude sees this context in the transcript and can act on it."

**codex-has-skills**
URL: https://learn.chatgpt.com/docs/build-skills
Accessed: 2026-08-21
Quote: "ChatGPT and Codex start with each skill's name and description, then load the full `SKILL.md` instructions when they decide to use that skill." (search paths `.agents/skills`, `$HOME/.agents/skills`, `/etc/codex/skills`; agentskills.io standard). Note: OpenAI Codex docs moved from developers.openai.com/codex/* to learn.chatgpt.com/docs/* (308 redirects).

**codex-has-hooks**
URL: https://learn.chatgpt.com/docs/hooks
Accessed: 2026-08-21
Quote: `SessionStart` example `"additionalContext": "Load the workspace conventions before editing."`; events include PreToolUse, PermissionRequest, PostToolUse, PreCompact, PostCompact, UserPromptSubmit, SubagentStart, SubagentStop, Stop, SessionStart, SessionEnd.

**codex-agents-md**
URL: https://learn.chatgpt.com/docs/agent-configuration/agents-md
Accessed: 2026-08-21
Quote: "Codex builds an instruction chain when it starts (once per run; in the TUI this usually means once per launched session)."

**otel-env-carriers**
URL: https://opentelemetry.io/docs/specs/otel/context/env-carriers/
Accessed: 2026-08-21
Quote: "Environment variables provide a mechanism to propagate context and baggage information across process boundaries when network protocols are not applicable." (status: Release Candidate; `traceparent` → `TRACEPARENT`; "MUST treat values as opaque strings")

**w3c-tracecontext**
URL: https://www.w3.org/TR/trace-context/
Accessed: 2026-08-21
Quote: "The `traceparent` HTTP header field identifies the incoming request in a tracing system." (HTTP headers only; env-var propagation is NOT defined here)

**agents-md-site**
URL: https://agents.md/
Accessed: 2026-08-21
Quote: "a README for agents: a dedicated, predictable place to provide the context and instructions to help AI coding agents work on your project." / "Agents automatically read the nearest file in the directory tree, so the closest one takes precedence."

**twelvefactor-config**
URL: https://12factor.net/config
Accessed: 2026-08-21
Quote: "Store config in the environment" / "a language- and OS-agnostic standard"

**gastown-verbs**
URL: ~/.tmp/wf-competitor-research/gastown (github.com/steveyegge/gastown, cloned 2026-08-21) — internal/cmd/root.go:372-378
Accessed: 2026-08-21
Quote: 567 `cobra.Command{` literals; 292 distinct `Use:` verbs; 7 help groups (GroupWork/GroupAgents/GroupComm/GroupServices/GroupWorkspace/GroupConfig/GroupDiag). Repo-wide grep for `mcp` across *.go/*.md/*.ts/*.json returns only test fixtures, a daemon comment, and design prose — no MCP server.

**gastown-prime-hook**
URL: ~/.tmp/wf-competitor-research/gastown/internal/cmd/prime.go:55-101
Accessed: 2026-08-21
Quote: `"SessionStart": [{"hooks": [{"type": "command", "command": "gt prime --hook"}]}]` (:95-96); "Detect the agent role from the current directory and output context" (:71-80); roles Mayor/Deacon/Boot/Witness/Refinery/Polecat/Crew/Dog/Unknown (:55-65); Gemini CLI SessionStart + PreCompress wiring (:99-101).

**gastown-polecat-safe**
URL: ~/.tmp/wf-competitor-research/gastown/internal/cmd/proxy_subcmds.go:11-48
Accessed: 2026-08-21
Quote: `const AnnotationPolecatSafe = "polecatSafe"` (:15); "Output the allowed subcommand allowlist for gt-proxy-server" (:26); auto-discovery `if c.Annotations[AnnotationPolecatSafe] == "true"` (:38). 13 files carry the annotation.

**gastown-skills**
URL: ~/.tmp/wf-competitor-research/gastown/.claude/skills/, .cursor/skills/, docs/skills/, .claude/commands/, internal/templates/commands/provision.go:38-60
Accessed: 2026-08-21
Quote: skills crew-commit, ghi-list, pr-sheriff, pr-list, gas-town-cursor, convoy; commands backup/reaper/patrol; provision.go generates per-harness frontmatter via `AgentFields map[string][]Field` keyed "claude", "opencode".

**gastown-json**
URL: ~/.tmp/wf-competitor-research/gastown/AGENTS.md:41-49; internal/cmd/{account.go:508, agents.go:141, agent_state.go:81, audit.go:57, boot.go:91, changelog.go:42, bead.go:120}
Accessed: 2026-08-21
Quote: "**NEVER run bare `bv`** — it launches interactive TUI. Always use `--robot-*` flags" (AGENTS.md:41-42)

**vibekanban-mcp**
URL: ~/.tmp/wf-competitor-research/vibe-kanban (github.com/BloopAI/vibe-kanban, cloned 2026-08-21) — crates/mcp/src/bin/vibe_kanban_mcp.rs:9-45; crates/mcp/src/task_server/tools/*.rs
Accessed: 2026-08-21
Quote: 34 `#[tool(...)]` methods across repos/workspaces/sessions/task_attempts/issues/organizations/tags/relationships; binary resolves `base_url` from a port file or `MCP_HOST`/`MCP_PORT` before `serve(stdio())`.

**vibekanban-mcp-modes**
URL: ~/.tmp/wf-competitor-research/vibe-kanban/crates/mcp/src/task_server/handler.rs:20-32; mod.rs:46,63,73,91
Accessed: 2026-08-21
Quote: "An orchestrator-scoped Vibe Kanban MCP server with tools limited to the configured workspace and orchestrator session context." / "Use list/read tools first when you need IDs or current state. TOOLS: {…}"

**vibekanban-get-context**
URL: ~/.tmp/wf-competitor-research/vibe-kanban/crates/mcp/src/task_server/tools/context.rs:7-13
Accessed: 2026-08-21
Quote: "Return project, issue, workspace, and orchestrator-session metadata for the current MCP context."

**codex-mcp-two-tools**
URL: ~/.tmp/wf-competitor-research/codex (github.com/openai/codex, cloned 2026-08-21) — codex-rs/mcp-server/src/message_processor.rs:341-356
Accessed: 2026-08-21
Quote: `ListToolsResult::with_all_items(vec![create_tool_for_codex_tool_call_param(), create_tool_for_codex_tool_call_reply_param()])`; dispatch matches only `"codex"` and `"codex-reply"`.

**claude-squad-tui**
URL: ~/.tmp/wf-competitor-research/claude-squad (github.com/smtg-ai/claude-squad, cloned 2026-08-21) — main.go:27,80,117,138
Accessed: 2026-08-21
Quote: 4 cobra commands total (root, reset, debug, version); README: "a terminal app that manages multiple [agents]... in one terminal window". No MCP, no skills dir.

**agentapi-http**
URL: ~/.tmp/wf-competitor-research/agentapi (github.com/coder/agentapi, cloned 2026-08-21) — README.md:10; openapi.json
Accessed: 2026-08-21
Quote: "as a backend in an MCP server that lets one agent control another coding agent" (README.md:10); endpoints /events, /message, /messages, /status, /upload.

**cmux-skills**
URL: ~/.tmp/wf-competitor-research/cmux (github.com/manaflow-ai/cmux, cloned 2026-08-21) — skills/, CLI/CMUXCLI+AgentHookCatalog.swift, CLI/CMUXCLI+AgentHookDefinitions.swift
Accessed: 2026-08-21
Quote: 20 skills (cmux-architecture, cmux-backend, cmux-debugging, cmux-socket-policy, …); grep for `modelcontextprotocol`/`McpServer` outside i18n bundles returns nothing.

**systemd-orthogonal-columns**
URL: local command on this host (systemd 259): `systemctl list-units --all --no-pager --no-legend --plain --output=json | jq -r 'group_by(.load+"|"+.active+"|"+.sub) | ...'`
Accessed: 2026-08-21
Quote: 352 loaded/active/plugged; 207 loaded/inactive/dead; 35 not-found/inactive/dead; 29 loaded/failed/failed; 3 masked/inactive/dead; 1 loaded/active/abandoned (+6 more)

**systemd-notfound-vs-inactive**
URL: local commands: `systemctl show -p LoadState,ActiveState,SubState nosuchunit.service`; `systemctl is-active nosuchunit.service`
Accessed: 2026-08-21
Quote: `LoadState=not-found / ActiveState=inactive / SubState=dead`; `is-active` prints `inactive` with EXIT=4

**systemd-default-hides-coverage**
URL: local command `man systemctl` (lines 20-28); measured 444 default vs 906 with --all
Accessed: 2026-08-21
Quote: "By default, only units which are active, have pending jobs, or have failed are shown; this can be changed with option --all."

**systemd-coverage-hint-footer**
URL: local command `systemctl list-units 'nosuchunit*' --no-pager 2>/dev/null | cat -A`; `man systemctl` (--legend/--plain)
Accessed: 2026-08-21
Quote: "0 loaded units listed. Pass --all to see loaded but inactive units, too." / "--legend=BOOL: Enable or disable printing of the legend, i.e. column headers and the footer with hints."

**systemd-json-drops-coverage**
URL: local command `systemctl list-units 'nosuchunit*' --no-pager --output=json`
Accessed: 2026-08-21
Quote: `[]`, EXIT=0 — no total, no scope, no hint

**systemd-output-stability**
URL: https://systemd.io/PORTABILITY_AND_STABILITY/
Accessed: 2026-08-21
Quote: "the _output_ generated by these commands is generally not stable, except in cases documented in the man page. Example: the output of `systemctl status` is not stable, but that of `systemctl show` is, because the former is intended to be human-readable and the latter computer-readable, and this is documented in the man page."

**docker-json-truncates**
URL: local commands (docker 29.7.2): `docker ps -a --format json | head -1 | jq -r '.Mounts'` vs the same with `--no-trunc`
Accessed: 2026-08-21
Quote: `/home/tnunamak…,pdpp_pdpp-home,pdpp_pdpp-tran…,pdpp_pdpp-data` vs `/home/tnunamak/.claude,/home/tnunamak/.codex,pdpp_pdpp-home,pdpp_pdpp-transformers,pdpp_pdpp-data`

**docker-json-stringly-typed**
URL: local commands: `docker ps -a --format json | head -1 | jq '{Ports:.Ports|type, Labels:.Labels|type, Mounts:.Mounts|type, Networks:.Networks|type}'`; `docker ps --filter 'name=zzz-nope' --format json`
Accessed: 2026-08-21
Quote: all four fields report `"string"`; empty result is zero bytes (NDJSON, not `[]`)

**docker-empty-vs-error**
URL: local commands: `docker ps --filter 'name=nonexistent-zzz'` (EXIT=0); `docker ps --filter 'bogusfilter=x'` (EXIT=1)
Accessed: 2026-08-21
Quote: "Error response from daemon: invalid filter 'bogusfilter'"

**git-plumbing-porcelain**
URL: https://git-scm.com/docs/git
Accessed: 2026-08-21
Quote: "The interface (input, output, set of options and the semantics) to these low-level commands are meant to be a lot more stable than Porcelain level commands, because these commands are primarily for scripted use."

**git-porcelain-guarantee**
URL: https://git-scm.com/docs/git-status
Accessed: 2026-08-21
Quote: "Version 1 porcelain format is similar to the short format, but is guaranteed not to change in a backwards-incompatible way between Git versions or based on user configuration. This makes it ideal for parsing by scripts."

**git-porcelain-v2-extensible**
URL: https://git-scm.com/docs/git-status
Accessed: 2026-08-21
Quote: "Version 2 also defines an extensible set of easy to parse optional headers. Header lines start with `#` and are added in response to specific command line arguments. Parsers should ignore headers they don't recognize."

**git-if-then**
URL: local commands (git 2.53.0): `git for-each-ref --help`; `git for-each-ref --format='%(if)%(HEAD)%(then)CURRENT %(else)------- %(end)%(refname:short)%(if)%(upstream)%(then) [tracks %(upstream:short)]%(else) [NO UPSTREAM]%(end)' refs/heads/`; `git for-each-ref --format='%(refname)' refs/heads/zzz-nope`
Accessed: 2026-08-21
Quote: "If there is an atom with value or string literal after the %(if) then everything after the %(then) is printed, else if the %(else) atom is used, then everything after %(else) is printed." Live output included `------- audit/api-key-warning-audit [NO UPSTREAM]`. Non-matching pattern: no output, EXIT=0.

**kubectl-field-selector-limits**
URL: https://kubernetes.io/docs/concepts/overview/working-with-objects/field-selectors/
Accessed: 2026-08-21
Quote: "Supported field selectors vary by Kubernetes resource type. All resource types support the `metadata.name` and `metadata.namespace` fields. Using unsupported field selectors produces an error."

**kubectl-no-resources-stderr**
URL: https://github.com/kubernetes/kubectl/blob/master/pkg/cmd/get/get.go — corroborating issue https://github.com/kubernetes/kubectl/issues/1667
Accessed: 2026-08-21
Quote: `fmt.Fprintf(o.ErrOut, "No resources found in %s namespace.\n", o.Namespace)` / issue: "This results in the message being printed to `stdErr` and nothing being assigned to the variable `yo`."
Note: kubectl is NOT installed on this host; all kubectl findings are source/docs-based, never local. Its documented exit-code contract for empty-vs-error is NOT DETERMINED.

**kubectl-no-resources-on-error**
URL: https://github.com/kubernetes/kubernetes/issues/35092
Accessed: 2026-08-21
Quote: "Unable to register third party resources: Get http://127.0.0.1:8888/api: read tcp ... connection reset by peer\nNo resources found.\nUnable to connect to the server: read tcp ..."

**kubectl-sortby-false-empty**
URL: https://github.com/kubernetes/kubectl/issues/1343
Accessed: 2026-08-21
Quote: "kubectl said \"No resources found\" when I tried to sort by a label that did not exist on any pod. Adding the label to a single pod caused the result to suddenly show all pods (including those without the label)."

**k8s-remaining-item-count**
URL: https://kubernetes.io/docs/reference/kubernetes-api/common-definitions/list-meta/
Accessed: 2026-08-21
Quote: "The intended use of the remainingItemCount is *estimating* the size of a collection. Clients should not rely on the remainingItemCount to be set or to be exact."

**es-shards-envelope**
URL: https://www.elastic.co/docs/solutions/search/the-search-api
Accessed: 2026-08-21
Quote: `"_shards": { "total": 1, "successful": 1, "skipped": 0, "failed": 0 }` present alongside `"timed_out": false` on a fully successful response.

**es-shards-field-defs**
URL: https://www.elastic.co/docs/api/doc/elasticsearch/v9/operation/operation-scroll
Accessed: 2026-08-21
Quote: total — "The number of shards the operation or search will run on overall."; successful — "The number of shards the operation or search succeeded on."; failed — "The number of shards the operation or search attempted to run on but failed."; failures — "an array containing details of shard failures, including index, node, reason, shard number, status".

**es-skipped-underdocumented**
URL: https://www.elastic.co/docs/api/doc/elasticsearch/v9/operation/operation-scroll — corroborated https://discuss.elastic.co/t/definition-for-skipped-in-shards-as-query-result/159841
Accessed: 2026-08-21
Quote: the `skipped` field appears in the response with no description in the documentation. In practice it counts shards pre-filtered by the can-match phase.

**es-timed-out**
URL: https://www.elastic.co/docs/api/doc/elasticsearch/v9/operation/operation-scroll
Accessed: 2026-08-21
Quote: "If `true`, the request timed out before completion; returned results may be partial or empty."

**es-allow-partial**
URL: https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-search
Accessed: 2026-08-21
Quote: "If `true` and there are shard request timeouts or shard failures, the request returns partial results. If `false`, it returns an error with no partial results." (default true; cluster-wide `search.default_allow_partial_results`)

**thanos-partial-response**
URL: https://thanos.io/tip/components/query.md/
Accessed: 2026-08-21
Quote: "controls tradeoff between accuracy and availability" (strategies "warn" and "abort"); "QueryAPI returns human readable warnings"; warnings contain "every error that occurred that is assumed non critical."

**thanos-warning-not-partial**
URL: https://thanos.io/tip/components/query.md/
Accessed: 2026-08-21
Quote: "Having a warning does not necessarily mean partial response (e.g no store matched query warning)." / a partial response "doesn't necessarily mean data loss — the broken store may have had nothing for your query anyway."

**prom-warnings-with-success**
URL: https://prometheus.io/docs/prometheus/latest/querying/api/
Accessed: 2026-08-21
Quote: warnings — "Only set if there were warnings while executing the request. There will still be data in the data field." (envelope: status, data, errorType, error, warnings, infos)

**prom-up-metric**
URL: https://prometheus.io/docs/concepts/jobs_instances/
Accessed: 2026-08-21
Quote: "up{job=\"<job-name>\", instance=\"<instance-id>\"}: 1 if the instance is healthy, i.e. reachable, or 0 if the scrape failed."

**prom-staleness**
URL: https://prometheus.io/docs/prometheus/latest/querying/basics/
Accessed: 2026-08-21
Quote: "A time series will go stale when it is no longer exported, or the target no longer exists. Such time series will disappear from graphs at the times of their latest collected sample, and they will not be returned in queries after they are marked stale."

**dns-nodata-vs-nxdomain**
URL: https://datatracker.ietf.org/doc/html/rfc2308
Accessed: 2026-08-21
Quote: §2.1 "Name errors (NXDOMAIN) are indicated by the presence of 'Name Error' in the RCODE field."; §2.2 "NODATA is indicated by an answer with the RCODE set to NOERROR and no relevant answers in the answer section." / "NODATA responses have to be algorithmically determined from the response's contents as there is no RCODE value to indicate NODATA."

**rfc8020-nxdomain-scope**
URL: https://datatracker.ietf.org/doc/html/rfc8020
Accessed: 2026-08-21
Quote: "When a DNS resolver receives a response with a response code of NXDOMAIN, it means that the domain name which is thus denied AND ALL THE NAMES UNDER IT do not exist."

**http-404-hides-403**
URL: https://datatracker.ietf.org/doc/html/rfc9110
Accessed: 2026-08-21
Quote: "An origin server that wishes to 'hide' the current existence of a forbidden target resource MAY instead respond with a 404 (Not Found) status code." / 404: "did not find a current representation for the target resource or is not willing to disclose that one exists."

**http-204**
URL: https://datatracker.ietf.org/doc/html/rfc9110
Accessed: 2026-08-21
Quote: "The server has successfully fulfilled the request and that there is no additional content to send in the response payload body."

**graphql-data-and-errors**
URL: https://spec.graphql.org/October2021/
Accessed: 2026-08-21
Quote: "A response may contain both a partial response as well as any field errors in the case that a field error was raised on a field and was replaced with null." / §6.4.4 "they are 'handled' by producing a partial response."

**graphql-request-vs-field-errors**
URL: https://spec.graphql.org/October2021/
Accessed: 2026-08-21
Quote: "This is distinct from 'request errors' which are raised before execution begins. If a request error is encountered, execution does not begin and no data is returned in the response." / "If a field error is raised, execution attempts to continue and a partial result is produced... The `data` entry in the response must be present."

**graphql-path-disambiguates-null**
URL: https://spec.graphql.org/October2021/
Accessed: 2026-08-21
Quote: "If an error can be associated to a particular field in the GraphQL result, it must contain an entry with the key `path` that details the path of the response field which experienced the error. This allows clients to identify whether a `null` result is intentional or caused by a runtime error."

**graphql-null-propagation**
URL: https://spec.graphql.org/October2021/
Accessed: 2026-08-21
Quote: "Since `Non-Null` type fields cannot be null, field errors are propagated to be handled by the parent field... If all fields from the root of the request to the source of the field error return `Non-Null` types, then the 'data' entry in the response should be null."

**trino-no-partial-state**
URL: https://trino.io/docs/current/develop/client-protocol.html
Accessed: 2026-08-21
Quote: "The `QueryResults` document contains an `error` field of type `QueryError` if the query has failed, and if that object is not present, the query succeeded."

**bigquery-errors-nonfatal**
URL: local command `curl -s "https://bigquery.googleapis.com/discovery/v1/apis/bigquery/v2/rest" | jq -r '.schemas.QueryResponse.properties.errors.description'`
Accessed: 2026-08-21
Quote: "Output only. The first errors or warnings encountered during the running of the job... Errors here do not necessarily mean that the job has completed or was unsuccessful."

**bigquery-jobcomplete**
URL: same discovery document, `.schemas.QueryResponse.properties.jobComplete.description`
Accessed: 2026-08-21
Quote: "Whether the query has completed or not. If rows or totalRows are present, this will always be true. If this is false, totalRows will not be available."

**http-warning-obsoleted**
URL: https://datatracker.ietf.org/doc/html/rfc9111
Accessed: 2026-08-21
Quote: "The \"Warning\" header field was used to carry additional information about the status or transformation of a message that might not be reflected in the status code. This specification obsoletes it, as it is not widely generated or surfaced to users."

**http-warning-rationale**
URL: https://datatracker.ietf.org/doc/html/rfc9111 (Appendix B)
Accessed: 2026-08-21
Quote: "Much of the information supported by Warning could be gleaned by examining the response, and the remaining information -- although potentially useful -- was entirely advisory. In practice, Warning was not added by caches or intermediaries."

**http-warn-codes**
URL: https://datatracker.ietf.org/doc/html/rfc7234 §5.5.1–5.5.3
Accessed: 2026-08-21
Quote: "111 - \"Revalidation Failed\" — A cache SHOULD generate this when sending a stale response because an attempt to validate the response failed, due to an inability to reach the server."

**http-age-header**
URL: https://datatracker.ietf.org/doc/html/rfc9111 §5.1
Accessed: 2026-08-21
Quote: "The \"Age\" response header field conveys the sender's estimate of the time since the response was generated or successfully validated at the origin server."

**http-age-absence-asymmetry**
URL: https://datatracker.ietf.org/doc/html/rfc9111 §5.1
Accessed: 2026-08-21
Quote: "However, lack of an Age header field does not imply the origin was contacted."

**http-stale-if-error**
URL: https://datatracker.ietf.org/doc/html/rfc5861 §4
Accessed: 2026-08-21
Quote: "The stale-if-error Cache-Control extension indicates that when an error is encountered, a cached stale response MAY be used to satisfy the request, regardless of other freshness information."

**http-content-location**
URL: https://datatracker.ietf.org/doc/html/rfc9110 §8.7
Accessed: 2026-08-21
Quote: "The \"Content-Location\" header field references a URI that can be used as an identifier for a specific resource corresponding to the representation in this message's content."

**dnssec-ad-bit**
URL: https://datatracker.ietf.org/doc/html/rfc4035 §3.1.6
Accessed: 2026-08-21
Quote: "A security-aware name server MUST NOT set the AD bit in a response unless the name server considers all RRsets in the Answer and Authority sections of the response to be authentic."

**dnssec-ad-is-a-claim**
URL: https://datatracker.ietf.org/doc/html/rfc4035 §4.9.3
Accessed: 2026-08-21
Quote: "in order to determine whether the security-aware recursive name server that sent the response claims to have cryptographically verified the data"

**dnssec-cd-bit**
URL: https://datatracker.ietf.org/doc/html/rfc4035 §3.2.2
Accessed: 2026-08-21
Quote: "The CD bit exists in order to allow a security-aware resolver to disable signature validation in a security-aware name server's processing of a particular query."

**slsa-graded-levels**
URL: https://slsa.dev/spec/v1.0/levels
Accessed: 2026-08-21
Quote: "Build L1: Provenance exists... trivial to bypass or forge. / Build L2: Hosted build platform — Forging the provenance or evading verification requires an explicit \"attack\"... / Build L3: Hardened builds — Forging the provenance or evading verification requires exploiting a vulnerability that is beyond the capabilities of most adversaries."

**slsa-l1-incomplete**
URL: https://slsa.dev/spec/v1.0/levels
Accessed: 2026-08-21
Quote: "Provenance may be incomplete and/or unsigned at L1. Higher levels require more complete and trustworthy provenance."

**intoto-subject-predicate**
URL: https://github.com/in-toto/attestation/blob/main/spec/README.md
Accessed: 2026-08-21
Quote: "Predicate: Contains arbitrary metadata about a subject artifact, with a type-specific schema. Statement: Binds the attestation to a particular subject and unambiguously identifies the types of the predicate."

**otel-status-unset**
URL: https://opentelemetry.io/docs/specs/otel/trace/api/#set-status
Accessed: 2026-08-21
Quote: "StatusCode is one of the following values: Unset The default status. Ok The operation has been validated by an Application developer or Operator to have completed successfully. Error The operation contains an error."

**w3c-sampled-flag**
URL: https://www.w3.org/TR/trace-context/ §3.2.2.5.1
Accessed: 2026-08-21
Quote: "When set, the least significant bit (right-most), denotes that the caller may have recorded trace data."

**codd-a-marks-i-marks**
URL: https://en.wikipedia.org/wiki/Null_(SQL) (underlying citation: Codd, *The Relational Model for Database Management, Version 2*, 1990, ISBN 978-0-201-14192-4)
Accessed: 2026-08-21
Quote: "these two Null-type markers are referred to as 'A-Values' and 'I-Values', representing 'Missing But Applicable' and 'Missing But Inapplicable', respectively. Codd's recommendation would have required SQL's logic system be expanded to accommodate a four-valued logic system."
Note: whether the 1979 TODS paper uses "A-marks"/"I-marks" verbatim is NOT DETERMINED (ACM served a paywall shell); terminology verified against the 1990 book.

**codd-rejected-for-complexity**
URL: https://en.wikipedia.org/wiki/Null_(SQL)
Accessed: 2026-08-21
Quote: "Because of this additional complexity, the idea of multiple Nulls with different definitions has not gained widespread acceptance in the database practitioners' domain. It remains an active field of research though."

**nulls-open-world**
URL: https://en.wikipedia.org/wiki/Null_(SQL)
Accessed: 2026-08-21
Quote: "Nulls, however, operate under the open world assumption, in which some items stored in the database are considered unknown, making the database's stored knowledge of the world incomplete."

**nist-uncertainty**
URL: https://www.nist.gov/pml/nist-technical-note-1297/nist-tn-1297-appendix-c-nist-technical-communications-program
Accessed: 2026-08-21
Quote: "A measurement result is complete only when accompanied by a quantitative statement of its uncertainty."

## SYNTHESIS

**Recommendation: CLI verbs first, one Skill second, an optional SessionStart push third. No MCP server — for now, and for a stated reason, not a vibe.**

The decisive question the evidence converges on is not "is MCP good" but **"does the consumer have a shell?"** Waspflow's consumers are coding agents that waspflow itself spawned into tmux — every one of them has a shell, and most of them waspflow chose. That places it squarely in the CLI+Skill default that Anthropic's Skills architecture is built for and that Microsoft now recommends over its own 67-tool MCP server. The MCP arguments that survive scrutiny are about audiences waspflow does not have (browser agents, claude.ai, multi-tenant sandboxes with no shell) and about a property waspflow does not need from a *query* surface (server-held session state).

**The competitor evidence is more one-sided than expected, and Gas Town is the direct precedent.** Gas Town is the closest analogue in existence — an agent-driven supervisor of agent workers — and with 292 verbs it has the discoverability problem in a far more acute form than waspflow. It ships **no MCP server**. It solves discoverability three ways, all of which waspflow can copy cheaply: (1) a `polecatSafe` annotation that reduces 292 verbs to ~13 agent-facing ones, published machine-readably via `gt proxy-subcmds` rather than trusting `--help`; (2) per-command `--json`; (3) role-scoped context pushed at SessionStart by `gt prime --hook`. The one competitor with a real query-oriented MCP server, vibe-kanban, is the exception that confirms the rule — its MCP is a *thin stdio client over its own HTTP API*, i.e. additive over a primary machine interface, exactly the layering the brief demands, and even it scopes tools into Global vs Orchestrator routers rather than exposing one flat catalog. Codex's MCP server is not a counter-example at all: two tools, both invocation.

**How the CLI stays primary — structurally, not by intention.** The layering that makes this safe is the one vibe-kanban and Cloudflare both use: the CLI (or an API beneath it) is the only thing that knows how to answer a query; every other surface is a caller of it. A Skill contains no logic — it teaches the verbs, the flags, and when to reach for them, and its bundled scripts are "executed, not loaded." A SessionStart hook shells out to the same CLI. If MCP is ever added, it must shell out too. The moment a second surface acquires its own query logic, the CLI stops being primary and starts being one of two implementations that will drift. Two supporting details make this concrete: `allowed-tools` can pre-approve the exact waspflow invocation so the skill runs prompt-free, and one SKILL.md on the agentskills.io standard serves both Claude Code and Codex, so the skill route costs one file, not one per harness.

**On discoverability, be honest: the `--help` premise is unproven.** No controlled study relates `--help` quality to agent success; the closest real evidence (the 120-run study) found that clear instructions shipped *with* the tool sufficed and agents didn't need `--help` — which argues for the Skill, not for elaborate help text. GitLab's unshipped `glab --agent-info` proposal suggests vendors suspect plain `--help` is insufficient, but suspicion is not evidence. Practical read: invest in the Skill and in stable `--json`, treat `--help` as the fallback, and don't claim a discoverability win you can't measure.

**The push/pull question resolved: do both, because the brief's premise about hooks was wrong.** Hooks are not react-only — `SessionStart` stdout and `additionalContext` are documented push channels in *both* Claude Code and Codex, and Gas Town already uses exactly this to inject role context. So a spawned worker can be told its own lane and root at launch with no query at all. But pushed context is snapshot-once and compaction-eroded (skill bodies are never re-read; re-attached skills keep only the first 5,000 tokens under a 25,000-token budget), so push alone will drift in exactly the long-running sessions waspflow exists to manage. The defensible shape is hybrid: **push identity at spawn** (waspflow already controls the launch boundary and already validates `CLAUDE_SESSION_ID`/Codex thread IDs — and OTel's env-carrier spec is the standard precedent for propagating identity into a child process), and **keep the CLI as the pull path** for fleet-scale questions and for freshness. Note this is my interpretation; no source directly analyzes the staleness tradeoff.

**Requirement 1 — evidence classes must not flatten — has excellent prior art, and one specific trap.** The transferable pattern from DNSSEC, SLSA, in-toto and OTel is: the class rides in the same envelope as the value, always, and it is framed as *what the asserter claims*, not as truth. Three concrete rules follow. First, **never emit a parent without its class in the same record** — SLSA's graded ladder is the right mental model, where `caller_asserted` is L1-grade ("trivial to forge") and `observed_harness_env` is meaningfully stronger, and naming them by adversary cost rather than a confidence score keeps the semantics honest. Second, **default to unknown, never to fine** — OTel's `Unset` default and the rule that `Ok` must be explicitly asserted. Third, and this is the trap: **absence of a class must not read as high confidence**, exactly as RFC 9111 warns that a missing `Age` header does not imply the origin was contacted. Waspflow's `absent` class already does this correctly; the danger is a query surface that omits the field when it's `absent` rather than emitting it.

**Requirement 2 — absence vs non-coverage — has one dominant precedent and one dominant failure.** The dominant precedent is Elasticsearch `_shards`: four integers, present on *every* response including complete successes. The dominant failure is HTTP's `Warning` header, obsoleted because it was "entirely advisory" and consequently "not added by caches or intermediaries." Codd's A/I-marks failed the same way for the same reason — correct, and rejected for complexity. The lesson is sharp and it is the single most important design constraint here: **a coverage field that is optional, omitted-when-clean, or advisory will not be emitted and will not be read.** Make it structural and unconditional, and make it cheap — four integers succeeded where four-valued logic failed.

Concretely, that means a `list`/`query` result should always carry a coverage block stating which sources were consulted and which were not, so an empty `lanes` array is never ambiguous. kubectl is the cautionary case waspflow must not reproduce: it prints "No resources found" to *stderr*, and prints it even when the real problem was a connection failure — the identical conflation that caused this week's error. Two refinements are worth stealing. Thanos's distinction prevents alarm fatigue: an unreachable source does not mean the answer is wrong, because "the broken store may have had nothing for your query anyway" — report coverage-incomplete, don't escalate it to answer-invalid. And GraphQL's `errors[].path` is the most directly applicable normative rule found: point at *which* coordinate is missing, so a consumer can tell an intentional gap from a failure.

**Two warts to avoid, both observed live.** First, do not let the JSON path carry less than the text path — `systemctl --output=json` returns a bare `[]` and drops the coverage hint the human output shows, and systemd's hint lives in the legend that every script disables. Second, do not let display concerns leak into serialization — `docker ps --format json` truncates values with an ellipsis by default and stringly-types nested fields. If waspflow adopts one stability rule, make it systemd's and git's: declare *per command* which output is a machine contract, and make that contract independent of user configuration.

**Trigger conditions to revisit MCP.** This recommendation is falsifiable. Add an MCP server if any of these become true: (a) a real consumer appears that has no shell (a web UI, a hosted orchestrator, a claude.ai-side workflow); (b) the query surface grows genuine multi-turn *server-held* state, which is the one axis where the CLI camp's own leading advocate reversed; or (c) measurement shows agents burning turns chaining waspflow reads — the Stripe suite found CLI cost the most on chained multi-step work (19 turns vs 4), so the CLI advantage is not universal and is weakest exactly where a query surface gets composed repeatedly. Until one of those holds, an MCP server would be the "tools that merely wrap existing... API endpoints" that Anthropic names as a common error, plus a process to supervise, four config formats to document, and a second implementation to keep in sync.

**What I could not verify.** Whether `--help` depth changes agent behaviour (no eval exists). The staleness tradeoff of push vs pull as an explicit documented finding. kubectl's exit-code contract for empty-vs-error. Whether Codd's 1979 paper uses "A-marks"/"I-marks" verbatim (verified against the 1990 book instead). Three of the four MCP-vs-CLI benchmarks are blog-grade and two of them disagree with the CLI-wins consensus; one has headline numbers its own repo contradicts. Finally, the earlier sweep's clones were gone, so these repos were re-cloned at 2026-08-21 HEAD — findings describe today's state, and the two repos named in the brief that I could not locate under any obvious org (firstmate, agent-deck, multiclaude, agent-orchestrator, oragent) are **not covered**; firstmate in particular was flagged as highly relevant and remains unexamined.
