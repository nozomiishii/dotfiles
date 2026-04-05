.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help
	@grep --color=never -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | sed 's/:.*## /\t/' | awk -F '\t' '{printf "  %-12s %s\n", $$1, $$2}'

.PHONY: homebrew
homebrew: ## Install/update Homebrew packages
	cat ./Brewfile ./Brewfile.optional | brew bundle --verbose --cleanup --file=-
	brew cleanup --verbose

.PHONY: macos
macos: ## Configure macOS settings
	bash ./scripts/darwin/macos.sh

.PHONY: always-on
always-on: ## Configure always-on services
	bash ./scripts/darwin/always_on.sh

.PHONY: toolchains
toolchains: ## Set up language toolchains
	bash ./scripts/toolchains/terraform.sh
	bash ./scripts/toolchains/claude-code.sh
	bash ./scripts/toolchains/node.sh
	bash ./scripts/toolchains/python.sh
	bash ./scripts/toolchains/ruby.sh
	bash ./scripts/toolchains/rust.sh

.PHONY: repo
repo: ## Clone GitHub repositories
	bash ./scripts/clone_github_repos.sh

.PHONY: link
link: ## Symlink dotfiles to home directory
	bash ./scripts/symlink.sh
