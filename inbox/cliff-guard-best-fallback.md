# Cliff guard: fall back to best.txt when prev has too few panes

## Problem

`tmux/.config/tmux/scripts/post-save-backup.sh` cliff guard requires
`prev_panes >= 3` before it considers rejecting a shrunken save. If the
prev save itself is broken (0–2 panes), the guard can't fire, and a
sequence like `19 → 0 → 2 → 2` propagates the broken state.

This is exactly what happened on the 2026-04-29 second crash:

```
[19:32:41Z] backed up 143240.txt (panes=19, prev=142740 with 19 panes, cliff_guard=0)
[19:41:05Z] backed up 144105.txt (panes=2,  prev=143452 with 0  panes, cliff_guard=0)
[19:46:05Z] backed up 144605.txt (panes=2,  prev=144105 with 2  panes, cliff_guard=0)
```

A save at 14:34:52 had 0 panes (immediately post-crash). When the next
save at 14:41 fired, prev was that 0-pane file, so the guard skipped.
The 14:41 and 14:46 saves both had 2 panes (kitty-spawned grouped
clones, no real work) and were accepted as `last`.

## Fix sketch

When `prev_panes < 3` AND `best.txt` exists with `>= 3` panes, use
best.txt as the cliff comparison baseline instead of skipping. This
catches the case where prev got corrupted by a previous crash.

Pseudocode:

```bash
if (( prev_panes < 3 )); then
  if [[ -f "$BEST_FILE" ]] && (( best_panes >= 3 )); then
    prev_path="$BEST_FILE"
    prev_panes=$best_panes
    log "cliff guard: prev too small ($prev_panes), falling back to best.txt"
  fi
fi
# ... existing cliff comparison ...
```

## Validation

Need a new harness scenario in
`devcontainer/scripts/tmux-restore-test/`:

- **`cliff-shrink-via-broken-prev`**: populate 19 panes, save, manually
  truncate the live last file to 0 panes (mimicking a post-crash empty
  save), then save again with 2 panes. Assert `last` ends up pointing
  at a 19-pane state (rewritten from best.txt) rather than the 2-pane
  shrunken state.

Negative variant: same scenario with the patch reverted should produce
a 2-pane `last`.

## Why this isn't shipped yet

Conservative — the fallback could mis-fire if best.txt is stale (weeks
old) and the user legitimately reduced their session size. Need to
think through:

1. Should best.txt be capped at recent? (e.g., refuse if older than 7
   days)
2. Should the cliff threshold be relaxed when using best.txt as baseline
   (since it's known to be a high-water mark)?
3. Or is the right fix to track `last_known_good` separately from
   `best.txt`?

## Related

- Original cliff guard added in commit `e809810`
- Redesigned to use `$1` (new save path) in commit `2bedee9`
- Dedup added in commit `af82c83`
- Arithmetic syntax error fix in commit `68dd92b`

## Found via

2026-04-29 second crash — see CLAUDE.md investigation. After repair of
the line-114 syntax bug, the restore-side worked, but `last` was still
pointing at a 2-pane post-crash save because the cliff guard hadn't
fired during the save chain. Manual recovery via repointing to a
backups/ entry was needed.
