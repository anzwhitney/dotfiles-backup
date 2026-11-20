# dotfiles-backup

## Setup
- `./install.sh` symlinks the Claude Code config in `claude/` (CLAUDE.md, RTK.md, the status line script and the `block-rm-rf.py` hook) into `~/.claude`. It is idempotent. `settings.json` and `settings.local.json` are not tracked.
- Everything else is copied by hand. tmux is applied by hand on purpose: the tmux-autoreload plugin re-sources `~/.tmux.conf` into running sessions as soon as it changes, so copy `.tmux.conf` over only when ready for that.
- concatenate .bashrc onto existing .bashrc, if there's already locally-relevant stuff there
- On macOS, bash login shells (including tmux panes) read `~/.bash_profile` and skip `~/.profile`, so put `source ~/.bashrc` in `~/.bash_profile`. `.profile` is only for software that sources it manually under `/bin/sh`; if that happens, protect the `.bashrc` sourcing with a check that we're actually using bash.
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
