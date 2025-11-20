# ----------------------------------------------------------------
# Cask Install Options
# ----------------------------------------------------------------
# appdir: "/Applications"
#   Place all GUI applications together in /Applications.
#
# no_quarantine: true
#   Skip the initial Gatekeeper dialog "App downloaded from the Internet..." on first launch.
cask_args appdir: "/Applications", no_quarantine: true

# Organize software neatly under a single directory tree (e.g. /usr/local) https://www.gnu.org/software/stow/
brew "stow"

# ----------------------------------------------------------------
# Prompt
# ----------------------------------------------------------------
# Fish shell like syntax highlighting for zsh https://github.com/zsh-users/zsh-syntax-highlighting
brew "zsh-syntax-highlighting"

# Cross-shell prompt for astronauts https://starship.rs
brew "starship"

# Pluggable terminal workspace, with terminal multiplexer as the base feature https://zellij.dev/
brew "zellij"

# Command-line helper for the 1Password password manager https://developer.1password.com/docs/cli
cask "1password-cli"

# Smarter Dockerfile linter to validate best practices https://github.com/hadolint/hadolint
brew "hadolint"

# ----------------------------------------------------------------
# macOS-only packages
# ----------------------------------------------------------------
if OS.mac?
  # ----------------------------------------------------------------
  # FIXME: 以下も入れたいけど, dev containerに入れようとするとエラーになる
  # ----------------------------------------------------------------
  # CLI: Easiest, most secure way to use WireGuard and 2FA https://tailscale.com
  # brew "tailscale"

  # GUI: Mesh VPN based on WireGuard https://tailscale.com/
  cask "tailscale-app"

  # GitHub command-line tool. https://github.com/cli/cli
  brew "gh"

  # AI-powered productivity tool for the command-line https://aws.amazon.com/q/developer/
  cask "amazon-q"

  # ----------------------------------------------------------------
  # OpenTofu / Terraform / Terragrunt / Terramate / Atmos version manager https://tofuutils.github.io/tenv/
  brew "tenv"

  # Linter for Terraform files https://github.com/terraform-linters/tflint
  brew "tflint"

  # Tool to generate documentation from Terraform modules https://terraform-docs.io/
  brew "terraform-docs"

  # Password manager that keeps all passwords secure behind one password. https://1password.com
  cask "1Password"

  # Terminal emulator that uses platform-native UI and GPU acceleration https://ghostty.org/
  cask "ghostty"

  # Dictation tool including LLM reformatting https://superwhisper.com/
  cask "superwhisper"

  # Speech-to-text system https://withaqua.com/
  cask "aqua-voice"

  # GUI app and toolkit for Claude Code https://github.com/getasterisk/claudia
  cask "claudia"

  # ----------------------------------------------------------------
  # Shell Development Environments
  # ----------------------------------------------------------------
  # Autoformat shell script source code https://github.com/mvdan/sh
  brew "shfmt"

  # Static analysis and lint tool, for (ba)sh scripts https://www.shellcheck.net/
  brew "shellcheck"

  # Bash Automated Testing System https://github.com/bats-core/bats-core
  brew "bats-core"

  # ----------------------------------------------------------------
  # Ruby
  # ----------------------------------------------------------------
  # Ruby version manager https://github.com/rbenv/rbenv#readme
  brew "rbenv"

  # Install various Ruby versions and implementations https://github.com/rbenv/ruby-build
  brew "ruby-build"

  # YAML Parser https://github.com/yaml/libyaml
  brew "libyaml"

  # ----------------------------------------------------------------
  # Node
  # ----------------------------------------------------------------
  # Fast Node Manager https://github.com/Schniz/fnm
  brew "fnm"

  # ----------------------------------------------------------------
  # Go
  # ----------------------------------------------------------------
  # Open source programming language to build simple/reliable/efficient software https://go.dev/
  brew "go"

  # Go Language's command-line interface for database migrations https://pressly.github.io/goose/
  brew "goose"

  # ----------------------------------------------------------------
  # Brew
  # ----------------------------------------------------------------
  # Run your GitHub Actions locally https://github.com/nektos/act
  brew "act"

  # Cat(1) clone with syntax highlighting and Git integration. https://github.com/sharkdp/bat
  brew "bat"

  # Load/unload environment variables based on $PWD https://direnv.net/
  brew "direnv"

  # Modern replacement for ls. https://github.com/eza-community/eza
  brew "eza"

  # Distributed revision control system. https://git-scm.com
  brew "git"

  # GNU grep, egrep and fgrep https://www.gnu.org/software/grep/
  brew "grep"

  # Command-line benchmarking tool https://github.com/sharkdp/hyperfine
  brew "hyperfine"

  # Lightweight and flexible command-line JSON processor https://stedolan.github.io/jq/
  brew "jq"

  # Ambitious Vim-fork focused on extensibility and agility https://neovim.io/
  brew "neovim"

  # Object-relational database system https://www.postgresql.org/
  brew "postgresql@17"

  # Protocol buffers (Google's data interchange format) https://github.com/protocolbuffers/protobuf/
  brew "protobuf"

  # Persistent key-value database, with built-in net interface https://redis.io/
  brew "redis"

  # Search tool like grep and The Silver Searcher https://github.com/BurntSushi/ripgrep
  brew "ripgrep"

  # Intuitive find & replace CLI https://github.com/chmln/sd
  brew "sd"

  # Dependencies app.sh | Select default apps for documents and URL schemes on macOS https://github.com/moretension/duti/
  brew "duti"

  # A CLI for configuring 'Night Shift' on macOS https://github.com/smudge/nightlight
  tap "smudge/smudge"
  brew "smudge/smudge/nightlight"

  # Dependency manager for Cocoa projects https://cocoapods.org/
  brew "cocoapods"

  # Play, record, convert, and stream audio and video https://ffmpeg.org/
  brew "ffmpeg"

  # Command-line tools for fly.io services https://fly.io
  brew "flyctl"

  # Command-line JSON processing tool https://github.com/antonmedv/fx
  brew "fx"

  # Like cURL, but for gRPC https://github.com/fullstorydev/grpcurl
  brew "grpcurl"

  # Build, test, and manage your Stripe integration https://stripe.com/docs/stripe-cli
  tap "stripe/stripe-cli"
  brew "stripe/stripe-cli/stripe"

  # Official Amazon AWS command-line interface https://aws.amazon.com/cli/
  brew "awscli"

  # ----------------------------------------------------------------
  # Cask
  # ----------------------------------------------------------------

  # Web browser focusing on privacy https://brave.com/
  cask "brave-browser"

  # Anthropic's official Claude AI desktop app https://www.anthropic.com/
  cask "claude"

  # Terminal-based AI coding assistant https://www.anthropic.com/claude-code
  cask "claude-code"

  # Replacement for Docker Desktop https://orbstack.dev/
  cask "orbstack"

  # Knowledge base that works on top of a local folder of plain text Markdown files https://obsidian.md/
  cask "obsidian"

  # Voice and text chat software. https://discord.com
  cask "discord"

  # Collaborative interface design tool. https://www.figma.com
  cask "figma"

  # GIT client　https://fork.dev/
  cask "fork"

  # OpenAI's official browser with ChatGPT built in https://chatgpt.com/atlas
  cask "chatgpt-atlas"

  # Web browser. https://www.google.com/chrome
  cask "google-chrome"

  # Google Cloud SDK https://cloud.google.com/sdk/
  cask "google-cloud-sdk"

  # Client for the Google Drive storage service https://www.google.com/drive/
  cask "google-drive"

  # App to write, plan, collaborate, and get organized. https://www.notion.so
  cask "notion"

  # Collaboration platform for API development. https://www.postman.com
  cask "postman"

  # Control your tools with a few keystrokes https://raycast.app/
  cask "raycast"

  # Team communication and collaboration software. https://slack.com
  cask "slack"

  # Native GUI tool for relational databases https://tableplus.com/
  cask "tableplus"

  # Open-source code editor. https://code.visualstudio.com
  cask "visual-studio-code"

  # Write, edit, and chat about your code with AI https://cursor.sh/
  cask "cursor"

  # Video communication and virtual meeting platform https://www.zoom.us/
  cask "zoom"

  # FreeMacSoft AppCleaner https://freemacsoft.net/appcleaner/
  cask "appcleaner"

  # Lock/unlock Apple computers using the proximity of a bluetooth low energy device https://github.com/ts1/BLEUnlock
  cask "bleunlock"

  # Screen Saver by Pedro Carrasco. https://github.com/pedrommcarrasco/Brooklyn
  cask "brooklyn"

  # Color picking application. https://colorsnapper.com
  cask "colorsnapper"

  # Tool for using an iPad as a second display https://www.duetdisplay.com/
  cask "duet"

  # Automated organization https://www.noodlesoft.com/
  cask "hazel"

  # Mozilla Firefox https://www.mozilla.org/firefox
  cask "firefox"

  # Wallet desktop application to maintain multiple cryptocurrencies https://www.ledgerwallet.com/live
  cask "ledger-live"

  # Music streaming service. https://www.spotify.com
  cask "spotify"

  # Virtual machines UI using QEMU https://getutm.app/
  cask "utm"

  # Tools for building Android applications https://developer.android.com/studio
  cask "android-studio"

  # Free and open-source 3D creation suite. https://www.blender.org
  cask "blender"

  # Virtual video-calling space https://gather.town/
  cask "gather"

  # Online collaborative whiteboard platform https://miro.com/
  cask "miro"

  # Messaging app with a focus on speed and security https://macos.telegram.org/
  cask "telegram"

  # Instant messaging application focusing on security https://signal.org/
  cask "signal"

  # Multimedia player. https://www.videolan.org/vlc
  cask "vlc"

  # Virtualization tool https://github.com/insidegui/VirtualBuddy
  cask "VirtualBuddy"

  # Agent-centric IDE with spec-driven development https://kiro.dev/
  cask "kiro"

  # AI Coding Agent IDE https://antigravity.google/
  cask "antigravity"

  # Open-source software for live streaming and screen recording https://obsproject.com/
  cask "obs"

  unless ENV["CI"]
    # VPN client for secure internet access and private browsing https://nordvpn.com/
    # mas "nordvpn", id: 905953485
    cask "nordvpn"

    # ----------------------------------------------------------------
    # Mas
    #
    # Search `mas search <app_name>`
    # info   `mas info <app_id>`
    # ----------------------------------------------------------------
    # Simple command line interface for the Mac App Store. https://github.com/mas-cli/mas
    brew "mas"

    # Apple's integrated development environment for macOS. https://developer.apple.com/xcode/
    mas "Xcode", id: 497799835

    # Interface for reading and syncing eBooks. https://www.amazon.com/gp/digital/fiona/kcp-landing-page
    mas "Kindle", id: 302584613

    # New communication app which allows you to make FREE voice calls and send FREE messages https://apps.apple.com/app/line/id539883307
    mas "LINE", id: 539883307
  end
end
