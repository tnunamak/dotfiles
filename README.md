# dotfiles

Personal config for macOS and Ubuntu. Shell, editor, terminal, and tooling.

## Setup

### New machine

**Ubuntu:**
```bash
git clone https://github.com/tnunamak/dotfiles ~/code/dotfiles
cd ~/code/dotfiles
./ubuntu-setup.sh
./setup.sh
# Log out and back in for zsh
```

**macOS:**
```bash
git clone https://github.com/tnunamak/dotfiles ~/code/dotfiles
cd ~/code/dotfiles
./macos-setup.sh
./setup.sh
```

### After setup

Create machine-local configs as needed:

- `~/.shell_local` — machine-specific PATH, tool init (nvm, conda, etc.). See `shell/.shell_local.example`.
- `~/.shell_secrets` — API keys, tokens (never committed)
- `~/.gitconfig.local` — signing key, email. Copied from example on first run.
- `~/.claude/CLAUDE.local.md` — private context (infrastructure details, IPs, etc.)

## What's included

| Component | Tool | Config |
|-----------|------|--------|
| Shell | zsh + bash | `zsh/.zshrc`, `bash/.bashrc`, `shell/.shell_config` |
| Prompt | [starship](https://starship.rs) | `starship/.config/starship.toml` |
| Editor | [neovim](https://neovim.io) | `nvim/.config/nvim/init.lua` |
| Terminal | [kitty](https://sw.kovidgoyal.net/kitty/) | `kitty/.config/kitty/` |
| Git | git | `git/.gitconfig` |
| AI | [claude code](https://docs.anthropic.com/en/docs/claude-code) | `claude/.claude/` |
| Devcontainer | docker | `devcontainer/` (synced from anthropics/claude-code) |
| Scripts | devc, cursorc, claude-export | `bin/.local/bin/` |

### Key tools

zsh, [starship](https://starship.rs), [fzf](https://github.com/junegunn/fzf), [zoxide](https://github.com/ajeetdsouza/zoxide), [ripgrep](https://github.com/BurntSushi/ripgrep), neovim, [GNU Stow](https://www.gnu.org/software/stow/)

## Managing

Configs are symlinked into `~` via GNU Stow. Each top-level directory is a "package" whose contents mirror the home directory structure. To re-apply after changes:

```bash
./setup.sh
```

To update the devcontainer config from upstream:

```bash
./sync-devcontainer.sh
# Review the diff, then commit if happy
```

## Kitty + tmux

**SSH** is aliased to `kitten ssh` when running in kitty. This automatically copies terminfo to remote hosts, fixing the `xterm-kitty: unknown terminal type` error that breaks tmux over SSH. Works transparently — just `ssh host` as normal.

**tmux essentials:**
- `ctrl+b w` — tree view of all sessions/windows/panes (the "menu")
- `ctrl+b c` — new window, `ctrl+b 0-9` — switch window
- `ctrl+b %` — vertical split, `ctrl+b "` — horizontal split
- `ctrl+b z` — zoom pane to fullscreen (toggle)
- `ctrl+b ,` — rename window
- `tmux new -s name` — named session, `tmux a -t name` — reattach

Note: tmux keybindings don't work inside Claude Code (it captures input). Use mouse mode (`set -g mouse on` in `.tmux.conf`) to click between tmux panes while Claude is running.

**kitty essentials:**
- `ctrl+shift+f1` — show all keyboard shortcuts
- `ctrl+shift+f2` — open full config with docs
- `ctrl+shift+f5` — reload config
- `ctrl+shift+e` — clickable links/paths/hashes in terminal output
- `ctrl+shift+t` — new tab, `ctrl+shift+right/left` — switch tabs
- `ctrl+shift+enter` — new split (works as tmux alternative for local use)

## Design decisions

**Stow over chezmoi** — [chezmoi](https://www.chezmoi.io/) is more powerful (templating, secrets, encryption) but adds complexity. Stow is simpler: just symlinks, no state, no learning curve. Machine-specific config is handled by `.local` files that are sourced if present. If the setup grows to 3+ machines with significantly different needs, chezmoi would be worth revisiting.

**No oh-my-zsh** — standalone plugins (autosuggestions, syntax-highlighting) + starship is faster and more transparent than a framework.

**Lean neovim** — no LSP, no completion engine, no treesitter. Neovim is used as a comfortable editor, not an IDE. Claude Code handles the heavy lifting.
