# History
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# Options
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP

# Emacs keybindings
bindkey -e

# Completion (compinit reuses its dump when the completion set is unchanged)
[[ -d ~/.grok/completions/zsh ]] && fpath=(~/.grok/completions/zsh $fpath)
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Shared config
[[ -f ~/.shell_config ]] && . ~/.shell_config

# Plugins
ZSH_PLUGINS=~/.zsh/plugins
[[ -f $ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source $ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh
# Syntax highlighting must be sourced last among plugins
[[ -f $ZSH_PLUGINS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
  source $ZSH_PLUGINS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# fzf
if command -v fzf &>/dev/null; then
  eval "$(fzf --zsh 2>/dev/null)" || true
fi

# Starship prompt
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# mise — polyglot version manager (node, terraform, ansible, ...).
# Replaces nvm. Unlike nvm (a shell function), mise ships real shims, so tools
# resolve in non-interactive contexts too: hooks, cron, systemd, /bin/sh.
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

# zoxide (smarter cd) — must be last
if command -v zoxide &>/dev/null; then
  export _ZO_DOCTOR=0  # suppress false positive in non-interactive shells (Claude Code)
  eval "$(zoxide init zsh --cmd cd)"
fi

# bun completions
[ -s "/home/tnunamak/.bun/_bun" ] && source "/home/tnunamak/.bun/_bun"
