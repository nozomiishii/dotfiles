if [ ! -d $ZINIT_HOME ]; then
  echo "Install zinit"
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi


# plugins=(
#   last-working-dir
#   git
#   docker
#   docker-compose
#   zsh-syntax-highlighting
#   zsh-completions
# )

# source $ZSH/oh-my-zsh.sh
