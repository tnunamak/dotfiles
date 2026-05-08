#!/usr/bin/env bash
# Runs INSIDE the container as the test user. Sets up tmux state for
# tmux-local-attach-main testing. Each scenario builds a different broken
# state — none of these involve a real crash/restore cycle, just direct
# tmux commands to construct sessions/groups.
#
# Required env:
#   ATTACH_SCENARIO  — kitty-attach-clean-boot | kitty-attach-no-session-named-main
#                      kitty-attach-group-name-drift | kitty-attach-multiple-groups
#                      kitty-attach-all-windows-viewed
set -euo pipefail

SCENARIO="${ATTACH_SCENARIO:-kitty-attach-clean-boot}"

# Reap any stale fake-attach units from a previous run.
systemctl --user list-units --no-legend 'fake-attach-*.service' 2>/dev/null \
  | awk '{print $1}' | xargs -r -I{} systemctl --user stop {} 2>/dev/null || true

# Make sure the tmux server is up and empty before we start.
# The install script started tmux.service, which spawns a default session
# named '0' (or similar). Kill it so we have a clean slate.
tmux kill-server 2>/dev/null || true
sleep 0.5
tmux start-server 2>/dev/null || true
# Force-create a server context: any command that requires one.
tmux list-sessions 2>/dev/null || true

# Helper: create a populated group rooted at $seed_name with $window_count
# windows, returns the seed session name.
make_group() {
  local seed_name="$1" window_count="$2"
  tmux new-session -d -s "$seed_name" -n "win-0" -c /tmp
  local i
  for (( i=1; i<window_count; i++ )); do
    tmux new-window -t "$seed_name:" -n "win-$i" -c /tmp
  done
}

# Helper: create N grouped clones of $seed (each one views a different window
# in round-robin to force "viewed by attached client" counts).
attach_clones() {
  local seed="$1" clone_prefix="$2" clone_count="$3"
  local i
  for (( i=0; i<clone_count; i++ )); do
    local name="${clone_prefix}-${i}"
    # Skip if the desired name collides with the seed
    [[ "$name" == "$seed" ]] && name="${clone_prefix}-extra-${i}"
    tmux new-session -d -s "$name" -t "=$seed"
  done
}

# Force a list of clones to be "attached" by spawning a background tmux
# attach in a separate process per clone, with a real PTY. We use `script`
# to allocate a PTY (it's installed via util-linux which Ubuntu ships by
# default). Each attach is selected to a specific window index.
#
# Caller provides parallel arrays:
#   $1 = nameref of array of session names
#   $2 = nameref of array of window indices per session (same length)
attach_to_windows() {
  local -n _names="$1"
  local -n _windows="$2"
  local i
  for (( i=0; i<${#_names[@]}; i++ )); do
    local sess="${_names[$i]}"
    local win="${_windows[$i]}"
    # Spawn a long-lived attached tmux client. We use systemd-run --user
    # to put the process under the user systemd manager so it survives
    # the docker exec session exiting (which would otherwise kill any
    # descendants in the exec's cgroup).
    #
    # `script -qc CMD /tmp/log` allocates a PTY for tmux. We feed it
    # `sleep 86400` on stdin so `script` doesn't get EOF and exit. The
    # tmux client remains attached as long as the PTY is open.
    systemd-run --user --quiet --collect --unit="fake-attach-${sess}.service" \
      --setenv=TERM=xterm-256color \
      bash -c "exec script -qc 'tmux attach-session -t \"=${sess}:${win}\"' /tmp/attach-${sess}.log < <(sleep 86400)" \
      || true
  done
  # Give tmux time to register the attaches.
  sleep 2.5
}

case "$SCENARIO" in
  kitty-attach-clean-boot)
    # Group `main` with sessions `main`, `main-0`, `main-1`. 5 windows total.
    # Each session views a different window so all are "viewed".
    make_group main 5
    attach_clones main main 2
    sessions=(main main-0 main-1)
    windows=(0 1 2)
    attach_to_windows sessions windows
    ;;

  kitty-attach-no-session-named-main)
    # Group named `main` (because main was created first) — but THEN main
    # gets renamed away (mimics a user who renamed). Group name stays `main`
    # in tmux, but no session is literally called `main`.
    # Sessions: main-1, main-2, main-3 (5 windows).
    make_group main 5
    attach_clones main main 3   # creates main-0, main-1, main-2
    # Rename main → main-3 (but the group keeps its name `main` because
    # group-name = first-session-name at group-creation time). Actually no —
    # tmux groups are immutable in name. Renaming the seed does NOT rename
    # the group. So this is the "no literal `main`" case: we rename the
    # seed away so `tmux has-session -t =main` reports negative.
    tmux rename-session -t main main-3
    # Attach two clones to different windows
    sessions=(main-1 main-2)
    windows=(0 1)
    attach_to_windows sessions windows
    ;;

  kitty-attach-group-name-drift)
    # Crash-recovery scenario: the group name is `main-10` because the first
    # session at group creation was `main-10`. No literal `main` and no
    # session at all that the OLD filter would match `session_group=main`.
    make_group main-10 5
    attach_clones main-10 main 5   # creates main-0..main-4
    # No rename — `main-10` is the group name.
    sessions=(main-0 main-1)
    windows=(0 1)
    attach_to_windows sessions windows
    ;;

  kitty-attach-multiple-groups)
    # Empty `main` group (1 session, 1 window) AND a populated `main-10`
    # group (11 windows, 5 attached clones). Old script joins the empty one
    # because `tmux has-session -t =main` succeeds; new script must prefer
    # the populated one.
    make_group main 1
    make_group main-10 11
    attach_clones main-10 main 5    # creates main-0..main-4 in main-10 group
    sessions=(main-0 main-1 main-2)
    windows=(0 1 2)
    attach_to_windows sessions windows
    ;;

  kitty-attach-all-windows-viewed)
    # 3 windows; 3 attached clones each viewing a different window. New
    # kitty must create a 4th window and view it.
    make_group main 3
    attach_clones main main 3   # creates main-0, main-1, main-2
    sessions=(main main-0 main-1)
    windows=(0 1 2)
    attach_to_windows sessions windows
    ;;

  *)
    echo "[populate] unknown scenario: $SCENARIO" >&2
    exit 1
    ;;
esac

echo "[populate:$SCENARIO] state after setup:"
tmux list-sessions -F '#{session_group}|#{session_name}|#{session_windows}|#{session_attached}|window_idx=#{window_index}' 2>/dev/null || true
echo "[populate:$SCENARIO] DONE"
