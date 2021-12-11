#!/usr/bin/env zsh
echo "\n🧝🏻‍♀️ Starting Third-Party Software Setup\n"
set -e


APP_PREFERENCES="$HOME/dotfiles/apps"


echo "\n🦄 Cloning repositoris...\n"
CODE_DIR="$HOME/Code"
if [ ! -d $CODE_DIR ]; then
  mkdir -p $CODE_DIR
fi

if [ ! -d $CODE_DIR/nozomiishii/dev ]; then
  git clone https://github.com/nozomiishii/dev $CODE_DIR/nozomiishii/dev
fi


echo '- 👾 NeoVim'
if [[ ! -e "$HOME/.config/nvim" ]]; then
  mkdir -p $HOME/.config/nvim
fi
ln -nfsv "$HOME/dotfiles/nvim/init.vim" "$HOME/.config/nvim/init.vim"
ln -nfsv "$HOME/dotfiles/nvim/coc-settings.json" "$HOME/.config/nvim/coc-settings.json"
# Turn key repear on
defaults write -g ApplePressAndHoldEnabled -bool false
# Install vim-plug
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'


echo "- 🐢 tmux"
ln -nfsv "$HOME/dotfiles/.tmux.conf" "$HOME/.tmux.conf"


echo "- 🐉 Node"
if type node > /dev/null 2>&1 ; then
  echo "🐉 Node exists, skip install"
  node -v
else
  echo "🐉 Node doesn't exist, continuing with install"
  n lts
  node -v 
  echo "📦 n installed"

  npm i -g yarn
  npm i -g typescript
  npm i -g firebase-tools
  npm i -g vercel
  npm i -g @nestjs/cli

  echo "📦 npm installed"
  npm list -g --depth=0
fi

echo "-🐍 Python"
python_version = 3.9.4
pyenv install $python_version
pyenv global $python_version

source ~/.zshrc 

echo "🐍 pyenv version"
pyenv versions

echo "🐍 python version"
python -V

echo "🐍 Install dependencies"
pip3 install pynvim




echo "- 🦖 C#"
if [ -d $HOME/.omnisharp ]; then
  ln -fs "$HOME/dotfiles/apps/omnisharp/omnisharp.json" "$HOME/.omnisharp/omnisharp.json"
else
  mkdir "$HOME/.omnisharp"
  touch "$HOME/.omnisharp/omnisharp.json"
fi

# check if it works
ls -l "$HOME/.omnisharp/omnisharp.json"



echo "- 🐟 VSCode"
VSCODE_USERDATA="$HOME/Library/Application Support/Code/User"
CUSTOMIZED_VSCODE_USERDATA="$APP_PREFERENCES/VSCode"

VSCODE_USERDATA_ITEMS=("keybindings.json" "settings.json" "snippets")
for item in ${VSCODE_USERDATA_ITEMS[@]}; do
  rm -rf "$VSCODE_USERDATA/$item"
  ln -nfsv "$CUSTOMIZED_VSCODE_USERDATA/$item" "$VSCODE_USERDATA/$item"
  if [ -L "$VSCODE_USERDATA/$item" ]; then
    echo "Created Link: $VSCODE_USERDATA/$item"
  else
    echo "Error: Creating Links fails"
  fi
done
ls -l "$VSCODE_USERDATA"


echo "- 🍎 Xcode"
XCODE_USERDATA="$HOME/Library/Developer/Xcode/UserData"
CUSTOMIZED_XCODE_USERDATA="$APP_PREFERENCES/Xcode/UserData"

XCODE_USERDATA_ITEMS=("CodeSnippets" "FontAndColorThemes" "KeyBindings")
for item in ${XCODE_USERDATA_ITEMS[@]}; do
  # Need rm -rf to symbolic-link KeyBindings folder
  rm -rf "$XCODE_USERDATA/$item"
  ln -nfsv "$CUSTOMIZED_XCODE_USERDATA/$item" "$XCODE_USERDATA/$item"
  if [ -L "$XCODE_USERDATA/$item" ]; then
    echo "Created Link: $XCODE_USERDATA/$item"
  else
    echo "Error: Creating Links fails"
  fi
done
ls -l "$XCODE_USERDATA"


PYCHARM_VERSION="CE2021.2"
echo "- 🐍 PyCharm$PYCHARM_VERSION"

PYCHARM_USERDATA="$HOME/Library/Application Support/JetBrains/PyCharm$PYCHARM_VERSION"
CUSTOMIZED_PYCHARM_USERDATA="$APP_PREFERENCES/PyCharm"

rm -rf "$PYCHARM_USERDATA"
ln -nfsv "$CUSTOMIZED_PYCHARM_USERDATA" "$PYCHARM_USERDATA"
ls -l "$PYCHARM_USERDATA"



ANDROID_STUDIO_VERSION="2020.3"
echo "- 🐸 Android Studio $ANDROID_STUDIO_VERSION"

ANDROID_STUDIO_USERDATA="$HOME/Library/Application Support/Google/AndroidStudio$ANDROID_STUDIO_VERSION"
CUSTOMIZED_ANDROID_STUDIO_USERDATA="$APP_PREFERENCES/AndroidStudio"

rm -rf "$ANDROID_STUDIO_USERDATA"
ln -nfsv "$CUSTOMIZED_ANDROID_STUDIO_USERDATA" "$ANDROID_STUDIO_USERDATA"
ls -l "$ANDROID_STUDIO_USERDATA"


echo "- 🎮 iTerm2"
# General > Preferences > check "Load preferences from a custom folder or URL"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
# Restore from the backup
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$APP_PREFERENCES/iTerm2"
# General > Preferences > Save changes: when quits 
defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile -bool true


echo "- ⛓ Karabiner-Elements"
rm -rf "$HOME/.config/karabiner"
ln -nfsv "$APP_PREFERENCES/karabiner" "$HOME/.config/karabiner"
# check if it works
ls -l "$HOME/.config" | grep karabiner


echo "- 🤡 yabai"
touch "$HOME/.yabairc"
ln -nfsv "$HOME/dotfiles/.yabairc" "$HOME/.yabairc"
chmod +x "$HOME/dotfiles/.yabairc"

touch "$HOME/.skhdrc"
ln -nfsv "$HOME/dotfiles/.skhdrc" "$HOME/.skhdrc"
chmod +x "$HOME/dotfiles/.skhdrc"

brew services start skhd
brew services start yabai


echo "- 🐵 Blender"
BLENDER_USERDATA="$HOME/Library/Application Support/Blender"
CUSTOMIZED_BLENDER_USERDATA="$APP_PREFERENCES/Blender"

rm -rf "$BLENDER_USERDATA"
ln -nfsv "$CUSTOMIZED_BLENDER_USERDATA" "$BLENDER_USERDATA"
ls -l "$BLENDER_USERDATA"



echo "- 🔖 Dash"
defaults write com.kapeli.dashdoc syncFolderPath "$APP_PREFERENCES/Dash"
defaults write com.kapeli.dashdoc snippetSQLPath "$APP_PREFERENCES/Dash/Snippets.dash"


echo "\n🎉 Completed Third-Party Software Setup\n"

echo "- 👼 Killall..."
killall Dock
killall Finder
killall SystemUIServer
sudo killall cfprefsd
sudo killall corebrightnessd
