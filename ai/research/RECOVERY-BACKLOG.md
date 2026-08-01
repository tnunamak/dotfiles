# Research recovery backlog

Findings surfaced by a full-census audit (2026-08-01) of Claude + Codex sessions that
did web research but never captured it to the corpus (the false-negative gap, now fixed
at the detector: playwright false-positives removed, Codex `web_search_call` detection
added via a Stop hook).

A stronger judge (Gemini, single-pass) classified each research session KEEP / SKIP /
UNCERTAIN against the corpus worthiness bar (see README). This is the KEEP set: research
worth turning into a corpus entry. **These are leads, not entries** — the one-line finding
+ session id is enough to recover the full research on demand (`convo show <id>`, or the
Codex rollout) without re-searching.

Method + honest caveats:
- ~262 of 555 research sessions received verdicts; the single judge silently dropped
  chunks on very large inputs (caught + reconciled), so this KEEP set is a strong sample,
  not an exhaustive census. Recovering these first captures the highest-confidence leads.
- KEEP rate landed at ~23% (95% CI ±5%), consistent across Claude and Codex.
- To recover one: `convo show <session-id>` (Claude) or open the matching
  `~/.codex/sessions/**/rollout-*<id>.jsonl` (Codex), then write an entry per README.

## KEEP findings (session-id · finding · suggested topic)

- `5659502b-5590-4cd7-b23f-c0410a7fa158` — comprehensive prior-art sweep of industry permission and consent UX models _(topic: consent and permission UX across major platforms)_
- `499aa4a0-e6b0-4d93-8cbd-f9e2701ad14e` — systematic evaluation of status banners and feature deprecation UX across leading fintechs _(topic: fintech UX patterns for service unavailability and deprecation)_
- `5d683de2-441e-472a-8a74-a7fa144acda1` — establishes concrete best practices and pitfalls for PostHog integration in Next.js App Router _(topic: PostHog configuration for Next.js App Router)_
- `1116bd10-e2c9-4ffd-9eec-822b4bd889b5` — identifies a transferable trap where Sentry's httpClientIntegration turns expected 400 validation responses into noisy alerts _(topic: Sentry httpClientIntegration noise reduction for 4xx errors)_
- `fc7c7495-298c-4c1b-917c-6001a7db5ca9` — practical analysis of Cloud Run concurrency and timeout limits causing a backlog and crashes in a document processing pipeline _(topic: Cloud Run concurrency, timeouts, and scaling limits for long-running jobs)_
- `004f6a10-7f83-4927-9243-84193601256c` — transferable finding on how Cloud Run cold starts plus heavy processing can easily breach Vercel's 60-second serverless timeout _(topic: Vercel serverless timeouts interacting with Cloud Run cold starts)_
- `1017cb1c-5d9a-4677-ab34-162c6e621961` — reusable pattern for structuring an .aiignore file to reduce context pollution in a Next.js/Prisma project _(topic: .aiignore best practices for Next.js and Prisma projects)_
- `ca04b082-613c-478a-b6db-7af007250c63` — excellent synthesis of enterprise auto-refresh UX patterns from leading fintech dashboards _(topic: admin dashboard auto-refresh and stale-while-revalidate UX patterns)_
- `5ff0b639-1c64-4ee4-998f-ed8293a9f19f` — documents the exact package and configuration flags needed to securely upload sourcemaps to PostHog in Next.js _(topic: PostHog sourcemap upload configuration for Next.js)_
- `4930ab02-a641-4663-ada3-d559c6b28b51` — strong synthesis of data quality warning UX and confidence thresholding from Stripe Radar and industry patterns _(topic: UX patterns for data quality warnings and ML confidence thresholds)_
- `a5de489c-ab2f-4cce-92af-32c5fa9445ea` — transferable architectural analysis of database foreign key strategies for handling GDPR user deletion vs accounting retention _(topic: database constraint design for GDPR deletion vs audit retention)_
- `36e5546f-9787-47a3-913f-e02a289dbec5` — documents the specific URL parameters required to integrate external surveys with MTurk and CloudResearch _(topic: MTurk and CloudResearch external survey integration parameters)_
- `d5a9e101-be6d-4c51-a305-fecaf9973064` — establishes a clean pattern for preserving and restoring URL-based filter and pagination state in Next.js App Router _(topic: persistent list state navigation patterns in Next.js App Router)_
- `e59a2426-8c19-4088-afa4-98d4d248cb75` — identifies a specific PyMuPDF failure mode where text extraction returns corrupted bounding boxes spanning multiple lines for certain fonts _(topic: PyMuPDF bounding box extraction failure modes)_
- `f10bf0a8-fe1d-40be-b742-01752cbe4950` — identifies a common NextAuth middleware trap where the PWA manifest is accidentally protected and causes noisy sign-in redirects _(topic: NextAuth middleware configuration for PWA manifests)_
- `7792f77b-2e04-46c9-ad0f-60c2de4da92a` — excellent synthesis of guest checkout and anonymous submission UX patterns from leading ecommerce and whistleblowing platforms _(topic: anonymous-first submission and guest checkout UX patterns)_
- `70ca0f58-ff90-4d98-a44f-c98cdb7cb624` — clear synthesis of selection removal UX patterns across professional editing tools _(topic: UX patterns for selection subtraction and removal in web editors)_
- `6326459a-1921-4cb6-9a51-d594e74795c5` — documents a critical RCE vulnerability in React 19 Server Components and the required version bump _(topic: CVE-2025-55182 React Server Components RCE vulnerability)_
- `8f05b83d-7eee-4408-a821-ed2a523c9ec0` — actionable architectural design for a referral system handling first-touch attribution and Safari ITP constraints _(topic: referral program attribution architecture and tracking)_
- `11647469-2457-4936-9f30-c3369321f172` — documents the exact domain and MX record architecture needed to separate SendGrid inbound parse from outbound transactional email _(topic: SendGrid inbound parse domain architecture and MX record separation)_
- `28533cbf-817d-4206-8591-6e8cb4ce12f2` — identifies a specific bug in sentry-cli 2.58.2 where the config file token is ignored, requiring environment variable fallback _(topic: sentry-cli 2.58.2 token authentication bug)_
- `34a6509d-de62-418c-b582-930fb367f5f0` — excellent synthesis of mobile dashboard UX patterns including collapsible navigation and card-over-table lists _(topic: mobile-first admin dashboard UX patterns)_
- `663ac836-27a7-4600-9f05-84d39c94ed80` — strong synthesis of industry UX messaging patterns for automated document redaction and verification _(topic: UX messaging patterns for automated document verification and human-in-the-loop review)_
- `08538e73-880b-49fc-a280-eb527063c236` — identifies a specific Vercel serverless deployment trap where node_modules/.bin symlinks are not preserved, breaking child_process spawning _(topic: Vercel serverless symlink limitations and child_process binary execution)_
- `7ed80c12-b4d9-45af-ae10-290f11893009` — documents a critical DNS rebinding/TOCTOU vulnerability in Node.js fetch() and the exact undici dispatcher configuration needed to pin the validated IP _(topic: preventing DNS rebinding/SSRF in Node.js fetch using undici connect.lookup overrides)_
- `bf94d142-2725-4d0f-a17b-ce8aaf45280c` — synthesizes the current fragmented state of AI assistant ignore files (.aiignore vs .aiexclude) and Claude Code's compliance bugs _(topic: .aiignore standard adoption and tool compatibility)_
- `795769cb-dbc2-440e-889d-f6fa5c8acb54` — provides concrete configuration fixes for BlueZ and Plasma Bluetooth auto-reconnect and boot initialization failures _(topic: BlueZ and KDE Plasma Bluetooth auto-reconnect configuration)_
- `4d370bac-8275-4ed3-a86f-a0dbae2504f4` — clear explanation of Ethereum gas mechanics distinguishing algorithmic base fee increases from relayer tip bidding wars _(topic: Ethereum EIP-1559 gas mechanics and base fee vs priority fee)_
- `9eed81df-f4b6-4734-ae3b-0ad812d8ed84` — identifies a specific failure mode where raw model control tokens in session history trigger invalid_prompt blocks from the OpenAI Responses API _(topic: OpenAI Responses API invalid_prompt blocks from model control tokens)_
- `8826c923-e6c7-4707-aceb-3f594c503661` — root cause analysis of a specific Kernel Oops related to NVIDIA driver 590.48.01 and cuda-EvtHandlr memory corruption _(topic: NVIDIA driver 590.48.01 cuda-EvtHandlr kernel memory corruption)_
- `09682362-1d47-41da-a3a3-a83e739b8760` — clarifies the distinction between Claude Code's built-in Task tools and the token-intensive Agent Teams parallel execution feature _(topic: Claude Code Agent Teams and Task tool architecture)_
- `42569d54-d339-4dac-a5d0-9fe01269743e` — documents a specific hardware failure mode where SK hynix P41 NVMe PCIe AER errors cascade into LVM dm-thin metadata loss and Proxmox cluster quorum failure _(topic: SK hynix P41 NVMe PCIe errors causing Proxmox dm-thin metadata and cluster failure)_
- `f7ee6afd-af1b-412d-8865-e4d54658ef3f` — identifies a specific Wayland/KWin DRM ownership conflict caused by Sunshine display switching _(topic: Sunshine Wayland DRM permission denied conflict with KWin atomic modesetting)_
- `acba62ca-6785-4af3-b525-6b50410638bd` — strong synthesis of B2B SaaS user invitation architecture and database schema best practices _(topic: B2B SaaS user invitation system database schema and lifecycle)_
- `450661b8-e4b3-4998-b994-9086b2b56707` — actionable analysis of a specific Shai-Hulud 2.0 npm supply chain attack variant using fetchRemoteJS and decodeHost _(topic: Shai-Hulud 2.0 npm supply chain attack variant analysis)_
- `890c0717-c432-40b5-ad0c-205395d2e3dd` — documents ElizaOS internal architecture for fact evaluators and cross-platform memory persistence _(topic: ElizaOS fact evaluator and memory management architecture)_
- `181a53b3-3588-431a-a4c5-88f7ca41de1f` — architectural planning for combining Presidio rule-based PII detection with LLM validation _(topic: hybrid PII detection architecture using Presidio and LLMs)_
- `796903d1-9df5-42ad-b677-5232f0764ad9` — documents the migration pain points between Tailwind v3 and v4 alpha syntax in PostCSS _(topic: Tailwind CSS v4 alpha PostCSS configuration syntax)_
- `d49b64f2-2863-4e43-a5b8-94d13a0edba0` — confirms industry standard patterns for iframe widget lifecycle management and postMessage isolation _(topic: iframe widget lifecycle control via postMessage)_
- `765899e1-9b54-45c8-b579-a17df4830bdd` — documents the exact URL parameters used by Prolific for tracking survey participants _(topic: Prolific participant tracking URL parameters)_
- `25e117df-de62-49ac-aa98-9607acb3a709` — provides a highly structured Midjourney/DALL-E prompt recipe for generating minimalist tech logos in the style of Massimo Vignelli _(topic: prompt engineering for minimalist corporate identity and logo design)_
- `1fe92e40-f585-49e1-9fb7-cc88341d86e1` — highlights a common EIP-1967 proxy verification trap where block explorers show roles on the proxy that aren't visible in the implementation ABI _(topic: EIP-1967 proxy contract ABI verification and role discovery)_
- `b11c356b-dc10-4c04-96cd-f8cd3c923b83` — maps the internal session log JSONL schemas for Claude Code, Codex, and Gemini CLI _(topic: internal session log formats for Claude Code, Codex, and Gemini CLI)_
- `a0d6315b-b4fc-43da-b879-8a531bd379fb` — systematic analysis of information architecture, typography, and governance signaling across major standards body websites (W3C, IETF, OpenAPI) _(topic: information architecture and design language of standards body websites)_
- `99588635-e57d-4926-9b3f-6d365496afce` — identifies a common web3.py/solidity integration trap where bytes parameters hash differently if passed as hex strings versus raw bytes _(topic: web3.py bytes vs hex string parameter encoding in keccak256 mapping keys)_
- `ea694826-852c-4874-b335-ab37d44409c9` — actionable architectural assessment of running heavy repository-packing CLI tools within Vercel serverless constraints _(topic: running repository packing tools in Vercel serverless environments)_
- `b168b9d9-fc4c-48aa-84a3-4a7a121838df` — identifies a highly specific GitHub Actions trap where setup-node's generated .npmrc requires NODE_AUTH_TOKEN, breaking semantic-release if only NPM_TOKEN is provided _(topic: semantic-release and setup-node NPM registry authentication conflicts)_
- `50db73ee-f201-4d1a-9677-d2d5640deeb9` — explains how Repomix's runCli falls back to git clone, and why runRemoteAction is required in serverless environments to use the GitHub archive API instead _(topic: executing Repomix remote repository packing in serverless environments)_
- `63713c72-59d3-46fc-8e7a-75d63c656d5a` — identifies a specific Phala Cloud API constraint where immutable visibility settings like public_logs cause 422 errors if included in VM update payloads _(topic: Phala Cloud CVM API visibility settings update constraints)_
- `7e4ac91d-0c52-4e21-a1f3-635e4dee7abf` — documents specific breaking syntax changes in the Axum 0.8.x routing API _(topic: Axum 0.8.x breaking changes in path parameter syntax)_
- `e53ddef6-d105-4e61-8204-be92425dbdc3` — identifies a breaking change in Phala Cloud OS image >= 0.5.0 requiring the allowed_envs field for environment variables _(topic: Phala Cloud API breaking changes for allowed_envs in OS images >= 0.5.0)_
- `e890a15f-b532-4867-b760-5af0330e2c3f` — documents the exact API response and address derivation scheme for Phala PGE threshold encryption services _(topic: Phala PGE public key API and address derivation)_
- `9c0d7b88-cf94-43ca-b62b-9da1a6e89b8a` — documents how React Doctor's server-auth-actions rules create false positives in architectures using token-based auth instead of Next.js auth() _(topic: React Doctor server-auth-actions rule false positives)_
- `adc05a9e-a747-4eea-a6c5-ac8954657dd1` — clear architectural guidance on mapping Doppler config projects to Vercel environments 1:1 for security isolation _(topic: Doppler and Vercel environment mapping architecture)_
- `97a165fd-70e2-48b0-adbc-ecec3c1c466a` — identifies a severe architectural flaw where a backend API attempts to programmatically drive an OAuth device approval flow that requires human CSRF interactions _(topic: OAuth device flow CSRF protection and backend automation anti-patterns)_
- `ca606b59-fdc2-49c2-93b5-69793f1bc9df` — identifies a specific Playwright configuration failure where channel: "chrome" requires a host installation of Google Chrome rather than relying on bundled Chromium _(topic: Playwright launchPersistentContext channel: "chrome" host requirements)_
- `549e8050-7d74-4b23-acde-c5391cd78b3e` — documents the specific, non-standard Multicall3 contract address and deployment blocks for the Vana Mainnet and Moksha testnet _(topic: Vana Mainnet and Moksha testnet Multicall3 contract addresses)_
- `1372d6d1-f1b0-4872-820e-5239eb5d7bd3` — strong architectural synthesis distinguishing request-level rate limiting from scheduler-level continuation across major distributed systems _(topic: architectural separation of request-level rate limiting from scheduler continuation)_
- `7f803ae6-41e5-4720-9cab-eef00be3406b` — clearly explains the security distinction between EDGE_CONFIG and NEXT_PUBLIC_EDGE_CONFIG for Vercel Edge Config connection strings _(topic: securing Vercel Edge Config connection strings in Next.js)_
- `9f6be941-43d9-4026-8584-6c585f17b20f` — resolves a common Radix UI accessibility warning by identifying the missing required DialogDescription or aria-describedby properties _(topic: fixing Radix UI DialogContent missing description accessibility warnings)_
- `e32de816-b271-436e-8653-65646146706d` — documents a clean, reversible pattern for forcing a specific theme in next-themes using forcedTheme _(topic: forcing light/dark mode overrides in next-themes)_
- `7d336d7b-ab12-4089-aec3-856228e75dd8` — identifies a critical GitHub Actions syntax trap where command substitution like $(cat file) is not evaluated inside action inputs _(topic: GitHub Actions input string interpolation and shell substitution limitations)_
- `e7a400b0-b709-4bfb-84bd-a8d7f15cbdc5` — detailed methodological takedown of a token-saving benchmark, exposing how provider cache warmup skews sequential run results _(topic: LLM API cache warmup confounds in token reduction benchmarking)_
- `25a08f6d-44f6-4321-83cb-a13fc902cac7` — documents the exact credential isolation and host-side keychain injection mechanics for Docker Sandboxes (sbx) _(topic: Docker Sandboxes (sbx) credential isolation and host-side OAuth token injection)_
- `8f0ec176-5e10-4bd7-bcb4-b0d450c615e3` — synthesizes UX research to recommend an interactive comparison slider over side-by-side views for document redaction verification _(topic: UX patterns for document redaction verification and image comparison)_
- `c23135d0-5af1-45c0-962d-1f0242e51abf` — actionable architectural recommendation for integrating Patchright browser automation running on a host with a Dockerized Playwright client _(topic: architecting Patchright host browser automation for Dockerized Playwright clients)_
- `4d31e545-1f1f-4ac4-a937-5c9e135caf36` — actionable architectural design for an internal testnet funding service that avoids the abuse vectors of public faucets _(topic: architecture for OIDC-attested internal testnet funding services)_
- `01acf076-b9a6-4305-9d47-1960b1f7b5db` — identifies that GitHub Actions cross-platform matrix builds (macOS 10x, Windows 2x multipliers) are the primary cost drivers for Tauri release workflows _(topic: GitHub Actions billing multipliers for cross-platform Tauri builds)_
- `6dd78cd1-8fbe-4f85-ae91-9805d56c67de` — excellent architectural breakdown of the security, custody, and migration tradeoffs between server-side key generation and Privy's TEE embedded wallets _(topic: architecture tradeoffs for server-side custodial wallets vs Privy embedded wallets)_
- `rollout-2026-06-29T08-46-07-019f13a1-50c7-7bc1-a19b-13744ea116e5` — compares API error structures and pagination patterns in Stripe and Plaid _(topic: Stripe and Plaid API design patterns)_
- `rollout-2026-06-29T08-46-09-019f13a1-5a84-7523-b4b2-1cf4e56db9ce` — investigates OAuth DCR and PAR standards for dynamic client registration _(topic: OAuth 2.0 Dynamic Client Registration and Pushed Authorization Requests)_
- `rollout-2026-06-22T09-03-26-019eefa4-aaa5-7b41-ad9a-adf6ac701bcf` — compares discovery and fetch patterns across open-source MCP filesystem servers _(topic: MCP filesystem server capabilities)_
- `rollout-2026-06-22T09-03-30-019eefa4-ba4d-76b3-84d3-66faa03026b8` — summarizes standard semantics for MCP structuredContent and resource linking _(topic: Model Context Protocol resource and tool semantics)_
- `rollout-2026-06-22T09-03-23-019eefa4-9b8c-7f90-a314-be22cf779942` — evaluates client-by-client compatibility and divergence for MCP structuredContent and resources _(topic: MCP client compatibility for structuredContent)_
- `rollout-2026-06-11T11-26-36-019eb781-c79e-72c2-98fc-2a99e486c95d` — evaluates and compares RTK and SEMMAP for AI agent token savings and setup _(topic: AI coding agent token optimization tools)_
- `rollout-2026-06-11T20-20-42-019eb96a-c4b3-74a2-9365-1c5e3532be29` — summarizes prior art and specifications for headless OAuth and device code flows in MCP _(topic: MCP headless OAuth prior art)_
- `rollout-2026-06-11T11-26-42-019eb781-dec7-7801-9af1-177d1e8ef264` — compares Repomix and Gitingest features for token reduction and compression _(topic: AI repository compression tools)_
- `rollout-2026-06-11T11-26-28-019eb781-a781-78f2-83a5-478207dbe3b5` — evaluates Headroom and Context-Mode for AI agent context compression and hooks _(topic: AI context compression tools)_
- `rollout-2026-06-12T20-33-20-019ebe9c-b13a-7f33-b7d1-7c6d569360f7` — evaluates prior art for WhatsApp data extraction tools and libraries _(topic: WhatsApp data extraction libraries)_
- `rollout-2026-06-13T11-37-10-019ec1d8-2c81-7a32-8152-da934338174f` — sweeps community sentiment and feature requests for AI coding agent token usage visibility _(topic: AI coding agent token visibility UX)_
- `rollout-2026-06-13T11-37-04-019ec1d8-169d-7053-b97a-3af8fae73ccd` — evaluates status line and hook event patterns across Claude Code and Codex CLIs _(topic: AI agent CLI status line patterns)_
- `rollout-2026-06-13T11-36-59-019ec1d8-002b-7f12-a112-6b35f8772bec` — evaluates prior art for terminal-native AI API usage meters and status lines _(topic: terminal AI usage meters)_
- `rollout-2026-06-15T15-54-53-019ecd10-d744-7400-812d-4548efb0fa13` — sweeps product patterns for cloud budget forecasting and quota alerts _(topic: cloud budget and quota alert UX)_
- `rollout-2026-06-15T15-54-54-019ecd10-d9b3-7912-a0b0-9d4184846e91` — sweeps product patterns for SaaS billing quota projections and forecast warnings _(topic: SaaS billing quota and forecast UX)_
- `rollout-2026-06-01T11-02-46-019e83ec-5e06-75d1-8dce-6059046f2d80` — sweeps UX patterns for desktop app download pages and release notes _(topic: desktop app download page UX)_
- `rollout-2026-06-05T21-39-15-019e9acc-8424-7241-aa92-3ef171f95459` — documents Railway's GraphQL API for programmatic environment and service source updates _(topic: Railway GraphQL API capabilities)_
- `rollout-2026-06-05T17-49-59-019e99fa-a0b5-7090-a6c6-5bc28f361db7` — details the Railway template creation workflow and Dockerfile target config limitations _(topic: Railway template publishing limitations)_
- `rollout-2026-06-25T23-26-28-019f022d-dd05-7732-98a6-5fedacf7f7da` — evaluates semantic-release interaction with GitHub auto-merge and merge queues _(topic: GitHub Actions semantic-release and auto-merge)_
- `rollout-2026-06-08T11-27-19-019ea80f-5d59-7e22-94f2-cbc2800039ff` — clarifies JSON Schema anyOf/oneOf support in MCP tool input schemas based on official specs _(topic: MCP tool inputSchema union support)_
- `rollout-2026-06-08T10-47-46-019ea7eb-26fa-7b12-b465-158759bf89c3` — identifies a mismatch between MCP server resource metadata and Claude connector exact-resource checking _(topic: MCP server protected resource metadata matching)_
- `rollout-2026-06-08T12-54-33-019ea85f-3ad8-7853-be3e-baf0da23dedf` — summarizes MCP authorization draft semantics for DCR and Client ID Metadata Documents _(topic: MCP Dynamic Client Registration and CIMD priorities)_
