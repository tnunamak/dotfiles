---
title: "Mature plugin/extension/connector ecosystems place the trusted execution runtime either in a separately-governed project (Terraform go-plugin, K8s CRI/containerd/runc, GitHub Actions runner, OTel Collector core) or inside the product itself (VS Code, browsers) — but never inside the same repo/governance as the untrusted content it runs; every surveyed case that shares governance between content and runtime (Home Assistant+HACS, ComfyUI custom nodes, npm postinstall) has documented incidents traceable to that conflation"
date: 2026-08-14
topic: connectors
tags: [runtime-governance, plugin-architecture, reference-monitor, terraform, kubernetes, github-actions, opentelemetry, vscode, home-assistant, comfyui, npm, supply-chain]
status: draft
sources: [go-plugin, terraform-plugin-protocol, terraform-registry-tiers-2, hashicorp-sdk-split, kubelet-cri-blog, kubelet-cri-docs, containerd-cncf-graduation, runc-oci, runc-cve-2019-5736, brauner-privileged-containers, actions-runner-repo, actions-runner-license, actions-runner-hardening-docs, tj-actions-incident, otel-collector-contrib, otel-component-stability, otel-ocb, vscode-extension-host, vscode-web-extensions, vscode-marketplace-separate, chromium-site-isolation, chromium-mv3, ha-hacs-warning, ha-hacs-security-disclosure, ha-hacs-safety-tradeoff, comfyui-security-policy, comfyui-cve, npm-postinstall-incidents, npm-v12-scripts-off, pnpm-allowlist, deno-permissions]
source_session: a7495b44-939c-46e4-a2d6-87d7d7562ac6
---

## CLAIMS

### Terraform — subprocess+RPC isolation, runtime governed separately from both core and provider content

- The gRPC/subprocess plumbing that runs provider code is `hashicorp/go-plugin`, a standalone repo/Go module, separate from `hashicorp/terraform` (core) and `terraform-plugin-sdk`. It predates Terraform's adoption of it (built first for Packer) and is reused by Vault, Nomad, Boundary, and Waypoint — a cross-product, separately-versioned runtime library, not Terraform-specific infrastructure. [go-plugin]
- Each Terraform provider runs as a separate OS subprocess; Terraform Core launches it, reads a handshake line off stdout, then connects as a gRPC client over a loopback Unix socket/TCP — the provider process is the gRPC server. The canonical protocol spec lives in `hashicorp/terraform`'s `docs/plugin-protocol/` directory, distinct from both the transport (go-plugin) and the developer-facing SDK bindings (terraform-plugin-sdk/terraform-plugin-go). [terraform-plugin-protocol]
- `terraform-plugin-sdk` itself split out of Terraform core in Sept 2019 specifically so provider development could evolve independently of core. [hashicorp-sdk-split]
- go-plugin's documented rationale for subprocess+RPC over in-process loading: crash isolation ("a panic in a plugin doesn't panic the plugin user"), security containment (plugin access limited "to the interfaces and args given to it, not the entire memory space"), and protocol versioning so the host can reject incompatible plugin versions cleanly. Vault-specific docs state dynamic library loading (dlopen/cgo) was "not acceptable for security reasons" for a secrets-management tool. [go-plugin]
- Provider content itself is tiered by the Terraform Registry into Official (HashiCorp-authored), Partner (vetted third-party), and Community (unvetted individual) — vetting tier is orthogonal to the uniform GPG-signing floor required of all three tiers. [terraform-registry-tiers-2]
- UNVERIFIED: no single HashiCorp engineering blog post found articulating supply-chain rationale specifically for Terraform providers (as opposed to the general go-plugin README rationale).

### Kubernetes — three independently-governed layers between orchestrator and executed content

- kubelet lives in `kubernetes/kubernetes` core, governed by SIG-Node (a vertical SIG inside the Kubernetes project) — not spun out to a separate repo. [kubelet-cri-docs]
- containerd lives in its own org (`containerd/containerd`), governed by CNCF (Cloud Native Computing Foundation, a Linux Foundation project), and graduated CNCF Feb 28, 2019 (5th project to graduate, after Kubernetes, Prometheus, Envoy, CoreDNS). [containerd-cncf-graduation]
- runc lives at `opencontainers/runc`, governed by OCI (Open Container Initiative), a *separate* Linux Foundation project from CNCF, established 2015 when Docker donated its container format/runtime spec plus the runc reference implementation. [runc-oci]
- CRI (Container Runtime Interface, introduced Kubernetes 1.5, Dec 2016) replaced kubelet's direct, hardcoded integration with Docker — described by the Kubernetes blog as "an internal and volatile interface" requiring "a deep understanding of Kubelet internals" and forming "high barriers to entry for nascent container runtimes." CRI is a protobuf+gRPC plugin API letting kubelet support many runtimes "without the need to recompile." Docker itself predated CRI; the dockershim compatibility layer was carried until formal removal in Kubernetes 1.24 (2022). [kubelet-cri-blog]
- CVE-2019-5736: a malicious container image (or a `docker exec` into an attacker-writable container) could overwrite the host's runc binary via `/proc/self/exe` mishandling, giving root code execution on the host — direct evidence that the low-level executor (runc) can be compromised by the content it's asked to run if the isolation is imperfect. [runc-cve-2019-5736]
- LXC/LXD maintainer Christian Brauner used this CVE to argue explicitly that a privileged container is not a security boundary, and specifically that runc's "exits after spawning the container" architecture made it more exposed to attack via malicious container images than comparable runtimes. [brauner-privileged-containers]
- UNVERIFIED: no official Kubernetes/CNCF doc found using language as explicit as "the runtime shouldn't trust workload-supplied config" verbatim; the security argument for the CRI boundary is better evidenced by the CVE record and independent researchers than by an explicit CNCF security statement (CRI's own stated rationale is maintainability/extensibility, not phrased as security per se).

### GitHub Actions — runner is its own repo, separate from both the product and marketplace content

- `actions/runner` is a distinct public repo (open-sourced Dec 19, 2019, MIT-licensed) from both GitHub.com's closed-source platform and from Marketplace Action content (e.g. `actions/checkout`, third-party actions). It contains the agent that registers with GitHub, listens for and picks up jobs, sets up the execution environment, and executes workflow steps. As of the current README the repo is not accepting external code contributions (still takes bug reports/security fixes). [actions-runner-repo]
- Releases are tagged independently in `actions/runner` (roughly every few weeks) and are NOT synchronized to GitHub.com platform deploys; GitHub's docs describe a progressive rollout policy where "the latest release might not be available to your enterprise, organization, or repository yet." [actions-runner-repo]
- The exact same runner binary/repo serves both GitHub-hosted and self-hosted deployment models — one runtime project, two hosting modes. GitHub-hosted runners are "ephemeral and clean isolated virtual machines" per job; self-hosted runners "do not have guarantees around running in ephemeral clean virtual machines, and can be persistently compromised by untrusted code in a workflow," and GitHub's own docs state self-hosted runners "should almost never be used for public repositories" because anyone who can open a PR can potentially compromise the environment and the `GITHUB_TOKEN`. [actions-runner-hardening-docs]
- GitHub's security-hardening docs draw the runner-vs-content boundary explicitly: `GITHUB_TOKEN` is auto-scoped to the triggering repo and expires after the job, but "there is significant risk in sourcing actions from third-party repositories" since "a compromise of a single action... would have access to all secrets configured on your repository." [actions-runner-hardening-docs]
- The tj-actions/changed-files compromise (March 2025, CVE-2025-30066): attackers compromised a maintainer PAT and retroactively rewrote version tags to point at a malicious commit that dumped runner memory into workflow logs, exposing secrets across an estimated 23,000+ repos. The compromise landed entirely in Marketplace Action content (a third-party repo's `dist/index.js`), not in `actions/runner` or GitHub's execution infrastructure — the runner/content boundary held; the content layer is where the damage occurred. Mitigation recommended: pin actions to full commit SHAs, not mutable tags. [tj-actions-incident]

### OpenTelemetry Collector — core/contrib repo split with a compile-time integrator gate

- `open-telemetry/opentelemetry-collector` (core: minimal, stable runtime/pipeline framework) and `open-telemetry/opentelemetry-collector-contrib` (community-contributed receivers/processors/exporters) are genuinely separate repos with separate governance: contrib uses a CODEOWNERS-based per-component ownership model (repo-wide Approvers/Maintainers plus per-directory Code Owners), distinctly lighter-weight than core's smaller, centralized maintainer group who own the stable public Go API. [otel-collector-contrib]
- The OpenTelemetry Collector Builder (OCB) composes a custom distribution from a YAML manifest listing components by Go module path + version — components can come from core, contrib, or any arbitrary third-party Go module. This is a compile-time, integrator-controlled gate: the project ships a small stable core; a build tool lets the integrator (not the project) choose what untrusted/community code gets linked into their binary. [otel-ocb]
- Core's `component-stability.md` defines a Development/Alpha → Beta → Stable maturity ladder tracked per-signal per-component, with explicit, auditable graduation gates (e.g. Alpha→Beta requires ≥2 active code owners responding to ≥80% of issues/PRs over 30 days; Beta→Stable requires ≥3 active code owners and non-critical production exposure). Production distros (official `otelcol-contrib`, vendor distros like Splunk/Datadog/Grafana Alloy) use this stability ledger, not the repo boundary alone, to decide which contrib components are trustworthy for GA. [otel-component-stability]
- OTel Collector is CNCF-governed under the OpenTelemetry umbrella project.

### VS Code and browsers — runtime owned by the product/vendor, distribution owned separately, isolation is process-level not organizational

- The VS Code Extension Host is implemented inside `microsoft/vscode` itself (same repo, same governance, same release cadence) — not a separately-governed runtime project. It is architecturally isolated (own OS process for desktop/remote; own Web Worker for web) but organizationally identical to the rest of the product. [vscode-extension-host]
- The documented isolation rationale is explicit: "VS Code aims to deliver a stable and high performance editor to users, and misbehaving extensions should not impact the user experience." Extension code communicates with the main/renderer process only via a channel-based RPC layer (typed proxy objects on each side), never direct access. [vscode-extension-host]
- The Marketplace (marketplace.visualstudio.com) is a genuinely separate service with its own repo (`microsoft/vsmarketplace`) and terms of use, distinct from the open-source `microsoft/vscode` runtime — the separation that exists is content-distribution-vs-runtime, not runtime-vs-product. [vscode-marketplace-separate]
- Chromium's extension platform (Manifest V3, service workers, site-isolation-based sandboxing) is developed inside the Chromium project/Google, co-standardized with other browser vendors via the W3C WebExtensions Community Group since 2020 — separate governance from the Chrome Web Store's review/distribution team. Extensions got dedicated process isolation as part of Site Isolation (Chromium M55, "isolating extension frames by default"); academic analysis found 70.4% of RCE-capable disclosed rendering-engine vulnerabilities would have been mitigated by this sandboxing architecture. [chromium-site-isolation]
- Pattern across both: browser/product vendor keeps the sandbox/permission engine outside forkable/moddable reach (organizationally as well as technically) so that even a failure in store-side review is capped by the runtime boundary — but this is vendor-owned-runtime-plus-vendor-owned-store-review-team as two functions of one org, not two separately governed projects the way Terraform/K8s/Actions/OTel are.

### Negative cases — shared governance/execution between content and runtime, with documented consequences

- Home Assistant's integration loader lives inside `home-assistant/core`; integrations run in-process in the same Python interpreter as core, with no privilege boundary between "an integration" and "the platform." [ha-hacs-warning]
- HACS (Home Assistant Community Store) is an explicitly separate, unofficial, community-run project (not part of `home-assistant/core` governance) that installs custom integrations from arbitrary GitHub repo URLs — but those integrations execute with the *same* in-process privilege as core-bundled ones; there is no separate runtime/sandbox tier at execution time. Home Assistant's own UI shows a warning banner: "We found a custom integration hacs which has not been tested by Home Assistant. This component might cause stability problems." [ha-hacs-warning]
- A real, named incident: Home Assistant's "Security Disclosure 2" blog post documents a directory-traversal-class vulnerability in HACS itself (patched HACS 1.10.1, mitigated core-side in HA Core 2021.1.5) — because HACS runs in-process with full core access, the vulnerability carried full-core blast radius. [ha-hacs-security-disclosure]
- Home Assistant's own safety/security roadmap discussion states directly: "HACS is not considered an appropriate foundation for safety-critical or guardrail-based guarantees. The current HACS model deliberately optimizes for openness, low friction, and rapid innovation... but those same properties make it difficult to rely on HACS components for anything needing strong assurances around review or provenance." This is HA's own explicit statement that equal execution privilege for reviewed vs. unreviewed content is a known, named tradeoff, not an oversight. [ha-hacs-safety-tradeoff]
- ComfyUI custom nodes are plain Python classes loaded and executed in-process with ComfyUI core. ComfyUI's own GitHub security policy states: "custom nodes are arbitrary Python code and are trusted as much as any other software the user chooses to install." This is arguably a worse case than Home Assistant/HACS because ComfyUI operates its own first-party Registry distributing these same unsandboxed nodes — the distribution channel is not fully third-party. [comfyui-security-policy]
- Documented consequences: ComfyUI's Registry standards now ban `eval`/`exec` in custom nodes due to RCE risk; CVE-2024-21576 documents code injection via `eval` in a specific custom-node package reachable through a crafted workflow; 2026 reports (Censys, The Hacker News) document internet-scale scanning campaigns exploiting exposed ComfyUI instances via custom nodes that accept raw Python input as an unauthenticated RCE primitive, with attackers auto-installing further vulnerable node packages via ComfyUI-Manager. A malicious node ("ComfyUI_LLMVISION") was found disguised as a helpful extension while stealing browser passwords, credit card data, and browsing history. [comfyui-cve]
- npm's install model runs `preinstall`/`install`/`postinstall` lifecycle scripts automatically with the same privilege as the invoking user/CI process — described as "the intended design of the tool," not a bug. Documented incidents using this as the execution primitive: event-stream (2018, backdoor targeting a specific cryptocurrency wallet via a socially-engineered maintainer handoff), ua-parser-js (CVE-2021-41265), colors/faker maintainer sabotage (2022), @ctrl/tinycolor worm (2024), the chained debug/chalk maintainer-account takeover (Sept 2025), and the large-scale self-propagating "Shai-Hulud" worm (2025, with a "2.0" wave later) that used compromised packages' install-time execution to harvest credentials and republish itself into further packages. [npm-postinstall-incidents]
- Industry response has converged on making install-time script execution opt-in rather than default: npm v12 (mid-2026) flips `allowScripts` to off by default. pnpm led this starting v10 (Jan 2025) with an explicit allowlist and interactive `pnpm approve-builds`; `strictDepBuilds` (default v11) hard-fails unlisted packages. Bun similarly disables postinstall scripts by default via a `trustedDependencies` allowlist. Deno goes further structurally: it never runs npm lifecycle scripts without explicit per-package approval (`--allow-scripts=<pkg>` or persistent `deno approve-scripts`), and its permission model extends beyond install scripts to runtime file/network/env access — an actual capability-based sandbox separating "the runtime" from "the code it runs," the piece missing from npm/ComfyUI/Home-Assistant-style in-process models. [npm-v12-scripts-off] [deno-permissions]

## SOURCES

**go-plugin**
URL: https://github.com/hashicorp/go-plugin
Accessed: 2026-08-14
Quote: "Plugins can't crash your host process: A panic in a plugin doesn't panic the plugin user" — cross-used by Terraform, Vault, Packer, Nomad, Boundary, Waypoint (agent summary via research subagent)

**terraform-plugin-protocol**
URL: https://github.com/hashicorp/terraform/blob/main/docs/plugin-protocol/README.md ; https://developer.hashicorp.com/terraform/plugin/framework/provider-servers
Accessed: 2026-08-14
Quote: "Only .proto files published as part of Terraform release tags are actually official protocol versions" (agent paraphrase relayed via research subagent, not independently re-fetched by primary author of this entry)

**terraform-registry-tiers-2**
URL: https://developer.hashicorp.com/terraform/registry/providers
Accessed: 2026-08-14
Quote: Official/Partner/Community tiers, GPG signing uniform across all tiers (see also [[terraform-krew-and-homebrew-model-multi-version-multi-platform-registry-indexes-with-materially-different-signing-and-deprecation-shapes]] in this corpus)

**hashicorp-sdk-split**
URL: https://github.com/hashicorp/terraform/issues/26418
Accessed: 2026-08-14
Quote: terraform-plugin-sdk internalized/split from core (Sept 2019) so provider development could evolve independently (agent summary)

**kubelet-cri-blog**
URL: https://kubernetes.io/blog/2016/12/container-runtime-interface-cri-in-kubernetes/
Accessed: 2026-08-14
Quote: pre-CRI integration was "an internal and volatile interface" requiring "a deep understanding of Kubelet internals and incurs significant maintenance overhead"

**kubelet-cri-docs**
URL: https://kubernetes.io/docs/concepts/architecture/cri/ ; https://github.com/kubernetes/community/tree/master/sig-node
Accessed: 2026-08-14
Quote: kubelet governed by SIG-Node within kubernetes/kubernetes core (agent summary)

**containerd-cncf-graduation**
URL: https://www.linuxfoundation.org/press/press-release/cloud-native-computing-foundation-announces-containerd-graduation ; https://www.cncf.io/announcements/2019/02/28/cncf-announces-containerd-graduation/
Accessed: 2026-08-14
Quote: containerd graduated CNCF Feb 28, 2019, 5th project after Kubernetes/Prometheus/Envoy/CoreDNS

**runc-oci**
URL: OCI/Linux Foundation founding history (agent summary via research subagent, not independently re-fetched)
Accessed: 2026-08-14
Quote: OCI established 2015 when Docker donated container format/runtime spec + runc reference implementation to the Linux Foundation, as a project distinct from CNCF

**runc-cve-2019-5736**
URL: https://seclists.org/oss-sec/2019/q1/119 ; https://unit42.paloaltonetworks.com/breaking-docker-via-runc-explaining-cve-2019-5736/
Accessed: 2026-08-14
Quote: runc breakout via `/proc/self/exe` overwrite from a malicious container image or `docker exec`

**brauner-privileged-containers**
URL: https://brauner.io/2019/02/12/privileged-containers.html
Accessed: 2026-08-14
Quote: runc "exits after spawning the container," making it attackable "through a malicious container image"; privileged container ≠ security boundary

**actions-runner-repo**
URL: https://github.com/actions/runner ; https://github.com/actions/runner/blob/main/LICENSE ; https://github.blog/changelog/2019-12-19-github-actions-the-runner-is-now-open-sourced/
Accessed: 2026-08-14
Quote: MIT-licensed, open-sourced Dec 19 2019, "we are not taking contributions... allocating resources towards other areas of Actions" (repo README, agent-relayed)

**actions-runner-hardening-docs**
URL: https://docs.github.com/en/actions/reference/security/secure-use ; https://docs.github.com/en/actions/concepts/security/compromised-runners ; https://docs.github.com/en/actions/reference/runners/self-hosted-runners
Accessed: 2026-08-14
Quote: "self-hosted runners should almost never be used for public repositories"; GitHub-hosted runners are "ephemeral and clean isolated virtual machines"

**tj-actions-incident**
URL: https://www.wiz.io/blog/github-action-tj-actions-changed-files-supply-chain-attack-cve-2025-30066 ; https://www.cisa.gov/news-events/alerts/2025/03/18/supply-chain-compromise-third-party-tj-actionschanged-files-cve-2025-30066-and-reviewdogaction
Accessed: 2026-08-14
Quote: compromised maintainer PAT used to retag `tj-actions/changed-files` to a malicious commit dumping runner memory into workflow logs, ~23,000+ repos exposed

**otel-collector-contrib**
URL: https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/CONTRIBUTING.md ; https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/docs/new-components.md
Accessed: 2026-08-14
Quote: contrib "houses a vast library of community-contributed components" vs. core "the standard distribution... lightweight and stable"; CODEOWNERS-based per-component ownership tier (agent-relayed, some paraphrase via secondary sources per subagent caveat)

**otel-ocb**
URL: https://opentelemetry.io/docs/collector/extend/ocb/
Accessed: 2026-08-14
Quote: manifest lists components by Go module path + version, drawn from core/contrib/any third-party module, compiled into one custom binary

**otel-component-stability**
URL: https://github.com/open-telemetry/opentelemetry-collector/blob/main/docs/component-stability.md
Accessed: 2026-08-14
Quote: Development/Alpha/Beta/Stable maturity ladder tracked per-signal; graduation requires named code-owner activity thresholds

**vscode-extension-host**
URL: https://code.visualstudio.com/api/advanced-topics/extension-host
Accessed: 2026-08-14
Quote: "VS Code aims to deliver a stable and high performance editor to users, and misbehaving extensions should not impact the user experience." (directly fetched and confirmed verbatim by research subagent)

**vscode-web-extensions**
URL: https://code.visualstudio.com/api/extension-guides/web-extensions
Accessed: 2026-08-14
Quote: web extensions run in a browser Web Worker inside the browser sandbox, same VS Code API, no Node.js APIs

**vscode-marketplace-separate**
URL: https://code.visualstudio.com/blogs/2025/11/18/privatemarketplace ; https://github.com/microsoft/vsmarketplace/discussions/211
Accessed: 2026-08-14
Quote: Private Marketplace GA (Nov 2025) lets orgs self-host a curated registry independent of the public gallery; marketplace terms restrict use to Microsoft products (motivating VSCodium/Open VSX)

**chromium-site-isolation**
URL: https://chromium.googlesource.com/chromium/src/+/main/docs/process_model_and_site_isolation.md ; https://css.csail.mit.edu/6.858/2017/readings/chromium.pdf
Accessed: 2026-08-14
Quote: extensions got dedicated process isolation via Site Isolation (Chromium M55); academic analysis found 70.4% of RCE-capable disclosed rendering-engine vulnerabilities would have been mitigated by this architecture

**chromium-mv3**
URL: https://chrome.jscn.org/docs/extensions/mv3/intro/mv3-overview/ ; https://blog.chromium.org/2024/05/manifest-v2-phase-out-begins.html
Accessed: 2026-08-14
Quote: MV3 constrains extension runtime capability (mandatory service workers, `declarativeNetRequest` vs. blocking `webRequest`) independent of store review

**ha-hacs-warning**
URL: https://ha-praksis.dk/en/what-is-hacs/ ; https://community.home-assistant.io/t/risks-involved-with-hacs/671049
Accessed: 2026-08-14
Quote: HA boot warning: "We found a custom integration hacs which has not been tested by Home Assistant. This component might cause stability problems, be sure to disable it if you experience issues."

**ha-hacs-security-disclosure**
URL: https://www.home-assistant.io/blog/2021/01/23/security-disclosure2/
Accessed: 2026-08-14
Quote: directory-traversal-class vulnerability disclosed in HACS itself, patched HACS 1.10.1 / HA Core 2021.1.5

**ha-hacs-safety-tradeoff**
URL: https://community.home-assistant.io/t/call-for-collaboration-home-assistant-safety-security-privacy/964086/29
Accessed: 2026-08-14
Quote: "HACS is not considered an appropriate foundation for safety-critical or guardrail-based guarantees... those same properties make it difficult to rely on HACS components for anything needing strong assurances around review or provenance."

**comfyui-security-policy**
URL: https://github.com/Comfy-Org/ComfyUI/security ; https://docs.comfy.org/registry/standards
Accessed: 2026-08-14
Quote: "custom nodes are arbitrary Python code and are trusted as much as any other software the user chooses to install"

**comfyui-cve**
URL: https://nvd.nist.gov/vuln/detail/CVE-2024-21576 ; https://thehackernews.com/2026/04/over-1000-exposed-comfyui-instances.html ; https://censys.com/blog/comfyui-servers-cryptomining-proxy-botnet/ ; https://labs.snyk.io/resources/hacking-comfyui-through-custom-nodes/
Accessed: 2026-08-14
Quote: CVE-2024-21576 (eval-based code injection in ComfyUI-Bmad-Nodes); 2026 internet-scale scanning campaigns against exposed ComfyUI instances

**npm-postinstall-incidents**
URL: https://linuxsecurity.com/features/npm-install-security-risk ; https://dev.to/pickuma/npm-supply-chain-attacks-why-they-keep-happening-and-how-to-defend-3dnf ; https://unit42.paloaltonetworks.com/npm-supply-chain-attack/ ; https://www.wiz.io/blog/shai-hulud-npm-supply-chain-attack
Accessed: 2026-08-14
Quote: lifecycle scripts run with full user/CI privilege "the intended design of the tool"; event-stream (2018), Shai-Hulud (2025) self-propagating worm via install-time execution

**npm-v12-scripts-off**
URL: https://semgrep.dev/blog/2026/rip-npm-postinstall-scripts-npm-v12-default-change/ ; https://www.infoq.com/news/2026/08/npm-12-released/ ; https://pnpm.io/supply-chain-security
Accessed: 2026-08-14
Quote: npm v12 flips `allowScripts` off by default; pnpm v10 (Jan 2025) blocks install scripts by default with `pnpm approve-builds` allowlist, `strictDepBuilds` hard-fail in v11

**deno-permissions**
URL: https://www.infoq.com/news/2026/08/npm-12-released/ (Deno comparison) ; general Deno permissions model
Accessed: 2026-08-14
Quote: Deno requires explicit `--allow-scripts=<pkg>` or persistent `deno approve-scripts`; permission model extends to runtime file/network/env access — a capability-based sandbox, not just an install-script gate

## SYNTHESIS

Two placements recur across every ecosystem that has actually solved this problem at scale, and a third placement recurs across every ecosystem with a documented incident.

**Pattern 1 — separately-governed runtime project, consumed by the product.** Terraform (go-plugin + wire protocol), Kubernetes (containerd/CNCF, runc/OCI), GitHub Actions (`actions/runner`), and OpenTelemetry (collector core, with contrib as a separately-CODEOWNERS'd companion) all place the trusted execution substrate in a project whose release cadence, governance, and security review are independent of the content it executes. In every one of these, the separation is not just architectural (a process boundary) but organizational (a different repo, different maintainers, sometimes a different foundation — CNCF vs. OCI are literally different Linux Foundation projects). The recurring justification, where documented, is never phrased as "the content team can't be trusted" — it's phrased as crash isolation, independent versioning, and enabling multiple/pluggable backends (CRI's stated goal was letting kubelet support many runtimes without recompiling, not a security statement per se). But the security payoff shows up empirically: when a compromise happens in these ecosystems (tj-actions/changed-files, CVE-2025-30066), it lands in the content layer, and the runtime/runner itself is unaffected — the boundary held exactly where it was supposed to.

**Pattern 2 — runtime owned by the product, but process-isolated from content; content distribution owned separately.** VS Code and Chromium/Firefox don't spin the runtime out into a separate governance body — the Extension Host ships in `microsoft/vscode`; the extension sandbox ships in Chromium. What IS separated is the content-distribution/review function (VS Code Marketplace, Chrome Web Store, AMO) from the product engineering org, and the isolation between runtime and content is enforced by a hard process/sandbox boundary (own OS process, own Web Worker, site-isolation-grade sandboxing) rather than by organizational separation. This works because the entity with governance authority over the runtime (the product vendor) is not the same entity publishing untrusted content (arbitrary third-party developers) — the content review team is a *different function*, but doesn't need to be a *different company* the way Terraform's provider ecosystem does, because VS Code/Chromium content authors have no claim to co-govern the runtime the way, say, a Terraform Community-tier provider author has no claim over go-plugin either. The key invariant shared with Pattern 1: the party publishing the content never has authority over the reference monitor.

**Pattern 3 — content and runtime share governance/execution, and every surveyed instance has a documented incident traceable to it.** Home Assistant integrations run in-process with core; HACS content (unofficial, but same execution privilege) has had a directory-traversal CVE with full-core blast radius, and Home Assistant's own team has explicitly and publicly disclaimed HACS as unsuitable for "safety-critical or guardrail-based guarantees" — i.e., the project's own maintainers recognize the shared-privilege model as a known limitation, not a design they'd extend to anything requiring assurance. ComfyUI is the sharper case: custom nodes run in-process AND are distributed through ComfyUI's own first-party registry (no even-nominal third-party distribution boundary), and this combination has produced multiple real RCE CVEs and ongoing internet-scale exploitation campaigns — ComfyUI's own security policy states plainly that custom nodes are "trusted as much as any other software the user chooses to install," an explicit acknowledgment that the project does not consider itself the reference monitor for its own registry's content. npm's postinstall-script model is the starkest version: no separate runtime layer mediates what an installed package's lifecycle script can do at all (full user/CI privilege by default) — and the entire 2018-2025 sequence of major npm supply-chain incidents (event-stream, ua-parser-js, colors/faker, tinycolor, debug/chalk, Shai-Hulud) exploited exactly that absence. The industry's own corrective motion (npm v12, pnpm, Bun all flipping to allowlist-only script execution; Deno's capability-based sandbox as the structurally cleanest fix) is itself evidence that "no separated reference monitor" was recognized industry-wide as the defect, arrived at independently by multiple ecosystems within about a year of each other (2025-2026).

**Answer to the PDPP question — where the runner should live.** PDPP's runner is closer to Pattern-1 territory than Pattern-2: it isn't just "a sandboxed process the product happens to own" (VS Code/Chromium), it does real reference-monitor work with teeth — spawning processes, constructing environment/credentials, handling secrets, writing to a durable outbox, and deciding what gets ingested into the product. That is a materially larger trust surface than "run this extension's JS in a Web Worker." It is architecturally and functionally the same *class* of component as go-plugin, containerd, or actions/runner: a thing that executes content authored by parties who should not have authority over the execution substrate itself. The security reviewer's argument — "the content-publishing repo must not govern its own reference monitor" — is exactly the invariant every Pattern-1 and Pattern-2 case preserves and every Pattern-3 case violates (with an incident to show for it). Two structural options both satisfy that invariant: (a) the runner lives in the product repo (PDPP-desktop-equivalent), analogous to VS Code/Chromium — acceptable IF the content repo (data-connectors) truly has zero commit/release authority over the runner, and the process/privilege boundary between runner and connector content is real (subprocess execution of connector code, not in-process `require`/`import` of connector modules into the runner's own address space); or (b) the runner lives in its own separately-governed project (Pattern 1), which is the *only* structurally sound option once you require the runner to also ship as a standalone device CLI (local-collector) with its own users, install base, and release cadence independent of the desktop product — this is precisely the shape GitHub Actions and OTel Collector solve (one runtime, multiple hosting/distribution contexts: GitHub-hosted vs. self-hosted runner from the same repo; core Collector embedded in many vendor distros from the same repo). Given local-collector already needs independent versioning/releases for its own install base, decoupled from both the content repo AND the desktop product's release cadence, Pattern 1 (separate hardened-runtime project, e.g. `pdpp-runner` or similar) is the better fit than folding the runner into either data-connectors (violates the reviewer's invariant directly) or the desktop product repo (couples local-collector's release cadence to desktop-product releases, which OTel/Actions precedent argues against — contrib-class content and core-class runtime benefit from decoupled cadence, and a device CLI even more so, since it must be independently patchable for a security fix without waiting on a desktop app release train). Recommend: split into (1) `data-connectors` — connector manifests/artifacts only, no execution authority, mirroring Terraform Registry Community/Partner content or OTel contrib; (2) a separately-governed runner project (own repo, own release cadence, own security review) that is a build-time/runtime *dependency* consumed by both the desktop product and the standalone local-collector CLI, mirroring go-plugin's cross-product reuse and OTel core's role as the thing multiple distros embed; (3) desktop product repo consumes the runner as a versioned dependency, the same relationship Terraform core has to go-plugin. Confidence: high on the general principle (governance separation prevents content from controlling its own reference monitor — this holds across every mature ecosystem surveyed with zero counterexamples once "mature" and "has a reference monitor with real privilege" are both true); medium on the specific repo-topology recommendation (3 repos vs. 2), since no single surveyed precedent has PDPP's exact "also ships as an independent end-user CLI" constraint simultaneously with "runner also needs tight product integration" — GitHub Actions runner and OTel Collector core are the closest fits for that specific combination, and both chose full separation, which is why that's the recommendation, but this is inference-by-analogy rather than a directly-cited case with PDPP's identical shape.
