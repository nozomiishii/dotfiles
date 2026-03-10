.PHONY: homebrew
homebrew:
	brew bundle --verbose --cleanup --file="./Brewfile"
	brew cleanup --verbose

.PHONY: macos
macos:
	bash ./scripts/darwin/macos.sh

.PHONY: toolchains
toolchains:
	bash ./scripts/toolchains/terraform.sh
	bash ./scripts/toolchains/node.sh
	bash ./scripts/toolchains/python.sh
	bash ./scripts/toolchains/ruby.sh
	bash ./scripts/toolchains/rust.sh

.PHONY: repo
repo:
	bash ./scripts/clone_github_repos.sh

.PHONY: link
link:
	stow --verbose --restow --adopt --target="$$HOME" home
