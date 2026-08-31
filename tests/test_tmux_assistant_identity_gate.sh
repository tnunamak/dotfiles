#!/usr/bin/env bash
# A sidecar can be well-formed and have a plausible count yet name a Claude
# session for a pane that is currently running Codex.  The bundle must retain
# the prior generation instead of treating that stale identity as current.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUARD="$ROOT/tmux/.config/tmux/scripts/save-assistant-sessions-guarded.sh"
VALIDATOR="$ROOT/tmux/.config/tmux/scripts/validate-assistant-session-identities.sh"
BUNDLE="$ROOT/tmux/.config/tmux/scripts/resurrect-transaction-bundle"
WORK="$(mktemp -d "${HOME}/.tmp/tmux-identity-gate.XXXXXX")"
HOME_DIR="$WORK/home"

cleanup() { chmod -R u+w "$WORK" >/dev/null 2>&1 || true; rm -rf "$WORK"; }
trap cleanup EXIT
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

mkdir -p "$HOME_DIR/.tmux/resurrect" "$HOME_DIR/.tmux/plugins/tmux-assistant-resurrect/scripts" "$HOME_DIR/.config/tmux/scripts"
ln -s "$BUNDLE" "$HOME_DIR/.config/tmux/scripts/resurrect-transaction-bundle"
ln -s "$VALIDATOR" "$HOME_DIR/.config/tmux/scripts/validate-assistant-session-identities.sh"

valid="$WORK/valid.json"
stale="$WORK/stale.json"
snapshot="$WORK/live.json"
layout="$HOME_DIR/.tmux/resurrect/tmux_resurrect_identity.txt"
printf 'pane\tmain:4.0\t%s\t1\tbash\n' "$WORK" >"$layout"

jq -n '{sessions:[{pane:"main:4.0",tool:"codex",session_id:"019f8f87",pid:"101",cwd:"/work"}]}' >"$valid"
jq -n '{sessions:[{pane:"main:4.0",tool:"claude",session_id:"bdac59f6",pid:"99",cwd:"/work"}]}' >"$stale"
jq -n '{panes:[{pane:"main:4.0",assistants:[{tool:"codex",pid:"101",session_id:"019f8f87"}]}]}' >"$snapshot"

# The normal path takes both a tmux pane snapshot and a process-tree snapshot.
# Reproduce the incident shape: main:4.0's shell owns a Codex resume process;
# the stale sidecar instead identifies an unrelated Claude PID/session.
mkdir -p "$WORK/bin"
cat >"$WORK/bin/tmux" <<'EOF'
#!/usr/bin/env bash
printf 'main|main|4|0|100\n'
EOF
cat >"$WORK/bin/ps" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "${TEST_PS_OUTPUT:-100 1 -zsh
101 100 node /opt/codex/bin/codex
102 101 /opt/codex/bin/codex}"
EOF
chmod +x "$WORK/bin/tmux" "$WORK/bin/ps"
# The saver can record the Node launcher (101) instead of the native child
# (102). Its tag must bind PID, session, and process-start ticks before this
# sidecar can pass validation.
proc_root="$WORK/proc"
mkdir -p "$proc_root/101" "$HOME_DIR/.codex"
printf 'btime 1000\n' >"$proc_root/stat"
{
  printf '101 (node) S'
  for _ in $(seq 1 18); do printf ' 0'; done
  printf ' 12345 0\n'
} >"$proc_root/101/stat"
jq -cn '{pid:101,session:"019f8f87",start_ticks:12345}' >"$HOME_DIR/.codex/session-tags.jsonl"
HOME="$HOME_DIR" TMUX_ASSISTANT_IDENTITY_PROC_ROOT="$proc_root" PATH="$WORK/bin:/usr/bin:/bin" \
  "$VALIDATOR" "$valid" >/dev/null ||
  fail 'Node-launcher Codex tag with matching start ticks was rejected'

jq -cn '{tool:"codex",pid:101,session_id:"019f8f87",start_ticks:12345}' >"$HOME_DIR/.codex/session-tags.jsonl"
HOME="$HOME_DIR" TMUX_ASSISTANT_IDENTITY_PROC_ROOT="$proc_root" PATH="$WORK/bin:/usr/bin:/bin" \
  "$VALIDATOR" "$valid" >/dev/null ||
  fail 'Codex SessionStart receipt schema with matching start ticks was rejected'

jq -cn '{pid:101,session:"019f8f87",start_ticks:99999}' >"$HOME_DIR/.codex/session-tags.jsonl"
if HOME="$HOME_DIR" TMUX_ASSISTANT_IDENTITY_PROC_ROOT="$proc_root" PATH="$WORK/bin:/usr/bin:/bin" \
  "$VALIDATOR" "$valid" >"$WORK/stale-ticks.out" 2>&1; then
  fail 'Codex tag with stale start ticks was accepted'
fi
grep -q 'no PID-bound session identity' "$WORK/stale-ticks.out" ||
  fail 'stale Codex start-ticks rejection was not specific'

jq -cn '{pid:101,session:"019f8f87"}' >"$HOME_DIR/.codex/session-tags.jsonl"
if HOME="$HOME_DIR" TMUX_ASSISTANT_IDENTITY_PROC_ROOT="$proc_root" PATH="$WORK/bin:/usr/bin:/bin" \
  "$VALIDATOR" "$valid" >"$WORK/missing-ticks.out" 2>&1; then
  fail 'Codex tag without start ticks was accepted'
fi
grep -q 'no PID-bound session identity' "$WORK/missing-ticks.out" ||
  fail 'missing Codex start-ticks rejection was not specific'

jq -cn '{pid:101,session:"019f8f87",start_ticks:12345}' >"$HOME_DIR/.codex/session-tags.jsonl"

# Ordinary Claude sessions use the upstream SessionStart receipt keyed by the
# main Claude PID. Its ppid field binds the session to that exact process.
claude_valid="$WORK/claude-valid.json"
runtime_dir="$WORK/runtime"
mkdir -p "$runtime_dir/tmux-assistant-resurrect"
jq -n '{sessions:[{pane:"main:4.0",tool:"claude",session_id:"claude-session",pid:"102",cwd:"/work"}]}' >"$claude_valid"
jq -n '{session_id:"claude-session",tool:"claude",ppid:102}' >"$runtime_dir/tmux-assistant-resurrect/claude-102.json"
mkdir -p "$proc_root/102"
{
  printf '102 (claude) S'
  for _ in $(seq 1 18); do printf ' 0'; done
  printf ' 20000 0\n'
} >"$proc_root/102/stat"
touch -d '@1201' "$runtime_dir/tmux-assistant-resurrect/claude-102.json"
HOME="$HOME_DIR" XDG_RUNTIME_DIR="$runtime_dir" TMUX_ASSISTANT_IDENTITY_PROC_ROOT="$proc_root" \
  TMUX_ASSISTANT_IDENTITY_CLK_TCK=100 PATH="$WORK/bin:/usr/bin:/bin" \
  TEST_PS_OUTPUT=$'100 1 -zsh\n102 100 /opt/claude/bin/claude' "$VALIDATOR" "$claude_valid" >/dev/null ||
  fail 'upstream Claude PID runtime receipt was rejected'

touch -d '@1198' "$runtime_dir/tmux-assistant-resurrect/claude-102.json"
if HOME="$HOME_DIR" XDG_RUNTIME_DIR="$runtime_dir" TMUX_ASSISTANT_IDENTITY_PROC_ROOT="$proc_root" \
  TMUX_ASSISTANT_IDENTITY_CLK_TCK=100 PATH="$WORK/bin:/usr/bin:/bin" \
  TEST_PS_OUTPUT=$'100 1 -zsh\n102 100 /opt/claude/bin/claude' \
  "$VALIDATOR" "$claude_valid" >"$WORK/stale-claude-receipt.out" 2>&1; then
  fail 'same-PID stale Claude receipt was accepted'
fi
grep -q 'no PID-bound session identity' "$WORK/stale-claude-receipt.out" ||
  fail 'stale Claude receipt rejection was not specific'

claude_resume="$WORK/claude-resume.json"
jq -n '{sessions:[{pane:"main:4.0",tool:"claude",session_id:"resume-session",pid:"102",cwd:"/work"}]}' >"$claude_resume"
HOME="$HOME_DIR" XDG_RUNTIME_DIR="$runtime_dir" TMUX_ASSISTANT_IDENTITY_PROC_ROOT="$proc_root" \
  TMUX_ASSISTANT_IDENTITY_CLK_TCK=100 PATH="$WORK/bin:/usr/bin:/bin" \
  TEST_PS_OUTPUT=$'100 1 -zsh\n102 100 /opt/claude/bin/claude --resume resume-session' \
  "$VALIDATOR" "$claude_resume" >/dev/null ||
  fail 'explicit Claude --resume fallback was rejected after stale runtime receipt'

# TMUX_ASSISTANT_RESURRECT_DIR is already the complete state directory in the
# upstream saver; it must not receive another tmux-assistant-resurrect suffix.
explicit_state_dir="$WORK/explicit-claude-state"
mkdir -p "$explicit_state_dir"
cp "$runtime_dir/tmux-assistant-resurrect/claude-102.json" "$explicit_state_dir/claude-102.json"
touch -d '@1201' "$explicit_state_dir/claude-102.json"
HOME="$HOME_DIR" TMUX_ASSISTANT_RESURRECT_DIR="$explicit_state_dir" TMUX_ASSISTANT_IDENTITY_PROC_ROOT="$proc_root" \
  TMUX_ASSISTANT_IDENTITY_CLK_TCK=100 PATH="$WORK/bin:/usr/bin:/bin" \
  TEST_PS_OUTPUT=$'100 1 -zsh\n102 100 /opt/claude/bin/claude' "$VALIDATOR" "$claude_valid" >/dev/null ||
  fail 'explicit upstream Claude state directory was rejected'

# A bare tool name in another program's argument list must not create identity
# evidence.
if HOME="$HOME_DIR" XDG_RUNTIME_DIR="$runtime_dir" PATH="$WORK/bin:/usr/bin:/bin" \
  TEST_PS_OUTPUT=$'100 1 -zsh\n102 100 /usr/bin/python3 /tmp/report.py --label claude --resume claude-session' \
  "$VALIDATOR" "$claude_valid" >"$WORK/argument-false-positive.out" 2>&1; then
  fail 'command argument containing claude was misclassified as Claude'
fi
grep -q 'does not match a live provider/PID' "$WORK/argument-false-positive.out" ||
  fail 'command-argument false-positive rejection was not specific'

if HOME="$HOME_DIR" TMUX_ASSISTANT_IDENTITY_PROC_ROOT="$proc_root" PATH="$WORK/bin:/usr/bin:/bin" \
  TEST_PS_OUTPUT=$'100 1 -zsh\n101 100 /usr/bin/python3 /tmp/codex resume 019f8f87' \
  "$VALIDATOR" "$valid" >"$WORK/path-false-positive.out" 2>&1; then
  fail 'non-Codex command with /tmp/codex argv was misclassified as Codex'
fi
grep -q 'does not match a live provider/PID' "$WORK/path-false-positive.out" ||
  fail 'path false-positive rejection was not specific'

# The file-only bundle command reproduces the old blind spot: hashes and
# counts alone accept the stale Claude record because they cannot see the pane.
HOME="$HOME_DIR" TMUX_RESURRECT_DIR="$HOME_DIR/.tmux/resurrect/repro" \
  "$BUNDLE" commit --layout "$layout" --assistant "$stale" --id blind-accept >/dev/null ||
  fail 'file-only bundle did not reproduce the formerly accepted stale sidecar'

HOME="$HOME_DIR" TMUX_ASSISTANT_IDENTITY_SNAPSHOT="$snapshot" "$VALIDATOR" "$valid" >/dev/null ||
  fail 'matching PID-bound Codex identity was rejected'
if HOME="$HOME_DIR" TMUX_ASSISTANT_IDENTITY_SNAPSHOT="$snapshot" "$VALIDATOR" "$stale" >"$WORK/stale.out" 2>&1; then
  fail 'stale Claude identity was accepted for live Codex pane'
fi
grep -q 'does not match a live provider/PID' "$WORK/stale.out" || fail 'stale identity rejection was not specific'

# Codex launched without a PID-bound tag or resume argument is deliberately
# unknown. It rejects the entire candidate rather than filtering a partial
# sidecar and letting a permissive count cliff commit it.
jq -n '{panes:[{pane:"main:4.0",assistants:[{tool:"codex",pid:"101",session_id:null}]}]}' >"$WORK/default-codex.json"
if HOME="$HOME_DIR" TMUX_ASSISTANT_IDENTITY_SNAPSHOT="$WORK/default-codex.json" "$VALIDATOR" "$valid" >"$WORK/default.out" 2>&1; then
  fail 'default Codex launch without PID-bound identity was accepted'
fi
grep -q 'no PID-bound session identity' "$WORK/default.out" ||
  fail 'default Codex rejection was not specific'

# A live assistant that has no sidecar entry (for example Pi without a durable
# ID) is an omission, not evidence that another saved entry is wrong.
jq -n '{panes:[
  {pane:"main:4.0",assistants:[{tool:"codex",pid:"101",session_id:"019f8f87"}]},
  {pane:"main:5.0",assistants:[{tool:"pi",pid:"102",session_id:null}]}
]}' >"$WORK/unsaved-pi.json"
HOME="$HOME_DIR" TMUX_ASSISTANT_IDENTITY_SNAPSHOT="$WORK/unsaved-pi.json" "$VALIDATOR" "$valid" >"$WORK/pi-omission.out" ||
  fail 'unsaved live Pi incorrectly blocked a valid Codex identity'
grep -q 'live-assistant-has-no-sidecar-entry' "$WORK/pi-omission.out" ||
  fail 'unsaved Pi omission was not recorded'

# Exercise the hook path: it starts with a good Codex sidecar, upstream writes
# the equally-sized stale Claude sidecar, and the guard must restore the good
# file and leave last-good unchanged.
cp "$valid" "$HOME_DIR/.tmux/resurrect/assistant-sessions.json"
HOME="$HOME_DIR" TMUX_RESURRECT_DIR="$HOME_DIR/.tmux/resurrect" \
  "$BUNDLE" commit --layout "$layout" --assistant "$valid" --id baseline >/dev/null
baseline="$(jq -r '.id' "$HOME_DIR/.tmux/resurrect/transactions/last-good.json")"
cat >"$HOME_DIR/.tmux/plugins/tmux-assistant-resurrect/scripts/save-assistant-sessions.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cp "$TEST_STALE_SIDECAR" "$HOME/.tmux/resurrect/assistant-sessions.json"
EOF
chmod +x "$HOME_DIR/.tmux/plugins/tmux-assistant-resurrect/scripts/save-assistant-sessions.sh"

HOME="$HOME_DIR" TEST_STALE_SIDECAR="$stale" TMUX_ASSISTANT_IDENTITY_SNAPSHOT="$snapshot" \
  bash "$GUARD" "$layout"
[[ "$(jq -r '.sessions[0].tool' "$HOME_DIR/.tmux/resurrect/assistant-sessions.json")" == codex ]] ||
  fail 'identity rejection did not restore the prior good sidecar'
[[ "$(jq -r '.id' "$HOME_DIR/.tmux/resurrect/transactions/last-good.json")" == "$baseline" ]] ||
  fail 'identity rejection advanced last-good'
grep -q 'IDENTITY GUARD: REFUSING candidate sidecar' "$HOME_DIR/.tmux/resurrect/assistant-save.log" ||
  fail 'identity rejection was not logged'

# PID-unbound entries must reject the complete candidate, even if filtering
# them would leave 79% of the prior snapshot — well above the 20% cliff.
many_valid="$WORK/many-valid.json"
many_default="$WORK/many-default.json"
many_snapshot="$WORK/many-live.json"
jq -n '[range(0;100) | {pane:("main:" + tostring + ".0"),tool:"codex",session_id:("session-" + tostring),pid:(1000 + . | tostring),cwd:"/work"}] | {sessions:.}' >"$many_valid"
jq -n '[range(0;100) | {pane:("main:" + tostring + ".0"),tool:"codex",session_id:("session-" + tostring),pid:(1000 + . | tostring),cwd:"/work"}] | {sessions:.}' >"$many_default"
jq -n '[range(0;100) | {pane:("main:" + tostring + ".0"),assistants:[{tool:"codex",pid:(1000 + . | tostring),session_id:(if . < 79 then "session-" + tostring else null end)}]}] | {panes:.}' >"$many_snapshot"
cp "$many_valid" "$HOME_DIR/.tmux/resurrect/assistant-sessions.json"
HOME="$HOME_DIR" TMUX_RESURRECT_DIR="$HOME_DIR/.tmux/resurrect" \
  "$BUNDLE" commit --layout "$layout" --assistant "$many_valid" --id hundred-baseline >/dev/null
hundred_baseline="$(jq -r '.id' "$HOME_DIR/.tmux/resurrect/transactions/last-good.json")"
HOME="$HOME_DIR" TEST_STALE_SIDECAR="$many_default" TMUX_ASSISTANT_IDENTITY_SNAPSHOT="$many_snapshot" \
  bash "$GUARD" "$layout"
[[ "$(jq '.sessions | length' "$HOME_DIR/.tmux/resurrect/assistant-sessions.json")" == 100 ]] ||
  fail 'PID-unverifiable 100-to-79 candidate did not retain all prior identities'
[[ "$(jq -r '.id' "$HOME_DIR/.tmux/resurrect/transactions/last-good.json")" == "$hundred_baseline" ]] ||
  fail 'PID-unverifiable 100-to-79 candidate advanced last-good'
grep -q 'no PID-bound session identity' "$HOME_DIR/.tmux/resurrect/assistant-save.log" ||
  fail 'PID-unverifiable 100-to-79 candidate was not rejected by identity guard'

printf 'PASS: assistant identity gate rejects stale provider/session sidecars\n'
