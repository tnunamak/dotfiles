---
title: "For a tmux-native agent fleet, tmux-agent-status is the strongest build reference (hook-derived states, priority ordering) and Omnara owns mobile push, but no single product ships hook-states + PR-keyed review + needs-review/needs-input split + push-to-phone together"
date: 2026-07-16
topic: session-ux
tags: [buy-vs-build, tmux, mobile, notifications, hooks, multi-agent]
status: draft
sources: [tmux-agent-status, omnara, cursor-cloud, codex-cloud, claude-agent-view, claude-desktop-dispatch, claude-squad]
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation. Skippable. No citations here.
-->

## CLAIMS

- tmux-agent-status derives Claude Code and Codex state from agent hooks, not screen-scraping: "Claude Code state is tracked entirely through hooks, so the plugin gets precise working/done transitions directly from the agent" and "Codex state is also hook-based." [tmux-agent-status]
- tmux-agent-status keeps a backgrounded session marked `working` by reading the Stop hook payload's `background_tasks` array, so backgrounded work does not show a premature completion checkmark. [tmux-agent-status]
- tmux-agent-status models five states — working, done, wait (timed wait), parked (deferred), ask (requires user input) — and its "agents" view sorts by priority `ask, done, working, wait, parked`; its inbox is ordered by session name then tmux window order. [tmux-agent-status]
- tmux-agent-status notifies by completion sound only (options: chime, bell, fanfare, frog, speech, none) and has no OS-desktop, push, or mobile notification and no native mobile client; it supports SSH remote tmux monitoring only. [tmux-agent-status]
- tmux-agent-status has no explicit error/failed state and no needs-review state distinct from needs-input (ask). [tmux-agent-status]
- Omnara positions itself as "the first command center for AI agents: terminal, web, and mobile" and ships native iOS and Android apps plus a web dashboard. [omnara]
- Omnara's notification service supports Push, Email, and SMS, and its documented human-in-the-loop trigger is real-time notification when an agent needs input, hits an error, or completes a critical phase. [omnara]
- Omnara detects agent state partly by parsing the Claude session files under `~/.claude/projects` and terminal output in real time (streamed via SSE), rather than purely from hooks; its exact state-label enum and list ordering are not documented on the pages fetched. [omnara]
- Cursor's cloud/background agents ship a native iOS app that sends a push notification when an agent finishes a turn, let you track up to eight agents at once, list agents "newest first", and notify on completion via Slack. [cursor-cloud]
- OpenAI Codex cloud exposes a "Needs input" status, orders its task list by recency (grouped Today / Yesterday / dated), sends web notifications via push/email/SMS, and surfaces task-done notifications inside the ChatGPT mobile app. [codex-cloud]
- Claude Code's own mobile push path is the Claude desktop app plus Dispatch: the desktop app sends an OS notification when a Code session finishes and you aren't viewing it, and Dispatch sends a phone push when a session finishes or needs approval (Pro/Max). [claude-desktop-dispatch]
- Mobile-push products consistently fire on the same two supervision triggers: needs-input/needs-approval, and turn-complete/finish/error. [omnara][cursor-cloud][codex-cloud][claude-desktop-dispatch]

## SOURCES

**tmux-agent-status**
URL: https://raw.githubusercontent.com/samleeney/tmux-agent-status/main/README.md
Accessed: 2026-07-16
Quote: "Claude Code state is tracked entirely through hooks, so the plugin gets precise working/done transitions directly from the agent." / "Codex state is also hook-based." / "Agents is a flat list of every agent pane (any status) sorted by priority — ask, done, working, wait, parked" / notification options "chime (default), bell, fanfare, frog, speech, none".

**omnara**
URL: https://github.com/omnara-ai/omnara (README) ; https://apps.apple.com/app/id6748426727 ; YC launch page
Accessed: 2026-07-16
Quote: "the first command center for AI agents: terminal, web, and mobile" / architecture line "🔔 Notification Service Push/Email/SMS" / "📱 iOS App", "🤖 Android App", "🌐 Web Dashboard" / "Get real-time push notifications when agents need your input." Note: state enum and ordering NOT documented on fetched pages (partially unconfirmed); detection parses `~/.claude/projects` + terminal output via SSE.

**cursor-cloud**
URL: https://cursor.com/docs/cloud-agent/web-and-mobile ; https://cursor.com/docs/integrations/slack ; https://cursor.com/docs/cloud-agent/api/endpoints
Accessed: 2026-07-16
Quote: "Get a push notification when an agent finishes a turn, and track up to eight agents at once." / "List agents for the authenticated user, newest first." / "When Cloud Agent completes, you get a notification in Slack".

**codex-cloud**
URL: https://learn.chatgpt.com/docs/cloud ; https://learn.chatgpt.com/docs/notifications
Accessed: 2026-07-16
Quote: task terminology "and a Needs input status"; task list grouped by "Today," "Yesterday," dated; web notifications "push, email, or SMS"; ChatGPT mobile app gives "notifications pings when the chat is done."

**claude-desktop-dispatch**
URL: https://code.claude.com/docs/en/desktop
Accessed: 2026-07-16
Quote: "The desktop app sends an OS notification when a Code session finishes a task and you aren't currently viewing that session." / Dispatch: "You get a push notification on your phone when it finishes or needs your approval."

**claude-squad**
URL: https://github.com/smtg-ai/claude-squad
Accessed: 2026-07-16
Quote: repo-wide grep found no push/sound/desktop notification; detection is 500ms tmux pane-content diffing (screen-scraping), contrast with tmux-agent-status hooks.

## SYNTHESIS

**Buy-vs-build verdict: adapt tmux-agent-status as the base; add the two things it lacks (a needs-review/error split and a phone-push channel) rather than build a bespoke roster from scratch.** It already does the hard, correct thing — deriving state from Claude/Codex *hooks* instead of pane-diffing — which is exactly the design conclusion the fleet-console research and this dotfiles repo's own prior notes (`agent-terminal-fleets-need-explicit-task-metadata...`) both point at. Its `ask > done > working > wait > parked` priority ordering, its `park`/`wait` triage states, and its correct handling of backgrounded work (reading the Stop hook's `background_tasks`) are non-obvious details that took the author real work and match our needs. Rebuilding all of that would be pure duplication.

The two concrete gaps to close on top of it:
1. **No error/failed state and no needs-review distinct from needs-input.** The richer products (Claude Agent View, Crystal, Vibe Kanban, Devin) all carry a needs-review state, usually PR-keyed. For our fleet this is the highest-value addition: distinguish "agent asked you a question" (ask) from "agent finished and produced a reviewable artifact/PR" (review), and add an explicit failed state.
2. **Sound-only notification, no phone.** This is the axis Omnara owns. Tim supervises episodically and from mobile (Termius over SSH), so a push-on-`ask`/push-on-review channel matters. Omnara is the reference for *what* to push (needs-input, error, complete) and *where* (native iOS/Android + web), and its triggers match Cursor, Codex, and Claude Dispatch — the whole wave pushes on the same two events (needs-you, and done/error).

Omnara is a reference, not a base to adopt: it parses `~/.claude/projects` session files and terminal output (SSE) rather than pure hooks, its state enum and ordering are undocumented, and it's a separate cloud product rather than a tmux-native plugin. The winning combination that **no single product ships** is: tmux-agent-status's hook-derived states + a PR-keyed "ready-for-review" rank (Claude/Devin/Conductor) + the needs-review vs needs-input split (Crystal/Vibe Kanban) + push-to-phone on the needs-you events (Omnara/Cursor/Codex/Dispatch). That gap is precisely the bespoke surface worth building — and it's small, because tmux-agent-status supplies the plumbing (hook collectors, status files, priority list) that the push channel and the review-state split bolt onto.

A note on fleet caps as prior art: Cursor caps at **8 agents** tracked at once and Codex/Claude Agent View use ambient counters ("← 2 agents"). Tim's fleet is ~13 agent windows and growing — past the point where any of these products expect you to eyeball a flat list, which reinforces that we need grouping + a bounded "needs-you" view, not a longer list.
