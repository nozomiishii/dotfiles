# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

### Development Tasks
```bash
# Install Node.js dependencies
pnpm install

# Run tests (validates setup scripts)
pnpm test

# Format code with Prettier
pnpm run format

# Lint markdown files
pnpm run lint

# Run Prettier without writing changes
pnpm run prettier

# Test shell startup performance
./scripts/test_shell_startup_time.sh
```

### System Setup Tasks
```bash
# Install/update Homebrew packages
make homebrew

# Configure macOS settings
make macos

# Set up programming toolchains (Node, Python, Ruby, Rust)
make toolchains

# Clone GitHub repositories
make repo

# Symlink dotfiles to home directory using GNU Stow
make link

# Complete installation (macOS/Linux)
./install.sh
```

## Architecture Overview

This is a comprehensive dotfiles repository that automates the setup of development environments on macOS and Linux. It uses **GNU Stow** for symlink management and provides a unified interface through Make targets.

### Key Components

1. **`home/` directory**: Contains all dotfiles organized to mirror the home directory structure. When `make link` is run, GNU Stow creates symlinks from `~` to files in this directory.

2. **`scripts/` directory**: Contains automation scripts organized by:
   - Platform (`darwin/` for macOS-specific)
   - Purpose (`toolchains/` for language setup)
   - Execution order (files prefixed with `run_onchange_after_` run when content changes)

3. **Makefile**: Central automation hub providing consistent commands for common tasks.

4. **Configuration Management**:
   - Shell configs: `.zshrc`, `.zprofile`, and `.zsh/` directory
   - Application configs: Mostly in `.config/` following XDG Base Directory spec
   - macOS app data: `Library/` for VS Code, Xcode settings

### Important Patterns

- **Stow Usage**: All dotfiles in `home/` are symlinked to `~` via GNU Stow. Never create files directly in `~` when adding new configs.
- **Script Naming**: Scripts using `run_onchange_after_` prefix are idempotent and run when their content changes.
- **Package Management**: Uses Homebrew (via `Brewfile`) for system packages and pnpm for Node.js dependencies.
- **Git Hooks**: Managed by lefthook with configuration in `lefthook.yaml`.
- **Code Quality**: Prettier for formatting, commitlint for commit messages, markdownlint for documentation.

### Key Files to Know

- `install.sh`: Main entry point for new system setup
- `Brewfile`: Defines all Homebrew packages, casks, and Mac App Store apps
- `.github/workflows/test-install.yaml`: CI configuration that tests installation on macOS and Ubuntu
- `.mcp.json`: MCP server configuration for AI assistant integration

### Adding New Configurations

1. Place dotfiles in appropriate subdirectory under `home/`
2. Run `make link` to create symlinks
3. If adding new tools, update `Brewfile` for system packages
4. For new scripts, follow the naming convention and place in appropriate `scripts/` subdirectory