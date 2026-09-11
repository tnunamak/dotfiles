# The agents that vanished in the 2026-09-10 crash — recovery map

**Nothing is lost.** Every recoverable transcript was verified present on disk
(25 of 25 from the pre-crash bundle). The conversations survived; they lost the
tmux *window* they were displayed in, because restore replayed a 10-day-old
snapshot after the save blackout.

Run `restore-lost-agents.sh` (same directory) to re-attach them.

## The numbers

- 38 windows in the `main` group; **28 came back as bare shells**
- **18 of those 28 are recoverable** with session id + tool + cwd
- **9 were never agent windows** — plainly named working dirs, nothing lost
- **1 genuine gap** — `main:27`, see below

## Where the map came from

`~/.tmux/resurrect/transactions/bundle-bad13e0f8d10761a/assistant-assistant-sessions.json`,
timestamped **2026-08-31T03:06:14Z** — the last save before the blackout, holding
63 sessions across 25 `main` windows. Later bundles only have ~9 main windows
because they were written *after* the crash, so they only see survivors. If you
ever need to redo this, search the transaction bundles for the one with the most
`main:` windows, not the most recent.

## Recoverable (18)

| win | window name | tool | session id | cwd |
|-----|-------------|------|-----------|-----|
| 3 | Investigate Coolify and Vivid Fish hosting | claude | `e893c807` | ~/sandbox |
| 4 | Investigate Claude Code hook errors | claude | `bdac59f6` | ~/code/dotfiles |
| 6 | context-gateway | codex | `019faeb4` | ~/code/context-gateway |
| 7 | Test Devspecs CLI v1.0.0 release | claude | `c0dad57d` | ~/code/dotfiles |
| 10 | Claude Code | claude | `42569d54` | ~/sandbox |
| 13 | pdpp | codex | `019fa50c` | ~/code/pdpp |
| 14 | Check memo and review Grafana data | claude | `47fd3267` | ~/sandbox |
| 15 | zsh | claude | `8b2c8ac0` | (pdpp project dir) |
| 16 | Improve data connector developer experience | claude | `1f934c1f` | ~ |
| 17 | Claude Code | claude | `58979a73` | ~/applications/SillyTavern |
| 19 | Fix excessive Plasma notifications in Kitty | claude | `66850dc0` | ~/code/dotfiles |
| 21 | Transfer pdpp.dev domain and add copyright | claude | `3f537a60` | ~ |
| 22 | Vana Privy facilitator security implementation | claude | `4c9ad3f0` | ~/code/vana-node-ops |
| 24 | sandbox | codex | `019ca25a` | ~ |
| 26 | Initialize new session | claude | `028cfed9` | ~ |
| 28 | archive-2 | codex | `019ff145` | ~ |
| 31 | Audio book generation from EPUBs | claude | `929c055b` | ~/Downloads |
| 33 | Debug signal launch issue | claude | `ff819ac4` | ~/code/pdpp |

Note `main:15` is the session that caused the "you resurrected wrongly" confusion
on the morning of 09-10 — it is `8b2c8ac0`, and it is intact.

## Never agent windows (9) — nothing lost

`main:1` openai-proxy · `main:2` vana-node-ops · `main:5` clawmeter ·
`main:8` unity-surfaces · `main:11` peregrine · `main:12` dotfiles ·
`main:23` unity-surfaces · `main:32` pdpp · `main:37` zsh

Checked every transaction bundle: none ever recorded an agent in these panes.
They were shells sitting in a working directory.

**`main:5` (clawmeter) specifically**: no agent was ever recorded there, so there
is no clawmeter conversation to resume. The most recent clawmeter-project session
on disk is `f6b30c77` (2026-09-05), but its only user turn is a one-shot
provider-roster audit — a waspflow lane, not an interactive session.

## The one real gap

**`main:27` — "Withdrawal flow ready for dev UAT"**. Named like an agent window
but absent from every bundle, and a transcript search for "withdraw" surfaced only
currently-live sessions. Either it predates the retained bundles or its agent had
already exited. The window name is the surviving record of what it was about.

## Why this happened (short version)

tmux-continuum's saves stopped 2026-08-31 because it declines to install its
status-line autosave hook while another tmux server exists. The replacement timer
was `enable`d without `--now`, so it did not start until the 09-10 reboot. Ten
days, no saves. Full detail in `RESURRECTION-ROOT-CAUSE.md`.

A freshness watchdog now alerts if saves stop for 30 minutes
(`tmux-save-watchdog.timer`), so this specific failure cannot silently repeat.
