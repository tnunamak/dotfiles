# Claude Code: Rewinding Past Compaction

## The Problem

When Claude Code auto-compacts (at ~85% context usage), it creates a new root node
with `parentUuid: null` in the JSONL session file. The `/rewind` UI (Esc+Esc) follows
`parentUuid` links backward, so it can never reach messages from before compaction --
they're a disconnected tree.

The full pre-compaction conversation is intact in the JSONL file. It's a UI limitation,
not data loss.

**Tracked bugs:**
- https://github.com/anthropics/claude-code/issues/24471 (rewind history lost after compaction)
- https://github.com/anthropics/claude-code/issues/27242 (no UI to access preserved-but-hidden data)
- https://github.com/anthropics/claude-code/issues/22526 (corrupt parentUuid references)

## JSONL Structure

Sessions live at `~/.claude/projects/<encoded-cwd>/<session-id>.jsonl`.

Each line is a JSON object with `uuid`, `parentUuid`, `type` (user/assistant/system), and `message`.
The compaction boundary has:
- `parentUuid: null` (disconnects the tree)
- `logicalParentUuid` pointing to the last pre-compaction message
- `compactMetadata` with trigger type and pre-compaction token count
- Message subtype `compact_boundary`

## Recovery Options

### Option 1: Recall plugin (best for continuing work)

https://github.com/FlineDev/Recall

Reads the raw JSONL and produces a ~15K token structured transcript of the full
conversation (every user message verbatim, assistant responses, tool call summaries).
Inject into a new session:

```
/recall:session <session-id>
```

Not a true rewind -- it's a new session with the old conversation as rich context.
Far more detail than the default compaction summary (~15K tokens vs ~3.5K).

### Option 2: Patch the JSONL (reconnect the tree)

Back up first:
```bash
cp session.jsonl session.jsonl.bak
```

Find the compact_boundary line (grep for `compact_boundary`), read its
`logicalParentUuid` value, then change `parentUuid` from `null` to that value.
This reconnects the pre-compaction tree so `/rewind` can traverse it.

Undocumented, may break things. Test on a copy.

### Option 3: Post-compaction hooks (prevention)

Add to Claude Code settings to auto-inject context after compaction:
```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "compact",
      "command": "cat path/to/context-recovery.md"
    }]
  }
}
```

### Option 4: Pre-compaction backups (prevention)

Back up JSONL files at token thresholds. Restore + `claude --resume <id>` to
get back exact state. The claudefast backup system automates this (every 10K
tokens starting at 50K used).

## Best Practices

- Manual `/compact <focus>` at ~70% context, before auto-compact triggers
- Use `CLAUDE.md` and memory files for anything that must survive compaction
- Fork sessions at natural breakpoints: `claude --continue --fork-session`
- Install Recall as a safety net for long sessions
