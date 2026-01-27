export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_ENV_HINTS=1
export PROMPT='%1~ %# '
export ZDOTDIR="${ZDOTDIR:-$HOME}"

[[ -f "$ZDOTDIR/.zsh_aliases" ]] && source "$ZDOTDIR/.zsh_aliases"
[[ -f "$ZDOTDIR/.zsh_options" ]] && source "$ZDOTDIR/.zsh_options"
[[ -f "$ZDOTDIR/.py-auto-venv.zsh" ]] && source "$ZDOTDIR/.py-auto-venv.zsh"

eval "$(pyenv init - zsh)"
