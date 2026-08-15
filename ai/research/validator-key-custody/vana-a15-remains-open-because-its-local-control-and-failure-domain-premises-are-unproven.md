---
title: "Vana A15 remains open because its local-control and failure-domain premises are unproven"
date: 2026-08-12
topic: validator-key-custody
tags: [vana, validator, web3signer, prysm, gcp, finality, slashing]
status: draft
sources:
  - vana-a15-proposal
  - ethereum-consensus-spec
  - web3signer-scale
  - web3signer-tls
  - web3signer-slashing
  - gcp-snapshot-security
  - gcp-compute-access
source_session: unknown
---

## CLAIMS

- Ethereum-style justification and finalization use attesting effective balance, not validator count: the specification requires target balance multiplied by 3 to be at least total active balance multiplied by 2 [ethereum-consensus-spec].
- Web3Signer documents multiple signer instances behind a load balancer sharing one slashing-protection database; its documentation says that this permits parallel signing without slashing risk [web3signer-scale].
- Web3Signer can authenticate an explicit set of clients with TLS certificate fingerprints [web3signer-tls].
- Web3Signer enables consensus-layer slashing protection by default and stores signing history in PostgreSQL for one or more signer instances [web3signer-slashing].
- Google warns that snapshot read permissions allow a principal to restore snapshot data into a project that the principal controls [gcp-snapshot-security].
- Google documents that Compute Instance Admin plus Service Account User can attach disks, alter instance metadata, and connect to instances; inherited project-level roles apply to child resources [gcp-compute-access].
- The Vana A15 proposal compares hardened local keystores with one clustered signer topology that puts all ten keys behind a shared database, but it does not compare independently partitioned signer cells [vana-a15-proposal].
- The proposal's ordinary weighted total favors the remote-signer rows 8 to 6, while its prose instead applies an unstated lexicographic rule in which any weight-3 item outranks any number of lower-weight items [vana-a15-proposal].

## SOURCES

**vana-a15-proposal**
URL: https://docs.google.com/document/d/14IJDbQV8LHtpv5jvDua-Eh7TwmDNydkXZYweSli2zuI/edit?tab=t.sp9cbyjj59xf
Accessed: 2026-08-12

**ethereum-consensus-spec**
URL: https://ethereum.github.io/consensus-specs/specs/phase0/beacon-chain/#weigh-justification-and-finalization
Accessed: 2026-08-12

**web3signer-scale**
URL: https://docs.web3signer.consensys.io/how-to/run-at-scale
Accessed: 2026-08-12

**web3signer-tls**
URL: https://docs.web3signer.consensys.io/how-to/configure-tls
Accessed: 2026-08-12

**web3signer-slashing**
URL: https://docs.web3signer.consensys.io/how-to/configure-slashing-protection
Accessed: 2026-08-12

**gcp-snapshot-security**
URL: https://cloud.google.com/compute/docs/disks/snapshot-best-practices#security_considerations
Accessed: 2026-08-12

**gcp-compute-access**
URL: https://cloud.google.com/compute/docs/access/iam
Accessed: 2026-08-12

## SYNTHESIS

The document does not yet justify a final architecture decision. Its strongest local-keystore advantage depends on two unproved premises: that removing selected permissions removes the cloud-control-plane path to raw keys, and that remote signing requires one shared failure domain for all Vana validators. The first needs an effective privilege graph, including who can restore permissions; the second disappears if signer and database cells are partitioned across disjoint key sets.

Use hardened local keystores as the urgent interim rotation path. Keep A15 open until Vana verifies effective-balance headroom, withdrawal custody, key/seed/backup mapping, and the actual GCP privilege boundary, then compares the local design with a partitioned signer design through a Moksha failure-injection exercise.
