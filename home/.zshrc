# starship
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
eval "$(starship init zsh)"

# Initialize zsh's auto-completion system
autoload -Uz compinit
zmodload -i zsh/complist
compinit

# Syntax Highlighting
source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

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

# git-harvest
export PATH="${XDG_BIN_HOME:-$HOME/.local/bin}:$PATH"

# Claude Code
export CLAUDE_CODE_NO_FLICKER=1

# direnv
if command -v direnv >/dev/null; then
  eval "$(direnv hook zsh)"
fi

# Node(fnm)
if command -v fnm >/dev/null; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Ruby
if command -v rbenv >/dev/null; then
  eval "$(rbenv init -)"
fi

# Python(uv)
if command -v uv >/dev/null; then
  eval "$(uv generate-shell-completion zsh)"
  eval "$(uvx --generate-shell-completion zsh)"
fi
