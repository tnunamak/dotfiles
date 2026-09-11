# Root cause: why "a lot of the windows in tmux main didn't restore properly"

Verified 2026-09-10 ~20:50 from raw logs, plugin source, and dotfiles git history.
High confidence. **This supersedes an earlier draft that got the causality backwards.**

## TL;DR

**The restore worked correctly. It was handed a 10-day-old snapshot.**

The newest tmux state available when you crashed this morning was from **Aug 30
22:06** (118 panes). Ten days of window state was never written to disk.

The gap has a precise, slightly painful explanation: **you already fixed this bug
on Aug 31, and the fix was enabled but never started.** It began working at
10:00 today — the reboot that followed the crash it would have protected you from.

## The evidence chain

### 1. Continuum's saves stopped Aug 31

Saves per day, `~/.tmux/resurrect/post-save-backup.log`:

```
2026-08-22   283
2026-08-23   288     <- healthy: ~288/day = one per 5 min
...
2026-08-30   236
2026-08-31    35     <- stops mid-day
2026-09-01     0     <- BLACKOUT
  ...            0      (Sep 1-9: zero entries)
2026-09-09     0
2026-09-10   148     <- resumes 10:04 today
```

### 2. Why continuum stopped — documented in your own commit

Commit `e129af6` (Aug 31 00:42), *"Add an independent periodic tmux recovery save"*:

> tmux-continuum normally saves sessions from a status-line hook, but it could
> leave recovery state stale because **it refused to install its autosave
> interpolation while another tmux server was running.** Recovery freshness then
> depended on stop-time saves, the path that failed during this incident.

So continuum's 5-minute interval was **inert** — it never installed its save hook
because other tmux servers existed (you routinely run isolated `tmux -L` sockets).
Not a crash, not a lock, not a config error: it silently declined to arm itself.

(The hook string IS present in `status-right` today and settings read correctly —
`@continuum-save-interval 5`, `status-interval 15` — which is exactly what makes
this failure so hard to see by inspection.)

### 3. The fix existed on Aug 31 but did not run until today

`e129af6` added a client-independent systemd user timer,
`tmux-resurrect-periodic-save.timer` (OnBootSec=5min, OnUnitActiveSec=5min),
calling `~/.config/tmux/scripts/tmux-resurrect-periodic-save`. Correct design: it
takes a trigger lock, checks the default socket with `tmux -N has-session`, and
invokes one quiet `save.sh`.

But its log, `~/.tmux/resurrect/periodic-save.log`, contains:

```
first entry: [2026-09-10T15:05:01Z]      <- 10:05 CDT today
Sep 1-9:     (nothing — the file has no entries before today)
today:       128 x "completed", 0 failures
```

And the timer unit reports `Active: active (waiting) since Thu 2026-09-10 10:00:10`.

The commit message called this outcome in advance:

> Teach setup to enable the timer after daemon-reload. It enables the timer rather
> than the oneshot service and **deliberately omits `--now`, so setup does not
> immediately start a save in the live user manager.** ... Setup enablement alone
> **intentionally does not start the timer until a later manager lifecycle or an
> explicit start.**

`enable` without `--now` schedules for the *next* user-manager start. No one ran
`systemctl --user start`, and the user manager did not restart until this morning's
boot. So from Aug 31 to Sep 10: continuum disarmed, timer enabled-but-not-running,
**no saver of any kind active.**

### 4. Confirming a single boot

`journalctl --list-boots`: previous boot Aug 29 02:07 → Sep 10 09:57; current boot
from 10:00:04. tmux server PID 3437 alive since 10:00. All 49 state files in
`~/.tmux/resurrect/` are dated today. There was **no second crash at ~20:11** —
whatever you experienced tonight did not touch the tmux server.

### 5. The restore itself behaved correctly

```
[2026-09-10T15:05:01Z] backed up tmux_resurrect_20260910T100455.txt
    (panes=98, prev=layout-tmux_resurrect_20260830T220559.txt with 118 panes)
```

That `prev=` chains straight to the **Aug 30** file. Restore replayed the only
input it had. The cliff guard, SIGPIPE fallback, and dangling-symlink handling
from the April/July hardening all worked — they were just fed stale data.

## Current state: healthy

- Timer firing every 5 min (last 20:40:33, next 20:45:33), 128 `completed`, 0 failures.
- `last` symlink resolves to tonight's newest save.
- `@continuum-save-last-timestamp` advancing.

**So there is nothing to fix right now.** The exposure was Aug 31 → Sep 10 and it
is closed. What remains is making sure it cannot silently reopen.

## Recommended fixes, ranked

### 1. Dead-man's switch on save freshness (high value, ~1 hour) — THE fix

Everything else here is already built. What is missing is the thing that would
have told you within 30 minutes instead of 10 days. Two independent savers both
failed silently; a third mechanism should assert *outcomes*, not liveness:

```bash
# ~/.config/systemd/user/tmux-save-watchdog.{service,timer}  (OnUnitActiveSec=15min)
newest=$(ls -t ~/.tmux/resurrect/tmux_resurrect_*.txt 2>/dev/null | head -1)
age=$(( $(date +%s) - $(stat -c %Y "$newest") ))
[ "$age" -gt 1800 ] && ntfy-send "tmux state not saved in $((age/60))m"
```

30-min threshold against a 5-min interval = 6 missed cycles, so no false alarms.
Put it in `dotfiles/systemd/.config/systemd/user/` next to `core-guard` and
`tmp-reaper`, which already follow this pattern. **And start it with `--now`.**

### 2. Make `setup.sh` start timers, not just enable them (high value, small)

The general lesson, and it generalizes past tmux: `enable` without `--now` means
"works after the next reboot," which is indistinguishable from "works" until a
reboot you did not plan. Either use `enable --now` for idempotent timers, or have
`setup.sh` report which enabled units are not currently active so the gap is
visible. Worth auditing the other units in `dotfiles/systemd/` for the same
pattern.

### 3. Accept the conversation-continuity ceiling (no fix possible)

Even with perfect saves, tmux-resurrect re-runs a command; it cannot restore an
LLM conversation. A restored `claude` resumes against a session ID, and if that ID
is stale the window looks "wrong" though restore succeeded. This is the recurring
"you resurrected wrongly" confusion (this morning 10:15, and ≥2 prior incidents).

For agent windows the right source of truth is **waspflow's durable lane state**,
which persists cwd + session id and survives an assistant's own compaction. Scope
tmux-resurrect to "shell in the right cwd"; let waspflow answer "which session
belongs here."

### 4. Latent bug in continuum's lock (low urgency)

`continuum_save.sh: acquire_lock()` creates two lockdirs under **`/tmp` (RAM-backed
tmpfs here)** keyed to the tmux server PID. If the first `mkdir` succeeds and the
second fails, it returns 1 while holding the first; a kill between those lines
leaves a stale lockdir that blocks saves until the generation window rolls.
Verified **no leaked lockdirs right now**, so this did not contribute. Upstream
continuum has ~no commits in a year, so a fix belongs in the local patcher.

## Related still-open item

`timvw/tmux-assistant-resurrect` PRs **#103** ("prefer the group name when saving
shared panes") and **#104** are both **still OPEN / unmerged** (verified via `gh`
today). Local patcher blocks remain load-bearing — do not retire them.

#103 is independently relevant: tonight's save captures panes under only
`main-37`, none under bare `main` or the other 7 group members — the exact
grouped-session bug it targets. Harmless tonight (nothing restored from that save),
but it makes the *next* restore's identity accuracy depend on which group member
was picked at save time.

## Correction to an earlier draft

My first pass concluded the blackout was caused by continuum needing an attached
client to render its status line. That is a real property of continuum's design,
but it is **not** what happened: the commit message and the `periodic-save.log`
dates show continuum was disarmed by the *other-tmux-server* condition, and the
replacement timer was enabled-but-never-started. I corrected this after reading
`e129af6`. Flagging because the wrong version sounds equally plausible and would
have sent the fix in the wrong direction.
