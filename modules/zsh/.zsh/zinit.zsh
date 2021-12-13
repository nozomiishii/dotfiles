ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [ ! -d $ZINIT_HOME ]; then
  echo "Install zinit"
  sh -c "$(curl -fsSL https://git.io/zinit-install)"
  zinit self-update
fi

source "${ZINIT_HOME}/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit


zinit snippet OMZL::git.zsh
zinit snippet OMZP::git

zinit light docker/cli
zinit ice as"completion"
zinit snippet OMZP::docker/_docker

zinit light zsh-users/zsh-syntax-highlighting
zinit light b4b4r07/enhancd
zinit light zdharma-continuum/history-search-multi-word
zinit light Aloxaf/fzf-tab
# zinit light zsh-users/zsh-completions
# zinit light g-plane/zsh-yarn-autocompletions


autoload -Uz compinit
compinit


zinit ice depth=1; zinit light romkatv/powerlevel10k
