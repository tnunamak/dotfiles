---
title: "Never tear down live agent-launch infrastructure (proxies, launch wrappers) while sessions are running; find the master switch and prefer pause over kill"
date: 2026-06-26
topic: agentic-context-design
tags: [operational, incident, headroom, launch-wrapper, proxy, tokensmash, blast-radius]
status: settled
sources: [incident-2026-06-26]
source_session: unknown
---

## CLAIMS

- Token-tool wrappers (Headroom/RTK via tokensmash launch) are not optional add-ons — they ARE the launch path: the `claude`/`codex` shell functions route through `tokensmash-launch → headroom wrap`, which injects the model base_url/proxy into each session at launch. Removing the proxy out from under running sessions breaks them (they hold connections to it / are pinned to its base_url for their process lifetime). [incident-2026-06-26]
- Stopping the headroom systemd proxy mid-flight, then restarting, did NOT collapse the process swarm: the runaway proxy + ~40 headroom procs (29 `mcp serve`, 8 `wrap`) were spawned by the wrap launch chains, not the systemd service, so `systemctl restart` only churned its own one proxy while an orphaned proxy kept pegging ~780% CPU and owning the port. Load hit ~135 on 24 cores. [incident-2026-06-26]
- The correct OFF switch was a single config field, not a kill: tokensmash study `config.json` `mode: "live" → "off"`. With mode != live, launchctl does a plain exec (no wrap, no proxy injection) — disabling ALL tool actuation while preserving the study framework + data for future tools. Reversible, one line. (assign.py: `if config is None or config.get("mode") != "live": return None`.) [incident-2026-06-26]
- A process's env (e.g. ANTHROPIC_BASE_URL=proxy) is frozen at launch; you cannot un-pin a running session by fixing config/env after the fact — only a fresh process picks up the change. Diagnose with /proc/<pid>/environ and `ss -tnp`, not assumptions. [incident-2026-06-26]
- "ConnectionRefused" in Claude Code can be MISLEADING: it appeared for (a) sessions pinned to a downed proxy AND (b) an over-context session (~1.2M tokens vs the model's window) that was too large to send any request, including /compact — a deadlock (too full to talk, can't compact without talking). Verify the real cause: fresh `claude -p` working + api.anthropic.com reachable means system-healthy and the failure is session-specific. [incident-2026-06-26]
- Auto-compaction failing during the proxy flap let sessions grow past their limit unchecked — the infrastructure disruption directly caused the over-context wedge. Long sessions depend on working API connectivity to stay compacted. [incident-2026-06-26]
- An over-limit session's content is still recoverable from its on-disk transcript (~/.claude/projects/<proj>/<id>.jsonl) even when live --resume is impossible; extract user+assistant turns to a doc. [incident-2026-06-26]

## SOURCES

**incident-2026-06-26**
URL: local — this session (c0dad57d), 2026-06-26 disabling RTK/Headroom/context-mode
Accessed: 2026-06-26
Quote: Stopping the Headroom proxy mid-flight broke live Claude/Codex sessions, spawned a 40-process swarm pegging CPU at ~780% (load ~135/24 cores), and wedged an over-context session. Root fix was tokensmash study mode:off (the master switch), not killing processes. Leaked the full shell env (all secrets) by printing a launch-resolution dict — separate lesson: never print env/whole dicts.

## SYNTHESIS

Operational rules for changing agent infrastructure: (1) Identify the MASTER SWITCH before
touching anything — for wrapper-class tools it's the actuation config (tokensmash study
mode), not the daemon or the per-session config the wrapper re-injects. (2) Prefer pause/
disable over kill, especially with `Restart=always` services that respawn and race for ports.
(3) Treat the launch wrapper as load-bearing: changes affect how EVERY agent starts; do them
when sessions are idle, or accept that running sessions break and need a fresh relaunch.
(4) Don't kill the load-bearing process to "free CPU" if it's serving live connections —
drain first. (5) When debugging "ConnectionRefused", first prove system health (fresh `claude
-p` + direct API reach) to localize to one session, then check that session's frozen env and
context size — don't theorize. (6) NEVER print process env or whole resolution dicts — it
leaks every secret to the transcript (happened here).
