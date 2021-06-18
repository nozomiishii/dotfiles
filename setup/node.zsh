#!/usr/bin/env zsh
echo "\n🐉 Starting Node Setup\n"


if type node > /dev/null 2>&1 ; then
  echo "🐉 Node exists, skip install"
  node -v
else
  echo "🐉 Node doesn't exist, continuing with install"
  n lts
  node -v 
  echo "📦 n installed"
fi

npm i -g typescript
npm i -g firebase-tools
npm i -g yarn
npm i -g vercel

echo "📦 npm installed"
npm list -g --depth=0
