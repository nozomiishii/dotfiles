.PHONY: homebrew macos toolchains

homebrew:
	bash ./home/.chezmoiscripts/darwin/run_before_homebrew.sh

macos:
	bash ./home/.chezmoiscripts/darwin/run_onchange_after_macos.sh

toolchains:
	bash ./home/.chezmoiscripts/toolchains/run_node.sh
	bash ./home/.chezmoiscripts/toolchains/run_python.sh
	bash ./home/.chezmoiscripts/toolchains/run_ruby.sh
	bash ./home/.chezmoiscripts/toolchains/run_rust.sh

repo:
	bash ./scripts/clone_github_repos.sh
