# tmux agent resurrection forensic audit

**Scope:** read-only inspection at 2026-07-13T05:40:15-05:00. No tmux
session, process, service, socket, save-state, or configuration was stopped,
restarted, killed, or changed. Pane contents and process command arguments are
intentionally omitted from this report.

## Conclusion

The fleet was created by the intended but over-broad restore path, not by an
independent `mcp-searxng` supervisor:

```text
systemd starts tmux.service (11:27:57)
  -> BindsTo/PartOf starts tmux-restore.service (11:27:59)
  -> systemd-restore.sh restores the tmux-resurrect layout
  -> post-restore-grouped-focus.sh invokes assistant restore
  -> tmux-assistant-resurrect replays 39 saved Codex/Claude sessions
  -> each replayed CLI starts its configured mcp-searxng server(s)
```

The assistant replay started at 11:28:14 and logged `restored 39 of 39` at
11:29:47. The 34 complete `mcp-searxng` launch trees started from 11:28:21 to
11:29:46. That timing and the parent chains make the causal conclusion
**high-confidence**.

This is not evidence of tmux duplicating a still-live server: the systemd
service had `NRestarts=0`, and one restore invocation replayed a saved fleet
into a fresh tmux server. It *is* evidence that the restore policy treated a
historical assistant inventory as current work without a liveness or intent
boundary.

## Live impact

| Snapshot measure | Result |
| --- | ---: |
| `mcp-searxng`-related processes | 103 |
| Complete npm-launch trees | 34 |
| Processes in those complete trees | 102 (34 × wrapper/shell/runtime) |
| Additional related child | 1 |
| MCP fleet RSS | 1,915,384 KiB / **1,870.5 MiB** |
| MCP npm-wrapper RSS | 891.8 MiB |
| MCP shell/runtime RSS | 978.7 MiB |
| Live Claude processes | 19 / 3,851.1 MiB RSS |
| Live Codex processes | 26 / 2,152.2 MiB RSS |
| tmux sessions / panes | 27 / 134 (0 dead) |
| Current assistant sidecar entries | 40 |
| Largest retained assistant sidecar | 99 |

Of the 34 complete MCP trees, 25 have a currently live Codex/Claude ancestor
(75 MCP-related processes). Nine trees (27 processes) no longer have one.
Those nine are the strongest evidence of stale work: no currently live agent
owns their MCP launcher/server subtree, which instead remains under a
surviving pane-shell ancestry. The remaining 25 are **not safely classifiable as leaks** from this
evidence: they are descendants of live agents and may be intentional active
sessions.

The extra related child is not enough evidence to label without inspecting its
arguments or affecting it, so it is deliberately excluded from the complete
tree classification.

## Exact evidence

### Startup and restore chronology

* User-systemd journal: `tmux.service` began at **11:27:57** and was active at
  **11:27:59** on 2026-07-12; `tmux-restore.service` began at **11:27:59** and
  finished at **11:29:47**.
* `assistant-restore.log`: the restore announced **39 assistant sessions** at
  **11:28:14** and completed **39/39** at **11:29:47**.
* The 34 MCP npm wrappers began at 11:28:21, :22, :23, :24, :26, :27, :33,
  :33, :38, :39, :39, :42, :43, :44, :44, :47, :49, :50, :56 (five), 11:29:00,
  :01, :03, :06, :07 (three), :09, :24, :43 (two), and :46. They are wholly
  inside the assistant replay interval.
* Immediately before the restart, the guarded save logged 39 assistant
  sessions and the layout save had 74 panes. The later 11:33 save recorded 38
  assistant sessions. This is consistent with replay, then normal process
  attrition; it is not consistent with a separate recurring spawn loop.

### Configuration path

* [`tmux.conf`](tmux/.config/tmux/tmux.conf) loads `tmux-resurrect`,
  `tmux-continuum`, and `tmux-assistant-resurrect`; continuum's own restore is
  explicitly off. Its post-restore hook is the local
  `post-restore-grouped-focus.sh` wrapper.
* [`tmux-restore.service`](tmux/.config/systemd/user/tmux-restore.service)
  is `BindsTo=tmux.service` and `PartOf=tmux.service`; therefore every tmux
  service start runs `systemd-restore.sh` after the patcher.
* [`systemd-restore.sh`](tmux/.config/tmux/scripts/systemd-restore.sh) restores
  whenever the new server has at most two panes and the save has at least
  three. Its protection is against overwriting live tmux state, not against
  stale assistant replay.
* [`post-restore-grouped-focus.sh`](tmux/.config/tmux/scripts/post-restore-grouped-focus.sh)
  rebuilds grouped-session presentation and then unconditionally runs the
  assistant restore script.
* The installed assistant restore script reads `assistant-sessions.json`, waits
  only five seconds per session for a client, logs the absence of a client, and
  **replays anyway**. It injects a resume command into every eligible restored
  shell using `tmux send-keys`. It has no entry age, explicit intent,
  completion, heartbeat, or process-group cleanup gate.

This combination explains both questions: all saved sessions are actively
restarted headlessly, and an MCP child has no owner-side reaper once the agent
that started it exits.

### Current tmux state

The server is alive and stable: 27 sessions, 134 panes, no dead panes, and
two attached clients on grouped `main` views. Twenty-four sessions are
unattached. Session names and counts show several retained test/reproduction
sessions as well as working sessions. That makes a blanket “all restored
sessions were intentional” claim untenable, but it does **not** authorize
closing any particular live pane.

## What is expected versus stale

| Class | Evidence | Assessment | Confidence |
| --- | --- | --- | --- |
| 25 complete trees | Live Codex/Claude ancestor remains | Potentially intentional; preserve | High for ancestry, low for user intent |
| 9 complete trees | No live agent ancestor remains | Unowned/likely stale MCP fleet | Medium-high |
| Historical saved entries | 39 were replayed, but only 40 are currently saved; saved state contains no explicit completion/lease state | Cannot infer present intent from save state | High |
| Detached/restored tmux sessions | Layout persistence preserves them; many look test/repro-related | Candidate stale sessions, not proven stale | Medium |

“No client attached … replaying anyway” is especially important. A headless
layout restore is safe; a headless agent replay changes external process state
and should not be implied by layout persistence.

## Safest systemic design

Separate **layout recovery** from **agent execution recovery**. The two have
different safety properties and must not share an implicit “saved means
resume” flag.

1. Keep the existing tmux-resurrect layout/backup path. It protects data and
   enables inspection of every old pane without running its workload.
2. Replace automatic assistant replay with a durable per-pane *resume lease*:
   `pane identity`, `agent kind`, `session id`, `saved_at`, `last-confirmed
   heartbeat`, `policy (manual | attached | explicit-auto)`, and an expiry.
   Absence of a valid lease means **deferred**, never “run anyway.”
3. Default every restored historical entry to `deferred`. A visible pane banner
   and a read-only/status CLI should show `saved`, `deferred`, `expired`, or
   `eligible` plus the exact reason. This preserves the session identifier and
   cwd without re-executing it.
4. Permit automatic resume only for a short-lived, explicit `explicit-auto`
   lease, and only after an attached client is present for that session. Do
   not use a five-second timeout as consent. Long-running autonomous workers
   should be renewed by their launcher/orchestrator, not inferred from a
   generic process scan.
5. Start each agent and its MCP servers in a per-pane/process-group or systemd
   user scope with an owner token. On normal agent exit, reap only descendants
   carrying that same token. On restore, run a conservative reaper that reports
   orphan candidates first; it must never kill an ancestry-linked live agent
   or an unknown process.
6. Make MCP lifetime explicit: either one owner-managed shared MCP service per
   user/session (if the client supports it safely), or one MCP scope per agent
   that is stopped when its owner ends. Do not rely on npm/stdio child-process
   exit behavior as cleanup.

This applies the repository’s existing researched pattern of a heartbeat,
wall-clock bound, startup reaper, and fencing/ownership token
([research note](/home/tnunamak/code/dotfiles/ai/research/distributed-systems/bounding-a-hung-job-uses-heartbeat-plus-wall-clock-timeout-a-startup-reaper-and-fencing-tokens.md)).
The lease is the human-intent boundary; the token/scope is the mechanical
ownership boundary. Neither should be inferred from a resurrect snapshot.

## Reversible implementation plan (do not execute during this audit)

1. **Add observation only.** Implement `tmux-agent-resume status --json` and
   `tmux-agent-resume plan --json`. It reads sidecar entries, live panes,
   leases, and owner scopes and emits a deterministic action plan; no
   `send-keys`, no kill, no tmux mutation. Test it with isolated `tmux -L`
   sockets.
2. **Back up before policy changes.** Copy the current resurrect layout,
   assistant sidecar, and a generated plan to timestamped backup files. Add a
   one-command rollback that restores only the previous hook configuration;
   do not restart tmux as part of rollback.
3. **Deploy deferred mode only.** Change the post-restore wrapper to record
   deferred entries instead of invoking the plugin's replay script. Leave the
   existing save/backup safeguards intact. Validate with a disposable isolated
   socket and fixture sidecars: layout returns, zero agents/MCP processes are
   launched, and `status` lists each deferred item.
4. **Add opt-in resume.** Implement `tmux-agent-resume resume <pane-or-id>`;
   require an attached client by default and make it create a fresh lease.
   Add `--allow-headless` only for an explicit orchestration caller and record
   its lease TTL/owner token. Test one selected pane end-to-end, then an
   intentional multi-agent session.
5. **Add ownership cleanup in report-first mode.** On agent exit and startup,
   list eligible orphan scopes with PID/RSS/age only. Require an explicit
   `reap --owner-token …` action initially. After repeated verified runs,
   optionally auto-reap only expired, token-matched scopes.
6. **Migrate existing state conservatively.** Mark all current 40 saved
   entries `deferred`; never delete them during migration. The user can resume
   selected ones or deliberately discard their lease. Keep old sidecars until
   the new mechanism has survived at least one real reboot/restore test.

## Residual uncertainty

* I can prove process lineage, timing, restore count, and RSS. I cannot prove
  a human's current intent for any live agent from process metadata alone.
* The nine no-agent-ancestor trees are likely stale, but the audit did not
  inspect their protocol traffic or send signals; a rare externally owned MCP
  use or an unusual deliberate daemonization cannot be ruled out absolutely.
* The report deliberately excludes prompt text, session arguments, tokens, and
  pane contents. Confidence in causal attribution is **high**; confidence in
  per-pane intent classification is **low to medium** and should be resolved
  by an explicit resume lease rather than forensic guesswork.
