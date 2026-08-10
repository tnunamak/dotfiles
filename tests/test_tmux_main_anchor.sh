#!/usr/bin/env bash
# Verify that tmux restore leaves a stable literal `main` session for service
# consumers, both after grouped-session drift and on a fresh server.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESTORE="$ROOT/tmux/.config/tmux/scripts/systemd-restore.sh"
REAL_TMUX="$(command -v tmux)"
WORK="$(mktemp -d "${HOME}/.tmp/tmux-main-anchor.XXXXXX")"
SOCKET="test-tmux-main-anchor-$$"
TEST_HOME="$WORK/home"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

tmux_test() {
  "$REAL_TMUX" -L "$SOCKET" "$@"
}

cleanup() {
  tmux_test kill-server >/dev/null 2>&1 || true
  rm -rf "$WORK"
}
trap cleanup EXIT

mkdir -p "$WORK/bin" "$TEST_HOME/.tmux/plugins/tmux-resurrect/scripts" "$TEST_HOME/.tmux/resurrect"
cat > "$WORK/bin/tmux" <<'EOF'
#!/usr/bin/env bash
exec /usr/bin/tmux -L "$TMUX_TEST_SOCKET" "$@"
EOF
chmod +x "$WORK/bin/tmux"
cat > "$TEST_HOME/.tmux/plugins/tmux-resurrect/scripts/restore.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$TEST_HOME/.tmux/plugins/tmux-resurrect/scripts/restore.sh"

run_restore() {
  HOME="$TEST_HOME" PATH="$WORK/bin:/usr/bin:/bin" TMUX_TEST_SOCKET="$SOCKET" \
    "$RESTORE" >/dev/null
}

# A restored work group can contain only main-N sessions while retaining the
# logical group name `main`. The anchor must join that existing group, not
# create an unrelated blank session.
tmux_test start-server
tmux_test new-session -d -s main-0 -n one
tmux_test new-window -d -t '=main-0' -n two
tmux_test new-window -d -t '=main-0' -n three
tmux_test new-session -d -s main-1 -t '=main-0'
run_restore

main_group="$(tmux_test display-message -p -t main -F '#{session_group}')"
[[ "$main_group" == main-0 ]] || fail "canonical main joined $main_group instead of the restored group"
[[ "$(tmux_test list-windows -t '=main' | wc -l)" -eq 3 ]] \
  || fail 'canonical main did not share the restored windows'

# A clean tmux.service start creates the default session `0`. Rename it to the
# same stable target so Daisy can start without waiting for a local attach.
tmux_test kill-server
sleep 0.2
tmux_test new-session -d
run_restore

tmux_test has-session -t '=main' || fail 'fresh server did not get canonical main'
! tmux_test has-session -t '=0' >/dev/null 2>&1 || fail 'fresh default session 0 was not renamed'

printf 'PASS: tmux restore maintains canonical main session\n'
