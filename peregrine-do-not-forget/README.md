# Peregrine: things to not forget

Open kernel-crash investigation. As of 2026-05-05, kfence is enabled on next boot to catch the next Oops with full attribution.

## Active state to undo eventually

### Memory speed dropped to BIOS Auto (2026-05-05 ~23:00)
- Was: EXPO/DOCP I profile → 5000 MT/s configured (above SPD 4800)
- Now: BIOS "Auto" → 3600 MT/s configured (well below SPD 4800; AMD-conservative for 4×DIMM)
- Reason: After kfence captured a series of escalating crashes (kernel-VA write fault at 18h, double fault at 32s, GPF + refcount_warn_saturate at 30s), the multiple distinct fault signatures + escalating frequency + refcount saturation pointed at hardware (RAM/MC marginal) rather than software.
- Hypothesis: 4-DIMM Zen 4 memory controller marginal at any speed >3600 in this loadout; EXPO 5000 was just the most aggressive setting exposing it.
- **Performance cost**: ~28% memory bandwidth vs EXPO 5000. Tolerable while diagnosing.
- **If stable for >1 week**: meaningful evidence RAM/MC was at least contributing. Can experiment with intermediate speeds (DDR5-4400 or 4800 with elevated VSOC) to recover bandwidth.
- **If crashes return at 3600**: RAM speed exonerated; investigate PSU/VRM/CPU/storage/BIOS-microcode angles.
- **To restore**: BIOS → Ai Tweaker → enable EXPO/DOCP I (or set memory frequency manually).

### kfence sampling on GRUB cmdline
- Added by: `sudo /tmp/peregrine-enable-kfence.sh` on 2026-05-05
- Effective: takes effect on first reboot after the script runs
- Tokens added to `GRUB_CMDLINE_LINUX_DEFAULT` in `/etc/default/grub`:
  - `kfence.sample_interval=100`  (sample every 100ms, ~<1% overhead)
  - `panic_on_warn=0`  (explicit; default behavior)
  - `oops=continue`  (explicit; default behavior — keeps system up after Oops so journald flushes)
- Backup of original grub config: `/etc/default/grub.bak.YYYYMMDD-HHMMSS` (timestamp from when script ran)
- **Disable when done:** restore the backup and `sudo update-grub`. Or remove just the kfence tokens by editing `/etc/default/grub` and re-running `sudo update-grub`.

### CIFS mount options still aggressive
- `/etc/fstab` lines for `//192.168.1.11/share` and `//192.168.1.11/home` use `actimeo=1,closetimeo=1,retrans=1,soft`
- These create maximum inode-lifetime churn on a flaky CIFS server. They're a leading suspect for the writeback-path Oopses.
- Considered changing to `actimeo=30,closetimeo=10,retrans=3,hard,cache=loose` — did not do this yet because we wanted to gather kfence evidence first under unchanged conditions.

## What we're trying to catch

Recurring kernel Oopses on peregrine, signature varies but lands in mm/page-writeback or page-fault paths. Two captured to date:

- 2026-05-04 12:14 — `BUG: page fault for address 0x0000000040000034`, `Oops: 0000 [#1] SMP NOPTI`. Netconsole truncated before RIP/Modules.
- 2026-05-04 23:21 — `Oops: general protection fault, probably for non-canonical address 0x6fff8e1ff33d9a80: 0000 [#1] SMP NOPTI` + `WARNING ... mm/page-writeback.c:2740 __folio_mark_dirty+0x9c/0xa0`. Single event; WARN fired from inside the GPF.

Original incident (pre-recovery) had multiple BUG/Oops messages (page faults, Bad page map, NULL deref, bad stack frame pointer) seconds after KDE login. That was likely the NVIDIA 590/595 stale-initramfs mismatch and is fixed.

The current crashes are slow-onset (15h and 11h uptime) and look like a different bug — leading suspect is a CIFS-related inode-lifetime UAF in writeback, but not confirmed by upstream lore search. kfence is the diagnostic to confirm or refute.

## What success looks like

Next Oops produces a kfence stack trace naming alloc/free/access sites:
```
BUG: KFENCE: use-after-free in <function>+<offset>
allocated by ...
freed by ...
accessed by ...
```

If that names a CIFS / netfs function → CIFS confirmed.
If it names something else → suspect class shifts.
If kfence stays silent through next Oops → not a UAF; pursue hardware (RAM at XMP, CPU/AGESA microcode) or look at non-UAF kernel bugs.

## Files / state to reference

- Memory: `~/.claude/projects/-home-tnunamak/memory/peregrine-crash-investigation.md`
- Crash log capture: `~/tmp/log.txt` (netconsole-via-ntfy GPF capture)
- Diagnostic script: `/tmp/peregrine-deep-check.sh` (read-only state collector)
- kfence enable script: `/tmp/peregrine-enable-kfence.sh`

## Hardware / system context

- ASUS ProArt X670E-CREATOR WIFI, BIOS 2204
- AMD Zen 4, microcode `0x0a601206`
- 4×32GB DDR5 G.Skill, SPD 4800 MT/s, **running 5000 MT/s via EXPO** (above-spec; possible RAM-marginal contributor; not yet tested at JEDEC)
- NVIDIA 595.58.03 across kernels 6.17.0-20/-22/-23 (DKMS clean)
- Synology DS1821+ at 192.168.1.11 (CIFS server) — DSM 7.2.0-64570u4, healthy, 30+ day uptime, not the source of crashes itself but produces normal SMB session recycling that the client races

## Don't get distracted by

- TabbyAPI/Daisy 503 errors — separate problem, not related to kernel crashes
- VirtualHere / vhci_hcd — initially suspected; ruled out by the writeback-path crash signature
- NVIDIA — versions match across kernels, no Xid messages in journal
- The path_noexec WARNs from Brave — benign, indicates Brave mmap'ing files from CIFS, not a crash
