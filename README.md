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
| Devcontainer | docker | `devcontainer/` (subtree from anthropics/claude-code) |
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
git subtree pull --prefix devcontainer \
  https://github.com/anthropics/claude-code.git main --squash
```

## Design decisions

**Stow over chezmoi** — [chezmoi](https://www.chezmoi.io/) is more powerful (templating, secrets, encryption) but adds complexity. Stow is simpler: just symlinks, no state, no learning curve. Machine-specific config is handled by `.local` files that are sourced if present. If the setup grows to 3+ machines with significantly different needs, chezmoi would be worth revisiting.

**No oh-my-zsh** — standalone plugins (autosuggestions, syntax-highlighting) + starship is faster and more transparent than a framework.

**Lean neovim** — no LSP, no completion engine, no treesitter. Neovim is used as a comfortable editor, not an IDE. Claude Code handles the heavy lifting.
