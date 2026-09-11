---
title: "PCI(e) passthrough pins the guest's entire memory in host RAM, so ballooning and KSM cannot reclaim anything on that VM and a balloon floor only starves the guest"
date: 2026-09-03
topic: self-hosting
tags: [proxmox, kvm, pci-passthrough, ballooning, memory, vfio]
status: draft
sources: [pve-gpu-overstated, pve-high-mem-passthrough, pve-balloon-nvme, pve-mem-limit-gpu]
source_session: 8d8ead3b-046f-4d4e-9536-d52b2c9cea18
---

## CLAIMS
- A passed-through PCI(e) device can initiate DMA at any time, and the hypervisor cannot know in advance which guest pages it will touch, so the full guest memory must be pinned into real host RAM up front. [pve-gpu-overstated]
- Consequently ballooning and KSM do not function on a VM with PCI(e) passthrough: the balloon device may be present and configured, but it will never reduce the VM's host-side memory below `memory` (max). [pve-gpu-overstated] [pve-high-mem-passthrough]
- The host-side QEMU RSS for such a VM sits at (slightly above) the configured max for the entire time the VM runs, regardless of what the Proxmox GUI reports as usage; overhead from QEMU itself and device BARs can push it a little over 100% of configured memory. [pve-gpu-overstated] [pve-mem-limit-gpu]
- This applies to PCI(e) passthrough (`hostpci0:` in the VM config), NOT to disk passthrough — a passed-through NVMe/SATA/USB/iSCSI *drive* does not pin memory and ballooning still works. [pve-balloon-nvme]
- Because the memory is fully reserved, over-allocating a passthrough VM can prevent it from starting or destabilize the host, sometimes with no related error in `journalctl`; the fix in one reported case was simply lowering the VM's memory (16 GB → 12 GB) to leave the host headroom. [pve-high-mem-passthrough]
- Keeping the balloon device present (minimum = maximum) rather than `balloon: 0` retains one useful function: for some guest OSes the device still *reports* in-guest memory usage to the Proxmox UI. Setting `balloon: 0` removes that reporting. [pve-gpu-overstated]
- The recommended configuration for a passthrough VM is minimum memory = maximum memory (or ballooning disabled), sized to actual need, leaving the freed headroom for non-passthrough VMs where ballooning and KSM actually work. [pve-gpu-overstated] [pve-high-mem-passthrough]

## SOURCES
**pve-gpu-overstated**
URL: https://forum.proxmox.com/threads/memory-usage-overstated-when-passing-through-gpu.175603/
Accessed: 2026-09-03
Quote: "Because PCI(e) devices can do Direct Memory Access at any time, all VM memory must be pinned into actual host RAM when using PCI(e) passthrough. If the VM memory were not pinned into actual memory, such a DMA could overwrite host or other VM memory."

**pve-high-mem-passthrough**
URL: https://forum.proxmox.com/threads/high-memory-usage-on-vm-with-pci-passthrough.147643/
Accessed: 2026-09-03
Quote: "Ballooning and KSM won't work for such a VM. You can have the balloon device enabled in the VM but it will never reduce the memory from max."

**pve-balloon-nvme**
URL: https://forum.proxmox.com/threads/memory-ballooning-pcie-passthrough-booting-from-nvme.123161/
Accessed: 2026-09-03
Quote: "This applies to PCI(e) passthrough, not disk passthrough — with disk passthrough you can still use ballooning, regardless of the drive type."

**pve-mem-limit-gpu**
URL: https://forum.proxmox.com/threads/memory-limit-with-pcie-gpu-passthrough.124488/
Accessed: 2026-09-03
Quote: "Regardless of what the GUI shows, all of the VM memory is used the whole time the VM is running."

## SYNTHESIS
This is the documented, expected mechanism — not a bug, and not something to tune around. It cleanly explains a failure mode that otherwise looks paradoxical: a VM simultaneously *starved inside* and *bloated outside*. The guest sees only its balloon floor and thrashes (kswapd pinned, swap saturated, load in the hundreds, services unreachable), while the host-side QEMU process is already holding the full ceiling in pinned RAM. Raising the balloon floor appears to "fix" such an incident, but it only widens the guest's window into memory the host was reserving anyway — it treats the symptom and leaves the same collapse available next time.

The diagnostic tell is cheap and worth remembering: compare host-side QEMU RSS (`ps -eo rss,args`) against what the guest reports. If RSS sits at the configured max while the guest believes it has far less, look for `hostpci`/`vfio-pci` in the VM's commandline before theorizing about leaks, page cache, or host scarcity. A same-host VM *without* passthrough whose RSS tracks actual usage is a useful control.

Practical decision rule: any VM with PCI(e) passthrough should be sized as a fixed allocation (min = max) at its real working-set need, and the "low floor + high ceiling" overcommit pattern should be reserved for non-passthrough VMs where it actually buys elasticity. Prefer min = max over `balloon: 0` so the guest still reports usage to the UI. Note also that a fixed passthrough VM permanently removes its full allocation from the host's pool, which shrinks the headroom other VMs rely on to inflate — so passthrough sizing is a whole-host capacity decision, not a per-VM one. Relates to [postgres-in-proxmox-lxc-outperforms-vm-on-io-and-unprivileged-uid-mapping-is-the-main-gotcha].
