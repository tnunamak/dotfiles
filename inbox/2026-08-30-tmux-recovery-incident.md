# Tmux, Kitty, and agent recovery incident - 2026-08-30

Status: recovery mostly complete; an isolated cold-restore rehearsal now passes, but a real cold reboot and KWin validation are still open. Crash-consistent bundle activation, periodic saving, and strict assistant identity receipts are committed and stowed. `tmux-restore.service` is active; the periodic timer is enabled but deliberately not started until the Codex hook is trusted and pre-hook sessions have receipts. Do not treat a matching tmux window number as proof of identity.

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

This is the causal hierarchy. Systemd is not buggy: it followed the ordering that
was declared. Our local unit graph was missing the ordering edge that should have
kept pane scopes alive until the tmux service stop save had finished.

- Initiating failure: at 16:33:20 CDT, `tmux.service` began stopping. Its ExecStop save started at 16:33:24 while tmux windows and `tmux-spawn` scopes were already disappearing. The save logged `can't find window: 4`, captured only 59 panes, and still returned success. The missing local stop-ordering edge made the save observe a live topology while it was being torn down.
- Amplifier: the old layout cliff guard was permissive. It rejected only saves below 20% of the previous pane count; 59 panes was 30.9% of 191, so the bad save passed and became `last`. The assistant-session guard independently rejected its 110-to-4 collapse, leaving layout and assistant identity at different, non-transactional generations.
- Amplifier: the retained 110-session assistant sidecar was semantically corrupt. Most entries were labeled `main:*` even though many were Waspflow lanes. The local grouped-session patch queried `tmux display-message -t "$session_name"` with a bare target. Because `main` had a window named `waspflow`, tmux resolved bare `waspflow` to that window and returned `session=main-30 group=main`. Querying exact `=waspflow:` returned the real ungrouped `waspflow` session. The saver therefore canonicalized unrelated Waspflow pane addresses to `main:N`.
- Amplifier: at about 19:00, boot restore selected the promoted 59-pane snapshot. Later saves recorded the partially reconstructed and broadly misassigned topology, contaminating newer evidence. The first broad recovery pass then trusted a 20:00 snapshot and placed several Waspflow/ODL sessions into `main` indexes without proving those were the pre-failure occupants.
- Recovery identity defects: Claude commands put `--resume ID` after a standalone `--`, so Claude treated the resume flag as prompt text and opened new sessions. Most affected Waspflow Claude transcripts live under `~/.claude-odl`; this is per-session state, not a global Claude profile. At least window 14 used `~/.claude`.
- Recovery target defects: malformed targets such as `=main:8.0` were used; one resolved to the current pane. The terminal corruption disappeared after the affected Kitty window was closed and reopened; no persistent terminal-mode change remains in the record. Duplicate `tmux_window_index=20` desktop records and wrong desktop-to-agent matches were also observed. A visual desktop mapping cannot be inferred from a window number alone.
- Desktop amplifiers: `display-message -c <tty>` did not evaluate the requested client context for the needed tmux fields, so multiple Kitty windows could collapse to one invoking-client row. A separate branch-order defect let rows that were both tmux rows and Kitty native-session rows prefer the native path and bypass `TMUX_ATTACH_TARGET_WINDOW`. These defects affected reconstruction and placement; they did not initiate the save race. The fixes use filtered `list-clients` rows keyed by `#{client_tty}` and make an explicit tmux target authoritative. Multiple visual windows may attach to one tmux index when the manifest intentionally contains duplicate views; duplicate KWin identities are still rejected.

## Correct System Behavior

This is the target behavior after the fixes.

- `tmux.service` must save before systemd stops any `tmux-spawn-*.scope` pane scopes. The tracked prefix drop-in `tmux/.config/systemd/user/tmux-spawn-.scope.d/20-save-before-pane-stop.conf` adds `Before=tmux.service`; because stop ordering is inverse, matching pane scopes stop after `tmux.service` has run its save.
- Stop saves must require a near-complete topology before advancing recovery state. `tmux-service-stop.sh` exports `TMUX_RESURRECT_SAVE_MIN_PCT=80` so a 191-to-59 collapse is rejected.
- Layout, assistant sidecar, and desktop manifest must advance as one transaction bundle. Activation is crash-consistent, fail-closed, and repairable, but deliberately not a multi-directory atomic commit: raw files are staged and fsynced, the old desktop receipt is removed before raw replacements, each replacement and the `last` pointer is fsynced, and the receipt is committed last. An interruption therefore leaves no desktop receipt; restore refuses that state, and the next activation recopies every raw component from the immutable bundle before writing a new receipt. A restore must use one resolved last-good bundle or fail closed when transaction state exists but no valid bundle resolves.
- Desktop restore must use sidecar-backed agent identity receipts and Kitty native-session assets. Shell receipts are weaker and must not be treated as equivalent proof for agent sessions.
- Agent processes must not restart merely because a pane existed before shutdown. `tmux-agent-resume` records entries as deferred and resumes only a selected entry or an explicit short-lived automatic lease. Boot restore waits for a human client attach before applying the one-shot attended marker.
- Codex paused-goal prompts are state, not noise. Faithful resurrection should preserve the paused state and default to `Leave paused` unless a separate valid continuation lease proves unattended work should restart.
- Claude `--resume ID` must be inserted before the first standalone `--` so it remains a CLI flag rather than prompt text.
- Claude per-session config roots must be restored only through an allowlisted `CLAUDE_CONFIG_DIR` under the owner home. Secret-looking environment values must not be serialized or rendered into resume commands.
- Desktop snapshots must join Kitty windows to tmux clients through filtered `list-clients` evidence, not `display-message -c` field lookups.
- Desktop restore must treat `TMUX_ATTACH_TARGET_WINDOW` as authoritative for tmux rows even when a Kitty native-session file is present. Native sessions are for non-tmux Kitty rows or for identity evidence bundled with desktop state, not a reason to bypass the tmux target.
- A periodic saver must run from its own systemd timer, serialize with other saves, and require both an active tmux service and a completed restore. Stop-time saves must retain the stricter 80% floor.
- Assistant sidecars must pass a strict PID-bound provider/session identity gate before a transaction can advance. Cwd history or a provider name found only in another process's arguments is discovery evidence, not identity proof.
- Codex uses its supported `SessionStart` hook to record the documented session ID plus the nearest native Codex PID, its immediate recognized Node launcher PID, and each process's Linux start ticks. Nested Codex sessions must not tag an outer Codex process. Existing Codex processes that started before the hook cannot be backfilled by guessing; saves fail closed until those processes resume or restart with a receipt.
- Claude's upstream PID-named runtime receipt is accepted only when its file mtime is not older than that PID generation's `/proc` start time. The incident audit found 43 fresh receipts and two stale files whose PIDs had been reused; the old filename-and-PID check would have accepted those stale files.
- When the upstream saver records a live `setsid --wait` wrapper PID, the validator accepts it only if the wrapper owns exactly one rootmost branch for the saved provider and that descendant proves the saved session with its own PID-bound receipt. Node and its native Codex child are one branch; sibling provider branches reject as ambiguous.

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
- Implemented: transaction activation cleanup and interruption handling. The focused activation matrix passed for staging, every component boundary, and the post-`last` boundary; each failure left no temporary artifacts or desktop receipt, and a subsequent activation repaired all raw files. This is crash-consistent/fail-closed/repairable, not multi-directory atomic.
- Isolated cold-restore rehearsal passed: `test_tmux_systemd_restore_bundle.sh` restored the resolved bundle on an isolated tmux socket, ignored newer raw files, and refused corrupt initialized transaction state; the desktop transaction rehearsal also passed activation and repair checks. A real cold reboot and live KWin validation remain open.
- Verified together in the final scoped gate: desktop restore target selection, native Kitty sessions, and the SIGWINCH resend path all pass their integration tests.
- Committed as `468e446`: crash-consistent transaction activation, live-server no-op preservation, native-session path validation, interruption repair tests, and production-state isolation for the native Kitty integration test.
- Committed as `be7e162` and `e129af6`: the strict PID-bound assistant identity gate, general Codex `SessionStart` receipts, and independent periodic saver/timer. The complete scoped suite passes, including `test_codex_sessionstart_receipt.sh`, `test_tmux_periodic_save.sh`, `test_setup_tmux_periodic_save_install.sh`, and `test_tmux_assistant_identity_gate.sh`. At commit time, live installation and a real reboot remained unverified.
- Committed as `9fe58d3`: strict validation for the `setsid --wait` wrapper PIDs produced by `tmux-agent-resume`. A production dry probe passed all 17 wrapper rows and then failed closed at an older Waspflow Codex process with no pre-existing PID-bound receipt.
- Live staged deployment: Codex and tmux files are stowed, the user manager has reloaded the units, the timer is enabled but inactive, and `tmux-restore.service` is active. Starting restore against the live server left the `last` pointer and desktop activation receipt unchanged, proving the pre-activation live-pane gate in production. Hook trust, receipt migration for older Codex sessions, timer start, and a real reboot remain open.
- Still needs operational follow-up: Daisy/Pi provisioning across Node/NVM updates.

## Completion Gates

1. Keep the per-index ledger current from clean snapshot, sidecars, transcript stores, Kitty native-session files, desktop-layout archives, and Tim's direct corrections.
2. Label each evidence source by timestamp and whether it predates or follows the faulty restore.
3. For every changed window, preserve any displaced process, restore the intended session, and verify transcript content, cwd, process identity, tab title, and resize behavior.
4. Verify Kitty-window-to-virtual-desktop mappings separately from tmux index mappings.
5. Run the focused isolated tests for assistant identity, agent resume, transaction bundles, systemd restore, desktop receipts, guarded assistant save, and desktop restore SIGWINCH/native-session behavior.
6. Perform an end-to-end restore rehearsal and retain machine-readable receipts.
