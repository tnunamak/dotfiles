---
title: "Geth recovery must match sync mode and state scheme, while signer-bearing snapshots require an isolated data-only trust boundary"
date: 2026-08-11
topic: distributed-systems
tags: [geth, ethereum, gcp, snapshots, disaster-recovery, validator-safety]
status: draft
sources: [geth-sync-modes, geth-archive-mode, geth-databases, gcp-snapshot-best-practices, gcp-restore-snapshot, gcp-instant-snapshots, gcloud-disks-create, e2fsck]
source_session: 0e6bb946-8816-4af7-b245-105863408163
---

## CLAIMS

- Geth snap sync starts from a recent checkpoint, downloads state, and is substantially faster than full block-by-block execution from genesis; it is the default sync mode. [geth-sync-modes]
- Geth full sync executes every block from genesis, while an archive node retains historical state rather than pruning it. [geth-sync-modes]
- Geth documents a legacy hash-scheme archive as `--state.scheme=hash --gcmode=archive --syncmode=full`. [geth-archive-mode]
- Geth documents a path-scheme archive that retains all historical state as `--history.state=0 --gcmode=archive --syncmode=full`; `--history.state=0` is therefore part of the archive contract, not an optional performance setting. [geth-archive-mode]
- Geth keeps recent chain and state data separately from older blocks and receipts in the freezer, or `ancients`, database; the default freezer location is inside `chaindata`, and starting Geth with a missing or invalid freezer path is explicitly unsupported. [geth-databases]
- A Compute Engine snapshot taken while an application is writing is crash-consistent, not application-consistent, and recovery can require replaying filesystem or application journals. Google recommends testing restoration against workload-level correctness requirements. [gcp-snapshot-best-practices]
- Compute Engine can restore a standard snapshot into a zonal disk in another zone, but the restored disk cannot be smaller than the snapshot's source disk. [gcp-restore-snapshot]
- A Compute Engine instant snapshot is crash-consistent and is stored in the same zone as its source disk. [gcp-instant-snapshots]
- `gcloud compute disks create --source-disk` clones a disk only within its zone or region; cross-zone copying uses a snapshot and `--source-snapshot`. [gcloud-disks-create]
- For `e2fsck`, exit status 0 means no filesystem errors and 1 means errors were corrected; statuses 2 and above indicate reboot requirements, uncorrected errors, operational failure, usage error, or cancellation. [e2fsck]

## SOURCES

**geth-sync-modes**
URL: https://geth.ethereum.org/docs/fundamentals/sync-modes
Accessed: 2026-08-11

**geth-archive-mode**
URL: https://geth.ethereum.org/docs/fundamentals/archive
Accessed: 2026-08-11

**geth-databases**
URL: https://geth.ethereum.org/docs/fundamentals/databases
Accessed: 2026-08-11

**gcp-snapshot-best-practices**
URL: https://docs.cloud.google.com/compute/docs/disks/snapshot-best-practices
Accessed: 2026-08-11

**gcp-restore-snapshot**
URL: https://docs.cloud.google.com/compute/docs/disks/restore-snapshot
Accessed: 2026-08-11

**gcp-instant-snapshots**
URL: https://docs.cloud.google.com/compute/docs/disks/create-instant-snapshots
Accessed: 2026-08-11

**gcloud-disks-create**
URL: https://docs.cloud.google.com/sdk/gcloud/reference/compute/disks/create
Accessed: 2026-08-11

**e2fsck**
URL: https://man7.org/linux/man-pages/man8/e2fsck.8.html
Accessed: 2026-08-11

## SYNTHESIS

Sync mode, state scheme, history retention, Geth version, and database contents form one compatibility contract. Do not treat these as independent deployment toggles.

For a new or disposable ordinary execution node, use snap sync and the current path state scheme. Copying a large archive database into such a node is slower, consumes more storage, and gives the node a database whose retention contract it does not need.

For an archive node, choose one of two explicit paths:

| Goal | Database source | Initial runtime contract |
| --- | --- | --- |
| Build a new path-scheme archive | Empty data directory | Full sync, path scheme, archive garbage-collection mode, and unlimited state history (`history.state=0`) |
| Recover quickly from a legacy hash archive | Verified copy of that archive's complete `chaindata` | Match the source Geth version and run full sync, hash scheme, and archive garbage-collection mode |

Do not start a path-configured Geth process against a copied hash-scheme archive. Treat the state scheme as backup metadata. A fast hash-archive recovery and a long-term path-archive migration are separate changes with separate rollback points; no in-place hash-to-path conversion was proven in this research.

### Safe snapshot-to-chaindata procedure

1. Snapshot the source disk without stopping the validator or beacon client. Treat the result as crash-consistent and secret-bearing.
2. Restore the snapshot to a disposable disk of equal or greater size. Attach it as a non-boot data disk to a clean helper VM with no public IP. Never boot the signer-bearing snapshot: a cloned boot disk can contain validator keys, slashing-protection data, wallets, node identity keys, and service definitions capable of starting a duplicate signer.
3. With the restored filesystem unmounted, run `e2fsck` on the disposable clone to replay its journal. Continue only for exit status 0 or 1. Any higher status is a stop condition for investigation, not permission to copy.
4. Mount the repaired clone read-only with `ro,noload,nodev,nosuid,noexec`. Confirm the expected filesystem UUID, source path, chain identity, and available capacity before reading data.
5. Verify that `chaindata` includes a non-empty `ancient` or configured freezer location. Copy only an explicit execution-data allowlist, normally `execution/geth/chaindata`, including its freezer. Do not copy the execution root, validator or consensus directories, keystores, wallets, JWT files, bootnode keys, system configuration, or service units.
6. Keep the target's previous execution database under a reversible name. Copy into a fresh destination, preserve ownership, and run a checksum-based `rsync --dry-run` between source and destination; zero proposed transfers is the integrity gate.
7. Start only the target execution client with the source-compatible storage contract. Verify the chain ID, canonical head and state availability, freezer access, peer connectivity, and sync progress before reconnecting consumers. Independently verify that no validator process or signer material exists on the helper or target execution-only path.

Rollback is local and mechanical: stop the target execution client, move the imported database aside, restore the previous database name, and restore the previous runtime flags. The validator and beacon client remain live throughout because the procedure does not replace their disks, keys, databases, or services.

The important boundary is not “snapshot versus rsync.” It is code versus data and signer versus non-signer. A whole boot-disk image is a recovery source, not a runnable machine image; only the allowlisted execution database crosses that boundary.
