PROMPT='%1~ %# '

export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_ENV_HINTS=1

if [ -f ~/.zsh_aliases ]; then
    source ~/.zsh_aliases
fi
if [[ -f "$HOME/.zsh_options" ]]; then
    source "$HOME/.zsh_options"
fi

eval "$(pyenv init - zsh)"
