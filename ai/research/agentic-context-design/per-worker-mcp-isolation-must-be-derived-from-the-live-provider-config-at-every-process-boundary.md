---
title: "Per-worker MCP isolation must be derived from the live provider config at every process boundary"
date: 2026-07-11
topic: agentic-context-design
tags: [mcp, orchestration, codex, claude, process-lifecycle]
status: draft
sources: [anthropic-cli, anthropic-mcp, local-cli-probes, orchestrator-prior-art]
source_session: unknown
---

## CLAIMS

- Claude Code supports per-invocation MCP configuration, and the installed 2.1.206 CLI accepts `--strict-mcp-config --mcp-config '{"mcpServers":{}}'`. [anthropic-cli] [local-cli-probes]
- Claude Code MCP configuration can exist at local, project, and user scopes. [anthropic-mcp]
- The installed Codex 0.144.1 CLI returns its auth/config-scoped model catalog from `codex debug models` and a top-level JSON array of configured MCP records from `codex mcp list --json`. [local-cli-probes]
- Codex `-c mcp_servers.<name>.enabled=false` disables a configured server; quoted dotted path segments are parsed differently and fail. [local-cli-probes]
- A new provider process, including a headless resume, reloads configuration; a deny snapshot captured for an earlier process does not cover servers added later. [local-cli-probes]
- Live multi-agent orchestrators commonly retain one worker process per tmux window and use explicit wait/idle primitives for lifecycle control. [orchestrator-prior-art]

## SOURCES

**anthropic-cli**
URL: https://docs.anthropic.com/en/docs/claude-code/cli-usage
Accessed: 2026-07-11

**anthropic-mcp**
URL: https://docs.anthropic.com/en/docs/claude-code/mcp
Accessed: 2026-07-11

**local-cli-probes**
URL: local://claude-2.1.206-and-codex-0.144.1-cli-probes
Accessed: 2026-07-11

**orchestrator-prior-art**
URL: ./live-multi-agent-tmux-orchestration-tools-drive-workers-via-mcp-tools-and-detect-idle-from-jsonl-not-screen-scraping.md
Accessed: 2026-07-11

## SYNTHESIS

Default workers should start MCP-minimal, with an explicit inherit escape hatch.
The boundary must be recomputed from the provider's live configuration in the
effective worker directory every time a new process starts. Raw profile or MCP
configuration flags must be rejected while isolation is claimed. Completion
cleanup should park a terminal-idle worker process while preserving durable
session/worktree evidence; age alone is not evidence that destructive reaping is
safe.
