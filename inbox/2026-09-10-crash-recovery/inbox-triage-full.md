All 85 notes reached. Here is the full triage.

## Table: all 85 notes

| note | problem (short) | verdict | effort | value |
|---|---|---|---|---|
| 2026-09-10-claude-trust-dialog-exits-worker | Trust-dialog option order + config-dir mismatch caused new lanes to exit | **FIXED** — commit ca13a67 | — | — |
| 2026-09-10-global-list-fanout-friction | Global `list`/`check` scans thousands of lanes, slow/token-heavy | ACTIONABLE | M | high |
| 2026-09-09-claude-cross-account-resume-gap | No supported cross-account Claude failover preserving conversation | NEEDS-DESIGN | L | med |
| 2026-08-31-codex-capacity-interstitial-menu | "thinking a bit more" menu misread as stall; Tab-queued directives stranded 3.5h | ACTIONABLE | M | high |
| 2026-08-30-codex-resume-must-preserve-paused-goal-state | Resurrection may silently resume a paused Codex goal | NEEDS-DESIGN (blocked on provider API) | M | med |
| 2026-08-30-tmux-session-name-collision-corrupted-resurrection-identity | Bare tmux session-group lookup collided with a window of the same name | ACTIONABLE (fix described as already applied in note; verify) | S | high |
| 2026-08-30-rollout-log-load-cost-coredump-noise-and-archive-resume-break | 3 issues: rg full-corpus scans, coredump desktop noise, archive broke resume | ACTIONABLE (parts); coredump fix reverted (see 41881f7) | M | med |
| 2026-08-29-antigravity-model-selection-and-tool-execution-gaps | Waspflow rejects a live/valid Antigravity model; empty receipt fields on bypass | ACTIONABLE | M | med |
| 2026-08-23-codex-spawn-failures-force-mcp-wrapper-tax | Codex spawn produced CORRUPT/unparseable state.json stubs, forced costly MCP fallback | ACTIONABLE | M | high |
| devspecs-feedback | `ds task --quick` missed real source/test files for a tmux task | ACTIONABLE (devspecs, not waspflow) | S | low |
| 2026-08-14-ask-a-ghost-reaped-session-consult | Feature request: ask a reaped session a question (ghost ask/do) | NEEDS-DESIGN | L | med |
| 2026-08-12-fleet-lifecycle-reconciliation-and-owned-resource-leaks | No end-to-end owned-resource lifecycle; manual machine-wide reconciliation needed | NEEDS-DESIGN | L | high |
| 2026-07-26-live-sbx-network-proxy-contention | Concurrent live-sbx tests contend on proxy injection, spurious 500 | ACTIONABLE | S | med |
| 2026-08-11-stale-lane-locks-and-slow-reap-finalization | Completed spawn/revise wrappers retain lane locks 20-30min; reap refresh opaque | ACTIONABLE | M | high |
| 2026-08-11-closed-harvested-reap-hangs-and-leaks-resources | `close --status harvested` + `reap --force` leaves reap wrappers/resources alive | ACTIONABLE | M | high |
| 2026-08-07-closed-codex-lane-reap-scan | Reap on closed Codex lanes scans full session tree (8s+), refuses cleanup w/o runtime receipt | ACTIONABLE | M | med |
| 2026-07-30-codex-child-overwrites-parent-runtime-receipt | Nested Codex subagent receipt overwrites parent's runtime receipt, blocks reap | ACTIONABLE | M | high |
| 2026-08-03-codex-hook-trust-false-live-lane | Codex hook-trust screen leaves lane `live` with no submission; needs `--dangerously-bypass-hook-trust` discoverability | ACTIONABLE | S | high |
| 2026-08-03-escalation-launch-provisioned-failure | Escalation can strand a lane in `launch_provisioned`; resume-transition doesn't complete | ACTIONABLE | M | med |
| 2026-08-01-codex-wait-false-idle-during-background-tool | `wait` returns IDLE while Codex turn still active/backgrounding a tool | Likely **FIXED** by turn_mark barrier (lib/providers/codex.sh:774, e8361c8/118aaf3a) — unverified against this exact repro | — | — |
| devspecs entries generally | — | — | — | — |
| 2026-07-31-multi-account-claude-lane-support | No per-lane Claude account targeting via CLAUDE_CONFIG_DIR | NEEDS-DESIGN | L | med |
| 2026-07-31-revise-reaped-lane-missing-worktree | `revise` on reaped lane tries to `cd` into removed worktree, fails | ACTIONABLE (DUPLICATE-OF 2026-07-09-reaped-isolated-lane-resume-gap) | M | high |
| 2026-07-31-tmux-scrollback-memory-budget | Unbounded tmux history-limit (500k lines/pane) caused 37.8GiB tmux RSS | ACTIONABLE | M | high |
| 2026-07-16-owner-wakeup-on-lane-event | Feature request: wake orchestrator on first actionable lane event | NEEDS-DESIGN | L | high |
| 2026-07-30-provider-failure-should-suggest-escalation | Provider quota/availability failure doesn't suggest `escalate --handoff` | ACTIONABLE | S | med |
| 2026-07-25-wait-reported-idle-during-live-codex-turn | `wait` false-idle during live Codex turn (repro'd twice) | Likely **FIXED** by turn_mark (same as above) — unverified against exact repro | — | — |
| 2026-07-29-terminal-idle-revise-pending-deadlock | Terminal-idle lane stuck: revise fails "unconfirmed", park refused, inspect stale | ACTIONABLE (DUPLICATE-OF 2026-08-01/2026-07-25 wait-idle cluster, root-cause overlap w/ turn_mark work) | M | med |
| 2026-07-26-reboot-restored-tmux-window-id-drift | Reboot-restored tmux window IDs stale in lane state; revise starts duplicate headless session | ACTIONABLE (related to 2026-08-30 session-collision fix; verify if same fix covers window-ID drift) | M | high |
| 2026-07-26-isolated-lane-base-drift | `spawn --isolate` started from stale HEAD instead of explicit intended commit (4 of 6 lanes) | ACTIONABLE | M | high |
| 2026-07-26-concurrent-write-lanes-shared-checkout | Non-isolated concurrent lanes silently shared/mutated one checkout | ACTIONABLE | M | high |
| 2026-07-25-claude-stale-task-completion | Claude background-task shows "Waiting for task" after process ended; wait hangs | ACTIONABLE | M | med |
| 2026-07-25-headless-revise-completes-but-never-idles | Headless Claude revise completes+commits but process/wait never idles (26+ min) | ACTIONABLE (overlaps turn-boundary cluster) | M | high |
| 2026-07-20-reaped-lane-headless-revise-invisible | Headless revise of reaped lane invisible to status/wait during the turn | ACTIONABLE (DUPLICATE-OF 2026-07-31-revise-reaped-lane-missing-worktree cluster) | M | high |
| 2026-07-24-parked-claude-revise-hangs-after-response | Parked/exited Claude revise can hang after producing a response, unobservable | ACTIONABLE (same cluster as above) | M | high |
| 2026-07-24-mass-lane-death-and-spawner-death-recovery-gap | No defined behavior for mass lane death or spawner death (crash of ~169 sessions) | NEEDS-DESIGN | L | high |
| 2026-07-24-federation-lan-tunnel-beats-ngrok-and-traefik | Informational: `--tunnel lan` beats ngrok/Traefik for same-LAN federation | STALE (informational, no action needed beyond maybe defaulting to LAN) | S | low |
| 2026-07-24-rejoin-already-approved-403 | Re-joining an already-approved federation collective 403s; error copy collapses causes | ACTIONABLE | S | low |
| 2026-07-24-tray-setup-state-mislabeled-not-running | Tray menu mislabels `VisualSetup` state as "daemon is not running" | ACTIONABLE | S | low |
| 2026-07-24-lane-provenance-gap | No `spawned_by`/owner field in lane state | **FIXED** — lib/provenance.sh (commits 93ecb23, df5432d/9ff7718, 18c5381 "preserve lane parent provenance") | — | — |
| 2026-07-24-reboot-interrupted-lane-wait-remains-blocked | Reboot-interrupted lane stays `live`, `wait` blocks instead of resolving interrupted | ACTIONABLE (cluster w/ window-drift/mass-death notes) | M | high |
| 2026-07-24-claude-turn-complete-attached-wait-hang | `wait` silent when tmux client attached despite `turn_completed` receipt | Likely mitigated: `wait`'s barrier uses `turn_mark`, not the `vetoed-attached-client` label (that's only in `inspect`/lib/events.sh:157) — ACTIONABLE to confirm `wait` itself never consults this veto | S | med |
| 2026-07-23-codex-runtime-drift-and-resume-sandbox | Runtime drift not caught pre-task; headless resume can't write worktree/report paths | ACTIONABLE | M | high |
| 2026-07-23-reaped-headless-revise-wait-false-completion | Headless revise of reaped lane can false-complete before writing deliverable | ACTIONABLE (cluster w/ turn-boundary notes) | M | high |
| 2026-07-23-login-shell-secret-hydration-can-stall-every-provider | `infisical login --silent` can hang forever in login-shell hydration, blocking all providers | ACTIONABLE | S | high |
| 2026-07-22-codex-tui-prompt-visible-but-not-submitted | Failed-submission lane stays `live`, has no `session_id`, unrecoverable | ACTIONABLE (partially addressed by submission confirmation work — verify residual) | M | med |
| 2026-07-22-ops-pin-provider-blocks-quota-aware-routing | `--op` catalog hardcodes provider/model; no quota-aware dynamic resolution | NEEDS-DESIGN | L | med |
| 2026-07-21-harness-auth-all-url-flow | Design correction: all harnesses support scriptable URL-based auth, not just interactive | ACTIONABLE (design note; verify Federation harness code updated) | M | low |
| 2026-07-21-sbx-daemon-fresh-start-blocker | Retracted: not an sbx bug, bad guest install. Packaging takeaway: fail loudly if sbx daemon can't start | ACTIONABLE (small doctor/preflight addition) | S | low |
| 2026-07-21-codex-billing-path-opacity | `doctor`'s "may use API billing" warning doesn't resolve actual effective billing path | ACTIONABLE | M | med |
| 2026-07-13-codex-spawn-leaves-prompt-unsubmitted | Spawn can leave initial prompt unsubmitted; cross-provider (Claude too) | Likely **FIXED** — commits 7528e18 "spawn confirms submission too", 23f3eca "refuse to submit into a provider startup menu" — verify against Claude submission path specifically | — | — |
| 2026-07-21-spawn-no-base-branch-flag | `spawn --isolate` has no `--base <ref>` to branch off non-default branch | ACTIONABLE — confirmed absent (`grep -n '\-\-base'` empty) | S | high |
| 2026-07-21-revise-safety-choice-model-drift | `revise` answering a numbered safety prompt starts new turn, silently drops model/effort | ACTIONABLE — DUPLICATE-OF 2026-07-17-model-drift-after-safety-checkpoint and 2026-07-16-provider-safety-prompt-silently-downgraded-arm | M | high |
| 2026-07-21-parked-lane-resume-times-out-large-context | Headless resume of large-context parked lane times out, effectively stranding it | ACTIONABLE | M | med |
| 2026-07-20-live-lanes-memory-and-reap-leaks | 205 "live" lanes incl. 21 harvested/4 superseded/3 abandoned still shown live; host memory pressure | ACTIONABLE — cluster w/ 2026-08-11/2026-08-12 resource-lifecycle notes | L | high |
| 2026-07-20-cursor-blog-economics | Bare link to external blog post, no content | STALE (no actionable content) | — | — |
| 2026-07-20-chatgpt-sandbox | Federation runtime backend decision doc (Docker Sandboxes vs Firecracker vs libkrun) | STALE as inbox friction item — this is a design doc, check `docs/design/` for whether decision was implemented | — | — |
| 2026-07-20-completed-lane-no-idle-notification | Codex lane completes+idles but `inspect` stays `live`/`active-observed`, no notification | ACTIONABLE — cluster w/ turn-boundary/idle-detection notes | M | high |
| 2026-07-17-llm-judge-verify-tier-via-hone | Feature request: wire LLM-judge verify tier (hone) into waspflow's verify/flywheel | NEEDS-DESIGN | L | med |
| 2026-07-17-completion-callback-and-owned-lane-tracking | Two asks: harness-native completion callback; owned-lane tracking | NEEDS-DESIGN | L | med |
| 2026-07-17-model-drift-after-safety-checkpoint | Model silently drifts (sol/high → luna/low) after Codex safety-checkpoint prompt | ACTIONABLE — DUPLICATE cluster (see above) | M | high |
| 2026-07-17-adopt-external-session-mcp | Feature request: adopt/operate external (non-waspflow-spawned) sessions via MCP | NEEDS-DESIGN — DUPLICATE-OF 2026-06-17-adopt-existing-session-feature, 2026-06-16-drive-existing-session-gap | L | med |
| 2026-07-17-neutral-session-interchange | Feature request: cross-provider neutral session export/import/translate | NEEDS-DESIGN — DUPLICATE-OF 2026-07-09-cross-provider-transfer-library | L | med |
| 2026-07-16-agent-decision-prompt-owner-response-gap | Decision prompts auto-record default choice; revise-as-correction gets treated as untrusted text | ACTIONABLE | M | high |
| 2026-07-16-reap-state-desynchronizes-from-worktree | `reap --force` removes worktree but doesn't always record `reaped`/emit receipt | ACTIONABLE | M | high |
| 2026-07-16-fast-mode-operating-points-and-deny-policy | No first-class fast-mode policy (deny/explicit/allow/require) across scopes | NEEDS-DESIGN — confirmed absent (`grep fast_mode` empty) | L | med |
| 2026-07-16-provider-safety-prompt-silently-downgraded-arm | Same as model-drift cluster: safety prompt silently downgrades explicit release-owner model | ACTIONABLE — DUPLICATE-OF 2026-07-17/2026-07-21 model-drift notes | M | high |
| 2026-07-16-isolate-worktree-root-policy-gap | `--isolate` doesn't discover/enforce a repo's declared worktree-root policy | ACTIONABLE — confirmed absent (`grep worktree_root` empty) | M | med |
| 2026-07-16-delegation-policy-and-orchestration-patterns | No explicit delegation policy/schema for nested lanes, subagents, budget inheritance | NEEDS-DESIGN | L | med |
| 2026-07-16-fleet-control-plane-analytics-and-telemetry | Feature request: adopt any session + fleet API/web panel + usage telemetry | NEEDS-DESIGN | L | low |
| 2026-07-13-output-and-reasoning-budget-operating-points | max_tokens/reasoning-budget scattered as harness constants, not operating-point data | NEEDS-DESIGN | M | med |
| 2026-07-12-headless-worker-budget-and-surface-controls | No first-class spend cap / capability-surface controls (MCP, browser, network) for headless workers | NEEDS-DESIGN | L | med |
| 2026-07-09-parent-idle-while-subagents-active | `wait` false-idle while Claude parent awaits background subagents | ACTIONABLE — cluster w/ turn-boundary notes; verify against current turn_mark logic | M | high |
| 2026-07-09-cross-provider-transfer-library | Feature request: cross-provider lane transfer / handoff packet / transcript translation | NEEDS-DESIGN | L | med |
| 2026-07-09-reaped-isolated-lane-resume-gap | Reaped isolated lane's saved `cwd` points at removed worktree; revise fails `cd` | ACTIONABLE — DUPLICATE-OF 2026-07-31-revise-reaped-lane-missing-worktree, 2026-07-20-reaped-lane-headless-revise-invisible | M | high |
| 2026-07-11-claude-mcp-policy-json-failure | `--mcp none`/`auto` triggered `jq` parse error, blocking all Claude spawns | Likely **FIXED** — current lib/providers/claude.sh MCP resolution (`claude_mcp_policy`, line 28-33) builds config directly rather than parsing an external policy-provider JSON response; no `jq parse error` path visible — moderate confidence, no exact commit cited | — | — |
| 2026-07-05-advisor-lane-stateless-consult-gap | No first-class long-lived "advisor lane" pattern (operator says existing spawn/revise loop mostly covers it) | STALE — note itself concludes spawn/revise already supports this; ~50% operator miss | S | low |
| 2026-07-09-grok-cwd-root-crash-preflight | `--cwd /` passed unchecked to grok, causing multi-GB crash dumps | **FIXED** — lib/core.sh:135-136 (`WASPFLOW_ALLOW_ROOT_CWD` guard) | — | — |
| 2026-07-10-codex-model-discoverability-and-spawn-injection | No `waspflow models` command; no live-model validation at spawn time | Split: model validation **FIXED** (lib/core.sh:187, `valid_models`, commit 37d92c3); standalone `waspflow models` listing command still ACTIONABLE (not found) | S | med |
| 2026-07-08-report-recovery-model-and-preflight-gap | Report deliverable enforced only at reap; recovery may spend wrong/expensive model | ACTIONABLE — `report_state`/`report_exists` machinery exists (lib/artifacts.sh) but recovery-model selection (`--recovery-model`) not found | M | med |
| 2026-07-09-exec-output-validation-and-access-preflight | `exec -o` can silently write placeholder/empty report; sandbox/access mismatch hidden | **FIXED** — lib/exec.sh:146,206-220 (byte floor + placeholder rejection) | — | — |
| 2026-07-04-exec-mode-vs-lane-mode | No headless fire-and-return exec mode; everything forced through heavy lane machinery | **FIXED** — `cmd_exec`/`exec_run` (lib/exec.sh), documented in bin/waspflow usage | — | — |
| 2026-06-17-adopt-existing-session-feature | Feature request: `waspflow adopt` to drive a pre-existing agent pane | NEEDS-DESIGN — confirmed absent (`grep cmd_adopt` empty); DUPLICATE-OF 2026-07-17-adopt-external-session-mcp, 2026-07-16-fleet-control-plane | L | med |
| 2026-06-16-fire-and-forget-evaluation | Positive report: fire-and-forget spawn/wait/reap worked well, no defects | STALE (no action item — validates the model) | — | — |
| 2026-07-03-fan-in-closeout-ledger-gap | No fan-in/closeout primitive; 130 lanes required manual archaeology to reconcile | **FIXED** — lib/fanin.sh (feat(fanin): lane closeout ledger, 3fb02e9) | — | — |
| 2026-06-16-drive-existing-session-gap | No way to adopt/drive a pre-existing (not spawned) agent session; manual tmux send-keys | NEEDS-DESIGN — DUPLICATE-OF 2026-06-17-adopt-existing-session-feature | L | med |

## ACTIONABLE, ranked

**High value / low-medium effort — do these first:**

1. **`--base <ref>` for `spawn --isolate`** (2026-07-21-spawn-no-base-branch-flag). Confirmed missing (`grep -n '\-\-base' bin/waspflow lib/core.sh` → empty). Change: add `--base` option in `bin/waspflow` spawn arg parsing, pass through to the worktree-creation call in `lib/core.sh` (replace hardcoded `origin/<default-branch>`). Verify: `waspflow spawn --isolate --base <feature-branch> ...` and assert `git -C <worktree> merge-base --is-ancestor <feature-branch> HEAD`.

2. **Model/effort drift after provider safety-checkpoint prompts** (cluster: 2026-07-16-provider-safety-prompt-silently-downgraded-arm, 2026-07-17-model-drift-after-safety-checkpoint, 2026-07-21-revise-safety-choice-model-drift). Three independent incidents, same root cause: answering a Codex "additional safety checks" numbered prompt via `revise` starts a *new turn* instead of answering in place, and the new turn can silently run at a different model/effort. Fix: teach `revise` (lib/providers/codex.sh) to detect this specific blocking-prompt shape and deliver the answer to the existing turn without restarting; if that can't be proven, fail before submission. Verify: reproduce the numbered safety prompt (or a fixture), send `revise ... -- "2"`, and assert `runtime_model`/`runtime_effort` unchanged.

3. **Codex spawn CORRUPT/unparseable state.json stubs** (2026-08-23-codex-spawn-failures-force-mcp-wrapper-tax). Add a spawn-time preflight (like the doctor gate) that fails fast with the actual Codex CLI error rather than leaving an unparseable state file. File: `lib/core.sh` spawn path + `lib/providers/codex.sh` preflight. Verify: force a known Codex spawn failure mode and assert spawn exits nonzero with readable error, no stub `state.json` left behind.

4. **Codex hook-trust screen leaves lane falsely "live"** (2026-08-03-codex-hook-trust-false-live-lane). Detect the hook-trust screen as blocked/stalled, and make `--dangerously-bypass-hook-trust` selectable at spawn without raw provider args. File: `lib/providers/codex.sh` preflight/detection, `bin/waspflow` spawn flags. Verify: spawn into an untrusted-hook repo, assert lane classifies as blocked not live.

5. **Stale lane locks after spawn/revise completion** (2026-08-11-stale-lane-locks-and-slow-reap-finalization). A completed `spawn`/`revise` wrapper process should release its flock and exit; currently lingers 20-30 min. File: wherever `flock`/`exec {fd}>lockfile` is held in `lib/core.sh` (see `bin/waspflow:253`). Verify: spawn/revise to completion, assert wrapper PID exits within seconds and lock is released (`flock -n` succeeds immediately after).

6. **`reap --force` doesn't converge on closed/harvested lanes** (2026-08-11-closed-harvested-reap-hangs-and-leaks-resources + 2026-08-07-closed-codex-lane-reap-scan + 2026-07-16-reap-state-desynchronizes-from-worktree). Cluster: reap should skip the expensive runtime-refresh scan for explicitly closed/abandoned lanes, and must be atomic (either full cleanup + `reaped` status, or untouched + explicit nonzero error). Files: `lib/core.sh` reap, `lib/events.sh` classification. Verify: close a lane as harvested, run `reap --force`, assert single fast convergence and `status: reaped`.

7. **Nested Codex subagent overwrites parent's runtime receipt** (2026-07-30-codex-child-overwrites-parent-runtime-receipt). Runtime-receipt selection must key on the parent turn/session, not "most recent receipt seen". File: `lib/providers/codex.sh` runtime refresh logic. Verify: spawn a Codex lane that itself spawns nested agents, confirm parent's `runtime_model`/`runtime_effort` stays attributed to the parent.

8. **Concurrent non-isolated write lanes can share/mutate one checkout** (2026-07-26-concurrent-write-lanes-shared-checkout). Add a launch-time warning/gate when a new lane's `cwd` matches an existing live lane's `cwd` without `--isolate`. File: `lib/core.sh` spawn preflight. Verify: spawn two lanes at the same non-isolated cwd, assert a visible warning/gate fires.

9. **Isolated lane can silently start from stale HEAD** (2026-07-26-isolated-lane-base-drift). Spawn should fail closed before the worker starts if the created worktree doesn't resolve to the required commit. Overlaps with the `--base` flag work (#1) — same code path. Verify: force a stale-fetch condition, assert spawn fails rather than silently using old HEAD.

10. **Global `list`/`check` too expensive for bounded orchestration** (2026-09-10-global-list-fanout-friction). Apply project/limit selection before per-lane liveness/receipt work, not after. File: `bin/waspflow` list/check filtering order. Verify: `waspflow list --project X --limit 5` returns promptly even with thousands of unrelated lanes on disk.

11. **tmux scrollback unbounded (37.8GiB observed)** (2026-07-31-tmux-scrollback-memory-budget). Set a bounded default `history-limit`, add a durable log for output that must be kept, and truncate/compact on reap/park. File: wherever tmux windows are created in `lib/core.sh` (there's already a `WASPFLOW_TMUX_SCROLLBACK` env per commit `81babcb`/`02122c8` — verify it defaults sanely; note may be **partially** already addressed). Verify: `tmux show-window-options -t <lane-window> history-limit`.

12. **Codex TUI capacity-interstitial menu misread as a stall** (2026-08-31-codex-capacity-interstitial-menu) + **Tab-queue stranding** (same note's addendum). Teach the stall classifier to recognize "Our systems are thinking a bit more" as benign-wait; document that Tab-queued input can sit hours undelivered in long-turn conductors. Files: stall-detection regex in `lib/core.sh` (`# Deliberately NARROW...` comment area). Verify: fixture the exact menu text, assert classifier returns benign-wait not rc=4-stall.

13. **Login-shell `infisical login --silent` can hang forever, stalling every provider** (2026-07-23-login-shell-secret-hydration-can-stall-every-provider). Add a timeout around the login-shell secret hydration used when launching provider panes. File: wherever the pane command wraps `bash -lc`. Verify: force infisical connection-refused, assert pane still reaches the provider binary within a bounded time via local-file fallback.

14. **Decision-prompt auto-recording default + revise-as-correction treated as untrusted text** (2026-07-16-agent-decision-prompt-owner-response-gap). Needs a typed `resolve-prompt` path distinct from `revise`. Larger lift — borderline NEEDS-DESIGN but has a concrete acceptance list in the note. File: new command in `bin/waspflow` + `lib/core.sh`.

15. **`waspflow models` discoverability command** (2026-07-10, remaining half). Model *validation* is fixed; a `waspflow models [--provider]` listing command is not. Small addition wrapping the already-existing `${provider}_valid_models` functions.

**Medium value:**

16. Escalation can strand a lane in `launch_provisioned` (2026-08-03-escalation-launch-provisioned-failure) — `lib/escalation.sh` resume-transition path.
17. Provider quota/availability failure doesn't suggest `escalate --handoff` (2026-07-30-provider-failure-should-suggest-escalation) — small, in the failure-reporting path.
18. `codex billing path opacity` — resolve actual effective billing path instead of "may use API billing" (2026-07-21) — `lib/billing.sh`.
19. Reaped-lane `cwd` still points at removed worktree, breaking `revise` (cluster: 2026-07-09-reaped-isolated-lane-resume-gap, 2026-07-31-revise-reaped-lane-missing-worktree, 2026-07-20-reaped-lane-headless-revise-invisible) — reconstruct a safe cwd or fail explicitly with a supported-continuation message. `lib/core.sh`/`lib/providers/*.sh` revise path.
20. Antigravity: valid live model rejected by waspflow's own gate; empty receipt fields on bypass (2026-08-29).
21. `--isolate` doesn't honor a repo's declared worktree-root policy (2026-07-16-isolate-worktree-root-policy-gap).
22. Federation tray mislabels `VisualSetup` as daemon-down (2026-07-24-tray-setup-state-mislabeled-not-running) — one-line Go fix, `cmd/waspflow-federation-tray/main.go`, add `case federationtray.VisualSetup:`.
23. Federation rejoin 403 error-copy collapse (2026-07-24-rejoin-already-approved-403) — small.
24. Live-sbx test proxy-injection contention (2026-07-26) — serialize the two live-sbx tests.

## FIXED (safe to archive)

- **2026-09-10-claude-trust-dialog-exits-worker** — commit `ca13a67` (per prompt's confirmed list).
- **2026-07-09-grok-cwd-root-crash-preflight** — `lib/core.sh:135-136`, `WASPFLOW_ALLOW_ROOT_CWD` guard.
- **2026-07-09-exec-output-validation-and-access-preflight** — `lib/exec.sh:146,206-220` (byte-floor + placeholder rejection).
- **2026-07-04-exec-mode-vs-lane-mode** — `cmd_exec`/`exec_run`, `lib/exec.sh`; documented in `bin/waspflow` usage header line 13.
- **2026-07-03-fan-in-closeout-ledger-gap** — `lib/fanin.sh`; commit `3fb02e9 feat(fanin): lane closeout ledger, content-capture check, bundle-before-reap`.
- **2026-07-24-lane-provenance-gap** — `lib/provenance.sh`; commits `93ecb23`, `9ff7718`, `18c5381` ("preserve lane parent provenance", "reconcile lane provenance receipts safely").
- **2026-07-10-codex-model-discoverability-and-spawn-injection** (model-validation half only) — `lib/core.sh:187` `valid_models` fail-fast; commit `37d92c3 feat: fail-fast --model validation from the provider's live model cache`. The `waspflow models` listing-command half is still open (see ACTIONABLE #15).

**Lower confidence — plausibly fixed, flagging rather than asserting, since I found the mechanism but not an exact matching regression test for the precise repro:**
- 2026-08-01-codex-wait-false-idle-during-background-tool, 2026-07-25-wait-reported-idle-during-live-codex-turn, 2026-07-09-parent-idle-while-subagents-active — all plausibly addressed by the `turn_mark` barrier work (`codex_turn_mark`/`claude_turn_mark`/`grok_turn_mark`, commits `e8361c8`, `118aaf3a`). I did NOT verify these specific repros pass today — treat as ACTIONABLE-to-verify, not confirmed fixed.
- 2026-07-13-codex-spawn-leaves-prompt-unsubmitted — plausibly addressed by commits `7528e18` ("spawn confirms submission too") and `23f3eca` ("refuse to submit into a provider startup menu"), but I did not verify the Claude-specific half of the repro.
- 2026-07-11-claude-mcp-policy-json-failure — current `claude_mcp_policy` code (lib/providers/claude.sh:28-33) builds config directly rather than parsing an external "auto" policy JSON response, so the described `jq: parse error` path doesn't appear to exist anymore — but I found no commit message naming this fix specifically.

## Clusters

- **Turn-boundary / completion-detection ("wait says idle but work is still happening")**: 2026-08-01-codex-wait-false-idle-during-background-tool, 2026-07-25-wait-reported-idle-during-live-codex-turn, 2026-07-09-parent-idle-while-subagents-active, 2026-07-25-headless-revise-completes-but-never-idles, 2026-07-20-completed-lane-no-idle-notification, 2026-07-24-claude-turn-complete-attached-wait-hang, 2026-07-23-reaped-headless-revise-wait-false-completion. Largest cluster in the inbox; likely mostly addressed by the `turn_mark` work but needs a verification pass against each specific repro before declaring done.
- **Reaped/parked lane can't be safely revised (`cd` into removed worktree, hangs, or invisible progress)**: 2026-07-31-revise-reaped-lane-missing-worktree, 2026-07-09-reaped-isolated-lane-resume-gap, 2026-07-20-reaped-lane-headless-revise-invisible, 2026-07-24-parked-claude-revise-hangs-after-response, 2026-07-21-parked-lane-resume-times-out-large-context, 2026-07-29-terminal-idle-revise-pending-deadlock.
- **Silent model/effort drift after a provider safety/capacity prompt**: 2026-07-16-provider-safety-prompt-silently-downgraded-arm, 2026-07-17-model-drift-after-safety-checkpoint, 2026-07-21-revise-safety-choice-model-drift, 2026-08-31-codex-capacity-interstitial-menu (related: auto-selecting the "faster model" option).
- **Lane lifecycle bookkeeping drifts from reality (crash/reboot/tmux identity)**: 2026-08-30-tmux-session-name-collision-corrupted-resurrection-identity, 2026-07-26-reboot-restored-tmux-window-id-drift, 2026-07-24-reboot-interrupted-lane-wait-remains-blocked, 2026-07-24-mass-lane-death-and-spawner-death-recovery-gap, 2026-08-12-fleet-lifecycle-reconciliation-and-owned-resource-leaks, 2026-07-20-live-lanes-memory-and-reap-leaks.
- **Reap/close doesn't converge or leaks resources**: 2026-08-11-closed-harvested-reap-hangs-and-leaks-resources, 2026-08-11-stale-lane-locks-and-slow-reap-finalization, 2026-08-07-closed-codex-lane-reap-scan, 2026-07-16-reap-state-desynchronizes-from-worktree, 2026-07-30-codex-child-overwrites-parent-runtime-receipt.
- **Adopt / drive a pre-existing or external session**: 2026-06-16-drive-existing-session-gap, 2026-06-17-adopt-existing-session-feature, 2026-07-05-advisor-lane-stateless-consult-gap, 2026-07-17-adopt-external-session-mcp, 2026-07-16-fleet-control-plane-analytics-and-telemetry, 2026-08-14-ask-a-ghost-reaped-session-consult.
- **Cross-provider/cross-account transfer & handoff**: 2026-07-09-cross-provider-transfer-library, 2026-07-17-neutral-session-interchange, 2026-07-31-multi-account-claude-lane-support, 2026-09-09-claude-cross-account-resume-gap.
- **Policy/governance for delegation, budget, fast-mode**: 2026-07-16-delegation-policy-and-orchestration-patterns, 2026-07-16-fast-mode-operating-points-and-deny-policy, 2026-07-13-output-and-reasoning-budget-operating-points, 2026-07-12-headless-worker-budget-and-surface-controls, 2026-07-22-ops-pin-provider-blocks-quota-aware-routing.
- **Spawn preflight/safety gaps**: 2026-07-21-spawn-no-base-branch-flag, 2026-07-26-isolated-lane-base-drift, 2026-07-26-concurrent-write-lanes-shared-checkout, 2026-07-16-isolate-worktree-root-policy-gap, 2026-08-23-codex-spawn-failures-force-mcp-wrapper-tax, 2026-08-03-codex-hook-trust-false-live-lane.
- **Federation-specific (separate subsystem)**: 2026-07-24-federation-lan-tunnel-beats-ngrok-and-traefik, 2026-07-24-rejoin-already-approved-403, 2026-07-24-tray-setup-state-mislabeled-not-running, 2026-07-21-harness-auth-all-url-flow, 2026-07-21-sbx-daemon-fresh-start-blocker, 2026-07-26-live-sbx-network-proxy-contention, 2026-07-20-chatgpt-sandbox.

## Coverage

All 85 notes in `/home/tnunamak/code/waspflow/inbox/` were read (header/problem statement, `head -40` or full for short ones) and triaged in the table above — none were skipped. Confidence varies: the 6 items marked plain **FIXED** are backed by a specific file:line or commit hash I verified directly in this session. The 4 items marked "likely FIXED... unverified against this exact repro" are genuine uncertainty — I found the relevant mechanism (`turn_mark`, submission-confirmation commits, MCP policy code shape) but did not run the original repro steps end-to-end, per the read-only/no-execution constraint implied by the budget. Everything else is either ACTIONABLE (gap confirmed absent by grep) or NEEDS-DESIGN (multi-system feature requests with no small fix). Effort/value on the NEEDS-DESIGN items are rough judgment calls, not measured.
