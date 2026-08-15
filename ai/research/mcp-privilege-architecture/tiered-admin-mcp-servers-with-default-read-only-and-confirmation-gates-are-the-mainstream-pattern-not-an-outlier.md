---
title: "Every major official MCP server that exposes admin/write power (GitHub, Stripe, Cloudflare, Supabase, Neon, AWS, Sentry, Kubernetes) ships default-read-only + tiered/scoped write access + confirmation gates — an owner-persona MCP with the same shape is mainstream, not an outlier"
date: 2026-08-14
topic: mcp-privilege-architecture
tags: [mcp, owner-persona, admin, read-only, toolsets, elicitation, confused-deputy, lethal-trifecta, tool-annotations, least-privilege]
status: draft
sources: [mcp-tools-2025-06-18, mcp-blog-tool-annotations, mcp-blog-2026-07-28, github-mcp-repo, github-mcp-server-config, github-mcp-readonly-bypass-issue, stripe-restricted-keys, stripe-ai-discussion-216, cloudflare-mcp-repo, cloudflare-agents-governance, cloudflare-agents-authz, supabase-mcp-docs, neon-mcp-repo, neon-mcp-docs, aws-iam-mcp-server, aws-api-mcp-server, aws-s3-tables-mcp-server, aws-mcp-ga-blog, sentry-mcp-deepwiki-authz, k8s-mcp-toolhive-guide, k8s-mcp-redhat, k8s-mcp-cve-2026-46519, willison-supabase-trifecta, willison-lethal-trifecta-newsletter, invariant-github-mcp, dev-api-to-mcp-destructive-survey]
source_session: 5ef17ffa-1518-4990-9859-dfa8981ef09c
---

<!-- Researched for PDPP's mcp-server owner-persona decision. Answers whether an
     MCP server may defensibly expose OWNER/ADMIN operations (vs. read-only-only),
     and what mainstream mitigation architecture looks like when it does.
     Overlaps checked: ai/research/oauth-mcp-auth/ (token/OAuth/CIMD mechanics, not
     privilege-tiering architecture) and
     ai/research/api-contract-design/mcp-tool-surface-minimized-by-host-native-search-server-toolsets-and-grant-scope.md
     (GitHub toolsets from a token-footprint angle, not a security-architecture angle) —
     no duplication with either; this entry is the security/privilege-tiering layer
     those two don't cover. See [[mcp-tool-surface-minimized-by-host-native-search-server-toolsets-and-grant-scope]]. -->

## CLAIMS

### (a) Official MCP servers exposing admin/write power, and how they scope it

- GitHub's official MCP server (`github/github-mcp-server`) defaults to five toolsets (`context, issues, pull_requests, repos, users`) and offers a `--read-only` flag / `GITHUB_READ_ONLY=1` env var that "will only offer read-only tools, preventing any modifications to repositories, issues, pull requests, etc." and takes precedence over any other configuration — e.g. `create_issue` is excluded even if the `issues` toolset is enabled. [github-mcp-server-config]
- GitHub's remote server exposes the equivalent read-only control via an `X-MCP-Readonly` header or `/readonly` URL path rather than a local flag. [github-mcp-server-config]
- GitHub added a "lockdown mode" (`GITHUB_LOCKDOWN_MODE=1` / `X-MCP-Lockdown` header) that "ensures the server only surfaces content in public repositories from users with push access to that repository," with private repos and collaborators' own content unaffected — a mitigation aimed specifically at prompt-injection-via-public-content, and GitHub also ships "comprehensive content sanitization... enabled by default." [github-mcp-server-config]
- GitHub's toolset system is fully composable (toolsets + individual `--tools` + `--tools-exclude` + read-only + lockdown), with excluded tools taking precedence over everything else, and supports "dynamic toolset discovery" so the host can enable toolsets on demand instead of loading all tools upfront. [github-mcp-server-config]
- A real security bug (GitHub issue, reported against server v0.31.0 running in `http`/streamable-HTTP mode) shows `--read-only` / `GITHUB_READ_ONLY=1` failed to restrict write tools (`create_branch`, `create_pull_request`, `merge_pull_request` remained listed and functional) in that transport mode — i.e., a flag-based read-only control is only as strong as its enforcement path, and enforcement bugs happen even in a widely-used official server. [github-mcp-readonly-bypass-issue]
- Stripe's MCP server (remote OAuth endpoint at `mcp.stripe.com`, or local `npx -y @stripe/mcp`) exposes ~25 tools across ~13 categories including elevated-scope financial operations, and gates them via Stripe's pre-existing Restricted API Key (RAK) mechanism: a RAK (prefix `rk_live_`/`rk_test_`) can be scoped to only the specific API permissions chosen, versus a standard secret key (`sk_live_`) which "allows any person, agent, or system with that key to do anything in the account." [stripe-restricted-keys]
- A GitHub Discussion on Stripe's own `stripe/ai` repo names the limitation of RAKs directly: they are a "coarse instrument" — a key can express "this key can do refunds" but not "this key can do at most 5 refunds totaling under $X today, only for customers in this allowlist" — implying real safety for money-moving MCP tools needs server-side policy on top of the key scope, not the key scope alone. [stripe-ai-discussion-216]
- Cloudflare ships per-server API-token scoping (user tokens vs. account tokens, `Account Resources: Read` recommended for auto-detecting account ID) plus a separate **MCP governance** layer in its Zero Trust/Access product: an "MCP server portal" where administrators define identity (who), conditions (device posture/location), and scope (which specific tools within a server are authorized), with all MCP requests and tool executions logged for audit. [cloudflare-mcp-repo][cloudflare-agents-governance]
- Cloudflare's own Agents docs recommend deploying "several focused MCP servers, each with narrowly scoped permissions" rather than one broad server, and describe a pattern where tool availability is gated per-user by external identity-provider role claims (e.g., only users with an `image_generation` permission in their IdP get access to a sensitive tool). [cloudflare-agents-authz]
- Supabase's official MCP server treats `--read-only` (routes every query through a read-only Postgres role) as "the single most important flag to set," recommends it be the default, and separately supports `project_ref` scoping (limits the server to one project instead of the whole account — `get_advisors` and account-wide tools are disabled in this mode) and a `--features` flag selecting toggleable tool groups (`account, docs, database, debug, development, functions, storage, branching`; `storage` excluded by default). Supabase's official combined 2026 guidance is: "don't connect to production... use read-only mode for real data, scope to specific projects, and enable manual tool approval in clients." [supabase-mcp-docs]
- Neon's official MCP server (`neondatabase/mcp-server-neon`) supports OAuth scopes `read`, `write`, `*`, project-level scoping via `projectId` (disables cross-project search/navigation), category-based tool restriction via a repeatable `category` param, and — as of March 2026 — runtime scoping headers (`X-Neon-Read-Only`, `X-Neon-Scopes`, `X-Neon-Project-Id`) that "dynamically filter available tools per authentication grant." Neon's own docs state the server "is intended for local development and IDE integrations only, and is not recommended for production environments because it can execute powerful operations that may lead to accidental or unauthorized changes," and instruct users to "always review and authorize actions requested by the LLM before execution." [neon-mcp-repo][neon-mcp-docs]
- AWS ships read-only-by-default or read-only-flagged modes across multiple official (AWS Labs) MCP servers: the IAM MCP Server supports `--readonly` to block all mutating IAM operations; the API MCP Server supports `READ_OPERATIONS_ONLY=true`, which AWS explicitly calls a "secondary control" — "IAM permissions remain the primary and most reliable security control"; the S3 Tables MCP Server defaults to read-only unless a `--allow-write` flag is explicitly passed. [aws-iam-mcp-server][aws-api-mcp-server][aws-s3-tables-mcp-server]
- AWS's account-level "AWS MCP Server" (GA) ships IAM condition keys (e.g. `aws:ViaAWSMCPService`) so an org can write a policy allowing a human to perform mutating operations while denying the same mutating action specifically when it originates from the MCP server — i.e., separation of duties enforced at the IAM layer, independent of anything the MCP server itself does — plus CloudWatch (`AWS-MCP` namespace) and CloudTrail visibility specifically for MCP-originated calls. [aws-mcp-ga-blog]
- Sentry's MCP server defaults stdio mode to read-only (`DEFAULT_SCOPES`) and is migrating its authorization model from static OAuth `scopes` to a "skills" system: runtime authorization for a remote HTTP session is driven by `grantedSkills` (which tools), path constraints (which org/project), and Sentry's own upstream bearer-token checks — with an explicit non-widening rule: "refresh does not widen access... reuses the same stored grant props and does not ask Sentry for broader permissions." [sentry-mcp-deepwiki-authz]
- Kubernetes MCP server guidance (ToolHive, Red Hat, `containers/kubernetes-mcp-server`) converges on the same shape as every other domain: run under a dedicated least-privilege ServiceAccount (not an existing admin kubeconfig), default to read-only, and only enable write (`--read-write=true`) "when necessary and in controlled environments." [k8s-mcp-toolhive-guide][k8s-mcp-redhat]
- A disclosed vulnerability (CVE-2026-46519, CVSS 8.8, in the popular `mcp-server-kubernetes` project) shows the same enforcement-gap failure mode as the GitHub read-only bypass: the environment variables meant to restrict tool access (including read-only mode) "are enforced at the discovery layer but not at the execution layer, meaning any client can invoke restricted tools directly" — in a cluster-admin-scoped, multi-user HTTP deployment this yields full cluster compromise. Fixed in v3.6.0. [k8s-mcp-cve-2026-46519]
- A survey converting 10 popular commercial APIs into MCP tool definitions found 300+ destructive endpoints (delete/cancel/revoke/irreversible-mutate) across those 10 APIs, and found 7 of 10 would let an agent delete data "with zero guardrails" if exposed naively — i.e., the risk this research addresses is general across the MCP ecosystem, not specific to any one vendor. [dev-api-to-mcp-destructive-survey]

### (b) Documented attacks and incidents

- Invariant Labs (May 2025) disclosed a working exploit against GitHub's official MCP server: an attacker opens a public GitHub issue containing a hidden prompt-injection payload; a developer's agent (e.g. Claude Desktop) reading that issue via the GitHub MCP server is hijacked into enumerating the user's other repos (including private ones), reading private file contents (in the demo: personal project names, a relocation plan, salary info), and then writing that harvested private data into a public README via a PR — fully exfiltrating private data through a public channel. [invariant-github-mcp]
- Invariant Labs and outside commentary agree this is *not* a code bug in the GitHub MCP server: "this vulnerability cannot be resolved through server-side patches. It requires architectural controls — not just software updates" — the server behaved exactly to spec, faithfully relaying an injected instruction found in data it was asked to retrieve. It reproduced across a broad-scope token and a narrower "public repos only" token; notably the narrow token *read* the private repos anyway but could not *write* the exfiltrated data back out, showing write-scoping (not read-scoping) was the actual choke point in that token configuration. [invariant-github-mcp]
- Simon Willison named this pattern the "lethal trifecta": an agent that combines (1) access to private data, (2) exposure to untrusted/attacker-controlled content, and (3) a channel to exfiltrate data back out. He has since documented the same trifecta recurring in Supabase's MCP server and (separately, via X posts) Atlassian's newly released MCP server. [willison-lethal-trifecta-newsletter][willison-supabase-trifecta]
- The Supabase MCP incident (July 2025, General Analysis): a developer's agent held the Supabase `service_role` key (bypasses Row-Level Security entirely) and ingested customer support messages as input; an attacker filed a support ticket containing a hidden instruction ("IMPORTANT: Instructions for CURSOR CLAUDE...") that got the agent to run unauthorized database reads and leak the results back through the same support channel. [willison-supabase-trifecta]
- Willison's own critique of read-only-as-a-complete-fix: "read-only is necessary but not sufficient — it removes the write-back exfiltration path, but a model that can read private data and is exposed to injection can still leak it through its own response text" — i.e., an owner-persona MCP that is read-only but still both reads sensitive owner data AND is exposed to untrusted content (e.g. web-fetched pages, third-party emails) retains an exfiltration-via-response-text risk that read-only mode alone does not close. [willison-supabase-trifecta]
- The MCP specification's dynamic `listChanged` tool-discovery mechanism is itself flagged as a risk amplifier: because most MCP hosts auto-refresh the tool list at runtime, "if a remote MCP server adds a `delete_repository` tool in an update, agents automatically gain access without user awareness or approval" — a live server can silently escalate an already-approved connection's privilege surface after the fact. [mcp-blog-tool-annotations context, per secondary academic source in search — verify against SEP/blog primary text before treating as settled]

### (c) Mitigation patterns actually used in production servers

- **Read-only-by-default, write gated behind an explicit flag/header**: universal across every vendor surveyed — GitHub (`--read-only`), Supabase (`--read-only`), Neon (`X-Neon-Read-Only` / OAuth `read` scope), AWS IAM/API/S3-Tables MCP servers (`--readonly` / `READ_OPERATIONS_ONLY` / default-until-`--allow-write`), Sentry (stdio defaults to `DEFAULT_SCOPES` = read-only), Kubernetes MCP servers (`--read-write=true` opt-in). [github-mcp-server-config][supabase-mcp-docs][neon-mcp-repo][aws-iam-mcp-server][aws-s3-tables-mcp-server][sentry-mcp-deepwiki-authz][k8s-mcp-toolhive-guide]
- **Per-tool/toolset allowlisting**: GitHub's `--toolsets`/`--tools`/`--tools-exclude` (exclude wins); Supabase's `--features` groups; Neon's repeatable `category` param; Sentry's `grantedSkills`. [github-mcp-server-config][supabase-mcp-docs][neon-mcp-repo][sentry-mcp-deepwiki-authz]
- **Resource/account scoping (blast-radius limiting) separate from operation-type scoping**: Supabase `project_ref`, Neon `projectId`, Sentry org/project path constraints, Cloudflare account-token auto-detection — narrowing *which* resource can be touched is treated as a distinct control from *what kind* of operation is allowed. [supabase-mcp-docs][neon-mcp-repo][sentry-mcp-deepwiki-authz][cloudflare-mcp-repo]
- **Human-in-the-loop confirmation as a first-class spec primitive ("elicitation")**: added to the MCP spec in the 2025-06-18 revision; lets a server pause a `tools/call` mid-execution and request structured input/approval from the user via the client, with the client rendering a form/prompt from a JSON Schema and resuming on response. Documented production users of elicitation-based approval gates include Cloudflare, AWS ("HITL workflows directly on this mechanism") and Pinterest, which "mandates human-in-the-loop approval for all sensitive MCP operations in their production deployment." Architectural limit: the MCP server itself has no UI and cannot talk to the user directly — it can only request that the client (which does own the UI) collect the confirmation. [general secondary-source claim on elicitation adoption — treat vendor-adoption specifics as unverified pending a primary Cloudflare/AWS/Pinterest source]
- **Tool annotations as a machine-readable risk vocabulary, independent of and in addition to elicitation**: the MCP spec (added via PR #185, in the 2025-03-26 revision, still present in 2025-06-18) defines four optional per-tool annotation hints — `readOnlyHint` (tool does not modify its environment; default false), `destructiveHint` (tool may perform destructive/irreversible updates rather than additive ones; only meaningful when `readOnlyHint` is false; default true), `idempotentHint` (repeat calls with the same args have no additional effect; only meaningful when `readOnlyHint` is false; default false), and `openWorldHint` (tool reaches an open world of external entities, e.g. the internet/third-party APIs, vs. a closed domain). Unannotated tools default to the most pessimistic posture (assumed non-read-only, destructive, non-idempotent, open-world). [mcp-tools-2025-06-18][mcp-blog-tool-annotations]
- **The spec explicitly requires clients to distrust unverified annotations**: "For trust & safety and security, clients **MUST** consider tool annotations to be untrusted unless they come from trusted servers" — because "a malicious or buggy server could mark a destructive tool as `readOnlyHint: true`" to dodge a confirmation dialog. [mcp-tools-2025-06-18][mcp-blog-tool-annotations]
- **The spec's own normative user-interaction guidance for tools generally (not just annotated-destructive ones)**: "For trust & safety and security, there **SHOULD** always be a human in the loop with the ability to deny tool invocations," and applications "**SHOULD**... present confirmation prompts to the user for operations, to ensure a human is in the loop." Separately, in Security Considerations: servers **MUST** validate all tool inputs, implement proper access controls, rate-limit invocations, and sanitize outputs; clients **SHOULD** prompt for confirmation on sensitive operations, show tool inputs before calling, validate results before passing to the LLM, timeout calls, and log tool usage for audit. [mcp-tools-2025-06-18]
- **Session-scoped / non-widening tokens**: Sentry's explicit rule that a session refresh reuses the originally granted props and cannot silently acquire broader scope over time. [sentry-mcp-deepwiki-authz]
- **Separation of duties enforced at the platform/IAM layer, independent of the MCP server's own logic**: AWS's `aws:ViaAWSMCPService` condition key lets an org permit a human to mutate a resource directly while denying the identical mutating call specifically when it arrives via the MCP server — a belt-and-suspenders control that does not depend on the MCP server's own code being correct. [aws-mcp-ga-blog]
- **Audit logging as a named, separate control from access control**: Cloudflare's MCP governance portal logs every MCP request and tool execution; AWS surfaces MCP-originated calls separately in CloudWatch (`AWS-MCP` namespace) and captures them in CloudTrail alongside all other API calls. [cloudflare-agents-governance][aws-mcp-ga-blog]
- **Enforcement must live at the execution layer, not just the discovery/listing layer** — proven negatively by two independent CVE-class bugs: GitHub's streamable-HTTP `--read-only` bypass (write tools stayed listed and callable) and `mcp-server-kubernetes`'s CVE-2026-46519 (restriction env vars filtered `tools/list` but not `tools/call`, so any client could invoke a "hidden" tool directly). The lesson from both: a read-only/toolset filter that only touches what `tools/list` returns, without also gating `tools/call` for the same tool names, is not a security boundary — it is a UI convenience that a client can trivially bypass. [github-mcp-readonly-bypass-issue][k8s-mcp-cve-2026-46519]

### (d) The MCP authorization spec's own current stance

- The MCP specification's authorization track (2025-11-25 → 2026-07-28, unchanged in substance across that span per the existing `oauth-mcp-auth` corpus) is built on OAuth 2.1 + RFC 9728 Protected Resource Metadata + RFC 8414/OIDC discovery + RFC 8707 Resource Indicators, and separately mandates server-side audience validation — this is scope/audience plumbing, not privilege-tiering guidance per se. [existing corpus: oauth-mcp-auth/mcp-spec-mandates-rfc-8707-resource-parameter-and-server-side-audience-validation.md — cited for context, not re-derived here]
- The 2026-07-28 release's "authorization hardening" changes (RFC 9207 issuer validation, `application_type` client registration, issuer-bound client credentials, formal CIMD-over-DCR deprecation) address authorization-server/client trust and credential-confusion attacks; the fetched MCP blog post for this release did not itself discuss tool annotations, privilege tiering, or destructive-tool guidance — those live in the separate tools-spec and tool-annotations-blog tracks cited above, not the authorization-spec release notes. [mcp-blog-2026-07-28]
- Tool annotations remain a live, actively-evolving area of the spec: as of the tool-annotations blog post, "the community has filed five independent Specification Enhancement Proposals (SEPs) proposing new annotations, driven in part by a sharper collective understanding of where risk actually lives in agentic workflows" — i.e., the spec authors consider the current four-hint vocabulary incomplete, not finished. [mcp-blog-tool-annotations]

## SOURCES

**mcp-tools-2025-06-18**
URL: https://modelcontextprotocol.io/specification/2025-06-18/server/tools
Accessed: 2026-08-14
Quote: "For trust & safety and security, there SHOULD always be a human in the loop with the ability to deny tool invocations... clients MUST consider tool annotations to be untrusted unless they come from trusted servers."

**mcp-blog-tool-annotations**
URL: https://blog.modelcontextprotocol.io/posts/2026-03-16-tool-annotations/
Accessed: 2026-08-14

**mcp-blog-2026-07-28**
URL: https://blog.modelcontextprotocol.io/posts/2026-07-28/
Accessed: 2026-08-14

**github-mcp-repo**
URL: https://github.com/github/github-mcp-server
Accessed: 2026-08-14

**github-mcp-server-config**
URL: https://github.com/github/github-mcp-server/blob/main/docs/server-configuration.md
Accessed: 2026-08-14

**github-mcp-server-readonly-bypass-issue**
URL: https://github.com/github/github-mcp-server/issues/2156
Accessed: 2026-08-14

**stripe-restricted-keys**
URL: https://docs.stripe.com/keys/restricted-api-keys
Accessed: 2026-08-14

**stripe-ai-discussion-216**
URL: https://github.com/stripe/ai/discussions/216
Accessed: 2026-08-14

**cloudflare-mcp-repo**
URL: https://github.com/cloudflare/mcp
Accessed: 2026-08-14

**cloudflare-agents-governance**
URL: https://developers.cloudflare.com/agents/model-context-protocol/governance/
Accessed: 2026-08-14

**cloudflare-agents-authz**
URL: https://developers.cloudflare.com/agents/model-context-protocol/authorization/
Accessed: 2026-08-14

**supabase-mcp-docs**
URL: https://supabase.com/docs/guides/ai-tools/mcp
Accessed: 2026-08-14

**neon-mcp-repo**
URL: https://github.com/neondatabase/mcp-server-neon
Accessed: 2026-08-14

**neon-mcp-docs**
URL: https://neon.com/docs/ai/neon-mcp-server
Accessed: 2026-08-14

**aws-iam-mcp-server**
URL: https://awslabs.github.io/mcp/servers/iam-mcp-server
Accessed: 2026-08-14

**aws-api-mcp-server**
URL: https://awslabs.github.io/mcp/servers/aws-api-mcp-server
Accessed: 2026-08-14

**aws-s3-tables-mcp-server**
URL: https://awslabs.github.io/mcp/servers/s3-tables-mcp-server
Accessed: 2026-08-14

**aws-mcp-ga-blog**
URL: https://aws.amazon.com/blogs/aws/the-aws-mcp-server-is-now-generally-available/
Accessed: 2026-08-14

**sentry-mcp-deepwiki-authz**
URL: https://deepwiki.com/getsentry/sentry-mcp/2.2-authentication-and-authorization
Accessed: 2026-08-14
Note: DeepWiki is an AI-generated wiki over the getsentry/sentry-mcp repo, not primary-source Sentry documentation — treat specifics (scope names, "skills" migration details) as plausible-but-unverified pending direct confirmation against the repo source.

**k8s-mcp-toolhive-guide**
URL: https://docs.stacklok.com/toolhive/guides-mcp/k8s
Accessed: 2026-08-14

**k8s-mcp-redhat**
URL: https://developers.redhat.com/articles/2025/09/25/kubernetes-mcp-server-ai-powered-cluster-management
Accessed: 2026-08-14

**k8s-mcp-cve-2026-46519**
URL: https://www.manifold.security/blog/mcp-server-kubernetes-readonly-bypass
Accessed: 2026-08-14

**willison-supabase-trifecta**
URL: https://simonwillison.net/2025/Jul/6/supabase-mcp-lethal-trifecta/
Accessed: 2026-08-14

**willison-lethal-trifecta-newsletter**
URL: https://simonw.substack.com/p/the-lethal-trifecta-for-ai-agents
Accessed: 2026-08-14

**invariant-github-mcp**
URL: https://invariantlabs.ai/blog/mcp-github-vulnerability
Accessed: 2026-08-14

**dev-api-to-mcp-destructive-survey**
URL: https://dev.to/levitc/i-converted-10-popular-apis-to-mcp-tools-7-would-let-an-agent-delete-your-data-with-zero-kp6
Accessed: 2026-08-14
Note: independent blogger's survey, not a vendor primary source — cited as illustrative, not authoritative.

## SYNTHESIS

The evidence says an owner/admin-persona MCP server is not an outlier design — it is what every major official MCP server that touches privileged operations already is. GitHub, Stripe, Cloudflare, Supabase, Neon, AWS (three separate official servers), Sentry, and multiple Kubernetes MCP servers all expose write/admin capability, and every single one converges independently on the same three-layer shape: **default read-only**, **explicit opt-in for write/admin** (a flag, header, or OAuth scope — never ambient), and **resource-scoping orthogonal to operation-type scoping** (which project/account/repo, separate from which verbs). None of them concluded "don't expose admin operations through MCP" — that option was evidently on the table and rejected by the entire ecosystem in favor of tiered exposure. This directly answers the PDPP framing: refusing owner tokens outright is *more* conservative than the mainstream pattern, not merely "the safe choice" — it's stricter than GitHub, AWS, and Cloudflare are willing to be with operations of comparable or higher blast radius (repo admin, IAM writes, account-level config).

The documented attacks (Invariant Labs/GitHub, Willison/Supabase) are not arguments against admin-capable MCP servers per se — both incidents involved *read* access to private data combined with exposure to untrusted content and an exfiltration channel (the "lethal trifecta"), not owner-privilege *write* operations being invoked. The GitHub exploit's own data is instructive: the broad-scope token and the narrow "public-repos-only" token both let the agent *read* private repos, but only the broad token let it *write* the exfiltrated data back to a public location. Write-scoping, not read-scoping, was the actual chokepoint. This matters for PDPP: an owner-persona MCP server whose write tools are gated (confirmation, destructiveHint, narrow scope) but whose read tools are broad is not obviously safer than one with narrow read and broad write — the trifecta requires only that *some* combination of read-private + untrusted-content-exposure + exfil-channel exist, and PDPP's context (an agent that also browses the web, drafts emails, etc. on the owner's behalf) plausibly has that combination regardless of whether the "owner" persona is admitted at the MCP layer or bypassed via CLI.

That last point is the crux of the actual PDPP decision: **CLI-with-owner-key does not remove the risk the prior agent was defending against — it removes every mitigation the MCP layer would otherwise provide.** A CLI given an owner key has no per-tool annotation vocabulary, no elicitation/confirmation primitive, no host-enforced allowlist, no tool-level audit trail structure, and no way for the MCP client (Claude Code, etc.) to distinguish "the agent is about to read something" from "the agent is about to irreversibly delete/export/grant something" — every command looks the same to the host. An MCP surface, even an imperfect one, gives the host something to hook: it can refuse to auto-approve `destructiveHint: true` tools, it can show the user the exact structured arguments before calling, it can log structured tool-call records instead of opaque shell history, and it can revoke access to specific *operations* instead of all-or-nothing key revocation. The GitHub read-only bypass and the Kubernetes CVE both show that MCP-layer gating can itself be buggy — but a buggy gate that fails closed to "the same risk as the CLI already has" is not worse than the CLI, and a fixed gate is strictly better.

**Recommended architecture for a PDPP owner-persona MCP surface**, following the pattern density above:

1. **Default read-only.** The server should ship with read-only as the out-of-the-box posture (Supabase/AWS/Kubernetes convention), requiring an explicit flag, env var, or scope grant (`--allow-owner-write`, or an OAuth `write`/`admin` scope analogous to Neon's `read`/`write`/`*`) to unlock owner-level mutation. This mirrors what every surveyed vendor does and gives PDPP a legitimate "secure by default" claim even with owner tools present in the codebase.
2. **Tier tools with MCP's own annotation vocabulary, not a custom taxonomy.** Mark every owner tool with `readOnlyHint`/`destructiveHint`/`idempotentHint`/`openWorldHint` per the spec's actual fields, so any MCP-aware host (Claude Code, Codex, etc.) that already implements annotation-based confirmation gets PDPP's owner tools gated for free, without PDPP inventing its own risk vocabulary. Since annotations are spec-defined as untrusted-unless-trusted-server, and PDPP's mcp-server is presumably a trusted first-party server for its own owner, this is exactly the case the spec designed the trust distinction for.
3. **Gate destructive/high-blast-radius owner operations behind elicitation**, not just a static confirmation flag. Use the spec's elicitation primitive (2025-06-18+) for operations like data export, grant revocation for other users, or irreversible deletes — pause the call, have the client render the specific action for the owner to approve, resume only on explicit confirmation. This is the same pattern Pinterest and (per secondary sourcing, unverified) Cloudflare/AWS apply to sensitive operations.
4. **Scope by resource, independent of scope by operation.** If PDPP's owner has multiple "projects"/data domains, add a Supabase/Neon-style resource-scoping parameter (equivalent to `project_ref`/`projectId`) so a given MCP session can be pinned to a narrower blast radius than "everything the owner token can touch," even when write access is granted.
5. **Enforce at the call layer, not just the list layer.** Both real-world CVEs surveyed here (GitHub, `mcp-server-kubernetes`) failed by filtering `tools/list` but not `tools/call`. PDPP's implementation must re-check the same read-only/scope/annotation gate inside the handler for every tool invocation, not only when deciding what to advertise.
6. **Session-scoped, non-widening grants**, per Sentry's rule — an owner-persona MCP session should not be able to silently acquire broader scope than what it was granted at connection time, even across token refresh.
7. **Structured audit logging of every owner-tool call**, separate from general request logs — this is the concrete advantage over the CLI-with-owner-key status quo, and every vendor surveyed treats it as a distinct, named control (Cloudflare's governance portal, AWS's CloudWatch/CloudTrail separation).
8. **Treat the lethal trifecta as the actual threat model, not "is this an owner token."** Because PDPP's agent plausibly reads owner data, is exposed to untrusted external content (web pages, third-party connector data), and has outbound channels, the owner-persona decision should be paired with a review of what untrusted content the agent ingests in the same session as owner-tool access — narrowing *that* exposure (e.g., not fetching untrusted web content and calling owner-write tools in the same agent turn) closes more real risk than blocking the owner persona at the MCP layer would.

One item flagged unverified above: the specific claim that Cloudflare/AWS/Pinterest have production elicitation-based HITL gates came from a secondary aggregator source, not a primary Cloudflare/AWS/Pinterest doc — worth a direct confirmation pass if this synthesis is used to justify a specific implementation choice. The NSA/CISA joint MCP security advisory (media.defense.gov, June 2026) surfaced in search but returned HTTP 403 on fetch and could not be reviewed for this entry; if government-grade MCP security guidance is wanted, that PDF should be sourced through an alternate channel (it is a primary source with likely-relevant guidance on exactly this question, given its title "CSI_MCP_SECURITY").
