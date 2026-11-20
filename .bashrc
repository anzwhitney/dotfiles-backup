
# always use vim
export EDITOR=vim

# complete partial commands from history with up & down keys
if [[ $- == *i* ]]; then
  bind '"[A":history-search-backward'
  bind '"[B":history-search-forward'
fi

# update .bash_history in realtime
shopt -s histappend
if [[ $- == *i* ]]; then
  PROMPT_COMMAND="history -a;$PROMPT_COMMAND"
fi

# and keep bash history forever
export HISTFILESIZE=
export HISTSIZE=

# some bash sessions truncate ~/.bash_history on close
export HISTFILE=~/.bash_eternal_history

# no need to keep duplicates in history
export HISTCONTROL=erasedups

# Set PATH, MANPATH, etc., for Homebrew.
eval "$(/opt/homebrew/bin/brew shellenv)"

# Setup for the delightful github.com/nvbn/thefuck
eval "$(thefuck --alias)"

# enable git completion, if the script is present
test -f ~/.git-completion.bash && . $_

export PS1="\u@\h:\W \t \\$ \[$(tput sgr0)\]"
