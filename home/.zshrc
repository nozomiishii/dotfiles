# starship
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
eval "$(starship init zsh)"

# Initialize zsh's auto-completion system
autoload -Uz compinit
zmodload -i zsh/complist
compinit

# carapace - multi-shell completion engine
export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
if command -v carapace >/dev/null; then
  # shellcheck source=/dev/null
  source <(carapace _carapace)
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
# cmux が shell-integration ファイルを同梱していないため手動で読み込む
# https://github.com/manaflow-ai/cmux/issues/177
if [[ -n "$GHOSTTY_RESOURCES_DIR" ]]; then
  builtin source "/Applications/Ghostty.app/Contents/Resources/ghostty/shell-integration/zsh/ghostty-integration"
fi

# pm - VS Code Project Manager CLI
export PM_CONFIG="$HOME/Code/nozomiishii/workspaces/projects.json"
export PATH="${XDG_BIN_HOME:-$HOME/.local/bin}:$PATH"
source "${XDG_CONFIG_HOME:-$HOME/.config}/pm/pm.zsh"
# Option+j (ESC+j / ∆)
bindkey -s '^[j' 'pm^M'
bindkey -s '∆' 'pm^M'

# direnv
if command -v direnv >/dev/null; then
  eval "$(direnv hook zsh)"
fi

# Node(fnm)
if command -v fnm >/dev/null; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

# Ruby
if command -v rbenv >/dev/null; then
  eval "$(rbenv init -)"
fi
