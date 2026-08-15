---
title: "The Terraform Registry declares provider-to-core wire-protocol compatibility as its own discovery-time metadata field, separate from and orthogonal to the provider's own semantic version number"
date: 2026-08-14
topic: lfdt-labs-prior-art
tags: [terraform, provider-protocol, registry-metadata, version-pinning, wire-protocol]
status: draft
sources: [tf-plugin-protocol-versions, tf-registry-protocol-metadata]
source_session: 2fbd3c3f-d8fe-4d5d-882c-5ece6a53592a
---

## CLAIMS

- Terraform's provider wire protocol has its own version line (protocol 5, protocol 6), independent of the Terraform CLI's release version and independent of any given provider's own semver: "Protocol version 5 is compatible with Terraform CLI version 0.12 and later" and "Protocol version 6 is compatible with Terraform CLI version 1.0 and later," with both protocol lines supported concurrently rather than one superseding the other. [tf-plugin-protocol-versions]
- Protocol version 6 is additive-only over version 5 (adds nested-attribute schema support) rather than a breaking replacement, and HashiCorp ships a translation shim (`tf5to6server`) that lets a protocol-5 provider be served over protocol 6 without the provider author rewriting it. [tf-plugin-protocol-versions]
- The Terraform Registry stores and surfaces protocol-version support as its own discovery-time compatibility metadata field, distinct from the provider's semver, and uses it to filter/recommend which provider releases a given Terraform CLI can use: "During discovery, the Terraform Registry uses the protocol version as additional compatibility metadata when deciding which plugin versions Terraform CLI can select." [tf-registry-protocol-metadata]

## SOURCES

**tf-plugin-protocol-versions**
URL: https://developer.hashicorp.com/terraform/plugin/terraform-plugin-protocol
Accessed: 2026-08-14
Quote: "Protocol version 6 is compatible with Terraform CLI version 1.0 and later." / "Protocol version 5 is compatible with Terraform CLI version 0.12 and later."

**tf-registry-protocol-metadata**
URL: https://developer.hashicorp.com/terraform/internals/provider-registry-protocol
Accessed: 2026-08-14
Quote: "During discovery, the Terraform Registry uses the protocol version as additional compatibility metadata when deciding which plugin versions Terraform CLI can select."

## SYNTHESIS

This is a narrower, directly-verified companion fact to the broader Terraform/OpenTofu drift-and-fragmentation case study already captured in `kubernetes-and-oidc-certification-programs-show-conformance-suites-work-as-alignment-mechanisms-only-when-self-certification-is-backed-by-a-published-audit-trail.md` (which covers the OpenTofu fork itself in depth). The piece worth keeping separate: the *mechanism* by which a Terraform provider declares core-compatibility is a dedicated metadata field at the registry layer, not the provider's own version number and not a runtime-only handshake. For `data-connectors` pinning against `pdpp`/`data-connect`, this argues for a connector manifest field that names the wire/interchange-protocol version a connector speaks (separate from the connector's own release version), checked at discovery/install time — mirroring Terraform's separation of "which protocol do you speak" from "what version are you."
