# https://github.com/zsh-users/antigen
ANTIGEN_PATH="$HOME/.antigen"

if [ ! -d "$ANTIGEN_PATH" ]; then
  echo "Install antigen"
  mkdir -p "$ANTIGEN_PATH"
  curl -L git.io/antigen > "$ANTIGEN_PATH/antigen.zsh"
fi

source "$ANTIGEN_PATH/antigen.zsh"

antigen use oh-my-zsh

antigen bundle git
antigen bundle plugin-name
antigen bundle command-not-found
antigen bundle docker
antigen bundle lilithium-hydride/history-search-multi-word
antigen bundle zsh-users/zsh-syntax-highlighting
# antigen bundle zsh-users/zsh-completions
# antigen bundle Aloxaf/fzf-tabxxxxxxx
# antigen bundle b4b4r07/enhancd

# autoload -Uz compinit
# compinit

antigen apply
