.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help
	@grep --color=never -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | sed 's/:.*## /\t/' | awk -F '\t' '{printf "  %-12s %s\n", $$1, $$2}'

.PHONY: homebrew
homebrew: ## Install/update Homebrew packages
	bash ./scripts/homebrew.sh

.PHONY: macos
macos: ## Configure macOS settings
	bash ./scripts/darwin/macos.sh

.PHONY: always-on
always-on: ## Configure always-on services
	bash ./scripts/darwin/always_on.sh

.PHONY: github-runner
github-runner: ## Set up GitHub Actions self-hosted runners
	bash ./scripts/darwin/github_runner/setup.sh
	bash ./scripts/darwin/github_runner/key.sh
	bash ./scripts/darwin/github_runner/launchd.sh

.PHONY: github-runner-key
github-runner-key: ## Register/rotate the GitHub App private key
	bash ./scripts/darwin/github_runner/key.sh

.PHONY: github-runner-launchd
github-runner-launchd: ## Register runner LaunchAgents
	bash ./scripts/darwin/github_runner/launchd.sh

.PHONY: toolchains
toolchains: ## Set up language toolchains
	bash ./scripts/toolchains/terraform.sh
	bash ./scripts/toolchains/claude-code.sh
	bash ./scripts/toolchains/node.sh
	bash ./scripts/toolchains/python.sh
	bash ./scripts/toolchains/ruby.sh
	bash ./scripts/toolchains/rust.sh
	bash ./scripts/toolchains/pm.sh

.PHONY: repo
repo: ## Clone GitHub repositories
	gh api repos/nozomiishii/infra/contents/scripts/clone_github_repos.sh -H "Accept: application/vnd.github.raw" | bash

.PHONY: link
link: ## Symlink dotfiles to home directory
	bash ./scripts/symlink.sh
