setopt APPEND_HISTORY
setopt AUTO_CD
setopt C_BASES
setopt NO_CASE_GLOB
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_LEX_WORDS
setopt HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY

PROMPT='%1~ %# '

if [ -f ~/.zsh_aliases ]; then
    source ~/.zsh_aliases
fi

# PipX
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"
