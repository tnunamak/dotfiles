#!/usr/bin/env bash
# Runs INSIDE the container as the test user. Sets up the tmux/continuum/
# resurrect/dotfiles config and the tmux.service + tmux-restore.service units.
#
# The dotfiles tree is bind-mounted at /workspace. We don't run the full
# setup.sh (it does way too much for a test container) — just the pieces the
# restore path actually depends on.
set -euo pipefail

DOTFILES=/workspace
TPM_DIR="$HOME/.tmux/plugins/tpm"

echo "[install] HOME=$HOME USER=$(id -un) UID=$(id -u)"

# --- Stow tmux config selectively ---
# Stow normally folds whole directories — but the dotfiles repo is mounted
# read-only, so a folded ~/.config/systemd → /workspace/tmux/.config/systemd
# would prevent us from writing the path-corrected unit files for this user.
# Use --no-folding so directories are created locally and only leaf files
# become symlinks. This matches setup.sh's NO_FOLD_PKGS pattern.
mkdir -p "$HOME/.config" "$HOME/.tmux"
cd "$DOTFILES"
stow --target="$HOME" --no-folding tmux
echo "[install] stowed tmux package (no-folding)"

# Remove any unit-file symlinks pointing into /workspace — they hardcode
# /home/tnunamak paths and won't work for /home/tester. We rewrite below.
find "$HOME/.config/systemd/user" -type l -lname '*workspace*' -delete 2>/dev/null || true

# --- Install TPM ---
if [[ ! -d "$TPM_DIR" ]]; then
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
  echo "[install] cloned tpm"
fi

# --- Install plugins declared in tmux.conf via TPM's install_plugins.sh ---
# We can't use prefix+I (no client). Run TPM's installer directly with TMUX
# unset — the script knows how to bootstrap a temp tmux server.
# Retry a few times: TPM uses git clone which can be flaky on slow networks.
for attempt in 1 2 3; do
  out=$("$TPM_DIR/bin/install_plugins" 2>&1)
  echo "$out"
  if echo "$out" | grep -q "download fail"; then
    echo "[install] tpm install retry $attempt (saw download fail)"
    sleep 2
    # Remove partial clones so the next attempt starts clean
    rm -rf "$HOME/.tmux/plugins/tmux-resurrect" "$HOME/.tmux/plugins/tmux-continuum" "$HOME/.tmux/plugins/tmux-assistant-resurrect" 2>/dev/null || true
  else
    break
  fi
done
echo "[install] tpm plugins installed"

# --- Apply tmux-assistant-resurrect patches via the shared idempotent
# patch script. Same code path as setup.sh and tmux-restore.service's
# ExecStartPre on the host, so the harness validates the real flow.
# PATCH_PLUGIN=0 skips patches — used by negative scenarios that verify
# the bug exists in vanilla upstream.
PATCH_PLUGIN="${PATCH_PLUGIN:-1}"
PATCH_SCRIPT="$HOME/.config/tmux/scripts/patch-assistant-resurrect.sh"
if (( PATCH_PLUGIN )) && [[ -x "$PATCH_SCRIPT" ]]; then
  "$PATCH_SCRIPT" || true
  echo "[install] ran patch-assistant-resurrect.sh"
fi

# --- Install fake claude/codex stubs so the assistant detector has something
# to find. Real CLIs aren't needed (no API calls); the plugin just needs a
# process literally named 'claude' or 'codex' in a pane's process tree.
# Stubs run a bash builtin loop that preserves the script name in `comm` —
# `exec sleep` would replace the process name with 'sleep' and the plugin
# would miss it.
mkdir -p "$HOME/.local/bin"
# Stubs use `exec -a NAME bash -c ...` to set argv[0] without launching the
# actual claude binary. uutils coreutils 0.2.2 (Ubuntu 25.10's default) blocks
# the more obvious `exec -a claude sleep` with a security check, but bash
# itself is fine.
# Pass through args (e.g. --resume <id>) so the plugin's argv-based
# session-id detector finds them. exec -a NAME bash -c also keeps the
# program name in argv[0], satisfying the plugin's regex match.
cat > "$HOME/.local/bin/claude" <<'EOF'
#!/usr/bin/env bash
exec -a "claude $*" bash -c 'while :; do sleep 3600 & wait; done'
EOF
cat > "$HOME/.local/bin/codex" <<'EOF'
#!/usr/bin/env bash
exec -a "codex $*" bash -c 'while :; do sleep 3600 & wait; done'
EOF
chmod +x "$HOME/.local/bin/claude" "$HOME/.local/bin/codex"
echo "[install] installed claude/codex stubs at ~/.local/bin"

# --- The user's personal tmux-assistant-resurrect plugin ---
# Lives under tmux/.config/tmux/plugins/tmux-assistant-resurrect/ in dotfiles.
# It's gitignored at runtime via plugins/, but for the test we want it present.
LOCAL_PLUGIN="$DOTFILES/tmux/.config/tmux/plugins/tmux-assistant-resurrect"
TARGET_PLUGIN="$HOME/.tmux/plugins/tmux-assistant-resurrect"
if [[ -d "$LOCAL_PLUGIN" && ! -e "$TARGET_PLUGIN" ]]; then
  ln -sf "$LOCAL_PLUGIN" "$TARGET_PLUGIN"
  echo "[install] linked tmux-assistant-resurrect"
fi

# --- Install systemd user units ---
# Mirror what tmux-continuum + the dotfiles tmux-restore.service do, but with
# paths corrected for THIS user (not /home/tnunamak). This decouples the
# test from any path-hardcoding in the dotfiles unit files.
mkdir -p "$HOME/.config/systemd/user" "$HOME/.config/systemd/user/tmux.service.d"

cat > "$HOME/.config/systemd/user/tmux.service" <<EOF
[Unit]
Description=tmux default session (detached)

[Service]
Type=forking
ExecStart=/usr/bin/tmux new-session -d
ExecStop=/usr/bin/tmux kill-server
KillMode=control-group

[Install]
WantedBy=default.target
EOF

# Drop-in: same as tmux/.config/systemd/user/tmux.service.d/restart.conf
cat > "$HOME/.config/systemd/user/tmux.service.d/restart.conf" <<EOF
[Service]
Restart=on-failure
RestartSec=2
EOF

# tmux-restore.service: like the dotfiles version but with this user's path.
# ExecStartPre runs the patch script every boot (same as host) UNLESS the
# scenario explicitly wants the plugin unpatched (PATCH_PLUGIN=0 also
# disables the durability mechanism).
EXEC_START_PRE_LINE="ExecStartPre=-$HOME/.config/tmux/scripts/patch-assistant-resurrect.sh"
if (( ! PATCH_PLUGIN )); then
  EXEC_START_PRE_LINE="# ExecStartPre disabled by PATCH_PLUGIN=0"
fi
cat > "$HOME/.config/systemd/user/tmux-restore.service" <<EOF
[Unit]
Description=tmux-resurrect restore (bypasses continuum race)
Documentation=file:///workspace/CLAUDE.md
After=tmux.service
BindsTo=tmux.service
PartOf=tmux.service

[Service]
Type=oneshot
RemainAfterExit=no
$EXEC_START_PRE_LINE
ExecStart=$HOME/.config/tmux/scripts/systemd-restore.sh

[Install]
WantedBy=tmux.service
EOF

systemctl --user daemon-reload
systemctl --user enable tmux.service tmux-restore.service
echo "[install] systemd user units installed and enabled"

echo "[install] DONE"
