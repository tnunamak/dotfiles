# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Shared config
[[ -f ~/.shell_config ]] && . ~/.shell_config

# fzf
if command -v fzf &>/dev/null; then
  eval "$(fzf --bash 2>/dev/null)" || true
fi

# zoxide (smarter cd)
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init bash --cmd cd)"
fi

# Starship prompt
if command -v starship &>/dev/null; then
  eval "$(starship init bash)"
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
