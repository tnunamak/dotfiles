---
title: "An immutable reusable workflow can combine required lexical secret scanning with optional verification in a second job without a second caller"
date: 2026-08-11
topic: repo-hygiene-and-secret-scanning
tags: [secret-scanning, verification, github-actions, reusable-workflows, supply-chain]
status: draft
sources: [gitguardian-layered-sdlc, trufflehog-verification, trufflehog-custom-detectors, github-secure-use, github-job-context, github-reuse-workflows, eip-1474]
source_session: unknown
---

## CLAIMS

- GitGuardian recommends secret scanning at multiple SDLC stages: remote VCS monitoring, CI, developer-workstation hooks, and (where self-hosted) pre-receive hooks. [gitguardian-layered-sdlc]
- TruffleHog permits verification to be enabled or disabled per detector, independently of detection. [trufflehog-verification]
- TruffleHog custom detectors pair regex and keyword detection with an optional verification endpoint; a matching response status marks the detected secret verified. [trufflehog-custom-detectors]
- GitHub says a full-length commit SHA is the only immutable release reference for an action and applies the same guidance to reusable workflows. [github-secure-use]
- In a reusable workflow, `job.workflow_repository` and `job.workflow_sha` identify the repository and commit defining the current job; GitHub documents checking out those exact values to access co-located workflow files. These properties are unavailable on GitHub Enterprise Server. [github-job-context]
- A reusable workflow can define multiple jobs, and GitHub permits callers to invoke reusable workflows directly as jobs. [github-reuse-workflows]
- Ethereum JSON-RPC quantities must use a lowercase `0x` prefix and the shortest hexadecimal representation; zero is `0x0`, and leading zeroes are invalid. [eip-1474]

## SOURCES

**gitguardian-layered-sdlc**
URL: https://docs.gitguardian.com/secrets-detection/core-concepts/where-to-implement-secrets-detection
Accessed: 2026-08-11
Quote: "We recommend you add automated secrets scanning wherever you can, at every stage of the SDLC."

**trufflehog-verification**
URL: https://trufflesecurity.com/docs/customizing-detection
Accessed: 2026-08-11
Quote: "TruffleHog scanners running locally can optionally enable or disable verification for individual detectors."

**trufflehog-custom-detectors**
URL: https://trufflesecurity.com/docs/custom-detectors
Accessed: 2026-08-11
Quote: "When the verification server responds with a matching status code, the secret is marked as verified."

**github-secure-use**
URL: https://docs.github.com/en/actions/reference/security/secure-use
Accessed: 2026-08-11
Quote: "Pinning an action to a full-length commit SHA is currently the only way to use an action as an immutable release." The page says the same principles apply to reusable workflows.

**github-job-context**
URL: https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#job-context
Accessed: 2026-08-11
Quote: "This example reusable workflow uses `job.workflow_repository` and `job.workflow_sha` to check out its own source code, rather than the caller's repository."

**github-reuse-workflows**
URL: https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows
Accessed: 2026-08-11
Quote: "You can call multiple workflows, referencing each in a separate job."

**eip-1474**
URL: https://eips.ethereum.org/EIPS/eip-1474
Accessed: 2026-08-11
Quote: "A `Quantity` value MUST be expressed using the fewest possible hex digits per byte."

## SYNTHESIS

Use a deterministic lexical scanner as the required control. It must scan the complete intended commit range without network access, because a failed, slow, or unavailable liveness service cannot be allowed to turn a candidate into a pass. A chain-derived address/balance/nonce check is useful enrichment and triage, but a zero balance or nonce is not proof that a private scalar is harmless. Derive the address locally and send only that public address to an RPC; do not send a candidate private key to a generic verification webhook.

Put the optional verifier in a second job of the same reusable workflow, rather than in a separate caller or tool repository. One full caller SHA then binds lexical rules, verifier code, and policy configuration together; each job can independently check out that workflow repository at `job.workflow_sha`. This retains a single rollout/update surface and separates failure semantics: the lexical job blocks, while verifier failure can be advisory or scheduled.

Split into a separate workflow only when the verifier needs a materially different trust boundary, such as credentials, network access, permissions, retention, or ownership. GitHub Enterprise Server cannot use the `job.workflow_*` checkout pattern, so it needs an explicit, separately pinned policy reference instead.

Treat RPC responses as untrusted protocol input. Validate the JSON-RPC version and request ID, then parse block numbers, nonces, and balances only when they match EIP-1474's canonical quantity form. Otherwise, report the endpoint check as incomplete.
