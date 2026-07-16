---
title: "A kanban board whose columns are worker states beats a flat recency list for many-worker oversight, and a WIP limit is the mechanism that bounds a supervisor's cognitive load — the agent-fleet products independently rediscovered both"
date: 2026-07-16
topic: session-ux
tags: [kanban, wip-limits, board-vs-list, overview-surface, supervision-ux, prior-art]
status: draft
sources: [kanban-wikipedia, kanban-university, conductor, vibe-kanban, claude-agent-view]
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation. Skippable. No citations here.
-->

## CLAIMS

- The two primary practices of the Kanban Method are to visualize work and to limit work in progress: "the two primary practices of The Kanban Method are to visualize work and to limit work in progress (WIP)." [kanban-wikipedia]
- Kanban visualizes work items on a board specifically to make progress and process legible start-to-finish: "Work items are visualized to give participants a view of progress and process, from start to finish—usually via a kanban board." [kanban-wikipedia]
- WIP limits give immediate feedback on workflow problems (i.e. a filling column exposes a bottleneck): "The WIP limits for development steps provide development teams immediate feedback on common workflow issues." [kanban-wikipedia]
- Kanban is a pull system: work is started only as capacity frees, not pushed on request — "Work is pulled as capacity permits, rather than work being pushed into the process when requested." [kanban-wikipedia]
- Visualization is framed as the key to transparency and to spotting improvement/bottleneck opportunities: "Visualizing that work and the flow of that work greatly improves transparency" and "A good visualization is the key to effective collaboration and to identify improvement opportunities." [kanban-university]
- Limiting WIP explicitly reduces delay and context-switching: "Limiting the work that is allowed to enter the system is an important key to reducing delay and context switching." [kanban-university]
- Multiple 2025-2026 agent-fleet products independently adopted a kanban board of worker states as their supervision surface: Conductor organizes workspaces by "backlog, in progress, in review, and done"; Vibe Kanban used board columns "To do / In progress / In review / Done." [conductor][vibe-kanban]
- Claude Code's Agent View, while presented as a list, is grouped by state (Pinned → Ready for review → Needs input → Working → Completed) — i.e. it is a board-by-grouping rather than a recency list. [claude-agent-view]

## SOURCES

**kanban-wikipedia**
URL: https://en.wikipedia.org/wiki/Kanban_(development)
Accessed: 2026-07-16
Quote: "the two primary practices of The Kanban Method are to visualize work and to limit work in progress (WIP)." / "Work items are visualized to give participants a view of progress and process, from start to finish—usually via a kanban board." / "The WIP limits for development steps provide development teams immediate feedback on common workflow issues." / "Work is pulled as capacity permits, rather than work being pushed into the process when requested."

**kanban-university**
URL: https://kanban.university/kanban-guide/
Accessed: 2026-07-16
Quote: "Visualizing that work and the flow of that work greatly improves transparency." / "A good visualization is the key to effective collaboration and to identify improvement opportunities." / "Limiting the work that is allowed to enter the system is an important key to reducing delay and context switching."

**conductor**
URL: https://conductor.build/changelog
Accessed: 2026-07-16
Quote: "Workspaces are now organized by status: backlog, in progress, in review, and done."

**vibe-kanban**
URL: https://github.com/BloopAI/vibe-kanban
Accessed: 2026-07-16
Quote: board columns "To do … In progress … In review … Done".

**claude-agent-view**
URL: https://code.claude.com/docs/en/agent-view
Accessed: 2026-07-16
Quote: group order "Pinned / Ready for review / Needs input / Working / Completed".

## SYNTHESIS

Kanban answers two of the design questions directly: the overview surface should be a **board whose columns are worker states**, not a flat recency list; and there should be a **WIP limit** that bounds how many workers the supervisor is on the hook for at once.

**Why board beats list.** The canonical Kanban claim is that visualizing work on a board "greatly improves transparency" and that WIP limits give "immediate feedback on common workflow issues." The mechanism is that you read the *columns*, not the *cards*: a column that piles up is a bottleneck that announces itself. For a fleet supervisor "checking in — what do we have now?", a board answers in one glance: how many need me (needs-input + ready-for-review columns), how many are working, how many are done-and-clearable. A flat list forces the supervisor to scan and classify every row themselves; a state board pre-classifies. This is exactly why Conductor, Vibe Kanban, and (via state-grouping) Claude Agent View all landed on a status board independently of the kanban literature — convergent evolution toward the same answer.

**The columns that recur** across the agent products map onto a supervision-appropriate board:
- **Needs you** — split into *needs-input* (agent asked a question / permission) and *ready-for-review* (finished, produced a PR/artifact). These are the two attention columns; they belong left/top and should carry the WIP-limit and the push notifications.
- **Working** — in progress; ambient, not attention-demanding.
- **Idle / queued** — ready for a prompt, or waiting to start (the pull buffer).
- **Done / failed** — terminal; cleared by the supervisor. (Claude collapses finished+failed+stopped into one "Completed" group; we likely want failed visible separately since it's actionable.)

**WIP limit = the supervisor's span-of-control bound.** Kanban's WIP limit and ATC's sector capacity are the same idea from two fields: cap the concurrent load and *pull* new work only as attention frees, rather than *pushing* (spawning agents on demand and letting the review queue overflow). For Tim's growing fleet this is the concrete lever against overload — not "show more rows faster" but "bound the needs-you column and make starting a new worker a pull against freed review capacity." Notably, none of the current products enforce a hard WIP limit on agents (Cursor merely *tracks up to 8*); this is a place our design can be more principled than the prior art, because Tim's fleet is already past the size where eyeballing works.

**Board is a *view*, not a storage model.** Practically, in tmux+kitty+Plasma this means the board is a rendered overview (a popup/status surface) computed from per-window hook-derived state — the windows still live in tmux; the board is the glanceable projection over them, with columns = states and WIP limit applied to the attention columns. That keeps Tim in the terminal (his hard constraint) while giving him the board-shaped oversight the dedicated products proved out.
