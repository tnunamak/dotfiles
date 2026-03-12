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

# Completion (cached for fast startup)
autoload -Uz compinit && compinit -C
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

# NVM (must be before zoxide since nvm hooks cd)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# zoxide (smarter cd) — must be last
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh --cmd cd)"
fi
