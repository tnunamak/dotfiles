#!/usr/bin/env bash
# Outside-container orchestrator. Builds image (if needed), runs a scenario,
# simulates a "reboot" by stopping and starting the container, then asserts.
#
# Usage:
#   ./run.sh [--rebuild] [--keep] [--scripts-dir DIR] [--scenario NAME]
#
#   --rebuild         Force docker image rebuild
#   --keep            Don't auto-remove the container after run (debugging)
#   --scripts-dir D   Bind-mount D as the source of tmux scripts. Lets us
#                     swap in old/new versions of the fixed scripts. Default:
#                     the dotfiles repo (current/fixed scripts).
#   --scenario N      Which scenario to run (default: dangling-symlink)
set -euo pipefail

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(cd "$SELF_DIR/../../.." && pwd)"
IMAGE_TAG="tmux-restore-test:latest"
CONTAINER_NAME="tmux-restore-test"

REBUILD=0
KEEP=0
SCRIPTS_DIR=""
SCENARIO="dangling-symlink"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rebuild) REBUILD=1; shift ;;
    --keep) KEEP=1; shift ;;
    --scripts-dir) SCRIPTS_DIR="$2"; shift 2 ;;
    --scenario) SCENARIO="$2"; shift 2 ;;
    -h|--help) sed -n '2,/^set -euo pipefail/p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) echo "unknown arg: $1"; exit 1 ;;
  esac
done

cd "$SELF_DIR"

# Build image if missing or --rebuild
if (( REBUILD )) || ! docker image inspect "$IMAGE_TAG" >/dev/null 2>&1; then
  echo ">>> building image"
  docker build -t "$IMAGE_TAG" .
fi

# Tear down any leftover container
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo ">>> removing leftover container"
  docker rm -f "$CONTAINER_NAME" >/dev/null
fi

# Bind-mount: dotfiles repo. If --scripts-dir was passed, also bind-mount
# OVER the tmux scripts dir so the container sees a different version.
DOTFILES_MOUNT=(-v "$DOTFILES_DIR:/workspace:ro")
SCRIPT_OVERRIDE_MOUNT=()
if [[ -n "$SCRIPTS_DIR" ]]; then
  abs_scripts_dir="$(cd "$SCRIPTS_DIR" && pwd)"
  SCRIPT_OVERRIDE_MOUNT=(-v "$abs_scripts_dir:/workspace/tmux/.config/tmux/scripts:ro")
  echo ">>> overriding tmux scripts with: $abs_scripts_dir"
fi

cleanup() {
  if (( ! KEEP )); then
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
  else
    echo ">>> --keep: container '$CONTAINER_NAME' left running for inspection"
    echo "    docker exec -it -u tester -e XDG_RUNTIME_DIR=/run/user/1000 $CONTAINER_NAME zsh"
  fi
}
trap cleanup EXIT

# Helper: docker exec as the test user with XDG_RUNTIME_DIR set so
# `systemctl --user` works.
user_exec() {
  docker exec -u tester \
    -e XDG_RUNTIME_DIR=/run/user/1000 \
    -e DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
    -e HOME=/home/tester \
    "$@"
}

# Bring up the per-user systemd manager. With linger enabled this runs
# automatically, but we may need to wait for it.
wait_for_user_systemd() {
  local last_state=""
  for _ in $(seq 1 60); do
    last_state=$(user_exec "$CONTAINER_NAME" systemctl --user is-system-running 2>/dev/null || true)
    case "$last_state" in
      running|degraded|starting) return 0 ;;
    esac
    sleep 0.5
  done
  echo "WARN: user systemd settled at state: $last_state (continuing anyway)"
  return 0
}

# --- Phase 1: start container, install dotfiles, populate state, "crash" ---
echo ""
echo ">>> phase 1: start container ($SCENARIO)"
docker run -d \
  --name "$CONTAINER_NAME" \
  --privileged \
  --cgroupns=host \
  --tmpfs /tmp \
  --tmpfs /run \
  --tmpfs /run/lock \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  "${DOTFILES_MOUNT[@]}" \
  "${SCRIPT_OVERRIDE_MOUNT[@]}" \
  "$IMAGE_TAG" >/dev/null

# Wait for system systemd to be ready
for _ in $(seq 1 30); do
  if docker exec "$CONTAINER_NAME" systemctl is-system-running 2>/dev/null | grep -qE "running|degraded"; then
    break
  fi
  sleep 0.5
done

# Enable linger for the test user (needs running logind) so user@1000.service
# starts automatically and survives shell exits. Required for systemctl --user
# to work via `docker exec`.
docker exec "$CONTAINER_NAME" loginctl enable-linger tester
sleep 1
wait_for_user_systemd

echo ">>> install dotfiles"
# INSTALL_VARS lets a scenario tweak install-dotfiles.sh (e.g., disable
# patches to prove the bug exists in upstream).
INSTALL_VARS=()
case "$SCENARIO" in
  assistant-grouped-naming-unpatched)
    INSTALL_VARS+=(-e PATCH_PLUGIN=0) ;;
  assistant-empty-group-race-unpatched)
    INSTALL_VARS+=(-e PATCH_PLUGIN=0) ;;
esac
user_exec "${INSTALL_VARS[@]}" "$CONTAINER_NAME" bash /opt/harness/install-dotfiles.sh

echo ">>> start tmux.service"
user_exec "$CONTAINER_NAME" systemctl --user start tmux.service
user_exec "$CONTAINER_NAME" systemctl --user status tmux.service --no-pager | head -10 || true

echo ">>> populate state and simulate crash (scenario=$SCENARIO)"
# Each scenario maps to a set of env vars consumed by populate-state.sh.
SCENARIO_VARS=(-e SCENARIO="$SCENARIO" -e WINDOW_COUNT=8)
# DOUBLE_CRASH=1 triggers a second populate+reboot cycle after the first.
DOUBLE_CRASH=0
# SECOND_SERVICE_RESTART=1: after first-boot restore succeeds, do a
# `systemctl restart tmux.service` inside the container (no full reboot) and
# run assert-restored.sh a second time. Reproduces the production bug where
# the second tmux-restore.service invocation exits 1 while sessions are live.
SECOND_SERVICE_RESTART=0
# EXPECTED_ASSISTANTS=N tells the assertion script to also verify N assistant
# sessions in the JSON and that they restored cleanly. 0 = skip checks.
EXPECTED_ASSISTANTS=0
CHECK_PATCH_PRESENT=0
CHECK_CAPTURE_SKIP=0
CHECK_DOUBLE_SAVE=0
CHECK_KEEP_LAST=0
CHECK_EMPTY_LAST_FALLBACK=0
CHECK_ZERO_CLIENT=0
CHECK_ATTENDED_RESTORE=0
case "$SCENARIO" in
  pane-capture-skip)
    # Validates Patch 3: assistant panes are skipped when tmux-resurrect captures
    # pane contents. 4 windows: 0,1 run claude stubs (assistant), 2,3 plain shells.
    # GROUPED_CLONES=20 mirrors the user's real environment (hundreds of grouped
    # session clones), where each pane's pid appears under many addresses
    # (main:0.0, main-0:0.0, ... main-19:0.0). This is the discriminating setup:
    # the original newline-delimited skip set silently captured EVERY clone of
    # each assistant pane (the space-glob never matched newline-separated pids);
    # the fix (newline→space normalization) skips them all. A single-session
    # scenario would NOT catch that bug.
    # populate seeds scrollback + runs a capture save + stages the archive;
    # assert verifies NO assistant content (any clone) is captured, plain content
    # IS, and no /tmp leak. no-crash (DELETE_LIVE_LAST=0) — only the save matters.
    SCENARIO_VARS+=(-e WINDOW_COUNT=4 -e SAVES_BEFORE=1 -e DELETE_LIVE_LAST=0 \
                    -e LAUNCH_ASSISTANTS=2 -e GROUPED_CLONES=20 -e CAPTURE_SKIP_TEST=1)
    CHECK_CAPTURE_SKIP=1 ;;
  dangling-symlink)
    # Baseline: 4 saves, then delete the live copy of the most recent.
    # backups/ + best.txt remain, so OLD scripts can recover via best.txt.
    SCENARIO_VARS+=(-e SAVES_BEFORE=4 -e DELETE_LIVE_LAST=1) ;;
  dangling-no-best)
    # Same as above but delete best.txt so OLD scripts must fall back to
    # the live dir's `find`. ADD_OLD_SAVES inflates the save count enough
    # to reliably trigger the OLD pipeline's SIGPIPE-on-sort bug.
    SCENARIO_VARS+=(-e SAVES_BEFORE=4 -e DELETE_LIVE_LAST=1 -e DELETE_BEST=1 -e ADD_OLD_SAVES=2000) ;;
  no-backups-dir)
    # Live dir has saves; backups/ is gone entirely. NEW scripts handle
    # via direct fallback to live; OLD scripts may or may not.
    SCENARIO_VARS+=(-e SAVES_BEFORE=4 -e DELETE_LIVE_LAST=1 -e DELETE_BACKUPS=1) ;;
  cliff-shrink)
    # The compounding-damage scenario: 4 large saves, then 2 tiny saves
    # (mimics post-boot empty state). With NEW post-save-backup, the cliff
    # guard rewrites the new save's content to keep the prior good state.
    # With OLD post-save-backup, the empty state propagates.
    SCENARIO_VARS+=(-e SAVES_BEFORE=4 -e SHRINK_TO=1 -e SAVES_AFTER=2 -e DELETE_LIVE_LAST=0) ;;
  no-crash)
    # Sanity: no crash, just reboot. Should restore cleanly.
    SCENARIO_VARS+=(-e SAVES_BEFORE=4 -e DELETE_LIVE_LAST=0) ;;
  empty-last-fallback)
    # Regression for the externally-killed tmux server outage:
    # 1. Kill the server, run the ExecStop wrapper against the dead socket, and
    #    assert it preserves the previous good `last` instead of writing empty.
    # 2. Then synthesize a valid 0-pane `last` with only backups holding the
    #    good save, so systemd-restore.sh must use its best-candidate fallback.
    SCENARIO_VARS+=(-e SAVES_BEFORE=4 -e DELETE_LIVE_LAST=0)
    CHECK_EMPTY_LAST_FALLBACK=1 ;;
  double-save-race)
    # Runs two save.sh instances concurrently. The save.sh flock patch should
    # let one writer complete and make the duplicate return 0 without touching
    # the same timestamped file.
    SCENARIO_VARS+=(-e SAVES_BEFORE=0 -e DELETE_LIVE_LAST=0 -e CONCURRENT_SAVE_TEST=1)
    CHECK_DOUBLE_SAVE=1 ;;
  keep-last-clone-reaping)
    # Validates the tmux native destroy-unattached=keep-last path for fresh
    # grouped main-N clones: detach storms destroy only clientless clones, seed
    # main survives, follow-up attaches still work, and restore-created grouped
    # sessions survive until post-restore-grouped-focus.sh consumes them.
    SCENARIO_VARS+=(-e SAVES_BEFORE=0 -e DELETE_LIVE_LAST=0 -e KEEP_LAST_TEST=1)
    CHECK_KEEP_LAST=1 ;;
  empty-live-dir)
    # Live dir gets only the most recent save; we delete it. Tests fallback
    # to backups/ when live dir has nothing to find.
    SCENARIO_VARS+=(-e SAVES_BEFORE=1 -e DELETE_LIVE_LAST=1) ;;
  many-old-saves-good-best)
    # Long-running system: 1500+ accumulated old saves. best.txt IS preserved.
    # Tests whether OLD systemd-restore.sh's SIGPIPE-on-sort bug fires before
    # the script ever gets to the best.txt fallback. NEW uses mapfile + a
    # pure-bash loop, so SIGPIPE never reaches the script.
    SCENARIO_VARS+=(-e SAVES_BEFORE=4 -e DELETE_LIVE_LAST=1 -e ADD_OLD_SAVES=2000) ;;
  prev-target-only-in-backups)
    # The exact original incident: the prev-target file is gone from live but
    # PRESENT in backups/. NEW systemd-restore.sh searches BOTH live and
    # backups/. OLD only searches live and falls back to best.txt — with
    # best.txt also gone, OLD has no path to the good save in backups/.
    SCENARIO_VARS+=(-e SAVES_BEFORE=4 -e DELETE_LIVE_LAST=1 -e DELETE_LIVE_ALL=1 -e DELETE_BEST=1) ;;
  double-crash)
    # Two power losses in a row. First crash deletes live last; reboot
    # restores. Second populate shrinks to 1 window and saves (cliff guard
    # must reject); second crash deletes live last; reboot must still see
    # the original 8-window state. Tests that NEW cliff guard prevents the
    # restored-then-shrunken state from burying the good save.
    SCENARIO_VARS+=(-e SAVES_BEFORE=4 -e DELETE_LIVE_LAST=1)
    DOUBLE_CRASH=1 ;;
  assistant-grouped-naming)
    # Validates the grouped-session canonicalization patch in
    # tmux-assistant-resurrect's save script. Launches 3 fake claude stubs
    # and creates 2 grouped clones (mimics kitty's tmux-local-attach-main).
    # With the PATCHED plugin (default), the JSON saves pane addresses as
    # 'main:N.0'. Without the patch, panes are saved as 'main-N:N.0' and
    # restore-time lookup of 'main-N' fails, yielding "restored 0 of N".
    SCENARIO_VARS+=(-e SAVES_BEFORE=2 -e DELETE_LIVE_LAST=0 -e LAUNCH_ASSISTANTS=3 -e GROUPED_CLONES=2)
    EXPECTED_ASSISTANTS=3 ;;
  cold-boot-zero-client)
    # Regression for AR-Patch7: no tmux client is attached anywhere during
    # the restore. The server-wide fallback must wait only once, then replay
    # all assistants rather than aborting on "no current client".
    SCENARIO_VARS+=(-e SAVES_BEFORE=2 -e DELETE_LIVE_LAST=0 -e LAUNCH_ASSISTANTS=3 -e GROUPED_CLONES=2)
    CHECK_ZERO_CLIENT=1
    CHECK_ATTENDED_RESTORE=1
    EXPECTED_WINDOWS=5 ;;
  assistant-grouped-naming-unpatched)
    # Same as assistant-grouped-naming but with PATCH_PLUGIN=0 set in
    # INSTALL_VARS. Proves the bug exists in vanilla upstream — assertion
    # checks the JSON contains 'main-N:' addresses and the restore log
    # shows "restored 0 of N". Used to validate the discriminator works
    # regardless of which version of systemd-restore.sh / post-save-backup
    # is in play (those are orthogonal to this bug).
    SCENARIO_VARS+=(-e SAVES_BEFORE=2 -e DELETE_LIVE_LAST=0 -e LAUNCH_ASSISTANTS=3 -e GROUPED_CLONES=2)
    EXPECTED_ASSISTANTS=3 ;;
  assistant-tpm-wipe-recovery)
    # The "TPM auto-update wiped the patch" durability scenario. Setup:
    #   1. Install + patch the plugin normally
    #   2. Launch assistants, populate, save (good addresses go into JSON)
    #   3. Revert the plugin via `git checkout` (mimics TPM auto-update)
    #   4. Reboot
    # tmux-restore.service's ExecStartPre re-applies the patch before any
    # new save fires, so the post-reboot state should still resolve cleanly.
    # Validates the durability mechanism, not just the patch itself —
    # CHECK_PATCH_PRESENT=1 also triggers a post-restore save and verifies
    # IT produces canonical addresses.
    SCENARIO_VARS+=(-e SAVES_BEFORE=2 -e DELETE_LIVE_LAST=0 -e LAUNCH_ASSISTANTS=3 -e GROUPED_CLONES=2 -e UNPATCH_PLUGIN_AFTER_SAVE=1)
    EXPECTED_ASSISTANTS=3
    CHECK_PATCH_PRESENT=1 ;;
  assistant-empty-group-race)
    # Incident 2026-06-08. Upstream PR #30 upstreamed the 2a/2b canonicalization,
    # but it trusts #{session_group} alone. When that query returns EMPTY while a
    # pane is still listed under a grouped clone (main-N) — the clone being torn
    # down mid-save, display-message erroring, swallowed by `|| true` — the pane
    # is saved verbatim as 'main-N:' and the next boot restores 0 of N.
    # FORCE_EMPTY_SESSION_GROUP=1 deterministically reproduces that race via a
    # tmux shim. With the PATCHED plugin (Patch 2c suffix-strip fallback), the
    # save must STILL produce canonical 'main:' addresses. This is the
    # discriminator the pre-existing assistant-grouped-naming scenario missed —
    # that one only exercised the happy path where #{session_group} resolves.
    SCENARIO_VARS+=(-e SAVES_BEFORE=2 -e DELETE_LIVE_LAST=0 -e LAUNCH_ASSISTANTS=3 -e GROUPED_CLONES=2 -e FORCE_EMPTY_SESSION_GROUP=1)
    EXPECTED_ASSISTANTS=3 ;;
  assistant-empty-group-race-unpatched)
    # Negative control: same empty-#{session_group} race, but PATCH_PLUGIN=0 so
    # only vanilla upstream canonicalization runs (no Patch 2c). The save MUST
    # produce 'main-N:' addresses and the restore MUST log "restored 0 of N",
    # proving the bug is real and that Patch 2c is what fixes it. If this
    # scenario ever PASSES, the discriminator is broken (false confidence).
    SCENARIO_VARS+=(-e SAVES_BEFORE=2 -e DELETE_LIVE_LAST=0 -e LAUNCH_ASSISTANTS=3 -e GROUPED_CLONES=2 -e FORCE_EMPTY_SESSION_GROUP=1)
    EXPECTED_ASSISTANTS=3 ;;
  second-boot-restore-failure)
    # Reproduces a production bug: after a successful first-boot restore,
    # a forced `systemctl restart tmux.service` (second run of tmux-restore.service)
    # exits 1 with only "systemd-restore.sh invoked" in the log — nothing after,
    # not even a "state:" line. The service ran ~8s matching the 20×0.5s wait
    # loop, suggesting the tmux server was not responding after the service restart.
    #
    # `systemctl restart tmux.service` kills the server; the new server starts
    # empty. Correct behavior: second run sees 1 pane (fresh server), detects the
    # valid save, and runs restore again — exiting 0 with "restore complete".
    SCENARIO_VARS+=(-e SAVES_BEFORE=3 -e DELETE_LIVE_LAST=1)
    SECOND_SERVICE_RESTART=1 ;;
  *)
    echo "WARN: unknown scenario '$SCENARIO', using defaults"
    SCENARIO_VARS+=(-e SAVES_BEFORE=4 -e DELETE_LIVE_LAST=1) ;;
esac
user_exec "${SCENARIO_VARS[@]}" "$CONTAINER_NAME" bash /opt/harness/populate-state.sh

if (( CHECK_EMPTY_LAST_FALLBACK )); then
  echo ">>> empty-last-fallback: kill tmux, run stop wrapper, then synthesize empty last"
  user_exec "$CONTAINER_NAME" bash -lc '
    set -euo pipefail
    RESURRECT_DIR="$HOME/.tmux/resurrect"
    SUMMARY="$RESURRECT_DIR/empty-last-fallback-summary"
    STOP_SCRIPT="$HOME/.config/tmux/scripts/tmux-service-stop.sh"

    before_target="$(readlink "$RESURRECT_DIR/last" 2>/dev/null || echo MISSING)"
    before_panes="$(grep -c "^pane" "$RESURRECT_DIR/last" 2>/dev/null || true)"
    [[ "$before_panes" =~ ^[0-9]+$ ]] || before_panes=0

    tmux kill-server 2>/dev/null || true
    bash "$STOP_SCRIPT" >/tmp/empty-last-stop-wrapper.log 2>&1 || true
    systemctl --user stop tmux.service 2>/dev/null || true
    sleep 1

    after_target="$(readlink "$RESURRECT_DIR/last" 2>/dev/null || echo MISSING)"
    after_panes="$(grep -c "^pane" "$RESURRECT_DIR/last" 2>/dev/null || true)"
    [[ "$after_panes" =~ ^[0-9]+$ ]] || after_panes=0
    dead_skip_logged=0
    if grep -q "skipping tmux-resurrect save because tmux server is not responsive" /tmp/empty-last-stop-wrapper.log; then
      dead_skip_logged=1
    fi
    empty_saves_after_stop=0
    while IFS= read -r -d "" save_file; do
      panes="$(grep -c "^pane" "$save_file" 2>/dev/null || true)"
      [[ "$panes" =~ ^[0-9]+$ ]] || panes=0
      if (( panes == 0 )); then
        empty_saves_after_stop=$((empty_saves_after_stop + 1))
      fi
    done < <(find "$RESURRECT_DIR" -maxdepth 1 -type f -name "tmux_resurrect_*.txt" -print0)

    good_backup=""
    while IFS=$'"'"'\t'"'"' read -r _ path; do
      [[ -n "$path" ]] || continue
      panes="$(grep -c "^pane" "$path" 2>/dev/null || true)"
      [[ "$panes" =~ ^[0-9]+$ ]] || panes=0
      if (( panes >= 3 )); then
        good_backup="$path"
        break
      fi
    done < <(find "$RESURRECT_DIR/backups" -maxdepth 1 -type f -name "tmux_resurrect_*.txt" -printf "%T@\t%p\n" 2>/dev/null | sort -rn)

    if [[ -z "$good_backup" ]]; then
      echo "no good backup save found" >&2
      exit 1
    fi

    rm -f "$RESURRECT_DIR"/tmux_resurrect_*.txt
    empty_name="tmux_resurrect_20990101T000000.txt"
    : > "$RESURRECT_DIR/$empty_name"
    ln -sfn "$empty_name" "$RESURRECT_DIR/last"

    {
      printf "before_target=%q\n" "$before_target"
      printf "before_panes=%s\n" "$before_panes"
      printf "after_target=%q\n" "$after_target"
      printf "after_panes=%s\n" "$after_panes"
      printf "dead_skip_logged=%s\n" "$dead_skip_logged"
      printf "empty_saves_after_stop=%s\n" "$empty_saves_after_stop"
      printf "good_backup=%q\n" "$good_backup"
      printf "synthesized_empty_last=%q\n" "$empty_name"
    } > "$SUMMARY"
    cat "$SUMMARY" | sed "s/^/[empty-last-fallback]   /"
  '
fi

# --- Phase 2: "reboot" by restarting the container ---
echo ""
echo ">>> phase 2: simulating reboot (stop + start container)"
# `docker stop` sends SIGTERM. systemd treats this as a clean shutdown which
# would let tmux save its state and ruin the simulation. We want abrupt
# termination — SIGKILL on PID 1 — to truly mimic power loss.
docker kill --signal=SIGKILL "$CONTAINER_NAME" >/dev/null
docker start "$CONTAINER_NAME" >/dev/null

# Wait for system systemd to be ready again
for _ in $(seq 1 30); do
  if docker exec "$CONTAINER_NAME" systemctl is-system-running 2>/dev/null | grep -qE "running|degraded"; then
    break
  fi
  sleep 0.5
done

# Wait for the user manager (linger should keep it auto-started)
wait_for_user_systemd

# tmux.service is enabled but it may not be auto-started by user@.service
# without a Wants= from default.target. Make sure it's running.
user_exec "$CONTAINER_NAME" systemctl --user start tmux.service tmux-restore.service || true

# Give tmux-restore.service time to run (it has internal waits)
sleep 6

if (( CHECK_ATTENDED_RESTORE )); then
  echo ">>> cold-boot-zero-client: record inert state before first human attach"
  user_exec "$CONTAINER_NAME" bash -lc '
    set -euo pipefail
    state="$HOME/.local/state/tmux-agent-resume"
    selected_resume_lines=0
    if [[ -f "$HOME/.tmux/resurrect/agent-resume.log" ]]; then
      selected_resume_lines="$(grep -c " selected resume " "$HOME/.tmux/resurrect/agent-resume.log" || true)"
    fi
    {
      printf "clients=%s\n" "$(tmux list-clients 2>/dev/null | wc -l)"
      printf "pending_marker=%s\n" "$([[ -f "$state/boot-restore-pending.json" ]] && echo yes || echo no)"
      printf "selected_resume_lines=%s\n" "$selected_resume_lines"
    } > "$HOME/.tmux/resurrect/cold-boot-zero-client-summary"
  '
  echo ">>> cold-boot-zero-client: attach twice; only the first may consume the marker"
  user_exec "$CONTAINER_NAME" bash -lc '
    set -euo pipefail
    for _ in 1 2; do
      fifo="/tmp/cold-boot-attend-$RANDOM"
      mkfifo "$fifo"
      sleep 2 > "$fifo" & input_pid=$!
      tmux -C attach-session -t =main < "$fifo" >/tmp/cold-boot-attend.log 2>&1 & client_pid=$!
      for _ in $(seq 1 20); do
        [[ -n "$(tmux list-clients -t =main 2>/dev/null || true)" ]] && break
        sleep .1
      done
      kill "$client_pid" "$input_pid" 2>/dev/null || true
      wait "$client_pid" "$input_pid" 2>/dev/null || true
      rm -f "$fifo"
      sleep 1
    done
  '
fi

if (( DOUBLE_CRASH )); then
  echo ""
  echo ">>> phase 2b: second populate (shrink to 1 window) + second crash"
  # Reuse populate-state.sh against the already-restored session. PHASE=second
  # is informational; the script's idempotent shape handles a pre-existing
  # 'main' session correctly. Shrink to 1 window, run a couple of saves
  # (cliff guard MUST refuse to overwrite the good content), then delete
  # the live last so we re-enter the dangling-symlink fallback path.
  SECOND_VARS=(
    -e SCENARIO="${SCENARIO}-second"
    -e PHASE=second
    -e WINDOW_COUNT=1
    -e SAVES_BEFORE=2
    -e DELETE_LIVE_LAST=1
  )
  user_exec "${SECOND_VARS[@]}" "$CONTAINER_NAME" bash /opt/harness/populate-state.sh

  echo ""
  echo ">>> phase 2c: simulating SECOND reboot"
  docker kill --signal=SIGKILL "$CONTAINER_NAME" >/dev/null
  docker start "$CONTAINER_NAME" >/dev/null

  for _ in $(seq 1 30); do
    if docker exec "$CONTAINER_NAME" systemctl is-system-running 2>/dev/null | grep -qE "running|degraded"; then
      break
    fi
    sleep 0.5
  done
  wait_for_user_systemd
  user_exec "$CONTAINER_NAME" systemctl --user start tmux.service tmux-restore.service || true
  sleep 6
fi

if (( SECOND_SERVICE_RESTART )); then
  echo ""
  echo ">>> phase 2b: second service restart (no container reboot)"
  # Wait for first tmux-restore.service run to settle before restarting.
  sleep 8
  echo ">>> first-boot restore state:"
  user_exec "$CONTAINER_NAME" systemctl --user show -p ActiveState,Result,ExecMainStatus tmux-restore.service --no-pager 2>/dev/null || true
  user_exec "$CONTAINER_NAME" tmux list-panes -a 2>/dev/null || true
  echo ">>> restarting tmux.service (not a full reboot) to trigger second restore run"
  # `systemctl restart` sends SIGTERM to tmux, which normally kills the server
  # and all sessions. This is the trigger for the production bug.
  user_exec "$CONTAINER_NAME" systemctl --user restart tmux.service || true
  # Give tmux-restore.service time to run (another 20×0.5s wait loop internally)
  sleep 12
  echo ">>> second tmux-restore.service state:"
  user_exec "$CONTAINER_NAME" systemctl --user show -p ActiveState,Result,ExecMainStatus tmux-restore.service --no-pager 2>/dev/null || true
  echo ">>> systemd-restore.log (last 30 lines, includes second run):"
  user_exec "$CONTAINER_NAME" tail -30 /home/tester/.tmux/resurrect/systemd-restore.log 2>/dev/null || true
  echo ">>> journal for tmux-restore.service:"
  user_exec "$CONTAINER_NAME" journalctl --user -u tmux-restore.service --no-pager -n 20 2>/dev/null || true
fi

echo ""
echo ">>> phase 3: assertions"
# Most scenarios use 8 windows; the capture-skip scenario uses 4.
EXPECTED_WINDOWS="${EXPECTED_WINDOWS:-8}"
[[ "$SCENARIO" == "pane-capture-skip" ]] && EXPECTED_WINDOWS=4
ASSERT_VARS=(
  -e EXPECTED_WINDOWS="$EXPECTED_WINDOWS"
  -e EXPECTED_ASSISTANTS="$EXPECTED_ASSISTANTS"
  -e CHECK_PATCH_PRESENT="$CHECK_PATCH_PRESENT"
  -e CHECK_CAPTURE_SKIP="$CHECK_CAPTURE_SKIP"
  -e CHECK_DOUBLE_SAVE="$CHECK_DOUBLE_SAVE"
  -e CHECK_KEEP_LAST="$CHECK_KEEP_LAST"
  -e CHECK_EMPTY_LAST_FALLBACK="$CHECK_EMPTY_LAST_FALLBACK"
  -e CHECK_ZERO_CLIENT="$CHECK_ZERO_CLIENT"
  -e CHECK_ATTENDED_RESTORE="$CHECK_ATTENDED_RESTORE"
)
user_exec "${ASSERT_VARS[@]}" "$CONTAINER_NAME" bash /opt/harness/assert-restored.sh
exit_code=$?

echo ""
echo "===================="
if [[ "$exit_code" == "0" ]]; then
  echo "SCENARIO '$SCENARIO': PASS"
else
  echo "SCENARIO '$SCENARIO': FAIL"
  echo ""
  echo "--- recent journal (tmux-restore.service) ---"
  user_exec "$CONTAINER_NAME" journalctl --user -u tmux-restore.service --no-pager -n 30 2>&1 | tail -30 || true
  echo "--- systemd-restore.log ---"
  user_exec "$CONTAINER_NAME" tail -30 /home/tester/.tmux/resurrect/systemd-restore.log 2>&1 | tail -30 || true
fi
echo "===================="
exit "$exit_code"
