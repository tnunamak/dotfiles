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
    sudo apt-get install -y neovim git ripgrep curl zsh fzf stow xclip socat

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
    brew install neovim git ripgrep fzf starship zoxide stow uv git-filter-repo socat 2>&1 | grep -v 'already installed'
    for cask in kitty docker; do
      brew list --cask "$cask" &>/dev/null || brew install --cask "$cask"
    done
    brew upgrade neovim git ripgrep fzf starship zoxide stow uv git-filter-repo socat 2>&1 | grep -v 'already.*latest'
    ;;
  *)
    echo "Unsupported platform: $(uname)"
    exit 1
    ;;
esac

# --- Cross-platform tool installs ---

# Node.js (via nvm)
if ! command -v node &>/dev/null; then
  if ! command -v nvm &>/dev/null && [[ ! -d "$HOME/.nvm" ]]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    # shellcheck source=/dev/null
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  fi
  nvm install --lts
fi

# uv (Python package manager)
if ! command -v uv &>/dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Claude Code
if ! command -v claude &>/dev/null; then
  npm install -g @anthropic-ai/claude-code
fi

# Gemini CLI
if ! command -v gemini &>/dev/null; then
  npm install -g @google/gemini-cli
fi

# Codex CLI
if ! command -v codex &>/dev/null; then
  npm install -g @openai/codex
fi

# Devcontainer CLI
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

PACKAGES=(nvim zsh bash shell kitty starship git claude bin gemini codex rtk)

echo ""
echo "Stowing packages: ${PACKAGES[*]}"
# --no-folding for bin: ~/.local/bin/ is shared with other tools (pipx, npm, etc.)
NO_FOLD_PKGS=(bin nvim claude)
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

# --- Local config setup ---

touch ~/.shell_local
touch ~/.shell_secrets
mkdir -p ~/.claude
touch ~/.claude/CLAUDE.local.md

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
