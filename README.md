# dotfiles-backup

## Setup
- concatenate .bashrc onto existing .bashrc, if there's already locally-relevant stuff there
- if using software that uses /bin/sh and sources .profile manually (which I've never run into but [evidently](https://superuser.com/a/789454) exists), may need to protect .bashrc sourcing in .profile with a check that we're actually using bash
- I've given up on separating anything between .profile and .bashrc; while theoretically there could be setup I'd want to do just once at login, I can't think what it might be, since any new shell (e.g., in tmux) will need all those envvars anyway?
- separate setup required for [The Fuck](https://github.com/nvbn/thefuck)
- may need to set up [Vundle](https://github.com/VundleVim/Vundle.vim)
- must run `:PluginInstall` in vim for plugins to take effect
- must clone tmux plugin manager (so it can then install all the other plugins):
```
git clone git@github.com:tmux-plugins/tpm.git ~/.tmux/plugins/tpm
```
- for git completion, must download script as follows:
```
curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.bash
```
