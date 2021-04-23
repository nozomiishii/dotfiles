#!/usr/bin/env zsh
echo "\n🐳 Starting Docker Setup\n"

# Install shell completion
# https://docs.docker.com/docker-for-mac/#install-shell-completion
etc=/Applications/Docker.app/Contents/Resources/etc
ln -s $etc/docker.zsh-completion /usr/local/share/zsh/site-functions/_docker
ln -s $etc/docker-compose.zsh-completion /usr/local/share/zsh/site-functions/_docker-compose
