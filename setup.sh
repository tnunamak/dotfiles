#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# Cache sudo credentials upfront
sudo -v

# Detect interactive terminal
INTERACTIVE=false
[[ -t 0 ]] && INTERACTIVE=true

prompt() {
  local var=$1 prompt_text=$2 default=$3
  if $INTERACTIVE; then
    read -rp "$prompt_text [$default]: " input
    printf -v "$var" '%s' "${input:-$default}"
  else
    printf -v "$var" '%s' "$default"
  fi
}

# --- Platform packages ---

case "$(uname)" in
  Linux)
    echo "Installing system packages (apt)..."
    sudo apt-get update
    sudo apt-get install -y neovim git ripgrep curl zsh fzf stow xclip socat tmux jq

    # Starship
    if ! command -v starship &>/dev/null; then
      curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi

    # zoxide
    if ! command -v zoxide &>/dev/null; then
      curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    fi

    # git-filter-repo (for sync-devcontainer.sh)
    if ! command -v git-filter-repo &>/dev/null; then
      sudo apt-get install -y git-filter-repo
    fi

    # Kitty terminal
    if ! command -v kitty &>/dev/null; then
      sudo apt-get install -y kitty
    fi

    # Docker CE
    if ! command -v docker &>/dev/null; then
      sudo apt-get install -y ca-certificates gnupg
      sudo install -m 0755 -d /etc/apt/keyrings
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      sudo chmod a+r /etc/apt/keyrings/docker.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      sudo apt-get update
      sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      sudo usermod -aG docker "$USER"
      echo "NOTE: Log out and back in for docker group membership to take effect."
    fi
    ;;
  Darwin)
    if ! command -v brew &>/dev/null; then
      echo "Homebrew not found. Install it from https://brew.sh"
      exit 1
    fi
    echo "Installing system packages (brew)..."
    brew install neovim git ripgrep fzf starship zoxide stow uv git-filter-repo socat tmux jq 2>&1 | grep -v 'already installed'
    for cask in kitty docker; do
      brew list --cask "$cask" &>/dev/null || brew install --cask "$cask"
    done
    brew upgrade neovim git ripgrep fzf starship zoxide stow uv git-filter-repo socat tmux jq 2>&1 | grep -v 'already.*latest'
    ;;
  *)
    echo "Unsupported platform: $(uname)"
    exit 1
    ;;
esac

# --- Cross-platform tool installs ---

# Node.js (via nvm)
if ! command -v nvm &>/dev/null && [[ ! -d "$HOME/.nvm" ]]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  # shellcheck source=/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
fi
# Ensure global npm packages survive nvm install (node upgrades).
# Shared list lives in npm-global-packages.txt; host-only extras appended here.
# NOTE: @anthropic-ai/claude-code is intentionally NOT listed — Claude Code
# migrated from npm to a native installer (installs to ~/.local/bin/claude).
{
  grep -v '^\s*#' "$DOTFILES_DIR/npm-global-packages.txt" | grep -v '^\s*$'
  echo "@devcontainers/cli"
} > "$HOME/.nvm/default-packages"
if ! command -v node &>/dev/null; then
  nvm install --lts
fi

# uv (Python package manager)
if ! command -v uv &>/dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Claude Code (native installer — no longer distributed via npm)
# If an old npm-global copy exists in the nvm bin dir, remove it so the native
# binary at ~/.local/bin/claude takes precedence.
if npm ls -g --depth=0 @anthropic-ai/claude-code &>/dev/null; then
  npm uninstall -g @anthropic-ai/claude-code
fi
if ! [[ -x "$HOME/.local/bin/claude" ]]; then
  curl -fsSL https://claude.ai/install.sh | bash
fi

# Install shared npm global packages (from npm-global-packages.txt)
echo "Installing shared npm global packages..."
while IFS= read -r pkg; do
  [[ -z "$pkg" || "$pkg" =~ ^[[:space:]]*# ]] && continue
  if ! npm ls -g --depth=0 "$pkg" &>/dev/null; then
    npm install -g "$pkg"
  fi
done < "$DOTFILES_DIR/npm-global-packages.txt"

# Devcontainer CLI (host-only — not needed inside containers)
if ! command -v devcontainer &>/dev/null; then
  npm install -g @devcontainers/cli
fi

# Kimi Code CLI
if ! command -v kimi &>/dev/null; then
  uv tool install --python 3.13 kimi-cli
fi

# rstring (code summarization for AI context)
if ! command -v rstring &>/dev/null; then
  uv tool install rstring
fi

# gog (Google Workspace CLI)
if ! command -v gog &>/dev/null; then
  go install github.com/steipete/gogcli/cmd/gog@latest
fi

# rtk (CLI proxy that reduces LLM token consumption)
if ! command -v rtk &>/dev/null; then
  curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
fi
# rtk init: --no-patch to avoid overwriting stowed settings.json (hook is already in it)
if [[ ! -f ~/.claude/hooks/rtk-rewrite.sh ]]; then
  rtk init --global --no-patch
fi

# Set zsh as default shell
if [[ "$SHELL" != */zsh ]]; then
  sudo chsh -s "$(which zsh)" "$USER"
fi

# --- Stow ---

PACKAGES=(nvim zsh bash shell kitty starship git claude bin gemini codex rtk tmux)

echo ""
echo "Stowing packages: ${PACKAGES[*]}"
# --no-folding:
# - bin: ~/.local/bin/ is shared with other tools (pipx, npm, etc.)
# - tmux: systemd drop-in dirs (e.g. tmux.service.d) must be real dirs,
#   not symlinks — systemd does not follow directory symlinks for drop-ins.
NO_FOLD_PKGS=(bin nvim claude tmux)

# Remove files that tools create before stow can link them
# (claude/rtk init write ~/.claude/settings.json as a regular file)
[[ -f ~/.claude/settings.json && ! -L ~/.claude/settings.json ]] && rm ~/.claude/settings.json

for pkg in "${PACKAGES[@]}"; do
  extra_flags=()
  for nf in "${NO_FOLD_PKGS[@]}"; do
    [[ "$pkg" == "$nf" ]] && extra_flags+=(--no-folding) && break
  done
  stow -d "$DOTFILES_DIR" -t "$HOME" --restow "${extra_flags[@]}" "$pkg"
done

# --- Zsh plugins ---

ZSH_PLUGINS=~/.zsh/plugins
mkdir -p "$ZSH_PLUGINS"
clone_if_missing() {
  local repo=$1 dest=$2
  if [[ ! -d "$dest" ]]; then
    echo "Cloning $repo"
    git clone --depth 1 "$repo" "$dest"
  fi
}
clone_if_missing https://github.com/zsh-users/zsh-autosuggestions "$ZSH_PLUGINS/zsh-autosuggestions"
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_PLUGINS/zsh-syntax-highlighting"

# --- tmux plugins (tpm) ---

clone_if_missing https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
~/.tmux/plugins/tpm/bin/install_plugins

# Patch tmux-assistant-resurrect's extract_cli_args regex. Upstream requires
# `[= ]` after --resume, which fails to strip a bare trailing --resume and
# causes a doubled --resume at restore time. That crashed Bun 1.3.13 (and
# took tmux with it) on 2026-04-22. Re-applied on every setup run so TPM
# updates don't silently revert it.
# Upstream: github.com/timvw/tmux-assistant-resurrect — remove once merged.
ASSISTANT_SAVE="$HOME/.tmux/plugins/tmux-assistant-resurrect/scripts/save-assistant-sessions.sh"
if [[ -f "$ASSISTANT_SAVE" ]] && grep -qF "'s/--resume[= ] *[^ ]*//'" "$ASSISTANT_SAVE"; then
  sed -i "s|'s/--resume\[= \] \*\[^ \]\*//'|'s/--resume(=[^ ]*)?( +[^ -][^ ]*)?//'|" "$ASSISTANT_SAVE"
  echo "Patched tmux-assistant-resurrect: bare-trailing --resume regex"
fi

# Patch tmux-assistant-resurrect to save pane targets using the grouped
# session's base name. tmux-local-attach-main creates ephemeral grouped
# sessions (main-0, main-1, ...), but restore only recreates the canonical
# session, so assistant pane IDs must be saved against that base session.
if [[ -f "$ASSISTANT_SAVE" ]] &&
   ! grep -qF 'session_group=$(tmux display-message -t "$session_name"' "$ASSISTANT_SAVE" &&
   grep -qF 'tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index}|#{pane_pid}|#{pane_current_path}" >"$PANE_FILE"' "$ASSISTANT_SAVE"; then
  sed -i '/tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index}|#{pane_pid}|#{pane_current_path}" >"$PANE_FILE"/c\
	>"$PANE_FILE"\
	while IFS='\''|'\'' read -r session_name window_index pane_index pane_pid pane_cwd; do\
		session_group=$(tmux display-message -t "$session_name" -p '\''#{session_group}'\'' 2>/dev/null || true)\
		if [ -n "$session_group" ]; then\
			session_name="$session_group"\
		fi\
		printf '\''%s:%s.%s|%s|%s\\n'\'' "$session_name" "$window_index" "$pane_index" "$pane_pid" "$pane_cwd" >>"$PANE_FILE"\
	done < <(tmux list-panes -a -F "#{session_name}|#{window_index}|#{pane_index}|#{pane_pid}|#{pane_current_path}")' "$ASSISTANT_SAVE"
  echo "Patched tmux-assistant-resurrect: grouped session pane targets"
fi

# Enable tmux-restore.service (Linux only — stowed by the `tmux` package).
# Replaces tmux-continuum's boot-time restore, which races against its own
# auto-save and the first kitty attach. See CLAUDE.md for the debugging
# history that led to this decision.
if [[ "$(uname)" == "Linux" ]] && command -v systemctl &>/dev/null; then
  systemctl --user daemon-reload
  systemctl --user enable tmux-restore.service 2>/dev/null || true
fi

# Patch koboldcpp's environment.yaml. The upstream file has three problems for
# a headless CUDA 13.x build against an NVIDIA 590.x driver on Ubuntu 25.10:
#
#   1. gxx=10 is too old for CUDA 13.x. Conda-forge's nvcc 13.x + gcc 10
#      triggers intermittent `cicc` segfaults on ggml flash-attention template
#      instantiations. Bumping to gxx=13 (CUDA 13.x-supported) fixes it.
#   2. ocl-icd-system's post-link script fails on this machine because the
#      destination dir isn't created before it symlinks /etc/OpenCL/vendors
#      into the conda prefix. Removing it is safe — OpenCL isn't used in the
#      CUDA build path.
#   3. customtkinter is a pip-installed GUI dep that pulls python-tk pieces.
#      The build breaks mid-install; not needed for headless server use.
#
# Driver 590.x supports up to CUDA 13.1 runtime, so you must build with
# `KCPP_CUDA=13.1.1 ARCHES_CU13=1 ./koboldcpp.sh rebuild`. CUDA 13.2.x
# compiles fine but produces PTX the driver rejects at load time.
#
# Also patches Makefile to remove /usr/local/cuda and /opt/cuda includes
# which mix system headers with the conda env's headers and fail CCCL
# compatibility checks.
#
# Re-applied on every setup run so `git pull` in koboldcpp doesn't silently
# revert either patch.
# Upstream: github.com/LostRuins/koboldcpp — remove once these are merged.
KCPP_DIR="$HOME/applications/koboldcpp"
KCPP_ENV="$KCPP_DIR/environment.yaml"
KCPP_MK="$KCPP_DIR/Makefile"
if [[ -f "$KCPP_ENV" ]]; then
  if grep -qF "gxx=10" "$KCPP_ENV"; then
    sed -i 's|gxx=10|gxx=13|' "$KCPP_ENV"
    echo "Patched koboldcpp environment.yaml: gxx 10 -> 13"
  fi
  if grep -qE "^\s*-\s*ocl-icd-system\s*$" "$KCPP_ENV"; then
    sed -i '/^\s*-\s*ocl-icd-system\s*$/d' "$KCPP_ENV"
    echo "Patched koboldcpp environment.yaml: removed ocl-icd-system"
  fi
  if grep -qE "^\s*-\s*customtkinter\s*$" "$KCPP_ENV"; then
    # Drop customtkinter and the now-empty `- pip:` section header.
    sed -i '/^\s*-\s*customtkinter\s*$/d' "$KCPP_ENV"
    # Remove trailing empty `- pip:` if it's the last line.
    if [[ "$(tail -n 1 "$KCPP_ENV")" =~ ^[[:space:]]*-[[:space:]]*pip:[[:space:]]*$ ]]; then
      sed -i '$d' "$KCPP_ENV"
    fi
    echo "Patched koboldcpp environment.yaml: removed customtkinter"
  fi
fi
if [[ -f "$KCPP_MK" ]] && grep -qF "-I/usr/local/cuda/include -I/opt/cuda/include" "$KCPP_MK"; then
  sed -i 's|-DSD_USE_CUDA -I/usr/local/cuda/include -I/opt/cuda/include|-DSD_USE_CUDA|; s|-L/usr/local/cuda/lib64 -L/opt/cuda/lib64||' "$KCPP_MK"
  echo "Patched koboldcpp Makefile: stripped system CUDA include/lib paths"
fi

# --- Local config setup ---

touch ~/.shell_local
touch ~/.shell_secrets
mkdir -p ~/.claude
touch ~/.claude/CLAUDE.local.md

# --- Managed MCP servers ---

chmod +x "$DOTFILES_DIR/sync-mcps.sh"
"$DOTFILES_DIR/sync-mcps.sh"

# --- Shared skills ---
# Two mechanisms, one per category:
#
# 1. Upstream skill suites: installed via `npx skills`. Pinned by
#    ~/.agents/.skill-lock.json, updatable with `npx skills update -g`.
#    Migrate this list to a committed Skillfile once vercel-labs/skills#729 lands.
#
# 2. Locally-authored skills under ai/skills/local/*/: direct symlinks so
#    edits propagate live. `npx skills` would copy instead of symlink here,
#    breaking the edit-in-dotfiles workflow, and local paths aren't tracked
#    in the lockfile anyway.
echo ""
echo "Installing upstream skills via npx skills..."
UPSTREAM_SKILLS=(
  pbakaus/impeccable
  forrestchang/andrej-karpathy-skills
)
for src in "${UPSTREAM_SKILLS[@]}"; do
  npx -y skills add "$src" -g -a claude-code -a codex -a gemini-cli --skill '*' -y
done

echo ""
echo "Symlinking locally-authored skills..."
for agent_dir in ~/.claude ~/.codex ~/.gemini; do
  mkdir -p "$agent_dir/skills"
  for skill in "$DOTFILES_DIR"/ai/skills/local/*/; do
    [[ -d "$skill" ]] || continue
    skill_name=$(basename "$skill")
    ln -sfn "${skill%/}" "$agent_dir/skills/$skill_name"
  done
done

# Git local config (only on first run)
if [[ ! -f ~/.gitconfig.local ]]; then
  echo ""
  echo "Setting up git identity..."

  prompt GIT_NAME "Name" "$(git config --global user.name 2>/dev/null || echo "")"
  prompt GIT_EMAIL "Email" "$(git config --global user.email 2>/dev/null || echo "")"

  # Pick signing key
  SIGNING_KEY=""
  mapfile -t PUBKEYS < <(ls ~/.ssh/*.pub 2>/dev/null)
  if [[ ${#PUBKEYS[@]} -gt 0 ]]; then
    echo "Available SSH keys:"
    for i in "${!PUBKEYS[@]}"; do
      echo "  $((i+1))) ${PUBKEYS[$i]}"
    done
    if $INTERACTIVE; then
      read -rp "Signing key [1]: " key_choice
      key_idx=$(( ${key_choice:-1} - 1 ))
      if [[ $key_idx -ge 0 && $key_idx -lt ${#PUBKEYS[@]} ]]; then
        SIGNING_KEY="${PUBKEYS[$key_idx]}"
      else
        SIGNING_KEY="${PUBKEYS[0]}"
      fi
    else
      # Non-interactive: prefer ed25519, fall back to first key
      for k in "${PUBKEYS[@]}"; do
        [[ "$k" == *ed25519* ]] && SIGNING_KEY="$k" && break
      done
      [[ -z "$SIGNING_KEY" ]] && SIGNING_KEY="${PUBKEYS[0]}"
    fi
  fi

  cat > ~/.gitconfig.local <<GITEOF
[user]
	name = $GIT_NAME
	email = $GIT_EMAIL
	signingkey = $SIGNING_KEY
GITEOF
  echo "Wrote ~/.gitconfig.local"
fi


echo ""
echo "Done. Restart your shell or run: exec zsh"
