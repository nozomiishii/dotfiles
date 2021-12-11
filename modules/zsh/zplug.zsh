if [ ! -f ~/.zplug/init.zsh ]; then
  echo "Install zplug"
  curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
fi
source ~/.zplug/init.zsh

POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
zplug "romkatv/powerlevel10k", as:theme, depth:1
zplug "plugins/git", from:oh-my-zsh, lazy:true
zplug "zsh-users/zsh-syntax-highlighting", defer:2
zplug "zsh-users/zsh-completions", lazy:true
zplug "zsh-users/zsh-history-substring-search", lazy:true
zplug "docker/cli", use:"/Applications/Docker.app/Contents/Resources/etc/docker.zsh-completion", lazy:true


# Install plugins if there are plugins that have not been installed
if ! zplug check; then
  printf "Install? [y/N]: "
  if read -q; then
    echo; zplug install
  fi
fi
zplug load
