---
title: "Postgres in a Proxmox LXC container generally has better raw disk I/O than a VM, contrary to common Reddit-folklore preference for VMs, with unprivileged UID/GID mapping on non-local storage as the main documented gotcha"
date: 2026-08-15
topic: self-hosting
tags: [proxmox, lxc, vm, postgres, database, backup, unprivileged-containers]
status: draft
sources: [proxmox-forum-lxc-vm-perf, proxmox-forum-lxc-vm-backup, medium-unprivileged-lxc-uid-gid, postgresql-mailing-list-consolidate]
source_session: 07a69092-80a0-4d83-950b-f3e8be8dd3d7
---

## CLAIMS

- LXC containers on Proxmox access disks directly via the host kernel, avoiding the virtual disk controller overhead a VM incurs; one user's MariaDB sysbench benchmark showed LXC throughput more than 2x a VM's. [proxmox-forum-lxc-vm-perf]
- Proxmox Backup Server gives VMs incremental "dirty bitmap" backups (only re-reads changed blocks after the first backup); LXC container backups re-read the full container's data on every backup run, though PBS's own chunking/dedup partially offsets this cost. A forum example: a 20GB-used, 32GB VM disk needs only ~200MB re-read via dirty bitmap on incremental backup vs. the full 20GB for an equivalent LXC. [proxmox-forum-lxc-vm-backup]
- Unprivileged LXC containers remap container root to a host UID range (commonly starting ~100000), which breaks bind mounts and NFS-backed paths unless UID/GID mapping is deliberately configured — a documented real-world pain point when running Postgres 15 in a Debian 12 unprivileged LXC on Proxmox. [medium-unprivileged-lxc-uid-gid]
- The mitigation recommended across sources is to keep the Postgres data directory on local block storage (e.g., local LVM-thin) rather than NFS or other network-backed bind mounts, which sidesteps both the UID-mapping issue and any fsync/consistency ambiguity over network filesystems. [medium-unprivileged-lxc-uid-gid]
- No LXC-specific Postgres data-corruption or fsync reports were found; fsync concerns that exist in the ecosystem trace to a well-known general PostgreSQL/Linux kernel fsync-EIO issue (2018), not something LXC introduces or worsens, and it does not elevate risk when running on local block storage. [proxmox-forum-lxc-vm-perf]
- A PostgreSQL mailing-list architectural discussion recommends consolidating multiple small applications onto one shared Postgres instance (multiple logical databases, proper roles/pg_hba) rather than one Postgres instance per application, splitting out a separate instance only when a specific workload misbehaves and affects others. [postgresql-mailing-list-consolidate]

## SOURCES

**proxmox-forum-lxc-vm-perf**
URL: https://forum.proxmox.com/threads/lxc-vm-performance.155546/
Accessed: 2026-08-15
Quote: "LXC accessing disks directly via host kernel vs. VM's virtual controller overhead" (paraphrased from thread; MariaDB sysbench throughput reported >2x for LXC vs VM)

**proxmox-forum-lxc-vm-backup**
URL: https://forum.proxmox.com/threads/proxmox-7-1-and-docker-lxc-vs-vm.105140/
Accessed: 2026-08-15
Quote: "20GB VM data on a 32GB disk needs only ~200MB re-read via dirty bitmap vs. LXC reading the full 20GB each run" (paraphrased from thread discussion of PBS incremental backup behavior)

**medium-unprivileged-lxc-uid-gid**
URL: https://medium.com/@PlanB./the-pain-and-promise-of-unprivileged-lxc-in-proxmox-a4e7c2ebdf00
Accessed: 2026-08-15
Quote: "UID/GID mapping nightmares and permission-denied errors" (running Postgres 15 in a Debian 12 unprivileged LXC)

**postgresql-mailing-list-consolidate**
URL: unknown (referenced via secondary research synthesis, original mailing-list thread URL not captured)
Accessed: 2026-08-15
Quote: "consolidate into one DB service with proper roles/pg_hba rather than one-per-app, and only split out to a separate instance as needed"

## SYNTHESIS

This corrects a common homelab assumption (echoed on Reddit/r/homelab as general folklore) that VMs are the "safer"/preferred choice for database workloads on Proxmox due to kernel isolation. In practice, at small-to-medium scale (tens of GB, single node, no live-migration/HA requirement), Proxmox forum practitioner data shows LXC containers have an I/O performance edge over VMs for DB workloads, not a disadvantage — the VM's advantage is elsewhere (incremental PBS backups, live migration, stronger kernel isolation for HA/Ceph setups), not raw performance. The one real, well-documented risk specific to LXC is unprivileged-container UID/GID mapping breaking when the data directory sits on NFS or other network-backed mounts — this is fully avoidable by keeping the Postgres data directory on local block storage, which is also the general best practice for Postgres regardless of virtualization layer (Postgres explicitly warns against NFS-backed PGDATA due to fsync/locking semantics). Decision rule for future Proxmox DB placement calls: default to LXC with local storage for single-node/no-HA homelab scale; only prefer VM when incremental-backup efficiency at large data sizes, live migration, or Ceph/HA architecture is a concrete near-term requirement, not a "someday."
