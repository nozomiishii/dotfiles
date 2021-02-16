#!/usr/bin/env zsh
echo "\n🐉Starting Node Setup\n"

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.0/install.sh | zsh

nvm install --lts

echo "\n📦nvm installed\n"
node -v

npm i -g typescript
npm i -g firebase-tools
npm i -g yarn

echo "\n📦npm installed\n"
npm list -g --depth=0
