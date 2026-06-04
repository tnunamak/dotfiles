# Teaching Examples From The First PDPP Audit

These examples are not universal rules. Use them as calibration windows when
teaching or testing the audit method on the original PDPP session.

## Best Three-Card Teaching Set

### Stop-Condition Repair Unlocks Execution

- Source: `tmp/workstreams/steering-calibration-cards-2026-05-28.md`
- Heading: `## Card 1 - Stop-Condition Repair Unlocks Execution`
- Window: `2026-04-18T18:00Z -> 2026-04-19T00:00Z`
- Why useful: a compact positive case where stop-rule corrections were followed
  by continued execution instead of arbitrary tranche returns.
- Teaches: stop only for a named human-in-loop decision.

### Output Volume Hides Repeated Premature Returns

- Source: `tmp/workstreams/steering-calibration-cards-2026-05-28.md`
- Heading: `## Card 2 - Output Volume Hides Repeated Premature Returns`
- Window: `2026-04-19T12:00Z -> 2026-04-19T18:00Z`
- Why useful: a contrast case that looked productive mechanically but still
  needed repeated stop-condition repair.
- Teaches: an acknowledged primitive is not durable state until behavior stays
  changed across turns.

### Refresh Doc Reanchored Concepts But Not Execution Shape

- Source: `tmp/workstreams/steering-audit-worked-slice-2026-05-27-abd.md`
- Heading: `### Card 5 - Refresh Doc Reanchored Concepts But Not Execution Shape`
- Window: `2026-05-27T19:20Z -> 2026-05-27T20:51Z`
- Why useful: context restored vocabulary, but not the intended operating mode
  until the user challenged serial planning.
- Teaches: after refresh, produce lane state first and prose second.

## Additional Contrast Cards

### Live Evidence Turns "Done" Into Firefight

- Source: `tmp/workstreams/steering-calibration-cards-2026-05-28.md`
- Heading: `## Card 4 - Live Evidence Turns "Done" Into Firefight`
- Window: `2026-05-23T00:00Z -> 2026-05-23T06:00Z`
- Why useful: repo progress and commits were real, while live ChatGPT/Claude
  evidence repeatedly reopened acceptance.
- Teaches: separate repo evidence from runtime acceptance.

### Worker "Done" Vs Owner "Done"

- Source: `tmp/workstreams/steering-audit-candidate-slice-2026-04-24.md`
- Heading: `## Candidate Cards For A Full Audit`, especially cards `3` and `7`
- Window: `2026-04-24T08:58Z -> 2026-04-24T21:50Z`
- Why useful: worker claims, worktree state, OpenSpec state, and live UI state
  had to be reconciled before closure.
- Teaches: the owner/coordinator role needs authority, lane state, stop
  condition, report path, and owner merge gate.
