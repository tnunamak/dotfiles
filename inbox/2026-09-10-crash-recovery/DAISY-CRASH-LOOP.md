# daisy crash loop, 2026-09-11 — diagnosed and stopped

## Symptom

`main:0` (daisy) scrolled `daisy-bwrap: granting write access to '.../vivid-fish'`
forever. That line was a red herring: it is normal launcher output, repeating
because the LAUNCHER was being re-run every ~6 seconds.

`journalctl --user -u daisy.service` showed the real shape:

```
daisy: stale main:daisy detected (exit_status=1); cleaning + respawning
daisy: monitoring main:daisy
```

`start_service.sh` is a watchdog: if pi is not alive in `main:daisy`, it
respawns it. pi was exiting 1 immediately, so the watchdog respawned forever.

## Root cause

The error only appears in the pane, for the ~5s before the watchdog kills it:

```
Error: Failed to load extension ".pi/extensions/approvals/index.ts":
  Cannot find module '../../../npm/node_modules/@llblab/pi-telegram/api/delivery.ts'
Require stack: .pi/extensions/approvals/channels/telegram.ts
```

The working tree held an **uncommitted rewrite** of the approvals extension,
written against pi-telegram **0.21.0**'s "Delivery API". Its own header comment
says so. But:

- installed pi-telegram is **0.20.6**, whose `api/` holds commands, inbound,
  keyboard, outbound, sections, status, updates, voice — **no `delivery.ts`**
- `git ls-remote git@github.com:Vivid-Fish/pi-telegram.git main` →
  `1227987357685b9e8a3840bb64b9c40a1e979f45`, which is **exactly** the commit
  pinned in `.pi/npm/package-lock.json`

So 0.20.6 **is** current upstream, and the Delivery API **does not exist yet**.
This was not a broken install or a bad upgrade — it was in-progress work
committed to nothing, written against an API that was never released.

`git show HEAD:.pi/extensions/approvals/channels/telegram.ts | grep -c
api/delivery.ts` → **0**. The committed version never referenced it.

## Fix applied

Stashed the incomplete refactor so daisy runs on committed code:

```
stash@{0}  WIP: approvals rewrite vs unreleased pi-telegram 0.21.0 Delivery API
           (daisy crash-loop 2026-09-11)
```

Scope: `.pi/extensions/approvals/` — 11 modified files plus 2 new
(`core/presentation.ts`, `test-telegram-bun.test.ts`). **Nothing was deleted**;
`git stash pop` restores it whenever the Delivery API lands.

Daisy recovered immediately: the pane now shows `pi-lens ✓ clean`,
`telegram connected`, `MCP: 1 server enabled`, and the respawn loop stopped.

## Note for whoever resumes that refactor

It cannot work until pi-telegram ships the Delivery API. Since Vivid-Fish is
Tim's own org, the unblocking move may be to ship it upstream first rather than
to port the refactor down onto 0.20.6's `outbound.ts`. A separate assessment of
that trade-off is in `daisy-approvals-wip.md` (same directory) if it completed.

## Lesson

A watchdog that respawns on failure converts a load-time error into an infinite
loop that hides its own cause: the error scrolls past in the pane and never
reaches the journal. `start_service.sh` already logs `exit_status`; logging the
pane's last few lines on a stale respawn would have named this in seconds
instead of requiring a race to capture the pane before teardown.
