---
title: "Home Assistant's hassfest is the closest prior art to machine-checked tier promotion (per-rule linting + human sign-off, not pure editorial review); Pact and VCR-family tools have no documented answer to a mock authored under the same misunderstanding as the code it mocks, and Pact's own model explicitly excludes third-party APIs you don't operate"
date: 2026-08-07
topic: connectors
tags: [home-assistant, quality-scale, terraform, plaid, stripe, zapier, pact, vcr, contract-testing, cassette-drift, connector-testing, certification, prior-art]
status: draft
sources: [ha-quality-scale-docs, ha-hassfest-source, tf-acceptance-tests, plaid-sandbox, stripe-test-mode, zapier-publishing-requirements, make-app-review, pact-how-it-works, pact-broker-can-i-deploy, pact-faq, vcr-re-record-interval, nock-docs, msw-keeping-mocks-in-sync]
source_session: 073acd59-50b7-4bf4-81a9-bfb5e652202b
---

## CLAIMS

- Home Assistant's Integration Quality Scale defines four tiers (bronze/silver/gold/platinum) with concrete, escalating requirements: bronze requires UI setup, basic coding standards, configurable tests, and basic docs; silver adds automatic reconnection/re-auth-on-failure and active code owners; gold adds auto-discovery, translations, device/firmware updates, and full test coverage; platinum adds fully-typed, fully-async code [ha-quality-scale-docs]
- Tier promotion in Home Assistant is a human-reviewed pull request, not a fully automatic gate: a contributor opens a PR to change the declared tier, and it takes effect only "once the Home Assistant core team reviews and approves it" [ha-quality-scale-docs]
- Home Assistant also runs `hassfest`, a script (`script/hassfest/quality_scale.py`) that programmatically validates a per-integration `quality_scale.yaml` file against code-detectable facts — e.g. checking for `_attr_has_entity_name` or `async_step_discovery` in source — and requires an explicit justification comment for any rule marked exempt [ha-hassfest-source]
- Terraform's provider acceptance tests (`TF_ACC=1`) run a real local Terraform binary against real infrastructure via real plan/apply/refresh/destroy operations, requiring genuine "Provider Access" (network/system access) and "Provider Credentials" (authorized credentials) — the fetched official docs describe no mocking, VCR, or cassette-replay mode [tf-acceptance-tests]
- HashiCorp's own acceptance-testing docs recommend "a separate provider account or namespace for acceptance testing," confirming official/maintained providers keep their own live cloud test accounts rather than sharing or mocking credentials [tf-acceptance-tests]
- Plaid's Sandbox is a fully separate hosted environment (`sandbox.plaid.com`) with its own dedicated API keys, and ships deterministic seeded test credentials: "The default username/password combination for all Sandbox institutions is `user_good` / `pass_good`" [plaid-sandbox]
- Stripe's sandboxes (test mode plus up to 5 creatable named sandboxes) each carry their own isolated test API keys and settings, with deterministic canned test-card numbers mapped to specific, documented failure outcomes (e.g. `card_declined`) [stripe-test-mode]
- Zapier's integration publishing requirements mandate a developer-supplied, non-expiring test account under `integration-testing@zapier.com` with all features enabled, explicitly ban sandbox/dev/test API endpoints in the published integration ("Integrations using sandbox/test/dev endpoints will not be published"), and ban hardcoded credentials — Zapier's review is binary pass/fail with no certified/community tier split documented on that page [zapier-publishing-requirements]
- Make.com's app review runs an automated pre-screen ("your app is first reviewed by Make's application, which checks for common issues and generates a PDF," explicitly flagged by Make as still in beta) before a manual QA engineer review — a two-stage automated-then-human shape structurally similar to hassfest-then-PR-review [make-app-review]
- Pact's provider verification replays the consumer-derived pact file against the actual running provider service and diffs real responses against expected ones: "each request is sent to the provider, and the actual response it generates is compared with the minimal expected response described in the consumer test" [pact-how-it-works]
- Pact's own FAQ explicitly states the tool does not fit situations "where you cannot load data into the provider without using the API that you're actually testing (e.g. public APIs)," and that Pact is "most valuable... where you... control the development of both the consumer and the provider" [pact-faq]
- Pact Broker's `can-i-deploy` gates deployment on the existence of "a successful verification result" between the candidate app version and every already-deployed version it would interact with [pact-broker-can-i-deploy]
- VCR (Ruby) ships a real staleness mechanism, `re_record_interval`, described as "How frequently (in seconds) the cassette should be re-recorded" — but it is opt-in, time-based only, and re-records silently (overwrites) rather than diffing old-vs-new or failing a build on detected divergence [vcr-re-record-interval]
- nock (Node) has no staleness-detection mechanism at all; its record modes (`wild`/`record`/`update`) are purely manual/on-demand re-recording triggers [nock-docs]
- MSW (Mock Service Worker) has a dedicated docs page, "Keeping mocks in sync," naming the exact temporal-drift problem directly: "You write mocks to describe a server behavior fixed in time. But as time goes on, that behavior may change, potentially rendering your mocks obsolete" — its recommended fix is spec-first generation (OpenAPI/GraphQL → auto-generated handlers) or scheduled HAR-snapshot regeneration in CI [msw-keeping-mocks-in-sync]
- No official documentation source across Pact, VCR, nock, Polly.js, or MSW explicitly names "the mock's author and the code's author are the same person, so they can share the same wrong belief from day one" as a distinct failure mode — every mechanism found (Pact's provider verification, VCR's re-record interval, MSW's spec-first sync) addresses either two-independent-parties drift or after-the-fact temporal drift, never a mock that was wrong at the moment of authorship [pact-how-it-works, vcr-re-record-interval, msw-keeping-mocks-in-sync]

## SOURCES

**ha-quality-scale-docs**
URL: https://developers.home-assistant.io/docs/core/integration-quality-scale/
Accessed: 2026-08-07
Quote: Bronze: "Can be easily set up through the UI," "The source code adheres to basic coding standards," "Automated tests that guard this integration can be configured correctly," "Offers basic end-user documentation." Promotion: "a contributor can open a pull request to adjust the scale for the integration... Once the Home Assistant core team reviews and approves it, the integration will display the new tier."

**ha-hassfest-source**
URL: https://github.com/home-assistant/core/blob/dev/script/hassfest/quality_scale.py
Accessed: 2026-08-07
Quote: Docstring "Validate integration quality scale files." Invoked via `python3 -m script.hassfest --action validate`; individual rules (e.g. `has_entity_name`, `discovery`) are checked against source code for specific attributes/functions, and can be marked `exempt` only with a required justification comment.

**tf-acceptance-tests**
URL: https://developer.hashicorp.com/terraform/plugin/testing/acceptance-tests
Accessed: 2026-08-07
Quote: Acceptance tests "run a local Terraform binary to perform real plan, apply, refresh, and destroy operations." Requirements listed: "Provider Access: Network or system access to the provider and any resources being tested," "Provider Credentials: Authorized credentials to the provider and any resources being tested." Recommends "a separate provider account or namespace for acceptance testing."

**plaid-sandbox**
URL: https://plaid.com/docs/sandbox/
Accessed: 2026-08-07
Quote: "The default username/password combination for all Sandbox institutions is `user_good` / `pass_good`." "A variety of test accounts and institutions are available to test against, and you can create an unlimited number of test Items."

**stripe-test-mode**
URL: https://docs.stripe.com/test-mode
Accessed: 2026-08-07
Quote: "Copy the test API keys for the sandbox. Copy the sandbox account ID." "Isolate settings completely for each sandbox. Copy settings from live mode at creation time." Documented deterministic test-card decline codes (e.g. `card_declined`).

**zapier-publishing-requirements**
URL: https://docs.zapier.com/platform/publish/integration-publishing-requirements
Accessed: 2026-08-07
Quote: "The submission includes a valid test account created in the application" under `integration-testing@zapier.com`, non-expiring, all features enabled. "The integration uses production API endpoints. Integrations using sandbox/test/dev endpoints will not be published." "Do not hard code credentials such as API Keys, Client IDs, Client Secrets, etc."

**make-app-review**
URL: https://developers.make.com/custom-apps-documentation/app-review/overview
Accessed: 2026-08-07
Quote: "your app is first reviewed by Make's application, which checks for common issues and generates a PDF" — explicitly flagged on the page as still in beta, followed by manual QA engineer review.

**pact-how-it-works**
URL: https://docs.pact.io/getting_started/how_pact_works
Accessed: 2026-08-07
Quote: "In provider verification, each request is sent to the provider, and the actual response it generates is compared with the minimal expected response described in the consumer test."

**pact-broker-can-i-deploy**
URL: https://docs.pact.io/pact_broker/can_i_deploy
Accessed: 2026-08-07
Quote: The Broker tracks "which version of each application is in each environment"; `can-i-deploy` checks for "a successful verification result" between the candidate version and everything already deployed.

**pact-faq**
URL: https://docs.pact.io/faq
Accessed: 2026-08-07
Quote: "Pact is most valuable for designing and testing integrations where you (or your team/organisation/partner organisation) control the development of both the consumer and the provider." Explicitly excludes "Situations where you cannot load data into the provider without using the API that you're actually testing (e.g. public APIs)."

**vcr-re-record-interval**
URL: https://rubydoc.info/gems/vcr/VCR/Cassette (supplemented by https://andrewmcodes.gitbook.io/vcr/cassettes/automatic_re_recording)
Accessed: 2026-08-07
Quote: `re_record_interval` — "How frequently (in seconds) the cassette should be re-recorded." "Over time, your cassettes may get out-of-date. APIs change and sites you scrape get updated." Mechanism re-records (overwrites) once the interval elapses; no diff-and-alert on divergence.

**nock-docs**
URL: https://github.com/nock/nock (nockBack documentation)
Accessed: 2026-08-07
Quote: `nockBack` modes `wild`/`record`/`update` are manual/on-demand only; no time-based or drift-detection mechanism documented.

**msw-keeping-mocks-in-sync**
URL: https://mswjs.io/docs/recipes/keeping-mocks-in-sync/
Accessed: 2026-08-07
Quote: "You write mocks to describe a server behavior fixed in time. But as time goes on, that behavior may change, potentially rendering your mocks obsolete." "Treating the backend runtime as the truth is prone to issues as the backend may introduce faulty runtime behavior that violates the intended specification."

## SYNTHESIS

Two separate questions get answered here, and they should stay separate.

**Tier promotion (Home Assistant vs. Airbyte vs. a `proven`/`unproven` vocabulary):** Home Assistant is the better model than Airbyte for a project that already has an evidence-level vocabulary. Airbyte's Certified/Community split (established in prior corpus research: [[airbyte-cat-and-singer-sdk-primary-source-verification-2026-08-07]]) promotes on *usage* (distinct-workspace count), which has no analog for a personal-data tool with one operator and no workspace concept. Home Assistant instead promotes per *rule*, and roughly half its rules are machine-checkable today via `hassfest` — a real, running, per-rule linter that greps source for specific code shapes and requires a written justification for any claimed exemption. The other half (doc clarity, "does the UX feel right") stays a human PR review. This maps directly onto the shape of the mock-mutation gate already built in this repo: PASS/WEAK/UNKNOWN is exactly a `hassfest`-style per-check machine verdict, and it should feed tier promotion the same way — a rule passes automatically, a human still signs off on the tier bump itself, and an exemption requires a written reason in the repo, not a silent skip.

**The credential problem:** every mature platform surveyed either (a) pays for and hosts its own realistic sandbox with deterministic seeded data (Plaid `user_good`/`pass_good`, Stripe's per-sandbox test keys and canned decline codes), or (b) requires the *contributor* to supply real production-endpoint credentials under a platform-controlled test account (Zapier's `integration-testing@zapier.com`), or (c) requires real live cloud credentials with no mocking path at all (Terraform, recommending providers keep a dedicated live test account). Nobody in this survey solves the credential problem for free — someone always pays, either the platform (Plaid/Stripe, because the sandbox *is* the product surface) or the contributor (Zapier, Terraform, because the provider is a third party the platform doesn't operate). This repo's situation — many connectors hitting third-party consumer APIs (Jellyfin, Gmail, USAA, etc.) the project doesn't control and can't hosted-sandbox — structurally matches the Terraform/Zapier shape, not the Plaid/Stripe shape. There is no version of this problem where a conformance suite alone solves live-credential testing; the repo's own design note reaches the identical conclusion independently, and this research confirms it's not a solved problem elsewhere either.

**The Jellyfin-class mock (same author, same mistake):** this is the sharpest finding. Pact's entire architecture is built to solve a *different*, adjacent problem — two independent parties (consumer team, provider team) whose assumptions can drift apart, caught by replaying the consumer's expectations against the real, live provider. That mechanism is real and effective for its intended shape, but Pact's own FAQ rules out exactly this repo's use case: a public third-party API the project doesn't operate, where there's no "provider team" to run verification. VCR's `re_record_interval` and MSW's "keeping mocks in sync" page both name a real problem — but it's temporal drift ("the API changed since we recorded"), which presupposes the original recording was correct when made. None of the five tools surveyed (Pact, VCR, nock, Polly.js by extension, MSW) has a documented mechanism for a mock that was wrong from the moment it was written, because its author shared the same misunderstanding as the code's author. This is a genuine, unaddressed gap across the entire contract-testing and cassette-replay space, not a tooling failure specific to this repo. The only structural defense implied (never stated) by any of these tools is Pact's core insight generalized: introduce a genuinely independent second source of truth — a real unauthenticated round-trip (this repo's `connector-reachability.mjs`), a captured-from-a-different-session fixture, or a spec the author didn't write (MSW's OpenAPI-first recommendation, `apple_contacts`'s RFC-6352-derived test server already in this repo) — rather than trying to test the mock harder with more assertions from the same mental model.
