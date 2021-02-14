# Nozomi's dotfiles
![Brow my mind](https://media.giphy.com/media/LqajRC2pU0Je8/giphy.gif)

## Installation 📦

1: Sign in your iCloud.

2: `xcode-select --install` (Command Line Tools are required for Git and Homebrew)

3: clone project(on Google Drive or dropbox recommended)
```shell
  cd ~/Google\ Drive && git clone git@github.com:nozomiishii/dotfiles.git 
```

4: Run
```shell
  ./install
```

5: Generate ssh key
Generate 
```ssh
  mkdir -p ~/.ssh && ssh-keygen -t ed25519 -o -a 100 -f ~/.ssh/id_ed25519 -C "TYPE_YOUR_EMAIL@HERE.com"
```
copy ssh key and set up on github
```ssh
  pbcopy < ~/.ssh/id_ed25519.pub
```
check if it's working
```ssh
  ssh -T git@github.com
```
save
```ssh
  ssh-add ~/.ssh/id_ed25519
```

## Install apps 🚚

Brew apps
```shell
  brew install <app name: String>
```

Appstore apps
```shell
  mas install <app id: Int>
```

update Blewfile
```shell
  brew bundle dump
```


## References 🙌
### Tutorials
[eieio](https://github.com/eieioxyz/dotfiles_macos) 

### CheatSheet
[Homebrew - Basics Commands and Cheatsheet](https://dev.to/code2bits/homebrew---basics--cheatsheet-3a3n)
### Modules
[dotbot](https://github.com/anishathalye/dotbot) - Dotbot makes installing your dotfiles as easy as git clone $url && cd dotfiles && ./install, even on a freshly installed system!

### Packages

[bat](https://github.com/sharkdp/bat) - A cat(1) clone with syntax highlighting and Git integration.
[exa](https://github.com/ogham/exa) - A modern replacement for ls.
[brooklyn](https://github.com/pedrommcarrasco/Brooklyn) - Screen Saver by Pedro Carrasco 
[swiftformat-for-xcode](https://github.com/nicklockwood/SwiftFormat) - Reformatting Swift code 
[rbenv](https://github.com/rbenv/rbenv) - Ruby version management

