---
title: "Institutional Ethereum staking operators split on validator-signing-key custody: Coinbase and Kiln run remote signers (Web3Signer/custom) with a shared anti-slashing DB, Web3Signer itself supports fetching keys from Vault/Azure/AWS (no manual export/import required), but Attestant/AWS-Cubist both independently confirm a single remote signer is a real SPOF that requires clustering (Dirk) or threshold signing (DVT) to fully mitigate"
date: 2026-08-10
topic: validator-key-custody
tags: [ethereum, staking, validator, bls12-381, web3signer, dirk, vouch, dvt, hsm, kms]
status: draft
sources:
  - coinbase-institutional-dsp
  - coinbase-beacon-node-blog
  - web3signer-vault-docs
  - web3signer-slashing-db-docs
  - kiln-web3signer-holesky
  - attestant-protecting-validator-keys
  - attestant-introducing-dirk
  - aws-cubist-cubesigner
  - eip-3076
  - obol-charon-performance
  - sigmaprime-lighthouse-remote-signing
  - kraken-ssv-dvt
  - bssc-kms-spec
source_session: 02d16fad-5b89-4da2-bcfc-53ef8471d46c
---

## CLAIMS

- Cloud KMS (AWS KMS, and by extension GCP KMS) cannot sign Ethereum validator (consensus-layer) messages directly because those services support secp256k1/NIST curves and RSA but not BLS12-381, the curve Ethereum validators use; AWS's own engineers state this is a "regulatory/NIST-alignment" gap in HSM firmware, not a missing SDK feature [aws-cubist-cubesigner]. AWS KMS added Ed25519/EdDSA support in Nov 2025, which still does not add BLS12-381 [general-knowledge-web-search].
- Coinbase's institutional staking product (Coinbase Prime, as of a Nov 14 2025 published article) explicitly uses a remote signer for Ethereum validators: "a highly secure remote signer stores validator private keys and uses a high watermark... to reject any new signing requests that are older than or conflict with that record," layered with a per-validator-client local anti-slashing DB and Kubernetes-level guarantees that a key loads on only one node at a time [coinbase-institutional-dsp].
- A separate, earlier (June 2024) Coinbase engineering post about their staking node architecture redesign is about a different problem (sharing beacon nodes across many validator clients for cost/resilience) and explicitly states signing keys live on the validator client in that design, with beacon nodes only broadcasting already-signed messages — this post does NOT describe a remote-signer-for-keys architecture and should not be conflated with the DSP post above [coinbase-beacon-node-blog].
- Web3Signer (Consensys) supports fetching BLS validator keys directly from HashiCorp Vault (KV v2), Azure Key Vault, and AWS Secrets Manager as key sources — configured via a `type` field (`hashicorp`, `azure-secret`, `aws-secret`) in its key-config file, or bulk-loaded via CLI flags — with Web3Signer fetching the key from the backend and signing locally, not requiring a human to manually export/import key material on each use [web3signer-vault-docs].
- Web3Signer's slashing protection database is PostgreSQL, and multiple Web3Signer instances can safely connect to the *same* shared Postgres database concurrently; Consensys's own "run at scale" docs recommend exactly this shared-DB, multi-instance pattern and note it is made safe by row-level database locking (only one instance signs for a given key at a time) [web3signer-slashing-db-docs].
- Kiln (a top-tier institutional staking operator, ~5%+ of all Ethereum validators, SOC2 Type 2) published a detailed engineering post on running Web3Signer at scale (~100k validators on the Holesky testnet) using exactly the shared-Postgres, multi-instance-fleet architecture described above. They found the design works but is latency-sensitive to the network distance between Web3Signer instances and the shared DB (each signing request holds a locking SQL transaction with several sub-queries; ~50ms DB latency caused queueing/timeouts), which they resolved by tuning Web3Signer's internal thread pool (`-Xworker-thread-pool`, added at their request by the Consensys team) and adding an ingress load balancer [kiln-web3signer-holesky].
- Attestant (founder Jim McDonald, pre-Bitwise-acquisition post from 2020, still their published architecture rationale) explicitly names a single remote signer as "a single point of failure: if it is attacked, or merely suffers a failure, it results in the user being unable to sign the desirable messages" — and presents threshold signing / distributed key generation (DVT) as the next layer specifically to solve that SPOF, while affirming standalone remote signing already buys real security/availability wins over local keystores [attestant-protecting-validator-keys].
- Attestant's production Dirk/Vouch deployment addresses the SPOF by running Dirk as multiple redundant instances (a single Vouch validator client talks to several Dirk signers); this is operationally a clustered-software-signer pattern, not HSM-backed or threshold BLS signing by default — Dirk's resilience comes from redundant plain instances, and zero-downtime upgrades are done by cycling one Dirk instance at a time while ≥3 others remain live [attestant-dirk-vouch — inferred from search-summarized Attestant blog content, not independently re-verified against raw source; treat as PLAUSIBLE not fully verified].
- An independent (AWS/Cubist, authors are a CMU professor + UCSD professor + AWS architect) technical blog directly corroborates Luganodes' SPOF argument in general form: "simply using an off-the-shelf signer like Web3Signer doesn't give you these properties [security/correctness/availability] ... the remote signer must itself be highly available and fault-tolerant, and it must use a global, highly available, anti-slashing database; otherwise, signer or OS updates, machine failures, or network interruptions could result in slashing events" [aws-cubist-cubesigner]. This is real, credible, non-Luganodes-authored evidence that a *single* remote signer instance is a legitimate risk — the rebuttal is that the shared-Postgres pattern (Web3Signer, Kiln-proven) and Dirk's multi-instance pattern (Attestant) are the standard fixes, not evidence that remote signing itself is unsound.
- EIP-3076 ("Slashing Protection Interchange Format") is a real, adopted standard (Prysm, Lighthouse, Teku, Nimbus, Lodestar all implement it) for portably migrating a validator's slashing-protection history (signed blocks/attestations) between clients/machines during key migration — it does not itself provide live cross-instance slashing protection; that's what the shared-DB pattern (Web3Signer+Postgres) or CubeSigner's DynamoDB-based reference monitor exist to do instead [eip-3076, aws-cubist-cubesigner].
- Prysm's local slashing-protection database is per-instance/local by design (not shared across machines); this is precisely why "doppelganger protection" and careful migration procedure (export/import via EIP-3076, wait for confirmation before restart) exist as manual safeguards for single-keystore-on-host operators moving keys between hosts [general-knowledge, corroborated by EIP-3076 sources describing per-client local DBs and interchange format purpose].
- Kraken fully deployed SSV Network DVT across its entire Ethereum staking infrastructure (reported as a "first major exchange" milestone), splitting validator keys into threshold shares across independent operators rather than using a remote signer or single-host keystore model at all [kraken-ssv-dvt].
- DVT (Obol/SSV) reached genuine institutional-scale production validation in 2026: the Ethereum Foundation deployed 72,000 ETH using "DVT-lite" (Obol) in March 2026; Lido's Simple DVT module (Obol + SSV clusters) has run on mainnet since April 2024; independent performance testing (MigaLabs, for Obol/Charon) found attestation/block-proposal performance within ~1% of traditional non-distributed validators, provided intra-cluster latency stays under ~235ms; Charon middleware itself adds under 500MB RAM and minimal CPU overhead [obol-charon-performance, kraken-ssv-dvt].
- No source found states a numeric industry-standard cap on "validators per host/key-holder" — the community consensus (P2P.org, Forbes, industry analyses) frames concentration risk in terms of *correlated* failure (one compromised host/config bug/cloud outage can affect every validator on it, and Ethereum's slashing correlation penalty scales with total ETH slashed network-wide in the surrounding window, so correlated slashing is disproportionately punished vs. independent slashing) rather than a fixed keys-per-host number [general web search, no single primary standards source found — NOT FOUND for a hard numeric threshold].
- The BSSC "Key Management Standard for Blockchains" (specs.blockchainssc.org/kms/) is algorithm/key-type agnostic — it does not distinguish BLS/validator keys from secp256k1/wallet keys, and gives only general architecture-agnostic guidance (HSM or FIPS 140 L3 secure element or encrypted DB with strong access controls; owner-approval requirement if a third party manages the key) rather than a specific remote-signer-vs-local-keystore recommendation [bssc-kms-spec].
- No joint or individual published opinion letter was found from Trail of Bits, Sigma Prime, or Least Authority specifically adjudicating "remote signer vs. local keystore" as a validator-key-custody question. Sigma Prime's Lighthouse documentation is reported (via secondary search summary only, NOT independently verified against the raw doc, which returned HTTP 403 to direct fetch) to state that remote signing "introduces a new set of security and slashing risks and should only be undertaken by advanced users" and that Lighthouse (Sigma Prime) does not maintain or vouch for Web3Signer's safety since it's a Consensys/Teku-team product — this claim is PLAUSIBLE given Sigma Prime's general posture as client authors rather than signer-safety auditors, but could not be confirmed verbatim from a primary source in this research pass [sigmaprime-lighthouse-remote-signing — UNVERIFIED, secondary-source only].

## SOURCES

**coinbase-institutional-dsp**
URL: https://www.coinbase.com/institutional/research-insights/resources/overviews/how-coinbase-protects-staked-assets
Accessed: 2026-08-10
Quote: "We employ a layered security approach that combines local state tracking, infrastructure-level primitives, and remote signing with high watermarks... For our Ethereum validators, a highly secure remote signer stores validator private keys and uses a high watermark (a record of the last valid action) to reject any new signing requests that are older than or conflict with that record."

**coinbase-beacon-node-blog**
URL: https://www.coinbase.com/developer-platform/discover/solutions/ethereum-staking-node
Accessed: 2026-08-10
Quote: "Since the signing keys are on the validator client and the beacon node is only used to broadcast the transaction once signed, this does not introduce any additional risk of double-signing."

**web3signer-vault-docs**
URL: https://docs.web3signer.consensys.io/how-to/store-keys/vaults/hashicorp ; https://docs.web3signer.consensys.io/how-to/store-keys/vaults/azure ; https://docs.web3signer.consensys.io/how-to/store-keys/vaults/aws
Accessed: 2026-08-10
Quote: "The azure-secret type has Web3Signer fetch the keys from the vault and sign locally, supporting SECP256K1 and BLS12-381 signing keys." (via search-engine summary of official docs; TOML `type = "hashicorp"` config directly confirmed in same docs tree)

**web3signer-slashing-db-docs**
URL: https://docs.web3signer.consensys.io/how-to/run-at-scale ; https://docs.web3signer.consensys.io/how-to/configure-slashing-protection ; https://docs.web3signer.consensys.io/concepts/architecture
Accessed: 2026-08-10
Quote: "Connect all Web3Signer instances to the same slashing database. This allows parallel signing without slashing risk... Database locking ensures that when multiple Web3Signer instances load the same keys, only one instance is permitted to sign."

**kiln-web3signer-holesky**
URL: https://www.kiln.fi/post/learnings-from-running-web3signer-at-scale-on-holesky
Accessed: 2026-08-10
Quote: "This document describes the infrastructure setup for running validation at scale using Web3Signer, which we put in place at Kiln to run our ~100k Holesky validators... Whenever a validator client reaches out to Web3Signer... Web3Signer sends a transaction to the database, which first locks the validator to check... increasing the latency between Web3Signer and the database will have a ~5x impact on the overall signing latency."

**attestant-protecting-validator-keys**
URL: https://www.attestant.io/posts/protecting-validator-keys/
Accessed: 2026-08-10
Quote: "However, the fact remains that the remote signer is a single point of failure: if it is attacked, or merely suffers a failure, it results in the user being unable to sign the desirable messages."

**attestant-dirk-vouch**
URL: https://www.attestant.io/posts/introducing-dirk/ ; https://github.com/attestantio/vouch/blob/master/README.md
Accessed: 2026-08-10 (via search-engine summary; not independently re-fetched raw)
Quote (as summarized): "In Attestant's actual production setup, a single Vouch instance talks to multiple Dirk signers for redundancy... a single Dirk signer can be stopped, upgraded and restarted without downtime... as long as there are at least 3 other signers running."

**aws-cubist-cubesigner**
URL: https://aws.amazon.com/blogs/web3/use-aws-nitro-enclaves-to-build-cubist-cubesigner-a-secure-and-highly-reliable-key-management-platform-for-ethereum-validators-and-beyond/
Accessed: 2026-08-10
Quote: "The remote signer must itself be highly available and fault-tolerant, and it must use a global, highly available, anti-slashing database; otherwise, signer or OS updates, machine failures, or network interruptions could result in slashing events... HSMs don't yet support BLS because of regulatory challenges aligning with the National Institute of Standards and Technology (NIST)."

**eip-3076**
URL: https://eips.ethereum.org/EIPS/eip-3076
Accessed: 2026-08-10
Quote: "EIP-3076: Slashing Protection Interchange Format" — JSON interchange format for proof of stake validators to migrate slashing protection data between clients; version 5; implemented by Prysm, Lighthouse, Teku, Nimbus.

**obol-charon-performance**
URL: https://blog.obol.org/performance-testing-distributed-validators/ ; https://blog.obol.org/lido-simple-dvt-wave-1-testing-complete/
Accessed: 2026-08-10
Quote (as summarized): "For critical indicators like attestation duties, block proposals, and achieved rewards, the difference between Obol DVs and traditional validators was under 1%... it is recommended to keep intra-cluster latency below 235 milliseconds for all nodes."

**sigmaprime-lighthouse-remote-signing**
URL: https://lighthouse-book.sigmaprime.io/validator-web3signer.html
Accessed: 2026-08-10 — fetch returned HTTP 403 (bot detection), content only available via search-engine summary, NOT independently verified verbatim.
Quote (unverified, per search summary): "Using a remote signer introduces a new set of security and slashing risks and should only be undertaken by advanced users who fully understand the risks... the Lighthouse team (Sigma Prime) does not maintain Web3Signer or make any guarantees about its safety or effectiveness."

**kraken-ssv-dvt**
URL: https://www.theblock.co/post/367922/kraken-distributed-validator-ethereum-staking
Accessed: 2026-08-10
Quote (as summarized): "Kraken says it is the first major exchange to fully deploy distributed validator technology for Ethereum staking, using SSV Network... now live across all of Kraken's Ethereum staking infrastructure."

**bssc-kms-spec**
URL: https://specs.blockchainssc.org/kms/
Accessed: 2026-08-10
Quote: "Keys SHOULD be stored in Hardware Security Modules (HSMs) OR on secure elements with FIPS 140 L3 certifications OR in encrypted databases with strong access controls" — algorithm-agnostic, no BLS/validator-specific carve-out.

## SYNTHESIS

The honest finding is that almost nobody publishes a full validator-key-custody architecture, and the few who do (Coinbase, Kiln, Attestant, Cubist/AWS) show a *split*, not a consensus, that maps closely onto the Luganodes debate:

1. **"Remote signer is unsafe/SPOF" is not a Luganodes-only claim** — it's independently made by Attestant's own founder and by AWS/Cubist's engineers, for the same reason: a lone signer instance is a liveness risk. This part of Luganodes' argument is defensible and grounded, not self-serving spin.
2. **But the standard industry fix for that SPOF is redundancy of the remote signer, not abandoning remote signing for keystore-on-host.** Every credible source that raises the SPOF concern (Attestant, Cubist) pairs it with a *clustering* solution (multiple Dirk instances, or Web3Signer instances behind a shared Postgres DB) — not a retreat to single-host local keystores. Coinbase and Kiln (two of the largest, most technically sophisticated operators in the ecosystem) run exactly the shared-DB clustered-remote-signer pattern Luganodes rejected, at far larger scale (Kiln: ~100k validators) than Vana's 21.
3. **Luganodes' specific claim that Web3Signer "requires export/import so a human touches key material every time" does not hold for the Vault/Azure/AWS-backed configurations** — Web3Signer fetches keys from those backends and signs; no human handling is required per signature or per restart. It may be true that Luganodes' *own* deployment pattern (perhaps file-based keys without a vault backend) requires manual handling — but that's an argument about their specific implementation choice, not an inherent Web3Signer limitation.
4. **The strongest argument for keystore-on-host at Vana's scale (21 validators/5 nodes) is operational simplicity and Luganodes' own team's familiarity/maturity with it**, not that it's provably safer. The correlated-slashing-risk literature actually cuts somewhat against concentrating many keys per host (which Vana's ~4 keys/host setup does, at a scale too small to have hard published norms either way).
5. **DVT (Obol/SSV) is the only approach in the survey that structurally removes the "any single machine has the whole key" problem** rather than trading it for a different SPOF, and by 2026 has real institutional-scale proof points (Kraken's full production deployment, EF's 72k ETH DVT-lite stake, Lido's 2+ year mainnet Simple DVT track record, MigaLabs' independent <1% performance-parity benchmarks). For a company sizing up a "load-bearing architecture decision," DVT is worth a serious second look rather than treating the choice as binary between Web3Signer and local keystores — though it adds real operational complexity (coordination across independent node operators) that a 5-node/21-validator shop should weigh honestly against its team's DVT unfamiliarity.

The one thing that should be flagged back to whoever is evaluating Luganodes' recommendation: ask Luganodes directly whether their Web3Signer aversion is about the *protocol* (in which case the Vault-backed / shared-Postgres counterevidence above is a fair challenge) or about *their own* operational maturity running Web3Signer at HA (in which case "we're not confident running clustered Web3Signer well" is a legitimate, if different, argument — and Dirk/Vouch migration, which Luganodes says they're already doing for other clients, is the appropriate hedge either way).
