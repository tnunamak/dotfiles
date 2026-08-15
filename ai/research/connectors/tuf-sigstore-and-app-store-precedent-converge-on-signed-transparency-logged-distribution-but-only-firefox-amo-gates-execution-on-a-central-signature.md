---
title: "TUF, Sigstore, and app-store/registry precedent converge on signed + transparency-logged distribution as the standard defense, but only Firefox AMO gates ALL execution (including self-distributed) on a central signature — every arbitrary-git-URL model (HACS, ComfyUI custom nodes) has documented real-world compromise incidents traceable to the absence of that gate"
date: 2026-08-14
topic: connectors
tags: [supply-chain-security, tuf, sigstore, code-signing, package-registries, extension-marketplaces, hacs, comfyui, terraform-registry, oci-cosign]
status: draft
sources: [tuf-spec, pypi-tuf-status, in-toto-tuf, uptane, sigstore-mechanics, npm-provenance, gh-attestations, sigstore-pseudonymous, sigstore-vs-tuf-cost, vscode-marketplace, firefox-amo-signing, obsidian-plugins, raycast-extensions, hacs-security, comfyui-malware, comfyui-response, terraform-registry-tiers, cosign-oci-generic, npm-terraform-lockfiles, npm-pypi-takedown, oauth-incremental-consent, chrome-permission-reconsent]
source_session: 90eda2e1-11b6-4c94-8c04-49c89508b2e4
---

## CLAIMS

### TUF (The Update Framework)

- TUF defines four core top-level roles: root (acts as the repository's CA, signs the other roles' public keys, must be distributed to clients out-of-band and kept offline), targets (signs metadata describing trusted artifacts, can delegate trust to auxiliary roles), snapshot (signs metadata about the latest version of all targets metadata, preventing mix-and-match attacks), and timestamp (frequently-signed, short-lived statement over the snapshot hash, preventing replay of stale-but-not-yet-expired metadata, kept online since compromise risk is minimal). [tuf-spec]
- TUF requires a THRESHOLD number of unique-keyid signatures per role; a client MUST NOT count more than one verified signature from the same keyid toward a role's threshold, even if that keyid is listed multiple times. [tuf-spec]
- TUF's compromise-resilience design principle: different metadata is signed by different roles so a single compromised key does not compromise the whole repository, and revocation of a compromised key is handled by having the root role re-sign metadata to replace it (or, if root keys are themselves compromised past threshold, the root file must be reissued out-of-band). [tuf-spec]
- PEP 458 ("minimum security model": PyPI signs with keys it holds) has been in development for roughly a decade; the concrete PyPI-facing tooling is the Repository Service for TUF (RSTUF), whose `repository-service-tuf` PyPI package was still at a beta pre-release (1.0.0b1, April 2025) with no confirmed stable 1.0 as of the most recent public release found. [pypi-tuf-status]
- PEP 480 ("maximum security model": end-to-end signing where developers also sign, protecting against a PyPI-itself compromise) remains an unadopted draft extension to PEP 458. [pypi-tuf-status]
- PyPI's actual shipped 2024–2026 security advancement is a separate, lighter mechanism: digital attestations (Sigstore-based, described further below), not full TUF metadata signing. [pypi-tuf-status]
- Uptane extends TUF for automotive OTA with a "Separation of Trust" model (Image Repository, Director Repository, Primary ECU, Secondary ECUs); it is in production use securing OTA updates for at least one major US automaker and is referenced by UNECE WP.29 R155 (mandatory connected-vehicle cybersecurity regulation). Open implementations include aktualizr, rust-tuf, and ota-tuf (Scala); commercial offerings exist from HERE Technologies and Airbiquity. [uptane]
- Docker Content Trust (built on TUF + Notary v1, launched 2015) is now largely abandoned in practice: Notary is no longer actively maintained, and fewer than 0.05% of Docker Hub pulls use DCT as of the source's reporting. [sigstore-vs-tuf-cost]

### in-toto + TUF composition

- in-toto adds supply-chain step attestation: a "layout" specifies the expected sequence of pipeline steps (build, test, package, sign), and in-toto verifies that per-step "link" metadata matches that layout — answering "was each build step performed by an authorized party, correctly" — whereas TUF secures distribution of the already-produced artifact (does the registry serve what it claims, resistant to key compromise, rollback, and mix-and-match). The two are described as complementary, operating at different layers. [in-toto-tuf]
- TUF is used specifically to distribute and rotate in-toto's root layout public keys in a compromise-resilient way: only one root metadata file needs to reach client applications, and keys throughout the system (in-toto layouts and functionaries) can be rotated without clients noticing. [in-toto-tuf]
- in-toto graduated CNCF in 2023, alongside TUF (graduated) and Sigstore, and Datadog is cited as a concrete production case combining TUF's distribution model with in-toto's attestations to secure publication of Datadog Agent Integrations. [in-toto-tuf]

### Sigstore ecosystem

- Sigstore's keyless flow: the signer authenticates via OIDC (GitHub Actions workload identity, or an individual's Google/GitHub login for non-CI use), Fulcio validates the OIDC token and issues a short-lived (~10–20 minute) X.509 certificate binding an ephemeral keypair to the verified identity, the artifact is signed with that ephemeral key, the signature+cert+digest are recorded in Rekor (an append-only, publicly auditable transparency log providing inclusion and consistency proofs), and the ephemeral private key is then discarded. Rekor's log entry is the durable evidence checked at verification time, since the cert itself expires in minutes. [sigstore-mechanics]
- Sigstore's own root of trust (Fulcio's root CA cert, Rekor's public key) is itself distributed via TUF — i.e., Sigstore is built on top of TUF rather than a replacement for it. [sigstore-mechanics]
- npm provenance attestations (`npm publish --provenance`, and automatically via GitHub/GitLab trusted publishing since GA July 2025) are signed by Sigstore public-good infrastructure and logged to Rekor; the provenance predicate captures builder identity, build instructions/parameters, environment variables, and dependency digests via in-toto attestations in a DSSE envelope. `npm audit signatures` verifies registry signatures and provenance attestations for installed packages, but verification is NOT enforced at install time by default — nothing stops installing a version that lacks provenance — and the signature chain trusts the registry's own signing infrastructure, so registry-side compromise or stolen publish credentials still produce a cleanly-verifying signature. Provenance is not generated for CircleCI-based publishing or for private repositories. [npm-provenance]
- GitHub artifact attestations (`actions/attest-build-provenance`, now a thin wrapper over `actions/attest`) bind an artifact (path/digest/checksum-file) to a SLSA build-provenance predicate in in-toto format, signed via a short-lived Sigstore cert (public-good instance for public repos, GitHub's private Sigstore instance for private/internal repos), and upload it to GitHub's attestations API tied to the originating repo. Verification is via `gh attestation verify PATH -o org`; the tool authors explicitly note generating attestations without verifying them provides no security benefit. Available on public repos for all current plans; private/internal repos require GitHub Enterprise Cloud. [gh-attestations]
- Sigstore explicitly supports pseudonymous, non-CI individual signers: a person can register a Google account under a pseudonym and sign with that identity via interactive OIDC login rather than a CI workload-identity token; Sigstore's own privacy documentation frames this as letting users "prove the person who signed a package today is the same as last week" without managing a keypair, at the cost of full anonymity (identity is pseudonymous, not anonymous — it's tied to an OIDC account). [sigstore-pseudonymous]
- The Sigstore-vs-TUF adoption tradeoff is explicitly framed in the ecosystem's own writing as an 80/20-style tradeoff: Sigstore trades some of TUF's formal compromise-resilience guarantees (which assume a threat model where all online servers/keys could be compromised) for dramatically lower key-management overhead, and is credited as one of the fastest-adopted open-source security projects (4M+ logged signatures cited), versus GPG signing's three decades of low uptake. TUF's own documentation is cited as saying standalone TUF repositories are best suited to "low to moderate frequency of change" for both artifacts and keys — i.e., a heavier operational fit for slow-moving repos, not necessarily a small project with frequent releases and few maintainers. [sigstore-vs-tuf-cost]

### Marketplace / extension-store models

- VS Code Marketplace publisher verification (blue checkmark) only certifies that the publisher proved ownership of *some* domain for 6+ months in good standing — the domain need not be relevant to the extension. Multiple security researchers (AquaSec, ExtensionTotal, Wiz) independently concluded the badge is a weak trust signal. Malware scanning does run at publish time via multiple AV engines and blocks publication until clear, plus post-publish monitoring (unusual usage, name-squatting detection, blocklist/removal). [vscode-marketplace]
- Documented VS Code Marketplace incidents: AquaSec's 2023 PoC extension reached 1,500+ installs in 48 hours; a 2024 NJCCIC scan found 1,283 extensions with known malicious code (229M cumulative installs), 8,161 talking to hardcoded IPs, 2,304 claiming another publisher's GitHub repo; ExtensionTotal found 10 malicious extensions in 2025 sharing identical code/C2 infrastructure across different claimed authors, one being "Rust Compiler for VSCode"; Microsoft's own 2025 transparency figures cite 136 reviewed, 110 removed; TigerJack published 11+ malicious extensions infecting 17,000+ developers (spyware/cryptominers/backdoors), two of which remained live on Open VSX months after Microsoft's removal; Wiz Research (2025) found 100+ cases of leaked publisher access tokens across VS Code Marketplace and Open VSX capable of pushing malicious auto-updates to as many as 150,000 cumulative installs (VS Code auto-updates extensions by default). 2026 activity includes GlassWorm, WhiteCobra, and "susvsex" campaigns. [vscode-marketplace]
- Firefox AMO requires that ALL extensions capable of running in release/beta Firefox be signed by Mozilla — this applies both to publicly listed AMO extensions and to self-distributed ("unlisted") extensions; there is no path to running an extension in stock Firefox release/beta without passing through Mozilla's signing infrastructure (bypass exists only in Developer Edition/Nightly/ESR via an about:config flag). Unlisted (self-distributed) submissions go through automated review (typically completing in seconds) and are auto-signed if they pass; listed AMO extensions may additionally get manual human code review, which can take hours to weeks depending on complexity. Both signed categories remain subject to later manual re-review by Mozilla's review team even after signing. [firefox-amo-signing]
- Firefox's signing mechanism: an XPI's per-file hashes are collected into a manifest, and that manifest is what's cryptographically signed (via Mozilla's internal Autograph service) — i.e., it is a package-integrity signature gate, layered with an automated (and sometimes manual) policy-compliance review, not solely a rubber-stamp scan. [firefox-amo-signing]
- Obsidian's community plugin ecosystem historically relied on light manual initial review plus community reporting, with no runtime sandbox — plugins inherit Obsidian's full access level (filesystem, network, arbitrary program execution) with no permission restriction possible. In May 2026, Obsidian shipped an overhaul ("Community" hub) adding automated per-version code-quality/security/malware scanning and public "scorecards," processing a backlog of 2,300+ queued submissions; manual review continues for popular/flagged plugins; older plugins failing new checks get temporary exceptions before possible removal. [obsidian-plugins]
- A documented 2026 incident (PHANTOMPULSE RAT, tracked as REF6598 by Elastic) abused Obsidian's legitimate Shell Commands and Hider community plugins as an execution vector, delivered via social engineering (shared vault + prompt to enable "sync installed community plugins") rather than a backdoored plugin release; the intrusion was reportedly detected and blocked before attacker objectives were achieved, and some researchers pushed back on framing it as a "malicious plugin" incident since it required the user to actively bypass multiple safety warnings. Obsidian's response added expanded privacy/capability disclosure labels (network, filesystem, clipboard access) to its new scorecards. [obsidian-plugins]
- Raycast extensions are 100% open-source and distributed via a GitHub monorepo + pull-request workflow: `npm run publish` opens a PR, automated CI validates manifest schema/assets/author/build, then Raycast staff and community members do human review (often multiple feedback rounds) before merge auto-publishes to the store. Raycast enforces a single-latest-version model (no historical version pinning by end users) and applies automatic background updates to store-installed extensions. [raycast-extensions]

### Custom-repo / arbitrary-git-URL models and failure modes

- HACS (Home Assistant Community Store) lets a user add any GitHub repository URL as a custom repository via a UI action (3-dot menu → paste URL → select type → Add); HACS performs no vetting, endorsement, or safety review of custom repositories — the docs' framing is that provenance transparency (a link to the original repo) substitutes for any trust gate. Custom integrations installed this way run with full Home Assistant process privilege. [hacs-security]
- GitHub's own security research team, auditing Home Assistant core, explicitly flagged HACS-distributed community integrations as out of scope for their review and warned users that such integrations "will have complete access to your Home Assistant installation, and any vulnerabilities in them could compromise your system." [hacs-security]
- Concrete incidents: in January 2021 Home Assistant disclosed a directory-traversal vulnerability in HACS itself (unauthenticated webview) allowing access to any file readable by the Home Assistant process, including stored credentials; a nearly identical second disclosure followed one day later affecting other custom integrations. In some cases the Home Assistant team could not reach the affected integrations' authors and had to advise users to simply remove them — illustrating no guaranteed maintenance/responsiveness in the community-repo model. [hacs-security]
- ComfyUI: in June 2024, a custom node ("ComfyUI_LLMVISION," distributed via a Reddit post) was found to contain code stealing browser passwords, credit card data, browsing history, and crypto wallets, exfiltrating to an attacker-controlled Discord webhook via a multi-stage attack (malicious code hidden inside disguised OpenAI/Anthropic library "updates," triggering encoded PowerShell to fetch further-stage malware). [comfyui-malware]
- A second, later incident reached the official Comfy Registry itself (not just community Reddit distribution): the node "EliseiBorisov/ComfyUI-Upscaler-4K" masqueraded as an image-upscaling tool while installing the "Akira Stealer" (obfuscated via Caesar shift, Base64, and LZMA-compressed Golang binary) targeting browser data, crypto wallets, and Discord tokens; researchers estimated up to 779 possible infections. [comfyui-malware]
- ComfyUI's/Comfy-Org's response: built AI + static-analysis scanning infrastructure alerting a private security channel after the first incident; announced a staged registry-restriction rollout specifically targeting `eval`/`exec` calls (block incremental additions within 1 month, block ALL public nodes using them within 3 months) and runtime `pip install` calls (block incremental additions immediately, block all published nodes calling it within 6 months), plus warnings/blocking for code-obfuscation patterns. ComfyUI Manager separately ships a client-side `security_level` setting (default "normal") that blocks installing unverified third-party git repos unless downgraded to "weak," plus a `security_check.py` that actively matches known-malicious node signatures and halts ComfyUI execution with remediation instructions if detected. A 2026 CVE was later found in the Manager's own config-handling (HTTP query-parameter injection into `config.ini`) that could tamper with these very security settings remotely on `--listen`-exposed instances. [comfyui-response]

### Registry models with trust tiers

- Terraform Provider Registry uses three tiers: Official (HashiCorp-authored), Partner (third-party org, went through HashiCorp's formal Partner onboarding/vetting program, can additionally earn a stricter "Partner Premier" badge), and Community (individual contributor, no vetting beyond the technical requirements). [terraform-registry-tiers]
- GPG signing is a universal technical requirement across ALL three tiers — every provider release must be signed with a registered RSA or DSA key (ECC not accepted); the Registry validates the signature at publish time, and `terraform init` validates it again at consumption time. Signing is necessary-but-not-sufficient: it proves integrity/non-tampering, not vetting — the Partner/Community distinction is purely a badge/vetting-process label layered on top of a uniform signing baseline. [terraform-registry-tiers]
- cosign has grown beyond container images into a general OCI-artifact signing tool: it can sign/verify anything storable in an OCI registry (Helm charts, Tekton pipelines, SBOMs as standalone files or in-registry objects, Kubernetes/GitOps config bundles via Flux, arbitrary binaries/scripts), with a companion `sget` for fetching+auto-verifying arbitrary OCI-distributed files by digest. Cosign's own maintainers speculate TUF repositories themselves would be a plausible thing to store/sign this way. Tested against most major registries (ECR, GCP Artifact Registry, Docker Hub, ACR, Artifactory, GitLab, GHCR, Harbor, DigitalOcean, Nexus, Alibaba Cloud). [cosign-oci-generic]

### Lockfiles / pinning as the auto-update circuit-breaker

- npm's `package-lock.json` stores a per-package integrity hash, checked on install. The critical distinction for preventing *silent* malicious updates is `npm ci` versus `npm install`: `npm ci` treats the lockfile as authoritative, refuses to modify it, and fails if a lockfile hash doesn't match — `npm install` can silently update the lockfile to a newer published version with no human review gate. [npm-terraform-lockfiles]
- Terraform's `.terraform.lock.hcl` records exact provider versions plus dual hashes (`h1:`, `zh:`) per platform, generated/updated by `terraform init`. Critically, plain `terraform init` CAN silently rewrite the lock file if a module's version constraint is loose (e.g. `> 5.58.0`), even with a lockfile present — the equivalent of `npm ci`'s strict behavior is the separate `-lockfile=readonly` flag, which must be explicitly added (e.g. in CI) to fail instead of silently drifting. Terraform can also surface the signing-key fingerprint used for a provider's checksums at `init` time for the user to manually vet. [npm-terraform-lockfiles]

### Post-hoc revocation precedent

- npm's unpublish policy (shaped by the 2016 left-pad incident): package versions under 24 hours old can be freely unpublished by the author; older versions require npm support intervention, which checks for dependents and generally refuses removal if any exist. If every version of a package name is removed, npm replaces it with a permanent "security placeholder" package specifically to block malicious name-squatting reuse of the freed name. npm has since added publish-time malware scanning that can block a package from ever becoming installable, with an appeal path for the publisher. [npm-pypi-takedown]
- PyPI's non-destructive "yanking" (PEP 592) is the primary security-takedown mechanism: a yanked release is skipped by dependency resolvers unless a user pins to that exact version (`==`/`===`), in which case it still installs with a warning — this preserves reproducibility for already-pinned consumers while stopping new adoption. True deletion is permanent (version number burned forever, never reusable) and reserved for rare cases; this permanence was also a direct response to the left-pad incident. [npm-pypi-takedown]

### Permission re-consent precedent

- Chrome extensions: an update is only auto-applied silently if new permissions fall into already-granted "permission warning" categories (a granular grading system, not literal permission-string equality); if the new permissions produce a materially different warning, Chrome disables the extension until the user explicitly re-approves the new permission set. Cross-device sync special-case: if a device previously approved the increased permission via sync, the extension is not re-disabled on that new device. [chrome-permission-reconsent]
- Google OAuth uses "incremental authorization": apps request only the scopes needed at a given moment and prompt for additional scopes later, in context, when a feature actually needs them — Google's own policy explicitly requires this ("ask for scopes in context... provide a justification to the user before requesting") and forbids silently re-requesting a scope the user previously denied without a fresh, feature-triggered user action. Multi-scope consent screens are not all-or-nothing: users can grant a subset, and well-behaved apps must check which scopes were actually granted rather than assuming full grant. The consent screen re-appears specifically when new scopes are requested (or access was revoked) — otherwise it's skipped on repeat logins. [oauth-incremental-consent]

## SOURCES

**tuf-spec**
URL: https://theupdateframework.github.io/specification/latest/ (and https://theupdateframework.io/docs/security/, https://theupdateframework.io/docs/faq/)
Accessed: 2026-08-14
Quote: "Each SIGNATURE which is counted towards the THRESHOLD MUST have a unique KEYID... a client MUST NOT count more than one verified SIGNATURE from that KEYID towards the THRESHOLD" (agent paraphrase of spec via search synthesis)

**pypi-tuf-status**
URL: https://peps.python.org/pep-0458/ ; https://peps.python.org/pep-0480/ (draft) ; https://pypi.org/project/repository-service-tuf/ ; https://blog.pypi.org/posts/2026-07-22-ui-updates/
Accessed: 2026-08-14
Quote: "repository-service-tuf... latest version was 1.0.0b1, a pre-release from April 30, 2025" (agent summary of PyPI package page, relayed via search; not independently re-fetched)

**in-toto-tuf**
URL: https://qconnewyork.com/presentation/jun2023/securing-software-supply-chain-how-toto-and-tuf-work-together-combat-supply ; https://www.cncf.io/blog/2023/08/17/unleashing-in-toto-the-api-of-devsecops/ ; https://hackmd.io/@colek42/H1Ub7g4e3
Accessed: 2026-08-14
Quote: "in-toto extends TUF to verify that each step in a software supply chain was performed by an authorized party... TUF ensures distribution integrity within a single repository" (agent summary relayed via search, not independently re-fetched)

**uptane**
URL: https://uptane.org/docs/1.0.0/standard/uptane-standard ; https://docs.ota.here.com/ota-client/latest/uptane.html ; https://uptane.org/blog/2024/02/26/Get-Started-With-Uptane
Accessed: 2026-08-14
Quote: "Uptane is the current industry standard for secure Over-the-Air (OTA) updates, extending The Update Framework (TUF) to the automotive context" (agent paraphrase relayed via search)

**sigstore-mechanics**
URL: https://docs.sigstore.dev/cosign/signing/overview/ ; https://docs.sigstore.dev/about/faq/
Accessed: 2026-08-14
Quote: "Fulcio verifies that OIDC token and issues a short-lived X.509 certificate... that binds the ephemeral public key to the verified identity" (agent summary relayed via search)

**npm-provenance**
URL: https://docs.npmjs.com/generating-provenance-statements/ ; https://docs.npmjs.com/trusted-publishers/ ; https://github.blog/security/supply-chain-security/introducing-npm-package-provenance/
Accessed: 2026-08-14
Quote: "the audit signatures command will also verify the provenance attestations of downloaded packages... this is not enforced at install time" (agent paraphrase relayed via search)

**gh-attestations**
URL: https://github.com/actions/attest-build-provenance ; https://docs.github.com/actions/security-for-github-actions/using-artifact-attestations/using-artifact-attestations-to-establish-provenance-for-builds
Accessed: 2026-08-14
Quote: "Generating attestations alone doesn't provide any security benefit — the attestations must be verified for the benefit to be realized" (agent paraphrase relayed via search)

**sigstore-pseudonymous**
URL: https://blog.sigstore.dev/privacy-in-sigstore-57cac15af0d0/
Accessed: 2026-08-14
Quote: "continuity lets you prove the person who signed a package today is the same as last week without managing a key pair yourself... Users can register a Google account under a pseudonym, and use that to publish artifacts" (agent paraphrase relayed via search)

**sigstore-vs-tuf-cost**
URL: https://blog.sigstore.dev/signatus-ergo-securus-who-can-sign-what-with-tuf-and-sigstore-ea4d3d84b8b6/ ; https://www.linuxfoundation.org/blog/blog/adopting-sigstore-incrementally
Accessed: 2026-08-14
Quote: "the optimal use case is TUF repositories with a low to moderate frequency of change, both for artifacts and keys" ; "fewer than 0.05% of Docker Hub image pulls use DCT" (agent paraphrase relayed via search)

**vscode-marketplace**
URL: https://www.bleepingcomputer.com/news/microsoft/vscode-marketplace-can-be-abused-to-host-malicious-extensions/ ; https://developer.microsoft.com/blog/security-and-trust-in-visual-studio-marketplace/ ; https://www.wiz.io/blog/supply-chain-risk-in-vscode-extension-marketplaces
Accessed: 2026-08-14
Quote: "the verification badge on the platform means next to nothing, as any publisher that has bought any domain gets the blue tick... the domain doesn't even have to be relevant to the software project" (agent paraphrase relayed via search)

**firefox-amo-signing**
URL: https://extensionworkshop.com/documentation/publish/signing-and-distribution-overview/ ; https://extensionworkshop.com/documentation/publish/self-distribution/
Accessed: 2026-08-14
Quote: "Extensions... need to be signed by Mozilla in order for them to be installable in release and beta versions of Firefox" ; "For unlisted add-ons, files submitted for signing go through an automated review process. If they pass this review, they are automatically signed" (agent paraphrase relayed via search)

**obsidian-plugins**
URL: https://obsidian.md/blog/future-of-plugins/ ; https://thehackernews.com/2026/04/obsidian-plugin-abuse-delivers.html ; https://gigazine.net/gsc_news/en/20260513-obsidian-plugin-future/
Accessed: 2026-08-14
Quote: "due to technical limitations, Obsidian cannot reliably restrict plugins to specific permissions or access levels, meaning plugins inherit Obsidian's access levels" (agent paraphrase relayed via search)

**raycast-extensions**
URL: https://developers.raycast.com/basics/publish-an-extension ; https://developers.raycast.com/basics/review-pullrequest
Accessed: 2026-08-14
Quote: "members from Raycast and the community collaboratively review extensions, following the store guidelines" (agent paraphrase relayed via search)

**hacs-security**
URL: https://www.hacs.xyz/docs/faq/custom_repositories/ ; https://www.home-assistant.io/blog/2021/01/22/security-disclosure/ ; https://github.blog/security/vulnerability-research/securing-our-home-labs-home-assistant-code-review/
Accessed: 2026-08-14
Quote: "they will have complete access to your Home Assistant installation, and any vulnerabilities in them could compromise your system" (agent paraphrase relayed via search, attributed to GitHub security research team review of Home Assistant)

**comfyui-malware**
URL: https://hackread.com/comfyui-malicious-node-steal-crypto-browser-data/ ; https://github.com/Comfy-Org/ComfyUI/issues/11791
Accessed: 2026-08-14
Quote: "the 'ComfyUI_LLMVISION' node, disguised as a helpful extension, contained code designed to steal sensitive user information, including browser passwords, credit card details, and browsing history" (agent paraphrase relayed via search)

**comfyui-response**
URL: https://blog.comfy.org/p/comfyui-2025-jan-security-update ; https://docs.comfy.org/manager/troubleshooting
Accessed: 2026-08-14
Quote: "within 1 month they would block incremental changes adding 'eval' and 'exec' calls to custom nodes, and within 3 months... block all public nodes using them" (agent paraphrase relayed via search)

**terraform-registry-tiers**
URL: https://developer.hashicorp.com/terraform/registry/providers ; https://spacelift.io/blog/terraform-registry
Accessed: 2026-08-14
Quote: "The Terraform Registry requires that all provider releases are signed with a GPG key... The Terraform Registry API accepts both RSA and DSA keys, but not the default ECC type" (agent paraphrase relayed via search)

**cosign-oci-generic**
URL: https://docs.sigstore.dev/cosign/signing/other_types/ ; https://github.com/sigstore/cosign
Accessed: 2026-08-14
Quote: "cosign can sign anything in a registry... Helm Charts, Tekton Pipelines, and anything else currently using OCI registries for distribution" (agent paraphrase relayed via search)

**npm-terraform-lockfiles**
URL: https://developer.hashicorp.com/terraform/language/files/dependency-lock ; https://medium.com/node-js-cybersecurity/lockfile-poisoning-and-how-hashes-verify-integrity-in-node-js-lockfiles-0f105a6a18cd
Accessed: 2026-08-14
Quote: "npm ci reads the lockfile as the authoritative source of truth... it does not update the lockfile, fails immediately if the lockfile is absent or inconsistent" ; "Plain terraform init can silently rewrite the lock file" if constraints are loose (agent paraphrase relayed via search)

**npm-pypi-takedown**
URL: https://docs.npmjs.com/policies/unpublish/ ; https://docs.pypi.org/project-management/yanking/
Accessed: 2026-08-14
Quote: "if every version of a package name is removed, npm will drop-in a placeholder package to keep future users from unknowingly referencing a potentially malicious replacement" ; "a yanked release is always ignored by an installer, unless it is the only release that matches a version specifier" (agent paraphrase relayed via search)

**oauth-incremental-consent**
URL: https://developers.googleblog.com/2021/10/granular-google-account-update.html ; https://developers.google.com/identity/protocols/oauth2/policies
Accessed: 2026-08-14
Quote: "you may only request a new authorization for a denied scope after the user clearly indicates an intent to use that feature... ask for scopes in context with incremental authorization and provide a justification to the user before requesting authorization" (agent paraphrase relayed via search)

**chrome-permission-reconsent**
URL: https://chromium.googlesource.com/chromium/src/+/main/extensions/docs/permissions.md ; https://developer.chrome.com/docs/extensions/develop/concepts/permission-warnings
Accessed: 2026-08-14
Quote: "if an extension adds new permissions but all of those permissions are either messageless or collapsed into already-granted permissions, then the extension is not disabled. Otherwise, Chrome considers it a privilege increase and disables it" (agent paraphrase relayed via search)

## SYNTHESIS

Cross-cutting pattern across every ecosystem surveyed: **signing proves the artifact wasn't tampered in transit; it does not prove the artifact is safe to run.** Every "signed" system here (npm provenance, GitHub attestations, Terraform's GPG requirement, HACS's implicit trust-the-link model) answers "did this come from the identity it claims" — a supply-chain-integrity question — while separately, and much more weakly across the board, ecosystems try to answer "is the content itself malicious" via runtime scanning (VS Code AV scan, ComfyUI's eval/exec restrictions, Obsidian's new malware scorecards). PDPP's threat model (compromised connector = credential theft) needs both, and the survey shows most incumbents under-invest in the second.

The single clearest signal in this research: **Firefox AMO is the only ecosystem surveyed that makes signing a hard execution gate with no exceptions** (not even for self-distributed/sideloaded extensions in release Firefox) — and it is also the ecosystem with the fewest publicly documented malware incidents in this survey, though that may partly reflect Firefox's smaller install base versus Chrome rather than the gate alone. Every ecosystem that allows install-without-central-gate — VS Code (any publisher can push straight to Marketplace), HACS (paste any GitHub URL), ComfyUI (custom nodes/git URLs, pre-2025 registry), Obsidian pre-May-2026 — has a documented real-world compromise. The severity also scales with the sensitivity of what's reachable: VS Code/ComfyUI incidents stole browser passwords and crypto wallets specifically because the plugin ran with the host's full privilege, which is structurally identical to PDPP's threat model (connector reaches credentials/OAuth tokens because there's no OS-level jail).

Second pattern: registries that DO have tiers (Terraform Official/Partner/Community, TUF's role separation) treat vetting-tier and cryptographic-integrity as orthogonal axes — GPG/TUF signing is a uniform floor applied to every tier, and the tier label is a separate, human-process signal layered on top. This maps cleanly onto a PDPP official/verified/unverified trust-tier design: don't make signing itself the differentiator between tiers, make review/vetting depth the differentiator, with signing required at every tier as the floor.

Third, on cost: full custom TUF (own root/targets/snapshot roles, offline root key ceremony, threshold signing infra) is real operational weight that even PyPI — with the funding and multi-year runway of the PSF plus dedicated OpenSSF grant work — has not fully shipped after roughly a decade of PEP 458 effort (RSTUF still beta as of the most recent data found). Sigstore, by contrast, reached GA-quality adoption across PyPI, npm, and Maven Central within roughly 2020-2025, precisely because it externalizes root-of-trust maintenance (Sigstore's own TUF-distributed root) and substitutes OIDC-identity-proof for local key custody. For a project at PDPP's scale, standing up bespoke TUF is very likely not proportionate; a Sigstore-based (or Sigstore-compatible OCI+cosign) approach gets most of the same practical protection — signed, timestamped, publicly-auditable provenance resistant to silent tampering — without the root-key-ceremony operational burden. The caveat: Sigstore's OIDC-identity model assumes signers can authenticate via a supported IdP (GitHub/Google/etc.) through either CI workload identity or interactive login; a fully anonymous author (no persistent identity at all) cannot participate, which is a deliberate design tradeoff, not a bug, and is directly relevant to PDPP's "pseudonymous third-party connector author" scenario — it is well-supported (pseudonymous OIDC identity is an explicitly designed use case) but does assume the third-party repo owner sets up at least a lightweight CI or is willing to sign in interactively per release, which is friction beyond zero but far below "run your own root-key ceremony."

Fourth, on lockfiles: the `npm ci` vs `npm install` and `terraform init` vs `-lockfile=readonly` distinction generalizes to a hard rule — **a lockfile without a strict/pinned-only enforcement mode does not actually stop silent auto-updates**; the loose mode (`install`, plain `init`) will happily rewrite the lock file to a newer, unreviewed version the moment constraints allow it. Any PDPP lockfile design must default to (or only offer) the strict mode for connector installs — auto-update should never silently rewrite a pin without an explicit user or app action, mirroring `npm ci`'s "fail rather than drift" posture.

Fifth, on revocation: both major package registries converged on **non-destructive, forward-only revocation** (PyPI's yank, npm's unpublish-with-dependent-check-and-permanent-placeholder) rather than silent deletion, specifically because 2016's left-pad incident taught the industry that deletion breaks the dependency graph for good-faith downstream consumers. A Rekor-style transparency log is a good fit for PDPP's revocation story because it gives an append-only, publicly-checkable record of exactly which artifact digests were signed and when — a revocation list checked at launch (blocklist of digests/versions) layered on top of that log is the direct analog to npm's placeholder-package mechanism, preventing both "quietly keep running the bad version" and "attacker reuses the freed name/version slot."
