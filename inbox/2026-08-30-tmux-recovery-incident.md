# Tmux, Kitty, and agent recovery incident - 2026-08-30

Status: recovery mostly complete; persistence fixes are implemented but still need an end-to-end reboot rehearsal before this can be called closed. Do not treat a matching tmux window number as proof of identity.

## Evidence

- Primary preserved evidence: `~/.tmp/tmux-recovery-incident-20260830/evidence-20260830T2040CDT.tar.zst`
- Evidence SHA-256: `23add8c...5081`
- Last proven clean tmux topology: `tmux_resurrect_20260830T162912.txt`, captured at 16:29:12 CDT with 191 panes.
- Authoritative pre-stop desktop evidence: `restore-archive/manifest-20260831T001042Z.json`. Its archive filename is later, but its internal `captured_at` is 16:18:57 CDT, and its 24 Kitty native-session files were written at 16:18:35-55.
- Current recovery ledger: `inbox/2026-08-30-tmux-recovery-ledger.tsv`.
- Desktop visual recovery ledger: `inbox/2026-08-30-desktop-visual-recovery-applied.tsv`.

## Safety Constraints

- Do not touch `main:20`. Tim manually recovered it and is actively using it.
- Do not touch current protected recovery/agent windows without a fresh owner instruction. Current protected set from the recovery record: `main:9`, `main:18`, `main:20`, `main:28`, `main:29`, and `main:34`.
- Do not change terminal modes or run `stty` against production panes.
- Do not use `tmux display-message` to test whether a target exists. A malformed or absent target can resolve to the current pane. Use `tmux list-panes -t` and then address the returned immutable `%pane_id`.
- Run all tmux tests on isolated sockets (`tmux -L test-...`). Never run a bare `tmux kill-server`.
- Do not use snapshots from 19:05 or later as pre-failure truth until each entry is corroborated. They contain post-restore assignments.
- Preserve a displaced live process in a detached recovery session before unlinking it.

## Incident Behavior

This is what went wrong.

- At 16:33:20 CDT, `tmux.service` began stopping. Its ExecStop save started at 16:33:24 while tmux windows and `tmux-spawn` scopes were already disappearing. The save logged `can't find window: 4`, captured only 59 panes, and still returned success.
- The save collapsed from 191 panes to 59 panes. The old layout cliff guard rejected only saves below 20% of the previous pane count. 59 panes was 30.9% of 191, so the bad save passed and became `last`.
- The assistant-session guard independently rejected its own 110-to-4 collapse. That left layout and assistant identity at different generations.
- The retained 110-session assistant sidecar was also semantically corrupt. Most entries were labeled `main:*` even though many were Waspflow lanes. The local grouped-session patch had queried `tmux display-message -t "$session_name"` with a bare target. Because `main` had a window named `waspflow`, tmux resolved bare `waspflow` to that window and returned `session=main-30 group=main`. Querying exact `=waspflow:` returned the real ungrouped `waspflow` session. The saver therefore canonicalized unrelated Waspflow pane addresses to `main:N`.
- At about 19:00, boot restore selected the promoted 59-pane snapshot. Later saves recorded the partially reconstructed and broadly misassigned topology, contaminating newer evidence.
- The first broad recovery pass trusted a 20:00 snapshot and placed several Waspflow/ODL sessions into `main` indexes without proving those were the pre-failure occupants.
- Claude recovery commands were rendered with `--resume ID` after a standalone `--`. Claude interpreted the resume flag as prompt text and opened new sessions.
- Most affected Waspflow Claude transcripts live under `~/.claude-odl`; this is per-session state, not a global Claude profile. At least window 14 used `~/.claude`.
- Malformed targets such as `=main:8.0` were used during recovery. One resolved to the current pane. The terminal corruption disappeared after the affected Kitty window was closed and reopened; no persistent terminal-mode change remains in the record.
- Duplicate `tmux_window_index=20` desktop records and wrong desktop-to-agent matches were observed. The visual desktop mapping cannot be inferred from window number alone.
- Desktop snapshot had a live-join defect: `display-message -c <tty>` did not evaluate the requested client context for the needed tmux fields, so multiple Kitty windows could collapse to one invoking-client row. The fix uses filtered `list-clients` rows keyed by `#{client_tty}` and has a regression that proves two fake TTYs keep distinct window indexes, names, cwd, and command.
- Desktop restore had a branch-order defect: rows that were both tmux rows and Kitty native-session rows preferred the native session path and bypassed `TMUX_ATTACH_TARGET_WINDOW`. The fix makes explicit tmux target selection win for all tmux rows. Multiple visual windows may attach to the same tmux index when the manifest intentionally contains duplicate visual views; duplicate KWin identities are still rejected.

## Correct System Behavior

This is the target behavior after the fixes.

- `tmux.service` must save before systemd stops any `tmux-spawn-*.scope` pane scopes. The tracked prefix drop-in `tmux/.config/systemd/user/tmux-spawn-.scope.d/20-save-before-pane-stop.conf` adds `Before=tmux.service`; because stop ordering is inverse, matching pane scopes stop after `tmux.service` has run its save.
- Stop saves must require a near-complete topology before advancing recovery state. `tmux-service-stop.sh` exports `TMUX_RESURRECT_SAVE_MIN_PCT=80` so a 191-to-59 collapse is rejected.
- Layout, assistant sidecar, and desktop manifest must advance as one transaction bundle. A restore must use one resolved last-good bundle or fail closed when transaction state exists but no valid bundle resolves.
- Desktop restore must use sidecar-backed agent identity receipts and Kitty native-session assets. Shell receipts are weaker and must not be treated as equivalent proof for agent sessions.
- Agent processes must not restart merely because a pane existed before shutdown. `tmux-agent-resume` records entries as deferred and resumes only a selected entry or an explicit short-lived automatic lease. Boot restore waits for a human client attach before applying the one-shot attended marker.
- Codex paused-goal prompts are state, not noise. Faithful resurrection should preserve the paused state and default to `Leave paused` unless a separate valid continuation lease proves unattended work should restart.
- Claude `--resume ID` must be inserted before the first standalone `--` so it remains a CLI flag rather than prompt text.
- Claude per-session config roots must be restored only through an allowlisted `CLAUDE_CONFIG_DIR` under the owner home. Secret-looking environment values must not be serialized or rendered into resume commands.
- Desktop snapshots must join Kitty windows to tmux clients through filtered `list-clients` evidence, not `display-message -c` field lookups.
- Desktop restore must treat `TMUX_ATTACH_TARGET_WINDOW` as authoritative for tmux rows even when a Kitty native-session file is present. Native sessions are for non-tmux Kitty rows or for identity evidence bundled with desktop state, not a reason to bypass the tmux target.

## Current Recovery State

- `main:0` is Daisy again. Pane `%156` runs `bwrap` in the Daisy directory.
- `daisy.service` is active and Pi `0.84.4` runs with `--continue`; the UI reports the existing high-token session state.
- The displaced `custody-consult2` pane `%142` was preserved in detached tmux session `recovery-custody-consult2`; it was not killed.
- Pi had disappeared from the newest NVM installation. Daisy failed three times at boot with `pi is not installed`. Daisy's own upgrade script reinstalled `@earendil-works/pi-coding-agent`; the reproducibility fix is still a separate follow-up.
- The archive-2 Codex parent session is `019ff145-437b-7360-8693-8adb853b5410`. It was repeatedly recorded at `main:28` before the failure and is restored at `main:28`, pane `%160`, with stable title `archive-2`. It is waiting at Codex's paused-goal choice. Session `01a0544d-06c7-7132-823c-474956736ca8` is a delegated child of this parent, not the user-facing window.
- The current incident Codex thread is `019f8f87` and is recorded at `main:34`; the immutable tmux window id is `@18`. Treat it as protected active work.
- The newest ledger marks most indexes verified-restored. The remaining owner-choice or unresolved-session-id rows are `main:2`, `main:16`, `main:21`, `main:26`, and `main:32`; `main:9` is protected with a cwd mismatch noted in the ledger.
- `main:20` was manually recovered by Tim and must remain untouched.
- The pre-reboot desktop manifest has no row for the Kitty client that displayed `main:28`. The archive-2 agent's old virtual desktop and geometry therefore cannot be proven from the current saved layout artifacts.
- The corrected production desktop manifest contains 32 visual window rows and 31 tmux-backed rows. A forced dry-run rendered 32 restore rows, proving the duplicate visual tmux view is retained instead of collapsed.
- The first production transaction bundle is `bundle-bad13e0f8d10761a`: layout count 118, assistant count 63, desktop component bundled, 29 native Kitty sessions. `resurrect-transaction-bundle resolve` verified this bundle as the current last-good bundle.

## Code and Test State

- Implemented: systemd prefix drop-in for `tmux-spawn-*.scope` stop ordering.
- Implemented: stop-wrapper 80% save floor.
- Implemented: transaction bundle tooling for layout, assistant sidecar, desktop manifest, Kitty native sessions, hashes, counts, last-good pointer, and fail-closed restore activation.
- Implemented: post-save transaction hook in `tmux.conf`, with assistant save run in the same layout generation.
- Implemented: assistant saver patch no longer uses the ambiguous bare-session `display-message` lookup; it captures `#{session_group}` from the same `list-panes` row and has an isolated collision regression.
- Implemented: `tmux-agent-resume` inserts Claude `--resume` before prompt delimiter, restores allowlisted `CLAUDE_CONFIG_DIR`, and refuses invalid or secret-looking sidecar environment data.
- Implemented: desktop-layout identity receipts and transaction-bundle desktop activation tests.
- Implemented: desktop snapshot tmux-client context regression for the `display-message -c` collapse; snapshot now uses filtered `list-clients`.
- Implemented: desktop restore target-selection regression; explicit `TMUX_ATTACH_TARGET_WINDOW` wins over Kitty native-session launch for tmux rows.
- Still needs review before commit: activation cleanup and atomicity in `systemd-restore.sh` have already been scrutinized once; staged-temp cleanup and atomic `last` symlink movement should remain under review until the focused test confirms the final diff.
- Still needs cold validation: the production bundle resolves and dry-run evidence is good, but a real cold reboot restore rehearsal has not yet been completed in this record.
- Still needs broader verification: `desktop-layout-restore` has SIGWINCH-related changes. A focused test passed once; keep this in the test gate until the native-session and target-selection paths are rerun together.
- Still needs operational follow-up: Daisy/Pi provisioning across Node/NVM updates.

## Completion Gates

1. Keep the per-index ledger current from clean snapshot, sidecars, transcript stores, Kitty native-session files, desktop-layout archives, and Tim's direct corrections.
2. Label each evidence source by timestamp and whether it predates or follows the faulty restore.
3. For every changed window, preserve any displaced process, restore the intended session, and verify transcript content, cwd, process identity, tab title, and resize behavior.
4. Verify Kitty-window-to-virtual-desktop mappings separately from tmux index mappings.
5. Run the focused isolated tests for assistant identity, agent resume, transaction bundles, systemd restore, desktop receipts, guarded assistant save, and desktop restore SIGWINCH/native-session behavior.
6. Perform an end-to-end restore rehearsal and retain machine-readable receipts.
