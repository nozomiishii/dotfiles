#!/bin/bash

# Change Directory
setopt autocd

# Change Directory history
DIRSTACKSIZE=8
setopt autopushd

# Command history
HISTFILE=$HOME/.zsh_history
HISTSIZE=50000
SAVEHIST=50000

# Do not save duplicate history
setopt hist_ignore_all_dups

# No history when starting command with space
setopt hist_ignore_space

# Share history between terminals
setopt share_history
