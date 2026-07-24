
## 2026-07-06 — codex spawn prompt fragmentation (Claude session, dotfiles tmux work)
Spawning a codex lane with a long multi-paragraph prompt (blank-line-separated sections) got delivered to the Codex TUI as multiple separate submissions: the model answered the first fragment conversationally ("What specific research question should I investigate?") and went idle without starting work — `wait` reported IDLE, report contract unfulfilled. Recovered with a `revise` nudge ("that was the complete brief, begin now"). Also seen: spawn needed 3 "retrying Enter" attempts on one lane, 1 on another. Suggestion: spawn could paste the prompt as a single bracketed-paste block (it partially does — "[Pasted Content 1018 chars]" was one fragment) or verify the first turn actually consumed the full prompt before declaring the lane started.

## 2026-07-10 — Codex lanes idle at prompt after spawn/revise; `wait` returns before first turn (Fable, pdpp SLVPQ campaign)

**Context:** 20-lane codex fleet (gpt-5.6-sol, `--isolate`), spawned in three batches, heavy use of
`revise` for mid-flight steering. Two related failure shapes, both cost real wall-clock on a
quota-deadline day:

**1. Lanes idle at their prompt with the task text delivered but the turn never started (9/20 lanes).**
Census at T+40..90min showed nine lanes with zero commits, zero dirty files, and `peek` showing only the
original prompt text echoed above an idle `❯`. Affected both `spawn`ed initial prompts (t1-t5, w3-routes,
w2-controller/search/rtindex) and follow-up `revise` turns (the four w1 lanes earlier: they processed a
revise turn, replied, and the session sat idle instead of continuing the standing task; their windows
showed `exited` state while work remained). Recovery that worked both times: `waspflow revise <lane> --
"EXECUTE NOW, end to end, without pausing"` — the headless resume runs to completion. Hypotheses for the
maintainer: (a) spawn's send of the initial prompt may race codex CLI startup under parallel-spawn load
(5+ spawns in quick succession; two spawn calls in a later batch also timed out at 90-120s while still
succeeding — the lane came up live but the CLI reported nothing); (b) after a `revise`-injected turn
completes, codex treats the conversation as turn-complete and idles — it does not re-read the original
standing instruction; every multi-step lane therefore needs its steering messages to re-state "continue
to completion", which is easy to forget and silently halves fleet throughput.

**2. `wait` returns immediately on fresh codex lanes.** A `wait` across five just-spawned lanes returned
"settled" for all five within seconds (10:03) while all five were demonstrably still working — presumably
the provider session log with the `task_complete` marker doesn't exist yet, and wait treats missing-log
as idle. Workaround used: watch deliverable files instead (report-file existence / content markers).
Suggestion: `wait` should block until the session log exists + at least one turn has started, or expose
`--require-turn`.

**Smaller notes from the same run:** `reap` on ~10 reaped-state lanes took >2min and timed out the batch
(individual `timeout 20 waspflow reap` each worked); the billing notice on `revise` (OPENAI_API_KEY set)
fires per-revise — once per lane per session would do; deliverable-contract verification on reports named
differently than `<lane>-report.md` (we used custom names) isn't possible — a `--report` glob or multiple
contracts would help.

**What worked well:** `--isolate` worktrees held up across 20 parallel lanes with zero collisions;
`revise` as headless resume is the workhorse recovery primitive; per-lane `git-diff.txt`/`prompt.txt`
state made post-hoc diagnosis fast.

**Addendum (same day, severity HIGH): `revise` drops the lane's model override.** Every lane resumed/steered
via `revise` came back on the codex CLI default (gpt-5.4-mini medium) instead of its spawned `--model
gpt-5.6-sol`. Discovered via tmux status-bar audit after a "Press enter to confirm" dialog (likely the CLI's
model-change confirm — blind-Enter risk). Fleet impact: most of a 20-lane sol fleet silently executed on
mini after mid-flight steering. Suggestion: revise should re-assert the lane's recorded model/effort (it's
in lane state) on resume, or at minimum warn on mismatch. Also: `status` JSON exposes `model` (requested)
but not the session's CURRENT model — surfacing actual-vs-requested would have caught this hours earlier.

## 2026-07-23 — accepted runtime drift still reaps as `corrupt_result`

Lane `dg58_balance_lock` was requested as `gpt-5.6-sol`/`xhigh`, then Codex compaction changed the
observed runtime to `gpt-5.6-luna`/`low` during final verification/reporting. `waspflow wait --reap`
correctly stopped with `runtime_unverified`. After inspecting the diff/report and recorded deterministic
PostgreSQL/full-suite gates, I ran `waspflow accept-runtime <lane> --reason ...`; it succeeded and
recorded `runtime_settings_accepted_at/reason`. A subsequent `waspflow reap <lane>` still treated the
prior `runtime_unverified` result as unrecognized, archived the branch, and stamped the reaped lane
`result: corrupt_result`. The dirty worktree and report were preserved, so no work was lost.

Expected: accepting the exact observed drift should transition the lane into a reap-eligible state (or
`reap` should honor the acceptance receipt) without laundering unrelated failures.

Same run, separate lane: `waspflow wait dg58_legacy_payee --reap` successfully archived and stamped
`result=succeeded`, then exited 2 with `/home/tnunamak/.local/bin/waspflow: line 1598: syntax error near
unexpected token ')'`. State and artifacts were correct, but the wrapper's post-success parse error made
the background completion signal falsely red. It repeated on `dg58_outbox_fix` after a successful
archive/worktree removal/reap, this time as `line 1598: syntax error near unexpected token ';;'`.
