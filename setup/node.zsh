#!/usr/bin/env zsh
echo "\n🐉 Starting Node Setup\n"
# How to remove nvm
# rm -rf $NVM_DIR ~/.npm ~/.bower

if type node > /dev/null 2>&1 ; then
  echo "🐉 Node exists, skip install"
  node -v
else
  echo "🐉 Node doesn't exist, continuing with install"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.0/install.sh | zsh
  
  source ~/.zshrc 
  nvm install --lts
  node -v 
  echo "📦 nvm installed"
fi

npm i -g typescript
npm i -g firebase-tools
npm i -g yarn

echo "📦 npm installed"
npm list -g --depth=0
