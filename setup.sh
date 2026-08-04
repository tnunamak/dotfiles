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

    # Linuxbrew — OPT-IN (SETUP_INSTALL_LINUXBREW=1 ./setup.sh). apt is the
    # primary package manager on this box, so brew is only worth its ~500MB and
    # its own update channel on a machine that actually needs a formula apt
    # lacks. Off by default keeps the default run from silently adding a second
    # package manager. Shell wiring is unconditional in shell/.shell_config
    # (guarded on the binary existing), so a box that installed it out-of-band
    # still gets a working brew without re-running with the flag.
    #
    # NONINTERACTIVE=1 is the installer's supported non-prompting mode; the
    # `sudo -v` at the top of this script has already cached credentials, so it
    # will not stall waiting for a password. The installer only PRINTS shellenv
    # instructions (verified against install.sh) — it does not edit rc files, so
    # it cannot clobber the stow-managed ~/.zshrc symlink.
    if [[ "${SETUP_INSTALL_LINUXBREW:-0}" == "1" ]] && ! [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
      echo "Installing Linuxbrew (SETUP_INSTALL_LINUXBREW=1)..."
      NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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
    brew install neovim git ripgrep fzf starship zoxide stow uv git-filter-repo socat tmux jq coreutils 2>&1 | grep -v 'already installed'
    for cask in kitty docker; do
      brew list --cask "$cask" &>/dev/null || brew install --cask "$cask"
    done
    brew upgrade neovim git ripgrep fzf starship zoxide stow uv git-filter-repo socat tmux jq coreutils 2>&1 | grep -v 'already.*latest'
    ;;
  *)
    echo "Unsupported platform: $(uname)"
    exit 1
    ;;
esac

# --- Cross-platform tool installs ---

# Node.js (via mise). mise replaced nvm: nvm is a shell function, so it is
# invisible to anything non-interactive (hooks, cron, systemd, /bin/sh). mise
# ships real shims, and manages terraform/ansible/etc. from the same config.
if ! command -v mise &>/dev/null; then
  curl https://mise.run | sh
  export PATH="$HOME/.local/bin:$PATH"
fi

# Global npm packages, installed after every node version install.
# Shared list lives in npm-global-packages.txt; host-only extras appended here.
# NOTE: @anthropic-ai/claude-code is intentionally NOT listed — Claude Code
# migrated from npm to a native installer (installs to ~/.local/bin/claude).
# mise reads $HOME/.default-npm-packages (its nvm-compatible mechanism).
# DEPRECATION: mise documents this file as legacy, targeted for removal late
# 2027. The successor is a per-tool postinstall hook in ~/.config/mise/config.toml:
#   node = { version = "lts", postinstall = "npm i -g <packages>" }
# That syntax parses (verified with `mise config get`), but it was NOT verified
# to actually fire on a clean install, so the migration is deliberately deferred.
# Prove postinstall runs before switching, or globals will vanish silently on the
# next node upgrade.
{
  grep -v '^\s*#' "$DOTFILES_DIR/npm-global-packages.txt" | grep -v '^\s*$'
  echo "@devcontainers/cli"
} > "$HOME/.default-npm-packages"

mise use -g node@lts 2>/dev/null || true

# NOTE on non-interactive callers (hooks, cron, systemd, /bin/sh):
# `mise activate` in .zshrc is a shell hook and does not exist outside a shell,
# so bare `node` will not resolve there. Do NOT try to fix this by exporting a
# PATH from ~/.profile: that file sources .shell_config, which uses bash-only
# syntax, aborts under dash, and resets PATH anyway (verified).
# The working fix is an ABSOLUTE SHIM PATH in the caller's command:
#   $HOME/.local/share/mise/shims/node
# That shim resolves with an empty environment (verified: `env -i` runs it fine)
# and stays correct across node upgrades, because it dispatches through mise.

# uv (Python package manager)
if ! command -v uv &>/dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Infisical CLI (canonical store for global shell secrets from secrets.vivid.fish;
# see shell/.shell_config. After install, run once per machine: infisical login --domain=https://secrets.vivid.fish)
if ! command -v infisical &>/dev/null; then
  if [[ "$OSTYPE" == darwin* ]]; then
    brew install infisical/get-cli/infisical 2>&1 | grep -v 'already installed' || true
  else
    "$DOTFILES_DIR/bin/.local/bin/infisical-update"
  fi
fi

# direnv (per-project env loading — pairs with Infisical via .envrc `eval "$(infisical export ...)"`)
if ! command -v direnv &>/dev/null; then
  if [[ "$OSTYPE" == darwin* ]]; then
    brew install direnv 2>&1 | grep -v 'already installed' || true
  else
    sudo apt-get install -y direnv
  fi
fi

# Claude Code (native installer — no longer distributed via npm)
# If an old npm-global copy exists in the node bin dir, remove it so the native
# binary at ~/.local/bin/claude takes precedence.
if npm ls -g --depth=0 @anthropic-ai/claude-code &>/dev/null; then
  npm uninstall -g @anthropic-ai/claude-code
fi
if ! [[ -x "$HOME/.local/bin/claude" ]]; then
  curl -fsSL https://claude.ai/install.sh | bash
fi

# kitty (upstream installer — Ubuntu's archive freezes each release at its
# snapshot version (26.04 = 0.45 forever) and the only PPA died in 2022;
# sw.kovidgoyal.net is the supported channel for current releases). Installs
# to ~/.local/kitty.app; apt's kitty is shadowed by ~/.local/bin PATH
# precedence. Upgrading = delete ~/.local/kitty.app and re-run setup.sh.
if ! [[ -x "$HOME/.local/kitty.app/bin/kitty" ]]; then
  curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
fi
ln -sfn "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/bin/kitty"
ln -sfn "$HOME/.local/kitty.app/bin/kitten" "$HOME/.local/bin/kitten"
# Desktop integration per https://sw.kovidgoyal.net/kitty/binary/ — patched
# copies into ~/.local/share/applications are runtime state, not stowed.
mkdir -p "$HOME/.local/share/applications"
cp "$HOME/.local/kitty.app/share/applications/kitty.desktop" "$HOME/.local/share/applications/"
cp "$HOME/.local/kitty.app/share/applications/kitty-open.desktop" "$HOME/.local/share/applications/" 2>/dev/null || true
sed -i "s|Icon=kitty|Icon=$HOME/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g; s|Exec=kitty|Exec=$HOME/.local/bin/kitty|g" "$HOME/.local/share/applications/kitty"*.desktop

# Antigravity CLI. Google does not publish the standalone `agy` CLI through
# its APT repository; the official installer is the supported CLI channel.
# Stage it under a temporary HOME so its shell-profile setup cannot modify
# files owned by this dotfiles repo, then install only the verified binary.
if ! command -v agy &>/dev/null; then
  mkdir -p "$HOME/.tmp" "$HOME/.local/bin"
  AGY_STAGE=$(mktemp -d "$HOME/.tmp/agy-install.XXXXXX")
  mkdir -p "$AGY_STAGE/home" "$AGY_STAGE/bin"
  curl -fsSL https://antigravity.google/cli/install.sh -o "$AGY_STAGE/install.sh"
  HOME="$AGY_STAGE/home" \
    bash "$AGY_STAGE/install.sh" --dir "$AGY_STAGE/bin"
  install -m 0755 "$AGY_STAGE/bin/agy" "$HOME/.local/bin/agy"
  rm -rf "$AGY_STAGE"
  unset AGY_STAGE
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
# Hook command is `rtk hook claude` (built-in subcommand), wired in stowed claude/.claude/settings.json.
# DISABLED: user opts out of auto-updates 2026-08-01.
# if ! command -v rtk &>/dev/null; then
#   curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
# fi

# Coolify CLI (self-hosted PaaS management)
# The official installer supports a user-scoped install, which keeps its binary in
# ~/.local/bin alongside the other user-managed CLIs and avoids another sudo-owned tool.
if ! command -v coolify &>/dev/null; then
  curl -fsSL https://raw.githubusercontent.com/coollabsio/coolify-cli/main/scripts/install.sh | bash -s -- --user
fi

# Headroom MCP tools. Keep this MCP-only by default until `headroom wrap` is
# benchmarked against rtk/context-mode; wrapping would add another
# agent/provider traffic-interception layer. The proxy extra is still needed
# because Headroom 0.24.0 eagerly imports proxy modules even for `headroom mcp`.
if ! command -v headroom &>/dev/null || ! env HEADROOM_TELEMETRY=off HEADROOM_TELEMETRY_WARN=off headroom mcp serve --help &>/dev/null; then
  uv tool install --upgrade "headroom-ai[mcp,proxy]"
fi

# Foundry (Ethereum toolkit: cast, forge, anvil, chisel)
# Keep ~/.foundry/bin in PATH before running the installer so its profile-file
# patcher sees the path already present; stowed shell config owns PATH setup.
export PATH="$HOME/.foundry/bin:$PATH"
if ! command -v foundryup &>/dev/null; then
  curl -fsSL https://foundry.paradigm.xyz | bash
fi
if ! command -v cast &>/dev/null || ! command -v forge &>/dev/null || ! command -v anvil &>/dev/null; then
  foundryup
fi

# Set zsh as default shell
if [[ "$SHELL" != */zsh ]]; then
  sudo chsh -s "$(which zsh)" "$USER"
fi

# --- Stow ---

PACKAGES=(nvim zsh bash shell kitty starship git claude bin gemini codex qwen tmux daisy-systemd playwright-mcp-systemd bee-watchdog-systemd llama-bee-systemd)
# DISABLED rtk 2026-08-01 (stow package comment-out; binary install also disabled above)

echo ""
echo "Stowing packages: ${PACKAGES[*]}"
# --no-folding:
# - bin: ~/.local/bin/ is shared with other tools (pipx, npm, etc.)
# - tmux: systemd drop-in dirs (e.g. tmux.service.d) must be real dirs,
#   not symlinks — systemd does not follow directory symlinks for drop-ins.
# - *-systemd facade packages: keep the user-unit parents real while linking
#   only their dedicated units and drop-ins, which avoids claiming unrelated
#   user units.
NO_FOLD_PKGS=(bin nvim claude qwen tmux daisy-systemd playwright-mcp-systemd bee-watchdog-systemd llama-bee-systemd)

# User units used to be stowed from the broad `systemd` package. They now live
# behind dedicated facade packages, but Stow will not transfer ownership from
# one package to another automatically: it refuses to replace a link it does
# not own and aborts the whole run. Remove only links whose lexical target is
# the old package (not the new facade, which resolves to the same canonical
# source), then let --restow recreate the new ownership below.
#
# Derived from the facade packages themselves rather than a hand-maintained
# path list. The hand-maintained version silently omitted playwright-mcp
# (added 2026-07-23), so every `./setup.sh` aborted at that package until
# 2026-08-02 — and the abort happens mid-loop, leaving later packages
# unstowed. Enumerating the packages means a new facade cannot reintroduce
# that failure.
if [[ "$(uname)" == "Linux" ]]; then
  migrate_legacy_systemd_link() {
    local relative="$1"
    local target="$HOME/$relative"
    local legacy="$DOTFILES_DIR/systemd/$relative"
    [[ -L "$target" ]] || return 0

    local raw_target lexical_target lexical_legacy
    raw_target="$(readlink "$target")"
    # A legacy link may be absolute (hand-made) or relative (Stow-made).
    # Joining an absolute raw target onto its own dirname produces nonsense
    # like $HOME/.config/systemd/user/home/tnunamak/code/... which silently
    # never matches, so the migration no-ops and Stow aborts the whole run.
    if [[ "$raw_target" == /* ]]; then
      lexical_target="$(realpath -sm "$raw_target")"
    else
      lexical_target="$(realpath -sm "$(dirname "$target")/$raw_target")"
    fi
    lexical_legacy="$(realpath -sm "$legacy")"
    [[ "$lexical_target" == "$lexical_legacy" ]] || return 0

    echo "Migrating legacy Stow ownership: $relative"
    unlink "$target"
  }

  # Scope the scan to each facade's user-unit tree: a facade may also ship
  # helper scripts (daisy-systemd has ~/.local/bin/*), which never had legacy
  # `systemd`-package ownership and should not be walked.
  #
  # Drop-in *directories* first: a legacy run may have folded a whole
  # `foo.service.d` dir into one symlink, which must become a real directory
  # before any file inside it can be linked.
  for pkg in "${PACKAGES[@]}"; do
    [[ "$pkg" == *-systemd ]] || continue
    unit_root="$DOTFILES_DIR/$pkg/.config/systemd/user"
    [[ -d "$unit_root" ]] || continue
    while IFS= read -r dropin_dir; do
      relative="${dropin_dir#"$DOTFILES_DIR/$pkg/"}"
      migrate_legacy_systemd_link "$relative"
      mkdir -p "$HOME/$relative"
    done < <(find "$unit_root" -type d -name '*.service.d' 2>/dev/null)
  done

  # Then every unit/drop-in the facades provide.
  for pkg in "${PACKAGES[@]}"; do
    [[ "$pkg" == *-systemd ]] || continue
    unit_root="$DOTFILES_DIR/$pkg/.config/systemd/user"
    [[ -d "$unit_root" ]] || continue
    while IFS= read -r entry; do
      migrate_legacy_systemd_link "${entry#"$DOTFILES_DIR/$pkg/"}"
    done < <(find "$unit_root" \( -type l -o -type f \) 2>/dev/null)
  done
  unset relative unit_root
fi

# Remove files that tools create before stow can link them
# (claude/rtk init write ~/.claude/settings.json as a regular file)
[[ -f ~/.claude/settings.json && ! -L ~/.claude/settings.json ]] && rm ~/.claude/settings.json
# (gemini-cli writes ~/.gemini/settings.json as a regular file on first run;
#  also ~/.codex/hooks.json if anything has touched it)
[[ -f ~/.gemini/settings.json && ! -L ~/.gemini/settings.json ]] && rm ~/.gemini/settings.json
[[ -f ~/.codex/hooks.json && ! -L ~/.codex/hooks.json ]] && rm ~/.codex/hooks.json
# (qwen writes ~/.qwen/settings.json as a regular file on first run / /auth)
[[ -f ~/.qwen/settings.json && ! -L ~/.qwen/settings.json ]] && rm ~/.qwen/settings.json

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

# Re-apply patches to tmux-assistant-resurrect's save script. TPM auto-updates
# can wipe in-place sed patches; the script is idempotent and also runs at
# every tmux-restore.service start as ExecStartPre, so this is belt+suspenders.
PATCH_SCRIPT="$HOME/.config/tmux/scripts/patch-assistant-resurrect.sh"
if [[ -x "$PATCH_SCRIPT" ]]; then
  "$PATCH_SCRIPT" || true
fi

# Enable tmux and desktop-layout restore units (Linux only — stowed by the
# `tmux` package) plus the host Playwright MCP server. Desktop restore
# self-gates when kitty is already present.
# Replaces tmux-continuum's boot-time restore, which races against its own
# auto-save and the first kitty attach. See CLAUDE.md for the debugging
# history that led to this decision.
if [[ "$(uname)" == "Linux" ]] && command -v systemctl &>/dev/null; then
  systemctl --user daemon-reload
  # ydotool packages the working user unit as ydotool.service. A legacy local
  # ydotoold.service launches a separately-built daemon with the same default
  # socket and races it at boot. Disable only its enablement links; leave the
  # legacy unit file and any currently-running process untouched so setup is
  # safe to re-run and does not unexpectedly interrupt input automation.
  systemctl --user disable ydotoold.service 2>/dev/null || true
  systemctl --user enable tmux-restore.service desktop-layout-restore.service desktop-layout-snapshot.timer 2>/dev/null || true
  systemctl --user enable playwright-mcp.service 2>/dev/null || true
fi

# Codex: disable alternate-screen mode so the TUI runs inline and kitty's
# native scrollback works. tui.alternate_screen=auto only opts out for
# Zellij; on kitty+tmux the user still gets a bounded alt-screen viewport
# that wraps. Idempotently insert the [tui] section if missing.
# Upstream config: github.com/openai/codex/pull/8555
CODEX_CONFIG="$HOME/.codex/config.toml"
if [[ -f "$CODEX_CONFIG" ]] && ! grep -qF '[tui]' "$CODEX_CONFIG"; then
  # Find first existing TOML section ([projects...], [profiles...], etc.)
  # and insert our block before it. If no sections exist, append at end.
  first_section_line=$(grep -n '^\[' "$CODEX_CONFIG" | head -1 | cut -d: -f1)
  if [[ -n "$first_section_line" ]]; then
    sed -i "${first_section_line}i [tui]\nalternate_screen = \"never\"\n" "$CODEX_CONFIG"
  else
    printf '\n[tui]\nalternate_screen = "never"\n' >> "$CODEX_CONFIG"
  fi
  echo "Patched Codex config: tui.alternate_screen=never"
fi

# context-mode disabled 2026-06-29 (recoverable — uncomment to re-enable).
# Codex: register context-mode MCP server. Stow can't manage config.toml because
# Codex mutates it (per-project trust levels), so we idempotently append.
# if [[ -f "$CODEX_CONFIG" ]] && ! grep -qF '[mcp_servers.context-mode]' "$CODEX_CONFIG"; then
#   printf '\n[mcp_servers.context-mode]\ncommand = "context-mode"\n' >> "$CODEX_CONFIG"
#   echo "Patched Codex config: registered context-mode MCP server"
# fi

# Codex: enable hooks. The feature flag was renamed from `codex_hooks` to
# `hooks`; migrate older configs and ensure the current flag is enabled.
# https://developers.openai.com/codex/hooks
if [[ -f "$CODEX_CONFIG" ]]; then
  if grep -qE '^\s*codex_hooks\s*=' "$CODEX_CONFIG"; then
    sed -i 's/^\([[:space:]]*\)codex_hooks\([[:space:]]*=\)/\1hooks\2/' "$CODEX_CONFIG"
    echo "Patched Codex config: migrated codex_hooks to hooks"
  fi

  if ! grep -qE '^\s*hooks\s*=\s*true' "$CODEX_CONFIG"; then
    if grep -qF '[features]' "$CODEX_CONFIG"; then
      sed -i '/^\[features\]/a hooks = true' "$CODEX_CONFIG"
    else
      printf '\n[features]\nhooks = true\n' >> "$CODEX_CONFIG"
    fi
    echo "Patched Codex config: enabled hooks"
  fi
fi

# Claude Code: install plugins. `enabledPlugins` in settings.json only takes
# effect after the marketplace is cloned to ~/.claude/plugins/marketplaces/<name>/
# and the plugin is installed. Both are runtime state Claude Code mutates, so
# we drive them imperatively via the CLI. `marketplace add` and `install` are
# both idempotent (no-op if already present).
if command -v claude &>/dev/null; then
  # marketplace_name:source_spec — source_spec is what `claude plugin marketplace add` accepts
  declare -A CC_MARKETPLACES=(
    # context-mode disabled 2026-06-29 (recoverable — uncomment to re-enable):
    # [context-mode]="mksglu/context-mode"
  )
  for mp in "${!CC_MARKETPLACES[@]}"; do
    if ! claude plugin marketplace list 2>/dev/null | grep -qF "$mp"; then
      claude plugin marketplace add "${CC_MARKETPLACES[$mp]}" || echo "WARN: failed to add marketplace $mp"
    fi
  done
  # context-mode disabled 2026-06-29 (recoverable — restore "context-mode@context-mode" to re-enable):
  for plugin in; do
    if ! claude plugin list 2>/dev/null | grep -qF "$plugin"; then
      claude plugin install "$plugin" || echo "WARN: failed to install $plugin"
    fi
  done
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
  npx -y skills add "$src" -g -a claude-code -a codex -a gemini-cli -a qwen-code --skill '*' -y
done

echo ""
echo "Symlinking locally-authored skills..."
for agent_dir in ~/.claude ~/.codex ~/.gemini ~/.qwen; do
  mkdir -p "$agent_dir/skills"
  for skill in "$DOTFILES_DIR"/ai/skills/local/*/; do
    [[ -d "$skill" ]] || continue
    skill_name=$(basename "$skill")
    ln -sfn "${skill%/}" "$agent_dir/skills/$skill_name"
  done
done

# minnows — standalone repo of small authored agent tools (convo, uncompact, ...).
# Each tool is a CLI; a skill is optional. minnows owns its own install (vendors a
# shared lib into each shipped skill, symlinks skills into the agents + bins onto
# PATH). We clone-or-pull then delegate. See github.com/tnunamak/minnows.
echo ""
echo "Setting up minnows (authored agent tools)..."
MINNOWS_DIR="$HOME/code/minnows"
if [[ -d "$MINNOWS_DIR/.git" ]]; then
  git -C "$MINNOWS_DIR" pull --ff-only --quiet || echo "  (minnows pull skipped — local changes or offline)"
elif [[ ! -d "$MINNOWS_DIR" ]]; then
  git clone --quiet https://github.com/tnunamak/minnows.git "$MINNOWS_DIR" \
    || echo "  (minnows clone failed — skipping; clone it manually later)"
fi
[[ -f "$MINNOWS_DIR/install.sh" ]] && bash "$MINNOWS_DIR/install.sh"

# waspflow — live multi-provider agent orchestration (Claude / Codex / Grok).
# Clone-or-pull then install.sh (symlink ~/.local/bin/waspflow). Tracks main.
echo ""
echo "Setting up waspflow (agent orchestration)..."
WASPFLOW_DIR="$HOME/code/waspflow"
if [[ -d "$WASPFLOW_DIR/.git" ]]; then
  git -C "$WASPFLOW_DIR" pull --ff-only --quiet || echo "  (waspflow pull skipped — local changes or offline)"
elif [[ ! -d "$WASPFLOW_DIR" ]]; then
  git clone --quiet https://github.com/tnunamak/waspflow.git "$WASPFLOW_DIR" \
    || echo "  (waspflow clone failed — skipping; clone it manually later)"
fi
[[ -f "$WASPFLOW_DIR/install.sh" ]] && bash "$WASPFLOW_DIR/install.sh"

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


# Per-host tier: machine-specific config that isn't universal (hardware-tuned
# sysctls, host-only services/packages, KDE-only bits). Keyed by hostname so a
# fresh machine reproduces ITS environment, not a one-size-fits-all blob.
#   hosts/<hostname>/host.sh  — idempotent installer/configurer for that box
# Universal config stays in the stow packages above; this is the disaster-
# recovery path for the per-machine extras. See hosts/README.md.
HOST_DIR="$DOTFILES_DIR/hosts/$(hostname -s)"
if [[ -x "$HOST_DIR/host.sh" ]]; then
  echo ""
  echo "Running per-host setup for $(hostname -s)..."
  "$HOST_DIR/host.sh" || echo "  (host.sh exited non-zero — review output above)"
fi


echo ""
echo "Done. Restart your shell or run: exec zsh"
