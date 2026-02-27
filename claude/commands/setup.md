---
description: Help me set up a Claude Code customization based on my goal
---

I want to set up a Claude Code customization. My goal: $ARGUMENTS

Help me choose the right feature and set it up.

## Your process

1. Ask clarifying questions about my goal
2. Recommend the best feature from the reference below
3. If implementing something complex or if the reference below seems incomplete, use WebFetch to check https://docs.anthropic.com/en/docs/claude-code for current documentation
4. Explain why that's the right choice
5. Walk me through creating it step by step
6. Test it works

## Quick decision guide

| Want to... | Use |
|------------|-----|
| Give Claude project context (build commands, conventions) | `CLAUDE.md` |
| Run a prompt repeatedly (review, deploy, fix issue) | **Slash Command** |
| Connect external tools (GitHub, Postgres, Sentry) | **MCP Server** |
| Auto-run code on every edit (format, lint, validate) | **Hook** (`PostToolUse`) |
| Block dangerous operations (protect .env, prevent rm -rf) | **Hook** (`PreToolUse`) |
| Give Claude a complex multi-step capability with scripts | **Skill** |
| Delegate specialized tasks (code review, security audit) | **Subagent** |
| Control what tools Claude can use | **Permissions** |
| Share a bundle of commands/hooks/agents | **Plugin** |

**Rule of thumb:**
- User invokes it → Slash Command
- Claude decides when → Skill or Subagent
- Always runs automatically → Hook
- External service → MCP Server
- Just context/instructions → CLAUDE.md

## Feature reference

> Last updated: December 2024. If this is more than a few months old, prefer checking the official docs.

### CLAUDE.md Files
Memory files loaded at startup.

Locations:
- `~/.claude/CLAUDE.md` - Personal global (all projects)
- `./CLAUDE.md` or `.claude/CLAUDE.md` - Team project (in git)
- `./CLAUDE.local.md` - Personal project (gitignored)

Features: `@file` imports, `#` quick memory addition, `/memory` editor

### Slash Commands
User-invoked prompts as Markdown files.

Locations:
- `.claude/commands/name.md` → `/name` (project)
- `~/.claude/commands/name.md` → `/name` (global)

Frontmatter options:
```yaml
---
description: Brief description shown in /help
argument-hint: "[arg1] [arg2]"
allowed-tools: Bash(git:*), Read, Write
model: claude-3-5-haiku-20241022
---
```

Features:
- $ARGUMENTS - all args, $1/$2 - individual args
- Exclamation + backticks - execute bash and include output
- @file - include file contents

### MCP Servers
External integrations for tools, databases, APIs.

Install:
```bash
claude mcp add --transport http <name> <url>
claude mcp add --transport stdio <name> -- command args
```

Scopes:
- User: `~/.claude.json` (all projects)
- Project: `.mcp.json` (in git, team-shared)
- Local: project-specific in `~/.claude.json`

Manage: `/mcp` command

### Hooks
Automatic shell commands at lifecycle events.

Events:
- `PreToolUse` - Before tool runs (block/approve)
- `PostToolUse` - After tool completes (format/validate)
- `UserPromptSubmit` - Before processing prompt
- `SessionStart`/`SessionEnd` - Setup/cleanup
- `Notification` - Custom alerts
- `Stop` - When Claude finishes responding

Config in `~/.claude/settings.json` or `.claude/settings.json`:
```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "npx prettier --write \"$FILE_PATH\""
      }]
    }]
  }
}
```

Hook input (stdin JSON): `session_id`, `tool_name`, `tool_input`, `cwd`
Exit codes: 0=success, 2=block with error message

### Skills
Auto-discovered capabilities Claude uses autonomously.

Locations:
- `.claude/skills/skill-name/SKILL.md` (project)
- `~/.claude/skills/skill-name/SKILL.md` (global)

Structure:
```yaml
---
name: skill-name
description: What it does and when to use it
allowed-tools: Read, Grep, Glob
---
Instructions for Claude...
```

Can include supporting files (scripts, templates, docs).

### Subagents
Specialized AI with separate context and tools.

Locations:
- `.claude/agents/name.md` (project)
- `~/.claude/agents/name.md` (global)

Structure:
```yaml
---
name: code-reviewer
description: Expert code reviewer. Use after code changes.
tools: Read, Grep, Glob, Bash
model: sonnet
---
System prompt for the subagent...
```

Fields: `name`, `description`, `tools`, `model` (sonnet/opus/haiku), `permissionMode`, `skills`

Built-in: `Explore` (fast search), `Plan` (architecture), `General` (multi-step)

### Settings & Permissions
Locations:
- `~/.claude/settings.json` - User global
- `.claude/settings.json` - Team shared
- `.claude/settings.local.json` - Personal project (gitignored)

Permission rules:
```json
{
  "permissions": {
    "allow": ["Bash(npm test:*)"],
    "deny": ["Read(.env)"],
    "defaultMode": "default"
  }
}
```

Modes: `default`, `acceptEdits`, `plan`, `bypassPermissions`

Manage: `/permissions` command

### Plugins
Bundled extensions with commands, agents, hooks, MCP servers.

Structure:
```
my-plugin/
├── plugin.json
├── commands/
├── agents/
├── hooks/hooks.json
└── servers/
```

Manage: `/plugin` command
