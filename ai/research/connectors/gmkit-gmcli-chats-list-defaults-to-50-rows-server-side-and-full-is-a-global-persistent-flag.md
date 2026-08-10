---
title: "gmkit's gmcli chats list caps results at 50 rows server-side by default (a real SQL LIMIT), chats list itself is already sorted newest-first, and --full is a global persistent flag rather than a chats-list-specific one"
date: 2026-08-10
topic: connectors
tags: [gmkit, gmcli, google-messages, cli-contract-verification, cobra, sqlite]
status: draft
sources: [gmkit-store-conversations, gmkit-store-messages, gmkit-cmd-chats, gmkit-cmd-root, gmkit-cmd-messages, gmkit-tags-api]
source_session: cb124ace-f040-4474-85b2-5befa84f1868
---

## CLAIMS
- `gmcli messages list` accepts `--order asc|desc` (default `desc`, i.e. newest-first) and has no offset/pagination-cursor flag — `--limit` is the only bound. [gmkit-cmd-messages][gmkit-store-messages]
- `gmcli chats list` defaults `--limit` to 50 and enforces it as a literal SQL `LIMIT ?` parameter inside `ListConversations` — a caller that never passes `--limit` silently gets at most 50 conversations back, regardless of true archive size. [gmkit-cmd-chats][gmkit-store-conversations]
- `chats list`'s SQL query is already `ORDER BY c.last_message_ts DESC, c.updated_at DESC` — gmcli returns chats newest-first on its own, with no client-side re-sort required to get recency-first output (though a client-side id tie-break is still needed for byte-for-byte determinism gmcli's own two-column sort doesn't guarantee). [gmkit-store-conversations]
- `--full` is registered as a Cobra **persistent** flag on the root command (`root.PersistentFlags().BoolVar(&flags.full, "full", false, "disable truncation in tabular output")`), so it is valid on every subcommand including `chats list`, not something scoped only to `messages list`. [gmkit-cmd-root]
- `chats list` itself only registers `--limit`, `--unread-only`, and `--pinned` as its own local flags — no `--full`-specific override or local re-declaration. [gmkit-cmd-chats]
- The `Conversation` struct's `last_message_time_ms` JSON field (Go: `LastMessageTimeMS int64`) is Unix milliseconds, confirmed by cross-referencing sibling `UpdatedAt`/`updated_at` scanning logic in the same file (`time.Now().UnixMilli()` / `time.UnixMilli(...)`) — the JSON tag name and the underlying SQL column name (`last_message_ts`) differ, but both represent the same ms-epoch value. [gmkit-store-conversations]
- `messages search` requires a positional query argument (`cobra.MinimumNArgs(1)`) and returns a different struct (`[]store.RichHit` via `SearchMessagesRich`) than `messages list`, which returns `store.Message` rows and has no query-term requirement — these are not interchangeable for full-archive enumeration. [gmkit-cmd-messages]
- gmkit is AGPL-3.0 (`AGPL-3.0-or-later` per its own `version` command output and GitHub's `license.spdx_id`). [gmkit-tags-api]
- gmkit has 18 real, numbered release tags as of the check date (`v0.1.0-alpha` through `v0.4.0`), contradicting a "no numbered release tags" characterization — though "beta"/"pre-1.0" independently holds per its own README. [gmkit-tags-api]
- No Cobra flag-tolerance override (`DisableFlagParsing`, `FParseErrWhitelist`, custom `UnknownFlags`) exists anywhere in the codebase — unregistered flags fail Cobra's normal parse-error path; the only reason `--full` succeeds globally is that it is a real registered flag, not because unknown flags are tolerated. [gmkit-cmd-root]

## SOURCES
**gmkit-store-conversations**
URL: https://raw.githubusercontent.com/johnlindquist/gmkit/main/internal/store/conversations.go
Accessed: 2026-08-10
Quote: "LastMessageTimeMS int64 `json:"last_message_time_ms"`" and "ORDER BY c.last_message_ts DESC, c.updated_at DESC LIMIT ?" with "limit := opts.Limit; if limit <= 0 { limit = 50 }"

**gmkit-store-messages**
URL: https://raw.githubusercontent.com/johnlindquist/gmkit/main/internal/store/messages.go
Accessed: 2026-08-10
Quote: "ORDER BY timestamp_ms {ASC|DESC}" (direction driven by the `order` flag, default desc); struct JSON tags confirmed: message_id, conversation_id, source_platform, sender_id, body, timestamp_ms, is_from_me, media_id, mime_type, reactions_json, reply_to_id.

**gmkit-cmd-chats**
URL: https://raw.githubusercontent.com/johnlindquist/gmkit/main/internal/cmd/chats.go
Accessed: 2026-08-10
Quote: "c.Flags().IntVar(&limit, \"limit\", 50, \"max rows\")" in `chatsListCmd()`; no `--full` flag registered anywhere in this file.

**gmkit-cmd-root**
URL: https://raw.githubusercontent.com/johnlindquist/gmkit/main/internal/cmd/root.go
Accessed: 2026-08-10
Quote: "root.PersistentFlags().BoolVar(&flags.full, \"full\", false, \"disable truncation in tabular output\")"; root command sets only `SilenceErrors: true` / `SilenceUsage: true` (output suppression, not flag-validation bypass).

**gmkit-cmd-messages**
URL: https://raw.githubusercontent.com/johnlindquist/gmkit/main/internal/cmd/messages.go
Accessed: 2026-08-10
Quote: "StringVar(&order, \"order\", \"desc\", \"asc or desc\")"; `messages search` has `Args: cobra.MinimumNArgs(1)` and returns `[]store.RichHit` via `SearchMessagesRich`, a different type from `messages list`'s `store.Message`.

**gmkit-tags-api**
URL: https://api.github.com/repos/johnlindquist/gmkit/tags
Accessed: 2026-08-10
Quote: 18 tags returned, newest-first: v0.4.0, v0.3.5, v0.3.4, v0.3.3, v0.3.2, v0.3.1, v0.3.0, v0.2.3, v0.2.2, v0.2.1, v0.2.0, v0.1.8-alpha ... v0.1.0-alpha. `license.spdx_id: "AGPL-3.0"` from the repo API; `internal/cmd/version.go` hardcodes `License: "AGPL-3.0-or-later"`.

## SYNTHESIS
A connector wrapping a small, single-maintainer, beta Go CLI cannot treat its own "verified from source" code comments as durable ground truth without periodically re-checking them — gmkit's contract has several specific, load-bearing defaults that are easy to miss when only skimming the CLI's documented flags on `messages list` (the command most of the wrapper's attention goes to) while treating `chats list` as a simpler, lower-risk enumeration call. In practice `chats list` carries the more dangerous default: a hidden server-side 50-row cap enforced via literal SQL `LIMIT`, invisible to any caller that doesn't pass `--limit` explicitly and easy to miss because it produces no error, just a shorter-than-expected — but still valid-looking, still correctly-shaped — JSON array.

The corollary finding — that `chats list` already returns newest-first server-side — matters for any future client-side re-sort logic: the sort is not rescuing an unordered response, it's adding a determinism guarantee (id tie-break) on top of an already-recency-ordered one. A code comment claiming "no ordering guarantee" for a query that in fact has a hardcoded `ORDER BY` is the kind of claim that reads as verified-from-source but wasn't actually re-checked against the specific command in question — worth flagging as a pattern: "verified from source" comments age out silently if the upstream CLI adds/changes commands and the comment is never re-diffed against the current source.

For any future work against gmkit/gmcli (or structurally similar single-maintainer Cobra CLIs with SQLite-backed local stores): always pass explicit `--limit` on every list-shaped subcommand, never rely on a CLI's default cap matching what the wrapping application's own bounding logic assumes, and treat "global flag reused across a Cobra command tree" as the default hypothesis for any flag documented once at the top level (`--full`, `--json`, `--store`, `--log-level`, `--read-only` here) rather than assuming it's subcommand-scoped.
