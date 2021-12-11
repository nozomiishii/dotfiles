ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [ ! -d $ZINIT_HOME ]; then
  echo "Install zinit"
  sh -c "$(curl -fsSL https://git.io/zinit-install)"
  zinit self-update
fi

source "${ZINIT_HOME}/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

zinit ice depth=1; zinit light 'romkatv/powerlevel10k'
zinit snippet 'OMZL::git.zsh'
zinit snippet 'OMZP::git'
zinit snippet 'OMZP::kubectl'

zinit light 'g-plane/zsh-yarn-autocompletions'
zinit light 'zsh-users/zsh-completions'
zinit light 'zsh-users/zsh-syntax-highlighting'
# zinit light 'asdf-vm/asdf'
