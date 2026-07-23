# Pramana DevSpecs feedback — 2026-07-23

## Producer V2 screenshot proof joins

- Used `ds task quick` to bound the producer/Unity wire-contract repair, then checkpointed the validated slice.
- The packed source/test context was useful for quickly locating the wire assembly and replay tests.
- Friction: `ds task quick` generated an unignored `devspecs/tasks/...` artifact after the initial command returned. Root `pnpm lint` then failed because Biome formatted that tool-owned JSON. The task artifact needs to be ignored or emitted in a formatter-clean form so dogfooding does not make an otherwise clean repository fail its own gate.

## I2 policy-authority producer repair

- `ds task quick` was appropriate for the bounded contract repair, but its automatic index scan failed with `SQLITE_BUSY` (`database is locked`).
- It still left untracked `devspecs/tasks/...` files behind. The task should either retry the lock safely or clean up its own incomplete artifacts when indexing cannot start.

## Recorder capture-order hotfix

- Used `ds task quick` to bound an async replay-recorder ordering repair.
- Friction: it again emitted an unignored `devspecs/tasks/...` tree, so the temporary task context had to be removed before the repository could be committed cleanly.
