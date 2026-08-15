---
title: "No major connector ecosystem verifies that a community connector actually works — registries verify identity (MCP OIDC namespaces) or artifact provenance (ToolHive), while functional evidence exists only in nascent forms (browser-harness execution-derived skill files, Stagehand observe→cache→replay), leaving captured-trace replay certification as unclaimed white space"
date: 2026-08-13
topic: connectors
tags: [connector-verification, mcp-registry, airbyte-declarative, browser-agents, evidence-carrying-contributions, trust-models]
status: draft
sources: [mcp-registry, airbyte-lowcode, airbyte-custom-components, dlt-contracts, nango, browser-harness, stagehand, anthropic-agent-tools-vana]
source_session: 1f934c1f-19c7-4d9d-9b1d-52f5e457e91e
---

## CLAIMS
- The official MCP Registry verifies publisher identity only (reverse-DNS namespaces tied to GitHub OIDC proof-of-publish); it explicitly punts behavior/security scanning to package registries and downstream directories, and no downstream directory (Smithery, Glama, PulseMCP) runs functional test suites against live services for community MCP servers. [mcp-registry]
- ToolHive is the one registry-adjacent exception found, and it verifies supply-chain integrity (image signature + build provenance), not live function. [mcp-registry]
- Airbyte's manifest-only declarative connectors run on a shared `source-declarative-manifest` base image with no per-connector container build; validation is JSON-schema + interactive live "Testing Values" reads, with no CAT-equivalent record-diff regression gate specific to low-code manifests. [airbyte-lowcode]
- Airbyte's declarative escape hatch (Custom Components, Python `class_name` overrides) is officially labeled "UNSAFE and EXPERIMENTAL" with "no sandboxing guarantees" and is disabled by default; declaration/runtime version skew is a live failure mode (builder emits manifests newer than installed CDK, GitHub issue #45398). [airbyte-custom-components]
- dlt's REST API source is a fully declarative dict config with an OpenAPI-to-config generator; its schema contracts (`tables`/`columns`/`data_types` × `evolve`/`freeze`/`discard_rows`/`discard_columns`) are per-scope, but dlt has no marketplace verification layer — trust model is "read the Python." [dlt-contracts]
- Nango's trust substitution: instead of vetting each of 700–900+ per-provider TypeScript templates, it open-sources the runtime and credential store itself so the shared execution substrate is auditable. [nango]
- browser-harness (browser-use org) has agents write execution-derived "skill files" documenting selectors/flows discovered at runtime — the closest existing precedent for evidence-carrying connector contributions (artifact generated from real runs rather than hand-authored). [browser-harness]
- Stagehand's `observe` returns candidate actions with selectors without executing; caching these and replaying via `act` gives deterministic selector replay with LLM re-observation only on breakage — a concrete self-healing pattern with a natural captured-trace certification hook. [stagehand]
- Skyvern rejects selectors entirely (multi-agent DOM reasoning per run), trading determinism and cost for layout resilience; Anon records no-code browser flows but deliberately targets only enterprise SLA workflows, rejecting consumer-grade reliability bets. [browser-harness]
- Vana's own `vana-com/data-connectors` (Playwright script + JSON metadata + JSON-Schema output contract) already ships an `errors[]` disposition distinguishing degraded from omitted data under selector drift, plus fixture-based validation and a Stable/Beta/Experimental maturity label in metadata. [anthropic-agent-tools-vana]

## SOURCES
**mcp-registry**
URL: https://modelcontextprotocol.io/registry/about
Accessed: 2026-08-13
Quote: "reverse-DNS namespaces tied to GitHub OIDC proof-of-publish — equivalent to 'by Apple Inc.' labeling, not a functionality check" (agent paraphrase of registry docs; registry verifies identity, not function)

**airbyte-lowcode**
URL: https://docs.airbyte.com/platform/connector-development/config-based/low-code-cdk-overview
Accessed: 2026-08-13
Quote: "Manifest-only connectors run on a shared source-declarative-manifest base image — no per-connector container build" (agent summary of docs)

**airbyte-custom-components**
URL: https://docs.airbyte.com/platform/connector-development/connector-builder-ui/custom-components
Accessed: 2026-08-13
Quote: "UNSAFE and EXPERIMENTAL... no sandboxing guarantees... could execute arbitrary code"

**dlt-contracts**
URL: https://dlthub.com/docs/general-usage/schema-contracts
Accessed: 2026-08-13
Quote: "schema_contract param scoped independently to tables/columns/data_types, each with mode evolve/freeze/discard_rows/discard_columns" (agent summary)

**nango**
URL: https://github.com/NangoHQ/nango
Accessed: 2026-08-13
Quote: "unlike most integration platforms (open-source SDK, closed proprietary runtime), Nango open-sources the runtime and credential store itself" (agent summary of repo/blog)

**browser-harness**
URL: https://github.com/browser-use/browser-harness
Accessed: 2026-08-13
Quote: "when the agent discovers something non-obvious, it writes a skill file documenting selectors/flows for that site" (agent summary)

**stagehand**
URL: https://docs.stagehand.dev
Accessed: 2026-08-13
Quote: "observe returns candidate actions with selectors without executing, which you cache and replay via act" (agent summary)

**anthropic-agent-tools-vana**
URL: https://github.com/vana-com/data-connectors
Accessed: 2026-08-13
Quote: "Output contract mandates reserved fields (requestedScopes, exportSummary, errors[]) and an explicit degraded-vs-omitted disposition for selector drift" (agent summary)

## CORRECTION (2026-08-13, same day — external review)
The headline claim is too broad as stated. Ecosystems that can hold credentials DO run live functional acceptance: Airbyte runs credentialed Connector Acceptance/integration tests (incl. two-read incremental checks) generally required to merge (docs.airbyte.com/platform/connector-development/testing-connectors); Terraform providers run real plan/apply/destroy acceptance tests against live APIs (developer.hashicorp.com/terraform/plugin/sdkv2/testing/acceptance-tests); Apify probes Store actors daily against default inputs and auto-deprecates repeated failures (docs.apify.com); Scrapy contracts declare live sample-URL assertions. The claim survives only in narrow form: **no surveyed ecosystem verifies function for private personal accounts where the platform cannot hold credentials** — community MCP servers and personal-data connectors. Registries (MCP) still verify identity only.

## SYNTHESIS
Surveyed for the PDPP connector DX/reliability strategy (pdpp inbox/8-13-26-connector-dx-strategy.md). NOTE: read the CORRECTION above before citing the headline claim. The strategy's two core bets — evidence-carrying contributions (captured-transcript provenance + attested run receipts as merge gates) and fault-injection certification against recorded provider twins — have no incumbent: declarative ecosystems (Airbyte, dlt) validate shape, registries (MCP) validate identity, and Nango substitutes runtime auditability for per-connector vetting. The nearest precedents are execution-derived artifacts (browser-harness skill files, Stagehand cached observations) and Vana's own degraded-vs-omitted error disposition, all of which point the same direction: make the artifact of contribution something generated by a real run, so reviewers diff behavior instead of trusting prose. Caveats: quotes above marked "agent summary" were relayed by a research subagent, not re-fetched verbatim; verify before citing externally. Companion sweeps (yt-dlp-class extractor ecosystems; 2024–2026 personal-data aggregators) were in flight when this was captured — extend this entry or add siblings when those land.
