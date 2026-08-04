---
name: claude-code-subagent-hooks
source_session: 949640aa-9865-4be7-90af-d11d9951e475
accessed: 2026-08-04
---

# Claude Code Hook Events for Subagents

Research into how hooks fire across parent and subagent sessions, including SubagentStart/Stop lifecycle events and session context isolation.

## Key findings

### Hook propagation

- **All hooks run in subagents**: Hooks from settings files, plugins, and managed policy settings fire inside subagents. Tool events (`PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`, `PermissionDenied`) execute in both parent and subagent contexts.
- **Parent doesn't see subagent events directly**: The parent session does NOT receive hook events fired by the subagent's tool calls. Each context is isolated.
- **Session context**: Subagent hook input includes `agent_id` (unique subagent identifier) and `agent_type` (e.g., "Explore", "Plan", or custom name), plus the standard `session_id` field that identifies the parent session.

### SubagentStart and SubagentStop

- **SubagentStart**: Fires when a subagent is spawned. Matcher filters by agent type.
- **SubagentStop**: Fires when a subagent finishes. Matcher filters by agent type (same values as SubagentStart: `"general-purpose"`, `"Explore"`, `"Plan"`, or custom agent names).
- **SubagentStop can block**: With exit code 2 or `decision: "block"`, a SubagentStop hook prevents the subagent from stopping and forces it to continue working.

### Stop vs SubagentStop conversion

- For subagent frontmatter, `Stop` hooks are **automatically converted** to `SubagentStop` hooks since `SubagentStop` is the event that fires when a subagent completes.
- Subagents don't have a `Stop` event; they use `SubagentStop` instead.

### Hook input fields in subagents

Subagent tool calls receive these additional fields in the hook JSON input:
- `agent_id`: unique identifier for the subagent instance
- `agent_type`: agent name or plugin-scoped identifier (e.g., "Explore", "code-improver", "plugin-name:reviewer")

The `session_id` field still identifies the parent session, not a separate subagent session ID.

### Fan-out (parent spawns N subagents)

From the hooks perspective:
- **Parent session**: Sees `SubagentStart` when each subagent launches, and `SubagentStop` when each finishes (if hooks are configured).
- **Subagent sessions**: Each subagent's tool calls fire `PreToolUse`, `PostToolUse`, etc. independently. These hooks receive `agent_id` and `agent_type` in their input, but the parent doesn't observe them.
- **Ownership**: Each subagent's work and its hook events "belong" to that subagent's execution context. The parent can't intercept or see the subagent's tool-call hooks; it only observes the subagent lifecycle (start/stop).

### Web research in a fan-out

If a parent spawns N subagents that each do web research:
- The parent's `SubagentStart` hook fires once per subagent.
- Each subagent's `PreToolUse` (for web fetch/search) fires in that subagent's hook context, not the parent's.
- The parent does NOT see the subagent's `PreToolUse` / `PostToolUse` events unless explicitly configured at the parent level to observe them (which it doesn't by default).
- The parent only observes `SubagentStart` and `SubagentStop` events for the research work.

## Sources

- [Automate actions with hooks — Claude Code Docs](https://code.claude.com/docs/en/hooks-guide) — hook lifecycle, SubagentStart/Stop events, subagent hook propagation
- [Hooks reference — Claude Code Docs](https://code.claude.com/docs/en/hooks) — complete event schemas, exit codes, JSON output formats, subagent hook behavior
- [Create custom subagents — Claude Code Docs](https://code.claude.com/docs/en/sub-agents) — subagent context isolation, what loads at startup
