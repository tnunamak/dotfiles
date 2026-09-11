# 2026-09-10 crash recovery — session artifacts

Moved here from `~/.tmp/recovery/` on 2026-09-11 because `tmp-reaper.timer`
deletes `~/.tmp` subdirs whose newest file is older than 7 days.

Read `SUMMARY.md` first.

## Status of the two rescued diffs — RESOLVED, nothing outstanding

Both pieces of uncommitted work found during the disk cleanup are now committed
in their own worktrees, so the loose `.patch` backups are obsolete and were not
copied here:

- `clawmeter-waspflow-clawmeter-model-support` → `2912fd5`
  "fix(diagnose): recognize model-scoped quota windows by shape"
  (`go build ./...` + `go test ./internal/diagnose/` clean)
- `vana-node-ops-waspflow-mainnet-phase0-sonnet-0817` → `6b1e135`
  "feat(mainnet): add the Phase 0 differential verification play"
  (oracle suite PASS; execution fixture 19/19 PASS against the real playbook)

Neither is pushed. Both sit on their existing `waspflow/*` branches.

**A correction worth carrying forward:** the original triage scanned with
`git status --porcelain --untracked-files=no`, so it reported vana-node-ops as
"4 modified files". The real deliverable was mostly UNTRACKED — the playbook,
its group_vars, the docs and both test suites. A `git diff` backup would have
preserved none of it. When checking a worktree for work at risk, count untracked
files too.

## Known-stale content in these reports

- `dropped-intent-claude.md` item 2 (`INFISICAL_SKIP_HYDRATION` still set) is
  WRONG. Verified unset on the global tmux environment — the crash restarted the
  server and cleared it. No action needed.
- `resurrection-state.md` is a partial draft that got the causality backwards.
  `RESURRECTION-ROOT-CAUSE.md` supersedes it; kept only for its prior-art survey.
- `waspflow-inbox-triage.md` is a summary only. The detailed 85-note table went
  to the worker's stdout and was lost (`waspflow exec` does not reliably write
  its final message to `-o`). The triage would need re-running to recover it.

## Resurrection health, re-verified 2026-09-11 08:20

Working. 51 saves that day, newest 0m old, `last` resolves, both timers firing,
56 assistant sessions captured, and all 38 windows of the `main` group present
in the save (saved count == live count).

One open cosmetic issue: panes are recorded under `main-37` only, not the bare
group name — the bug upstream PR #103 fixes, still unmerged. Not data loss.

## Follow-up investigations (added 2026-09-11)

- `window30-migration.md` — the Codex→Claude fork migration. Both rollouts located
  and verified (parent `01a07172`, Sep 5; fork `01a085e4`, Sep 9, forked at
  ordinal 3782). **Two corrections to earlier claims:** `smigrate` DOES NOT EXIST
  — it is a design proposal quoted in a transcript, never a tool, so "smigrate
  refuses forks" was never true of anything runnable. And the migration target
  session could not be located on disk. **Resolved separately: tmux `main:30` is
  now `peregrine` (last active Sep 2), NOT the migration session** — window
  indices shifted in the crash restore, so "window 30" no longer names what it
  did on 09-10. Any repair must first identify the real target session rather
  than trusting the window number.
- `inbox-triage-full.md` — full triage of the 85 waspflow inbox notes.
- `daisy-approvals-wip.md` — assessment of the stashed approvals refactor.
- `pin-check-fix.md` — the data-connect connector-pin CI check.
