---
title: "cgroup v2 (and v1) effective cpu.max/memory.max for a process is the MINIMUM across every ancestor cgroup in its path, not the value in the nearest ancestor file that happens to exist"
date: 2026-08-10
topic: linux-cgroups
tags: [cgroups, cgroup-v2, cgroup-v1, cpu-quota, memory-quota, systemd, containers, kernel-scheduler]
status: draft
sources: [kernel-cgroup-v2-rst, kernel-cfs-bandwidth-doc, community-writeups]
source_session: 58f47f9f-f8a6-4edd-9918-32d2f007026d
---

## CLAIMS

- cgroup v2 distributes resources top-down; a cgroup can only sub-distribute a resource it was itself given by its parent [kernel-cgroup-v2-rst].
- The CFS bandwidth controller's own invariant is `max(c_i) <= C` for children under a parent C — a child's own quota file can be numerically set higher than what its parent actually grants, but the kernel still enforces the parent's tighter ceiling; a child cannot exceed an ancestor's limit regardless of its own file's value [kernel-cfs-bandwidth-doc].
- Community technical write-ups converge on the same operational statement: "a child cgroup's effective quota is the minimum of its own quota and its ancestors' quotas" for both `cpu.max` and `memory.max`/`memory.high` [community-writeups].
- Live-reproduced on a real Linux host (2026-08-10, this session) with genuine nested systemd cgroups: a slice's `cpu.max` set to `10000 100000` (0.1 core) with a child scope's own `cpu.max` set to `400000 100000` (4.0 cores) — the leaf file reads 4.0 cores, but a 3-second busy-loop inside that leaf completed only ~67 iterations, consistent with ~0.1-core throttling, not 4.0-core. The kernel enforces the tighter ancestor; the leaf's own file value is not the effective quota. [local-repro]
- Consequence for any userspace "resolve my effective quota" reader: walking from the process's leaf cgroup toward the mount root and returning the value from the *first* ancestor that has the quota file (nearest-file-wins) is unsound whenever a nearer ancestor's own quota is numerically looser than a farther ancestor's. The mathematically correct read is the minimum resolved value across *every* ancestor that has the file, not the nearest one. [derived]

## SOURCES

**kernel-cgroup-v2-rst**
URL: https://raw.githubusercontent.com/torvalds/linux/master/Documentation/admin-guide/cgroup-v2.rst
Accessed: 2026-08-10
Quote: "Resources are distributed top-down and a cgroup can further distribute a resource only if the resource has been distributed to it from the parent."

**kernel-cfs-bandwidth-doc**
URL: https://docs.kernel.org/scheduler/sched-bwc.html
Accessed: 2026-08-10
Quote: "The interface enforces that an individual entity's bandwidth is always attainable, that is: max(c_i) <= C." (referring to per-child bandwidth `c_i` bounded by parent `C`; over-subscription in the aggregate/declared sense is permitted, but the enforced/effective bandwidth is still capped by the parent.)

**community-writeups**
URL: (aggregate of search results, see WebSearch "cgroup v2 cpu.max effective quota hierarchical enforcement child looser than parent", 2026-08-10)
Accessed: 2026-08-10
Quote: "a child cgroup always exists inside a parent cgroup and can never exceed its parent's limits — even if the child's own limit is set higher... the effective enforced quota is always the minimum across the ancestor chain."

**local-repro**
URL: n/a (live command output, this session, dev sandbox)
Accessed: 2026-08-10
Quote: "leaf cpu.max: 400000 100000 / parent cpu.max: 10000 100000 / iterations: 67" (3-second busy loop, systemd-run --user nested slice+scope, `systemctl --user set-property <slice> CPUQuota=10%` on the parent slice, `-p CPUQuota=400%` on the child scope)

## SYNTHESIS

This resolves, with a live kernel-level reproduction (not just documentation reading), a hypothesis about a specific PDP-Connect `cpu-quota.ts` implementation (commit 78b58fc78, reference-implementation/server/cpu-quota.ts) that walks a process's cgroup ancestor chain and returns the quota from the **nearest** ancestor with the file present, described in that commit's own comments as sound "by cgroup v2's own delegation invariant (a descendant's limit can only be tighter than or equal to any ancestor's, never looser)." That stated invariant is false as a constraint on the *values written in each level's own file* — nothing stops an administrator, systemd unit config, or container runtime from writing a numerically looser `cpu.max`/`cpu.cfs_quota_us` at a child level than a parent has, and the kernel does not reject such a write. What IS true is that the kernel's *enforcement* still honors the tightest ancestor regardless. So nearest-file-wins can read a looser child value and silently under-constrain a userspace concurrency sizer even though the kernel itself would still throttle the process correctly — the userspace reader's belief about its own quota becomes wrong, over-provisioning worker/thread counts relative to what the kernel will actually allow. The correct algorithm is: for each ancestor from leaf to mount root that has the quota file, parse it, and take the **minimum** resolved value across all of them (treating "unlimited"/missing as not participating in the min) — not the first one found.
