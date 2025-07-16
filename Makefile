.PHONY: homebrew
homebrew:
	brew bundle --verbose --cleanup --file="./Brewfile"
	brew cleanup --verbose

.PHONY: macos
macos:
	bash ./scripts/darwin/run_onchange_after_macos.sh

.PHONY: toolchains
toolchains:
	bash ./scripts/toolchains/run_node.sh
	bash ./scripts/toolchains/run_python.sh
	bash ./scripts/toolchains/run_ruby.sh
	bash ./scripts/toolchains/run_rust.sh

.PHONY: repo
repo:
	bash ./scripts/clone_github_repos.sh

.PHONY: link
link:
	stow --verbose --restow --adopt --target="$$HOME" home
