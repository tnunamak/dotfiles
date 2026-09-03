
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

## 2026-07-24 — reap blocked on missing runtime receipt (Claude session, pdpp-pg-volumes lane)
Lane completed its work + report fine, but `waspflow reap` refused: "no current verified Codex runtime receipt (refresh=observed, match=unknown)". Status showed receipt_emitted=false, model fields all empty — the receipt was apparently never emitted rather than drifted, so the operator gets pointed at "inspect an observed drift" that doesn't exist. Worked around with --accept-runtime. Suggestion: distinguish "receipt never emitted" (spawn-time integration gap, probably warn-only) from "receipt mismatch" (real drift, block), and have the error name the actual condition.
Addendum: accept-runtime then ALSO refused ("no observed runtime mismatch to accept") — so a never-emitted receipt is unreapable by both paths (reap wants a receipt or accepted drift; accept-runtime wants a drift to accept). Fell back to `close --status harvested` + manual kill-window. That deadlock needs an escape hatch.
## 2026-08-11: completed Codex lanes lost provider receipts and could not accept revisions

Four Codex Luna lanes completed their requested report and left correct worktree edits, but `waspflow inspect <lane> --json` classified each as `corrupt/unknown` with `provider-log:missing` and `provider-receipt-not-trustworthy`. The tmux window still existed at an idle Codex prompt.

`waspflow revise <lane> -- "..."` returned successfully but did not deliver the follow-up prompt or resume the lane. `peek` remained at the original final response. I had to close each lane as abandoned, reap it, and spawn a new revision lane against the same worktree.

The durable report and filesystem edits were present, so this looks like receipt capture or lane-finalization loss rather than agent failure. Useful behavior would be either:

- recover the provider receipt from the live TUI/session before classifying the lane as corrupt;
- make `revise` fail loudly when it cannot deliver; or
- allow `revise` to start a successor lane automatically while preserving the prior lane's report provenance.
## 2026-08-11: `reap` left terminal-idle tmux windows alive

After closing harvested or abandoned Codex lanes, `waspflow reap <lane> --force --keep-worktree --no-archive` returned without an error but left the lane lifecycle `live` and its tmux window present. Repeating without `--keep-worktree` behaved the same way. I had to kill each exact `waspflow:<lane>` tmux window after confirming its work was harvested. This made prompt lane cleanup slow and unreliable under mild resource pressure.

## 2026-08-23: Codex spawn produces an empty lane — zero-byte state, no tmux window

`waspflow spawn --provider codex` returned success and created a lane directory, but the lane
never existed in any usable sense: `state.json` zero bytes, transcript zero bytes, and no tmux
window created at all. `inspect` reported `CORRUPT`.

Reproduced **three times in one night** across three different models (`gpt-5.6-sol`,
`gpt-5.6-terra`, `gpt-5.6-luna`) and two effort levels, so it is not model- or effort-specific.

This is worse than the 2026-08-11 receipt-loss entry above. There, the agent did the work and
only the receipt was lost — the worktree edits and the report survived. Here nothing runs. Had I
dispatched the planned five-lane wave into this path, I would have gotten five empty shells and
discovered it only at harvest time.

The same Codex account and models work fine through the Codex MCP tool (`mcp__codex-cli__codex`
with `model`, `reasoningEffort`, `sandbox`, `workingDirectory`), which is how the wave actually
ran. So the provider credentials and CLI are healthy; the breakage is in waspflow's codex spawn
path specifically.

Most useful fix, in order: (1) `spawn` should verify the lane is real — non-empty state file and
a live tmux window — before reporting success, and fail loudly otherwise; a spawn that silently
yields nothing is the worst failure shape for a fan-out orchestrator, because the cost is only
discovered after the whole wave is dispatched. (2) Worth checking whether the CLI invocation
shape drifted from what the installed Codex version expects.

### 2026-08-23 addendum: reconfirmed with CORRECT syntax; `escalate` cannot substitute

My earlier reproductions used a wrong flag (`--task` instead of the positional `-- <task>`),
so they were not clean evidence. Re-probed with the documented form:

```
waspflow spawn --provider codex --model gpt-5.6-luna --effort low --lane wf-probe2-0823 \
  -- "Reply with the single word OK and nothing else."
```

Exit 0, no output, and the lane lands as:
```
wf-probe2-0823   ?   CORRUPT   ?   unknown   (unparseable state.json)
```

So the defect is real and independent of my earlier syntax error: **spawn exits 0 while
producing an unparseable `state.json` and no usable lane.** Exit 0 on a lane that does not
exist is the worst possible signal for a fan-out orchestrator — a caller dispatching N lanes
gets N successes and discovers the truth only at harvest.

`waspflow escalate` was suggested as a workaround. It cannot substitute: its usage is
`escalate <lane> [--to ...]`, i.e. it switches an EXISTING failed lane to another operating
point or provider arm. When spawn never produces a healthy lane, there is nothing to escalate
from. (`--force` escalates "without an eligible failed checkpoint", but still requires the lane.)

Also observed: `waspflow list` took >120s on this machine during the same session, having been
sub-second minutes earlier. Possibly unrelated to spawn, but worth knowing if the lane registry
has grown large — the list is well over a thousand lanes here.

Still worked around by calling the Codex MCP tool directly, which has been reliable all session
across ~15 lanes.

## 2026-08-30 — rollout-log scan cost and lane-scope core dumps (Claude session, crash-noise-suppression-0830)

Two separate costs observed today, unrelated to each other:

1. Every waspflow lane operation this session triggered a scan over rollout logs that had grown
   to 23GB, driving load past 100 on the host during otherwise-normal lane spawn/list/reap calls.
   Not measured precisely (no before/after timing capture), but the load spike was consistently
   correlated with lane ops during this session, not with any other concurrent process.

2. Lanes running the pdpp repo's test suite hit an intentional-abort test oracle (memory-capped
   Node child processes that SIGABRT by design to prove an OOM-detection oracle). Because
   `systemd-run --user --scope` scopes have no exec context, `--property=LimitCORE=0` cannot be
   applied to them (`systemd-run` rejects it with "Unknown assignment"), so every one of these
   by-design aborts was captured as a full core dump by systemd-coredump and surfaced to the
   desktop as a "Service Crash" notification, roughly every 15-90 minutes today. Fixed in
   `~/code/waspflow` commit `7e90aa8f2` (`lib/core.sh`, `ulimit -c 0` inserted into the lane-scope
   wrapper shell before it execs the real command) — committed to branch
   `waspflow/crash-noise-suppression-0830`, not pushed, not merged.
