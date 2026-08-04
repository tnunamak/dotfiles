---
title: "Claude Code hook events expose distinct input schemas and blocking contracts, with Stop/PreToolUse able to block and JSON parsed only on exit 0"
date: 2026-08-04
topic: agentic-context-design
tags: [claude-code, hooks, schema, stop-hook, blocking]
status: draft
sources: [cc-hooks-ref, cc-hooks-guide]
source_session: fd141154-b7f8-4f29-9af8-98cb590a4340
---

# Claude Code Hooks Schema Reference (Aug 2026)

**Source**: https://code.claude.com/docs/en/hooks.md and https://code.claude.com/docs/en/hooks-guide.md  
**Verified**: 2026-08-04  
**Source Session**: fd141154-b7f8-4f29-9af8-98cb590a4340

## PostToolUse Hook

### Stdin JSON Schema

```json
{
  "session_id": "string",
  "prompt_id": "string (UUID)",
  "transcript_path": "string",
  "cwd": "string",
  "permission_mode": "default|plan|acceptEdits|auto|dontAsk|bypassPermissions",
  "hook_event_name": "PostToolUse",
  "tool_name": "string",
  "tool_use_id": "string",
  "tool_input": {
    // Tool-specific input object; for Write/Edit tools:
    // { "file_path": "...", "content": "..." } or { "file_path": "...", "new_string": "..." }
  },
  "tool_response": {
    // Tool result - structure depends on tool type
  },
  "agent_id": "string (optional, only in subagents)",
  "agent_type": "string (optional, for subagents or --agent sessions)"
}
```

**Critical field names:**
- Tool identification: `tool_name` (string), `tool_use_id` (UUID string)
- Tool invocation: `tool_input` (object, tool-specific structure)
- Tool result: `tool_response` (object, tool-specific structure)

For **Write** tool: `tool_input.file_path`, `tool_input.content`  
For **Edit** tool: `tool_input.file_path`, `tool_input.new_string`

### Matcher Syntax

Filters by **tool name only** (does not support event filtering). Formats:
- `"*"` or omitted: all tools
- Exact: `"Edit"`, `"Write"`, `"Bash"`
- Multiple: `"Edit|Write"` (regex `|` OR) or `"Edit, Write"` (comma-separated)
- Regex: `"^Notebook"`, `"mcp__memory__.*"` (any regex with non-alphanumeric chars)

### Blocking & Exit Code Semantics

**PostToolUse cannot block** the tool call (it already executed). Exit codes:

| Code | Behavior |
|------|----------|
| 0 | Success. Parse stdout for JSON output control (see below) |
| 2 | Non-blocking error. Stderr text shown to Claude as feedback; tool result proceeds |
| Other | Non-blocking error. First line of stderr shown in transcript |

### Output Control: JSON Stdout Protocol

PostToolUse can modify what Claude sees of the tool result via JSON stdout:

```json
{
  "decision": "block",
  "reason": "File contains credentials and should not be displayed",
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "updatedToolOutput": {
      // Replaces tool_response with this (for redaction/transformation)
    },
    "additionalContext": "Context string for Claude (injected as system reminder)"
  }
}
```

**Decision values:**
- Omit `decision` or exit 0 with no JSON: allow tool result to proceed unchanged
- `"block"`: prevents Claude from seeing the result (rare; tool already ran)

**Output fields:**
- `updatedToolOutput`: replaces `tool_response` before Claude sees it (redaction, transformation)
- `additionalContext`: injected as system reminder alongside result (surface warnings without blocking)

### Use Cases

- Redact secrets from file read/write results
- Validate tool output before Claude processes it
- Inject warnings or context (non-blocking)

---

## Stop Hook

### Stdin JSON Schema

Stop fires at **turn completion** and receives comprehensive turn data:

```json
{
  "session_id": "string",
  "prompt_id": "string (UUID)",
  "transcript_path": "string",
  "cwd": "string",
  "permission_mode": "default|plan|acceptEdits|auto|dontAsk|bypassPermissions",
  "effort": {
    "level": "low|medium|high|xhigh|max"
  },
  "hook_event_name": "Stop",
  "last_assistant_message": "string (full assistant response text)",
  "last_assistant_message_tokens": number,
  "turn_number": number,
  "tools_used": [
    {
      "tool_name": "string",
      "tool_use_id": "string",
      "input": { /* tool input */ },
      "output": { /* tool output */ }
    }
  ],
  "agent_id": "string (optional, only in subagents)",
  "agent_type": "string (optional, for subagents or --agent sessions)"
}
```

**Critical for AI-ism detection:**
- `last_assistant_message`: full assistant response text (can inspect for AI patterns)
- `last_assistant_message_tokens`: token count of that message
- `turn_number`: index of this turn

### Matcher Support

**Stop does not support matchers.** The hook fires on every turn completion.

### Blocking & Exit Code Semantics

Stop **can block** the turn end (preventing Claude from stopping). Exit codes:

| Code | Behavior |
|------|----------|
| 0 | Success. Claude receives response; turn ends |
| 2 | **Blocking**. Prevents turn end; conversation continues with stderr shown to Claude as feedback |
| Other | Non-blocking error. First line of stderr shown in transcript |

### Output Control: JSON Stdout Protocol

Stop can prevent turn completion or inject context:

```json
{
  "decision": "block",
  "reason": "Test suite failed. Please fix the tests before responding.",
  "hookSpecificOutput": {
    "hookEventName": "Stop",
    "additionalContext": "The build succeeded. CI is now running tests in the background."
  }
}
```

**Decision values:**
- Omit `decision` or exit 0: turn ends normally
- `"block"`: prevents turn end; conversation continues (gate turn completion on conditions)

**Output fields:**
- `reason`: problem statement shown to Claude (frames as blocker)
- `additionalContext`: state update shown to Claude (non-blocking context, no problem framing)

### Use Cases

- Enforce turn-level policies (e.g., "don't respond until tests pass")
- Detect and reject AI-isms in assistant output before returning to user
- Inject turn-level state updates (build results, CI status, etc.)

---

## Environment Variables Available to Hook Scripts

Hooks run with these environment variables set:

- **`$CLAUDE_PROJECT_DIR`**: Project root (also available as `${CLAUDE_PROJECT_DIR}` in command config)
- **`$CLAUDE_EFFORT`**: Active effort level (`"low"`, `"medium"`, `"high"`, `"xhigh"`, `"max"`)
- **`$CLAUDE_CODE_REMOTE`**: Set to `"true"` in remote web environments (not set in local CLI)
- **`$CLAUDE_CODE_BRIDGE_SESSION_ID`**: Remote Control session ID (if active remote connection, v2.1.199+)

**Plugin-specific:**
- **`$CLAUDE_PLUGIN_OPTION_<KEY>`**: Plugin configuration options as env vars

**Note:** Claude Code removes `OTEL_*` exporter variables from all subprocesses (including hooks).

---

## Key Differences: PostToolUse vs Stop

| Aspect | PostToolUse | Stop |
|--------|-------------|------|
| **Timing** | After single tool call completes | After Claude finishes responding (turn end) |
| **Can block?** | No | Yes |
| **Receives message content?** | No | **Yes** (`last_assistant_message`) |
| **Matcher support?** | Yes (by tool name) | No (always fires) |
| **Input modification?** | Yes (`updatedToolOutput`) | No |
| **Stdin input** | Current tool call only | Entire turn summary + last assistant message |

---

## Implementation Notes

1. **Input format**: All hook input is JSON on stdin; parse robustly.
2. **Stdin vs args**: Environment variables are in env; JSON payload is on stdin (not command args).
3. **PostToolUse redaction**: Use `updatedToolOutput` to redact sensitive tool results before Claude sees them.
4. **Stop for AI-ism detection**: Stop receives the full `last_assistant_message`, making it suitable for detecting AI writing patterns after Claude generates but before returning to the user.
5. **Non-blocking feedback**: PostToolUse can inject `additionalContext` without blocking; Stop `reason` blocks (use `additionalContext` for non-blocking state updates in Stop).

