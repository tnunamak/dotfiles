---
title: "Third-party protocol extensions are best served by a namespaced-capability wire boundary plus PATH/registry-style discovery metadata, not a runtime code-loading plugin system"
date: 2026-08-14
topic: extension-architecture
tags: [mcp, cli-plugins, protocol-design, capability-discovery, lsp, terraform, krew, oclif, opentelemetry]
status: draft
sources: [claude-desktop-config, mcp-aggregation-q1-2026, metamcp, krew-architecture, krew-index-deepwiki, git-howto-new-command, rust-analyzer-lsp-extensions, lsp-dollar-slash-spec, otel-registry, otel-adding-registry, terraform-plugin-protocol, terraform-registry-provider-protocol, terraform-provider-requirements, oclif-plugin-plugins-github, vscode-extension-runtime-security]
source_session: 9fdbf189-ee1a-4a83-94fa-df700c11b73d
---

## CLAIMS

- Claude Desktop and Claude Code impose no hard limit on the number of simultaneously-configured MCP servers under `mcpServers`; each server is an independent process/connection keyed by an arbitrary name in the config JSON, so a third party can ship a fully standalone MCP server for a PDPP extension profile today with zero coordination from the first-party server. [claude-desktop-config]
- Practical downside of many small MCP servers is host-side: dozens of servers with hundreds of tools slows session startup and adds tool-selection noise for the model, and each additional server increases attack surface — this is a UX/context cost, not a protocol-level blocker. [claude-desktop-config]
- There is no official MCP aggregation standard; Anthropic's spec does not define how to merge multiple servers into one logical surface, so every aggregator (MetaMCP, mcp-proxy, IBM ContextForge, Docker MCP Gateway, agentgateway, MCPJungle, combine-mcp) invents its own namespacing, tool-dedup, and auth-delegation approach. [mcp-aggregation-q1-2026]
- MetaMCP's aggregation model is Servers → Namespaces → Endpoints: individual MCP servers are grouped into a "namespace" where tools can be enabled/disabled and renamed, and each public-facing "endpoint" exposes exactly one namespace over SSE/Streamable-HTTP/OpenAPI. [metamcp]
- An emerging aggregator pattern is "nested aggregation" — aggregators that themselves consume other aggregators, forming a federation tree the client never has to see past its own single connection. [mcp-aggregation-q1-2026]
- OAuth 2.1 for MCP is still evolving and there is no standard for auth delegation across multiple aggregated servers as of Q1 2026 — meaning N independent third-party MCP servers today generally means N independent auth flows unless a gateway layer is added. [mcp-aggregation-q1-2026]
- krew's plugin index (`krew-index`) is a git repository of per-plugin YAML manifests (name, version, platform-specific download URL, checksums for `.tar.gz`/`.zip`); the index itself carries no executable code, only metadata pointing to externally-hosted release archives (typically GitHub releases). [krew-architecture, krew-index-deepwiki]
- Getting a plugin into the *public* krew-index requires a reviewed pull request adding one YAML file to the `plugins/` directory; anyone can bypass that review entirely by pointing their local `kubectl krew` at a custom index via `KREW_DEFAULT_INDEX_URI`, with no central approval needed. [krew-index-deepwiki]
- Git's subcommand mechanism is pure PATH convention: `git <foo>` first checks Git's own exec-path, then falls back to scanning the rest of `$PATH` for an executable literally named `git-foo`; there is no manifest, registry, or negotiation step at all — discovery is 100% filesystem/PATH based. [git-howto-new-command]
- LSP's `$/`-prefixed methods (e.g. `$/cancelRequest`, `$/progress`) are reserved by the base spec for protocol-level notifications any implementation may safely ignore; this is distinct from vendor-namespaced extension methods. [lsp-dollar-slash-spec]
- rust-analyzer splits its non-standard methods into two namespaces by upstreaming intent: `experimental/*` for things it hopes will eventually become part of core LSP, and `rust-analyzer/*` for things expected to stay permanently vendor-specific. [rust-analyzer-lsp-extensions]
- LSP capability negotiation for these extensions happens entirely through the standard `initialize` handshake's `experimental` field on `ClientCapabilities`/`ServerCapabilities` — servers only expose extended behavior if the client's `experimental` capabilities object signals support, and vice versa; there is no separate registry of extension IDs. [rust-analyzer-lsp-extensions]
- Client support for vendor LSP extensions varies by editor (Eglot explicitly declines to support rust-analyzer extensions; lsp-mode and Neovim's built-in client support more, including runtime queries like "does the server support inlayHint/resolve"), illustrating that capability negotiation is necessary but not sufficient — client adoption is still required per extension. [rust-analyzer-lsp-extensions]
- OpenTelemetry's registry (opentelemetry.io/ecosystem/registry) is a pure listing/catalog with maintainer self-submission (PR-based, "Adding to the registry" is a documented but unenforced process) — it is not a code-loading or trust mechanism, just discoverability metadata. [otel-registry, otel-adding-registry]
- OTel formally distinguishes "Core" packages (spec-defined, e.g. OTLP exporter, TraceContext propagator — SIG-maintained) from "Contrib" packages (optional exporters/propagators/instrumentation, maintained outside core, loaded via the SDK's documented plugin interfaces such as Java's `@AutoService`/SPI `META-INF/services` mechanism). [otel-registry]
- OTel's actual extension point is a documented language-level interface contract (exporter/propagator/resource-detector interfaces) plus a language-native discovery convention (SPI in Java, package imports elsewhere) — the registry is separate from and does not enforce use of that interface; nothing stops a broken or malicious package from being listed. [otel-registry]
- Terraform Core communicates with every provider — first-party or third-party — over the same versioned gRPC/protobuf "provider protocol," currently split between protocol v5 (legacy, maintained for compat) and protocol v6 (current default, adds resource identity, move-resource-state, deferred actions, ephemeral resources, provider-contributed functions, list resources). [terraform-plugin-protocol]
- HashiCorp ships official muxing tooling (`tf5to6server`, `tf6muxserver`, `tf5muxserver`) so providers built against different protocol versions can be combined and served together, and so a provider can be upgraded from v5 to v6 without breaking Terraform Core compatibility. [terraform-plugin-protocol]
- Terraform provider addresses are a three-part `hostname/namespace/type` identifier (default hostname `registry.terraform.io`); anyone can publish a provider under their own namespace (e.g. `DataDog/datadog`) with zero code review by HashiCorp beyond the "Official"/"Verified-Partner"/"Community" tier badge, which is a trust-signal label, not a security gate. [terraform-registry-provider-protocol]
- Terraform's provider registry protocol itself (used by `required_providers` resolution) is an open, documented HTTP API that third parties can implement independently to run their own private/alternate registry — the public registry is just the reference implementation, one of potentially many. [terraform-registry-provider-protocol]
- Publishing to the public Terraform Registry requires a GitHub repo matching `terraform-provider-{NAME}`, a registered signing key, and creates a release-event webhook — versions are pulled automatically from GitHub releases, not reviewed line-by-line by HashiCorp. [terraform-registry-provider-protocol]
- oclif's plugin installation (`@oclif/plugin-plugins`) is a thin wrapper around `npm install`: there is no sandboxing, no permission scoping, and an installed third-party plugin can override a core plugin entirely — it runs with full privilege in the same Node process. [oclif-plugin-plugins-github]
- VS Code has no capability-scoped extension permission model either: per VS Code's own "Extension runtime security" docs, an installed extension can read/write any file the editor can, spawn arbitrary processes, and make arbitrary network calls; VS Code's actual trust mechanism is a publisher-identity confirmation dialog (since v1.97) plus optional workspace-trust gating, not per-capability scoping. [vscode-extension-runtime-security]
- Both oclif and VS Code's extension models therefore share the same fundamental trust boundary as any npm dependency: installing a third-party package/extension grants it full ambient authority in-process, and mitigation happens outside the tool (containerized installs, registry scanning, manual vetting) rather than through the extension framework itself. [oclif-plugin-plugins-github, vscode-extension-runtime-security]

## SOURCES

**claude-desktop-config**
URL: https://modelcontextprotocol.io/docs/develop/connect-local-servers
Accessed: 2026-08-14
Quote: "There's no hard limit on how many MCP servers you can register... In practice, having dozens of servers with hundreds of tools can slow session startup and may add noise to Claude's tool selection."

**mcp-aggregation-q1-2026**
URL: https://www.heyitworks.tech/blog/mcp-aggregation-gateway-proxy-tools-q1-2026
Accessed: 2026-08-14
Quote: "there's no official aggregation standard since Anthropic's MCP spec doesn't define how to aggregate servers... there's no standard auth delegation since OAuth 2.1 for MCP is still evolving"

**metamcp**
URL: https://github.com/metatool-ai/metamcp
Accessed: 2026-08-14
Quote: "MetaMCP uses a three-level hierarchy for aggregating MCP servers: Servers → Namespaces → Endpoints"

**krew-architecture**
URL: https://github.com/kubernetes-sigs/krew/blob/master/docs/KREW_ARCHITECTURE.md
Accessed: 2026-08-14
Quote: "currently, krew only supports downloading plugin packages of formats .tar.gz and .zip over HTTP(S) protocol"

**krew-index-deepwiki**
URL: https://deepwiki.com/kubernetes-sigs/krew-index
Accessed: 2026-08-14
Quote: "each plugin has its own YAML file in the plugins folder... they need to make a pull request to the krew-index"

**git-howto-new-command**
URL: https://git.github.io/htmldocs/howto/new-command.html
Accessed: 2026-08-14
Quote: "to execute git <foo>, git finds command <foo> (either a core Git program found in GIT_EXEC_PATH, or a custom one in a directory on PATH), before trying foo as an alias"

**rust-analyzer-lsp-extensions**
URL: https://github.com/rust-lang/rust-analyzer/blob/979e788957ced1957ee9ac1da70fb97abf9fe2b1/docs/dev/lsp-extensions.md
Accessed: 2026-08-14
Quote: "Requests which they hope to upstream live under experimental/ namespace, while requests which are likely to always remain specific to rust-analyzer are under rust-analyzer/ namespace... All capabilities are enabled via experimental field of ClientCapabilities or ServerCapabilities."

**lsp-dollar-slash-spec**
URL: https://deepwiki.com/rust-lang/rust-analyzer/3-language-server-protocol-integration
Accessed: 2026-08-14
Quote: "the base LSP spec reserves the $/ prefix (e.g., $/cancelRequest, $/progress) for protocol-level implementation notifications that any client/server may choose to ignore safely"

**otel-registry**
URL: https://opentelemetry.io/ecosystem/registry/
Accessed: 2026-08-14
Quote: "Core packages are maintained by an OpenTelemetry SIG and are distinct from Contrib packages, which are optional."

**otel-adding-registry**
URL: https://opentelemetry.io/ecosystem/registry/adding/
Accessed: 2026-08-14
Quote: "If you are a project maintainer, you can add your project to the OpenTelemetry Registry."

**terraform-plugin-protocol**
URL: https://developer.hashicorp.com/terraform/plugin/terraform-plugin-protocol
Accessed: 2026-08-14
Quote: "Protocol v6, the current protocol version with the latest features... resource identity, move resource state, deferred actions, ephemeral resources, functions, and list resources."

**terraform-registry-provider-protocol**
URL: https://developer.hashicorp.com/terraform/internals/provider-registry-protocol
Accessed: 2026-08-14
Quote: "the provider registry protocol is what Terraform CLI uses to discover metadata about providers available for installation and locate distribution packages... by writing and deploying your own implementation, you can create a separate origin registry"

**terraform-provider-requirements**
URL: https://developer.hashicorp.com/terraform/language/providers/requirements
Accessed: 2026-08-14
Quote: "The source attribute uses a three-part format: hostname/namespace/type"

**oclif-plugin-plugins-github**
URL: https://github.com/oclif/plugin-plugins
Accessed: 2026-08-14
Quote: "this plugin installs a plugin into the CLI using npm to install plugins" (no sandboxing layer documented)

**vscode-extension-runtime-security**
URL: https://code.visualstudio.com/docs/configure/extensions/extension-runtime-security
Accessed: 2026-08-14
Quote: "an extension runs with the user's full permissions: it can read and write any file the editor can, spawn processes, and make network calls."

## SYNTHESIS

Every strong, durable prior-art pattern here separates two things PDPP is currently conflating: the wire-level extension seam (how a capability is named and negotiated) from the code-loading/distribution seam (how third-party code gets onto a user's machine and runs). The protocol boundary can and should be opened now, cheaply and without risk. The code-loading boundary should stay closed until there's a real trust story.

Terraform is the cleanest model: Core never runs third-party code in-process — it talks to a separate binary over a versioned RPC protocol, and "third party" only means "different namespace in the address string," not "different trust model in the runtime." LSP shows the namespacing half of this at the wire-metadata layer: reserve a prefix for protocol-owned concerns, give first-party extensions a durable namespace, and let anyone else claim their own prefix (vendor/org-scoped), with capability negotiation happening declaratively at handshake time so unrecognized capabilities are just absent, never fatal. MCP's own multi-server story proves a third party doesn't need any permission from PDPP's core team to ship value today — they can register an independent MCP server directly with the host — but the aggregation-tooling chaos (many competing gateway projects, no standard namespacing or auth delegation) is the visible cost of MCP not having designed a first-party aggregation seam: everyone downstream had to invent one badly, in parallel. krew and git both confirm that a plugin index can be pure inert metadata (a YAML pointer or a PATH convention) with zero code execution by the index/core maintainer — review, if any, happens at the metadata layer, not the payload layer, and even that review is optional (custom indexes, arbitrary PATH entries bypass it entirely). OTel's registry is the weakest of the "registries" studied — a self-submitted, unenforced listing — useful as a discoverability precedent but not a trust mechanism at all. oclif and VS Code are the cautionary tale: both grant full ambient runtime authority to installed third-party code with no capability scoping, and both explicitly rely on external mitigations (publisher trust dialogs, workspace trust, registry scanning) rather than framework-level sandboxing — this is exactly the shape of risk that should be deferred, not adopted, for PDPP's "easy unlock later."
