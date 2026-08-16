# starship
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
eval "$(starship init zsh)"

# Initialize zsh's auto-completion system
# Enable zsh completions distributed through the Nix profile.
if [[ -d "$HOME/.nix-profile/share/zsh/site-functions" ]]; then
  fpath=("$HOME/.nix-profile/share/zsh/site-functions" $fpath)
fi
autoload -Uz compinit
zmodload -i zsh/complist
compinit

# carapace - multi-shell completion engine
export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
export CARAPACE_EXCLUDES='make,devenv'
zstyle ':completion:*:*:make:*' tag-order targets
if command -v carapace >/dev/null; then
  # shellcheck source=/dev/null
  source <(carapace _carapace zsh)
fi

# fzf-tab - replace zsh tab completion with fzf preview menu
# Must be sourced after compinit and before zsh-syntax-highlighting.
brew_prefix=''
if command -v brew >/dev/null; then
  brew_prefix="$(brew --prefix)"
  fzf_tab_path="$brew_prefix/share/fzf-tab/fzf-tab.zsh"

  # shellcheck source=/dev/null
  [[ -r "$fzf_tab_path" ]] && source "$fzf_tab_path"

  if command -v eza >/dev/null; then
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
  fi
fi

# Set up fzf key bindings and fuzzy completion
if command -v fzf >/dev/null; then
  # shellcheck source=/dev/null
  source <(fzf --zsh)
fi

# Syntax Highlighting (must be sourced last)
if [[ -n "$brew_prefix" ]]; then
  zsh_syntax_highlighting_path="$brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  if [[ -r "$zsh_syntax_highlighting_path" ]]; then
    # shellcheck source=/dev/null
    source "$zsh_syntax_highlighting_path"
  fi
fi
unset brew_prefix fzf_tab_path zsh_syntax_highlighting_path

# Config
source "$HOME/.zsh/config.zsh"

# Aliases
source "$HOME/.zsh/alias/index.zsh"

# Functions
source "$HOME/.zsh/functions.zsh"

# Ghostty shell integration
if [[ -n "$GHOSTTY_RESOURCES_DIR" ]]; then
  builtin source "/Applications/Ghostty.app/Contents/Resources/ghostty/shell-integration/zsh/ghostty-integration"
fi

# pm - VS Code Project Manager CLI
# 未導入のマシンでも zsh が起動できるようガードする。source の行は pm installer が
# 追記済み判定に使うマーカーなので、この文字列のまま変えない
# https://github.com/nozomiishii/pm/blob/main/install.sh
export PM_CONFIG="$HOME/Code/nozomiishii/infra/projects.json"
export PATH="${XDG_BIN_HOME:-$HOME/.local/bin}:$PATH"
if [[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/pm/pm.zsh" ]]; then
  # shellcheck source=/dev/null
  source "${XDG_CONFIG_HOME:-$HOME/.config}/pm/pm.zsh"
fi
# Option+j (ESC+j / ∆)
bindkey -s '^[j' 'pm^M'
bindkey -s '∆' 'pm^M'

# direnv
if command -v direnv >/dev/null; then
  eval "$(direnv hook zsh)"
fi

# Ruby
if command -v rbenv >/dev/null; then
  eval "$(rbenv init -)"
fi

# mise
if command -v mise >/dev/null; then
  eval "$(mise activate zsh)"
fi
