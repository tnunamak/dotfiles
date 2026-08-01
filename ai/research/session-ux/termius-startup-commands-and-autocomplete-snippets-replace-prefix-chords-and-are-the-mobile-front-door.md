---
title: "Termius per-host startup commands auto-run an attach on every connect and its docs already endorse tmux for cross-device continuity; autocomplete snippets replace prefix-chord navigation — so the mobile front door is configured in Termius, not fought against it"
date: 2026-07-16
topic: session-ux
tags: [termius, snippets, startup-command, autocomplete, mobile, tmux, prefix-chords]
status: draft
sources: [termius-snippets, termius-agents-blog, termius-ios-bg, termius-mosh-forum]
source_session: unknown
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation/conclusions. Skippable. No citations here.
-->

## CLAIMS

- Termius supports a per-host **Startup Command** and startup **snippets** that run automatically every time you connect to that host; Termius's own docs give `tmux attach -t <session_name>` as the example, explicitly "to restore your previous session automatically" and "continue your AI agent session when switching between desktop and mobile." [termius-snippets][termius-agents-blog]
- A raw Startup Command can chain shell, e.g. `cd ~/my-project/src && claude`, so you connect already inside the project with the agent running. [termius-snippets]
- Termius **Autocomplete** (enable in Settings → Terminal) suggests saved snippets as you type, matching both snippet name and content; it also powers Broadcast Input (type a snippet title to send to all Split View panes). [termius-snippets]
- Snippets are cloud-synced labeled scripts stored in Vaults, organizable into packages, and runnable on multiple hosts at once (running from the Snippets screen creates new connections to selected hosts). [termius-snippets]
- Termius does not yet support variables in the snippet editor; the workaround is `export` in a startup snippet or setting env vars on the Host Edit screen. [termius-snippets]
- Termius Split View lets multiple terminals share the screen and Broadcast Input sends one command to all active Split View panes. [termius-snippets]
- On iOS/iPadOS, Termius background activity stops in ~20–30s; enabling Location tracking makes background interruption "less likely" (not prevented), and iPad Split View keeps Termius visible to avoid backgrounding. [termius-ios-bg]
- Termius does not support mosh (a long-standing, unfulfilled feature request on Termius's own support forum). [termius-mosh-forum]

## SOURCES

**termius-snippets**
URL: https://docs.termius.com/terminal/snippets
Accessed: 2026-07-16
Quote: "A startup snippet is a command that runs automatically every time you connect to a host. Use it to open a directory, activate a virtual environment, run checks, or attach to an existing tmux session." / "if you use tmux, add a Startup Command tmux attach -t <session_name> to restore your previous session automatically. This lets you continue your AI agent session when switching between desktop and mobile." / "When Autocomplete is enabled, Termius suggests snippets as you type. It checks both the snippet name and the snippet content." / "Termius does not support variables in the snippet editor yet."

**termius-agents-blog**
URL: https://termius.com/blog/8-tips-for-using-ai-agents-on-mobile-in-termius
Accessed: 2026-07-16
Quote: Automate the connect→cd→launch-agent sequence with a Startup Command; use `tmux attach` on connect to continue an agent session across desktop and mobile.

**termius-ios-bg**
URL: https://docs.termius.com/help-center/faq/how-can-i-keep-termius-sessions-alive-in-the-background-on-ios-ipados
Accessed: 2026-07-16
Quote: Background activity stops in ~20–30s; Location tracking makes interruption "less likely"; iPad Split View keeps the app foregrounded.

**termius-mosh-forum**
URL: https://support.termius.com/forums/243651-desktop-app/suggestions/6335073-mosh-support
Accessed: 2026-07-16
Quote: "Mosh support" — a standing feature suggestion on Termius's own support forum, not shipped (thread reachable via termius.com search; direct link 404'd on fetch 2026-07-16).

## SYNTHESIS

The biggest practical lever is not a new protocol — it's that **Termius already has the exact primitives the redesign needs, and Termius's own docs describe the intended workflow.** Two things fall out:

1. **The mobile front door is a Startup Command per host.** Instead of "auto-attach to a fixed window then tab by hand," point each Termius host's Startup Command at the login auto-attach script (or directly at a picker). Termius literally documents `tmux attach -t <session>` as the recommended startup command for cross-device continuity — so the redesign is *configuring* Termius, not working around it. This also means the "auto-attach to a picker instead of a window" decision is trivially implementable: set the Startup Command to launch the fzf picker (`--no-unicode`, `tmux -u`) rather than a bare attach. Each new Termius tab = a new connection = the picker again, which is the right behavior for "open another view."

2. **Prefix-chord navigation can be largely replaced by Termius Autocomplete + snippets.** The painful part of the current flow is tmux prefix chords on a touch keyboard at ~50 columns. Snippets with Autocomplete turn navigation into "type a few letters of a label → run." Define snippets like `w:logs` → `tmux select-window -t logs`, `w:agent` → `tmux select-window -t agent`, `pick` → the fzf picker — and Autocomplete surfaces them as you type the label. This is a touch-friendly command palette that doesn't require the prefix key at all. Snippets are cloud-synced across devices, so the palette is identical on phone and iPad.

Constraints to design around: no snippet variables yet (so parameterized "go to window N" needs one snippet per target, or a snippet that shells to the picker); iOS kills background in 20–30s (reinforces the server-side-continuity entry — don't rely on the Termius connection surviving, rely on fast re-attach); Location-tracking is a partial, privacy-costly mitigation, not a fix. Split View + Broadcast Input is a bonus: two panes side by side on iPad with one-command broadcast covers the "concurrent views" need without opening N separate Termius connections/clones.

Net: adopt Termius Startup Command (→ picker) as the front door, build a synced snippet palette for window navigation, and stop treating the Termius connection as something that must survive — treat *reconnect* as the fast path. This dovetails with the ntfy entry (ambient awareness while the app is backgrounded/killed) and the server-side-continuity entry (tmux holds state).
