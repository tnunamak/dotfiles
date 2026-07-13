# tmux agent resume leases

## Boundary

`tmux-resurrect` remains the layout-recovery mechanism. It recreates panes and
working directories so historical work can be inspected. It does not authorize
running a saved agent, its MCP servers, or any other child process.

The local `tmux-agent-resume` command reads the existing
`~/.tmux/resurrect/assistant-sessions.json` sidecar as input and keeps its own
state at `~/.local/state/tmux-agent-resume/state.json`. The third-party replay
script is neither modified nor invoked by this recovery boundary.

## Normal operation

```bash
tmux-agent-resume status --json
tmux-agent-resume plan --json
tmux-agent-resume resume <pane-or-id-or-session-id>
```

`status` and `plan` are read-only. `record-deferred`, which the post-restore
hook runs, writes only local lease state and marks historical sidecar entries
deferred. It never sends keys or starts an agent.

`resume` is intentionally single-entry. It requires a client attached to the
entry's tmux session and creates a short-lived manual lease before sending the
resume command. `grant <selector> --auto --ttl 900` creates a short-lived
automatic lease but does not run it. A caller must explicitly invoke
`apply --execute-auto`; it will execute only unexpired `explicit-auto` leases
whose session is attached. Each automatic lease is consumed before dispatch and
cannot inject the same resume command twice.

For a deliberate headless orchestrator flow, both switches are required:

```bash
tmux-agent-resume grant <selector> --auto --ttl 900 \
  --allow-headless --owner waspflow
tmux-agent-resume apply --execute-auto
```

The lease records pane identity, agent kind, saved session id and timestamp,
policy, expiry, and its last confirmed heartbeat (initially the explicit grant
time). The owner name and a generated owner token are retained in the lease.
Resumed commands run in a separate `setsid` process group with that token in
their environment. `orphans --json` reports expired-lease candidates only; it
does not inspect or classify live PIDs, infer that a process is disposable, or
**ever kill anything**. Process reaping is a future, separately validated
change.

## Rollback

The boundary is reversible without restarting tmux:

1. Save the current hook value and sidecar: `tmux show-option -gqv
   @resurrect-hook-post-restore-all`, `cp ~/.tmux/resurrect/assistant-sessions.json
   ~/.tmux/resurrect/assistant-sessions.pre-lease.json`, and save
   `tmux-agent-resume plan --json` beside them.
2. To revert only the policy hook, restore the previous tmux option or restore
   the previous dotfiles revision, then `tmux source-file ~/.config/tmux/tmux.conf`.
   Do not restart tmux as a rollback step.
3. Keep `~/.local/state/tmux-agent-resume/state.json`; it is an audit record.
   Removing it merely makes every saved entry deferred again, never runnable.

The hook, sidecar, lease state, and process ownership are deliberately separate
configuration boundaries. A layout backup cannot become an execution permit.
