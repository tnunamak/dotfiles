---
title: "Terraform Registry, krew, and Homebrew's formulae.brew.sh model multi-version/multi-platform registry indexes with materially different signing and deprecation shapes, informing PDPP's v1 index schema"
date: 2026-08-14
topic: connectors
tags: [registry-protocol, wire-format, terraform-registry, krew, homebrew, versioning, signing, deprecation]
status: draft
sources: [terraform-discovery, terraform-versions, terraform-download, krew-manifest, homebrew-formula, homebrew-deprecated]
source_session: 6f87cffc-37f4-4e31-ba75-15ceb54ab22a
---

## CLAIMS

- Terraform Registry uses a `.well-known/terraform.json` service-discovery document mapping `"&lt;service&gt;.v&lt;N&gt;"` keys (e.g. `modules.v1`, `providers.v1`) to base API paths, allowing new API versions to be added as additional keys without breaking old clients. [terraform-discovery]
- Terraform's `GET /v1/providers/{namespace}/{type}/versions` returns a flat `versions[]` array; each entry has its own `version`, `protocols[]` (provider RPC protocol compatibility, not registry schema version), and its own `platforms[]` array of `{os, arch}` pairs — so platform availability can differ per version. [terraform-versions]
- Terraform's per-platform download endpoint (`/v1/providers/.../download/{os}/{arch}`) returns `download_url`, `shasum` (single artifact digest), `shasums_url` (full SHA256SUMS manifest), `shasums_signature_url` (detached GPG signature over that manifest), and `signing_keys.gpg_public_keys[]` with `key_id`, inline `ascii_armor`, and a `source`/`source_url` attribution field. [terraform-download]
- Terraform's module registry protocol includes a `"deprecation": null` field per version (populated with a deprecation object when set); the provider registry protocol has no such field at all — provider deprecation is handled outside the wire schema. [terraform-versions]
- krew's plugin manifest (`apiVersion: krew.googlecontainertools.github.com/v1alpha2`, `kind: Plugin`) models exactly ONE version per file (`spec.version` is a scalar, not an array) — there is no multi-version history in the index; old versions are not installable via the index at all. [krew-manifest]
- krew models platform variants via `spec.platforms[]`, each entry pairing a Kubernetes-style `selector` (`matchLabels: {os, arch}` or list-based `matchExpressions`) with its own `uri`, inline `sha256`, `bin` (executable name, can vary e.g. Windows `.exe`), and optional `files[]` extraction rules. [krew-manifest]
- krew has no signing mechanism beyond the inlined sha256 per platform entry — trust is rooted entirely in GitHub PR review of the krew-index repo plus HTTPS to the release host, with no GPG/sigstore/cosign reference anywhere in the manifest schema. [krew-manifest]
- krew has no deprecation/removal field in its schema; plugin removal is a pure git deletion of the YAML file from the index repo (this specific absence is stated with medium confidence — the lifecycle doc page 404'd and a targeted GitHub issue search found nothing, but no exhaustive repo-wide search was done). [krew-manifest]
- Homebrew's `formulae.brew.sh/api/formula/<name>.json` is a single flat per-formula document, not a version-history list — `versions.stable`/`versions.head` are the only version strings; historical versions live only in tap git history or as separately-named sibling formulae (e.g. `wget@1.20`). [homebrew-formula]
- Homebrew's `bottle.stable.files` is a map keyed by platform tag (e.g. `arm64_tahoe`, `arm64_sequoia`, `arm64_linux`, `x86_64_linux`) — macOS codename+arch or generic Linux+arch — each value `{cellar, url, sha256}`; bottles are distributed as OCI blobs on GHCR (`root_url: https://ghcr.io/v2/homebrew/core`). [homebrew-formula]
- Homebrew has no GPG/signature field in its formula API; trust is rooted in SHA256 content-addressing of the OCI blob plus a `ruby_source_checksum.sha256` hash of the build recipe itself and `tap_git_head` (git commit of the tap at build time) — no detached signature or key-ID field exists. [homebrew-formula]
- Homebrew implements a two-stage soft-then-hard deprecation lifecycle with exact field names: `deprecated` (bool), `deprecation_date`, `deprecation_reason`, `deprecation_replacement_formula`/`_cask` (soft — still installs, warns); and separately `disabled`, `disable_date`, `disable_reason`, `disable_replacement_formula`/`_cask` (hard — refuses to install), each independently settable with its own future date. [homebrew-deprecated]
- None of the three systems expose an explicit top-level schema-version field for the index/API document itself (Terraform's discovery-doc key suffix `.v1` is the closest analog; Homebrew and krew have no equivalent for their JSON/YAML document shape, only for the plugin/formula's own version). [terraform-discovery] [krew-manifest] [homebrew-formula]

## SOURCES

**terraform-discovery**
URL: https://registry.terraform.io/.well-known/terraform.json ; https://developer.hashicorp.com/terraform/internals/remote-service-discovery
Accessed: 2026-08-14
Quote: `{"modules.v1":"/v1/modules/","providers.v1":"/v1/providers/"}`

**terraform-versions**
URL: https://registry.terraform.io/v1/providers/hashicorp/random/versions ; https://developer.hashicorp.com/terraform/internals/provider-registry-protocol
Accessed: 2026-08-14
Quote: `"versions":[{"version":"3.8.0","protocols":["5.0"],"platforms":[{"os":"linux","arch":"amd64"}, ...]}]`

**terraform-download**
URL: https://registry.terraform.io/v1/providers/hashicorp/random/3.8.0/download/linux/amd64
Accessed: 2026-08-14
Quote: `"signing_keys":{"gpg_public_keys":[{"key_id":"34365D9472D7468F","ascii_armor":"-----BEGIN PGP PUBLIC KEY BLOCK-----...","source":"HashiCorp"}]}`

**krew-manifest**
URL: https://github.com/kubernetes-sigs/krew-index/blob/master/plugins/view-secret.yaml ; https://github.com/kubernetes-sigs/krew-index/blob/master/plugins/ctx.yaml ; https://krew.sigs.k8s.io/docs/developer-guide/plugin-manifest/
Accessed: 2026-08-14
Quote: `apiVersion: krew.googlecontainertools.github.com/v1alpha2` / `selector: {matchLabels: {os: darwin, arch: amd64}}`

**homebrew-formula**
URL: https://formulae.brew.sh/api/formula/wget.json
Accessed: 2026-08-14
Quote: `"bottle":{"stable":{"root_url":"https://ghcr.io/v2/homebrew/core","files":{"arm64_linux":{"cellar":"/home/linuxbrew/.linuxbrew/Cellar","url":"...","sha256":"f6e698..."}}}}`

**homebrew-deprecated**
URL: https://formulae.brew.sh/api/formula/imagemagick@6.json
Accessed: 2026-08-14
Quote: `"deprecated":true,"deprecation_date":"2026-05-01","deprecation_reason":"is end of life and only receives security updates","disabled":false,"disable_date":"2029-04-01"`

## SYNTHESIS

The three systems sit at different points on a maturity/weight spectrum that maps directly onto trade-offs relevant to a new registry index design (e.g. PDPP's `registry.pdpp.dev`): krew is minimal (single version, inline hash, zero signing, git-as-trust) and cheap to run but has no answer for rollback, revocation, or supply-chain identity; Homebrew adds real multi-platform binary distribution (OCI-backed) and a genuinely good two-stage deprecation lifecycle (soft warn → hard block, each independently dated) but still has no cryptographic signing layer of its own, leaning entirely on GHCR content-addressing plus recipe-hash pinning; Terraform is the only one of the three with an explicit signing-identity chain (GPG key + detached signature over a checksums manifest) and the only one with a formal API-discovery/versioning document separate from the package metadata itself.

For a schema that needs both real signing (Sigstore, per the existing PDPP OCI-artifact recommendation) and clean deprecation semantics, Homebrew's two-stage `deprecated`/`disabled` field pair is the strongest lifecycle precedent to borrow directly — it cleanly separates "still works, please migrate" from "blocked," which neither Terraform's single nullable field nor krew's git-deletion model provides. Terraform's `signing_keys` shape (self-describing, inline public key material, no external keyserver dependency) is the strongest precedent for embedding Sigstore identity data directly in an index entry rather than requiring a separate lookup. None of the three offers a strong precedent for schema-level (not package-level) versioning beyond Terraform's discovery-document key-suffix pattern — this suggests an explicit `/v2/` path-based breaking-change strategy (rather than an in-document version field) is the safer bet, consistent with what none of these three systems solved cleanly.
