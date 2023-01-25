
# complete partial commands from history with up & down keys
bind '"[A":history-search-backward'
bind '"[B":history-search-forward'

# opam configuration
[[ ! -r /Users/anz/.opam/opam-init/init.zsh ]] || source /Users/anz/.opam/opam-init/init.zsh  > /dev/null 2> /dev/null

# Set PATH, MANPATH, etc., for Homebrew.
eval "$(/opt/homebrew/bin/brew shellenv)"

# Setup for the delightful github.com/nvbn/thefuck
eval $(thefuck --alias)

export PS1="\u@\h:\w \t \\$ \[$(tput sgr0)\]"

source ~/.bashrc
