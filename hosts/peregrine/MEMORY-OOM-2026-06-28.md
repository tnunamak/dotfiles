# peregrine memory/OOM incident - 2026-06-28

This note records why peregrine's earlyoom floor was raised from 2GiB/1GiB to
6GiB/4GiB. Keep the durable config in `hosts/peregrine/host.sh`.

## Conclusion

The 2026-06-28 hard-poweroff incident matched memory reclaim/PSI collapse, not a
hardware panic and not a simple "swap is full" problem.

The old earlyoom config was too late for this workstation:

```sh
-r 3600 -m 4 -M 2097152,1048576 -s 100
```

Its effective floor was about 2GiB TERM / 1GiB KILL. On 2026-06-28, the desktop
was already in severe pressure above 4GiB available memory, and kernel OOM fired
earlier that day. The new policy is:

```sh
EARLYOOM_ARGS="-r 60 -M 6291456,4194304 -s 100,100 --prefer '^(brave|chrome|chromium|firefox|electron|node|node-MainThread|claude|codex|npm exec codex-|llama-server|python|python3|Discord)$'"
```

That means:

- TERM around 6GiB `MemAvailable`
- KILL around 4GiB `MemAvailable`
- ignore swap for both TERM and KILL decisions
- prefer killing browser / Electron / Node / Python / Claude / Codex / local
  LLM workloads before unpreferred processes with similar OOM scores

## Facts From The Incident

Previous boot ended at 2026-06-28 22:55:57 CDT. Current boot began at
2026-06-28 22:57:07 CDT.

No final-window kernel panic, NVMe, or GPU hardware error was found. The final
logs were dominated by memory-pressure symptoms, including repeated:

```text
systemd-journald: Under memory pressure, flushing caches.
```

At the bad final sample around 22:51:

- memory PSI was extreme: `%smem-10=99.00`, `%fmem-10=95.81`
- I/O and CPU PSI were also extreme
- run queue was hundreds deep; load average was about 696; blocked tasks were
  about 139
- `MemAvailable` was about 4.2GiB
- swap was effectively full
- swap I/O was not the main story: `pswpin/s` and `pswpout/s` were tiny compared
  with page-in, major faults, and reclaim scan/steal activity

Earlyoom had logged at 22:46:

```text
mem avail: 7845 of 107418 MiB (7.30%), swap free: 0
```

Under the old 2GiB/1GiB floor, earlyoom still had no reason to act. The system
entered severe pressure shortly after.

Earlier in the same boot, kernel OOM entries appeared around 01:00 and 13:00.
That means the documented "earlyoom was outrun" trigger was met before the final
hard poweroff.

## Swap Interpretation

Full swap alone is not an error on this box.

With swappiness 80 and a large desktop/LLM workload, Linux can park cold anonymous
pages in swap and leave them there. That is acceptable when `si/so`, PSI, major
faults, and reclaim pressure are low.

Bad signals are:

- high memory PSI
- high major faults
- high reclaim scans/steals
- high blocked tasks / run queue / load
- `systemd-journald` memory-pressure messages
- kernel OOM entries

The 2026-06-28 incident had those bad signals. It was not diagnosed merely from
swap being full.

## Why Not zram/zswap Or systemd-oomd

Prior tuning rejected zram/zswap for this host because the observed swapped-out
pages were mostly cold and the problem was not sustained swap throughput. The
problem was that global reclaim pressure could make the desktop unusable before
the kernel made a useful kill decision.

systemd-oomd/PSI-based policy may be worth revisiting someday, but it was not
chosen as the main guardrail here because KDE/user-session cgroup boundaries are
not clean enough to make it an obvious drop-in replacement. earlyoom remains the
simple global airbag.

Longer term, memory-managed cgroups for specific risky workloads would be more
precise than a global earlyoom floor, but less flexible.

## Expected Behavior

The new config does not reserve 6GiB idle. It allows Linux to use memory for
cache and reclaimable pages. It intervenes when `MemAvailable` falls to the last
few GiB and the machine is near the zone where this host previously became
unresponsive.

Expected tradeoff:

- a large browser, agent, Node, Python, or LLM process may die
- KDE and the rest of the session should be much less likely to wedge
- kernel OOM should be rarer for the same workload class

If this kills useful work during otherwise recoverable pressure, the first sane
step down is 5GiB/3GiB:

```sh
-M 5242880,3145728
```

If kernel OOM or hard freezes still occur, the next step is not to blame full
swap by itself. First inspect PSI/reclaim and then consider 8GiB/6GiB or
workload-specific cgroups.

## Recheck Commands

Find the boot:

```sh
journalctl --list-boots
```

Inspect earlyoom:

```sh
journalctl -b -1 -u earlyoom --no-pager
journalctl -u earlyoom -n 40 --no-pager
systemctl status --no-pager earlyoom
cat /etc/default/earlyoom
```

Inspect kernel OOM and pressure symptoms:

```sh
journalctl -b -1 -k --no-pager | rg -i 'out of memory|oom-killer|killed process|blocked|hung'
journalctl -b -1 --no-pager | rg -i 'under memory pressure|out of memory|oom|killed process'
```

Inspect sysstat for the incident day, replacing `sa28` and times as needed:

```sh
sar -f /var/log/sysstat/sa28 -q PSI -s 22:30 -e 22:57
sar -f /var/log/sysstat/sa28 -q     -s 22:30 -e 22:57
sar -f /var/log/sysstat/sa28 -r ALL -s 22:30 -e 22:57
sar -f /var/log/sysstat/sa28 -S     -s 22:30 -e 22:57
sar -f /var/log/sysstat/sa28 -B     -s 22:30 -e 22:57
sar -f /var/log/sysstat/sa28 -W     -s 22:30 -e 22:57
```
