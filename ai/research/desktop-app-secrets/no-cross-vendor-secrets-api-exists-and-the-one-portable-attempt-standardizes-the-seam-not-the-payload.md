---
title: "No standardized cross-vendor secrets-storage API exists to adopt — HashiCorp Vault's KV v2 is explicitly vendor-specific, and the Kubernetes Secrets Store CSI Driver, the one serious portability attempt, standardizes the plugin seam (CRD + gRPC) while leaving the per-provider parameters block non-portable"
date: 2026-09-03
topic: desktop-app-secrets
tags: [secrets-management, vault, csi-driver, portability, credential-storage, plugin-seam]
status: draft
sources: [vault-kv2, csi-concepts, csi-repo, csi-aws, csi-azure, rfc8693, psd2-rts]
source_session: 2d805b64-ec04-48db-86c4-60332cf6998b
---

## CLAIMS

- HashiCorp Vault KV v2 exposes a complete secrets HTTP API — `GET/POST/PATCH/DELETE /:mount/data/:path` for data, `POST /:mount/delete/:path`, `POST /:mount/undelete/:path`, `PUT /:mount/destroy/:path` for version lifecycle, `GET/POST/PATCH/DELETE/LIST /:mount/metadata/:path` for metadata, and `GET/POST /:mount/config` — and its documentation references no cross-vendor secrets standard, making the design Vault-specific. [vault-kv2]
- The Kubernetes Secrets Store CSI Driver is the closest thing to a portable multi-backend secrets interface: a namespaced `SecretProviderClass` CRD (`apiVersion: secrets-store.csi.x-k8s.io/v1`) plus a `provider` field, with the driver `secrets-store.csi.k8s.io` mounting external-store contents into pods as a CSI volume. [csi-concepts] [csi-repo]
- The actual plugin boundary of that driver is gRPC: on pod start and restart the driver calls the provider over gRPC to retrieve secret content, then mounts a tmpfs volume and writes the contents to it — so anything implementing the gRPC contract becomes a provider. [csi-concepts]
- Pod specs under that driver never name the storage backend; they reference only `driver: secrets-store.csi.k8s.io` plus `volumeAttributes.secretProviderClass`, so swapping backends means editing the SecretProviderClass rather than the workload. [csi-concepts] [csi-repo]
- Portability of that interface stops at the `parameters` block, which is not standardized and remains provider-specific: the AWS provider uses `objectType` ("secretsmanager" or "ssmparameter"), `objectAlias`, `filePermission`, and `failoverRegion`, while the Azure Key Vault provider uses `keyvaultName`, `tenantId`, `usePodIdentity`, and `useManagedIdentity`. Migrating between clouds therefore still requires rewriting that block. [csi-aws] [csi-azure]
- Auto-rotation in that driver is documented as not stable, and with `subPath` volume mounts, rotated updates are not propagated to the container. [csi-concepts]
- RFC 8693 OAuth 2.0 Token Exchange defines delegation semantics that let a component act with a scoped, exchanged token instead of holding an original long-lived credential, which is an architectural alternative to standardizing credential storage. [rfc8693]
- EU PSD2 regulatory technical standards (Commission Delegated Regulation (EU) 2018/389) require dedicated interfaces with qualified certificates, and the regulatory direction of travel is to stop third parties from holding end-user credentials rather than to standardize how such credentials are stored. [psd2-rts]

## SOURCES

**vault-kv2**
URL: https://developer.hashicorp.com/vault/api-docs/secret/kv/kv-v2
Accessed: 2026-09-03
Quote: Endpoints documented include "GET /:secret-mount-path/data/:path" (read secret version), "POST /:secret-mount-path/data/:path" (create/update), "PATCH /:secret-mount-path/data/:path", "DELETE /:secret-mount-path/data/:path" (delete latest version), "PUT /:secret-mount-path/destroy/:path" (permanently destroy versions), and "LIST /:secret-mount-path/metadata/:path". The documentation contains no reference to a standardized cross-vendor secrets interface.

**csi-concepts**
URL: https://secrets-store-csi-driver.sigs.k8s.io/concepts.html
Accessed: 2026-09-03
Quote: "The SecretProviderClass is a namespaced resource used to provide driver configurations and provider-specific parameters to the CSI driver." On mount: the driver "communicates with the provider using gRPC to retrieve the secret content from the external Secrets Store you have specified in the SecretProviderClass custom resource," then mounts the volume as tmpfs and writes the secret contents to it.

**csi-repo**
URL: https://github.com/kubernetes-sigs/secrets-store-csi-driver
Accessed: 2026-09-03
Quote: "Secrets Store CSI driver for Kubernetes secrets - Integrates secrets stores with Kubernetes via a CSI volume." Listed features include multiple external secrets store providers and "pod portability with the SecretProviderClass CustomResourceDefinition."

**csi-aws**
URL: https://github.com/aws/secrets-store-csi-driver-provider-aws
Accessed: 2026-09-03
Quote: "The AWS provider for the Secrets Store CSI Driver allows you to fetch secrets from AWS Secrets Manager and AWS Systems Manager Parameter Store, and mount them into Kubernetes pods." Provider-specific parameter fields include `objectType` ("secretsmanager" or "ssmparameter"), `objectAlias`, `filePermission`, and `failoverRegion`.

**csi-azure**
URL: https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-driver
Accessed: 2026-09-03
Quote: The Azure Key Vault provider integrates Key Vault as a secret store with an AKS cluster via a CSI volume, keyed on provider-specific parameters including `keyvaultName`, `tenantId`, `usePodIdentity`, and `useManagedIdentity`.

**rfc8693**
URL: https://www.rfc-editor.org/rfc/rfc8693
Accessed: 2026-09-03
Quote: Defines OAuth 2.0 Token Exchange, including the distinction between delegation and impersonation semantics, allowing a party to obtain a token for acting on behalf of another rather than reusing the original credential.

**psd2-rts**
URL: https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX%3A32018R0389
Accessed: 2026-09-03
Quote: Commission Delegated Regulation (EU) 2018/389 sets regulatory technical standards for strong customer authentication and common and secure open standards of communication, including Article 34's qualified-certificate requirements for dedicated interfaces.

## SYNTHESIS

The practical answer to "should we define a secrets/vault interface or adopt an existing one?" is usually neither, and the reason is specific rather than hand-wavy: there is nothing cross-vendor to adopt. Vault's KV v2 is a complete and well-documented API but is Vault's own; its docs do not gesture at any standard. The Kubernetes Secrets Store CSI Driver is the one serious attempt at backend portability across AWS, Azure, GCP, Vault, and Akeyless, and it is instructive precisely because of where it draws the line: the CRD kind, the volume attribute, the gRPC provider contract, and the mount semantics are standard, while the `parameters` payload is explicitly provider-specific. Portability lands on the *seam*, not the *schema*.

The reusable design rule: when tempted to standardize secret storage, standardize the seam (who fetches, who isolates, what the consumer sees) and leave the payload to the deployment. Treat SecretProviderClass as a portable seam rather than portable config — keep workload specs and mount paths identical across environments and isolate the per-cloud parameters into per-environment overlays, since that one object is all that differs between backends.

The stronger move is often to make the question moot. RFC 8693 token exchange, and the PSD2/Open Banking regulatory direction of eliminating third-party credential holding, both point at reducing what must be stored rather than standardizing its storage. Before designing a vault abstraction, check whether the component can be handed a scoped short-lived token instead of a credential; if it can, the storage interface problem largely dissolves.

One caveat for anyone relying on the CSI driver for rotation: auto-rotation is documented as not stable, and `subPath` mounts do not receive rotated updates — so rotation is not a property you get for free from adopting the seam.

Applied to PDPP (DEL-303): this is why the recommendation was to add a credential *isolation obligation* rather than a vault interface — the isolation half of the problem is real and checkable, while the interface half has no portable standard to adopt.
