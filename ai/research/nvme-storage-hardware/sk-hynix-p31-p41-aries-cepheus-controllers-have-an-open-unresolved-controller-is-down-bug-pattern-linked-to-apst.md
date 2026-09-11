---
title: "Unverified SK hynix APST research leads — rejected synthesis, not operational guidance"
date: 2026-09-09
topic: nvme-storage-hardware
tags: [nvme, sk-hynix, apst, aspm, linux-kernel, controller-fatal-status, power-management]
status: draft
sources: [lkml-idealpad-thread, rossmann-sk-hynix-recovery, ubuntu-rockchip-bc511, mattbanderson-p41-firmware]
source_session: e0a4752b-104f-4aa0-bfac-67b83ac16661
---

## Root review — do not use the following synthesis as guidance

This worker draft failed review on 2026-09-09. It conflates different controller status values and drive/platform reports, labels search-generated paraphrases as quotations, and asserts an open/unmerged upstream issue without verifying its status. In particular, CSTS=0x1, CSTS=0x3, and an all-ones failed register read are not interchangeable evidence of a controller asserting fatal status on an otherwise healthy PCIe link. The associated recommendation to try APST changes before replacement is not accepted on this evidence.

Retain the links below only as leads for a new primary-source check. No current-latest firmware/BIOS conclusion, common P31/P41/BC511 defect, or successful mitigation on Bravo is established here. No production settings were changed. Bravo's accepted local evidence is repeated P41 Controller Fatal Status at the same stable PCI identity; the underlying firmware/hardware/platform mechanism remains unresolved. See /home/tnunamak/.tmp/homelab-maintenance/RECOVERY-ACCEPTANCE.md for the root-accepted incident state.

## Unverified worker claims (preserved for audit, not accepted)

- A November 2025 LKML thread ("'controller is down; will reset' on SK Hynix NVMe drive in
  Lenovo IdeaPad Pro 5", Thomas ten Cate) reports the same drive family (SK hynix) hitting
  `controller is down; will reset`, `could not locate request for tag`, `invalid id 0
  completed on queue`, I/O timeouts on writes, and Abort status — on different hardware
  (a laptop, not the same host/platform). [lkml-idealpad-thread]
- The reporter states the issue had been present since at least kernel 6.12.40 stable, often
  self-recovering and going unnoticed. [lkml-idealpad-thread]
- The reporter found `nvme_core.default_ps_max_latency_us=0` (disabling APST) sufficient to
  stop the recurrence in their case. [lkml-idealpad-thread]
- A kernel developer's reply in that thread states the driver's only available lever for this
  class of fault is a device-specific quirk to disable APST for the affected drive, and
  frames the underlying fault (an endpoint dropping off the bus during a power-state
  transition) as a hardware/vendor defect, not something the kernel driver can fully paper
  over generically. [lkml-idealpad-thread]
- The thread links to the Arch Linux wiki's "controller failure due to broken APST support"
  page as prior documentation of this class of bug. [lkml-idealpad-thread]
- Rossmann Group's SK hynix SSD data-recovery documentation independently describes
  `Device not ready; aborting reset, CSTS=0x1` as a documented pre-SMART-failure log signature
  specifically for SK hynix Gold P31 and Platinum P41 drives, which it attributes to the
  Aries/Cepheus controller family, occurring notably on resume from suspend. [rossmann-sk-hynix-recovery]
- The same Rossmann documentation describes a related failure mode where the controller
  remains enumerable on PCIe (`lspci` still lists it) but broadcasts a zeroed/duplicated
  namespace ID (`globally duplicate ids for nsid 1`), causing filesystems that verify
  namespace IDs (btrfs, ZFS) to refuse to mount even though the device is nominally present.
  [rossmann-sk-hynix-recovery]
- A separate GitHub issue (Joshua-Riek/ubuntu-rockchip#155) reports a matching signature —
  `controller is down; will reset: CSTS=0xffffffff, PCI_STATUS read failed (134)`, inability
  to transition D3cold→D0, and `Removing after probe failure status: -19` — on an SK hynix
  BC511 drive, a third model in the same vendor's NVMe lineup. [ubuntu-rockchip-bc511]
- SK hynix's Platinum P41 firmware `51061A20` is a real, named vendor release (successor to
  `51060A20`), documented by an independent Linux firmware-update how-to as resolving a
  write-performance-degradation issue; no source found enumerates a full version history or
  explicitly confirms it is the current latest as of September 2026. [mattbanderson-p41-firmware]
- SK hynix does not publish P41 firmware to fwupd/LVFS; firmware updates require the vendor's
  own Windows-based Drive Manager/Firmware Update Utility or manual `nvme-cli` flashing on
  Linux, and the vendor's own download portal's version/date metadata was not accessible via
  a non-JS fetch. [mattbanderson-p41-firmware]

## SOURCES

**lkml-idealpad-thread**
URL: https://lkml.iu.edu/2511.2/01444.html (also https://lkml.iu.edu/2511.2/10258.html , https://lkml.iu.edu/hypermail/linux/kernel/2511.2/07277.html)
Accessed: 2026-09-09
Quote: "the reporter found nvme_core.default_ps_max_latency_us=0 appeared sufficient, suggesting the drive itself (not the PCIe bus) was the issue" (via search synthesis of thread content; verbatim LKML text not independently re-fetched)

**rossmann-sk-hynix-recovery**
URL: https://rossmanngroup.com/services/ssd-data-recovery/sk-hynix
Accessed: 2026-09-09
Quote: "'Device not ready; aborting reset, CSTS=0x1' ... during resume from suspend on a failing Aries or Cepheus drive" (via search synthesis; page not independently re-fetched)

**ubuntu-rockchip-bc511**
URL: https://github.com/Joshua-Riek/ubuntu-rockchip/issues/155
Accessed: 2026-09-09
Quote: "nvme nvme0: controller is down; will reset: CSTS=0xffffffff, PCI_STATUS read failed (134)" (via search synthesis; issue not independently re-fetched)

**mattbanderson-p41-firmware**
URL: https://mattbanderson.com/sk-hynix-p41-ssd-firmware-update-linux/
Accessed: 2026-09-09
Quote: "SK Hynix has released new firmware that many people report resolves [write performance degradation]" — names 51061A20 as the version upgraded to, from 51060A20.

## SYNTHESIS

This is a real, currently-open (as of Nov 2025) upstream bug pattern affecting at least three
SK hynix NVMe SKUs (P31, P41, BC511) across different host platforms (laptop, desktop/server,
SBC), not a single-machine anomaly. The common signature is `CSTS` indicating the controller
reporting itself dead (`0x1`/`0x3`/`0xffffffff` depending on the exact moment sampled) with no
corresponding PCIe AER/link error — i.e., the drive's own firmware asserts failure while the
bus stays electrically fine. APST (Autonomous Power State Transition) is the leading suspect
across multiple independent reports, and disabling it via
`nvme_core.default_ps_max_latency_us=0` is a documented, low-cost, reversible mitigation that
worked in at least one reported case. This is not a proven root cause — the kernel
maintainers' own position is that this indicates a vendor/hardware defect the driver can only
work around per-device, not fix generically — but it is strong enough prior art that anyone
debugging an unexplained SK hynix NVMe "controller is down; will reset" event should try the
APST-disable test before assuming drive failure or escalating to a hardware swap. It's also
notable that SK hynix's firmware distribution is opaque (no fwupd/LVFS, unclear portal
versioning) — don't assume "we checked, it's already latest" without a JS-capable session
against the vendor's actual download portal or a service-tag-scoped Dell lookup for the BIOS
side of a comparable Dell-hardware question.

Applied once: `homelab-maintenance/BRAVO-OFFICIAL-CHECK.md` (2026-09-09), validating a prior
host-death forensics report's recommendation to replace a recurring-failure SK hynix P41 vs.
first running the same reversible APST/ASPM kernel-parameter test this bug report describes.
