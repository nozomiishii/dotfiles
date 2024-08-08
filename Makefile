.PHONY: homebrew
homebrew:
	bash ./home/.chezmoiscripts/darwin/run_before_homebrew.sh

.PHONY: macos
macos:
	bash ./home/.chezmoiscripts/darwin/run_onchange_after_macos.sh

.PHONY: toolchains
toolchains:
	bash ./home/.chezmoiscripts/toolchains/run_node.sh
	bash ./home/.chezmoiscripts/toolchains/run_python.sh
	bash ./home/.chezmoiscripts/toolchains/run_ruby.sh
	bash ./home/.chezmoiscripts/toolchains/run_rust.sh

.PHONY: repo
repo:
	bash ./scripts/clone_github_repos.sh
