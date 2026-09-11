---
title: "A VFIO/PCI-passthrough VM keeps host QEMU RSS pinned at the memory ceiling while the guest balloon still inflates, because QEMU silently skips the discard (ram_block_discard_is_disabled) instead of refusing the balloon — the guest pays the full cost of ballooning and the host gets none of the benefit"
date: 2026-09-03
topic: self-hosting
tags: [proxmox, kvm, qemu, vfio, virtio-balloon, memory, free-page-reporting, pvestatd]
status: verified
sources:
  - https://gitlab.com/qemu-project/qemu/-/raw/master/hw/virtio/virtio-balloon.c
  - https://gitlab.com/qemu-project/qemu/-/raw/master/hw/vfio/container-legacy.c
  - https://pve.proxmox.com/wiki/Dynamic_Memory_Management
  - https://git.proxmox.com/?p=pve-manager.git;a=blob_plain;f=PVE/Service/pvestatd.pm;hb=HEAD
  - https://patchwork.kernel.org/project/qemu-devel/patch/20200603144914.41645-3-david@redhat.com/
  - https://lists.proxmox.com/pipermail/pve-devel/2022-March/052132.html
source_session: 8d8ead3b-046f-4d4e-9536-d52b2c9cea18
---

## CLAIMS

### The mechanism (verified in upstream QEMU source, not inferred)

- Both virtio-balloon reclaim paths in QEMU are gated on one predicate, `virtio_balloon_inhibited()`, defined as `return ram_block_discard_is_disabled() || migration_in_incoming_postcopy() || migration_in_bg_snapshot();` [qemu-virtio-balloon]
- Classic inflate/deflate is wrapped in `if (!virtio_balloon_inhibited()) { ... balloon_inflate_page(...) ... }`. When inhibited the branch is **skipped with no error and no log** — the virtqueue element is still consumed, so the guest's balloon driver believes the inflation succeeded. [qemu-virtio-balloon]
- Free page reporting is gated by the same predicate plus page poisoning: `if (virtio_balloon_inhibited() || dev->poison_val) { goto skip_element; }` — again a silent skip, not a refusal. [qemu-virtio-balloon]
- The upstream comment states the reason exactly: "When we discard the page it has the effect of removing the page from the hypervisor itself and causing it to be zeroed when it is returned to us. So we must not discard the page if it is accessible by another device or process". [qemu-virtio-balloon]
- VFIO sets that inhibit flag: `hw/vfio/container-legacy.c` calls `vfio_ram_block_discard_disable(container, true)` on container connect, which for `VFIO_TYPE1v2_IOMMU`/`VFIO_TYPE1_IOMMU` returns `ram_block_discard_disable(state)`; failure path errors with "Cannot set discarding of RAM broken". [qemu-vfio-container]
- A comment in that same file describes this precise failure mode as a known, unfixed gap: "Especially virtio-balloon is currently only prevented from discarding new memory, it will not yet set ram_block_discard_set_required() and therefore, neither stops us here or deals with the sudden memory consumption of inflated memory." [qemu-vfio-container]
- Consequence chain: the guest allocates and holds the balloon pages (losing them from its own usable memory), QEMU never calls `ram_block_discard_range()`/`MADV_DONTNEED`, so host RSS stays at the ceiling. **The guest pays the full cost of ballooning and the host receives none of the benefit.** [qemu-virtio-balloon] [qemu-vfio-container]
- This is not a bug to be worked around but the intended safety behavior: a passed-through device can DMA to any guest page at any time with no way to trap a fault, so discarding a pinned page would let the device write to memory the guest has since re-faulted as a fresh zero page. [qemu-vfio-convert]
- The design was generalized from an earlier VFIO-specific `qemu_balloon_inhibit()` to `ram_block_discard_disable()` in 2020 by David Hildenbrand; the patch rationale states "vfio usually pins all guest memory, turning virtio-balloon basically useless and making the VM consume more memory than reported via the balloon." [qemu-vfio-convert]
- The `x-balloon-allowed` opt-out exists (`DEFINE_PROP_BOOL("x-balloon-allowed", VFIOPCIDevice, vbasedev.ram_block_discard_allowed, false)`) but is rejected for non-mdev devices: "x-balloon-allowed only potentially compatible with mdev devices". It is an experimental (`x-`) property and not a fix for real PCI passthrough. [qemu-vfio-pci]

### Proxmox's documented position

- The Proxmox wiki states it directly: "if you are passing through a physical PCI(e) device or a Virtual Function I/O (VFIO) Mediated device (MDEV) such as a vGPU, then ballooning will not work since these devices are mapped to fixed memory addresses in the host and in the guest. If you do enable ballooning, the KVM process will not release the memory back to the host but the guest may report a reduced memory availability which can be manually recovered using the KVM monitor using the balloon command." [pve-wiki-dmm]
- **Documentation gap worth knowing:** the official admin guide's Memory section (`qm.adoc`, the `qm_memory`/`qm_ballooning` anchors) contains NO passthrough warning at all. The caveat exists only on the wiki page, which was last edited 2023-10-06. A reader who only consults the official docs (the GUI's own help target) will not be warned. [pve-qm-adoc] [pve-wiki-dmm]
- The wiki also warns generally: "If set too aggressively, some applications in the guest may run out of memory as a result and your guest's OOM killer may activate, killing important processes." [pve-wiki-dmm]

### pvestatd auto-ballooning algorithm (read from source, not folklore)

- The 80% threshold is real and lives in `PVE/Service/pvestatd.pm`: `my $target = int($config->{'ballooning-target'} // 80);` then `my $goal = int($hostmeminfo->{memtotal} * $target / 100 - $hostmeminfo->{memused});` [pvestatd]
- It is no longer hardcoded — as of the fix for bug #2413 it reads the node config key `ballooning-target`, defaulting to 80. Older reports that it is unchangeable are outdated. [pvestatd] [pve-qm-adoc]
- `$maxchange` is `100 * 1024 * 1024` (100 MiB) per iteration, so adjustment is gradual — it cannot rescue a host from a fast allocation spike. [pvestatd]
- Distribution is by `shares` (default 1000, range 0–50000): `my $desired = $d->{balloon_min} + int(($alloc_new / $shares_total) * $shares);` Setting `shares: 0` removes the VM from auto-ballooning entirely. [pvestatd] [autoballoon] [pve-qm-man]
- `compute_alg1` skips VMs where `!$d->{balloon}` or `!$d->{balloon_min}` — i.e. a VM with `balloon: 0` is excluded. [autoballoon]
- Targets are applied via QMP `balloon` monitor command per VM. [pvestatd]
- Official docs confirm the shares math with a worked example: 32GB host at 16GB used → "32 * 80/100 - 16 = 9GB RAM to be allocated to the VMs on top of their configured minimum memory amount." [pve-qm-adoc]
- Note the loop is blind to whether reclaim actually worked: it compares the requested balloon target against `$vmstatus->{$vmid}->{balloon}` and re-issues, so on a passthrough VM it will keep driving the target down toward `balloon_min` while host `memused` never falls in response. [pvestatd]

### free-page-reporting in Proxmox

- Proxmox enables `free-page-reporting=on` by default only for machine version >= 6.2, via a 2022 patch by Alexandre Derumier; the feature needs QEMU >= 5.1 and host kernel >= 5.7. VMs pinned to older machine types silently do not get it. [pve-devel-fpr]
- Its presence on the QEMU command line proves only that the device was *configured* with the feature — it says nothing about whether reports are being acted on, because the skip happens at runtime inside `virtio_balloon_handle_report()`. **`free-page-reporting=on` in the cmdline is not evidence that reclaim is working.** [qemu-virtio-balloon] [pve-devel-fpr]
- Guest side additionally requires negotiating `VIRTIO_BALLOON_F_REPORTING`, and only reports free pages of order >= (MAX_ORDER - 2), i.e. large contiguous blocks. Page poisoning / `init_on_free=1` in the guest disables it. [pve-devel-fpr] [qemu-virtio-balloon]

### Other candidate causes for RSS-not-dropping (ruled in/out generally)

- Hugetlbfs-backed or `mlock`ed guest RAM also prevents `MADV_DONTNEED` from freeing anything, because hole-punching only frees pages for private anonymous mappings. [qemu-balloon-general]
- THP can cause a balloon inflate to split rather than free host huge pages, and khugepaged can re-collapse regions, making RSS climb back. [qemu-balloon-general]
- Migration (postcopy incoming / background snapshot) inhibits discard by the same predicate, but transiently. [qemu-virtio-balloon]
- Guest page cache alone does NOT explain a pinned RSS: page cache is reclaimable and a healthy balloon inflate would evict it. A ceiling-pinned RSS combined with a guest that is visibly shrinking is the passthrough signature specifically.

### Guest-side thrashing remedies (weaker sourcing — vendor docs + community, flagged)

- `pgscan_*` vs `pgsteal_*` in `/proc/vmstat` measure reclaim efficiency; `pgscan_direct`/`allocstall` (direct reclaim) is the serious signal, more than kswapd activity alone. [suse-tuning]
- `vm.watermark_scale_factor` widens the gap between the min and low watermarks, giving kswapd more runway to reclaim in the background before allocations stall — this is the direct knob for kswapd pegging a core, and is generally a better first move than swappiness. [suse-tuning] [k8s-swap]
- `vm.min_free_kbytes` should not normally be lowered; raise it if "page allocation failure" appears in logs. [suse-tuning]
- Swappiness is 0–200 since kernel 5.8; values >100 are documented as sensible only when swap is faster than filesystem I/O (i.e. zram), not for disk swap. Setting it to 0 does not disable swap, it defers swapping to the worst possible moment. [k8s-swap]
- Per-container `--memory` limits prevent one container from evicting the whole guest's page cache; this is the structural fix for "many containers" pressure, vs. tuning a global knob. [oneuptime-docker]

## SOURCES

**qemu-virtio-balloon**
URL: https://gitlab.com/qemu-project/qemu/-/raw/master/hw/virtio/virtio-balloon.c
Accessed: 2026-09-03 (fetched and read directly, 1093 lines)
Quote: `static bool virtio_balloon_inhibited(void) { /* Postcopy cannot deal with concurrent discards, so it's special, as well as background snapshots. */ return ram_block_discard_is_disabled() || migration_in_incoming_postcopy() || migration_in_bg_snapshot(); }`
Quote: `/* When we discard the page it has the effect of removing the page from the hypervisor itself and causing it to be zeroed when it is returned to us. So we must not discard the page if it is accessible by another device or process, or if the guest is expecting it to retain a non-zero value. */ if (virtio_balloon_inhibited() || dev->poison_val) { goto skip_element; }`
Quote: `if (!virtio_balloon_inhibited()) { if (vq == s->ivq) { balloon_inflate_page(...); } else if (vq == s->dvq) { balloon_deflate_page(...); } ... }`

**qemu-vfio-container**
URL: https://gitlab.com/qemu-project/qemu/-/raw/master/hw/vfio/container-legacy.c
Accessed: 2026-09-03 (fetched and read directly)
Quote: `static int vfio_ram_block_discard_disable(VFIOLegacyContainer *container, bool state) { switch (container->iommu_type) { case VFIO_TYPE1v2_IOMMU: case VFIO_TYPE1_IOMMU: ... return ram_block_discard_disable(state); } }`
Quote: `/* Especially virtio-balloon is currently only prevented from discarding new memory, it will not yet set ram_block_discard_set_required() and therefore, neither stops us here or deals with the sudden memory consumption of inflated memory. */`
Quote: `ret = vfio_ram_block_discard_disable(container, true); if (ret) { error_setg_errno(errp, -ret, "Cannot set discarding of RAM broken"); ... }`

**qemu-vfio-pci**
URL: https://gitlab.com/qemu-project/qemu/-/raw/master/hw/vfio/pci.c
Accessed: 2026-09-03
Quote: `if (vbasedev->ram_block_discard_allowed && !vbasedev->mdev) { error_setg(errp, "x-balloon-allowed only potentially compatible with mdev devices"); goto error; }`
Quote: `DEFINE_PROP_BOOL("x-balloon-allowed", VFIOPCIDevice, vbasedev.ram_block_discard_allowed, false),`

**qemu-vfio-convert**
URL: https://patchwork.kernel.org/project/qemu-devel/patch/20200603144914.41645-3-david@redhat.com/
Accessed: 2026-09-03 (via search summary — patch text not re-fetched verbatim)
Quote: "vfio usually pins all guest memory, turning virtio-balloon basically useless and making the VM consume more memory than reported via the balloon"

**pve-wiki-dmm**
URL: https://pve.proxmox.com/wiki/Dynamic_Memory_Management
Accessed: 2026-09-03 (fetched full page text; page last edited 2023-10-06)
Quote: "Note that if you are passing through a physical PCI(e) device or a Virtual Function I/O (VFIO) Mediated device (MDEV) such as a vGPU, then ballooning will not work since these devices are mapped to fixed memory addresses in the host and in the guest. If you do enable ballooning, the KVM process will not release the memory back to the host but the guest may report a reduced memory availability which can be manually recovered using the KVM monitor using the balloon command."
Quote: "Note that the Guest cannot ask for the memory back until the host has 'deflated' this balloon. If set too aggressively, some applications in the guest may run out of memory as a result and your guest's OOM killer may activate, killing important processes"

**pvestatd**
URL: https://git.proxmox.com/?p=pve-manager.git;a=blob_plain;f=PVE/Service/pvestatd.pm;hb=HEAD
Accessed: 2026-09-03 (fetched and read directly)
Quote: `my $target = int($config->{'ballooning-target'} // 80); # goal is the change amount required to achieve that my $goal = int($hostmeminfo->{memtotal} * $target / 100 - $hostmeminfo->{memused});`
Quote: `my $maxchange = 100 * 1024 * 1024; my $res = PVE::AutoBalloon::compute_alg1($vmstatus, $goal, $maxchange);`

**autoballoon**
URL: https://git.proxmox.com/?p=pve-manager.git;a=blob_plain;f=PVE/AutoBalloon.pm;hb=HEAD
Accessed: 2026-09-03 (fetched and read directly)
Quote: `next if !$d->{balloon}; # skip if balloon driver not running` / `next if !$d->{balloon_min}; # skip if balloon value not set in config` / `next if defined($d->{shares}) && ($d->{shares} == 0);`
Quote: `my $desired = $d->{balloon_min} + int(($alloc_new / $shares_total) * $shares);`

**pve-qm-adoc**
URL: https://git.proxmox.com/?p=pve-docs.git;a=blob_plain;f=qm.adoc;hb=HEAD
Accessed: 2026-09-03 (fetched and read lines 750-812 directly)
Quote: "The target percentage defaults to 80% and can be configured in the node options."
Quote: "When the host is running low on RAM, the VM will then release some memory back to the host, swapping running processes if needed and starting the oom killer in last resort."
Quote: "Even when using a fixed memory size, the ballooning device gets added to the VM, because it delivers useful information such as how much memory the guest really uses."
Note: the Memory section contains NO mention of PCI passthrough, VFIO, DMA, or pinning.

**pve-qm-man**
URL: https://pve.proxmox.com/pve-docs/qm.1.html
Accessed: 2026-09-03
Quote: "--shares <integer> (0 - 50000) (default = 1000) Amount of memory shares for auto-ballooning. ... Using zero disables auto-ballooning. Auto-ballooning is done by pvestatd."
Quote: "--balloon <integer> (0 - N) Amount of target RAM for the VM in MiB. The balloon driver is enabled by default, unless it is explicitly disabled by setting the value to zero."

**pve-devel-fpr**
URL: https://lists.proxmox.com/pipermail/pve-devel/2022-March/052132.html
Accessed: 2026-09-03
Quote: gated by `min_version($machine_version, 6, 2)`; requires QEMU 5.1+ and host kernel 5.7+.

**qemu-balloon-general**
URL: https://blog.pmhahn.de/virtio-balloon/ and https://lwn.net/Articles/814696/
Accessed: 2026-09-03 (via search synthesis; not individually re-fetched)
Note: hugetlbfs / mlock / THP-split caveats. Weaker sourcing than the source-code claims above.

**suse-tuning**
URL: https://documentation.suse.com/sles/15-SP7/html/SLES-all/cha-tuning-memory.html
Accessed: 2026-09-03 (via search synthesis)

**k8s-swap**
URL: https://kubernetes.io/blog/2025/08/19/tuning-linux-swap-for-kubernetes-a-deep-dive/
Accessed: 2026-09-03 (via search synthesis)

**oneuptime-docker**
URL: https://oneuptime.com/blog/post/2026-02-08-how-to-optimize-docker-for-memory-intensive-applications/view
Accessed: 2026-09-03 (via search synthesis)

## SYNTHESIS

The generalizable trap is the **silent skip**. QEMU had two design options when a balloon request arrives on a VM whose memory is pinned: refuse the balloon (fail loudly, guest keeps its memory) or honor it guest-side and skip the host-side discard. It chose the latter, for a defensible reason — refusing would break live migration and hotplug flows — but the result is the worst possible split of costs: the guest genuinely surrenders the memory, and the host genuinely does not get it back. There is no error, no log line, and no counter. Every observable that an operator naturally checks (`free` in the guest, `info balloon`, the presence of `free-page-reporting=on` in the command line) reports success.

This means the config-visible evidence actively misleads. `free-page-reporting=on` on the QEMU command line is a statement about device *construction*, while the reclaim decision happens per-request at runtime in `virtio_balloon_handle_report()`. Reading the flag and concluding reclaim works is exactly the inference the code defeats. The right check is behavioral: does host RSS for that PID actually fall when the balloon target drops? On a passthrough VM it never will.

The diagnostic that isolates this fast, given two VMs on one host: compare whether each QEMU's RSS tracks its balloon target. A VM whose RSS follows usage has working reclaim; one pinned at its ceiling while the guest shrinks has an inhibitor. Then check for `hostpci*` in the config — that single line predicts which is which, and it is a per-VM property, so identical ballooning settings legitimately produce opposite behavior on the same host.

Second-order effect worth internalizing: because pvestatd's control loop measures host `memused` and never sees it respond, a passthrough VM under auto-ballooning is a control system with a severed feedback path. The daemon keeps pushing the target toward `balloon_min` chasing a host number that cannot move, and the guest keeps absorbing the loss until it thrashes or OOMs. The "high ceiling, low floor" pattern that is merely optimistic on a normal VM becomes an actively destructive ratchet on a passthrough VM — the floor is not a safety net, it is the destination.

The broader lesson for capacity planning: ballooning's premise is that the guest knows better than the host which pages are cold. That premise holds for an idle VM with slack. It fails for a page-cache-heavy workload (many containers, media serving) where the "reclaimable" cache is what makes the service fast, and it fails completely when a pinning device removes the host's ability to act on the guest's cooperation. Fixed memory sized to the real working set is not a fallback for these cases; it is the correct design.
