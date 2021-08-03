all: test

test: runTests checkFlake

runTests:
	nix develop -c sudo run-tests-in-container.sh

checkFlake:
	nix flake check

doc:
	nix run .#updateReadme

.PHONY: runTests checkFlake test doc
