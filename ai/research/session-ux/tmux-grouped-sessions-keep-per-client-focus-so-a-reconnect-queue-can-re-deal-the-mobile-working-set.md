---
title: "tmux grouped sessions keep per-client current-window focus independent, so a reconnect can re-deal each dropped mobile client its pre-drop window — but tmux itself does not persist that per-client focus across a disconnect; a sidecar must record it"
date: 2026-07-16
topic: session-ux
tags: [tmux, grouped-sessions, reconnect, per-client-focus, hooks, restore-queue]
status: draft
sources: [tmux-man, tmux-superfocus, tmux-groups-gist, tmux-hooks, tmux-picker-gist, blink-persist]
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation/conclusions. Skippable. No citations here.
-->

## CLAIMS

- In a tmux session group, sessions share one set of windows (new/closed windows propagate to all group members), but "The current and previous window and any session options remain independent and any session in a group may be killed without affecting the others." [tmux-man]
- Plain `attach-session` shares one current window across all clients on that session, so switching windows on one client forces every other client to the same window; grouped sessions (`new-session -t <group>`) are the standard fix for independent per-client focus. [tmux-superfocus][tmux-groups-gist]
- The idiom is `tmux new-session -t main -A -s <client-name>` (attach-if-exists else spawn a grouped clone); each grouped session keeps its own focus. [tmux-superfocus]
- Detached grouped clones accumulate ("zombie" sessions) unless leaving tmux is changed — remap detach to kill-session, or set `destroy-unattached` on the clones (not on main). [tmux-groups-gist][tmux-superfocus]
- tmux 3.6 adds `default-client-command`, letting bare `tmux` default to `new-session -t main` so a fresh connection joins the group instead of making a new window set. [tmux-superfocus]
- tmux exposes `client-attached` and `client-detached` hooks that fire when clients connect/disconnect; a hook re-runs on every attach unless it self-unsets (`set-hook -u <hook>`), and `session-created` covers the brand-new-session case where `client-attached` may not fire. [tmux-hooks]
- The `active-pane` client flag lets a client select the active pane independently of other clients on the same session (cursor/command target only) — a per-client property, but scoped to pane focus, not window focus. [tmux-hooks]
- An SSH-login picker is conventionally a shell-rc script gated on `SSH_TTY` set and `TMUX` unset, showing an fzf menu to start a shell / new session / attach; full-screen fzf with `--no-unicode` avoids layout glitches when a mobile software keyboard changes terminal height, and `tmux -u` forces UTF-8. [tmux-picker-gist]
- No surveyed tmux mechanism persists a client's current-window focus across that client's disconnect: grouped-session focus is independent *while attached*, but a killed/detached clone's "which window was it viewing" is not retained by tmux; reconstructing it requires recording it externally (the Blink feature request proposes exactly this client-side: store tab/session state on disk to reopen the same tabs on restart). [tmux-man][blink-persist]

## SOURCES

**tmux-man**
URL: https://man7.org/linux/man-pages/man1/tmux.1.html
Accessed: 2026-07-16
Quote: "Sessions in the same group share the same set of windows - new windows are linked to all sessions in the group and any windows closed removed from all sessions. The current and previous window and any session options remain independent and any session in a group may be killed without affecting the others."

**tmux-superfocus**
URL: https://blog.nicholas.clooney.io/posts/my-super-powered-tmux-one-session-but-multiple-focuses/
Accessed: 2026-07-16
Quote: "Sessions in the same group share windows but keep their own focus." / "tmux new-session -t main -A -s <client-name>" / tmux 3.6 `default-client-command` set to `new-session -t main`.

**tmux-groups-gist**
URL: https://gist.github.com/chakrit/5004006
Accessed: 2026-07-16
Quote: Substituting attach-session with `new-session -t` builds up detached sessions unless you remap detach to kill-session or set `destroy-unattached` on the grouped (non-main) sessions.

**tmux-hooks**
URL: https://devel.tech/tips/n/tMuXz2lj/the-power-of-tmux-hooks/
Accessed: 2026-07-16
Quote: `client-attached`/`client-detached` hooks re-run on every attach; self-unset with `set-hook -u`; use `session-created` for brand-new sessions. `active-pane` client flag selects active pane independently per client.

**tmux-picker-gist**
URL: https://gist.github.com/golbin/2842fab87515ce56b3bb1a216f8c433e
Accessed: 2026-07-16
Quote: SSH-login picker gated on `SSH_TTY` set and `TMUX` unset; full-screen fzf `--no-unicode` to avoid glitches when a mobile keyboard changes terminal height; `tmux -u` for UTF-8.

**blink-persist**
URL: https://github.com/blinksh/blink/issues/59
Accessed: 2026-07-16
Quote: "Blink might store the client information on disk whenever a connection is first established, so that restarting the app could seamlessly reconnect, opening all the tabs from when the app was last running."

## SYNTHESIS

This is the load-bearing finding for a reconnect-restore design. Tim already runs grouped sessions (`main-N` clones), and the tmux manual confirms the exact property that makes a per-device restore *possible*: current-window focus is independent per clone. So "each Termius tab was looking at window X" is well-defined per clone while attached.

But there is a hard gap: **tmux does not remember that focus once the clone dies.** When wifi→5G drops all connections, the clones detach/die and their "which window" is gone. Prior art does not solve this at the tmux layer — the only concrete per-device restore proposal found is Blink's client-side one (store tab state on disk, reopen the same tabs on restart). That's the shape of the answer, just on the wrong side of the wire for this setup (Termius won't do it, and it can't).

So the design that fits: **a server-side sidecar that records, per client, the window it's viewing, updated on a `client-session-changed`/window-focus hook, keyed by a stable device identity — and a reconnect queue that re-deals it.** This directly parallels the desktop kitty "restore queue" Tim already has: after a drop, incoming Termius connections consume a queue that hands each one its pre-drop window. Concretely:

- **Record:** on each grouped clone, a hook writes `{device_id → last_window}` to a small file (the same pattern the assistant-resurrect sidecar uses to key session IDs per pane). Device identity has to come from something Termius can carry across a reconnect — a per-tab startup-command argument or a `LC_*`/env var pinned to that Termius host entry (Termius sets env per host), since the clone name `main-N` is not stable across a drop.
- **Re-deal:** the login auto-attach script checks the queue: if this device has a recorded window, create its grouped clone and `select-window` to it; else hand it the picker. This makes reconnect "land back where I was" instead of "rebuild the working set by hand."
- **Lifecycle hygiene is a prerequisite, not optional:** the CLAUDE.md history already documents that grouped clones leak without `destroy-unattached keep-last` set *after* attach and a two-strikes reaper. A restore queue that re-deals to stale clones would compound that. The queue must reconcile against `tmux list-clients` (authoritative liveness), not clone count.

One caveat worth stating with low confidence: whether to restore *per device* or *per working-set* depends on how Tim thinks about his tabs. Prior art (Blink) restores per-app-instance (all tabs that app had). If Tim's mental model is "my 3 mobile views," a single ordered working-set queue (device-agnostic, re-dealt in order to whatever reconnects) is simpler than tracking stable device IDs and likely matches the kitty-queue pattern he already likes. I'd lean working-set-ordered-queue over per-device unless he wants device-specific layouts.
