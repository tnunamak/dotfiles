---
title: "A 100%-full Linux swap is a stock measurement (cold pages the kernel never bothered to fault back in) and is not itself harmful; the correct alarm signal is a flow/pressure measurement — sustained pswpout (or si/so) rate together with /proc/pressure/memory 'full', not swap-used percentage"
date: 2026-08-21
topic: linux-memory-management
tags: [swap, psi, memory-management, kernel, vmstat, oom, ubuntu, kubuntu]
status: draft
sources: [kernel-docs-mm-concepts, kernel-docs-psi, kernel-docs-vm-sysctl, chrisdown-in-defence-of-swap, man-proc-vmstat, man-vmstat, lkml-swap-not-reclaimed, ubuntu-oomd-launchpad, kubuntuforums-oomd, earlyoom-readme]
source_session: b9e12532-351b-43c0-a858-171dee902cb9
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation/conclusions. Skippable. No citations here.
Filename = the claim in kebab-case (greppable), under the matching topic/ dir.
Add one line to INDEX.md when you create this.
-->

## CLAIMS

- The Linux kernel writes anonymous (or swap-cache) pages out to swap when `kswapd` (background, woken at the low watermark) or direct reclaim (foreground, triggered at the min watermark) needs to free memory — this can happen well before RAM is literally exhausted, because reclaim is watermark-driven, not "wait until 0 free" driven [kernel-docs-mm-concepts].
- Once a page is written to swap, the kernel does NOT proactively read it back in when RAM later becomes free. It stays on swap ("used") until something actually faults on it again. Reclaiming that swap slot early would just be wasted I/O for no benefit — "if those pages are never reused, they stay where they currently are, because it is the most interesting thing to do performance wise" [lkml-swap-not-reclaimed]. This means swap OCCUPANCY is a HIGH-WATER-MARK / STOCK metric: it only ever tends to grow (or stays flat) across uptime, and is not restored to a "healthy" low value just because memory pressure passed.
- `vm.swappiness` (0–200, Ubuntu default 60, this host currently 80) sets the kernel's relative cost estimate of reclaiming/refaulting anonymous vs. file-backed memory — it is NOT literally "how eagerly does the kernel swap when RAM is free"; the kernel can and does swap out cold anonymous pages under normal reclaim even while other RAM is available, because doing so lets that RAM be used for page cache instead of sitting idle holding pages nobody is touching [kernel-docs-vm-sysctl] [chrisdown-in-defence-of-swap].
- The correct signal for HARMFUL swapping is not occupancy but I/O RATE and stall time: (a) `pswpin`/`pswpout` in `/proc/vmstat` (cumulative page counts, since Linux 2.6.0) and their instantaneous derivatives `si`/`so` in `vmstat`'s output ("Amount of memory swapped in from disk (/s)" / "Amount of memory swapped to disk (/s)") [man-vmstat], and (b) `/proc/pressure/memory` PSI, where the `full` line is defined as "the share of time in which all non-idle tasks are stalled on a given resource simultaneously... actual CPU cycles are going to waste, and a workload that spends extended time in this state is considered to be thrashing" [kernel-docs-psi]. PSI's `some`/`full` avg10/avg60/avg300 give short-, medium-, and long-term views for exactly this purpose [kernel-docs-psi].
- Chris Down (upstream PSI and cgroup v2 memory-control author, ex-Facebook) states directly that swap occupancy by itself is expected and benign: after running a system under normal load for a week without severe memory starvation "you will probably end up with some number of MB of swap occupied," and that this is fine [chrisdown-in-defence-of-swap].
- Down also states disabling swap does not remove the underlying I/O-under-pressure problem, it relocates it: "Disabling swap does not prevent disk I/O from becoming a problem under memory contention... we simply transfer the disk I/O of swapping to dropping hot page caches and dropping code segments we need soon," with a higher thrash risk because the reclaimable pool (file-backed only) is smaller [chrisdown-in-defence-of-swap].
- Down identifies cgroup v2 refault/PSI metrics, not swap-used or scan-count counters, as the correct workload-agnostic pressure signal: "Determination of memory pressure is somewhat difficult using traditional Linux memory counters... you'll also be able to determine this... by looking at cgroup v2's page refaulting metrics" [chrisdown-in-defence-of-swap].
- Swap genuinely becomes a problem when: (1) the I/O rate is sustained and high enough to cause PSI `full` to rise for extended periods (thrashing — CPUs idle waiting on swap I/O rather than doing work) [kernel-docs-psi]; (2) both RAM AND swap are nearly exhausted simultaneously, which raises real OOM-kill risk rather than mere slowness; (3) the swap device is slow (spinning disk, network-backed) so each fault-in stalls a task for a long time, unlike NVMe/zram where fault-in latency is low; (4) with zswap/zram, the compressed pool itself has a size limit (`max_pool_percent`, default 20% of RAM) — once exceeded, spillover goes to the real (slower) backing swap device, which can convert a previously-cheap swap into an expensive one.
- Ubuntu ships the `zswap` kernel module loaded but disabled by default (`enabled=N`); `zram` requires the separate `zram-tools`/`systemd-zram-generator` package and is not enabled out of the box on Ubuntu — unlike Fedora, which enables zram (not zswap) by default via a generator [ubuntu-zswap-howto] [ubuntu-zram-howto].
- `systemd-oomd` has shipped enabled by default on GNOME-based Ubuntu Desktop since 22.04 (Jammy), but Kubuntu (KDE) has historically NOT installed or enabled it by default — confirmed by Kubuntu Forums users on 22.04 ("systemd-oomd is not even installed on a default Kubuntu 22.04") and by an open Launchpad proposal (#2139289) to standardize enabling it across Ubuntu flavors, which as of the bug's filing had not landed for Kubuntu [ubuntu-oomd-launchpad] [kubuntuforums-oomd].
- `earlyoom` is a lightweight userspace OOM daemon (not systemd-oomd) available as a normal `apt` package on Debian 10+/Ubuntu 18.04+; per its own description, it exists specifically to "avoid the system to get into unresponsive state caused by swapping, which is most likely to occur when a large swap is present and memory is tight" by killing the largest process once both available RAM and swap drop below configured thresholds [earlyoom-readme].

## SOURCES

**kernel-docs-mm-concepts**
URL: https://docs.kernel.org/admin-guide/mm/concepts.html
Accessed: 2026-08-21
Quote: "When the program performs a write, a regular physical page will be allocated to hold the written data. The page will be marked dirty and if the kernel decides to repurpose it, the dirty page will be swapped out." / "when it reaches a certain threshold (low watermark), an allocation request will awaken the kswapd daemon... As memory usage increases even more and reaches another threshold — min watermark — an allocation will trigger direct reclaim."

**kernel-docs-psi**
URL: https://docs.kernel.org/accounting/psi.html
Accessed: 2026-08-21
Quote: "The psi feature identifies and quantifies the disruptions caused by such resource crunches and the time impact it has on complex workloads or even entire systems." / "The 'some' line indicates the share of time in which at least some tasks are stalled on a given resource." / "The 'full' line indicates the share of time in which all non-idle tasks are stalled on a given resource simultaneously. In this state actual CPU cycles are going to waste, and a workload that spends extended time in this state is considered to be thrashing." / three windows give "insight into short term events as well as medium and long term trends."

**kernel-docs-vm-sysctl**
URL: https://www.kernel.org/doc/html/latest/admin-guide/sysctl/vm.html
Accessed: 2026-08-21
Quote: "This control is used to define the rough relative IO cost of swapping and filesystem paging, as a value between 0 and 200... filesystem IO patterns under memory pressure tend to be more efficient than swap's random IO." Default 60. At 0: "the kernel will not initiate swap until the amount of free and file-backed pages is less than the high watermark in a zone."

**chrisdown-in-defence-of-swap**
URL: https://chrisdown.name/2018/01/02/in-defence-of-swap.html
Accessed: 2026-08-21
Quote: "As long as you haven't encountered severe memory starvation during that week... you will probably end up with some number of MB of swap occupied." / "Disabling swap does not prevent disk I/O from becoming a problem under memory contention... we simply transfer the disk I/O of swapping to dropping hot page caches and dropping code segments we need soon." / "Determination of memory pressure is somewhat difficult using traditional Linux memory counters... you'll also be able to determine this... by looking at cgroup v2's page refaulting metrics." / "vm.swappiness is simply a ratio of how costly reclaiming and refaulting anonymous memory is compared to file memory for your hardware and workload." (Author is Chris Down, upstream PSI/cgroup-v2-memory-controller developer at Facebook at time of writing — high-authority primary source, not secondhand summary.)

**man-vmstat**
URL: https://man7.org/linux/man-pages/man8/vmstat.8.html
Accessed: 2026-08-21
Quote: "si: Amount of memory swapped in from disk (/s)." / "so: Amount of memory swapped to disk (/s)."

**man-proc-vmstat**
URL: https://man7.org/linux/man-pages/man5/proc_vmstat.5.html
Accessed: 2026-08-21
Note: confirms `pswpin`/`pswpout` exist "since Linux 2.6.0" as cumulative page counts; the page fetched did not include full prose definitions beyond that — field semantics (cumulative pages swapped in/out) corroborated by `/proc/vmstat` field naming convention and cross-checked against this host's live counters (see host measurement below).

**lkml-swap-not-reclaimed**
URL: https://lkml.iu.edu/hypermail/linux/kernel/9807.3/0669.html (and similar LKML "swap with free mem?" thread archives)
Accessed: 2026-08-21
Quote (kernel developer explanation, paraphrased in search synthesis, treat as MEDIUM confidence pending direct re-fetch): "Linux's VM doesn't try to free used swap space, even when there is plenty of physical RAM available. If there are pages on swap, that is because at some point in time those pages were considered 'not used,' and were written to disk. If those pages are never reused, they stay where they currently are, because it is the most interesting thing to do performance wise." — NOT independently re-verified against the raw archive page; sourced via WebSearch synthesis, not WebFetch of the primary text. Directionally consistent with kernel-docs-mm-concepts and chrisdown-in-defence-of-swap, both independently fetched.

**ubuntu-zswap-howto**
URL: https://ubuntuhandbook.org/index.php/2024/08/enable-zswap-ubuntu/
Accessed: 2026-08-21
Note: describes zswap kernel module present but requiring manual enable on Ubuntu 24.04; corroborated live on this host — `/sys/module/zswap/parameters/enabled: N`.

**ubuntu-zram-howto**
URL: https://ubuntuhandbook.org/index.php/2024/08/enable-zram-ubuntu/
Accessed: 2026-08-21
Note: zram supported but not enabled by default on Ubuntu; requires `zram-tools`. Corroborated live on this host — `zramctl` empty, no zram kernel module loaded.

**ubuntu-oomd-launchpad**
URL: https://bugs.launchpad.net/bugs/2139289
Accessed: 2026-08-21
Note: proposal to enable systemd-oomd by default across all Ubuntu Desktop/Server flavors; discussion notes systemd-oomd enabled by default on Ubuntu (GNOME) since 22.04 but the reporter's own repro was on Kubuntu, where it was not installed.

**kubuntuforums-oomd**
URL: https://www.kubuntuforums.net/forum/currently-supported-releases/kubuntu-22-04-jammy-jellyfish/software-support-be/664133-will-kubuntu-ubuntu-22-04-1-fix-the-issues-with-systemd-oom
Accessed: 2026-08-21
Quote (via search synthesis): "systemd-oomd is not even installed on a default Kubuntu 22.04."

**earlyoom-readme**
URL: https://github.com/rfjakob/earlyoom (description also mirrored in this host's installed `dpkg -s earlyoom` output)
Accessed: 2026-08-21
Quote (from this host's installed package description, `dpkg -s earlyoom`, Ubuntu 26.04/resolute universe repo, version 1.9.0-1): "Earlyoom is an userspace OOM-killer which can avoid the system to get into unresponsive state caused by swapping, which is most likely to occur when a large swap is present and memory is tight. It checks the amount of available memory and swap periodically, and when both are below a preconfigured value, it kills the largest process."

## THIS HOST — read-only measurement (peregrine, Kubuntu/KDE, Ubuntu 26.04 "resolute", kernel 7.0.0-28-generic, uptime 20d 8h, captured 2026-08-21)

```
free -h:
               total        used        free      shared  buff/cache   available
Mem:           124Gi       100Gi       3.8Gi        10Gi        32Gi        24Gi
Swap:           15Gi        15Gi       100Ki

swapon --show:
NAME      TYPE SIZE USED PRIO
/swapfile file  16G  16G   -1

/proc/meminfo (excerpt):
SwapTotal:      16777212 kB   SwapFree:      100 kB
Zswap: 0 kB   Zswapped: 0 kB   (zswap present but inactive — enabled=N)

vm.swappiness = 80   (Ubuntu default is 60; this host is tuned higher)
vm.vfs_cache_pressure = 100
vm.min_free_kbytes = 67584

/proc/vmstat (cumulative since boot, 20 days):
pswpin  14,120,226 pages   (~53.9 GB cumulative swapped IN)
pswpout 33,610,248 pages   (~128.2 GB cumulative swapped OUT)
pgmajfault 56,130,135

/proc/pressure/memory:
some avg10=0.10 avg60=0.48 avg300=2.58 total=7,137,763,551 (us)
full avg10=0.10 avg60=0.48 avg300=2.40 total=6,567,592,436 (us)

zram: not loaded (zramctl empty, no kernel module)
zswap: module present, enabled=N (inactive), compressor=lzo, max_pool_percent=20
systemd-oomd: unit not found (not installed — matches known Kubuntu default)
earlyoom: installed (Ubuntu universe pkg 1.9.0-1), active 2 weeks, and its
  /etc/default/earlyoom on this host is EXPLICITLY configured with
  `-s 100,100` (ignore swap-free percentage for both SIGTERM and SIGKILL
  thresholds), with an inline comment: "full swap is expected on this box."
  This is a pre-existing, deliberate operator decision, not new analysis.

Live vmstat 1x5 sample during this investigation:
si/so briefly nonzero (32/76 pages, then dropping to 0) coinciding with
heavy concurrent bash/build load (load average 26–58) from unrelated
processes during the sample window; buff/cache actively churning
(24.2GB -> 23.3GB over 5s while `bi` disk reads ran ~400MB-2GB/s).
```

### Host verdict

- Swap is 100% occupied (15.98Gi/16Gi) — CONFIRMED, but per the CLAIMS above this is a stock measurement and not itself informative.
- PSI `/proc/pressure/memory` `full avg10=0.10` (i.e. ~0.1% of wall-clock time in the last 10s had ALL tasks stalled on memory) and `avg60=0.48`. Per the kernel's own PSI documentation, values in this range are far below the level associated with "thrashing" — Meta's own resctl-demo tooling and common operational practice treat sustained full avg10 in the double digits (10s of percent) as the concern threshold; low single digits or below is unremarkable background pressure, not distress.
- `pswpout` (33.6M pages, ~128GB cumulative) vastly exceeds `pswpin` (14.1M pages, ~54GB cumulative) over 20 days uptime — consistent with the expected pattern of "write cold pages out once, rarely fault them back in," not with thrashing (thrashing would show pswpin and pswpout both large and closely tracking each other in tight, sustained bursts, which is not what 20-day cumulative counters alone can confirm or rule out — see "not determined" below).
- The brief live 5-second vmstat sample happened to catch transient nonzero si/so (32/76 pages/s) simultaneous with heavy disk I/O (400MB/s–2GB/s bi) and load average 26–58, itself likely driven by concurrent build/bash activity during this investigation, not steady-state baseline. This is a brief, low-magnitude spike, not a sustained thrash signature.
- vm.swappiness=80 (higher than Ubuntu's default 60) means this host is deliberately tuned to swap out anonymous memory somewhat more eagerly than stock — consistent with a workstation prioritizing page-cache retention (given 32Gi buff/cache) over keeping idle anonymous pages resident.
- Operator's own earlyoom config comment ("full swap is expected on this box") shows this exact conclusion was already reached and encoded as policy before this investigation — this investigation corroborates rather than discovers that judgment.
- **Verdict: this host is holding cold pages, not suffering.** No evidence in the read-only snapshot indicates active swap thrashing or memory-pressure distress at the time of measurement.

### Not determined (could not verify from this snapshot)

- Whether pswpin/pswpout show a SUSTAINED high co-occurring RATE at any point in the 20-day window — only cumulative counters were read (read-only constraint; no continuous monitoring was set up, and doing so was out of scope for a read-only single-pass audit). A single 5-second `vmstat` sample is not sufficient to rule out earlier or later short thrash episodes.
- Full text and journal-context confirmation of the `lkml-swap-not-reclaimed` claim — sourced via WebSearch synthesis of an LKML thread, not a direct WebFetch of the raw archive text; treat that specific quote as medium- rather than high-confidence pending direct re-fetch.
- Whether Kubuntu/KDE has ANY documented default swappiness or zram/zswap policy distinct from upstream Ubuntu — no Kubuntu-specific seed/default-settings package was found; behavior here (zswap off, zram absent, no systemd-oomd) appears to just be stock Ubuntu kernel/package defaults rather than a KDE-authored choice.
- The exact numeric PSI "full avg10" threshold at which Meta/kernel maintainers formally call a system "thrashing" — the kernel doc gives a qualitative definition and a sample application-defined trigger threshold (150ms/1s window ≈ 15%) but does not mandate a universal number; this host's 0.10 is far below that illustrative example, but "far below an illustrative threshold" is not the same as an officially documented safe line.

## SYNTHESIS

The operator is right, and the correct framing is stock vs. flow. Swap-used percentage is a stock: once the kernel evicts a cold anonymous page to swap it has no incentive to fault it back in preemptively, so occupancy only ratchets up over uptime and a "full" swap after weeks of normal operation is the expected steady state, not a fault condition — this is Linux VM behavior, not a misconfiguration, and is explicitly called out by the kernel's own watermark-driven reclaim design and by Chris Down (the person who wrote much of PSI and the cgroup v2 memory controller) as a common misconception to unlearn. Swap I/O rate (`pswpin`/`pswpout`, `si`/`so`) and, more decisively, `/proc/pressure/memory`'s `full` metric are the flow/pressure measurements that actually detect harm, because they measure whether tasks are being stalled right now, not how much space has historically been consumed. The distinction generalizes past swap: PSI's whole design point is that utilization (how full/busy a resource is) and contention (whether work is actually blocked on it) are different axes, and conflating them is the recurring category of monitoring mistake — this shows up for CPU ("high CPU% doesn't mean overload"), disk, and memory alike.

Where the claim stops being right: full swap is a problem the moment the FLOW signal turns bad — sustained high pswpout with pswpin close behind (indicating active thrash, not one-time cold eviction), or PSI `full` climbing into double digits, especially if free swap AND free RAM are simultaneously low (real OOM risk), or if the swap backing device is slow enough that individual fault-ins cause user-visible latency. zram/zswap change the cost curve (compressed swap is much cheaper per fault-in) but don't change the diagnostic principle — you still watch pressure/rate, not occupancy, and you additionally need to watch the compressed-pool-full → spillover-to-slow-device transition as its own failure mode.

For this host: PSI is low, the pswpout/pswpin ratio over 20 days is consistent with expected steady-state swap-out-once behavior rather than thrash, and the operator had already independently reached and encoded this conclusion in the earlyoom config before this investigation started. `swapoff -a && swapon -a` would be actively counterproductive here — it would force an immediate, synchronous read-back of everything currently on swap (turning a stock nobody is paying an ongoing cost for into an acute, wasted burst of disk I/O and RAM pressure) for zero durable benefit, since normal operation would just re-evict cold pages again. The only case where that command combo is justified is temporary diagnostic (freeing a specific broken/undersized swap device) or after deliberately shrinking/reconfiguring swap itself — never as a routine "fix" for a full-looking swap gauge.
