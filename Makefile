.PHONY: homebrew
homebrew:
	cat ./Brewfile ./Brewfile.optional | brew bundle --verbose --cleanup --file=-
	brew cleanup --verbose

.PHONY: macos
macos:
	bash ./scripts/darwin/macos.sh

.PHONY: always-on
always-on:
	bash ./scripts/darwin/always_on.sh

.PHONY: toolchains
toolchains:
	bash ./scripts/toolchains/terraform.sh
	bash ./scripts/toolchains/claude-code.sh
	bash ./scripts/toolchains/node.sh
	bash ./scripts/toolchains/python.sh
	bash ./scripts/toolchains/ruby.sh
	bash ./scripts/toolchains/rust.sh

.PHONY: repo
repo:
	bash ./scripts/clone_github_repos.sh

.PHONY: link
link:
	bash ./scripts/symlink.sh
