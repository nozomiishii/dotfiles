### Added by Zinit's installer

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -d "$(dirname $ZINIT_HOME)" ]]; then
  print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" && \
    print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
    print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "${ZINIT_HOME}/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# snippet
zinit wait lucid for \
    OMZL::git.zsh \
  atload"unalias grv" \
    OMZP::git

zinit snippet OMZP::kubectl
alias k=kubectl

# yarn completions
zinit ice atload"zpcdreplay" atclone'./zplug.zsh'
zinit light g-plane/zsh-yarn-autocompletions

# Plugins
zinit wait lucid light-mode for \
  atinit"zicompinit; zicdreplay" \
    zsh-users/zsh-syntax-highlighting \
  blockf atpull'zinit creinstall -q .' \
    zsh-users/zsh-completions

# asdf
zinit light asdf-vm/asdf

# powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
### End of Zinit's installer chunk
