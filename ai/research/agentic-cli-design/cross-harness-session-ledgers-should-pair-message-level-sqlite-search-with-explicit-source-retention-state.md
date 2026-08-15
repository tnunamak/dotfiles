---
title: "Cross-harness session ledgers should pair message-level SQLite search with explicit source-retention state"
date: 2026-08-11
topic: agentic-cli-design
tags: [cli, agent-sessions, sqlite, fts5, retention, provenance]
status: draft
sources: [codeburn, codeburn-releases, sessions, agent-sessions, copilot-cli, hermes-agent, git-status, github-cli]
source_session: unknown
---

## CLAIMS

- CodeBurn reads local agent-session files and exposes the same usage data through terminal, desktop, web, and menu-bar surfaces. [codeburn]
- CodeBurn added durable daily aggregation for session logs that have been deleted, and its terminal output reports how much history came from expired logs. [codeburn-releases]
- `nicknisi/sessions` indexes individual messages in SQLite FTS5, builds the index on first use, and refreshes changed sessions by file modification time. [sessions]
- Agent Sessions provides local-only cross-harness search and exact resume commands; a release repaired resume and project filtering after working-directory data was omitted. [agent-sessions]
- GitHub Copilot CLI keeps raw session state separately from a SQLite cross-session search index; its index can be rebuilt, while deleting session state removes resume history. [copilot-cli]
- Hermes Agent uses SQLite FTS5 without an LLM or summaries and returns the matching message with a bounded context window plus session-start and session-end bookends. [hermes-agent]
- Git guarantees that `git status --porcelain=v1` will not change incompatibly across versions or user configuration. [git-status]
- GitHub CLI uses line-oriented human output by default and offers explicit JSON fields, `--jq`, and templates for automation. [github-cli]

## SOURCES

**codeburn**
URL: https://github.com/getagentseal/codeburn
Accessed: 2026-08-11

**codeburn-releases**
URL: https://github.com/getagentseal/codeburn/releases
Accessed: 2026-08-11

**sessions**
URL: https://github.com/nicknisi/sessions
Accessed: 2026-08-11

**agent-sessions**
URL: https://github.com/jazzyalex/agent-sessions
Accessed: 2026-08-11

**copilot-cli**
URL: https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-config-dir-reference
Accessed: 2026-08-11

**hermes-agent**
URL: https://github.com/NousResearch/hermes-agent/blob/main/website/docs/user-guide/sessions.md
Accessed: 2026-08-11

**git-status**
URL: https://git-scm.com/docs/git-status
Accessed: 2026-08-11

**github-cli**
URL: https://cli.github.com/manual/gh_help_formatting
Accessed: 2026-08-11

## SYNTHESIS

The strongest V1 is a fast CLI over a message-level SQLite FTS5 store. It should not start as a dashboard, an AI-memory system, or a second tool beside an existing transcript reader. Ranked search and exhaustive grep are different jobs and should remain separate. A search result should include the exact matching message, a small context window, the beginning and end of the session, and a deterministic next action such as `show` or `resume`.

Deleted source logs change the architecture. A database that preserves normalized conversation text after source deletion is durable product data, not a disposable cache. It must record what it retained and what it cannot reconstruct. Source presence, archive verification, snapshot policy, and transcript completeness are separate facts. An archive locator is not proof of a backup until its size and hash have been verified.

The default durable snapshot should keep user and assistant text for search and resumption, but omit thinking, system prompts, and raw tool arguments or results. This retains the useful conversation while reducing the secret and storage cost of copying full traces. Raw logs remain the highest-fidelity evidence while available. Search results must label whether their content came from verified raw data, a retained normalized snapshot, or metadata only.

The CLI should preserve the existing `convo` name and commands. Human output should be useful without configuration. Machine output needs a versioned schema, data-only stdout, diagnostic stderr, and stable exit codes. Resume should print the command by default and execute only with an explicit flag.

CodeBurn is useful evidence for durable aggregation and consistent multi-surface calculations. Its growth into spend optimization, guards, desktop, menu-bar, web, and MCP features is also a scope warning. The session ledger should prove deterministic indexing, search, retention, and resume before it adds summaries, a resident daemon, or another interface.
