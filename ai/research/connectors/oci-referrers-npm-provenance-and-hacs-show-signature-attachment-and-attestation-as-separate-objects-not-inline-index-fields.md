---
title: "OCI's referrers API, npm's provenance attestations, and HACS's unsigned repo-trust model show that mature ecosystems attach signatures/attestations as separate linked objects rather than inline index fields, while HACS confirms zero signing is viable at community scale"
date: 2026-08-14
topic: connectors
tags: [oci-distribution-spec, sigstore, npm-provenance, hacs, cosign, referrers-api, attestation]
status: draft
sources: [hacs-repo-list, hacs-manifest, oci-manifest-spec, oci-referrers-spec, cosign-referrers, npm-registry-live, npm-attestation-live, npm-deprecation, vscode-marketplace]
source_session: 6f87cffc-37f4-4e31-ba75-15ceb54ab22a
---

## CLAIMS

- HACS's default repo list (`hacs/default`, e.g. the `integration` file) is a flat JSON array of `"owner/repo"` strings with no per-entry metadata — verified live, 3,105 entries. [hacs-repo-list]
- Each HACS-managed repo self-describes via a root `hacs.json` with fields `name` (required), plus optional `content_in_root`, `zip_release`, `filename`, `hide_default_branch`, `country` (ISO 3166-1 alpha-2), `homeassistant` (min HA version), `hacs` (min HACS version), `persistent_directory`. [hacs-manifest]
- HACS has no signing or checksum verification layer anywhere in its dependency chain or docs (grepped for checksum/signing/signature/integrity/sigstore — zero matches); trust is entirely GitHub-repo-based (PR review + `hacs/action` validator gates entry into the default list, then runtime fetches rely on GitHub's own auth/TLS with no additional verification). [hacs-repo-list] [hacs-manifest]
- The OCI Image Manifest spec's `subject` field (schema v1.1) creates a "weak association to a separate Merkle DAG" — i.e., one manifest can reference another manifest's digest without that referenced manifest ever being modified. [oci-manifest-spec]
- The OCI distribution-spec referrers API (`GET /v2/<name>/referrers/<digest>`) returns an OCI Image Index whose `manifests[]` are descriptors of every manifest in the repo whose `subject` points at the queried digest, each carrying an `artifactType` (from the manifest itself, or falling back to the config `mediaType`). [oci-referrers-spec]
- cosign/sigstore signatures use this OCI 1.1 referrers mechanism directly — sigstore's own docs state signatures "use the OCI 1.1 referrer specification," discoverable via `cosign tree $IMAGE`; an older tag-based convention (`sha256-<digest>.sig`) exists as a separate, earlier spec. [cosign-referrers]
- A live npm registry fetch (`registry.npmjs.org/sigstore@5.0.0`) shows `dist.attestations` as a pointer object (`{url, provenance: {predicateType}}`), not the attestation bundle itself — the bundle must be fetched separately from that URL. [npm-registry-live]
- Fetching that attestations URL live returns two separate attestations: a publish attestation (`predicateType: https://github.com/npm/attestation/tree/main/specs/publish/v0.1`) and a provenance/SLSA attestation (`predicateType: https://slsa.dev/provenance/v1`), each a full Sigstore bundle with `verificationMaterial` (cert/pubkey + Rekor `tlogEntries`) and a `dsseEnvelope` (in-toto payload + signatures). [npm-attestation-live]
- npm also carries its own separate, older registry-level signature mechanism: `dist.signatures[]`, each `{keyid, sig}` — this predates and is distinct from the newer provenance/attestation mechanism. [npm-registry-live]
- npm represents per-version deprecation as a plain string field (`"deprecated": "<message>"`) inside that version's object in `versions{}`, absent entirely when not deprecated (confirmed live on `left-pad`, `request`, `tslint`, `babel-eslint`); unpublish is destructive (deletes the version's metadata; that exact version can never be republished), a materially different lifecycle than deprecation. [npm-deprecation]
- VS Code Marketplace's (undocumented for third-party use) extension query API models platform variants as separate entries in `versions[]`, each carrying its own `targetPlatform` string (e.g. `alpine-x64`, omitted for platform-neutral builds) and its own `files[]` array of `{assetType, source}` pairs, including a distinct `VsixSignature` asset type alongside the VSIX package itself. [vscode-marketplace]

## SOURCES

**hacs-repo-list**
URL: https://raw.githubusercontent.com/hacs/default/master/integration
Accessed: 2026-08-14
Quote: `["007hacky007/car_maintenance", "0jety0/emaux_spv150", ...]` (3,105 entries, flat string array)

**hacs-manifest**
URL: https://hacs.xyz/docs/publish/start/
Accessed: 2026-08-14
Quote: fields `name`, `content_in_root`, `zip_release`, `filename`, `hide_default_branch`, `country`, `homeassistant`, `hacs`, `persistent_directory` (per-field docs on the page; `render_readme` corroborated only secondarily, not primary-doc-confirmed)

**oci-manifest-spec**
URL: https://github.com/opencontainers/image-spec/blob/main/manifest.md
Accessed: 2026-08-14
Quote: `subject` — "This OPTIONAL property specifies a descriptor of another manifest... creating a weak association to a separate Merkle DAG"

**oci-referrers-spec**
URL: https://github.com/opencontainers/distribution-spec/blob/main/spec.md
Accessed: 2026-08-14
Quote: `GET /v2/<name>/referrers/<digest>` returns an image index of manifests whose `subject` matches `<digest>`

**cosign-referrers**
URL: https://docs.sigstore.dev/cosign/signing/signing_with_containers/ ; https://github.com/sigstore/cosign/blob/main/specs/SIGNATURE_SPEC.md
Accessed: 2026-08-14
Quote: "Signatures use the OCI 1.1 referrer specification"

**npm-registry-live**
URL: https://registry.npmjs.org/sigstore@5.0.0
Accessed: 2026-08-14
Quote: `"attestations":{"url":"https://registry.npmjs.org/-/npm/v1/attestations/sigstore@5.0.0","provenance":{"predicateType":"https://slsa.dev/provenance/v1"}},"signatures":[{"keyid":"SHA256:DhQ8wR5APBvFHLF/+Tc+AYvPOdTpcIDqOhxsBHRwC7U","sig":"MEUCIGIJh+4R..."}]`

**npm-attestation-live**
URL: https://registry.npmjs.org/-/npm/v1/attestations/sigstore@5.0.0
Accessed: 2026-08-14
Quote: two bundles, `predicateType` values `https://github.com/npm/attestation/tree/main/specs/publish/v0.1` and `https://slsa.dev/provenance/v1`, each with `dsseEnvelope.payloadType: application/vnd.in-toto+json`

**npm-deprecation**
URL: https://registry.npmjs.org/left-pad
Accessed: 2026-08-14
Quote: `"deprecated":"use String.prototype.padStart()"` on version `1.1.1`

**vscode-marketplace**
URL: https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery (live POST) ; https://github.com/coder/code-marketplace ; https://github.com/microsoft/vsmarketplace/issues/106
Accessed: 2026-08-14
Quote: `versions[]` entries each carry `targetPlatform` (e.g. `alpine-x64`) and `files[]` including asset types `Microsoft.VisualStudio.Services.VSIXPackage` and `...VsixSignature`

## SYNTHESIS

The clearest structural signal across OCI/cosign/npm is that **signatures and attestations are modeled as separate, independently-fetchable objects linked by digest/URL, never as inline fields on the index entry itself.** OCI's referrers API, cosign's `subject`-linked manifests, and npm's `dist.attestations` (a pointer, not the bundle) all converge on the same shape: the index/manifest carries a reference; the actual signed material is a separate document, fetched on demand and independently verifiable against Rekor/OIDC. This directly validates the existing PDPP recommendation (see the companion synthesis file on OCI+Sigstore+trust tiers) to keep the index itself lightweight — it should carry a pointer (digest + maybe a Rekor UUID) rather than embedding full Sigstore bundles inline, mirroring npm's `attestations.url` pattern rather than Terraform's embed-the-whole-public-key-inline pattern. Terraform's inline `gpg_public_keys` (from the companion Terraform/krew/Homebrew entry) is the outlier here specifically because GPG has no external transparency log to point at — Sigstore's Rekor log gives PDPP a place to point *to* instead of embedding.

HACS is the load-bearing counter-example proving the null hypothesis: a large (3,000+ repo), community-run registry with **zero** signing or checksum infrastructure is operationally viable at scale, its entire trust model resting on GitHub's own repo/PR/auth infrastructure. This is useful as a lower bound / sanity check, not a recommendation — the existing PDPP synthesis already correctly treats HACS as the cautionary tale (no visible trust-tier signal, documented incident history), not the model to copy. npm's two parallel signature mechanisms (older `dist.signatures[]` registry-level PGP-ish signing vs. newer `dist.attestations` Sigstore/SLSA provenance) is a useful cautionary data point too: running two trust mechanisms simultaneously long-term creates exactly the kind of ambiguity ("which one do I check, do I need both") a new registry should avoid by picking one (Sigstore) from day one rather than accreting a second scheme later.
