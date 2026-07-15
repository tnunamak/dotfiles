---
title: "Connector/config systems separate secrets from non-secret config either by per-field flag (common) or a separate object (security-deliberate minority), and tolerate-but-warn on unknown keys rather than reject"
date: 2026-06-05
topic: data-collection-systems
tags: [connectors, config-schema, secrets, json-schema, etl, prior-art]
status: draft
sources: [airbyte, dlt, singer-meltano, terraform, kubernetes, openapi, pulumi, json-schema]
---

## CLAIMS

- Airbyte ships one combined `connectionSpecification` JSON Schema with secrets and non-secrets side by side, marking secrets per-field with the custom keyword `airbyte_secret: true`; the split happens at storage (secret values are replaced with a coordinate and written to a secret-persistence layer, re-hydrated before the connector runs), and `additionalProperties` defaults lenient (`true`) "for forwards compatibility." [airbyte]
- dlt physically separates `secrets.toml` from `config.toml` (Family B, strongest precedent) and enforces the invariant that "configuration resolution fails if a secret value is discovered in a config provider that does not support secrets"; unknown config keys are ignored, not rejected; dlt has shipped a real file-split-failure bug (issue #2782) where the file-level split silently failed. [dlt]
- Singer has no config schema at all; Meltano uses one flat `settings:` list with a per-setting `sensitive: true`; the Singer SDK declares one `config_jsonschema` validated by `_validate_config()`, where `secret=True` adds inline `secret`/`writeOnly` annotations rather than splitting secrets out; cross-field required groups stay within one schema (`settings_group_validation`, `dependentRequired`); all pass unknown keys through. [singer-meltano]
- Terraform uses one typed schema per resource with in-place `Sensitive: true` (redacted in plan/state) and, since 1.11, `WriteOnly: true` for input-but-never-persisted secrets — still per-field flags, not a second schema. [terraform]
- Kubernetes deliberately split config into two resource kinds — non-secret `ConfigMap` vs secret `Secret` (own RBAC, optional encryption-at-rest) — choosing a separate object over a `secret: true` flag because secret handling needed to diverge structurally: "If the data you want to store are confidential, use a Secret rather than a ConfigMap." [kubernetes]
- OpenAPI puts credentials in a separate `securitySchemes` construct (B-like) while `writeOnly` is a per-field secret-in/not-out flag (A-like); Pulumi sets secrets with `--secret`, stores encrypted ciphertext under a `secure:` prefix, read via `requireSecret` (B at set-time). [openapi] [pulumi]
- JSON Schema: `additionalProperties: false` is strict but composes badly with `allOf`/`$ref` (rejects sibling-subschema properties; `unevaluatedProperties: false` is the composition-safe fix); `default` is an annotation that validators do not fill in (defaults must be applied in code); Kubernetes' three-mode field validation (`Ignore`/`Warn`/`Strict`, GA v1.27) was introduced *because* silently-dropped typos like `replica` vs `replicas` caused outages. [json-schema] [kubernetes]

## SOURCES

**airbyte**
URL: https://docs.airbyte.com/platform/understanding-airbyte/secrets ; https://docs.airbyte.com/platform/connector-development/connector-specification-reference ; https://docs.airbyte.com/platform/understanding-airbyte/airbyte-protocol
Accessed: 2026-06-05

**dlt**
URL: https://dlthub.com/docs/general-usage/credentials/setup ; https://dlthub.com/docs/general-usage/credentials/advanced ; https://github.com/dlt-hub/dlt/issues/2782
Accessed: 2026-06-05
Quote: "Configuration resolution fails if a secret value is discovered in a config provider that does not support secrets."

**singer-meltano**
URL: https://github.com/singer-io/getting-started/blob/master/docs/SPEC.md ; https://docs.meltano.com/reference/plugin-definition-syntax/ ; https://github.com/meltano/sdk/blob/main/singer_sdk/typing.py ; https://github.com/meltano/sdk/blob/main/singer_sdk/plugin_base.py
Accessed: 2026-06-05

**terraform**
URL: https://developer.hashicorp.com/terraform/plugin/sdkv2/schemas/schema-behaviors ; https://developer.hashicorp.com/terraform/plugin/framework/resources/write-only-arguments
Accessed: 2026-06-05

**kubernetes**
URL: https://kubernetes.io/docs/concepts/configuration/configmap/ ; https://kubernetes.io/docs/concepts/configuration/secret/ ; https://kubernetes.io/blog/2023/04/24/openapi-v3-field-validation-ga/
Accessed: 2026-06-05
Quote: "If the data you want to store are confidential, use a Secret rather than a ConfigMap."

**openapi**
URL: https://spec.openapis.org/oas/v3.1.0.html
Accessed: 2026-06-05

**pulumi**
URL: https://www.pulumi.com/docs/iac/concepts/secrets/
Accessed: 2026-06-05

**json-schema**
URL: https://json-schema.org/understanding-json-schema/reference/object ; https://json-schema.org/understanding-json-schema/reference/annotations ; https://en.wikipedia.org/wiki/Robustness_principle ; https://google.aip.dev/180
Accessed: 2026-06-05

## SYNTHESIS

Two families for separating secret from non-secret config. Family A (per-field flag in one schema) is the more common declaration-level convention: Airbyte `airbyte_secret`, Meltano `sensitive`, Singer SDK `secret=True`, Terraform `Sensitive`/`WriteOnly`, OpenAPI `writeOnly`. Family B (a separate object/construct for secrets) is the minority but is the model of the most security-deliberate systems: dlt (`secrets.toml`/`config.toml`), Kubernetes (`ConfigMap`/`Secret`), Pulumi. The choice principle: Family B is warranted precisely when secrets get *different downstream handling* (different transport, redaction, never-persisted, future injection) than options; if the only difference were UI redaction, Family A (a flag) is the lighter, more conventional choice. The invariant "a secret cannot travel the non-secret channel" is industry-standard (dlt resolution-fails, Kubernetes separate kind), not novel — but per-field-flag and per-value-routing enforcement both have shipped real split-failure bugs (Airbyte silently-ignored flags on some shapes, dlt #2782), so a build-time static no-overlap check between the two declarations is a stronger guarantee than either. On validation strictness, every ETL system surveyed passes unknown config keys through; strict `additionalProperties: false` rejection is the outlier and composes badly. The best-precedented middle path is Kubernetes' `Warn` mode — type-check declared fields, accept + warn (and ideally *preserve*) unknown keys so typos surface without breaking forward-compatibility. Defaults must be applied in code, since JSON Schema validators do not fill them in. Keep cross-field credential groups ("API key OR username+password") inside a single schema via `dependentRequired`, and keep OAuth declaration distinct from static-secret config (Airbyte `advanced_auth`, OpenAPI `securitySchemes`).
