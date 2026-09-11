# Bravo wedge continuity — 2026-09-05

Durable incident record. No config edits were made.

## Recovery timeline

- `systemctl reboot` on Proxmox Bravo `.12`: **18:56:50**.
- PVE VM140 and VM130 graceful waits timed out at 180s; recovery escalated.
- CT116 graceful stop exceeded 80s; explicit `pct stop 116 --overrule-shutdown 1` at
  approximately **19:04:19**, exit 0.
- New boot `29c27cb7`; host uptime 0 minutes at **19:06:23**.
- VM103 auto-started **19:06:54**.

## Verified after boot

- P41 `SHPP41`, full ~1.8T, firmware **51061A20**.
- `data-main` active: ~32% used; metadata ~1.31%.
- WD SN740 firmware **73914109**.
- Bravo BIOS **1.41.0**.
- `/proc/cmdline`: no APST/ASPM override flags; proposed latency cap/performance-policy
  experiment was not applied.
- VM103/Jellyfin/Traefik healthy; NAS mounts present.
- Public Cloudflare-edge curl with redirect following: HTTP 200.

## Interpretation

Service and storage availability were restored by reboot. This is not proof of root-cause
resolution. No storage repair, restore, firmware change, or configuration change occurred
in this recovery. Keep wording as “controller/device unreachable/reset-failed; cause open,”
per the user's prior rejection of the “dead drive” conclusion.

## History links

- Long-running Bravo thread: Claude `42569d54-d339-4dac-a5d0-9fe01269743e`.
- July P41 flash/verification thread: Claude `028cfed9-8046-4929-b0c4-fe4e7b068369`.
- July 30 post-reboot/APST-ASPM analysis: Claude `47fd3267-7d5e-45af-89dd-a8d2a493d248`.
- Current triage: Codex `2026-09-05T07-02-32-01a07172-ed64-7413-a6f8-14678f0516ac` and
  continuation `2026-09-05T18-48-22-01a073f9-2439-76c3-8ef9-fae56578d06f`.
- Detailed working note: [`bravo-wedge-history-2026-09-05.md`](/home/tnunamak/code/waspflow/tmp/workstreams/bravo-wedge-history-2026-09-05.md)
