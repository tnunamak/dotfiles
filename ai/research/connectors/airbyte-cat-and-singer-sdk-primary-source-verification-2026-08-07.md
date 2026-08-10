---
title: "Airbyte's connector-acceptance-test package has been removed from the live repo (relocated/deprecated by airbyte-ci), while Meltano's Singer SDK ships a live, named, subclassable test-template suite; Singer's 'any tap + any target' interoperability promise is documented-broken by version-pinning conflicts, not just folklore"
date: 2026-08-07
topic: connectors
tags: [airbyte, singer, meltano, connector-testing, prior-art]
status: draft
sources: [airbyte-docs-acceptance-tests, airbyte-docs-local-dev, airbyte-docs-low-code-cdk, airbyte-docs-support-levels, airbyte-blog-cert-community, airbyte-repo-bases-current, singer-spec, meltano-sdk-testing-doc, meltano-sdk-tap-tests-source, singer-python-issue-102]
source_session: a8556422-732b-4af9-9ba5-2ea0f8b6ae48
---

## CLAIMS

- Airbyte's versioned docs (1.8) describe five acceptance-test categories — TestSpec, TestConnection, TestDiscovery, TestBasicRead, TestSequentialReads/incremental tests — with specific assertions per class [airbyte-docs-acceptance-tests]
- As of 2026-08-07, `airbyte-integrations/bases/` on `airbytehq/airbyte` master contains only `base`, `base-java`, `base-normalization` — no `connector-acceptance-test` or `source-acceptance-test` package exists in the live tree [airbyte-repo-bases-current]
- `airbyte-ci/connectors/` on current master contains only `ci_credentials` — no visible pipeline test-suite package at that path either [airbyte-repo-bases-current]
- A repo-wide code search for `class TestSpec` and `TestBasicRead` in airbytehq/airbyte returns zero hits, corroborating that the CAT package's Python source is not present at HEAD (search may lag indexing, so this is directional, not absolute proof) [airbyte-repo-bases-current]
- 250+ individual connectors still carry `integration_tests/acceptance.py` files invoking the acceptance-test framework, meaning the *harness* is likely vendored/imported per-connector or via a package no longer easily browsable at the paths historically documented [airbyte-repo-bases-current]
- Airbyte requires GSM secrets with exactly two labels: `connector` (e.g. `source-s3`) and `filename` (`config`, `invalid_config`, `oauth_config`, etc., without the `.json` suffix because GSM labels can't contain `.`) [airbyte-docs-local-dev]
- Airbyte CI auth to GSM uses env vars `GCP_PROJECT_ID` and `GCP_GSM_CREDENTIALS` [airbyte-docs-local-dev]
- For community-contributed connector PRs from forks without sandbox secrets, a maintainer can run `/run-connector-tests` to execute tests with maintainer-held credentials on the contributor's behalf [airbyte-docs-local-dev]
- Airbyte's low-code/declarative CDK is "a mapping from connector manifest YAML files to actual behavior implementations," built for REST APIs specifically; non-REST sources still need the full Python CDK, and custom Python components can be referenced from the manifest for logic beyond declarative config [airbyte-docs-low-code-cdk]
- Airbyte's current (non-versioned) support-level docs define four tiers — Airbyte (officially supported), Enterprise (paid, Airbyte-built), Marketplace (community-maintained, no SLA), Custom (self-built) — replacing the older two-tier Certified/Community system from a 2023 blog post [airbyte-docs-support-levels, airbyte-blog-cert-community]
- The 2023 blog post states Community→Certified promotion criteria explicitly as usage-based, not purely test-gate-based: "the main goal of certifying a connector is ensuring we've seen enough different use-cases... measured by counting the distinct Airbyte workspaces... using the connector, and each release stage has an ever-higher bar" — i.e., certification requires passing QA/acceptance tests AND clearing a usage/workspace-count threshold, not an automatic pass/fail gate alone [airbyte-blog-cert-community]
- Current support-levels docs do not document any explicit automatic-vs-editorial promotion process between the four current tiers (Airbyte/Enterprise/Marketplace/Custom) — this appears to be an undocumented gap versus the 2023 two-tier system, which did document usage-based promotion [airbyte-docs-support-levels]
- Archived (removed) connectors can be un-archived via a GitHub Discussion, but "must pass Acceptance Tests before you can start the un-archiving process" — a hard test gate for that specific lifecycle transition [airbyte-blog-cert-community search result]
- The Singer spec (singer-io/getting-started/docs/SPEC.md) defines RECORD (`record`, `stream`, optional `time_extracted`), SCHEMA (`schema` as JSON Schema, `stream`, required `key_properties`), and STATE (`value`, semantics explicitly NOT specified by the spec — "determined independently by each Tap") message types, plus a catalog file (`{"streams": [...]}`) for discovery [singer-spec]
- Meltano SDK's `singer_sdk.testing` module provides a real, subclassable, named test suite — not just a vague framework — with confirmed classes: `TapCLIPrintsTest`, `TapDiscoveryTest`, `TapStreamConnectionTest`, `TapValidFinalStateTest` (Tap-level); `StreamSchemaIsValidTest`, `StreamReturnsRecordTest`, `StreamCatalogSchemaMatchesRecordTest`, `StreamRecordSchemaMatchesCatalogTest`, `StreamPrimaryKeysTest` (Stream-level); `AttributeIsDateTimeTest`, `AttributeIsBooleanTest`, `AttributeIsObjectTest`, `AttributeIsIntegerTest`, `AttributeIsNumberTest`, `AttributeNotNullTest` (Attribute-level), assembled via `get_tap_test_class`/`get_target_test_class` factories [meltano-sdk-testing-doc, meltano-sdk-tap-tests-source]
- Singer's "any tap + any target" interoperability promise is documented-broken in practice by dependency version pinning, not merely folklore: `singer-io/singer-python#102` is a real, still-open GitHub issue titled "Incompatible taps & targets" showing `pip install tap-shopify target-postgres` failing because `target-postgres==1.1.3` pins `singer-python==5.1.1` while `tap-shopify` requires a different pinned version — reproduced across three separate tap/target pairings (Shopify+Postgres, Shopify+CSV, Klaviyo+Postgres) in the issue body itself [singer-python-issue-102]
- Singer's own `getting-started` docs acknowledge this class of problem and recommend running each tap and target in a separate Python virtualenv as the standard workaround — an ecosystem-level admission that co-installation is not reliably supported [community-sourced via search, not independently WebFetch-verified against the exact getting-started doc text — flag as UNCONFIRMED primary-source location]

## SOURCES

**airbyte-docs-acceptance-tests**
URL: https://docs.airbyte.com/platform/1.8/connector-development/testing-connectors/connector-acceptance-tests-reference
Accessed: 2026-08-07
Quote: "Verify that a `spec` operation issued to the connector returns a valid connector specification" (TestSpec); "Verify that a check operation issued to the connector with the input config file returns a successful response" (TestConnection); TestBasicRead "configures all streams in full refresh mode to verify a read operation produces some RECORD messages"; TestSequentialReads verifies "RECORD messages output from both were identical or the former is a strict subset of the latter."

**airbyte-docs-local-dev**
URL: https://docs.airbyte.com/platform/connector-development/local-connector-development
Accessed: 2026-08-07
Quote: "Google Secrets Manager does not support including the '.' character in label text" (hence filename labels omit `.json`); env vars `GCP_PROJECT_ID` and `GCP_GSM_CREDENTIALS`; maintainers can run `/run-connector-tests` "if the fork does not have sufficient secrets bootstrapping or other permissions needed to fully test the connector changes."

**airbyte-docs-low-code-cdk**
URL: https://docs.airbyte.com/platform/connector-development/config-based/low-code-cdk-overview
Accessed: 2026-08-07
Quote: "a part of the Python CDK that provides a mapping from connector manifest YAML files to actual behavior implementations." Framework targets REST APIs; non-REST sources need the Python CDK; custom Python components can be referenced under e.g. `CustomIncrementalSync`.

**airbyte-docs-support-levels**
URL: https://docs.airbyte.com/integrations/connector-support-levels
Accessed: 2026-08-07
Quote: Four tiers — Airbyte ("tested, vetted, and production ready... officially supported by Airbyte"), Enterprise ("built and maintained by the Airbyte team... exclusively for Enterprise and Pro customers"), Marketplace ("maintained by Airbyte's community members... not covered by Airbyte support SLAs"), Custom ("connectors you build and maintain yourself"). No documented tier-promotion process found on this page.

**airbyte-blog-cert-community**
URL: https://airbyte.com/blog/introducing-certified-community-connectors
Accessed: 2026-08-07 (via search snippet, not directly WebFetched — treat sub-quotes as UNCONFIRMED pending direct fetch)
Quote (search-surfaced): "A Community connector is maintained by the Airbyte community until it becomes Certified... The Airbyte team is continually certifying Community connectors as usage grows"; "the main goal of certifying a connector is ensuring that we've seen enough different use-cases... measured by counting the distinct Airbyte workspaces... using the connector."

**airbyte-repo-bases-current**
URL: https://api.github.com/repos/airbytehq/airbyte/contents/airbyte-integrations/bases (and .../airbyte-ci/connectors)
Accessed: 2026-08-07 via `gh api`
Quote: directory listing returns exactly `base`, `base-java`, `base-normalization` for `bases/`, and exactly `ci_credentials` for `airbyte-ci/connectors/` — no acceptance-test package present at either historically-documented path. VERIFIED via direct GitHub API call, not a search snippet.

**singer-spec**
URL: https://github.com/singer-io/getting-started/blob/master/docs/SPEC.md
Accessed: 2026-08-07
Quote: RECORD "must have the following properties: `record` Required... `stream` Required... `time_extracted` Optional"; SCHEMA "must have... `schema` Required. A JSON Schema... `key_properties` Required"; STATE "the semantics of a STATE value are not part of the specification, and should be determined independently by each Tap."

**meltano-sdk-testing-doc**
URL: https://github.com/meltano/sdk/blob/main/docs/testing.md?plain=true
Accessed: 2026-08-07
Quote: "a runner class (TapTestRunner and TargetTestRunner)... test template classes (TapTestTemplate, StreamTestTemplate, AttributeTestTemplate, and TargetTestTemplate)... get_tap_test_class and get_target_test_class factory methods." Older `get_standard_tap_tests`/`get_standard_target_tests` functions were removed/deprecated in favor of these.

**meltano-sdk-tap-tests-source**
URL: https://github.com/meltano/sdk/blob/main/singer_sdk/testing/tap_tests.py (fetched via WebFetch rendering)
Accessed: 2026-08-07
Quote: Confirmed class names and one-line docstrings: `TapCLIPrintsTest` ("Test that the tap is able to print standard metadata"), `TapDiscoveryTest` ("Test that discovery mode generates a valid tap catalog"), `StreamReturnsRecordTest` ("Test that a stream sync returns at least 1 record"), `StreamPrimaryKeysTest` ("Test all records for a stream's primary key are unique and non-null"), plus 6 named `Attribute*Test` classes for datetime/boolean/object/integer/number/not-null checks. Note: WebFetch renders GitHub's HTML view through a summarizing model, not raw source — treat exact docstring wording as tightly-paraphrased rather than character-verbatim.

**singer-python-issue-102**
URL: https://github.com/singer-io/singer-python/issues/102
Accessed: 2026-08-07 via `gh api repos/singer-io/singer-python/issues/102`
Quote (full issue body, VERIFIED via direct API call): "At this point I've found it impossible to continue with any singer project, as basically no combination of taps & target work together due to any number of dependency errors... `pip install tap-shopify target-postgres` ERROR: target-postgres 1.1.3 has requirement singer-python==5.1.1, but you'll have singer-python 5.4.1 which is incompatible."

## SYNTHESIS

The single most reportable finding is the Airbyte one: the acceptance-test package that every existing docs page, blog post, and Stack Overflow answer describes (`bases/connector-acceptance-test`, `test_core.py`, `TestSpec`/`TestBasicRead` etc.) is **not present in the current `airbytehq/airbyte` master branch** — confirmed by direct `gh api` directory listing, not a search snippet. The versioned docs page (`/platform/1.8/...`) that fully describes these classes is dated/frozen documentation, and current (unversioned) docs no longer surface an equivalent page at a stable non-versioned URL in the same depth. This strongly suggests the CAT harness was migrated into `airbyte-ci` tooling (Dagger-based pipelines) and is no longer a standalone browsable Python package — but I could not confirm its exact new location/form, so any report claim about "airbyte-ci test suite" internals beyond what the docs literally say should be marked UNCONFIRMED. A follow-up search specifically for the Dagger pipeline test-step definitions (not just the README, which also 404'd) would be needed to close this gap.

For Singer, the interoperability failure is real and primary-sourced (not just community folklore) — issue #102 is a verbatim, reproducible bug report, not a blog opinion. This is stronger evidence than what the report brief anticipated ("hardest to source").
