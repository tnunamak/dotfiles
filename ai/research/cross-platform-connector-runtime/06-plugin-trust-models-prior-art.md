---
title: "Most connector ecosystems trust installation; containment is reserved for adversarial or cross-tenant code"
date: 2026-09-01
topic: cross-platform-connector-runtime
tags: [connectors, plugins, sandbox, supply-chain, trust, personal-data]
status: draft
sources: [airbyte-support, singer-spec, home-assistant-quality, home-assistant-incident, terraform-signing, github-actions-security, zapier-incident, vscode-runtime-security, obsidian-security, backstage-threat-model, n8n-risks, grafana-signing, docker-security, chrome-permissions, firefox-permissions, aws-lambda-isolation]
source_session: f4773a11-4dae-4fbf-aeca-dd5a65ab0f27
---

> **Headline findings**
>
> **Typical model:** trust-by-installation, strengthened by source/publisher identity, review, official/community tiers, version pinning, signatures or provenance, declared permissions, and logs. Most platforms do **not** put a user-installed connector behind a deny-by-default process and network boundary.
>
> **Important qualification:** several systems do use a separate process, container, worker, or iframe for stability and deployment. That is not automatically a security sandbox. In particular, a separate process with the user's credentials and unrestricted outbound network is still a trusted plugin boundary, not containment.
>
> **Containment model:** browser extensions, mobile applications, serverless customer-code execution, and browser-based editor extensions assume code may be malicious or code from one tenant may attack another. They pay for a reference monitor, per-OS sandbox integration, VM/microVM, or reduced API surface.
>
> **PDPP implication:** a personal-data connector runner should not treat “the user clicked Install” as sufficient for arbitrary community code with account credentials. The practical fit is a curated, signed and pinned connector artifact running out-of-process, with explicit credential/scope declarations, narrow filesystem mounts, default-deny access to local services, and an auditable allowlist of required egress. This is defense-in-depth around chosen code, not a claim of a browser-grade adversarial sandbox.

## Classification rubric

“Sandboxed” below means a documented enforcement boundary that limits the plugin's host resources or network. A subprocess, VM, or container is marked **not containment** when the platform documentation does not show the relevant restrictions. “Thin” means I found no authoritative public evidence sufficient to make a stronger claim; it does not mean that the platform has no private controls.

## Survey

| Platform | (a) Runtime containment / egress | (b) Actual trust mechanism | (c) Public failure and response |
|---|---|---|---|
| **Airbyte connectors** | Connectors are commonly packaged and run as Docker containers, which gives a process/filesystem boundary. Airbyte's public connector material does not establish a deny-by-default egress policy for connector containers; ordinary container networking permits outbound access. **Process isolation: partial; egress restriction: not established.** | Official/Enterprise/Marketplace/Custom support tiers; acceptance tests; maintainer review; connector manifests/CDK. Current docs call Marketplace community-maintained with no Airbyte SLA. | Airbyte disclosed a connector-builder-server deserialization vulnerability in CVE-2025-68664; the issue describes malicious connector configurations reaching the vulnerable path. Response was patch/upstream remediation, not a new general connector sandbox. Supply-chain compromise of a published connector was not found in authoritative sources reviewed. |
| **Singer taps / Meltano taps** | A tap is a normal executable, usually isolated only by a Python virtualenv or process. The Singer spec defines messages, not permissions or isolation. **No sandbox; no egress restriction.** | Open source, repository/maintainer identity, code review, virtualenv separation, tests, and user choice. Meltano SDK supplies named test templates, but tests are not a security boundary. | Singer's own issue tracker documents broken tap/target interoperability from dependency pinning. That is reliability failure, not a known malicious supply-chain incident. The evidence for Singer-specific security governance is thin and old; do not infer a maintained signing or audit system from the protocol spec. |
| **Home Assistant integrations** | Core integrations run inside the Home Assistant process. Custom integrations are Python code loaded by the same application and therefore inherit its filesystem, network, and credential access. **No sandbox; no egress restriction.** | Core review, code owners, `hassfest`, and the Integration Quality Scale (bronze/silver/gold/platinum). Custom integrations are explicitly outside the official release and unsupported; HACS is a distribution/review-adjacent community tool, not a sandbox. | Home Assistant disclosed 2021 vulnerabilities in HACS and other custom integrations, including unauthenticated directory traversal that could read files accessible to Home Assistant, including stored credentials. Response: fixed integrations, Home Assistant Core protections in 2021.1.3, update/remove guidance, and credential rotation advice. |
| **Terraform providers** | Providers run as separate plugin subprocesses over HashiCorp's go-plugin RPC. That improves crash isolation, but official docs do not say the subprocess is sandboxed or that outbound network is allowlisted. Providers can read environment/files and call APIs with Terraform's credentials. **Separate process, not containment.** | Strongest provenance model in this group: registry namespaces and Official/Partner/Community tiers; signed releases and checksum verification; dependency lock file; manual installation is explicitly a trust decision. HashiCorp says it does not provide a full chain of trust for self-signed providers. | No confirmed active malicious-provider campaign was found in primary HashiCorp sources reviewed. Public security research and proof-of-concept work show that a provider can exfiltrate credentials or execute commands; that is a demonstrated trust-model risk, not evidence of a particular in-the-wild incident. Response is signing, checksums, lock files, private registries, and warnings—not runtime containment. |
| **GitHub Actions** | A GitHub-hosted job gets an ephemeral runner VM, but actions in a job share the job's filesystem, token, secrets, and network capabilities. Self-hosted runners are the customer's machine and can be much less isolated. GitHub's controls reduce blast radius through workflow permissions and event policy; they are not a per-action sandbox. | Commit-SHA pinning, allowed-action policy, least-privilege `GITHUB_TOKEN`, secret handling, artifact attestations/provenance, review, and reusable-workflow governance. | The 2025 `tj-actions/changed-files` compromise exposed the weakness of mutable action tags and action trust. GitHub and the ecosystem responded with SHA-pinning guidance, stronger action policies, changes to `actions/checkout` behavior for untrusted forks, and a broader supply-chain hardening program. |
| **Zapier / Make connectors** | Usually not user-machine plugins: connector code executes in the vendor's hosted service. Public connector-review material does not expose a per-connector egress sandbox design. **Customer-machine question: not applicable; hosted isolation details: thin.** | Zapier publishing tests, developer-supplied test account, prohibition on sandbox/test endpoints and hardcoded credentials; Make automated pre-screen plus manual QA. Vendor-controlled connector catalog and account permissions are the main trust controls. | Zapier reported a 2025 npm supply-chain compromise affecting a subset of packages used by integration developers. Response included incident communication and package/update investigation. This is a vendor build/dependency incident, not proof that Zapier connector execution escaped its hosted boundary. |
| **VS Code extensions (desktop)** | Desktop extensions run in a local Node.js extension host with the same permissions as VS Code: files, network, external processes, and settings. The extension host is a stability boundary, not a security sandbox. **No containment on desktop.** VS Code for the Web uses a browser worker host and is materially more constrained. | Marketplace publisher trust prompt, static manifest metadata, Marketplace malware/secret scanning, dynamic runtime detection in a clean-room VM, ratings/installs, and Workspace Trust for code/workspaces. | The model has repeatedly faced malicious or compromised extensions as a class; the official documentation treats malicious extensions and privacy risk as expected threats and tells users how to report them. Response is publisher trust, Marketplace scanning/removal, and web/restricted modes—not desktop extension sandboxing. Exact incident counts are not established by the official docs reviewed. |
| **Obsidian plugins** | Community plugins execute as Electron/Node code and inherit Obsidian's access: files, Internet, and installing programs. Obsidian explicitly says it cannot reliably restrict plugin permissions. **No sandbox; no egress restriction.** Restricted Mode prevents third-party code execution until the user opts in; it is an installation gate, not runtime containment. | Official directory policies, automated security/malware/code-quality scanning, safety scorecard, manual review for popular/featured/flagged plugins, author/source visibility, and an explicit “trust the author” warning. | No authoritative Obsidian disclosure of a malicious community-plugin incident was found in this survey. That negative result is thin evidence, not assurance. Obsidian's response posture is independent audit guidance, reporting/removal, Restricted Mode, and directory scanning. |
| **Backstage plugins** | Frontend plugins are bundled into the Backstage frontend; backend plugins are normally deployed in the same backend service. Backstage's threat model discusses signed service/user tokens and plugin authorization, but does not make plugins separate hostile processes or restrict their network egress. **No general plugin sandbox.** | Plugin package/repository review, backend permission framework, service-to-service signed tokens with source/target plugin IDs, and deployment topology choices. High-security deployments can split sensitive services such as auth into separate services/databases. | Backstage publishes audits and security advisories; the threat model warns that custom plugin permission checks and token handling matter. No plugin supply-chain incident establishing a general Backstage marketplace failure was found in the reviewed primary sources. |
| **dbt packages** | A package is code/macros compiled into the dbt project. It has no independent plugin process. Macros can affect generated SQL and, depending on adapter/project configuration, invoke powerful behavior. **No sandbox; no egress restriction.** | Package Hub/repository identity, open source review, package version constraints/lock files, project code review, and organizational allowlists. This is dependency trust, not capability enforcement. | No dbt-package-specific public supply-chain incident was confirmed in the primary sources reviewed. The threat is structurally the same as a compromised language dependency; evidence on package-level incident response is thin. |
| **n8n nodes** | Community nodes are npm packages loaded into the n8n instance. n8n's own docs say community nodes have full access to the machine and workflow data and can perform malicious actions. **No sandbox; no egress restriction.** | “Verified community nodes” tier, n8n review/security requirements, npm provenance guidance, admin switch to disable community packages, and cloud restrictions on unverified nodes. | Security researchers reported malicious npm packages impersonating n8n community integrations in 2026. n8n's documented response/control is to vet verified nodes and allow administrators to disable community packages; its risk documentation remains explicit that unverified nodes have full machine access. |
| **Grafana plugins** | Frontend code runs in the browser UI; backend plugins run as separate processes. Grafana's documented controls are signature verification and plugin policy, not a general OS sandbox or per-plugin egress denylist. **Separate backend process, not proven containment.** | Cryptographic signed manifest required by default; Core/Private/Community/Commercial signature levels; catalog review; unsigned plugins blocked by default (except explicit development/configuration override); RBAC and secure secret fields for plugin configuration. | Grafana has disclosed serious plugin vulnerabilities, including Image Renderer file disclosure and arbitrary code execution. Response: security advisories, fixed versions, and continued signature enforcement. Grafana also disclosed a 2026 GitHub-environment supply-chain incident affecting its repositories, while reporting no production/customer compromise; it rotated credentials and hardened controls. |
| **Docker / OCI connector runtimes** | This is the strongest general-purpose containment option in the survey, but defaults matter. Linux namespaces, cgroups, seccomp, capabilities, mounts, and a private network stack isolate processes; default bridge networking still allows outbound Internet. `--network none`, a controlled proxy, rootless mode, read-only mounts, capability dropping, and a VM-backed runtime can make the boundary stronger. **Containment available; not automatic.** | Image digest pinning, registry identity, signatures/attestations (for example Sigstore/cosign), SBOM/provenance, admission policy, least privilege, resource limits, and runtime audit logs. OCI itself defines packaging/runtime interfaces, not a trust decision or a universal egress policy. | Container escapes and poisoned images are well-known ecosystem failure classes; Docker's own security documentation warns that default mounts/capabilities can provide incomplete isolation and that kernel vulnerabilities matter. Response is layered hardening, rootless/VM-backed runtimes, scanning/signing/provenance, and patching—not a claim that containers are invulnerable. |

## What the contrast set tells us

### Browser extensions: adversarial web context plus a reference monitor

Chrome and Firefox make permissions part of the extension manifest: API permissions, host permissions, and optional permissions are visible to the user and can be granted later. Sandboxed extension pages have an opaque origin and cannot use browser extension APIs directly. The browser process itself is the reference monitor, enforcing origin, content-script, storage, and network rules. This is different from VS Code desktop or Obsidian, where the host deliberately gives installed code broad native capability.

The cost is substantial browser engineering: multi-process site isolation, origin enforcement, IPC, permission UX, store review, update/revocation infrastructure, and OS-specific native hardening. A manifest is useful only because the browser enforces it; it is not a substitute for enforcement.

### Mobile app sandboxes: adversarial apps and cross-app data separation

Android and iOS treat installed applications as mutually untrusted tenants. Each app receives an OS identity and private storage; dangerous capabilities pass through OS permission brokers, code signing, store review, and platform policy. The mobile model is therefore closer to containment than to connector governance. The cost is OS-owned kernel/runtime isolation, permission systems, signing/update infrastructure, and platform-specific APIs. Reproducing this on macOS, Windows, and Linux is a product-scale undertaking.

### Serverless customer-code runtimes: explicitly hostile or cross-tenant code

Lambda describes each function execution environment as isolated, and its tenant-isolation mode uses Firecracker virtualization to prevent reuse across tenants. Lambda MicroVMs expose configurable ingress and egress for workloads that execute user or AI-generated code. This is an adversarial/cross-tenant threat model, so the provider pays for microVMs, scheduling, cold starts, per-tenant lifecycle, network policy, observability, and the operational burden of patching the substrate.

### VS Code Restricted Mode: trust the project, not the extension

Restricted Mode protects against unintended code execution from an untrusted workspace. It disables or limits extension features that consume workspace-controlled code/settings and prevents tasks/debugging. It does **not** turn desktop extensions into sandboxes: an extension that is already trusted by the user still runs with VS Code's native privileges. This is a useful warning against conflating a consent gate with a capability boundary.

## ANSWER

Among the strongest prior-art platforms in this survey, the typical governance model is **trust-by-installation with layered supply-chain governance**, not full containment of every third-party connector. The recurring controls are:

- publisher/namespace identity and official/partner/community tiers;
- review, acceptance tests, quality scales, or catalog admission;
- signatures, checksums, lock files, commit pins, and increasingly provenance/attestation;
- declared permissions or credential scopes where the host can enforce them;
- disable/revoke controls, warnings, audit/security logs, and incident response.

Separate processes, containers, and workers are common, but the evidence does not support calling them sandboxes unless the platform also restricts the plugin's filesystem, credentials, syscalls, and egress. Grafana and Terraform are good examples of “separate process plus provenance”; Obsidian and n8n are explicit examples of “installed code has full host access”; Docker/OCI is a toolkit that can provide containment when configured as such.

For a personal-data collection tool whose connectors access the owner's accounts, credentials, and machine, the right model depends on the connector supply chain:

1. **Curated first-party connectors:** trust-by-installation can be the primary model, but use signed/pinned artifacts, explicit scopes, an out-of-process runner, narrow mounts, credential injection only for the active operation, and a recorded network allowlist. This is the closest fit to mature connector ecosystems.
2. **Community or arbitrary connectors:** add a real containment boundary. A rootless OCI runtime with no host-network mode, no broad host mounts, dropped capabilities, read-only base image, resource limits, and proxy-mediated egress is a reasonable first boundary. A VM/microVM is stronger when the connector may be actively malicious or when the host holds unrelated secrets.
3. **Do not rely on a manifest alone:** declarations improve review and consent, but they only become security properties when the runtime is a reference monitor that can reject undeclared access.

The evidence is strongest for the broad pattern and for the documented failures in Home Assistant, GitHub Actions, Zapier's npm supply chain, n8n, Obsidian's stated limitations, Terraform's signing/lock model, Grafana's signature model, and Docker's default-network caveats. Evidence is thinner for platform-specific malicious incidents in Singer/Meltano, Backstage, dbt packages, Obsidian community plugins, and Terraform providers; absence of a located incident should not be read as evidence of safety.

## CLAIMS

- Airbyte documents current connector support tiers as Airbyte, Enterprise, Marketplace, and Custom, with Marketplace community maintenance and no Airbyte support SLA. [airbyte-support]
- The Singer specification defines RECORD, SCHEMA, STATE, and catalog semantics, but does not define a permission or execution sandbox. [singer-spec]
- Home Assistant says custom integrations are not included in official releases and are not reviewed, security-audited, maintained, or supported by the project. [home-assistant-quality]
- Home Assistant's 2021 disclosure describes HACS directory traversal and file/credential exposure through custom integrations, and says Core 2021.1.3 added protections. [home-assistant-incident]
- Terraform verifies registry provider signatures and distinguishes HashiCorp, partner, and self-signed providers; it says HashiCorp does not provide a chain of trust for self-signed providers. [terraform-signing]
- GitHub recommends least-privilege workflow permissions, full-length commit-SHA pinning, and action allowlists because a compromised action can exfiltrate secrets or inject code. [github-actions-security]
- Zapier's status page documents a 2025 npm supply-chain compromise affecting a subset of packages. [zapier-incident]
- VS Code documents that desktop extensions have the same permissions as VS Code, including filesystem, network, and external-process access; its Marketplace uses scanning and clean-room dynamic detection. [vscode-runtime-security]
- Obsidian says community plugins can access files, connect to the Internet, and install programs, and that it cannot reliably restrict plugin permissions; Restricted Mode prevents third-party code execution until disabled. [obsidian-security]
- Backstage's threat model documents signed service/plugin tokens and authorization boundaries, but does not establish a general OS sandbox for plugins. [backstage-threat-model]
- n8n says community nodes have full access to the machine and workflow data; it offers verified nodes and a setting to disable community packages. [n8n-risks]
- Grafana verifies plugin signatures at startup and does not load unsigned plugins by default; its policy assigns Private, Community, and Commercial levels. [grafana-signing]
- Docker documents namespaces, a separate network stack, reduced capabilities, and the fact that default bridge networking permits external access; it warns that defaults can provide incomplete isolation. [docker-security]
- Chrome and Firefox expose API/host permissions and optional permissions through extension manifests; Firefox sandboxed pages cannot access extension APIs. [chrome-permissions] [firefox-permissions]
- AWS Lambda documents Firecracker-based tenant isolation and configurable egress for microVM workloads intended to run user or AI-generated code. [aws-lambda-isolation]

## SOURCES

**airbyte-support** — https://docs.airbyte.com/integrations/connector-support-levels — accessed 2026-09-01.

**singer-spec** — https://github.com/singer-io/getting-started/blob/master/docs/SPEC.md — accessed 2026-09-01.

**home-assistant-quality** — https://developers.home-assistant.io/docs/core/integration-quality-scale/ — accessed 2026-09-01.

**home-assistant-incident** — https://www.home-assistant.io/blog/2021/01/22/security-disclosure/ — accessed 2026-09-01.

**terraform-signing** — https://developer.hashicorp.com/terraform/cli/plugins/signing — accessed 2026-09-01.

**github-actions-security** — https://docs.github.com/en/code-security/tutorials/secure-your-organization/protect-against-threats — accessed 2026-09-01.

**zapier-incident** — https://status.zapier.com/incidents/01KAV9DDHMYT7R6MFHSB8C09E3 — accessed 2026-09-01.

**vscode-runtime-security** — https://code.visualstudio.com/docs/configure/extensions/extension-runtime-security — accessed 2026-09-01.

**obsidian-security** — https://obsidian.md/help/plugin-security — accessed 2026-09-01.

**backstage-threat-model** — https://backstage.io/docs/next/overview/threat-model/ — accessed 2026-09-01.

**n8n-risks** — https://docs.n8n.io/integrations/community-nodes/risks/ — accessed 2026-09-01.

**grafana-signing** — https://grafana.com/docs/grafana/latest/administration/plugin-management/plugin-sign/ — accessed 2026-09-01.

**docker-security** — https://docs.docker.com/engine/security/ — accessed 2026-09-01.

**chrome-permissions** — https://developer.chrome.com/docs/extensions/develop/concepts/declare-permissions — accessed 2026-09-01.

**firefox-permissions** — https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/manifest.json/permissions — accessed 2026-09-01. See also https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/manifest.json/sandbox.

**aws-lambda-isolation** — https://docs.aws.amazon.com/lambda/latest/dg/tenant-isolation.html and https://docs.aws.amazon.com/lambda/latest/dg/lambda-microvms-guide.html — accessed 2026-09-01.

Additional incident and prior-art references used during synthesis:

- GitHub's 2026 supply-chain hardening response: https://github.blog/security/supply-chain-security/disrupting-supply-chain-attacks-on-npm-and-github-actions/
- Grafana plugin security advisories: https://grafana.com/security/security-advisories/
- Grafana plugin policy and review/signing tiers: https://grafana.com/legal/plugins/
- n8n verification guidelines: https://docs.n8n.io/connect/create-nodes/build-your-node/reference/verification-guidelines/
- VS Code Workspace Trust and Restricted Mode: https://code.visualstudio.com/api/extension-guides/workspace-trust
- Docker networking defaults: https://docs.docker.com/engine/network/

## SYNTHESIS

The platforms converge on a governance stack, not on one universal sandbox. The decisive variable is threat model: chosen code that extends a local tool is commonly admitted through review and explicit installation; adversarial code, browser content, mobile apps, and cross-tenant customer code require a reference monitor and pay the cost of containment. For PDPP, account credentials and personal data raise the consequence of a connector compromise enough to justify OCI-level defense-in-depth even when the product still uses curated-installation trust as its primary governance model.
