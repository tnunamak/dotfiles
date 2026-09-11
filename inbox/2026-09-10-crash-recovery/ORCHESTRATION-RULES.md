# Orchestration rules for this autonomous run (2026-09-10)

Owner stepped away. Budget rationale: both Claude accounts are under 100% on the 7d
quota and reset in ~2h54m, so Claude tokens are use-it-or-lose-it. Codex is OUT
(100% of 7d, ~4d to reset) — do NOT route to Codex arms.

## Hard rules (learned the hard way this session)

1. **No native `Agent` subagents for bulk work.** `subagent_type: "fork"` ALWAYS
   inherits the parent model (Fable) — the `model:` override is silently ignored.
   Even `general-purpose` defaults to the parent/Fable. Four dispatched agents
   immediately fanned out into their own children; cost compounds invisibly.
2. **Killing a parent does NOT kill its children.** Orphans keep running and
   keep billing. After any kill, re-run `ListAgents` and confirm `killed`.
3. **`ListAgents` before and after every dispatch.** It is the only ground truth.
   Never assert "nothing is running" from inference.
4. **All delegation goes through `waspflow`**, where provider+model+effort are
   explicit on the command line and auditable later via `waspflow list` /
   `waspflow receipts summary`.
5. **Verify `ANTHROPIC_API_KEY` is unset** before Claude workers (confirmed unset;
   `waspflow doctor` says subscription/Agent-SDK credit). A stray key once ran
   $1,800 in two days.

## Model routing (from minnows model-choice-policy pack, `waspflow ops list`)

Resolved policy file: ~/.local/share/minnows-data/model-choice-policy/operating-points.json

| intent | op | arm |
|---|---|---|
| broad info gathering / fan-out | `fanout.explore` | claude-sonnet-5 / medium |
| report writing, doc lookup | `recover.report`, `docs.lookup` | claude-sonnet-5 / low |
| normal implementation | `implement.standard` | claude-sonnet-5 / medium |
| implementation under quota pressure | `implement.quota-tight` | claude-sonnet-5 / low |
| judged review / deep advice | `advisor.deep` | claude-sonnet-5 / high |
| ~~accuracy-first impl / audit~~ | ~~`implement.accuracy-first`, `review.audit`~~ | **codex gpt-6-astra — UNAVAILABLE, out of quota** |

Fable (this orchestrator) is for final judgment and synthesis ONLY — never for
bulk reading or mechanical work. Opus is mid-tier; prefer Sonnet unless a task
genuinely needs more.

Because `review.audit` (Codex) is unavailable, the "maker is not the judge" rule
is satisfied by using a DIFFERENT Claude arm for review than for making
(`advisor.deep` sonnet/high reviewing `implement.standard` sonnet/medium output),
and by me (Fable) doing final judgment. Note this is weaker than cross-provider
review — flag any conclusion that depended on it.

## Salvage available

Killed agents left ~3.5MB of extracted transcripts in this directory
(`_*.txt`, `_full_list.json`, `inbox-list.txt`, `batch-0*`). Workers should READ
THESE LOCAL FILES rather than re-running `convo` where possible — the expensive
extraction is already paid for.

## Safety boundaries

- tmux default socket (`main`, `waspflow`, `recovery-*` sessions) is Tim's LIVE
  production server with 43 real agent sessions in it. Read-only: `tmux ls`,
  `list-windows`, `capture-pane` are OK. NEVER send-keys / run-shell /
  kill-session / kill-server on the default socket. Test tmux only via
  `tmux -L test-$$`.
- Do not push, merge, or comment on PRs without explicit owner approval. Draft
  artifacts to disk; leave the irreversible step for Tim.
- `/tmp` is RAM-backed; use `~/.tmp` for anything large.
