---
title: "Credible, forkable reference implementations keep the reference engine, sample worlds, CLI, and docs site as separate but coordinated consumers of one common public substrate — a real first-class CLI, narrow swappable sample worlds, docs-as-router, and local orchestration as assembly only — never a single all-in-one demo shell with demo-only endpoints"
date: 2026-04-16
topic: product-design
tags: [reference-implementation, forkability, cli-design, developer-experience, packaging, prior-art]
status: draft
sources: [stripe-cli-docs, stripe-cli-repo, stripe-samples, plaid-quickstart-docs, plaid-quickstart-repo, ory-cli, ory-cli-repo, ory-kratos-ui, temporal-cli, temporal-samples, otel-demo-docs, otel-demo-repo]
source_session: 019ce297-6779-78c0-a12e-667fda61949e
---

## CLAIMS

- Stripe's docs site is the index/teaching layer while runnable developer artifacts live elsewhere: the Stripe CLI is a real standalone tool (webhook testing, request logs, event triggering, API object management) distributed like a normal developer tool (native installers, Docker image, its own repo and release cadence), and samples live in a dedicated GitHub org of many narrow, focused repos rather than embedded in the docs. [stripe-cli-docs][stripe-cli-repo][stripe-samples]
- Plaid's docs tell developers to clone the Quickstart repo, set env vars, run a backend then a frontend, and explicitly explain the client + server split; the Quickstart repo is multi-language on the backend but converges on one canonical frontend and one conceptual shape of the flow — one canonical quickstart with minimal ambiguity. [plaid-quickstart-docs][plaid-quickstart-repo]
- Ory keeps product docs, CLI, and reference UIs distinct: the CLI is positioned for automation, migration, CI/CD, and project management; reference UIs (e.g. the Kratos self-service UI) are published separately and framed as examples/reference implementations, not disguised as the core product; generated CLI/API reference is treated as downstream from source repos rather than hand-maintained prose. [ory-cli][ory-cli-repo][ory-kratos-ui]
- Temporal describes its CLI as direct access to a Temporal Service for managing/monitoring/debugging, and that CLI also embeds a local Temporal Service (SQLite persistence + Web UI) suitable for dev/CI; deployment/server samples (including Docker Compose and security-focused configs) live in a separate samples repo outside the docs shell. [temporal-cli][temporal-samples]
- The OpenTelemetry Demo repo is explicitly intended as a near-real-world distributed system that is both a realistic example and a base for vendors/tooling authors to extend; it ships multiple Compose files, tests, and explicit fork guidance, and remains its own runnable artifact that the docs route into rather than a toy embedded in docs. [otel-demo-docs][otel-demo-repo]

## SOURCES

**stripe-cli-docs**
URL: https://docs.stripe.com/stripe-cli
Accessed: 2026-04-16

**stripe-cli-repo**
URL: https://github.com/stripe/stripe-cli
Accessed: 2026-04-16

**stripe-samples**
URL: https://github.com/stripe-samples
Accessed: 2026-04-16

**plaid-quickstart-docs**
URL: https://plaid.com/docs/quickstart/
Accessed: 2026-04-16

**plaid-quickstart-repo**
URL: https://github.com/plaid/quickstart
Accessed: 2026-04-16

**ory-cli**
URL: https://www.ory.com/cli
Accessed: 2026-04-16

**ory-cli-repo**
URL: https://github.com/ory/cli
Accessed: 2026-04-16

**ory-kratos-ui**
URL: https://github.com/ory/kratos-selfservice-ui-node
Accessed: 2026-04-16

**temporal-cli**
URL: https://docs.temporal.io/cli
Accessed: 2026-04-16

**temporal-samples**
URL: https://github.com/temporalio/samples-server
Accessed: 2026-04-16

**otel-demo-docs**
URL: https://opentelemetry.io/docs/demo/
Accessed: 2026-04-16

**otel-demo-repo**
URL: https://github.com/open-telemetry/opentelemetry-demo
Accessed: 2026-04-16

## SYNTHESIS

The strong precedents share one architectural rule: keep the reference implementation, sample worlds, CLI, and docs site as separate but coordinated consumers of a common public substrate. Cross-cutting patterns:

1. **Docs site as router, not runtime dependency.** Docs explain the shape and link to cloneable repos, CLI installs, and quickstarts; runnable artifacts survive without the docs site. The failure mode is a docs/marketing shell that imports the runtime or becomes the only way to operate it.
2. **CLI as a first-class real client.** Across Stripe, Ory, and Temporal the CLI is a serious surface for automation, debugging, inspection, local dev, and management — not a sidecar. If the CLI needs private DB access or website-only APIs, the architecture is drifting.
3. **Reference worlds should be concrete, narrow, and swappable.** Plaid Quickstart, Stripe samples, and OTel Demo each choose a concrete world and stay inside it; sample names/manifests must not leak into the core engine.
4. **Local orchestration is acceptable when it is clearly assembly.** Compose/local-dev bootstrapping starts the real system and remains inspectable as infrastructure; it must not become the only place core behavior is defined, nor a hidden control plane / parallel protocol.
5. **Generated/reference docs should flow from source where possible** (Ory), so protocol shapes shown in docs come from the real implementation rather than hand-curated JSON that drifts.

Anti-patterns to avoid: the "all-in-one demo shell" (one app trying to be docs, marketing, control plane, runtime console, component workbench, and reference at once); demo-only endpoints the CLI/tests don't use; sample worlds baked into core logic; CLIs that are only wrappers around a guided demo path; and samples too broad to copy. A good target is the blend of Stripe's docs/samples/CLI separation, Plaid's canonical-quickstart discipline, Ory's separation of core services / reference UIs / automation tooling, Temporal's serious CLI plus local-dev convenience, and OpenTelemetry Demo's explicit forkability over a near-real-world substrate.
