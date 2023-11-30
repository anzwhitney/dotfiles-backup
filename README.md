# dotfiles-backup

## Setup
- concatenate .profile onto existing .profile or .bash\_profile (or put relevant lines into .bashrc on platforms that don't source .profile)
- separate setup required for [The Fuck](https://github.com/nvbn/thefuck)
- may need to set up [Vundle](https://github.com/VundleVim/Vundle.vim)
- must run `:PluginInstall` in vim for plugins to take effect
- for git completion, must download script as follows:
```
curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.bash
```
